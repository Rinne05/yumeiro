# 通知

用 <ApiLink symbol="showYumeiroToast" /> 反馈保存成功、操作失败或可恢复提醒。通知会按预设时长结束，适合无需阻塞页面的操作反馈。需要持续可见的内容时用[内联提示](./display#提示和指标)。

<ComponentDemo id="toasts" title="自动和手动关闭通知预览" :overlay-height="300">

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

简化通知也使用 Yumeiro 的通知表面和状态色。需要复制、点击操作或撤销指定通知时，用通知宿主中可访问的上下文。

需要按标识符撤销通知时，使用 <ApiLink symbol="YumeiroToastController" />。用 `show()` 得到编号，用 `dismiss(id)` 关闭。控制器保留最近四条活动通知，通过 <ApiLink symbol="YumeiroToastEntry" /> 表示队列内容。自建控制器时由调用方释放它。

托管通知默认显示三秒。`Duration.zero` 会关闭自动计时。文档预览和画廊「浮层路由 → 通知」都可以试用显示与手动关闭常驻通知。系统启用无障碍导航时，可点击复制或绑定了 `onTap` 的通知会暂缓计时。退出无障碍导航后，仍在队列中的这类通知会重新开始计时。通知仍可手动关闭，队列满后也会按加入顺序移除最早项。

通知超出屏幕可用高度时可以滚动。新打开的通知区优先显示最后加入的通知，通过键盘聚焦通知也会将它滚动到可见范围。

<ApiLink symbol="YumeiroToast" /> 是可单独嵌入的通知视图，队列和显示时长由宿主或外层逻辑控制。可在[浮层预览](./dialogs)试用通知。
