import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

import '../pages/controls_page.dart';
import '../pages/display_page.dart';
import '../pages/layout_page.dart';
import '../pages/overlays_page.dart';
import '../pages/themes_page.dart';
import '../state/gallery_controller.dart';
import '../theme/gallery_registry.dart';
import '../widgets/gallery_widgets.dart';

/// Unified adaptive showcase shell assembled inside [YumeiroSearchHost],
/// [YumeiroSearchScope], and [YumeiroNavigationShell].
class GalleryShellPage extends StatefulWidget {
  const GalleryShellPage({
    super.key,
    required this.profile,
    required this.controller,
    this.mobilePreviewOpen = false,
    this.onToggleMobilePreview,
  });

  final GalleryProfile profile;
  final GalleryController controller;
  final bool mobilePreviewOpen;
  final VoidCallback? onToggleMobilePreview;

  @override
  State<GalleryShellPage> createState() => _GalleryShellPageState();
}

class _GalleryShellPageState extends State<GalleryShellPage> {
  final _exampleKeys = {
    for (final example in GalleryExample.values) example: GlobalKey(),
  };

  void _submitSearch(String query) {
    final controller = widget.controller;
    controller.setSearchScopeQuery(query);
    final term = query.trim().toLowerCase();
    if (term.isEmpty) return;

    final example = GalleryExample.find(
      term,
      YumeiroModalityScope.modalityOf(context),
    );
    if (example != null) {
      controller.setNavIndex(example.pageIndex);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final target = _exampleKeys[example]!.currentContext;
        if (target != null) Scrollable.ensureVisible(target);
      });
    } else if (term.contains('theme') || term.contains('主题')) {
      controller.setNavIndex(0);
    } else if (term.contains('control') || term.contains('控件')) {
      controller.setNavIndex(1);
    } else if (term.contains('display') || term.contains('展示')) {
      controller.setNavIndex(2);
    } else if (term.contains('layout') || term.contains('布局')) {
      controller.setNavIndex(3);
    } else if (term.contains('overlay') || term.contains('浮层')) {
      controller.setNavIndex(4);
    } else {
      showYumeiroToast(
        context,
        gText(
          context,
          en: 'No example found for “$query”',
          zh: '没有找到“$query”对应的示例',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final profile = widget.profile;
    final mobilePreviewOpen = widget.mobilePreviewOpen;
    final onToggleMobilePreview = widget.onToggleMobilePreview;
    final theme = YumeiroTheme.of(context);
    final effectiveCapability = YumeiroMaterialCapabilityScope.of(context)
        .resolveForRuntime();
    final isDesktop = profile == GalleryProfile.desktop;

    final destinations = [
      YumeiroNavDestination(
        id: 'themes',
        label: gText(context, en: 'Themes', zh: '主题预设'),
        icon: Icons.palette_outlined,
        selectedIcon: Icons.palette_rounded,
      ),
      YumeiroNavDestination(
        id: 'controls',
        label: gText(context, en: 'Controls', zh: '交互控件'),
        icon: Icons.tune_outlined,
        selectedIcon: Icons.tune_rounded,
      ),
      YumeiroNavDestination(
        id: 'display',
        label: gText(context, en: 'Display', zh: '展示组件'),
        icon: Icons.widgets_outlined,
        selectedIcon: Icons.widgets_rounded,
      ),
      YumeiroNavDestination(
        id: 'layout',
        label: gText(context, en: 'Layout', zh: '布局导航'),
        icon: Icons.view_quilt_outlined,
        selectedIcon: Icons.view_quilt_rounded,
      ),
      YumeiroNavDestination(
        id: 'overlays',
        label: gText(context, en: 'Overlays', zh: '浮层路由'),
        icon: Icons.layers_outlined,
        selectedIcon: Icons.layers_rounded,
      ),
    ];

    final pageTitles = [
      gText(context, en: 'Themes & Material Pipeline', zh: '主题与材质管线'),
      gText(context, en: 'Interactive Controls', zh: '交互控件库'),
      gText(context, en: 'Display & Media Surfaces', zh: '展示与媒体组件'),
      gText(context, en: 'Layout, Data & Navigation', zh: '布局、表格与页内导航'),
      gText(context, en: 'Overlays, Menus & Routes', zh: '浮层、菜单与路由转场'),
    ];

    final shell = Material(
      type: MaterialType.transparency,
      child: YumeiroSearchHost(
        child: YumeiroSearchScope(
          query: controller.searchScopeQuery,
          placeholder: gText(
            context,
            en: 'Find a page or example, such as Compact Table',
            zh: '搜索分类或示例，例如紧凑表',
          ),
          onSubmitted: _submitSearch,
          child: YumeiroNavigationShell(
            destinations: destinations,
            selectedIndex: controller.navIndex,
            onSelectedIndex: controller.setNavIndex,
            sidebarHeader: LayoutBuilder(
              builder: (context, constraints) {
                final responsive = YumeiroResponsive.of(context);
                final isCollapsed =
                    (constraints.hasBoundedWidth &&
                        constraints.maxWidth < 140) ||
                    responsive.isMedium ||
                    responsive.modality == YumeiroModality.touch;
                if (isCollapsed) {
                  return YumeiroTooltip(
                    message: 'Yumeiro UI',
                    child: Center(
                      child: Icon(
                        theme.icons.auto,
                        size: theme.iconSizes.md,
                        color: theme.accentSoft,
                      ),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Icon(
                        theme.icons.auto,
                        size: theme.iconSizes.md,
                        color: theme.accentSoft,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Yumeiro UI',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.typography.title.copyWith(
                            color: theme.text,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            sidebarFooter: isDesktop
                ? LayoutBuilder(
                    builder: (context, constraints) {
                      final responsive = YumeiroResponsive.of(context);
                      final isCollapsed =
                          (constraints.hasBoundedWidth &&
                              constraints.maxWidth < 140) ||
                          responsive.isMedium;
                      final showBlurWarning =
                          controller.isOpticalGlassPreset &&
                          effectiveCapability ==
                              YumeiroMaterialCapability.blurOnly;
                      final mobileLabel = mobilePreviewOpen
                          ? gText(context, en: 'Close Viewport', zh: '关闭视口')
                          : gText(context, en: 'Mobile Viewport', zh: '手机视口');
                      final mobileIcon = mobilePreviewOpen
                          ? Icons.close_rounded
                          : Icons.smartphone_rounded;
                      if (isCollapsed) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (showBlurWarning) ...[
                              YumeiroTooltip(
                                message: gText(
                                  context,
                                  en: 'Blur Fallback',
                                  zh: '模糊降级',
                                ),
                                child: Icon(
                                  theme.icons.warning,
                                  size: theme.iconSizes.md,
                                  color: theme.colors.warning,
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            if (onToggleMobilePreview != null)
                              YumeiroButton(
                                variant: YumeiroButtonVariant.ghost,
                                icon: mobileIcon,
                                tooltip: mobileLabel,
                                selected: mobilePreviewOpen,
                                onPressed: onToggleMobilePreview,
                              ),
                          ],
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (showBlurWarning) ...[
                            YumeiroBadge(
                              label: gText(
                                context,
                                en: 'Blur Fallback',
                                zh: '模糊降级',
                              ),
                              statusRole: YumeiroStatusRole.warning,
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (onToggleMobilePreview != null)
                            YumeiroButton(
                              label: mobileLabel,
                              icon: mobileIcon,
                              selected: mobilePreviewOpen,
                              onPressed: onToggleMobilePreview,
                            ),
                        ],
                      );
                    },
                  )
                : null,
            body: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      isDesktop ? theme.spacing.page : 16,
                      isDesktop ? theme.spacing.xl : theme.spacing.md,
                      isDesktop ? theme.spacing.page : 16,
                      0,
                    ),
                    child: YumeiroPageHeader(
                      title: pageTitles[controller.navIndex],
                      actions: [
                        const YumeiroSearchButton(
                          key: ValueKey('gallery-global-search'),
                        ),
                        YumeiroButton(
                          label: controller.locale.languageCode == 'zh'
                              ? 'EN'
                              : '中文',
                          onPressed: () => controller.setLocale(
                            controller.locale.languageCode == 'zh'
                                ? const Locale('en')
                                : const Locale('zh'),
                          ),
                        ),
                      ],
                      bottomDivider: true,
                    ),
                  ),
                  Expanded(
                    child: YumeiroScrollView(
                      key: ValueKey('gallery-page-${controller.navIndex}'),
                      padding: EdgeInsets.all(
                        isDesktop ? theme.spacing.page : 16,
                      ),
                      child: GalleryExampleScope(
                        anchors: _exampleKeys,
                        child: switch (controller.navIndex) {
                          0 => ThemesPage(
                            controller: controller,
                            profile: profile,
                          ),
                          1 => ControlsPage(controller: controller),
                          2 => DisplayPage(controller: controller),
                          3 => LayoutPage(controller: controller),
                          _ => OverlaysPage(
                            controller: controller,
                            profile: profile,
                          ),
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    // Keep the page's semantics together when a pushed route covers and then
    // restores its deeply scrolled content.
    return Semantics(container: true, child: shell);
  }
}
