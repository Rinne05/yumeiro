import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/semantics.dart' show SemanticsRole;
import 'package:material_ui/material_ui.dart';

import '../../foundation/input.dart';
import '../../foundation/modality.dart';
import '../../primitives/backdrop_group.dart';
import '../../primitives/visual_surface.dart';
import '../../theme/semantic_visuals.dart';
import '../../theme/theme.dart';
import '../../theme/theme_extension.dart';
import '../../theme/visual_role.dart';
import '../overlays/tooltip.dart';

/// Labeled destination shared by the navigation bar, rail, and sidebar.
@immutable
class YumeiroNavDestination {
  const YumeiroNavDestination({
    required this.id,
    required this.label,
    required this.icon,
    this.selectedIcon,
    this.badge,
  });

  final String id;
  final String label;
  final IconData icon;
  final IconData? selectedIcon;
  final Widget? badge;
}

/// Adaptive application navigation shell:
/// - In `touch` modality: renders a bottom navigation bar on compact screens
///   and a touch navigation rail at wider sizes.
/// - In `pointer` modality: renders a collapsed or expanded sidebar using
///   [YumeiroSurfaceRole.navigation].
///
/// With fewer than two destinations, the shell displays only [body]. Layout
/// changes keep the body mounted while its widget type and key remain the same.
class YumeiroNavigationShell extends StatelessWidget {
  const YumeiroNavigationShell({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelectedIndex,
    required this.body,
    this.sidebarHeader,
    this.sidebarFooter,
    this.collapsed = false,
  });

  final List<YumeiroNavDestination> destinations;

  /// Current destination's index in [destinations], owned by the host.
  /// Ignored when fewer than two destinations are available.
  final int selectedIndex;

  /// Requests a destination change. Update [selectedIndex] and [body] from
  /// the same state or route.
  final ValueChanged<int> onSelectedIndex;
  final Widget body;
  final Widget? sidebarHeader;
  final Widget? sidebarFooter;

  /// Collapses the pointer sidebar to icons. Compact and medium pointer
  /// layouts always use the collapsed layout.
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    final responsive = YumeiroResponsive.of(context);
    final touch = responsive.modality == YumeiroModality.touch;
    final useBottomBar = touch && responsive.isCompact;
    final showNavigation = destinations.length >= 2;
    final sidebarCollapsed = collapsed || !responsive.isExpanded;

    return YumeiroVisualSurface(
      role: YumeiroSurfaceRole.canvas,
      child: Flex(
        direction: useBottomBar ? Axis.vertical : Axis.horizontal,
        children: [
          if (showNavigation && !useBottomBar)
            if (touch)
              _TouchNavRail(
                destinations: destinations,
                selectedIndex: selectedIndex,
                onSelectedIndex: onSelectedIndex,
                leading: sidebarHeader,
                trailing: sidebarFooter,
              )
            else
              _SidebarNav(
                destinations: destinations,
                selectedIndex: selectedIndex,
                onSelectedIndex: onSelectedIndex,
                header: sidebarHeader,
                footer: sidebarFooter,
                collapsed: sidebarCollapsed,
                width: responsive.sidebarWidth(collapsed: sidebarCollapsed),
              ),
          Expanded(key: const ValueKey('body'), child: body),
          if (showNavigation && useBottomBar)
            _BottomNavBar(
              destinations: destinations,
              selectedIndex: selectedIndex,
              onSelectedIndex: onSelectedIndex,
            ),
        ],
      ),
    );
  }
}

class _TouchNavRail extends StatelessWidget {
  const _TouchNavRail({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelectedIndex,
    this.leading,
    this.trailing,
  });

  final List<YumeiroNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelectedIndex;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final spacing = YumeiroTheme.of(context).spacing;
    final metrics = YumeiroModalityScope.metricsOf(context);
    final localizations = MaterialLocalizations.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;

    return YumeiroVisualSurface(
      role: YumeiroSurfaceRole.navigation,
      visualInsets: EdgeInsets.zero,
      child: SafeArea(
        left: !rtl,
        right: rtl,
        child: YumeiroBackdropGroup(
          child: PrimaryScrollController.none(
            child: Material(
              type: MaterialType.transparency,
              child: SizedBox(
                width: metrics.minTargetSize + 2 * (spacing.lg + spacing.xs),
                child: LayoutBuilder(
                  builder: (context, constraints) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (leading != null)
                        Padding(
                          padding: EdgeInsets.all(spacing.sm),
                          child: leading,
                        ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(vertical: spacing.xs),
                          child: Semantics(
                            role: SemanticsRole.tabBar,
                            container: true,
                            explicitChildNodes: true,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (var i = 0; i < destinations.length; i++)
                                  _TouchRailDestination(
                                    key: ValueKey(destinations[i].id),
                                    destination: destinations[i],
                                    indexLabel: kIsWeb
                                        ? null
                                        : localizations.tabLabel(
                                            tabIndex: i + 1,
                                            tabCount: destinations.length,
                                          ),
                                    selected: i == selectedIndex,
                                    onTap: () => onSelectedIndex(i),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (trailing != null)
                        ConstrainedBox(
                          // Share the available height with the scrolling destinations.
                          constraints: BoxConstraints(
                            maxHeight: constraints.maxHeight / 2,
                          ),
                          child: Padding(
                            padding: EdgeInsets.only(bottom: spacing.sm),
                            child: trailing,
                          ),
                        ),
                    ],
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

EdgeInsets _touchIndicatorInsets(YumeiroThemeExtension theme) =>
    EdgeInsets.symmetric(
      horizontal: theme.spacing.xs,
      vertical: theme.spacing.xs / 2,
    );

TextStyle _touchLabelStyle(
  YumeiroThemeExtension theme,
  YumeiroNavigationItemVisual visual,
  bool selected,
) => theme.typography.caption.copyWith(
  color: selected
      ? visual.destinationForeground ?? visual.iconForeground
      : visual.labelForeground,
  fontWeight: visual.labelWeight,
);

class _TouchRailDestination extends StatefulWidget {
  const _TouchRailDestination({
    super.key,
    required this.destination,
    required this.indexLabel,
    required this.selected,
    required this.onTap,
  });

  final YumeiroNavDestination destination;
  final String? indexLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_TouchRailDestination> createState() => _TouchRailDestinationState();
}

class _TouchRailDestinationState extends State<_TouchRailDestination> {
  final _interaction = WidgetStatesController();

  @override
  void dispose() {
    _interaction.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final metrics = YumeiroModalityScope.metricsOf(context);
    final destination = widget.destination;
    final selected = widget.selected;

    return MergeSemantics(
      child: Semantics(
        role: SemanticsRole.tab,
        selected: selected,
        child: YumeiroTooltip(
          message: destination.label,
          excludeFromSemantics: true,
          child: InkWell(
            statesController: _interaction,
            splashFactory: NoSplash.splashFactory,
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            onTap: widget.onTap,
            child: ListenableBuilder(
              listenable: _interaction,
              builder: (context, _) {
                final showFocus = YumeiroInputScope.keyboardFocusOf(context);
                final interactions = {
                  for (final state in _interaction.value)
                    if (state != WidgetState.focused || showFocus) state,
                };
                final visual = theme.visuals.navigationItem({
                  ...interactions,
                  if (selected) WidgetState.selected,
                });
                final indicator =
                    visual.destinationIndicator ??
                    theme.visuals.item(
                      YumeiroItemRole.navigation,
                      interactions,
                    );
                final appearance = theme.isMotionEnabled('navigationTransition')
                    ? indicator
                    : indicator.copyWith(
                        transition: YumeiroVisualTransition.instant,
                      );

                return YumeiroResolvedVisualSurface(
                  appearance: appearance,
                  visualInsets: _touchIndicatorInsets(theme),
                  constraints: BoxConstraints(
                    minHeight: metrics.minTargetSize + theme.spacing.sm,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: theme.spacing.sm,
                    vertical: theme.spacing.xs,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    spacing: theme.spacing.xs,
                    children: [
                      IconTheme.merge(
                        data: IconThemeData(
                          color:
                              visual.destinationForeground ??
                              visual.iconForeground,
                        ),
                        child: _DestinationIcon(
                          destination: destination,
                          selected: selected,
                        ),
                      ),
                      Text(
                        destination.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: _touchLabelStyle(theme, visual, selected),
                        semanticsLabel: widget.indexLabel == null
                            ? null
                            : '${destination.label}\n${widget.indexLabel}',
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _DestinationIcon extends StatelessWidget {
  const _DestinationIcon({
    required this.destination,
    required this.selected,
    this.compact = false,
  });

  final YumeiroNavDestination destination;
  final bool selected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final iconData = selected
        ? (destination.selectedIcon ?? destination.icon)
        : destination.icon;
    final iconWidget = SizedBox(
      width: compact ? 44 : 64,
      height: compact ? theme.iconSizes.md : 32,
      child: Icon(
        iconData,
        size: theme.iconSizes.md,
        color: compact
            ? theme.visuals.navigationItem({
                if (selected) WidgetState.selected,
              }).iconForeground
            : null,
      ),
    );
    if (destination.badge == null) return iconWidget;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        iconWidget,
        PositionedDirectional(
          end: compact ? 0 : 10,
          top: 0,
          child: destination.badge!,
        ),
      ],
    );
  }
}

class _SidebarNav extends StatelessWidget {
  const _SidebarNav({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelectedIndex,
    required this.collapsed,
    required this.width,
    this.header,
    this.footer,
  });

  final List<YumeiroNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelectedIndex;
  final bool collapsed;
  final double width;
  final Widget? header;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final padding = EdgeInsets.symmetric(
      horizontal: collapsed ? 12 : 14,
      vertical: 18,
    );
    return AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : theme.motion.normal,
      curve: Curves.easeOutCubic,
      width: width,
      child: YumeiroVisualSurface(
        role: YumeiroSurfaceRole.navigation,
        clipBehavior: Clip.antiAlias,
        padding: padding,
        child: YumeiroBackdropGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (header != null) ...[
                header!,
                SizedBox(height: theme.spacing.md),
              ],
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Keep the badge and icon together while the sidebar grows.
                    final iconsOnly =
                        collapsed ||
                        constraints.maxWidth < width - padding.horizontal;
                    return ListView.builder(
                      itemCount: destinations.length,
                      itemBuilder: (context, index) => _SidebarItem(
                        destination: destinations[index],
                        selected: index == selectedIndex,
                        collapsed: iconsOnly,
                        onTap: () => onSelectedIndex(index),
                      ),
                    );
                  },
                ),
              ),
              if (footer != null) ...[
                SizedBox(height: theme.spacing.md),
                footer!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.destination,
    required this.selected,
    required this.collapsed,
    required this.onTap,
  });

  final YumeiroNavDestination destination;
  final bool selected;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final navVisual = theme.visuals.navigationItem({
      if (selected) WidgetState.selected,
    });
    final iconData = selected
        ? (destination.selectedIcon ?? destination.icon)
        : destination.icon;

    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 40),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          if (navVisual.indicator != null)
            Positioned(
              left: 0,
              top: 10,
              bottom: 10,
              child: YumeiroResolvedVisualSurface(
                appearance: navVisual.indicator!,
                width: 3,
                child: const SizedBox.shrink(),
              ),
            ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: collapsed ? 0 : 12,
              vertical: 8,
            ),
            child: Row(
              mainAxisAlignment: collapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                if (collapsed)
                  _DestinationIcon(
                    destination: destination,
                    selected: selected,
                    compact: true,
                  )
                else ...[
                  Icon(
                    iconData,
                    size: theme.iconSizes.md,
                    color: navVisual.iconForeground,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      destination.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.typography.body.copyWith(
                        color: navVisual.labelForeground,
                        fontWeight: navVisual.labelWeight,
                      ),
                    ),
                  ),
                  if (destination.badge != null) destination.badge!,
                ],
              ],
            ),
          ),
        ],
      ),
    );

    return Semantics(
      label: destination.label,
      button: true,
      selected: selected,
      child: YumeiroTooltip(
        message: collapsed ? destination.label : '',
        child: YumeiroInteractiveVisualSurface(
          role: YumeiroItemRole.navigation,
          selected: selected,
          onTap: onTap,
          child: content,
        ),
      ),
    );
  }
}

class _BottomNavBar extends StatefulWidget {
  const _BottomNavBar({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelectedIndex,
  });

  final List<YumeiroNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelectedIndex;

  @override
  State<_BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<_BottomNavBar> {
  int? _hoveredIndex;
  int? _pressedIndex;
  int? _focusedIndex;

  @override
  void didUpdateWidget(_BottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final count = widget.destinations.length;
    if (_hoveredIndex != null && _hoveredIndex! >= count) _hoveredIndex = null;
    if (_pressedIndex != null && _pressedIndex! >= count) _pressedIndex = null;
    if (_focusedIndex != null && _focusedIndex! >= count) _focusedIndex = null;
  }

  void _setHovered(int index, bool value) {
    final next = value
        ? index
        : (_hoveredIndex == index ? null : _hoveredIndex);
    if (next != _hoveredIndex) setState(() => _hoveredIndex = next);
  }

  void _setPressed(int index, bool value) {
    final next = value
        ? index
        : (_pressedIndex == index ? null : _pressedIndex);
    if (next != _pressedIndex) setState(() => _pressedIndex = next);
  }

  void _setFocused(int index, bool value) {
    final next = value
        ? index
        : (_focusedIndex == index ? null : _focusedIndex);
    if (next != _focusedIndex) setState(() => _focusedIndex = next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final interactionIndex = _pressedIndex ?? _hoveredIndex ?? _focusedIndex;
    final interactionStates = interactionIndex == null
        ? const <WidgetState>{}
        : <WidgetState>{
            if (_hoveredIndex == interactionIndex) WidgetState.hovered,
            if (_pressedIndex == interactionIndex) WidgetState.pressed,
            if (_focusedIndex == interactionIndex) WidgetState.focused,
          };
    final selectedStates = <WidgetState>{
      WidgetState.selected,
      if (_hoveredIndex == widget.selectedIndex) WidgetState.hovered,
      if (_pressedIndex == widget.selectedIndex) WidgetState.pressed,
      if (_focusedIndex == widget.selectedIndex) WidgetState.focused,
    };

    // The bottom bar owns the bottom inset, never the status-bar inset.
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: YumeiroVisualSurface(
        role: YumeiroSurfaceRole.navigation,
        visualInsets: EdgeInsets.zero,
        child: YumeiroBackdropGroup(
          child: _NavigationIndicatorHost(
            count: widget.destinations.length,
            selectedIndex: widget.selectedIndex,
            selectedStates: selectedStates,
            interactionIndex: interactionIndex,
            interactionStates: interactionStates,
            indicatorInsets: _touchIndicatorInsets(theme),
            builder: (anchors) => NavigationBarTheme(
              data: NavigationBarThemeData(
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                shadowColor: Colors.transparent,
                elevation: 0,
                height: 64,
                labelPadding: EdgeInsets.only(top: theme.spacing.xs),
                indicatorColor: Colors.transparent,
                overlayColor: const WidgetStatePropertyAll(Colors.transparent),
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                iconTheme: WidgetStateProperty.resolveWith((states) {
                  final visual = theme.visuals.navigationItem(states);
                  return IconThemeData(
                    size: theme.iconSizes.md,
                    color:
                        visual.destinationForeground ?? visual.iconForeground,
                  );
                }),
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  final visual = theme.visuals.navigationItem(states);
                  return _touchLabelStyle(
                    theme,
                    visual,
                    states.contains(WidgetState.selected),
                  );
                }),
              ),
              child: NavigationBar(
                selectedIndex: widget.selectedIndex,
                onDestinationSelected: widget.onSelectedIndex,
                destinations: [
                  for (var i = 0; i < widget.destinations.length; i++)
                    KeyedSubtree(
                      key: anchors[i],
                      child: MouseRegion(
                        onEnter: (_) => _setHovered(i, true),
                        onExit: (_) => _setHovered(i, false),
                        child: Listener(
                          behavior: HitTestBehavior.translucent,
                          onPointerDown: (_) => _setPressed(i, true),
                          onPointerUp: (_) => _setPressed(i, false),
                          onPointerCancel: (_) => _setPressed(i, false),
                          child: Focus(
                            canRequestFocus: false,
                            onFocusChange: (focused) => _setFocused(i, focused),
                            child: YumeiroTooltip(
                              message: widget.destinations[i].label,
                              child: NavigationDestination(
                                tooltip: '',
                                icon: _DestinationIcon(
                                  destination: widget.destinations[i],
                                  selected: i == widget.selectedIndex,
                                ),
                                label: widget.destinations[i].label,
                              ),
                            ),
                          ),
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
  }
}

/// Measures the selected and hovered/pressed destination bounds and renders
/// matching [YumeiroResolvedVisualSurface] / [YumeiroVisualSurface] pills
/// behind native navigation destinations.
class _NavigationIndicatorHost extends StatefulWidget {
  const _NavigationIndicatorHost({
    required this.count,
    required this.selectedIndex,
    required this.builder,
    this.selectedStates = const {WidgetState.selected},
    this.interactionIndex,
    this.interactionStates = const <WidgetState>{},
    this.indicatorInsets = EdgeInsets.zero,
  });

  final int count;
  final int selectedIndex;
  final Set<WidgetState> selectedStates;
  final int? interactionIndex;
  final Set<WidgetState> interactionStates;
  final Widget Function(List<GlobalKey> anchors) builder;
  final EdgeInsets indicatorInsets;

  @override
  State<_NavigationIndicatorHost> createState() =>
      _NavigationIndicatorHostState();
}

class _NavigationIndicatorHostState extends State<_NavigationIndicatorHost> {
  final _stack = GlobalKey();
  final _anchors = <GlobalKey>[];
  Rect? _target;
  Rect? _interactionTarget;
  BoxConstraints? _constraints;
  bool _scheduled = false;
  bool _hasIndicator = false;
  int? _visibleInteractionIndex;

  @override
  void initState() {
    super.initState();
    _syncAnchors();
  }

  @override
  void didUpdateWidget(_NavigationIndicatorHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.count != widget.count) {
      _syncAnchors();
      _target = null;
      _interactionTarget = null;
    }
    if (widget.interactionIndex != oldWidget.interactionIndex ||
        widget.interactionStates.isEmpty) {
      final index = widget.interactionIndex;
      _interactionTarget = index != null && widget.interactionStates.isNotEmpty
          ? _rectFor(index)
          : null;
    }
  }

  void _syncAnchors() {
    while (_anchors.length < widget.count) {
      _anchors.add(GlobalKey());
    }
    if (_anchors.length > widget.count) {
      _anchors.removeRange(widget.count, _anchors.length);
    }
  }

  Rect? _rectFor(int index) {
    if (index < 0 || index >= _anchors.length) return null;
    final parent = _stack.currentContext?.findRenderObject() as RenderBox?;
    final anchor =
        _anchors[index].currentContext?.findRenderObject() as RenderBox?;
    if (parent == null ||
        anchor == null ||
        !anchor.hasSize ||
        !parent.hasSize) {
      return null;
    }
    return widget.indicatorInsets.deflateRect(
      MatrixUtils.transformRect(
        anchor.getTransformTo(parent),
        Offset.zero & anchor.size,
      ),
    );
  }

  void _measure() {
    if (_scheduled || (!_hasIndicator && _visibleInteractionIndex == null)) {
      return;
    }
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!mounted) return;
      final nextTarget = _hasIndicator ? _rectFor(widget.selectedIndex) : null;
      final index = _visibleInteractionIndex;
      final nextInteraction = index == null ? null : _rectFor(index);
      if (nextTarget != _target || nextInteraction != _interactionTarget) {
        setState(() {
          _target = nextTarget;
          _interactionTarget = nextInteraction;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final appearance = theme.visuals
        .navigationItem(widget.selectedStates)
        .destinationIndicator;
    _hasIndicator = appearance != null;
    if (!_hasIndicator) _target = null;

    final interactionIndex = widget.interactionIndex;
    _visibleInteractionIndex =
        interactionIndex != null &&
            widget.interactionStates.isNotEmpty &&
            (!_hasIndicator || interactionIndex != widget.selectedIndex)
        ? interactionIndex
        : null;
    if (_visibleInteractionIndex == null) _interactionTarget = null;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (_constraints != constraints) {
          _constraints = constraints;
          _target = null;
          _interactionTarget = null;
        }
        _measure();
        final target = _target;
        final moving = target != null && appearance != null;
        final interactionRect = _interactionTarget;
        return Stack(
          key: _stack,
          children: [
            if (interactionRect != null)
              Positioned.fromRect(
                rect: interactionRect,
                child: IgnorePointer(
                  child: YumeiroVisualSurface(
                    role: YumeiroItemRole.navigation,
                    states: widget.interactionStates,
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            if (moving)
              AnimatedPositioned(
                left: target.left,
                top: target.top,
                width: target.width,
                height: target.height,
                duration:
                    MediaQuery.disableAnimationsOf(context) ||
                        !theme.isMotionEnabled('navigationTransition')
                    ? Duration.zero
                    : theme.motion.normal,
                curve: Curves.easeOutCubic,
                child: IgnorePointer(
                  child: YumeiroResolvedVisualSurface(
                    appearance: appearance,
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            widget.builder(_anchors),
          ],
        );
      },
    );
  }
}
