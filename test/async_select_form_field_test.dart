import 'dart:async';

import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

const _alpha = YumeiroSelectionOption(value: 1, label: 'Alpha');
const _beta = YumeiroSelectionOption(
  value: 2,
  label: 'Beta',
  trailingIcon: Icons.bolt,
);
const _locked = YumeiroSelectionOption(
  value: 3,
  label: 'Locked',
  enabled: false,
);
typedef _Options = List<YumeiroSelectionOption<int>>;

void main() {
  for (final modality in YumeiroModality.values) {
    testWidgets('remote selection validates, saves, clears and resets in '
        '${modality.name}', (tester) async {
      final form = GlobalKey<FormState>();
      final field = GlobalKey<FormFieldState<YumeiroSelectionOption<int>>>();
      final queries = <String>[];
      final changes = <int?>[];
      final saved = <int?>[];
      await tester.pumpWidget(
        _app(
          Form(
            key: form,
            child: YumeiroAsyncSelect.form(
              key: field,
              label: 'Entity',
              placeholder: 'Choose an entity',
              clearable: true,
              loadOptions: (query) async {
                queries.add(query);
                return [_beta, _locked];
              },
              validator: (option) => option == null ? 'Select an entity' : null,
              onChanged: (option) => changes.add(option?.value),
              onSaved: (option) => saved.add(option?.value),
            ),
          ),
          modality: modality,
        ),
      );
      expect(form.currentState!.validate(), isFalse);
      await tester.pumpAndSettle();
      expect(find.text('Select an entity'), findsOneWidget);
      await tester.tap(
        modality == YumeiroModality.pointer
            ? find.byType(EditableText)
            : find.text('Choose an entity'),
      );
      await tester.pumpAndSettle();
      expect(queries, ['']);
      expect(find.byIcon(Icons.bolt).hitTestable(), findsOneWidget);
      await tester.tap(find.text('Locked'));
      await tester.pumpAndSettle();
      expect(changes, isEmpty);
      await tester.tap(find.text('Beta'));
      await tester.pumpAndSettle();
      expect(find.byType(YumeiroBottomSheet), findsNothing);
      expect(_pointerPopup, findsNothing);
      expect(find.text('Beta'), findsOneWidget);
      expect(field.currentState!.value, _beta);
      expect(form.currentState!.validate(), isTrue);
      form.currentState!.save();
      expect(saved, [2]);

      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is YumeiroButton &&
              widget.semanticLabel == 'Clear, Entity',
        ),
      );
      await tester.pumpAndSettle();
      expect(field.currentState!.value, isNull);
      expect(changes, [2, null]);
      field.currentState!.didChange(_alpha);
      await tester.pumpAndSettle();
      expect(find.text('Alpha'), findsOneWidget);
      form.currentState!.reset();
      await tester.pumpAndSettle();
      expect(find.text('Choose an entity'), findsOneWidget);
      expect(changes, [2, null]);
    });

    testWidgets('read-only remote selection keeps focus in ${modality.name}', (
      tester,
    ) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      final queries = <String>[];
      final changes = <YumeiroSelectionOption<int>?>[];
      await tester.pumpWidget(
        _app(
          YumeiroAsyncSelect<int>(
            value: _alpha,
            focusNode: focus,
            autofocus: true,
            readOnly: true,
            clearable: true,
            loadOptions: (query) async {
              queries.add(query);
              return [_beta];
            },
            onChanged: changes.add,
          ),
          modality: modality,
        ),
      );
      await tester.pumpAndSettle();

      expect(focus.hasPrimaryFocus, isTrue);
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.byTooltip('Clear'), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(queries, isEmpty);
      expect(changes, isEmpty);
      expect(_pointerPopup, findsNothing);
      expect(find.byType(YumeiroBottomSheet), findsNothing);
    });
  }

  testWidgets('loading, retry, empty and outdated remote responses', (
    tester,
  ) async {
    final requests = <(String, Completer<_Options>)>[];
    await tester.pumpWidget(
      _app(
        YumeiroAsyncSelect.form(
          placeholder: 'Choose an entity',
          loadErrorText: 'Could not load entities',
          debounce: const Duration(milliseconds: 250),
          loadOptions: (query) {
            final request = Completer<_Options>();
            requests.add((query, request));
            return request.future;
          },
        ),
      ),
    );
    await tester.tap(find.byType(EditableText));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(YumeiroSpinner), findsOneWidget);
    expect(requests.single.$1, '');
    requests.single.$2.completeError(StateError('internal error'));
    await tester.pumpAndSettle();
    expect(find.text('Could not load entities'), findsOneWidget);
    expect(
      tester.widget<YumeiroCallout>(find.byType(YumeiroCallout)).statusRole,
      YumeiroStatusRole.danger,
    );
    expect(find.text('internal error'), findsNothing);
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(requests.last.$1, '');
    requests.last.$2.complete([]);
    await tester.pumpAndSettle();
    expect(find.text('No matching items'), findsOneWidget);

    final input = find.byType(EditableText);
    await tester.enterText(input, 'slow');
    await tester.pump(const Duration(milliseconds: 250));
    final slow = requests.last;
    expect(slow.$1, 'slow');
    await tester.enterText(input, '  fast  ');
    await tester.pump(const Duration(milliseconds: 100));
    slow.$2.complete([_alpha]);
    await tester.pump();
    expect(find.text('Alpha'), findsNothing);
    expect(find.byType(YumeiroSpinner), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 150));
    final fast = requests.last;
    expect(fast.$1, 'fast');

    await tester.enterText(input, 'newer');
    await tester.pump(const Duration(milliseconds: 250));
    expect(requests.last.$1, 'newer');
    requests.last.$2.complete([_beta]);
    await tester.pumpAndSettle();
    fast.$2.completeError(StateError('stale failure'));
    await tester.pumpAndSettle();
    expect(find.text('Beta'), findsOneWidget);
    expect(find.text('Could not load entities'), findsNothing);
  });

  testWidgets('controlled pointer search keeps focus and commits by keyboard', (
    tester,
  ) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    final choices = <YumeiroSelectionOption<int>?>[];
    final queries = <String>[];
    await tester.pumpWidget(
      _app(
        YumeiroAsyncSelect<int>(
          value: _alpha,
          focusNode: focus,
          searchHint: 'Filter entities',
          debounce: Duration.zero,
          loadOptions: (query) async {
            queries.add(query);
            return [_alpha, _locked, _beta];
          },
          onChanged: choices.add,
        ),
      ),
    );

    await tester.tap(
      find.descendant(
        of: find.byType(YumeiroTextField),
        matching: find.byType(Icon),
      ),
    );
    await tester.pumpAndSettle();
    final editor = find.byType(EditableText);
    expect(editor, findsOneWidget);
    expect(_pointerPopup, findsOneWidget);
    expect(focus.hasPrimaryFocus, isTrue);
    expect(tester.widget<EditableText>(editor).controller.text, isEmpty);
    expect(queries, ['']);

    await tester.enterText(editor, '  bet  ');
    await tester.pumpAndSettle();
    expect(queries, ['', 'bet']);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(choices, [_beta]);
    expect(_pointerPopup, findsNothing);
    expect(tester.widget<EditableText>(editor).controller.text, 'Alpha');
    expect(focus.hasPrimaryFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(_pointerPopup, findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(_pointerPopup, findsNothing);
    expect(tester.widget<EditableText>(editor).controller.text, 'Alpha');
    expect(choices, [_beta]);
  });

  testWidgets('pointer search closes when its field scrolls out of view', (
    tester,
  ) async {
    final scroll = ScrollController();
    final focus = FocusNode();
    addTearDown(scroll.dispose);
    addTearDown(focus.dispose);
    await tester.pumpWidget(
      _app(
        SizedBox(
          height: 160,
          child: SingleChildScrollView(
            controller: scroll,
            child: Column(
              children: [
                YumeiroAsyncSelect<int>(
                  value: null,
                  focusNode: focus,
                  loadOptions: (_) async => [_alpha],
                  onChanged: (_) {},
                ),
                const SizedBox(height: 300),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();
    expect(_pointerPopup, findsOneWidget);

    scroll.jumpTo(180);
    await tester.pumpAndSettle();
    expect(_pointerPopup, findsNothing);
    expect(focus.hasFocus, isFalse);
  });

  testWidgets('pointer navigation scrolls the highlighted result into view', (
    tester,
  ) async {
    final choices = <YumeiroSelectionOption<int>?>[];
    await tester.pumpWidget(
      _app(
        YumeiroAsyncSelect<int>(
          value: null,
          loadOptions: (_) async => [
            for (var index = 0; index < 20; index++)
              YumeiroSelectionOption(value: index, label: 'Result $index'),
          ],
          onChanged: choices.add,
        ),
      ),
    );
    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();
    expect(find.text('Result 13').hitTestable(), findsNothing);
    for (var index = 0; index < 13; index++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
    }

    expect(find.text('Result 13').hitTestable(), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(choices.single?.value, 13);
    expect(_pointerPopup, findsNothing);
  });

  testWidgets(
    'reset dismisses an open remote picker and preserves initial value',
    (tester) async {
      final field = GlobalKey<FormFieldState<YumeiroSelectionOption<int>>>();
      final load = Completer<_Options>();
      final changes = <YumeiroSelectionOption<int>?>[];
      await tester.pumpWidget(
        _app(
          YumeiroAsyncSelect.form(
            key: field,
            initialValue: _alpha,
            loadOptions: (_) => load.future,
            onChanged: changes.add,
          ),
        ),
      );
      await tester.tap(find.text('Alpha'));
      await tester.pump();
      expect(_pointerPopup, findsOneWidget);
      field.currentState!.reset();
      await tester.pump();
      load.complete([_beta]);
      await tester.pumpAndSettle();
      expect(_pointerPopup, findsNothing);
      expect(find.text('Alpha'), findsOneWidget);
      expect(field.currentState!.value, _alpha);
      expect(changes, isEmpty);
    },
  );

  testWidgets('changing source closes the picker and retains committed value', (
    tester,
  ) async {
    final field = GlobalKey<FormFieldState<YumeiroSelectionOption<int>>>();
    final configuration = ValueNotifier((source: 1, rebuild: 0));
    addTearDown(configuration.dispose);
    final load = Completer<_Options>();
    final requests = <(int, int)>[];
    final changes = <int?>[];
    await tester.pumpWidget(
      _app(
        ValueListenableBuilder(
          valueListenable: configuration,
          builder: (context, config, _) => YumeiroAsyncSelect.form(
            key: field,
            sourceKey: config.source,
            initialValue: _alpha,
            loadOptions: (_) {
              requests.add((config.source, config.rebuild));
              return config.source == 1 ? load.future : Future.value([_beta]);
            },
            onChanged: (option) => changes.add(option?.value),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Alpha'));
    await tester.pump();
    configuration.value = (source: 1, rebuild: 1);
    await tester.pump();
    expect(_pointerPopup, findsOneWidget);
    expect(requests, [(1, 0)]);

    configuration.value = (source: 2, rebuild: 0);
    await tester.pump();
    load.complete([
      const YumeiroSelectionOption(value: 4, label: 'Previous source'),
    ]);
    await tester.pumpAndSettle();
    expect(_pointerPopup, findsNothing);
    expect(find.text('Previous source'), findsNothing);
    expect(field.currentState!.value, _alpha);
    expect(changes, isEmpty);

    await tester.tap(find.text('Alpha'));
    await tester.pumpAndSettle();
    expect(requests, [(1, 0), (2, 0)]);
    await tester.tap(find.text('Beta'));
    await tester.pumpAndSettle();
    expect(field.currentState!.value, _beta);
    expect(changes, [2]);
  });

  for (final layout in [
    (viewport: 800.0, parent: 520.0, field: null, trigger: 520.0, popup: 520.0),
    (
      viewport: 800.0,
      parent: 440.0,
      field: 420.0,
      trigger: 420.0,
      popup: 420.0,
    ),
    (
      viewport: 800.0,
      parent: 440.0,
      field: 124.0,
      trigger: 124.0,
      popup: 124.0,
    ),
    (viewport: 280.0, parent: 320.0, field: null, trigger: 280.0, popup: 264.0),
  ]) {
    testWidgets('remote popup follows the ${layout.trigger}-wide trigger', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(layout.viewport, 650));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _app(
          Center(
            child: SizedBox(
              width: layout.parent,
              child: YumeiroAsyncSelect.form(
                width: layout.field,
                expand: layout.field == null,
                loadOptions: (_) async => [_beta],
              ),
            ),
          ),
        ),
      );
      final field = find.byType(YumeiroTextField);
      expect(tester.getSize(field).width, closeTo(layout.trigger, .01));
      await tester.tap(field);
      await tester.pumpAndSettle();
      expect(tester.getSize(_pointerPopup).width, closeTo(layout.popup, .01));
      expect(find.text('Beta').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('retry remains usable in a narrow remote popup', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(
      _app(
        Center(
          child: YumeiroAsyncSelect.form(
            width: 112,
            loadErrorText: 'Could not load entities',
            loadOptions: (_) async {
              if (++attempts == 1) throw StateError('offline');
              return [_beta];
            },
          ),
        ),
      ),
    );
    await tester.tap(find.byType(YumeiroTextField));
    await tester.pumpAndSettle();
    expect(find.text('Could not load entities'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Beta').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final height in [200.0, 600.0]) {
    testWidgets('remote search stays usable in a $height-high viewport', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(660, height));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final choices = <int?>[];
      await tester.pumpWidget(
        _app(
          Center(
            child: SizedBox(
              width: 300,
              child: YumeiroAsyncSelect.form(
                placeholder: 'Choose an entity',
                debounce: Duration.zero,
                loadOptions: (query) async =>
                    query.isEmpty ? [_alpha] : [_beta],
                onChanged: (option) => choices.add(option?.value),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();
      final trigger = tester.getRect(find.byType(YumeiroTextField));
      expect(find.byType(EditableText), findsOneWidget);
      expect(find.byType(YumeiroBottomSheet), findsNothing);
      final popup = tester.getRect(_pointerPopup);
      expect(
        popup.bottom <= trigger.top || popup.top >= trigger.bottom,
        isTrue,
      );
      expect(popup.top, greaterThanOrEqualTo(0));
      expect(popup.bottom, lessThanOrEqualTo(height));
      expect(tester.takeException(), isNull);
      expect(find.text('Alpha').hitTestable(), findsOneWidget);

      await tester.enterText(find.byType(EditableText), 'b');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Beta'));
      await tester.pumpAndSettle();
      expect(choices, [2]);
    });
  }

  testWidgets('remote search and selection fit above a landscape keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final choices = <int?>[];
    await tester.pumpWidget(
      _app(
        Center(
          child: SizedBox(
            width: 260,
            child: YumeiroAsyncSelect.form(
              placeholder: 'Choose an entity',
              debounce: Duration.zero,
              loadOptions: (query) async => query == 'be' ? [_beta] : [_alpha],
              onChanged: (option) => choices.add(option?.value),
            ),
          ),
        ),
        modality: YumeiroModality.touch,
      ),
    );
    await tester.tap(find.text('Choose an entity'));
    await tester.pumpAndSettle();
    final search = find.byType(EditableText);
    await tester.enterText(search, 'a');
    await tester.pumpAndSettle();
    final editor = tester.state<EditableTextState>(search);
    tester.view.viewInsets = const FakeViewPadding(bottom: 270);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.state<EditableTextState>(search), same(editor));
    expect(editor.widget.focusNode.hasFocus, isTrue);
    expect(editor.widget.controller.text, 'a');

    await tester.enterText(search, 'be');
    await tester.pumpAndSettle();
    final result = find.byType(YumeiroSelectionRow).hitTestable();
    expect(result, findsOneWidget);
    expect(find.text('Beta').hitTestable(), findsOneWidget);
    await tester.tap(result);
    await tester.pumpAndSettle();
    expect(choices, [2]);
    expect(tester.takeException(), isNull);
  });
}

final _pointerPopup = find.byWidgetPredicate(
  (widget) =>
      widget is YumeiroVisualSurface &&
      widget.role == YumeiroSurfaceRole.floating,
);

Widget _app(
  Widget child, {
  YumeiroModality modality = YumeiroModality.pointer,
}) => YumeiroApp(
  locale: const Locale('en'),
  modality: modality,
  home: Scaffold(body: child),
);
