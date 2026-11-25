# 媒体

在「海报网格」中，点封面打开条目，点封面上的播放按钮推进模拟进度。切到「图片与结果行」可切换缺图状态、查看半星评分和点击浏览记录。封面来自示例内嵌的合成图案。

<ComponentDemo id="media" title="媒体展示预览" :overlay-height="440">

<<< ../../example/lib/docs/display_demos.dart#media

</ComponentDemo>

## 图片容器

- <ApiLink symbol="YumeiroArtworkImage" /> 用于背景和封面。`loading` 在首帧准备时展示，缺少图片或解码失败时采用 `fallback` 或主题默认占位。
- <ApiLink symbol="YumeiroArtworkImage.thumbnail" /> 为列表缩略图提供固定宽高。
- <ApiLink symbol="YumeiroAvatar" /> 以圆形框展示头像，`radius` 控制大小。

由宿主构造 `ImageProvider` 并管理 URL、认证和解码尺寸。信息性图片可用 `semanticLabel` 提供替代文本。

图片提供者为空或加载失败时使用回退内容。提供者有缓存且可同步得到首帧时，图片可直接显示。若封面宽高影响布局，由外层先固定显示尺寸或纵横比，加载文字和图片就会使用同一块区域。

## 海报和媒体卡

<ApiLink symbol="YumeiroMediaCard" /> 适合以图为主的浏览入口。`title` 是主标签，`supportingLines` 按顺序显示补充说明，每项占一行，`footer` 可放自定义内容。`topLeft`、`topRight`、`bottomLeft`、`bottomRight` 及 `overlayActions` 可放角标或按钮。指针交互配合当前主题和动效配置驱动视觉反馈。

<ApiLink symbol="YumeiroPosterGrid" /> 根据宽度、`minimumTileWidth`、`spacing` 和列数限制计算海报网格。`spacing` 同时控制实际列间距，默认 14。`footerExtent` 为卡片下方的文字和自定义内容预留空间，补充说明较多时可增大该值。`maxRows` 可限制显示行数。

海报网格的列数受容器可用宽度和主题海报缩放影响。使用 `maxRows` 时，同一行数在宽窄窗口可能显示不同数量的条目。独立滚动区使用默认构造器，嵌入纵向 `CustomScrollView` 时使用 <ApiLink symbol="YumeiroPosterGrid.sliver" />，由外层视口管理滚动行为。

## 辅助信息和操作

- <ApiLink symbol="YumeiroListTile.media" /> 用于搜索结果或浏览历史，将缩略图、标题、元信息和末端内容排在一行。
- <ApiLink symbol="YumeiroSectionHeader.eyebrow" /> 为分区标题添加强调色短标题。
- <ApiLink symbol="YumeiroProgress" /> 接收 `0.0` 到 `1.0` 的进度，轨道端帽随主题变化。`YumeiroMediaCard.progress` 可直接接入同一读数。
- <ApiLink symbol="YumeiroStarRating" /> 展示五分制半星评分，编辑用 <ApiLink symbol="YumeiroRatingEditor" />。
- <ApiLink symbol="YumeiroMediaPlayButton" /> 为媒体封面提供播放入口，播放和暂停的状态由宿主管理。
