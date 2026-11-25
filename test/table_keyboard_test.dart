import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/src/components/layout/table_keyboard.dart';
import 'package:yumeiro/src/components/layout/table_selection.dart'
    show TableRadioIndex;
import 'package:yumeiro/yumeiro.dart';

void main() {
  testWidgets('arrows skip disabled row bodies and leave cell input alone', (
    tester,
  ) async {
    final keys = List.generate(4, ValueKey.new);
    final changes = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TableKeyboard(
            rowKeys: keys,
            toggleFor: (index) => index == 1 ? null : () => changes.add(index),
            child: Column(
              children: [
                for (var i = 0; i < keys.length; i++)
                  TableKeyboardTarget(
                    rowKey: keys[i],
                    builder: (focus) => Row(
                      children: [
                        InkWell(
                          key: keys[i],
                          focusNode: focus,
                          onTap: i == 1 ? null : () {},
                          child: Text('Row $i'),
                        ),
                        if (i == 2)
                          const SizedBox(width: 100, child: TextField()),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    FocusNode node(int index) =>
        tester.widget<InkWell>(find.byKey(keys[index])).focusNode!;

    node(0).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    expect(changes, isEmpty);
    expect(node(0).hasPrimaryFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(changes, [2]);
    expect(node(2).hasPrimaryFocus, isTrue);

    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    expect(changes, [2]);
  });

  testWidgets('radio arrows reach unbuilt variable-height sliver rows', (
    tester,
  ) async {
    final keys = List.generate(30, ValueKey.new);
    final updates = <Set<Key>>[];
    final vertical = ScrollController();
    addTearDown(vertical.dispose);

    bool enabled(int index) => index == 0 || index == 23;
    await tester.pumpWidget(
      YumeiroApp(
        modality: YumeiroModality.pointer,
        home: Scaffold(
          body: SizedBox(
            height: 175,
            width: 260,
            child: CustomScrollView(
              controller: vertical,
              scrollCacheExtent: const ScrollCacheExtent.pixels(0),
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 50)),
                YumeiroDataTable<int>.sliver(
                  items: List.generate(keys.length, (index) => index),
                  rowKey: (index) => keys[index],
                  pinnedHeader: true,
                  selection: YumeiroTableSelection(
                    mode: YumeiroTableSelectionMode.single,
                    selectedKeys: {keys[0]},
                    isItemEnabled: enabled,
                    onChanged: updates.add,
                  ),
                  columns: [
                    YumeiroTableColumn(
                      title: 'Name',
                      cellBuilder: (_, item, _) => SizedBox(
                        height: 32 + 13.0 * (item % 4),
                        child: Text('Row $item'),
                      ),
                    ),
                  ],
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 200)),
              ],
            ),
          ),
        ),
      ),
    );

    Finder radio(int index) => find.descendant(
      of: find.byKey(keys[index]),
      matching: find.byType(Radio<TableRadioIndex>),
    );
    Radio<TableRadioIndex> control(int index) =>
        tester.widget<Radio<TableRadioIndex>>(radio(index));
    FocusNode node(int index) => control(index).focusNode!;
    ScrollPosition horizontal(int index) => Scrollable.of(
      tester.element(radio(index)),
      axis: Axis.horizontal,
    ).position;

    expect(radio(23), findsNothing);
    horizontal(0).jumpTo(10);
    node(0).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();

    expect(updates, [
      {keys[23]},
    ]);
    expect(radio(23).hitTestable(), findsOneWidget);
    expect(node(23).hasPrimaryFocus, isTrue);
    expect(horizontal(23).pixels, 10);
    expect(control(23).groupRegistry!.groupValue, isNull);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(updates, [
      {keys[23]},
    ]);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(updates, [
      {keys[23]},
    ]);
    expect(radio(0).hitTestable(), findsOneWidget);
    expect(node(0).hasPrimaryFocus, isTrue);
  });

  testWidgets(
    'sliver radios share a Tab stop and leave cell actions reachable',
    (tester) async {
      final cell = FocusNode();
      final after = FocusNode();
      addTearDown(cell.dispose);
      addTearDown(after.dispose);
      await tester.pumpWidget(
        YumeiroApp(
          modality: YumeiroModality.pointer,
          home: Scaffold(
            body: Column(
              children: [
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      YumeiroDataTable<int>.sliver(
                        items: const [0, 1, 2],
                        selection: YumeiroTableSelection(
                          mode: YumeiroTableSelectionMode.single,
                          selectedKeys: {const ValueKey(1)},
                          onChanged: (_) {},
                        ),
                        columns: [
                          YumeiroTableColumn(
                            title: 'Name',
                            cellBuilder: (_, item, _) => item == 2
                                ? TextButton(
                                    onPressed: () {},
                                    focusNode: cell,
                                    child: const Text('Open'),
                                  )
                                : Text('Row $item'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  focusNode: after,
                  child: const Text('After'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final selected = tester
          .widget<Radio<TableRadioIndex>>(
            find.descendant(
              of: find.byKey(const ValueKey(1)),
              matching: find.byType(Radio<TableRadioIndex>),
            ),
          )
          .focusNode!;
      for (final node in [selected, cell, after]) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        expect(node.hasPrimaryFocus, isTrue);
      }
    },
  );

  for (final sliver in [false, true]) {
    testWidgets(
      'table arrows stop at the first and last row (sliver=$sliver)',
      (tester) async {
        final changes = <Set<Key>>[];
        var selected = <Key>{const ValueKey(0)};
        await tester.pumpWidget(
          YumeiroApp(
            modality: YumeiroModality.pointer,
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  final createTable = sliver
                      ? YumeiroDataTable<int>.sliver
                      : YumeiroDataTable<int>.new;
                  final table = createTable(
                    items: const [0, 1, 2],
                    columns: [
                      YumeiroTableColumn(
                        title: 'Name',
                        cellBuilder: (_, item, _) => Text('Row $item'),
                      ),
                    ],
                    selection: YumeiroTableSelection(
                      mode: YumeiroTableSelectionMode.single,
                      selectedKeys: selected,
                      isItemEnabled: (item) => item != 1,
                      onChanged: (keys) {
                        changes.add(keys);
                        setState(() => selected = keys);
                      },
                    ),
                  );
                  return sliver ? CustomScrollView(slivers: [table]) : table;
                },
              ),
            ),
          ),
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pumpAndSettle();
        expect(changes, isEmpty);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        expect(changes, [
          {const ValueKey(2)},
        ]);
      },
    );
  }
}
