import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../foundation/modality.dart';
import '../../l10n/localizations.dart';
import '../../primitives/visual_surface.dart';
import '../../theme/theme.dart';
import '../../theme/visual_role.dart';
import '../layout/setting_row.dart';
import 'buttons.dart';
import 'inputs.dart';

/// Modality-adaptive continuous or stepped slider with optional formatted
/// readout badge.
class YumeiroSlider extends StatelessWidget {
  const YumeiroSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.label,
    this.valueLabel,
    this.activeColor,
    this.inactiveColor,
    this.thumbColor,
    this.focusNode,
    this.semanticFormatterCallback,
    this.padding,
  });

  /// Host-owned position. The visible slider clamps it to [min] and [max].
  final double value;

  /// Reports changes as the user adjusts the slider. Null disables it.
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeStart;
  final ValueChanged<double>? onChangeEnd;
  final double min;
  final double max;
  final int? divisions;
  final String? label;
  final String? valueLabel;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? thumbColor;
  final FocusNode? focusNode;
  final SemanticFormatterCallback? semanticFormatterCallback;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final metrics = YumeiroModalityScope.metricsOf(context);
    final effectiveTheme =
        (activeColor == null && inactiveColor == null && thumbColor == null)
        ? theme.sliderTheme
        : theme.sliderTheme.copyWith(
            activeTrackColor: activeColor,
            inactiveTrackColor: inactiveColor,
            thumbColor: thumbColor ?? activeColor,
          );
    final slider = SliderTheme(
      data: effectiveTheme,
      child: SizedBox(
        height: metrics.isTouch ? metrics.minTargetSize : 32,
        child: Slider(
          value: value.clamp(min, max).toDouble(),
          min: min,
          max: max,
          divisions: divisions,
          label: label,
          onChanged: onChanged,
          onChangeStart: onChangeStart,
          onChangeEnd: onChangeEnd,
          focusNode: focusNode,
          semanticFormatterCallback: semanticFormatterCallback,
          padding: padding,
        ),
      ),
    );

    if (valueLabel == null) return slider;
    final readoutStyle = theme.typography.tag(interactive: true);
    return LayoutBuilder(
      builder: (context, constraints) => Row(
        children: [
          Expanded(child: slider),
          SizedBox(width: theme.spacing.sm),
          ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: metrics.chipHeight,
              maxWidth: constraints.hasBoundedWidth
                  ? constraints.maxWidth * .4
                  : double.infinity,
            ),
            child: YumeiroVisualSurface(
              role: YumeiroSurfaceRole.readout,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              child: Center(
                widthFactor: 1,
                heightFactor: 1,
                child: Text(
                  valueLabel!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.typography.mono(
                    fontSize: readoutStyle.fontSize,
                    fontWeight: theme.typography.emphasisWeight,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Modality-adaptive slider for choosing the two endpoints of an interval.
class YumeiroRangeSlider extends StatelessWidget {
  const YumeiroRangeSlider({
    super.key,
    required this.values,
    required this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.labels,
    this.activeColor,
    this.inactiveColor,
    this.thumbColor,
    this.semanticFormatterCallback,
    this.padding,
  }) : assert(min <= max);

  /// Host-owned interval. Each endpoint is displayed within [min] and [max].
  final RangeValues values;

  /// Reports the interval as the user moves a thumb. Null disables the slider.
  final ValueChanged<RangeValues>? onChanged;
  final ValueChanged<RangeValues>? onChangeStart;
  final ValueChanged<RangeValues>? onChangeEnd;
  final double min;
  final double max;
  final int? divisions;
  final RangeLabels? labels;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? thumbColor;
  final SemanticFormatterCallback? semanticFormatterCallback;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context).sliderTheme;
    final metrics = YumeiroModalityScope.metricsOf(context);
    final singleThumb = theme.thumbShape;
    return SliderTheme(
      data: theme.copyWith(
        activeTrackColor: activeColor,
        inactiveTrackColor: inactiveColor,
        thumbColor: thumbColor ?? activeColor,
        rangeTrackShape:
            theme.rangeTrackShape ?? const RoundedRectRangeSliderTrackShape(),
        rangeThumbShape:
            theme.rangeThumbShape ??
            (singleThumb is RoundSliderThumbShape
                ? RoundRangeSliderThumbShape(
                    enabledThumbRadius: singleThumb.enabledThumbRadius,
                    disabledThumbRadius: singleThumb.disabledThumbRadius,
                    elevation: singleThumb.elevation,
                    pressedElevation: singleThumb.pressedElevation,
                  )
                : null),
      ),
      child: SizedBox(
        height: metrics.isTouch ? metrics.minTargetSize : 32,
        child: RangeSlider(
          values: RangeValues(
            values.start.clamp(min, max).toDouble(),
            values.end.clamp(min, max).toDouble(),
          ),
          min: min,
          max: max,
          divisions: divisions,
          labels: labels,
          onChanged: onChanged,
          onChangeStart: onChangeStart,
          onChangeEnd: onChangeEnd,
          semanticFormatterCallback: semanticFormatterCallback,
          padding: padding,
        ),
      ),
    );
  }
}

/// Combined slider + reset action + numeric [YumeiroTextField] editor,
/// supporting logarithmic tracks, display multipliers, custom formatting/parsing,
/// and responsive modality convergence.
class YumeiroSliderInput extends StatefulWidget {
  const YumeiroSliderInput({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.title,
    this.subtitle,
    this.defaultValue,
    this.onReset,
    this.resetTooltip,
    this.isResetEnabled,
    this.divisions,
    this.logarithmic = false,
    this.step,
    this.suffixText,
    this.displayMultiplier,
    this.decimalPlaces = 0,
    this.formatValue,
    this.parseValue,
    this.formatSuffix,
    this.width = 320.0,
    this.inputWidth = 80.0,
    this.enabled = true,
    this.controller,
    this.focusNode,
    this.placeholder,
    this.onTextSubmitted,
    this.sliderLabel,
    this.textAlign = TextAlign.center,
  }) : assert(!logarithmic || (min > 0 && max > min));

  final String? title;
  final String? subtitle;
  final double value;
  final double min;
  final double max;

  /// Target for the default reset action. When configured, the reset button
  /// is disabled by default if the current value already matches it.
  final double? defaultValue;

  /// Reports adjusted slider values and committed numeric text values.
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeStart;
  final ValueChanged<double>? onChangeEnd;

  /// Supplies a custom reset action. Update the configured value in the caller.
  final VoidCallback? onReset;
  final String? resetTooltip;

  /// Overrides the enabled state of a configured reset action for [value].
  final bool Function(double value)? isResetEnabled;
  final int? divisions;
  final bool logarithmic;

  /// Quantizes committed numeric text in value units. Slider steps are
  /// controlled separately by [divisions].
  final double? step;
  final String? suffixText;
  final double? displayMultiplier;
  final int decimalPlaces;

  /// Overrides text formatting and lets this widget synchronize the text of
  /// an external [controller] with the value.
  final String Function(double value)? formatValue;

  /// Parses a draft and returns a value in model units. Return null for
  /// invalid input.
  final double? Function(String text)? parseValue;
  final String? Function(double value)? formatSuffix;
  final double? width;
  final double inputWidth;
  final bool enabled;

  /// External text controller owned by the caller. Supply [formatValue] to
  /// opt in to automatic text formatting when using this controller.
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? placeholder;

  /// Takes over Enter submission and disables the default commit on blur.
  final ValueChanged<String>? onTextSubmitted;
  final String? sliderLabel;
  final TextAlign textAlign;

  @override
  State<YumeiroSliderInput> createState() => _YumeiroSliderInputState();
}

class _YumeiroSliderInputState extends State<YumeiroSliderInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isInternalController = false;
  bool _isInternalFocusNode = false;
  String? _lastCommittedText;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController();
      _isInternalController = true;
    }

    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _focusNode = FocusNode();
      _isInternalFocusNode = true;
    }

    _syncText();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant YumeiroSliderInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (_isInternalController) _controller.dispose();
      if (widget.controller != null) {
        _controller = widget.controller!;
        _isInternalController = false;
      } else {
        _controller = TextEditingController.fromValue(
          oldWidget.controller!.value,
        );
        _isInternalController = true;
      }
    }
    if (oldWidget.focusNode != widget.focusNode) {
      _focusNode.removeListener(_handleFocusChange);
      if (_isInternalFocusNode) _focusNode.dispose();
      if (widget.focusNode != null) {
        _focusNode = widget.focusNode!;
        _isInternalFocusNode = false;
      } else {
        _focusNode = FocusNode();
        _isInternalFocusNode = true;
      }
      _focusNode.addListener(_handleFocusChange);
    }
    _syncText();
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    if (_isInternalFocusNode) _focusNode.dispose();
    if (_isInternalController) _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      _lastCommittedText = null;
    } else {
      if (widget.onTextSubmitted != null) return;
      _commitText();
    }
  }

  String _formatValue(double v) {
    if (widget.formatValue != null) return widget.formatValue!(v);
    final mult = widget.displayMultiplier ?? 1.0;
    final displayVal = v * mult;
    if (widget.decimalPlaces > 0) {
      return displayVal.toStringAsFixed(widget.decimalPlaces);
    }
    return '${displayVal.round()}';
  }

  double? _parseText(String text) {
    if (widget.parseValue != null) return widget.parseValue!(text);
    var cleaned = text.trim();
    if (widget.suffixText != null &&
        widget.suffixText!.isNotEmpty &&
        cleaned.endsWith(widget.suffixText!)) {
      cleaned = cleaned
          .substring(0, cleaned.length - widget.suffixText!.length)
          .trim();
    }
    final parsed = double.tryParse(cleaned);
    if (parsed == null) return null;
    final mult = widget.displayMultiplier ?? 1.0;
    return parsed / mult;
  }

  void _syncText({double? forcedValue}) {
    if (_focusNode.hasFocus && forcedValue == null) return;
    if (!_isInternalController && widget.formatValue == null) return;
    final val = forcedValue ?? widget.value;
    final formatted = _formatValue(val);
    if (_controller.text != formatted) {
      _controller.text = formatted;
    }
  }

  void _commitText() {
    if (!widget.enabled) {
      _syncText();
      return;
    }
    final raw = _controller.text;
    if (_lastCommittedText == raw) return;
    final parsed = _parseText(raw);
    if (parsed == null || !parsed.isFinite) {
      _syncText();
      return;
    }
    var clamped = parsed.clamp(widget.min, widget.max);
    if (widget.step != null && widget.step! > 0) {
      clamped = (clamped / widget.step!).round() * widget.step!;
    }
    clamped = clamped.clamp(widget.min, widget.max);
    if (clamped != widget.value) {
      widget.onChanged(clamped);
      widget.onChangeEnd?.call(clamped);
    }
    _syncText(forcedValue: clamped);
    _lastCommittedText = _controller.text;
  }

  void _handleSubmitted(String raw) {
    if (widget.onTextSubmitted != null) {
      widget.onTextSubmitted!(raw);
      return;
    }
    _commitText();
    _focusNode.unfocus();
  }

  void _handleSliderChanged(double v) {
    _discardTextDraft();
    widget.onChanged(v);
    _syncText(forcedValue: v);
    _lastCommittedText = _controller.text;
  }

  void _discardTextDraft() {
    _lastCommittedText = _controller.text;
    _focusNode.unfocus();
  }

  void _handleReset() {
    _discardTextDraft();
    if (widget.onReset != null) {
      widget.onReset!();
    } else if (widget.defaultValue != null) {
      widget.onChanged(widget.defaultValue!);
      widget.onChangeEnd?.call(widget.defaultValue!);
      _syncText(forcedValue: widget.defaultValue!);
    }
    _lastCommittedText = _controller.text;
  }

  bool get _isAtDefault {
    final defaultValue = widget.defaultValue;
    if (defaultValue == null) return false;
    final diff = (widget.value - defaultValue).abs();
    final epsilon = widget.divisions != null && widget.divisions! > 0
        ? (widget.max - widget.min) / (widget.divisions! * 4)
        : 0.001;
    return diff <= epsilon;
  }

  String? get _effectiveSuffix {
    if (widget.formatSuffix != null) return widget.formatSuffix!(widget.value);
    return widget.suffixText;
  }

  double _inputWidth(BuildContext context, YumeiroMetrics metrics) {
    final painter = TextPainter(
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    );
    final typography = YumeiroTheme.of(context).typography;
    double measure(String text, TextStyle style) {
      painter.text = TextSpan(text: text, style: style);
      painter.layout();
      return painter.width;
    }

    var valueWidth = 0.0;
    for (final value in [widget.min, widget.max, widget.value]) {
      final width = measure(_formatValue(value), typography.input());
      if (width > valueWidth) valueWidth = width;
    }
    final suffix = _effectiveSuffix;
    final suffixWidth = suffix == null || suffix.isEmpty
        ? 0.0
        : 4 + measure(suffix, typography.supporting);
    painter.dispose();
    final contentWidth =
        valueWidth + suffixWidth + metrics.horizontalPadding * 2 + 2;
    final minimum = metrics.isTouch && widget.inputWidth < 96.0
        ? 96.0
        : widget.inputWidth;
    return contentWidth > minimum ? contentWidth.ceilToDouble() : minimum;
  }

  String _semanticValue(double value) {
    final suffix =
        widget.formatSuffix?.call(value) ??
        (widget.formatSuffix == null ? widget.suffixText : null);
    return '${_formatValue(value)} ${suffix ?? ''}'.trim();
  }

  double _fromSlider(double value) {
    if (!widget.logarithmic) return value;
    return (widget.min * math.pow(widget.max / widget.min, value))
        .clamp(widget.min, widget.max)
        .toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final metrics = YumeiroModalityScope.metricsOf(context);
    final l10n = YumeiroLocalizations.of(context);
    final value = widget.value.clamp(widget.min, widget.max);

    final slider = YumeiroSlider(
      value: widget.logarithmic
          ? (math.log(value / widget.min) / math.log(widget.max / widget.min))
                .clamp(0.0, 1.0)
          : value,
      min: widget.logarithmic ? 0 : widget.min,
      max: widget.logarithmic ? 1 : widget.max,
      divisions: widget.divisions,
      label: widget.sliderLabel,
      semanticFormatterCallback: (position) =>
          _semanticValue(_fromSlider(position)),
      onChanged: widget.enabled
          ? (next) => _handleSliderChanged(_fromSlider(next))
          : null,
      onChangeStart: widget.enabled && widget.onChangeStart != null
          ? (next) => widget.onChangeStart!(_fromSlider(next))
          : null,
      onChangeEnd: widget.enabled && widget.onChangeEnd != null
          ? (next) => widget.onChangeEnd!(_fromSlider(next))
          : null,
    );

    final input = YumeiroTextField(
      width: _inputWidth(context, metrics),
      controller: _controller,
      focusNode: _focusNode,
      enabled: widget.enabled,
      hintText: widget.placeholder,
      semanticLabel: widget.title ?? widget.sliderLabel,
      suffixText: _effectiveSuffix,
      textAlign: widget.textAlign,
      keyboardType: TextInputType.numberWithOptions(
        decimal: true,
        signed: widget.min < 0,
      ),
      onSubmitted: _handleSubmitted,
    );

    final hasReset = widget.defaultValue != null || widget.onReset != null;
    final atDefault = _isAtDefault;
    final canReset =
        hasReset && (widget.isResetEnabled?.call(widget.value) ?? !atDefault);
    final resetButton = hasReset
        ? YumeiroButton(
            variant: YumeiroButtonVariant.ghost,
            icon: theme.icons.refresh,
            tooltip: atDefault && !canReset
                ? l10n.alreadyDefault
                : widget.resetTooltip ?? l10n.resetToDefault,
            onPressed: widget.enabled && canReset ? _handleReset : null,
          )
        : null;

    if (metrics.isTouch) {
      final controls = Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: theme.spacing.sm,
        runSpacing: theme.spacing.sm,
        children: [?resetButton, input],
      );
      return TextFieldTapRegion(
        child: widget.title != null
            ? YumeiroSettingRow(
                title: widget.title!,
                subtitle: widget.subtitle,
                trailing: controls,
                editor: slider,
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: controls,
                  ),
                  slider,
                ],
              ),
      );
    }

    final row = Row(
      children: [
        Expanded(child: slider),
        const SizedBox(width: 12),
        if (resetButton != null) ...[
          resetButton,
          SizedBox(width: theme.spacing.sm),
        ],
        input,
      ],
    );
    final editor = widget.width != null
        ? SizedBox(width: widget.width, child: row)
        : row;

    return TextFieldTapRegion(
      child: widget.title == null
          ? editor
          : YumeiroSettingRow(
              title: widget.title!,
              subtitle: widget.subtitle,
              editor: editor,
            ),
    );
  }
}
