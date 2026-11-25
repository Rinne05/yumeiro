import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../foundation/input.dart';
import '../../primitives/visual_scope.dart';
import '../../primitives/visual_surface.dart';
import '../../theme/semantic_visuals.dart';
import '../../theme/theme.dart';
import '../../theme/visual_role.dart';

/// Floating tooltip powered by [RawTooltip] and [YumeiroSurfaceRole.floating].
class YumeiroTooltip extends StatelessWidget {
  const YumeiroTooltip({
    super.key,
    required this.message,
    required this.child,
    this.waitDuration,
    this.preferBelow,
    this.verticalOffset,
    this.margin = 12.0,
    this.excludeFromSemantics,
    this.triggerMode,
    this.showOnFocus = false,
  });

  final String message;
  final Widget child;
  final Duration? waitDuration;
  final bool? preferBelow;
  final double? verticalOffset;
  final double margin;

  /// Hides the tooltip text from assistive technology when the child already
  /// exposes an equivalent description.
  final bool? excludeFromSemantics;

  /// Overrides the theme's touch trigger. The default fallback is long press.
  final TooltipTriggerMode? triggerMode;

  /// Shows the tooltip when a descendant receives keyboard focus.
  final bool showOnFocus;

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty ||
        !TooltipVisibility.of(context) ||
        Overlay.maybeOf(context) == null) {
      return child;
    }

    final tooltipTheme = TooltipTheme.of(context);
    final theme = YumeiroTheme.of(context);
    final padding =
        tooltipTheme.padding ??
        const EdgeInsets.symmetric(horizontal: 10, vertical: 6);

    RawTooltip buildTooltip(Key? key, Widget child) => RawTooltip(
      key: key,
      semanticsTooltip:
          (excludeFromSemantics ?? tooltipTheme.excludeFromSemantics ?? false)
          ? null
          : message,
      hoverDelay: waitDuration ?? tooltipTheme.waitDuration ?? Duration.zero,
      touchDelay:
          tooltipTheme.showDuration ?? const Duration(milliseconds: 1500),
      dismissDelay:
          tooltipTheme.exitDuration ?? const Duration(milliseconds: 100),
      triggerMode:
          triggerMode ??
          tooltipTheme.triggerMode ??
          TooltipTriggerMode.longPress,
      enableFeedback: tooltipTheme.enableFeedback ?? true,
      ignorePointer: true,
      positionDelegate: (info) => positionDependentBox(
        size: info.overlaySize,
        childSize: info.tooltipSize,
        target: info.target,
        verticalOffset:
            verticalOffset ??
            tooltipTheme.verticalOffset ??
            math.max(18.0, info.targetSize.height / 2 + 6),
        preferBelow: preferBelow ?? tooltipTheme.preferBelow ?? true,
        margin: margin,
      ),
      tooltipBuilder: (context, animation) => AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final scope = YumeiroVisualScope.maybeOf(context);
          final appearance = YumeiroTheme.of(context).visuals.surface(
            scope?.surfaceRole ?? YumeiroSurfaceRole.floating,
            const <WidgetState>{},
            scope?.visualOverride,
          );
          return Padding(
            padding: tooltipTheme.margin ?? EdgeInsets.zero,
            child: ConstrainedBox(
              constraints:
                  tooltipTheme.constraints ??
                  const BoxConstraints(maxWidth: 360),
              child: YumeiroResolvedVisualSurface(
                appearance: appearance.copyWith(
                  opacity: appearance.opacity * animation.value,
                  transition: YumeiroVisualTransition.instant,
                ),
                padding: padding,
                child: Text(
                  message,
                  style: (tooltipTheme.textStyle ?? theme.typography.supporting)
                      .copyWith(color: appearance.foreground),
                  textAlign: tooltipTheme.textAlign,
                ),
              ),
            ),
          );
        },
      ),
      child: child,
    );
    return showOnFocus
        ? _FocusTooltip(buildTooltip: buildTooltip, child: child)
        : buildTooltip(null, child);
  }
}

class _FocusTooltip extends StatefulWidget {
  const _FocusTooltip({required this.buildTooltip, required this.child});

  final RawTooltip Function(Key? key, Widget child) buildTooltip;
  final Widget child;

  @override
  State<_FocusTooltip> createState() => _FocusTooltipState();
}

class _FocusTooltipState extends State<_FocusTooltip> {
  final _childKey = GlobalKey();
  final _hoveringDevices = <int>{};
  var _tooltipKey = GlobalKey<RawTooltipState>();
  bool _hasFocus = false;
  bool _openedByFocus = false;

  void _handleFocusChange(bool focused) {
    _hasFocus = focused;
    if (focused) {
      // Tab between scopes updates the destination input tracker after the
      // traversal. Read it after that update.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_hasFocus) return;
        final input = context
            .getInheritedWidgetOfExactType<YumeiroInputScope>()
            ?.notifier;
        final keyboard =
            input?.showKeyboardFocus ??
            (FocusManager.instance.highlightMode ==
                FocusHighlightMode.traditional);
        if (keyboard &&
            _tooltipKey.currentState?.ensureTooltipVisible() == true) {
          _openedByFocus = true;
        }
      });
      WidgetsBinding.instance.ensureVisualUpdate();
    } else if (_openedByFocus && mounted) {
      _openedByFocus = false;
      if (_hoveringDevices.isNotEmpty) return;
      // RawTooltip can only dismiss all open instances. Recreate this one
      // while retaining the wrapped control and its focus node.
      setState(() => _tooltipKey = GlobalKey<RawTooltipState>());
    }
  }

  @override
  Widget build(BuildContext context) => MouseRegion(
    opaque: false,
    onEnter: (event) => _hoveringDevices.add(event.device),
    onExit: (event) => _hoveringDevices.remove(event.device),
    child: Focus(
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      onFocusChange: _handleFocusChange,
      child: widget.buildTooltip(
        _tooltipKey,
        KeyedSubtree(key: _childKey, child: widget.child),
      ),
    ),
  );
}
