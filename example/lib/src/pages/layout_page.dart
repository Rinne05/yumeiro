import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

import '../../docs/data_table_pagination_demo.dart';
import '../../docs/layout_demos.dart';
import '../state/gallery_controller.dart';
import '../widgets/compact_table_demo.dart';
import '../widgets/gallery_widgets.dart';
import '../widgets/layout_structure_demos.dart';

class LayoutPage extends StatefulWidget {
  const LayoutPage({super.key, required this.controller});

  final GalleryController controller;

  @override
  State<LayoutPage> createState() => _LayoutPageState();
}

class _LayoutPageState extends State<LayoutPage> {
  GalleryController get controller => widget.controller;

  YumeiroTableSelectionMode? _selectionMode =
      YumeiroTableSelectionMode.multiple;
  var _disclosureExpanded = false;
  var _resetDisclosureExpanded = false;
  var _showTableColumns = false;
  Set<String> _tableCategories = const {};
  var _searchableSetting = 1;
  var _topTab = 0;
  var _pagerPage = 0;
  var _leadingSelection = true;

  @override
  Widget build(BuildContext context) {
    final spacing = YumeiroTheme.of(context).spacing;
    final isTouch = YumeiroModalityScope.metricsOf(context).isTouch;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: spacing.xl,
      children: [
        GallerySection(
          title: gText(
            context,
            en: 'Page structure and navigation',
            zh: '页面结构与导航',
          ),
          children: [
            _pageHeaders(context),
            const GalleryCard.example(
              example: GalleryExample.pageScaffold,
              child: GalleryPageScaffoldDemo(),
            ),
            const GalleryCard.example(
              example: GalleryExample.navigationShell,
              child: GalleryNavigationShellDemo(),
            ),
            _pageNavigation(context, isTouch: isTouch),
          ],
        ),
        GallerySection(
          title: gText(context, en: 'Containers and actions', zh: '容器与操作布局'),
          children: [
            _containers(context),
            _disclosure(context),
            _actionGroups(context, isTouch: isTouch),
          ],
        ),
        GallerySection(
          title: gText(context, en: 'Settings and rows', zh: '设置与列表行'),
          children: [
            _settingsRows(context),
            _settingSelect(context),
            _summaryRows(context),
          ],
        ),
        GallerySection(
          title: gText(context, en: 'Data tables', zh: '数据表格'),
          children: [
            _dataTable(context, isTouch: isTouch),
            _compactTable(context),
            GalleryCard.example(
              example: GalleryExample.tablePagination,
              key: const ValueKey('sample-data-table-pagination'),
              description: gText(
                context,
                en: 'Retry failed requests and keep selections across pages.',
                zh: '重试失败请求，并在翻页时保留选择。',
              ),
              child: dataTablePaginationDemo(
                context,
                decorate: GalleryComponent.sample,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _pageHeaders(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    return GalleryCard.example(
      example: GalleryExample.pageHeaders,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: theme.spacing.md,
        children: [
          YumeiroNavigationScope(
            onBack: () => _showMessage(context, en: 'Back tapped', zh: '已点击返回'),
            child: GalleryComponent(
              'YumeiroPageHeader',
              child: YumeiroPageHeader(
                title: gSample(context, 'Example A'),
                badge: YumeiroBadge(
                  label: gSample(context, 'State A'),
                  statusRole: YumeiroStatusRole.success,
                ),
                bottomDivider: true,
              ),
            ),
          ),
          GalleryComponent(
            'YumeiroPageHeader.compact',
            child: YumeiroCard.panel(
              role: YumeiroSurfaceRole.navigation,
              child: YumeiroPageHeader.compact(
                title: gSample(context, 'Example B'),
                onBack: () =>
                    _showMessage(context, en: 'Back tapped', zh: '已点击返回'),
                actions: [
                  YumeiroButton(
                    variant: YumeiroButtonVariant.ghost,
                    icon: theme.icons.more,
                    tooltip: gText(context, en: 'More', zh: '更多'),
                    onPressed: () => _showMessage(context),
                  ),
                ],
              ),
            ),
          ),
          GalleryComponent(
            'YumeiroSectionHeader',
            child: YumeiroSectionHeader(
              title: gSample(context, 'Example C'),
              subtitle: gText(context, en: 'Description A', zh: '说明 A'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pageNavigation(BuildContext context, {required bool isTouch}) {
    final theme = YumeiroTheme.of(context);
    final destinations = [
      for (final (index, letter) in const ['A', 'B', 'C'].indexed)
        YumeiroTopNavigationDestination(
          value: index,
          label: gText(context, en: 'Tab $letter', zh: '标签页 $letter'),
        ),
    ];
    final pageValues = List.generate(24, (index) => index);

    void changePagerPage(int index) => setState(() => _pagerPage = index);
    Widget pageBody(BuildContext context, int value) => YumeiroCard.panel(
      role: YumeiroSurfaceRole.inset,
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(gSample(context, 'Example ${['A', 'B', 'C'][value]}')),
      ),
    );
    return GalleryCard.example(
      example: GalleryExample.pageNavigation,
      description: isTouch
          ? gText(
              context,
              en: 'In the paged example, tap a tab or swipe the content to change pages.',
              zh: '在分页示例中，点击标签或左右滑动正文可切页。',
            )
          : gText(
              context,
              en: 'Click a tab to switch pages. Use arrow keys when a tab has focus.',
              zh: '点击标签切页。标签获得焦点后可用方向键导航。',
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: theme.spacing.md,
        children: [
          GalleryComponent(
            'YumeiroTopNavigation',
            child: SizedBox(
              width: double.infinity,
              child: YumeiroTopNavigation<int>(
                value: _topTab,
                onChanged: (tab) => setState(() => _topTab = tab),
                destinations: destinations,
              ),
            ),
          ),
          GalleryComponent(
            'YumeiroTopNavigation.paged',
            child: SizedBox(
              height: 150,
              width: double.infinity,
              child: YumeiroTopNavigation.paged<int>(
                value: controller.topNavTab,
                onChanged: controller.setTopNavTab,
                destinations: destinations,
                between: SizedBox(height: theme.spacing.sm),
                itemBuilder: pageBody,
              ),
            ),
          ),
          GalleryComponent(
            'YumeiroNavigationPager',
            child: SizedBox(
              height: 80,
              child: YumeiroNavigationPager<int>(
                value: _pagerPage,
                values: pageValues,
                onChanged: changePagerPage,
                itemBuilder: (context, value) => YumeiroCard.panel(
                  role: YumeiroSurfaceRole.inset,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(gSample(context, 'Example ${value + 1}')),
                  ),
                ),
              ),
            ),
          ),
          for (final variant in [
            if (!isTouch) YumeiroPaginationVariant.numbered,
            YumeiroPaginationVariant.compact,
          ])
            GalleryComponent(
              'YumeiroPagination(variant: ${variant.name})',
              child: YumeiroPagination(
                pageIndex: _pagerPage,
                pageCount: pageValues.length,
                onChanged: changePagerPage,
                variant: variant,
              ),
            ),
        ],
      ),
    );
  }

  Widget _containers(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final cardSelected = controller.previewCardSelected;
    final cardHintStyle = theme.typography.supporting.copyWith(
      color: theme.muted,
    );
    return GalleryCard.example(
      example: GalleryExample.containers,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: theme.spacing.md,
        children: [
          Wrap(
            spacing: theme.spacing.md,
            runSpacing: theme.spacing.md,
            children: [
              SizedBox(
                width: 240,
                child: GalleryComponent(
                  'YumeiroCard.panel',
                  child: YumeiroCard.panel(
                    role: YumeiroSurfaceRole.inset,
                    child: Text(gSample(context, 'Example A')),
                  ),
                ),
              ),
              SizedBox(
                width: 240,
                child: GalleryComponent(
                  'YumeiroCard',
                  child: Semantics(
                    selected: cardSelected,
                    child: YumeiroCard(
                      selected: cardSelected,
                      onTap: () =>
                          controller.setPreviewCardSelected(!cardSelected),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: theme.spacing.xs,
                        children: [
                          YumeiroTextStyle(
                            style: theme.typography.title,
                            child: Text(
                              gText(context, en: 'Sample card', zh: '示例卡片'),
                            ),
                          ),
                          IndexedStack(
                            index: cardSelected ? 1 : 0,
                            alignment: AlignmentDirectional.centerStart,
                            children: [
                              Text(
                                gText(
                                  context,
                                  en: 'Tap to toggle selection',
                                  zh: '点击切换选中态',
                                ),
                                style: cardHintStyle,
                              ),
                              YumeiroTextStyle(
                                style: theme.typography.supporting,
                                child: Text(
                                  gText(
                                    context,
                                    en: 'Selected · Tap to deselect',
                                    zh: '已选中 · 点击取消',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const GalleryComponent('YumeiroDivider', child: YumeiroDivider()),
        ],
      ),
    );
  }

  Widget _disclosure(BuildContext context) {
    final spacing = YumeiroTheme.of(context).spacing;

    Widget draftField(String key) => Padding(
      padding: EdgeInsets.all(spacing.sm),
      child: YumeiroTextField(
        key: ValueKey(key),
        initialValue: gSample(context, 'Example A'),
        semanticLabel: gText(context, en: 'Draft', zh: '草稿'),
      ),
    );

    return GalleryCard.example(
      example: GalleryExample.disclosure,
      description: gText(
        context,
        en: 'Edit the draft, fold the section, then open it again.',
        zh: '编辑草稿后，折叠再展开，比较输入状态。',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: spacing.md,
        children: [
          GalleryComponent(
            'YumeiroDisclosure',
            child: YumeiroDisclosure(
              key: const ValueKey('gallery-disclosure'),
              title: Text(gText(context, en: 'Keep draft', zh: '保留草稿')),
              expanded: _disclosureExpanded,
              onChanged: (value) => setState(() => _disclosureExpanded = value),
              child: draftField('gallery-kept-draft'),
            ),
          ),
          GalleryComponent(
            'YumeiroDisclosure(maintainState: false)',
            child: YumeiroDisclosure(
              title: Text(gText(context, en: 'Reset draft', zh: '重置草稿')),
              expanded: _resetDisclosureExpanded,
              onChanged: (value) =>
                  setState(() => _resetDisclosureExpanded = value),
              maintainState: false,
              child: draftField('gallery-reset-draft'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionGroups(BuildContext context, {required bool isTouch}) {
    final theme = YumeiroTheme.of(context);
    return GalleryCard.example(
      example: GalleryExample.actionGroups,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: theme.spacing.md,
        children: [
          GalleryComponent(
            'YumeiroActionRow',
            child: YumeiroActionRow(
              leading: Text(
                gSample(context, 'Example A'),
                style: theme.typography.title,
              ),
              actions: [
                YumeiroButton(
                  label: gText(context, en: 'Action A', zh: '操作 A'),
                  variant: YumeiroButtonVariant.secondary,
                  onPressed: () => _showMessage(context),
                ),
                YumeiroButton(
                  label: gText(context, en: 'Action B', zh: '操作 B'),
                  variant: YumeiroButtonVariant.primary,
                  onPressed: () => _showMessage(context),
                ),
              ],
            ),
          ),
          if (isTouch)
            GalleryComponent(
              'YumeiroActionBar',
              child: YumeiroActionBar(
                primaryAction: YumeiroButton(
                  label: gText(context, en: 'Action A', zh: '操作 A'),
                  variant: YumeiroButtonVariant.primary,
                  onPressed: () => _showMessage(context),
                ),
                secondaryActions: [
                  YumeiroButton(
                    label: gText(context, en: 'Action B', zh: '操作 B'),
                    variant: YumeiroButtonVariant.ghost,
                    onPressed: () => _showMessage(context),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _settingsRows(BuildContext context) {
    final spacing = YumeiroTheme.of(context).spacing;
    return GalleryExampleScope.anchor(
      context,
      GalleryExample.settingsRows,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: spacing.md,
        children: [
          GalleryComponent(
            'YumeiroSettingsSection',
            child: YumeiroSettingsSection(
              title: gText(
                context,
                en: GalleryExample.settingsRows.en,
                zh: GalleryExample.settingsRows.zh,
              ),
              children: [
                GalleryComponent(
                  'YumeiroSettingRow(trailing: …)',
                  child: YumeiroSettingRow(
                    leading: const Icon(Icons.tune_rounded),
                    title: gText(context, en: 'Sample option', zh: '示例选项'),
                    trailing: YumeiroSwitch(
                      value: controller.layoutSwitchValue,
                      onChanged: controller.setLayoutSwitchValue,
                    ),
                  ),
                ),
                GalleryComponent(
                  'YumeiroSettingRow(editor: …)',
                  child: YumeiroSettingRow(
                    title: gSample(context, 'Example B'),
                    editorMaxWidth: 300,
                    editor: YumeiroTextField(
                      key: const ValueKey('gallery-setting-editor'),
                      initialValue: gSample(context, 'Example C'),
                    ),
                  ),
                ),
                GalleryComponent(
                  'YumeiroListTile',
                  child: YumeiroListTile(
                    leading: const Icon(Icons.palette_rounded),
                    title: Text(gSample(context, 'Sample item 01')),
                    subtitle: Text(
                      gText(context, en: 'Description A', zh: '说明 A'),
                    ),
                    onTap: () => _showMessage(
                      context,
                      en: 'List tile tapped',
                      zh: '已点击列表项',
                    ),
                  ),
                ),
                GalleryComponent(
                  'YumeiroSelectionRow',
                  child: YumeiroSelectionRow(
                    key: const ValueKey('gallery-list-selection-row'),
                    title: Text(gSample(context, 'Option A')),
                    selected: controller.layoutSelectionValue,
                    onChanged: controller.setLayoutSelectionValue,
                  ),
                ),
                GalleryComponent(
                  'YumeiroSelectionRow(leadingCheckbox: true)',
                  child: YumeiroSelectionRow(
                    leadingCheckbox: true,
                    title: Text(gSample(context, 'Option C')),
                    selected: _leadingSelection,
                    onChanged: (value) =>
                        setState(() => _leadingSelection = value),
                  ),
                ),
                GalleryComponent(
                  'YumeiroSelectionRow(card: true)',
                  child: YumeiroSelectionRow(
                    key: const ValueKey('gallery-card-selection-row'),
                    card: true,
                    title: Text(gSample(context, 'Option B')),
                    selected: controller.checkboxRowValue,
                    onChanged: controller.setCheckboxRowValue,
                  ),
                ),
              ],
            ),
          ),
          GalleryComponent(
            'YumeiroSettingsSection.flat',
            child: YumeiroSettingsSection.flat(
              title: gText(context, en: 'Flat settings section', zh: '平铺设置分组'),
              children: [
                for (final letter in const ['A', 'B'])
                  YumeiroSettingRow(
                    title: gSample(context, 'Example $letter'),
                    trailing: Text(gSample(context, 'Option $letter')),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingSelect(BuildContext context) => GalleryCard.example(
    example: GalleryExample.settingSelect,
    child: GalleryComponent(
      'YumeiroSettingRow.select',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          YumeiroSettingRow.select<String>(
            key: const ValueKey('gallery-selection-setting'),
            title: gSample(context, 'Example A'),
            subtitle: gText(context, en: 'Short option list', zh: '选项较少'),
            value: controller.settingSelectValue,
            options: [
              for (final (value, letter) in const [
                ('auto', 'A'),
                ('pointer', 'B'),
                ('touch', 'C'),
              ])
                YumeiroSelectionOption(
                  value: value,
                  label: gSample(context, 'Option $letter'),
                ),
            ],
            onChanged: (value) {
              if (value != null) controller.setSettingSelectValue(value);
            },
          ),
          const YumeiroDivider(),
          YumeiroSettingRow.select<int>(
            key: const ValueKey('gallery-searchable-selection-setting'),
            title: gSample(context, 'Example B'),
            subtitle: gText(context, en: 'Searchable option list', zh: '可搜索选项'),
            value: _searchableSetting,
            options: [
              for (var i = 1; i <= 12; i++)
                YumeiroSelectionOption(
                  value: i,
                  label: gSample(
                    context,
                    'Option ${i.toString().padLeft(2, '0')}',
                  ),
                ),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _searchableSetting = value);
            },
          ),
        ],
      ),
    ),
  );

  Widget _summaryRows(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    return GalleryCard.example(
      example: GalleryExample.summaryRows,
      child: GalleryComponent(
        'YumeiroDataRow',
        child: Padding(
          padding: EdgeInsetsDirectional.only(start: theme.spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (index, item)
                  in GalleryController.tableItems.take(2).indexed) ...[
                if (index > 0) const YumeiroDivider(),
                YumeiroDataRow(
                  leading: Icon(theme.icons.auto),
                  title: Text(gSample(context, item.name)),
                  subtitle: Text(gSample(context, item.category)),
                  status: _statusBadge(context, item),
                  progress: YumeiroProgress(value: item.progress),
                  onTap: () =>
                      showYumeiroToast(context, gSample(context, item.name)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<GalleryRowItem> _tableResults(BuildContext context, {String? query}) {
    final search = (query ?? controller.toolbarSearchQuery)
        .trim()
        .toLowerCase();
    final results = controller.visibleTableItems.where((item) {
      if (_tableCategories.isNotEmpty &&
          !_tableCategories.contains(item.category)) {
        return false;
      }
      return [item.name, item.category, item.status].any(
        (value) =>
            value.toLowerCase().contains(search) ||
            gSample(context, value).toLowerCase().contains(search),
      );
    }).toList();
    results.sort(
      (a, b) => switch (controller.toolbarSort) {
        'Progress' => a.progress.compareTo(b.progress),
        'Status' => a.status.compareTo(b.status),
        _ => a.name.compareTo(b.name),
      },
    );
    return results;
  }

  Widget _tableToolbar(
    BuildContext context,
    List<GalleryRowItem> results,
    Set<GalleryRowItem> selectedRows,
  ) {
    final theme = YumeiroTheme.of(context);
    final hasSelection = selectedRows.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.spacing.md,
      children: [
        Builder(
          builder: (toolbarContext) => GalleryComponent(
            'YumeiroSearchToolbar(onFilter: …)',
            child: YumeiroSearchToolbar(
              query: controller.toolbarSearchQuery,
              onQueryChanged: (value) => controller.setToolbarSearchQuery(
                value,
                visibleItems: _tableResults(context, query: value),
              ),
              onFilter: () => _openTableFilters(toolbarContext),
              filterCount: _tableCategories.length,
              onSort: controller.cycleToolbarSort,
              onMore: () => _openTableActions(toolbarContext),
            ),
          ),
        ),
        if (_tableCategories.isNotEmpty)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: YumeiroBadge(
              label: YumeiroLocalizations.of(context)
                  .filterWithCount(_tableCategories.length),
            ),
          ),
        if (_selectionMode == YumeiroTableSelectionMode.multiple)
          GalleryComponent(
            'YumeiroSelectionToolbar',
            child: YumeiroSelectionToolbar(
              selectedCount: selectedRows.length,
              onClose: hasSelection
                  ? () => controller.setSelectedRows(const {})
                  : null,
              onSelectAll: results.isEmpty
                  ? null
                  : () => controller.setSelectedRows(results.toSet()),
              actions: [
                YumeiroButton(
                  label: gText(context, en: 'Remove selected', zh: '移除所选'),
                  variant: YumeiroButtonVariant.danger,
                  onPressed: hasSelection
                      ? () => controller.removeTableRows(selectedRows)
                      : null,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _openTableFilters(BuildContext context) async {
    final result = await YumeiroFilter.show<Set<String>>(
      context: context,
      title: gText(context, en: 'Filter categories', zh: '按分类筛选'),
      initialValue: _tableCategories,
      resetValue: const {},
      builder: (context, draft, onChanged) => YumeiroSelectionList<String>(
        options: [
          for (final category
              in GalleryController.tableItems
                  .map((item) => item.category)
                  .toSet())
            YumeiroSelectionOption(
              value: category,
              label: gSample(context, category),
            ),
        ],
        values: draft,
        multiple: true,
        scrollable: false,
        onChanged: onChanged,
      ),
    );
    if (!mounted || result == null) return;
    setState(() => _tableCategories = result);
    controller.setSelectedRows(
      controller.selectedRows.intersection(_tableResults(this.context).toSet()),
    );
  }

  void _openTableActions(BuildContext context) {
    final box = context.findRenderObject()! as RenderBox;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final sortLabels = {
      'Name': gText(context, en: 'Name', zh: '名称'),
      'Progress': gText(context, en: 'Progress', zh: '进度'),
      'Status': gText(context, en: 'Status', zh: '状态'),
    };
    YumeiroActionMenu.show(
      context: context,
      globalPosition: box.localToGlobal(
        rtl
            ? box.size.bottomLeft(Offset.zero)
            : box.size.bottomRight(Offset.zero),
      ),
      items: [
        YumeiroMenuHeader(
          title: gText(context, en: 'Sort by', zh: '排序字段'),
        ),
        for (final entry in sortLabels.entries)
          YumeiroMenuAction(
            label: entry.value,
            selected: controller.toolbarSort == entry.key,
            onPressed: () => controller.setToolbarSort(entry.key),
          ),
        const YumeiroMenuDivider(),
        YumeiroMenuAction(
          label: gText(context, en: 'Restore sample rows', zh: '恢复示例数据'),
          enabled: controller.hasRemovedTableRows,
          onPressed: controller.restoreTableRows,
        ),
      ],
    );
  }

  Widget _dataTable(BuildContext context, {required bool isTouch}) {
    final theme = YumeiroTheme.of(context);
    final results = _tableResults(context);
    final selectedRows = controller.selectedRows.intersection(results.toSet());
    final mode = _selectionMode;
    final showTableColumns = isTouch && _showTableColumns;

    return GalleryCard.example(
      example: GalleryExample.dataTable,
      key: const ValueKey('sample-data-table'),
      description: isTouch
          ? gText(
              context,
              en: 'Long-press a row for its actions.',
              zh: '长按行可打开该行的操作。',
            )
          : gText(
              context,
              en: 'Right-click a row for its actions.',
              zh: '右键单击行可打开该行的操作。',
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: theme.spacing.md,
        children: [
          if (isTouch)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: YumeiroSegmentedControl<bool>(
                key: const ValueKey('gallery-table-layout'),
                value: _showTableColumns,
                options: [
                  YumeiroSegmentOption(
                    value: false,
                    label: gText(context, en: 'Summary rows', zh: '摘要行'),
                  ),
                  YumeiroSegmentOption(
                    value: true,
                    label: gText(context, en: 'Scrollable columns', zh: '横向表格'),
                  ),
                ],
                onChanged: (value) => setState(() => _showTableColumns = value),
              ),
            ),
          if (showTableColumns)
            Text(
              gText(
                context,
                en: 'Swipe left to see the remaining columns.',
                zh: '向左滑动可查看其余列。',
              ),
              style: theme.typography.supporting.copyWith(color: theme.muted),
            ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: YumeiroSegmentedControl<YumeiroTableSelectionMode?>(
              key: const ValueKey('gallery-table-selection-mode'),
              value: mode,
              options: [
                YumeiroSegmentOption(
                  value: null,
                  label: gText(context, en: 'Browse', zh: '浏览'),
                ),
                YumeiroSegmentOption(
                  value: YumeiroTableSelectionMode.single,
                  label: gText(context, en: 'Single', zh: '单选'),
                ),
                YumeiroSegmentOption(
                  value: YumeiroTableSelectionMode.multiple,
                  label: gText(context, en: 'Multiple', zh: '多选'),
                ),
              ],
              onChanged: (next) {
                setState(() => _selectionMode = next);
                if (next == YumeiroTableSelectionMode.single) {
                  controller.setSelectedRows(
                    results.where(selectedRows.contains).take(1).toSet(),
                  );
                }
              },
            ),
          ),
          _tableToolbar(context, results, selectedRows),
          GalleryComponent(
            showTableColumns
                ? 'YumeiroDataTable(compactRowBuilder: null)'
                : 'YumeiroDataTable',
            child: YumeiroDataTable<GalleryRowItem>(
              items: results,
              emptyPlaceholder: YumeiroEmptyState(
                title: YumeiroLocalizations.of(context).noResults,
                compact: true,
              ),
              rowKey: (item) => ValueKey(item.id),
              rowSemanticsLabel: (item) => gSample(context, item.name),
              selection: mode == null
                  ? null
                  : YumeiroTableSelection(
                      mode: mode,
                      selectedKeys: {
                        for (final row in selectedRows) ValueKey(row.id),
                      },
                      onChanged: (keys) => controller.setSelectedRows({
                        for (final row in results)
                          if (keys.contains(ValueKey(row.id))) row,
                      }),
                    ),
              onRowTap: (item) =>
                  showYumeiroToast(context, gSample(context, item.name)),
              contextMenuBuilder: (context, item) => [
                YumeiroMenuAction(
                  icon: theme.icons.info,
                  label: gText(context, en: 'Show row details', zh: '查看行详情'),
                  onPressed: () => YumeiroDialog.show<void>(
                    context: context,
                    builder: (_) => YumeiroDialog(
                      title: gSample(context, item.name),
                      child: Text(gSample(context, item.category)),
                    ),
                  ),
                ),
                YumeiroMenuAction(
                  label: gText(context, en: 'Remove this row', zh: '移除此行'),
                  destructive: true,
                  onPressed: () => controller.removeTableRows({item}),
                ),
              ],
              compactRowBuilder: showTableColumns
                  ? null
                  : (context, item, _) => YumeiroDataRow(
                      title: Text(gSample(context, item.name)),
                      subtitle: Text(gSample(context, item.category)),
                      status: _statusBadge(context, item),
                      progress: YumeiroProgress(value: item.progress),
                      metadata: Text(
                        '${(item.progress * 100).round()}% · ★ ${item.rating}',
                      ),
                    ),
              columns: [
                YumeiroTableColumn<GalleryRowItem>(
                  title: gText(context, en: 'Name', zh: '名称'),
                  flex: 2,
                  cellBuilder: (_, item, _) => Text(
                    gSample(context, item.name),
                    style: theme.typography.control(selected: false),
                  ),
                ),
                YumeiroTableColumn<GalleryRowItem>(
                  title: gText(context, en: 'Category', zh: '分类'),
                  cellBuilder: (_, item, _) =>
                      Text(gSample(context, item.category)),
                ),
                YumeiroTableColumn<GalleryRowItem>(
                  title: gText(context, en: 'Status', zh: '状态'),
                  fixedWidth: 110,
                  cellBuilder: (_, item, _) => Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: _statusBadge(context, item),
                  ),
                ),
                YumeiroTableColumn<GalleryRowItem>(
                  title: gText(context, en: 'Progress', zh: '进度'),
                  fixedWidth: 130,
                  cellBuilder: (_, item, _) =>
                      YumeiroProgress(value: item.progress),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactTable(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    return GalleryCard.example(
      example: GalleryExample.compactTable,
      key: const ValueKey('sample-compact-table'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: theme.spacing.md,
        children: [
          Text(
            gText(context, en: 'Short tables in overlays', zh: '短表浮层'),
            style: theme.typography.title,
          ),
          const GalleryCompactTableDemo(),
          const YumeiroDivider(),
          Text(
            gText(context, en: 'Tables built on demand', zh: '惰性长表'),
            style: theme.typography.title,
          ),
          compactTableDemo(context, decorate: GalleryComponent.sample),
        ],
      ),
    );
  }

  Widget _statusBadge(BuildContext context, GalleryRowItem item) =>
      YumeiroBadge(
        label: gSample(context, item.status),
        statusRole: item.status == 'State A'
            ? YumeiroStatusRole.success
            : YumeiroStatusRole.neutral,
      );

  void _showMessage(
    BuildContext context, {
    String en = 'Example action triggered.',
    String zh = '已触发示例操作。',
  }) => showYumeiroToast(context, gText(context, en: en, zh: zh));
}
