import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../foundation/modality.dart';
import '../../foundation/typography.dart';
import '../../primitives/visual_surface.dart';
import '../../theme/semantic_visuals.dart';
import '../../theme/theme.dart';
import '../../theme/theme_extension.dart';
import '../../theme/visual_role.dart';
import '../layout/list_tile.dart';
import '../layout/row_visuals.dart';
import '../overlays/tooltip.dart';

/// Selectable value and presentation for a segmented control.
///
/// Provide a label or an icon. Use a tooltip to name an icon-only segment.
@immutable
class YumeiroSegmentOption<T> {
  const YumeiroSegmentOption({
    required this.value,
    this.label,
    this.subtitle,
    this.icon,
    this.leading,
    this.tooltip,
    this.enabled = true,
  }) : assert(
         label != null || icon != null,
         'YumeiroSegmentOption must provide at least a label or an icon.',
       );

  final T value;
  final String? label;

  /// Supporting text for a vertical segment.
  final String? subtitle;
  final IconData? icon;

  /// Custom content replacing the icon in a vertical segment.
  final Widget? leading;
  final String? tooltip;
  final bool enabled;
}

/// Unified segmented selector adapting padding, hit targets, and layout
/// automatically to [YumeiroModality] and [YumeiroDensity].
class YumeiroSegmentedControl<T> extends StatelessWidget {
  const YumeiroSegmentedControl({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.expand = false,
    this.dense = false,
  });

  /// Creates a vertical choice list with room for supporting content.
  ///
  /// A checkmark identifies the selected option by default. Set
  /// [showCheckmark] to false to show selection through the row styling alone.
  /// Call this method in a runtime widget expression.
  static Widget vertical<V>({
    Key? key,
    required List<YumeiroSegmentOption<V>> options,
    required V value,
    required ValueChanged<V>? onChanged,
    bool dense = false,
    bool showCheckmark = true,
  }) => _VerticalSegmentedControl<V>(
    key: key,
    options: options,
    value: value,
    onChanged: onChanged,
    dense: dense,
    showCheckmark: showCheckmark,
  );

  final List<YumeiroSegmentOption<T>> options;

  /// Currently selected option value, supplied by the caller.
  final T value;

  /// Reports the requested option value. Null disables all segments.
  final ValueChanged<T>? onChanged;
  final bool expand;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final metrics = YumeiroModalityScope.metricsOf(context);
    final layoutHeight = metrics.isTouch
        ? metrics.minTargetSize
        : dense
        ? metrics.denseControlHeight
        : metrics.minTargetSize;
    final shellInset = metrics.isTouch
        ? ((metrics.minTargetSize -
                      (dense
                          ? metrics.denseControlHeight
                          : metrics.controlHeight)) /
                  2)
              .clamp(0.0, 12.0)
        : 0.0;
    final iconSize = metrics.isTouch
        ? (dense ? theme.iconSizes.md : 22.0)
        : (dense ? theme.iconSizes.xs : theme.iconSizes.sm);

    return LayoutBuilder(
      builder: (context, constraints) {
        final rawItems = [
          for (final option in options)
            _buildSegment(
              context,
              theme,
              metrics,
              option,
              layoutHeight,
              shellInset,
              iconSize,
            ),
        ];

        Widget shell(Widget content) => YumeiroVisualSurface(
          role: YumeiroControlRole.secondary,
          states: {if (onChanged == null) WidgetState.disabled},
          visualInsets: shellInset > 0
              ? EdgeInsets.symmetric(vertical: shellInset)
              : null,
          child: content,
        );

        assert(
          !expand || constraints.hasBoundedWidth,
          'Expanded YumeiroSegmentedControl requires a finite available width.',
        );

        if (expand) {
          return shell(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [for (final item in rawItems) Expanded(child: item)],
              ),
            ),
          );
        }

        return Align(
          alignment: Alignment.centerLeft,
          widthFactor: 1,
          heightFactor: 1,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            primary: false,
            child: shell(
              IntrinsicHeight(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: rawItems,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSegment(
    BuildContext context,
    YumeiroThemeExtension theme,
    YumeiroMetrics metrics,
    YumeiroSegmentOption<T> option,
    double layoutHeight,
    double shellInset,
    double iconSize,
  ) {
    final selected = option.value == value;
    final enabled = onChanged != null && option.enabled;

    Widget item = Semantics(
      button: true,
      enabled: enabled,
      label: option.label == null ? option.tooltip : null,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: YumeiroInteractiveVisualSurface(
        role: YumeiroItemRole.selection,
        selected: selected,
        visualOverride: onChanged == null
            ? const YumeiroVisualOverride(base: YumeiroVisualDelta(opacity: 1))
            : null,
        visualInsets: EdgeInsets.symmetric(
          horizontal: 3,
          vertical: shellInset + 3,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: expand ? 4 : (dense ? 10 : 12),
        ),
        onTap: enabled ? () => onChanged!(option.value) : null,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: layoutHeight),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: metrics.isTouch ? (dense ? 6 : 10) : (dense ? 3 : 6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (option.icon != null) Icon(option.icon, size: iconSize),
                if (option.icon != null && option.label != null)
                  const SizedBox(width: 6),
                if (option.label != null)
                  Flexible(
                    child: YumeiroTextStyle(
                      style: theme.typography.control(
                        selected: selected,
                        dense: dense,
                      ),
                      child: Text(
                        option.label!,
                        maxLines: expand ? null : 1,
                        overflow: expand ? null : TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    if (option.tooltip != null && option.tooltip!.isNotEmpty) {
      item = YumeiroTooltip(message: option.tooltip!, child: item);
    }

    return item;
  }
}

class _VerticalSegmentedControl<T> extends StatelessWidget {
  const _VerticalSegmentedControl({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    required this.dense,
    required this.showCheckmark,
  });

  final List<YumeiroSegmentOption<T>> options;
  final T value;
  final ValueChanged<T>? onChanged;
  final bool dense;
  final bool showCheckmark;

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final metrics = YumeiroModalityScope.metricsOf(context);
    final touchMetrics = metrics.isTouch
        ? metrics
        : YumeiroMetrics.resolve(
            modality: YumeiroModality.touch,
            density: metrics.density,
          );
    final touchRowInset = rowVisualInsets(context, metrics: touchMetrics).left;
    final frameGap = math.max(3.0, touchRowInset);

    return YumeiroVisualSurface(
      role: YumeiroControlRole.secondary,
      padding: EdgeInsets.all(
        metrics.isTouch ? frameGap - touchRowInset : frameGap,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final option in options)
            metrics.isTouch
                ? _buildTouchOption(context, option, theme)
                : _buildOption(context, option, theme, metrics),
        ],
      ),
    );
  }

  Widget _buildTouchOption(
    BuildContext context,
    YumeiroSegmentOption<T> option,
    YumeiroThemeExtension theme,
  ) {
    final selected = option.value == value;
    final enabled = onChanged != null && option.enabled;
    final label = option.label;
    final Widget tile = Semantics(
      inMutuallyExclusiveGroup: true,
      label: label == null ? option.tooltip : null,
      child: YumeiroListTile(
        showChevron: false,
        role: YumeiroItemRole.selection,
        title: label == null ? const SizedBox.shrink() : Text(label),
        subtitle: option.subtitle == null || option.subtitle!.isEmpty
            ? null
            : Text(option.subtitle!),
        leading:
            option.leading ??
            (option.icon == null ? null : Icon(option.icon, size: 24)),
        trailing: showCheckmark
            ? (selected
                  ? Icon(theme.icons.check, size: 24)
                  : const SizedBox(width: 24))
            : null,
        selected: selected,
        enabled: enabled,
        dense: dense,
        onTap: enabled ? () => onChanged!(option.value) : null,
      ),
    );
    return option.tooltip == null || option.tooltip!.isEmpty
        ? tile
        : YumeiroTooltip(
            message: option.tooltip!,
            excludeFromSemantics: label == null ? true : null,
            child: tile,
          );
  }

  Widget _buildOption(
    BuildContext context,
    YumeiroSegmentOption<T> option,
    YumeiroThemeExtension theme,
    YumeiroMetrics metrics,
  ) {
    final selected = option.value == value;
    final enabled = onChanged != null && option.enabled;
    final label = option.label;
    final subtitle = option.subtitle;
    final titleStyle = theme.typography.control(
      selected: selected,
      dense: dense,
    );
    final subtitleTone = TextStyle(color: enabled ? theme.muted : theme.subtle);

    final leadingIcon = option.icon == null
        ? null
        : Icon(option.icon, size: theme.iconSizes.sm);
    final trailing = showCheckmark
        ? SizedBox.square(
            dimension: theme.iconSizes.sm,
            child: selected
                ? Icon(theme.icons.check, size: theme.iconSizes.sm)
                : null,
          )
        : null;

    final optionMinHeight =
        (dense ? metrics.denseControlHeight : metrics.controlHeight) - 6;

    final content = ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: metrics.isTouch ? metrics.minTargetSize : optionMinHeight,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 8 : 12,
          vertical: dense ? 3 : 6,
        ),
        child: Row(
          children: [
            if (option.leading != null) ...[
              option.leading!,
              const SizedBox(width: 8),
            ] else if (leadingIcon != null) ...[
              leadingIcon,
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (label != null)
                    YumeiroTextStyle(
                      style: titleStyle,
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    if (label != null) const SizedBox(height: 2),
                    YumeiroTextStyle(
                      style: theme.typography.caption,
                      child: Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: selected ? null : subtitleTone,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing],
          ],
        ),
      ),
    );

    final item = YumeiroInteractiveVisualSurface(
      role: YumeiroItemRole.selection,
      selected: selected,
      onTap: enabled ? () => onChanged!(option.value) : null,
      child: content,
    );
    final name = label ?? option.tooltip;
    final semanticLabel = [
      ?name,
      if (subtitle != null && subtitle.isNotEmpty) subtitle,
    ].join(', ');
    final semanticItem = Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: semanticLabel,
      onTap: enabled ? () => onChanged!(option.value) : null,
      child: ExcludeSemantics(child: item),
    );
    return option.tooltip == null || option.tooltip!.isEmpty
        ? semanticItem
        : YumeiroTooltip(
            message: option.tooltip!,
            excludeFromSemantics: label == null ? true : null,
            child: semanticItem,
          );
  }
}
