---
description: 选择内置主题，保存主题配置，按预设公开的选项定制颜色和交互。
---

# 主题与预设

`YumeiroThemePreset` 定义一套可独立使用的主题。`YumeiroThemeFamily` 将同风格的浅色和深色版本归到一起，应用可以分别保存用户选择的家族和外观偏好。以下 Dart 片段沿用[开始使用](./getting-started)的导入。

## 选择内置预设

将 `YumeiroThemePresets` 上的预设传给 `YumeiroApp` 或 `YumeiroScope` 的 `preset`，或通过 `presetId` 在当前注册表查找。两个字段同时提供时，`preset` 优先。省略 `preset` 且 ID 缺失或无法找到时，应用根部使用 Classic Dark。向用户展示主题列表时，可以读取 `YumeiroThemeFamilies.builtInValues`，用 `family.resolve(preferredVariant)` 获取当前偏好的版本。当首选外观不可用时，家族使用自己的默认版本，宿主仍可保留原来的外观偏好。

| 主题家族 | `YumeiroThemePresets` 预设字段 |
| --- | --- |
| 经典 | `classicLight`、`classicDark` |
| 极客 | `geek`（深色） |
| 素描 | `sketch`（浅色） |
| 新拟态 | `neumorphicLight`、`neumorphicDark` |
| 极简 | `minimalLight`、`minimalDark` |
| 液态玻璃 | `liquidGlassLight`、`liquidGlassDark` |
| 釉面陶瓷 | `ceramicLight`、`ceramicDark` |
| 拉丝金属 | `brushedMetalLight`、`brushedMetalDark` |
| 新粗野主义 | `neoBrutalistLight`、`neoBrutalistDark` |
| 复古像素 | `pixelLight`、`pixelDark` |
| 磨砂亚克力 | `acrylicLight`、`acrylicDark` |
| 软硅胶 | `siliconeLight`、`siliconeDark` |
| 厚磨砂玻璃 | `frostedGlassLight`、`frostedGlassDark` |

保存预设的 `id` 或 `YumeiroThemePresetIds` 中的常量。显示时用 `preset.resolveLabel(YumeiroLocalizations.of(context))` 取得本地化名称。部分浅色预设沿用原有无后缀 ID，例如 `neoBrutalistLight.id` 仍为 `yumeiro.neo-brutalist`。

用 `presetId` 选择确切的预设版本，并另外保存强调色与自定义选项，以便恢复用户的外观。需要用户跨家族保留明暗偏好时，分别保存家族 ID 与首选外观（<ApiLink symbol="YumeiroThemeVariant" />）。恢复持久化配置时，用 `familyById` 或 `maybePresetById` 识别因删除或更新而失效的旧值，再由应用决定替代项。`presetById` 适用于调用方接受回退的地方。

## 按预设定制外观

从当前 `preset.options` 读取参数定义，以 `option.id` 为键，将用户的更改传入 `customizations`。删除该键会恢复预设的默认值。换用其他家族时，按预设或家族保存选项值可以保留各自的外观偏好。

```dart
Widget buildCustomizedApp(Widget home) {
  return YumeiroApp(
    preset: YumeiroThemePresets.neoBrutalistLight,
    customizations: const {
      'backgroundTone': Color(0xFFF9F0BB),
      'panelColor': Color(0xFFFFAA9F),
      'roundness': 120.0,
    },
    home: home,
  );
}
```

`backgroundTone` 调整底色的色相和饱和度，保留原有明暗层次。设置页按当前预设公开的选项生成控件。以下选项适合分别控制各区域的颜色。

| 选项 ID | 用途 | 提供该选项的预设示例 |
| --- | --- | --- |
| `panelColor` | 面板底色 | 新粗野主义 |
| `surfaceColor` | 内容表面底色 | 新粗野主义、软硅胶 |
| `secondarySurfaceColor` | 次级表面底色，例如输入控件 | 复古像素 |
| `surfaceHoverColor` | 悬停表面底色 | 新粗野主义 |
| `hardShadowColor` | 硬阴影颜色 | 新粗野主义、复古像素 |

| 选项类型 | 设置页读取的字段 |
| --- | --- |
| `YumeiroThemeToggleOption` | 布尔值和 `defaultValue` |
| `YumeiroThemeNumberOption` | 有限数值会被限制在 `min` 与 `max` 之间。`step`、`unit` 和 `decimalPlaces` 供控件显示与输入使用。 |
| `YumeiroThemeColorOption` | 接受 `Color`、ARGB 整数、六位 RGB 或八位 ARGB 十六进制字符串，可带 `#`。 |
| `YumeiroThemeChoiceOption` | 用 `choices` 的键验证和持久化选择，用 `resolveChoices` 提供显示标签。 |

用 `option.resolve(values)` 读取已校验的值，用 `resolveLabel` 和 `resolveDescription` 获取显示文案。`pointerOnly` 与 `minCapability` 是宿主设置页可读取的元数据。根据当前交互方式和实际材质档位决定可否编辑，保留已经保存的值便于回到支持的环境后使用。运行时材质档位的读取方式见[材质与玻璃](./materials#材质能力)。

持久化时，把 `Color` 转为 `toARGB32()` 的整数值或 `#AARRGGBB` 文本。只保存用户实际覆盖的键。如果把控件展示的默认值也写入 `customizations`，恢复时那些值会作为显式覆盖继续生效。

主题先用 `accentColor` 或已设置的 accent 选项经 `accentCustomizer` 派生色板，再应用背景、描边和各表面颜色选项。圆角和已解析的参数用于生成角色配方，通用视觉调整与 `backdropBlur` 在此之后生效，最后由 `visualsAugmenter` 扩充角色。单独设置 `accentColor` 时，选取带有 `accentCustomizer` 的预设才能派生整套相关颜色。

使用内置规则派生主色色板时，强调色保持原值。颜色合成会用共同色彩空间，对比度在 sRGB 中计算。按亮度选出的文字颜色与基础主色的对比低于 `2.5:1` 时，规则会在黑、白文字中选择更清楚的一种。检查悬停、按下、自定义角色或半透明材质时，以组件实际绘制的前景和背景为准。

内置设置可以覆盖已有配方，预设也可定义专用选项。为每个选项使用稳定且唯一的 ID，按需声明何种 `YumeiroThemeAdjustment` 负责通用变换，或由 `visualsBuilder` 消费对应参数。例如数值选项声明 `YumeiroThemeAdjustment.roundness` 后可用自己的 ID 控制圆角。多个圆角选项同时传值时，以预设声明顺序中最后一个为准。构建器应为缺少的参数提供默认值，加载未知 ID 的历史设置时也能正常生成主题。

## 注册应用自己的主题

以现有预设为起点，使用 `copyWith` 改颜色或令牌，保留其语义配方和派生规则。为应用的预设提供独立稳定的 ID。注册表可以用 `standard()` 包含内置主题，也可以用 `empty()` 只保留应用注册的主题。

```dart
YumeiroThemeRegistry createAppRegistry() {
  final base = YumeiroThemePresets.classicDark;
  final ocean = base.copyWith(
    id: 'app.ocean.dark',
    label: '深海',
    colors: base.resolveColors(const Color(0xFF6AD7C4)),
  );

  return YumeiroThemeRegistry.standard()
    ..registerPreset(ocean, familyId: 'app.ocean', familyLabel: '深海');
}

Widget buildOceanApp(YumeiroThemeRegistry registry, Widget home) {
  return YumeiroApp(
    registry: registry,
    presetId: 'app.ocean.dark',
    home: home,
  );
}
```

在应用根部创建并复用注册表。`standard()` 创建独立可改的注册表，省略 `registry` 时使用全局共享实例。每个预设 ID 只能占一个注册位置。调用 `registerPreset` 会替换同位置的家族外观或同 ID 的独立预设。调用 `registerFamily` 时可以用 `replace: false` 保留已有家族。若另一个位置已占用该 ID，注册会在修改前抛出 `ArgumentError`。通过 `presetId` 选中的主题会随注册表更新，直接传入 `preset` 时以传入对象为准。主题色表、配方和默认参数由预设决定，只修改 `brightness` 会继续复用原色表和配方。

完整主题可以传入 `materialSchemeBuilder`、`visualsBuilder` 和 `categoricalPaletteBuilder` 定义 Material 色板、组件语义配方和分类颜色。需要调整控件各状态时，主题可提供专用的 checkbox、switch 或 slider 构建器。若应用只需要补充几种业务角色，使用[视觉角色与令牌](./visual-roles#添加应用角色)中的 `visualsAugmenter` 即可。子页面可通过 <ApiLink symbol="YumeiroThemeRegistryScope.of" /> 读取当前注册表，例如构建主题选择器。

## 试用主题和选项

在预览栏切换经典、液态玻璃和复古像素。可以聚焦文本字段或打开详情浮层，比较同一组控件的轮廓、焦点和材质。切换主题时会重新加载示例。

<ComponentDemo id="theme-preview" title="主题样式对比" :overlay-height="500" theme-styles input-modes>

<<< ../../example/lib/docs/theme_preview_demo.dart#theme-preview

</ComponentDemo>

从仓库根目录启动现有 Flutter 画廊。在「主题风格与外观模式」里选择预设，随后用参数控件实时比较颜色、圆角和材质。

```sh
cd example
flutter run
```

<ApiLink symbol="YumeiroThemePreset" />

<ApiLink symbol="YumeiroThemePreset.resolveColors" />

<ApiLink symbol="YumeiroThemePreset.options" />

<ApiLink symbol="YumeiroThemeFamily" />

<ApiLink symbol="YumeiroThemeRegistry" />

<ApiLink symbol="YumeiroThemeRegistry.presetById" />

<ApiLink symbol="YumeiroThemeOption" />
