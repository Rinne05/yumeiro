import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

void main() {
  testWidgets('headed sliver shares column widths and selects offscreen rows', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.binding.setSurfaceSize(const Size(400, 320));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final vertical = ScrollController();
    addTearDown(vertical.dispose);
    final keys = ValueNotifier<Set<Key>>({const ValueKey(-1)});
    addTearDown(keys.dispose);
    final items = List.generate(120, (i) => i);
    final built = <int>{};
    final toggled = <int>[];
    await tester.pumpWidget(
      YumeiroApp(
        modality: YumeiroModality.pointer,
        home: Scaffold(
          body: ValueListenableBuilder(
            valueListenable: keys,
            builder: (_, selected, _) => CustomScrollView(
              controller: vertical,
              slivers: [
                YumeiroDataTable<int>.sliver(
                  items: items,
                  minWidth: 680,
                  pinnedHeader: true,
                  rowTapBehavior: YumeiroTableRowTapBehavior.select,
                  selection: YumeiroTableSelection(
                    mode: YumeiroTableSelectionMode.multiple,
                    selectedKeys: selected,
                    onChanged: (value) => keys.value = value,
                    isItemEnabled: (item) => item != 3,
                  ),
                  columns: [
                    YumeiroTableColumn(
                      title: 'Main',
                      fixedWidth: 350,
                      cellBuilder: (_, item, _) {
                        built.add(item);
                        return Text('Row $item');
                      },
                    ),
                  ],
                  additionalColumnBands: [
                    [
                      YumeiroTableColumn(
                        title: 'Detail',
                        cellBuilder: (_, item, _) => Text('Detail $item'),
                      ),
                    ],
                    [
                      YumeiroTableColumn(
                        title: 'More',
                        cellBuilder: (_, item, _) => Text('More $item'),
                      ),
                    ],
                  ],
                  trailingColumns: [
                    YumeiroTableColumn(
                      title: 'Action',
                      headerAlignment: AlignmentDirectional.centerEnd,
                      alignment: AlignmentDirectional.centerEnd,
                      preferredWidth: 80,
                      cellBuilder: (_, item, _) => YumeiroButton(
                        label: 'Open $item',
                        onPressed: () => toggled.add(item),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(built.length, lessThan(25));
    expect(find.text('Row 119'), findsNothing);
    expect(
      tester.getTopLeft(find.text('More 0')).dy,
      greaterThan(tester.getTopLeft(find.text('Detail 0')).dy),
    );
    await tester.tap(find.byType(YumeiroCheckbox).first);
    await tester.pumpAndSettle();
    expect(keys.value, {
      const ValueKey(-1),
      for (final item in items)
        if (item != 3) ValueKey(item),
    });

    await tester.drag(find.text('Main'), const Offset(-430, 0));
    await tester.pumpAndSettle();
    expect(find.text('Action').hitTestable(), findsOneWidget);
    expect(find.text('Open 0').hitTestable(), findsOneWidget);
    await tester.tap(find.text('Open 0'));
    await tester.pumpAndSettle();
    expect(toggled, [0]);
    expect(keys.value, contains(const ValueKey(0)));

    vertical.jumpTo(1240);
    await tester.pumpAndSettle();
    expect(find.text('Action').hitTestable(), findsOneWidget);
    expect(find.text('Open 0').hitTestable(), findsNothing);
    expect(find.textContaining('Open ').hitTestable(), findsWidgets);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('resizing and hiding the header preserve a mounted cell draft', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(820, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final header = ValueNotifier(true);
    addTearDown(header.dispose);
    final columns = [
      YumeiroTableColumn<int>(
        title: 'Editable',
        cellBuilder: (_, _, _) => const TextField(),
      ),
    ];
    await tester.pumpWidget(
      YumeiroApp(
        home: Scaffold(
          body: ValueListenableBuilder(
            valueListenable: header,
            builder: (_, showHeader, _) => CustomScrollView(
              slivers: [
                YumeiroDataTable<int>.sliver(
                  items: const [1],
                  columns: columns,
                  showHeader: showHeader,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'draft');
    await tester.pumpAndSettle();
    EditableText editor() => tester.widget(find.byType(EditableText));
    final focus = editor().focusNode;

    await tester.binding.setSurfaceSize(const Size(450, 360));
    await tester.pumpAndSettle();
    expect(editor().controller.text, 'draft');
    expect(editor().focusNode, same(focus));
    expect(focus.hasFocus, isTrue);

    header.value = false;
    await tester.pumpAndSettle();
    expect(find.text('Editable'), findsNothing);
    expect(editor().controller.text, 'draft');
    expect(editor().focusNode, same(focus));

    await tester.binding.setSurfaceSize(const Size(820, 360));
    await tester.pumpAndSettle();
    expect(editor().controller.text, 'draft');
    expect(editor().focusNode, same(focus));
    expect(focus.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });
}
