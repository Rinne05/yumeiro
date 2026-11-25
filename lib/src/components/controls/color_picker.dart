import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter/services.dart' show KeyDownEvent, LogicalKeyboardKey;

import '../../foundation/modality.dart';
import '../../l10n/localizations.dart';
import '../../primitives/glass_backdrop.dart';
import '../../primitives/visual_surface.dart';
import '../../theme/semantic_visuals.dart';
import '../../theme/theme.dart';
import '../../theme/visual_role.dart';
import '../layout/scroll_view.dart';
import '../overlays/dialogs.dart';
import '../overlays/picker_overlay.dart';
import '../overlays/sheets.dart';
import '../overlays/tooltip.dart';
import 'buttons.dart';
import 'inputs.dart';

/// Named preset swatch selectable inside [YumeiroColorPickerButton].
@immutable
class YumeiroColorPickerPreset {
  const YumeiroColorPickerPreset({
    required this.label,
    required this.color,
    this.accentColor,
  });

  final String label;
  final Color color;
  final Color? accentColor;
}

/// Compact color swatch trigger opening an anchored HSV picker panel on pointer
/// or a modal bottom sheet editor on touch.
class YumeiroColorPickerButton extends StatefulWidget {
  const YumeiroColorPickerButton({
    super.key,
    required this.value,
    required this.defaultColor,
    required this.onChanged,
    this.presets = const [],
    this.defaultLabel,
    this.showDefaultSwatch = true,
    this.tooltip,
    this.enabled = true,
  });

  /// Current override. Null keeps the color inherited from [defaultColor].
  final Color? value;

  /// Inherited color shown and used as the starting point with no override.
  final Color defaultColor;

  /// Reports a changed color when a swatch, drag, or hex edit is committed.
  /// Restoring the default reports null. The caller owns the saved override.
  final ValueChanged<Color?> onChanged;
  final List<YumeiroColorPickerPreset> presets;
  final String? defaultLabel;

  /// Shows the automatic icon alone when the inherited style has no one color.
  /// [defaultColor] still seeds the editor.
  final bool showDefaultSwatch;

  final String? tooltip;
  final bool enabled;

  @override
  State<YumeiroColorPickerButton> createState() =>
      _YumeiroColorPickerButtonState();
}

class _YumeiroColorPickerButtonState extends State<YumeiroColorPickerButton> {
  final _overlayController = OverlayPortalController();
  final _tapRegionGroup = Object();
  final _sheetController = YumeiroSheetController();
  final _draftRevision = ValueNotifier<int>(0);
  late final TextEditingController _hexController;
  final _triggerFocus = FocusNode();

  Color? _draftValue;
  Color? _lastEmittedValue;
  bool _isOpen = false;
  bool _hasHexEdit = false;
  double _hue = 0;

  @override
  void initState() {
    super.initState();
    _draftValue = widget.value;
    _lastEmittedValue = widget.value;
    _noteHue(_draftColor);
    _hexController = TextEditingController(
      text: _hexFor(widget.value ?? widget.defaultColor),
    );
  }

  void _noteHue(Color color) {
    final hsv = HSVColor.fromColor(color);
    if (hsv.saturation > 0 && hsv.value > 0) _hue = hsv.hue;
  }

  @override
  void didUpdateWidget(covariant YumeiroColorPickerButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && _isOpen) _hidePicker();
    if (!_sameColor(oldWidget.value, widget.value)) {
      final external = !_sameColor(widget.value, _lastEmittedValue);
      _lastEmittedValue = widget.value;
      if (!_isOpen || external) {
        _draftValue = widget.value;
        _syncExternalDraft();
      }
    } else if (oldWidget.defaultColor != widget.defaultColor &&
        widget.value == null &&
        _draftValue == null) {
      _syncExternalDraft();
    }
  }

  void _syncExternalDraft() {
    _noteHue(_draftColor);
    _hasHexEdit = false;
    if (!_isOpen) return;
    // The editor can be in a separate route from this widget. Notify the
    // field and the spectrum together once the host has finished building.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_isOpen) return;
      _syncHexText();
      _draftRevision.value++;
    });
  }

  @override
  void dispose() {
    _sheetController.close();
    _draftRevision.dispose();
    _triggerFocus.dispose();
    _hexController.dispose();
    super.dispose();
  }

  Color get _draftColor => _draftValue ?? widget.defaultColor;

  void _togglePicker() {
    if (!widget.enabled) return;
    if (_isOpen) {
      _hidePicker();
      return;
    }
    _draftValue = widget.value;
    _lastEmittedValue = widget.value;
    _noteHue(_draftColor);
    _syncHexText();
    if (YumeiroModalityScope.metricsOf(context).isTouch) {
      _showTouchPicker();
      return;
    }
    _overlayController.show();
    setState(() => _isOpen = true);
  }

  void _hidePicker({bool restoreFocus = true}) {
    if (!_isOpen) return;
    if (widget.enabled) _commitHexInput();
    _sheetController.close();
    _overlayController.hide();
    if (mounted) setState(() => _isOpen = false);
    if (restoreFocus) _restoreTriggerFocus();
  }

  void _restoreTriggerFocus() {
    if (!widget.enabled) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _triggerFocus.requestFocus();
    });
  }

  void _emitDraft() {
    final value = _draftValue;
    if (_sameColor(value, _lastEmittedValue)) return;
    _lastEmittedValue = value;
    widget.onChanged(value);
  }

  void _setDraftColor(Color color, {bool commit = false}) {
    _noteHue(color);
    if (!_sameColor(_draftValue, color)) {
      setState(() => _draftValue = color);
      _draftRevision.value++;
    }
    _syncHexText();
    if (commit) _emitDraft();
  }

  void _setDefaultColor() {
    _noteHue(widget.defaultColor);
    setState(() => _draftValue = null);
    _draftRevision.value++;
    _syncHexText();
    _emitDraft();
  }

  void _handleHexChanged(String text) {
    _hasHexEdit = true;
    final parsed = _parseHex(text);
    if (parsed == null) return;
    // An edit that returns to the inherited color keeps that default selected.
    final next =
        widget.showDefaultSwatch &&
            _lastEmittedValue == null &&
            _sameColor(parsed, widget.defaultColor)
        ? null
        : parsed;
    _noteHue(parsed);
    if (_sameColor(_draftValue, next)) return;
    setState(() => _draftValue = next);
    _draftRevision.value++;
  }

  void _commitHexInput() {
    if (!_hasHexEdit) return;
    final parsed = _parseHex(_hexController.text);
    if (parsed == null) {
      _syncHexText();
      return;
    }
    if (_draftValue == null && _sameColor(parsed, _draftColor)) {
      _syncHexText();
      return;
    }
    _setDraftColor(parsed, commit: true);
  }

  void _syncHexText() {
    _hasHexEdit = false;
    final text = _hexFor(_draftColor);
    if (_hexController.text == text) return;
    _hexController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _updateFromSaturationValue(Offset position, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final saturation = (position.dx / size.width).clamp(0.0, 1.0);
    final value = (1 - position.dy / size.height).clamp(0.0, 1.0);
    _setDraftColor(
      HSVColor.fromAHSV(_draftColor.a, _hue, saturation, value).toColor(),
    );
  }

  void _updateFromHue(Offset position, Size size) {
    if (size.width <= 0) return;
    final hue = (position.dx / size.width * 360).clamp(0.0, 360.0);
    final current = HSVColor.fromColor(_draftColor);
    _hue = hue;
    final next = current.withHue(hue).toColor();
    if (_sameColor(_draftColor, next)) {
      setState(() {});
      _draftRevision.value++;
    } else {
      _setDraftColor(next);
    }
  }

  String _triggerLabel(YumeiroLocalizations l10n) {
    final color = widget.value;
    if (color == null) return widget.defaultLabel ?? l10n.defaultOption;
    for (final preset in widget.presets) {
      if (_sameColor(color, preset.color)) return preset.label;
    }
    return _hexFor(color);
  }

  Widget _buildTrigger(BuildContext context) {
    final l10n = YumeiroLocalizations.of(context);
    final currentColor =
        widget.value ?? (widget.showDefaultSwatch ? widget.defaultColor : null);
    return YumeiroButton(
      label: _triggerLabel(l10n),
      customLeading: _ColorPreview(
        color: currentColor,
        isDefault: widget.value == null,
      ),
      tooltip: widget.tooltip ?? l10n.colorPickerTitle,
      focusNode: _triggerFocus,
      onPressed: widget.enabled ? _togglePicker : null,
    );
  }

  List<Widget> _buildSpectrum({required bool touch}) {
    final hsv = HSVColor.fromColor(_draftColor);
    final hueField = _HueField(
      key: const ValueKey('yumeiro-color-hue'),
      hue: _hue,
      onChanged: _updateFromHue,
      onInteractionEnd: _emitDraft,
    );
    return [
      _SaturationValueField(
        key: const ValueKey('yumeiro-color-saturation-value'),
        hue: _hue,
        saturation: hsv.saturation,
        value: hsv.value,
        onChanged: _updateFromSaturationValue,
        onInteractionEnd: _emitDraft,
      ),
      SizedBox(height: touch ? 16 : 10),
      if (touch)
        SizedBox(height: 48, child: Center(child: hueField))
      else
        hueField,
    ];
  }

  Widget _buildHexInput(YumeiroLocalizations l10n, {bool dense = false}) =>
      YumeiroTextField(
        key: const ValueKey('yumeiro-color-hex-input'),
        controller: _hexController,
        dense: dense,
        semanticLabel: dense ? l10n.hexColor : null,
        hintText: '#RRGGBB',
        textInputAction: TextInputAction.done,
        onChanged: _handleHexChanged,
        onEditingComplete: _commitHexInput,
      );

  Widget _buildPresets(YumeiroLocalizations l10n) => _ColorOptions(
    defaultLabel: widget.defaultLabel ?? l10n.defaultOption,
    defaultColor: widget.showDefaultSwatch ? widget.defaultColor : null,
    value: _draftValue,
    presets: widget.presets,
    onDefault: _setDefaultColor,
    onPreset: (color) => _setDraftColor(color, commit: true),
  );

  Future<void> _showTouchPicker() async {
    final l10n = YumeiroLocalizations.of(context);
    setState(() => _isOpen = true);
    try {
      await YumeiroBottomSheet.show<void>(
        context: context,
        controller: _sheetController,
        builder: (sheetContext) => YumeiroBottomSheet(
          title: widget.tooltip ?? l10n.colorPickerTitle,
          actions: [YumeiroButton(label: l10n.done, onPressed: _hidePicker)],
          child: ValueListenableBuilder<int>(
            valueListenable: _draftRevision,
            builder: (context, _, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ..._buildSpectrum(touch: true),
                  const SizedBox(height: 16),
                  YumeiroFieldLayout(
                    label: l10n.hexColor,
                    child: _buildHexInput(l10n),
                  ),
                  _buildPresets(l10n),
                ],
              );
            },
          ),
        ),
      );
      if (mounted && widget.enabled) _commitHexInput();
    } finally {
      if (mounted) {
        setState(() => _isOpen = false);
        _restoreTriggerFocus();
      }
    }
  }

  Widget _buildOverlay(BuildContext context, OverlayChildLayoutInfo info) {
    final theme = YumeiroTheme.of(context);
    final l10n = YumeiroLocalizations.of(context);
    final media = MediaQuery.of(context);
    return Positioned.fill(
      child: PickerOverlayLayout(
        anchor: MatrixUtils.transformRect(
          info.childPaintTransform,
          Offset.zero & info.childSize,
        ),
        width: 304,
        maxHeight: double.infinity,
        padding: EdgeInsets.fromLTRB(
          math.max(media.viewPadding.left, media.viewInsets.left),
          math.max(media.viewPadding.top, media.viewInsets.top),
          math.max(media.viewPadding.right, media.viewInsets.right),
          math.max(media.viewPadding.bottom, media.viewInsets.bottom),
        ),
        child: TapRegion(
          groupId: _tapRegionGroup,
          onTapOutside: (_) => _hidePicker(restoreFocus: false),
          child: Focus(
            autofocus: true,
            onKeyEvent: (_, event) {
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.escape) {
                _hidePicker();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: Material(
              type: MaterialType.transparency,
              child: YumeiroGlassSamplingScope(
                child: YumeiroVisualSurface(
                  role: YumeiroSurfaceRole.floating,
                  padding: const EdgeInsets.all(14),
                  child: SingleChildScrollView(
                    primary: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.tooltip ?? l10n.colorPickerTitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.typography.title,
                              ),
                            ),
                            YumeiroButton(
                              variant: YumeiroButtonVariant.ghost,
                              icon: theme.icons.close,
                              tooltip: l10n.close,
                              iconSize: 14,
                              onPressed: _hidePicker,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ..._buildSpectrum(touch: false),
                        const SizedBox(height: 12),
                        LayoutBuilder(
                          builder: (context, constraints) => Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: constraints.maxWidth,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _ColorPreview(
                                      color:
                                          widget.showDefaultSwatch ||
                                              _draftValue != null
                                          ? _draftColor
                                          : null,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        !widget.showDefaultSwatch &&
                                                _draftValue == null
                                            ? (widget.defaultLabel ??
                                                  l10n.defaultOption)
                                            : _hexFor(_draftColor),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.typography.mono(
                                          fontSize:
                                              theme.typography.caption.fontSize,
                                          color: theme.muted,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: math.min(150, constraints.maxWidth),
                                child: Row(
                                  children: [
                                    Text(
                                      'HEX',
                                      style: theme.typography.caption,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: _buildHexInput(l10n, dense: true),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildPresets(l10n),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TapRegion(
      groupId: _tapRegionGroup,
      child: OverlayPortal.overlayChildLayoutBuilder(
        controller: _overlayController,
        overlayChildBuilder: _buildOverlay,
        child: _buildTrigger(context),
      ),
    );
  }
}

class _ColorOptions extends StatelessWidget {
  const _ColorOptions({
    required this.defaultLabel,
    required this.defaultColor,
    required this.value,
    required this.presets,
    required this.onDefault,
    required this.onPreset,
  });

  final String defaultLabel;
  final Color? defaultColor;
  final Color? value;
  final List<YumeiroColorPickerPreset> presets;
  final VoidCallback onDefault;
  final ValueChanged<Color> onPreset;

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final l10n = YumeiroLocalizations.of(context);
    final isTouch = YumeiroModalityScope.metricsOf(context).isTouch;
    final size = isTouch ? 48.0 : 24.0;
    return YumeiroScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          _ColorPresetChip(
            label: defaultLabel,
            color: defaultColor,
            selected: value == null,
            isDefault: true,
            onTap: onDefault,
          ),
          for (final preset in presets)
            _ColorPresetChip(
              label: preset.label,
              color: preset.color,
              accentColor: preset.accentColor,
              selected: value?.toARGB32() == preset.color.toARGB32(),
              onTap: () => onPreset(preset.color),
            ),
          YumeiroButton(
            icon: theme.icons.refresh,
            tooltip: l10n.resetToDefault,
            width: size,
            height: size,
            iconSize: isTouch ? 24 : 14,
            onPressed: onDefault,
          ),
        ],
      ),
    );
  }
}

class _ColorPreview extends StatelessWidget {
  const _ColorPreview({
    required this.color,
    this.isDefault = false,
    this.size = 18,
    this.outlineColor,
  });

  final Color? color;
  final bool isDefault;
  final double size;
  final Color? outlineColor;

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final swatch = color;
    if (swatch == null) {
      return SizedBox.square(
        dimension: size,
        child: Icon(theme.icons.auto, size: 14, color: theme.muted),
      );
    }
    return YumeiroVisualSurface(
      role: YumeiroSurfaceRole.compact,
      visualOverride: YumeiroVisualOverride(
        base: YumeiroVisualDelta(
          fill: YumeiroSolidFill(swatch),
          foreground: !isDefault
              ? null
              : swatch == theme.accent
              ? theme.onAccent
              : theme.colors
                    .withAccent(
                      swatch,
                      lighten: Theme.of(context).brightness == Brightness.light,
                    )
                    .onAccent,
          outline: outlineColor == null
              ? null
              : theme.visuals
                    .surface(YumeiroSurfaceRole.compact)
                    .outline
                    .copyWith(color: outlineColor),
        ),
      ),
      child: SizedBox.square(
        dimension: size,
        child: isDefault ? Icon(theme.icons.auto, size: 10) : null,
      ),
    );
  }
}

class _ColorPresetChip extends StatelessWidget {
  const _ColorPresetChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
    this.accentColor,
    this.isDefault = false,
  });

  final String label;
  final Color? color;
  final Color? accentColor;
  final bool selected;
  final bool isDefault;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final isTouch = YumeiroModalityScope.metricsOf(context).isTouch;
    return YumeiroTooltip(
      message: label,
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: YumeiroInteractiveVisualSurface(
          role: YumeiroControlRole.secondary,
          selected: selected,
          onTap: onTap,
          padding: EdgeInsets.all(isTouch ? 10 : 2),
          child: _ColorPreview(
            color: color,
            isDefault: isDefault,
            size: isTouch ? 28 : 20,
            outlineColor: selected ? (accentColor ?? theme.accent) : null,
          ),
        ),
      ),
    );
  }
}

class _SaturationValueField extends StatelessWidget {
  const _SaturationValueField({
    super.key,
    required this.hue,
    required this.saturation,
    required this.value,
    required this.onChanged,
    required this.onInteractionEnd,
  });

  final double hue;
  final double saturation;
  final double value;
  final void Function(Offset position, Size size) onChanged;
  final VoidCallback onInteractionEnd;

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final l10n = YumeiroLocalizations.of(context);
    final isTouch = YumeiroModalityScope.metricsOf(context).isTouch;
    final radius = theme.buttonRadius;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 276.0;
        final height = isTouch ? 210.0 : 150.0;
        final size = Size(width, height);
        const step = 0.02;

        void apply(double nextSaturation, double nextValue) {
          final clampedS = nextSaturation.clamp(0.0, 1.0);
          final clampedV = nextValue.clamp(0.0, 1.0);
          onChanged(Offset(clampedS * width, (1 - clampedV) * height), size);
          onInteractionEnd();
        }

        KeyEventResult handleKey(KeyEvent event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            apply(saturation - step, value);
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            apply(saturation + step, value);
          } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            apply(saturation, value + step);
          } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            apply(saturation, value - step);
          } else {
            return KeyEventResult.ignored;
          }
          return KeyEventResult.handled;
        }

        int pct(double val) => (val.clamp(0.0, 1.0) * 100).round();
        final current = l10n.saturationBrightnessValue(
          pct(saturation),
          pct(value),
        );
        final increased = l10n.saturationBrightnessValue(
          pct(saturation + step),
          pct(value),
        );
        final decreased = l10n.saturationBrightnessValue(
          pct(saturation - step),
          pct(value),
        );

        return Focus(
          onKeyEvent: (_, event) => handleKey(event),
          child: Builder(
            builder: (focusContext) {
              final focused = Focus.of(focusContext).hasFocus;
              return Semantics(
                container: true,
                slider: true,
                label: l10n.saturationValuePanel,
                value: current,
                increasedValue: increased,
                decreasedValue: decreased,
                hint: l10n.saturationValueHint,
                onIncrease: () => apply(saturation + step, value),
                onDecrease: () => apply(saturation - step, value),
                customSemanticsActions: {
                  CustomSemanticsAction(label: l10n.increaseBrightness): () =>
                      apply(saturation, value + step),
                  CustomSemanticsAction(label: l10n.decreaseBrightness): () =>
                      apply(saturation, value - step),
                },
                child: AnimatedContainer(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : theme.motion.fast,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(radius),
                    border: Border.all(
                      color: focused ? theme.accent : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(radius),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (_) => Focus.of(focusContext).requestFocus(),
                      onTapUp: (details) {
                        onChanged(details.localPosition, size);
                        onInteractionEnd();
                      },
                      onPanStart: (details) {
                        Focus.of(focusContext).requestFocus();
                        onChanged(details.localPosition, size);
                      },
                      onPanUpdate: (details) =>
                          onChanged(details.localPosition, size),
                      onPanEnd: (_) => onInteractionEnd(),
                      child: SizedBox(
                        width: width,
                        height: height,
                        child: CustomPaint(
                          painter: _SaturationValuePainter(
                            hue: hue,
                            saturation: saturation,
                            value: value,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _HueField extends StatelessWidget {
  const _HueField({
    super.key,
    required this.hue,
    required this.onChanged,
    required this.onInteractionEnd,
  });

  final double hue;
  final void Function(Offset position, Size size) onChanged;
  final VoidCallback onInteractionEnd;

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final l10n = YumeiroLocalizations.of(context);
    final isTouch = YumeiroModalityScope.metricsOf(context).isTouch;
    final radius = theme.chipRadius;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 276.0;
        final height = isTouch ? 48.0 : 16.0;
        final size = Size(width, height);
        const step = 2.0;

        void apply(double nextHue) {
          final normalized = nextHue.clamp(0.0, 360.0);
          onChanged(Offset(normalized / 360 * width, 0), size);
          onInteractionEnd();
        }

        KeyEventResult handleKey(KeyEvent event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            apply(hue - step);
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            apply(hue + step);
          } else {
            return KeyEventResult.ignored;
          }
          return KeyEventResult.handled;
        }

        String degrees(double value) => '${value.round()}°';

        return Focus(
          onKeyEvent: (_, event) => handleKey(event),
          child: Builder(
            builder: (focusContext) {
              final focused = Focus.of(focusContext).hasFocus;
              return Semantics(
                container: true,
                slider: true,
                label: l10n.hueSlider,
                value: degrees(hue),
                increasedValue: degrees(hue + step),
                decreasedValue: degrees(hue - step),
                hint: l10n.hueSliderArrowHint,
                onIncrease: () => apply(hue + step),
                onDecrease: () => apply(hue - step),
                child: AnimatedContainer(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : theme.motion.fast,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(radius),
                    border: Border.all(
                      color: focused ? theme.accent : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(radius),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (_) => Focus.of(focusContext).requestFocus(),
                      onTapUp: (details) {
                        onChanged(details.localPosition, size);
                        onInteractionEnd();
                      },
                      onPanStart: (details) {
                        Focus.of(focusContext).requestFocus();
                        onChanged(details.localPosition, size);
                      },
                      onPanUpdate: (details) =>
                          onChanged(details.localPosition, size),
                      onPanEnd: (_) => onInteractionEnd(),
                      child: SizedBox(
                        width: width,
                        height: height,
                        child: CustomPaint(painter: _HuePainter(hue: hue)),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _SaturationValuePainter extends CustomPainter {
  const _SaturationValuePainter({
    required this.hue,
    required this.saturation,
    required this.value,
  });

  final double hue;
  final double saturation;
  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final baseColor = HSVColor.fromAHSV(1, hue, 1, 1).toColor();
    canvas.drawRect(rect, Paint()..color = baseColor);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Colors.white, Colors.transparent],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black],
        ).createShader(rect),
    );

    final marker = Offset(
      saturation.clamp(0.0, 1.0) * size.width,
      (1 - value.clamp(0.0, 1.0)) * size.height,
    );
    canvas.drawCircle(
      marker,
      8,
      Paint()..color = Colors.black.withValues(alpha: 0.38),
    );
    canvas.drawCircle(
      marker,
      6,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _SaturationValuePainter oldDelegate) =>
      oldDelegate.hue != hue ||
      oldDelegate.saturation != saturation ||
      oldDelegate.value != value;
}

class _HuePainter extends CustomPainter {
  const _HuePainter({required this.hue});

  final double hue;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Colors.red,
            Colors.yellow,
            Colors.green,
            Colors.cyan,
            Colors.blue,
            Color(0xFFFF00FF),
            Colors.red,
          ],
        ).createShader(rect),
    );
    final x = hue.clamp(0.0, 360.0) / 360 * size.width;
    canvas.drawCircle(
      Offset(x, size.height / 2),
      7,
      Paint()..color = Colors.black.withValues(alpha: 0.35),
    );
    canvas.drawCircle(
      Offset(x, size.height / 2),
      5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _HuePainter oldDelegate) =>
      oldDelegate.hue != hue;
}

bool _sameColor(Color? first, Color? second) {
  if (first == null || second == null) return first == null && second == null;
  return first.toARGB32() == second.toARGB32();
}

String _hexFor(Color color) {
  final argb = color.toARGB32();
  final opaque = argb >> 24 == 0xFF;
  final value = opaque ? argb & 0xFFFFFF : argb;
  return '#${value.toRadixString(16).padLeft(opaque ? 6 : 8, '0').toUpperCase()}';
}

Color? _parseHex(String raw) {
  final clean = raw.trim().replaceFirst('#', '');
  if (clean.length != 6 && clean.length != 8) return null;
  final value = int.tryParse(clean, radix: 16);
  if (value == null) return null;
  return clean.length == 6 ? Color(0xFF000000 | value) : Color(value);
}
