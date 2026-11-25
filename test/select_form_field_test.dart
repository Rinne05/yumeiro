import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

const _options = [
  YumeiroSelectionOption(value: 1, label: 'Alpha'),
  YumeiroSelectionOption(value: 2, label: 'Beta'),
];

void main() {
  testWidgets('shrink-wrap select includes clear and chevron in its width', (
    tester,
  ) async {
    const label = 'Selectable Alpha';
    await tester.pumpWidget(
      YumeiroApp(
        modality: YumeiroModality.pointer,
        home: Scaffold(
          body: Center(
            child: YumeiroSelect.form<int>(
              options: const [YumeiroSelectionOption(value: 1, label: label)],
              initialValue: 1,
              expand: false,
              clearable: true,
            ),
          ),
        ),
      ),
    );
    expect(
      tester.renderObject<RenderParagraph>(find.text(label)).didExceedMaxLines,
      isFalse,
    );
  });

  for (final modality in YumeiroModality.values) {
    testWidgets(
      'searchable select shares the form lifecycle in ${modality.name}',
      (tester) async {
        final form = GlobalKey<FormState>();
        final field = GlobalKey<FormFieldState<int>>();
        final focus = FocusNode();
        addTearDown(focus.dispose);
        final changes = <int?>[];
        final saved = <int?>[];
        await tester.pumpWidget(
          YumeiroApp(
            modality: modality,
            locale: const Locale('en'),
            home: Scaffold(
              body: Form(
                key: form,
                child: YumeiroSelect.form<int>(
                  key: field,
                  options: _options,
                  initialValue: 1,
                  label: 'Region',
                  focusNode: focus,
                  clearable: true,
                  searchable: true,
                  onChanged: changes.add,
                  onSaved: saved.add,
                  validator: (value) => value == null ? 'Pick a region' : null,
                ),
              ),
            ),
          ),
        );

        if (modality == YumeiroModality.touch) {
          await tester.tap(find.text('Alpha'));
        } else {
          await tester.tap(find.byType(TextField));
        }
        await tester.pumpAndSettle();
        expect(focus.hasFocus, modality == YumeiroModality.pointer);
        await tester.enterText(find.byType(EditableText), 'Bet');
        await tester.pumpAndSettle();
        await tester.tap(find.text('Beta'));
        await tester.pumpAndSettle();
        expect(field.currentState!.value, 2);
        expect(changes, [2]);
        expect(form.currentState!.validate(), isTrue);
        form.currentState!.save();
        expect(saved, [2]);

        expect(find.byTooltip('Clear'), findsOneWidget);
        final clear = find.semantics.byLabel('Clear, Region');
        tester.semantics.tap(clear);
        await tester.pumpAndSettle();
        expect(changes, [2, null]);
        expect(form.currentState!.validate(), isFalse);
        await tester.pumpAndSettle();
        expect(find.text('Pick a region'), findsOneWidget);

        if (modality == YumeiroModality.pointer) {
          await tester.enterText(find.byType(EditableText), 'Uncommitted');
          await tester.pumpAndSettle();
        }
        form.currentState!.reset();
        await tester.pumpAndSettle();
        expect(field.currentState!.value, 1);
        expect(find.text('Alpha'), findsOneWidget);
        expect(find.text('Uncommitted'), findsNothing);
        expect(changes, [2, null]);
      },
    );

    testWidgets(
      'select field validates, saves and resets in ${modality.name}',
      (tester) async {
        final form = GlobalKey<FormState>();
        final field = GlobalKey<FormFieldState<int>>();
        final changes = <int?>[];
        final saved = <int?>[];
        final forcedError = ValueNotifier<String?>(null);
        addTearDown(forcedError.dispose);
        var resets = 0;
        var validations = 0;
        await tester.pumpWidget(
          YumeiroApp(
            modality: modality,
            home: Scaffold(
              body: Form(
                key: form,
                child: ValueListenableBuilder(
                  valueListenable: forcedError,
                  builder: (context, error, _) => YumeiroSelect.form(
                    key: field,
                    label: 'Region',
                    helperText: 'Where this service runs',
                    required: true,
                    options: _options,
                    placeholder: 'Choose a region',
                    onChanged: changes.add,
                    onSaved: saved.add,
                    onReset: () => resets++,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) {
                      validations++;
                      return value == null ? 'Selection is required' : null;
                    },
                    forceErrorText: error,
                  ),
                ),
              ),
            ),
          ),
        );
        expect(field.currentState!.value, isNull);
        expect(find.text('Where this service runs'), findsOneWidget);
        expect(find.text('Selection is required'), findsNothing);
        expect(form.currentState!.validate(), isFalse);
        await tester.pump();
        expect(find.text('Selection is required'), findsOneWidget);
        expect(find.text('Where this service runs'), findsNothing);

        final trigger = find.byType(YumeiroSelect<int>);
        final danger = YumeiroTheme.of(tester.element(trigger)).danger;
        expect(_triggerOutline(tester, trigger), danger);
        await tester.tap(trigger);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Beta'));
        await tester.pumpAndSettle();
        expect(field.currentState!.value, 2);
        expect(changes, [2]);
        expect(find.text('Selection is required'), findsNothing);
        expect(find.text('Where this service runs'), findsOneWidget);
        form.currentState!.save();
        expect(saved, [2]);

        final previousValidations = validations;
        forcedError.value = 'Region unavailable';
        await tester.pump();
        expect(form.currentState!.validate(), isFalse);
        await tester.pump();
        expect(find.text('Region unavailable'), findsOneWidget);
        expect(validations, previousValidations);
        forcedError.value = null;
        await tester.pump();

        form.currentState!.reset();
        await tester.pump();
        expect(field.currentState!.value, isNull);
        expect(find.text('Choose a region'), findsOneWidget);
        expect(find.text('Region unavailable'), findsNothing);
        expect(changes, [2]);
        expect(resets, 1);
      },
    );

    for (final invalidate in [
      'reset',
      'programmatic change',
      'disable',
      'read only',
      'disable option',
      'remove',
    ]) {
      final behavior = invalidate == 'disable option' ? 'refreshes' : 'closes';
      testWidgets('$behavior the ${modality.name} picker after $invalidate', (
        tester,
      ) async {
        final form = GlobalKey<FormState>();
        final field = GlobalKey<FormFieldState<int>>();
        final changes = <int?>[];
        late StateSetter update;
        var enabled = true;
        var readOnly = false;
        var visible = true;
        var options = _options;
        await tester.pumpWidget(
          YumeiroApp(
            modality: modality,
            home: Scaffold(
              body: Form(
                key: form,
                child: StatefulBuilder(
                  builder: (_, setState) {
                    update = setState;
                    return visible
                        ? YumeiroSelect.form(
                            key: field,
                            initialValue: 1,
                            options: options,
                            enabled: enabled,
                            readOnly: readOnly,
                            onChanged: changes.add,
                          )
                        : const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.byType(YumeiroSelect<int>));
        await tester.pumpAndSettle();
        expect(find.text('Beta'), findsOneWidget);
        switch (invalidate) {
          case 'reset':
            form.currentState!.reset();
          case 'programmatic change':
            field.currentState!.didChange(null);
          case 'disable':
            update(() => enabled = false);
          case 'read only':
            update(() => readOnly = true);
          case 'disable option':
            update(() {
              options = [
                _options.first,
                const YumeiroSelectionOption(
                  value: 2,
                  label: 'Beta',
                  enabled: false,
                ),
              ];
            });
          case 'remove':
            update(() => visible = false);
        }
        await tester.pumpAndSettle();
        final list = find.byType(YumeiroSelectionList<int>);
        if (invalidate == 'disable option') {
          expect(
            tester.widget<YumeiroSelectionList<int>>(list).options.last.enabled,
            isFalse,
          );
          await tester.tap(find.text('Beta'));
          await tester.pumpAndSettle();
          expect(list, findsOneWidget);
          if (modality == YumeiroModality.touch) {
            await tester.tap(find.byTooltip('Close'));
          } else {
            await tester.tapAt(const Offset(4, 500));
          }
          await tester.pumpAndSettle();
        }
        expect(list, findsNothing);
        expect(find.text('Beta'), findsNothing);
        expect(changes, isEmpty);
        expect(
          field.currentState?.value,
          visible && invalidate != 'programmatic change' ? 1 : null,
        );
        expect(tester.takeException(), isNull);
      });
    }

    for (final useRootNavigator in [true, false]) {
      testWidgets(
        '${modality.name} select opens on the requested navigator with local configuration (root=$useRootNavigator)',
        (tester) async {
          final outer = GlobalKey<NavigatorState>();
          final inner = GlobalKey<NavigatorState>();
          final changes = <int?>[];
          await tester.pumpWidget(
            MaterialApp(
              navigatorKey: outer,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              supportedLocales: const [Locale('en'), Locale('zh')],
              builder: (_, child) => YumeiroScope(
                preset: YumeiroThemePresets.classicDark,
                child: child!,
              ),
              home: Navigator(
                key: inner,
                onGenerateRoute: (_) => MaterialPageRoute<void>(
                  builder: (_) => YumeiroScope(
                    preset: YumeiroThemePresets.classicLight,
                    locale: const Locale('zh'),
                    modality: modality,
                    density: YumeiroDensity.comfortable,
                    capability: YumeiroMaterialCapability.blurOnly,
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: Scaffold(
                        body: YumeiroSelect.form<int>(
                          options: _options,
                          initialValue: 1,
                          useRootNavigator: useRootNavigator,
                          onChanged: changes.add,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );

          await tester.tap(find.byType(YumeiroSelect<int>));
          await tester.pumpAndSettle();
          expect(outer.currentState!.canPop(), useRootNavigator);
          expect(inner.currentState!.canPop(), !useRootNavigator);
          final option = find.text('Beta');
          final context = tester.element(option);
          expect(
            YumeiroTheme.of(context).presetId,
            YumeiroThemePresets.classicLight.id,
          );
          expect(YumeiroLocalizations.of(context).localeName, 'zh');
          expect(YumeiroModalityScope.modalityOf(context), modality);
          expect(
            YumeiroModalityScope.densityOf(context),
            YumeiroDensity.comfortable,
          );
          expect(
            YumeiroMaterialCapabilityScope.of(context),
            YumeiroMaterialCapability.blurOnly,
          );
          expect(Directionality.of(context), TextDirection.rtl);

          await tester.tap(option);
          await tester.pumpAndSettle();
          expect(changes, [2]);
          expect(outer.currentState!.canPop(), isFalse);
          expect(inner.currentState!.canPop(), isFalse);
        },
      );
    }

    testWidgets('opt-in clear reports null and validates in ${modality.name}', (
      tester,
    ) async {
      final field = GlobalKey<FormFieldState<int>>();
      final changes = <int?>[];
      await tester.pumpWidget(
        YumeiroApp(
          modality: modality,
          locale: const Locale('en'),
          home: Scaffold(
            body: YumeiroSelect.form(
              key: field,
              options: _options,
              initialValue: 1,
              label: 'Region',
              semanticLabel: 'Service location',
              clearable: true,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) => value == null ? 'Choose a region' : null,
              onChanged: changes.add,
            ),
          ),
        ),
      );

      final clear = find.byType(YumeiroButton);
      final clearAction = find.semantics.byLabel('Clear, Service location');
      expect(
        clearAction.evaluate().single,
        isSemantics(label: 'Clear, Service location', hasTapAction: true),
      );
      tester.semantics.tap(clearAction);
      await tester.pumpAndSettle();
      expect(field.currentState!.value, isNull);
      expect(changes, [null]);
      expect(find.text('Choose a region'), findsOneWidget);
      expect(clear, findsNothing);
      expect(find.text('Beta'), findsNothing);
      field.currentState!.reset();
      await tester.pumpAndSettle();
      expect(field.currentState!.value, 1);
      expect(changes, [null]);
      expect(clear, findsOneWidget);
    });
  }

  for (final readOnly in [true, false]) {
    testWidgets(
      'select field exposes ${readOnly ? 'read-only' : 'disabled'} semantics',
      (tester) async {
        final focus = FocusNode();
        addTearDown(focus.dispose);
        await tester.pumpWidget(
          YumeiroApp(
            home: Scaffold(
              body: YumeiroSelect.form(
                options: _options,
                initialValue: 1,
                label: 'Region',
                semanticLabel: 'Service location',
                autofocus: true,
                focusNode: focus,
                readOnly: readOnly,
                enabled: readOnly,
                clearable: true,
                forceErrorText: 'Invalid region',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final trigger = find.byType(YumeiroSelect<int>);
        final semantics = tester.getSemantics(trigger);
        expect(
          semantics,
          isSemantics(
            hasEnabledState: true,
            isEnabled: readOnly,
            isReadOnly: readOnly,
            hasTapAction: false,
          ),
        );
        expect(semantics.label, contains('Service location'));
        expect(semantics.label, isNot(contains('Region')));
        expect(focus.hasFocus, readOnly);
        expect(find.byType(YumeiroButton), findsNothing);
        final danger = YumeiroTheme.of(tester.element(trigger)).danger;
        expect(
          _triggerOutline(tester, trigger),
          readOnly ? danger : isNot(danger),
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.tap(trigger, warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(find.text('Beta'), findsNothing);
        expect(find.text('Alpha'), findsOneWidget);
      },
    );
  }
}

Color _triggerOutline(WidgetTester tester, Finder trigger) => tester
    .widget<YumeiroResolvedVisualSurface>(
      find
          .descendant(
            of: trigger,
            matching: find.byType(YumeiroResolvedVisualSurface),
          )
          .first,
    )
    .appearance
    .outline
    .color;
