import 'package:material_ui/material_ui.dart';

import '../../foundation/modality.dart';
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
        : YumeiroCheckbox(dense: dense, value: selected, onChanged: onChanged);
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
  return ExcludeSemantics(
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
  );
}
