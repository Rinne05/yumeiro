# 数据表

<ApiLink symbol="YumeiroDataTable" /> 在各行之间共享列宽。标准变体适合任务、记录和管理页，默认有表头及卡片底板。[紧凑变体](./compact-table)适合嵌入弹窗或宿主提供的表面。两种变体均可使用常规构造器或 `YumeiroDataTable.sliver`。

先选择「仅显示蓝色任务」再全选，最后恢复全部任务，核对被隐藏的已选项。「午后列车」禁用选择，仍可用该行的详情按钮。切换「禁选项置底」可比较行顺序。「查看触控摘要」用同一组选中键切换到 `compactRowBuilder`。

<ComponentDemo id="data-table" title="数据表选择、筛选与行内操作预览" :overlay-height="510">

<<< ../../example/lib/docs/layout_demos.dart#data-table

</ComponentDemo>

## 表头、操作和布局

- 用 <ApiLink symbol="YumeiroTableColumn" /> 定义 `title`、可替换表头的 `titleWidget` 和 `cellBuilder(context, item, index)`。指定精确的 `fixedWidth`、可收缩的 `preferredWidth`，或用 `flex` 分配剩余空间。`title` 命名语义表头，`titleWidget` 中的排序按钮保留自己的可访问名称与动作。列默认按阅读方向的起始边对齐，可用 `alignment` 和 `headerAlignment` 自定义。
- `columns` 是第一排正文列，`additionalColumnBands` 可追加多排，`trailingColumns` 跨越各排，适合独立操作。用 `showHeader` 调整变体的表头默认设置。
- `minWidth` 设置列式表格的最小内容宽度。表格会为固定列、选择列、内边距和弹性列预留空间，容器更窄时可横向滚到末列。表头和正文共用列宽和横向滚动位置。
- 行内按钮各自响应点击。用 `contextMenuBuilder` 为行提供[上下文菜单](./menus)。
- `items` 为空时居中显示内置空态，启用的表头仍会显示。通过 `emptyPlaceholder` 可以替换整个表格。宿主通过 `items` 提供筛选结果和业务排序。

行构建器的 `index` 始终是记录在当前 `items` 中的索引。用稳定的业务键把选择状态与刷新后的记录关联起来。

## 受控选择

用 <ApiLink symbol="YumeiroTableSelection" /> 管理所有表格外观与构造方式的选择。用 <ApiLink symbol="YumeiroDataTable.rowKey" /> 返回与记录身份绑定的唯一键，例如 `ValueKey(item.id)`。页面持有 <ApiLink symbol="YumeiroTableSelection.selectedKeys" />，把 `onChanged` 提供的键集写回状态，然后重新构建选择配置。

列式数据表、触控摘要和紧凑表共用选中行的主题样式。行背景四周留出半个 `spacing.xs` 的视觉间距，默认是 2 个逻辑像素。列对齐和各自的点击范围按行布局计算。

| <ApiLink symbol="YumeiroTableSelectionMode" /> | 数据表的选择方式 |
| --- | --- |
| `single` | 选择另一项时返回仅含新项的集合。再次点已选项会保留选中。 |
| `multiple` | 全选增删当前 `items` 中可选的键，保留被过滤或禁用的已选项。 |

启用 `showSelectionIndicator` 后，行首显示单选标记或复选框，标准变体默认开启。复古像素主题的单选外圈和圆点采用与滑块一致的圆角比例。启用 `showHeader` 的多选表格和触控摘要提供全选入口。

单选时，普通表与惰性表都用方向键切换可选行，跳过禁选行，并在首尾停下。切换主题预设时，已聚焦的单选控件会保持键盘焦点。

浏览数据时省略 `selection` 或传 `null`。调用方可保留选中集合，稍后恢复选择。同一布局下启停选择会保留使用稳定行键的单元格状态。

使用 `isItemEnabled` 对单项禁用选择。该行保留选择列宽，控件中心显示斜线。禁选项原本已选时，保留选中键、行高亮和标记的选中填色，标记内部仅显示斜线。整张表省略 `onChanged` 时，选择只读，各项仍显示通常的选中或未选中标记。关闭 `showSelectionIndicator` 会隐藏行首控件，正文选择依旧遵循 `isItemEnabled`。

<ApiLink symbol="YumeiroTableSelection.moveDisabledToEnd" /> 是可选的 `bool`，默认 `false`，沿用 `items` 的顺序。设为 `true` 时，表格将 `isItemEnabled` 返回 `false` 的行移到当前 `items` 的末尾，两组各自保留原顺序。省略 `isItemEnabled` 时，所有行都沿用传入顺序。只读选择也可以按 `isItemEnabled` 分组。

`cellBuilder` 和 `compactRowBuilder` 继续接收记录在传入 `items` 中的索引。重排仅作用于当前传入的记录。服务端分页时，稳定的 `rowKey` 继续关联跨页的选中键。

行的激活动作和选择控件可同时存在，通过各自的处理函数独立控制。可用 `rowSemanticsLabel` 生成读屏用的行名称。

只提供上下文菜单的纯文本行可以用 Tab 聚焦，按菜单键或 `Shift+F10` 打开菜单。行内已有焦点控件时，也可以从该控件打开行菜单。

例如 A/B/C 中已选 A 和 C，当前筛选只展示 A 和 B。点全选会补选 B，得到 A、B、C。再次全选会清除 A 和 B，保留隐藏的 C。在宿主需要「清空全部选择」时，直接在工具栏写回空集合。若按筛选清理隐藏键是业务要求，也由宿主在改变筛选条件时执行。

用 <ApiLink symbol="YumeiroTableRowTapBehavior" /> 指定点击正文的动作。`activate` 调用 `onRowTap`，由 `rowTapEnabled` 管理激活权限。`select` 执行当前选择模式，由 `isItemEnabled` 管理单项是否可选。`none` 让正文只展示内容。行首标记、尾列控件、单元格内的按钮及上下文菜单各自响应。标准变体默认采用 `activate`。

## 在长列表中按需构建

短列表可直接使用 `YumeiroDataTable(...)`。较长的列表可使用 <ApiLink symbol="YumeiroDataTable.sliver" />，将其放入有界纵向 `CustomScrollView` 的 `slivers`，表格按视口和缓存范围构建行。标准与紧凑变体都支持此入口，且可在同一个滚动视口中与其他 Sliver 组合。

启用 `moveDisabledToEnd` 时，Sliver 会对全部传入的记录检查 `isItemEnabled`，以确定显示顺序。单元格仍按需构建。

用 `pinnedHeader: true` 可以把启用的表头固定在滚动视口顶部。表头全选作用于 `items` 中全部可选记录，包括尚未进入视口的行。应用通过增减传入的 `items` 实现「查看全部」或「隐藏」，并用稳定的 `rowKey` 维护已选记录。[演示标准与紧凑长表](./compact-table#在长列表中按需构建)

## 服务端分页

在下方预览或示例画廊「布局导航 → 服务端分页」中，用 <ApiLink symbol="YumeiroPagination" /> 的页码或箭头切页。全选第一页后跳到其他页，再返回第一页查看勾选状态。搜索或切换排序会回到第一页。点击「模拟下次请求失败」后触发一次查询，可以查看「重试」如何重新请求同一页。

<ComponentDemo id="data-table-pagination" title="服务端分页、加载与跨页选择预览" :overlay-height="600" input-modes compact-touch>

<<< ../../example/lib/docs/data_table_pagination_demo.dart#data-table-pagination

</ComponentDemo>

页面保存查询词、排序方向和页码。示例中的模拟接口先筛选、排序，再返回当前页数据和总条数。宿主根据总条数和每页容量计算 `pageCount`，通过 `onChanged` 请求目标页，再把返回的记录传给表格的 `items`。可以在表格下方或工具栏中摆放[页码分页控件](./navigation#页码分页)。

每次请求生成一个序号。结果返回时只处理最新序号的成功或失败，避免较慢的旧请求覆盖新页面。可在第一页快速点击「下一页」再点「上一页」，观察较慢的第二页请求返回后仍显示第一页。加载、空结果和失败重试都由宿主处理，重试沿用当前查询。

用 `ValueKey(item.id)` 标识记录，并在页面保存完整的 `selectedKeys`。表头全选操作当前页，工具栏的「清空全部选择」操作所有页。

## 触控摘要行

用 `compactRowBuilder` 构造适合窄屏的内容，例如包含标题、副标题、状态、进度及操作的 <ApiLink symbol="YumeiroDataRow" />。选中控件和上下文操作由数据表配置。表格以外的组装方式见[列表与设置行](./rows#列表入口)。

表格为触控摘要统一提供行内边距和选择位。嵌入 `YumeiroDataRow` 时，默认直接沿用表格的边距。只有确实需要在摘要内容周围再加留白时，才设置 `contentPadding`。状态徽标在窄屏换到下一行时会按自身内容收窄。

只有当前作用域为触控模式且提供了 `compactRowBuilder`，才使用摘要行。其他情况使用列式布局，较窄时可以横向滚动。

紧凑变体的多排字段、宽度和正文选择示例见[紧凑表](./compact-table)。
