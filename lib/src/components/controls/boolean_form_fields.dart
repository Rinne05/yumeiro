import 'package:material_ui/material_ui.dart';

import '../../primitives/visual_surface.dart';
import '../../theme/visual_role.dart';
import 'inputs.dart';

/// Internal form adapter shared by the checkbox and switch controls.
/// The control type keeps their form state distinct when changing controls.
class BooleanFormField<Control extends Widget> extends FormField<bool> {
  BooleanFormField({
    super.key,
    required this.label,
    required bool? initialValue,
    required this.buildControl,
    this.isCheckbox = false,
    this.allowsNull = false,
    this.onChanged,
    super.onSaved,
    super.onReset,
    super.validator,
    super.autovalidateMode,
    super.forceErrorText,
    super.enabled,
    this.helperText,
    this.required = false,
    this.semanticLabel,
    this.readOnly = false,
    this.dense = false,
    this.focusNode,
    this.autofocus = false,
  }) : super(
         initialValue: allowsNull ? initialValue : initialValue ?? false,
         builder: (field) => (field as _BooleanFormFieldState)._buildField(),
       );

  final String label;
  final String? helperText;

  /// Marks the label. Use [validator] to enforce a required value.
  final bool required;
  final String? semanticLabel;

  /// Leaves the control focusable and visible while blocking edits.
  final bool readOnly;
  final bool dense;

  /// Optional focus node owned by the caller.
  final FocusNode? focusNode;
  final bool autofocus;

  final bool isCheckbox;
  final bool allowsNull;
  final ValueChanged<bool?>? onChanged;
  final Control Function(
    bool? value,
    ValueChanged<bool?>? onChanged,
    FocusNode? focusNode,
    bool autofocus,
  )
  buildControl;

  @override
  FormFieldState<bool> createState() => _BooleanFormFieldState();
}

class _BooleanFormFieldState extends FormFieldState<bool> {
  BooleanFormField<Widget> get _field => widget as BooleanFormField<Widget>;

  @override
  void didUpdateWidget(covariant BooleanFormField<Widget> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_field.allowsNull && value == null) setValue(false);
  }

  @override
  void didChange(bool? value) {
    super.didChange(_field.allowsNull ? value : value ?? false);
  }

  void _changeFromUser(bool? value) {
    if (!_field.enabled || _field.readOnly) return;
    didChange(value);
    _field.onChanged?.call(this.value);
  }

  Widget _buildField() {
    final field = _field;
    final readOnly = field.enabled && field.readOnly;
    final control = field.buildControl(
      value,
      field.enabled ? _changeFromUser : null,
      readOnly ? null : field.focusNode,
      field.enabled && !readOnly && field.autofocus,
    );
    return YumeiroFieldLayout(
      label: field.label,
      semanticLabel: field.semanticLabel,
      helperText: field.helperText,
      required: field.required,
      errorText: errorText,
      dense: field.dense,
      crossAxisAlignment: CrossAxisAlignment.start,
      child: readOnly ? _readOnlyControl(field, control) : control,
    );
  }

  Widget _readOnlyControl(BooleanFormField<Widget> field, Widget control) =>
      Focus(
        focusNode: field.focusNode,
        autofocus: field.autofocus,
        includeSemantics: false,
        descendantsAreFocusable: false,
        child: Builder(
          builder: (context) {
            final focused = Focus.of(context).hasFocus;
            final checkbox = field.isCheckbox;
            return Semantics(
              enabled: true,
              readOnly: true,
              focusable: true,
              focused: focused,
              checked: checkbox ? value ?? false : null,
              mixed: checkbox && field.allowsNull && value == null
                  ? true
                  : null,
              toggled: checkbox ? null : value,
              child: YumeiroVisualSurface(
                role: YumeiroItemRole.standard,
                states: {if (focused) WidgetState.focused},
                child: ExcludeSemantics(child: IgnorePointer(child: control)),
              ),
            );
          },
        ),
      );
}
