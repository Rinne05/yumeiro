import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../../foundation/color_math.dart';
import '../../foundation/modality.dart';
import '../../primitives/pixel_border.dart';
import '../../primitives/selection_marks.dart';
import '../../primitives/visual_surface.dart';
import '../../theme/theme.dart';
import 'boolean_form_fields.dart';

/// Semantic binary switch rendered from [YumeiroThemeExtension.switchVisuals]
/// with unified touch/pointer hit target adaptation, RTL flip, and drag support.
class YumeiroSwitch extends StatefulWidget {
  const YumeiroSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
  });

  /// Creates an on/off switch field for a Flutter [Form].
  ///
  /// [required] marks the label. Use a validator to check the value and
  /// [onSaved] to read it when the form is saved. [onChanged] reports user
  /// edits after the field updates.
  static FormField<bool> form({
    Key? key,
    required String label,
    bool initialValue = false,
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
    ValueChanged<bool>? onChanged,
  }) => BooleanFormField<YumeiroSwitch>(
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
    onChanged: onChanged == null ? null : (value) => onChanged(value ?? false),
    buildControl: (value, onChanged, focusNode, autofocus) => YumeiroSwitch(
      value: value ?? false,
      onChanged: onChanged,
      focusNode: focusNode,
      autofocus: autofocus,
    ),
  );

  /// Current on/off value, controlled by the caller.
  final bool value;

  /// Requests a new on/off value. Null disables the switch and marks its
  /// thumb with a slash while retaining its current position.
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  State<YumeiroSwitch> createState() => _YumeiroSwitchState();
}

class _YumeiroSwitchState extends State<YumeiroSwitch> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focusHighlight = false;
  bool _focused = false;
  double? _dragPosition;

  bool get _enabled => widget.onChanged != null;
  double get _position => _dragPosition ?? (widget.value ? 1 : 0);

  @override
  void didUpdateWidget(covariant YumeiroSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_enabled || oldWidget.value != widget.value) {
      _dragPosition = null;
      _pressed = false;
    }
  }

  void _toggle() => widget.onChanged?.call(!widget.value);

  void _release() => setState(() {
    _pressed = false;
    _dragPosition = null;
  });

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final metrics = YumeiroModalityScope.metricsOf(context);
    final visuals = theme.switchVisuals;
    final rtl = Directionality.of(context) == TextDirection.rtl;

    final states = <WidgetState>{
      if (widget.value) WidgetState.selected,
      if (!_enabled) WidgetState.disabled,
      if (_hovered && _enabled) WidgetState.hovered,
      if (_pressed && _enabled) WidgetState.pressed,
      if (_focusHighlight && _enabled) WidgetState.focused,
    };

    final trackAppearance = visuals.track.resolve(states);
    final thumbAppearance = visuals.thumb.resolve(states);
    final markColor = !_enabled
        ? unavailableMarkInk(
            yumeiroAlphaBlend(
              thumbAppearance.background,
              yumeiroAlphaBlend(trackAppearance.background, theme.surface),
            ),
          )
        : null;
    final trackSize = visuals.trackSize;
    final thumbSize = visuals.thumbSize;
    final inset = (trackSize.height - thumbSize) / 2;
    final travel = trackSize.width - thumbSize - inset * 2;
    final duration =
        _dragPosition != null || MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : theme.motion.fast;

    final switchVisual = SizedBox.fromSize(
      size: trackSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: YumeiroResolvedVisualSurface(
              appearance: trackAppearance,
              child: const SizedBox.expand(),
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(end: _position),
            duration: duration,
            curve: Curves.easeOutCubic,
            builder: (context, position, child) => Positioned(
              left: inset + (rtl ? 1 - position : position) * travel,
              top: inset,
              width: thumbSize,
              height: thumbSize,
              child: child!,
            ),
            child: CustomPaint(
              foregroundPainter: markColor == null
                  ? null
                  : UnavailableSlashPainter(
                      color: markColor,
                      pixel: thumbAppearance.shape is YumeiroPixelBorder,
                    ),
              child: YumeiroResolvedVisualSurface(
                appearance: thumbAppearance,
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ],
      ),
    );

    final targetHeight = metrics.isTouch
        ? metrics.minTargetSize
        : trackSize.height;
    final targetWidth = metrics.isTouch
        ? math.max(trackSize.width, metrics.minTargetSize)
        : trackSize.width;

    return Semantics(
      label: widget.semanticLabel,
      toggled: widget.value,
      enabled: _enabled,
      focusable: _enabled,
      focused: _enabled && _focused,
      onTap: _enabled ? _toggle : null,
      excludeSemantics: true,
      child: FocusableActionDetector(
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        enabled: _enabled,
        mouseCursor: _enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onShowHoverHighlight: (value) => setState(() => _hovered = value),
        onShowFocusHighlight: (value) =>
            setState(() => _focusHighlight = value),
        onFocusChange: (value) => setState(() => _focused = value),
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _toggle();
              return null;
            },
          ),
        },
        child: Listener(
          onPointerCancel: (_) => _release(),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            dragStartBehavior: DragStartBehavior.down,
            onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
            onTapUp: _enabled ? (_) => _release() : null,
            onTapCancel: _enabled ? _release : null,
            onTap: _enabled ? _toggle : null,
            onHorizontalDragStart: _enabled
                ? (_) => setState(() {
                    _dragPosition = widget.value ? 1 : 0;
                    _pressed = true;
                  })
                : null,
            onHorizontalDragUpdate: _enabled
                ? (details) => setState(() {
                    _dragPosition =
                        (_position + details.delta.dx * (rtl ? -1 : 1) / travel)
                            .clamp(0.0, 1.0);
                  })
                : null,
            onHorizontalDragEnd: _enabled
                ? (details) {
                    if (_dragPosition == null) return;
                    final velocity =
                        details.velocity.pixelsPerSecond.dx * (rtl ? -1 : 1);
                    final next = velocity.abs() >= kMinFlingVelocity
                        ? velocity > 0
                        : _position >= .5;
                    _release();
                    if (next != widget.value) widget.onChanged?.call(next);
                  }
                : null,
            onHorizontalDragCancel: _enabled ? _release : null,
            child: SizedBox(
              height: math.max(trackSize.height, targetHeight),
              width: targetWidth,
              child: Center(child: switchVisual),
            ),
          ),
        ),
      ),
    );
  }
}
