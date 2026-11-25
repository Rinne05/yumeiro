# Yumeiro

简体中文说明见仓库中的 `README.zh-CN.md`。

An independent, business-agnostic Flutter UI framework driven by **extensible semantic visual recipes**, a **pluggable material rendering pipeline**, and **unified touch/pointer modality adaptation**.

## Documentation

The VitePress site in `docs/` includes usage guides, component examples with live Flutter Web previews, and the generated Dart API reference. With Flutter 3.50.1 or later and Node.js 22 or later installed, build and open the site from the repository root.

```sh
npm --prefix docs ci
npm --prefix docs run build
npm --prefix docs run preview
```

See `docs/components/index.md` for components, `docs/contributing.md` for the site workflow, and `CHANGELOG.md` for release notes.

## Architecture

1. **Open Semantic Visual Roles (`YumeiroVisualRole`)**
   - Extensible class-based role families (`YumeiroSurfaceRole`, `YumeiroControlRole`, `YumeiroItemRole`, `YumeiroStatusRole`) instead of closed enums.
   - Host applications define custom roles with explicit `fallback` chains; unregistered roles gracefully resolve through ancestor roles.
   - `YumeiroSemanticVisualTheme.extend(...)` and `.lerp(...)` preserve custom role recipes across theme transitions.

2. **Pluggable Effect Pipeline & Shader Fallback (`YumeiroEffectPass` & `YumeiroMaterialCapability`)**
   - Built-in passes (`YumeiroOuterShadowPass`, `YumeiroInnerShadowPass`, `YumeiroBackdropBlurPass`, `YumeiroLiquidGlassPass`, `YumeiroTintOverlayPass`) plus custom host subclasses of `YumeiroEffectPass`.
   - Global capability tiering (`fullOptical` / `blurOnly`) via `YumeiroMaterialCapabilityScope` automatically falls back from optical liquid-glass shaders to Gaussian blur when `ImageFilter.shader` is unsupported.

3. **Unified Modality & Density (`YumeiroModalityScope`)**
   - Single adaptive component APIs without split mobile/desktop duplicates.
   - `YumeiroModality` (`pointer` / `touch`) + `YumeiroDensity` (`compact` / `standard` / `comfortable`) + `YumeiroScreenClass` (`compact` / `medium` / `expanded` / `wide`) drive hit targets, spacing, typography, and layout shells (`YumeiroNavigationShell`, `YumeiroDialog.show`).

4. **Open Theme Registry (`YumeiroThemeRegistry`)**
   - 13 built-in families with 24 presets. Classic, Neumorphic, Minimal, Liquid Glass, Ceramic Glaze, Brushed Metal, Neo-Brutalist, Pixel Retro, Frosted Acrylic, Soft Silicone, and Thick Frosted Glass each provide light and dark variants. Geek remains dark-only; Sketch remains light-only.
   - Host apps can clone `YumeiroThemeRegistry.standard()` or start from `YumeiroThemeRegistry.empty()` and call `registerFamily` / `registerPreset`.

5. **Internationalization & Asset Decoupling**
   - Built-in `YumeiroLocalizations` (`en` / `zh`) with delegate/subclass overrides.
   - Zero business-specific copy or brand assets; icons (`YumeiroIconSet`) and typography (`YumeiroFontConfig`) are fully injectable.

## Naming & Prefix Conventions

- Public classes, enums, mixins, extensions, and typedefs use the `Yumeiro` prefix (`YumeiroScope`, `YumeiroApp`, `YumeiroTheme`, `YumeiroButton`, etc.).
- Public top-level functions and constants include the library name, as in `yumeiroThemeData`, `showYumeiroToast`, and `kYumeiroFontFallback`.

## Quick Start

Yumeiro and its example gallery require Flutter 3.50.1 or later and Dart 3.14 or later. For a source checkout alongside your app, add these entries to the app's `pubspec.yaml`.

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

Run `flutter pub get`, then use this as the app's `lib/main.dart`.

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
          title: 'Hello, Yumeiro',
          body: Center(child: Text('Your first Yumeiro page')),
        ),
      ),
    ),
  );
}
```

For a Git dependency, pin the checkout's repository address and commit or tag. The installation guide in `docs/guide/getting-started.md` covers host integration and the verified platforms.

The gallery guide in `example/README.md` has launch commands and examples of form validation, table selection, and server-side pagination. In the gallery, **Theme Style & Appearance** shows one card per family (14 cards including the custom Nordic Amber style), with a separate Light/Dark selector. Style cards preview the preferred appearance, and only one family is selected at a time. Single-variant styles show a fixed mode without changing the preference used when returning to a dual-variant family. Changing appearance within a family preserves live customization; choosing a different family resets its accent and options.

## Material presets and reuse

Chinese display names include 新拟态 (Neumorphic), 素描 (Sketch), 釉面陶瓷 (Ceramic Glaze), 磨砂亚克力 (Frosted Acrylic), and 复古像素 (Pixel Retro). These labels do not change theme IDs or public API names.

The material and graphic presets expose different recipes, each available in light and dark variants:

| Preset | Appearance |
| --- | --- |
| `YumeiroThemePresets.ceramicLight` | Opaque glazed ceramic with a broad reflection and lit rim |
| `YumeiroThemePresets.brushedMetalLight` | Opaque metal with directional grain and reflection bands |
| `YumeiroThemePresets.neoBrutalistLight` | Solid color blocks, including hover and press fills, with heavy outlines and offset hard shadows |
| `YumeiroThemePresets.pixelLight` | Stepped borders, flat colors and monospaced type |
| `YumeiroThemePresets.acrylicLight` | Translucent tint with diffuse Gaussian backdrop blur |
| `YumeiroThemePresets.siliconeLight` | Opaque matte pastel surfaces with soft pressed states |
| `YumeiroThemePresets.frostedGlassLight` | Dense frosted glass with blur and optical edge refraction |

Use `YumeiroThemePresets.ceramicLight` or `.ceramicDark` to choose a variant explicitly. The light variants retain their persisted IDs and remain the default for these families. For example, `ceramicLight` uses `yumeiro.ceramic` and `ceramicDark` uses `yumeiro.ceramic.dark`.

`YumeiroMaterials` exposes reusable `ceramic`, `brushedMetal`, `acrylic`, `silicone`, and `frostedGlass` factories. Materials contain fill, outline, and effects independently of typography and shape. For example, this keeps the current panel geometry and text styling while applying metal:

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
  child: const Text('Reusable metal panel'),
);
```

Material factories accept `brightness: Brightness.dark` to use the dark lighting recipe independently of the fill color. This is useful for bright accent controls inside a dark theme. When omitted, very dark base colors select dark lighting automatically; existing light recipe calls retain their defaults.

Use materials in semantic role recipes, or pass their fill, outline, and effects through a component's `visualOverride`. Keep hover, pressed, disabled, selected, and keyboard focus states when customizing interactive roles. The gallery includes a working ceramic button, acrylic card, and metal panel on the same page.

During appearance transitions, solid fills retain their visible color as they fade to transparency. Outer shadows fade in opacity when added or removed.

Use `copyWith` to change a material's fill, outline, or entire effect stack, and `withPass` to add or replace a finish by its type and identifier. Custom passes can implement `paintMaterial` for clipped decoration below labels and icons. Use `paintForeground` for effects drawn above the content. Both hooks receive `textDirection` for directional shapes and gradients.

Acrylic and frosted glass need artwork or other visual content behind them; the host owns that background. Acrylic uses Gaussian blur without optical refraction. Frosted Glass and Liquid Glass add edge refraction where shader image filters are supported and fall back to Gaussian blur elsewhere. These are two-dimensional UI material approximations, with deterministic lighting rather than a physically based 3D material system.

Gaussian blur and optical input snapshots use Flutter's standard `srcOver` backdrop compositing. On partially transparent host backgrounds this can increase the resulting opacity; an opaque backdrop retains full opacity without transparent edge seams. Optical surfaces keep an independent input snapshot so ancestor clips and offscreen layers preserve their edge coordinates. Fully faded materials bypass filtering and restore the original background.

The effect stack exposes shadow lists and one core blur/glass material per surface; core getters resolve the first pass of each type. Its order does not define an arbitrary filter graph. Custom `YumeiroEffectPass` subclasses can add texture, sheen, or wrappers. `YumeiroFill` currently supports solid and gradient fills; image textures can be supplied by custom passes. A local `visualOverride` takes precedence over the nearest `YumeiroVisualScope`; effect overrides replace the stack rather than implicitly merging nested materials.

Pixel Retro ships without a bundled pixel font. Its portable default is monospace; register a suitable font asset in the host app, then inject its family for pixel glyphs (including CJK coverage where needed):

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

## License

MIT © 2026 Rinne05. See `LICENSE` for the license text.
