import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../foundation/modality.dart';
import '../../l10n/localizations.dart';
import '../../primitives/visual_surface.dart';
import '../../theme/theme.dart';
import '../../theme/visual_role.dart';
import '../overlays/tooltip.dart';
import 'rating_stars.dart';

/// Half-star interactive 5-star rating editor with full keyboard, slider,
/// pointer hover preview, and touch drag support.
class YumeiroRatingEditor extends StatefulWidget {
  const YumeiroRatingEditor({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
    this.semanticValueFormatter,
  });

  /// Current rating on a five-star scale. Null denotes an unrated item.
  final double? value;

  /// Requests a new rating from the caller. Null disables editing.
  final ValueChanged<double?>? onChanged;
  final String? semanticLabel;
  final String Function(double?)? semanticValueFormatter;

  @override
  State<YumeiroRatingEditor> createState() => _YumeiroRatingEditorState();
}

class _YumeiroRatingEditorState extends State<YumeiroRatingEditor> {
  final _focus = FocusNode();
  double? _preview;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_focusChanged);
  }

  void _focusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focus.removeListener(_focusChanged);
    _focus.dispose();
    super.dispose();
  }

  double _ratingAt(double x, double width) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final position = (rtl ? width - x : x).clamp(0.0, width);
    return ((position / width * 10).ceil().clamp(1, 10)) / 2;
  }

  void _hover(double x, double width) {
    if (widget.onChanged == null || width <= 0) return;
    final next = _ratingAt(x, width);
    if (_preview != next) setState(() => _preview = next);
  }

  void _clearPreview() {
    if (_preview != null) setState(() => _preview = null);
  }

  @override
  void didUpdateWidget(YumeiroRatingEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value || widget.onChanged == null) {
      _preview = null;
    }
  }

  String _valueLabel(YumeiroLocalizations l10n, double? value) {
    if (widget.semanticValueFormatter != null) {
      return widget.semanticValueFormatter!(value);
    }
    if (value == null) return l10n.unrated;
    return l10n.ratingOutOfFive(formatRating(normalizeRating(value)));
  }

  void _choose(double x, double width) {
    if (widget.onChanged == null || width <= 0) return;
    _focus.requestFocus();
    _clearPreview();
    widget.onChanged!(_ratingAt(x, width));
  }

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final metrics = YumeiroModalityScope.metricsOf(context);
    final l10n = YumeiroLocalizations.of(context);
    final enabled = widget.onChanged != null;
    final value = normalizeRating(widget.value ?? 0);
    final visualValue = enabled ? _preview ?? value : value;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.min(200.0, constraints.maxWidth);
        return MergeSemantics(
          child: YumeiroVisualSurface(
            role: YumeiroControlRole.ghost,
            states: {
              if (_focus.hasFocus) WidgetState.focused,
              if (enabled && _preview != null) WidgetState.hovered,
              if (!enabled) WidgetState.disabled,
            },
            child: YumeiroTooltip(
              message: _valueLabel(l10n, _preview ?? widget.value),
              excludeFromSemantics: true,
              triggerMode: TooltipTriggerMode.manual,
              child: MouseRegion(
                cursor: enabled
                    ? SystemMouseCursors.click
                    : SystemMouseCursors.basic,
                onEnter: (event) => _hover(event.localPosition.dx, width),
                onHover: (event) => _hover(event.localPosition.dx, width),
                onExit: (_) => _clearPreview(),
                child: SizedBox(
                  width: width,
                  height: metrics.minTargetSize,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: RatingStars(
                          value: visualValue,
                          size: 24,
                          color: enabled ? theme.rating : theme.subtle,
                          expand: true,
                        ),
                      ),
                      Positioned.fill(
                        child: Semantics(
                          label: widget.semanticLabel ?? l10n.rating,
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 0,
                              thumbShape: SliderComponentShape.noThumb,
                              overlayShape: SliderComponentShape.noOverlay,
                              activeTrackColor: Colors.transparent,
                              inactiveTrackColor: Colors.transparent,
                              showValueIndicator: ShowValueIndicator.never,
                            ),
                            child: Slider(
                              focusNode: _focus,
                              value: value,
                              max: 5,
                              divisions: 10,
                              onChanged: enabled
                                  ? (next) {
                                      _clearPreview();
                                      final rating = normalizeRating(next);
                                      widget.onChanged!(
                                        rating == 0 ? null : rating,
                                      );
                                    }
                                  : null,
                              semanticFormatterCallback: (next) =>
                                  _valueLabel(l10n, next == 0 ? null : next),
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: ExcludeSemantics(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapUp: enabled
                                ? (event) =>
                                      _choose(event.localPosition.dx, width)
                                : null,
                            onHorizontalDragStart: enabled
                                ? (event) =>
                                      _choose(event.localPosition.dx, width)
                                : null,
                            onHorizontalDragUpdate: enabled
                                ? (event) =>
                                      _choose(event.localPosition.dx, width)
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
