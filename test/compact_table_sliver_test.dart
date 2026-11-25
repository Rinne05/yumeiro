import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

typedef _Row = ({int id, String name});

Widget _host({required List<Widget> slivers, ScrollController? controller}) =>
    YumeiroApp(
      modality: YumeiroModality.pointer,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 440,
            height: 240,
            child: CustomScrollView(controller: controller, slivers: slivers),
          ),
        ),
      ),
    );

void main() {
  testWidgets(
    'sliver builds cells and evaluates eligibility near the viewport',
    (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      final rows = List.generate(1000, (index) => index);
      final built = <int>{};
      final checked = <int>{};
      var firstRowBuilds = 0;
      await tester.pumpWidget(
        _host(
          controller: controller,
          slivers: [
            YumeiroDataTable<int>.sliver(
              variant: YumeiroTableVariant.compact,
              items: rows,
              showSelectionIndicator: true,
              selection: YumeiroTableSelection(
                mode: YumeiroTableSelectionMode.multiple,
                onChanged: (_) {},
                isItemEnabled: (item) {
                  checked.add(item);
                  return item.isEven;
                },
              ),
              columns: [
                YumeiroTableColumn(
                  cellBuilder: (_, item, _) {
                    built.add(item);
                    if (item == 0) firstRowBuilds++;
                    return SizedBox(height: 28, child: Text('Row $item'));
                  },
                ),
              ],
            ),
          ],
        ),
      );

      expect(find.text('Row 0').hitTestable(), findsOneWidget);
      expect(built, contains(0));
      expect(checked, contains(0));
      expect(built.length, lessThan(30));
      expect(checked.difference(built), isEmpty);
      final buildsBeforeSmallScroll = firstRowBuilds;

      controller.jumpTo(8);
      await tester.pumpAndSettle();
      expect(find.text('Row 0').hitTestable(), findsOneWidget);
      expect(firstRowBuilds, buildsBeforeSmallScroll);

      final initiallyBuilt = Set<int>.of(built);
      final initiallyChecked = Set<int>.of(checked);

      controller.jumpTo(780);
      await tester.pumpAndSettle();

      expect(find.text('Row 0').hitTestable(), findsNothing);
      expect(built.difference(initiallyBuilt), isNotEmpty);
      expect(checked.difference(initiallyChecked), isNotEmpty);
      expect(built.length, lessThan(60));
      expect(checked.difference(built), isEmpty);
      expect(checked, isNot(contains(rows.last)));
    },
  );

  testWidgets('sliver aligns tracks like the box table with an absent cell', (
    tester,
  ) async {
    const rows = [1, 2];
    final columns = [
      YumeiroTableColumn<int>(
        cellBuilder: (_, item, _) =>
            Text('Name $item', key: ValueKey('name-$item')),
      ),
      YumeiroTableColumn<int>(
        preferredWidth: 90,
        alignment: AlignmentDirectional.centerEnd,
        cellBuilder: (_, item, _) =>
            Text(item == 1 ? '8 MB' : '15.2 GB', key: ValueKey('size-$item')),
      ),
    ];
    final secondary = [
      YumeiroTableColumn<int>(
        cellBuilder: (_, item, _) =>
            Text('Detail $item', key: ValueKey('detail-$item')),
      ),
    ];
    final trailing = [
      YumeiroTableColumn<int>(
        preferredWidth: 30,
        cellBuilder: (_, item, _) =>
            item == 1 ? null : const Icon(Icons.star, key: ValueKey('star-2')),
      ),
      YumeiroTableColumn<int>(
        preferredWidth: 60,
        cellBuilder: (_, item, _) => Text('Open', key: ValueKey('open-$item')),
      ),
    ];

    Rect cell(String key) => tester.getRect(find.byKey(ValueKey(key)));
    await tester.pumpWidget(
      _host(
        slivers: [
          SliverToBoxAdapter(
            child: YumeiroDataTable(
              variant: YumeiroTableVariant.compact,
              items: rows,
              columns: columns,
              additionalColumnBands: [secondary],
              trailingColumns: trailing,
            ),
          ),
        ],
      ),
    );
    final box = (
      name: cell('name-1').left,
      size: cell('size-1').right,
      detail: cell('detail-1').left,
      trailing: cell('open-1').left,
    );

    await tester.pumpWidget(
      _host(
        slivers: [
          YumeiroDataTable.sliver(
            variant: YumeiroTableVariant.compact,
            items: rows,
            columns: columns,
            additionalColumnBands: [secondary],
            trailingColumns: trailing,
          ),
        ],
      ),
    );
    for (final item in rows) {
      expect(cell('name-$item').left, closeTo(box.name, 0.01));
      expect(cell('size-$item').right, closeTo(box.size, 0.01));
      expect(cell('detail-$item').left, closeTo(box.detail, 0.01));
      expect(cell('detail-$item').top, greaterThan(cell('name-$item').top));
      expect(cell('open-$item').left, closeTo(box.trailing, 0.01));
    }
    expect(find.byKey(const ValueKey('star-1')), findsNothing);
    expect(find.byKey(const ValueKey('star-2')), findsOneWidget);
  });

  testWidgets('empty placeholder can share a viewport with other slivers', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        slivers: [
          const SliverToBoxAdapter(child: Text('Before')),
          YumeiroDataTable<int>.sliver(
            variant: YumeiroTableVariant.compact,
            items: const [],
            columns: [
              YumeiroTableColumn(
                cellBuilder: (_, _, _) =>
                    throw StateError('Empty table built a row'),
              ),
            ],
            emptyPlaceholder: const Text('No matching records'),
          ),
          const SliverToBoxAdapter(child: Text('After')),
        ],
      ),
    );

    final empty = find.text('No matching records');
    expect(empty, findsOneWidget);
    expect(
      tester.getTopLeft(empty).dy,
      greaterThan(tester.getTopLeft(find.text('Before')).dy),
    );
    expect(
      tester.getTopLeft(empty).dy,
      lessThan(tester.getTopLeft(find.text('After')).dy),
    );
    expect(find.byType(Scrollable), findsOneWidget);
  });

  testWidgets('an edited sliver cell keeps its identity when keyed rows move', (
    tester,
  ) async {
    final rows = ValueNotifier<List<_Row>>([
      (id: 1, name: 'Alpha'),
      (id: 2, name: 'Beta'),
    ]);
    addTearDown(rows.dispose);
    await tester.pumpWidget(
      _host(
        slivers: [
          ValueListenableBuilder(
            valueListenable: rows,
            builder: (_, items, _) => YumeiroDataTable<_Row>.sliver(
              variant: YumeiroTableVariant.compact,
              items: items,
              rowKey: (row) => ValueKey(row.id),
              columns: [
                YumeiroTableColumn(
                  cellBuilder: (_, row, _) => TextField(
                    decoration: InputDecoration(labelText: row.name),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    Finder input(String label) => find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.labelText == label,
    );
    EditableText editor(String label) => tester.widget(
      find.descendant(of: input(label), matching: find.byType(EditableText)),
    );

    await tester.enterText(input('Alpha'), 'draft');
    await tester.pump();
    final original = editor('Alpha');
    rows.value = [
      (id: 2, name: 'Beta'),
      (id: 1, name: 'Updated alpha'),
      (id: 3, name: 'Gamma'),
    ];
    await tester.pumpAndSettle();

    final updated = editor('Updated alpha');
    expect(updated.controller, same(original.controller));
    expect(updated.focusNode, same(original.focusNode));
    expect(updated.focusNode.hasFocus, isTrue);
    expect(updated.controller.text, 'draft');
    expect(editor('Gamma').controller.text, isEmpty);
  });

  testWidgets(
    'sliver row selection is controlled and trailing actions are independent',
    (tester) async {
      const locked = ValueKey(2);
      const hidden = ValueKey(99);
      final selected = ValueNotifier<Set<Key>>({locked, hidden});
      addTearDown(selected.dispose);
      final reports = <Set<Key>>[];
      final opened = <int>[];
      await tester.pumpWidget(
        _host(
          slivers: [
            ValueListenableBuilder(
              valueListenable: selected,
              builder: (_, selectedKeys, _) => YumeiroDataTable<int>.sliver(
                variant: YumeiroTableVariant.compact,
                items: const [1, 2],
                columns: [
                  YumeiroTableColumn(
                    cellBuilder: (_, item, _) => Text('Row $item'),
                  ),
                ],
                trailingColumns: [
                  YumeiroTableColumn(
                    preferredWidth: 96,
                    cellBuilder: (_, item, _) => YumeiroButton(
                      label: 'Open $item',
                      onPressed: () => opened.add(item),
                    ),
                  ),
                ],
                selection: YumeiroTableSelection(
                  mode: YumeiroTableSelectionMode.multiple,
                  selectedKeys: selectedKeys,
                  onChanged: reports.add,
                  isItemEnabled: (item) => item == 1,
                ),
                rowSemanticsLabel: (item) => 'Choose row $item',
              ),
            ),
          ],
        ),
      );

      void expectSelected(int item, bool selected) {
        expect(
          find.semantics.byLabel(RegExp('Choose row $item')).evaluate().single,
          isSemantics(hasCheckedState: true, isChecked: selected),
        );
      }

      expectSelected(1, false);
      expectSelected(2, true);

      await tester.tap(find.text('Row 2'));
      await tester.tap(find.text('Open 2'));
      await tester.pump();
      expect(reports, isEmpty);
      expect(opened, [2]);

      await tester.tap(find.text('Row 1'));
      await tester.pump();
      expect(reports, [
        {const ValueKey(1), locked, hidden},
      ]);
      expectSelected(1, false);

      selected.value = reports.single;
      await tester.pumpAndSettle();
      expectSelected(1, true);
      expectSelected(2, true);

      await tester.tap(find.text('Open 1'));
      await tester.pump();
      expect(opened, [2, 1]);
      expect(reports, hasLength(1));
    },
  );
}
