import 'package:material_ui/material_ui.dart';

import '../../foundation/modality.dart';
import '../../primitives/visual_surface.dart';
import '../../theme/semantic_visuals.dart';
import '../../theme/theme.dart';
import '../../theme/visual_role.dart';

/// Shared layout for badges, chips, and token labels.
class CompactLabel extends StatelessWidget {
  const CompactLabel({
    super.key,
    required this.label,
    this.icon,
    this.iconColor,
    this.removeAction,
    this.dense = false,
    this.height,
    this.padding,
    this.role = YumeiroSurfaceRole.compact,
    this.visualOverride,
    this.selected = false,
    this.onTap,
  });

  final Widget label;
  final IconData? icon;
  final Color? iconColor;
  final Widget? removeAction;
  final bool dense;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final YumeiroVisualRole role;
  final YumeiroVisualOverride? visualOverride;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final metrics = YumeiroModalityScope.metricsOf(context);
    final touchTarget =
        metrics.isTouch && (onTap != null || removeAction != null);
    final visualHeight =
        height ?? (dense ? metrics.denseChipHeight : metrics.chipHeight);
    final targetHeight = touchTarget ? metrics.minTargetSize : visualHeight;
    final visualInsets = touchTarget
        ? EdgeInsets.symmetric(vertical: (targetHeight - visualHeight) / 2)
        : null;
    final horizontalInset = dense ? 8.0 : 10.0;
    final verticalInset = dense ? 2.0 : 3.0;
    final contentPadding =
        padding ??
        EdgeInsetsDirectional.fromSTEB(
          horizontalInset,
          verticalInset,
          removeAction == null ? horizontalInset : (dense ? 4 : 6),
          verticalInset,
        );
    final actionPadding = metrics.isTouch && removeAction != null
        ? contentPadding.resolve(Directionality.of(context))
        : null;
    final surfacePadding =
        actionPadding?.copyWith(top: 0, bottom: 0) ?? contentPadding;
    final paddedLabel = actionPadding != null
        ? Padding(
            padding: EdgeInsets.only(
              top: actionPadding.top,
              bottom: actionPadding.bottom,
            ),
            child: label,
          )
        : label;
    final content = Center(
      widthFactor: 1,
      heightFactor: 1,
      child: icon == null && removeAction == null
          ? label
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon case final leadingIcon?) ...[
                  Icon(leadingIcon, size: theme.iconSizes.xs, color: iconColor),
                  SizedBox(width: dense ? 3 : 4),
                ],
                Flexible(child: paddedLabel),
                if (removeAction case final action?) ...[
                  SizedBox(width: dense ? 2 : 4),
                  action,
                ],
              ],
            ),
    );
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: targetHeight),
      child: onTap == null
          ? YumeiroVisualSurface(
              role: role,
              states: {if (selected) WidgetState.selected},
              visualOverride: visualOverride,
              visualInsets: visualInsets,
              padding: surfacePadding,
              child: content,
            )
          : YumeiroInteractiveVisualSurface(
              role: role,
              selected: selected,
              onTap: onTap,
              visualOverride: visualOverride,
              visualInsets: visualInsets,
              padding: surfacePadding,
              child: content,
            ),
    );
  }
}
