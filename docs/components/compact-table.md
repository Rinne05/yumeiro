# 数据表紧凑变体

给 <ApiLink symbol="YumeiroDataTable" /> 传入 `variant: YumeiroTableVariant.compact`，可以在弹窗、面板和页面内嵌一组需要跨行对齐的记录。紧凑变体默认隐藏表头，由外层提供表面。下方示例用同一批数据展示标准和紧凑外观。

<ComponentDemo id="compact-table" title="标准与紧凑表格的布局、选择与惰性滚动" :overlay-height="600" input-modes compact-touch>

<<< ../../example/lib/docs/layout_demos.dart#compact-table

</ComponentDemo>

## 安排列与操作

| 列组 | 位置与用途 |
| --- | --- |
| `columns` | 正文第一排。全横排布局可以把正文各列都放在这里。 |
| `additionalColumnBands` | 依次追加正文列组，每组占一排。适合补充字段。 |
| `trailingColumns` | 跨越全部正文排，适合状态或独立操作。 |

<ApiLink symbol="YumeiroTableColumn" /> 的 `cellBuilder(context, item, index)` 可返回任意 Widget，也可返回 `null` 留空。用 `preferredWidth` 指定可收缩的列宽，用 `fixedWidth` 指定精确宽度。设置 `title` 可以给无表头的单元格补充字段名。

普通和 Sliver 表格都向读屏提供表、行和单元格结构。纯阅读时，正文按各自字段读取。点击正文执行选择时，所有正文排共同形成一个选择区域，尾列操作仍可单独到达。

各行共用列宽。容器较窄时，表格会压缩 `preferredWidth`。如果固定列或显式设置的 `minWidth` 需要更多空间，表格可横向滚动。列组由宿主决定，可按可用宽度改变同一批字段的排布。

## 在长列表中按需构建

短列表和弹窗可使用 `YumeiroDataTable(...)`。滚动较多记录时，将 `YumeiroDataTable.sliver(...)` 放进纵向 `CustomScrollView` 的 `slivers`，两种构造方式都指定 `variant: YumeiroTableVariant.compact`。Sliver 按视口和缓存范围构建行，完整的 `items` 由宿主提供。

在上方预览中切换到「多选」，点击「查看全部」展开 120 项，在不同滚动位置勾选几行。切换为「标准」后能看到同一批选择和固定表头。点击「隐藏」后，选择计数仍包含隐藏项。

示例画廊「布局导航 → 表格变体与惰性滚动」的「短表浮层」展示了单选和带行操作的短表。桌面使用对话框展示列布局。手机使用底部面板，通过 `compactRowBuilder` 将每行内容排成摘要。需要对照多列或持续浏览的任务适合独立页面。

`items` 为空时，两个入口都居中显示与数据表触控摘要相同的空态。可用 `emptyPlaceholder` 替换它，Sliver 入口的占位内容会参与外层滚动。

## 单选与多选

宿主持有 `selectedKeys`，通过 <ApiLink symbol="YumeiroTableSelection" /> 将它与 `mode`、`onChanged` 传给表格。用稳定且唯一的 `rowKey` 标识行，例如 `ValueKey(item.id)`。`isItemEnabled` 只控制对应行的选择，尾列操作仍使用自己的启用状态。`rowSemanticsLabel` 可为选择区生成清晰的可访问名称。

选中背景覆盖正文和尾列，四周留出与[标准表](./data-table#受控选择)一致的视觉间距。紧凑变体的正文默认执行选择，尾列按钮各自响应。默认通过行背景表示选中。设置 `showSelectionIndicator: true` 可以在正文起始侧增加按整行高度居中的单选圆点或复选框。也可通过 `rowTapBehavior` 调整点击正文的动作。

| 场景 | 宿主配置 |
| --- | --- |
| 纯阅读 | 省略 `selection`。 |
| 页面暂时退出选择模式 | 保留同一批行和键，将 `selection` 设为 `null`。已保存的键可以在恢复时使用。 |
| 只读显示已选项 | 传入单选或多选模式及选中键，省略 `onChanged`。 |
| 行选择与详情按钮并存 | 在正文提供选择交互，在 `trailingColumns` 放有独立回调的详情按钮。禁用行选择后，详情按钮仍按自己的条件响应。 |

通过宿主持有的键集合决定确认按钮的可用性。示例可通过「确认选择」查看确认数量，也可清空全部选择。从多选切换回单选时保留第一个已选键。需要额外的「全选」入口时，在表格外提供按钮，由宿主明确其作用范围。

列标题、固定表头与跨页选择的示例见[数据表](./data-table)。
