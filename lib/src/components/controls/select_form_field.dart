part of 'select.dart';

class _YumeiroSelectFormField<T extends Object> extends FormField<T> {
  _YumeiroSelectFormField({
    super.key,
    required this.options,
    super.initialValue,
    super.onSaved,
    super.onReset,
    super.validator,
    super.autovalidateMode,
    super.forceErrorText,
    super.enabled,
    this.onChanged,
    this.label,
    this.helperText,
    this.required = false,
    this.semanticLabel,
    this.placeholder,
    this.title,
    this.width,
    this.menuWidth,
    this.menuAutoWidth = false,
    this.maxWidth = 320,
    this.expand = true,
    this.dense = false,
    this.readOnly = false,
    this.clearable = false,
    this.searchable = false,
    this.focusNode,
    this.autofocus = false,
    this.useRootNavigator = true,
  }) : super(
         builder: (field) =>
             (field as _YumeiroSelectFormFieldState<T>)._buildField(),
       );

  final List<YumeiroSelectionOption<T>> options;

  /// Reports a user selection after the form field has updated. Clearing sends
  /// null. Use [onReset] to observe a reset.
  final ValueChanged<T?>? onChanged;

  final String? label;
  final String? helperText;
  final bool required;
  final String? semanticLabel;
  final String? placeholder;
  final String? title;
  final double? width;
  final double? menuWidth;
  final bool menuAutoWidth;
  final double maxWidth;
  final bool expand;
  final bool dense;

  /// Displays the selected value and allows focus without opening the picker.
  final bool readOnly;

  /// Shows a clear action for an enabled and editable selected value.
  final bool clearable;
  final bool searchable;

  /// Optional focus node owned by the caller.
  final FocusNode? focusNode;
  final bool autofocus;

  /// Set to false to open the picker on the nearest navigator in either mode.
  final bool useRootNavigator;

  @override
  FormFieldState<T> createState() => _YumeiroSelectFormFieldState<T>();
}

class _YumeiroSelectFormFieldState<T extends Object> extends FormFieldState<T> {
  final _selectKey = GlobalKey<_YumeiroSelectState<T>>();
  final _searchKey = GlobalKey<_SearchableSelectState<T>>();

  _YumeiroSelectFormField<T> get _field => widget as _YumeiroSelectFormField<T>;
  bool get _editable => _field.enabled && !_field.readOnly;

  @override
  void didChange(T? value) {
    _invalidatePicker();
    super.didChange(value);
  }

  @override
  void reset() {
    _invalidatePicker();
    super.reset();
  }

  void _invalidatePicker() {
    _selectKey.currentState?._invalidatePicker();
    _searchKey.currentState?._formValueDidChange();
  }

  void _changeFromUser(T? value) {
    if (!_editable) return;
    didChange(value);
    _field.onChanged?.call(value);
  }

  Widget _buildField() {
    final field = _field;
    final l10n = YumeiroLocalizations.of(context);
    final name =
        field.semanticLabel ?? field.label ?? field.title ?? l10n.selectItem;
    return YumeiroFieldLayout(
      label: field.label,
      semanticLabel: field.semanticLabel,
      helperText: field.helperText,
      required: field.required,
      errorText: errorText,
      dense: field.dense,
      crossAxisAlignment: field.expand && field.width == null
          ? CrossAxisAlignment.stretch
          : CrossAxisAlignment.start,
      child: _SelectClearAction(
        enabled: field.clearable && _editable,
        button: field.clearable && value != null && _editable
            ? yumeiroPickerClearButton(
                context,
                fieldLabel: name,
                dense: field.dense,
                onPressed: () => _changeFromUser(null),
              )
            : null,
        child: field.searchable
            ? YumeiroSelect<T>.searchable(
                key: _searchKey,
                options: field.options,
                value: value,
                onChanged: _changeFromUser,
                clearable: field.clearable,
                placeholder: field.placeholder,
                title: field.title ?? field.label,
                width: field.width,
                menuWidth: field.menuWidth,
                menuAutoWidth: field.menuAutoWidth,
                maxWidth: field.maxWidth,
                expand: field.expand || field.width != null,
                dense: field.dense,
                enabled: field.enabled,
                readOnly: field.readOnly,
                focusNode: field.focusNode,
                autofocus: field.autofocus,
                hasError: hasError,
                semanticLabel: name,
                useRootNavigator: field.useRootNavigator,
              )
            : YumeiroSelect<T>(
                key: _selectKey,
                options: field.options,
                value: value,
                onChanged: _changeFromUser,
                placeholder: field.placeholder,
                title: field.title ?? field.label,
                width: field.width,
                menuWidth: field.menuWidth,
                menuAutoWidth: field.menuAutoWidth,
                maxWidth: field.maxWidth,
                expand: field.expand || field.width != null,
                dense: field.dense,
                enabled: field.enabled,
                readOnly: field.readOnly,
                focusNode: field.focusNode,
                autofocus: field.autofocus,
                hasError: hasError,
                useRootNavigator: field.useRootNavigator,
              ),
      ),
    );
  }
}

class _SelectClearAction extends InheritedWidget {
  const _SelectClearAction({
    required this.enabled,
    required this.button,
    required super.child,
  });

  final bool enabled;
  final Widget? button;

  static _SelectClearAction? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SelectClearAction>();

  @override
  bool updateShouldNotify(_SelectClearAction oldWidget) =>
      enabled != oldWidget.enabled || button != oldWidget.button;
}
