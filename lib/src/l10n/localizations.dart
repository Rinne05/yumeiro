import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'built_in_locales.dart';

/// Localization contract for built-in copy across Yumeiro widgets, presets,
/// and customization metadata.
///
/// Built-in locales include English (`en`) and Simplified Chinese (`zh`).
/// Host applications can subclass [YumeiroLocalizations] or supply a custom
/// [LocalizationsDelegate] to support additional locales or override strings.
@immutable
abstract class YumeiroLocalizations {
  const YumeiroLocalizations();

  static const LocalizationsDelegate<YumeiroLocalizations> delegate =
      _YumeiroLocalizationsDelegate();

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  static YumeiroLocalizations? maybeOf(BuildContext context) =>
      Localizations.of<YumeiroLocalizations>(context, YumeiroLocalizations);

  static YumeiroLocalizations of(BuildContext context) =>
      maybeOf(context) ?? const YumeiroLocalizationsEn();

  String get localeName;

  // Common actions & states
  String get confirm;
  String get cancel;
  String get close;
  String get ok;
  String get back;
  String get save;
  String get saving;
  String get apply;
  String get done;
  String get add;
  String get remove;
  String get reset;
  String get resetToDefault;
  String get retry;
  String get clear;
  String get selectAll;
  String get selectItem;
  String get all;
  String get none;
  String get filter;
  String get clearFilters;
  String get sort;
  String get actions;
  String get moreActions;
  String get copy => 'Copy';
  String get copied => 'Copied';
  String get showPassword;
  String get hidePassword;
  String get requiredField;
  String get defaultOption;
  String get alreadyDefault;
  String get showOptions;
  String get hideOptions;
  String get hexColor;
  String get colorPickerTitle;
  String get hueSlider;
  String get hueSliderHint;
  String get hueSliderArrowHint;
  String get saturationValuePanel;
  String get saturationValueHint;
  String get increaseBrightness;
  String get decreaseBrightness;
  String get rating;
  String get unrated;
  String get play;
  String get search;
  String get searchHint;
  String get searchOrSelectHint;
  String get searchFilterHint;
  String get tokenInputHint;
  String get selectPlaceholder;
  String get selectOptionsHint;
  String get noResults;
  String get emptyTable;
  String get loading;
  String get emptyStateTitle;
  String get errorTitle;
  String get actionFailed;
  String selectedCount(int count);
  String confirmWithCount(int count);
  String filterWithCount(int count);
  String removeItem(String label);
  String ratingOutOfFive(String value);
  String ratingValue(String value);
  String searchHotkeyTooltip(String placeholder, String shortcut);
  String dropdownSelection(String label);
  String saturationBrightnessValue(
    int saturationPercent,
    int brightnessPercent,
  );
  String errorMessage(String error);

  // Pagination
  String get previousPage => 'Previous page';
  String get nextPage => 'Next page';
  String pageNumber(int page) => 'Page $page';
  String pagePosition(int page, int count) => 'Page $page of $count';
  String get jumpToPage => 'Go to page';
  String get pageNumberLabel => 'Page number';
  String pageNumberRange(int count) => 'Enter a page from 1 to $count.';

  // Modality & capability tier labels
  String get modalityPointer;
  String get modalityTouch;
  String get densityCompact;
  String get densityStandard;
  String get densityComfortable;
  String get capabilityFullOptical;
  String get capabilityBlurOnly;

  // Built-in theme families & presets
  String get familyClassic;
  String get familyGeek;
  String get familySketch;
  String get familyNeumorphic;
  String get familyMinimal;
  String get familyLiquidGlass;

  String get familyCeramic => 'Ceramic Glaze';
  String get familyBrushedMetal => 'Brushed Metal';
  String get familyNeoBrutalist => 'Neo-Brutalist';
  String get familyPixel => 'Pixel Retro';
  String get familyAcrylic => 'Frosted Acrylic';
  String get familySilicone => 'Soft Silicone';
  String get familyFrostedGlass => 'Thick Frosted Glass';

  String get presetClassicDark;
  String get presetClassicLight;
  String get presetGeek;
  String get presetSketch;
  String get presetMinimalDark;
  String get presetMinimalLight;
  String get presetLiquidGlassDark;
  String get presetLiquidGlassLight;
  // Variants use the localized family label unless overridden individually.
  String get presetNeumorphicLight => '$familyNeumorphic · Light';
  String get presetNeumorphicDark => '$familyNeumorphic · Dark';
  String get presetCeramicLight => '$familyCeramic · Light';
  String get presetCeramicDark => '$familyCeramic · Dark';
  String get presetBrushedMetalLight => '$familyBrushedMetal · Light';
  String get presetBrushedMetalDark => '$familyBrushedMetal · Dark';
  String get presetNeoBrutalistLight => '$familyNeoBrutalist · Light';
  String get presetNeoBrutalistDark => '$familyNeoBrutalist · Dark';
  String get presetPixelLight => '$familyPixel · Light';
  String get presetPixelDark => '$familyPixel · Dark';
  String get presetAcrylicLight => '$familyAcrylic · Light';
  String get presetAcrylicDark => '$familyAcrylic · Dark';
  String get presetSiliconeLight => '$familySilicone · Light';
  String get presetSiliconeDark => '$familySilicone · Dark';
  String get presetFrostedGlassLight => '$familyFrostedGlass · Light';
  String get presetFrostedGlassDark => '$familyFrostedGlass · Dark';

  // Theme customization options
  String get optionAccentColor;
  String get optionBorderColor;
  String get optionBorderColorDescription =>
      'Applies a solid color override. Preset borders can vary by material and state.';
  String get optionPresetBorder => 'Preset Borders';
  String get optionBackgroundTone;
  String get optionBackgroundToneDescription;
  String get optionPanelColor => 'Panel Color';
  String get optionPanelColorDescription =>
      'Sets the panel fill independently of the background tone.';
  String get optionSurfaceColor => 'Content Surface Color';
  String get optionSurfaceColorDescription =>
      'Sets the shared base color for cards, tables, and dialogs.';
  String get optionSecondarySurfaceColor => 'Secondary Surface Color';
  String get optionSecondarySurfaceColorDescription =>
      'Sets the base color for inputs and inset surfaces.';
  String get optionSurfaceHoverColor => 'Hover Surface Color';
  String get optionSurfaceHoverColorDescription =>
      'Sets the base color for hovered and pressed lightweight controls.';
  String get optionRoundness;
  String get optionSelectionStrength;
  String get optionSurfaceOpacity;
  String get optionSurfaceOpacityDescription =>
      'Scales the preset fill opacity of navigation, panels, cards and floating surfaces.';
  String get optionBorderOpacity;
  String get optionOutlineWidth;
  String get optionOutlineWidthDescription =>
      'Scales decorative outlines. Checkboxes can retain a visible boundary.';
  String get optionShadowStrength;
  String get optionShadowDistance;
  String get optionShadowSoftness;
  String get optionPressScale;
  String get optionInnerHighlight;
  String get optionRaisedHighlight;
  String get optionShadowColor;
  String get optionHardShadowColor;
  String get optionGlassRefraction;
  String get optionOpticalSizeLimitDescription =>
      'The effective range depends on the surface size. Small controls can reach the limit before the slider maximum.';
  String get optionRequiresOpticalDescription =>
      'Available with optical rendering.';
  String get optionGlassOpacity;
  String get optionGlassOpacityDescription =>
      'Adjusts the surface tint without changing blur or refraction.';
  String get optionGlassOpacityFallbackDescription =>
      'Blur fallback adds a base tint at 76% opacity.';
  String get optionTagOpacity;
  String get optionHighlightScale;
  String get optionGlassLighting;
  String get optionGlassLightingDescription;
  String get optionRimLightDisabledDescription =>
      'Turn on directional rim light to adjust its strength.';
  String get optionGlassEdgeThickness;
  String get optionActionOpacity;
  String get optionActionOpacityFallbackDescription =>
      'In blur fallback, primary and danger buttons keep a solid fill for legibility.';
  String get optionTextureStrength => 'Texture Strength';
  String get optionBackdropBlur => 'Backdrop Blur';
  String get optionMaterialOpacity => 'Material Tint Strength';
  String get optionMaterialOpacityDescription =>
      'Scales the preset tint. Blur and refraction have separate settings.';

  // Motion options
  String get motionPosterTilt;
  String get motionPosterScale;
  String get motionPosterLighting;
  String get motionDetailParallax;
  String get motionChartHover;
  String get motionNavigationTransition;
  String get motionControlPressScale;

  /// Resolves a localized label for a built-in theme family ID, or returns
  /// [fallback] for custom host-registered families.
  String resolveFamilyLabel(String familyId, String fallback) =>
      switch (familyId) {
        'classic' => familyClassic,
        'geek' => familyGeek,
        'sketch' => familySketch,
        'neumorphic' => familyNeumorphic,
        'minimal' => familyMinimal,
        'liquid-glass' => familyLiquidGlass,
        'ceramic' => familyCeramic,
        'brushed-metal' => familyBrushedMetal,
        'neo-brutalist' => familyNeoBrutalist,
        'pixel' => familyPixel,
        'acrylic' => familyAcrylic,
        'silicone' => familySilicone,
        'frosted-glass' => familyFrostedGlass,
        _ => fallback,
      };

  /// Resolves a localized label for a built-in theme preset ID, or returns
  /// [fallback] for custom host-registered presets.
  String resolvePresetLabel(String presetId, String fallback) =>
      switch (presetId) {
        'yumeiro.classic.dark' => presetClassicDark,
        'yumeiro.classic.light' => presetClassicLight,
        'yumeiro.geek' => presetGeek,
        'yumeiro.sketch' => presetSketch,
        'yumeiro.neumorphic' => presetNeumorphicLight,
        'yumeiro.neumorphic.dark' => presetNeumorphicDark,
        'yumeiro.minimal.dark' => presetMinimalDark,
        'yumeiro.minimal.light' => presetMinimalLight,
        'yumeiro.liquid-glass.dark' => presetLiquidGlassDark,
        'yumeiro.liquid-glass.light' => presetLiquidGlassLight,
        'yumeiro.ceramic' => presetCeramicLight,
        'yumeiro.ceramic.dark' => presetCeramicDark,
        'yumeiro.brushed-metal' => presetBrushedMetalLight,
        'yumeiro.brushed-metal.dark' => presetBrushedMetalDark,
        'yumeiro.neo-brutalist' => presetNeoBrutalistLight,
        'yumeiro.neo-brutalist.dark' => presetNeoBrutalistDark,
        'yumeiro.pixel' => presetPixelLight,
        'yumeiro.pixel.dark' => presetPixelDark,
        'yumeiro.acrylic' => presetAcrylicLight,
        'yumeiro.acrylic.dark' => presetAcrylicDark,
        'yumeiro.silicone' => presetSiliconeLight,
        'yumeiro.silicone.dark' => presetSiliconeDark,
        'yumeiro.frosted-glass' => presetFrostedGlassLight,
        'yumeiro.frosted-glass.dark' => presetFrostedGlassDark,
        _ => fallback,
      };
}

class _YumeiroLocalizationsDelegate
    extends LocalizationsDelegate<YumeiroLocalizations> {
  const _YumeiroLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'en' || locale.languageCode == 'zh';

  @override
  Future<YumeiroLocalizations> load(Locale locale) => SynchronousFuture(
    locale.languageCode == 'zh'
        ? const YumeiroLocalizationsZh()
        : const YumeiroLocalizationsEn(),
  );

  @override
  bool shouldReload(_YumeiroLocalizationsDelegate old) => false;
}
