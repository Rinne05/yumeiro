import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

// #region compact-table
typedef _CompactRow = ({String id, String label, String size, bool ready});

Widget compactTableDemo(
  BuildContext context, {
  Widget Function(String api, Widget child)? decorate,
}) => _CompactTableDemo(decorate: decorate);

class _CompactTableDemo extends StatefulWidget {
  const _CompactTableDemo({this.decorate});

  final Widget Function(String api, Widget child)? decorate;

  @override
  State<_CompactTableDemo> createState() => _CompactTableDemoState();
}

class _CompactTableDemoState extends State<_CompactTableDemo> {
  static const _versions = <_CompactRow>[
    (id: 'a', label: 'A', size: '1.42 GB', ready: true),
    (id: 'b', label: 'B', size: '0.83 GB', ready: true),
    (id: 'c', label: 'C', size: '3.24 GB', ready: false),
  ];
  static final _longList = List<_CompactRow>.generate(120, (index) {
    if (index < _versions.length) return _versions[index];
    final version = _versions[index % _versions.length];
    return (
      id: 'version-$index',
      label: '${version.label} · ${index + 1}',
      size: version.size,
      ready: version.ready,
    );
  }, growable: false);
  Set<Key> _selectedKeys = {const ValueKey('a')};
  var _mode = YumeiroTableSelectionMode.single;
  var _variant = YumeiroTableVariant.compact;
  var _stacked = true;
  var _showAll = false;

  ValueKey<String> _rowKey(_CompactRow item) => ValueKey(item.id);

  void _changeMode(YumeiroTableSelectionMode mode) => setState(() {
    _mode = mode;
    if (mode == YumeiroTableSelectionMode.single) {
      _selectedKeys = _selectedKeys.take(1).toSet();
    }
  });

  @override
  Widget build(BuildContext context) {
    final chinese = Localizations.localeOf(context).languageCode == 'zh';
    final theme = YumeiroTheme.of(context);
    Widget sample(String api, Widget child) =>
        widget.decorate?.call(api, child) ?? child;
    String label(_CompactRow item) =>
        chinese ? '示例 ${item.label}' : 'Example ${item.label}';
    final metrics = YumeiroModalityScope.metricsOf(context);
    final nameColumn = YumeiroTableColumn<_CompactRow>(
      title: chinese ? '名称' : 'Name',
      cellBuilder: (_, item, _) => Text(label(item)),
    );
    final sizeColumn = YumeiroTableColumn<_CompactRow>(
      title: chinese ? '大小' : 'Size',
      cellBuilder: (_, item, _) => Text(item.size),
    );
    final columns = [nameColumn, if (!_stacked) sizeColumn];
    final additionalColumnBands = [
      if (_stacked) [sizeColumn],
    ];
    final actions = [
      YumeiroTableColumn<_CompactRow>(
        fixedWidth: metrics.minTargetSize,
        cellBuilder: (context, item, _) => YumeiroButton(
          variant: YumeiroButtonVariant.ghost,
          icon: theme.icons.info,
          tooltip: chinese
              ? '查看 ${label(item)} 的详情'
              : 'Details for ${label(item)}',
          onPressed: () =>
              showYumeiroToast(context, '${label(item)} · ${item.size}'),
        ),
      ),
    ];
    final selection = YumeiroTableSelection<_CompactRow>(
      mode: _mode,
      selectedKeys: _selectedKeys,
      isItemEnabled: (item) => item.ready,
      onChanged: (keys) => setState(() => _selectedKeys = keys),
    );
    final compact = _variant == YumeiroTableVariant.compact;
    final items = _showAll ? _longList : _versions;
    final count = _selectedKeys.length;
    final hiddenSelectionCount = _showAll
        ? 0
        : _selectedKeys.difference(_versions.map(_rowKey).toSet()).length;
    String rowLabel(_CompactRow item) => '${label(item)}, ${item.size}';
    final constructor = _showAll
        ? 'YumeiroDataTable.sliver'
        : 'YumeiroDataTable';
    final arguments = [
      if (compact) 'variant: compact',
      if (_stacked) 'additionalColumnBands: …',
    ];
    final caption = arguments.isEmpty
        ? constructor
        : '$constructor(${arguments.join(', ')})';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            YumeiroSegmentedControl<YumeiroTableVariant>(
              options: [
                YumeiroSegmentOption(
                  value: YumeiroTableVariant.compact,
                  label: chinese ? '紧凑' : 'Compact',
                ),
                YumeiroSegmentOption(
                  value: YumeiroTableVariant.standard,
                  label: chinese ? '标准' : 'Standard',
                ),
              ],
              value: _variant,
              onChanged: (value) => setState(() => _variant = value),
            ),
            YumeiroSegmentedControl<bool>(
              options: [
                YumeiroSegmentOption(
                  value: false,
                  label: chinese ? '单排' : 'One line',
                ),
                YumeiroSegmentOption(
                  value: true,
                  label: chinese ? '上下两排' : 'Two lines',
                ),
              ],
              value: _stacked,
              onChanged: (value) => setState(() => _stacked = value),
            ),
            YumeiroSegmentedControl<YumeiroTableSelectionMode>(
              options: [
                YumeiroSegmentOption(
                  value: YumeiroTableSelectionMode.single,
                  label: chinese ? '单选' : 'Single',
                ),
                YumeiroSegmentOption(
                  value: YumeiroTableSelectionMode.multiple,
                  label: chinese ? '多选' : 'Multiple',
                ),
              ],
              value: _mode,
              onChanged: _changeMode,
            ),
            YumeiroButton(
              label: chinese
                  ? (_showAll ? '隐藏' : '查看全部')
                  : (_showAll ? 'Hide' : 'View all'),
              onPressed: () => setState(() => _showAll = !_showAll),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_showAll)
          sample(
            caption,
            SizedBox(
              height: 240,
              child: CustomScrollView(
                primary: false,
                slivers: [
                  YumeiroDataTable<_CompactRow>.sliver(
                    items: items,
                    rowKey: _rowKey,
                    rowSemanticsLabel: rowLabel,
                    columns: columns,
                    additionalColumnBands: additionalColumnBands,
                    trailingColumns: actions,
                    variant: _variant,
                    minWidth: compact ? null : 380,
                    pinnedHeader: !compact,
                    selection: selection,
                    showSelectionIndicator: true,
                    rowTapBehavior: YumeiroTableRowTapBehavior.select,
                  ),
                ],
              ),
            ),
          )
        else
          sample(
            caption,
            YumeiroDataTable<_CompactRow>(
              items: items,
              rowKey: _rowKey,
              rowSemanticsLabel: rowLabel,
              columns: columns,
              additionalColumnBands: additionalColumnBands,
              trailingColumns: actions,
              variant: _variant,
              minWidth: compact ? null : 380,
              selection: selection,
              showSelectionIndicator: true,
              rowTapBehavior: YumeiroTableRowTapBehavior.select,
            ),
          ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Semantics(
              liveRegion: true,
              child: Text(chinese ? '已选 $count 项' : 'Selected: $count'),
            ),
            if (hiddenSelectionCount > 0)
              Text(
                chinese
                    ? '其中 $hiddenSelectionCount 项已隐藏'
                    : '$hiddenSelectionCount hidden',
              ),
            YumeiroButton(
              label: chinese ? '确认选择' : 'Confirm selection',
              onPressed: count == 0
                  ? null
                  : () => showYumeiroToast(
                      context,
                      chinese ? '已确认 $count 项' : 'Confirmed: $count',
                    ),
            ),
            YumeiroButton(
              label: chinese ? '清空选择' : 'Clear selection',
              variant: YumeiroButtonVariant.ghost,
              onPressed: count == 0
                  ? null
                  : () => setState(() => _selectedKeys = {}),
            ),
          ],
        ),
      ],
    );
  }
}
// #endregion compact-table

// #region data-table
typedef DownloadTask = ({int id, String name, bool complete});

Widget dataTableDemo(BuildContext context) {
  const items = <DownloadTask>[
    (id: 1, name: '薄荷色的早晨', complete: true),
    (id: 3, name: '午后列车', complete: false),
    (id: 2, name: '蓝色邮局', complete: true),
  ];
  YumeiroTableSelectionMode? mode = YumeiroTableSelectionMode.multiple;
  var selected = <Key>{const ValueKey(1)};
  var showOnlyBlueTask = false;
  var useTouchSummary = false;
  var moveDisabledToEnd = false;
  String? lastOpened;

  ValueKey<int> rowKey(DownloadTask task) => ValueKey(task.id);

  return StatefulBuilder(
    builder: (context, setState) {
      final visible = [
        for (final item in items)
          if (!showOnlyBlueTask || item.name.startsWith('蓝色')) item,
      ];
      final hiddenSelection = selected.difference(visible.map(rowKey).toSet());

      Widget statusBadge(DownloadTask item) => YumeiroBadge(
        label: item.complete ? '已完成' : '下载中',
        statusRole: item.complete
            ? YumeiroStatusRole.success
            : YumeiroStatusRole.info,
      );

      Widget detailsButton(BuildContext context, DownloadTask item) =>
          YumeiroButton(
            variant: YumeiroButtonVariant.ghost,
            icon: YumeiroTheme.of(context).icons.info,
            tooltip: '查看 ${item.name} 的详情',
            onPressed: () => setState(() => lastOpened = item.name),
          );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          YumeiroSegmentedControl<YumeiroTableSelectionMode?>(
            options: const [
              YumeiroSegmentOption(value: null, label: '浏览'),
              YumeiroSegmentOption(
                value: YumeiroTableSelectionMode.single,
                label: '单选',
              ),
              YumeiroSegmentOption(
                value: YumeiroTableSelectionMode.multiple,
                label: '多选',
              ),
            ],
            value: mode,
            onChanged: (next) => setState(() {
              mode = next;
              if (next == YumeiroTableSelectionMode.single) {
                selected = selected.take(1).toSet();
              }
            }),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              YumeiroButton(
                label: showOnlyBlueTask ? '显示全部任务' : '仅显示蓝色任务',
                variant: YumeiroButtonVariant.secondary,
                onPressed: () => setState(() {
                  showOnlyBlueTask = !showOnlyBlueTask;
                }),
              ),
              YumeiroButton(
                label: useTouchSummary ? '切回列式表格' : '查看触控摘要',
                variant: YumeiroButtonVariant.secondary,
                onPressed: () => setState(() {
                  useTouchSummary = !useTouchSummary;
                }),
              ),
              YumeiroCheckbox(
                label: '禁选项置底',
                value: moveDisabledToEnd,
                onChanged: mode == null
                    ? null
                    : (value) =>
                          setState(() => moveDisabledToEnd = value ?? false),
              ),
              Text('已选择 ${selected.length} 项'),
              if (hiddenSelection.isNotEmpty)
                Text('其中 ${hiddenSelection.length} 项被筛选隐藏'),
            ],
          ),
          const SizedBox(height: 12),
          YumeiroModalityScope(
            modality: useTouchSummary
                ? YumeiroModality.touch
                : YumeiroModality.pointer,
            child: YumeiroDataTable<DownloadTask>(
              items: visible,
              minWidth: 350,
              rowKey: rowKey,
              rowSemanticsLabel: (item) => item.name,
              columns: [
                YumeiroTableColumn(
                  title: '任务',
                  flex: 2,
                  cellBuilder: (context, item, index) => Text(item.name),
                ),
                YumeiroTableColumn(
                  title: '状态',
                  cellBuilder: (context, item, index) => statusBadge(item),
                ),
                YumeiroTableColumn(
                  title: '操作',
                  fixedWidth: 52,
                  cellBuilder: (context, item, index) =>
                      detailsButton(context, item),
                ),
              ],
              compactRowBuilder: (context, item, index) => YumeiroDataRow(
                title: Text(item.name),
                subtitle: Text(item.complete ? '离线文件可用' : '等待下载完成'),
                status: statusBadge(item),
                actions: detailsButton(context, item),
              ),
              selection: switch (mode) {
                final mode? => YumeiroTableSelection(
                  mode: mode,
                  selectedKeys: selected,
                  isItemEnabled: (item) => item.complete,
                  moveDisabledToEnd: moveDisabledToEnd,
                  onChanged: (keys) => setState(() => selected = keys),
                ),
                null => null,
              },
            ),
          ),
          if (lastOpened != null) ...[
            const SizedBox(height: 8),
            Text('已打开详情 · $lastOpened'),
          ],
        ],
      );
    },
  );
}
// #endregion data-table

// #region navigation
Widget navigationDemo(BuildContext context) {
  const destinations = [
    YumeiroNavDestination(id: 'home', label: '首页', icon: Icons.home_outlined),
    YumeiroNavDestination(id: 'list', label: '任务', icon: Icons.list_alt),
    YumeiroNavDestination(id: 'saved', label: '收藏', icon: Icons.star_outline),
  ];
  const layouts = [
    ('窄屏底栏', 480.0, YumeiroModality.touch),
    ('窄窗口侧栏', 480.0, YumeiroModality.pointer),
    ('触控导航轨', 720.0, YumeiroModality.touch),
    ('桌面侧栏', 1024.0, YumeiroModality.pointer),
  ];
  const tabs = [
    YumeiroTopNavigationDestination(value: '简介', label: '简介'),
    YumeiroTopNavigationDestination(value: '章节', label: '章节'),
    YumeiroTopNavigationDestination(value: '收藏', label: '收藏'),
  ];
  var layoutIndex = 0;
  var selectedIndex = 0;
  var tab = tabs.first.value;
  var showPager = false;
  return StatefulBuilder(
    builder: (context, setState) {
      final (_, width, modality) = layouts[layoutIndex];
      const shellHeight = 280.0;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < layouts.length; i++)
                YumeiroButton(
                  label: layouts[i].$1,
                  variant: YumeiroButtonVariant.secondary,
                  selected: !showPager && layoutIndex == i,
                  onPressed: () => setState(() {
                    layoutIndex = i;
                    showPager = false;
                  }),
                ),
              YumeiroButton(
                label: '标签与分页',
                variant: YumeiroButtonVariant.secondary,
                selected: showPager,
                onPressed: () => setState(() => showPager = true),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (showPager)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                YumeiroPageHeader.compact(
                  title: '资源库',
                  onBack: tab == tabs.first.value
                      ? null
                      : () => setState(() => tab = tabs.first.value),
                ),
                SizedBox(
                  height: 170,
                  child: YumeiroTopNavigation.paged<String>(
                    value: tab,
                    destinations: tabs,
                    onChanged: (value) => setState(() => tab = value),
                    itemBuilder: (context, value) =>
                        Center(child: Text('当前栏目 · $value')),
                  ),
                ),
              ],
            )
          else ...[
            Text('示例逻辑宽度 · ${width.round()}'),
            const SizedBox(height: 12),
            SizedBox(
              height: shellHeight,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: MediaQuery(
                  // Simulate the screen class inside the embedded example.
                  data: MediaQuery.of(context)
                      .copyWith(size: Size(width, shellHeight)),
                  child: YumeiroModalityScope(
                    modality: modality,
                    child: YumeiroNavigationShell(
                      destinations: destinations,
                      selectedIndex: selectedIndex,
                      onSelectedIndex: (index) =>
                          setState(() => selectedIndex = index),
                      body: Center(
                        child: Text(
                          '当前页面 · ${destinations[selectedIndex].label}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      );
    },
  );
}
// #endregion navigation
