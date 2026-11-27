# 颜色选择

<ApiLink symbol="YumeiroColorPickerButton" /> 用于编辑主题、高亮或标签颜色。指针模式打开锚定的选色面板，触控模式打开模态面板。

<ComponentDemo id="color-picker" title="自定义颜色与恢复继承预览" :overlay-height="470" input-modes compact-touch theme-styles>

<<< ../../example/lib/docs/controls_demos.dart#color-picker

</ComponentDemo>

`value` 保存用户覆盖值，`null` 表示继承默认配色。`defaultColor` 决定默认色样以及编辑器在没有覆盖值时的起始色。调用方可以将 `null` 持久化为继承状态，让默认配色继续随主题变化。

```dart
YumeiroColorPickerButton(
  value: accentOverride,
  defaultColor: const Color(0xFF427C68),
  presets: const [
    YumeiroColorPickerPreset(label: '青松', color: Color(0xFF427C68)),
    YumeiroColorPickerPreset(label: '海蓝', color: Color(0xFF4166C9)),
  ],
  onChanged: (value) => setState(() => accentOverride = value),
)
```

预设色样通过 <ApiLink symbol="YumeiroColorPickerPreset" /> 提供可读名称和颜色。如果继承样式由一组颜色组成，可用 `showDefaultSwatch: false` 只显示默认图标，`defaultColor` 仍用于初始化编辑器。

## 提交时机

| 操作 | 结果 |
| --- | --- |
| 选择预设色样或结束拖动 | 提交当前颜色。拖动期间在选色面板中预览草稿。调整色相、饱和度或亮度时保留当前透明度。 |
| 恢复默认 | 提交 `null`，宿主可移除已保存的覆盖值。 |
| 确认十六进制输入或关闭面板 | 提交有效颜色。支持六位 `RRGGBB` 和八位 `AARRGGBB`，可带 `#`。无效输入会还原为当前草稿的格式化值。 |

仅在结果改变时调用 `onChanged`。点击面板外关闭也会确认有效的十六进制编辑，因此，如果设置页另有「应用」与「取消」，应先把这些回调写到设置页的本地草稿。

面板打开时，宿主更新 `value` 会同步光谱和十六进制输入。处于继承状态时，更新 `defaultColor` 也会刷新面板。

色相和饱和度／亮度面板用圆环定位当前颜色。复古像素主题的圆环沿用像素滑块的阶梯轮廓。

主题选项的构建和持久化见[主题指南](/guide/theming)。
