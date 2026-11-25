import 'package:material_ui/material_ui.dart';

import '../../foundation/modality.dart';
import '../../l10n/localizations.dart';
import '../../primitives/backdrop_group.dart';
import '../../theme/theme.dart';
import '../controls/buttons.dart';
import 'panels.dart';
import 'setting_row_header.dart';

/// A back action supplied by the host shell without binding to any router.
class YumeiroNavigationScope extends InheritedWidget {
  const YumeiroNavigationScope({super.key, this.onBack, required super.child});

  final VoidCallback? onBack;

  static YumeiroNavigationScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<YumeiroNavigationScope>();

  @override
  bool updateShouldNotify(YumeiroNavigationScope oldWidget) =>
      onBack != oldWidget.onBack;
}

/// Adapts the heading and its actions to input modality and available width.
/// The regular constructor reads [YumeiroNavigationScope.onBack] from the host.
class YumeiroPageHeader extends StatelessWidget {
  const YumeiroPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.badge,
    this.actions = const <Widget>[],
    this.bottomDivider = false,
  }) : onBack = null,
       namesRoute = false,
       _compact = false;

  /// Builds a single-line bar for a page, dialog, or sheet with explicit
  /// navigation actions. The parent is responsible for safe areas.
  const YumeiroPageHeader.compact({
    super.key,
    required this.title,
    this.onBack,
    this.actions = const <Widget>[],
    this.namesRoute = false,
  }) : subtitle = null,
       badge = null,
       bottomDivider = false,
       _compact = true;

  final String title;
  final String? subtitle;
  final Widget? badge;
  final List<Widget> actions;
  final bool bottomDivider;
  final VoidCallback? onBack;

  /// Whether the compact title names its enclosing route for accessibility.
  final bool namesRoute;
  final bool _compact;

  @override
  Widget build(BuildContext context) {
    if (_compact) {
      return buildYumeiroCompactHeader(
        context,
        title: title,
        leading: _backButton(context, onBack),
        actions: actions,
        namesRoute: namesRoute,
      );
    }

    final theme = YumeiroTheme.of(context);
    final responsive = YumeiroResponsive.of(context);
    final isTouch = responsive.modality == YumeiroModality.touch;
    final back = YumeiroNavigationScope.maybeOf(context)?.onBack;
    final subtitle = this.subtitle;
    final subtitleText = subtitle == null || subtitle.isEmpty
        ? null
        : Text(
            subtitle,
            style: theme.typography.supporting.copyWith(color: theme.muted),
          );

    if (isTouch) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          buildYumeiroCompactHeader(
            context,
            title: title,
            subtitle: subtitleText,
            leading: _backButton(context, back),
            actions: actions,
          ),
          if (badge != null)
            Padding(
              padding: EdgeInsets.only(top: theme.spacing.xs),
              child: YumeiroBackdropGroup(
                child: Wrap(
                  spacing: theme.spacing.sm,
                  runSpacing: theme.spacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [badge!],
                ),
              ),
            ),
          if (bottomDivider) ...[
            SizedBox(height: theme.spacing.sm),
            const YumeiroDivider(),
          ],
        ],
      );
    }

    final trailing = <Widget>[?badge, ...actions];
    final titleBlock = _buildHeading(
      context,
      title: Text(
        title,
        style: theme.typography.pageTitle.copyWith(color: theme.text),
      ),
      subtitle: subtitleText,
      leading: _backButton(context, back),
    );

    final row = YumeiroBackdropGroup(
      child: YumeiroSettingRowHeader(
        title: titleBlock,
        spacing: theme.spacing.md,
        runSpacing: theme.spacing.md,
        trailing: _buildActions(trailing, theme.spacing.sm),
      ),
    );

    if (!bottomDivider) return row;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        row,
        SizedBox(height: theme.spacing.md),
        const YumeiroDivider(),
      ],
    );
  }
}

/// Shared layout for compact page headings and selection toolbars.
Widget buildYumeiroCompactHeader(
  BuildContext context, {
  required String title,
  Widget? leading,
  required List<Widget> actions,
  double? actionSpacing,
  Widget? subtitle,
  bool namesRoute = false,
}) {
  final theme = YumeiroTheme.of(context);
  final heading = Text(
    title,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: theme.typography.textTheme.titleLarge,
  );
  return YumeiroBackdropGroup(
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Align(
        heightFactor: 1,
        child: YumeiroSettingRowHeader(
          spacing: theme.spacing.sm,
          runSpacing: theme.spacing.xs,
          title: _buildHeading(
            context,
            title: namesRoute
                ? Semantics(container: true, namesRoute: true, child: heading)
                : heading,
            subtitle: subtitle,
            leading: leading,
          ),
          trailing: _buildActions(actions, actionSpacing ?? theme.spacing.xs),
        ),
      ),
    ),
  );
}

Widget? _buildActions(List<Widget> actions, double gap) => actions.isEmpty
    ? null
    : Wrap(
        alignment: WrapAlignment.end,
        spacing: gap,
        runSpacing: gap,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: actions,
      );

Widget _buildHeading(
  BuildContext context, {
  required Widget title,
  required Widget? subtitle,
  required Widget? leading,
}) {
  final theme = YumeiroTheme.of(context);
  final heading = subtitle == null
      ? title
      : Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: theme.spacing.xs,
          children: [title, subtitle],
        );
  if (leading == null) return heading;

  return Row(
    mainAxisSize: MainAxisSize.min,
    spacing: theme.spacing.sm,
    children: [
      leading,
      Flexible(child: heading),
    ],
  );
}

Widget? _backButton(BuildContext context, VoidCallback? onBack) =>
    onBack == null
    ? null
    : YumeiroButton(
        variant: YumeiroButtonVariant.ghost,
        icon: YumeiroTheme.of(context).icons.back,
        tooltip: YumeiroLocalizations.of(context).back,
        onPressed: onBack,
      );
