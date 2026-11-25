# Yumeiro

[English](README.md)

Yumeiro 是一个独立的通用 Flutter UI 框架，提供**可扩展的语义视觉配方**、**可插拔的材质渲染管线**，以及**统一的触控与指针适配**。

## 文档

`docs/` 下的 VitePress 站点包含使用指南、支持 Flutter Web 交互预览的组件示例，以及生成的 Dart API 参考。安装 Flutter 3.50.1 或更高版本和 Node.js 22 或更高版本后，从仓库根目录构建和预览站点。

```sh
npm --prefix docs ci
npm --prefix docs run build
npm --prefix docs run preview
```

可查阅[组件目录](docs/components/index.md)、[文档维护指南](docs/contributing.md)和[更新日志](CHANGELOG.md)。

## 架构

1. **开放的语义视觉角色（`YumeiroVisualRole`）**
   - `YumeiroSurfaceRole`、`YumeiroControlRole`、`YumeiroItemRole` 和 `YumeiroStatusRole` 是可扩展的角色类型。
   - 宿主应用可以定义自有角色并通过 `fallback` 指定回退关系。未登记配方的角色沿这条链查找可用配方。
   - `YumeiroSemanticVisualTheme.extend(...)` 和 `.lerp(...)` 在主题过渡时保留自定义角色配方。

2. **可插拔的效果管线与着色器回退（`YumeiroEffectPass`、`YumeiroMaterialCapability`）**
   - 内置 `YumeiroOuterShadowPass`、`YumeiroInnerShadowPass`、`YumeiroBackdropBlurPass`、`YumeiroLiquidGlassPass` 和 `YumeiroTintOverlayPass`，宿主还可以继承 `YumeiroEffectPass` 添加效果。
   - `YumeiroMaterialCapabilityScope` 提供 `fullOptical` 和 `blurOnly` 两个能力档位。渲染器不支持 `ImageFilter.shader` 时，液态玻璃从光学效果自动回退为高斯模糊。

3. **统一的交互方式与密度（`YumeiroModalityScope`）**
   - 触控端与桌面端共用一套自适应组件接口。
   - `YumeiroModality`（`pointer`、`touch`）、`YumeiroDensity`（`compact`、`standard`、`comfortable`）和 `YumeiroScreenClass`（`compact`、`medium`、`expanded`、`wide`）共同决定交互区域、间距、排版和布局容器的呈现，例如 `YumeiroNavigationShell` 和 `YumeiroDialog.show`。

4. **开放的主题注册表（`YumeiroThemeRegistry`）**
   - 内置 13 个主题家族，共 24 个预设。经典、新拟态、极简、液态玻璃、釉面陶瓷、拉丝金属、新粗野主义、复古像素、磨砂亚克力、软硅胶和厚磨砂玻璃均提供浅色与深色版本。极客仅提供深色，素描仅提供浅色。
   - 宿主可以用 `YumeiroThemeRegistry.standard()` 创建可独立修改的标准注册表，也可以用 `YumeiroThemeRegistry.empty()` 创建空注册表，再调用 `registerFamily` 或 `registerPreset`。

5. **国际化与资源注入**
   - `YumeiroLocalizations` 内置英语（`en`）和中文（`zh`），可通过本地化委托与子类覆盖。
   - 组件使用通用文案，图标（`YumeiroIconSet`）和字体（`YumeiroFontConfig`）由宿主按需注入。

## 命名与前缀

- 公开的类、枚举、混入、扩展与类型别名使用 `Yumeiro` 前缀，例如 `YumeiroScope`、`YumeiroApp`、`YumeiroTheme` 和 `YumeiroButton`。
- 公开的顶层函数和常量包含库名，例如 `yumeiroThemeData`、`showYumeiroToast` 和 `kYumeiroFontFallback`。

## 快速开始

Yumeiro 和示例画廊需要 Flutter 3.50.1 或更高版本，以及 Dart 3.14 或更高版本。如果将 Yumeiro 源码检出到应用的同级目录，可在应用的 `pubspec.yaml` 中加入以下内容。

```yaml
dependencies:
  flutter:
    sdk: flutter
  material_ui: ^1.11.1
  yumeiro:
    path: ../yumeiro

flutter:
  uses-material-design: true
```

运行 `flutter pub get`，将以下代码用作应用的 `lib/main.dart`。

```dart
import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

void main() {
  runApp(
    YumeiroApp(
      preset: YumeiroThemePresets.classicLight,
      home: const YumeiroVisualSurface(
        role: YumeiroSurfaceRole.canvas,
        child: YumeiroPageScaffold.detail(
          title: '你好，Yumeiro',
          body: Center(child: Text('你的第一个 Yumeiro 页面')),
        ),
      ),
    ),
  );
}
```

通过 Git 引入依赖时，请指定仓库地址并固定提交或标签。[安装指南](docs/guide/getting-started.md)介绍了宿主应用的接入方式和已验证的平台。

[画廊指南](example/README.md)列出了启动命令，并介绍表单校验、表格选择和服务端分页示例。画廊的「主题风格与外观模式」为每个主题家族展示一张卡片，13 个内置家族加上自定义的 Nordic Amber，共 14 张。浅色和深色由独立的选择器控制，卡片按当前外观偏好展示预览，每次选中一个家族。仅有一种外观的家族显示固定模式，切回支持两种外观的家族时会恢复原来的外观偏好。在同一家族内切换明暗会保留实时定制，切换家族会重置强调色和选项。

## 材质预设与复用

新拟态（Neumorphic）、素描（Sketch）、釉面陶瓷（Ceramic Glaze）、磨砂亚克力（Frosted Acrylic）和复古像素（Pixel Retro）是面向用户的中文显示名。主题 ID 与公开接口使用固定标识。

下列材质与图形预设各自提供不同的视觉配方，均有浅色和深色版本。

| 预设 | 外观 |
| --- | --- |
| `YumeiroThemePresets.ceramicLight` | 不透明的釉面陶瓷，带宽幅反光与亮边 |
| `YumeiroThemePresets.brushedMetalLight` | 不透明的金属，带方向性纹理与反射条带 |
| `YumeiroThemePresets.neoBrutalistLight` | 使用实色色块、粗描边和偏移硬阴影，悬停与按下也使用实色填充 |
| `YumeiroThemePresets.pixelLight` | 阶梯状边框、平涂色和等宽字体 |
| `YumeiroThemePresets.acrylicLight` | 半透明着色，带柔和的高斯背景模糊 |
| `YumeiroThemePresets.siliconeLight` | 低饱和度的不透明哑光表面，带柔和的按压效果 |
| `YumeiroThemePresets.frostedGlassLight` | 厚磨砂玻璃，带背景模糊和光学边缘折射 |

使用 `YumeiroThemePresets.ceramicLight` 或 `YumeiroThemePresets.ceramicDark` 可明确选择版本。这些家族以浅色为默认版本，并沿用浅色预设原有的持久化 ID。例如，`ceramicLight` 使用 `yumeiro.ceramic`，`ceramicDark` 使用 `yumeiro.ceramic.dark`。

`YumeiroMaterials` 提供可复用的 `ceramic`、`brushedMetal`、`acrylic`、`silicone` 和 `frostedGlass` 工厂。材质独立定义填充、描边和效果。以下示例为当前面板应用金属材质，同时保留面板的形状和文本样式。

```dart
final theme = YumeiroTheme.of(context);
final material = YumeiroMaterials.brushedMetal(
  color: const Color(0xFFD7DFE5),
  texture: 0.8,
);
final appearance = material.applyTo(
  theme.visuals.surface(YumeiroSurfaceRole.panel),
);
return YumeiroResolvedVisualSurface(
  appearance: appearance,
  padding: const EdgeInsets.all(20),
  child: const Text('可复用的金属面板'),
);
```

材质工厂支持 `brightness: Brightness.dark`，可以独立于填充色选择深色光照配方，适用于深色主题里的明亮强调控件。省略 `brightness` 时，底色很深的材质自动采用深色光照，浅色配方沿用原有默认值。

可在语义角色配方中使用材质，或通过组件的 `visualOverride` 应用材质的填充、描边和效果。自定义交互角色时，请保留悬停、按下、禁用、选中和键盘焦点状态。画廊在同一页面展示了陶瓷按钮、亚克力卡片和金属面板。

外观过渡时，实色填充以原来的色相淡出至透明。外侧阴影在添加或移除时会渐变透明度。

使用 `copyWith` 修改填充、描边或整个效果栈，使用 `withPass` 按类型和标识添加或替换效果。自定义通道可通过 `paintMaterial` 在表面形状内绘制位于文字和图标下方的装饰，通过 `paintForeground` 在内容上方绘制。两个钩子都接收 `textDirection`，可用于处理有方向性的形状和渐变。

亚克力和厚磨砂玻璃需要由宿主提供背景图或其他可采样的内容。亚克力使用高斯模糊。厚磨砂玻璃与液态玻璃在支持着色器图像过滤时增加边缘折射，在其他环境下使用高斯模糊。这些材质用固定的光照规则在二维界面中模拟真实质感。

高斯模糊与光学输入快照采用 Flutter 的 `srcOver` 背景合成方式。宿主背景半透明时，合成后的不透明度可能增加。背景不透明时，边缘也保持不透明。光学表面独立保存输入快照，使上层裁剪与离屏图层保留边缘坐标。材质完全淡出后会跳过过滤，恢复原有背景。

效果栈提供阴影列表，每种核心模糊或玻璃效果的读取方法返回首个匹配的通道。背景采样使用每个表面的一个核心效果。自定义 `YumeiroEffectPass` 子类可以添加纹理、高光或包裹表面的绘制层。`YumeiroFill` 支持纯色和渐变，图像纹理可以通过自定义通道提供。局部 `visualOverride` 优先于最近的 `YumeiroVisualScope`，覆盖效果时替换整组效果栈。

复古像素默认使用等宽字体。需要像素字形时，在宿主应用中注册合适的字体资源，再注入字体家族。有中文、日文或韩文内容时，请选择包含相应字形的字体。

```dart
YumeiroApp(
  preset: YumeiroThemePresets.pixelLight,
  fontConfig: const YumeiroFontConfig(
    fontFamily: 'MyPixelFont',
    monoFontFamily: 'MyPixelFont',
  ),
  home: MyHomePage(),
)
```

## 许可证

MIT © 2026 Rinne05。许可证全文见 [LICENSE](LICENSE)。
