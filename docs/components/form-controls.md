# 表单控件

在下方预览或示例画廊「交互控件 → 表单 → 表单控件」中，先点「保存」，查看表单如何展开包含错误字段的「日期与时间」。在字段 C 选择至少一项，填入日期范围并勾选字段 E 后，页面可保存并显示结果。「重置」会恢复初值。

<ComponentDemo id="form-controls" title="表单控件预览" :overlay-height="620" input-modes compact-touch>

<<< ../../example/lib/docs/form_controls_demo.dart#form-controls

</ComponentDemo>

## 把选择控件接入表单

字段 A 使用 `YumeiroSelect.form`，字段 H 在同一入口传入 `searchable: true`，可以在固定选项中筛选并保存结果。字段 C 使用 `YumeiroMultiSelect.form` 等待确认。字段 D 用 `YumeiroSelectionList.form` 以内联选项编辑单值，字段 G 用 `YumeiroSelectionList.multiForm` 立即更新集合。字段通过 `initialValue` 设置重置值，`validator` 校验输入，`onSaved` 收集保存结果。 [内联选择列表](./selection#内联选择列表) · [多选标签](./selection#多选标签)

多选表单默认保留暂时缺失的已选值。如果 `options` 完整列出有效值，可在 `YumeiroMultiSelect.form` 或 `YumeiroSelectionList.multiForm` 设置 `retainMissingValues: false`，从初值、当前值和重置值中移除已经缺失的项。仍存在的禁用项继续保留。刷新时更新字段值，无需触发字段或 `Form` 的 `onChanged`。确认式多选保留面板草稿，确认时只提交仍可选的增删操作。

单选、多选和远程单选的 `.form()` 在有界容器中默认填满可用宽度。为并排或纵向排列的字段提供相同的宽度约束即可对齐，单个字段也可以显式设置 `width`。指针模式的远程搜索结果面板跟随实际输入框宽度，空间不足时受视口限制。

启用 `clearable` 后，字段会为清除操作预留位置。选择或清空时，字段外框和指针弹层的宽度保持稳定。

## 复选框与开关

用 <ApiLink symbol="YumeiroCheckbox.form" /> 收集条款同意等独立确认，用 <ApiLink symbol="YumeiroSwitch.form" /> 保存随表单提交的开关偏好。两个字段都接入 `Form` 的校验、保存和重置。立即生效的设置仍可直接使用[开关与复选框](./selection#开关、复选框与分段)。

`required` 提供必填标记。要求用户同意时，用 `validator` 检查值是否为 `true`。复选字段启用 `tristate` 后，`null` 表示混合态。开关字段使用 `true` 或 `false`。

设置 `enabled: false` 会在复选框或开关滑块上显示禁用斜线。禁用的已选复选框和混合复选框使用相同的底色与斜线，读屏仍可区分两种值。设置 `readOnly: true` 会显示通常的状态标记，并可用键盘聚焦查看。

```dart
YumeiroCheckbox.form(
  label: '我同意服务条款',
  required: true,
  validator: (accepted) => accepted == true ? null : '请先同意服务条款',
)
```

## 远程搜索单选

用 <ApiLink symbol="YumeiroAsyncSelect" /> 查询成员、项目等远程实体，通过 `value` 和 `onChanged` 在宿主维护当前选项。使用 <ApiLink symbol="YumeiroAsyncSelect.form" /> 接入表单。选择结果保存为 `YumeiroSelectionOption<T>`，显示名称可独立于后续候选列表保留。保存业务 ID 时读取 `option?.value`。

指针模式可直接在字段输入，通过键盘浏览并选择下拉中的候选。窄屏触控在抽屉中搜索。每次打开立即请求一次空查询，后续输入按 `debounce` 防抖。新的输入使旧请求结果失效。返回空列表时显示无结果，抛出异常时显示 `loadErrorText` 或本地化错误，重试沿用当前查询。禁用候选仍可见，选择后关闭面板。取消保留原值，开启 `clearable` 可清空当前值。

当候选依赖工作区、父级字段或查询数据版本时，将对应 ID 或版本传给 `sourceKey`。值改变时，已打开的面板会关闭，旧请求的结果不会提交，表单中已经选择的值仍会保留。普通重建应保持此标识稳定。

预览使用本地模拟数据。打开字段 B，首次在当前选项下搜索「重试」会触发加载失败。点击结果区里的「重试」可重新加载，输入 `zzzz` 可查看空结果。选中一项后，切换字段 A 的选项，再打开字段 B，可以看到更新后的候选。已选值保留到重新选择或清空时。

```dart
Widget buildAssigneeField(
  int workspaceId,
  Future<List<YumeiroSelectionOption<int>>> Function(String) searchMembers,
  ValueChanged<int?> saveAssignee,
) => YumeiroAsyncSelect.form<int>(
  label: '负责人',
  clearable: true,
  sourceKey: workspaceId,
  loadOptions: searchMembers,
  loadErrorText: '未能加载成员，请重试',
  onSaved: (option) => saveAssignee(option?.value),
);
```

## 日期、时间与日期范围

| 字段 | 值类型 | 常用配置 |
| --- | --- | --- |
| <ApiLink symbol="YumeiroDatePicker" /> / <ApiLink symbol="YumeiroDatePicker.form" /> | `DateTime` | 通过 `firstDate`、`lastDate` 设置边界，用 `selectableDayPredicate` 禁选日期。 |
| <ApiLink symbol="YumeiroTimePicker" /> / <ApiLink symbol="YumeiroTimePicker.form" /> | `TimeOfDay` | 用 `initialPickerTime` 指定尚未选值时的起始时间。 |
| <ApiLink symbol="YumeiroDateRangePicker" /> / <ApiLink symbol="YumeiroDateRangePicker.form" /> | `DateTimeRange<DateTime>` | 设置起止边界，或通过 `selectableDayPredicate` 约束可选的起止日期。 |

三个字段在指针模式打开锚定浮层，在窄屏触控模式打开底部面板。指针浮层周边空间不足时在视口内居中。面板操作按钮使用主题的标准尺寸，单日期的月份标题与导航空间不足时分行显示。日期和范围使用固定六行的月视图，支持翻月和跳转年份，日期数字保留较小字号。今天用描边标记，已选日期带有主色填充。日期范围在上方显示起止值，空间充足时并排显示两个月。

### 设置打开时的界面

三个选择器的独立构造器和 `.form()` 都接受 `initialEntryMode`。该参数指定每次打开时的界面以及可用的输入方式。允许切换时，用户可通过面板顶部的按钮切换。

| 入口 | 可切换模式 | 固定模式 |
| --- | --- | --- |
| 日期与日期范围的 Flutter `DatePickerEntryMode` | `calendar`（默认）打开月历，`input` 打开文本输入。 | `calendarOnly` 仅月历，`inputOnly` 仅文本输入。 |
| 时间的 <ApiLink symbol="YumeiroTimePickerEntryMode" /> | `list`（默认）打开时间选项，`input` 打开文本输入。 | `listOnly` 仅时间选项，`inputOnly` 仅文本输入。 |

时间选项在指针模式下是并排的时、分列表。默认 `list` 模式还可直接编辑列表上方的读数。在触控模式下，选项为两列滚轮，中间一行标记所选时间。允许切换时，触控用户也可点击时间读数进入手动输入。时间显示跟随应用的本地化和 12／24 小时设置。

```dart
Widget buildScheduleFields() => Column(
  children: [
    YumeiroDatePicker.form(
      firstDate: DateTime(2026, 1, 1),
      lastDate: DateTime(2026, 12, 31),
      initialEntryMode: DatePickerEntryMode.input,
    ),
    YumeiroTimePicker.form(
      initialEntryMode: YumeiroTimePickerEntryMode.inputOnly,
      initialPickerTime: const TimeOfDay(hour: 9, minute: 0),
    ),
  ],
);
```

`initialPickerTime` 只给空时间字段设定面板打开时的起始时间，确认后才写入字段。日期和日期范围可用 `currentDate` 指定标记为「今天」的日期，默认使用当天。

独立组件通过 `value` 和 `onChanged` 接入宿主状态。日期和范围的端点按年、月、日处理，应用负责将日历日期映射到业务时区或具体时刻。面板中的编辑在确认后写回，取消选择保留旧值。开启 `clearable` 后，可用独立按钮清空为 `null`。字段很窄时会预留独立一行放置清除按钮。要在嵌套路由中打开选择器，设 `useRootNavigator: false`。

表单字段均支持 Flutter 的 `validator`、`onSaved`、`onReset` 和 `forceErrorText`，并提供 `enabled` 和 `readOnly`。必填标记通过 `required` 设置，业务校验通过 `validator` 定义。完整生命周期见[表单接入](./inputs#flutter-表单)。

## 展开与收起

<ApiLink symbol="YumeiroDisclosure" /> 通过 `expanded` 和 `onChanged` 接收宿主的展开状态。收起时正文退出键盘遍历和读屏。若焦点原本在正文中，收起会将焦点移到可用的标题。

`maintainState` 默认开启，折叠的字段仍参与表单校验、保存和重置。提交时可以调用 `FormState.validateGranularly()`，发现错误字段位于折叠区时展开该区。设为 `false` 时，正文会在收起后卸载，字段在重新展开时从初值开始。
