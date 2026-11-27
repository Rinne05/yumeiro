import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

void main() {
  testWidgets('opt-in box ordering keeps source indexes and row actions', (
    tester,
  ) async {
    const items = [40, 11, 60, 23, 12];
    final reorder = ValueNotifier(false);
    addTearDown(reorder.dispose);
    final activated = <int>[];
    final trailing = <int>[];
    final changes = <Set<Key>>[];
    await tester.pumpWidget(
      _host(
        ValueListenableBuilder(
          valueListenable: reorder,
          builder: (_, moveDisabledToEnd, _) => YumeiroDataTable<int>(
            items: items,
            minWidth: 0,
            rowKey: ValueKey<int>.new,
            selection: YumeiroTableSelection(
              mode: YumeiroTableSelectionMode.multiple,
              isItemEnabled: (item) => item < 40,
              onChanged: changes.add,
              moveDisabledToEnd: moveDisabledToEnd,
            ),
            onRowTap: activated.add,
            columns: [
              YumeiroTableColumn(
                title: 'Rows',
                cellBuilder: (_, item, index) => Text('Row $item/$index'),
              ),
            ],
            trailingColumns: [
              YumeiroTableColumn(
                fixedWidth: 128,
                cellBuilder: (_, item, index) => YumeiroButton(
                  label: 'Open $item/$index',
                  onPressed: () => trailing.add(item),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    expect(_displayedOrder(tester, items), items);

    reorder.value = true;
    await tester.pumpAndSettle();
    expect(_displayedOrder(tester, items), [11, 23, 12, 40, 60]);
    for (final (index, item) in items.indexed) {
      expect(find.text('Row $item/$index'), findsOneWidget);
      expect(find.text('Open $item/$index'), findsOneWidget);
    }

    await tester.tap(find.text('Row 60/2'));
    await tester.tap(find.text('Open 60/2'));
    expect(activated, [60]);
    expect(trailing, [60]);
    expect(changes, isEmpty);
  });

  testWidgets(
    'reordered sliver preserves keyed drafts and keyboard selection',
    (tester) async {
      const items = [1, 2, 3];
      final disabled = ValueNotifier<Set<int>>({});
      addTearDown(disabled.dispose);
      final changes = <Set<Key>>[];
      await tester.pumpWidget(
        _host(
          CustomScrollView(
            slivers: [
              ValueListenableBuilder(
                valueListenable: disabled,
                builder: (_, ineligible, _) => YumeiroDataTable<int>.sliver(
                  items: items,
                  variant: YumeiroTableVariant.compact,
                  rowKey: ValueKey<int>.new,
                  rowTapBehavior: YumeiroTableRowTapBehavior.none,
                  showSelectionIndicator: true,
                  selection: YumeiroTableSelection(
                    mode: YumeiroTableSelectionMode.single,
                    isItemEnabled: (item) => !ineligible.contains(item),
                    moveDisabledToEnd: true,
                    onChanged: changes.add,
                  ),
                  columns: [
                    YumeiroTableColumn(
                      cellBuilder: (_, item, index) => TextField(
                        key: ValueKey('editor-$item'),
                        decoration: InputDecoration(
                          labelText: 'Row $item/$index',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

      final field = find.byKey(const ValueKey('editor-1'));
      EditableText editor() => tester.widget(
        find.descendant(of: field, matching: find.byType(EditableText)),
      );
      await tester.enterText(field, 'draft');
      final original = editor();

      disabled.value = {1};
      await tester.pumpAndSettle();
      const displayOrder = [2, 3, 1];
      expect(_displayedOrder(tester, items), displayOrder);
      expect(tester.widget<TextField>(field).decoration!.labelText, 'Row 1/0');
      expect(editor().controller, same(original.controller));
      expect(editor().focusNode, same(original.focusNode));
      expect(editor().focusNode.hasFocus, isTrue);
      expect(editor().controller.text, 'draft');
      for (final (displayIndex, item) in displayOrder.indexed) {
        final indexed = tester.widget<IndexedSemantics>(
          find.descendant(
            of: find.byKey(ValueKey(item)),
            matching: find.byType(IndexedSemantics),
          ),
        );
        expect(indexed.index, displayIndex);
      }

      final firstRadio = tester.widget<Radio<dynamic>>(
        find.descendant(
          of: find.byKey(const ValueKey(2)),
          matching: find.byWidgetPredicate(
            (widget) => widget is Radio<dynamic>,
          ),
        ),
      );
      firstRadio.focusNode!.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(changes, [
        {const ValueKey(3)},
      ]);
    },
  );

  testWidgets('ordered sliver bulk selection covers unbuilt eligible rows', (
    tester,
  ) async {
    final items = List.generate(100, (index) => index);
    final built = <int>{};
    final checked = <int, int>{};
    final changes = <Set<Key>>[];
    final retained = {const ValueKey(-1), const ValueKey(1)};
    await tester.pumpWidget(
      _host(
        CustomScrollView(
          scrollCacheExtent: const ScrollCacheExtent.pixels(0),
          slivers: [
            YumeiroDataTable<int>.sliver(
              items: items,
              minWidth: 0,
              selection: YumeiroTableSelection(
                mode: YumeiroTableSelectionMode.multiple,
                isItemEnabled: (item) {
                  checked.update(item, (calls) => calls + 1, ifAbsent: () => 1);
                  return item.isEven;
                },
                moveDisabledToEnd: true,
                selectedKeys: retained,
                onChanged: changes.add,
              ),
              columns: [
                YumeiroTableColumn(
                  title: 'Rows',
                  cellBuilder: (_, item, index) {
                    built.add(item);
                    return Text('Row $item/$index');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
    expect(find.text('Row 2/2'), findsOneWidget);
    expect(find.text('Row 1/1'), findsNothing);
    expect(built, isNot(contains(98)));
    expect(checked, {for (final item in items) item: 1});

    await tester.tap(find.byType(YumeiroCheckbox).first);
    expect(changes, [
      {
        ...retained,
        for (final item in items.where((item) => item.isEven)) ValueKey(item),
      },
    ]);
  });
}

Widget _host(Widget child) => YumeiroApp(
  modality: YumeiroModality.pointer,
  home: Scaffold(
    body: Center(child: SizedBox(width: 440, height: 420, child: child)),
  ),
);

List<int> _displayedOrder(WidgetTester tester, List<int> items) =>
    List.of(items)..sort(
      (a, b) => tester
          .getCenter(find.byKey(ValueKey(a)))
          .dy
          .compareTo(tester.getCenter(find.byKey(ValueKey(b))).dy),
    );
