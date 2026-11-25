import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals, setEquals;
import 'package:flutter/services.dart'
    show
        HardwareKeyboard,
        KeyDownEvent,
        KeyRepeatEvent,
        KeyEvent,
        LogicalKeyboardKey;
import 'package:material_ui/material_ui.dart';

import '../../foundation/modality.dart';
import '../../l10n/localizations.dart';
import '../../primitives/visual_scope.dart';
import '../../theme/theme.dart';
import '../../theme/visual_role.dart';
import '../overlays/dialogs.dart' show YumeiroSheetController;
import '../overlays/picker_overlay.dart';
import '../overlays/sheets.dart';
import 'buttons.dart';
import 'form_picker_trigger.dart';
import 'inputs.dart';
import 'multi_selection_draft.dart';
import 'selection_set_form_field.dart';
import 'select_trigger.dart' show yumeiroSelectTextWidth;
import 'selection_menu_row.dart';

part 'multi_select_pointer.dart';

/// Controlled multiple-choice picker backed by a set of values.
///
/// Use [value] and [onChanged] together to retain the user's selection. The
/// picker stages a draft until confirmation and returns an immutable set. Search
/// filters visible options while preserving hidden selections.
///
/// In pointer mode, the field contains the search and draft actions while the
/// anchored popup displays options. Touch mode uses a selection sheet. The
/// resting field lists selected labels on a single line.
class YumeiroMultiSelect<T extends Object> extends StatefulWidget {
  const YumeiroMultiSelect({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.label,
    this.helperText,
    this.semanticLabel,
    this.placeholder,
    this.title,
    this.width,
    this.expand = true,
    this.dense = false,
    this.enabled = true,
    this.readOnly = false,
    this.clearable = false,
    this.focusNode,
    this.autofocus = false,
    this.searchable = false,
    this.useRootNavigator = true,
  }) : _required = false,
       _errorText = null,
       _readValue = null;

  const YumeiroMultiSelect._field({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    required this.label,
    required this.helperText,
    required this.semanticLabel,
    required this.placeholder,
    required this.title,
    required this.width,
    required this.expand,
    required this.dense,
    required this.enabled,
    required this.readOnly,
    required this.clearable,
    required this.focusNode,
    required this.autofocus,
    required this.searchable,
    required this.useRootNavigator,
    required this._required,
    required this._errorText,
    required this._readValue,
  });

  /// Registers the picker with a Flutter [Form] for validation, saving, and
  /// resets. The reset value is [initialValue] filtered by the current options
  /// when [retainMissingValues] is false.
  ///
  /// When [retainMissingValues] is false, option updates silently prune the
  /// current selection. Search leaves the selection intact. Disabled options
  /// can remain selected.
  static FormField<Set<V>> form<V extends Object>({
    Key? key,
    required List<YumeiroSelectionOption<V>> options,
    Set<V>? initialValue,
    FormFieldSetter<Set<V>>? onSaved,
    VoidCallback? onReset,
    FormFieldValidator<Set<V>>? validator,
    AutovalidateMode? autovalidateMode,
    String? forceErrorText,
    bool enabled = true,
    ValueChanged<Set<V>>? onChanged,
    String? label,
    String? helperText,
    bool required = false,
    String? semanticLabel,
    String? placeholder,
    String? title,
    double? width,
    bool expand = true,
    bool dense = false,
    bool readOnly = false,
    bool clearable = false,
    bool retainMissingValues = true,
    FocusNode? focusNode,
    bool autofocus = false,
    bool searchable = false,
    bool useRootNavigator = true,
  }) => _MultiSelectFormField<V>(
    key: key,
    options: options,
    initialValue: initialValue,
    onSaved: onSaved,
    onReset: onReset,
    validator: validator,
    autovalidateMode: autovalidateMode,
    forceErrorText: forceErrorText,
    enabled: enabled,
    retainMissingValues: retainMissingValues,
    builder: (state) {
      final field = state as _MultiSelectFormFieldState<V>;
      return YumeiroMultiSelect<V>._field(
        key: field._controlKey,
        options: options,
        value: field.value!,
        onChanged: (value) {
          field.didChange(value);
          onChanged?.call(field.value!);
        },
        label: label,
        helperText: helperText,
        semanticLabel: semanticLabel,
        placeholder: placeholder,
        title: title,
        width: width,
        expand: expand,
        dense: dense,
        enabled: enabled,
        readOnly: readOnly,
        clearable: clearable,
        focusNode: focusNode,
        autofocus: autofocus,
        searchable: searchable,
        useRootNavigator: useRootNavigator,
        required: required,
        errorText: state.errorText,
        readValue: () => field.value!,
      );
    },
  );

  /// Options have distinct values. A disabled option can remain selected.
  final List<YumeiroSelectionOption<T>> options;

  /// Reports a new immutable selection after user interaction.
  /// Set to null to disable editing.
  final ValueChanged<Set<T>>? onChanged;

  final Set<T> value;
  final String? label;
  final String? helperText;
  final bool _required;
  final String? _errorText;
  final ValueGetter<Set<T>>? _readValue;
  final String? semanticLabel;
  final String? placeholder;
  final String? title;
  final double? width;

  /// Fills available width when no [width] is specified.
  final bool expand;
  final bool dense;
  final bool enabled;
  final bool readOnly;

  /// Shows a separate action that clears the entire selection.
  final bool clearable;

  final FocusNode? focusNode;
  final bool autofocus;
  final bool searchable;

  /// Set to false to open the picker on the nearest navigator.
  final bool useRootNavigator;

  @override
  State<YumeiroMultiSelect<T>> createState() => _YumeiroMultiSelectState<T>();
}

class _YumeiroMultiSelectState<T extends Object>
    extends State<YumeiroMultiSelect<T>> {
  final _sheetController = YumeiroSheetController();
  var _generation = 0;
  var _sheetOpen = false;

  bool get _enabled =>
      widget.enabled && (widget.readOnly || widget.onChanged != null);
  bool get _editable => _enabled && !widget.readOnly;
  bool get _canOpen => _editable && widget.options.isNotEmpty;
  Set<T> get _selection => widget._readValue?.call() ?? widget.value;

  void _invalidateDraft() {
    _generation++;
    _sheetController.close();
  }

  @override
  void didUpdateWidget(covariant YumeiroMultiSelect<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_canOpen || oldWidget.useRootNavigator != widget.useRootNavigator) {
      _invalidateDraft();
    } else if (_sheetOpen &&
        (!listEquals(oldWidget.options, widget.options) ||
            !setEquals(oldWidget.value, widget.value) ||
            oldWidget.title != widget.title ||
            oldWidget.label != widget.label ||
            oldWidget.searchable != widget.searchable)) {
      _sheetController.refresh();
    }
  }

  @override
  void dispose() {
    _invalidateDraft();
    super.dispose();
  }

  void _commit(Set<T> next) {
    if (!_editable || setEquals(next, _selection)) return;
    widget.onChanged?.call(Set<T>.unmodifiable(next));
  }

  Future<void> _openTouchPicker(BuildContext context) async {
    if (_sheetOpen || !_canOpen) return;
    final generation = _generation;
    final l10n = YumeiroLocalizations.of(context);

    _sheetOpen = true;
    try {
      final draft = await presentMultiSelectionSheet<T>(
        context: context,
        controller: _sheetController,
        useRootNavigator: widget.useRootNavigator,
        selection: () => (
          title: widget.title ?? widget.label ?? l10n.selectItem,
          options: widget.options,
          values: _selection,
          searchable: widget.searchable,
        ),
      );
      if (!mounted || generation != _generation || !_canOpen || draft == null) {
        return;
      }
      _commit(draft.resolve(_selection, widget.options));
    } finally {
      _sheetOpen = false;
    }
  }

  Widget _fieldLayout(
    Widget child, {
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.stretch,
  }) => YumeiroFieldLayout(
    label: widget.label,
    semanticLabel: widget.semanticLabel,
    helperText: widget.helperText,
    required: widget._required,
    errorText: widget._errorText,
    dense: widget.dense,
    crossAxisAlignment: crossAxisAlignment,
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    final field = widget;
    final l10n = YumeiroLocalizations.of(context);
    final pointer = YumeiroModalityScope.metricsOf(context).isPointer;
    final selected = field.value;
    final generation = _generation;
    final name =
        field.semanticLabel ?? field.label ?? field.title ?? l10n.selectItem;
    final clearButton =
        field.clearable && selected.isNotEmpty && _editable && !pointer
        ? yumeiroPickerClearButton(
            context,
            fieldLabel: name,
            dense: field.dense,
            onPressed: () => _commit(<T>{}),
          )
        : null;
    return _fieldLayout(
      pointer
          ? _PointerMultiSelect<T>(
              field: field,
              name: name,
              generation: generation,
              onCommit: (next) {
                if (generation == _generation) _commit(next);
              },
            )
          : YumeiroFormPickerTrigger(
              width: field.width,
              text: _multiSelectSummary(context, field, selected),
              isPlaceholder: selected.isEmpty,
              enabled: _enabled,
              readOnly: field.readOnly,
              hasError: field._errorText != null,
              dense: field.dense,
              expand: field.expand || field.width != null,
              focusNode: field.focusNode,
              autofocus: field.autofocus,
              onOpen: field.options.isEmpty ? null : _openTouchPicker,
              clearable: field.clearable && _editable,
              clearButton: clearButton,
            ),
      crossAxisAlignment: field.expand && field.width == null
          ? CrossAxisAlignment.stretch
          : CrossAxisAlignment.start,
    );
  }
}

String _multiSelectSummary<T extends Object>(
  BuildContext context,
  YumeiroMultiSelect<T> field,
  Set<T> values,
) {
  final l10n = YumeiroLocalizations.of(context);
  if (values.isEmpty) return field.placeholder ?? l10n.selectPlaceholder;

  final unnamed = Set<T>.of(values);
  final labels = [
    for (final option in field.options)
      if (option.label.isNotEmpty && unnamed.remove(option.value)) option.label,
  ];
  if (labels.isEmpty) return l10n.selectedCount(values.length);
  final chinese = Localizations.maybeLocaleOf(context)?.languageCode == 'zh';
  final names = labels.join(chinese ? '、' : ', ');
  return unnamed.isEmpty ? names : '$names +${unnamed.length}';
}

Widget _multiSelectSearchSurface(BuildContext context, Widget child) {
  final visualScope = YumeiroVisualScope.maybeOf(context);
  return YumeiroVisualScope(
    controlRole: visualScope?.controlRole ?? YumeiroControlRole.secondary,
    visualOverride: visualScope?.visualOverride,
    child: child,
  );
}

class _MultiSelectFormField<T extends Object> extends SelectionSetFormField<T> {
  _MultiSelectFormField({
    super.key,
    required super.options,
    super.initialValue,
    required super.retainMissingValues,
    super.onSaved,
    super.onReset,
    super.validator,
    super.autovalidateMode,
    super.forceErrorText,
    super.enabled,
    required super.builder,
  });

  @override
  FormFieldState<Set<T>> createState() => _MultiSelectFormFieldState<T>();
}

class _MultiSelectFormFieldState<T extends Object>
    extends SelectionSetFormFieldState<T> {
  final _controlKey = GlobalKey<_YumeiroMultiSelectState<T>>();

  @override
  void didChange(Set<T>? value) {
    _controlKey.currentState?._invalidateDraft();
    super.didChange(value);
  }

  @override
  void reset() {
    _controlKey.currentState?._invalidateDraft();
    super.reset();
  }
}
