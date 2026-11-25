import 'dart:ui' show CheckedState;

import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

const _options = [
  YumeiroSelectionOption(value: 'a', label: 'Alpha'),
  YumeiroSelectionOption(value: 'b', label: 'Beta'),
  YumeiroSelectionOption(value: 'c', label: 'Locked', enabled: false),
];

void main() {
  for (final modality in YumeiroModality.values) {
    testWidgets(
      'multi-select confirms or discards a draft in ${modality.name}',
      (tester) async {
        final pointer = modality == YumeiroModality.pointer;
        final form = GlobalKey<FormState>();
        final field = GlobalKey<FormFieldState<Set<String>>>();
        final saved = <Set<String>?>[];
        final changes = <Set<String>>[];
        await tester.pumpWidget(
          _host(
            modality,
            Form(
              key: form,
              child: YumeiroMultiSelect.form(
                key: field,
                options: _options,
                label: 'Reviewers',
                placeholder: 'Choose reviewers',
                required: true,
                searchable: true,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) =>
                    value!.isEmpty ? 'Choose at least one' : null,
                onChanged: changes.add,
                onSaved: saved.add,
              ),
            ),
          ),
        );

        expect(form.currentState!.validate(), isFalse);
        await tester.pump();
        expect(find.text('Choose at least one'), findsOneWidget);
        Future<void> open() async {
          await tester.tap(find.text('Choose reviewers'));
          await tester.pumpAndSettle();
        }

        await open();
        expect(
          find.byType(YumeiroBottomSheet),
          pointer ? findsNothing : findsOneWidget,
        );
        if (pointer) {
          final editor = _inField(find.byType(EditableText));
          final cancel = _inField(find.text('Cancel'));
          expect(editor, findsOneWidget);
          expect(cancel, findsOneWidget);
          expect(_inPopup(find.byType(EditableText)), findsNothing);
          expect(_inPopup(find.text('Cancel')), findsNothing);
          await tester.enterText(editor, 'Be');
          await tester.pumpAndSettle();
          expect(_optionText('Alpha'), findsNothing);
          expect(cancel, findsOneWidget);
          await tester.tap(cancel);
          await tester.pumpAndSettle();
          expect(_pointerPopup(), findsNothing);
          expect(changes, isEmpty);
          await open();
        }

        final alpha = _optionText('Alpha');
        expect(find.byType(Checkbox), findsNWidgets(_options.length));
        CheckedState checked() => tester
            .getSemantics(alpha)
            .getSemanticsData()
            .flagsCollection
            .isChecked;
        if (pointer) {
          expect(checked(), CheckedState.isFalse);
        }
        await tester.tap(alpha);
        await tester.pumpAndSettle();
        if (pointer) {
          expect(checked(), CheckedState.isTrue);
          final confirm = find.text('Confirm (1)');
          expect(_inField(confirm), findsOneWidget);
          expect(_inPopup(confirm), findsNothing);
          expect(
            tester
                .widget<EditableText>(_inField(find.byType(EditableText)))
                .focusNode
                .hasFocus,
            isTrue,
          );
        }
        expect(field.currentState!.value, isEmpty);
        await tester.tapAt(const Offset(4, 4));
        await tester.pumpAndSettle();
        expect(changes, isEmpty);

        if (pointer) {
          await open();
          await tester.tap(alpha);
          await tester.pumpAndSettle();
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pumpAndSettle();
          expect(_pointerPopup(), findsNothing);
          expect(field.currentState!.value, isEmpty);
          expect(changes, isEmpty);
        }

        await open();
        await tester.tap(alpha);
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(EditableText), 'Beta');
        await tester.pumpAndSettle();
        expect(alpha, findsNothing);
        await tester.tap(_optionText('Beta'));
        await tester.pumpAndSettle();
        final confirmBoth = find.text('Confirm (2)');
        await tester.tap(pointer ? _inField(confirmBoth) : confirmBoth);
        await tester.pumpAndSettle();
        expect(changes, [
          {'a', 'b'},
        ]);
        expect(() => changes.single.clear(), throwsUnsupportedError);
        expect(find.text('Alpha, Beta'), findsOneWidget);
        expect(_pointerPopup(), findsNothing);
        expect(find.text('Choose at least one'), findsNothing);
        form.currentState!.save();
        expect(saved.single, {'a', 'b'});

        await tester.tap(find.text('Alpha, Beta'));
        await tester.pumpAndSettle();
        await tester.tap(alpha);
        await tester.tap(_optionText('Beta'));
        await tester.pumpAndSettle();
        final confirmNone = find.text('Confirm (0)');
        await tester.tap(pointer ? _inField(confirmNone) : confirmNone);
        await tester.pumpAndSettle();
        expect(changes.last, isEmpty);
        expect(find.text('Choose at least one'), findsOneWidget);

        form.currentState!.reset();
        await tester.pump();
        expect(field.currentState!.value, isEmpty);
        expect(find.text('Choose at least one'), findsNothing);
        expect(changes, hasLength(2));
      },
    );
  }

  testWidgets(
    'standalone multi-select applies eligible edits to the host value',
    (tester) async {
      final value = ValueNotifier<Set<String>>({'a'});
      addTearDown(value.dispose);
      final changes = <Set<String>>[];
      await tester.pumpWidget(
        _host(
          YumeiroModality.pointer,
          ValueListenableBuilder(
            valueListenable: value,
            builder: (context, selection, _) => YumeiroMultiSelect<String>(
              options: _options,
              value: selection,
              onChanged: changes.add,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();
      await tester.tap(_optionText('Beta'));
      await tester.pumpAndSettle();
      expect(changes, isEmpty);
      value.value = {'c'};
      await tester.pump();
      await tester.tap(_inField(find.text('Confirm (2)')));
      await tester.pumpAndSettle();
      expect(changes, [
        {'b', 'c'},
      ]);
      expect(() => changes.single.clear(), throwsUnsupportedError);
      expect(find.text('Locked'), findsOneWidget);
      value.value = changes.single;
      await tester.pumpAndSettle();
      expect(find.text('Beta, Locked'), findsOneWidget);
    },
  );

  for (final modality in YumeiroModality.values) {
    testWidgets('summary shows labels in option order in ${modality.name}', (
      tester,
    ) async {
      final value = ValueNotifier<Set<String>>({'b', 'a', 'unknown'});
      addTearDown(value.dispose);
      final chinese = modality == YumeiroModality.touch;
      await tester.pumpWidget(
        _host(
          modality,
          ValueListenableBuilder(
            valueListenable: value,
            builder: (_, selection, _) => YumeiroMultiSelect<String>(
              options: _options,
              value: selection,
              width: 112,
              onChanged: (_) {},
            ),
          ),
          locale: Locale(chinese ? 'zh' : 'en'),
        ),
      );

      final summary = find.text(chinese ? 'Alpha、Beta +1' : 'Alpha, Beta +1');
      final text = tester.widget<Text>(summary);
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
      expect(
        tester.renderObject<RenderParagraph>(summary).didExceedMaxLines,
        isTrue,
      );

      value.value = {'unknown', 'other'};
      await tester.pumpAndSettle();
      final host = find.byType(YumeiroMultiSelect<String>);
      expect(
        find.text(
          YumeiroLocalizations.of(tester.element(host)).selectedCount(2),
        ),
        findsOneWidget,
      );
    });
  }

  testWidgets('inline choices preserve hidden values and honor read only', (
    tester,
  ) async {
    final optionsEditable = ValueNotifier(true);
    addTearDown(optionsEditable.dispose);
    final field = GlobalKey<FormFieldState<Set<String>>>();
    final original = {'c', 'unknown'};
    await tester.pumpWidget(
      _host(
        YumeiroModality.pointer,
        SingleChildScrollView(
          child: ValueListenableBuilder(
            valueListenable: optionsEditable,
            builder: (context, editable, _) => YumeiroSelectionList.multiForm(
              key: field,
              options: _options,
              initialValue: original,
              searchable: true,
              readOnly: !editable,
            ),
          ),
        ),
      ),
    );
    original.clear();
    expect(field.currentState!.value, {'c', 'unknown'});
    expect(
      find.descendant(
        of: find.byType(YumeiroSelectionList<String>),
        matching: find.byType(SingleChildScrollView),
      ),
      findsNothing,
    );
    await tester.tap(_optionText('Locked'));
    await tester.tap(_optionText('Alpha'));
    await tester.pumpAndSettle();
    expect(field.currentState!.value, {'a', 'c', 'unknown'});

    await tester.enterText(find.byType(EditableText), 'Beta');
    await tester.pumpAndSettle();
    expect(find.text('Alpha'), findsNothing);
    optionsEditable.value = false;
    await tester.pumpAndSettle();
    await tester.tap(_optionText('Beta'), warnIfMissed: false);
    expect(field.currentState!.value, {'a', 'c', 'unknown'});
  });

  for (final modality in YumeiroModality.values) {
    testWidgets(
      'inline search remains above immediate choices in ${modality.name}',
      (tester) async {
        final field = GlobalKey<FormFieldState<Set<String>>>();
        final changes = <Set<String>>[];
        await tester.pumpWidget(
          _host(
            modality,
            YumeiroSelectionList.multiForm(
              key: field,
              label: 'Reviewers',
              searchable: true,
              clearable: true,
              initialValue: const {'a'},
              options: _options,
              onChanged: changes.add,
            ),
          ),
        );

        final fieldWidget = find.byType(YumeiroSelectionList<String>);
        final search = find.descendant(
          of: fieldWidget,
          matching: find.byType(YumeiroTextField),
        );
        expect(search, findsOneWidget);
        final editor = find.descendant(
          of: search,
          matching: find.byType(EditableText),
        );
        final panel = _inlineOptionPanel(_optionText('Alpha'));
        final initialSearch = tester.getRect(search);
        final initialPanel = tester.getRect(panel);
        expect(initialSearch.left, initialPanel.left);
        expect(initialSearch.right, initialPanel.right);
        expect(initialSearch.bottom, lessThanOrEqualTo(initialPanel.top));
        await tester.enterText(editor, 'Bet');
        await tester.pumpAndSettle();
        expect(_optionText('Alpha'), findsNothing);
        final searchBounds = tester.getRect(search);
        await tester.tap(_optionText('Beta'));
        expect(field.currentState!.value, {'a', 'b'});
        expect(changes, [
          {'a', 'b'},
        ]);
        expect(find.text('Confirm (2)'), findsNothing);
        expect(find.byType(YumeiroBottomSheet), findsNothing);

        await tester.pumpAndSettle();
        final clear = find.descendant(
          of: search,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is YumeiroButton &&
                widget.semanticLabel == 'Clear, Reviewers',
          ),
        );
        final clearQuery = find.descendant(
          of: search,
          matching: find.byWidgetPredicate(
            (widget) => widget is YumeiroButton && widget.tooltip == 'Clear',
          ),
        );
        final theme = YumeiroTheme.of(tester.element(clear));
        expect(tester.widget<YumeiroButton>(clear).icon, theme.icons.close);
        final clearSurface = find
            .descendant(
              of: clear,
              matching: find.byType(YumeiroResolvedVisualSurface),
            )
            .first;
        expect(
          tester
              .widget<YumeiroResolvedVisualSurface>(clearSurface)
              .appearance
              .background,
          theme.visuals.control(YumeiroControlRole.ghost, {}).background,
        );
        final clearBounds = tester.getRect(clear);
        expect(clearBounds.right, searchBounds.right);
        expect(clearBounds.center.dy, searchBounds.center.dy);
        expect(tester.getTopRight(clearQuery).dx, lessThan(clearBounds.left));
        expect(searchBounds.width, tester.getSize(fieldWidget).width);
        await tester.tap(clear);
        expect(field.currentState!.value, isEmpty);
        expect(changes.last, isEmpty);
        await tester.pumpAndSettle();
        expect(tester.getRect(search), searchBounds);
        expect(tester.widget<EditableText>(editor).controller.text, 'Bet');

        await tester.tap(_optionText('Beta'));
        await tester.pumpAndSettle();
        expect(field.currentState!.value, {'b'});
        expect(tester.getRect(search), searchBounds);

        await tester.tap(clearQuery);
        await tester.pumpAndSettle();
        expect(field.currentState!.value, {'b'});
        expect(_optionText('Alpha'), findsOneWidget);
      },
    );
  }

  testWidgets('selection list without search keeps its width and clear slot', (
    tester,
  ) async {
    for (final modality in YumeiroModality.values) {
      final pointer = modality == YumeiroModality.pointer;
      final direction = pointer ? TextDirection.ltr : TextDirection.rtl;
      await tester.pumpWidget(
        _host(
          modality,
          Directionality(
            textDirection: direction,
            child: Align(
              child: YumeiroSelectionList.multiForm<String>(
                label: 'Reviewers',
                width: pointer ? 210 : null,
                expand: false,
                clearable: true,
                options: _options,
              ),
            ),
          ),
        ),
      );

      final field = find.byType(YumeiroSelectionList<String>);
      final option = _optionText('Alpha');
      final panel = _inlineOptionPanel(option);
      final clear = find.descendant(
        of: field,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is YumeiroButton &&
              widget.semanticLabel == 'Clear, Reviewers',
        ),
      );
      final fieldBounds = tester.getRect(field);
      final initialPanel = tester.getRect(panel);
      expect(fieldBounds.width, pointer ? 210 : 240);
      expect(find.byType(EditableText), findsNothing);
      expect(clear, findsNothing);

      await tester.tap(option);
      await tester.pumpAndSettle();
      final clearBounds = tester.getRect(clear);
      expect(tester.getRect(panel), initialPanel);
      expect(tester.getRect(field), fieldBounds);
      if (direction == TextDirection.ltr) {
        expect(clearBounds.right, fieldBounds.right);
      } else {
        expect(clearBounds.left, fieldBounds.left);
      }

      await tester.tap(clear);
      await tester.pumpAndSettle();
      expect(clear, findsNothing);
      expect(tester.getRect(panel), initialPanel);
    }
  });

  testWidgets('narrow inline clear action stays inside the logical end', (
    tester,
  ) async {
    for (final direction in TextDirection.values) {
      await tester.pumpWidget(
        _host(
          YumeiroModality.touch,
          Directionality(
            textDirection: direction,
            child: YumeiroSelectionList.multiForm<String>(
              width: 120,
              label: 'Reviewers',
              searchable: true,
              clearable: true,
              initialValue: const {'a'},
              options: _options,
            ),
          ),
        ),
      );

      final searchField = find.byType(YumeiroTextField);
      final editor = find.descendant(
        of: searchField,
        matching: find.byType(EditableText),
      );
      await tester.enterText(editor, 'Bet');
      await tester.pumpAndSettle();
      final search = tester.getRect(searchField);
      final clear = tester.getRect(
        find.descendant(
          of: searchField,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is YumeiroButton &&
                widget.semanticLabel == 'Clear, Reviewers',
          ),
        ),
      );
      expect(clear.center.dy, search.center.dy);
      if (direction == TextDirection.ltr) {
        expect(clear.right, search.right);
      } else {
        expect(clear.left, search.left);
      }
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('a pending confirmation respects a reset and option refresh', (
    tester,
  ) async {
    final field = GlobalKey<FormFieldState<Set<String>>>();
    final available = ValueNotifier(_options);
    addTearDown(available.dispose);
    final changes = <Set<String>>[];
    await tester.pumpWidget(
      _host(
        YumeiroModality.touch,
        ValueListenableBuilder(
          valueListenable: available,
          builder: (context, options, _) => YumeiroMultiSelect.form(
            key: field,
            options: options,
            initialValue: const {'a'},
            onChanged: changes.add,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Alpha'));
    await tester.pumpAndSettle();
    await tester.tap(_optionText('Beta'));
    await tester.pumpAndSettle();
    field.currentState!.reset();
    await tester.pumpAndSettle();
    expect(find.byType(YumeiroBottomSheet), findsNothing);
    expect(field.currentState!.value, {'a'});
    expect(changes, isEmpty);

    await tester.tap(find.text('Alpha'));
    await tester.pumpAndSettle();
    await tester.tap(_optionText('Alpha'));
    await tester.tap(_optionText('Beta'));
    await tester.pumpAndSettle();
    available.value = [
      _options[0],
      const YumeiroSelectionOption(value: 'b', label: 'Beta', enabled: false),
      const YumeiroSelectionOption(value: 'd', label: 'Delta'),
    ];
    await tester.pumpAndSettle();
    final list = tester.widget<YumeiroSelectionList<String>>(
      find.byType(YumeiroSelectionList<String>),
    );
    expect(list.options[1].enabled, isFalse);
    expect(_optionText('Locked'), findsNothing);
    expect(_optionText('Delta'), findsOneWidget);
    await tester.tap(find.text('Confirm (0)'));
    await tester.pumpAndSettle();
    expect(field.currentState!.value, isEmpty);
    expect(changes.single, isEmpty);
  });

  testWidgets('pointer confirmation cannot apply a draft after form reset', (
    tester,
  ) async {
    final field = GlobalKey<FormFieldState<Set<String>>>();
    final changes = <Set<String>>[];
    await tester.pumpWidget(
      _host(
        YumeiroModality.pointer,
        YumeiroMultiSelect.form(
          key: field,
          options: _options,
          initialValue: const {'a'},
          onChanged: changes.add,
        ),
      ),
    );

    await tester.tap(find.text('Alpha'));
    await tester.pumpAndSettle();
    await tester.tap(_optionText('Beta'));
    await tester.pumpAndSettle();
    final confirm = _inField(find.text('Confirm (2)'));
    expect(confirm.hitTestable(), findsOneWidget);
    field.currentState!.reset();
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(field.currentState!.value, {'a'});
    expect(changes, isEmpty);
    expect(_pointerPopup(), findsNothing);
    expect(find.text('Alpha'), findsOneWidget);
  });

  for (final inline in [false, true]) {
    testWidgets('clearing unavailable choices works with inline = $inline', (
      tester,
    ) async {
      final field = GlobalKey<FormFieldState<Set<String>>>();
      final changes = <Set<String>>[];
      await tester.pumpWidget(
        _host(
          YumeiroModality.pointer,
          inline
              ? YumeiroSelectionList.multiForm<String>(
                  key: field,
                  label: 'Reviewers',
                  initialValue: const {'missing'},
                  clearable: true,
                  options: const [],
                  onChanged: changes.add,
                )
              : YumeiroMultiSelect.form<String>(
                  key: field,
                  label: 'Reviewers',
                  initialValue: const {'missing'},
                  clearable: true,
                  options: const [],
                  onChanged: changes.add,
                ),
        ),
      );
      final clear = find.byWidgetPredicate(
        (widget) =>
            widget is YumeiroButton &&
            widget.semanticLabel == 'Clear, Reviewers',
      );
      await tester.tap(clear);
      await tester.pumpAndSettle();
      expect(field.currentState!.value, isEmpty);
      expect(changes, [<String>{}]);
      expect(clear, findsNothing);
    });
  }

  testWidgets('authoritative options drop only missing values', (tester) async {
    final field = GlobalKey<FormFieldState<Set<String>>>();
    final available = ValueNotifier(_options);
    addTearDown(available.dispose);
    final changes = <Set<String>>[];
    await tester.pumpWidget(
      _host(
        YumeiroModality.pointer,
        ValueListenableBuilder(
          valueListenable: available,
          builder: (context, options, _) => YumeiroSelectionList.multiForm(
            key: field,
            options: options,
            searchable: true,
            initialValue: const {'a', 'c', 'unknown'},
            retainMissingValues: false,
            onChanged: changes.add,
          ),
        ),
      ),
    );
    expect(field.currentState!.value, {'a', 'c'});
    await tester.enterText(find.byType(EditableText), 'Beta');
    await tester.pumpAndSettle();
    expect(field.currentState!.value, {'a', 'c'});
    available.value = [_options[1], _options[2]];
    await tester.pump();
    expect(field.currentState!.value, {'c'});
    expect(changes, isEmpty);
    field.currentState!.reset();
    await tester.pump();
    expect(field.currentState!.value, {'c'});
    expect(changes, isEmpty);
  });

  testWidgets('inline form changes read the latest value before a rebuild', (
    tester,
  ) async {
    final field = GlobalKey<FormFieldState<Set<String>>>();
    await tester.pumpWidget(
      _host(
        YumeiroModality.pointer,
        YumeiroSelectionList.multiForm(key: field, options: _options),
      ),
    );

    await tester.tap(_optionText('Alpha'));
    await tester.tap(_optionText('Beta'));
    expect(field.currentState!.value, {'a', 'b'});
  });

  for (final modality in YumeiroModality.values) {
    testWidgets(
      'option refresh keeps eligible edits in a ${modality.name} draft',
      (tester) async {
        final field = GlobalKey<FormFieldState<Set<String>>>();
        final available = ValueNotifier(_options);
        addTearDown(available.dispose);
        final changes = <Set<String>>[];
        var formChanges = 0;
        await tester.pumpWidget(
          _host(
            modality,
            Form(
              onChanged: () => formChanges++,
              child: ValueListenableBuilder(
                valueListenable: available,
                builder: (context, options, _) => YumeiroMultiSelect.form(
                  key: field,
                  options: options,
                  initialValue: const {'a'},
                  retainMissingValues: false,
                  onChanged: changes.add,
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Alpha'));
        await tester.pumpAndSettle();
        await tester.tap(_optionText('Beta'));
        await tester.pumpAndSettle();

        available.value = [_options[1], _options[2]];
        await tester.pumpAndSettle();
        expect(_optionText('Alpha'), findsNothing);
        expect(field.currentState!.value, isEmpty);
        expect(formChanges, 0);
        expect(changes, isEmpty);
        final confirm = find.text('Confirm (1)');
        await tester.tap(
          modality == YumeiroModality.pointer ? _inField(confirm) : confirm,
        );
        await tester.pumpAndSettle();
        expect(field.currentState!.value, {'b'});
        expect(formChanges, 1);
        expect(changes, [
          {'b'},
        ]);
      },
    );
  }

  for (final width in [320.0, 112.0]) {
    testWidgets('search and confirm fit a $width field in a short viewport', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(660, 200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final changes = <Set<String>>[];
      await tester.pumpWidget(
        _host(
          YumeiroModality.pointer,
          YumeiroMultiSelect.form(
            label: 'Reviewers',
            placeholder: 'Choose reviewers',
            options: _options,
            width: width,
            searchable: true,
            onChanged: changes.add,
          ),
        ),
      );
      await tester.tap(find.text('Choose reviewers'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final search = _inField(find.byType(EditableText));
      final trigger = tester.getRect(_inField(find.byType(YumeiroTextField)));
      expect(
        tester.getRect(_pointerPopup()).width,
        closeTo(trigger.width, .01),
      );
      expect(_inPopup(find.byType(EditableText)), findsNothing);
      await tester.enterText(search, 'Bet');
      await tester.pumpAndSettle();
      expect(_optionText('Beta').hitTestable(), findsOneWidget);
      await tester.tap(_optionText('Beta'));
      await tester.pumpAndSettle();
      final action = find.byWidgetPredicate(
        (widget) =>
            widget is YumeiroButton &&
            (widget.label == 'Confirm (1)' || widget.tooltip == 'Confirm (1)'),
      );
      final confirm = _inField(action);
      expect(confirm.hitTestable(), findsOneWidget);
      expect(_inPopup(action), findsNothing);
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(changes, [
        {'b'},
      ]);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'multi-select search and confirm fit above a landscape keyboard',
    (tester) async {
      tester.view.physicalSize = const Size(800, 390);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final changes = <Set<String>>[];
      await tester.pumpWidget(
        _host(
          YumeiroModality.touch,
          YumeiroMultiSelect.form(
            label: 'Reviewers',
            options: _options,
            placeholder: 'Choose reviewers',
            searchable: true,
            onChanged: changes.add,
          ),
        ),
      );
      await tester.tap(find.text('Choose reviewers'));
      await tester.pumpAndSettle();
      final search = find.byType(EditableText);
      await tester.enterText(search, 'al');
      await tester.pumpAndSettle();
      final editor = tester.state<EditableTextState>(search);
      tester.view.viewInsets = const FakeViewPadding(bottom: 270);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(editor.widget.focusNode.hasFocus, isTrue);
      expect(editor.widget.controller.text, 'al');

      await tester.enterText(search, 'bet');
      await tester.pumpAndSettle();
      expect(_optionText('Beta').hitTestable(), findsOneWidget);
      await tester.tap(_optionText('Beta'));
      await tester.pumpAndSettle();
      expect(changes, isEmpty);
      final confirm = find.text('Confirm (1)').hitTestable();
      expect(confirm, findsOneWidget);
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(changes, [
        {'b'},
      ]);
      expect(tester.takeException(), isNull);
    },
  );
}

Finder _inField(Finder matching) => find.descendant(
  of: find.byType(YumeiroMultiSelect<String>),
  matching: matching,
);

Finder _pointerPopup() => find.byWidgetPredicate(
  (widget) =>
      widget is YumeiroVisualSurface &&
      widget.role == YumeiroSurfaceRole.floating,
);

Finder _inPopup(Finder matching) =>
    find.descendant(of: _pointerPopup(), matching: matching);

Finder _optionText(String label) => find.descendant(
  of: find.byType(YumeiroSelectionList<String>),
  matching: find.byWidgetPredicate(
    (widget) => widget is Text && widget.data == label,
  ),
);

Finder _inlineOptionPanel(Finder option) => find.ancestor(
  of: option,
  matching: find.descendant(
    of: find.byType(YumeiroSelectionList<String>),
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is YumeiroVisualSurface && widget.role is YumeiroSurfaceRole,
    ),
  ),
);

Widget _host(
  YumeiroModality modality,
  Widget child, {
  Locale locale = const Locale('en'),
}) => YumeiroApp(
  locale: locale,
  modality: modality,
  home: Scaffold(
    body: Center(child: SizedBox(width: 320, child: child)),
  ),
);
