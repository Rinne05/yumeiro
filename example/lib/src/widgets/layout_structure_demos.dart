import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

import 'gallery_widgets.dart';

enum _NavigationLayout { phone, rail, sidebar }

class GalleryNavigationShellDemo extends StatefulWidget {
  const GalleryNavigationShellDemo({super.key});

  @override
  State<GalleryNavigationShellDemo> createState() =>
      _GalleryNavigationShellDemoState();
}

class _GalleryNavigationShellDemoState
    extends State<GalleryNavigationShellDemo> {
  var _layout = _NavigationLayout.phone;
  var _selected = 0;

  @override
  Widget build(BuildContext context) {
    final spacing = YumeiroTheme.of(context).spacing;
    final (width, modality) = switch (_layout) {
      _NavigationLayout.phone => (390.0, YumeiroModality.touch),
      _NavigationLayout.rail => (720.0, YumeiroModality.touch),
      _NavigationLayout.sidebar => (1024.0, YumeiroModality.pointer),
    };
    final destinations = [
      for (final (label, icon) in const [
        ('A', Icons.home_outlined),
        ('B', Icons.list_alt),
        ('C', Icons.star_outline),
      ])
        YumeiroNavDestination(id: label, label: label, icon: icon),
    ];
    const height = 216.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: spacing.md,
      children: [
        Wrap(
          spacing: spacing.sm,
          runSpacing: spacing.sm,
          children: [
            for (final (layout, en, zh) in const [
              (_NavigationLayout.phone, 'Phone', '底部导航'),
              (_NavigationLayout.rail, 'Touch rail', '触控导航轨'),
              (_NavigationLayout.sidebar, 'Sidebar', '桌面侧栏'),
            ])
              YumeiroButton(
                key: ValueKey('gallery-navigation-${layout.name}'),
                label: gText(context, en: en, zh: zh),
                variant: YumeiroButtonVariant.secondary,
                selected: layout == _layout,
                onPressed: () => setState(() => _layout = layout),
              ),
          ],
        ),
        GalleryComponent(
          'YumeiroNavigationShell',
          child: SizedBox(
            height: height,
            child: LayoutBuilder(
              builder: (context, constraints) => YumeiroCard.panel(
                padding: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    size: Size(width, height),
                    padding: EdgeInsets.zero,
                    viewPadding: EdgeInsets.zero,
                  ),
                  child: YumeiroModalityScope(
                    modality: modality,
                    child: YumeiroNavigationShell(
                      key: const ValueKey('gallery-navigation-shell-preview'),
                      destinations: destinations,
                      selectedIndex: _selected,
                      onSelectedIndex: (index) =>
                          setState(() => _selected = index),
                      collapsed: constraints.maxWidth < 320,
                      body: Center(
                        child: Text(
                          gSample(
                            context,
                            'Example ${destinations[_selected].id}',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class GalleryPageScaffoldDemo extends StatelessWidget {
  const GalleryPageScaffoldDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final spacing = YumeiroTheme.of(context).spacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: spacing.md,
      children: [
        _pageWithList(context),
        GalleryComponent(
          'YumeiroScrollView',
          child: YumeiroCard.panel(
            role: YumeiroSurfaceRole.inset,
            padding: EdgeInsets.zero,
            child: SizedBox(
              height: 112,
              width: double.infinity,
              child: YumeiroScrollView(
                key: const ValueKey('gallery-scroll-content'),
                padding: EdgeInsets.all(spacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: spacing.md,
                  children: [
                    for (final label in const ['A', 'B', 'C'])
                      YumeiroCard.panel(
                        child: Text(gSample(context, 'Example $label')),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _pageWithList(BuildContext context) {
    final spacing = YumeiroTheme.of(context).spacing;
    return GalleryComponent(
      'YumeiroPageScaffold',
      child: SizedBox(
        height: 300,
        width: double.infinity,
        child: YumeiroCard.panel(
          padding: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: YumeiroPageScaffold(
            appBar: YumeiroPageHeader.compact(
              title: gSample(context, 'Example A'),
            ),
            body: Padding(
              padding: EdgeInsets.symmetric(horizontal: spacing.md),
              child: GalleryComponent(
                'YumeiroScrollView.list',
                child: Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    child: YumeiroScrollView.list(
                      key: const ValueKey('gallery-page-scroll-list'),
                      children: [
                        for (var i = 1; i <= 10; i++) ...[
                          if (i > 1) const YumeiroDivider(),
                          Padding(
                            padding: EdgeInsets.all(spacing.sm),
                            child: Text(gSample(context, 'Example $i')),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
