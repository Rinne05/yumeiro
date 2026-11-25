import 'package:flutter/foundation.dart' show defaultTargetPlatform, internal;
import 'package:material_ui/material_ui.dart';

import '../foundation/icons.dart';
import '../foundation/modality.dart';
import '../foundation/typography.dart';
import '../primitives/visual_surface.dart';
import 'semantic_visuals.dart';
import 'theme_extension.dart';
import 'theme_preset.dart';
import 'visual_role.dart';

/// Convenient theme lookup helpers for Yumeiro widgets and host apps.
abstract final class YumeiroTheme {
  static final _fallback = YumeiroThemeExtension.fromPreset(
    preset: YumeiroThemePresets.classicDark,
  );

  /// Reads the active theme extension, with Classic Dark tokens as fallback.
  static YumeiroThemeExtension of(BuildContext context) =>
      Theme.of(context).extension<YumeiroThemeExtension>() ?? _fallback;

  static YumeiroIconSet iconsOf(BuildContext context) => of(context).icons;
}

typedef _ThemeCacheKey = ({
  YumeiroThemePreset preset,
  TargetPlatform platform,
  YumeiroModality modality,
  YumeiroDensity density,
  bool advancedMotionEnabled,
  double? backdropBlur,
  YumeiroFontConfig fontConfig,
  YumeiroIconSet? icons,
  Color? accentColor,
  double posterCardScale,
});

final _builtInPresets = Set<YumeiroThemePreset>.identity()
  ..addAll(YumeiroThemePresets.builtInValues);

// Separate scopes and simultaneous windows share recent built-in themes.
final _themeCache =
    <({_ThemeCacheKey key, YumeiroThemeExtension tokens, ThemeData theme})>[];

bool _sameThemeOptions(Map<String, Object> a, Map<String, Object> b) {
  if (a.length != b.length) return false;
  final previous = b.entries.iterator;
  for (final option in a.entries) {
    previous.moveNext();
    if (option.key != previous.current.key ||
        option.value.runtimeType != previous.current.value.runtimeType ||
        option.value != previous.current.value) {
      return false;
    }
  }
  return true;
}

/// Builds a Material [ThemeData] backed by [YumeiroThemeExtension] and
/// modality-aware sizing/typography.
///
/// This resolves visual styling. Install a Yumeiro scope when the subtree also
/// needs input tracking, toast hosting, or material capability configuration.
ThemeData yumeiroThemeData({
  YumeiroThemePreset? preset,
  YumeiroModality modality = YumeiroModality.pointer,
  YumeiroDensity density = YumeiroDensity.standard,
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
  final effectivePreset = preset ?? YumeiroThemePresets.classicDark;
  // Custom builders may read host state. Host-provided mutable font lists and
  // arbitrary option objects also need to be resolved on every call.
  final _ThemeCacheKey? cacheKey =
      visualsAugmenter == null &&
          _builtInPresets.contains(effectivePreset) &&
          fontConfig.runtimeType == YumeiroFontConfig &&
          identical(fontConfig.fontFallback, kYumeiroFontFallback) &&
          identical(fontConfig.monoFontFallback, kYumeiroMonoFontFallback) &&
          (icons == null || icons.runtimeType == YumeiroIconSet) &&
          (accentColor == null || accentColor.runtimeType == Color) &&
          customizations.values.every(
            (value) =>
                value is bool ||
                value is num ||
                value is String ||
                value.runtimeType == Color,
          )
      ? (
          preset: effectivePreset,
          platform: defaultTargetPlatform,
          modality: modality,
          density: density,
          advancedMotionEnabled: advancedMotionEnabled,
          backdropBlur: backdropBlur,
          fontConfig: fontConfig,
          icons: icons,
          accentColor: accentColor,
          posterCardScale: posterCardScale,
        )
      : null;
  if (cacheKey != null) {
    for (var i = _themeCache.length - 1; i >= 0; i--) {
      final entry = _themeCache[i];
      if (entry.key == cacheKey &&
          _sameThemeOptions(motionOptions, entry.tokens.motionOptions) &&
          _sameThemeOptions(customizations, entry.tokens.customizations)) {
        if (i != _themeCache.length - 1) {
          _themeCache.add(_themeCache.removeAt(i));
        }
        return entry.theme;
      }
    }
  }

  var tokens = YumeiroThemeExtension.fromPreset(
    preset: effectivePreset,
    advancedMotionEnabled: advancedMotionEnabled,
    motionOptions: motionOptions,
    customizations: customizations,
    backdropBlur: backdropBlur,
    fontConfig: fontConfig,
    icons: icons,
    accentColor: accentColor,
    visualsAugmenter: visualsAugmenter,
    posterCardScale: posterCardScale,
  );
  if (modality == YumeiroModality.touch) {
    tokens = tokens.copyWith(
      typography: tokens.typography.forModality(modality),
    );
  }

  final metrics = YumeiroMetrics.resolve(modality: modality, density: density);
  final colors = tokens.colors;
  final scheme = effectivePreset.materialSchemeBuilder(colors);
  final tooltipVisual = tokens.visuals.surface(YumeiroSurfaceRole.floating);

  YumeiroVisualAppearance control(
    YumeiroControlRole role,
    Set<WidgetState> states,
  ) => tokens.visuals.control(role, states);

  final material = ThemeData(
    brightness: effectivePreset.brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: colors.background,
    cardColor: colors.surfaceSecondary,
    dividerColor: colors.line,
    useMaterial3: true,
    splashFactory: NoSplash.splashFactory,
    fontFamily: tokens.typography.textTheme.bodyMedium?.fontFamily,
    fontFamilyFallback:
        tokens.typography.textTheme.bodyMedium?.fontFamilyFallback,
    textTheme: tokens.typography.textTheme,
    extensions: <ThemeExtension<dynamic>>[tokens],
    checkboxTheme: tokens.checkboxVisuals.materialTheme,
    sliderTheme: tokens.sliderTheme,
    visualDensity: switch (density) {
      YumeiroDensity.compact => VisualDensity.compact,
      YumeiroDensity.standard => VisualDensity.standard,
      YumeiroDensity.comfortable => VisualDensity.comfortable,
    },
    materialTapTargetSize: modality == YumeiroModality.touch
        ? MaterialTapTargetSize.padded
        : MaterialTapTargetSize.shrinkWrap,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.surfaceSecondary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(tokens.buttonRadius)),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(tokens.buttonRadius)),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(tokens.buttonRadius)),
        borderSide: control(YumeiroControlRole.neutral, const {
          WidgetState.focused,
        }).border,
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: metrics.horizontalPadding,
        vertical: metrics.verticalPadding,
      ),
      hintStyle: tokens.typography.input().copyWith(color: colors.subtle),
    ),
    dividerTheme: DividerThemeData(color: colors.line, thickness: 1, space: 1),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        minimumSize: WidgetStatePropertyAll(
          Size(metrics.controlHeight, metrics.controlHeight),
        ),
        maximumSize: WidgetStatePropertyAll(
          Size(metrics.controlHeight, metrics.controlHeight),
        ),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.buttonRadius),
          ),
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => control(YumeiroControlRole.ghost, states).foreground,
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => control(YumeiroControlRole.ghost, states).background,
        ),
        side: WidgetStateProperty.resolveWith(
          (states) => control(YumeiroControlRole.ghost, states).border,
        ),
        elevation: const WidgetStatePropertyAll(0),
        shadowColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      waitDuration: const Duration(milliseconds: 400),
      decoration: YumeiroResolvedVisualSurface.materialDecoration(
        tooltipVisual,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      textStyle: tokens.typography.caption.copyWith(
        color: tooltipVisual.foreground,
        fontWeight: tokens.typography.bodyWeight,
      ),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.dragged)
            ? colors.muted.withValues(alpha: .55)
            : colors.muted.withValues(alpha: .28),
      ),
      thickness: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.dragged)
            ? 7
            : 5,
      ),
      radius: Radius.circular(tokens.chipRadius / 2),
      trackColor: const WidgetStatePropertyAll(Colors.transparent),
      crossAxisMargin: 2,
      mainAxisMargin: 2,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: tokens.visuals.surface(YumeiroSurfaceRole.floating).background,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.buttonRadius),
      ),
      elevation: 0,
      shadowColor: Colors.transparent,
      textStyle: tokens.typography.body.copyWith(color: colors.text),
      position: PopupMenuPosition.under,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: tokens.visuals
          .surface(YumeiroSurfaceRole.modal)
          .background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.mdRadius),
      ),
    ),
  );

  final theme = applyYumeiroTypography(material, tokens.typography);
  if (cacheKey != null) {
    if (_themeCache.length == 4) _themeCache.removeAt(0);
    _themeCache.add((key: cacheKey, tokens: tokens, theme: theme));
  }
  return theme;
}

@internal
ThemeData applyYumeiroTypography(
  ThemeData material,
  YumeiroTypographyTokens typography,
) => material.copyWith(
  textTheme: typography.textTheme,
  primaryTextTheme: typography.textTheme.apply(
    bodyColor: material.primaryTextTheme.bodyMedium?.color,
    displayColor: material.primaryTextTheme.displaySmall?.color,
  ),
  inputDecorationTheme: material.inputDecorationTheme.copyWith(
    hintStyle: typography.input().copyWith(
      color: material.inputDecorationTheme.hintStyle?.color,
    ),
  ),
  tooltipTheme: material.tooltipTheme.copyWith(
    textStyle: typography.caption.copyWith(
      color: material.tooltipTheme.textStyle?.color,
    ),
  ),
  popupMenuTheme: material.popupMenuTheme.copyWith(
    textStyle: typography.body.copyWith(
      color: material.popupMenuTheme.textStyle?.color,
    ),
  ),
  sliderTheme: material.sliderTheme.copyWith(
    valueIndicatorTextStyle: typography.caption.copyWith(
      color: material.sliderTheme.valueIndicatorTextStyle?.color,
      fontWeight: typography.controlWeight(),
    ),
  ),
);
