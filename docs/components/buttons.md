# 按钮

<ApiLink symbol="YumeiroButton" /> 表示一次明确的操作。纯图标操作传入 `icon` 和 `tooltip` 即可。需要低权重外观时，设置 `variant: YumeiroButtonVariant.ghost`。

点击「收藏」切换选中态。保存后可以重置。「播放预告」展示有色背景上的 `mediaOverlay` 变体。

<ComponentDemo id="buttons" title="按钮交互预览" :overlay-height="180">

<<< ../../example/lib/docs/demos.dart#buttons

</ComponentDemo>

## 选择变体

| 变体 | 用法 |
| --- | --- |
| `primary` | 当前区域的主要操作，例如保存或继续。 |
| `neutral` | 常规操作，也是文字按钮的默认变体。 |
| `secondary` | 次要操作或同等级操作组，例如同一行的查看与编辑入口。 |
| `danger` | 删除、移除或其他破坏性操作。 |
| `ghost` | 低权重操作，例如用于关闭面板的纯图标按钮。 |
| `mediaOverlay` | 放在图片、封面或视频上方的高对比操作。 |

## 内容和状态

- 至少提供 `label`、`icon` 或 `customLeading` 中的一项。需要在正文后面放图标时，使用 `trailingIcon`。
- `onPressed: null` 禁用操作。`selected` 由调用方维护，可用于有保持状态的操作。`badge` 显示提示圆点，复古像素主题使用阶梯式轮廓。
- `dense` 使用紧凑样式，`expand` 可让按钮填充可用宽度。列表或工具栏中的按钮应与区域的触控密度一起检查。
- 纯图标按钮需要提供操作名称，例如 `tooltip: '移除任务'`。按钮会在键盘聚焦或悬停时显示提示。只需要读屏名称时可传 `semanticLabel`，两者都提供时优先用 `semanticLabel` 命名。外部 `focusNode` 由创建者释放。

## 定制外观

按钮先读取最近的 `YumeiroVisualScope.controlRole`，再读取自身的 `controlRole`，最后才从 `variant` 推导角色。媒体封面上的一组操作可在外层统一指定高对比角色。在按钮上直接传入 `visualOverride` 时，它优先于作用域中的覆盖。

用 `selected` 显示外部状态，例如「已收藏」。按下只调用 `onPressed`，宿主在更新收藏数据后重新传入 `selected`。需要明确的开关语义或互斥选项时，见[选择控件](./selection)。

完整变体见 <ApiLink symbol="YumeiroButtonVariant" />。自定义角色见[主题指南](/guide/theming)。
