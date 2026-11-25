import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';
import 'package:yumeiro_example/docs/form_controls_demo.dart';

void main() {
  testWidgets('the form opens its invalid disclosure and saves field values', (
    tester,
  ) async {
    await _pumpDemo(tester, const Locale('zh'));

    final range = find.byWidgetPredicate(
      (widget) => widget is FormField<DateTimeRange<DateTime>>,
    );
    final save = find.text('保存');
    final booleanFields = find.byWidgetPredicate(
      (widget) => widget is FormField<bool>,
    );
    final confirm = find.ancestor(
      of: find.byType(YumeiroCheckbox),
      matching: booleanFields,
    );
    final switchField = find.ancestor(
      of: find.byType(YumeiroSwitch),
      matching: booleanFields,
    );
    expect(range, findsNothing);
    await _tap(tester, save);
    expect(range, findsOneWidget);
    expect(find.text('请选择日期范围'), findsOneWidget);
    expect(find.text('请勾选此项'), findsOneWidget);

    final multiple = find.byType(YumeiroMultiSelect<String>);
    final setFields = find.byWidgetPredicate(
      (widget) => widget is FormField<Set<String>>,
    );
    final selected = tester.state<FormFieldState<Set<String>>>(
      find.ancestor(of: multiple, matching: setFields),
    );
    await _tap(
      tester,
      find.descendant(of: multiple, matching: find.text('选择选项')),
    );
    final sheet = find.byType(YumeiroBottomSheet);
    expect(sheet, findsOneWidget);
    final search = find.descendant(
      of: sheet,
      matching: find.byType(EditableText),
    );
    await tester.enterText(search, 'B');
    await tester.pumpAndSettle();
    await _tap(tester, find.descendant(of: sheet, matching: find.text('选项 B')));
    expect(selected.value, isEmpty);
    final confirmMultiple = YumeiroLocalizations.of(tester.element(sheet))
        .confirmWithCount(1);
    await _tap(
      tester,
      find.descendant(of: sheet, matching: find.text(confirmMultiple)),
    );
    expect(selected.value, {'B'});
    final inline = find.byWidgetPredicate(
      (widget) => widget is YumeiroSelectionList<String> && widget.multiple,
    );
    final inlineField = tester.state<FormFieldState<Set<String>>>(
      find.ancestor(of: inline, matching: setFields),
    );
    await _tap(
      tester,
      find.descendant(of: inline, matching: find.text('选项 C')),
    );
    expect(inlineField.value, {'C'});
    final searchable = find.byKey(
      const ValueKey('gallery-form-searchable-select'),
    );
    await _tap(
      tester,
      find.descendant(of: searchable, matching: find.text('筛选选项')),
    );
    await tester.enterText(search, 'H12');
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: sheet, matching: find.text('选项 H1')),
      findsNothing,
    );
    await _tap(
      tester,
      find.descendant(of: sheet, matching: find.text('选项 H12')),
    );
    expect(tester.state<FormFieldState<String>>(searchable).value, 'H12');
    await _tap(tester, find.text('搜索选项'));
    await _tap(tester, find.text('示例 A'));
    final period = tester.state<FormFieldState<DateTimeRange<DateTime>>>(range);
    period.didChange(
      DateTimeRange(start: DateTime(2026, 8, 7), end: DateTime(2026, 8, 8)),
    );
    await tester.pumpAndSettle();

    await _tap(
      tester,
      find.descendant(of: confirm, matching: find.byType(YumeiroCheckbox)),
    );
    await _tap(
      tester,
      find.descendant(of: switchField, matching: find.byType(YumeiroSwitch)),
    );
    await _tap(tester, save);
    expect(find.textContaining('已保存 · 选项 A · 选项 B'), findsOneWidget);
    expect(find.textContaining('字段 B ID 101'), findsOneWidget);
    expect(find.textContaining('字段 F 已开启'), findsOneWidget);
    expect(find.textContaining('字段 G 选项 C'), findsOneWidget);
    expect(find.textContaining('字段 H 选项 H12'), findsOneWidget);
    expect(find.text('请勾选此项'), findsNothing);

    await _tap(tester, find.text('重置'));
    expect(period.value, isNull);
    expect(selected.value, isEmpty);
    expect(inlineField.value, isEmpty);
    expect(tester.state<FormFieldState<String>>(searchable).value, isNull);
    expect(tester.state<FormFieldState<bool>>(confirm).value, isFalse);
    expect(tester.state<FormFieldState<bool>>(switchField).value, isFalse);
    expect(find.textContaining('已保存'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('remote field shows request states and refreshes by source', (
    tester,
  ) async {
    await _pumpDemo(tester, const Locale('en'));
    final trigger = find.text('Search options');
    await tester.ensureVisible(trigger);
    await tester.tap(trigger);
    await tester.pump();
    expect(find.byType(YumeiroSpinner), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Example A'), findsOneWidget);

    final search = find.byType(EditableText);
    await tester.enterText(search, 'zzzz');
    await tester.pumpAndSettle();
    expect(find.text('No matching items'), findsOneWidget);
    await tester.enterText(search, 'retry');
    await tester.pumpAndSettle();
    expect(find.text('Could not load options.'), findsOneWidget);
    await _tap(tester, find.text('Retry'));
    await _tap(tester, find.text('Example A'));

    final remoteField = find.byWidgetPredicate(
      (widget) => widget is FormField<YumeiroSelectionOption<int>>,
    );
    final state = tester.state<FormFieldState<YumeiroSelectionOption<int>>>(
      remoteField,
    );
    expect(state.value?.value, 101);
    final source = find.byWidgetPredicate(
      (widget) => widget is YumeiroSelect<Enum>,
    );
    await _tap(
      tester,
      find.descendant(of: source, matching: find.text('Option A')),
    );
    await _tap(
      tester,
      find.descendant(
        of: find.byType(YumeiroBottomSheet),
        matching: find.text('Option B'),
      ),
    );
    expect(state.value?.value, 101);

    await _tap(tester, find.text('Example A'));
    expect(find.text('Example C'), findsOneWidget);
    expect(find.text('Example B'), findsNothing);
    await _tap(tester, find.text('Example C'));
    expect(state.value?.value, 201);

    await _tap(tester, find.text('Reset'));
    expect(state.value, isNull);
    expect(trigger, findsOneWidget);
    expect(
      find.descendant(of: source, matching: find.text('Option A')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'pointer fields use aligned dropdowns for multiple and remote options',
    (tester) async {
      await _pumpDemo(
        tester,
        const Locale('en'),
        modality: YumeiroModality.pointer,
      );

      final multiple = find.byType(YumeiroMultiSelect<String>);
      final selected = tester.state<FormFieldState<Set<String>>>(
        find.ancestor(
          of: multiple,
          matching: find.byWidgetPredicate(
            (widget) => widget is FormField<Set<String>>,
          ),
        ),
      );
      await _tap(
        tester,
        find.descendant(of: multiple, matching: find.text('Choose options')),
      );
      expect(find.byType(YumeiroBottomSheet), findsNothing);
      final multipleInput = find.descendant(
        of: multiple,
        matching: find.byType(EditableText),
      );
      expect(multipleInput, findsOneWidget);
      expect(
        find.descendant(of: multiple, matching: find.text('Cancel')),
        findsOneWidget,
      );
      await tester.enterText(multipleInput, 'B');
      await tester.pumpAndSettle();
      await _tap(
        tester,
        find.descendant(
          of: find.byType(MenuItemButton),
          matching: find.text('Option B'),
        ),
      );
      expect(selected.value, isEmpty);
      await _tap(
        tester,
        find.descendant(of: multiple, matching: find.text('Confirm (1)')),
      );
      expect(selected.value, {'B'});
      expect(multipleInput, findsNothing);
      expect(
        find.descendant(of: multiple, matching: find.text('Option B')),
        findsOneWidget,
      );

      final source = find.byWidgetPredicate(
        (widget) => widget is YumeiroSelect<Enum>,
      );
      await _tap(
        tester,
        find.descendant(of: source, matching: find.text('Option A')),
      );
      await _tap(
        tester,
        find.descendant(
          of: find.byType(MenuItemButton),
          matching: find.text('Option B'),
        ),
      );
      final remote = find.byType(YumeiroAsyncSelect<int>);
      final field = find.descendant(
        of: remote,
        matching: find.byType(YumeiroTextField),
      );
      final input = find.descendant(
        of: remote,
        matching: find.byType(EditableText),
      );
      double chevronInset(Finder trigger) {
        final icons = YumeiroTheme.of(tester.element(trigger)).icons;
        final chevron = find.descendant(
          of: trigger,
          matching: find.byIcon(icons.chevronDown),
        );
        return tester.getRect(trigger).right - tester.getCenter(chevron).dx;
      }

      final trailingInset = chevronInset(source);
      expect(chevronInset(multiple), trailingInset);
      expect(chevronInset(field), trailingInset);
      final fieldWidth = tester.getSize(field).width;
      final results = find.byWidgetPredicate(
        (widget) =>
            widget is YumeiroVisualSurface &&
            widget.role == YumeiroSurfaceRole.floating,
      );
      await _tap(tester, input);
      expect(tester.getSize(results).width, fieldWidth);
      expect(find.byType(YumeiroBottomSheet), findsNothing);
      await tester.enterText(input, 'Example C');
      await tester.pumpAndSettle();
      await _tap(
        tester,
        find.descendant(of: results, matching: find.text('Example C')),
      );
      expect(tester.widget<YumeiroAsyncSelect<int>>(remote).value?.value, 201);
      expect(tester.getSize(field).width, fieldWidth);
      expect(chevronInset(field), trailingInset);
      await _tap(tester, input);
      expect(tester.getSize(results).width, fieldWidth);

      final clear = find.descendant(
        of: remote,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is YumeiroButton &&
              widget.semanticLabel == 'Clear, Field B',
        ),
      );
      await tester.tap(clear);
      await tester.pumpAndSettle();
      expect(tester.widget<YumeiroAsyncSelect<int>>(remote).value, isNull);
      expect(results, findsNothing);
      expect(tester.getSize(field).width, fieldWidth);
      expect(chevronInset(field), trailingInset);

      final searchable = find.byKey(
        const ValueKey('gallery-form-searchable-select'),
      );
      final localInput = find.descendant(
        of: searchable,
        matching: find.byType(EditableText),
      );
      await _tap(tester, localInput);
      await tester.enterText(localInput, 'H12');
      await tester.pumpAndSettle();
      expect(find.byType(YumeiroBottomSheet), findsNothing);
      expect(
        find.descendant(of: results, matching: find.text('Option H1')),
        findsNothing,
      );
      await _tap(
        tester,
        find.descendant(of: results, matching: find.text('Option H12')),
      );
      expect(tester.state<FormFieldState<String>>(searchable).value, 'H12');
    },
  );

  for (final modality in YumeiroModality.values) {
    testWidgets(
      'inline lists keep independent values and align the clear action in ${modality.name}',
      (tester) async {
        const form = ValueKey('form');
        const variants = ValueKey('selection-list');
        const picker = ValueKey('multi-select');
        await _pumpDemo(
          tester,
          const Locale('en'),
          modality: modality,
          builder: (context) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              KeyedSubtree(key: form, child: formControlsDemo(context)),
              KeyedSubtree(key: variants, child: selectionListDemo(context)),
              KeyedSubtree(key: picker, child: multiSelectDemo(context)),
            ],
          ),
        );

        Finder pickerIn(Key key) => find.descendant(
          of: find.byKey(key),
          matching: find.byType(YumeiroMultiSelect<String>),
        );
        Finder listIn({required bool multiple}) => find.descendant(
          of: find.byKey(variants),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is YumeiroSelectionList<String> &&
                widget.multiple == multiple,
          ),
        );
        final confirmation = pickerIn(picker);
        final single = listIn(multiple: false);
        final inline = listIn(multiple: true);
        final multiple = pickerIn(form);
        Finder option(String label) =>
            find.descendant(of: inline, matching: find.text(label));
        YumeiroMultiSelect<String> control(Finder finder) =>
            tester.widget<YumeiroMultiSelect<String>>(finder);
        Set<String> selection(Finder finder) =>
            tester.widget<YumeiroSelectionList<String>>(finder).values;

        expect(
          find.descendant(of: single, matching: find.byType(YumeiroTextField)),
          findsNothing,
        );
        await _tap(
          tester,
          find.descendant(of: single, matching: find.text('Option B')),
        );
        expect(selection(single), {'B'});
        expect(selection(inline), {'A'});
        expect(control(confirmation).value, {'Tag A', 'Tag B'});
        expect(control(multiple).value, isEmpty);

        final searchField = find.descendant(
          of: inline,
          matching: find.byType(YumeiroTextField),
        );
        final search = find.descendant(
          of: searchField,
          matching: find.byType(EditableText),
        );
        final card = find.descendant(
          of: inline,
          matching: find.byType(YumeiroCard),
        );
        expect(tester.getRect(card).left, tester.getRect(searchField).left);
        expect(tester.getRect(card).right, tester.getRect(searchField).right);
        await tester.ensureVisible(search);
        await tester.enterText(search, 'B');
        await tester.pumpAndSettle();
        expect(option('Option A'), findsNothing);
        expect(option('Option C'), findsNothing);
        await _tap(tester, option('Option B'));
        expect(selection(inline), {'A', 'B'});
        expect(control(multiple).value, isEmpty);
        expect(find.byType(YumeiroBottomSheet), findsNothing);
        expect(find.text('Confirm (2)'), findsNothing);

        final clear = find.descendant(
          of: searchField,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is YumeiroButton &&
                widget.semanticLabel == 'Clear, Multiple choices',
          ),
        );
        expect(tester.getRect(clear).right, tester.getRect(searchField).right);
        await _tap(tester, clear);
        expect(selection(inline), isEmpty);
        expect(selection(single), {'B'});
        expect(control(confirmation).value, {'Tag A', 'Tag B'});
        expect(control(multiple).value, isEmpty);
        expect(tester.widget<EditableText>(search).controller.text, 'B');

        final longList = find.descendant(
          of: find.byKey(variants),
          matching: find.byType(YumeiroSelectionList<int>),
        );
        final viewport = find.descendant(
          of: longList,
          matching: find.byType(Scrollable),
        );
        final page = tester.state<ScrollableState>(
          find.ancestor(
            of: find.byKey(variants),
            matching: find.byType(Scrollable),
          ),
        );
        await tester.ensureVisible(viewport);
        await tester.pumpAndSettle();
        final pageOffset = page.position.pixels;
        final last = find.descendant(
          of: longList,
          matching: find.text('Option 30'),
        );
        expect(last, findsNothing);
        await tester.scrollUntilVisible(last, 140, scrollable: viewport);
        expect(page.position.pixels, pageOffset);
        await _tap(tester, last);
        expect(tester.widget<YumeiroSelectionList<int>>(longList).values, {30});
        expect(selection(single), {'B'});
        expect(tester.takeException(), isNull);
      },
    );
  }
}

Future<void> _pumpDemo(
  WidgetTester tester,
  Locale locale, {
  YumeiroModality modality = YumeiroModality.touch,
  WidgetBuilder builder = formControlsDemo,
}) async {
  tester.view.physicalSize = modality == YumeiroModality.touch
      ? const Size(390, 844)
      : const Size(900, 860);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    YumeiroApp(
      modality: modality,
      locale: locale,
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Builder(builder: builder),
        ),
      ),
    ),
  );
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
