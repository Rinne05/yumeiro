# 列表与设置行

<ComponentDemo id="rows" title="列表选中与设置行预览" :overlay-height="320">

<<< ../../example/lib/docs/controls_demos.dart#rows

</ComponentDemo>

## 列表入口

<ApiLink symbol="YumeiroListTile" /> 适合导航入口、列表动作或名称与摘要。可将任意 Widget 放到 `title`、`subtitle`、`leading` 或 `trailing`。用 `onTap` 提供整行动作，`enabled` 控制该动作可用性，`selected` 提供选中样式。

<ApiLink symbol="YumeiroSelectionRow" /> 适合选项列表。页面持有 `selected`，通过 `onChanged` 获取下一状态。`multiple` 区分多选和单选呈现，`leadingCheckbox` 可在多选时将选择标记放到起始侧。单排选项共用行高，选择动作由整行接收。`footer` 跟随标题和副标题的起始边，也适用于有前导标记或图标的行。

给 <ApiLink symbol="YumeiroSelectionRow" /> 设置 `card: true` 可用独立卡片外观展示选项。`dense` 缩小行内间距，复选框默认位于末尾。

选择行设置 `enabled: false` 时，标记中间的斜线表示该项不可选。多选行沿用复选框轮廓，单选行在原有标记位置显示带斜线的圆环。已选项保留选中状态和底色。`readOnly: true` 用于展示当前值，沿用普通选中标记。可交互的单选行用勾号标出选中项。带单选圆环的布局见[内联选择列表](./selection#内联选择列表)。

需要让行右侧的辅助操作拥有自己的交互时，为 `trailing` 中的控件传入独立的回调。使用 `YumeiroListTile` 做不可交互的信息行时，可以省略 `onTap`。

列表行、选择行和摘要行与表格共用高亮留白。悬停、按下和选中背景的四周默认各留 2 个逻辑像素，内容和点击目标沿用整行边界。设置分组中的分隔线画在行边缘，相邻高亮默认间隔 4 个逻辑像素。

需要状态、进度和多项行内操作时，使用 <ApiLink symbol="YumeiroDataRow" />。在页面已有的列表或 `Column` 中排列各行，按需插入 <ApiLink symbol="YumeiroDivider" />。需要多行共享列宽时，使用[数据表](./data-table)或它的[紧凑变体](./compact-table)。

## 设置项

<ApiLink symbol="YumeiroSettingRow" /> 为配置项提供标题、副标题和控制区。`trailing` 适合一个小型动作或状态，`editor` 适合长文本框、滑块和分段选择。`editorMaxWidth` 控制宽屏内联编辑器的上限，触控和空间不足时编辑器可堆叠到标题下方。

普通列表行和设置行共用标题排版和行内边距。设置选择行的触控布局可以点击整行打开选择面板。需要整行导航或执行操作时，用 `YumeiroListTile` 的 `onTap` 和 `showChevron`。

```dart
YumeiroSettingRow(
  title: '自动更新',
  subtitle: '在启动时检查可用版本',
  trailing: YumeiroSwitch(
    value: autoUpdate,
    semanticLabel: '自动更新',
    onChanged: (value) => setState(() => autoUpdate = value),
  ),
)
```

`enabled` 控制设置行标题区的外观。通过嵌入控件各自的禁用参数控制 `editor` 和 `trailing` 的交互。

同时提供 `trailing` 和 `editor` 时，前者与标题同区，后者位于下方。只有指针布局中未提供 `trailing` 时，长编辑器才会在空间足够时移到标题右侧。同一设置仍可以保持自己的控制器和校验状态。

<ApiLink symbol="YumeiroSettingsSection" /> 将相关设置行放入有标题的区块，`framed` 可控制是否使用面板表面。`.flat` 直接在外层表面上排列内容，也会省去分组内的自动分隔线。`YumeiroDivider(height: 24, touchHeight: 1)` 为指针模式留出较大行距，触控模式使用紧凑分隔线。 [分隔线 API](../components/layout#表面和排列)

设置单选入口见[选择控件](./selection)，设置内的精确数值编辑见[数值与评分](./sliders)。
