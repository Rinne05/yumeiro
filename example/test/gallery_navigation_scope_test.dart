import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yumeiro/yumeiro.dart';
import 'package:yumeiro_example/main.dart';
import 'package:yumeiro_example/src/shell/gallery_shell.dart';
import 'package:yumeiro_example/src/state/gallery_controller.dart';
import 'package:yumeiro_example/src/widgets/gallery_widgets.dart';

void main() {
  testWidgets('desktop sample changes keep mobile appearance independent', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1700, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const YumeiroGalleryDesktopApp(initialShowMobilePreview: true),
    );
    await tester.pumpAndSettle();
    final desktop = find.byWidgetPredicate(
      (widget) =>
          widget is GalleryShellPage &&
          widget.profile == GalleryProfile.desktop,
    );
    final mobile = find.byWidgetPredicate(
      (widget) =>
          widget is GalleryShellPage && widget.profile == GalleryProfile.mobile,
    );
    final source = tester.widget<GalleryShellPage>(desktop).controller;
    final target = tester.widget<GalleryShellPage>(mobile).controller;

    final mobileMode = find.descendant(
      of: mobile,
      matching: find.byKey(const ValueKey('theme-appearance-mode')),
    );
    await _tapVisible(
      tester,
      find.descendant(of: mobileMode, matching: find.text('浅色')),
    );
    await _tapVisible(
      tester,
      find.descendant(
        of: mobile,
        matching: find.byKey(const ValueKey('theme-family-ceramic')),
      ),
    );
    await _tapVisible(
      tester,
      find.descendant(of: mobile, matching: find.text('EN')),
    );
    expect(target.activePreset.id, YumeiroThemePresetIds.ceramicLight);
    expect(target.locale, const Locale('en'));
    final sourceRevision = source.appearanceRevision;

    await _tapVisible(
      tester,
      find.descendant(of: desktop, matching: find.text('交互控件')),
    );
    expect(source.navIndex, 1);
    expect(target.navIndex, 0);
    expect(target.activePreset.id, YumeiroThemePresetIds.ceramicLight);
    expect(target.locale, const Locale('en'));
    final switchFinder = find
        .descendant(
          of: desktop,
          matching: find.byWidgetPredicate(
            (widget) => widget is YumeiroSwitch && widget.onChanged != null,
          ),
        )
        .first;
    final oldSwitch = source.switchValue;
    await _tapVisible(tester, switchFinder);
    expect(source.switchValue, !oldSwitch);
    expect(target.switchValue, isTrue);
    expect(source.appearanceRevision, sourceRevision);
    expect(target.activePreset.id, YumeiroThemePresetIds.ceramicLight);
    expect(target.preferredVariant, YumeiroThemeVariant.light);
    expect(target.locale, const Locale('en'));
    final mobileContext = tester.element(mobile);
    expect(YumeiroTheme.of(mobileContext).presetId, target.activePreset.id);
    expect(Theme.of(mobileContext).brightness, Brightness.light);

    await _tapVisible(
      tester,
      find.descendant(of: mobile, matching: find.text('Layout')),
    );
    expect(target.navIndex, 3);
    // A real desktop appearance change still synchronizes every design setting.
    await _tapVisible(
      tester,
      find.descendant(of: desktop, matching: find.text('EN')),
    );
    expect(source.appearanceRevision, greaterThan(sourceRevision));
    expect(target.activePreset.id, source.activePreset.id);
    expect(target.preferredVariant, source.preferredVariant);
    expect(target.locale, source.locale);
    expect(target.navIndex, 3);
    expect(target.switchValue, isTrue);
    expect(source.navIndex, 1);

    await _tapVisible(
      tester,
      find.descendant(of: desktop, matching: find.text('Themes')),
    );
    await _tapVisible(
      tester,
      find.descendant(
        of: desktop,
        matching: find.byKey(const ValueKey('theme-family-brushed-metal')),
      ),
    );
    expect(target.activePreset.id, YumeiroThemePresetIds.brushedMetalDark);
    expect(source.activePreset.id, target.activePreset.id);
    expect(target.navIndex, 3);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'navigation and submitted search start the destination at the top',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final controller = GalleryController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(YumeiroGalleryMobileApp(controller: controller));
      await tester.pumpAndSettle();

      double offset() => tester
          .state<ScrollableState>(
            find
                .descendant(
                  of: find.byKey(
                    ValueKey('gallery-page-${controller.navIndex}'),
                  ),
                  matching: find.byType(Scrollable),
                )
                .first,
          )
          .position
          .pixels;
      final firstControlsButton = find.widgetWithText(YumeiroButton, '默认按钮');
      await tester.ensureVisible(find.text('当前主题色彩令牌'));
      await tester.pumpAndSettle();
      expect(offset(), greaterThan(0));
      await _tapVisible(tester, find.text('交互控件'));
      expect(controller.navIndex, 1);
      expect(offset(), 0);
      expect(firstControlsButton.hitTestable(), findsOneWidget);

      await _tapVisible(tester, find.text('主题预设'));
      await tester.ensureVisible(find.text('当前主题色彩令牌'));
      await tester.pumpAndSettle();
      final originalOffset = offset();
      expect(originalOffset, greaterThan(0));
      final searchButton = find.byType(YumeiroSearchButton);
      final searchPanel = find.byType(YumeiroBottomSheet);
      await _tapVisible(tester, searchButton);
      Finder searchInput() =>
          find.descendant(of: searchPanel, matching: find.byType(EditableText));
      await tester.enterText(searchInput(), 'controls');
      await _tapVisible(
        tester,
        find.descendant(
          of: searchPanel,
          matching: find.widgetWithText(YumeiroButton, '取消'),
        ),
      );
      expect(controller.navIndex, 0);
      expect(controller.searchScopeQuery, isEmpty);
      expect(offset(), closeTo(originalOffset, .01));

      await _tapVisible(tester, searchButton);
      expect(
        tester.widget<EditableText>(searchInput()).controller.text,
        isEmpty,
      );
      await tester.enterText(searchInput(), 'controls');
      await _tapVisible(
        tester,
        find.descendant(
          of: searchPanel,
          matching: find.widgetWithText(YumeiroButton, '搜索'),
        ),
      );
      expect(controller.navIndex, 1);
      expect(controller.searchScopeQuery, 'controls');
      expect(offset(), 0);
      expect(firstControlsButton.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('gallery search scrolls to the matching example', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = GalleryController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(YumeiroGalleryMobileApp(controller: controller));
    await tester.pumpAndSettle();

    Future<void> tapSearchControl(Finder finder) async {
      await tester.tap(finder);
      await tester.pump();
      // Content such as the loading demo can animate continuously.
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
    }

    Future<void> expectSearchTarget(
      String query,
      GalleryExample example,
    ) async {
      await tapSearchControl(
        find.byKey(const ValueKey('gallery-global-search')),
      );
      final searchPanel = find.byType(YumeiroBottomSheet);
      await tester.enterText(
        find.descendant(of: searchPanel, matching: find.byType(EditableText)),
        query,
      );
      await tapSearchControl(
        find.descendant(
          of: searchPanel,
          matching: find.widgetWithText(YumeiroButton, '搜索'),
        ),
      );

      expect(controller.navIndex, example.pageIndex);
      final card = find.byWidgetPredicate(
        (widget) => widget is GalleryCard && widget.example == example,
      );
      expect(
        find
            .descendant(of: card, matching: find.text(example.zh))
            .hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    }

    await expectSearchTarget(
      'YumeiroDataTable.sliver',
      GalleryExample.compactTable,
    );
    await expectSearchTarget('紧凑表', GalleryExample.compactTable);
    await expectSearchTarget('服务端分页', GalleryExample.tablePagination);
    await expectSearchTarget('YumeiroDataRow', GalleryExample.summaryRows);
    await expectSearchTarget(
      'YumeiroSettingRow.select',
      GalleryExample.settingSelect,
    );
    await expectSearchTarget(
      'YumeiroTopNavigation.paged',
      GalleryExample.pageNavigation,
    );
    await expectSearchTarget('YumeiroAsyncSelect', GalleryExample.remoteSelect);
    await expectSearchTarget(
      'YumeiroAsyncSelect.form',
      GalleryExample.formControls,
    );
    await expectSearchTarget('YumeiroMultiSelect', GalleryExample.multiSelect);
    await expectSearchTarget(
      'inline multi-select',
      GalleryExample.selectionList,
    );
    await expectSearchTarget(
      'YumeiroSelectionList.multiForm',
      GalleryExample.formControls,
    );
    await expectSearchTarget(
      'YumeiroSelectionList(scrollable: true)',
      GalleryExample.selectionList,
    );
    await expectSearchTarget('YumeiroBadge.overlay', GalleryExample.posters);
    await expectSearchTarget('YumeiroChip', GalleryExample.chips);
    await expectSearchTarget('YumeiroActionMenu.show', GalleryExample.menus);
    await expectSearchTarget(
      'YumeiroSelect.searchable(onFreeTextSubmitted: …)',
      GalleryExample.singleSelect,
    );
    await expectSearchTarget(
      'YumeiroFilter.show',
      GalleryExample.compoundFilter,
    );
    expect(
      GalleryExample.find('yumeiroasyncselectformfield', YumeiroModality.touch),
      isNull,
    );
    for (final modality in YumeiroModality.values) {
      expect(
        GalleryExample.find('yumeiroselectionrow', modality),
        GalleryExample.settingsRows,
      );
      expect(
        GalleryExample.find('yumeironavigationpager', modality),
        GalleryExample.pageNavigation,
      );
      expect(
        GalleryExample.find('yumeiropagination(variant: numbered)', modality),
        modality == YumeiroModality.pointer
            ? GalleryExample.pageNavigation
            : isNull,
      );
      for (final (caption, example) in [
        ('Compact Table', GalleryExample.compactTable),
        ('YumeiroButton(variant: mediaOverlay)', GalleryExample.buttons),
        ('YumeiroSelectionList(multiple: true)', GalleryExample.selectionList),
        ('YumeiroSelect.form(searchable: true)', GalleryExample.formControls),
        ('YumeiroProgress(value: null)', GalleryExample.loading),
        ('YumeiroPosterGrid(shrinkWrap: false)', GalleryExample.posters),
        ('YumeiroSelectionRow(card: true)', GalleryExample.settingsRows),
        ('YumeiroSearchToolbar(onFilter: …)', GalleryExample.dataTable),
        ('YumeiroPagination(variant: compact)', GalleryExample.pageNavigation),
        ('YumeiroDisclosure(maintainState: false)', GalleryExample.disclosure),
        ('YumeiroDialog.confirm(destructive: true)', GalleryExample.dialogs),
        ('YumeiroToast', GalleryExample.toasts),
        (
          'YumeiroToastController.show(duration: Duration.zero)',
          GalleryExample.toasts,
        ),
      ]) {
        expect(GalleryExample.find(caption.toLowerCase(), modality), example);
      }
      expect(
        GalleryExample.find('yumeirotooltip(triggermode: tap)', modality),
        modality == YumeiroModality.touch ? GalleryExample.tooltip : isNull,
      );
      expect(
        GalleryExample.find(
          'yumeirodatatable(compactrowbuilder: null)',
          modality,
        ),
        modality == YumeiroModality.touch ? GalleryExample.dataTable : isNull,
      );
      expect(
        GalleryExample.find(
          'yumeirodatatable(variant: compact, compactrowbuilder: …)',
          modality,
        ),
        modality == YumeiroModality.touch
            ? GalleryExample.compactTable
            : isNull,
      );
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
