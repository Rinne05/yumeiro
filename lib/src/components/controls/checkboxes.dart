import 'package:material_ui/material_ui.dart';

import '../../foundation/color_math.dart';
import '../../foundation/input.dart';
import '../../foundation/modality.dart';
import '../../primitives/pixel_border.dart';
import '../../primitives/selection_marks.dart';
import '../../theme/theme.dart';
import 'boolean_form_fields.dart';

/// Modality-adaptive checkbox styled from [YumeiroThemeExtension.checkboxVisuals].
class YumeiroCheckbox extends StatelessWidget {
  const YumeiroCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.tristate = false,
    this.label,
    this.labelWidget,
    this.dense = false,
    this.enabled = true,
    this.focusNode,
    this.autofocus = false,
    this.spacing = 8.0,
  }) : _rowOwnsDisabledOpacity = false,
       _showUnavailableMark = true;

  const YumeiroCheckbox._selection({
    required this.value,
    required this.onChanged,
    required this.dense,
    required this._rowOwnsDisabledOpacity,
    this.tristate = false,
    this.label,
    this.spacing = 8.0,
  }) : labelWidget = null,
       enabled = true,
       focusNode = null,
       autofocus = false,
       _showUnavailableMark = false;

  /// Creates a checkbox field for a Flutter [Form].
  ///
  /// With [tristate] enabled, a null value represents a mixed selection.
  /// Supply a validator to require a checked value. [required] marks the label.
  /// [onChanged] reports user edits after the field updates.
  static FormField<bool> form({
    Key? key,
    required String label,
    bool? initialValue = false,
    FormFieldSetter<bool>? onSaved,
    VoidCallback? onReset,
    FormFieldValidator<bool>? validator,
    AutovalidateMode? autovalidateMode,
    String? forceErrorText,
    bool enabled = true,
    String? helperText,
    bool required = false,
    String? semanticLabel,
    bool readOnly = false,
    bool dense = false,
    FocusNode? focusNode,
    bool autofocus = false,
    bool tristate = false,
    ValueChanged<bool?>? onChanged,
  }) => BooleanFormField<YumeiroCheckbox>(
    key: key,
    label: label,
    initialValue: initialValue,
    onSaved: onSaved,
    onReset: onReset,
    validator: validator,
    autovalidateMode: autovalidateMode,
    forceErrorText: forceErrorText,
    enabled: enabled,
    helperText: helperText,
    required: required,
    semanticLabel: semanticLabel,
    readOnly: readOnly,
    dense: dense,
    focusNode: focusNode,
    autofocus: autofocus,
    isCheckbox: true,
    allowsNull: tristate,
    onChanged: onChanged,
    buildControl: (value, onChanged, focusNode, autofocus) => YumeiroCheckbox(
      value: value,
      onChanged: onChanged,
      tristate: tristate,
      dense: dense,
      focusNode: focusNode,
      autofocus: autofocus,
    ),
  );

  /// Current host-owned value. Null represents mixed selection when
  /// [tristate] is enabled.
  final bool? value;

  /// Requests the next value. Store it in the host to update [value].
  /// Null or [enabled] set to false disables the control and marks it with a
  /// slash. Selected and mixed values use the same disabled appearance.
  final ValueChanged<bool?>? onChanged;

  /// Supports mixed selection and cycles false, true, and null on activation.
  final bool tristate;
  final String? label;
  final Widget? labelWidget;
  final bool dense;
  final bool enabled;
  final FocusNode? focusNode;
  final bool autofocus;
  final double spacing;

  final bool _rowOwnsDisabledOpacity;
  final bool _showUnavailableMark;

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final metrics = YumeiroModalityScope.metricsOf(context);
    final effectiveEnabled = enabled && onChanged != null;
    final showUnavailableMark = _showUnavailableMark && !effectiveEnabled;
    final size = metrics.isTouch
        ? metrics.minTargetSize
        : (dense ? metrics.checkboxSize + 6 : metrics.checkboxSize + 10);

    final check = SizedBox(
      width: size,
      height: size,
      child: Center(
        child: _buildMaterialCheckbox(
          context,
          value: value,
          tristate: tristate,
          onChanged: effectiveEnabled ? onChanged : null,
          rowOwnsDisabledOpacity: _rowOwnsDisabledOpacity,
          showUnavailableMark: showUnavailableMark,
          focusNode: focusNode,
          autofocus: effectiveEnabled && autofocus,
        ),
      ),
    );

    Widget? labelPart = labelWidget;
    if (labelPart == null && label != null) {
      labelPart = Text(
        label!,
        style: theme.typography
            .control(
              selected: value == true || (showUnavailableMark && value == null),
              dense: dense,
            )
            .copyWith(color: effectiveEnabled ? theme.text : theme.subtle),
      );
    }

    if (labelPart == null) return check;

    void handleTap() {
      if (!effectiveEnabled) return;
      if (tristate) {
        onChanged!(switch (value) {
          false => true,
          true => null,
          null => false,
        });
      } else {
        onChanged!(!(value ?? false));
      }
    }

    return MergeSemantics(
      child: MouseRegion(
        cursor: effectiveEnabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: effectiveEnabled ? handleTap : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              check,
              SizedBox(width: spacing),
              Flexible(child: labelPart),
            ],
          ),
        ),
      ),
    );
  }
}

/// Uses the surrounding row's opacity for a disabled indicator.
YumeiroCheckbox buildYumeiroRowCheckbox({
  required bool value,
  required ValueChanged<bool?>? onChanged,
  bool dense = false,
}) => YumeiroCheckbox._selection(
  value: value,
  onChanged: onChanged,
  dense: dense,
  rowOwnsDisabledOpacity: true,
);

/// Builds the checkbox used when a selection group owns its disabled marker.
YumeiroCheckbox buildYumeiroSelectionCheckbox({
  required bool? value,
  required ValueChanged<bool?>? onChanged,
  bool tristate = false,
  bool dense = false,
  String? label,
  double spacing = 8.0,
}) => YumeiroCheckbox._selection(
  value: value,
  onChanged: onChanged,
  dense: dense,
  tristate: tristate,
  label: label,
  spacing: spacing,
  rowOwnsDisabledOpacity: false,
);

Widget _buildMaterialCheckbox(
  BuildContext context, {
  required bool? value,
  required bool tristate,
  required ValueChanged<bool?>? onChanged,
  required bool rowOwnsDisabledOpacity,
  required bool showUnavailableMark,
  FocusNode? focusNode,
  bool autofocus = false,
}) {
  final theme = YumeiroTheme.of(context);
  final visuals = theme.checkboxVisuals;
  final pixel = visuals.shape is YumeiroPixelBorder;
  final metrics = YumeiroModalityScope.metricsOf(context);
  final keyboardFocus = YumeiroInputScope.keyboardFocusOf(context);

  Set<WidgetState> paintStates(Set<WidgetState> states) =>
      {...states}..removeWhere(
        (state) =>
            (rowOwnsDisabledOpacity &&
                onChanged == null &&
                const {
                  WidgetState.disabled,
                  WidgetState.hovered,
                  WidgetState.pressed,
                  WidgetState.focused,
                }.contains(state)) ||
            (state == WidgetState.focused && !keyboardFocus),
      );

  final baseTheme = visuals.materialTheme.copyWith(
    materialTapTargetSize: metrics.isTouch
        ? MaterialTapTargetSize.padded
        : MaterialTapTargetSize.shrinkWrap,
    visualDensity: metrics.isTouch ? VisualDensity.standard : null,
  );

  final effectiveTheme = rowOwnsDisabledOpacity
      ? baseTheme.copyWith(
          fillColor: WidgetStateProperty.resolveWith(
            (states) => visuals.fillColor.resolve(paintStates(states)),
          ),
          checkColor: WidgetStateProperty.resolveWith(
            (states) => visuals.checkColor.resolve(paintStates(states)),
          ),
          side: WidgetStateBorderSide.resolveWith(
            (states) => visuals.side.resolve(paintStates(states)),
          ),
        )
      : baseTheme;

  final markerColor = showUnavailableMark
      ? unavailableMarkInk(
          yumeiroAlphaBlend(
            visuals.fillColor.resolve({
                  WidgetState.disabled,
                  if (value != false) WidgetState.selected,
                }) ??
                Colors.transparent,
            theme.surface,
          ),
        )
      : null;

  return CustomPaint(
    foregroundPainter: markerColor == null
        ? null
        : UnavailableSlashPainter(
            color: markerColor,
            extent: Checkbox.width,
            pixel: pixel,
          ),
    child: CheckboxTheme(
      data: effectiveTheme,
      child: Checkbox(
        value: value,
        tristate: tristate,
        onChanged: onChanged,
        checkColor: showUnavailableMark ? Colors.transparent : null,
        focusNode: focusNode,
        autofocus: autofocus,
        side: WidgetStateBorderSide.resolveWith((states) {
          final outline = visuals.side.resolve(paintStates(states));
          return showUnavailableMark && pixel
              ? outline?.copyWith(color: theme.subtle)
              : outline;
        }),
      ),
    ),
  );
}
