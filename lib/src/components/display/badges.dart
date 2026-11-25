import 'package:material_ui/material_ui.dart';

import '../../primitives/visual_scope.dart';
import '../../primitives/visual_surface.dart';
import '../../theme/semantic_visuals.dart';
import '../../theme/theme.dart';
import '../../theme/visual_role.dart';
import '../overlays/tooltip.dart';
import 'compact_label.dart';
import 'metric_typography.dart';

/// Passive status, metadata, or artwork badge.
class YumeiroBadge extends StatelessWidget {
  /// Compact text or custom content on the theme's compact surface.
  ///
  /// The default badge has a muted foreground. [statusRole] applies a status
  /// palette and [tint] supplies a custom palette. [visualOverride] adjusts
  /// the resolved appearance.
  const YumeiroBadge({
    super.key,
    this.label,
    this.child,
    this.statusRole,
    this.icon,
    this.tint,
    this.dense = false,
    this.height,
    this.padding,
    this.visualOverride,
    this.emphasized = false,
    this.maxLines = 1,
  }) : assert(label != null || child != null),
       _overlay = false,
       backgroundColor = null,
       foregroundColor = null;

  /// Intrinsically sized badge for overlaying artwork.
  const YumeiroBadge.overlay({
    super.key,
    this.label,
    this.icon,
    this.child,
    this.backgroundColor,
    this.foregroundColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
  }) : assert(label != null || child != null),
       _overlay = true,
       statusRole = null,
       tint = null,
       dense = false,
       height = null,
       visualOverride = null,
       emphasized = true,
       maxLines = null;

  final String? label;
  final Widget? child;
  final YumeiroStatusRole? statusRole;
  final IconData? icon;
  final Color? tint;
  final bool dense;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final YumeiroVisualOverride? visualOverride;
  final bool emphasized;
  final int? maxLines;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool _overlay;

  @override
  Widget build(BuildContext context) {
    if (_overlay) return _buildOverlay(context);
    final theme = YumeiroTheme.of(context);
    final status = switch (statusRole) {
      final role? => theme.visuals.status(role),
      null => null,
    };
    final (fillColor, foreground) = switch (tint) {
      final color? => (
        theme.visuals.customStatusFill(color),
        theme.visuals.customStatusForeground(color),
      ),
      null => (status?.subtleFill, status?.foreground ?? theme.colors.muted),
    };
    final configuredOverride =
        visualOverride ??
        (statusRole == null && tint == null
            ? YumeiroVisualScope.maybeOf(context)?.visualOverride
            : null);
    final colorDelta = YumeiroVisualDelta(
      fill: fillColor == null ? null : YumeiroSolidFill(fillColor),
      foreground: foreground,
    );
    final textColor =
        configuredOverride
            ?.apply(
              theme.visuals
                  .surface(YumeiroSurfaceRole.compact)
                  .apply(colorDelta),
              const {},
            )
            .foreground ??
        foreground;
    final surfaceOverride = switch ((fillColor, configuredOverride)) {
      (null, final override?) => override,
      (_, final override?) => _BadgeTintOverride(colorDelta, override),
      (_, null) => YumeiroVisualOverride(base: colorDelta),
    };
    final labelStyle = theme.typography
        .tag(dense: dense)
        .copyWith(
          color: textColor,
          fontWeight: emphasized ? theme.typography.emphasisWeight : null,
        );
    final labelWidget = child != null
        ? DefaultTextStyle.merge(style: labelStyle, child: child!)
        : Text(
            label!,
            maxLines: maxLines,
            overflow: maxLines == null ? null : TextOverflow.ellipsis,
            style: labelStyle,
          );

    return CompactLabel(
      label: labelWidget,
      icon: icon,
      iconColor: textColor,
      dense: dense,
      height: height,
      padding: padding,
      visualOverride: surfaceOverride,
    );
  }

  Widget _buildOverlay(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final foreground = foregroundColor ?? theme.colors.text;
    return YumeiroVisualSurface(
      role: YumeiroSurfaceRole.compact,
      visualOverride: YumeiroVisualOverride(
        base: YumeiroVisualDelta(
          fill: backgroundColor == null
              ? null
              : YumeiroSolidFill(backgroundColor!),
          foreground: foreground,
        ),
      ),
      padding: padding,
      child:
          child ??
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) Icon(icon, size: 11, color: foreground),
              if (icon != null && label != null) const SizedBox(width: 3),
              if (label != null)
                Text(
                  label!,
                  style: theme.typography.caption.copyWith(
                    fontWeight: theme.typography.emphasisWeight,
                    color: foreground,
                  ),
                ),
            ],
          ),
    );
  }
}

class _BadgeTintOverride extends YumeiroVisualOverride {
  const _BadgeTintOverride(YumeiroVisualDelta base, this.configured)
    : super(base: base);

  final YumeiroVisualOverride configured;

  @override
  YumeiroVisualAppearance apply(
    YumeiroVisualAppearance appearance,
    Set<WidgetState> widgetStates,
  ) => configured.apply(super.apply(appearance, widgetStates), widgetStates);
}

/// Numeric/metric summary tile built on [YumeiroSurfaceRole.readout].
class YumeiroStatTile extends StatelessWidget {
  const YumeiroStatTile({
    super.key,
    required this.value,
    required this.label,
    this.statusRole = YumeiroStatusRole.neutral,
    this.surfaceRole = YumeiroSurfaceRole.readout,
    this.tooltip,
    this.padding = defaultContentPadding,
    this.valueMaxLines = 1,
  });

  static const defaultContentPadding = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 10,
  );

  final String value;
  final String label;
  final YumeiroStatusRole statusRole;
  final YumeiroSurfaceRole surfaceRole;
  final String? tooltip;
  final EdgeInsetsGeometry padding;
  final int valueMaxLines;

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final status = theme.visuals.status(statusRole);
    final styles = metricTextStyles(
      theme,
      inline: false,
      valueColor: status.foreground,
    );

    final tile = YumeiroVisualSurface(
      role: surfaceRole,
      visualOverride: YumeiroVisualOverride(
        base: YumeiroVisualDelta(foreground: status.foreground),
      ),
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            maxLines: valueMaxLines,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: styles.value,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: styles.label,
          ),
        ],
      ),
    );

    if (tooltip == null) return tile;
    return YumeiroTooltip(message: tooltip!, child: tile);
  }
}
