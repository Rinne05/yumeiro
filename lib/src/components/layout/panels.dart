import 'package:material_ui/material_ui.dart';

import '../../foundation/modality.dart';
import '../../l10n/localizations.dart';
import '../../primitives/backdrop_group.dart';
import '../../primitives/visual_surface.dart';
import '../../theme/semantic_visuals.dart';
import '../../theme/theme.dart';
import '../../theme/visual_role.dart';
import '../controls/buttons.dart';
import '../display/loading.dart';
import '../display/metric_typography.dart';
import 'setting_row_header.dart';

/// Keeps leading content left and actions right, wrapping naturally when needed.
class YumeiroActionRow extends StatelessWidget {
  const YumeiroActionRow({
    super.key,
    required this.leading,
    required this.actions,
  });

  final Widget leading;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final spacing = YumeiroTheme.of(context).spacing;
    return YumeiroBackdropGroup(
      child: YumeiroSettingRowHeader(
        title: leading,
        spacing: spacing.md,
        runSpacing: spacing.sm,
        trailing: actions.isEmpty
            ? null
            : Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: spacing.sm,
                runSpacing: spacing.sm,
                children: actions,
              ),
      ),
    );
  }
}

/// Interactive or passive semantic card ([YumeiroSurfaceRole.card]).
class YumeiroCard extends StatelessWidget {
  const YumeiroCard({
    super.key,
    required this.child,
    this.onTap,
    this.selected = false,
    this.role = YumeiroSurfaceRole.card,
    this.padding,
    this.visualOverride,
  }) : clipBehavior = Clip.antiAlias;

  /// Passive container with the panel surface role by default.
  const YumeiroCard.panel({
    super.key,
    required this.child,
    this.role = YumeiroSurfaceRole.panel,
    this.padding,
    this.visualOverride,
    this.clipBehavior = Clip.antiAlias,
  }) : onTap = null,
       selected = false;

  final Widget child;

  /// Adds an action to the card surface. Omit for a passive container.
  final VoidCallback? onTap;

  /// Host-owned selected state used by either passive or interactive cards.
  final bool selected;
  final YumeiroSurfaceRole role;
  final EdgeInsetsGeometry? padding;
  final YumeiroVisualOverride? visualOverride;

  /// Clipping for the passive surface.
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ?? const EdgeInsets.all(20);

    if (onTap == null) {
      return YumeiroVisualSurface(
        role: role,
        states: {if (selected) WidgetState.selected},
        padding: effectivePadding,
        visualOverride: visualOverride,
        clipBehavior: clipBehavior,
        child: child,
      );
    }

    return YumeiroInteractiveVisualSurface(
      role: role,
      selected: selected,
      onTap: onTap,
      padding: effectivePadding,
      visualOverride: visualOverride,
      child: child,
    );
  }
}

/// Section heading with optional uppercase eyebrow, subtitle, and trailing content.
/// Trailing content moves below the heading when both do not fit on one line.
class YumeiroSectionHeader extends StatelessWidget {
  const YumeiroSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.eyebrow,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final String? eyebrow;

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final subtitle = this.subtitle;
    final hasSubtitle = subtitle != null && subtitle.isNotEmpty;
    return YumeiroSettingRowHeader(
      spacing: theme.spacing.md,
      runSpacing: theme.spacing.sm,
      crossAxisAlignment: hasSubtitle
          ? WrapCrossAlignment.end
          : WrapCrossAlignment.center,
      title: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (eyebrow case final label?) ...[
            Text(
              label.toUpperCase(),
              style: theme.typography.caption.copyWith(
                color: theme.accentSoft,
                fontWeight: theme.typography.headingWeight,
              ),
            ),
            const SizedBox(height: 6),
          ],
          Text(
            title,
            style: theme.typography.textTheme.headlineSmall?.copyWith(
              color: theme.text,
            ),
          ),
          if (hasSubtitle) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.typography.supporting.copyWith(color: theme.muted),
            ),
          ],
        ],
      ),
      trailing: trailing,
    );
  }
}

/// Centered error placeholder for a failed page or section.
class YumeiroErrorState extends StatelessWidget {
  const YumeiroErrorState({
    super.key,
    required this.message,
    this.title,
    this.retryEnabled = true,
    this.onRetry,
    this.action,
  });

  final String? title;
  final String message;
  final VoidCallback? onRetry;
  final bool retryEnabled;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final l10n = YumeiroLocalizations.of(context);
    final effectiveAction =
        action ??
        (onRetry == null
            ? null
            : YumeiroButton(
                label: l10n.retry,
                icon: theme.icons.refresh,
                onPressed: retryEnabled ? onRetry : null,
              ));
    return Semantics(
      liveRegion: true,
      child: YumeiroEmptyState(
        icon: theme.icons.error,
        iconColor: theme.visuals.status(YumeiroStatusRole.danger).foreground,
        title: title ?? l10n.errorTitle,
        message: message,
        action: effectiveAction,
      ),
    );
  }
}

/// Standard-size read-only inline metric pill using [YumeiroSurfaceRole.readout].
class YumeiroMetricPill extends StatelessWidget {
  const YumeiroMetricPill({
    super.key,
    this.label,
    this.value,
    this.items,
    this.maxWidth,
  }) : assert(
         (label != null && value != null) || items != null,
         'YumeiroMetricPill must provide either label+value or items',
       );

  final String? label;
  final String? value;
  final List<({String label, String value})>? items;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final metrics = YumeiroModalityScope.metricsOf(context);
    final metricItems = items ?? [(label: label!, value: value!)];
    final singleMetric = metricItems.length == 1;
    final styles = metricTextStyles(theme, inline: true);

    Widget metricText(String text, TextStyle? style) {
      final content = Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
      return singleMetric ? Flexible(child: content) : content;
    }

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < metricItems.length; i++) ...[
          if (i > 0) ...[
            const SizedBox(width: 8),
            Container(width: 1, height: 12, color: theme.line),
            const SizedBox(width: 8),
          ],
          metricText(metricItems[i].label, styles.label),
          const SizedBox(width: 5),
          metricText(metricItems[i].value, styles.value),
        ],
      ],
    );

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: metrics.minTargetSize,
        maxWidth: maxWidth ?? double.infinity,
      ),
      child: YumeiroVisualSurface(
        role: YumeiroSurfaceRole.readout,
        visualInsets: metrics.isTouch ? metrics.controlVisualInsets : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          child: singleMetric
              ? row
              : Align(
                  widthFactor: 1,
                  heightFactor: 1,
                  alignment: Alignment.centerLeft,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: row,
                  ),
                ),
        ),
      ),
    );
  }
}

/// Horizontal divider colored from the current theme's separator token.
class YumeiroDivider extends StatelessWidget {
  const YumeiroDivider({
    super.key,
    this.height = 1,
    this.touchHeight,
    this.thickness = 1,
    this.indent = 0,
    this.endIndent = 0,
  });

  final double height;

  /// Overrides [height] in touch layouts.
  final double? touchHeight;
  final double thickness;
  final double indent;
  final double endIndent;

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    return Divider(
      height:
          touchHeight != null && YumeiroModalityScope.metricsOf(context).isTouch
          ? touchHeight
          : height,
      thickness: thickness,
      indent: indent,
      endIndent: endIndent,
      color: theme.line,
    );
  }
}
