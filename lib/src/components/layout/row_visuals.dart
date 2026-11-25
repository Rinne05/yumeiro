import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../foundation/modality.dart';
import '../../theme/theme.dart';

/// The space around row paint, independent of content and hit targets.
EdgeInsets rowVisualInsets(BuildContext context, {YumeiroMetrics? metrics}) =>
    EdgeInsets.all(
      math.min(
        YumeiroTheme.of(context).spacing.xs / 2,
        (metrics ?? YumeiroModalityScope.metricsOf(context)).verticalPadding,
      ),
    );

BoxDecoration rowDividerDecoration(Color color) => BoxDecoration(
  border: Border(bottom: BorderSide(color: color)),
);

Widget rowNavigationIcon(BuildContext context, {IconData? icon, Color? color}) {
  final icons = YumeiroTheme.of(context).icons;
  final rtl = Directionality.of(context) == TextDirection.rtl;
  return ExcludeSemantics(
    child: Icon(
      icon ?? (rtl ? icons.chevronLeft : icons.chevronRight),
      color: color,
      // The chosen default chevron already points forward.
      textDirection: icon == null ? TextDirection.ltr : null,
    ),
  );
}

EdgeInsets rowContentPadding(BuildContext context) {
  final metrics = YumeiroModalityScope.metricsOf(context);
  return metrics.isTouch
      ? EdgeInsets.symmetric(
          horizontal: metrics.horizontalPadding,
          vertical: metrics.verticalPadding,
        )
      : EdgeInsets.all(YumeiroTheme.of(context).spacing.md);
}

/// Heading layout shared by standard list and settings rows.
class RowHeading extends StatelessWidget {
  const RowHeading({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.enabled = true,
    this.dense = false,
    this.selected,
  });

  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final bool enabled;
  final bool dense;
  final bool? selected;

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final typography = theme.typography;
    final titleStyle = dense || selected != null
        ? typography.control(selected: selected ?? true, dense: dense)
        : typography.title;
    final selectedForeground = selected == true
        ? DefaultTextStyle.of(context).style.color
        : null;
    final supportingColor =
        selectedForeground ?? (enabled ? theme.muted : theme.subtle);
    final label = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        DefaultTextStyle.merge(
          style: titleStyle.copyWith(
            color: selectedForeground ?? (enabled ? null : theme.subtle),
          ),
          child: title,
        ),
        if (subtitle case final details?) ...[
          SizedBox(height: theme.spacing.xs),
          DefaultTextStyle.merge(
            style: typography.supporting.copyWith(color: supportingColor),
            child: details,
          ),
        ],
      ],
    );
    return switch (leading) {
      final icon? => Row(
        mainAxisSize: MainAxisSize.min,
        spacing: theme.spacing.md,
        children: [
          IconTheme.merge(
            data: IconThemeData(
              color: supportingColor,
              size: theme.iconSizes.md,
            ),
            child: icon,
          ),
          Flexible(child: label),
        ],
      ),
      null => label,
    };
  }
}
