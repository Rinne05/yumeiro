import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

import 'gallery_widgets.dart';

class GalleryCompactTableDemo extends StatefulWidget {
  const GalleryCompactTableDemo({super.key});

  @override
  State<GalleryCompactTableDemo> createState() =>
      _GalleryCompactTableDemoState();
}

class _GalleryCompactTableDemoState extends State<GalleryCompactTableDemo> {
  bool _stacked = false;
  String? _selectedChoice;

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final touch = YumeiroModalityScope.metricsOf(context).isTouch;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: theme.spacing.sm,
      children: [
        Wrap(
          spacing: theme.spacing.sm,
          runSpacing: theme.spacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (!touch)
              YumeiroSegmentedControl<bool>(
                value: _stacked,
                options: [
                  YumeiroSegmentOption(
                    value: false,
                    label: gText(context, en: 'Horizontal', zh: '单排横向'),
                  ),
                  YumeiroSegmentOption(
                    value: true,
                    label: gText(context, en: 'Stacked', zh: '上下两排'),
                  ),
                ],
                onChanged: (value) => setState(() => _stacked = value),
              ),
            YumeiroButton(
              label: gText(context, en: 'Single-select table', zh: '单选表格'),
              variant: YumeiroButtonVariant.secondary,
              onPressed: _showChoices,
            ),
            YumeiroButton(
              label: gText(context, en: 'Table with actions', zh: '带操作的表格'),
              variant: YumeiroButtonVariant.secondary,
              onPressed: _showActions,
            ),
          ],
        ),
        if (_selectedChoice case final choice?)
          Semantics(
            liveRegion: true,
            child: Text(
              gText(
                context,
                en: 'Selected $choice',
                zh: '已选择 ${gSample(context, choice)}',
              ),
            ),
          ),
      ],
    );
  }

  Future<T?> _showTable<T>(WidgetBuilder builder) =>
      YumeiroModalityScope.metricsOf(context).isTouch
      ? YumeiroBottomSheet.show<T>(context: context, builder: builder)
      : YumeiroDialog.show<T>(context: context, builder: builder);

  Widget _tablePanel(
    BuildContext context, {
    required String title,
    required List<Widget> actions,
    required YumeiroDataTable<_SampleRow> table,
  }) {
    final child = _tableBody(table);
    return YumeiroModalityScope.metricsOf(context).isTouch
        ? YumeiroBottomSheet(title: title, actions: actions, child: child)
        : YumeiroDialog(title: title, actions: actions, child: child);
  }

  Future<void> _showChoices() async {
    var selectedKeys = <Key>{ValueKey(_selectedChoice ?? _choices.first.title)};
    final chosen = await _showTable<_SampleRow>(
      (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final touch = YumeiroModalityScope.metricsOf(context).isTouch;
          final selected = _choices.firstWhere(
            (row) => selectedKeys.contains(_choiceRowKey(row)),
          );
          return _tablePanel(
            context,
            title: gText(context, en: 'Single-select table', zh: '单选表格'),
            actions: [
              YumeiroButton(
                label: YumeiroLocalizations.of(context).cancel,
                variant: YumeiroButtonVariant.ghost,
                onPressed: () => Navigator.of(context).pop(),
              ),
              YumeiroButton(
                label: gText(context, en: 'Confirm Selection', zh: '确认选择'),
                variant: YumeiroButtonVariant.primary,
                onPressed: () => Navigator.of(context).pop(selected),
              ),
            ],
            table: YumeiroDataTable<_SampleRow>(
              variant: YumeiroTableVariant.compact,
              minWidth: _stacked || touch ? null : 350,
              items: _choices,
              rowKey: _choiceRowKey,
              columns: _entryColumns(context, files: false, selected: selected),
              additionalColumnBands: [
                if (_stacked && !touch)
                  _choiceMetadataColumns(context, selected),
              ],
              compactRowBuilder: touch
                  ? (context, row, _) => _summaryRow(
                      context,
                      row,
                      files: false,
                      selected: row == selected,
                    )
                  : null,
              showSelectionIndicator: true,
              selection: YumeiroTableSelection<_SampleRow>(
                mode: YumeiroTableSelectionMode.single,
                selectedKeys: selectedKeys,
                isItemEnabled: (row) => row.available,
                onChanged: (keys) => setDialogState(() => selectedKeys = keys),
              ),
            ),
          );
        },
      ),
    );
    if (!mounted || chosen == null) return;
    setState(() => _selectedChoice = chosen.title);
  }

  Key _choiceRowKey(_SampleRow row) => ValueKey(row.title);

  Future<void> _showActions() => _showTable<void>((context) {
    final theme = YumeiroTheme.of(context);
    final metrics = YumeiroModalityScope.metricsOf(context);
    final touch = metrics.isTouch;
    final actionWidth = metrics.minTargetSize;
    final copyLabel = gText(context, en: 'Copy', zh: '复制');
    final copyWidth = math.max(
      actionWidth + 16,
      _labelWidth(context, copyLabel, theme.typography.control(dense: true)) +
          metrics.horizontalPadding * 1.5,
    );
    final fileActions = <YumeiroTableColumn<_SampleRow>>[
      YumeiroTableColumn(
        title: gText(context, en: 'Inspect', zh: '查看详情'),
        preferredWidth: actionWidth,
        cellBuilder: (context, row, _) => _inspectButton(context, row),
      ),
      YumeiroTableColumn(
        title: gText(context, en: 'Copy description', zh: '复制说明'),
        preferredWidth: copyWidth,
        cellBuilder: (context, row, _) => _copyButton(context, row),
      ),
    ];
    return _tablePanel(
      context,
      title: gText(context, en: 'Table with actions', zh: '带操作的表格'),
      actions: [
        YumeiroButton(
          label: gText(context, en: 'Done', zh: '完成'),
          variant: YumeiroButtonVariant.ghost,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
      table: YumeiroDataTable<_SampleRow>(
        variant: YumeiroTableVariant.compact,
        minWidth: touch ? null : (_stacked ? 350 : 450),
        items: _details,
        columns: _stacked
            ? [_titleColumn()]
            : _entryColumns(context, files: true),
        additionalColumnBands: [
          if (_stacked && !touch)
            [
              YumeiroTableColumn(
                cellBuilder: (context, row, _) => _subtitleCell(context, row),
              ),
              const YumeiroTableColumn(
                alignment: AlignmentDirectional.centerEnd,
                cellBuilder: _fileMetadataCell,
              ),
            ],
        ],
        trailingColumns: touch ? const [] : fileActions,
        compactRowBuilder: touch
            ? (context, row, _) => _summaryRow(context, row, files: true)
            : null,
      ),
    );
  });

  Widget _tableBody(YumeiroDataTable<_SampleRow> table) => GalleryComponent(
    table.compactRowBuilder != null
        ? 'YumeiroDataTable(variant: compact, compactRowBuilder: …)'
        : table.additionalColumnBands.isEmpty
        ? 'YumeiroDataTable(variant: compact)'
        : 'YumeiroDataTable(variant: compact, additionalColumnBands: …)',
    child: table,
  );

  Widget _summaryRow(
    BuildContext context,
    _SampleRow row, {
    required bool files,
    bool selected = false,
  }) {
    final theme = YumeiroTheme.of(context);
    return YumeiroDataRow(
      title: Text(row.localizedTitle(context)),
      subtitle: Text(gSample(context, row.subtitle)),
      status: _statusBadge(context, row, files: files, selected: selected),
      metadata: row.size == null
          ? null
          : YumeiroTextStyle(
              style: theme.typography.mono(),
              child: Text(row.size!),
            ),
      actions: files
          ? Wrap(
              alignment: WrapAlignment.end,
              spacing: theme.spacing.xs,
              runSpacing: theme.spacing.xs,
              children: [
                ?_inspectButton(context, row),
                _copyButton(context, row),
              ],
            )
          : null,
    );
  }

  Widget? _inspectButton(BuildContext context, _SampleRow row) => row.available
      ? YumeiroButton(
          variant: YumeiroButtonVariant.ghost,
          icon: YumeiroTheme.of(context).icons.info,
          tooltip: gText(
            context,
            en: 'Inspect ${row.subtitle}',
            zh: '查看 ${gSample(context, row.subtitle)}',
          ),
          onPressed: () => _showDetails(context, row),
        )
      : null;

  Widget _copyButton(BuildContext context, _SampleRow row) => YumeiroButton(
    label: gText(context, en: 'Copy', zh: '复制'),
    dense: true,
    variant: YumeiroButtonVariant.ghost,
    tooltip: gText(
      context,
      en: 'Copy ${row.subtitle}',
      zh: '复制 ${gSample(context, row.subtitle)}',
    ),
    onPressed: () => _copyDescription(context, gSample(context, row.subtitle)),
  );

  YumeiroTableColumn<_SampleRow> _titleColumn({_SampleRow? selected}) =>
      YumeiroTableColumn(
        cellBuilder: (context, row, _) {
          final theme = YumeiroTheme.of(context);
          final isSelected = row == selected;
          final title = _cellText(
            row.localizedTitle(context),
            theme.typography.body.copyWith(
              fontWeight: theme.typography.emphasisWeight,
              color: theme.text,
            ),
            inheritForeground: isSelected,
          );
          return _stacked
              ? title
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    SizedBox(height: theme.spacing.xs),
                    _subtitleCell(context, row, inheritForeground: isSelected),
                  ],
                );
        },
      );

  List<YumeiroTableColumn<_SampleRow>> _entryColumns(
    BuildContext context, {
    required bool files,
    _SampleRow? selected,
  }) => [
    _titleColumn(selected: selected),
    YumeiroTableColumn(
      title: gText(context, en: 'Size', zh: '大小'),
      preferredWidth: (files ? _details : _choices).fold<double>(
        72,
        (width, row) => math.max(
          width,
          _labelWidth(
            context,
            row.size ?? '—',
            YumeiroTheme.of(context).typography.mono(),
          ),
        ),
      ),
      alignment: AlignmentDirectional.centerEnd,
      cellBuilder: (context, row, _) =>
          _sizeCell(context, row, inheritForeground: row == selected),
    ),
    if (!_stacked) _statusColumn(context, files: files, selected: selected),
  ];

  List<YumeiroTableColumn<_SampleRow>> _choiceMetadataColumns(
    BuildContext context,
    _SampleRow selection,
  ) => [
    YumeiroTableColumn(
      cellBuilder: (context, row, _) =>
          _subtitleCell(context, row, inheritForeground: row == selection),
    ),
    _statusColumn(context, files: false, selected: selection),
  ];

  Future<void> _showDetails(BuildContext context, _SampleRow row) =>
      YumeiroDialog.show<void>(
        context: context,
        builder: (context) => YumeiroDialog(
          title: row.localizedTitle(context),
          maxWidth: 390,
          child: YumeiroFieldLayout.readOnly(
            label: gText(context, en: 'Description', zh: '说明'),
            value: gSample(context, row.subtitle),
            bottomSpacing: 0,
          ),
        ),
      );

  Future<void> _copyDescription(BuildContext context, String name) async {
    await Clipboard.setData(ClipboardData(text: name));
    if (!context.mounted) return;
    showYumeiroToast(
      context,
      gText(context, en: 'Copied $name.', zh: '已复制 $name。'),
      statusRole: YumeiroStatusRole.success,
    );
  }
}

Widget _subtitleCell(
  BuildContext context,
  _SampleRow row, {
  bool inheritForeground = false,
}) {
  final theme = YumeiroTheme.of(context);
  return _cellText(
    gSample(context, row.subtitle),
    theme.typography.supporting.copyWith(color: theme.muted),
    inheritForeground: inheritForeground,
  );
}

Widget _sizeCell(
  BuildContext context,
  _SampleRow row, {
  bool inheritForeground = false,
}) => _cellText(
  row.size ?? '—',
  YumeiroTheme.of(context).typography.mono(),
  textAlign: TextAlign.end,
  inheritForeground: inheritForeground,
);

Widget _cellText(
  String text,
  TextStyle style, {
  TextAlign? textAlign,
  required bool inheritForeground,
}) {
  final label = Text(
    text,
    textAlign: textAlign,
    style: inheritForeground ? null : style,
  );
  return inheritForeground
      ? YumeiroTextStyle(style: style, child: label)
      : label;
}

Widget _fileMetadataCell(BuildContext context, _SampleRow row, int _) {
  final theme = YumeiroTheme.of(context);
  return Wrap(
    alignment: WrapAlignment.end,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: theme.spacing.sm,
    runSpacing: theme.spacing.xs,
    children: [
      Semantics(
        label: gText(context, en: 'Size', zh: '大小'),
        child: _sizeCell(context, row),
      ),
      Semantics(
        label: gText(context, en: 'Status', zh: '状态'),
        child: Text(
          _statusLabel(context, row, files: true),
          textAlign: TextAlign.end,
          style: theme.typography.tag().copyWith(
            color: theme.visuals.status(_statusRole(row)).foreground,
          ),
        ),
      ),
    ],
  );
}

YumeiroTableColumn<_SampleRow> _statusColumn(
  BuildContext context, {
  required bool files,
  _SampleRow? selected,
}) {
  final style = YumeiroTheme.of(context).typography.tag();
  final rows = files ? _details : _choices;
  final width = rows.fold<double>(
    files ? 80 : 106,
    (width, row) => math.max(
      width,
      _labelWidth(context, _statusLabel(context, row, files: files), style) +
          20,
    ),
  );
  return YumeiroTableColumn(
    title: gText(context, en: 'Status', zh: '状态'),
    preferredWidth: width,
    alignment: AlignmentDirectional.centerEnd,
    cellBuilder: (context, row, _) =>
        _statusBadge(context, row, files: files, selected: row == selected),
  );
}

Widget _statusBadge(
  BuildContext context,
  _SampleRow row, {
  required bool files,
  required bool selected,
}) => YumeiroBadge(
  label: _statusLabel(context, row, files: files),
  statusRole: _statusRole(row),
  tint: selected
      ? YumeiroTheme.of(context).visuals.status(_statusRole(row)).tint
      : null,
);

String _statusLabel(
  BuildContext context,
  _SampleRow row, {
  required bool files,
}) => switch ((files, row.available)) {
  (true, true) => gText(context, en: 'Ready', zh: '已就绪'),
  (true, false) => gText(context, en: 'Pending', zh: '待生成'),
  (false, true) => gText(context, en: 'Available', zh: '可用'),
  (false, false) => gText(context, en: 'Unavailable', zh: '暂不可用'),
};

YumeiroStatusRole _statusRole(_SampleRow row) =>
    row.available ? YumeiroStatusRole.success : YumeiroStatusRole.warning;

double _labelWidth(BuildContext context, String label, TextStyle style) =>
    TextPainter.computeWidth(
      text: TextSpan(
        text: label,
        style: Theme.of(context).textTheme.bodyMedium?.merge(style) ?? style,
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      locale: Localizations.maybeLocaleOf(context),
      maxLines: 1,
    ).ceilToDouble();

class _SampleRow {
  const _SampleRow({
    required this.title,
    required this.subtitle,
    this.size,
    this.available = true,
  });

  final String title;
  final String subtitle;
  final String? size;
  final bool available;

  String localizedTitle(BuildContext context) => gSample(context, title);
}

const _choices = [
  _SampleRow(title: 'Option A', subtitle: 'Description A', size: '1.42 GB'),
  _SampleRow(title: 'Option B', subtitle: 'Description B', size: '1.76 GB'),
  _SampleRow(title: 'Option C', subtitle: 'Description C', size: '0.83 GB'),
  _SampleRow(
    title: 'Option D',
    subtitle: 'Description D',
    size: '3.24 GB',
    available: false,
  ),
];

const _details = [
  _SampleRow(title: 'Example A', subtitle: 'Description A', size: '1.42 GB'),
  _SampleRow(title: 'Example B', subtitle: 'Description B', size: '96 KB'),
  _SampleRow(title: 'Example C', subtitle: 'Description C', size: '102 KB'),
  _SampleRow(title: 'Example D', subtitle: 'Description D', available: false),
];
