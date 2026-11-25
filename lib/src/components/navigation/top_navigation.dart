import 'dart:math' as math;
import 'dart:ui' show SemanticsRole;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../primitives/visual_surface.dart';
import '../../theme/theme.dart';

/// Links page motion and top-navigation tab selection without owning state.
class YumeiroNavigationMotionScope extends StatefulWidget {
  const YumeiroNavigationMotionScope({super.key, required this.child});

  final Widget child;

  @override
  State<YumeiroNavigationMotionScope> createState() =>
      _YumeiroNavigationMotionScopeState();
}

class _YumeiroNavigationMotionScopeState
    extends State<YumeiroNavigationMotionScope> {
  final _motion = _NavigationMotion();

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _NavigationMotionScope(notifier: _motion, child: widget.child);
}

class _NavigationMotionScope extends InheritedNotifier<_NavigationMotion> {
  const _NavigationMotionScope({required super.notifier, required super.child});
}

class _NavigationMotion extends ChangeNotifier {
  double? index;
  ValueChanged<Object?>? navigate;
  bool _disposed = false;

  void update(double progress) {
    if (_disposed || index == progress) return;
    index = progress;
    notifyListeners();
  }

  void reset() {
    if (_disposed || index == null) return;
    index = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Value and visible label for a tab in [YumeiroTopNavigation].
@immutable
class YumeiroTopNavigationDestination<T> {
  const YumeiroTopNavigationDestination({
    required this.value,
    required this.label,
  });

  final T value;
  final String label;
}

/// Controlled horizontal top tab navigation with keyboard support and animated
/// sliding indicator driven by [YumeiroNavigationMotionScope].
class YumeiroTopNavigation<T> extends StatefulWidget {
  const YumeiroTopNavigation({
    super.key,
    required this.value,
    required this.destinations,
    required this.onChanged,
    this.gap = 32,
    this.minGap = 12,
  }) : assert(gap >= minGap && minGap >= 0);

  /// Places the tabs above a swipeable pager and links their motion. The pager
  /// builds pages in [destinations] order and requires bounded height.
  /// [between] stays below the tabs when the page changes.
  static Widget paged<V>({
    Key? key,
    required V value,
    required List<YumeiroTopNavigationDestination<V>> destinations,
    required ValueChanged<V>? onChanged,
    required Widget Function(BuildContext context, V value) itemBuilder,
    Widget? between,
    double gap = 32,
    double minGap = 12,
  }) => YumeiroNavigationMotionScope(
    key: key,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        YumeiroTopNavigation<V>(
          value: value,
          destinations: destinations,
          onChanged: onChanged,
          gap: gap,
          minGap: minGap,
        ),
        ?between,
        Expanded(
          child: YumeiroNavigationPager<V>(
            value: value,
            values: [for (final destination in destinations) destination.value],
            onChanged: onChanged,
            itemBuilder: itemBuilder,
          ),
        ),
      ],
    ),
  );

  /// Active destination supplied by the caller.
  final T value;
  final List<YumeiroTopNavigationDestination<T>> destinations;

  /// Reports a requested destination. Pass the new value back to the tabs
  /// and to a linked [YumeiroNavigationPager].
  final ValueChanged<T>? onChanged;
  final double gap;
  final double minGap;

  @override
  State<YumeiroTopNavigation<T>> createState() =>
      _YumeiroTopNavigationState<T>();
}

class _YumeiroTopNavigationState<T> extends State<YumeiroTopNavigation<T>> {
  final _scroll = ScrollController();
  final _keys = <T, GlobalKey>{};
  final _focus = <T, FocusNode>{};
  bool _revealPending = false;
  Object? _revealLayout;

  void _revealSelected() {
    if (_revealPending) return;
    _revealPending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _revealPending = false;
      if (!mounted) return;
      final context = _keys[widget.value]?.currentContext;
      if (context == null) return;
      final render = context.findRenderObject();
      if (render == null || !_scroll.hasClients) return;
      _scroll.position.ensureVisible(
        render,
        alignment: .5,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : YumeiroTheme.of(context).motion.normal,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    PaintingBinding.instance.systemFonts.addListener(_handleSystemFontsChange);
  }

  void _handleSystemFontsChange() => setState(() {});

  @override
  void dispose() {
    PaintingBinding.instance.systemFonts.removeListener(
      _handleSystemFontsChange,
    );
    _scroll.dispose();
    for (final node in _focus.values) {
      node.dispose();
    }
    super.dispose();
  }

  void _move(int offset) {
    if (widget.onChanged == null) return;
    var index = widget.destinations.indexWhere(
      (item) => item.value == widget.value,
    );
    for (var i = 0; i < widget.destinations.length; i++) {
      if (_focus[widget.destinations[i].value]?.hasFocus ?? false) {
        index = i;
        break;
      }
    }
    final next = index + offset;
    if (index < 0 || next < 0 || next >= widget.destinations.length) return;
    final value = widget.destinations[next].value;
    final navigate = context
        .getInheritedWidgetOfExactType<_NavigationMotionScope>()
        ?.notifier
        ?.navigate;
    if (navigate != null) {
      navigate(value);
    } else {
      widget.onChanged!(value);
    }
    _focus[value]?.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final values = widget.destinations.map((item) => item.value).toSet();
    assert(values.length == widget.destinations.length);
    for (final value
        in _focus.keys.where((value) => !values.contains(value)).toList()) {
      _focus.remove(value)!.dispose();
      _keys.remove(value);
    }
    for (final value in values) {
      _keys.putIfAbsent(value, GlobalKey.new);
      _focus.putIfAbsent(value, FocusNode.new);
    }
    final theme = YumeiroTheme.of(context);
    final direction = Directionality.of(context);
    final textStyle = theme.typography.title;
    final visuals = theme.visuals;
    final idleWeight = visuals.navigationItem({}).labelWeight;
    final activeWeight = visuals.navigationItem({
      WidgetState.selected,
    }).labelWeight;
    final styles = [
      textStyle.copyWith(fontWeight: idleWeight),
      if (activeWeight != idleWeight)
        textStyle.copyWith(fontWeight: activeWeight),
    ];
    final painter = TextPainter(
      textDirection: direction,
      textScaler: MediaQuery.textScalerOf(context),
      locale: Localizations.maybeLocaleOf(context),
      maxLines: 1,
    );
    final widths = <double>[];
    var height = 48.0;
    try {
      for (final item in widget.destinations) {
        var width = 0.0;
        for (final style in styles) {
          painter
            ..text = TextSpan(text: item.label, style: style)
            ..layout();
          width = math.max(width, painter.width);
          height = math.max(height, painter.height + 22);
        }
        widths.add(math.max(56, width.ceilToDouble() + 32));
      }
    } finally {
      painter.dispose();
    }
    final total = widths.fold(0.0, (sum, width) => sum + width);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
            _move(direction == TextDirection.ltr ? -1 : 1),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
            _move(direction == TextDirection.ltr ? 1 : -1),
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Page motion updates the tab visuals without measuring labels.
            final motion = context
                .dependOnInheritedWidgetOfExactType<_NavigationMotionScope>()
                ?.notifier;
            final gaps = math.max(0, widths.length - 1);
            final gap = gaps == 0
                ? 0.0
                : ((constraints.maxWidth - total) / gaps)
                      .clamp(widget.minGap, widget.gap)
                      .toDouble();
            final itemsWidth = total + gap * gaps;
            final width = math.max(itemsWidth, constraints.maxWidth);
            final inset = (width - itemsWidth) / 2;
            final revealLayout = (
              widget.value,
              constraints.maxWidth,
              height,
              gap,
              direction,
              Object.hashAll(widths),
              Object.hashAll(widget.destinations.map((item) => item.value)),
            );
            if (_revealLayout != revealLayout) {
              _revealLayout = revealLayout;
              _revealSelected();
            }
            final selected = widget.destinations.indexWhere(
              (item) => item.value == widget.value,
            );
            final motionIndex = motion?.index;
            final tracking = motionIndex != null && widget.onChanged != null;
            double markerPosition(int index) =>
                inset +
                widths.take(index).fold(0.0, (sum, width) => sum + width) +
                index * gap +
                widths[index] / 2 -
                10;
            final progress = selected < 0
                ? -1.0
                : tracking
                ? motionIndex.clamp(0.0, widths.length - 1.0)
                : selected.toDouble();
            var markerLeft = 0.0;
            if (selected >= 0) {
              final from = progress.floor();
              final to = progress.ceil();
              markerLeft =
                  markerPosition(from) +
                  (markerPosition(to) - markerPosition(from)) *
                      (progress - from);
              if (direction == TextDirection.rtl) {
                markerLeft = width - markerLeft - 20;
              }
            }
            final marker = visuals.navigationItem({
              WidgetState.selected,
              if (widget.onChanged == null) WidgetState.disabled,
            }).topIndicator;
            return SingleChildScrollView(
              controller: _scroll,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: width,
                height: height,
                child: Stack(
                  children: [
                    Semantics(
                      container: true,
                      role: SemanticsRole.tabBar,
                      explicitChildNodes: true,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (
                            var index = 0;
                            index < widget.destinations.length;
                            index++
                          ) ...[
                            if (index > 0) SizedBox(width: gap),
                            _TopNavigationItem(
                              key: ValueKey(widget.destinations[index].value),
                              revealKey:
                                  _keys[widget.destinations[index].value]!,
                              focusNode:
                                  _focus[widget.destinations[index].value]!,
                              label: widget.destinations[index].label,
                              selected: index == selected,
                              activation: (1 - (progress - index).abs()).clamp(
                                0.0,
                                1.0,
                              ),
                              width: widths[index],
                              height: height,
                              onPressed: widget.onChanged == null
                                  ? null
                                  : () {
                                      if (index != selected) {
                                        final next =
                                            widget.destinations[index].value;
                                        if (motion?.navigate != null) {
                                          motion!.navigate!(next);
                                        } else {
                                          motion?.reset();
                                          widget.onChanged!(next);
                                        }
                                      }
                                    },
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (selected >= 0 && marker != null)
                      AnimatedPositioned(
                        duration:
                            tracking ||
                                !theme.isMotionEnabled(
                                  'navigationTransition',
                                ) ||
                                MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : theme.motion.normal,
                        curve: Curves.easeOutCubic,
                        left: markerLeft,
                        bottom: 5,
                        width: 20,
                        height: 3,
                        child: IgnorePointer(
                          child: YumeiroResolvedVisualSurface(
                            appearance: marker,
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TopNavigationItem extends StatefulWidget {
  const _TopNavigationItem({
    super.key,
    required this.revealKey,
    required this.focusNode,
    required this.label,
    required this.selected,
    required this.activation,
    required this.width,
    required this.height,
    required this.onPressed,
  });

  final GlobalKey revealKey;
  final FocusNode focusNode;
  final String label;
  final bool selected;
  final double activation;
  final double width;
  final double height;
  final VoidCallback? onPressed;

  @override
  State<_TopNavigationItem> createState() => _TopNavigationItemState();
}

class _TopNavigationItemState extends State<_TopNavigationItem> {
  late final WidgetStatesController _states;

  @override
  void initState() {
    super.initState();
    _states = WidgetStatesController({
      if (widget.onPressed == null) WidgetState.disabled,
    });
  }

  @override
  void didUpdateWidget(_TopNavigationItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    _states.update(WidgetState.disabled, widget.onPressed == null);
    if (widget.onPressed == null) _states.update(WidgetState.pressed, false);
  }

  @override
  void dispose() {
    _states.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _states,
    builder: (context, _) {
      final theme = YumeiroTheme.of(context);
      final visuals = theme.visuals;
      final states = {
        ..._states.value,
        if (widget.onPressed == null) WidgetState.disabled,
      };
      final visual = visuals
          .navigationItem(states)
          .lerp(
            visuals.navigationItem({...states, WidgetState.selected}),
            widget.activation,
          );
      final labelStyle = theme.typography.title.copyWith(
        color: visual.topSurface.foreground,
        fontWeight: visual.labelWeight,
      );
      return MergeSemantics(
        child: Semantics(
          role: SemanticsRole.tab,
          enabled: widget.onPressed != null,
          selected: widget.selected,
          inMutuallyExclusiveGroup: true,
          child: SizedBox(
            key: widget.revealKey,
            width: widget.width,
            height: widget.height,
            child: YumeiroResolvedVisualSurface(
              appearance: visual.topSurface,
              visualInsets: const EdgeInsets.all(4),
              child: TextButton(
                focusNode: widget.focusNode,
                statesController: _states,
                onPressed: widget.onPressed,
                style: ButtonStyle(
                  animationDuration: Duration.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const WidgetStatePropertyAll(EdgeInsets.zero),
                  minimumSize: const WidgetStatePropertyAll(Size.zero),
                  splashFactory: NoSplash.splashFactory,
                  backgroundColor: const WidgetStatePropertyAll(
                    Colors.transparent,
                  ),
                  overlayColor: const WidgetStatePropertyAll(
                    Colors.transparent,
                  ),
                  elevation: const WidgetStatePropertyAll(0),
                  shadowColor: const WidgetStatePropertyAll(Colors.transparent),
                  shape: WidgetStatePropertyAll(visual.topSurface.shape),
                  foregroundColor: WidgetStatePropertyAll(
                    visual.topSurface.foreground,
                  ),
                  textStyle: WidgetStatePropertyAll(labelStyle),
                ),
                child: Text(
                  widget.label,
                  style: labelStyle,
                  maxLines: 1,
                  softWrap: false,
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// Controlled horizontal paging linked with [YumeiroTopNavigation] via
/// [YumeiroNavigationMotionScope].
class YumeiroNavigationPager<T> extends StatefulWidget {
  const YumeiroNavigationPager({
    super.key,
    required this.value,
    required this.values,
    required this.onChanged,
    required this.itemBuilder,
  });

  final T value;

  /// Unique values in page order, including the current [value]. Use the same
  /// order in [YumeiroTopNavigation] when linking a tab bar to this pager.
  final List<T> values;

  /// Reports the page value after navigating. Null disables user paging.
  final ValueChanged<T>? onChanged;
  final Widget Function(BuildContext context, T value) itemBuilder;

  @override
  State<YumeiroNavigationPager<T>> createState() =>
      _YumeiroNavigationPagerState<T>();
}

class _YumeiroNavigationPagerState<T> extends State<YumeiroNavigationPager<T>> {
  late final PageController _controller;
  _NavigationMotion? _motion;
  T? _sessionOrigin;
  T? _reportedValue;
  int _generation = 0;

  int get _selected => widget.values.indexOf(widget.value);

  @override
  void initState() {
    super.initState();
    assert(
      _selected >= 0 && widget.values.toSet().length == widget.values.length,
    );
    _sessionOrigin = _reportedValue = widget.value;
    _controller = PageController(initialPage: _selected, keepPage: false)
      ..addListener(_tick);
  }

  void _afterFrame(VoidCallback callback) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) callback();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final motion = context
        .getInheritedWidgetOfExactType<_NavigationMotionScope>()
        ?.notifier;
    if (_motion != motion && _motion?.navigate == _navigate) {
      _motion?.navigate = null;
    }
    _motion = motion;
    _motion?.navigate = _navigate;
    _afterFrame(_tick);
  }

  void _tick() {
    if (!mounted ||
        !_controller.hasClients ||
        !_controller.position.hasContentDimensions) {
      return;
    }
    void update() {
      if (mounted && _controller.hasClients) {
        _motion?.update(_controller.page ?? _selected.toDouble());
      }
    }

    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      _afterFrame(update);
    } else {
      update();
    }
  }

  void _commit() {
    if (!_controller.hasClients ||
        widget.onChanged == null ||
        _sessionOrigin != widget.value) {
      return;
    }
    final index = (_controller.page ?? _selected.toDouble()).round().clamp(
      0,
      widget.values.length - 1,
    );
    final value = widget.values[index];
    if (_reportedValue == value || value == widget.value) return;
    final generation = _generation;
    _reportedValue = value;
    widget.onChanged!(value);
    // Give the host one build to accept the request before returning to its page.
    _afterFrame(() {
      if (generation != _generation || !_controller.hasClients) return;
      _reportedValue = widget.value;
      _controller.jumpToPage(_selected);
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _navigate(Object? value) {
    final target = widget.values.indexWhere((item) => item == value);
    if (target < 0 || widget.onChanged == null || !_controller.hasClients) {
      return;
    }
    final generation = ++_generation;
    _sessionOrigin = widget.value;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.jumpToPage(target);
      _commit();
    } else {
      _controller
          .animateToPage(
            target,
            duration: YumeiroTheme.of(context).motion.normal,
            curve: Curves.easeOutCubic,
          )
          .then((_) {
            if (mounted &&
                generation == _generation &&
                !_controller.position.isScrollingNotifier.value) {
              _commit();
            }
          });
    }
  }

  @override
  void didUpdateWidget(YumeiroNavigationPager<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value ||
        !listEquals(oldWidget.values, widget.values) ||
        (oldWidget.onChanged != null && widget.onChanged == null)) {
      final generation = ++_generation;
      _sessionOrigin = _reportedValue = widget.value;
      _afterFrame(() {
        if (generation == _generation &&
            _selected >= 0 &&
            _controller.hasClients) {
          _controller.jumpToPage(_selected);
          _tick();
        }
      });
    }
  }

  bool _notification(ScrollNotification notification) {
    if (notification.depth != 0) return false;
    if (notification is ScrollStartNotification) {
      if (notification.dragDetails != null) ++_generation;
      _sessionOrigin = widget.value;
    } else if (notification is ScrollEndNotification) {
      final generation = _generation;
      _afterFrame(() {
        if (generation == _generation) _commit();
      });
    }
    return false;
  }

  @override
  void dispose() {
    ++_generation;
    _controller.dispose();
    final motion = _motion;
    if (motion?.navigate == _navigate) motion?.navigate = null;
    WidgetsBinding.instance.addPostFrameCallback((_) => motion?.reset());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(
        gestureSettings: const DeviceGestureSettings(touchSlop: 12),
      ),
      child: NotificationListener<ScrollNotification>(
        onNotification: _notification,
        child: PageView.builder(
          controller: _controller,
          pageSnapping: !MediaQuery.disableAnimationsOf(context),
          physics: widget.onChanged == null
              ? const NeverScrollableScrollPhysics()
              : MediaQuery.disableAnimationsOf(context)
              ? const _ReducedMotionPagePhysics()
              : const _NavigationPagePhysics(),
          itemCount: widget.values.length,
          findChildIndexCallback: (key) {
            final index = widget.values.indexOf((key as ValueKey<T>).value);
            return index < 0 ? null : index;
          },
          itemBuilder: (context, index) => _NavigationPage(
            key: ValueKey(widget.values[index]),
            selected: widget.values[index] == widget.value,
            child: widget.itemBuilder(context, widget.values[index]),
          ),
        ),
      ),
    );
  }
}

class _NavigationPage extends StatefulWidget {
  const _NavigationPage({
    super.key,
    required this.selected,
    required this.child,
  });

  final bool selected;
  final Widget child;

  @override
  State<_NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<_NavigationPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final scrolling = Scrollable.of(context).position.isScrollingNotifier;
    return AnimatedBuilder(
      animation: scrolling,
      child: widget.child,
      builder: (context, child) => TickerMode(
        enabled: widget.selected || scrolling.value,
        child: ExcludeFocus(
          excluding: scrolling.value || !widget.selected,
          child: ExcludeSemantics(
            excluding: !widget.selected,
            child: IgnorePointer(
              ignoring: scrolling.value || !widget.selected,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationPagePhysics extends PageScrollPhysics {
  const _NavigationPagePhysics({super.parent});

  static final _settlingSpring = SpringDescription.withDurationAndBounce(
    duration: const Duration(milliseconds: 100),
  );

  @override
  SpringDescription get spring => _settlingSpring;

  @override
  double get minFlingDistance => 8;

  @override
  double get minFlingVelocity => 25;

  @override
  _NavigationPagePhysics applyTo(ScrollPhysics? ancestor) =>
      _NavigationPagePhysics(parent: buildParent(ancestor));
}

class _ReducedMotionPagePhysics extends _NavigationPagePhysics {
  const _ReducedMotionPagePhysics({super.parent});

  @override
  _ReducedMotionPagePhysics applyTo(ScrollPhysics? ancestor) =>
      _ReducedMotionPagePhysics(parent: buildParent(ancestor));

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final simulation = super.createBallisticSimulation(position, velocity);
    return simulation == null
        ? null
        : _ImmediatePageSimulation(simulation.x(1000));
  }
}

class _ImmediatePageSimulation extends Simulation {
  _ImmediatePageSimulation(this.target);

  final double target;

  @override
  double x(double time) => target;

  @override
  double dx(double time) => 0;

  @override
  bool isDone(double time) => true;
}
