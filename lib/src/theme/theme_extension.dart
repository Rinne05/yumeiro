import 'package:material_ui/material_ui.dart';

import '../foundation/colors.dart';
import '../foundation/icons.dart';
import '../foundation/motion.dart';
import '../foundation/radii.dart';
import '../foundation/spacing.dart';
import '../foundation/typography.dart';
import 'effect_pass.dart';
import 'semantic_visuals.dart';
import 'theme_options.dart';
import 'theme_preset.dart';
import 'visual_role.dart';

/// Adds or replaces semantic recipes after preset settings are resolved.
///
/// Receives the final colors and scaled radii so app roles follow the preset.
typedef YumeiroVisualsAugmenter = YumeiroSemanticVisualTheme Function(
  YumeiroSemanticVisualTheme visuals,
  YumeiroColorTokens colors,
  YumeiroRadiiTokens radii,
);

/// Resolved Yumeiro tokens and recipes carried by a Material theme.
///
/// Read this through `YumeiroTheme.of(context)` in custom widgets. Use
/// [YumeiroThemeExtension.fromPreset] to keep the palette, typography, and
/// recipes in sync with the current host configuration.
@immutable
class YumeiroThemeExtension extends ThemeExtension<YumeiroThemeExtension> {
  const YumeiroThemeExtension({
    required this.presetId,
    required this.categoricalPalette,
    required this.colors,
    required this.typography,
    required this.sliderTheme,
    required this.checkboxVisuals,
    required this.switchVisuals,
    required this.modalVisuals,
    required this.spacing,
    required this.radii,
    required this.motion,
    required this.visuals,
    required this.icons,
    required this.iconSizes,
    this.mediaBackdropTone = YumeiroMediaBackdropTone.cinematicDark,
    this.advancedMotionEnabled = true,
    this.motionOptions = const <String, bool>{},
    this.customizations = const <String, Object>{},
    this.posterCardScale = 1.0,
  });

  /// Resolves accent and palette options before building semantic recipes.
  ///
  /// Applies visual options and the scoped blur override to the preset's
  /// recipes, then invokes the host's augmenter on the result.
  factory YumeiroThemeExtension.fromPreset({
    required YumeiroThemePreset preset,
    bool advancedMotionEnabled = true,
    Map<String, bool> motionOptions = const <String, bool>{},
    Map<String, Object> customizations = const <String, Object>{},
    double? backdropBlur,
    YumeiroFontConfig fontConfig = const YumeiroFontConfig(),
    YumeiroIconSet? icons,
    Color? accentColor,
    YumeiroVisualsAugmenter? visualsAugmenter,
    double posterCardScale = 1.0,
  }) {
    final options = preset.options;
    final accentOption = options
        .whereType<YumeiroThemeColorOption>()
        .where((option) => option.adjustment == YumeiroThemeAdjustment.accent)
        .firstOrNull;
    final effectiveAccent =
        accentColor ??
        (accentOption != null && customizations.containsKey(accentOption.id)
            ? accentOption.resolve(customizations)
            : null);
    final baseColors = preset.resolveColors(effectiveAccent);
    final colors = customizeYumeiroColors(baseColors, options, customizations);

    final parameters = <String, Object>{
      for (final option in options)
        // Resolve this default from the authored palette before a border color
        // override can replace the recipe's line color.
        if (customizations.containsKey(option.id) ||
            (preset.supportsHardShadowCustomization &&
                option.id == 'hardShadowColor'))
          option.id: option.resolve(customizations),
    };
    final roundnessOption = options
        .whereType<YumeiroThemeNumberOption>()
        .where(
          (option) =>
              option.adjustment == YumeiroThemeAdjustment.roundness &&
              customizations.containsKey(option.id),
        )
        .lastOrNull;
    final roundness = roundnessOption?.resolve(customizations) ?? 100.0;
    final radii = preset.radii.scaled((roundness / 100.0).clamp(0.0, 2.0));

    final motion = advancedMotionEnabled
        ? preset.motion
        : const YumeiroMotion(
            fast: Duration.zero,
            normal: Duration.zero,
            slow: Duration.zero,
          );

    final typography = preset.typographyBuilder(colors, fontConfig);
    var visuals = preset.visualsBuilder(colors, radii, motion, parameters);
    visuals = customizeYumeiroVisuals(visuals, options, customizations);
    if (backdropBlur != null) {
      visuals = _withBackdropBlur(visuals, backdropBlur);
    }
    if (visualsAugmenter != null) {
      visuals = visualsAugmenter(visuals, colors, radii);
    }

    return YumeiroThemeExtension(
      presetId: preset.id,
      mediaBackdropTone: preset.mediaBackdropTone,
      categoricalPalette: List<Color>.unmodifiable(
        preset.categoricalPaletteBuilder(colors),
      ),
      colors: colors,
      typography: typography,
      sliderTheme: preset.sliderThemeBuilder(
        colors,
        typography,
        parameters: parameters,
      ),
      checkboxVisuals: preset.checkboxVisualsBuilder(colors, radii, visuals),
      switchVisuals: preset.switchVisualsBuilder(colors, visuals),
      modalVisuals: preset.modalVisuals,
      spacing: preset.spacing,
      radii: radii,
      motion: motion,
      visuals: visuals,
      icons: icons ?? YumeiroIconSet.material(),
      iconSizes: preset.iconSizes,
      advancedMotionEnabled: advancedMotionEnabled,
      motionOptions: Map<String, bool>.unmodifiable(motionOptions),
      customizations: Map<String, Object>.unmodifiable(customizations),
      posterCardScale: posterCardScale,
    );
  }

  /// ID of the preset used to resolve these tokens.
  final String presetId;
  final YumeiroMediaBackdropTone mediaBackdropTone;

  /// Ordered colors for distinguishing data categories.
  final List<Color> categoricalPalette;
  final YumeiroColorTokens colors;
  final YumeiroTypographyTokens typography;
  final SliderThemeData sliderTheme;
  final YumeiroCheckboxVisuals checkboxVisuals;
  final YumeiroSwitchVisuals switchVisuals;
  final YumeiroModalVisuals modalVisuals;
  final YumeiroSpacing spacing;
  final YumeiroRadiiTokens radii;
  final YumeiroMotion motion;

  /// Visual recipes resolved by controls and surfaces in this theme.
  final YumeiroSemanticVisualTheme visuals;
  final YumeiroIconSet icons;
  final YumeiroIconSizes iconSizes;

  /// Global gate checked by [isMotionEnabled].
  final bool advancedMotionEnabled;

  /// Explicit per-effect preferences read by [isMotionEnabled].
  final Map<String, bool> motionOptions;

  /// Host-supplied option values. Resolve them through the preset declarations
  /// when displaying settings that need effective defaults.
  final Map<String, Object> customizations;
  final double posterCardScale;

  Color get background => colors.background;
  Color get sidebar => colors.sidebar;
  Color get surface => colors.surface;
  Color get surfaceSecondary => colors.surfaceSecondary;
  Color get surfaceElevated => colors.surfaceElevated;
  Color get surfaceHover => colors.surfaceHover;
  Color get line => colors.line;
  Color get lineStrong => colors.lineStrong;
  Color get text => colors.text;
  Color get muted => colors.muted;
  Color get subtle => colors.subtle;
  Color get accent => colors.accent;
  Color get accentSoft => colors.accentSoft;
  Color get info => colors.info;
  Color get success => colors.success;
  Color get warning => colors.warning;
  Color get rating => colors.rating;
  Color get danger => colors.danger;
  Color get supporting => colors.supporting;
  Color get neutral => colors.neutral;
  Color get onAccent => colors.onAccent;

  double get chipRadius => radii.chip;
  double get buttonRadius => radii.button;
  double get mdRadius => radii.md;
  double get lgRadius => radii.lg;
  double get posterRadius => radii.poster;

  /// Reads a motion preference, using [fallback] for an absent key.
  ///
  /// Returns false when [advancedMotionEnabled] is false. Custom animations
  /// should also honor the surrounding MediaQuery's reduced-motion preference.
  bool isMotionEnabled(String key, {bool fallback = true}) {
    if (!advancedMotionEnabled) return false;
    return motionOptions[key] ?? fallback;
  }

  @override
  YumeiroThemeExtension copyWith({
    String? presetId,
    YumeiroMediaBackdropTone? mediaBackdropTone,
    List<Color>? categoricalPalette,
    YumeiroColorTokens? colors,
    YumeiroTypographyTokens? typography,
    SliderThemeData? sliderTheme,
    YumeiroCheckboxVisuals? checkboxVisuals,
    YumeiroSwitchVisuals? switchVisuals,
    YumeiroModalVisuals? modalVisuals,
    YumeiroSpacing? spacing,
    YumeiroRadiiTokens? radii,
    YumeiroMotion? motion,
    YumeiroSemanticVisualTheme? visuals,
    YumeiroIconSet? icons,
    YumeiroIconSizes? iconSizes,
    bool? advancedMotionEnabled,
    Map<String, bool>? motionOptions,
    Map<String, Object>? customizations,
    double? posterCardScale,
  }) => YumeiroThemeExtension(
    presetId: presetId ?? this.presetId,
    mediaBackdropTone: mediaBackdropTone ?? this.mediaBackdropTone,
    categoricalPalette: categoricalPalette ?? this.categoricalPalette,
    colors: colors ?? this.colors,
    typography: typography ?? this.typography,
    sliderTheme: sliderTheme ?? this.sliderTheme,
    checkboxVisuals: checkboxVisuals ?? this.checkboxVisuals,
    switchVisuals: switchVisuals ?? this.switchVisuals,
    modalVisuals: modalVisuals ?? this.modalVisuals,
    spacing: spacing ?? this.spacing,
    radii: radii ?? this.radii,
    motion: motion ?? this.motion,
    visuals: visuals ?? this.visuals,
    icons: icons ?? this.icons,
    iconSizes: iconSizes ?? this.iconSizes,
    advancedMotionEnabled: advancedMotionEnabled ?? this.advancedMotionEnabled,
    motionOptions: motionOptions ?? this.motionOptions,
    customizations: customizations ?? this.customizations,
    posterCardScale: posterCardScale ?? this.posterCardScale,
  );

  @override
  YumeiroThemeExtension lerp(covariant YumeiroThemeExtension? other, double t) {
    if (other == null) return this;
    return YumeiroThemeExtension(
      presetId: t < .5 ? presetId : other.presetId,
      mediaBackdropTone: t < .5 ? mediaBackdropTone : other.mediaBackdropTone,
      categoricalPalette: _lerpPalette(
        categoricalPalette,
        other.categoricalPalette,
        t,
      ),
      colors: colors.lerp(other.colors, t),
      typography: typography.lerp(other.typography, t),
      sliderTheme: SliderThemeData.lerp(sliderTheme, other.sliderTheme, t),
      checkboxVisuals: checkboxVisuals.lerp(other.checkboxVisuals, t),
      switchVisuals: switchVisuals.lerp(other.switchVisuals, t),
      modalVisuals: modalVisuals.lerp(other.modalVisuals, t),
      spacing: spacing.lerp(other.spacing, t),
      radii: radii.lerp(other.radii, t),
      motion: motion.lerp(other.motion, t),
      visuals: visuals.lerp(other.visuals, t),
      icons: t < .5 ? icons : other.icons,
      iconSizes: iconSizes.lerp(other.iconSizes, t),
      advancedMotionEnabled: t < .5
          ? advancedMotionEnabled
          : other.advancedMotionEnabled,
      motionOptions: t < .5 ? motionOptions : other.motionOptions,
      customizations: t < .5 ? customizations : other.customizations,
      posterCardScale:
          posterCardScale + (other.posterCardScale - posterCardScale) * t,
    );
  }

  static List<Color> _lerpPalette(List<Color> a, List<Color> b, double t) {
    if (a.length != b.length) return t < .5 ? a : b;
    return List<Color>.generate(
      a.length,
      (index) => Color.lerp(a[index], b[index], t)!,
      growable: false,
    );
  }
}

YumeiroSemanticVisualTheme _withBackdropBlur(
  YumeiroSemanticVisualTheme theme,
  double blur,
) {
  YumeiroVisualAppearance apply(YumeiroVisualAppearance appearance) {
    final effects = appearance.effects;
    if (effects.backdropBlur <= 0) return appearance;
    final nextPasses = <YumeiroEffectPass>[
      for (final pass in effects.passes)
        switch (pass) {
          YumeiroBackdropBlurPass(
            :final tint,
            :final id,
            :final minCapability,
          ) =>
            YumeiroBackdropBlurPass(
              sigma: blur,
              tint: tint,
              id: id,
              minCapability: minCapability,
            ),
          YumeiroLiquidGlassPass(
            :final glass,
            :final fallbackTint,
            :final id,
            :final minCapability,
          ) =>
            YumeiroLiquidGlassPass(
              glass: glass,
              blur: blur,
              fallbackTint: fallbackTint,
              id: id,
              minCapability: minCapability,
            ),
          _ => pass,
        },
    ];
    return appearance.copyWith(
      effects: YumeiroEffectStack.fromPasses(nextPasses),
    );
  }

  return YumeiroSemanticVisualTheme(
    surfaces: {
      for (final entry in theme.surfaces.entries)
        if (entry.key == YumeiroSurfaceRole.readout)
          entry.key: entry.value
        else
          entry.key: YumeiroVisualRecipe(
            base: apply(entry.value.base),
            states: entry.value.states == null
                ? null
                : WidgetStateProperty.resolveWith((states) {
                    final value = entry.value.states!.resolve(states);
                    return value == null ? null : apply(value);
                  }),
            focusIndicator: entry.value.focusIndicator,
          ),
    },
    controls: theme.controls,
    items: theme.items,
    statuses: theme.statuses,
    navigationItems: theme.navigationItems,
    customStatusTintOpacity: theme.customStatusTintOpacity,
  );
}
