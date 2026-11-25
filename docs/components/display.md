# 状态与反馈

在「标签与指标」中可切换共享标签、移除筛选并选择只读的记录 ID。切到「错误」后点击重试，可观察错误提示如何转入加载状态，再通过「完成同步」回到列表摘要。

<ComponentDemo id="display" title="状态与反馈预览" :overlay-height="400">

<<< ../../example/lib/docs/display_demos.dart#display

</ComponentDemo>

## 小型标签

| 组件 | 用法 |
| --- | --- |
| <ApiLink symbol="YumeiroBadge" /> | 展示状态、日期、计数和其他短标签。用 `label` 显示文字，或用 `child` 提供自定义内容。 |
| <ApiLink symbol="YumeiroBadge.overlay" /> | 放在图片上的标签，例如清晰度或内容类型。 |
| <ApiLink symbol="YumeiroChip" /> | 可点按、选中或删除的标签，例如可切换的筛选条件。 |

纯展示标签默认使用低强调的紧凑外观。业务状态用 `statusRole` 取得主题配色，并搭配文字或 `icon` 表达含义。为单个标签指定 `tint` 时，它优先决定前景和填充颜色。文字默认单行并使用常规字重，可用 `emphasized: true` 强调，或用 `maxLines` 调整行数。

`YumeiroChip` 的正文点击和删除分别通过 `onTap` 和 `onDeleted` 处理。可选标签由宿主管理选中状态，并通过 `selected` 传回。删除时从宿主集合移除对应 ID，再用新集合重建标签。Chip 与 Badge 共用紧凑标签布局，输入框中的 `YumeiroTokenInput` 标签也复用 Chip 的渲染。

## 提示和指标

- <ApiLink symbol="YumeiroCallout" /> 显示持续可见的段落提示。用 `statusRole` 表达状态，用 `action` 附加处理入口。横向空间不足时，操作移到提示文字下方。短时操作结果可使用[通知](./toasts)。
- <ApiLink symbol="YumeiroStatTile" /> 强调一个数值和名称，支持 `statusRole` 和提示。
- <ApiLink symbol="YumeiroMetricPill" /> 显示一组紧凑读数。可传入单组 `label` 和 `value`，也可通过 `items` 提供多组文本读数。
- <ApiLink symbol="YumeiroFieldLayout.readOnly" /> 用表单式标签显示可选择复制的只读文本。需要沿用输入框的轮廓与前后缀时，可用[文本框](./inputs)的 `readOnly`。

## 加载、空内容和错误

| 组件 | 应用状态 |
| --- | --- |
| <ApiLink symbol="YumeiroSpinner" /> | 局部等待，可配置尺寸、标签与可访问性描述。 |
| <ApiLink symbol="YumeiroLoadingCard" /> | 居中显示等待内容和 `message`。 |
| <ApiLink symbol="YumeiroEmptyState" /> | 请求成功但没有内容，可带恢复操作。 |
| <ApiLink symbol="YumeiroErrorState" /> | 居中显示请求失败，支持 `onRetry` 和 `retryEnabled`。 |

空内容支持 `compact`，可嵌入卡片或结果区，通过 `action` 放置刷新等操作。需要在现有内容旁显示局部错误时，使用 `YumeiroCallout(statusRole: YumeiroStatusRole.danger)`，可用其 `action` 附加重试按钮。

刷新已有列表时，可以保留旧结果并在工具栏放局部等待提示。首次请求失败时，可用错误状态集中呈现恢复入口。在继续加载下一页或重试时，由宿主管理按钮是否可用。
