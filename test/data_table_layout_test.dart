import 'dart:ui' show PointerDeviceKind;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

void main() {
  for (final direction in TextDirection.values) {
    testWidgets('list and summary arrows point forward in ${direction.name}', (
      tester,
    ) async {
      await tester.pumpWidget(
        YumeiroApp(
          home: Directionality(
            textDirection: direction,
            child: Scaffold(
              body: Column(
                children: [
                  YumeiroListTile(title: const Text('List item'), onTap: () {}),
                  YumeiroDataRow(title: const Text('Summary'), onTap: () {}),
                ],
              ),
            ),
          ),
        ),
      );
      final icons = YumeiroTheme.of(
        tester.element(find.byType(YumeiroListTile)),
      ).icons;
      final rtl = direction == TextDirection.rtl;
      expect(
        find.byIcon(rtl ? icons.chevronLeft : icons.chevronRight),
        findsNWidgets(2),
      );
      expect(
        find.byIcon(rtl ? icons.chevronRight : icons.chevronLeft),
        findsNothing,
      );
    });
  }

  for (final (modality, direction) in [
    (YumeiroModality.pointer, TextDirection.ltr),
    (YumeiroModality.pointer, TextDirection.rtl),
    (YumeiroModality.touch, TextDirection.ltr),
  ]) {
    testWidgets('wide fixed columns stay accessible with selection in '
        '${modality.name} ${direction.name}', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final selected = <Set<Key>>[];
      var opened = false;
      await tester.pumpWidget(
        YumeiroApp(
          modality: modality,
          home: Directionality(
            textDirection: direction,
            child: Scaffold(
              body: YumeiroDataTable<int>(
                items: const [1],
                selection: YumeiroTableSelection(
                  mode: YumeiroTableSelectionMode.multiple,
                  onChanged: selected.add,
                ),
                columns: [
                  YumeiroTableColumn(
                    title: 'Name',
                    fixedWidth: 400,
                    cellBuilder: (_, item, _) => Text('Item $item'),
                  ),
                  YumeiroTableColumn(
                    title: 'Actions',
                    fixedWidth: 400,
                    alignment: AlignmentDirectional.centerEnd,
                    cellBuilder: (_, _, _) => YumeiroButton(
                      label: 'Open',
                      onPressed: () => opened = true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);

      await tester.tap(find.byType(YumeiroCheckbox).first);
      await tester.pumpAndSettle();
      expect(selected, [
        {const ValueKey(1)},
      ]);

      final table = find.byType(YumeiroDataTable<int>);
      final viewport = tester.getRect(table);
      final action = find.widgetWithText(YumeiroButton, 'Open');
      expect(viewport.contains(tester.getCenter(action)), isFalse);
      await tester.drag(
        table,
        Offset(direction == TextDirection.ltr ? -800 : 800, 0),
      );
      await tester.pumpAndSettle();
      expect(viewport.contains(tester.getCenter(find.text('Actions'))), isTrue);
      expect(viewport.contains(tester.getCenter(action)), isTrue);
      await tester.tap(action);
      expect(opened, isTrue);
    });
  }

  for (final (description, viewportWidth, unbounded) in [
    ('a narrow viewport', 360.0, false),
    ('a wider viewport', 900.0, false),
    ('an unbounded parent', 900.0, true),
  ]) {
    testWidgets('columns preserve fixed and flex widths in $description', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(viewportWidth, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final table = YumeiroDataTable<int>(
        minWidth: 300,
        items: const [1],
        columns: [
          YumeiroTableColumn(
            title: 'Fixed',
            fixedWidth: 400,
            titleWidget: _track('fixed header'),
            cellBuilder: (_, _, _) => _track('fixed cell'),
          ),
          YumeiroTableColumn(
            title: 'Double',
            flex: 2,
            titleWidget: _track('double header'),
            cellBuilder: (_, _, _) => _track('double cell'),
          ),
          YumeiroTableColumn(
            title: 'Single',
            flex: null,
            titleWidget: _track('single header'),
            cellBuilder: (_, _, _) => _track('single cell'),
          ),
        ],
      );
      await tester.pumpWidget(
        YumeiroApp(
          modality: YumeiroModality.pointer,
          home: Scaffold(body: unbounded ? Row(children: [table]) : table),
        ),
      );
      expect(tester.takeException(), isNull);

      Rect track(String part) => tester.getRect(find.byKey(ValueKey(part)));
      for (final name in ['fixed', 'double', 'single']) {
        final cell = track('$name cell');
        final header = track('$name header');
        expect(header.width, cell.width);
        expect(header.left, cell.left);
      }
      expect(track('fixed cell').width, 400);
      final single = track('single cell').width;
      expect(single, greaterThanOrEqualTo(40));
      expect(track('double cell').width, closeTo(single * 2, 1e-10));
      final actualViewportWidth = tester
          .getSize(find.byType(YumeiroDataTable<int>))
          .width;
      if (unbounded) {
        expect(actualViewportWidth, closeTo(400 + single * 3 + 32, 1e-10));
      } else {
        expect(actualViewportWidth, viewportWidth);
      }
    });
  }

  testWidgets('a clickable pointer row keeps a gutter without selection', (
    tester,
  ) async {
    const rowKey = ValueKey('pointer row');
    await tester.pumpWidget(
      YumeiroApp(
        modality: YumeiroModality.pointer,
        home: Scaffold(
          body: YumeiroDataTable<int>(
            items: const [1],
            rowKey: (_) => rowKey,
            onRowTap: (_) {},
            columns: [
              YumeiroTableColumn(
                title: 'Name',
                cellBuilder: (_, _, _) => const Text('Details'),
              ),
            ],
          ),
        ),
      ),
    );
    final row = find.byKey(rowKey);
    final rowRect = tester.getRect(row);
    final hover = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await hover.addPointer(location: rowRect.center);
    await tester.pumpAndSettle();

    final hoveredColor = YumeiroTheme.of(tester.element(row)).visuals
        .item(YumeiroItemRole.standard, {WidgetState.hovered})
        .background;
    final surface = find.descendant(
      of: row,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is YumeiroResolvedVisualSurface &&
            widget.appearance.background == hoveredColor,
      ),
    );
    expect(tester.getRect(surface), rowRect.deflate(2));
    await hover.removePointer();
  });

  testWidgets(
    'touch summaries align with compact rows and keep badges fitted',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final selection = YumeiroTableSelection<int>(
        mode: YumeiroTableSelectionMode.multiple,
        onChanged: (_) {},
      );
      const badgeKey = ValueKey('status badge');
      const progressKey = ValueKey('summary progress');
      await tester.pumpWidget(
        YumeiroApp(
          modality: YumeiroModality.touch,
          home: Scaffold(
            body: Column(
              children: [
                YumeiroDataTable<int>(
                  items: const [1, 2],
                  rowKey: (item) => ValueKey('summary $item'),
                  selection: selection,
                  onRowTap: (_) {},
                  columns: const [],
                  compactRowBuilder: (_, item, _) => YumeiroDataRow(
                    contentPadding: item == 2
                        ? const EdgeInsets.symmetric(horizontal: 12)
                        : null,
                    title: Text('Summary $item'),
                    status: item == 1
                        ? const YumeiroBadge(key: badgeKey, label: 'Ready')
                        : null,
                    progress: item == 1
                        ? const SizedBox(key: progressKey, height: 4)
                        : null,
                  ),
                ),
                YumeiroDataTable<int>(
                  variant: YumeiroTableVariant.compact,
                  items: const [1],
                  rowKey: (item) => ValueKey('compact $item'),
                  selection: selection,
                  showSelectionIndicator: true,
                  columns: [
                    YumeiroTableColumn(
                      cellBuilder: (_, item, _) => Text('Compact $item'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      final summary = find.byKey(const ValueKey('summary 1'));
      final compact = find.byKey(const ValueKey('compact 1'));
      double checkboxCenterX(Finder row) => tester
          .getCenter(
            find.descendant(of: row, matching: find.byType(YumeiroCheckbox)),
          )
          .dx;
      final selectAll = find.byWidgetPredicate(
        (widget) => widget is YumeiroCheckbox && widget.tristate,
      );
      final title = tester.getRect(find.text('Summary 1'));
      final status = tester.getRect(find.byKey(badgeKey));
      final progress = tester.getRect(find.byKey(progressKey));
      final rowRect = tester.getRect(summary);
      final metrics = YumeiroModalityScope.metricsOf(tester.element(summary));
      final checkbox = tester.getRect(
        find.descendant(of: summary, matching: find.byType(YumeiroCheckbox)),
      );
      expect(checkboxCenterX(summary), checkboxCenterX(compact));
      expect(tester.getTopLeft(selectAll).dx, checkbox.left);
      expect(title.left, tester.getTopLeft(find.text('Compact 1')).dx);
      expect(tester.getTopLeft(find.text('Summary 2')).dx, title.left + 12);
      expect(status.left, title.left);
      expect(status.width, lessThan(title.width));
      expect(rowRect.right - progress.right, metrics.horizontalPadding);

      final hover = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await hover.addPointer(location: const Offset(0, 0));
      await hover.moveTo(rowRect.center);
      await tester.pumpAndSettle();
      final hoveredColor = YumeiroTheme.of(tester.element(summary)).visuals
          .item(YumeiroItemRole.selection, {WidgetState.hovered})
          .background;
      final surface = find.descendant(
        of: summary,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is YumeiroResolvedVisualSurface &&
              widget.appearance.background == hoveredColor,
        ),
      );
      expect(tester.getRect(surface), rowRect.deflate(2));
      final nextRow = tester.getRect(find.byKey(const ValueKey('summary 2')));
      expect(nextRow.top, rowRect.bottom);
      await hover.removePointer();
    },
  );
}

Widget _track(String name) =>
    SizedBox(key: ValueKey(name), width: double.infinity, height: 20);
