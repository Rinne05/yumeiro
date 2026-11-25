import 'dart:ui' as ui;

import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/semantics.dart' show SemanticsNode;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

void main() {
  for (final lazy in [false, true]) {
    testWidgets('read-only compact table groups labeled cells (sliver=$lazy)', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      var inspected = 0;
      const items = ['Video', 'Cover'];
      final columns = [
        YumeiroTableColumn<String>(
          title: 'File',
          cellBuilder: (_, item, _) => Text(item),
        ),
      ];
      final secondary = [
        YumeiroTableColumn<String>(
          title: 'Status',
          cellBuilder: (_, _, _) => const Text('Ready'),
        ),
      ];
      final trailing = [
        YumeiroTableColumn<String>(
          preferredWidth: 100,
          cellBuilder: (_, item, _) => YumeiroButton(
            label: 'Inspect $item',
            onPressed: () => inspected++,
          ),
        ),
      ];
      await tester.pumpWidget(
        _host(
          width: 520,
          child: lazy
              ? SizedBox(
                  height: 280,
                  child: CustomScrollView(
                    slivers: [
                      YumeiroDataTable.sliver(
                        variant: YumeiroTableVariant.compact,
                        items: items,
                        columns: columns,
                        additionalColumnBands: [secondary],
                        trailingColumns: trailing,
                      ),
                    ],
                  ),
                )
              : YumeiroDataTable(
                  variant: YumeiroTableVariant.compact,
                  items: items,
                  columns: columns,
                  additionalColumnBands: [secondary],
                  trailingColumns: trailing,
                ),
        ),
      );
      SemanticsNode? table = tester.getSemantics(find.text('Video'));
      while (table != null && table.role != ui.SemanticsRole.table) {
        table = table.parent;
      }
      expect(table, isNotNull);
      final rows = _semanticChildren(table!);
      expect(rows.map((row) => row.role), [
        ui.SemanticsRole.row,
        ui.SemanticsRole.row,
      ]);
      if (lazy) expect(rows.map((row) => row.indexInParent), [0, 1]);
      final cells = _semanticChildren(rows.first);
      expect(
        cells.map((cell) => cell.role),
        List.filled(3, ui.SemanticsRole.cell),
      );
      expect(cells.first.label, contains('File'));
      expect(cells.first.label, contains('Video'));
      expect(cells[1].label, contains('Status'));
      expect(cells[1].label, contains('Ready'));
      tester.semantics.tap(find.semantics.byLabel('Inspect Video'));
      expect(inspected, 1);
      semantics.dispose();
    });
  }

  testWidgets('headerless rows share columns even with an absent action', (
    tester,
  ) async {
    await tester.pumpWidget(_host(width: 520, child: _table()));

    expect(find.text('File size'), findsNothing);
    expect(find.text('Status'), findsNothing);
    expect(_rect(tester, 'name-video').left, _rect(tester, 'name-cover').left);
    expect(
      _rect(tester, 'size-video').right,
      _rect(tester, 'size-cover').right,
    );
    expect(
      _rect(tester, 'status-video').left,
      _rect(tester, 'status-cover').left,
    );
    expect(find.byKey(const ValueKey('open-cover')), findsNothing);
    expect(
      _rect(tester, 'notify-video').left,
      _rect(tester, 'notify-cover').left,
    );
    expect(
      _rect(tester, 'open-video').right,
      lessThan(_rect(tester, 'notify-video').left),
    );
    expect(
      tester.semantics.find(find.byKey(const ValueKey('size-video'))).label,
      allOf(contains('File size'), contains('1.42 GB')),
    );
  });

  testWidgets('explicit row arrangement stays independent of the table width', (
    tester,
  ) async {
    await tester.pumpWidget(_host(width: 380, child: _table()));

    expect(
      _rect(tester, 'size-video').center.dy,
      inInclusiveRange(
        _rect(tester, 'name-video').top,
        _rect(tester, 'name-video').bottom,
      ),
    );
    expect(
      _rect(tester, 'notify-video').left,
      greaterThan(_rect(tester, 'status-video').right),
    );

    for (final width in [380.0, 520.0]) {
      await tester.pumpWidget(
        _host(width: width, child: _table(stacked: true)),
      );

      expect(
        _rect(tester, 'size-video').top,
        greaterThanOrEqualTo(_rect(tester, 'name-video').bottom),
      );
      expect(
        _rect(tester, 'size-video').right,
        lessThan(_rect(tester, 'status-video').left),
      );
      expect(
        _rect(tester, 'notify-video').center.dy,
        inInclusiveRange(
          _rect(tester, 'name-video').top,
          _rect(tester, 'size-video').bottom,
        ),
      );
      expect(
        _rect(tester, 'notify-video').left,
        greaterThan(_rect(tester, 'status-video').right),
      );
    }

    await tester.pumpWidget(
      _host(
        width: 160,
        child: YumeiroDataTable(
          variant: YumeiroTableVariant.compact,
          items: const ['video'],
          columns: [
            YumeiroTableColumn(
              preferredWidth: 120,
              cellBuilder: (_, _, _) => const SizedBox(
                key: ValueKey('first-fixed-cell'),
                width: 120,
                height: 12,
              ),
            ),
            YumeiroTableColumn(
              preferredWidth: 80,
              cellBuilder: (_, _, _) => const SizedBox(
                key: ValueKey('second-fixed-cell'),
                width: 80,
                height: 12,
              ),
            ),
          ],
        ),
      ),
    );
    final first = _rect(tester, 'first-fixed-cell');
    final second = _rect(tester, 'second-fixed-cell');
    expect(first.center.dy, second.center.dy);
    expect(first.right, lessThan(second.left));
    expect(first.width / second.width, closeTo(1.5, 0.001));
    expect(second.right, lessThanOrEqualTo(_rect(tester, 'table').right));

    expect(find.byType(Scrollable), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'row selection and actions have independent pointer and keyboard activation',
    (tester) async {
      final events = <String>[];
      final selected = ValueNotifier<Set<Key>>({const ValueKey('cover')});
      addTearDown(selected.dispose);
      await tester.pumpWidget(
        _host(
          width: 520,
          child: ValueListenableBuilder(
            valueListenable: selected,
            builder: (_, keys, _) => _table(
              showSelectionIndicator: true,
              selection: YumeiroTableSelection(
                mode: YumeiroTableSelectionMode.single,
                selectedKeys: keys,
                onChanged: (changedKeys) {
                  final key = changedKeys.single as ValueKey<String>;
                  events.add('select:${key.value}');
                  selected.value = changedKeys;
                },
                isItemEnabled: (item) => item != 'cover',
              ),
              onAction: (item, action) => events.add('$action:$item'),
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('choice-cover')), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(events, ['select:video']);
      expect(find.byKey(const ValueKey('choice-video')), findsOneWidget);
      expect(find.byKey(const ValueKey('choice-cover')), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(events, ['select:video', 'open:video']);

      selected.value = {const ValueKey('cover')};
      await tester.pumpAndSettle();
      final rowName = find.byKey(const ValueKey('name-video'));
      final selectionTarget = find.ancestor(
        of: rowName,
        matching: find.byType(InkWell),
      );
      final leadingPadding = Offset(
        _rect(tester, 'table').left + 4,
        tester.getCenter(rowName).dy,
      );
      expect(leadingPadding.dx, lessThan(tester.getTopLeft(rowName).dx));
      expect(tester.getRect(selectionTarget).contains(leadingPadding), isTrue);
      await tester.tapAt(leadingPadding);

      await tester.tap(find.byKey(const ValueKey('name-cover')));
      await tester.tap(find.byKey(const ValueKey('notify-cover')));
      await tester.pumpAndSettle();
      expect(events, [
        'select:video',
        'open:video',
        'select:video',
        'notify:cover',
      ]);
      expect(selected.value, {const ValueKey('video')});
    },
  );

  testWidgets('selectable rows can name an independent semantics node', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final events = <String>[];
    await tester.pumpWidget(
      _host(
        width: 520,
        child: YumeiroDataTable<String>(
          variant: YumeiroTableVariant.compact,
          items: const ['video', 'cover'],
          showSelectionIndicator: true,
          selection: YumeiroTableSelection(
            mode: YumeiroTableSelectionMode.single,
            selectedKeys: {const ValueKey('video')},
            onChanged: (keys) {
              final key = keys.single as ValueKey<String>;
              events.add('select:${key.value}');
            },
          ),
          rowSemanticsLabel: (item) => 'Choose $item',
          columns: [
            YumeiroTableColumn(
              cellBuilder: (_, item, _) => Semantics(
                container: true,
                child: Text(item == 'video' ? 'Video track' : 'Cover art'),
              ),
            ),
          ],
          trailingColumns: [
            YumeiroTableColumn(
              preferredWidth: 100,
              cellBuilder: (_, item, _) => item == 'video'
                  ? YumeiroButton(
                      label: 'Inspect',
                      onPressed: () => events.add('inspect'),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );

    final row = find.semantics.byLabel('Choose video');
    final action = find.semantics.byLabel('Inspect');
    expect(
      row.evaluate().single,
      isSemantics(
        hasCheckedState: true,
        isChecked: true,
        isInMutuallyExclusiveGroup: true,
        hasTapAction: true,
      ),
    );
    expect(find.semantics.byLabel('Video track'), findsOne);
    expect(
      action.evaluate().single,
      isSemantics(hasCheckedState: false, hasTapAction: true),
    );
    tester.semantics.tap(action);
    tester.semantics.tap(find.semantics.byLabel('Choose cover'));
    expect(events, ['inspect', 'select:cover']);
    semantics.dispose();
  });

  for (final modality in YumeiroModality.values) {
    testWidgets(
      'native indicators center over both bands in ${modality.name}',
      (tester) async {
        final selected = ValueNotifier<Set<Key>>({});
        addTearDown(selected.dispose);
        var inspected = 0;
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(
          _host(
            width: 520,
            modality: modality,
            child: ValueListenableBuilder(
              valueListenable: selected,
              builder: (_, keys, _) => YumeiroDataTable<String>(
                variant: YumeiroTableVariant.compact,
                items: const ['video', 'cover'],
                showSelectionIndicator: true,
                selection: YumeiroTableSelection(
                  mode: YumeiroTableSelectionMode.multiple,
                  selectedKeys: keys,
                  onChanged: (value) => selected.value = value,
                  isItemEnabled: (item) => item == 'video',
                ),
                rowSemanticsLabel: (item) => 'Choose $item',
                columns: [
                  YumeiroTableColumn(
                    cellBuilder: (_, item, _) => Text('Title $item'),
                  ),
                ],
                additionalColumnBands: [
                  [
                    YumeiroTableColumn(
                      cellBuilder: (_, item, _) => Text('Details $item'),
                    ),
                  ],
                ],
                trailingColumns: [
                  YumeiroTableColumn(
                    preferredWidth: 100,
                    cellBuilder: (_, item, _) => SizedBox(
                      height: 88,
                      child: Center(
                        child: YumeiroButton(
                          label: 'Inspect $item',
                          onPressed: () => inspected++,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        final row = find.byKey(const ValueKey('video'));
        final marker = find.descendant(
          of: row,
          matching: find.byType(YumeiroCheckbox),
        );
        final title = tester.getRect(find.text('Title video'));
        final detail = tester.getRect(find.text('Details video'));
        final indicator = tester.getRect(marker);
        expect(indicator.center.dy, tester.getCenter(row).dy);
        expect(indicator.center.dy, greaterThan(title.center.dy));
        expect(indicator.center.dy, lessThan(detail.center.dy));
        expect(indicator.right, lessThanOrEqualTo(title.left));
        expect(title.left, detail.left);

        await tester.tapAt(indicator.center);
        await tester.pumpAndSettle();
        expect(selected.value, {const ValueKey('video')});
        expect(
          find.semantics.byLabel(RegExp('Choose video')).evaluate().single,
          isSemantics(
            hasCheckedState: true,
            isChecked: true,
            hasTapAction: true,
          ),
        );

        await tester.tapAt(tester.getCenter(find.byType(YumeiroCheckbox).last));
        await tester.tap(find.text('Inspect cover'));
        await tester.pumpAndSettle();
        expect(selected.value, {const ValueKey('video')});
        expect(inspected, 1);
        semantics.dispose();
      },
    );
  }

  testWidgets(
    'editable cells follow their row after insertion and reordering',
    (tester) async {
      final items = ValueNotifier<List<String>>(['video', 'cover']);
      addTearDown(items.dispose);
      await tester.pumpWidget(
        _host(
          width: 520,
          child: ValueListenableBuilder(
            valueListenable: items,
            builder: (_, value, _) => YumeiroDataTable<String>(
              variant: YumeiroTableVariant.compact,
              items: value,
              columns: [
                YumeiroTableColumn(
                  cellBuilder: (_, item, _) => TextField(
                    decoration: InputDecoration(labelText: 'Edit $item'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      Finder edit(String item) => find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'Edit $item',
      );
      EditableText editable(String item) => tester.widget(
        find.descendant(of: edit(item), matching: find.byType(EditableText)),
      );

      await tester.enterText(edit('video'), 'draft');
      await tester.pumpAndSettle();
      items.value = ['subtitles', 'cover', 'video'];
      await tester.pumpAndSettle();

      expect(editable('video').controller.text, 'draft');
      expect(editable('video').focusNode.hasFocus, isTrue);
      expect(editable('subtitles').controller.text, isEmpty);
    },
  );

  testWidgets('provided row keys match a selection after item values refresh', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        width: 520,
        child: YumeiroDataTable<({int id, String title})>(
          variant: YumeiroTableVariant.compact,
          items: const [
            (id: 2, title: 'Cover'),
            (id: 1, title: 'Updated video'),
          ],
          rowKey: (item) => ValueKey(item.id),
          selection: YumeiroTableSelection(
            mode: YumeiroTableSelectionMode.single,
            selectedKeys: {const ValueKey(1)},
            onChanged: (_) {},
          ),
          rowSemanticsLabel: (item) => 'Choose ${item.title}',
          columns: [
            YumeiroTableColumn(cellBuilder: (_, item, _) => Text(item.title)),
          ],
        ),
      ),
    );

    expect(
      find.semantics.byLabel(RegExp('Choose Updated video')).evaluate().single,
      isSemantics(hasCheckedState: true, isChecked: true),
    );
    expect(
      find.semantics.byLabel(RegExp('Choose Cover')).evaluate().single,
      isSemantics(hasCheckedState: true, isChecked: false),
    );
  });

  for (final sliver in [false, true]) {
    final layout = sliver ? 'sliver' : 'box';
    testWidgets('selected $layout row paints beyond its last action', (
      tester,
    ) async {
      const background = Color(0xFFF1EADF);
      const selectionFill = Color(0xFFAB26D1);
      const restingAppearance = YumeiroVisualAppearance(
        fill: YumeiroSolidFill(Colors.transparent),
        foreground: Colors.black,
        shape: RoundedRectangleBorder(),
        transition: YumeiroVisualTransition.instant,
      );
      final boundaryKey = GlobalKey();
      final opened = <int>[];
      final selectionChanges = <Set<Key>>[];
      final buildTable = sliver
          ? YumeiroDataTable<int>.sliver
          : YumeiroDataTable<int>.new;
      final table = buildTable(
        variant: YumeiroTableVariant.compact,
        items: const [1, 2],
        showSelectionIndicator: true,
        columns: [
          YumeiroTableColumn(cellBuilder: (_, item, _) => Text('Name $item')),
        ],
        trailingColumns: [
          YumeiroTableColumn(
            preferredWidth: 124,
            cellBuilder: (_, item, _) => YumeiroButton(
              key: ValueKey('trailing-$item'),
              label: 'Open $item',
              width: 70,
              variant: YumeiroButtonVariant.ghost,
              onPressed: () => opened.add(item),
            ),
          ),
        ],
        selection: YumeiroTableSelection(
          mode: YumeiroTableSelectionMode.multiple,
          selectedKeys: {const ValueKey(1)},
          onChanged: selectionChanges.add,
        ),
      );
      await tester.pumpWidget(
        YumeiroApp(
          modality: YumeiroModality.pointer,
          visualsAugmenter: (visuals, _, _) => visuals.extend(
            items: {
              YumeiroItemRole.selection: YumeiroVisualRecipe(
                base: restingAppearance,
                states: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? restingAppearance.copyWith(
                          fill: const YumeiroSolidFill(selectionFill),
                        )
                      : null,
                ),
              ),
            },
          ),
          home: Scaffold(
            body: Center(
              child: RepaintBoundary(
                key: boundaryKey,
                child: SizedBox(
                  width: 400,
                  height: 160,
                  child: ColoredBox(
                    color: background,
                    child: sliver
                        ? CustomScrollView(slivers: [table])
                        : Align(alignment: Alignment.topCenter, child: table),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final action = find.byKey(const ValueKey('trailing-1'));
      Offset tail(int item) {
        final button = _rect(tester, 'trailing-$item');
        final row = tester.getRect(find.byKey(ValueKey(item)));
        final point = Offset(button.right + 20, row.center.dy);
        expect(row.contains(point), isTrue);
        return point;
      }

      final selectedTail = tail(1);
      final unselectedTail = tail(2);
      final selectedRow = tester.getRect(find.byKey(const ValueKey(1)));
      await tester.runAsync(() async {
        final boundary =
            boundaryKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await boundary.toImage();
        try {
          final bytes = (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          Color colorAt(Offset point) {
            final local = boundary.globalToLocal(point);
            final index =
                (local.dy.floor() * image.width + local.dx.floor()) * 4;
            return Color.fromARGB(
              bytes.getUint8(index + 3),
              bytes.getUint8(index),
              bytes.getUint8(index + 1),
              bytes.getUint8(index + 2),
            );
          }

          expect(colorAt(selectedTail), selectionFill);
          expect(colorAt(unselectedTail), background);
          expect(
            colorAt(Offset(selectedRow.left + 1, selectedRow.center.dy)),
            background,
          );
          expect(
            colorAt(Offset(selectedRow.center.dx, selectedRow.top + 1)),
            background,
          );
        } finally {
          image.dispose();
        }
      });

      await tester.tap(action);
      await tester.tapAt(selectedTail);
      expect(opened, [1]);
      expect(selectionChanges, isEmpty);

      await tester.tap(find.text('Name 1'));
      expect(selectionChanges, [<Key>{}]);
    });
  }
}

List<SemanticsNode> _semanticChildren(SemanticsNode node) {
  final result = <SemanticsNode>[];
  node.visitChildren((child) {
    result.add(child);
    return true;
  });
  return result;
}

Widget _host({
  required double width,
  required Widget child,
  YumeiroModality modality = YumeiroModality.pointer,
}) => YumeiroApp(
  modality: modality,
  home: Scaffold(
    body: Center(
      child: SizedBox(key: const ValueKey('table'), width: width, child: child),
    ),
  ),
);

YumeiroDataTable<String> _table({
  bool stacked = false,
  bool showSelectionIndicator = false,
  YumeiroTableSelection<String>? selection,
  void Function(String, String)? onAction,
}) {
  final details = <YumeiroTableColumn<String>>[
    YumeiroTableColumn(
      title: 'File size',
      preferredWidth: 80,
      alignment: AlignmentDirectional.centerEnd,
      cellBuilder: (_, item, _) => Text(
        item == 'video' ? '1.42 GB' : '812 KB',
        key: ValueKey('size-$item'),
      ),
    ),
    YumeiroTableColumn(
      title: 'Status',
      preferredWidth: 72,
      cellBuilder: (_, item, _) => Text(
        item == 'video' ? 'Ready' : 'Pending',
        key: ValueKey('status-$item'),
      ),
    ),
  ];
  return YumeiroDataTable<String>(
    variant: YumeiroTableVariant.compact,
    showSelectionIndicator: showSelectionIndicator,
    items: const ['video', 'cover'],
    selection: selection,
    columns: [
      YumeiroTableColumn(
        cellBuilder: (_, item, _) => Text(
          item == 'video' ? 'Video track' : 'Cover',
          key: ValueKey('name-$item'),
        ),
      ),
      if (!stacked) ...details,
      if (selection != null)
        YumeiroTableColumn(
          preferredWidth: 100,
          cellBuilder: (_, item, _) =>
              selection.selectedKeys.contains(ValueKey(item))
              ? Text('Current', key: ValueKey('choice-$item'))
              : null,
        ),
    ],
    additionalColumnBands: [if (stacked) details],
    trailingColumns: [
      YumeiroTableColumn(
        title: 'Open',
        preferredWidth: 48,
        cellBuilder: (context, item, _) => item == 'cover'
            ? null
            : YumeiroButton(
                variant: YumeiroButtonVariant.ghost,
                key: ValueKey('open-$item'),
                icon: YumeiroTheme.of(context).icons.play,
                tooltip: 'Open $item',
                onPressed: () => onAction?.call(item, 'open'),
              ),
      ),
      YumeiroTableColumn(
        preferredWidth: 54,
        cellBuilder: (_, item, _) => YumeiroSwitch(
          key: ValueKey('notify-$item'),
          semanticLabel: 'Notify for $item',
          value: item == 'video',
          onChanged: (_) => onAction?.call(item, 'notify'),
        ),
      ),
    ],
  );
}

Rect _rect(WidgetTester tester, String key) =>
    tester.getRect(find.byKey(ValueKey(key)));
