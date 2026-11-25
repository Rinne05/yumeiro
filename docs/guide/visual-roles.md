---
description: 用主题令牌和语义角色为应用定义一致的表面、控件、列表项与状态。
---

# 视觉角色与令牌

主题令牌提供颜色、间距、圆角、排版和动画时长。视觉角色为用途命名，同一个角色在不同主题中会解析成各自的填充、轮廓和材质。写组件时，先选与用途匹配的角色，再用主题令牌补齐布局和文字。

内置角色与应用自定义角色共享 <ApiLink symbol="YumeiroVisualRole" /> 的标识规则。角色类型与 ID 一起确定其身份，回退角色用于未登记配方时的查找。

| 角色 | 用途 | 示例 |
| --- | --- | --- |
| `YumeiroSurfaceRole` | 容器和层次 | `panel`、`card`、`floating`、`modal` |
| `YumeiroControlRole` | 控件的操作优先级和状态 | `primary`、`secondary`、`danger` |
| `YumeiroItemRole` | 列表或表格中可交互的项目 | `standard` |
| `YumeiroStatusRole` | 状态文字、底色和强调色 | `neutral`、`success`、`warning` |

## 读取令牌

使用 `YumeiroTheme.of(context)` 获取作用域中的 `YumeiroThemeExtension`。常用字段包括 `colors`、`spacing`、`radii`、`typography`、`iconSizes`、`motion` 和 `visuals`。`YumeiroTextStyle` 会保留所在表面提供的前景色，适合同时支持不同底色的标题和正文。

| 用途 | 对应接口 |
| --- | --- |
| 容器间距、内容内边距与圆角 | `theme.spacing` 和 `theme.radii` 分别提供 <ApiLink symbol="YumeiroSpacing" /> 与已应用圆角设置的令牌。 |
| 点击目标、控件高度、不同模式的行间隔 | `YumeiroModalityScope.metricsOf(context)` 根据交互方式和密度解析。 |
| 内容类型、图标和状态颜色 | `theme.typography` 提供文字样式，`theme.icons` 与 `theme.iconSizes` 提供共享图标，`theme.visuals.status(role)` 读取状态视觉。 |
| 图表或分类色板 | `theme.categoricalPalette` 是预设生成的有序色板。将分类与颜色的对应关系独立保存，并用标签明确类别。 |

```dart
Widget buildSummary(BuildContext context, String title, String description) {
  final theme = YumeiroTheme.of(context);

  return YumeiroCard(
    padding: EdgeInsets.all(theme.spacing.xl),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        YumeiroTextStyle(style: theme.typography.title, child: Text(title)),
        SizedBox(height: theme.spacing.sm),
        Text(description),
      ],
    ),
  );
}
```

这里的 `context` 来自 `YumeiroApp` 或 `YumeiroScope` 的子树。交互控件的最小目标尺寸、密度和行间隔从 [YumeiroMetrics](./adaptive#密度与目标尺寸) 读取。

## 添加应用角色

为业务用途声明稳定的 ID 和回退角色。通过 `YumeiroApp.visualsAugmenter` 注册配方时，按当前预设解析基础外观，再修改要强调的字段。如果某个主题未注册应用角色，会沿 `fallback` 查找已有样式。

下例在卡片配方上增加信息色描边。它为普通态和已有交互态应用相同的轮廓，并沿用卡片的焦点指示器。

```dart
const noticeRole = YumeiroSurfaceRole(
  'app.notice',
  fallback: YumeiroSurfaceRole.card,
);

YumeiroSemanticVisualTheme addNoticeRole(
  YumeiroSemanticVisualTheme base,
  YumeiroColorTokens colors,
  YumeiroRadiiTokens radii,
) {
  final card = base.surfaceRecipe(YumeiroSurfaceRole.card);

  YumeiroVisualAppearance withNoticeOutline(YumeiroVisualAppearance value) {
    return value.copyWith(outline: BorderSide(color: colors.info));
  }

  return base.extend(
    surfaces: {
      noticeRole: YumeiroVisualRecipe(
        base: withNoticeOutline(card.base),
        states: WidgetStateProperty.resolveWith((states) {
          return withNoticeOutline(card.resolve(states));
        }),
        focusIndicator: card.focusIndicator,
      ),
    },
  );
}

Widget buildNoticeApp() {
  return const YumeiroApp(
    visualsAugmenter: addNoticeRole,
    home: Scaffold(
      body: Center(
        child: YumeiroCard(role: noticeRole, child: Text('处理完成')),
      ),
    ),
  );
}
```

`YumeiroSemanticVisualTheme.extend` 可以登记表面、控件、项目和状态配方；登记现有角色时会替换它的配方。自定义控件角色可传给 `YumeiroButton.controlRole`，自定义状态角色可用于读取对应的 `YumeiroStatusVisual`。

## 读取生效的角色配方

角色查找先检查该角色的注册项，再沿回退链查找。找不到匹配项时，表面回退到 `panel`，控件回退到 `neutral`，交互项目回退到 `standard`，状态回退到 `neutral`。

完整构造器要求首发的基础角色有明确配方。各类角色的 `builtInValues` 列出当前内置目录。发布后新增的内置角色会声明回退，应用可以继续用原有配方构造完整主题。需要覆盖某个新增角色时，可显式登记其配方。用 `extend` 修改回退角色后，尚未登记配方的新角色会继承更新。

`surfaces`、`controls`、`items` 和 `statuses` 保存当前主题明确登记的配方。读取生效配方用 `surfaceRecipe(role)`、`controlRecipe(role)`、`itemRecipe(role)` 和 `status(role)`。给定选中或悬停等交互状态后，`resolveRole(role, states)` 返回表面、控件或交互项目的实际外观。

## 局部调整

给支持 `visualOverride` 的组件传入 `YumeiroVisualOverride`。先由配方解析当前状态的完整外观，再依次应用 `base` 和 `states` 的差量。`base` 影响所有状态，适合统一形状和描边。`states` 适合只在悬停、按下、选中或禁用时改变视觉，解析为 null 时沿用前面的结果。组件的显式视觉覆盖优先于最近的 `YumeiroVisualScope` 中的覆盖。

`YumeiroVisualDelta.fillOpacity` 只乘到填充的透明度上，`opacity` 设置整层的透明度，可能同时改变内容。`effects` 替换整组效果，传入 `YumeiroEffectStack.none` 可清空。差量保留原有焦点指示器。只改一个控件时，可通过差量保持其他视觉。希望同一主题中的一类控件一起改变时，扩展它们的角色配方。

`YumeiroVisualScope.overlay` 适合在图像上给一组支持视觉作用域的子控件提供浮层控件角色。组合控件由父层统一处理点击和选中时，可用 `YumeiroInteractionStateScope` 把状态快照传给会读取该作用域的视觉子控件，避免子层独立处理同一个手势。

自定义配方的填充可以使用 <ApiLink symbol="YumeiroSolidFill" /> 或 <ApiLink symbol="YumeiroGradientFill" />。渐变的代表色供需要单色的视觉计算使用。键盘焦点描边和辉光由 <ApiLink symbol="YumeiroFocusIndicator" /> 描述。需要像素阶梯轮廓时，可将 <ApiLink symbol="YumeiroPixelBorder" /> 传给配方的 `shape`，`step` 以逻辑像素计，在小尺寸表面上会自动收敛。

## 选择绘制组件

| 场景 | 使用的接口 |
| --- | --- |
| 自定义面板已知语义角色 | `YumeiroVisualSurface` 从主题和最近的视觉作用域解析外观。调用方提供要用于绘制的状态集合。 |
| 可点击的自定义图块或列表项 | `YumeiroInteractiveVisualSurface` 管理悬停、按压和焦点，由调用方传入当前 `selected` 与点击回调。 |
| 已有完整外观或应用了局部材质 | `YumeiroResolvedVisualSurface` 绘制明确的 `YumeiroVisualAppearance`，保留对应的效果栈和内容处理。 |
| 需要把外观交给现有 Flutter `Decoration` API | `YumeiroResolvedVisualSurface.materialDecoration` 提供静态装饰。实时模糊或折射见[材质与玻璃](./materials)。 |

<ApiLink symbol="YumeiroThemeExtension" />

<ApiLink symbol="YumeiroSemanticVisualTheme" />

<ApiLink symbol="YumeiroVisualRecipe" />

<ApiLink symbol="YumeiroVisualOverride" />

<ApiLink symbol="YumeiroVisualDelta" />

<ApiLink symbol="YumeiroVisualScope" />

<ApiLink symbol="YumeiroInteractionStateScope" />

<ApiLink symbol="YumeiroVisualSurface" />

<ApiLink symbol="YumeiroInteractiveVisualSurface" />

<ApiLink symbol="YumeiroResolvedVisualSurface" />
