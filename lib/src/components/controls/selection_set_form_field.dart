import 'package:flutter/foundation.dart' show setEquals;
import 'package:material_ui/material_ui.dart';

import 'selection_option.dart';

/// Set-valued form field shared by inline and confirmation-based selection.
class SelectionSetFormField<T extends Object> extends FormField<Set<T>> {
  SelectionSetFormField({
    super.key,
    required this.options,
    Set<T>? initialValue,
    required this.retainMissingValues,
    super.onSaved,
    super.onReset,
    super.validator,
    super.autovalidateMode,
    super.forceErrorText,
    super.enabled,
    required super.builder,
  }) : super(
         initialValue: _selectionValues(
           initialValue,
           options,
           retainMissingValues,
         ),
       );

  final List<YumeiroSelectionOption<T>> options;
  final bool retainMissingValues;

  @override
  FormFieldState<Set<T>> createState() => SelectionSetFormFieldState<T>();
}

class SelectionSetFormFieldState<T extends Object>
    extends FormFieldState<Set<T>> {
  SelectionSetFormField<T> get _field => widget as SelectionSetFormField<T>;

  @override
  void didChange(Set<T>? value) {
    super.didChange(
      _selectionValues(value, _field.options, _field.retainMissingValues),
    );
  }

  @override
  void didUpdateWidget(covariant SelectionSetFormField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_field.retainMissingValues) {
      final current = value!;
      final next = _selectionValues(current, _field.options, false);
      if (!setEquals(next, current)) setValue(next);
    }
  }
}

Set<T> _selectionValues<T extends Object>(
  Set<T>? values,
  List<YumeiroSelectionOption<T>> options,
  bool retainMissingValues,
) {
  if (retainMissingValues || values == null || values.isEmpty) {
    return Set<T>.unmodifiable(values ?? <T>{});
  }
  final available = {for (final option in options) option.value};
  return Set<T>.unmodifiable(values.where(available.contains));
}
