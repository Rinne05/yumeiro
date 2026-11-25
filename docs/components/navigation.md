# 导航与切页

用同一窄屏宽度比较触控底栏和折叠的桌面侧栏，也可以试试较宽的触控导航轨与桌面侧栏。打开「标签与分页」后，可以点击顶部标签或左右滑动内容。

<ComponentDemo id="navigation" title="自适应应用导航预览" :overlay-height="470">

<<< ../../example/lib/docs/layout_demos.dart#navigation

</ComponentDemo>

## 应用导航

<ApiLink symbol="YumeiroNavigationShell" /> 接收一组 <ApiLink symbol="YumeiroNavDestination" />、当前 `selectedIndex`、`onSelectedIndex` 和页面 `body`。每个目的地包含 `id`、名称和图标，还可提供选中图标或徽标。

| 场景 | 布局 |
| --- | --- |
| 触控视口宽度小于 600 逻辑像素 | 底部导航。 |
| 更宽的触控视口 | 触控导航轨，可使用 `sidebarHeader` 与 `sidebarFooter`。 |
| 紧凑或中等宽度的指针视口 | 收起的侧栏，保留图标和徽标。 |
| 展开或宽指针视口 | 侧栏默认展开，由 `collapsed` 控制是否收起。 |

布局读取作用域的输入模式和视口宽度。切换布局时，只要 `body` 的组件类型与 `key` 一致，其页面状态和焦点就会保留。目的地少于两项时，所有布局都仅显示页面内容，忽略 `selectedIndex`。

触控导航轨在矮屏中可纵向滚动。选中高亮随目的地一起滚动，头尾区域保留在轨道的两端。导航轨与底部导航共用主题的选中指示器、悬停、按下和键盘焦点视觉。

由同一份路由或页面状态驱动 `selectedIndex` 与 `body`。回调给出目标下标，宿主可用它查询目标 ID，再更新路由和深链接。见[自适应指南](/guide/adaptive)。

## 顶部标签和分页

<ApiLink symbol="YumeiroTopNavigation" /> 用于页面内部的分类，通过 <ApiLink symbol="YumeiroTopNavigationDestination" /> 定义 `value` 和 `label`。在宿主保存当前 `value`，并用 `onChanged` 同步内容。

需要同时支持点击顶部标签和左右滑动时，使用 <ApiLink symbol="YumeiroTopNavigation.paged" />。分页顺序取自 `destinations`，页面由 `itemBuilder(context, value)` 构建。通过 `onChanged` 更新当前 `value`。把分页区域放在有高度约束的父容器中，`between` 可在标签栏与滑动内容之间放置工具栏或分隔线。

标签值应唯一，当前 `value` 应对应一个目的地。若宿主保留原值，分页器会回到当前页。重新挂载时也按宿主提供的 `value` 定位。标题太长时，顶部导航可横向滚动，并让当前项保持可见。自定义布局可将顶部标签和 <ApiLink symbol="YumeiroNavigationPager" /> 放在同一个 <ApiLink symbol="YumeiroNavigationMotionScope" /> 中，并为两者提供顺序一致的值和相同的状态回调。

## 页码分页

<ApiLink symbol="YumeiroPagination" /> 为列表、数据表和滑动页面提供页码导航。传入从零开始的 `pageIndex` 与总页数 `pageCount`，在 `onChanged` 中保存目标页。界面页码从 1 开始。传入 `onChanged: null` 可只读展示。总页数为 0 时隐藏控件，只有一页时保留页码，两侧箭头均禁用。

| <ApiLink symbol="YumeiroPaginationVariant" /> | 呈现 |
| --- | --- |
| `auto` | 默认根据控件可用宽度选择页码式或紧凑式。 |
| `numbered` | 显示可点击的页码，较长的页码序列保留首尾和当前页附近的页码，用省略号表示中间范围。 |
| `compact` | 两侧为翻页箭头，中间显示当前页与总页数。点击中间的页数可以直接跳页。 |

翻页箭头与标准图标按钮共用图标和点击区域尺寸，页码和省略号默认与它们等高。紧凑式跳页在手机上打开底部面板，在指针模式下打开对话框。提交时按最新的总页数校验。超出范围时保留输入和错误提示。

需要给滑动页面加上数字导航时，让 `YumeiroNavigationPager` 与分页控件共用外层状态。对于自定义类型的页面值，用 `values[pageIndex]` 找到当前页面，并在滑动回调中把页面值映射回页码。示例画廊「布局导航 → 顶部标签页与分页器」在桌面展示页码式和紧凑式，在手机上展示紧凑式。服务端请求和跨页选择见[数据表分页](./data-table#服务端分页)。

## 标题栏与自定义导航

- <ApiLink symbol="YumeiroPageHeader.compact" /> 提供单行标题、显式的 `onBack` 和操作列表。宽度不足时，操作可移动到标题下方。安全区由外层页面或面板处理。
- <ApiLink symbol="YumeiroNavigationScope" /> 可为普通页眉提供 `onBack`，后代也可通过 `maybeOf(context)` 读取。搜索入口可将 <ApiLink symbol="YumeiroSearchButton" /> 放入页眉的 `actions`。
- 用 <ApiLink symbol="YumeiroVisualSurface" /> 配合 `role: YumeiroSurfaceRole.navigation` 为自建导航添加主题表面。`visualInsets` 调整视觉内缩并保留布局中的命中范围。
- <ApiLink symbol="YumeiroPageTransition" /> 可用于路由的过渡构建器。传入主动画和可选次动画，遵循系统减少动效设置。

粘于页面底部的确认操作见[页面与容器](./layout)，搜索或批量操作见[工具栏和全局搜索](./toolbars)。
