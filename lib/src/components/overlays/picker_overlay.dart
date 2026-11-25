import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/rendering.dart' show RenderView;
import 'package:material_ui/material_ui.dart';

import '../../l10n/localizations.dart';
import '../../primitives/glass_backdrop.dart';
import '../../primitives/visual_surface.dart';
import '../../scope/captured_configuration.dart';
import '../../theme/semantic_visuals.dart';
import '../../theme/theme.dart';
import '../../theme/visual_role.dart';
import 'menu_visuals.dart';
import 'selection_overlay.dart' show yumeiroFloatingSafeBounds;

Rect? pickerGlobalBounds(RenderBox box) => box.attached
    ? MatrixUtils.transformRect(
        box.getTransformTo(null),
        Offset.zero & box.size,
      )
    : null;

/// Dismisses an editable picker once scrolling has fully clipped its trigger.
class PickerAnchorVisibility {
  PickerAnchorVisibility({required this.anchorContext, required this.onHidden});

  final BuildContext? Function() anchorContext;
  final VoidCallback onHidden;
  List<ScrollPosition> _positions = const [];
  bool _tracking = false;
  bool _scheduled = false;

  void track(BuildContext? context) {
    _tracking = context != null;
    final positions = <ScrollPosition>[];
    if (context != null) {
      for (
        var scrollable = Scrollable.maybeOf(context);
        scrollable != null;
        scrollable = Scrollable.maybeOf(scrollable.context)
      ) {
        positions.add(scrollable.position);
      }
      _schedule();
    }
    if (listEquals(_positions, positions)) return;
    for (final position in _positions) {
      position.removeListener(_schedule);
    }
    _positions = positions;
    for (final position in _positions) {
      position.addListener(_schedule);
    }
  }

  void _schedule() {
    if (_scheduled) return;
    _scheduled = true;
    final binding = WidgetsBinding.instance;
    binding.addPostFrameCallback((_) {
      _scheduled = false;
      if (!_tracking) return;
      final anchor = anchorContext()?.findRenderObject();
      if (anchor is RenderBox &&
          anchor.attached &&
          anchor.hasSize &&
          !_isVisible(anchor)) {
        onHidden();
      }
    });
    binding.ensureVisualUpdate();
  }

  bool _isVisible(RenderBox anchor) {
    var bounds = pickerGlobalBounds(anchor)!;
    if (!bounds.isFinite || bounds.isEmpty) return false;
    RenderObject child = anchor;
    for (
      var ancestor = anchor.parent;
      ancestor != null;
      ancestor = ancestor.parent
    ) {
      if (!ancestor.paintsChild(child)) return false;
      final clip = ancestor is RenderView
          ? Offset.zero & ancestor.size
          : ancestor.describeApproximatePaintClip(child);
      if (clip != null) {
        bounds = bounds.intersect(
          MatrixUtils.transformRect(ancestor.getTransformTo(null), clip),
        );
        if (!bounds.isFinite || bounds.isEmpty) return false;
      }
      child = ancestor;
    }
    return true;
  }
}

/// Native menu hosting for selectors with an anchor inside a scrolling page.
class PickerMenuAnchor extends StatelessWidget {
  const PickerMenuAnchor({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.width,
    required this.menu,
    required this.child,
    this.maxHeight = double.infinity,
    this.position = PopupMenuPosition.under,
    this.center = false,
    this.offset,
    this.visualOverride,
    this.crossAxisUnconstrained = true,
    this.useRootOverlay = false,
    this.onOpen,
    this.onClose,
  });

  final MenuController controller;
  final FocusNode focusNode;
  final double width;
  final double maxHeight;
  final PopupMenuPosition position;
  final bool center;
  final Offset? offset;
  final YumeiroVisualOverride? visualOverride;
  final bool crossAxisUnconstrained;
  final bool useRootOverlay;
  final VoidCallback? onOpen;
  final VoidCallback? onClose;
  final Widget menu;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final theme = YumeiroTheme.of(context);
    final adjustment = offset ?? Offset(0, theme.spacing.xs);
    final appearance = theme.visuals.surface(
      YumeiroSurfaceRole.floating,
      const <WidgetState>{},
      visualOverride,
    );
    return MenuAnchor(
      controller: controller,
      childFocusNode: focusNode,
      crossAxisUnconstrained: crossAxisUnconstrained,
      useRootOverlay: useRootOverlay,
      clipBehavior: Clip.antiAlias,
      alignmentOffset: center
          ? adjustment + Offset((rtl ? 1 : -1) * width / 2, 0)
          : Offset(rtl ? -adjustment.dx : adjustment.dx, adjustment.dy),
      style: yumeiroMenuHostStyle(appearance).copyWith(
        alignment: switch ((position, center)) {
          (PopupMenuPosition.under, true) => Alignment.bottomCenter,
          (PopupMenuPosition.under, false) => AlignmentDirectional.bottomStart,
          (_, true) => Alignment.topCenter,
          (_, false) => AlignmentDirectional.topStart,
        },
        minimumSize: WidgetStatePropertyAll(Size(width, 0)),
        maximumSize: WidgetStatePropertyAll(Size(width, maxHeight)),
      ),
      onOpen: onOpen,
      onClose: onClose,
      menuChildren: [SizedBox(width: width, child: menu)],
      child: child,
    );
  }
}

class PickerOverlayController {
  RawDialogRoute<Object?>? _route;

  void refresh() => _update((route) => route.changedExternalState());

  void close() => _update((route) => route.navigator?.removeRoute(route));

  void _update(void Function(RawDialogRoute<Object?> route) action) {
    final route = _route;
    if (route == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (identical(_route, route) && route.isActive) action(route);
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }
}

Future<T?> showPickerOverlay<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  PickerOverlayController? controller,
  bool useRootNavigator = true,
  double? width,
  double maxHeight = 320,
  double minHeight = 0,
  EdgeInsetsGeometry surfacePadding = const EdgeInsets.all(6),
}) {
  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  final trigger = context.findRenderObject() as RenderBox;
  final overlay = navigator.overlay!.context.findRenderObject() as RenderBox;
  final configuration = YumeiroCapturedConfiguration.capture(
    context,
    navigator.context,
  );
  Rect? measureAnchor() => trigger.attached && overlay.attached
      ? MatrixUtils.transformRect(
          trigger.getTransformTo(overlay),
          Offset.zero & trigger.size,
        )
      : null;

  final route = RawDialogRoute<T>(
    barrierDismissible: true,
    barrierColor: Colors.transparent,
    barrierLabel: YumeiroLocalizations.of(context).close,
    transitionDuration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : YumeiroTheme.of(context).motion.fast,
    pageBuilder: (_, _, _) => configuration.wrap(
      _PickerRouteContent(
        width: width,
        maxHeight: maxHeight,
        minHeight: minHeight,
        anchor: measureAnchor(),
        measureAnchor: measureAnchor,
        child: PickerFloatingSurface(
          padding: surfacePadding,
          child: Builder(builder: builder),
        ),
      ),
    ),
  );
  if (controller != null) controller._route = route;
  return navigator.push(route).whenComplete(() {
    if (controller != null && identical(controller._route, route)) {
      controller._route = null;
    }
  });
}

class PickerFloatingSurface extends StatelessWidget {
  const PickerFloatingSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(6),
    this.visualOverride,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final YumeiroVisualOverride? visualOverride;

  @override
  Widget build(BuildContext context) => YumeiroGlassSamplingScope(
    child: YumeiroVisualSurface(
      role: YumeiroSurfaceRole.floating,
      visualOverride: visualOverride,
      padding: padding,
      clipBehavior: Clip.antiAlias,
      child: Material(type: MaterialType.transparency, child: child),
    ),
  );
}

class _PickerRouteContent extends StatefulWidget {
  const _PickerRouteContent({
    required this.anchor,
    required this.measureAnchor,
    required this.width,
    required this.maxHeight,
    required this.minHeight,
    required this.child,
  });

  final Rect? anchor;
  final Rect? Function() measureAnchor;
  final double? width;
  final double maxHeight;
  final double minHeight;
  final Widget child;

  @override
  State<_PickerRouteContent> createState() => _PickerRouteContentState();
}

class _PickerRouteContentState extends State<_PickerRouteContent> {
  late Rect? _anchor = widget.anchor;
  BoxConstraints? _constraints;

  @override
  void didUpdateWidget(_PickerRouteContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A refreshed route already measures the trigger after the host lays out.
    _anchor = widget.anchor;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (_constraints != constraints) {
        _constraints = constraints;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final anchor = widget.measureAnchor();
          if (anchor != _anchor) setState(() => _anchor = anchor);
        });
      }
      final media = MediaQuery.of(context);
      return PickerOverlayLayout(
        anchor: _anchor,
        width: widget.width,
        maxHeight: widget.maxHeight,
        minHeight: widget.minHeight,
        padding: media.viewPadding.copyWith(
          bottom: math.max(media.viewPadding.bottom, media.viewInsets.bottom),
        ),
        child: widget.child,
      );
    },
  );
}

/// Positions a picker in overlay coordinates, keeping its content bounded.
class PickerOverlayLayout extends StatelessWidget {
  const PickerOverlayLayout({
    super.key,
    required this.anchor,
    required this.child,
    this.width,
    this.maxHeight = 320,
    this.minHeight = 0,
    this.padding = EdgeInsets.zero,
    this.preferLargerSide = false,
  });

  final Rect? anchor;
  final double? width;
  final double maxHeight;
  final double minHeight;
  final EdgeInsets padding;
  final bool preferLargerSide;
  final Widget child;

  @override
  Widget build(BuildContext context) => CustomSingleChildLayout(
    delegate: _PickerLayout(
      anchor: anchor,
      width: width ?? anchor?.width ?? 320,
      maxHeight: maxHeight,
      minHeight: minHeight,
      gap: YumeiroTheme.of(context).spacing.xs,
      direction: Directionality.of(context),
      padding: padding,
      preferLargerSide: preferLargerSide,
    ),
    child: child,
  );
}

class _PickerLayout extends SingleChildLayoutDelegate {
  const _PickerLayout({
    required this.anchor,
    required this.width,
    required this.maxHeight,
    required this.minHeight,
    required this.gap,
    required this.direction,
    required this.padding,
    required this.preferLargerSide,
  });

  final Rect? anchor;
  final double width;
  final double maxHeight;
  final double minHeight;
  final double gap;
  final TextDirection direction;
  final EdgeInsets padding;
  final bool preferLargerSide;

  double _space(Rect bounds, Rect anchor) =>
      math.max(anchor.top - bounds.top, bounds.bottom - anchor.bottom) - gap;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final bounds = yumeiroFloatingSafeBounds(constraints.biggest, padding);
    final trigger = anchor;
    final space = trigger == null ? 0.0 : _space(bounds, trigger);
    final height = space > 0 && space >= minHeight ? space : bounds.height;
    final popupWidth = math.min(width, bounds.width);
    return BoxConstraints(
      minWidth: popupWidth,
      maxWidth: popupWidth,
      maxHeight: math.min(maxHeight, math.min(height, bounds.height)),
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final bounds = yumeiroFloatingSafeBounds(size, padding);
    final trigger = anchor;
    if (trigger == null || _space(bounds, trigger) < childSize.height) {
      return bounds.center - Offset(childSize.width / 2, childSize.height / 2);
    }
    final above = trigger.top - gap - childSize.height;
    final below = trigger.bottom + gap;
    final spaceAbove = trigger.top - bounds.top;
    final spaceBelow = bounds.bottom - trigger.bottom;
    final opensBelow =
        (!preferLargerSide || spaceBelow >= spaceAbove) &&
        gap + childSize.height <= spaceBelow;
    final top = opensBelow ? below : above;
    final left = direction == TextDirection.rtl
        ? trigger.right - childSize.width
        : trigger.left;
    return Offset(
      left.clamp(bounds.left, bounds.right - childSize.width),
      top.clamp(bounds.top, bounds.bottom - childSize.height),
    );
  }

  @override
  bool shouldRelayout(_PickerLayout old) =>
      anchor != old.anchor ||
      width != old.width ||
      maxHeight != old.maxHeight ||
      minHeight != old.minHeight ||
      gap != old.gap ||
      direction != old.direction ||
      padding != old.padding ||
      preferLargerSide != old.preferLargerSide;
}
