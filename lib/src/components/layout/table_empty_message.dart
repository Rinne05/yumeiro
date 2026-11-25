import 'package:material_ui/material_ui.dart';

import '../../foundation/modality.dart';
import '../../l10n/localizations.dart';
import '../../theme/theme.dart';

/// Default empty message for standard and compact table layouts.
class TableEmptyMessage extends StatelessWidget {
  const TableEmptyMessage({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final metrics = YumeiroModalityScope.metricsOf(context);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: metrics.horizontalPadding,
        vertical:
            metrics.verticalPadding +
            (compact ? theme.spacing.xs : theme.spacing.md),
      ),
      child: Center(
        heightFactor: 1,
        child: Text(
          YumeiroLocalizations.of(context).emptyTable,
          textAlign: TextAlign.center,
          style: theme.typography.supporting.copyWith(color: theme.muted),
        ),
      ),
    );
  }
}
