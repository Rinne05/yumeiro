import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../foundation/color_math.dart';
import '../foundation/colors.dart';
import '../foundation/icons.dart';
import '../foundation/motion.dart';
import '../foundation/radii.dart';
import '../foundation/spacing.dart';
import '../foundation/typography.dart';
import '../l10n/localizations.dart';
import '../primitives/pixel_border.dart';
import 'effect_pass.dart';
import 'materials.dart';
import 'semantic_visuals.dart';
import 'theme_options.dart';
import 'visual_role.dart';

part 'theme_presets_material.dart';
part 'theme_presets_stylized.dart';
part 'theme_presets_finishes.dart';
part 'theme_presets_graphic.dart';

/// Derives coordinated color tokens from the preset palette and a host accent.
typedef YumeiroAccentCustomizer = YumeiroColorTokens Function(
  YumeiroColorTokens colors,
  Color accent,
);

/// Maps resolved Yumeiro colors to the Material color scheme.
typedef YumeiroMaterialSchemeBuilder = ColorScheme Function(
  YumeiroColorTokens colors,
);

/// Builds role recipes from resolved tokens and the active preset parameters.
///
/// The parameter map contains resolved values for supplied options. A builder
/// should provide defaults when an option is absent.
typedef YumeiroSemanticVisualThemeBuilder = YumeiroSemanticVisualTheme Function(
  YumeiroColorTokens colors,
  YumeiroRadiiTokens radii,
  YumeiroMotion motion, [
  Map<String, Object> parameters,
]);

/// Builds typography using resolved colors and the host's font configuration.
typedef YumeiroTypographyBuilder = YumeiroTypographyTokens Function(
  YumeiroColorTokens colors,
  YumeiroFontConfig fontConfig,
);

/// Derives the Material slider styling from the resolved palette, type, and
/// active preset parameters. Provide defaults for absent option values.
typedef YumeiroSliderThemeBuilder = SliderThemeData Function(
  YumeiroColorTokens colors,
  YumeiroTypographyTokens typography, {
  required Map<String, Object> parameters,
});

/// Resolves checkbox-specific visuals from colors, radii, and role recipes.
typedef YumeiroCheckboxVisualsBuilder = YumeiroCheckboxVisuals Function(
  YumeiroColorTokens colors,
  YumeiroRadiiTokens radii,
  YumeiroSemanticVisualTheme visuals,
);

/// Resolves switch-specific visuals from colors and role recipes.
typedef YumeiroSwitchVisualsBuilder = YumeiroSwitchVisuals Function(
  YumeiroColorTokens colors,
  YumeiroSemanticVisualTheme visuals,
);

/// Appearance preference used to look up a preset within a theme family.
enum YumeiroThemeVariant { light, dark }

/// Recommended backdrop contrast polarity when hosts overlay artwork behind
/// detail pages or hero headers.
enum YumeiroMediaBackdropTone { cinematicDark, airyLight }

/// Complete, self-contained visual preset definition.
///
/// Host applications can construct custom [YumeiroThemePreset] instances and
/// register them via [YumeiroThemeRegistry].
@immutable
class YumeiroThemePreset {
  /// Defines a full preset with a stable identifier and palette-based builders.
  ///
  /// Extending an existing preset through [copyWith] retains its authored
  /// builders and is useful for changing a specific theme token.
  const YumeiroThemePreset({
    required this.id,
    required this.label,
    required this.brightness,
    required this.colors,
    required this.materialSchemeBuilder,
    required this.visualsBuilder,
    required this.categoricalPaletteBuilder,
    this.spacing = const YumeiroSpacing(),
    this.radii = const YumeiroRadiiTokens(),
    this.motion = const YumeiroMotion(),
    this.iconSizes = const YumeiroIconSizes(),
    this.typographyBuilder = _defaultTypographyBuilder,
    this.sliderThemeBuilder = _defaultSliderThemeBuilder,
    this.checkboxVisualsBuilder = _defaultCheckboxVisualsBuilder,
    this.switchVisualsBuilder = _defaultSwitchVisualsBuilder,
    this.modalVisuals = const YumeiroModalVisuals(),
    this.mediaBackdropTone = YumeiroMediaBackdropTone.cinematicDark,
    this.icon,
    this.iconBuilder,
    this.accentCustomizer,
    this.customizationOptions = const [],
    this.supportsBorderCustomization = true,
    this.preserveStateBorderColors = false,
    this.supportsHardShadowCustomization = false,
  });

  /// Stable key for registration, persistence, localization, and lookup.
  final String id;

  /// Display name used when localization does not supply one for [id].
  final String label;

  /// Fixed picker icon, with priority over [iconBuilder].
  final IconData? icon;

  /// Resolves a picker icon with the host's icon set.
  final IconData Function(YumeiroIconSet icons)? iconBuilder;

  /// Brightness of this preset. The palette and builders author its visuals.
  final Brightness brightness;

  /// Authored palette, used before accent and other host customization.
  final YumeiroColorTokens colors;

  /// Maps the resolved palette into Material defaults for descendant widgets.
  final YumeiroMaterialSchemeBuilder materialSchemeBuilder;

  /// Builds semantic appearance recipes from the resolved tokens.
  final YumeiroSemanticVisualThemeBuilder visualsBuilder;

  /// Builds an ordered color palette for differentiating data categories.
  final List<Color> Function(YumeiroColorTokens colors)
  categoricalPaletteBuilder;

  /// Baseline layout spacing in logical pixels.
  final YumeiroSpacing spacing;

  /// Corner radii before the user's roundness adjustment.
  final YumeiroRadiiTokens radii;

  /// Transition durations when advanced motion is enabled.
  final YumeiroMotion motion;

  /// Logical sizes for icons in the preset.
  final YumeiroIconSizes iconSizes;

  /// Produces the text theme from resolved colors and host font preferences.
  final YumeiroTypographyBuilder typographyBuilder;

  /// Produces slider styling using the active palette and typography.
  final YumeiroSliderThemeBuilder sliderThemeBuilder;

  /// Produces component-specific check box styling.
  final YumeiroCheckboxVisualsBuilder checkboxVisualsBuilder;

  /// Produces component-specific switch styling.
  final YumeiroSwitchVisualsBuilder switchVisualsBuilder;

  /// Chrome policy for dialogs, popovers, and related surfaces.
  final YumeiroModalVisuals modalVisuals;

  /// Suggested contrast polarity for artwork behind media content.
  final YumeiroMediaBackdropTone mediaBackdropTone;

  /// Optional palette transformation invoked when an accent is supplied.
  final YumeiroAccentCustomizer? accentCustomizer;

  /// Additional options that follow the built-in declarations in [options].
  ///
  /// Give each option its own stable key within the preset.
  final List<YumeiroThemeOption> customizationOptions;

  /// Whether [options] includes the built-in border color setting.
  final bool supportsBorderCustomization;

  /// Changes the line palette while allowing recipes to keep state colors.
  final bool preserveStateBorderColors;

  /// Exposes the independent hard shadow color used by graphic recipes.
  final bool supportsHardShadowCustomization;

  /// Clones a preset while retaining its component builders and host hooks.
  /// Changing brightness alone does not replace its palette or recipes.
  /// Null arguments retain the existing values, including optional hooks.
  /// Give standalone host clones a new [id] when registering them.
  YumeiroThemePreset copyWith({
    String? id,
    String? label,
    Brightness? brightness,
    YumeiroColorTokens? colors,
    YumeiroMaterialSchemeBuilder? materialSchemeBuilder,
    YumeiroSemanticVisualThemeBuilder? visualsBuilder,
    List<Color> Function(YumeiroColorTokens colors)? categoricalPaletteBuilder,
    YumeiroSpacing? spacing,
    YumeiroRadiiTokens? radii,
    YumeiroMotion? motion,
    YumeiroIconSizes? iconSizes,
    YumeiroTypographyBuilder? typographyBuilder,
    YumeiroSliderThemeBuilder? sliderThemeBuilder,
    YumeiroCheckboxVisualsBuilder? checkboxVisualsBuilder,
    YumeiroSwitchVisualsBuilder? switchVisualsBuilder,
    YumeiroModalVisuals? modalVisuals,
    YumeiroMediaBackdropTone? mediaBackdropTone,
    IconData? icon,
    IconData Function(YumeiroIconSet icons)? iconBuilder,
    YumeiroAccentCustomizer? accentCustomizer,
    List<YumeiroThemeOption>? customizationOptions,
    bool? supportsBorderCustomization,
    bool? preserveStateBorderColors,
    bool? supportsHardShadowCustomization,
  }) => YumeiroThemePreset(
    id: id ?? this.id,
    label: label ?? this.label,
    brightness: brightness ?? this.brightness,
    colors: colors ?? this.colors,
    materialSchemeBuilder: materialSchemeBuilder ?? this.materialSchemeBuilder,
    visualsBuilder: visualsBuilder ?? this.visualsBuilder,
    categoricalPaletteBuilder:
        categoricalPaletteBuilder ?? this.categoricalPaletteBuilder,
    spacing: spacing ?? this.spacing,
    radii: radii ?? this.radii,
    motion: motion ?? this.motion,
    iconSizes: iconSizes ?? this.iconSizes,
    typographyBuilder: typographyBuilder ?? this.typographyBuilder,
    sliderThemeBuilder: sliderThemeBuilder ?? this.sliderThemeBuilder,
    checkboxVisualsBuilder:
        checkboxVisualsBuilder ?? this.checkboxVisualsBuilder,
    switchVisualsBuilder: switchVisualsBuilder ?? this.switchVisualsBuilder,
    modalVisuals: modalVisuals ?? this.modalVisuals,
    mediaBackdropTone: mediaBackdropTone ?? this.mediaBackdropTone,
    icon: icon ?? this.icon,
    iconBuilder: iconBuilder ?? this.iconBuilder,
    accentCustomizer: accentCustomizer ?? this.accentCustomizer,
    customizationOptions: customizationOptions ?? this.customizationOptions,
    supportsBorderCustomization:
        supportsBorderCustomization ?? this.supportsBorderCustomization,
    preserveStateBorderColors:
        preserveStateBorderColors ?? this.preserveStateBorderColors,
    supportsHardShadowCustomization:
        supportsHardShadowCustomization ?? this.supportsHardShadowCustomization,
  );

  /// Looks up a localized name, using the authored [label] as fallback.
  String resolveLabel(YumeiroLocalizations l10n) =>
      l10n.resolvePresetLabel(id, label);

  /// Chooses the explicit [icon], the [iconBuilder], then the brightness icon.
  IconData resolveIcon(YumeiroIconSet icons) =>
      icon ??
      iconBuilder?.call(icons) ??
      (brightness == Brightness.dark ? icons.themeDark : icons.themeLight);

  /// Whether an accent can derive new colors for this preset.
  bool get supportsAccentCustomization => accentCustomizer != null;

  /// Settings declarations available for this preset.
  ///
  /// Includes compatible built-in palette controls, roundness, selection
  /// strength, and the preset's [customizationOptions], in that order.
  List<YumeiroThemeOption> get options => [
    if (supportsAccentCustomization)
      YumeiroThemeColorOption(
        id: 'accent',
        label: 'Accent Color',
        localizedLabel: (l) => l.optionAccentColor,
        defaultValue: colors.accent,
        adjustment: YumeiroThemeAdjustment.accent,
      ),
    if (supportsBorderCustomization)
      YumeiroThemeColorOption(
        id: 'borderColor',
        label: 'Custom Border Color',
        localizedLabel: (l) => l.optionBorderColor,
        localizedDescription: (l) => l.optionBorderColorDescription,
        defaultValue: colors.lineStrong.withValues(alpha: 1),
        adjustment: preserveStateBorderColors
            ? YumeiroThemeAdjustment.paletteBorderColor
            : YumeiroThemeAdjustment.borderColor,
      ),
    YumeiroThemeColorOption(
      id: 'backgroundTone',
      label: 'Background Tone',
      localizedLabel: (l) => l.optionBackgroundTone,
      description: 'Adjusts base surface hue and saturation while preserving luminance contrast.',
      localizedDescription: (l) => l.optionBackgroundToneDescription,
      defaultValue: colors.background,
      adjustment: YumeiroThemeAdjustment.backgroundTone,
    ),
    if (colors.panel case final panel?)
      YumeiroThemeColorOption(
        id: 'panelColor',
        label: 'Panel Color',
        localizedLabel: (l) => l.optionPanelColor,
        localizedDescription: (l) => l.optionPanelColorDescription,
        defaultValue: panel,
        adjustment: YumeiroThemeAdjustment.panelColor,
      ),
    if (supportsHardShadowCustomization)
      YumeiroThemeColorOption(
        id: 'hardShadowColor',
        label: 'Hard Shadow Color',
        localizedLabel: (l) => l.optionHardShadowColor,
        defaultValue: _graphicShadowColor(colors),
      ),
    yumeiroRoundnessOption,
    yumeiroSelectionStrengthOption,
    ...customizationOptions,
  ];

  /// Applies [accentCustomizer] to [colors] when both are available.
  ///
  /// With an absent accent or customizer, returns the authored [colors].
  YumeiroColorTokens resolveColors(Color? accent) =>
      accent == null || accentCustomizer == null
      ? colors
      : accentCustomizer!(colors, accent);
}

/// Groups light/dark variants under one thematic family.
@immutable
class YumeiroThemeFamily {
  /// Defines a picker entry with at least its [defaultVariant] registered.
  YumeiroThemeFamily({
    required this.id,
    required this.label,
    required Map<YumeiroThemeVariant, YumeiroThemePreset> variants,
    required this.defaultVariant,
    this.icon,
    this.iconBuilder,
  }) : assert(variants.containsKey(defaultVariant)),
       variants = Map.unmodifiable(variants);

  final String id;
  final String label;
  final IconData? icon;
  final IconData Function(YumeiroIconSet icons)? iconBuilder;

  /// Read-only snapshot of the available variants keyed by appearance.
  final Map<YumeiroThemeVariant, YumeiroThemePreset> variants;

  /// Variant selected when the preferred appearance is unavailable.
  final YumeiroThemeVariant defaultVariant;

  String resolveLabel(YumeiroLocalizations l10n) =>
      l10n.resolveFamilyLabel(id, label);

  IconData resolveIcon(YumeiroIconSet icons) =>
      icon ??
      iconBuilder?.call(icons) ??
      icons.forThemeFamily(id) ??
      resolve().resolveIcon(icons);

  /// Returns the preferred variant if present, otherwise the default preset.
  YumeiroThemePreset resolve([YumeiroThemeVariant? preferred]) =>
      variants[preferred] ?? variants[defaultVariant]!;

  bool containsPreset(String presetId) =>
      variants.values.any((preset) => preset.id == presetId);

  /// Finds the registered variant by preset ID, including equivalent clones.
  YumeiroThemeVariant? variantOf(YumeiroThemePreset preset) {
    for (final entry in variants.entries) {
      if (entry.value.id == preset.id) return entry.key;
    }
    return null;
  }
}

/// Stable identifiers for the built-in presets.
abstract final class YumeiroThemePresetIds {
  static const classicDark = 'yumeiro.classic.dark';
  static const classicLight = 'yumeiro.classic.light';
  static const geek = 'yumeiro.geek';
  static const sketch = 'yumeiro.sketch';
  static const neumorphicLight = 'yumeiro.neumorphic';
  static const minimalDark = 'yumeiro.minimal.dark';
  static const minimalLight = 'yumeiro.minimal.light';
  static const liquidGlassDark = 'yumeiro.liquid-glass.dark';
  static const liquidGlassLight = 'yumeiro.liquid-glass.light';
  static const ceramicLight = 'yumeiro.ceramic';
  static const brushedMetalLight = 'yumeiro.brushed-metal';
  static const neoBrutalistLight = 'yumeiro.neo-brutalist';
  static const pixelLight = 'yumeiro.pixel';
  static const acrylicLight = 'yumeiro.acrylic';
  static const siliconeLight = 'yumeiro.silicone';
  static const frostedGlassLight = 'yumeiro.frosted-glass';
  static const neumorphicDark = 'yumeiro.neumorphic.dark';
  static const ceramicDark = 'yumeiro.ceramic.dark';
  static const brushedMetalDark = 'yumeiro.brushed-metal.dark';
  static const neoBrutalistDark = 'yumeiro.neo-brutalist.dark';
  static const pixelDark = 'yumeiro.pixel.dark';
  static const acrylicDark = 'yumeiro.acrylic.dark';
  static const siliconeDark = 'yumeiro.silicone.dark';
  static const frostedGlassDark = 'yumeiro.frosted-glass.dark';
}

/// Built-in theme presets for direct application or host customization.
abstract final class YumeiroThemePresets {
  static final classicDark = YumeiroThemePreset(
    id: YumeiroThemePresetIds.classicDark,
    label: 'Classic · Dark',
    iconBuilder: (icons) => icons.themeDark,
    brightness: Brightness.dark,
    colors: YumeiroColorTokens.dark,
    materialSchemeBuilder: _darkMaterialScheme,
    accentCustomizer: _darkAccent,
    visualsBuilder: _darkVisuals,
    customizationOptions: [
      yumeiroSurfaceOpacityOption,
      yumeiroShadowOption,
      yumeiroShadowDistanceOption,
      yumeiroShadowSoftnessOption,
      yumeiroPressOption,
    ],
    categoricalPaletteBuilder: _darkCategoricalPalette,
  );

  static final classicLight = YumeiroThemePreset(
    id: YumeiroThemePresetIds.classicLight,
    label: 'Classic · Light',
    iconBuilder: (icons) => icons.themeLight,
    brightness: Brightness.light,
    mediaBackdropTone: YumeiroMediaBackdropTone.airyLight,
    colors: YumeiroColorTokens.light,
    materialSchemeBuilder: _lightMaterialScheme,
    accentCustomizer: _lightAccent,
    visualsBuilder: _lightVisuals,
    customizationOptions: [
      yumeiroSurfaceOpacityOption,
      yumeiroShadowOption,
      yumeiroShadowDistanceOption,
      yumeiroShadowSoftnessOption,
      yumeiroPressOption,
    ],
    categoricalPaletteBuilder: _lightCategoricalPalette,
  );

  static final geek = YumeiroThemePreset(
    id: YumeiroThemePresetIds.geek,
    label: 'Geek',
    iconBuilder: (icons) => icons.themeGeek,
    sliderThemeBuilder: _geekSliderTheme,
    modalVisuals: const YumeiroModalVisuals(
      barrierColor: Color(0x99081009),
      backdropBlur: 0,
      entryScale: 1,
    ),
    brightness: Brightness.dark,
    colors: _geekColors,
    materialSchemeBuilder: _darkMaterialScheme,
    accentCustomizer: _darkAccent,
    visualsBuilder: _geekVisuals,
    preserveStateBorderColors: true,
    customizationOptions: [
      yumeiroBorderOpacityOption,
      yumeiroOutlineOption,
      yumeiroShadowOption,
      yumeiroShadowDistanceOption,
      yumeiroShadowSoftnessOption,
    ],
    categoricalPaletteBuilder: _darkCategoricalPalette,
    radii: const YumeiroRadiiTokens(
      chip: 3,
      button: 3,
      md: 5,
      lg: 8,
      checkbox: 2,
      poster: 5,
    ),
    motion: const YumeiroMotion(fast: Duration(milliseconds: 120)),
  );

  static final sketch = YumeiroThemePreset(
    id: YumeiroThemePresetIds.sketch,
    label: 'Sketch',
    iconBuilder: (icons) => icons.themeSketch,
    sliderThemeBuilder: _sketchSliderTheme,
    checkboxVisualsBuilder: _sketchCheckboxVisuals,
    modalVisuals: const YumeiroModalVisuals(
      barrierColor: Color(0x66362F25),
      backdropBlur: 0,
      entryScale: 1,
    ),
    brightness: Brightness.light,
    mediaBackdropTone: YumeiroMediaBackdropTone.airyLight,
    colors: _sketchColors,
    materialSchemeBuilder: _lightMaterialScheme,
    accentCustomizer: _lightAccent,
    visualsBuilder: _sketchVisuals,
    customizationOptions: [
      YumeiroThemeColorOption(
        id: 'shadowColor',
        label: 'Hard Shadow Color',
        localizedLabel: (l) => l.optionHardShadowColor,
        defaultValue: const Color(0xFF292F2B),
      ),
      yumeiroOutlineOption,
      yumeiroShadowOption,
      yumeiroShadowDistanceOption,
    ],
    categoricalPaletteBuilder: _lightCategoricalPalette,
    radii: const YumeiroRadiiTokens(
      chip: 6,
      button: 8,
      md: 12,
      lg: 14,
      checkbox: 3,
      poster: 12,
    ),
  );

  static final neumorphicLight = YumeiroThemePreset(
    id: YumeiroThemePresetIds.neumorphicLight,
    label: 'Neumorphic · Light',
    iconBuilder: (icons) => icons.themeNeumorphic,
    sliderThemeBuilder: _neumorphicSliderTheme,
    modalVisuals: const YumeiroModalVisuals(
      barrierColor: Color(0x66364662),
      backdropBlur: 18,
      entryScale: .97,
    ),
    brightness: Brightness.light,
    mediaBackdropTone: YumeiroMediaBackdropTone.airyLight,
    colors: _neumorphicColors,
    materialSchemeBuilder: _lightMaterialScheme,
    accentCustomizer: _lightAccent,
    visualsBuilder: _neumorphicVisuals,
    customizationOptions: [
      yumeiroRaisedHighlightOption,
      YumeiroThemeColorOption(
        id: 'shadowColor',
        label: 'Shadow Color',
        localizedLabel: (l) => l.optionShadowColor,
        defaultValue: const Color(0xFF546B92),
      ),
      yumeiroShadowOption,
      yumeiroShadowDistanceOption,
      yumeiroShadowSoftnessOption,
    ],
    categoricalPaletteBuilder: _lightCategoricalPalette,
    radii: const YumeiroRadiiTokens(
      chip: 10,
      button: 12,
      md: 18,
      lg: 22,
      checkbox: 5,
      poster: 16,
    ),
  );

  static final minimalDark = YumeiroThemePreset(
    id: YumeiroThemePresetIds.minimalDark,
    label: 'Minimal · Dark',
    iconBuilder: (icons) => icons.themeMinimal,
    brightness: Brightness.dark,
    colors: _minimalDarkColors,
    materialSchemeBuilder: _darkMaterialScheme,
    accentCustomizer: _darkAccent,
    visualsBuilder: (colors, radii, motion, [parameters = const {}]) =>
        _minimalVisuals(
          colors,
          radii,
          motion,
          parameters,
          dangerForeground: const Color(0xFFFF9DA7),
        ),
    customizationOptions: [
      yumeiroInnerHighlightOption,
      yumeiroOutlineOption,
      yumeiroShadowOption,
      yumeiroShadowDistanceOption,
      yumeiroShadowSoftnessOption,
    ],
    categoricalPaletteBuilder: _darkCategoricalPalette,
    sliderThemeBuilder: _geekSliderTheme,
    modalVisuals: const YumeiroModalVisuals(
      barrierColor: Color(0x4D101820),
      backdropBlur: 0,
      entryScale: 1,
    ),
    radii: _minimalRadii,
  );

  static final minimalLight = YumeiroThemePreset(
    id: YumeiroThemePresetIds.minimalLight,
    label: 'Minimal · Light',
    iconBuilder: (icons) => icons.themeMinimal,
    brightness: Brightness.light,
    mediaBackdropTone: YumeiroMediaBackdropTone.airyLight,
    colors: _minimalLightColors,
    materialSchemeBuilder: _lightMaterialScheme,
    accentCustomizer: _lightAccent,
    visualsBuilder: (colors, radii, motion, [parameters = const {}]) =>
        _minimalVisuals(
          colors,
          radii,
          motion,
          parameters,
          dangerForeground: const Color(0xFF9F263A),
        ),
    customizationOptions: [
      yumeiroInnerHighlightOption,
      yumeiroOutlineOption,
      yumeiroShadowOption,
      yumeiroShadowDistanceOption,
      yumeiroShadowSoftnessOption,
    ],
    categoricalPaletteBuilder: _lightCategoricalPalette,
    sliderThemeBuilder: _geekSliderTheme,
    modalVisuals: const YumeiroModalVisuals(
      barrierColor: Color(0x1F101820),
      backdropBlur: 0,
      entryScale: 1,
    ),
    radii: _minimalRadii,
  );

  static final liquidGlassLight = YumeiroThemePreset(
    id: YumeiroThemePresetIds.liquidGlassLight,
    label: 'Liquid Glass · Light',
    iconBuilder: (icons) => icons.themeLiquidGlass,
    brightness: Brightness.light,
    mediaBackdropTone: YumeiroMediaBackdropTone.airyLight,
    colors: _liquidGlassLightColors,
    materialSchemeBuilder: _lightMaterialScheme,
    accentCustomizer: _lightAccent,
    visualsBuilder: _liquidGlassVisuals,
    checkboxVisualsBuilder: _liquidGlassCheckboxVisuals,
    customizationOptions: yumeiroGlassOptions,
    supportsBorderCustomization: false,
    categoricalPaletteBuilder: _lightCategoricalPalette,
    sliderThemeBuilder: _neumorphicSliderTheme,
    modalVisuals: const YumeiroModalVisuals(
      barrierColor: Color(0x33101820),
      backdropBlur: 18,
      entryScale: .98,
    ),
    radii: _liquidGlassRadii,
  );

  static final liquidGlassDark = YumeiroThemePreset(
    id: YumeiroThemePresetIds.liquidGlassDark,
    label: 'Liquid Glass · Dark',
    iconBuilder: (icons) => icons.themeLiquidGlass,
    brightness: Brightness.dark,
    colors: _liquidGlassDarkColors,
    materialSchemeBuilder: _darkMaterialScheme,
    accentCustomizer: _darkAccent,
    visualsBuilder: _liquidGlassVisuals,
    checkboxVisualsBuilder: _liquidGlassCheckboxVisuals,
    customizationOptions: yumeiroGlassOptions,
    supportsBorderCustomization: false,
    categoricalPaletteBuilder: _darkCategoricalPalette,
    sliderThemeBuilder: _neumorphicSliderTheme,
    modalVisuals: const YumeiroModalVisuals(
      barrierColor: Color(0x88101820),
      backdropBlur: 18,
      entryScale: .98,
    ),
    radii: _liquidGlassRadii,
  );

  static final ceramicLight = YumeiroThemePreset(
    id: YumeiroThemePresetIds.ceramicLight,
    label: 'Ceramic Glaze · Light',
    iconBuilder: (icons) => icons.themeCeramic,
    brightness: Brightness.light,
    mediaBackdropTone: YumeiroMediaBackdropTone.airyLight,
    colors: _ceramicColors,
    materialSchemeBuilder: _lightMaterialScheme,
    accentCustomizer: _lightAccent,
    visualsBuilder: _ceramicVisuals,
    sliderThemeBuilder: _neumorphicSliderTheme,
    switchVisualsBuilder: _finishSwitchVisualsBuilder,
    customizationOptions: _finishOptions,
    categoricalPaletteBuilder: _lightCategoricalPalette,
    radii: const YumeiroRadiiTokens(button: 14, md: 20, lg: 26, checkbox: 5),
  );

  static final brushedMetalLight = YumeiroThemePreset(
    id: YumeiroThemePresetIds.brushedMetalLight,
    label: 'Brushed Metal · Light',
    iconBuilder: (icons) => icons.themeBrushedMetal,
    brightness: Brightness.light,
    mediaBackdropTone: YumeiroMediaBackdropTone.airyLight,
    colors: _brushedMetalColors,
    materialSchemeBuilder: _lightMaterialScheme,
    accentCustomizer: _lightAccent,
    visualsBuilder: _brushedMetalVisuals,
    switchVisualsBuilder: _finishSwitchVisualsBuilder,
    customizationOptions: [..._finishOptions, yumeiroTextureStrengthOption],
    categoricalPaletteBuilder: _lightCategoricalPalette,
    radii: const YumeiroRadiiTokens(button: 5, md: 9, lg: 12, checkbox: 2),
  );

  static final neoBrutalistLight = YumeiroThemePreset(
    id: YumeiroThemePresetIds.neoBrutalistLight,
    label: 'Neo-Brutalist · Light',
    iconBuilder: (icons) => icons.themeNeoBrutalist,
    brightness: Brightness.light,
    mediaBackdropTone: YumeiroMediaBackdropTone.airyLight,
    colors: _neoBrutalistColors,
    materialSchemeBuilder: _lightMaterialScheme,
    accentCustomizer: _lightAccent,
    visualsBuilder: _neoBrutalistVisuals,
    typographyBuilder: _neoBrutalistTypographyBuilder,
    sliderThemeBuilder: _neoBrutalistSliderThemeBuilder,
    checkboxVisualsBuilder: _neoBrutalistCheckboxVisualsBuilder,
    switchVisualsBuilder: _neoBrutalistSwitchVisualsBuilder,
    supportsHardShadowCustomization: true,
    customizationOptions: _neoBrutalistOptions(_neoBrutalistColors),
    categoricalPaletteBuilder: _lightCategoricalPalette,
    radii: const YumeiroRadiiTokens(
      chip: 2,
      button: 2,
      md: 3,
      lg: 4,
      checkbox: 1,
      poster: 3,
    ),
  );

  static final pixelLight = YumeiroThemePreset(
    id: YumeiroThemePresetIds.pixelLight,
    label: 'Pixel Retro · Light',
    iconBuilder: (icons) => icons.themePixel,
    brightness: Brightness.light,
    mediaBackdropTone: YumeiroMediaBackdropTone.airyLight,
    colors: _pixelColors,
    materialSchemeBuilder: _lightMaterialScheme,
    accentCustomizer: _lightAccent,
    visualsBuilder: _pixelVisuals,
    typographyBuilder: _pixelTypographyBuilder,
    sliderThemeBuilder: _pixelSliderThemeBuilder,
    checkboxVisualsBuilder: _pixelCheckboxVisualsBuilder,
    switchVisualsBuilder: _pixelSwitchVisualsBuilder,
    supportsHardShadowCustomization: true,
    customizationOptions: _pixelOptions(_pixelColors),
    categoricalPaletteBuilder: _lightCategoricalPalette,
    motion: const YumeiroMotion(fast: Duration(milliseconds: 80)),
    radii: const YumeiroRadiiTokens(
      chip: 3,
      button: 3,
      md: 4,
      lg: 4,
      checkbox: 2,
      poster: 4,
    ),
  );

  static final acrylicLight = YumeiroThemePreset(
    id: YumeiroThemePresetIds.acrylicLight,
    label: 'Frosted Acrylic · Light',
    iconBuilder: (icons) => icons.themeAcrylic,
    brightness: Brightness.light,
    mediaBackdropTone: YumeiroMediaBackdropTone.airyLight,
    colors: _acrylicColors,
    materialSchemeBuilder: _lightMaterialScheme,
    accentCustomizer: _lightAccent,
    visualsBuilder: _acrylicVisuals,
    switchVisualsBuilder: _finishSwitchVisualsBuilder,
    customizationOptions: [
      ..._finishOptions,
      yumeiroBackdropBlurOption,
      yumeiroMaterialOpacityOption,
    ],
    categoricalPaletteBuilder: _lightCategoricalPalette,
    radii: const YumeiroRadiiTokens(button: 14, md: 20, lg: 26),
  );

  static final siliconeLight = YumeiroThemePreset(
    id: YumeiroThemePresetIds.siliconeLight,
    label: 'Soft Silicone · Light',
    iconBuilder: (icons) => icons.themeSilicone,
    brightness: Brightness.light,
    mediaBackdropTone: YumeiroMediaBackdropTone.airyLight,
    colors: _siliconeColors,
    materialSchemeBuilder: _lightMaterialScheme,
    accentCustomizer: _lightAccent,
    visualsBuilder: _siliconeVisuals,
    sliderThemeBuilder: _neumorphicSliderTheme,
    switchVisualsBuilder: _finishSwitchVisualsBuilder,
    customizationOptions: [
      _surfaceColorOption(_siliconeColors),
      ..._finishOptions,
    ],
    categoricalPaletteBuilder: _lightCategoricalPalette,
    radii: const YumeiroRadiiTokens(
      chip: 12,
      button: 16,
      md: 22,
      lg: 28,
      checkbox: 6,
      poster: 20,
    ),
  );

  static final frostedGlassLight = YumeiroThemePreset(
    id: YumeiroThemePresetIds.frostedGlassLight,
    label: 'Thick Frosted Glass · Light',
    iconBuilder: (icons) => icons.themeFrostedGlass,
    brightness: Brightness.light,
    mediaBackdropTone: YumeiroMediaBackdropTone.airyLight,
    colors: _frostedGlassColors,
    materialSchemeBuilder: _lightMaterialScheme,
    accentCustomizer: _lightAccent,
    visualsBuilder: _frostedGlassVisuals,
    switchVisualsBuilder: _finishSwitchVisualsBuilder,
    customizationOptions: [
      ..._finishOptions,
      yumeiroBackdropBlurOption,
      yumeiroMaterialOpacityOption,
      yumeiroGlassEdgeOption,
      yumeiroGlassOptions.first,
    ],
    categoricalPaletteBuilder: _lightCategoricalPalette,
    radii: const YumeiroRadiiTokens(button: 16, md: 24, lg: 30),
    modalVisuals: const YumeiroModalVisuals(
      barrierColor: Color(0x331B3540),
      backdropBlur: 12,
    ),
  );

  static final neumorphicDark = _darkVariant(
    neumorphicLight,
    YumeiroThemePresetIds.neumorphicDark,
    _neumorphicDarkColors,
    customizations: [
      yumeiroRaisedHighlightOption,
      YumeiroThemeColorOption(
        id: 'shadowColor',
        label: 'Shadow Color',
        localizedLabel: (l) => l.optionShadowColor,
        defaultValue: const Color(0xFF080C12),
      ),
      yumeiroShadowOption,
      yumeiroShadowDistanceOption,
      yumeiroShadowSoftnessOption,
    ],
  );
  static final ceramicDark = _darkVariant(
    ceramicLight,
    YumeiroThemePresetIds.ceramicDark,
    _ceramicDarkColors,
  );
  static final brushedMetalDark = _darkVariant(
    brushedMetalLight,
    YumeiroThemePresetIds.brushedMetalDark,
    _brushedMetalDarkColors,
  );
  static final neoBrutalistDark = _darkVariant(
    neoBrutalistLight,
    YumeiroThemePresetIds.neoBrutalistDark,
    _neoBrutalistDarkColors,
    customizations: _neoBrutalistOptions(_neoBrutalistDarkColors),
  );
  static final pixelDark = _darkVariant(
    pixelLight,
    YumeiroThemePresetIds.pixelDark,
    _pixelDarkColors,
    customizations: _pixelOptions(_pixelDarkColors),
  );
  static final acrylicDark = _darkVariant(
    acrylicLight,
    YumeiroThemePresetIds.acrylicDark,
    _acrylicDarkColors,
  );
  static final siliconeDark = _darkVariant(
    siliconeLight,
    YumeiroThemePresetIds.siliconeDark,
    _siliconeDarkColors,
    customizations: [
      _surfaceColorOption(_siliconeDarkColors),
      ..._finishOptions,
    ],
  );
  static final frostedGlassDark = _darkVariant(
    frostedGlassLight,
    YumeiroThemePresetIds.frostedGlassDark,
    _frostedGlassDarkColors,
  );

  /// All built-in variants, ordered by family and then by variant.
  static final List<YumeiroThemePreset> builtInValues =
      List<YumeiroThemePreset>.unmodifiable(
        YumeiroThemeFamilies.builtInValues.expand(
          (family) => family.variants.values,
        ),
      );

  /// Finds a built-in ID, falling back to [classicDark].
  static YumeiroThemePreset byId(String? id) => builtInValues.firstWhere(
    (preset) => preset.id == id,
    orElse: () => classicDark,
  );
}

/// Built-in theme families for an appearance-aware theme picker.
abstract final class YumeiroThemeFamilies {
  /// Default picker order used when constructing a standard registry.
  static final List<YumeiroThemeFamily> builtInValues =
      List<YumeiroThemeFamily>.unmodifiable([
        YumeiroThemeFamily(
          id: 'classic',
          label: 'Classic',
          iconBuilder: (icons) => icons.themeDark,
          variants: {
            YumeiroThemeVariant.dark: YumeiroThemePresets.classicDark,
            YumeiroThemeVariant.light: YumeiroThemePresets.classicLight,
          },
          defaultVariant: YumeiroThemeVariant.dark,
        ),
        YumeiroThemeFamily(
          id: 'geek',
          label: 'Geek',
          iconBuilder: (icons) => icons.themeGeek,
          variants: {YumeiroThemeVariant.dark: YumeiroThemePresets.geek},
          defaultVariant: YumeiroThemeVariant.dark,
        ),
        YumeiroThemeFamily(
          id: 'sketch',
          label: 'Sketch',
          iconBuilder: (icons) => icons.themeSketch,
          variants: {YumeiroThemeVariant.light: YumeiroThemePresets.sketch},
          defaultVariant: YumeiroThemeVariant.light,
        ),
        YumeiroThemeFamily(
          id: 'neumorphic',
          label: 'Neumorphic',
          iconBuilder: (icons) => icons.themeNeumorphic,
          variants: {
            YumeiroThemeVariant.light: YumeiroThemePresets.neumorphicLight,
            YumeiroThemeVariant.dark: YumeiroThemePresets.neumorphicDark,
          },
          defaultVariant: YumeiroThemeVariant.light,
        ),
        YumeiroThemeFamily(
          id: 'minimal',
          label: 'Minimal',
          iconBuilder: (icons) => icons.themeMinimal,
          variants: {
            YumeiroThemeVariant.dark: YumeiroThemePresets.minimalDark,
            YumeiroThemeVariant.light: YumeiroThemePresets.minimalLight,
          },
          defaultVariant: YumeiroThemeVariant.dark,
        ),
        YumeiroThemeFamily(
          id: 'liquid-glass',
          label: 'Liquid Glass',
          iconBuilder: (icons) => icons.themeLiquidGlass,
          variants: {
            YumeiroThemeVariant.dark: YumeiroThemePresets.liquidGlassDark,
            YumeiroThemeVariant.light: YumeiroThemePresets.liquidGlassLight,
          },
          defaultVariant: YumeiroThemeVariant.dark,
        ),
        for (final entry
            in <(String, String, YumeiroThemePreset, YumeiroThemePreset)>[
              (
                'ceramic',
                'Ceramic Glaze',
                YumeiroThemePresets.ceramicLight,
                YumeiroThemePresets.ceramicDark,
              ),
              (
                'brushed-metal',
                'Brushed Metal',
                YumeiroThemePresets.brushedMetalLight,
                YumeiroThemePresets.brushedMetalDark,
              ),
              (
                'neo-brutalist',
                'Neo-Brutalist',
                YumeiroThemePresets.neoBrutalistLight,
                YumeiroThemePresets.neoBrutalistDark,
              ),
              (
                'pixel',
                'Pixel Retro',
                YumeiroThemePresets.pixelLight,
                YumeiroThemePresets.pixelDark,
              ),
              (
                'acrylic',
                'Frosted Acrylic',
                YumeiroThemePresets.acrylicLight,
                YumeiroThemePresets.acrylicDark,
              ),
              (
                'silicone',
                'Soft Silicone',
                YumeiroThemePresets.siliconeLight,
                YumeiroThemePresets.siliconeDark,
              ),
              (
                'frosted-glass',
                'Thick Frosted Glass',
                YumeiroThemePresets.frostedGlassLight,
                YumeiroThemePresets.frostedGlassDark,
              ),
            ])
          YumeiroThemeFamily(
            id: entry.$1,
            label: entry.$2,
            iconBuilder: entry.$3.iconBuilder,
            variants: {
              YumeiroThemeVariant.light: entry.$3,
              YumeiroThemeVariant.dark: entry.$4,
            },
            defaultVariant: YumeiroThemeVariant.light,
          ),
      ]);
}

YumeiroThemeColorOption _surfaceColorOption(YumeiroColorTokens colors) =>
    YumeiroThemeColorOption(
      id: 'surfaceColor',
      label: 'Content Surface Color',
      localizedLabel: (l) => l.optionSurfaceColor,
      localizedDescription: (l) => l.optionSurfaceColorDescription,
      defaultValue: colors.surface,
      adjustment: YumeiroThemeAdjustment.surfaceColor,
    );

YumeiroThemePreset _darkVariant(
  YumeiroThemePreset light,
  String id,
  YumeiroColorTokens colors, {
  List<YumeiroThemeOption>? customizations,
}) => light.copyWith(
  id: id,
  label: light.label.replaceFirst(' · Light', ' · Dark'),
  brightness: Brightness.dark,
  colors: colors,
  materialSchemeBuilder: _darkMaterialScheme,
  accentCustomizer: _darkAccent,
  categoricalPaletteBuilder: _darkCategoricalPalette,
  mediaBackdropTone: YumeiroMediaBackdropTone.cinematicDark,
  customizationOptions: customizations,
  modalVisuals: YumeiroModalVisuals(
    barrierColor: const Color(0x99000000),
    backdropBlur: light.modalVisuals.backdropBlur,
    entryScale: light.modalVisuals.entryScale,
  ),
);

ColorScheme _darkMaterialScheme(YumeiroColorTokens colors) => ColorScheme.dark(
  surface: colors.surface,
  onSurface: colors.text,
  primary: colors.accent,
  onPrimary: colors.onAccent,
  secondary: colors.accentSoft,
  onSecondary: colors.background,
  error: colors.danger,
  onError: _errorForeground(colors),
  surfaceContainerHighest: colors.surfaceElevated,
  surfaceContainer: colors.surfaceSecondary,
);

ColorScheme _lightMaterialScheme(YumeiroColorTokens colors) =>
    ColorScheme.light(
      surface: colors.surface,
      onSurface: colors.text,
      primary: colors.accent,
      onPrimary: colors.onAccent,
      secondary: colors.accentSoft,
      onSecondary: colors.background,
      error: colors.danger,
      onError: _errorForeground(colors),
      surfaceContainerHighest: colors.surfaceElevated,
      surfaceContainer: colors.surfaceSecondary,
    );

Color _errorForeground(YumeiroColorTokens colors) {
  final errorLuminance = yumeiroRelativeLuminance(colors.danger);
  final textLuminance = yumeiroRelativeLuminance(colors.text);
  final contrast =
      (math.max(errorLuminance, textLuminance) + .05) /
      (math.min(errorLuminance, textLuminance) + .05);
  if (contrast >= 4.5) return colors.text;

  // Pastel errors in dark variants and saturated errors in light variants
  // need their own ink instead of inheriting the page's foreground.
  final blackContrast = (errorLuminance + .05) / .05;
  final whiteContrast = 1.05 / (errorLuminance + .05);
  return blackContrast >= whiteContrast ? Colors.black : Colors.white;
}

YumeiroColorTokens _darkAccent(YumeiroColorTokens colors, Color accent) =>
    colors.withAccent(accent, lighten: true);

YumeiroColorTokens _lightAccent(YumeiroColorTokens colors, Color accent) =>
    colors.withAccent(accent, lighten: false);

List<Color> _lightCategoricalPalette(YumeiroColorTokens colors) => <Color>[
  colors.accent,
  colors.info,
  colors.supporting,
  colors.success,
  colors.warning,
  colors.danger,
];

List<Color> _darkCategoricalPalette(YumeiroColorTokens colors) => <Color>[
  _darkCategoricalTone(colors.accent, maxSaturation: .46, lightness: .53),
  _darkCategoricalTone(colors.info, maxSaturation: .52, lightness: .56),
  _darkCategoricalTone(colors.supporting, maxSaturation: .55, lightness: .68),
  _darkCategoricalTone(colors.success, maxSaturation: .48, lightness: .53),
  _darkCategoricalTone(colors.warning, maxSaturation: .60, lightness: .56),
  _darkCategoricalTone(colors.danger, maxSaturation: .52, lightness: .64),
];

Color _darkCategoricalTone(
  Color color, {
  required double maxSaturation,
  required double lightness,
}) {
  final hsl = HSLColor.fromColor(color);
  return hsl
      .withSaturation(math.min(hsl.saturation, maxSaturation).toDouble())
      .withLightness(lightness)
      .toColor();
}

YumeiroTypographyTokens _defaultTypographyBuilder(
  YumeiroColorTokens colors,
  YumeiroFontConfig fontConfig,
) => YumeiroTypographyTokens.fromColors(
  text: colors.text,
  muted: colors.muted,
  fontConfig: fontConfig,
);

SliderThemeData _defaultSliderThemeBuilder(
  YumeiroColorTokens colors,
  YumeiroTypographyTokens typography, {
  required Map<String, Object> parameters,
}) => _baseSliderTheme(colors, typography);

SliderThemeData _baseSliderTheme(
  YumeiroColorTokens colors,
  YumeiroTypographyTokens typography, {
  SliderTrackShape trackShape = const RoundedRectSliderTrackShape(),
  double trackHeight = 3.5,
  SliderComponentShape thumbShape = const RoundSliderThumbShape(
    enabledThumbRadius: 6,
    pressedElevation: 3,
  ),
  RangeSliderThumbShape? rangeThumbShape,
  Color? inactiveTrackColor,
}) {
  final inactive = inactiveTrackColor ?? colors.line;
  return SliderThemeData(
    trackHeight: trackHeight,
    trackShape: trackShape,
    rangeTrackShape: trackShape is RectangularSliderTrackShape
        ? const RectangularRangeSliderTrackShape()
        : const RoundedRectRangeSliderTrackShape(),
    activeTrackColor: colors.accent,
    inactiveTrackColor: inactive,
    disabledActiveTrackColor: colors.accent.withValues(
      alpha: colors.accent.a * _disabledMaterialOpacity,
    ),
    disabledInactiveTrackColor: inactive.withValues(
      alpha: inactive.a * _disabledMaterialOpacity,
    ),
    thumbColor: colors.accent,
    disabledThumbColor: colors.accent.withValues(
      alpha:
          colors.accent.a * _disabledMaterialOpacity * _disabledContentOpacity,
    ),
    overlayColor: colors.accent.withValues(alpha: .15),
    thumbShape: thumbShape,
    rangeThumbShape: rangeThumbShape,
    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
    tickMarkShape: SliderTickMarkShape.noTickMark,
    valueIndicatorColor: colors.accent,
    valueIndicatorTextStyle: typography.caption.copyWith(
      color: colors.onAccent,
      fontWeight: typography.controlWeight(),
    ),
  );
}

YumeiroCheckboxVisuals _liquidGlassCheckboxVisuals(
  YumeiroColorTokens colors,
  YumeiroRadiiTokens radii,
  YumeiroSemanticVisualTheme visuals,
) => _defaultCheckboxVisualsBuilder(
  colors,
  radii,
  visuals,
).copyWith(shape: const CircleBorder());

YumeiroCheckboxVisuals _defaultCheckboxVisualsBuilder(
  YumeiroColorTokens colors,
  YumeiroRadiiTokens radii,
  YumeiroSemanticVisualTheme visuals,
) {
  YumeiroVisualAppearance appearance(Set<WidgetState> states) =>
      visuals.control(
        states.contains(WidgetState.selected)
            ? YumeiroControlRole.primary
            : YumeiroControlRole.neutral,
        states,
      );
  final fillColor = WidgetStateProperty.resolveWith<Color?>(
    (states) => appearance(states).background,
  );
  final checkColor = WidgetStateProperty.resolveWith<Color?>((states) {
    final value = appearance(states);
    return value.foreground.withValues(
      alpha: value.foreground.a * value.opacity,
    );
  });
  const overlayColor = WidgetStatePropertyAll<Color?>(Colors.transparent);
  final side = WidgetStateBorderSide.resolveWith((states) {
    if (states.contains(WidgetState.disabled)) {
      return BorderSide(
        color: colors.line.withValues(alpha: colors.line.a * .7),
        width: 1.2,
      );
    }
    if (states.contains(WidgetState.focused)) {
      return BorderSide(color: colors.accent, width: 1.5);
    }
    if (states.contains(WidgetState.selected)) {
      return BorderSide(color: colors.accent, width: 1.2);
    }
    if (states.contains(WidgetState.hovered)) {
      return BorderSide(color: colors.lineStrong, width: 1.4);
    }
    return BorderSide(color: colors.lineStrong, width: 1.2);
  });
  return YumeiroCheckboxVisuals(
    fillColor: fillColor,
    checkColor: checkColor,
    overlayColor: overlayColor,
    side: side,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radii.checkbox),
    ),
  );
}

YumeiroSwitchVisuals _defaultSwitchVisualsBuilder(
  YumeiroColorTokens colors,
  YumeiroSemanticVisualTheme visuals,
) {
  YumeiroVisualAppearance track(Set<WidgetState> states) {
    final visual = visuals.control(
      states.contains(WidgetState.selected)
          ? YumeiroControlRole.primary
          : YumeiroControlRole.neutral,
      states,
    );
    return visual.copyWith(
      outline: BorderSide(
        color: colors.lineStrong,
        width: math.max(1, visual.outline.width),
      ),
    );
  }

  YumeiroVisualAppearance thumb(Set<WidgetState> states) {
    final visual = visuals.control(
      YumeiroControlRole.secondary,
      states.difference(const {WidgetState.selected, WidgetState.focused}),
    );
    return visual.copyWith(
      fill: YumeiroSolidFill(colors.text),
      shape: visual.shape.scale(.7) as OutlinedBorder,
      focusIndicator: YumeiroFocusIndicator.none,
    );
  }

  return YumeiroSwitchVisuals(
    track: YumeiroVisualRecipe(
      base: track(const {}),
      states: WidgetStateProperty.resolveWith(track),
    ),
    thumb: YumeiroVisualRecipe(
      base: thumb(const {}),
      states: WidgetStateProperty.resolveWith(thumb),
    ),
  );
}

YumeiroSemanticVisualTheme _darkVisuals(
  YumeiroColorTokens colors,
  YumeiroRadiiTokens radii,
  YumeiroMotion motion, [
  Map<String, Object> parameters = const {},
]) => _buildBaseVisuals(
  colors,
  radii,
  motion,
  navigationFill: colors.sidebar.withValues(alpha: .72),
  panelFill: colors.surface.withValues(alpha: .62),
  cardFill: colors.surface.withValues(alpha: .62),
  floatingFill: colors.surfaceElevated.withValues(alpha: .82),
  toastFill: colors.surfaceElevated.withValues(alpha: .82),
  controlFill: colors.surfaceSecondary.withValues(alpha: .65),
  hoverOverlay: Colors.white.withValues(alpha: .08),
  pressedOverlay: colors.accent.withValues(alpha: .13),
  selectedControlFill: colors.accentSoft.withValues(alpha: .18),
  selectedItemFill: colors.accent.withValues(alpha: .14),
  cardShadowOpacity: .16,
  controlShadowOpacity: .10,
  floatingShadowOpacity: .26,
  modalShadowOpacity: .28,
  toastShadowOpacity: .22,
);

YumeiroSemanticVisualTheme _lightVisuals(
  YumeiroColorTokens colors,
  YumeiroRadiiTokens radii,
  YumeiroMotion motion, [
  Map<String, Object> parameters = const {},
]) => _buildBaseVisuals(
  colors,
  radii,
  motion,
  navigationFill: colors.sidebar.withValues(alpha: .80),
  panelFill: colors.surface.withValues(alpha: .85),
  cardFill: colors.surface.withValues(alpha: .85),
  floatingFill: colors.surfaceElevated.withValues(alpha: .90),
  toastFill: colors.surfaceElevated.withValues(alpha: .90),
  controlFill: colors.surfaceSecondary.withValues(alpha: .75),
  hoverOverlay: Colors.black.withValues(alpha: .05),
  pressedOverlay: colors.accent.withValues(alpha: .09),
  selectedControlFill: colors.accentSoft.withValues(alpha: .14),
  selectedItemFill: colors.accent.withValues(alpha: .10),
  cardShadowOpacity: .035,
  controlShadowOpacity: .02,
  floatingShadowOpacity: .09,
  modalShadowOpacity: .10,
  toastShadowOpacity: .06,
);

double _materialRatio(
  Map<String, Object> parameters,
  String id, {
  double defaultValue = 100,
}) => (parameters[id] as double? ?? defaultValue) / 100;

Color _materialColor(
  Map<String, Object> parameters,
  String id,
  Color fallback,
) => parameters[id] as Color? ?? fallback;

Color _materialAlpha(Color color, double strength) =>
    color.withValues(alpha: (color.a * strength).clamp(0, 1));

const _disabledMaterialOpacity = .55;
const _disabledContentOpacity = .7;

YumeiroVisualAppearance _disabledVisual(YumeiroVisualAppearance value) =>
    value.copyWith(
      foreground: value.foreground.withValues(
        alpha: value.foreground.a * _disabledContentOpacity,
      ),
      opacity: value.opacity * _disabledMaterialOpacity,
      focusIndicator: YumeiroFocusIndicator.none,
    );

YumeiroSemanticVisualTheme _buildBaseVisuals(
  YumeiroColorTokens colors,
  YumeiroRadiiTokens radii,
  YumeiroMotion motion, {
  required Color navigationFill,
  required Color panelFill,
  required Color cardFill,
  required Color floatingFill,
  required Color toastFill,
  required Color controlFill,
  required Color hoverOverlay,
  required Color pressedOverlay,
  required Color selectedControlFill,
  required Color selectedItemFill,
  required double cardShadowOpacity,
  required double controlShadowOpacity,
  required double floatingShadowOpacity,
  required double modalShadowOpacity,
  required double toastShadowOpacity,
  YumeiroFocusIndicator? focusIndicator,
}) {
  final transition = YumeiroVisualTransition(
    duration: motion.fast,
    curve: Curves.easeOutCubic,
    pressedScale: .975,
  );
  const squareShape = RoundedRectangleBorder();
  final controlShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(radii.button),
  );
  final itemShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(radii.chip),
  );
  final selectionShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(math.max(0, radii.button - 3)),
  );
  final surfaceShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(radii.md),
  );
  final focus =
      focusIndicator ??
      YumeiroFocusIndicator(
        side: BorderSide(
          color: colors.accent.withValues(alpha: .82),
          width: 1.5,
        ),
        glow: [
          BoxShadow(
            color: colors.accent.withValues(alpha: .16),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      );

  YumeiroVisualMaterial material(
    Color fill, {
    List<BoxShadow> shadows = const <BoxShadow>[],
    double blur = 0,
  }) => YumeiroVisualMaterial(
    fill: YumeiroSolidFill(fill),
    effects: YumeiroEffectStack(outerShadows: shadows, backdropBlur: blur),
  );

  YumeiroVisualAppearance appearance(
    YumeiroVisualMaterial visualMaterial, {
    Color? foreground,
    OutlinedBorder? shape,
  }) => visualMaterial.appearance(
    foreground: foreground ?? colors.text,
    shape: shape ?? surfaceShape,
    transition: transition,
  );

  final flatPanel = material(colors.panel ?? panelFill);
  final insetMaterial = material(controlFill);
  final cardMaterial = material(
    cardFill,
    shadows: [
      BoxShadow(
        color: Colors.black.withValues(alpha: cardShadowOpacity),
        blurRadius: 14,
        offset: const Offset(0, 3),
      ),
    ],
  );
  final floatingMaterial = material(
    floatingFill,
    blur: 18,
    shadows: [
      BoxShadow(
        color: Colors.black.withValues(alpha: floatingShadowOpacity),
        blurRadius: 18,
        offset: const Offset(0, 6),
      ),
    ],
  );
  final modalMaterial = material(
    cardFill,
    shadows: [
      BoxShadow(
        color: Colors.black.withValues(alpha: modalShadowOpacity),
        blurRadius: 32,
        offset: const Offset(0, 12),
      ),
    ],
  );
  final controlMaterial = material(
    controlFill,
    shadows: [
      BoxShadow(
        color: Colors.black.withValues(alpha: controlShadowOpacity),
        blurRadius: 3.5,
        offset: const Offset(0, 1.2),
      ),
    ],
  );
  final transparentMaterial = material(Colors.transparent);

  YumeiroVisualAppearance overlayFill(
    YumeiroVisualAppearance value,
    Color overlay,
  ) => value.copyWith(
    fill: YumeiroSolidFill(yumeiroAlphaBlend(overlay, value.background)),
  );

  YumeiroVisualRecipe interactive(
    YumeiroVisualAppearance base, {
    YumeiroVisualAppearance? selected,
    Color? hover,
    Color? pressed,
  }) => YumeiroVisualRecipe(
    base: base,
    focusIndicator: focus,
    states: WidgetStateProperty.resolveWith((states) {
      var value = states.contains(WidgetState.selected)
          ? selected ?? base
          : base;
      if (states.contains(WidgetState.disabled)) return _disabledVisual(value);
      if (states.contains(WidgetState.pressed) && pressed != null) {
        value = overlayFill(value, pressed);
      } else if (states.contains(WidgetState.hovered) && hover != null) {
        value = overlayFill(value, hover);
      }
      return value;
    }),
  );

  final cardSurface = appearance(cardMaterial);
  final neutralControl = appearance(controlMaterial, shape: controlShape);
  final selectedControl = neutralControl.copyWith(
    fill: YumeiroSolidFill(selectedControlFill),
    foreground: colors.accentSoft,
  );
  final selectedItem = appearance(
    material(selectedItemFill),
    foreground: colors.accentSoft,
    shape: itemShape,
  );

  YumeiroStatusVisual tintedStatus(Color tint) => YumeiroStatusVisual(
    foreground: tint,
    subtleFill: tint.withValues(alpha: .08),
    tint: tint,
  );

  final navigationIndicator = appearance(
    material(
      colors.accent,
      shadows: [
        BoxShadow(color: colors.accent.withValues(alpha: .45), blurRadius: 4),
      ],
    ),
    foreground: colors.accent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topRight: Radius.circular(3),
        bottomRight: Radius.circular(3),
      ),
    ),
  );
  final topNavigationIndicator = appearance(
    material(colors.accent),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radii.chip),
    ),
  );

  final navigationItems = WidgetStateProperty.resolveWith((states) {
    final selected = states.contains(WidgetState.selected);
    final disabled = states.contains(WidgetState.disabled);
    final topSurface = interactive(
      appearance(
        transparentMaterial,
        foreground: selected ? colors.accentSoft : colors.muted,
        shape: controlShape,
      ),
      hover: hoverOverlay,
      pressed: pressedOverlay,
    ).resolve(states);
    return selected
        ? YumeiroNavigationItemVisual(
            iconForeground: colors.accentSoft,
            labelForeground: colors.text,
            labelWeight: FontWeight.w600,
            indicator: navigationIndicator,
            topSurface: topSurface,
            topIndicator: topNavigationIndicator.copyWith(
              opacity: disabled ? .38 : 1,
            ),
          )
        : YumeiroNavigationItemVisual(
            iconForeground: colors.muted,
            labelForeground: colors.muted,
            labelWeight: FontWeight.w500,
            topSurface: topSurface,
          );
  });

  final neutralRecipe = interactive(
    neutralControl,
    selected: selectedControl,
    hover: hoverOverlay,
    pressed: pressedOverlay,
  );
  final optionRecipe = interactive(
    appearance(transparentMaterial, shape: itemShape),
    selected: selectedItem,
    hover: hoverOverlay,
    pressed: pressedOverlay,
  );

  return YumeiroSemanticVisualTheme(
    surfaces: {
      YumeiroSurfaceRole.canvas: YumeiroVisualRecipe(
        base: appearance(material(colors.background), shape: squareShape),
      ),
      YumeiroSurfaceRole.navigation: YumeiroVisualRecipe(
        base: appearance(material(navigationFill), shape: squareShape),
      ),
      YumeiroSurfaceRole.panel: YumeiroVisualRecipe(
        base: appearance(flatPanel),
      ),
      YumeiroSurfaceRole.inset: YumeiroVisualRecipe(
        base: appearance(insetMaterial, shape: controlShape),
      ),
      YumeiroSurfaceRole.readout: YumeiroVisualRecipe(base: neutralControl),
      YumeiroSurfaceRole.scrim: YumeiroVisualRecipe(
        base: YumeiroVisualAppearance(
          fill: const YumeiroGradientFill(
            LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x59000000), Color(0xD1000000)],
            ),
            fallbackColor: Color(0xD1000000),
          ),
          foreground: Colors.white,
          shape: squareShape,
          transition: transition,
          effects: YumeiroEffectStack(backdropBlur: 12),
        ),
      ),
      YumeiroSurfaceRole.compact: interactive(
        appearance(insetMaterial, shape: itemShape),
        selected: selectedControl.copyWith(shape: itemShape),
      ),
      YumeiroSurfaceRole.card: interactive(
        cardSurface,
        selected: overlayFill(cardSurface, selectedItemFill),
        hover: hoverOverlay,
      ),
      YumeiroSurfaceRole.floating: YumeiroVisualRecipe(
        base: appearance(floatingMaterial, shape: controlShape),
      ),
      YumeiroSurfaceRole.modal: YumeiroVisualRecipe(
        base: appearance(modalMaterial),
      ),
      YumeiroSurfaceRole.toast: YumeiroVisualRecipe(
        base: appearance(
          material(
            toastFill,
            blur: 14,
            shadows: [
              BoxShadow(
                color: Colors.black.withValues(alpha: toastShadowOpacity),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          shape: controlShape,
        ),
      ),
      YumeiroSurfaceRole.media: interactive(
        appearance(
          material(
            cardFill,
            shadows: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .18),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
        ),
      ),
    },
    controls: {
      YumeiroControlRole.neutral: neutralRecipe,
      YumeiroControlRole.secondary: neutralRecipe,
      YumeiroControlRole.primary: interactive(
        appearance(
          material(colors.accent),
          foreground: colors.onAccent,
          shape: controlShape,
        ),
        hover: hoverOverlay,
        pressed: pressedOverlay,
      ),
      YumeiroControlRole.danger: interactive(
        appearance(
          material(colors.danger),
          foreground: Colors.white,
          shape: controlShape,
        ),
        hover: hoverOverlay,
        pressed: pressedOverlay,
      ),
      YumeiroControlRole.ghost: interactive(
        appearance(transparentMaterial, shape: controlShape),
        selected: appearance(
          material(selectedControlFill),
          foreground: colors.accentSoft,
          shape: controlShape,
        ),
        hover: hoverOverlay,
        pressed: pressedOverlay,
      ),
      YumeiroControlRole.overlay: interactive(
        appearance(
          material(Colors.black.withValues(alpha: .36)),
          foreground: Colors.white,
          shape: controlShape,
        ),
        selected: appearance(
          material(colors.accent.withValues(alpha: .32)),
          foreground: colors.accentSoft,
          shape: controlShape,
        ),
        hover: Colors.white.withValues(alpha: .14),
        pressed: pressedOverlay,
      ),
    },
    items: {
      YumeiroItemRole.navigation: interactive(
        appearance(transparentMaterial, shape: controlShape),
        selected: selectedItem.copyWith(shape: controlShape),
        hover: hoverOverlay,
        pressed: pressedOverlay,
      ),
      YumeiroItemRole.standard: optionRecipe,
      YumeiroItemRole.selection: interactive(
        appearance(transparentMaterial, shape: selectionShape),
        selected: selectedItem.copyWith(shape: selectionShape),
        hover: hoverOverlay,
        pressed: pressedOverlay,
      ),
      YumeiroItemRole.danger: interactive(
        appearance(
          transparentMaterial,
          foreground: colors.danger,
          shape: itemShape,
        ),
        hover: colors.danger.withValues(alpha: .14),
        pressed: colors.danger.withValues(alpha: .22),
      ),
    },
    statuses: {
      YumeiroStatusRole.neutral: YumeiroStatusVisual(
        foreground: colors.text,
        subtleFill: controlFill,
      ),
      YumeiroStatusRole.info: YumeiroStatusVisual(
        foreground: colors.muted,
        subtleFill: controlFill,
      ),
      YumeiroStatusRole.accent: tintedStatus(colors.accent),
      YumeiroStatusRole.success: tintedStatus(colors.success),
      YumeiroStatusRole.warning: tintedStatus(colors.warning),
      YumeiroStatusRole.danger: tintedStatus(colors.danger),
    },
    navigationItems: navigationItems,
  );
}
