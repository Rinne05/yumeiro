# 上下文菜单与提示

用任务菜单按钮打开操作，在指针预览里查看锚定菜单，在触控预览里查看底部动作面板。两种模式也分别支持右键和长按。选择「置顶」后再次打开，查看选中标记和禁用项。悬停或长按「下载状态」可查看提示。

<ComponentDemo id="menus" title="上下文菜单预览" :overlay-height="460" input-modes compact-touch>

<<< ../../example/lib/docs/overlays_demos.dart#menus

</ComponentDemo>

## 上下文菜单

<ApiLink symbol="YumeiroContextMenuRegion" /> 为一块内容提供右键和长按菜单。区域内的控件获得焦点后，按菜单键或 `Shift+F10` 可以打开菜单。读屏可使用「更多操作」动作。用 `menuBuilder` 按当前记录生成条目。已有按钮或手势回调时，可以直接调用 <ApiLink symbol="YumeiroActionMenu.show" />。

纯文本等内容可用 `focusable: true` 让 Tab 到达菜单区域。当内容已有可遍历的子控件时，继续从这些控件打开菜单。将区域的 `enabled` 改为 `false` 会关闭已打开的菜单，并保留内容状态。

菜单使用 <ApiLink symbol="YumeiroMenuEntry" /> 的这些条目类型。

- <ApiLink symbol="YumeiroMenuAction" /> 表示一项操作，也可以交给动作面板。操作在 `enabled` 为真且提供 `onPressed` 时可用。用 `destructive` 标记破坏性操作，用 `shortcut` 显示快捷键文本。快捷键绑定由调用方提供。
- <ApiLink symbol="YumeiroMenuHeader" /> 提供分组标题。
- <ApiLink symbol="YumeiroMenuDivider" /> 为空间关系添加可见分隔。

指针模式在锚点处打开菜单，触控模式打开[动作面板](./sheets)。两种模式都按原顺序呈现分组标题、分隔线与操作。快捷键文本显示在指针菜单中。设置 `useRootNavigator: false` 可将菜单留在当前嵌套路由的浮层中。

指针菜单和触控动作面板都在整组操作中对齐标签。动作图标位于起始侧，选中勾号位于末尾。同一项同时设置 `icon` 和 `selected: true` 时，两种标记都会显示。将可选操作的 `enabled` 设为 `false` 时，末尾用带斜线的标记表示不可选，并保留 `selected` 指定的状态。

区域的 `menuBuilder` 收到子控件坐标，适合判断点击了行内哪个区域。直接打开菜单时，可传入手势的全局坐标 `globalPosition`，也可使用触发按钮的 `context` 锚定。`title` 在两种模式中都可显示。动作权限可以在打开时从当前记录派生，禁用项仍可显示其名称。

## 提示

<ApiLink symbol="YumeiroTooltip" /> 为悬停或触控手势添加简短说明。设置 `showOnFocus: true` 可让子控件在键盘聚焦时显示提示。可以设置 `waitDuration`、`preferBelow` 和 `triggerMode`。带图标的操作可以用[按钮](./buttons)自带的 `tooltip` 参数。

参数省略时沿用 `TooltipTheme`，触控触发方式默认回退为长按。若子控件已经有独立的读屏标签，可评估是否要把同一句提示从语义中排除。

```dart
YumeiroTooltip(
  message: '已验证文件完整性',
  child: const Icon(Icons.verified_outlined),
)
```

需要用户阅读较长说明、点击链接或确认时，可用[内联提示](./display#提示和指标)或[对话框](./dialogs)。
