import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../foundation/color_math.dart';
import '../../foundation/modality.dart';
import '../../primitives/pixel_border.dart';
import '../../primitives/pixel_circle.dart';
import '../../primitives/selection_marks.dart';
import '../../theme/theme.dart';
import 'checkboxes.dart';

double selectionIndicatorWidth(YumeiroMetrics metrics) =>
    metrics.isTouch ? metrics.minTargetSize : 32.0;

Widget buildSelectionControl<T>({
  required bool multiple,
  required T radioValue,
  required bool selected,
  required VoidCallback? onToggle,
  required bool dense,
  bool parentHandlesDisabledOpacity = false,
  FocusNode? focusNode,
  RadioGroupRegistry<T>? groupRegistry,
}) {
  if (multiple) {
    final onChanged = onToggle == null ? null : (bool? _) => onToggle();
    return parentHandlesDisabledOpacity
        ? buildYumeiroRowCheckbox(
            dense: dense,
            value: selected,
            onChanged: onChanged,
          )
        : buildYumeiroSelectionCheckbox(
            dense: dense,
            value: selected,
            onChanged: onChanged,
          );
  }
  return Builder(
    builder: (context) {
      final foreground =
          IconTheme.of(context).color ?? YumeiroTheme.of(context).text;
      return Radio<T>(
        value: radioValue,
        focusNode: focusNode,
        groupRegistry: groupRegistry,
        enabled: onToggle != null,
        fillColor: WidgetStateProperty.resolveWith(
          (states) =>
              !parentHandlesDisabledOpacity &&
                  states.contains(WidgetState.disabled)
              ? foreground.withValues(alpha: foreground.a * .38)
              : foreground,
        ),
        materialTapTargetSize: dense
            ? MaterialTapTargetSize.shrinkWrap
            : MaterialTapTargetSize.padded,
        visualDensity: YumeiroModalityScope.metricsOf(context).isTouch
            ? VisualDensity.standard
            : null,
      );
    },
  );
}

enum _SelectionIndicatorValue { selected }

/// A radio or checkbox mark for a row that owns its own interaction.
Widget buildSelectionIndicator({
  required bool multiple,
  required bool selected,
  required VoidCallback? onToggle,
  required bool dense,
  bool disabledForItem = false,
  Key? markKey,
}) {
  const radioValue = _SelectionIndicatorValue.selected;
  final control = buildSelectionControl(
    multiple: multiple,
    radioValue: radioValue,
    selected: selected,
    onToggle: onToggle,
    dense: dense,
    parentHandlesDisabledOpacity: true,
  );
  return SelectionControlMark(
    multiple: multiple,
    selected: selected,
    enabled: onToggle != null,
    disabledForItem: disabledForItem,
    parentHandlesDisabledOpacity: true,
    markKey: markKey,
    child: ExcludeSemantics(
      child: ExcludeFocus(
        child: IgnorePointer(
          child: multiple
              ? control
              : RadioGroup<_SelectionIndicatorValue>(
                  groupValue: selected ? radioValue : null,
                  onChanged: (_) => onToggle?.call(),
                  child: control,
                ),
        ),
      ),
    ),
  );
}

/// Draws the themed selection glyph over an existing checkbox or radio.
///
/// The child supplies layout, semantics, and interaction. Use
/// [disabledForItem] to show a slash for an option that cannot be selected.
class SelectionControlMark extends StatelessWidget {
  const SelectionControlMark({
    super.key,
    required this.multiple,
    required this.selected,
    required this.enabled,
    this.disabledForItem = false,
    this.parentHandlesDisabledOpacity = false,
    this.markKey,
    required this.child,
  });

  final bool multiple;
  final bool selected;
  final bool disabledForItem;
  final bool enabled;
  final bool parentHandlesDisabledOpacity;
  final Key? markKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final checkbox = theme.checkboxVisuals;
    final pixel = checkbox.shape is YumeiroPixelBorder;
    if (multiple && !disabledForItem) return child;

    final radioTheme = RadioTheme.of(context);
    final control = disabledForItem
        ? Opacity(opacity: 0, alwaysIncludeSemantics: true, child: child)
        : RadioTheme(
            // Keep the native radio mounted when switching presets. For the
            // pixel glyph, hide its paint but keep focus and pointer reaction.
            data: pixel
                ? radioTheme.copyWith(
                    side: WidgetStateBorderSide.resolveWith(
                      (_) => BorderSide.none,
                    ),
                    backgroundColor: const WidgetStatePropertyAll(
                      Colors.transparent,
                    ),
                    innerRadius: const WidgetStatePropertyAll(0),
                  )
                : radioTheme,
            child: child,
          );
    if (!disabledForItem && !pixel) {
      return CustomPaint(key: markKey, child: control);
    }

    final states = <WidgetState>{
      if (selected) WidgetState.selected,
      if (!enabled) WidgetState.disabled,
    };
    final selectedInk = IconTheme.of(context).color ?? theme.onAccent;
    final disabledInk = selected && pixel ? selectedInk : theme.subtle;
    var radioInk = disabledForItem
        ? disabledInk
        : selected
        ? selectedInk
        : theme.lineStrong;
    if (!disabledForItem && !enabled && !parentHandlesDisabledOpacity) {
      radioInk = radioInk.withValues(alpha: radioInk.a * .38);
    }
    final fill = disabledForItem && selected
        ? yumeiroAlphaBlend(
            theme.accent.withValues(alpha: theme.accent.a * .42),
            theme.surfaceElevated,
          )
        : multiple
        ? checkbox.fillColor.resolve(states)
        : radioTheme.backgroundColor?.resolve(states);
    final checkboxOutline = checkbox.side.resolve(states) ?? BorderSide.none;

    return CustomPaint(
      key: markKey,
      foregroundPainter: _SelectionControlMarkPainter(
        checkbox: multiple ? checkbox.shape : null,
        pixel: pixel,
        outline: multiple
            ? pixel
                  ? checkboxOutline.copyWith(color: disabledInk)
                  : checkboxOutline
            : BorderSide(color: radioInk, width: 2),
        fill: fill,
        slash: disabledForItem ? disabledInk : null,
        dot: !disabledForItem && selected ? radioInk : null,
        textDirection: Directionality.of(context),
      ),
      child: control,
    );
  }
}

/// Passive marker for an unavailable option in a checkmark-only layout.
class UnavailableSelectionMark extends StatelessWidget {
  const UnavailableSelectionMark({
    super.key,
    this.selected = false,
    required this.size,
  });

  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: IgnorePointer(
      child: SizedBox.square(
        dimension: size,
        child: SelectionControlMark(
          multiple: false,
          selected: selected,
          enabled: false,
          disabledForItem: true,
          child: const SizedBox.expand(),
        ),
      ),
    ),
  );
}

class _SelectionControlMarkPainter extends CustomPainter {
  const _SelectionControlMarkPainter({
    required this.checkbox,
    required this.pixel,
    required this.outline,
    required this.fill,
    required this.slash,
    required this.dot,
    required this.textDirection,
  });

  final OutlinedBorder? checkbox;
  final bool pixel;
  final BorderSide outline;
  final Color? fill;
  final Color? slash;
  final Color? dot;
  final TextDirection textDirection;

  Path _radioPath(Rect rect) => pixel
      ? pixelCircleBorder(rect.width).getOuterPath(rect)
      : (Path()..addOval(rect));

  Paint _ink(Color color) => Paint()
    ..color = color
    ..isAntiAlias = !pixel;

  @override
  void paint(Canvas canvas, Size size) {
    final extent = math.min(Checkbox.width, size.shortestSide);
    if (extent == 0) return;
    final center = size.center(Offset.zero);
    final rect = Rect.fromCenter(center: center, width: extent, height: extent);
    if (checkbox case final shape?) {
      if (fill case final color?) {
        canvas.drawPath(
          shape.getOuterPath(rect, textDirection: textDirection),
          _ink(color),
        );
      }
      shape
          .copyWith(side: outline)
          .paint(canvas, rect, textDirection: textDirection);
    } else {
      final outer = _radioPath(rect);
      if (fill case final color?) canvas.drawPath(outer, _ink(color));
      final inner = rect.deflate(outline.width);
      if (!inner.isEmpty) {
        outer
          ..addPath(_radioPath(inner), Offset.zero)
          ..fillType = PathFillType.evenOdd;
      }
      canvas.drawPath(outer, _ink(outline.color));
    }
    if (slash case final color?) {
      paintUnavailableSlash(
        canvas,
        center,
        extent: extent,
        color: color,
        pixel: pixel,
      );
    } else if (dot case final color?) {
      final radius = extent / 6;
      canvas.drawPath(
        _radioPath(Rect.fromCircle(center: center, radius: radius)),
        _ink(color),
      );
    }
  }

  @override
  bool shouldRepaint(_SelectionControlMarkPainter oldDelegate) =>
      checkbox != oldDelegate.checkbox ||
      pixel != oldDelegate.pixel ||
      outline != oldDelegate.outline ||
      fill != oldDelegate.fill ||
      slash != oldDelegate.slash ||
      dot != oldDelegate.dot ||
      textDirection != oldDelegate.textDirection;
}
