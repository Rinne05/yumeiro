# 选择控件

选择控件由调用方传入当前值，用户操作经由 `onChanged` 报告给调用方。根据选项数量、是否可搜索及是否有层级来选组件。

- 「下拉」提供画质单选、带状态的筛选下拉和台站搜索。试着提交已有台站、自定义名称或清空当前值。
- 「开关与分段」展示开关、三态复选、整行勾选以及横向和纵向分段。时间线选项用于展示禁用状态。
- 「级联与设置」展示分支导航、叶项提交和适应输入模式的设置选择。

<ComponentDemo id="selection" title="单选、可搜索下拉框与级联预览" :overlay-height="590" input-modes compact-touch>

<<< ../../example/lib/docs/demos.dart#selection

</ComponentDemo>

## 开关、复选框与分段

| 组件 | 用法 |
| --- | --- |
| <ApiLink symbol="YumeiroSwitch" /> | 立即切换布尔设置。用 `semanticLabel` 标明开关控制的功能。 |
| <ApiLink symbol="YumeiroCheckbox" /> | 选择独立选项。启用 `tristate` 时，`null` 表示混合态。 |
| <ApiLink symbol="YumeiroSelectionRow" /> | 用整行切换选项。`card: true` 使用独立卡片外观，`dense: true` 缩小间距。 |
| <ApiLink symbol="YumeiroSegmentedControl" /> | 少量同级值同时可见，`expand` 控制选项是否填满空间。 |
| <ApiLink symbol="YumeiroSegmentedControl.vertical" /> | 选项有副标题或自定义前导内容，需要纵向排列。 |

横向和纵向分段都使用 <ApiLink symbol="YumeiroSegmentOption" />。纵向分段在指针和触控模式都使用主题提供的分组背景和边框，还可显示 `subtitle` 和自定义前导组件 `leading`。纯图标选项应提供 `tooltip`。用选项的 `enabled` 禁用单项，用 `onChanged: null` 禁用整个控件。

三态复选框依次请求 `false → true → null → false`。用于父级「全选」时，通常由子项集合派生混合态，并根据业务规则处理下一次点击，例如直接选中当前范围内所有可选项。

## 下拉选择

| 组件 | 用法与关键参数 |
| --- | --- |
| <ApiLink symbol="YumeiroSelect" /> | 常规单选。通过 `.form()` 接入 Flutter 表单，选项较多时可启用 `searchable: true`。 |
| <ApiLink symbol="YumeiroSelect.menu" /> | 需要自定义触发内容、选中显示文本或菜单位置时使用。 |
| <ApiLink symbol="YumeiroSelect.searchable" /> | 选项较多时使用。指针端在触发输入框内搜索，触控端在面板内搜索。传入 `onFreeTextSubmitted` 可同时接收自由文本。 |
| <ApiLink symbol="YumeiroSettingRow.select" /> | 把标题、副标题和固定选项的单选入口组合成设置行。指针模式下，下拉和可搜索下拉使用同样的编辑区，超过十项时启用搜索。触控模式下点击整行打开选项面板。两种模式都只报告当前已启用选项的值。 |

单选入口都用 <ApiLink symbol="YumeiroSelectionOption" /> 提供值、名称、副标题和可选图标。常规单选和菜单通过 `onChanged` 提交选项的原始值。若「全部版本」这样的选项需要表示为 `null`，可使用 `YumeiroSelect<String?>` 或 `YumeiroSelect<String?>.menu`。取消不会调用 `onChanged`。较长的固定选项列表按需构建，打开时会定位已选项。菜单宽度可用 `menuWidth` 指定，或用 `menuAutoWidth` 根据内容测量。指针模式下，可搜索字段完全滚出视口时会收起菜单。自定义菜单触发器内容可传给 <ApiLink symbol="YumeiroSelect.menu" /> 的 `child`。

指针下拉采用统一的选项行尺寸与内边距。选项文字居中时，两侧会预留等宽的图标位置，选中标记出现后文字仍位于菜单行中央。自动测宽会将这部分空间计入。设定更窄的菜单宽度时，标签在可用空间内排布。

指针下拉与触发器的默认距离使用主题的 `spacing.xs`，内置默认值为 4 个逻辑像素。菜单上翻和下展沿用同一间距。`YumeiroSelect.menu` 的 `offset` 可显式指定位置偏移，窗口边缘可限制菜单的位置。

单选入口在指针模式打开锚定菜单，在紧凑竖屏的触控模式打开贴底面板。浮层默认使用根导航器，传入 `useRootNavigator: false` 可交由最近的导航器。用 `readOnly: true` 保留已选值和焦点，用 `enabled: false` 禁用控件。表单里需要允许用户清空单选时，使用 [`YumeiroSelect.form` 的 `clearable` 选项](./inputs#flutter-表单)。

常规单选、`YumeiroSelect.menu` 和设置行有候选项时才可打开。浮层打开后会随调用方更新选项和当前值。控件禁用、设为只读或清空候选项时会关闭浮层。

`YumeiroSelect.menu` 的默认触发文字依次读取 `displayText`、选中项的 `selectedLabelBuilder` 或标签、`placeholder`。尾部图标依次读取 `trailingIcon`、选中项的尾部图标和主题箭头。用 `showTrailingIcon: false` 隐藏触发器尾部图标。传入 `child` 可替换默认触发内容，菜单项仍使用各自标签。

### 可搜索下拉框的提交

点击选项，或在指针端的菜单打开且有可选项时按回车，会提交选项。后者采用当前高亮项。其余文本提交会去除首尾空白，再查找可用的精确匹配，匹配依据为显示文本、标签或值的字符串形式，忽略大小写。

| 结果 | 回调 |
| --- | --- |
| 选中已启用的选项或精确匹配该选项 | `onChanged(item.value)` |
| 非空文本与所有候选项均不匹配 | 提供 `onFreeTextSubmitted` 时，以该回调接收去除首尾空白后的文本 |
| 文本仅匹配禁用选项 | 保留当前值 |
| 使用清除按钮，或提交空文本时启用了清空 | `onChanged(null)` |

传入 `onChanged: null` 禁用交互。默认可提交启用的候选项，也可清空已选值。设置 `clearable: false` 禁止清空已选值。清空触控面板里的搜索框仍可恢复完整列表。`filter` 只决定候选列表，精确提交规则独立。

指针模式用勾号标出已选项，用高亮标出方向键浏览到的候选。查询无结果时，提示留在下拉内，表单里的后续字段仍在原位。可按 Tab 聚焦可见的清除按钮，再按 Enter 或空格清除。

触控面板以当前选项作为打开时的滚动位置。输入搜索词后从匹配结果的顶部浏览，清空搜索词后会重新定位已选项。横屏键盘压缩可见高度时，面板使用紧凑布局保留搜索框和候选列表。两种输入模式都可用 `emptyText` 自定义无结果提示。

已匹配的 `value` 优先于 `initialText`。默认的固定候选模式在焦点离开整个控件时恢复当前选中项。启用自由文本时，可将自定义字符串写回 `value` 以显示已提交的文字。`displayText` 可覆盖触发器在未编辑时显示的文字，候选项仍按各自的标签搜索和提交。初始化后，焦点留在输入框内时会保留正在编辑的文字。如果需要从外部替换当前输入，先结束这次编辑，再把新的选中值传给 `value`。

## 内联选择列表

<ApiLink symbol="YumeiroSelectionList" /> 将选项始终显示在页面或自定义面板里。传入 `values`，通过 `onChanged` 接收新集合。单选会替换当前选项。打开 `multiple: true` 后，每次勾选立即更新集合。用空集合表示未选，可用 `{null}` 表示选中了值为 `null` 的选项。

单选用圆圈，多选用方框。两种指示器均从行首对齐，在有两行文字时仍按整行垂直居中。单选时按 Tab 进出选项组，方向键在启用选项间切换。搜索默认隐藏，开启 `searchable` 后只过滤可见项，并保留已选择的隐藏项。选项卡片和搜索框同宽。开启 `clearable` 时，可从搜索框最右侧清空选中项，保留当前查询。没有搜索框时，清空操作位于选项卡片上方。

在已有滚动区域中设置 `scrollable: false`。在有界高度的容器中可用独立滚动按需构建选项。宿主需要在点选后关闭自定义面板时，可以用 `onSelected` 监听点击，重复点击当前单选项也会报告该选项。

<ComponentDemo id="selection-list" title="内联单选、多选与长列表预览" :overlay-height="440" input-modes compact-touch>

<<< ../../example/lib/docs/form_controls_demo.dart#selection-list

</ComponentDemo>

用 <ApiLink symbol="YumeiroSelectionList.form" /> 接入单值字段，用 <ApiLink symbol="YumeiroSelectionList.multiForm" /> 接入多选集合。可在[表单控件示例](./form-controls)中体验校验、保存与重置。

## 远程选项

<ApiLink symbol="YumeiroAsyncSelect" /> 适合从远程查询中选择一个实体，例如负责人。控件用选项对象保留当前名称，并处理防抖、空结果与重试。使用 <ApiLink symbol="YumeiroAsyncSelect.form" /> 接入表单。

## 多选标签

<ApiLink symbol="YumeiroMultiSelect" /> 使用 `Set<T>` 保存已选值，通过 `onChanged` 更新集合。开启 `searchable` 后，搜索只改变可见项。用 `clearable: true` 提供清空全部选项的操作。

指针模式在字段内输入查询，字段旁的弹层列出候选。展开后可用字段尾部的「取消」关闭。勾选改变草稿后，字段尾部显示「确认（数量）」并提供取消操作。确认后更新字段并恢复选中摘要。按 `Esc` 或点字段与弹层之外会放弃草稿。

触控模式在选择面板内搜索、勾选和确认，收起面板可放弃草稿。表单预览中的字段 C 和画廊「交互控件 → 标签 → 多选标签」均展示确认后应用的交互。

浮层打开时更新选项或已提交值，未编辑的项会跟随新值。用户的暂存勾选在对应选项仍可用时保留。表单重置会丢弃草稿。

<ComponentDemo id="multi-select" title="确认式多选预览" :overlay-height="460" input-modes compact-touch>

<<< ../../example/lib/docs/form_controls_demo.dart#multi-select

</ComponentDemo>

字段收起时按候选顺序列出已选标签，默认用逗号分隔，中文用顿号。文字超出可用宽度时以省略号截断。部分标签缺失时在末尾用 `+N` 表示其数量，全部缺失时显示选中数量。

有固定高度的选择面板按视口构建候选行，完整候选由调用方提供。用 <ApiLink symbol="YumeiroMultiSelect.form" /> 可将确认后的值接入表单。

## 级联选择

<ApiLink symbol="YumeiroCascadingSelect" /> 用在分类树、地区或目录。用 <ApiLink symbol="YumeiroCascadingOption" /> 的 `.branch` 创建分类，用默认构造器创建带值的叶项。同级 `id` 应唯一，选择叶项才提交值。指针模式以并列浮层展开已选路径。触控面板每次从第一级打开，各级会标出当前选择所在的分支，点击分支后进入下一级。

键盘可用上下方向键在同级选项间移动。展开与返回的方向键随阅读方向变化，RTL 布局中按左键展开、右键返回。

叶项 `value` 应能唯一定位一条选择路径，例如目录记录的 ID。给禁用的分类或叶项传入 `enabled: false`。整个控件传入 `onChanged: null` 时只展示当前值。

可用 <ApiLink symbol="YumeiroCascadingSelection" /> 将级联选项主体放入自定义组合。独立选择面板的扩展入口见[底部与选择面板](./sheets)。
