import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../../foundation/modality.dart';
import '../../l10n/localizations.dart';
import '../../primitives/visual_scope.dart';
import '../../primitives/visual_surface.dart';
import '../../theme/semantic_visuals.dart';
import '../../theme/theme.dart';
import '../../theme/visual_role.dart';
import 'buttons.dart';
import 'form_picker_trigger.dart';
import 'text_editing_menu.dart';

part 'text_form_field.dart';

/// Semantic single-line or multi-line text input backed by [YumeiroSurfaceRole.inset].
///
/// Supports optional [obscureToggle] (show/hide eye button), [clearable]
/// (one-tap clear button), [suffixText] unit labels, [prefixIcon], and
/// localized accessibility labels.
class YumeiroTextField extends StatefulWidget {
  const YumeiroTextField({
    super.key,
    this.controller,
    this.initialValue,
    this.focusNode,
    this.hintText,
    this.semanticLabel,
    this.prefixIcon,
    this.leading,
    this.trailing,
    this.contentPadding,
    this.suffixText,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.obscureText = false,
    this.obscureToggle = false,
    this.clearable = false,
    this.width,
    this.height,
    this.maxLines = 1,
    this.minLines,
    this.dense = false,
    this.keyboardType,
    this.inputFormatters,
    this.textAlign = TextAlign.start,
    this.textInputAction,
    this.autofillHints = const <String>[],
    this.maxLength,
    this.maxLengthEnforcement,
    this.restorationId,
    this.hasError = false,
    this.style,
  });

  /// Registers a text input with the enclosing Flutter [Form].
  ///
  /// Use [validator] for synchronous validation and [forceErrorText] for an
  /// error resolved by the application. [required] marks the label. Pass a
  /// `GlobalKey<FormFieldState<String>>` as [key] to access the field state.
  ///
  /// Supply either [controller] or [initialValue]. The text at mount is
  /// restored on reset. Use a new [key] to start editing a different initial
  /// value. Writes to an external controller update the form value without
  /// reporting a user edit.
  ///
  /// [restorationId] restores validation and internally owned text. The
  /// application restores text managed by an external [controller].
  static FormField<String> form({
    Key? key,
    TextEditingController? controller,
    String? initialValue,
    String? label,
    String? semanticLabel,
    String? helperText,
    bool required = false,
    String? hintText,
    FocusNode? focusNode,
    bool enabled = true,
    bool readOnly = false,
    bool autofocus = false,
    bool clearable = false,
    bool dense = false,
    bool obscureText = false,
    bool obscureToggle = false,
    IconData? prefixIcon,
    String? suffixText,
    int? maxLines = 1,
    int? minLines,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    TextAlign textAlign = TextAlign.start,
    TextStyle? style,
    List<TextInputFormatter>? inputFormatters,
    Iterable<String>? autofillHints = const <String>[],
    int? maxLength,
    MaxLengthEnforcement? maxLengthEnforcement,
    String? restorationId,
    FormFieldValidator<String>? validator,
    FormFieldSetter<String>? onSaved,
    VoidCallback? onReset,
    AutovalidateMode autovalidateMode = AutovalidateMode.disabled,
    String? forceErrorText,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    VoidCallback? onEditingComplete,
  }) {
    assert(controller == null || initialValue == null);
    return _TextInputFormField(
      key: key,
      controller: controller,
      initialValue: controller?.text ?? initialValue ?? '',
      enabled: enabled,
      validator: validator,
      onSaved: onSaved,
      onReset: onReset,
      autovalidateMode: autovalidateMode,
      forceErrorText: forceErrorText,
      restorationId: restorationId,
      builder: (field) {
        final input = field as _TextInputFormFieldState;
        return UnmanagedRestorationScope(
          bucket: input.bucket,
          child: YumeiroFieldLayout(
            label: label,
            semanticLabel: semanticLabel,
            helperText: helperText,
            required: required,
            errorText: input.errorText,
            dense: dense,
            child: YumeiroTextField(
              controller: input._controller,
              focusNode: focusNode,
              hintText: hintText,
              hasError: input.hasError,
              prefixIcon: prefixIcon,
              suffixText: suffixText,
              enabled: enabled,
              readOnly: readOnly,
              autofocus: autofocus,
              clearable: clearable,
              dense: dense,
              obscureText: obscureText,
              obscureToggle: obscureToggle,
              maxLines: maxLines,
              minLines: minLines,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              textAlign: textAlign,
              style: style,
              inputFormatters: inputFormatters,
              autofillHints: autofillHints,
              maxLength: maxLength,
              maxLengthEnforcement: maxLengthEnforcement,
              restorationId: restorationId == null ? null : 'text',
              onChanged: (value) {
                input.didChange(value);
                onChanged?.call(value);
              },
              onSubmitted: onSubmitted,
              onEditingComplete: onEditingComplete,
            ),
          ),
        );
      },
    );
  }

  /// Creates a single-line field with a search prefix and a clear action.
  /// Clearing reports an empty string through [onChanged] before [onCleared].
  const factory YumeiroTextField.search({
    Key? key,
    TextEditingController? controller,
    FocusNode? focusNode,
    String? hintText,
    bool autofocus,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    VoidCallback? onCleared,
    bool dense,
  }) = _YumeiroSearchField;

  /// Caller-owned text and selection. Takes precedence over [initialValue].
  final TextEditingController? controller;

  /// Seeds the internal controller when it is created. Changing this value
  /// alone does not replace text the field already holds.
  final String? initialValue;

  /// Caller-owned focus node. The field creates its own node when omitted.
  final FocusNode? focusNode;
  final String? hintText;
  final String? semanticLabel;
  final IconData? prefixIcon;
  final Widget? leading;

  /// Accessory at the end of the field, after its built-in actions.
  final Widget? trailing;

  /// Overrides the padding inside the field surface.
  final EdgeInsetsGeometry? contentPadding;
  final String? suffixText;

  /// Reports user edits and reports an empty string after the clear action.
  /// Listen to [controller] for programmatic edits.
  final ValueChanged<String>? onChanged;

  /// Reports text when the keyboard submits the field.
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onEditingComplete;
  final bool enabled;

  /// Prevents editing and hides the clear action while leaving text available
  /// for selection.
  final bool readOnly;
  final bool autofocus;

  /// Initially conceals the text. Use a single-line field when enabled.
  final bool obscureText;

  /// Starts with concealed text and adds a visibility toggle. Use a single
  /// line even when the user can reveal the value.
  final bool obscureToggle;

  /// Shows a clear action when enabled, editable, and non-empty.
  final bool clearable;
  final double? width;
  final double? height;
  final int? maxLines;
  final int? minLines;
  final bool dense;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextAlign textAlign;
  final TextInputAction? textInputAction;

  /// Autofill hints passed to the platform. Null disables autofill.
  final Iterable<String>? autofillHints;

  /// Maximum number of user-perceived characters. The field has no counter.
  final int? maxLength;

  /// Overrides Flutter's platform-specific policy for enforcing [maxLength].
  final MaxLengthEnforcement? maxLengthEnforcement;

  /// Restores locally owned text under the nearest restoration scope.
  /// The caller restores the text when providing a [controller].
  final String? restorationId;

  /// Shows the theme's error outline while preserving the focus indicator.
  /// Use [YumeiroFieldLayout] to display an error message.
  final bool hasError;
  final TextStyle? style;

  @override
  State<YumeiroTextField> createState() => _YumeiroTextFieldState();
}

class _YumeiroTextFieldState extends State<YumeiroTextField>
    with RestorationMixin {
  RestorableTextEditingController? _ownedController;
  TextEditingController? _observedController;
  TextEditingValue? _searchDraft;
  FocusNode? _ownedFocusNode;
  bool _hovered = false;
  late bool _obscured;
  late bool _showClear;

  TextEditingController get _controller =>
      widget.controller ?? _ownedController!.value;

  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownedFocusNode ??= FocusNode());

  bool get _canClear =>
      widget.clearable &&
      widget.enabled &&
      !widget.readOnly &&
      _controller.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscureText || widget.obscureToggle;
    if (widget.controller == null) {
      _ownedController = RestorableTextEditingController(
        text: widget.initialValue,
      );
    } else {
      _observeController(_controller);
      _showClear = _canClear;
    }
    _focusNode.addListener(_onFocusChange);
  }

  @override
  String? get restorationId => widget.restorationId;

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    final ownedController = _ownedController;
    if (ownedController == null) return;
    _observeController(null);
    registerForRestoration(ownedController, 'controller');
    _observeController(ownedController.value);
    _showClear = _canClear;
  }

  void _observeController(TextEditingController? controller) {
    _observedController?.removeListener(_onTextChange);
    _observedController = controller;
    controller?.addListener(_onTextChange);
  }

  @override
  void didUpdateWidget(covariant YumeiroTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _observeController(null);
      if (_ownedController case final owned?) {
        if (widget is _YumeiroSearchField) _searchDraft = owned.value.value;
        unregisterFromRestoration(owned);
        owned.dispose();
        _ownedController = null;
      }
      if (widget.controller == null) {
        final draft = _searchDraft;
        final owned = draft == null
            ? RestorableTextEditingController(text: widget.initialValue)
            : RestorableTextEditingController.fromValue(draft);
        _ownedController = owned;
        registerForRestoration(owned, 'controller');
      }
      _observeController(_controller);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownedFocusNode)?.removeListener(_onFocusChange);
      if (widget.focusNode != null) {
        _ownedFocusNode?.dispose();
        _ownedFocusNode = null;
      }
      _focusNode.addListener(_onFocusChange);
    }
    if (oldWidget.obscureText != widget.obscureText ||
        oldWidget.obscureToggle != widget.obscureToggle) {
      _obscured = widget.obscureText || widget.obscureToggle;
    }
    _showClear = _canClear;
  }

  void _onFocusChange() {
    setState(() {});
  }

  void _onTextChange() {
    final showClear = _canClear;
    if (mounted && _showClear != showClear) {
      setState(() => _showClear = showClear);
    }
  }

  @override
  void dispose() {
    _observeController(null);
    (widget.focusNode ?? _ownedFocusNode)?.removeListener(_onFocusChange);
    _ownedController?.dispose();
    _ownedFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final metrics = YumeiroModalityScope.metricsOf(context);
    final l10n = YumeiroLocalizations.of(context);
    final search = switch (widget) {
      final _YumeiroSearchField field => field,
      _ => null,
    };
    final prefixIcon =
        widget.prefixIcon ?? (search == null ? null : theme.icons.search);
    final hintText =
        widget.hintText ?? (search == null ? null : l10n.searchHint);
    final isSingleLine = widget.maxLines == 1;
    final focused = _focusNode.hasFocus;

    final states = <WidgetState>{
      if (!widget.enabled) WidgetState.disabled,
      if (focused && widget.enabled) WidgetState.focused,
      if (_hovered && widget.enabled) WidgetState.hovered,
    };

    final visualScope = YumeiroVisualScope.maybeOf(context);
    final control = theme.visuals.control(
      visualScope?.controlRole ?? YumeiroControlRole.neutral,
      states,
      visualScope?.visualOverride,
    );
    final showError = widget.enabled && widget.hasError;
    final visual = control.apply(
      YumeiroVisualDelta(
        foreground: widget.style?.color,
        outline: showError
            ? BorderSide(
                color: theme.danger,
                width: control.outline.width.clamp(1.0, double.infinity),
              )
            : null,
      ),
    );
    final effectiveTextStyle = theme.typography
        .input(dense: widget.dense)
        .copyWith(color: visual.foreground)
        .merge(widget.style);
    final supportingColor = widget.style?.color ?? theme.subtle;
    final effectiveHintStyle = effectiveTextStyle.copyWith(
      color: widget.enabled ? supportingColor : visual.foreground,
    );

    var effectiveHeight = widget.height;
    if (effectiveHeight == null && isSingleLine) {
      effectiveHeight = yumeiroPickerMinHeight(
        context,
        metrics,
        widget.dense,
        style: effectiveTextStyle,
      );
    }

    final horizontalPadding = yumeiroPickerHorizontalPadding(
      metrics,
      widget.dense,
    );
    final iconSize = yumeiroPickerIconSize(theme, metrics, widget.dense);

    Widget surface = SizedBox(
      height: effectiveHeight,
      child: YumeiroResolvedVisualSurface(
        appearance: visual,
        visualInsets: isSingleLine && widget.height == null && metrics.isTouch
            ? (widget.dense
                  ? metrics.denseControlVisualInsets
                  : metrics.controlVisualInsets)
            : null,
        clipBehavior: Clip.antiAlias,
        padding:
            widget.contentPadding ??
            (isSingleLine
                ? EdgeInsets.symmetric(horizontal: horizontalPadding)
                : EdgeInsets.symmetric(
                    horizontal: metrics.isTouch
                        ? metrics.horizontalPadding
                        : 10.0,
                    vertical: metrics.isTouch ? metrics.horizontalPadding : 8.0,
                  )),
        child: Row(
          crossAxisAlignment: isSingleLine
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            if (prefixIcon != null) ...[
              Icon(
                prefixIcon,
                size: iconSize,
                color: !widget.enabled
                    ? visual.foreground
                    : focused
                    ? theme.accentSoft
                    : theme.muted,
              ),
              SizedBox(width: metrics.isTouch ? 10 : 8),
            ],
            if (widget.leading != null) ...[
              IconTheme.merge(
                data: IconThemeData(
                  color: !widget.enabled ? visual.foreground : theme.muted,
                  size: iconSize,
                ),
                child: widget.leading!,
              ),
              SizedBox(width: metrics.isTouch ? 10 : 8),
            ],
            Expanded(
              child: Semantics(
                label: widget.semanticLabel,
                child: UnmanagedRestorationScope(
                  bucket: bucket,
                  child: TextField(
                    controller: _controller,
                    contextMenuBuilder: buildYumeiroTextEditingMenu,
                    focusNode: _focusNode,
                    enabled: widget.enabled,
                    readOnly: widget.readOnly,
                    autofocus: widget.autofocus,
                    obscureText: _obscured,
                    maxLines: widget.maxLines,
                    minLines: widget.minLines,
                    keyboardType: widget.keyboardType,
                    inputFormatters: widget.inputFormatters,
                    textAlign: widget.textAlign,
                    textAlignVertical: isSingleLine
                        ? TextAlignVertical.center
                        : TextAlignVertical.top,
                    textInputAction: widget.textInputAction,
                    autofillHints: widget.autofillHints,
                    maxLength: widget.maxLength,
                    maxLengthEnforcement: widget.maxLengthEnforcement,
                    restorationId: widget.restorationId == null
                        ? null
                        : 'input',
                    onChanged: widget.onChanged,
                    onSubmitted: widget.onSubmitted,
                    onEditingComplete: widget.onEditingComplete,
                    style: effectiveTextStyle,
                    cursorColor: showError ? theme.danger : theme.accent,
                    cursorWidth: 1.5,
                    decoration: InputDecoration(
                      isCollapsed: true,
                      isDense: true,
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      hintText: hintText,
                      hintStyle: effectiveHintStyle,
                      counterText: widget.maxLength == null ? null : '',
                    ),
                  ),
                ),
              ),
            ),
            if (widget.suffixText != null && widget.suffixText!.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                widget.suffixText!,
                style: theme.typography.supporting.copyWith(
                  color: widget.enabled ? theme.subtle : visual.foreground,
                ),
              ),
            ],
            if (_showClear) ...[
              SizedBox(width: search == null ? 2 : theme.spacing.sm),
              _InlineAction(
                foreground: search == null ? visual.foreground : theme.muted,
                icon: theme.icons.close,
                tooltip: l10n.clear,
                dense: widget.dense,
                onPressed: () {
                  _controller.clear();
                  widget.onChanged?.call('');
                  search?.onCleared?.call();
                },
              ),
            ],
            if (widget.obscureToggle) ...[
              const SizedBox(width: 2),
              _InlineAction(
                foreground: visual.foreground,
                icon: _obscured
                    ? theme.icons.visibilityOn
                    : theme.icons.visibilityOff,
                tooltip: _obscured ? l10n.showPassword : l10n.hidePassword,
                dense: widget.dense,
                onPressed: widget.enabled
                    ? () => setState(() => _obscured = !_obscured)
                    : null,
              ),
            ],
            if (widget.trailing != null) ...[
              SizedBox(width: theme.spacing.sm),
              widget.trailing!,
            ],
          ],
        ),
      ),
    );

    surface = MouseRegion(
      cursor: widget.enabled
          ? SystemMouseCursors.text
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: surface,
    );

    if (widget.width != null) {
      surface = SizedBox(width: widget.width, child: surface);
    }

    return TextFieldTapRegion(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        excludeFromSemantics: true,
        onTap: widget.enabled ? _focusNode.requestFocus : null,
        child: surface,
      ),
    );
  }
}

class _InlineAction extends StatelessWidget {
  const _InlineAction({
    required this.foreground,
    required this.icon,
    required this.tooltip,
    required this.dense,
    required this.onPressed,
  });

  final Color foreground;
  final IconData icon;
  final String tooltip;
  final bool dense;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final metrics = YumeiroModalityScope.metricsOf(context);
    return YumeiroVisualScope(
      visualOverride: YumeiroVisualOverride(
        base: YumeiroVisualDelta(
          foreground: foreground,
          opacity: onPressed == null ? 1 : null,
        ),
      ),
      child: YumeiroButton(
        icon: icon,
        tooltip: tooltip,
        dense: !metrics.isTouch || dense,
        variant: YumeiroButtonVariant.ghost,
        onPressed: onPressed,
      ),
    );
  }
}

class _YumeiroSearchField extends YumeiroTextField {
  const _YumeiroSearchField({
    super.key,
    super.controller,
    super.focusNode,
    super.hintText,
    super.autofocus,
    super.onChanged,
    super.onSubmitted,
    this.onCleared,
    super.dense,
  }) : super(clearable: true, textInputAction: TextInputAction.search);

  final VoidCallback? onCleared;
}

/// Unified form field container providing consistent label typography,
/// required indicator, trailing accessory, helper text, and error display.
class YumeiroFieldLayout extends StatelessWidget {
  const YumeiroFieldLayout({
    super.key,
    this.label,
    this.semanticLabel,
    this.labelWidget,
    this.labelTrailing,
    this.required = false,
    this.helperText,
    this.errorText,
    this.dense = false,
    this.spacing,
    this.bottomSpacing,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    this.flexibleChild = false,
    required Widget this._child,
  }) : _readOnlyValue = null,
       _readOnlyMaxLines = null;

  /// Displays a labeled value that can be selected and copied.
  const YumeiroFieldLayout.readOnly({
    super.key,
    required String this.label,
    required String value,
    int? maxLines,
    this.bottomSpacing,
  }) : _readOnlyValue = value,
       _readOnlyMaxLines = maxLines,
       _child = null,
       semanticLabel = null,
       labelWidget = null,
       labelTrailing = null,
       required = false,
       helperText = null,
       errorText = null,
       dense = false,
       spacing = null,
       flexibleChild = false,
       crossAxisAlignment = CrossAxisAlignment.stretch;

  final String? label;

  /// Overrides the accessible name while leaving [label] visible.
  final String? semanticLabel;
  final Widget? labelWidget;
  final Widget? labelTrailing;

  /// Marks the field as required in its label. Validation belongs to the host.
  final bool required;
  final String? helperText;

  /// Host-provided validation message. Takes precedence over [helperText].
  final String? errorText;
  final bool dense;
  final double? spacing;
  final double? bottomSpacing;
  final CrossAxisAlignment crossAxisAlignment;

  /// Allows a scrollable field to use the space between its label and message.
  final bool flexibleChild;
  final Widget? _child;
  final String? _readOnlyValue;
  final int? _readOnlyMaxLines;

  Widget get child =>
      _child ??
      Builder(
        builder: (context) {
          final theme = YumeiroTheme.of(context);
          return SelectableText(
            _readOnlyValue!,
            maxLines: _readOnlyMaxLines,
            contextMenuBuilder: buildYumeiroTextEditingMenu,
            style: theme.typography.body.copyWith(color: theme.text),
          );
        },
      );

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final metrics = YumeiroModalityScope.metricsOf(context);
    final l10n = YumeiroLocalizations.of(context);
    final readOnly = _readOnlyValue != null;
    final effectiveSpacing =
        spacing ??
        (readOnly
            ? (metrics.isTouch ? theme.spacing.sm : theme.spacing.xs)
            : (metrics.isTouch ? 8.0 : (dense ? 3.0 : 4.0)));

    Widget? header;
    if (labelWidget != null || label != null || labelTrailing != null) {
      Widget? labelPart = labelWidget;
      if (labelPart == null && label != null) {
        labelPart = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: ExcludeSemantics(
                child: Text(
                  label!,
                  style: theme.typography.supporting.copyWith(
                    color: theme.muted,
                    fontWeight: theme.typography.controlWeight(),
                  ),
                ),
              ),
            ),
            if (required) ...[
              const SizedBox(width: 3),
              ExcludeSemantics(
                child: Text(
                  '*',
                  style: theme.typography.supporting.copyWith(
                    color: theme.danger,
                    fontWeight: theme.typography.emphasisWeight,
                  ),
                ),
              ),
            ],
          ],
        );
      }

      if (labelTrailing != null) {
        header = Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (labelPart != null)
              Expanded(child: labelPart)
            else
              const Spacer(),
            labelTrailing!,
          ],
        );
      } else if (labelPart != null) {
        header = labelPart;
      }
    }

    final hasError = errorText != null && errorText!.isNotEmpty;
    final hasHelper = helperText != null && helperText!.isNotEmpty;

    final field = Semantics(
      label: [
        if ((semanticLabel ?? label) case final name? when name.isNotEmpty)
          name,
        if (required) l10n.requiredField,
        if (hasError) l10n.errorMessage(errorText!),
      ].join(', '),
      child: child,
    );
    Widget content = Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (header != null) ...[header, SizedBox(height: effectiveSpacing)],
        if (flexibleChild) Flexible(child: field) else field,
        if (hasError) ...[
          const SizedBox(height: 4),
          Semantics(
            liveRegion: true,
            child: Text(
              errorText!,
              style: theme.typography.supporting.copyWith(color: theme.danger),
            ),
          ),
        ] else if (hasHelper) ...[
          const SizedBox(height: 4),
          Text(
            helperText!,
            style: theme.typography.supporting.copyWith(color: theme.subtle),
          ),
        ],
      ],
    );

    final effectiveBottomSpacing =
        bottomSpacing ??
        (readOnly ? theme.spacing.lg : (metrics.isTouch ? 20.0 : 12.0));
    if (effectiveBottomSpacing > 0) {
      content = Padding(
        padding: EdgeInsets.only(bottom: effectiveBottomSpacing),
        child: content,
      );
    }

    return content;
  }
}
