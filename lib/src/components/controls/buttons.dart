import 'package:material_ui/material_ui.dart';
import 'package:flutter/scheduler.dart';

import '../../foundation/modality.dart';
import '../../primitives/pixel_border.dart';
import '../../primitives/pixel_circle.dart';
import '../../primitives/visual_scope.dart';
import '../../primitives/visual_surface.dart';
import '../../theme/semantic_visuals.dart';
import '../../theme/theme.dart';
import '../../theme/visual_role.dart';
import '../overlays/tooltip.dart';

/// Built-in semantic roles for action buttons.
enum YumeiroButtonVariant {
  /// Standard action with the theme's neutral treatment.
  neutral,

  /// Supporting action alongside a primary or peer action.
  secondary,

  /// Main action of the current view or group.
  primary,

  /// Action that deletes data or has another destructive effect.
  danger,

  /// Quiet action with minimal resting emphasis.
  ghost,

  /// High-contrast controls placed over artwork, imagery, or video.
  mediaOverlay,
}

/// Modality-adaptive action button driven by [YumeiroControlRole] recipes.
///
/// Supports text+icon buttons, icon-only compact actions (when [label] is null),
/// custom leading widgets, monospaced numeric/code labels, optional badge dot,
/// and press-scale feedback controlled by the theme.
class YumeiroButton extends StatefulWidget {
  const YumeiroButton({
    super.key,
    this.label,
    required this.onPressed,
    this.icon,
    this.customLeading,
    this.trailingIcon,
    this.variant = YumeiroButtonVariant.neutral,
    this.dense = false,
    this.expand = false,
    this.selected = false,
    this.badge = false,
    this.monospace = false,
    this.tooltip,
    this.semanticLabel,
    this.width,
    this.height,
    this.iconSize,
    this.fontSize,
    this.focusNode,
    this.controlRole,
    this.visualOverride,
  }) : assert(
         label != null || icon != null || customLeading != null,
         'YumeiroButton requires at least a label, an icon, or customLeading.',
       ),
       assert(
         label != null ||
             customLeading != null ||
             (semanticLabel != null && semanticLabel != '') ||
             (tooltip != null && tooltip != ''),
         'An icon-only YumeiroButton needs a semanticLabel or tooltip.',
       );

  final String? label;

  /// Activates the button. Null leaves it visible in the disabled state.
  final VoidCallback? onPressed;
  final IconData? icon;
  final Widget? customLeading;
  final IconData? trailingIcon;
  final YumeiroButtonVariant variant;
  final bool dense;
  final bool expand;

  /// Host-owned selected state. Pressing the button does not toggle it.
  final bool selected;
  final bool badge;
  final bool monospace;
  final String? tooltip;

  /// Accessible name for the action. Icon-only buttons fall back to [tooltip].
  /// A custom leading widget can supply its own semantics.
  final String? semanticLabel;

  final double? width;
  final double? height;
  final double? iconSize;
  final double? fontSize;

  /// Optional focus node owned and disposed by the caller.
  final FocusNode? focusNode;

  /// Role used instead of [variant] when no enclosing [YumeiroVisualScope]
  /// supplies a control role.
  final YumeiroControlRole? controlRole;

  /// Appearance overrides for this button, preferred over the nearest
  /// [YumeiroVisualScope] override.
  final YumeiroVisualOverride? visualOverride;

  @override
  State<YumeiroButton> createState() => _YumeiroButtonState();
}

class _YumeiroButtonState extends State<YumeiroButton> {
  late final WidgetStatesController _statesController;
  bool _stateRefreshScheduled = false;

  @override
  void initState() {
    super.initState();
    _statesController = WidgetStatesController(<WidgetState>{
      if (widget.selected) WidgetState.selected,
      if (widget.onPressed == null) WidgetState.disabled,
    })..addListener(_handleStatesChanged);
  }

  @override
  void didUpdateWidget(covariant YumeiroButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _statesController
      ..update(WidgetState.selected, widget.selected)
      ..update(WidgetState.disabled, widget.onPressed == null);
  }

  void _handleStatesChanged() {
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      if (_stateRefreshScheduled) return;
      _stateRefreshScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _stateRefreshScheduled = false;
        if (mounted) setState(() {});
      });
    } else if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _statesController
      ..removeListener(_handleStatesChanged)
      ..dispose();
    super.dispose();
  }

  YumeiroControlRole get _effectiveRole =>
      widget.controlRole ??
      switch (widget.variant) {
        YumeiroButtonVariant.neutral => YumeiroControlRole.neutral,
        YumeiroButtonVariant.secondary => YumeiroControlRole.secondary,
        YumeiroButtonVariant.primary => YumeiroControlRole.primary,
        YumeiroButtonVariant.danger => YumeiroControlRole.danger,
        YumeiroButtonVariant.ghost => YumeiroControlRole.ghost,
        YumeiroButtonVariant.mediaOverlay => YumeiroControlRole.overlay,
      };

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final metrics = YumeiroModalityScope.metricsOf(context);
    final visualScope = YumeiroVisualScope.maybeOf(context);
    final inheritedStates = YumeiroInteractionStateScope.maybeOf(context);
    final role = visualScope?.controlRole ?? _effectiveRole;
    final visualOverride = widget.visualOverride ?? visualScope?.visualOverride;
    final iconOnly = widget.label == null;
    final explicitLabel = widget.semanticLabel?.trim();
    final tooltip = widget.tooltip?.trim();
    final semanticLabel = explicitLabel?.isNotEmpty == true
        ? explicitLabel
        : (iconOnly && tooltip?.isNotEmpty == true ? tooltip : null);
    assert(
      !iconOnly || widget.customLeading != null || semanticLabel != null,
      'An icon-only YumeiroButton needs a non-blank semanticLabel or tooltip.',
    );

    final hitHeight =
        widget.height ??
        (widget.dense ? metrics.denseTargetSize : metrics.minTargetSize);
    final iconWidth = widget.width ?? hitHeight;
    final horizontalPadding = widget.dense
        ? metrics.horizontalPadding * .75
        : (metrics.isTouch ? 20.0 : theme.spacing.lg);
    final resolvedIconSize =
        widget.iconSize ??
        (metrics.isTouch
            ? 22.0
            : (widget.dense ? theme.iconSizes.xs : theme.iconSizes.sm));

    final states = <WidgetState>{
      ...(inheritedStates ?? _statesController.value),
      if (inheritedStates != null && widget.selected) WidgetState.selected,
    };
    final appearance = theme.visuals.control(role, states, visualOverride);

    final content = ConstrainedBox(
      constraints: iconOnly
          ? BoxConstraints.tightFor(width: iconWidth, height: hitHeight)
          : BoxConstraints(
              minHeight: hitHeight,
              maxHeight: widget.height ?? double.infinity,
            ),
      child: iconOnly
          ? Center(
              child:
                  widget.customLeading ??
                  Icon(
                    widget.icon,
                    size:
                        widget.iconSize ??
                        (metrics.isTouch
                            ? 24.0
                            : (widget.dense
                                  ? theme.iconSizes.sm
                                  : theme.iconSizes.md)),
                    color: appearance.foreground,
                  ),
            )
          : Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Row(
                mainAxisSize: widget.expand
                    ? MainAxisSize.max
                    : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.customLeading != null) ...[
                    widget.customLeading!,
                    SizedBox(width: theme.spacing.xs + 2),
                  ] else if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      size: resolvedIconSize,
                      color: appearance.foreground,
                    ),
                    SizedBox(width: theme.spacing.xs + 2),
                  ],
                  Flexible(
                    child: Text(
                      widget.label!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.typography
                          .control(
                            selected: widget.selected,
                            dense: widget.dense,
                            monospace: widget.monospace,
                          )
                          .copyWith(
                            fontSize: widget.fontSize,
                            color: appearance.foreground,
                          ),
                    ),
                  ),
                  if (widget.trailingIcon != null) ...[
                    SizedBox(width: theme.spacing.xs + 2),
                    Icon(
                      widget.trailingIcon,
                      size: resolvedIconSize,
                      color: appearance.foreground,
                    ),
                  ],
                ],
              ),
            ),
    );

    final insets = widget.height == null && metrics.isTouch
        ? (widget.dense
              ? metrics.denseControlVisualInsets
              : metrics.controlVisualInsets)
        : null;

    Widget button = Semantics(
      button: true,
      enabled: widget.onPressed != null,
      selected: widget.selected,
      label: semanticLabel,
      child: YumeiroResolvedVisualSurface(
        appearance: appearance,
        visualInsets: insets,
        clipBehavior: Clip.antiAlias,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            splashFactory: NoSplash.splashFactory,
            statesController: _statesController,
            onTap: widget.onPressed,
            focusNode: widget.focusNode,
            customBorder: appearance.shape,
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            child: semanticLabel == null
                ? content
                : ExcludeSemantics(child: content),
          ),
        ),
      ),
    );

    if (metrics.isTouch && widget.width == null && widget.height == null) {
      button = ConstrainedBox(
        constraints: BoxConstraints(minWidth: metrics.minTargetSize),
        child: button,
      );
    }

    if (tooltip case final tip? when tip.isNotEmpty) {
      button = YumeiroTooltip(message: tip, showOnFocus: true, child: button);
    }

    if (widget.badge) {
      const diameter = 5.0;
      final outline = BorderSide(
        color: Theme.of(context).scaffoldBackgroundColor,
        width: 2,
      );
      final shape = theme.checkboxVisuals.shape is YumeiroPixelBorder
          ? pixelCircleBorder(diameter).copyWith(side: outline)
          : CircleBorder(side: outline);
      button = Stack(
        clipBehavior: Clip.none,
        children: [
          button,
          Positioned(
            right: 7,
            top: 7,
            child: DecoratedBox(
              decoration: ShapeDecoration(color: theme.accent, shape: shape),
              child: const SizedBox.square(dimension: diameter),
            ),
          ),
        ],
      );
    }

    if (!iconOnly && widget.width != null) {
      button = SizedBox(width: widget.width, child: button);
    }

    if (theme.isMotionEnabled('controlPressScale') &&
        !MediaQuery.disableAnimationsOf(context)) {
      button = AnimatedScale(
        scale: widget.onPressed != null && states.contains(WidgetState.pressed)
            ? appearance.transition.pressedScale
            : 1,
        duration: appearance.transition.duration,
        curve: appearance.transition.curve,
        child: button,
      );
    }

    return button;
  }
}
