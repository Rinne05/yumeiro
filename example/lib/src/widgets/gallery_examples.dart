import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

/// The gallery searches sample titles, API names, and related keywords.
enum GalleryExample {
  themeOptions(0, 'Customize a theme', '实时调节主题', ['YumeiroThemeOption']),
  preferences(0, 'Gallery preferences', '全局偏好配置', [
    'YumeiroDensity',
    'YumeiroLocalizations',
    'YumeiroMotionPreferences',
  ]),
  themeTokens(0, 'Active theme colors', '当前主题色彩令牌', [
    'YumeiroColorTokens',
    'categoricalPalette',
    'YumeiroThemeExtension.categoricalPalette',
  ]),
  buttons(1, 'Buttons and search', '按钮与搜索', [
    'YumeiroButton',
    'YumeiroButton(variant: primary)',
    'YumeiroButton(variant: secondary)',
    'YumeiroButton(variant: ghost)',
    'YumeiroButton(variant: danger)',
    'YumeiroButton(variant: mediaOverlay)',
    'YumeiroButton(dense: true)',
    'YumeiroButton(label: null)',
    'YumeiroSearchButton',
  ]),
  booleanControls(1, 'Switches and checkboxes', '开关与复选', [
    'YumeiroSwitch',
    'YumeiroCheckbox',
    'YumeiroCheckbox(tristate: true)',
  ]),
  numbers(1, 'Numbers and ratings', '数值与评分', [
    'YumeiroSlider',
    'YumeiroSlider(divisions: 4)',
    'YumeiroRangeSlider',
    'YumeiroSliderInput',
    'YumeiroRatingEditor',
  ]),
  textFields(1, 'Text and validation', '文本与验证', [
    'YumeiroTextField',
    'YumeiroTextField(maxLines: 4)',
    'YumeiroTextField(obscureToggle: true)',
    'YumeiroTextField.search',
    'YumeiroTextField.form',
    'YumeiroFieldLayout',
  ]),
  tokenInput(1, 'Add your own tags', '自由输入标签', ['YumeiroTokenInput']),
  chips(1, 'Choose or remove tags', '选择与移除标签', [
    'YumeiroChip',
    'YumeiroChip(onTap: …)',
    'YumeiroChip(selected: …)',
    'YumeiroChip(dense: true)',
    'YumeiroChip(onDeleted: …)',
  ]),
  inputActionGroup(1, 'Inputs with an action', '输入操作组', [
    'YumeiroInputActionGroup',
  ]),
  segments(1, 'Horizontal and vertical segments', '横向与纵向分段', [
    'YumeiroSegmentedControl',
    'YumeiroSegmentedControl.vertical',
    'YumeiroSegmentOption',
  ]),
  singleSelect(1, 'Pick one from a list', '从列表选一个', [
    'YumeiroSelect',
    'YumeiroSelect.menu',
    'YumeiroSelect.searchable',
    'YumeiroSelect.searchable(onFreeTextSubmitted: …)',
    'YumeiroSelectionOption',
  ]),
  multiSelect(
    1,
    'Choose multiple tags',
    '多选标签',
    ['YumeiroMultiSelect'],
    keywords: ['multi-select', '多选', '确认后应用'],
  ),
  cascadingSelect(1, 'Choose by hierarchy', '按层级选择', [
    'YumeiroCascadingSelect',
    'YumeiroCascadingOption',
  ]),
  remoteSelect(1, 'Search remote options', '远程搜索选择', ['YumeiroAsyncSelect']),
  selectionList(
    1,
    'Inline selection list',
    '内联选择列表',
    [
      'YumeiroSelectionList',
      'YumeiroSelectionList(multiple: true)',
      'YumeiroSelectionList(scrollable: true)',
    ],
    keywords: ['inline single choice', 'inline multi-select', '单选组', '内联多选'],
  ),
  dateTimePickers(1, 'Date, time and ranges', '日期、时间与范围', [
    'YumeiroDatePicker',
    'YumeiroTimePicker',
    'YumeiroDateRangePicker',
  ]),
  colorPicker(1, 'Edit a color', '编辑颜色', [
    'YumeiroColorPickerButton',
    'YumeiroColorPickerPreset',
  ]),
  formControls(
    1,
    'Form controls',
    '表单控件',
    [
      'YumeiroSelect.form',
      'YumeiroSelect.form(searchable: true)',
      'YumeiroAsyncSelect.form',
      'YumeiroMultiSelect.form',
      'YumeiroSelectionList.form',
      'YumeiroSelectionList.multiForm',
      'YumeiroCheckbox.form',
      'YumeiroSwitch.form',
      'YumeiroDatePicker.form',
      'YumeiroTimePicker.form',
      'YumeiroDateRangePicker.form',
    ],
    keywords: ['form', 'form controls', 'form-controls', '表单', '表单控件'],
  ),
  badges(2, 'Badges', '徽章', [
    'YumeiroBadge',
    'YumeiroBadge(dense: true)',
    'YumeiroBadge(emphasized: true)',
  ]),
  metrics(2, 'Read-only information', '只读信息与指标', [
    'YumeiroStatTile',
    'YumeiroMetricPill',
    'YumeiroMetricPill(items: …)',
    'YumeiroFieldLayout.readOnly',
  ]),
  callouts(2, 'Persistent messages', '持续提示', [
    'YumeiroCallout',
    'YumeiroCallout(action: …)',
  ]),
  loading(2, 'Loading and progress', '加载与进度', [
    'YumeiroSpinner',
    'YumeiroSpinner(label: …)',
    'YumeiroLoadingCard',
    'YumeiroProgress',
    'YumeiroProgress(value: null)',
  ]),
  emptyStates(2, 'Empty and failed requests', '空内容与请求失败', [
    'YumeiroEmptyState',
    'YumeiroEmptyState(compact: true)',
    'YumeiroErrorState',
  ]),
  artwork(2, 'Artwork and result rows', '图片与媒体结果行', [
    'YumeiroArtworkImage',
    'YumeiroArtworkImage.thumbnail',
    'YumeiroAvatar',
    'YumeiroListTile.media',
    'YumeiroStarRating',
  ]),
  posters(2, 'Poster gallery', '海报网格', [
    'YumeiroPosterGrid',
    'YumeiroPosterGrid(shrinkWrap: true)',
    'YumeiroPosterGrid(shrinkWrap: false)',
    'YumeiroPosterGrid.sliver',
    'YumeiroMediaCard',
    'YumeiroBadge.overlay',
    'YumeiroMediaPlayButton',
    'YumeiroMediaPlayButton(active: false)',
  ]),
  pageHeaders(3, 'Page and section headers', '页眉与分区标题', [
    'YumeiroPageHeader',
    'YumeiroPageHeader.compact',
    'YumeiroSectionHeader',
    'YumeiroNavigationScope',
  ]),
  navigationShell(3, 'Adaptive navigation', '自适应导航', [
    'YumeiroNavigationShell',
    'YumeiroNavDestination',
  ]),
  pageScaffold(3, 'Page with a scrolling list', '带滚动列表的页面骨架', [
    'YumeiroPageScaffold',
    'YumeiroScrollView',
    'YumeiroScrollView.list',
  ]),
  containers(3, 'Cards and dividers', '卡片与分隔线', [
    'YumeiroCard.panel',
    'YumeiroCard',
    'YumeiroDivider',
  ]),
  disclosure(3, 'Expand and collapse', '展开与收起', [
    'YumeiroDisclosure',
    'YumeiroDisclosure(maintainState: false)',
  ]),
  settingsRows(3, 'Rows in a settings section', '设置分组里的列表行', [
    'YumeiroSettingsSection',
    'YumeiroSettingsSection.flat',
    'YumeiroSettingRow',
    'YumeiroSettingRow(trailing: …)',
    'YumeiroSettingRow(editor: …)',
    'YumeiroListTile',
    'YumeiroSelectionRow',
    'YumeiroSelectionRow(leadingCheckbox: true)',
    'YumeiroSelectionRow(card: true)',
  ]),
  settingSelect(3, 'Choose a setting', '在设置行选择', ['YumeiroSettingRow.select']),
  actionGroups(
    3,
    'Arrange page actions',
    '排布页面操作',
    ['YumeiroActionRow'],
    touchApis: ['YumeiroActionBar'],
  ),
  dataTable(
    3,
    'Filter and select table rows',
    '筛选与批量选择',
    [
      'YumeiroDataTable',
      'YumeiroTableColumn',
      'YumeiroTableSelection',
      'YumeiroSearchToolbar',
      'YumeiroSearchToolbar(onFilter: …)',
      'YumeiroSelectionToolbar',
    ],
    keywords: ['data table', '数据表'],
    touchApis: ['YumeiroDataTable(compactRowBuilder: null)'],
  ),
  summaryRows(3, 'Stand-alone summary rows', '摘要列表', ['YumeiroDataRow']),
  compactTable(
    3,
    'Table Variants and Lazy Scrolling',
    '表格变体与惰性滚动',
    [
      'YumeiroDataTable(variant: compact)',
      'YumeiroDataTable(variant: compact, additionalColumnBands: …)',
      'YumeiroDataTable(additionalColumnBands: …)',
      'YumeiroDataTable.sliver',
      'YumeiroDataTable.sliver(additionalColumnBands: …)',
      'YumeiroDataTable.sliver(variant: compact)',
      'YumeiroDataTable.sliver(variant: compact, additionalColumnBands: …)',
    ],
    keywords: [
      'compact table',
      'compact-table',
      '紧凑表',
      '紧凑表格',
      '无表头紧凑表',
      '惰性长表',
    ],
    touchApis: ['YumeiroDataTable(variant: compact, compactRowBuilder: …)'],
  ),
  tablePagination(
    3,
    'Server-Side Pagination',
    '服务端分页',
    ['YumeiroDataTable', 'YumeiroTableSelection', 'YumeiroPagination'],
    keywords: ['data-table-pagination', '数据表分页'],
  ),
  pageNavigation(
    3,
    'Top tabs and pager',
    '顶部标签页与分页器',
    [
      'YumeiroTopNavigation',
      'YumeiroTopNavigation.paged',
      'YumeiroNavigationPager',
      'YumeiroPagination(variant: compact)',
    ],
    pointerApis: ['YumeiroPagination(variant: numbered)'],
    keywords: [
      'YumeiroTopNavigationDestination',
      'YumeiroPagination',
      '页码',
      '跳页',
      'YumeiroNavigationMotionScope',
    ],
  ),
  dialogs(4, 'Dialogs and editors', '对话框与编辑器', [
    'YumeiroDialog',
    'YumeiroDialog.show',
    'YumeiroDialog.confirm',
    'YumeiroDialog.confirm(destructive: true)',
    'YumeiroEditor',
    'YumeiroEditor.show',
  ]),
  bottomSheet(4, 'Basic bottom sheet', '基础底部面板', [
    'YumeiroBottomSheet',
    'YumeiroBottomSheet.show',
  ], modality: YumeiroModality.touch),
  selectionSheets(4, 'Open selection sheets', '打开选择面板', [
    'YumeiroBottomSheet.select',
    'YumeiroBottomSheet.multiSelect',
  ], modality: YumeiroModality.touch),
  menus(
    4,
    'Actions on an item',
    '对同一条目执行操作',
    [
      'YumeiroContextMenuRegion',
      'YumeiroActionMenu.show',
      'YumeiroMenuAction',
      'YumeiroMenuHeader',
      'YumeiroMenuDivider',
    ],
    keywords: ['action menu', '动作菜单', '右键菜单'],
  ),
  compoundFilter(4, 'Combine filters', '组合筛选', [
    'YumeiroFilter.show',
    'YumeiroCascadingSelection',
  ]),
  toasts(
    4,
    'Notifications',
    '通知',
    [
      'YumeiroToast',
      'YumeiroToastHost',
      'showYumeiroToast',
      'YumeiroToastController.show(duration: Duration.zero)',
    ],
    keywords: ['toast', 'short notifications', '短时通知', '常驻通知'],
  ),
  tooltip(
    4,
    'Tooltip',
    '提示气泡',
    ['YumeiroTooltip'],
    touchApis: ['YumeiroTooltip(triggerMode: tap)'],
  ),
  detailRoute(4, 'Open a detail page', '打开详情页', [
    'YumeiroPageScaffold.detail',
    'YumeiroPageTransition',
  ], modality: YumeiroModality.touch);

  const GalleryExample(
    this.pageIndex,
    this.en,
    this.zh,
    this.apis, {
    this.keywords = const [],
    this.pointerApis = const [],
    this.touchApis = const [],
    this.modality,
  });

  final int pageIndex;
  final String en;
  final String zh;
  final List<String> apis;
  final List<String> keywords;
  final List<String> pointerApis;
  final List<String> touchApis;
  final YumeiroModality? modality;

  Iterable<String> apisFor(YumeiroModality modality) => [
    ...apis,
    ...(modality == YumeiroModality.touch ? touchApis : pointerApis),
  ];

  static GalleryExample? find(String term, YumeiroModality modality) {
    for (final example in values) {
      if (example.modality != null && example.modality != modality) continue;
      if ([
        example.en,
        example.zh,
        ...example.apisFor(modality),
        ...example.keywords,
      ].any((name) => name.toLowerCase() == term)) {
        return example;
      }
    }
    return null;
  }
}

class GalleryExampleScope extends InheritedWidget {
  const GalleryExampleScope({
    super.key,
    required this.anchors,
    required super.child,
  });

  final Map<GalleryExample, GlobalKey> anchors;

  static Widget anchor(
    BuildContext context,
    GalleryExample example,
    Widget child,
  ) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<GalleryExampleScope>();
    final key = scope?.anchors[example];
    return key == null ? child : KeyedSubtree(key: key, child: child);
  }

  @override
  bool updateShouldNotify(GalleryExampleScope oldWidget) =>
      anchors != oldWidget.anchors;
}
