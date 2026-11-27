import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../foundation/modality.dart';
import '../../l10n/localizations.dart';
import '../../primitives/backdrop_group.dart';
import '../../primitives/visual_surface.dart';
import '../../theme/theme.dart';
import '../../theme/visual_role.dart';
import '../controls/buttons.dart';
import '../controls/inputs.dart';
import '../overlays/editor.dart';

/// Presentation of a [YumeiroPagination] control.
enum YumeiroPaginationVariant {
  /// Shows page buttons when they fit in the available width.
  auto,

  /// Shows page buttons with gaps for omitted ranges.
  numbered,

  /// Shows the current page and total. Enables jumping when the pager is
  /// interactive and has more than one page.
  compact,
}

/// Controlled navigation for a known number of data or content pages.
///
/// Place it beside a data view or a swipeable page viewport, and update both
/// from the same page index. The host owns page loading and any data selection.
class YumeiroPagination extends StatefulWidget {
  const YumeiroPagination({
    super.key,
    required this.pageIndex,
    required this.pageCount,
    required this.onChanged,
    this.variant = YumeiroPaginationVariant.auto,
  }) : assert(pageCount >= 0),
       assert(pageIndex >= 0 && (pageCount == 0 || pageIndex < pageCount));

  /// Zero-based index of the selected page. Labels start at one.
  final int pageIndex;

  /// Total number of pages. Zero hides the control.
  final int pageCount;

  /// Requests a different page. Null leaves the control read-only.
  final ValueChanged<int>? onChanged;

  final YumeiroPaginationVariant variant;

  @override
  State<YumeiroPagination> createState() => _YumeiroPaginationState();
}

class _YumeiroPaginationState extends State<YumeiroPagination> {
  static const _previousKey = ValueKey('previous-page');
  static const _nextKey = ValueKey('next-page');

  void _select(int index) {
    if (index != widget.pageIndex && index < widget.pageCount) {
      widget.onChanged?.call(index);
    }
  }

  Future<void> _jumpToPage() async {
    final fieldKey = GlobalKey<FormFieldState<String>>();
    final initialValue = '${widget.pageIndex + 1}';
    final index = await YumeiroEditor.show<int>(
      context: context,
      builder: (panelContext) {
        final l10n = YumeiroLocalizations.of(panelContext);
        void submit() {
          final field = fieldKey.currentState!;
          if (field.validate()) {
            Navigator.of(panelContext).pop(int.parse(field.value!.trim()) - 1);
          }
        }

        final actions = [
          YumeiroButton(
            label: l10n.cancel,
            variant: YumeiroButtonVariant.ghost,
            onPressed: () => Navigator.of(panelContext).pop(),
          ),
          YumeiroButton(
            label: l10n.confirm,
            variant: YumeiroButtonVariant.primary,
            onPressed: submit,
          ),
        ];
        return YumeiroEditor(
          title: l10n.jumpToPage,
          maxWidth: 360,
          actions: actions,
          child: YumeiroTextField.form(
            key: fieldKey,
            initialValue: initialValue,
            label: l10n.pageNumberLabel,
            autofocus: true,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.go,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (value) {
              final pageCount = mounted ? widget.pageCount : 0;
              if (pageCount == 0) return l10n.noResults;
              final page = int.tryParse(value?.trim() ?? '', radix: 10);
              return page != null && page >= 1 && page <= pageCount
                  ? null
                  : l10n.pageNumberRange(pageCount);
            },
            onSubmitted: (_) => submit(),
          ),
        );
      },
    );
    if (mounted && index != null) _select(index);
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.pageCount;
    if (count == 0) return const SizedBox.shrink();

    final index = widget.pageIndex;
    final enabled = widget.onChanged != null;
    final l10n = YumeiroLocalizations.of(context);
    final theme = YumeiroTheme.of(context);
    final metrics = YumeiroModalityScope.metricsOf(context);
    final direction = Directionality.of(context);
    final rtl = direction == TextDirection.rtl;
    final gap = theme.spacing.xs;
    final targetSize = metrics.minTargetSize;
    final indicatorSize = metrics.isTouch
        ? theme.iconSizes.sm
        : theme.iconSizes.xs;
    final pagePadding = gap + 2;
    final preferredCompactPadding = metrics.horizontalPadding - 2;
    final gapWidth = metrics.isTouch ? targetSize : metrics.denseTargetSize - 6;
    final pages = _pageWindow(index, count);
    final canJump = enabled && count > 1;
    final position = l10n.pagePosition(index + 1, count);
    final controlStyle = theme.typography.control(selected: true);
    final labelStyle = controlStyle.copyWith(
      fontFeatures: [
        ...?controlStyle.fontFeatures,
        const FontFeature.tabularFigures(),
      ],
    );
    final normalLabelStyle = labelStyle.copyWith(
      fontWeight: theme.typography.controlWeight(),
    );
    final suffixStyle = labelStyle.copyWith(
      color: theme.muted,
      fontWeight: theme.typography.bodyWeight,
    );
    final totalLabel = ' / $count';

    final painter = TextPainter(
      textDirection: direction,
      textScaler: MediaQuery.textScalerOf(context),
      textWidthBasis: TextWidthBasis.longestLine,
      locale: Localizations.maybeLocaleOf(context),
    );
    final boldText = MediaQuery.boldTextOf(context);
    var textHeight = 0.0;
    double labelWidth(String label, TextStyle style) {
      painter.text = TextSpan(
        text: label,
        style: boldText ? style.copyWith(fontWeight: FontWeight.bold) : style,
      );
      painter.layout();
      for (final line in painter.computeLineMetrics()) {
        textHeight = math.max(textHeight, line.height.ceilToDouble());
      }
      return painter.width.ceilToDouble();
    }

    // Some theme fonts ignore tabular figures. Reserve space from their
    // widest digit, measured as the widest of ten single-digit lines.
    const digitLines = '0\n1\n2\n3\n4\n5\n6\n7\n8\n9';
    final digitCount = count.toString().length;
    final selectedDigitWidth = labelWidth(digitLines, labelStyle);
    final pageWidth = math.max(
      targetSize,
      digitCount *
              math.max(
                selectedDigitWidth,
                labelWidth(digitLines, normalLabelStyle),
              ) +
          2 * pagePadding,
    );
    final compactContentWidth =
        digitCount * selectedDigitWidth +
        labelWidth(totalLabel, suffixStyle) +
        (canJump ? indicatorSize + gap : 0);
    final preferredCompactWidth = math.max(
      targetSize,
      compactContentWidth + 2 * preferredCompactPadding,
    );
    final labelHeight = textHeight > targetSize ? textHeight + gap * 2 : null;
    painter.dispose();
    TextStyle foregroundStyle(BuildContext context, TextStyle style) =>
        style.copyWith(color: DefaultTextStyle.of(context).style.color);
    Widget pageLabel(String value, {bool selected = false}) => Builder(
      builder: (context) => Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: foregroundStyle(
          context,
          selected ? labelStyle : normalLabelStyle,
        ),
      ),
    );

    final compactLabel = Builder(
      builder: (context) => Text.rich(
        TextSpan(
          text: '${index + 1}',
          children: [TextSpan(text: totalLabel, style: suffixStyle)],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: foregroundStyle(context, labelStyle),
      ),
    );
    // The widest page window has one ellipsis. Using that width keeps the
    // variant stable when the current page adds or removes another ellipsis.
    final numberedWidth =
        2 * targetSize +
        pages.length * pageWidth +
        (pages.length + 1) * gap -
        (count > pages.length ? pageWidth - gapWidth : 0);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = switch (widget.variant) {
          YumeiroPaginationVariant.auto => constraints.maxWidth < numberedWidth,
          YumeiroPaginationVariant.numbered => false,
          YumeiroPaginationVariant.compact => true,
        };
        // Keep room for both arrows before allocating space to the readout.
        final compactWidth = math.max(
          targetSize,
          math.min(
            preferredCompactWidth,
            constraints.maxWidth - 2 * (targetSize + gap),
          ),
        );
        final compactPadding = math.min(
          preferredCompactPadding,
          math.max(0.0, (compactWidth - compactContentWidth) / 2),
        );

        return YumeiroBackdropGroup(
          child: Wrap(
            spacing: gap,
            runSpacing: gap,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              YumeiroButton(
                key: _previousKey,
                icon: rtl ? theme.icons.chevronRight : theme.icons.chevronLeft,
                tooltip: l10n.previousPage,
                variant: YumeiroButtonVariant.ghost,
                onPressed: enabled && index > 0
                    ? () => _select(index - 1)
                    : null,
              ),
              if (compact)
                if (canJump)
                  YumeiroButton(
                    customLeading: Padding(
                      padding: EdgeInsets.symmetric(horizontal: compactPadding),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: gap,
                        children: [
                          Flexible(child: compactLabel),
                          Icon(
                            theme.icons.chevronDown,
                            size: indicatorSize,
                            color: theme.muted,
                          ),
                        ],
                      ),
                    ),
                    semanticLabel: position,
                    tooltip: l10n.jumpToPage,
                    width: compactWidth,
                    height: labelHeight,
                    variant: YumeiroButtonVariant.secondary,
                    onPressed: _jumpToPage,
                  )
                else
                  Semantics(
                    label: position,
                    excludeSemantics: true,
                    child: YumeiroVisualSurface(
                      role: YumeiroSurfaceRole.readout,
                      visualInsets: metrics.isTouch
                          ? metrics.controlVisualInsets
                          : null,
                      child: SizedBox(
                        width: compactWidth,
                        height: labelHeight ?? targetSize,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: compactPadding,
                          ),
                          child: Center(child: compactLabel),
                        ),
                      ),
                    ),
                  )
              else
                for (final (slot, page) in pages.indexed)
                  if (page != null)
                    YumeiroButton(
                      key: ValueKey(page),
                      customLeading: Padding(
                        padding: EdgeInsets.symmetric(horizontal: pagePadding),
                        child: pageLabel(
                          '${page + 1}',
                          selected: page == index,
                        ),
                      ),
                      semanticLabel: l10n.pageNumber(page + 1),
                      width: pageWidth,
                      height: labelHeight,
                      variant: page == index
                          ? YumeiroButtonVariant.primary
                          : YumeiroButtonVariant.ghost,
                      selected: page == index,
                      onPressed: enabled ? () => _select(page) : null,
                    )
                  else
                    ExcludeSemantics(
                      key: ValueKey(('gap', slot)),
                      child: SizedBox(
                        width: gapWidth,
                        height: labelHeight ?? targetSize,
                        child: Icon(
                          theme.icons.more,
                          size: indicatorSize,
                          color: theme.subtle,
                        ),
                      ),
                    ),
              YumeiroButton(
                key: _nextKey,
                icon: rtl ? theme.icons.chevronLeft : theme.icons.chevronRight,
                tooltip: l10n.nextPage,
                variant: YumeiroButtonVariant.ghost,
                onPressed: enabled && index < count - 1
                    ? () => _select(index + 1)
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }
}

// Null slots mark omitted ranges. The number of slots stays stable when
// navigating through a long sequence.
List<int?> _pageWindow(int index, int count) {
  if (count <= 7) return List<int>.generate(count, (page) => page);
  final last = count - 1;
  if (index <= 3) return [0, 1, 2, 3, 4, null, last];
  if (index >= last - 3) {
    return [0, null, last - 4, last - 3, last - 2, last - 1, last];
  }
  return [0, null, index - 1, index, index + 1, null, last];
}
