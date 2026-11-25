import 'package:material_ui/material_ui.dart';

import '../../theme/theme_extension.dart';

/// Text styles shared by inline and stacked metric readouts.
({TextStyle label, TextStyle? value}) metricTextStyles(
  YumeiroThemeExtension theme, {
  required bool inline,
  Color? valueColor,
}) {
  final typography = theme.typography;
  final value = inline ? typography.tag() : typography.textTheme.titleLarge;
  return (
    label: typography.caption.copyWith(
      color: theme.muted,
      fontWeight: inline ? typography.controlWeight() : null,
    ),
    value: value?.copyWith(
      fontWeight: typography.headingWeight,
      color: valueColor ?? theme.text,
    ),
  );
}
