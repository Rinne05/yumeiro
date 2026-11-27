import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/src/components/layout/table_empty_message.dart';
import 'package:yumeiro/yumeiro.dart';

typedef _Row = ({int id, String title});

const _alphaKey = ValueKey(1);
const _betaKey = ValueKey(2);
const _lockedKey = ValueKey(3);
const _hiddenKey = ValueKey(99);
const _selectionMarkKey = ValueKey('yumeiro-table-selection-mark');
const _rows = [
  (id: 1, title: 'Alpha'),
  (id: 2, title: 'Beta'),
  (id: 3, title: 'Locked'),
];

void main() {
  for (final modality in YumeiroModality.values) {
    testWidgets('tables share selection surface insets in ${modality.name}', (
      tester,
    ) async {
      const dataTableKey = ValueKey('data-table');
      const compactTableKey = ValueKey('compact-table');
      const selectedFill = YumeiroSolidFill(Color(0xFFAB26D1));
      const resting = YumeiroVisualAppearance(
        fill: YumeiroSolidFill(Colors.transparent),
        foreground: Colors.black,
        shape: RoundedRectangleBorder(),
        transition: YumeiroVisualTransition.instant,
      );
      var opened = 0;
      final compactChanges = <Set<Key>>[];
      YumeiroTableSelection<_Row> selection(ValueChanged<Set<Key>> onChanged) =>
          YumeiroTableSelection(
            mode: YumeiroTableSelectionMode.multiple,
            selectedKeys: {_alphaKey},
            onChanged: onChanged,
          );

      await tester.pumpWidget(
        YumeiroApp(
          modality: modality,
          visualsAugmenter: (visuals, _, _) => visuals.extend(
            items: {
              YumeiroItemRole.selection: YumeiroVisualRecipe(
                base: resting,
                states: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? resting.copyWith(fill: selectedFill)
                      : null,
                ),
              ),
            },
          ),
          home: Scaffold(
            body: SizedBox(
              width: 520,
              child: Column(
                children: [
                  YumeiroDataTable<_Row>(
                    key: dataTableKey,
                    minWidth: 0,
                    items: [_rows.first],
                    rowKey: (row) => ValueKey(row.id),
                    columns: [
                      YumeiroTableColumn(
                        title: 'Name',
                        cellBuilder: (_, row, _) => Text(row.title),
                      ),
                    ],
                    compactRowBuilder: (_, row, _) => Text(row.title),
                    selection: selection((_) {}),
                    onRowTap: (_) => opened++,
                  ),
                  YumeiroDataTable<_Row>(
                    variant: YumeiroTableVariant.compact,
                    key: compactTableKey,
                    items: [_rows.first],
                    rowKey: (row) => ValueKey(row.id),
                    columns: [
                      YumeiroTableColumn(
                        cellBuilder: (_, row, _) => Text(row.title),
                      ),
                    ],
                    selection: selection(compactChanges.add),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (final tableKey in [dataTableKey, compactTableKey]) {
        final row = find.descendant(
          of: find.byKey(tableKey),
          matching: find.byKey(_alphaKey),
        );
        final surface = find.descendant(
          of: row,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is YumeiroResolvedVisualSurface &&
                widget.visualInsets == null &&
                widget.appearance.background == selectedFill.color,
          ),
        );
        final rowRect = tester.getRect(row);
        expect(tester.getRect(surface), rowRect.deflate(2));
        await tester.tapAt(Offset(rowRect.left + 1, rowRect.center.dy));
      }

      expect(opened, 1);
      expect(compactChanges, [<Key>{}]);
    });

    testWidgets('data table shows an empty message in ${modality.name} mode', (
      tester,
    ) async {
      Widget table({Widget? emptyPlaceholder}) => _host(
        modality: modality,
        child: YumeiroDataTable<_Row>(
          items: const [],
          columns: [
            YumeiroTableColumn(
              title: 'Name',
              cellBuilder: (_, row, _) => Text(row.title),
            ),
          ],
          compactRowBuilder: (_, row, _) => Text(row.title),
          selection: YumeiroTableSelection(
            mode: YumeiroTableSelectionMode.multiple,
            onChanged: (_) {},
          ),
          emptyPlaceholder: emptyPlaceholder,
        ),
      );

      await tester.pumpWidget(table());
      final tableContext = tester.element(find.byType(YumeiroDataTable<_Row>));
      final l10n = YumeiroLocalizations.of(tableContext);
      expect(find.text(l10n.emptyTable), findsOneWidget);
      final usesColumns = modality != YumeiroModality.touch;
      expect(find.text('Name'), usesColumns ? findsOneWidget : findsNothing);
      expect(
        find.byType(YumeiroCheckbox),
        usesColumns ? findsOneWidget : findsNothing,
      );

      await tester.pumpWidget(
        table(emptyPlaceholder: const Text('No matches')),
      );
      expect(find.text('No matches'), findsOneWidget);
      expect(find.text(l10n.emptyTable), findsNothing);
      expect(find.text('Name'), findsNothing);
    });

    testWidgets('tables share centered empty messages in ${modality.name}', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          modality: modality,
          child: SizedBox(
            width: 320,
            child: Column(
              children: [
                YumeiroDataTable<int>(
                  columns: [
                    YumeiroTableColumn(
                      title: 'Name',
                      cellBuilder: (_, item, _) => Text('$item'),
                    ),
                  ],
                  items: const [],
                  compactRowBuilder: (_, item, _) => Text('$item'),
                  minWidth: 0,
                ),
                const YumeiroDataTable<int>(
                  variant: YumeiroTableVariant.compact,
                  items: [],
                  columns: [],
                ),
                const SizedBox(
                  height: 140,
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(child: Text('Before')),
                      YumeiroDataTable<int>.sliver(
                        variant: YumeiroTableVariant.compact,
                        items: [],
                        columns: [],
                      ),
                      SliverToBoxAdapter(child: Text('After')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final emptyStates = find.byType(TableEmptyMessage);
      expect(emptyStates, findsNWidgets(3));
      final textStyles = <TextStyle?>[];
      for (var i = 0; i < 3; i++) {
        final state = emptyStates.at(i);
        final text = find.descendant(of: state, matching: find.byType(Text));
        expect(tester.getCenter(text).dx, tester.getCenter(state).dx);
        final label = tester.widget<Text>(text);
        expect(label.textAlign, TextAlign.center);
        textStyles.add(label.style);
      }
      expect(textStyles.toSet(), hasLength(1));
      expect(
        tester.getSize(emptyStates.at(1)),
        tester.getSize(emptyStates.at(2)),
      );
      if (modality == YumeiroModality.pointer) {
        expect(
          tester.getSize(emptyStates.first).height,
          greaterThan(tester.getSize(emptyStates.at(1)).height),
        );
      } else {
        expect(
          tester.getSize(emptyStates.first),
          tester.getSize(emptyStates.at(1)),
        );
      }
    });

    testWidgets('data table single selection is independent of row activation '
        'in ${modality.name} mode', (tester) async {
      var selected = <Key>{_alphaKey};
      final changes = <Set<Key>>[];
      final opened = <int>[];
      await tester.pumpWidget(
        _host(
          modality: modality,
          child: StatefulBuilder(
            builder: (_, setState) => _dataTable(
              selection: YumeiroTableSelection(
                mode: YumeiroTableSelectionMode.single,
                selectedKeys: selected,
                onChanged: (keys) {
                  changes.add(keys);
                  setState(() => selected = keys);
                },
                isItemEnabled: (row) => row.id != 3,
              ),
              onRowTap: (row) => opened.add(row.id),
            ),
          ),
        ),
      );

      final radios = find.byWidgetPredicate((widget) => widget is Radio);
      expect(radios, findsNWidgets(3));
      expect(find.byType(YumeiroCheckbox), findsNothing);

      await _tap(
        tester,
        find.text(modality == YumeiroModality.touch ? 'Compact Beta' : 'Beta'),
      );
      expect(opened, [2]);
      expect(changes, isEmpty);

      await _tap(tester, radios.at(1));
      expect(selected, {_betaKey});
      expect(changes, [
        {_betaKey},
      ]);
      expect(opened, [2]);

      await _tap(tester, radios.at(1));
      expect(changes, [
        {_betaKey},
      ]);
      expect(opened, [2]);

      await tester.tap(radios.last, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(changes, [
        {_betaKey},
      ]);
      expect(opened, [2]);

      final rawRadio = tester.widget<RawRadio<Object>>(
        find.descendant(
          of: radios.at(1),
          matching: find.byWidgetPredicate(
            (widget) => widget is RawRadio<Object>,
          ),
        ),
      );
      rawRadio.focusNode.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(selected, {_betaKey});
      expect(changes, [
        {_betaKey},
      ]);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(selected, {_alphaKey});
      expect(changes, [
        {_betaKey},
        {_alphaKey},
      ]);
      expect(opened, [2]);
    });

    testWidgets('data table select all preserves hidden and disabled keys '
        'in ${modality.name} mode', (tester) async {
      final initial = <Key>{_alphaKey, _lockedKey, _hiddenKey};
      var selected = initial;
      await tester.pumpWidget(
        _host(
          modality: modality,
          child: StatefulBuilder(
            builder: (_, setState) => _dataTable(
              selection: YumeiroTableSelection(
                mode: YumeiroTableSelectionMode.multiple,
                selectedKeys: selected,
                onChanged: (keys) => setState(() => selected = keys),
                isItemEnabled: (row) => row.id != 3,
              ),
            ),
          ),
        ),
      );

      final checkboxes = find.byType(YumeiroCheckbox);
      expect(checkboxes, findsNWidgets(4));
      bool? checkedAt(int index) =>
          tester.widget<YumeiroCheckbox>(checkboxes.at(index)).value;
      expect(checkedAt(0), isNull);

      await _tap(tester, checkboxes.first);
      expect(selected, {_alphaKey, _betaKey, _lockedKey, _hiddenKey});
      expect(checkedAt(0), isTrue);

      await _tap(tester, checkboxes.first);
      expect(selected, {_lockedKey, _hiddenKey});
      expect(checkedAt(0), isFalse);
      expect(checkedAt(3), isTrue);

      await _tap(tester, checkboxes.at(2));
      expect(selected, {_betaKey, _lockedKey, _hiddenKey});
      expect(checkedAt(0), isNull);
      expect(initial, {_alphaKey, _lockedKey, _hiddenKey});
    });

    testWidgets(
      'data table retains the focused cell across refresh and mode changes '
      'in ${modality.name} mode',
      (tester) async {
        final model =
            ValueNotifier<({List<_Row> rows, YumeiroTableSelectionMode? mode})>(
              (rows: _rows, mode: YumeiroTableSelectionMode.multiple),
            );
        addTearDown(model.dispose);
        Widget editor(_Row row) => TextField(
          decoration: InputDecoration(labelText: 'Edit ${row.title}'),
        );
        await tester.pumpWidget(
          _host(
            modality: modality,
            child: ValueListenableBuilder(
              valueListenable: model,
              builder: (_, value, _) => YumeiroDataTable<_Row>(
                items: value.rows,
                rowKey: (row) => ValueKey(row.id),
                selection: switch (value.mode) {
                  final mode? => YumeiroTableSelection(
                    mode: mode,
                    selectedKeys: {_alphaKey},
                  ),
                  null => null,
                },
                columns: [
                  YumeiroTableColumn(
                    title: 'Name',
                    cellBuilder: (_, row, _) => editor(row),
                  ),
                ],
                compactRowBuilder: (_, row, _) => editor(row),
              ),
            ),
          ),
        );

        Finder field(String title) => find.byWidgetPredicate(
          (widget) =>
              widget is TextField &&
              widget.decoration?.labelText == 'Edit $title',
        );
        EditableText editable(String title) => tester.widget(
          find.descendant(
            of: field(title),
            matching: find.byType(EditableText),
          ),
        );
        await tester.enterText(field('Alpha'), 'draft');
        await tester.pumpAndSettle();

        model.value = (
          rows: const [
            (id: 4, title: 'New row'),
            (id: 2, title: 'Beta'),
            (id: 1, title: 'Updated alpha'),
          ],
          mode: model.value.mode,
        );
        await tester.pumpAndSettle();

        expect(editable('Updated alpha').controller.text, 'draft');
        expect(editable('Updated alpha').focusNode.hasFocus, isTrue);
        expect(editable('New row').controller.text, isEmpty);
        final checkboxes = find.byType(YumeiroCheckbox);
        expect(tester.widget<YumeiroCheckbox>(checkboxes.last).value, isTrue);
        expect(tester.widget<YumeiroCheckbox>(checkboxes.at(1)).value, isFalse);

        for (final mode in [
          YumeiroTableSelectionMode.single,
          null,
          YumeiroTableSelectionMode.multiple,
        ]) {
          model.value = (rows: model.value.rows, mode: mode);
          await tester.pumpAndSettle();
          expect(editable('Updated alpha').controller.text, 'draft');
          expect(editable('Updated alpha').focusNode.hasFocus, isTrue);
        }
      },
    );
  }

  testWidgets(
    'table marks row-specific disabled states in the selection slot',
    (tester) async {
      final opened = <int>[];
      final changes = <Set<Key>>[];
      Widget table(YumeiroTableSelectionMode mode, {bool readOnly = false}) =>
          _host(
            child: _dataTable(
              selection: YumeiroTableSelection(
                mode: mode,
                selectedKeys: {_lockedKey},
                isItemEnabled: (row) => row.id == 1,
                onChanged: readOnly ? null : changes.add,
              ),
              onRowTap: (row) => opened.add(row.id),
            ),
          );

      for (final mode in YumeiroTableSelectionMode.values) {
        await tester.pumpWidget(table(mode));
        await tester.pumpAndSettle();
        expect(_selectionMarkIn(_alphaKey), findsNothing);
        expect(_selectionMarkIn(_betaKey), findsOneWidget);
        expect(_selectionMarkIn(_lockedKey), findsOneWidget);

        await tester.tapAt(tester.getCenter(_selectionMarkIn(_lockedKey)));
        await tester.pumpAndSettle();
        expect(opened, isEmpty);
        expect(changes, isEmpty);
        await _tap(tester, find.text('Locked'));
        expect(opened, [3]);
        opened.clear();

        await tester.pumpWidget(table(mode, readOnly: true));
        await tester.pumpAndSettle();
        expect(_selectionMarks(), findsNothing);
      }
    },
  );

  testWidgets('pixel table radios keep native keyboard and checked semantics', (
    tester,
  ) async {
    var selected = <Key>{_alphaKey};
    await tester.pumpWidget(
      YumeiroApp(
        preset: YumeiroThemePresets.pixelDark,
        modality: YumeiroModality.pointer,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (_, setState) => _dataTable(
              selection: YumeiroTableSelection(
                mode: YumeiroTableSelectionMode.single,
                selectedKeys: selected,
                isItemEnabled: (row) => row.id != 2,
                onChanged: (keys) => setState(() => selected = keys),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(_selectionMarks(), findsNWidgets(3));

    Finder radioIn(Key key) => find.descendant(
      of: find.byKey(key),
      matching: find.byWidgetPredicate((widget) => widget is RawRadio<Object>),
    );
    expect(
      tester.getSemantics(radioIn(_alphaKey)),
      isSemantics(hasCheckedState: true, isChecked: true),
    );
    expect(
      tester.getSemantics(radioIn(_betaKey)),
      isSemantics(
        hasCheckedState: true,
        hasEnabledState: true,
        isEnabled: false,
      ),
    );
    tester
        .widget<RawRadio<Object>>(radioIn(_alphaKey))
        .focusNode
        .requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(selected, {_lockedKey});
    expect(
      tester.getSemantics(radioIn(_lockedKey)),
      isSemantics(hasCheckedState: true, isChecked: true),
    );
  });

  testWidgets('table radio keeps keyboard focus through a preset switch', (
    tester,
  ) async {
    final changes = <Set<Key>>[];
    final home = Scaffold(
      body: _dataTable(
        selection: YumeiroTableSelection(
          mode: YumeiroTableSelectionMode.single,
          selectedKeys: {_alphaKey},
          onChanged: changes.add,
        ),
      ),
    );
    Future<void> show(YumeiroThemePreset preset) async {
      await tester.pumpWidget(
        YumeiroApp(
          preset: preset,
          modality: YumeiroModality.pointer,
          home: home,
        ),
      );
      await tester.pumpAndSettle();
    }

    FocusNode radioFocus(Key rowKey) => tester
        .widget<RawRadio<Object>>(
          find.descendant(
            of: find.byKey(rowKey),
            matching: find.byWidgetPredicate(
              (widget) => widget is RawRadio<Object>,
            ),
          ),
        )
        .focusNode;

    await show(YumeiroThemePresets.classicDark);
    final originalFocus = radioFocus(_alphaKey)..requestFocus();
    await tester.pump();
    expect(originalFocus.hasPrimaryFocus, isTrue);

    for (final preset in [
      YumeiroThemePresets.pixelDark,
      YumeiroThemePresets.classicDark,
    ]) {
      await show(preset);
      expect(radioFocus(_alphaKey), same(originalFocus));
      expect(originalFocus.hasPrimaryFocus, isTrue);
    }

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(changes, [
      {_betaKey},
    ]);
    expect(radioFocus(_betaKey).hasPrimaryFocus, isTrue);
  });

  testWidgets('compact tables show disabled marks only with a selection slot', (
    tester,
  ) async {
    final changes = <Set<Key>>[];
    Widget table({required bool showIndicator}) => _host(
      modality: YumeiroModality.touch,
      child: YumeiroDataTable<_Row>(
        variant: YumeiroTableVariant.compact,
        items: _rows,
        rowKey: (row) => ValueKey(row.id),
        showSelectionIndicator: showIndicator,
        selection: YumeiroTableSelection(
          mode: YumeiroTableSelectionMode.multiple,
          isItemEnabled: (row) => row.id != 3,
          onChanged: changes.add,
        ),
        compactRowBuilder: (_, row, _) => Text(row.title),
        columns: const [],
      ),
    );

    await tester.pumpWidget(table(showIndicator: false));
    await tester.pumpAndSettle();
    expect(_selectionMarks(), findsNothing);
    await tester.pumpWidget(table(showIndicator: true));
    await tester.pumpAndSettle();
    expect(_selectionMarkIn(_lockedKey), findsOneWidget);

    await tester.tapAt(tester.getCenter(find.text('Locked')));
    await tester.pumpAndSettle();
    expect(changes, isEmpty);
    await _tap(tester, find.text('Beta'));
    expect(changes, [
      {_betaKey},
    ]);
  });

  testWidgets(
    'compact table shares selection modes and keeps actions independent',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final mode = ValueNotifier<YumeiroTableSelectionMode?>(
        YumeiroTableSelectionMode.single,
      );
      addTearDown(mode.dispose);
      var selected = <Key>{_alphaKey};
      final changes = <Set<Key>>[];
      final actions = <int>[];
      await tester.pumpWidget(
        _host(
          child: StatefulBuilder(
            builder: (_, setState) => ValueListenableBuilder(
              valueListenable: mode,
              builder: (_, value, _) => YumeiroDataTable<_Row>(
                variant: YumeiroTableVariant.compact,
                items: _rows,
                rowKey: (row) => ValueKey(row.id),
                selection: value == null
                    ? null
                    : YumeiroTableSelection(
                        mode: value,
                        selectedKeys: selected,
                        onChanged: (keys) {
                          changes.add(keys);
                          setState(() => selected = keys);
                        },
                        isItemEnabled: (row) => row.id != 3,
                      ),
                rowSemanticsLabel: (row) => 'Choose ${row.title}',
                columns: [
                  YumeiroTableColumn(
                    cellBuilder: (_, row, _) => Text(row.title),
                  ),
                ],
                trailingColumns: [
                  YumeiroTableColumn(
                    preferredWidth: 140,
                    cellBuilder: (_, row, _) => YumeiroButton(
                      label: 'Open ${row.title}',
                      onPressed: () => actions.add(row.id),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await _tap(tester, find.text('Alpha'));
      await _tap(tester, find.text('Locked'));
      expect(changes, isEmpty);

      await _tap(tester, find.text('Beta'));
      expect(changes, [
        {_betaKey},
      ]);
      final beta = find.semantics.byLabel(RegExp('Choose Beta'));
      expect(
        beta.evaluate().single,
        isSemantics(
          hasCheckedState: true,
          isChecked: true,
          isInMutuallyExclusiveGroup: true,
        ),
      );

      await _tap(tester, find.text('Open Beta'));
      expect(actions, [2]);
      expect(changes, [
        {_betaKey},
      ]);

      mode.value = YumeiroTableSelectionMode.multiple;
      await tester.pumpAndSettle();
      await _tap(tester, find.text('Alpha'));
      expect(selected, {_alphaKey, _betaKey});
      await _tap(tester, find.text('Beta'));
      expect(selected, {_alphaKey});
      expect(
        beta.evaluate().single,
        isSemantics(
          hasCheckedState: true,
          isChecked: false,
          isInMutuallyExclusiveGroup: false,
        ),
      );

      mode.value = null;
      await tester.pumpAndSettle();
      await _tap(tester, find.text('Beta'));
      expect(changes, [
        {_betaKey},
        {_alphaKey, _betaKey},
        {_alphaKey},
      ]);
      semantics.dispose();
    },
  );

  testWidgets(
    'compact table keeps editable cells when selection mode changes',
    (tester) async {
      final mode = ValueNotifier<YumeiroTableSelectionMode?>(null);
      addTearDown(mode.dispose);
      await tester.pumpWidget(
        _host(
          child: ValueListenableBuilder(
            valueListenable: mode,
            builder: (_, value, _) => YumeiroDataTable<String>(
              variant: YumeiroTableVariant.compact,
              items: const ['file'],
              showSelectionIndicator: true,
              selection: value == null
                  ? null
                  : YumeiroTableSelection(mode: value, onChanged: (_) {}),
              columns: [
                YumeiroTableColumn(cellBuilder: (_, _, _) => const TextField()),
              ],
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'draft');
      await tester.pumpAndSettle();

      for (final value in [
        YumeiroTableSelectionMode.single,
        YumeiroTableSelectionMode.multiple,
        null,
      ]) {
        mode.value = value;
        await tester.pumpAndSettle();
        final editor = tester.widget<EditableText>(find.byType(EditableText));
        expect(editor.controller.text, 'draft');
        expect(editor.focusNode.hasFocus, isTrue);
      }
    },
  );
}

Widget _host({
  required Widget child,
  YumeiroModality modality = YumeiroModality.pointer,
}) => YumeiroApp(
  modality: modality,
  home: Scaffold(body: child),
);

Finder _selectionMarks() => find.byWidgetPredicate(
  (widget) =>
      widget is CustomPaint &&
      widget.key == _selectionMarkKey &&
      widget.foregroundPainter != null,
);

Finder _selectionMarkIn(Key rowKey) =>
    find.descendant(of: find.byKey(rowKey), matching: _selectionMarks());

YumeiroDataTable<_Row> _dataTable({
  required YumeiroTableSelection<_Row> selection,
  ValueChanged<_Row>? onRowTap,
}) => YumeiroDataTable<_Row>(
  items: _rows,
  rowKey: (row) => ValueKey(row.id),
  selection: selection,
  onRowTap: onRowTap,
  columns: [
    YumeiroTableColumn(
      title: 'Name',
      cellBuilder: (_, row, _) => Text(row.title),
    ),
  ],
  compactRowBuilder: (_, row, _) => Text('Compact ${row.title}'),
);

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
