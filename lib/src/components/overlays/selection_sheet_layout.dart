import 'package:material_ui/material_ui.dart';

import '../../foundation/modality.dart';
import '../../theme/theme.dart';

/// Internal layout state shared by a selection sheet and its search field.
class YumeiroSelectionSheetLayout extends InheritedWidget {
  static const searchMaxWidth = 360.0;

  const YumeiroSelectionSheetLayout({
    super.key,
    required this.compact,
    required super.child,
  });

  final bool compact;

  static EdgeInsets searchPaddingOf(BuildContext context) {
    final spacing = YumeiroTheme.of(context).spacing.sm;
    final compact =
        context
            .dependOnInheritedWidgetOfExactType<YumeiroSelectionSheetLayout>()
            ?.compact ??
        false;
    return EdgeInsets.symmetric(
      horizontal: spacing,
      vertical: compact ? 0 : spacing,
    );
  }

  @override
  bool updateShouldNotify(YumeiroSelectionSheetLayout oldWidget) =>
      compact != oldWidget.compact;
}

/// Estimates the height of the selector's title, search, one option, and
/// optional confirmation action before picking an anchored layout.
double yumeiroSelectionSheetMinHeight(
  BuildContext context, {
  required String title,
  required bool searchable,
  bool hasConfirmation = false,
}) {
  final target = YumeiroModalityScope.metricsOf(context).minTargetSize;
  final spacing = YumeiroTheme.of(context).spacing.sm;
  return (title.isEmpty ? 0 : kMinInteractiveDimension) +
      target +
      spacing * 4 +
      (searchable ? target + spacing * 2 : 0) +
      (hasConfirmation ? target + 32 : 0);
}
