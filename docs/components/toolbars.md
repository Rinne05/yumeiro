# 工具栏和全局搜索

输入「蓝色」过滤列表，再用批量工具栏选中当前结果。清空关键词后可查看选择状态在过滤前后的变化。

底部的全局搜索按钮会打开独立的搜索面板。切换到触控预览可体验底部抽屉。提交查询后可以比较它与列表过滤各自保留的关键词。

<ComponentDemo id="toolbars" title="列表搜索、批量选择与全局搜索预览" :overlay-height="430" input-modes compact-touch>

<<< ../../example/lib/docs/controls_demos.dart#toolbars

</ComponentDemo>

## 当前列表的搜索

<ApiLink symbol="YumeiroSearchToolbar" /> 将搜索框与筛选、排序和更多操作组合。空间不足时，搜索框占满首行，操作按钮排到下一行。`onQueryChanged` 适合实时过滤，`onSubmitted` 适合按回车后查询。相应的 `onFilter`、`onSort`、`onMore` 存在时才显示操作按钮。`filterCount` 大于零时，高亮筛选按钮并在提示中显示数量。

通过 `query` 同步外部关键词，或通过 `controller` 使用调用方的 `TextEditingController`。调用方负责释放自己创建的控制器。两项都省略时，工具栏从空文本开始。仅需一项搜索输入时，也可使用[搜索框](./inputs#字段布局和搜索)。

远程搜索时可在宿主决定何时发请求，例如防抖处理 `onQueryChanged`，或只在 `onSubmitted` 后查询。加载期间增减工具栏操作会保留搜索框的文字和焦点。清除按钮会通过 `onQueryChanged('')` 通知宿主，可以用这个事件恢复未过滤的结果。

## 批量选择工具栏

<ApiLink symbol="YumeiroSelectionToolbar" /> 显示当前选择数，提供 `onClose`、`onSelectAll` 和自定义 `actions`。提供 `onClose` 时，计数旁的关闭按钮请求退出选择模式。空间充足时，计数和操作位于同一行，自定义操作接在「全选」后。可用宽度不足时，操作会换行。绑定范围、过滤条件和选择集合由宿主维护，例如把「全选」限定为[数据表](./data-table)当前展示的可选项。

## 通过快捷键发起搜索

<ApiLink symbol="YumeiroSearchScope" /> 记录当前页的 `query`、`placeholder` 和 `onSubmitted`。在其子树放入 <ApiLink symbol="YumeiroSearchButton" />，点击后会打开搜索面板。手机使用底部面板，指针模式使用对话框。
搜索按钮默认使用 `YumeiroButtonVariant.neutral`，与标题栏的轻量图标并排时可传入 `variant: YumeiroButtonVariant.ghost`。

当应用壳保留多个页面时，在壳外包上 <ApiLink symbol="YumeiroSearchHost" />。按 `Ctrl+F`（macOS 使用 `⌘F`）时优先搜索当前获焦区域，焦点在搜索作用域之外时使用当前可用页面。只有一个页面时，搜索作用域本身也能处理这个快捷键。

保活页面使用 `YumeiroSearchScope.enabled` 表示当前页面能否发起搜索和接收结果。禁用期间确认已打开的搜索面板时，结果会被丢弃。宿主还会检查路由是否在前台及动画作用域是否启用。在同一页面重复触发快捷键时，已打开的搜索面板会继续使用。

```dart
YumeiroSearchHost(
  child: YumeiroSearchScope(
    query: query,
    placeholder: '搜索文档',
    onSubmitted: (next) => setState(() => query = next),
    child: const YumeiroSearchButton(),
  ),
)
```
