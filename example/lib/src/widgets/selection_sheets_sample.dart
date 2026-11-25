import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

import 'gallery_widgets.dart';

/// Opens selection sheets directly, with state separate from the form samples.
class SelectionSheetsSample extends StatefulWidget {
  const SelectionSheetsSample({super.key});

  @override
  State<SelectionSheetsSample> createState() => _SelectionSheetsSampleState();
}

class _SelectionSheetsSampleState extends State<SelectionSheetsSample> {
  var _single = 'A';
  Set<String> _multiple = const {'A'};
  bool? _confirmed;

  List<YumeiroSelectionOption<String>> _options(BuildContext context) => [
    for (final letter in ['A', 'B', 'C'])
      YumeiroSelectionOption(
        value: letter,
        label: gSample(context, 'Option $letter'),
      ),
  ];

  Future<void> _openSingle() async {
    final result = await YumeiroBottomSheet.select(
      context: context,
      title: gText(context, en: 'Select one option', zh: '请选择一项'),
      options: _options(context),
      value: _single,
      searchable: true,
    );
    if (!mounted || result == null) return;
    setState(() => _single = result.value);
  }

  Future<void> _openMultiple() async {
    final result = await YumeiroBottomSheet.multiSelect(
      context: context,
      title: gText(context, en: 'Select options', zh: '请选择多项'),
      options: _options(context),
      values: _multiple,
      searchable: true,
    );
    if (!mounted) return;
    setState(() {
      _confirmed = result != null;
      if (result != null) _multiple = result;
    });
  }

  String _summary(BuildContext context, Iterable<String> values) {
    if (values.isEmpty) {
      return gText(context, en: 'No options selected.', zh: '未选中任何选项。');
    }
    final labels = values
        .map((letter) => gSample(context, 'Option $letter'))
        .join(gText(context, en: ', ', zh: '、'));
    return gText(context, en: 'Selected $labels.', zh: '已选$labels。');
  }

  String _multipleSummary(BuildContext context) {
    final summary = _summary(context, _multiple);
    return switch (_confirmed) {
      true when _multiple.isEmpty => gText(
        context,
        en: 'Confirmed an empty selection.',
        zh: '已确认空选择。',
      ),
      true => gText(context, en: 'Confirmed. $summary', zh: '已确认。$summary'),
      false => gText(context, en: 'Cancelled. $summary', zh: '已取消。$summary'),
      null => summary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);

    Widget sample({
      required String api,
      required Key buttonKey,
      required Key resultKey,
      required String actionLabel,
      required VoidCallback onOpen,
      required String result,
    }) => GalleryComponent(
      api,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: theme.spacing.sm,
        children: [
          YumeiroButton(
            key: buttonKey,
            label: actionLabel,
            variant: YumeiroButtonVariant.secondary,
            onPressed: onOpen,
          ),
          Semantics(
            liveRegion: true,
            child: Text(
              key: resultKey,
              result,
              style: theme.typography.supporting.copyWith(color: theme.muted),
            ),
          ),
        ],
      ),
    );

    return GalleryCard.example(
      example: GalleryExample.selectionSheets,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: theme.spacing.md,
        children: [
          sample(
            api: 'YumeiroBottomSheet.select',
            buttonKey: const ValueKey('gallery-open-single-sheet'),
            resultKey: const ValueKey('gallery-single-sheet-result'),
            actionLabel: gText(
              context,
              en: 'Open Single-Select Sheet',
              zh: '打开单选面板',
            ),
            onOpen: _openSingle,
            result: _summary(context, [_single]),
          ),
          sample(
            api: 'YumeiroBottomSheet.multiSelect',
            buttonKey: const ValueKey('gallery-open-multiple-sheet'),
            resultKey: const ValueKey('gallery-multiple-sheet-result'),
            actionLabel: gText(
              context,
              en: 'Open Multi-Select Sheet',
              zh: '打开多选面板',
            ),
            onOpen: _openMultiple,
            result: _multipleSummary(context),
          ),
        ],
      ),
    );
  }
}
