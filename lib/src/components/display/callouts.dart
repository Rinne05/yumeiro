import 'package:material_ui/material_ui.dart';

import '../../foundation/modality.dart';
import '../../primitives/visual_surface.dart';
import '../../theme/semantic_visuals.dart';
import '../../theme/theme.dart';
import '../../theme/visual_role.dart';
import '../layout/setting_row_header.dart';

/// Semantic informational callout banner driven by [YumeiroStatusRole].
class YumeiroCallout extends StatelessWidget {
  const YumeiroCallout({
    super.key,
    required this.message,
    this.title,
    this.statusRole = YumeiroStatusRole.info,
    this.icon,
    this.action,
  });

  final String message;
  final String? title;
  final YumeiroStatusRole statusRole;
  final IconData? icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final metrics = YumeiroModalityScope.metricsOf(context);
    final status = theme.visuals.status(statusRole);
    final feedback = resolveYumeiroStatusFeedback(statusRole, theme.icons);
    final action = this.action;

    return Semantics(
      liveRegion: feedback.liveRegion,
      child: YumeiroVisualSurface(
        role: YumeiroSurfaceRole.inset,
        visualOverride: YumeiroVisualOverride(
          base: YumeiroVisualDelta(
            fill: YumeiroSolidFill(status.subtleFill),
            foreground: status.foreground,
          ),
        ),
        padding: action == null
            ? const EdgeInsets.symmetric(horizontal: 14, vertical: 10)
            : EdgeInsets.symmetric(
                horizontal: theme.spacing.lg,
                vertical: theme.spacing.sm,
              ),
        child: YumeiroSettingRowHeader(
          spacing: theme.spacing.md,
          runSpacing: theme.spacing.sm,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: action == null && title == null
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            spacing: theme.spacing.sm,
            children: [
              Icon(
                icon ?? feedback.icon,
                size: metrics.isTouch ? 24.0 : 16.0,
                color: status.foreground,
              ),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title case final title?) ...[
                      Text(
                        title,
                        style: theme.typography.title.copyWith(
                          color: status.foreground,
                        ),
                      ),
                      SizedBox(height: theme.spacing.xs),
                    ],
                    Text(
                      message,
                      style: theme.typography.supporting.copyWith(
                        color: status.foreground,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          trailing: action,
        ),
      ),
    );
  }
}
