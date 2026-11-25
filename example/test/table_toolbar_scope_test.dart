import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/gestures.dart' show kSecondaryMouseButton;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yumeiro/yumeiro.dart';
import 'package:yumeiro_example/src/pages/layout_page.dart';
import 'package:yumeiro_example/src/state/gallery_controller.dart';
import 'package:yumeiro_example/src/widgets/gallery_widgets.dart';

void main() {
  for (final modality in YumeiroModality.values) {
    testWidgets('table tools share one visible selection scope in $modality', (
      tester,
    ) async {
      tester.view.physicalSize = modality == YumeiroModality.touch
          ? const Size(390, 844)
          : const Size(760, 920);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final controller = GalleryController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) => YumeiroApp(
            preset: controller.activePreset,
            modality: modality,
            capability: YumeiroMaterialCapability.blurOnly,
            locale: controller.locale,
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: LayoutPage(controller: controller),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      Finder component(String api) => find.byWidgetPredicate(
        (widget) => widget is GalleryComponent && widget.api == api,
      );
      for (final (api, key, isList) in [
        ('YumeiroScrollView', 'gallery-scroll-content', false),
        ('YumeiroScrollView.list', 'gallery-page-scroll-list', true),
      ]) {
        final viewport = find.descendant(
          of: component(api),
          matching: find.byKey(ValueKey(key)),
        );
        final scroll = tester.widget<YumeiroScrollView>(viewport);
        expect(scroll.children != null, isList);
      }

      final scaffold = find.descendant(
        of: component('YumeiroPageScaffold'),
        matching: find.byType(YumeiroPageScaffold),
      );
      expect(tester.widget<YumeiroPageScaffold>(scaffold).bottomBar, isNull);
      final header = find.descendant(
        of: scaffold,
        matching: find.byType(YumeiroPageHeader),
      );
      final list = find.descendant(
        of: scaffold,
        matching: find.byKey(const ValueKey('gallery-page-scroll-list')),
      );
      final scrollable = find.descendant(
        of: list,
        matching: find.byType(Scrollable),
      );
      await tester.ensureVisible(list);
      await tester.pumpAndSettle();
      final headerTop = tester.getTopLeft(header);
      await tester.drag(list, const Offset(0, -100));
      await tester.pumpAndSettle();
      expect(
        tester.state<ScrollableState>(scrollable).position.pixels,
        greaterThan(0),
      );
      expect(tester.getTopLeft(header), headerTop);

      final tableFinder = find.byWidgetPredicate(
        (widget) => widget is YumeiroDataTable<GalleryRowItem>,
      );
      final searchToolbar = find.descendant(
        of: find.byKey(const ValueKey('sample-data-table')),
        matching: find.byType(YumeiroSearchToolbar),
      );
      final selectionToolbar = find.byType(YumeiroSelectionToolbar);
      Element cardFor(Finder child) => tester.element(
        find.ancestor(of: child, matching: find.byType(GalleryCard)),
      );
      expect(cardFor(searchToolbar), same(cardFor(tableFinder)));
      expect(cardFor(selectionToolbar), same(cardFor(tableFinder)));
      for (final (sample, api) in [
        (searchToolbar, 'YumeiroSearchToolbar(onFilter: …)'),
        (selectionToolbar, 'YumeiroSelectionToolbar'),
        (tableFinder, 'YumeiroDataTable'),
      ]) {
        final entry = find.ancestor(
          of: sample,
          matching: find.byWidgetPredicate(
            (widget) => widget is GalleryComponent && widget.api == api,
          ),
        );
        final caption = find.descendant(of: entry, matching: find.text(api));
        expect(entry, findsOneWidget);
        expect(caption, findsOneWidget);
        expect(
          tester.getBottomLeft(caption).dy,
          lessThanOrEqualTo(tester.getTopLeft(sample).dy),
        );
      }
      expect(
        tester.getTopLeft(searchToolbar).dy,
        lessThan(tester.getTopLeft(tableFinder).dy),
      );
      expect(
        tester.getTopLeft(selectionToolbar).dy,
        lessThan(tester.getTopLeft(tableFinder).dy),
      );
      final summaryCard = find.byWidgetPredicate(
        (widget) =>
            widget is GalleryCard &&
            widget.example == GalleryExample.summaryRows,
      );
      expect(tester.element(summaryCard), isNot(same(cardFor(tableFinder))));
      final summaryRows = find.descendant(
        of: summaryCard,
        matching: find.byType(YumeiroDataRow),
      );
      expect(summaryRows, findsNWidgets(2));
      final divider = find
          .descendant(of: summaryCard, matching: find.byType(YumeiroDivider))
          .last;
      expect(
        tester.getTopLeft(divider).dy,
        tester.getBottomLeft(summaryRows.first).dy,
      );

      YumeiroDataTable<GalleryRowItem> table() =>
          tester.widget<YumeiroDataTable<GalleryRowItem>>(tableFinder);
      YumeiroSelectionToolbar selection() =>
          tester.widget<YumeiroSelectionToolbar>(selectionToolbar);
      final removeSelected = find.descendant(
        of: selectionToolbar,
        matching: find.widgetWithText(YumeiroButton, '移除所选'),
      );
      final selectAll = find.descendant(
        of: selectionToolbar,
        matching: find.widgetWithText(YumeiroButton, '全选'),
      );
      final count = find.descendant(
        of: selectionToolbar,
        matching: find.text('已选 0 项'),
      );
      expect(tester.getCenter(count).dy, tester.getCenter(selectAll).dy);
      expect(
        tester.getCenter(removeSelected).dy,
        tester.getCenter(selectAll).dy,
      );

      Future<void> tap(Finder target) async {
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
        await tester.tap(target);
        await tester.pumpAndSettle();
      }

      final pagerSample = component('YumeiroNavigationPager');
      expect(pagerSample, findsOneWidget);
      final pager = find.descendant(
        of: pagerSample,
        matching: find.byType(YumeiroNavigationPager<int>),
      );
      expect(tester.widget<YumeiroNavigationPager<int>>(pager).value, 0);
      final numbered = component('YumeiroPagination(variant: numbered)');
      final compact = component('YumeiroPagination(variant: compact)');
      final isTouch = modality == YumeiroModality.touch;
      expect(numbered, isTouch ? findsNothing : findsOneWidget);
      expect(compact, findsOneWidget);
      Finder pagerControl(Finder sample) =>
          find.descendant(of: sample, matching: find.byType(YumeiroPagination));
      await tap(
        find.descendant(
          of: isTouch ? compact : numbered,
          matching: find.byTooltip('下一页'),
        ),
      );
      expect(tester.widget<YumeiroNavigationPager<int>>(pager).value, 1);
      expect(
        tester.widget<YumeiroPagination>(pagerControl(compact)).pageIndex,
        1,
      );
      await tap(find.descendant(of: compact, matching: find.byTooltip('上一页')));
      expect(tester.widget<YumeiroNavigationPager<int>>(pager).value, 0);
      expect(
        tester
            .widget<YumeiroPagination>(
              pagerControl(isTouch ? compact : numbered),
            )
            .pageIndex,
        0,
      );

      for (final (title, key, expected) in [
        ('保留草稿', 'gallery-kept-draft', '临时文字'),
        ('重置草稿', 'gallery-reset-draft', '示例 A'),
      ]) {
        final header = find.text(title);
        final edit = find.descendant(
          of: find.byKey(ValueKey(key)),
          matching: find.byType(EditableText),
        );
        await tap(header);
        await tester.enterText(edit, '临时文字');
        await tester.pumpAndSettle();
        await tap(header);
        expect(edit.hitTestable(), findsNothing);
        await tap(header);
        expect(tester.widget<EditableText>(edit).controller.text, expected);
        await tap(header);
      }

      if (modality == YumeiroModality.touch) {
        final viewportSwitch = find.byKey(
          const ValueKey('gallery-table-layout'),
        );
        Finder tableLayout(String label) =>
            find.descendant(of: viewportSwitch, matching: find.text(label));
        await tap(tableLayout('横向表格'));
        expect(table().compactRowBuilder, isNull);
        expect(
          find.text('YumeiroDataTable(compactRowBuilder: null)'),
          findsOneWidget,
        );
        final scroll = find.descendant(
          of: tableFinder,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.right,
          ),
        );
        await tester.ensureVisible(scroll);
        await tester.pumpAndSettle();
        final progressHeader = find.descendant(
          of: tableFinder,
          matching: find.text('进度'),
        );
        expect(progressHeader.hitTestable(), findsNothing);
        await tester.drag(scroll, const Offset(-540, 0));
        await tester.pumpAndSettle();
        expect(
          tester.state<ScrollableState>(scroll).position.pixels,
          greaterThan(0),
        );
        expect(progressHeader.hitTestable(), findsOneWidget);
        await tap(tableLayout('摘要行'));
        expect(table().compactRowBuilder, isNotNull);
      }

      Future<void> search(String value) async {
        final input = find.descendant(
          of: searchToolbar,
          matching: find.byType(EditableText),
        );
        await tester.ensureVisible(input);
        await tester.pumpAndSettle();
        await tester.enterText(input, value);
        await tester.pumpAndSettle();
      }

      expect(tester.widget<YumeiroButton>(removeSelected).onPressed, isNull);
      // A different page's active categories must not mark this search filtered.
      final toolbar = tester.widget<YumeiroSearchToolbar>(searchToolbar);
      expect(controller.activeCategories, isNotEmpty);
      expect(toolbar.filterCount, 0);
      expect(toolbar.onFilter, isNotNull);

      await tap(
        find
            .descendant(of: tableFinder, matching: find.byType(YumeiroCheckbox))
            .first,
      );
      expect(selection().selectedCount, 3);
      expect(table().selection!.selectedKeys, hasLength(3));

      final icons = YumeiroTheme.of(tester.element(tableFinder)).icons;
      final filterButton = find.descendant(
        of: searchToolbar,
        matching: find.byWidgetPredicate(
          (widget) => widget is YumeiroButton && widget.icon == icons.filter,
        ),
      );
      final filterPanel = find.byType(
        modality == YumeiroModality.touch ? YumeiroBottomSheet : YumeiroDialog,
      );
      Finder inFilter(String label) =>
          find.descendant(of: filterPanel, matching: find.text(label));
      await tap(filterButton);
      await tap(inFilter('分类 A'));
      expect(tester.widget<YumeiroSearchToolbar>(searchToolbar).filterCount, 0);
      await tap(inFilter('应用'));
      expect(tester.widget<YumeiroSearchToolbar>(searchToolbar).filterCount, 1);
      expect(find.text('筛选（1）'), findsOneWidget);
      expect(table().items.map((item) => item.id), ['1']);
      expect(table().selection!.selectedKeys, {const ValueKey('1')});
      expect(controller.activeCategories, {'Category A', 'Category B'});
      await tap(filterButton);
      await tap(inFilter('重置'));
      await tap(inFilter('应用'));
      expect(tester.widget<YumeiroSearchToolbar>(searchToolbar).filterCount, 0);
      expect(table().items, hasLength(3));
      await tap(
        find
            .descendant(of: tableFinder, matching: find.byType(YumeiroCheckbox))
            .first,
      );

      await search('分类 B');
      expect(table().items.map((item) => item.id), ['2']);
      expect(table().selection!.selectedKeys, {const ValueKey('2')});
      expect(selection().selectedCount, 1);
      controller.setLocale(const Locale('en'));
      await tester.pumpAndSettle();
      expect(table().items, isEmpty);
      expect(table().selection!.selectedKeys, isEmpty);
      expect(selection().selectedCount, 0);
      expect(
        tester
            .widget<YumeiroButton>(
              find.descendant(
                of: selectionToolbar,
                matching: find.widgetWithText(YumeiroButton, 'Remove selected'),
              ),
            )
            .onPressed,
        isNull,
      );
      controller.setLocale(const Locale('zh'));
      await tester.pumpAndSettle();
      expect(selection().selectedCount, 1);
      await tap(
        find.descendant(
          of: selectionToolbar,
          matching: find.byWidgetPredicate(
            (widget) => widget is YumeiroButton && widget.label == null,
          ),
        ),
      );
      expect(controller.selectedRows, isEmpty);
      await tap(selectAll);
      expect(controller.selectedRows.map((item) => item.id), ['2']);

      await search('');
      await tap(
        find.descendant(
          of: searchToolbar,
          matching: find.byWidgetPredicate(
            (widget) => widget is YumeiroButton && widget.icon == icons.sort,
          ),
        ),
      );
      expect(table().items.map((item) => item.id), ['3', '2', '1']);
      expect(controller.selectedRows.map((item) => item.id), ['2']);

      await search('no matching row');
      expect(table().items, isEmpty);
      expect(find.text('暂无匹配项'), findsOneWidget);
      expect(selection().selectedCount, 0);
      expect(selection().onSelectAll, isNull);
      expect(tester.widget<YumeiroButton>(removeSelected).onPressed, isNull);

      await search('category a');
      expect(table().items.map((item) => item.id), ['1']);
      await tap(selectAll);
      await tap(removeSelected);
      expect(table().items, isEmpty);
      expect(controller.selectedRows, isEmpty);
      await tap(
        find.descendant(
          of: searchToolbar,
          matching: find.byWidgetPredicate(
            (widget) => widget is YumeiroButton && widget.icon == icons.more,
          ),
        ),
      );
      expect(find.text('排序字段'), findsOneWidget);
      await tap(find.text('恢复示例数据'));
      expect(table().items.map((item) => item.id), ['1']);

      final modes = find.byKey(const ValueKey('gallery-table-selection-mode'));
      Finder mode(String label) =>
          find.descendant(of: modes, matching: find.text(label));
      await tap(mode('单选'));
      expect(table().selection!.mode, YumeiroTableSelectionMode.single);
      expect(selectionToolbar, findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('sample-data-table')),
          matching: find.text('YumeiroDataTable'),
        ),
        findsOneWidget,
      );
      await tap(
        find.descendant(
          of: tableFinder,
          matching: find.byWidgetPredicate((widget) => widget is Radio),
        ),
      );
      expect(table().selection!.selectedKeys, {const ValueKey('1')});

      await tap(mode('浏览'));
      expect(table().selection, isNull);
      expect(selectionToolbar, findsNothing);
      final row = find.descendant(
        of: tableFinder,
        matching: find.text('示例项目 01'),
      );
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      if (modality == YumeiroModality.touch) {
        await tester.longPress(row);
      } else {
        await tester.tap(
          row,
          buttons: kSecondaryMouseButton,
          kind: PointerDeviceKind.mouse,
        );
      }
      await tester.pumpAndSettle();
      await tap(find.text('移除此行'));
      expect(table().items, isEmpty);

      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
