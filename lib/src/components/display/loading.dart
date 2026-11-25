import 'package:material_ui/material_ui.dart';

import '../../l10n/localizations.dart';
import '../../primitives/visual_surface.dart';
import '../../theme/theme.dart';
import '../../theme/visual_role.dart';
import '../layout/scroll_view.dart';

/// Theme-aligned progress spinner with constraint-safe sizing, live-region
/// accessibility semantics, and an optional visible label.
class YumeiroSpinner extends StatelessWidget {
  const YumeiroSpinner({
    super.key,
    this.size = 20,
    this.strokeWidth = 2.2,
    this.label,
    this.color,
    this.semanticLabel = _defaultSemanticLabel,
  });

  static const String _defaultSemanticLabel = '\u0000';

  final double size;
  final double strokeWidth;
  final String? label;
  final Color? color;

  /// Accessibility label announced by screen readers when [label] is null.
  /// Pass `null` explicitly when a parent widget (such as [YumeiroLoadingCard])
  /// owns the live-region announcement.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final effectiveColor = color ?? theme.accent;

    // Align + LayoutBuilder prevent stretched Row/Column parents from distorting
    // the circular progress indicator into an oval.
    final indicator = Align(
      widthFactor: 1,
      heightFactor: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dimension = size.clamp(0.0, constraints.biggest.shortestSide);
          return SizedBox.square(
            dimension: dimension.toDouble(),
            child: CircularProgressIndicator(
              strokeWidth: strokeWidth,
              valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
            ),
          );
        },
      ),
    );

    if (label case final text?) {
      return _labeledSpinner(
        indicator: indicator,
        label: text,
        spacing: theme.spacing.sm,
        style: theme.typography.supporting.copyWith(color: theme.muted),
      );
    }
    final announcement = semanticLabel == _defaultSemanticLabel
        ? YumeiroLocalizations.of(context).loading
        : semanticLabel;
    return announcement == null
        ? indicator
        : Semantics(
            container: true,
            liveRegion: true,
            label: announcement,
            child: indicator,
          );
  }
}

/// Centered panel card presenting an active loading spinner and live-region message.
class YumeiroLoadingCard extends StatelessWidget {
  const YumeiroLoadingCard({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(theme.spacing.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: YumeiroVisualSurface(
            role: YumeiroSurfaceRole.panel,
            clipBehavior: Clip.antiAlias,
            padding: EdgeInsets.all(theme.spacing.lg),
            child: _labeledSpinner(
              indicator: const YumeiroSpinner(semanticLabel: null),
              label: message,
              spacing: theme.spacing.md,
              style: theme.typography.body.copyWith(color: theme.text),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _labeledSpinner({
  required Widget indicator,
  required String label,
  required double spacing,
  required TextStyle style,
}) => Semantics(
  container: true,
  liveRegion: true,
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      indicator,
      SizedBox(width: spacing),
      Flexible(child: Text(label, style: style)),
    ],
  ),
);

/// Generic empty/placeholder state presenter supporting both compact section
/// mode and full-viewport centered presentation with localized defaults.
class YumeiroEmptyState extends StatelessWidget {
  const YumeiroEmptyState({
    super.key,
    this.title,
    this.message,
    this.icon,
    this.iconColor,
    this.action,
    this.compact = false,
  });

  final String? title;
  final String? message;
  final IconData? icon;
  final Color? iconColor;

  /// Optional recovery action, such as a reload button.
  final Widget? action;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final l10n = YumeiroLocalizations.of(context);
    final iconSize = compact ? 32.0 : 44.0;
    final typography = theme.typography;
    final titleStyle = typography.title.copyWith(color: theme.text);
    final messageStyle = typography.supporting.copyWith(color: theme.muted);
    final message = this.message;
    final content = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: compact ? 360 : 420),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: compact ? 12 : 24,
            horizontal: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon ?? theme.icons.auto,
                size: iconSize,
                color: iconColor ?? theme.accentSoft,
              ),
              SizedBox(height: compact ? 10 : 16),
              Text(
                title ?? l10n.emptyStateTitle,
                textAlign: TextAlign.center,
                style: titleStyle,
              ),
              if (message != null && message.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(message, textAlign: TextAlign.center, style: messageStyle),
              ],
              if (action case final recovery?) ...[
                SizedBox(height: compact ? 14 : 20),
                recovery,
              ],
            ],
          ),
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedHeight) return content;
        return YumeiroScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: content,
          ),
        );
      },
    );
  }
}
