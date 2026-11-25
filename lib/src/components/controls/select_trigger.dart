import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../foundation/modality.dart';
import '../../foundation/typography.dart';
import '../../primitives/visual_surface.dart';
import '../../theme/semantic_visuals.dart';
import '../../theme/theme.dart';
import '../../theme/visual_role.dart';

/// Shared passive visual for menu and cascading selection triggers.
/// Callers own focus, pointer states, and popups.
class YumeiroSelectTriggerVisual extends StatelessWidget {
  const YumeiroSelectTriggerVisual({
    super.key,
    required this.label,
    required this.states,
    this.icon,
    this.trailingIcon,
    this.showTrailingIcon = true,
    this.selected = false,
    this.isPlaceholder = false,
    this.fillsWidth = false,
    this.dense = false,
    this.textAlign = TextAlign.center,
    this.visualOverride,
  });

  final String label;
  final Set<WidgetState> states;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool showTrailingIcon;
  final bool selected;
  final bool isPlaceholder;
  final bool fillsWidth;
  final bool dense;
  final TextAlign textAlign;
  final YumeiroVisualOverride? visualOverride;

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final metrics = YumeiroModalityScope.metricsOf(context);
    final height = dense ? metrics.denseTargetSize : metrics.minTargetSize;
    final isEnabled = !states.contains(WidgetState.disabled);
    final triggerVisual = theme.visuals.control(
      YumeiroControlRole.secondary,
      states,
      visualOverride,
    );

    if (metrics.isTouch) {
      return _YumeiroTouchSelectTrigger(
        label: label,
        icon: icon,
        trailingIcon: showTrailingIcon
            ? (trailingIcon ?? theme.icons.chevronDown)
            : null,
        states: states,
        selected: selected,
        dense: dense,
        isPlaceholder: isPlaceholder,
        fillsWidth: fillsWidth,
        textAlign: textAlign,
        visualOverride: visualOverride,
      );
    }

    final effectiveTrailingIcon = showTrailingIcon
        ? (trailingIcon ?? theme.icons.chevronDown)
        : null;
    final effectiveTextColor =
        isEnabled && isPlaceholder && !states.contains(WidgetState.selected)
        ? theme.subtle
        : triggerVisual.foreground;
    final effectiveIconColor = isEnabled && !selected
        ? theme.muted
        : triggerVisual.foreground;
    final iconSize = dense ? theme.iconSizes.xs : theme.iconSizes.sm;

    final labelWidget = Text(
      label,
      textAlign: textAlign,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.typography
          .control(selected: selected, dense: dense)
          .copyWith(
            color: effectiveTextColor,
            fontWeight: isPlaceholder ? theme.typography.bodyWeight : null,
          ),
    );

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: height),
      child: YumeiroResolvedVisualSurface(
        appearance: triggerVisual,
        clipBehavior: Clip.antiAlias,
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 8 : 10,
          vertical: dense ? 2 : 4,
        ),
        child: Row(
          mainAxisSize: fillsWidth ? MainAxisSize.max : MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: iconSize, color: effectiveIconColor),
              SizedBox(width: dense ? 5 : 8),
            ],
            if (fillsWidth)
              Expanded(child: labelWidget)
            else
              Flexible(child: labelWidget),
            if (effectiveTrailingIcon != null) ...[
              SizedBox(width: dense ? 4 : 6),
              Icon(
                effectiveTrailingIcon,
                size: iconSize,
                color: effectiveIconColor,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _YumeiroTouchSelectTrigger extends StatelessWidget {
  const _YumeiroTouchSelectTrigger({
    required this.label,
    this.icon,
    this.trailingIcon,
    this.states = const {},
    this.selected = false,
    this.dense = false,
    this.isPlaceholder = false,
    this.fillsWidth = true,
    this.textAlign = TextAlign.start,
    this.visualOverride,
  });

  final String label;
  final IconData? icon;
  final IconData? trailingIcon;
  final Set<WidgetState> states;
  final bool selected;
  final bool dense;
  final bool isPlaceholder;
  final bool fillsWidth;
  final TextAlign textAlign;
  final YumeiroVisualOverride? visualOverride;

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final metrics = YumeiroModalityScope.metricsOf(context);
    final isEnabled = !states.contains(WidgetState.disabled);
    final layoutHeight = dense
        ? metrics.denseTargetSize
        : metrics.minTargetSize;
    final horizontalPadding = dense ? 12.0 : metrics.horizontalPadding;
    final iconSize = dense ? theme.iconSizes.md : 22.0;
    final effectiveIconColor = isEnabled && !selected ? theme.muted : null;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: layoutHeight),
      child: YumeiroVisualSurface(
        role: YumeiroControlRole.secondary,
        visualOverride: visualOverride,
        visualInsets: dense
            ? metrics.denseControlVisualInsets
            : metrics.controlVisualInsets,
        states: states,
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: dense ? 4 : 8,
        ),
        child: Row(
          mainAxisSize: fillsWidth ? MainAxisSize.max : MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: iconSize, color: effectiveIconColor),
              SizedBox(width: dense ? 8 : 12),
            ],
            Flexible(
              fit: fillsWidth ? FlexFit.tight : FlexFit.loose,
              child: YumeiroTextStyle(
                style: theme.typography
                    .control(
                      selected:
                          selected || states.contains(WidgetState.selected),
                      dense: dense,
                    )
                    .copyWith(
                      fontWeight: isPlaceholder
                          ? theme.typography.bodyWeight
                          : null,
                    ),
                child: Text(
                  label,
                  textAlign: textAlign,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style:
                      isEnabled &&
                          isPlaceholder &&
                          !states.contains(WidgetState.selected)
                      ? TextStyle(color: theme.subtle)
                      : null,
                ),
              ),
            ),
            if (trailingIcon != null) ...[
              SizedBox(width: dense ? 6 : 8),
              Icon(trailingIcon, size: iconSize, color: effectiveIconColor),
            ],
          ],
        ),
      ),
    );
  }
}

/// Measures single-line text width using the active theme's font fallback.
double yumeiroSelectTextWidth(
  BuildContext context,
  String text,
  TextStyle style,
) {
  if (text.isEmpty) return 0;
  final theme = YumeiroTheme.of(context);
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: style.copyWith(
        fontWeight: MediaQuery.boldTextOf(context) ? FontWeight.bold : null,
        fontFamilyFallback:
            style.fontFamilyFallback ??
            theme.typography.fontConfig.resolvedFontFallback,
      ),
    ),
    maxLines: 1,
    textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
    textScaler: MediaQuery.maybeTextScalerOf(context) ?? TextScaler.noScaling,
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width;
}

/// Computes unified trigger/menu width so switching options never causes jitter.
double yumeiroSelectAutoWidth(
  BuildContext context, {
  required double triggerTextWidth,
  double menuTextWidth = 0,
  required bool hasLeadingIcon,
  bool hasTrailingIcon = true,
  bool menuHasLeadingIcon = false,
  bool menuHasTrailingIcon = false,
  bool dense = false,
  double? minWidth,
  double maxWidth = 320.0,
}) {
  final metrics = YumeiroModalityScope.metricsOf(context);
  if (metrics.isTouch) {
    final horizontalPadding = dense ? 12.0 : metrics.horizontalPadding;
    final iconSize = dense ? YumeiroTheme.of(context).iconSizes.md : 22.0;
    final lower = minWidth ?? (dense ? 96.0 : 112.0);
    final upper = math.max(lower, maxWidth);
    return (horizontalPadding * 2 +
            triggerTextWidth +
            (hasLeadingIcon ? iconSize + (dense ? 8 : 12) : 0) +
            (hasTrailingIcon ? iconSize + (dense ? 6 : 8) : 0) +
            8)
        .ceilToDouble()
        .clamp(lower, upper);
  }
  final trigger =
      (dense ? 16.0 : 20.0) +
      2 +
      (hasLeadingIcon ? (dense ? 14.0 : 16.0) + (dense ? 5.0 : 8.0) : 0) +
      triggerTextWidth +
      (hasTrailingIcon ? (dense ? 4.0 : 6.0) + (dense ? 14.0 : 16.0) : 0) +
      8;
  final menu =
      24.0 +
      (menuHasLeadingIcon ? 21.0 : 0) +
      menuTextWidth +
      (menuHasTrailingIcon ? 6 + (dense ? 13.0 : 15.0) : 0) +
      8;
  final lower = minWidth ?? (dense ? 64.0 : 76.0);
  final upper = math.max(lower, maxWidth);
  return math.max(trigger, menu).ceilToDouble().clamp(lower, upper);
}
