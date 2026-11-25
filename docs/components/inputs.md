# 文本与标签输入

切换「文本与密码」「表单与搜索」和「标签」，可试用清除昵称、密码显隐、保存任务、台站搜索和标签编辑。切换场景时保留各自的编辑状态。

<ComponentDemo id="inputs" title="文本输入预览" :overlay-height="430">

<<< ../../example/lib/docs/demos.dart#inputs

</ComponentDemo>

## 文本框

<ApiLink symbol="YumeiroTextField" /> 适合普通输入、密码和备注。通过 `onChanged` 接收编辑，用 `onSubmitted` 接收键盘提交。

| 需要 | 配置及行为 |
| --- | --- |
| 只在首次打开表单时填入文字 | `initialValue` 在组件创建内部控制器时读取。后续重建只改变 `initialValue` 会保留用户已经输入的内容。 |
| 填入异步数据，重置文本或调整选区 | 传入 <ApiLink symbol="YumeiroTextField.controller" />，更新控制器的 `text` 或 `value`。外部控制器优先于 `initialValue`。 |
| 在字段之间移动焦点 | 传入 `focusNode` 并在宿主调用 `requestFocus()`。外部控制器和焦点节点都由创建者释放。 |
| 可查看或复制的只读输入 | 用 `readOnly: true` 保留文本选择。用 `enabled: false` 进入禁用状态。 |
| 可见的清除操作 | `clearable` 要求已启用、可编辑且内容非空。点击会清空控制器并调用 `onChanged('')`。 |
| 密码 | `obscureText` 初始隐藏文字，`obscureToggle` 也会初始隐藏并提供显隐按钮。使用 `maxLines: 1`。 |

程序主动修改控制器时，可用控制器监听器观察变化。对输入约束使用 `inputFormatters`，对键盘动作使用 `keyboardType` 和 `textInputAction`。用 `semanticLabel` 命名字段，`suffixText` 可显示固定单位。用 `contentPadding` 设置输入框的内边距。

## Flutter 表单

将 <ApiLink symbol="YumeiroTextField.form" /> 或 <ApiLink symbol="YumeiroSelect.form" /> 放在 Flutter 的 `Form` 中。字段提供 `label`、必填标记 `required` 和 `helperText`，通过 `validator` 返回业务错误，返回 `null` 表示校验通过。

在预览中打开「表单与搜索」，直接保存可查看两个必填错误。填入任务名称，从登记名单中搜索并选择台站后保存，页面会显示已保存的内容。用「例行巡检」作为名称可模拟重名错误，重新编辑名称会清除此消息。「重置表单」将两个字段恢复为初始值。

| 操作 | 接法 |
| --- | --- |
| 校验 | 调用 `FormState.validate()`。通过 `autovalidateMode` 可以在编辑等时机自动校验。 |
| 保存 | 校验通过后调用 `FormState.save()`，用各字段的 `onSaved` 收集数据，由宿主发起提交。 |
| 重置 | 调用 `FormState.reset()`，字段恢复到初始值并执行 `onReset`。宿主一并清理外部错误和提交状态。 |
| 显示服务端错误 | 把服务端返回的字段错误传给 `forceErrorText`。该字段视为校验失败，这段时间暂停调用 `validator`。宿主可在修改对应字段或重置时传回 `null`。 |

`validate()` 和 `save()` 遵循 Flutter `Form` 的注册规则，处理调用时仍挂载在该表单中的字段。应用可以在自身状态中保存在切换页面或表单步骤时需要保留的值。

`YumeiroTextField.form` 接受 `initialValue` 或外部 `controller`，两者择一。字段在挂载时读取初值或控制器文本，作为重置值。程序修改文本或在重建时替换控制器会更新表单当前值，重置值仍取自字段挂载时的文本。加载另一条记录并设置新的重置值时，给字段组件传入新的 `key`。文本字段的 `onChanged` 报告用户输入和清除操作。程序修改可通过控制器监听器观察。系统自动填充和字数限制分别通过 `autofillHints`、`maxLength` 和 `maxLengthEnforcement` 配置。

`YumeiroSelect.form` 通过 <ApiLink symbol="YumeiroSelectionOption" /> 定义可选值，用 `initialValue` 设置初值，用 `onChanged` 接收用户选择。两个入口都返回 Flutter 的 `FormField<T>`，支持 `enabled`、`readOnly` 和 `focusNode`。需要直接操作字段状态时，把 `GlobalKey<FormFieldState<T>>` 传给 `key`，文本字段的 `T` 为 `String`。

选填单选可启用 `clearable: true`。清除按钮在字段可编辑且已有值时出现，空间不足时移到选择器下方。清除会通过 `onChanged` 发送 `null`，并按 Flutter 表单规则重新校验。关闭选择器不会改变值。若打开选择器后通过 `FormFieldState.didChange` 写入新值，旧选择器的结果会被忽略。嵌套路由可用 `useRootNavigator: false` 让最近的导航器管理选择器。

需要文本草稿参与 Flutter 状态恢复时，在 `YumeiroApp(restorationScopeId: 'task-app', ...)` 中开启恢复作用域，再给文本表单字段设置稳定的 `restorationId`。由宿主管理的控制器使用宿主自己的状态恢复策略。

内联单选、多选、日期、时间和日期范围字段也可以接入同一个 `Form`，见[表单控件](./form-controls)。

## 字段布局和搜索

<ApiLink symbol="YumeiroFieldLayout" /> 为任意输入排列标题、必填标记、辅助提示和宿主传入的 `errorText`。有错误时优先展示错误文案。已有独立输入或自定义表单流程可以直接复用这一布局。

用 <ApiLink symbol="YumeiroFieldLayout.readOnly" /> 展示可选中和复制的路径、标识符或说明。`maxLines` 可限制显示行数。需要保留输入框的外观时，使用 `YumeiroTextField(readOnly: true)`。

选中文字时，支持系统编辑菜单的字段继续由系统展示操作。Flutter 绘制的菜单会使用当前 Yumeiro 主题，同样适用于可搜索选择器。

<ApiLink symbol="YumeiroTextField.search" /> 提供搜索前缀、清除入口和键盘搜索动作。可用 `focusNode` 管理焦点，或开启 `autofocus` 在打开时聚焦。点击清除时先回调 `onChanged('')`，随后回调 `onCleared`，可按需用后者恢复搜索界面。筛选、排序和更多操作需要放在同一行时，用[搜索工具栏](./toolbars)。

## 标签输入

<ApiLink symbol="YumeiroTokenInput" /> 用于关键词、别名等少量可独立增删的项。传入 `values` 并接收 `onChanged` 报告的新列表。

字符串默认去除首尾空白。使用业务对象时，通过 `parseInput` 将文本转换为一项或多项，用 `labelBuilder` 生成可读内容，用 `valueKey` 定义去重和删除所用的身份。

`onChanged` 返回新的只读列表。把它存回宿主状态并作为 `values` 传入。用稳定的业务 ID 作为对象的 `valueKey`，可在刷新数据后继续识别同一个标签。
