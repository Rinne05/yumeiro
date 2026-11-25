import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yumeiro/yumeiro.dart';
import 'package:yumeiro_example/main.dart';
import 'package:yumeiro_example/src/shell/gallery_shell.dart';
import 'package:yumeiro_example/src/widgets/gallery_widgets.dart';

void main() {
  testWidgets(
    'Desktop gallery showcases all 5 pages, preset customization, contextual Liquid Glass fallback, locale sync, and isolated mobile preview',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const YumeiroGalleryDesktopApp());
      await tester.pumpAndSettle();

      expect(find.text('主题与材质管线'), findsOneWidget);
      expect(find.text('Nordic Amber'), findsOneWidget);

      // Each registered family has one card, with uniform dimensions.
      final presetCards = find.byType(GalleryPresetCard);
      final presetCardFinder = find.descendant(
        of: presetCards,
        matching: find.byType(YumeiroCard),
      );
      const familyCount = 14;
      expect(presetCardFinder, findsNWidgets(familyCount));
      expect(presetCards, findsNWidgets(familyCount));
      expect(
        tester
            .widgetList<GalleryPresetCard>(presetCards)
            .where((card) => card.selected),
        hasLength(1),
      );
      expect(find.text('主题风格与外观模式'), findsOneWidget);
      final firstCardSize = tester.getSize(presetCardFinder.first);
      for (var i = 1; i < familyCount; i++) {
        expect(tester.getSize(presetCardFinder.at(i)), firstCardSize);
      }

      // Classic Dark is active by default: Liquid Glass fallback simulation is hidden
      expect(find.text('经典 · 深色'), findsNWidgets(2));
      expect(find.text('液态玻璃降级模拟'), findsNothing);

      // Changing style retains the preferred dark appearance.
      final liquidGlass = find.byKey(
        const ValueKey('theme-family-liquid-glass'),
      );
      await tester.ensureVisible(liquidGlass);
      await tester.pumpAndSettle();
      await tester.tap(liquidGlass);
      await tester.pumpAndSettle();
      expect(find.text('液态玻璃降级模拟'), findsOneWidget);
      final supportsOptical =
          YumeiroMaterialCapability.fullOptical.resolveForRuntime() ==
          YumeiroMaterialCapability.fullOptical;
      expect(find.text('光学折射'), findsNWidgets(supportsOptical ? 2 : 1));
      expect(find.text('模糊降级'), findsNWidgets(supportsOptical ? 1 : 3));

      // Toggle Blur Fallback and verify badge updates cleanly
      final fallbackOption = find.descendant(
        of: find.byType(YumeiroSegmentedControl<YumeiroMaterialCapability>),
        matching: find.text('模糊降级'),
      );
      await tester.ensureVisible(fallbackOption);
      await tester.pumpAndSettle();
      await tester.tap(fallbackOption);
      await tester.pumpAndSettle();
      expect(find.text('模糊降级'), findsNWidgets(3));

      // Switch to Sketch preset: fallback simulation hides and Sketch-specific options appear
      final sketch = find.byKey(const ValueKey('theme-family-sketch'));
      await tester.ensureVisible(sketch);
      await tester.pumpAndSettle();
      await tester.tap(sketch);
      await tester.pumpAndSettle();
      expect(find.text('液态玻璃降级模拟'), findsNothing);
      expect(find.text('模糊降级'), findsNothing);
      expect(find.text('硬阴影颜色'), findsOneWidget);

      // Switch to host-registered custom preset
      final nordic = find.byKey(const ValueKey('theme-family-nordic-amber'));
      await tester.ensureVisible(nordic);
      await tester.pumpAndSettle();
      await tester.tap(nordic);
      await tester.pumpAndSettle();
      expect(find.text('液态玻璃降级模拟'), findsNothing);

      // Switch locale to English via global preference toggle, then back to zh
      await tester.ensureVisible(find.text('English'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      expect(find.text('Themes & Material Pipeline'), findsOneWidget);
      expect(find.text('Preset Customization Engine'), findsOneWidget);
      expect(find.text('Theme Style & Appearance'), findsOneWidget);

      await tester.ensureVisible(find.text('简体中文'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('简体中文'));
      await tester.pumpAndSettle();
      expect(find.text('主题与材质管线'), findsOneWidget);

      // Open isolated 390x844 mobile viewport preview alongside desktop
      await tester.tap(find.text('手机视口'));
      await tester.pumpAndSettle();
      expect(
        find.text('Isolated Mobile Viewport · 390×844 (Touch)'),
        findsOneWidget,
      );
      expect(find.text('主题与材质管线'), findsNWidgets(2));

      // Close isolated mobile preview before stepping through all desktop tabs
      await tester.tap(find.text('关闭视口'));
      await tester.pumpAndSettle();

      // Tab 2: Controls
      await tester.tap(find.text('交互控件'));
      await tester.pumpAndSettle();
      expect(find.text('YumeiroTextField.search'), findsOneWidget);
      expect(find.byType(YumeiroTokenInput<String>), findsOneWidget);
      expect(find.byType(YumeiroRatingEditor), findsOneWidget);

      final filterDropdownFinder = find.byKey(
        const ValueKey('gallery-filter-select'),
      );
      final filterTrigger = find.descendant(
        of: filterDropdownFinder,
        matching: find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.button == true,
        ),
      );
      await tester.ensureVisible(filterDropdownFinder);
      await tester.pumpAndSettle();
      expect(
        tester.widget<Semantics>(filterTrigger).properties.selected,
        isTrue,
      );
      await tester.tap(filterDropdownFinder);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byWidgetPredicate(
            (widget) =>
                widget is YumeiroSelectionList<String> &&
                widget.options.any((option) => option.value == 'all'),
          ),
          matching: find.text('选项 A'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<Semantics>(filterTrigger).properties.selected,
        isNull,
      );

      // Tab 3: Display
      await tester.tap(find.text('展示组件'));
      await tester.pump();
      expect(find.byType(YumeiroStatTile), findsNWidgets(5));
      expect(find.byType(YumeiroEmptyState), findsNWidgets(3));
      expect(find.byType(YumeiroErrorState), findsOneWidget);
      expect(find.byType(YumeiroPosterGrid), findsNWidgets(3));

      // Tab 4: Layout showcases shared rows and navigation for pointer input.
      await tester.tap(find.text('布局导航'));
      await tester.pumpAndSettle();
      expect(find.byType(YumeiroSettingsSection), findsNWidgets(2));
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('sample-data-table')),
          matching: find.byType(YumeiroSearchToolbar),
        ),
        findsOneWidget,
      );
      expect(find.text('YumeiroPageHeader.compact'), findsAtLeastNWidgets(1));
      expect(find.byType(YumeiroDataRow), findsNWidgets(2));
      expect(find.byType(YumeiroTopNavigation<int>), findsNWidgets(2));

      // Tab 5: Overlays -> pointer tooltip visible, mobile push route hidden
      await tester.tap(find.text('浮层路由'));
      await tester.pumpAndSettle();
      expect(find.text('悬停查看提示'), findsOneWidget);
      expect(find.text('推入详情二级页'), findsNothing);

      await tester.ensureVisible(find.text('触发 Toast 通知'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('触发 Toast 通知'));
      await tester.pump();
      expect(find.text('这是一条通知示例。'), findsOneWidget);

      await tester.ensureVisible(find.text('长文本提示'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('长文本提示'));
      await tester.pump();
      expect(find.text('长文本示例'), findsOneWidget);

      // Open & close adaptive dialog
      await tester.ensureVisible(find.text('打开基础弹窗'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('打开基础弹窗'));
      await tester.pumpAndSettle();
      expect(find.byType(YumeiroDialog), findsOneWidget);
      await tester.tap(find.text('关闭'));
      await tester.pumpAndSettle();
      expect(find.text('已关闭对话框。'), findsOneWidget);

      // Open & save adaptive editor (renders as YumeiroDialog on pointer modality)
      await tester.ensureVisible(find.text('打开自适应编辑器'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('打开自适应编辑器'));
      await tester.pumpAndSettle();
      expect(find.byType(YumeiroEditor), findsOneWidget);
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      expect(find.text('已保存示例内容。'), findsOneWidget);
    },
  );

  testWidgets(
    'Mobile gallery runs in touch modality across all 5 tabs with zero overflow, hides hover tooltips, and pushes detail route',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const YumeiroGalleryMobileApp());
      await tester.pumpAndSettle();

      expect(find.text('主题与材质管线'), findsOneWidget);
      expect(find.text('经典 · 深色'), findsNWidgets(2));

      // Scroll down Themes page on 390px viewport to verify zero overflow
      await tester.ensureVisible(find.text('当前主题色彩令牌'));
      await tester.pumpAndSettle();

      // Bottom nav tab: Controls
      await tester.tap(find.text('交互控件'));
      await tester.pumpAndSettle();
      expect(find.text('YumeiroTextField.search'), findsOneWidget);
      // Bottom nav tab: Display
      await tester.tap(find.text('展示组件'));
      await tester.pump();
      expect(find.byType(YumeiroStatTile), findsNWidgets(5));
      await tester.ensureVisible(
        find.byKey(const ValueKey('display-poster-grid')),
      );
      await tester.pump();

      // Bottom nav tab: Layout -> touch-only bars, compact rows & top tabs shown
      await tester.tap(find.text('布局导航'));
      await tester.pump();
      expect(find.text('YumeiroPageHeader.compact'), findsAtLeastNWidgets(1));
      expect(find.byType(YumeiroActionBar), findsAtLeastNWidgets(1));
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('sample-data-table')),
          matching: find.byType(YumeiroDataRow),
        ),
        findsNWidgets(3),
      );
      expect(find.byType(YumeiroTopNavigation<int>), findsNWidgets(2));
      await tester.ensureVisible(
        find.byKey(const ValueKey('gallery-selection-setting')),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(YumeiroSelectionToolbar));
      await tester.pump();

      // Bottom nav tab: Overlays -> push detail route shown, hover tooltip hidden
      await tester.tap(find.text('浮层路由'));
      await tester.pumpAndSettle();
      expect(find.text('推入详情二级页'), findsOneWidget);
      expect(find.text('悬停查看提示'), findsNothing);

      await tester.ensureVisible(find.text('推入详情二级页'));
      await tester.pumpAndSettle();
      final pageScroll = tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byKey(const ValueKey('gallery-page-4')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      final returnOffset = pageScroll.position.pixels;
      expect(returnOffset, greaterThan(0));
      await tester.tap(find.text('推入详情二级页'));
      await tester.pumpAndSettle();
      expect(find.text('二级详情路由页'), findsOneWidget);
      final detail = find.byType(YumeiroPageScaffold);
      expect(tester.widget<YumeiroPageScaffold>(detail).bottomBar, isNull);
      final detailCanvas = find.ancestor(
        of: detail,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is YumeiroVisualSurface &&
              widget.role == YumeiroSurfaceRole.canvas,
        ),
      );
      expect(detailCanvas, findsOneWidget);
      expect(
        tester.getSize(detailCanvas),
        MediaQuery.sizeOf(tester.element(detailCanvas)),
      );

      await tester.tap(
        find.descendant(of: detail, matching: find.byTooltip('返回')),
      );
      await tester.pumpAndSettle();
      expect(find.text('浮层、菜单与路由转场'), findsOneWidget);
      expect(pageScroll.position.pixels, closeTo(returnOffset, .001));
      expect(find.text('推入详情二级页').hitTestable(), findsOneWidget);
      final restoredButton = tester.getSemantics(find.text('推入详情二级页'));
      expect(restoredButton.label, contains('推入详情二级页'));
      expect(restoredButton.rect.isEmpty, isFalse);
    },
  );

  testWidgets(
    'Desktop sidebar hides header and footer text labels cleanly when auto-collapsed at medium width',
    (tester) async {
      tester.view.physicalSize = const Size(760, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const YumeiroGalleryDesktopApp());
      await tester.pumpAndSettle();

      expect(find.text('Yumeiro UI'), findsNothing);
      expect(find.text('手机视口'), findsNothing);
      expect(find.text('Pointer Modality'), findsNothing);
      expect(find.text('Pointer · Desktop'), findsNothing);
      expect(find.byIcon(Icons.smartphone_rounded), findsNothing);
    },
  );

  testWidgets('narrow pointer gallery hides its side-by-side touch preview', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(380, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const YumeiroGalleryDesktopApp(initialShowMobilePreview: true),
    );
    await tester.pumpAndSettle();

    final shells = find.byType(YumeiroNavigationShell);
    expect(shells, findsOneWidget);
    expect(
      YumeiroModalityScope.modalityOf(tester.element(shells)),
      YumeiroModality.pointer,
    );
    expect(find.byIcon(Icons.smartphone_rounded), findsNothing);
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(960, 640);
    await tester.pumpAndSettle();
    expect(shells, findsNWidgets(2));
    final close = find.bySemanticsLabel('Close mobile viewport');
    expect(close, findsOneWidget);
    await tester.tap(close);
    await tester.pumpAndSettle();
    expect(shells, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'minimum desktop window keeps a sidebar beside the touch preview',
    (tester) async {
      tester.view.physicalSize = const Size(960, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        const YumeiroGalleryDesktopApp(initialShowMobilePreview: true),
      );
      await tester.pumpAndSettle();

      final shells = find.byType(YumeiroNavigationShell);
      expect(shells, findsNWidgets(2));
      final desktop = tester.element(shells.first);
      final mobile = tester.element(shells.last);
      expect(YumeiroResponsive.of(desktop).width, 530);
      expect(YumeiroModalityScope.modalityOf(desktop), YumeiroModality.pointer);
      expect(YumeiroModalityScope.modalityOf(mobile), YumeiroModality.touch);
      expect(
        find.descendant(of: shells.first, matching: find.byType(NavigationBar)),
        findsNothing,
      );
      expect(
        find.descendant(of: shells.last, matching: find.byType(NavigationBar)),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      final galleries = find.byType(GalleryShellPage);
      final desktopController = tester
          .widget<GalleryShellPage>(galleries.first)
          .controller;
      final mobileController = tester
          .widget<GalleryShellPage>(galleries.last)
          .controller;
      for (final page in [1, 2, 3, 4]) {
        desktopController.setNavIndex(page);
        mobileController.setNavIndex(page);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull, reason: 'gallery page $page');
      }
    },
  );
}
