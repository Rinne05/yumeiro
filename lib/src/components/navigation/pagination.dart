import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../foundation/modality.dart';
import '../../l10n/localizations.dart';
import '../../primitives/backdrop_group.dart';
import '../../theme/theme.dart';
import '../controls/buttons.dart';
import '../controls/inputs.dart';
import '../overlays/editor.dart';

/// Presentation of a [YumeiroPagination] control.
enum YumeiroPaginationVariant {
  /// Shows page buttons when they fit in the available width.
  auto,

  /// Shows page buttons with gaps for omitted ranges.
  numbered,

  /// Shows the current page and total, with a jump-to-page action.
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
    final iconSize = metrics.isTouch ? 24.0 : theme.iconSizes.md;
    final pages = _pageWindow(index, count);
    final canJump = enabled && count > 1;
    final labelStyle = theme.typography.control(
      selected: true,
      monospace: true,
    );
    final painter = TextPainter(
      textDirection: direction,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    );
    final widestNumber = '8' * count.toString().length;
    double labelWidth(String label) {
      painter.text = TextSpan(text: label, style: labelStyle);
      painter.layout();
      return painter.width.ceilToDouble() + gap * 2;
    }

    final pageWidth = math.max(targetSize, labelWidth(widestNumber));
    final compactWidth = math.max(
      targetSize,
      labelWidth('$widestNumber / $widestNumber') +
          (count > 1 ? iconSize + gap : 0),
    );
    final textHeight = painter.height.ceilToDouble();
    final labelHeight = textHeight > targetSize ? textHeight + gap * 2 : null;
    painter.dispose();
    Widget pageLabel(String value, {bool selected = false}) => Builder(
      builder: (context) => Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: labelStyle.copyWith(
          color: DefaultTextStyle.of(context).style.color,
          fontWeight: theme.typography.controlWeight(selected: selected),
        ),
      ),
    );

    final numberedWidth =
        2 * targetSize + pages.length * pageWidth + (pages.length + 1) * gap;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = switch (widget.variant) {
          YumeiroPaginationVariant.auto => constraints.maxWidth < numberedWidth,
          YumeiroPaginationVariant.numbered => false,
          YumeiroPaginationVariant.compact => true,
        };

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
                YumeiroButton(
                  customLeading: Padding(
                    padding: EdgeInsets.symmetric(horizontal: gap),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: gap,
                      children: [
                        Flexible(child: pageLabel('${index + 1} / $count')),
                        if (count > 1)
                          Icon(theme.icons.chevronDown, size: iconSize),
                      ],
                    ),
                  ),
                  semanticLabel: l10n.pagePosition(index + 1, count),
                  tooltip: canJump ? l10n.jumpToPage : null,
                  width: compactWidth,
                  height: labelHeight,
                  variant: YumeiroButtonVariant.ghost,
                  onPressed: canJump ? _jumpToPage : null,
                )
              else
                for (final (slot, page) in pages.indexed)
                  if (page != null)
                    YumeiroButton(
                      key: ValueKey(page),
                      customLeading: Padding(
                        padding: EdgeInsets.symmetric(horizontal: gap),
                        child: pageLabel(
                          '${page + 1}',
                          selected: page == index,
                        ),
                      ),
                      semanticLabel: l10n.pageNumber(page + 1),
                      width: pageWidth,
                      height: labelHeight,
                      variant: YumeiroButtonVariant.ghost,
                      selected: page == index,
                      onPressed: enabled ? () => _select(page) : null,
                    )
                  else
                    ExcludeSemantics(
                      key: ValueKey(('gap', slot)),
                      child: SizedBox(
                        width: pageWidth,
                        height: labelHeight ?? targetSize,
                        child: Icon(
                          theme.icons.more,
                          size: iconSize,
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
