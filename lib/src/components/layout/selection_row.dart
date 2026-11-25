import 'package:material_ui/material_ui.dart';

import '../../foundation/modality.dart';
import '../../primitives/visual_surface.dart';
import '../../theme/theme.dart';
import '../../theme/visual_role.dart';
import '../controls/selection_control.dart';
import 'row_visuals.dart';

/// Controlled selection row used in sheets, multi-select lists, and filters.
/// Callers own selection state and submission.
class YumeiroSelectionRow extends StatelessWidget {
  const YumeiroSelectionRow({
    super.key,
    required this.title,
    required this.selected,
    required this.onChanged,
    this.subtitle,
    this.leading,
    this.trailing,
    this.footer,
    this.card = false,
    this.enabled = true,
    this.dense = false,
    this.readOnly = false,
    this.multiple = true,
    this.leadingCheckbox = false,
    this.padding,
  });

  static const _indicatorSize = 24.0;

  /// Uses a standalone card surface for the same selection behavior.
  final bool card;
  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;

  /// Additional content aligned with [title] and [subtitle].
  final Widget? footer;
  final bool selected;
  final bool enabled;
  final bool dense;
  final bool readOnly;
  final bool multiple;
  final bool leadingCheckbox;
  final ValueChanged<bool>? onChanged;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final metrics = YumeiroModalityScope.metricsOf(context);
    final active = enabled && !readOnly && onChanged != null;
    final showsValueOnly = enabled && readOnly;
    final visualInsets = card ? null : rowVisualInsets(context);
    final role = card ? YumeiroControlRole.neutral : YumeiroItemRole.standard;
    final wrapsText = card || metrics.isTouch;
    final textOverflow = wrapsText ? TextOverflow.clip : TextOverflow.ellipsis;
    void choose() => onChanged?.call(multiple ? !selected : true);

    final indicator = SizedBox.square(
      dimension: card ? metrics.checkboxSize + 6 : _indicatorSize,
      child: multiple
          ? buildSelectionIndicator(
              multiple: true,
              selected: selected,
              onToggle: active ? choose : null,
              dense: !metrics.isTouch,
            )
          : selected
          ? ExcludeSemantics(
              child: Icon(theme.icons.check, size: _indicatorSize),
            )
          : null,
    );

    final titleStyle = card
        ? theme.typography.control(selected: selected, dense: dense)
        : theme.typography.option(selected: selected, dense: dense);
    final rowPadding =
        padding ??
        (card
            ? EdgeInsets.symmetric(
                horizontal: dense ? theme.spacing.sm : theme.spacing.md,
                vertical: dense ? 2 : theme.spacing.sm,
              )
            : EdgeInsets.symmetric(
                horizontal: theme.spacing.sm,
                vertical: dense ? theme.spacing.xs : theme.spacing.sm,
              ));

    final content = ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: dense ? metrics.denseTargetSize : metrics.minTargetSize,
      ),
      child: Padding(
        padding: rowPadding,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: card ? 0 : 32),
          child: Row(
            children: [
              if (leadingCheckbox && multiple) ...[
                indicator,
                SizedBox(width: theme.spacing.sm),
              ],
              if (leading != null) ...[
                leading!,
                SizedBox(width: theme.spacing.sm),
              ],
              Expanded(
                child: Builder(
                  builder: (context) {
                    final foreground = DefaultTextStyle.of(context).style.color;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DefaultTextStyle.merge(
                          style: titleStyle.copyWith(color: foreground),
                          maxLines: wrapsText ? null : 1,
                          overflow: textOverflow,
                          child: title,
                        ),
                        if (subtitle != null) ...[
                          if (card) const SizedBox(height: 2),
                          DefaultTextStyle.merge(
                            style: theme.typography.supporting.copyWith(
                              color: selected ? foreground : theme.muted,
                            ),
                            maxLines: wrapsText ? null : 2,
                            overflow: textOverflow,
                            child: subtitle!,
                          ),
                        ],
                        if (footer != null) ...[
                          SizedBox(height: theme.spacing.sm),
                          footer!,
                        ],
                      ],
                    );
                  },
                ),
              ),
              if (trailing != null) ...[
                SizedBox(width: theme.spacing.sm),
                trailing!,
              ],
              if (!leadingCheckbox || !multiple) ...[
                SizedBox(width: theme.spacing.sm),
                indicator,
              ],
            ],
          ),
        ),
      ),
    );
    // Cards with controls keep each control's own accessibility action.
    final mergeContents =
        card && leading == null && trailing == null && footer == null;
    final row = Semantics(
      container: !mergeContents,
      enabled: active || showsValueOnly,
      readOnly: showsValueOnly ? true : null,
      checked: multiple ? selected : null,
      selected: multiple ? null : selected,
      onTap: active && !mergeContents ? choose : null,
      child: showsValueOnly
          ? YumeiroVisualSurface(
              role: role,
              states: {if (selected) WidgetState.selected},
              visualInsets: visualInsets,
              child: content,
            )
          : YumeiroInteractiveVisualSurface(
              role: role,
              selected: selected,
              onTap: active ? choose : null,
              visualInsets: visualInsets,
              child: content,
            ),
    );
    return mergeContents ? MergeSemantics(child: row) : row;
  }
}
