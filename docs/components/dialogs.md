# 对话框和编辑器

使用「更改位置」查看对话框如何将选择结果写回调用者，用「编辑名称」试验草稿的保存与取消。切换到触控预览可看到编辑器从底部打开。

<ComponentDemo id="overlays" title="对话框、草稿编辑和通知预览" :overlay-height="460" input-modes compact-touch>

<<< ../../example/lib/docs/demos.dart#overlays

</ComponentDemo>

## 对话框与确认

通过 <ApiLink symbol="YumeiroDialog.show" /> 打开 <ApiLink symbol="YumeiroDialog" />。用 `child` 提供正文，用 `headerAccessory` 在标题区放置徽标或控件，用 `actions` 显示确认或取消入口。需要返回选择结果时，从对话框的构建上下文调用 `Navigator.of(context).pop(result)`，由调用处等待 `Future<T?>`。

- 普通二选一确认用 <ApiLink symbol="YumeiroDialog.confirm" />。可用 `message` 附加说明。只有确认返回 `true`，取消或关闭返回 `false`。删除等操作可以开启 `destructive`。
- 打开时的 `barrierDismissible` 配置点击遮罩的行为，`canDismiss` 管理对话框的返回和关闭控件。要让用户只能通过正文中的按钮处理任务，两处都要考虑。
- 对话框、模态浮层和编辑器默认由根导航器管理。从嵌套路由打开时，传入 `useRootNavigator: false` 可让最近的导航器处理返回和结果。
- 从设有局部阅读方向的子树打开浮层时，浮层正文沿用该方向。
- 触控对话框的标题区、正文和底部操作默认沿同一内容边缘对齐。可以用 `contentPadding` 调整正文的内边距。
- `showClose: false` 隐藏关闭按钮。传入 `onClose` 时，关闭按钮把处理交给该回调，由宿主决定何时结束路由。
- 通过关闭、返回或遮罩离开且未提交值时，泛型对话框返回 `null`。等待异步结果后，先检查宿主是否仍挂载，再写回状态。
- 已有滚动体时设置 `scrollable: false`。使用 <ApiLink symbol="YumeiroScrollView" /> 自建滚动内容时，可传入 `padding: YumeiroDialog.defaultContentPadding` 复用对话框的正文间距。

默认关闭按钮遵守内容里的 `PopScope` 和 `Form.canPop`，可用它们阻止关闭尚未完成的表单。需要自定义模态内容时，可以给 <ApiLink symbol="YumeiroDialog.show" /> 的构建器直接返回自己的组件。

## 编辑器

<ApiLink symbol="YumeiroEditor.show" /> 配合 <ApiLink symbol="YumeiroEditor" /> 用于创建条目或修改当前页面里的设置。指针模式使用居中对话框。触控模式使用面板，紧凑竖屏时停靠底部，宽屏或横屏时居中。需要完整页面空间的长表单或多步编辑，可以传入 `fullscreenOnTouch: true`。

```dart
Future<String?> editName(BuildContext context, String initialValue) =>
    YumeiroEditor.show<String>(
      context: context,
      fullscreenOnTouch: true,
      builder: (editorContext) => YumeiroEditor(
        title: '编辑名称',
        child: YumeiroTextField(
          initialValue: initialValue,
          semanticLabel: '名称',
          textInputAction: TextInputAction.done,
          onSubmitted: (value) => Navigator.of(editorContext).pop(value),
        ),
      ),
    );
```

- 编辑器的 `child` 用来构建表单。草稿、验证、提交和异常恢复由调用方维护。
- 独立全屏页默认使用主题画布。如果宿主在导航器外绘制统一背景，可在 `show` 上传入 `pageBackground: Colors.transparent`。直接嵌入触控页面的编辑器共用外层背景。
- 对话框和触控面板都可通过 `barrierDismissible` 配置点击遮罩是否尝试关闭。关闭按钮、返回和可点击的遮罩均遵守 `canDismiss`、`busy` 和 <ApiLink symbol="YumeiroEditor.onLeave" />。只有离开检查返回 `true` 且编辑器仍处于当前路由时，才继续关闭。通过 `onClose` 接管允许离开后的操作时，由宿主完成路由关闭。
- 在触控模式下，操作列表最后一项作为底部主要按钮。将关键操作放在最后，并在存在自定义滚动区时调整 `scrollable`。

保存按钮可先验证并等待提交，再用编辑器上下文返回已保存的值。失败时保留草稿，恢复可交互状态，并显示错误。取消时只关闭本地编辑器，宿主数据由确认结果更新。

多个筛选条件一起应用时，用 <ApiLink symbol="YumeiroFilter.show" /> 在指针模式打开筛选对话框，在触控模式打开面板。草稿和操作共用，见[组合筛选](./sheets#组合筛选)。

## 说明文字

在对话框或编辑器的 `child` 开头放置说明文字，使它随正文一起滚动。如果 `child` 自带滚动区，把说明放在该滚动区开头。简单的确认说明可以通过 `YumeiroDialog.confirm` 的 `message` 传入。
