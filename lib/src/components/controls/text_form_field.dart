part of 'inputs.dart';

class _TextInputFormField extends FormField<String> {
  const _TextInputFormField({
    super.key,
    required this.controller,
    required String super.initialValue,
    required super.enabled,
    super.validator,
    super.onSaved,
    super.onReset,
    super.autovalidateMode,
    super.forceErrorText,
    super.restorationId,
    required super.builder,
  });

  final TextEditingController? controller;

  @override
  FormFieldState<String> createState() => _TextInputFormFieldState();
}

class _TextInputFormFieldState extends FormFieldState<String> {
  late final String _resetText;
  RestorableTextEditingController? _ownedController;
  bool _writingController = false;

  @override
  _TextInputFormField get widget => super.widget as _TextInputFormField;

  TextEditingController get _controller =>
      widget.controller ?? _ownedController!.value;

  @override
  void initState() {
    super.initState();
    _resetText = widget.controller?.text ?? widget.initialValue!;
    setValue(_resetText);
    if (widget.controller case final external?) {
      external.addListener(_onControllerChanged);
    } else {
      _ownedController = RestorableTextEditingController(text: _resetText);
    }
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    super.restoreState(oldBucket, initialRestore);
    if (_ownedController case final owned?) {
      registerForRestoration(owned, 'controller');
    }
    setValue(_controller.text);
  }

  @override
  void didUpdateWidget(covariant _TextInputFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previous = oldWidget.controller;
    final current = widget.controller;
    if (identical(previous, current)) return;

    previous?.removeListener(_onControllerChanged);
    if (current != null) {
      if (_ownedController case final owned?) {
        unregisterFromRestoration(owned);
        owned.dispose();
        _ownedController = null;
      }
      current.addListener(_onControllerChanged);
    } else {
      final owned = RestorableTextEditingController.fromValue(previous!.value);
      _ownedController = owned;
      registerForRestoration(owned, 'controller');
    }
    setValue(_controller.text);
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onControllerChanged);
    _ownedController?.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    final text = _controller.text;
    if (!_writingController && value != text) {
      setState(() => setValue(text));
    }
  }

  void _writeController(String text) {
    _writingController = true;
    try {
      _controller.value = TextEditingValue(text: text);
    } finally {
      _writingController = false;
    }
  }

  @override
  void didChange(String? value) {
    final text = value ?? '';
    if (_controller.text != text) _writeController(text);
    super.didChange(text);
  }

  @override
  void reset() {
    // Rebuilding with a controller captures its current text in the widget.
    // Restore the value read when this field mounted.
    _writeController(_resetText);
    setValue(_resetText);
    clearError();
    widget.onReset?.call();
  }
}
