# 通知

用 <ApiLink symbol="showYumeiroToast" /> 反馈保存成功、操作失败或可恢复提醒。通知会按预设时长结束，适合无需阻塞页面的操作反馈。需要持续可见的内容时用[内联提示](./display#提示和指标)。

<ComponentDemo id="toasts" title="自动和手动关闭通知预览" :overlay-height="300" input-modes compact-touch>

<<< ../../example/lib/docs/overlays_demos.dart#toasts

</ComponentDemo>

```dart
showYumeiroToast(
  context,
  '更改已保存',
  statusRole: YumeiroStatusRole.success,
  copyOnTap: false,
);
```

用 `statusRole` 设置通知的 <ApiLink symbol="YumeiroStatusRole" />，可以使用内置角色或应用注册的主题角色。通知还支持标题、图标和自定义 `duration`。默认允许点击复制，可通过 `copyText` 控制复制内容，或通过 `copyOnTap: false` 关闭复制。`onTap` 可以处理通知的点击。

点击时先调用 `onTap`，随后按 `copyOnTap` 决定是否复制。未传 `copyText` 时，默认复制标题和正文。剪贴板写入成功后才显示「已复制」。在通知上提供打开详情等操作时，可以关闭复制，让一次点击只执行该动作。

## 宿主与队列

<ApiLink symbol="YumeiroToastHost" /> 渲染队列，并提供 <ApiLink symbol="YumeiroToastScope" />。从其子树中的上下文调用展示函数。没有作用域时，展示函数可使用当前的 `ScaffoldMessenger` 显示简化通知。

通知全部退场后，局部宿主的尺寸由 `child` 和父级约束决定。

简化通知也使用 Yumeiro 的通知表面和状态色。需要复制、点击操作或撤销指定通知时，用通知宿主中可访问的上下文。

需要按标识符撤销通知时，使用 <ApiLink symbol="YumeiroToastController" />。用 `show()` 得到编号，用 `dismiss(id)` 关闭。控制器最多保留四条活动通知，通过 <ApiLink symbol="YumeiroToastEntry" /> 表示队列内容。自建控制器时由调用方释放它。

托管通知的 `duration` 默认是三秒。传入 `Duration.zero` 可关闭自动计时，再用卡片上的关闭按钮或 `dismiss(id)` 手动关闭。系统启用无障碍导航时，可点击复制或绑定了 `onTap` 的通知暂停自动关闭，退出无障碍导航后恢复计时。

### 触控模式

触控模式以单张卡片显示队列中最新的通知，后方最多露出两层卡片边缘。卡片边缘提示还有通知待展示，点击、关闭、键盘和读屏操作均作用于当前卡片。

控制器仅连接触控宿主时，限时通知在前景计时，退到后方暂停，再次显示时至少保留 1.5 秒。满四条后，优先移除最早的普通限时通知。常驻通知、`onTap` 通知以及使用 `warning` 或 `danger`（含回退至这两个角色）的通知有保留优先级，全部都有优先级时移除最早的一条。控制器同时连接指针宿主时，采用指针模式的计时和移除规则。

通知默认在底部居中，避开安全区、可见的 `YumeiroNavigationShell` 底部导航栏和软键盘。局部宿主按与底部遮挡相交的范围留出空间。设置 `YumeiroToastHost.alignment` 可自行定位，仍会避开安全区和软键盘。导航栏避让随默认定位启用。底部卡片上移淡入、下移淡出，顶部卡片的位移方向相反。系统启用减弱动态效果时，通知直接切换。

在上方预览切换到触控模式，先显示常驻通知，再显示成功通知。成功通知结束或手动关闭后，常驻通知会回到前方。画廊的「浮层路由 → 通知」也可以试用这组操作。

### 指针模式

通知默认在右上角依次排列，从右侧滑入和退出。通知超出可用高度时可以滚动，键盘焦点会将对应的通知滚动到可见范围。限时通知各自计时，队列满后按加入顺序移除最早项。退出无障碍导航后，仍在队列中的操作类通知会重新开始计时。

<ApiLink symbol="YumeiroToast" /> 是可单独嵌入的通知视图，队列和显示时长由宿主或外层逻辑控制。可在[浮层预览](./dialogs)试用通知。
