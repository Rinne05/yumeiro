# 底部与选择面板

在桌面和手机共用页面上，选择用 <ApiLink symbol="YumeiroSelect" /> 或 <ApiLink symbol="YumeiroMultiSelect" />，动作菜单用 <ApiLink symbol="YumeiroActionMenu.show" />，多条件筛选用 <ApiLink symbol="YumeiroFilter.show" />。这些入口会按发起位置的交互模式选择浮层。切换预览的输入模式，可以比较同一组字段的锚定下拉和底部选择面板。「打开基础底部面板」在触控预览里展示自定义内容。

<ComponentDemo id="sheets" title="选择、组合筛选与基础面板预览" :overlay-height="500" input-modes compact-touch>

<<< ../../example/lib/docs/overlays_demos.dart#sheets

</ComponentDemo>

## 组合筛选

<ApiLink symbol="YumeiroFilter.show" /> 在指针模式打开对话框，在触控模式打开面板。两种模式共用同一个 `builder` 和草稿。打开时以 `initialValue` 初始化，重置将草稿替换为 `resetValue`，应用返回当前草稿，关闭返回 `null`。调用方可在收到结果后更新查询条件。

传入不可变配置，或在打开前创建一份副本。在构建器中通过回调替换整个草稿，取消时即可保留宿主原有的筛选条件。可以在预览中勾选两个条件，分别试验关闭、重置和应用。

## 显式面板

<ApiLink symbol="YumeiroBottomSheet.show" /> 将内容放进模态路由。<ApiLink symbol="YumeiroBottomSheet" /> 提供标题、滚动和操作区。触控模式在紧凑竖屏底部停靠。其余布局可用 `anchor` 放在触发位置附近，省略锚点时居中。直接给 `YumeiroBottomSheet.anchor` 传入浮层局部坐标的 `Rect`。单选、多选面板函数接收全局坐标的 `Rect`，并负责转换。

面板和筛选默认由根导航器管理。需要在标签页等嵌套路由内打开时，传入 `useRootNavigator: false`。

| 入口 | 行为 |
| --- | --- |
| <ApiLink symbol="YumeiroBottomSheet.select" /> | 点击一项后返回对应 <ApiLink symbol="YumeiroSelectionOption" /> 并关闭。可用 `value` 标出当前项。 |
| <ApiLink symbol="YumeiroBottomSheet.multiSelect" /> | 以 `values` 初始化选择草稿，确认后返回 `Set<T>`。空集合是有效的确认结果。 |

`searchable` 为选择面板启用本地名称和副标题匹配。锚点上下空间不足时，选择面板会在较宽的视口中居中。横屏键盘大幅压缩可见高度时，关闭和确认操作移到候选区旁，搜索内容仍会保留。关闭选择面板时返回 `null`。用 <ApiLink symbol="YumeiroSelectionList" /> 在自定义区域内呈现选项，通过它的回调处理选择。

单选和多选共用选项行的基础高度与文字起点。整行响应点击，较长的内容可自然撑高行。

多选初值在打开面板时拷贝为本地集合，修改草稿不会改动传入的 `values`。搜索只筛选显示项，已经选中的隐藏项留在草稿里。用结果是否为 `null` 区分取消，确认清空会返回空集合。

表单中的 `YumeiroMultiSelect` 在触控模式使用多选面板，在指针模式通过字段完成搜索和确认。 [多选标签](./selection#多选标签)

```dart
final choice = await YumeiroBottomSheet.select<int>(
  context: context,
  title: '选择分辨率',
  value: currentResolution,
  options: const [
    YumeiroSelectionOption(value: 720, label: '720p'),
    YumeiroSelectionOption(value: 1080, label: '1080p'),
  ],
);
if (!context.mounted || choice == null) return;
setState(() => currentResolution = choice.value);
```

## 自定义布局

需要在外层更新打开的面板时，可以传入 <ApiLink symbol="YumeiroSheetController" />，调用 `refresh()` 重新读取构建输入，或调用 `close()` 关闭。

同一个控制器应管理一个打开的面板。`close()` 关闭时没有提交值。用动作面板执行操作时，面板先关闭，再调用动作的 `onPressed`。如果宿主需要自行处理返回项，用单选或多选面板。

选择入口见[选择控件预览](./selection)，其他模态内容见[浮层预览](./dialogs)。
