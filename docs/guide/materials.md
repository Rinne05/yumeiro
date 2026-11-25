---
description: 复用陶瓷、金属、亚克力、硅胶和玻璃材质，了解渲染能力与自定义效果。
---

# 材质与玻璃

角色配方决定组件的完整外观。`YumeiroVisualMaterial` 将其中的填充、描边和效果做成可复用的对象。同一页可以让面板使用拉丝金属、按钮使用陶瓷、卡片使用亚克力，继续沿用当前主题的几何和内容排版。

<ComponentDemo id="materials" title="材质预览" :overlay-height="340">

<<< ../../example/lib/docs/demos.dart#materials

</ComponentDemo>

## 复用现有材质

`YumeiroMaterials` 提供 `ceramic`、`brushedMetal`、`acrylic`、`silicone` 和 `frostedGlass`。可传入 `brightness` 指定明暗适配的光照配方。`material.applyTo(appearance)` 应用填充、轮廓和效果栈，保留原外观的形状、前景色、焦点与动效。

```dart
Widget buildMetalPanel(BuildContext context) {
  final theme = YumeiroTheme.of(context);
  final metal = YumeiroMaterials.brushedMetal(
    color: const Color(0xFFD7DFE5),
    texture: 0.8,
  );
  final panel = theme.visuals.surface(YumeiroSurfaceRole.panel);

  return YumeiroResolvedVisualSurface(
    appearance: metal.applyTo(panel),
    padding: EdgeInsets.all(theme.spacing.xl),
    child: const Text('拉丝金属面板'),
  );
}
```

在交互控件上使用材质时，为普通、悬停、按下、选中和禁用状态分别保留需要的视觉反馈，可以通过[视觉角色与令牌](./visual-roles)中的配方和差量设置。

## 材质能力

`YumeiroMaterialCapability.fullOptical` 请求启用光学玻璃和模糊。如果当前 Flutter 渲染器不支持 `ImageFilter.shader`，有效档位会解析成 `blurOnly`。显式给 `YumeiroApp` 或 `YumeiroScope` 传 `capability: YumeiroMaterialCapability.blurOnly`，可以在支持光学的设备上复查回退路径。

```dart
YumeiroMaterialCapability activeCapability(BuildContext context) {
  return YumeiroMaterialCapabilityScope.of(context).resolveForRuntime();
}
```

亚克力本身使用高斯背景模糊。液态玻璃和厚磨砂玻璃在光学着色器就绪后增加边缘折射。着色器加载中、加载失败或渲染器不支持光学时，使用高斯模糊和着色。没有显式模糊时，模糊半径按玻璃强度推导。没有显式回退色时，使用玻璃着色并按强度调整透明度。请用目标设备核对折射、边缘与透明度。文档预览使用当前浏览器的 Flutter Web 渲染能力。

玻璃采样位于其后方已绘制的内容，背景图或颜色由应用提供。若场景只有一块纯色，折射的变化会很小。若玻璃需要表现实时模糊或折射，使用 `YumeiroResolvedVisualSurface` 或接受对应角色的组件。`materialDecoration` 适用于只绘制装饰的场景，它没有实时背景采样。

### 采样边界

将背景和表面放在同一个叠放布局中，先绘制背景，再绘制玻璃及其内容。玻璃表面形状与其祖先裁剪共同决定可见区域。如果列表滚动或浮层裁剪后才出现异常，缩小为一个带图案背景、一个表面和一个滚动区域，再逐步恢复祖先布局。

`YumeiroBackdropGroup` 让采样相同背景且彼此不重叠的模糊表面共享采样键。应用根部的 `YumeiroScope` 已提供一个组。绘制过的表面为子内容建立新的采样边界，便于子控件读取自身所在的局部背景。自定义低层绘制时，`YumeiroGlassSamplingScope` 负责传递这个键，传入空键可断开共享。重叠的模糊表面需要各取自己的区域，给它们分开采样。光学玻璃按各表面的变换与裁剪计算采样区域。

### 排查折射和模糊

1. 在目标设备打开 Liquid Glass 或 Thick Frosted Glass。让一个表面覆盖在分色或带图案的背景上，再移动背景或滚动区域，便于观察边缘。
2. 从表面下的 `BuildContext` 读取 `YumeiroMaterialCapabilityScope.of(context).resolveForRuntime()`。有效档位为 `blurOnly` 时，检查回退模糊和着色。渲染器需要支持 `ImageFilter.shader` 才能进入光学路径，Web 和原生都按运行时能力判断。
3. 档位为 `fullOptical` 时，检查当前角色的效果栈是否包含玻璃通道，并关注启动日志中的着色器加载问题。若只在初次打开时延迟出现折射，可以在已初始化 Flutter 的启动流程中调用 `YumeiroGlassBackdrop.warmUp()`，预载光学程序。
4. 把同一个预设依次放在 `fullOptical` 与显式 `blurOnly` 的作用域中。观察背景细节是否发生位移，以及多层裁剪、滚动和缩放后的位置。背景采样附近有多个重叠表面时，先分离共享模糊组再判断。

Linux 本机可从仓库根目录进入画廊，启动目标设备后使用主题区的回退开关对照。

```sh
cd example
flutter run -d linux -t lib/main_desktop.dart
```

从仓库根目录运行下列回归测试，覆盖边缘、随滚动变化的裁剪，以及着色器加载失败时的回退。测试如果因运行时不支持着色器过滤而跳过，应到支持的目标设备验证折射。

```sh
flutter test --enable-impeller \
  test/glass_edge_compositing_test.dart \
  test/glass_backdrop_perf_test.dart
```

## 扩展效果

`YumeiroEffectStack` 支持内外阴影、核心背景模糊或玻璃、以及自定义装饰。`withPass` 用类型和 `id` 匹配并替换现有效果；类型和 `id` 都匹配时还可在配方间插值。背景采样取自一个核心效果，添加多个同类通道不会依次过滤同一个底图。

| 用途 | 效果 |
| --- | --- |
| 模糊与着色 | <ApiLink symbol="YumeiroBackdropBlurPass" /> |
| 折射、边缘光和模糊回退 | <ApiLink symbol="YumeiroLiquidGlassPass" /> 与其 <ApiLink symbol="YumeiroGlassEffect" /> 参数 |
| 外侧阴影和内侧凹凸 | <ApiLink symbol="YumeiroOuterShadowPass" />、<ApiLink symbol="YumeiroInnerShadowPass" /> |
| 装饰着色、反光和纹理 | <ApiLink symbol="YumeiroTintOverlayPass" />、<ApiLink symbol="YumeiroSheenPass" />、<ApiLink symbol="YumeiroBrushedTexturePass" /> |

扩展 `YumeiroEffectPass` 时，按绘制位置选择钩子。

| 钩子 | 绘制位置 |
| --- | --- |
| `paintBeforeFill` | 填充后方的装饰 |
| `paintMaterial` | 填充和内容之间的纹理、高光或饰面，在表面形状内裁剪 |
| `paintForeground` | 在内容上方绘制 |
| `wrapSurface` | 在效果启用时包裹表面的绘制子树 |

渲染器按有效档位执行内置效果和自定义效果。`YumeiroLiquidGlassPass` 在光学档位不可用时以高斯模糊和着色降级。为自定义效果指定 `minCapability`，并在 `lerp(other, t)` 中支持渐变。当 `other` 为 `null` 时，返回逐渐减弱的效果，结束时可返回 `null`。若同一效果在两端要求不同档位，主题插值会先淡出旧效果，再淡入新效果。`paintMaterial` 和 `paintForeground` 提供 `textDirection`，可用于解析随文字方向变化的形状和渐变。

效果栈、内外阴影和焦点光晕接收列表的不可变快照。调整效果时构造新列表，或通过 `withPass`、`withoutPass` 得到新的效果栈。

<ApiLink symbol="YumeiroMaterials" />

<ApiLink symbol="YumeiroVisualMaterial" />

<ApiLink symbol="YumeiroMaterialCapability" />

<ApiLink symbol="YumeiroMaterialCapability.resolveForRuntime" />

<ApiLink symbol="YumeiroMaterialCapabilityScope" />

<ApiLink symbol="YumeiroBackdropGroup" />

<ApiLink symbol="YumeiroGlassSamplingScope" />

<ApiLink symbol="YumeiroGlassBackdrop.warmUp" />

<ApiLink symbol="YumeiroEffectPass" />

<ApiLink symbol="YumeiroEffectStack" />
