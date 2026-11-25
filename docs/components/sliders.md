# 数值与评分

拖动音量滑块或集数范围的两端，在数值框里编辑播放速度并重置。评分以半星为步长，点击星形或水平拖动可以调整，清除按钮恢复未评分状态。

<ComponentDemo id="sliders" title="滑块与数值输入预览" :overlay-height="390">

<<< ../../example/lib/docs/demos.dart#sliders

</ComponentDemo>

## 滑块

<ApiLink symbol="YumeiroSlider" /> 适合拖动调整音量、透明度等连续值。`min` 和 `max` 定义范围，`divisions` 将范围切成等间距的区间。`valueLabel` 可显示常驻读数，`semanticFormatterCallback` 可输出含单位的可访问性文案。

通过 `onChanged` 更新显示。需要区别拖动中的预览与拖动结束后的保存时，可用 `onChangeStart`、`onChangeEnd`。

`onChanged: null` 显示禁用滑块。控件会把显示值限制到 `min` 到 `max`，宿主仍应以相同范围约束存储的值。

## 范围滑块

<ApiLink symbol="YumeiroRangeSlider" /> 适合选择价格、时长或集数区间。宿主通过 `RangeValues(start, end)` 持有端点，`start` 应小于或等于 `end`。用 `divisions` 设置步进，`labels` 和 `semanticFormatterCallback` 可分别为浮动标签和读屏补充单位。值与标签类型 `RangeValues`、`RangeLabels` 由 `package:material_ui/material_ui.dart` 提供。

两个端点使用同一组边界。通过 `onChanged` 更新区间，通过 `onChangeEnd` 在拖动结束后提交。传入 `onChanged: null` 禁用调整。区间滑块和单滑块共用主题轨道与端点外观，Pixel Retro 和 Neo-Brutalist 也提供对应的范围端点。两端均可用键盘操作。

## 精确数值输入

<ApiLink symbol="YumeiroSliderInput" /> 将滑块、数字输入框和可选重置操作组合起来。

- 提供 `defaultValue` 或 `onReset` 时才显示重置按钮。`defaultValue` 提供重置目标，当前值已达到默认值时按钮默认禁用。仅提供 `onReset` 时，按钮默认可用。`isResetEnabled` 可以自定义启用条件。
- `step` 量化内置文本提交的数值，滑块拖动使用 `divisions`。`decimalPlaces` 格式化默认数字文本。`displayMultiplier` 可把 `0.45` 显示为 `45`，与 `suffixText: '%'` 一起使用。
- `formatValue` 和 `parseValue` 用于自定义双向转换。使用 `logarithmic` 时，范围须满足 `0 < min < max`。
- 设为 `enabled: false` 可以禁用当前数值编辑器。

输入数字后，回车或失焦会尝试提交。默认解析器会去掉配置的 `suffixText`，并用 `displayMultiplier` 把显示单位换回实际值。提交时会限制范围、按 `step` 量化，再次保证结果落在范围内。自定义 `parseValue` 应返回实际单位。提供 `onTextSubmitted` 后，输入框的提交事件交给宿主处理，单独失焦不会提交。

`min` 小于零时，输入框请求支持负号的数字键盘。触控模式下，空间不足时重置按钮和数字输入框可以换行。

外部 `TextEditingController` 由创建者释放。组件默认只格式化自己的控制器。如果希望组件为外部控制器格式化当前数值，同时提供 `formatValue`。

## 评分

<ApiLink symbol="YumeiroRatingEditor" /> 是五颗星、半星步长的输入控件。`value` 为 `null` 时表示未评分。`onChanged` 接收结果，`semanticLabel` 和 `semanticValueFormatter` 可用于自定义辅助朗读。只展示评分时，用[媒体组件](./media)中的 <ApiLink symbol="YumeiroStarRating" />。

编辑器和只读评分都将传入分数限制在 0 到 5 之间，再取最接近的半星，例如 `3.26` 会显示为三颗半星。
