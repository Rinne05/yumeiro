# 页面与容器

切换完成通知，或打开「通知渠道」进入带固定底部操作的详情页。选择渠道后应用或取消，可以对照局部编辑和宿主状态。

<ComponentDemo id="layout" title="页面容器预览" :overlay-height="400">

<<< ../../example/lib/docs/page_layout_demo.dart#layout

</ComponentDemo>

## 页面结构

- <ApiLink symbol="YumeiroPageScaffold" /> 安排 `appBar`、`body` 和可选 `bottomBar`，并处理安全区。列表页可使用固定页眉，将 `YumeiroScrollView.list` 放进 `body`，省略 `bottomBar`。
- <ApiLink symbol="YumeiroPageScaffold.detail" /> 在详情中提供标题、返回、操作按钮和默认滚动区。已有滚动视图时，传入 `scrollable: false`。
- <ApiLink symbol="YumeiroPageHeader" /> 适合页面顶部，可显示说明、徽标与操作组。标题和说明在返回按钮旁共用起始边缘。
- <ApiLink symbol="YumeiroSectionHeader" /> 用于页内分区，支持小标题、说明和尾部内容。横向空间不足时，尾部内容移到标题下方。

App 级导航见[导航与切页](./navigation)，设置相关区域见[列表与设置行](./rows)。

从列表推入二级详情路由时，可在该路由外层用 <ApiLink symbol="YumeiroVisualSurface" /> 和 `YumeiroSurfaceRole.canvas` 提供主题页面背景。嵌入卡片或现有页面时，页面骨架共用外层背景。当前页面里的局部编辑可用 <ApiLink symbol="YumeiroEditor.show" />。

`YumeiroPageScaffold.detail` 默认让正文滚动。需要在已有的 `ListView` 或 `CustomScrollView` 中展示内容时，设 `scrollable: false` 给它分配正文区域。提交按钮可传入 `bottomBar`，随正文滚动时继续留在页面底部。

## 表面和排列

- <ApiLink symbol="YumeiroCard.panel" /> 用作通用内容容器，可配置 `role`、`padding`、`visualOverride` 和裁剪。
- <ApiLink symbol="YumeiroCard" /> 用作独立内容单元，可带 `onTap` 和 `selected`。
- <ApiLink symbol="YumeiroActionRow" /> 将主要内容与右侧操作区排在一起，宜给操作保留可用宽度。
- <ApiLink symbol="YumeiroDivider" /> 提供主题分隔线，支持粗细与首尾缩进。需要按输入模式调整间距时，可提供 `touchHeight`。

使用语义表面角色可以让容器跟随[主题和材质](/guide/theming)。

需要卡片本身响应点击时，给 `YumeiroCard` 提供 `onTap`。可独立点击的行内操作则提供各自的回调。用 `selected` 从宿主状态绘制选中外观。

## 滚动和提交

<ApiLink symbol="YumeiroScrollView" /> 为单个 `child` 或通过 `.list` 传入的 `children` 提供滚动区和滚动条。`padding` 在视口内，`scrollDirection` 可选水平或垂直。外部传入 `controller` 时，由创建者管理生命周期。

共用一条滚动轴的标题、内容和列表适合交给同一个滚动容器管理。用控制器跳转到条目时，先确认它已附着到该视口。使用[列式数据表](./data-table)时，外层通常负责纵向滚动，表格自行负责横向滚动。

<ApiLink symbol="YumeiroActionBar" /> 让 `primaryAction` 占满一行，`secondaryActions` 排在下面。要固定在详情底部，可以把它传给 `bottomBar`。当父对话框或面板已提供背景时，使用 `showBackground: false`。

<ApiLink symbol="YumeiroInputActionGroup" /> 将一个或多个输入与提交按钮组合。触控端的额外输入位于最后一组上方，末个输入和按钮在宽度足够时并排，空间不足时按钮移到下一行。用 `inputWidth` 调整指针端的输入宽度，用 `actionWidth` 设置按钮的最小宽度。
