import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../foundation/modality.dart';
import '../../l10n/localizations.dart';
import '../../primitives/visual_scope.dart';
import '../../primitives/visual_surface.dart';
import '../../theme/semantic_visuals.dart';
import '../../theme/theme.dart';
import '../../theme/theme_extension.dart';
import '../../theme/visual_role.dart';
import 'buttons.dart';

/// Builds a clear action with the current field's accessible name.
Widget yumeiroPickerClearButton(
  BuildContext context, {
  required String fieldLabel,
  required bool dense,
  required VoidCallback onPressed,
  bool includeFieldLabelInTooltip = false,
}) {
  final clearLabel = YumeiroLocalizations.of(context).clear;
  final fieldActionLabel = '$clearLabel, $fieldLabel';
  return Semantics(
    container: true,
    child: YumeiroButton(
      variant: YumeiroButtonVariant.ghost,
      icon: YumeiroTheme.of(context).icons.close,
      tooltip: includeFieldLabelInTooltip ? fieldActionLabel : clearLabel,
      semanticLabel: fieldActionLabel,
      dense: dense,
      onPressed: onPressed,
    ),
  );
}

/// Paints the trigger at its full width with a separate trailing clear target.
Widget yumeiroFormPickerActions(
  BuildContext context, {
  required double maxWidth,
  required bool dense,
  required bool clearable,
  required Widget Function(double clearExtent, double chevronExtent) trigger,
  required Widget? clearButton,
  double leadingExtent = 0,
}) {
  if (!clearable) return trigger(0, 0);
  final (clearExtent: target, :chevronExtent) = yumeiroPickerActionExtents(
    YumeiroTheme.of(context),
    YumeiroModalityScope.metricsOf(context),
    dense,
  );
  // Two full targets need two rows in a particularly narrow field. Reserve
  // the same geometry when there is no value to clear.
  if (maxWidth < target + chevronExtent + leadingExtent) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        trigger(0, 0),
        SizedBox(
          height: target,
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: clearButton,
          ),
        ),
      ],
    );
  }
  return Stack(
    fit: StackFit.passthrough,
    children: [
      trigger(target, chevronExtent),
      if (clearButton != null)
        PositionedDirectional(
          top: 0,
          bottom: 0,
          end: chevronExtent,
          width: target,
          child: Center(child: clearButton),
        ),
    ],
  );
}

double yumeiroPickerHorizontalPadding(YumeiroMetrics metrics, bool dense) =>
    metrics.isTouch
    ? (dense ? 12.0 : metrics.horizontalPadding)
    : (dense ? 8.0 : 10.0);

double yumeiroPickerIconSize(
  YumeiroThemeExtension theme,
  YumeiroMetrics metrics,
  bool dense,
) => metrics.isTouch
    ? (dense ? theme.iconSizes.md : 22.0)
    : (dense ? theme.iconSizes.xs : theme.iconSizes.sm);

({double clearExtent, double chevronExtent}) yumeiroPickerActionExtents(
  YumeiroThemeExtension theme,
  YumeiroMetrics metrics,
  bool dense,
) {
  final target = dense ? metrics.denseTargetSize : metrics.minTargetSize;
  return (
    clearExtent: target,
    chevronExtent: math.max(
      target,
      yumeiroPickerHorizontalPadding(metrics, dense) +
          yumeiroPickerIconSize(theme, metrics, dense) +
          theme.spacing.sm,
    ),
  );
}

double yumeiroPickerMinHeight(
  BuildContext context,
  YumeiroMetrics metrics,
  bool dense, {
  TextStyle? style,
}) => math.max(
  dense ? metrics.denseTargetSize : metrics.minTargetSize,
  yumeiroSingleLineTextHeight(
        context,
        style ?? YumeiroTheme.of(context).typography.input(dense: dense),
      ) +
      (dense ? 10.0 : 14.0),
);

double yumeiroSingleLineTextHeight(BuildContext context, TextStyle style) {
  final line = TextPainter(
    text: TextSpan(text: ' ', style: style),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
  );
  final lineHeight = line.preferredLineHeight;
  line.dispose();
  return lineHeight;
}

YumeiroVisualOverride? yumeiroPickerErrorOverride(
  BuildContext context, {
  required bool enabled,
  required bool hasError,
}) => enabled && hasError
    ? _PickerErrorVisualOverride(
        YumeiroTheme.of(context).danger,
        YumeiroVisualScope.maybeOf(context)?.visualOverride,
      )
    : null;

/// Internal trigger for form fields that open a picker.
class YumeiroFormPickerTrigger extends StatelessWidget {
  const YumeiroFormPickerTrigger({
    super.key,
    required this.text,
    required this.isPlaceholder,
    required this.enabled,
    required this.readOnly,
    required this.hasError,
    required this.dense,
    required this.expand,
    this.width,
    this.icon,
    this.clearable = false,
    this.clearButton,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
    this.textAlign = TextAlign.start,
    this.onOpen,
  });

  final String text;
  final bool isPlaceholder;
  final bool enabled;
  final bool readOnly;
  final bool hasError;
  final bool dense;
  final bool expand;
  final double? width;
  final IconData? icon;
  final bool clearable;
  final Widget? clearButton;
  final FocusNode? focusNode;
  final bool autofocus;
  final String? semanticLabel;
  final TextAlign textAlign;
  final ValueChanged<BuildContext>? onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    return SizedBox(
      width: width,
      child: LayoutBuilder(
        builder: (context, constraints) => yumeiroFormPickerActions(
          context,
          maxWidth: constraints.maxWidth,
          dense: dense,
          clearable: clearable,
          clearButton: clearButton,
          trigger: (clearExtent, chevronExtent) => YumeiroPickerTriggerSurface(
            enabled: enabled,
            readOnly: readOnly,
            hasError: hasError,
            dense: dense,
            focusNode: focusNode,
            autofocus: autofocus,
            semanticLabel: semanticLabel,
            semanticValue: text,
            onOpen: onOpen,
            child: yumeiroPickerTriggerContent(
              context,
              text: text,
              style: theme.typography
                  .input(dense: dense)
                  .copyWith(color: isPlaceholder ? theme.subtle : theme.text),
              dense: dense,
              textAlign: textAlign,
              fillsWidth:
                  expand && constraints.hasBoundedWidth || width != null,
              icon: icon,
              showChevron: !readOnly,
              clearExtent: clearExtent,
              chevronExtent: chevronExtent,
            ),
          ),
        ),
      ),
    );
  }
}

/// Single-line content shared by the picker trigger variants.
Widget yumeiroPickerTriggerContent(
  BuildContext context, {
  required String text,
  required TextStyle style,
  required bool dense,
  TextAlign textAlign = TextAlign.start,
  bool fillsWidth = true,
  IconData? icon,
  bool showChevron = true,
  double clearExtent = 0,
  double chevronExtent = 0,
}) {
  final theme = YumeiroTheme.of(context);
  final metrics = YumeiroModalityScope.metricsOf(context);
  final iconSize = yumeiroPickerIconSize(theme, metrics, dense);
  final iconSlot = iconSize + theme.spacing.sm;
  final horizontalPadding = yumeiroPickerHorizontalPadding(metrics, dense);

  Widget content({
    required double startPadding,
    required double endPadding,
    required bool showLeading,
    required double chevronGap,
  }) => Padding(
    padding: EdgeInsetsDirectional.fromSTEB(startPadding, 0, endPadding, 0),
    child: Row(
      mainAxisSize: fillsWidth ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (showLeading) ...[
          Icon(icon, size: iconSize, color: theme.muted),
          SizedBox(width: theme.spacing.sm),
        ],
        Flexible(
          fit: fillsWidth ? FlexFit.tight : FlexFit.loose,
          child: Text(
            text,
            textAlign: textAlign,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
        if (clearExtent > 0) SizedBox(width: clearExtent),
        if (showChevron) ...[
          SizedBox(width: chevronGap),
          Icon(theme.icons.chevronDown, size: iconSize, color: theme.muted),
        ],
      ],
    ),
  );
  return ConstrainedBox(
    constraints: BoxConstraints(
      minHeight: yumeiroPickerMinHeight(context, metrics, dense),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        if (clearExtent > 0) {
          final labelExtent =
              constraints.maxWidth - clearExtent - chevronExtent;
          final padding = math.min(horizontalPadding, labelExtent);
          return content(
            startPadding: padding,
            endPadding: horizontalPadding,
            showLeading: icon != null && labelExtent >= padding + iconSlot,
            chevronGap: chevronExtent - horizontalPadding - iconSize,
          );
        }
        final width = constraints.maxWidth;
        final chevronWidth = showChevron ? iconSlot : 0.0;
        final padding = ((width - chevronWidth) / 4).clamp(
          0.0,
          horizontalPadding,
        );
        final showsLeading =
            icon != null && width >= chevronWidth + iconSlot + 2 * padding;
        return content(
          startPadding: padding,
          endPadding: padding,
          showLeading: showsLeading,
          chevronGap: theme.spacing.sm,
        );
      },
    ),
  );
}

/// Shared focus, semantics, and appearance for selection and form triggers.
class YumeiroPickerTriggerSurface extends StatelessWidget {
  const YumeiroPickerTriggerSurface({
    super.key,
    required this.enabled,
    required this.readOnly,
    required this.hasError,
    required this.dense,
    required this.focusNode,
    required this.autofocus,
    required this.onOpen,
    this.semanticLabel,
    this.semanticValue,
    required this.child,
  });

  final bool enabled;
  final bool readOnly;
  final bool hasError;
  final bool dense;
  final FocusNode? focusNode;
  final bool autofocus;
  final ValueChanged<BuildContext>? onOpen;
  final String? semanticLabel;
  final String? semanticValue;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final metrics = YumeiroModalityScope.metricsOf(context);
    final showsValueOnly = enabled && readOnly;
    final canOpen = enabled && !readOnly && onOpen != null;
    final insets = metrics.isTouch
        ? (dense
              ? metrics.denseControlVisualInsets
              : metrics.controlVisualInsets)
        : null;
    final errorOverride = yumeiroPickerErrorOverride(
      context,
      enabled: enabled,
      hasError: hasError,
    );
    final content = semanticLabel == null
        ? child
        : ExcludeSemantics(child: child);

    return Semantics(
      button: !showsValueOnly,
      enabled: canOpen || showsValueOnly,
      readOnly: showsValueOnly ? true : null,
      label: semanticLabel,
      value: semanticLabel == null ? null : semanticValue,
      child: showsValueOnly
          ? Focus(
              focusNode: focusNode,
              autofocus: autofocus,
              child: Builder(
                builder: (context) => YumeiroVisualSurface(
                  role: YumeiroControlRole.secondary,
                  states: {if (Focus.of(context).hasFocus) WidgetState.focused},
                  visualOverride: errorOverride,
                  visualInsets: insets,
                  child: content,
                ),
              ),
            )
          : YumeiroInteractiveVisualSurface(
              role: YumeiroControlRole.secondary,
              visualOverride: errorOverride,
              visualInsets: insets,
              focusNode: focusNode,
              autofocus: canOpen && autofocus,
              onTap: canOpen ? () => onOpen!(context) : null,
              child: content,
            ),
    );
  }
}

/// Composes a field outline with the override inherited from its visual scope.
class _PickerErrorVisualOverride extends YumeiroVisualOverride {
  const _PickerErrorVisualOverride(this.color, this.inherited);

  final Color color;
  final YumeiroVisualOverride? inherited;

  @override
  YumeiroVisualAppearance apply(
    YumeiroVisualAppearance appearance,
    Set<WidgetState> widgetStates,
  ) {
    final visual = inherited?.apply(appearance, widgetStates) ?? appearance;
    return visual.copyWith(
      outline: BorderSide(
        color: color,
        width: math.max(1.0, visual.outline.width),
      ),
    );
  }
}
