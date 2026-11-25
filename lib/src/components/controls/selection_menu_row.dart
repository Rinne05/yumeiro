import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../foundation/modality.dart';
import '../../theme/theme.dart';
import '../../theme/theme_extension.dart';
import '../overlays/menu_visuals.dart';
import 'checkboxes.dart';
import 'form_picker_trigger.dart';
import 'select_trigger.dart';
import 'selection_option.dart';

const selectionMenuSurfacePadding = EdgeInsets.symmetric(vertical: 4);
const selectionMenuRowInsets = EdgeInsets.symmetric(
  horizontal: 4,
  vertical: 1.5,
);
const selectionMenuRowContentPadding = EdgeInsets.symmetric(
  horizontal: 8,
  vertical: 4,
);
const selectionMenuSubtitleGap = 2.0;
const _iconGap = 6.0;

double selectionMenuRowExtent(bool dense) => dense ? 30 : 34;

double selectionMenuRowHeight<T>(
  BuildContext context,
  Iterable<YumeiroSelectionOption<T>> options, {
  required bool dense,
  bool multiple = false,
}) {
  final theme = YumeiroTheme.of(context);
  final typography = theme.typography;
  final title = math.max(
    yumeiroSingleLineTextHeight(context, typography.option(dense: dense)),
    yumeiroSingleLineTextHeight(
      context,
      typography.option(dense: dense, selected: true),
    ),
  );
  final subtitle = options.any((option) => option.subtitle != null)
      ? yumeiroSingleLineTextHeight(context, typography.caption) +
            selectionMenuSubtitleGap
      : 0.0;
  final leading = multiple
      ? math.max(
          theme.iconSizes.sm,
          YumeiroModalityScope.metricsOf(context).checkboxSize,
        )
      : theme.iconSizes.sm;
  return math.max(
    selectionMenuRowExtent(dense),
    math.max(title + subtitle, leading) +
        selectionMenuRowContentPadding.vertical +
        selectionMenuRowInsets.vertical,
  );
}

({double leading, double trailing}) _iconSlots<T>(
  YumeiroThemeExtension theme,
  YumeiroSelectionOption<T> option, {
  required bool dense,
  required bool centered,
  required bool showCheckmark,
  double checkboxSize = 0,
}) {
  final leading = option.icon == null ? 0.0 : theme.iconSizes.sm + _iconGap;
  final trailing =
      (option.trailingIcon == null
          ? 0.0
          : (dense ? theme.iconSizes.xs : theme.iconSizes.sm) + _iconGap) +
      (showCheckmark ? theme.iconSizes.sm + _iconGap : 0) +
      (checkboxSize == 0 ? 0 : checkboxSize + _iconGap);
  if (!centered) return (leading: leading, trailing: trailing);
  final side = math.max(leading, trailing);
  return (leading: side, trailing: side);
}

double selectionMenuContentWidth<T>(
  BuildContext context,
  Iterable<YumeiroSelectionOption<T>> options, {
  required bool dense,
  required bool showCheckmark,
  TextAlign textAlign = TextAlign.start,
  String Function(YumeiroSelectionOption<T>)? labelBuilder,
}) {
  final theme = YumeiroTheme.of(context);
  final selectedStyle = theme.typography.option(selected: true, dense: dense);
  final optionStyle = theme.typography.option(dense: dense);
  var contentWidth = 0.0;
  for (final option in options) {
    final label = labelBuilder?.call(option) ?? option.label;
    final labelWidth = math.max(
      yumeiroSelectTextWidth(context, label, selectedStyle),
      yumeiroSelectTextWidth(context, label, optionStyle),
    );
    final subtitleWidth = option.subtitle == null
        ? 0.0
        : yumeiroSelectTextWidth(
            context,
            option.subtitle!,
            theme.typography.caption,
          );
    final slots = _iconSlots(
      theme,
      option,
      dense: dense,
      centered: textAlign == TextAlign.center,
      showCheckmark: showCheckmark,
    );
    contentWidth = math.max(
      contentWidth,
      math.max(labelWidth, subtitleWidth) + slots.leading + slots.trailing,
    );
  }
  return contentWidth +
      selectionMenuRowContentPadding.horizontal +
      selectionMenuRowInsets.horizontal +
      selectionMenuSurfacePadding.horizontal;
}

/// Pointer option renderer for single and multiple selection menus.
class SelectionMenuRow<T> extends StatelessWidget {
  const SelectionMenuRow({
    super.key,
    required this.option,
    required this.selected,
    required this.onPressed,
    required this.dense,
    this.highlighted = false,
    this.autofocus = false,
    this.textAlign = TextAlign.start,
    this.displayLabel,
    this.showCheckmark = false,
    this.showCheckbox = false,
  });

  final YumeiroSelectionOption<T> option;
  final bool selected;
  final VoidCallback? onPressed;
  final bool dense;
  final bool highlighted;
  final bool autofocus;
  final TextAlign textAlign;
  final String? displayLabel;
  final bool showCheckmark;
  final bool showCheckbox;

  @override
  Widget build(BuildContext context) => YumeiroMenuVisualButton(
    selected: selected,
    checked: showCheckbox ? selected : null,
    highlighted: highlighted,
    autofocus: autofocus,
    onPressed: option.enabled ? onPressed : null,
    minHeight: selectionMenuRowExtent(dense) - selectionMenuRowInsets.vertical,
    padding: selectionMenuRowContentPadding,
    builder: (context, appearance) {
      final theme = YumeiroTheme.of(context);
      final foreground = appearance.foreground;
      final disabled = !option.enabled || onPressed == null;
      final iconColor = selected || disabled ? foreground : theme.muted;
      final centered = textAlign == TextAlign.center;
      final checkboxSize = showCheckbox
          ? YumeiroModalityScope.metricsOf(context).checkboxSize
          : 0.0;
      final slots = _iconSlots(
        theme,
        option,
        dense: dense,
        centered: centered,
        showCheckmark: showCheckmark,
        checkboxSize: checkboxSize,
      );
      Widget icon(IconData data, {double? size}) => ExcludeSemantics(
        child: Icon(
          data,
          size: size ?? theme.iconSizes.sm,
          color: iconColor,
          applyTextScaling: false,
        ),
      );

      final label = Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: centered
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Text(
            displayLabel ?? option.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: textAlign,
            style: theme.typography
                .option(selected: selected, dense: dense)
                .copyWith(inherit: false, color: foreground),
          ),
          if (option.subtitle case final subtitle?) ...[
            const SizedBox(height: selectionMenuSubtitleGap),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: textAlign,
              style: theme.typography.caption.copyWith(
                inherit: false,
                color: foreground,
              ),
            ),
          ],
        ],
      );
      final leadingIcon = option.icon;
      final trailingIcon = option.trailingIcon;
      final trailing = [
        if (trailingIcon != null)
          icon(trailingIcon, size: dense ? theme.iconSizes.xs : null),
        if (showCheckmark)
          selected
              ? icon(theme.icons.check)
              : SizedBox(width: theme.iconSizes.sm),
        if (showCheckbox)
          ExcludeSemantics(
            child: ExcludeFocus(
              child: IgnorePointer(
                child: SizedBox.square(
                  dimension: checkboxSize,
                  child: buildYumeiroRowCheckbox(
                    value: selected,
                    dense: true,
                    onChanged: option.enabled && onPressed != null
                        ? (_) => onPressed!()
                        : null,
                  ),
                ),
              ),
            ),
          ),
      ];
      if (slots.leading == 0 && slots.trailing == 0) {
        return Row(children: [Expanded(child: label)]);
      }
      return LayoutBuilder(
        builder: (context, constraints) {
          // Keep space for an ellipsis when an explicit menu width leaves
          // less room than the icon slots and a minimal label need.
          final availableSlots = math.max(0.0, constraints.maxWidth - 16);
          final scale = math.min(
            1.0,
            availableSlots / (slots.leading + slots.trailing),
          );
          Widget slot(
            double width,
            AlignmentDirectional alignment, {
            Widget? child,
          }) => SizedBox(
            width: width * scale,
            child: child == null
                ? null
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: alignment,
                    child: child,
                  ),
          );

          return Row(
            children: [
              slot(
                slots.leading,
                AlignmentDirectional.centerStart,
                child: leadingIcon == null
                    ? null
                    : Padding(
                        padding: const EdgeInsetsDirectional.only(
                          end: _iconGap,
                        ),
                        child: icon(leadingIcon),
                      ),
              ),
              Expanded(child: label),
              slot(
                slots.trailing,
                AlignmentDirectional.centerEnd,
                child: trailing.isEmpty
                    ? null
                    : Padding(
                        padding: const EdgeInsetsDirectional.only(
                          start: _iconGap,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: _iconGap,
                          children: trailing,
                        ),
                      ),
              ),
            ],
          );
        },
      );
    },
  );
}
