---
description: 区分视口宽度、输入方式与密度，为同一页面提供触屏、鼠标和键盘体验。
---

# 响应式与输入方式

`YumeiroModality` 表示交互方式，`YumeiroDensity` 表示界面密度，`YumeiroScreenClass` 表示可用视口宽度。横屏平板继续使用触控目标尺寸，桌面窄窗口继续使用指针控件。宽度断点用于调整内容的排列。

## 输入模式

不传 `modality` 时，Android、iOS 和 Fuchsia 使用 `touch`，Linux、macOS 和 Windows 使用 `pointer`。Web 使用 Flutter 报告的目标平台。设备预览或应用入口需要指定交互方式时，设置 `YumeiroApp` 或 `YumeiroScope` 的 `modality`。原生桌面窗口的最小尺寸由宿主应用设置。

`YumeiroInputController` 记录鼠标、触摸或键盘输入，帮助作用域内的控件决定何时展示键盘焦点指示。按键由焦点所在的作用域记录，布局继续遵循作用域中的交互模式。需要观察最近输入时，使用 `YumeiroInputScope.maybeOf(context)` 获取控制器。组件预览的「独立打开」保留当前示例，在网址后添加 `&modality=pointer` 或 `&modality=touch` 可以在同一设备上对照两种交互方式。移除这个参数可恢复自动判断。

## 宽度分类

| 可用宽度（逻辑像素） | `YumeiroScreenClass` |
| --- | --- |
| `width < 600` | `compact` |
| `600 ≤ width < 840` | `medium` |
| `840 ≤ width < 1280` | `expanded` |
| `1280 ≤ width` | `wide` |

`YumeiroResponsive.of(context)` 使用 `MediaQuery` 的视口宽度。面板内部需要按自身空间排布时，用 `YumeiroLayoutBuilder` 读取父布局提供的宽度。直接处理数值时可用 `YumeiroBreakpoints.classify`，表中的边界值属于后一档。响应对象的 `isExpanded` 在 `expanded` 和 `wide` 两档均为真。

```dart
Widget buildActions(VoidCallback onRefresh, VoidCallback onAdd) {
  return YumeiroLayoutBuilder(
    builder: (context, responsive) {
      final metrics = YumeiroModalityScope.metricsOf(context);
      return Wrap(
        direction: responsive.isCompact ? Axis.vertical : Axis.horizontal,
        spacing: metrics.rowGap,
        runSpacing: metrics.rowGap,
        children: [
          YumeiroButton(label: '刷新', onPressed: onRefresh),
          YumeiroButton(
            label: '新增',
            variant: YumeiroButtonVariant.primary,
            onPressed: onAdd,
          ),
        ],
      );
    },
  );
}
```

`YumeiroNavigationShell` 在窄触控视口显示底部导航，在更宽的触控视口显示导航轨。指针模式始终使用侧栏，窄窗口收起侧栏标签。应用通过 `selectedIndex` 和 `onSelectedIndex` 接管页面选择，页面内容跨布局复用。

`YumeiroEditor.show` 根据输入模式展示局部编辑。紧凑触控竖屏使用底部面板，宽屏和横屏使用居中的触控面板，指针模式使用居中对话框。长表单或多步编辑可通过 `fullscreenOnTouch: true` 在触控模式打开整页编辑器。 [编辑器](../components/dialogs#编辑器)

单选、多选与上下文动作在指针模式使用锚定菜单，组合筛选使用对话框。触控模式通过面板完成这些操作，紧凑竖屏的面板停在底部。桌面窄窗口保持指针交互，浮层的位置和尺寸随可用空间调整。 [菜单](../components/menus) · [选择与筛选](../components/sheets)

## 密度与目标尺寸

`YumeiroDensity` 有 `compact`、`standard` 和 `comfortable` 三档。通过 `YumeiroModalityScope.metricsOf(context)` 获取当前 `minTargetSize`、`controlHeight` 和间距。标准密度下，指针模式的基础目标尺寸为 40 逻辑像素，触摸模式为 48 逻辑像素。紧凑的可见外框可以和较大的触摸目标共存，自定义控件时可参考 `denseTargetSize`。

## 组件间距

组合页面时，从 `YumeiroTheme.of(context).spacing` 获取间距刻度，并给同一组里重复出现的关系使用同一个值。组件内部也按关系共用间距，例如指针选择菜单与触发器之间使用 `xs`。字段内部的内容边距和最小点击区域由输入模式及密度决定。

检查间距时，分别看清需要对齐的可见边缘、内容与点击区域。表格行背景的留白由表格负责，单元格对齐和整行交互可以独立排布。比较浮层时，从移动或滚动后实际显示的触发器边缘量到浮层表面，也要检查上翻和下展两种位置。

## 键盘与无障碍

`YumeiroScope` 已安装 `YumeiroInputListener`。按键进入 Yumeiro 的键盘焦点样式，按下鼠标、触笔或手指会退出这种样式，单纯移动鼠标会保留它。宿主和原生控件的焦点高亮由 Flutter 的焦点策略控制。应用触控模式还会在文本输入外部点击或开始拖动滚动视图时收起键盘。

1. 用 Tab 和 Shift+Tab 遍历设置项、弹窗动作与关闭入口，再用 Enter 或空格激活其中一个按钮。检查禁用项的可达性，以及从浮层返回后能否继续键盘操作。
2. 让同一个控件依次处于聚焦、悬停、禁用和选中状态。为纯图标操作提供可读提示或语义标签，用文字或图标表达业务状态。
3. 重复窄视口检查，增大字号并换用较长的标签。用换行、弹性列或 `Wrap` 允许内容在实际约束内排布。

## 高级动效与减少动画

`YumeiroApp` 和 `YumeiroScope` 接受高级动效总开关 `advancedMotionEnabled`，还可以通过 `motionOptions` 关闭某个效果。总开关关闭后，预设的 `YumeiroMotion` 时长解析为零，`isMotionEnabled` 对各项返回 false。总开关开启时，未指定的效果采用调用方的默认值。`YumeiroMotionOptions.values` 提供设置界面使用的七个选项，其中 `pointerOnly` 可以控制该项在设置界面是否可操作。

例如关闭海报倾斜和按钮按压缩放，同时为自定义页面过渡保留独立开关。减少动画由 Flutter 的 `MediaQuery` 提供，应用写自己的动画时同时检查这个值。

```dart
Widget buildMotionApp(Widget home, {required bool advancedMotion}) {
  return YumeiroApp(
    advancedMotionEnabled: advancedMotion,
    motionOptions: const {
      'posterTilt': false,
      'controlPressScale': false,
      'app.detailsTransition': true,
    },
    home: home,
  );
}

Duration detailsTransitionDuration(BuildContext context) {
  final theme = YumeiroTheme.of(context);
  if (MediaQuery.disableAnimationsOf(context) ||
      !theme.isMotionEnabled('app.detailsTransition')) {
    return Duration.zero;
  }
  return theme.motion.normal;
}
```

内置海报、按钮和导航会读取相应的键。应用自己的详情视差、图表悬停或路由动画需要在实现中消费相应偏好。在画廊切换「高级动效」和单项开关，复查内容在动画关闭时仍能正常完成选中、显示与导航。也可以启用系统的减少动画选项，检查自定义过渡。

<ApiLink symbol="YumeiroModalityScope" />

<ApiLink symbol="YumeiroResponsive" />

<ApiLink symbol="YumeiroMetrics" />

<ApiLink symbol="YumeiroBreakpoints.classify" />

<ApiLink symbol="YumeiroLayoutBuilder" />

<ApiLink symbol="YumeiroInputController" />

<ApiLink symbol="YumeiroInputScope" />

<ApiLink symbol="YumeiroMotionOptions" />

<ApiLink symbol="YumeiroMotionPreferences" />

<ApiLink symbol="YumeiroThemeExtension.isMotionEnabled" />
