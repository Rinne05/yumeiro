import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../foundation/modality.dart';
import '../../l10n/localizations.dart';
import '../../primitives/backdrop_group.dart';
import '../../theme/theme.dart';
import '../controls/select.dart';
import '../controls/selection_option.dart';
import '../overlays/dialogs.dart';
import '../overlays/picker_overlay.dart';
import '../overlays/sheets.dart' show presentSingleSelectionSheet;
import 'list_tile.dart';
import 'panels.dart';
import 'row_visuals.dart';
import 'setting_row_header.dart';

part 'selection_setting.dart';

/// Adaptive settings row that arranges controls beside or below its heading.
class YumeiroSettingRow extends StatelessWidget {
  const YumeiroSettingRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.editor,
    this.editorMaxWidth,
    this.enabled = true,
  }) : assert(editorMaxWidth == null || editorMaxWidth >= 0);

  /// Builds a single-choice setting. Pointer users choose from an inline
  /// select, and touch users tap the row to open a selection sheet.
  ///
  /// Lists with more than ten options are searchable. [displayLabel] can
  /// override the resting label, and a null [onChanged] disables the row.
  static Widget select<T>({
    Key? key,
    required String title,
    String? subtitle,
    String? displayLabel,
    required T? value,
    required List<YumeiroSelectionOption<T>> options,
    required ValueChanged<T?>? onChanged,
  }) => _SelectionSetting<T>(
    key: key,
    title: title,
    subtitle: subtitle,
    displayLabel: displayLabel,
    value: value,
    options: options,
    onChanged: onChanged,
  );

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;

  /// Control rendered inline on wide pointer rows without [trailing].
  /// Otherwise it is stacked below the heading.
  final Widget? editor;

  /// Maximum width for an inline editor. Omit to use the standard width limit,
  /// or use [double.infinity] to let a group of controls use the available space
  /// while reserving room for the heading. Stacked editors use the full row.
  final double? editorMaxWidth;

  /// Controls the heading appearance. Embedded controls have their own state.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final metrics = YumeiroModalityScope.metricsOf(context);
    final isTouch = metrics.isTouch;

    final heading = RowHeading(
      title: Text(title),
      subtitle: subtitle == null || subtitle!.isEmpty ? null : Text(subtitle!),
      leading: leading,
      enabled: enabled,
    );

    final content = editor != null && trailing == null && !isTouch
        ? LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final inline = width >= 460;
              final editorBounds = inline
                  ? BoxConstraints(
                      maxWidth: editorMaxWidth == null
                          ? (width * 0.50).clamp(160.0, 440.0)
                          : math.min(
                              editorMaxWidth!,
                              math.max(0, width - theme.spacing.lg - 160),
                            ),
                    )
                  : BoxConstraints.tightFor(width: width);
              // Keep the editor mounted in the same wrap child when it moves
              // between the first and second runs.
              return YumeiroSettingRowHeader(
                title: heading,
                trailing: ConstrainedBox(
                  constraints: editorBounds,
                  child: editor!,
                ),
                spacing: theme.spacing.lg,
                runSpacing: theme.spacing.sm,
              );
            },
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              YumeiroSettingRowHeader(
                title: heading,
                trailing: trailing,
                spacing: theme.spacing.md,
                runSpacing: theme.spacing.sm,
              ),
              if (editor != null) ...[
                SizedBox(height: theme.spacing.sm),
                editor!,
              ],
            ],
          );

    return Padding(
      padding: rowContentPadding(context),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: metrics.minTargetSize),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: content,
        ),
      ),
    );
  }
}

/// Titled settings section wrapping children in a shared [YumeiroBackdropGroup]
/// and adaptive [YumeiroCard.panel] container when [framed] is enabled.
class YumeiroSettingsSection extends StatelessWidget {
  const YumeiroSettingsSection({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.children,
    this.framed,
  }) : _showDividers = true;

  /// Places the heading and rows directly on the surrounding surface.
  const YumeiroSettingsSection.flat({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.children,
  }) : framed = false,
       _showDividers = false;

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final List<Widget> children;
  final bool? framed;
  final bool _showDividers;

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final metrics = YumeiroModalityScope.metricsOf(context);
    final isFramed = framed ?? !metrics.isTouch;
    final divider = rowDividerDecoration(theme.line);

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: _showDividers
          ? [
              for (var i = 0; i < children.length; i++)
                DecoratedBox(
                  key: children[i].key == null
                      ? null
                      : ValueKey(children[i].key),
                  position: DecorationPosition.foreground,
                  decoration: i == children.length - 1
                      ? const BoxDecoration()
                      : divider,
                  child: children[i],
                ),
            ]
          : children,
    );

    return YumeiroBackdropGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            header: true,
            child: YumeiroSectionHeader(
              title: title,
              subtitle: subtitle,
              trailing: trailing,
            ),
          ),
          SizedBox(height: theme.spacing.sm),
          if (isFramed)
            YumeiroCard.panel(
              padding: EdgeInsets.symmetric(
                horizontal: metrics.horizontalPadding + 2,
                vertical: 4,
              ),
              child: body,
            )
          else
            body,
        ],
      ),
    );
  }
}
