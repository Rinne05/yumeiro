import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../foundation/color_math.dart';
import '../foundation/colors.dart';
import '../l10n/localizations.dart';
import 'effect_pass.dart';
import 'semantic_visuals.dart';
import 'visual_role.dart';

/// Identifies the palette, geometry, or effect handled by a shared adjustment.
///
/// A preset-specific option can omit this value and let the preset's builders
/// interpret its ID directly.
enum YumeiroThemeAdjustment {
  accent,
  borderColor,
  backgroundTone,
  roundness,
  outline,
  shadow,
  shadowDistance,
  shadowSoftness,
  pressScale,
  refraction,
  glassOpacity,
  tagOpacity,
  highlight,
  panelColor,
  surfaceColor,
  secondarySurfaceColor,
  surfaceHoverColor,
  paletteBorderColor,
}

/// Declarative customization parameter exposed by a [YumeiroThemePreset].
@immutable
sealed class YumeiroThemeOption {
  const YumeiroThemeOption({
    required this.id,
    required this.label,
    this.description,
    this.motion = false,
    this.pointerOnly = false,
    this.minCapability = YumeiroMaterialCapability.blurOnly,
    this.adjustment,
    this.localizedLabel,
    this.localizedDescription,
  });

  /// Stable key used by the host's settings and customization maps.
  final String id;

  /// Display label used when [localizedLabel] is absent.
  final String label;

  /// Optional help text used when [localizedDescription] is absent.
  final String? description;

  /// Metadata for hosts grouping appearance and motion settings.
  final bool motion;

  /// Metadata for hosts exposing this option only in pointer mode.
  final bool pointerOnly;

  /// Lowest rendering capability at which the option has its intended effect.
  final YumeiroMaterialCapability minCapability;

  /// Shared adjustment to apply when supported by the option's value type.
  final YumeiroThemeAdjustment? adjustment;
  final String Function(YumeiroLocalizations l10n)? localizedLabel;
  final String Function(YumeiroLocalizations l10n)? localizedDescription;

  String resolveLabel(YumeiroLocalizations l10n) =>
      localizedLabel?.call(l10n) ?? label;

  String? resolveDescription(YumeiroLocalizations l10n) =>
      localizedDescription?.call(l10n) ?? description;

  /// Value to present for an option with no stored override.
  Object get initialValue;

  /// Reads and validates the value at [id], using the declared default when
  /// there is no valid value.
  Object resolve(Map<String, Object> values);
}

/// Boolean preference that falls back to [defaultValue] for other types.
@immutable
final class YumeiroThemeToggleOption extends YumeiroThemeOption {
  const YumeiroThemeToggleOption({
    required super.id,
    required super.label,
    super.description,
    this.defaultValue = true,
    super.motion = true,
    super.pointerOnly,
    super.minCapability,
    super.adjustment,
    super.localizedLabel,
    super.localizedDescription,
  });

  final bool defaultValue;

  @override
  Object get initialValue => defaultValue;

  @override
  bool resolve(Map<String, Object> values) {
    final value = values[id];
    return value is bool ? value : defaultValue;
  }
}

/// Numeric preference clamped to the inclusive [min] and [max] bounds.
@immutable
final class YumeiroThemeNumberOption extends YumeiroThemeOption {
  const YumeiroThemeNumberOption({
    required super.id,
    required super.label,
    super.description,
    required this.defaultValue,
    this.min = 0,
    this.max = 100,
    this.step = 1,
    this.unit = '%',
    this.decimalPlaces,
    super.motion = false,
    super.pointerOnly,
    super.minCapability,
    super.adjustment,
    super.localizedLabel,
    super.localizedDescription,
  });

  /// Used when the key is absent or the supplied value is nonnumeric or nonfinite.
  final double defaultValue;
  final double min;
  final double max;

  /// Suggested increment for controls. [resolve] only clamps the value.
  final double step;

  /// Display suffix supplied to the host, such as percent or logical pixels.
  final String unit;

  /// Optional display precision; null lets the host infer it from [step].
  /// This does not round the stored value or change [resolve].
  final int? decimalPlaces;

  @override
  Object get initialValue => defaultValue;

  @override
  double resolve(Map<String, Object> values) {
    final value = values[id];
    if (value is num && value.isFinite) {
      return value.clamp(min, max).toDouble();
    }
    return defaultValue;
  }
}

/// Color preference accepting a Color, packed ARGB integer, or hex string.
///
/// Six hex digits are interpreted as opaque RGB and eight as ARGB. An
/// optional leading hash is accepted.
@immutable
final class YumeiroThemeColorOption extends YumeiroThemeOption {
  const YumeiroThemeColorOption({
    required super.id,
    required super.label,
    super.description,
    required this.defaultValue,
    super.motion = false,
    super.pointerOnly,
    super.minCapability,
    super.adjustment,
    super.localizedLabel,
    super.localizedDescription,
  });

  final Color defaultValue;

  @override
  Object get initialValue => defaultValue;

  @override
  Color resolve(Map<String, Object> values) {
    final value = values[id];
    if (value is Color) return value;
    if (value is int) return Color(value);
    if (value is String) {
      final hex = value.trim().replaceFirst('#', '');
      if (hex.length == 6) {
        final parsed = int.tryParse(hex, radix: 16);
        if (parsed != null) return Color(0xFF000000 | parsed);
      } else if (hex.length == 8) {
        final parsed = int.tryParse(hex, radix: 16);
        if (parsed != null) return Color(parsed);
      }
    }
    return defaultValue;
  }
}

/// Choice preference with stable keys and optional localized display labels.
@immutable
final class YumeiroThemeChoiceOption extends YumeiroThemeOption {
  const YumeiroThemeChoiceOption({
    required super.id,
    required super.label,
    super.description,
    required this.defaultValue,
    required this.choices,
    this.localizedChoices,
    super.motion = false,
    super.pointerOnly,
    super.minCapability,
    super.adjustment,
    super.localizedLabel,
    super.localizedDescription,
  });

  /// Fallback key returned when the stored selection is unavailable.
  final String defaultValue;

  /// Supported keys mapped to their default display labels.
  final Map<String, String> choices;
  final Map<String, String> Function(YumeiroLocalizations l10n)?
  localizedChoices;

  /// Supplies display labels. Keep the keys aligned with [choices], which
  /// defines the keys accepted by [resolve].
  Map<String, String> resolveChoices(YumeiroLocalizations l10n) =>
      localizedChoices?.call(l10n) ?? choices;

  @override
  Object get initialValue => defaultValue;

  @override
  String resolve(Map<String, Object> values) {
    final value = values[id];
    if (value is String && choices.containsKey(value)) return value;
    return defaultValue;
  }
}

/// Built-in motion preference declarations consumed by host settings UIs and
/// [YumeiroThemeExtension.isMotionEnabled].
abstract final class YumeiroMotionOptions {
  static final List<YumeiroThemeToggleOption> values = List.unmodifiable([
    YumeiroThemeToggleOption(
      id: 'posterTilt',
      label: 'Poster 3D Tilt',
      localizedLabel: (l) => l.motionPosterTilt,
      pointerOnly: true,
    ),
    YumeiroThemeToggleOption(
      id: 'posterScale',
      label: 'Poster Hover Scale',
      localizedLabel: (l) => l.motionPosterScale,
      pointerOnly: true,
    ),
    YumeiroThemeToggleOption(
      id: 'posterLighting',
      label: 'Poster Dynamic Lighting',
      localizedLabel: (l) => l.motionPosterLighting,
      pointerOnly: true,
    ),
    YumeiroThemeToggleOption(
      id: 'detailParallax',
      label: 'Detail Backdrop Parallax',
      localizedLabel: (l) => l.motionDetailParallax,
    ),
    YumeiroThemeToggleOption(
      id: 'chartHover',
      label: 'Chart Hover Morph',
      localizedLabel: (l) => l.motionChartHover,
      pointerOnly: true,
    ),
    YumeiroThemeToggleOption(
      id: 'navigationTransition',
      label: 'Navigation Highlight Transition',
      localizedLabel: (l) => l.motionNavigationTransition,
    ),
    YumeiroThemeToggleOption(
      id: 'controlPressScale',
      label: 'Control Press Scale',
      localizedLabel: (l) => l.motionControlPressScale,
    ),
  ]);
}

/// Typed convenience view over [YumeiroThemeExtension.motionOptions].
@immutable
class YumeiroMotionPreferences {
  const YumeiroMotionPreferences({
    this.enabled = true,
    this.options = const <String, bool>{},
    this.pressScale = true,
  });

  final bool enabled;
  final Map<String, bool> options;
  final bool pressScale;

  bool _on(String id) => enabled && (options[id] ?? true);

  bool get posterTilt => _on('posterTilt');
  bool get posterScale => _on('posterScale');
  bool get posterLighting => _on('posterLighting');
  bool get detailParallax => _on('detailParallax');
  bool get chartHover => _on('chartHover');
  bool get navigationTransition => _on('navigationTransition');
  bool get controlPressScale =>
      enabled && pressScale && _on('controlPressScale');
}

/// Applies declared color adjustments to [YumeiroColorTokens] before semantic
/// visual recipes are resolved. Independent surface color declarations keep
/// their palette colors through a background tint until explicitly overridden.
YumeiroColorTokens customizeYumeiroColors(
  YumeiroColorTokens colors,
  List<YumeiroThemeOption> declarations,
  Map<String, Object> overrides,
) {
  if (overrides.isEmpty) return colors;
  var result = colors;
  Color? surface;
  Color? surfaceSecondary;
  Color? surfaceHover;
  for (final option in declarations.whereType<YumeiroThemeColorOption>()) {
    final overridden = overrides.containsKey(option.id);
    switch (option.adjustment) {
      case YumeiroThemeAdjustment.surfaceColor:
        surface = overridden ? option.resolve(overrides) : colors.surface;
      case YumeiroThemeAdjustment.secondarySurfaceColor:
        surfaceSecondary = overridden
            ? option.resolve(overrides)
            : colors.surfaceSecondary;
      case YumeiroThemeAdjustment.surfaceHoverColor:
        surfaceHover = overridden
            ? option.resolve(overrides)
            : colors.surfaceHover;
      case YumeiroThemeAdjustment.backgroundTone when overridden:
        result = result.withBackgroundTone(option.resolve(overrides));
      case YumeiroThemeAdjustment.panelColor when overridden:
        result = result.copyWith(panel: option.resolve(overrides));
      case YumeiroThemeAdjustment.borderColor when overridden:
      case YumeiroThemeAdjustment.paletteBorderColor when overridden:
        final color = option.resolve(overrides);
        result = result.copyWith(
          line: color.withValues(alpha: result.line.a),
          lineStrong: color.withValues(alpha: result.lineStrong.a),
        );
      default:
        break;
    }
  }
  if (surface != null || surfaceSecondary != null || surfaceHover != null) {
    return result.copyWith(
      surface: surface,
      surfaceSecondary: surfaceSecondary,
      surfaceHover: surfaceHover,
    );
  }
  return result;
}

/// Percentage scale for the radii tokens, where 100 keeps the authored radii.
final yumeiroRoundnessOption = YumeiroThemeNumberOption(
  id: 'roundness',
  label: 'Corner Roundness',
  localizedLabel: (l) => l.optionRoundness,
  defaultValue: 100,
  min: 0,
  max: 200,
  adjustment: YumeiroThemeAdjustment.roundness,
);

/// Strength of a role's selected fill relative to its resting fill.
final yumeiroSelectionStrengthOption = YumeiroThemeNumberOption(
  id: 'selectionStrength',
  label: 'Selection Strength',
  localizedLabel: (l) => l.optionSelectionStrength,
  defaultValue: 100,
  min: 40,
  max: 180,
);

/// Opacity multiplier for the solid fill of major container roles.
final yumeiroSurfaceOpacityOption = YumeiroThemeNumberOption(
  id: 'surfaceOpacity',
  label: 'Container Fill Opacity Scale',
  localizedLabel: (l) => l.optionSurfaceOpacity,
  localizedDescription: (l) => l.optionSurfaceOpacityDescription,
  defaultValue: 100,
  min: 20,
  max: 100,
);

/// Percentage scale for the opacity of existing outlines.
final yumeiroBorderOpacityOption = YumeiroThemeNumberOption(
  id: 'borderOpacity',
  label: 'Border Opacity',
  localizedLabel: (l) => l.optionBorderOpacity,
  defaultValue: 100,
  min: 0,
  max: 200,
);

/// Percentage scale for existing outline widths.
final yumeiroOutlineOption = YumeiroThemeNumberOption(
  id: 'outline',
  label: 'Outline Width',
  localizedLabel: (l) => l.optionOutlineWidth,
  localizedDescription: (l) => l.optionOutlineWidthDescription,
  defaultValue: 100,
  min: 0,
  max: 200,
  adjustment: YumeiroThemeAdjustment.outline,
);

/// Percentage scale for shadow strength in recipes with shadows.
final yumeiroShadowOption = YumeiroThemeNumberOption(
  id: 'shadow',
  label: 'Shadow Strength',
  localizedLabel: (l) => l.optionShadowStrength,
  defaultValue: 100,
  min: 0,
  max: 200,
  adjustment: YumeiroThemeAdjustment.shadow,
);

/// Percentage scale for existing shadow offsets.
final yumeiroShadowDistanceOption = YumeiroThemeNumberOption(
  id: 'shadowDistance',
  label: 'Shadow Distance',
  localizedLabel: (l) => l.optionShadowDistance,
  defaultValue: 100,
  min: 0,
  max: 200,
  adjustment: YumeiroThemeAdjustment.shadowDistance,
);

/// Percentage scale for the blur radii of existing shadows.
final yumeiroShadowSoftnessOption = YumeiroThemeNumberOption(
  id: 'shadowSoftness',
  label: 'Shadow Softness',
  localizedLabel: (l) => l.optionShadowSoftness,
  defaultValue: 100,
  min: 0,
  max: 200,
  adjustment: YumeiroThemeAdjustment.shadowSoftness,
);

/// Scales the press movement already authored into a control transition.
final yumeiroPressOption = YumeiroThemeNumberOption(
  id: 'pressScale',
  label: 'Press Feedback Scale',
  localizedLabel: (l) => l.optionPressScale,
  defaultValue: 100,
  min: 0,
  max: 200,
  adjustment: YumeiroThemeAdjustment.pressScale,
);

/// Preset parameter for the strength of a recessed inner highlight.
final yumeiroInnerHighlightOption = YumeiroThemeNumberOption(
  id: 'innerHighlight',
  label: 'Inner Highlight',
  localizedLabel: (l) => l.optionInnerHighlight,
  defaultValue: 0,
  min: 0,
  max: 200,
);

/// Preset parameter for the edge highlight on raised surfaces.
final yumeiroRaisedHighlightOption = YumeiroThemeNumberOption(
  id: 'raisedHighlight',
  label: 'Edge Highlight',
  localizedLabel: (l) => l.optionRaisedHighlight,
  defaultValue: 100,
  min: 0,
  max: 200,
);

/// Optical preset parameter for thickness of the refracting edge.
final yumeiroGlassEdgeOption = YumeiroThemeNumberOption(
  id: 'glassEdge',
  label: 'Glass Edge Thickness',
  localizedLabel: (l) => l.optionGlassEdgeThickness,
  localizedDescription: (l) => l.optionOpticalSizeLimitDescription,
  minCapability: YumeiroMaterialCapability.fullOptical,
  defaultValue: 100,
  min: 0,
  max: 200,
);

/// Optical preset parameter for the fill opacity of action controls.
final yumeiroActionOpacityOption = YumeiroThemeNumberOption(
  id: 'actionOpacity',
  label: 'Action Fill Opacity',
  localizedLabel: (l) => l.optionActionOpacity,
  minCapability: YumeiroMaterialCapability.fullOptical,
  defaultValue: 40,
  min: 10,
  max: 90,
);

/// Surface-finish controls shared by the material-based theme presets.
/// These values are consumed by their recipes, without double-applying a
/// generic glass-lighting adjustment.
final yumeiroMaterialHighlightOption = YumeiroThemeNumberOption(
  id: 'materialHighlight',
  label: 'Specular Highlight',
  localizedLabel: (l) => l.optionHighlightScale,
  defaultValue: 100,
  min: 0,
  max: 200,
);

/// Material preset parameter for decorative texture strength.
final yumeiroTextureStrengthOption = YumeiroThemeNumberOption(
  id: 'textureStrength',
  label: 'Texture Strength',
  localizedLabel: (l) => l.optionTextureStrength,
  defaultValue: 100,
  min: 0,
  max: 200,
);

/// Material preset parameter for the backdrop blur radius in logical pixels.
final yumeiroBackdropBlurOption = YumeiroThemeNumberOption(
  id: 'materialBlur',
  label: 'Backdrop Blur',
  localizedLabel: (l) => l.optionBackdropBlur,
  defaultValue: 24,
  min: 0,
  max: 60,
  unit: 'px',
);

/// Material preset parameter for the strength of its tint.
final yumeiroMaterialOpacityOption = YumeiroThemeNumberOption(
  id: 'materialOpacity',
  label: 'Material Tint Strength',
  localizedLabel: (l) => l.optionMaterialOpacity,
  localizedDescription: (l) => l.optionMaterialOpacityDescription,
  defaultValue: 100,
  min: 0,
  max: 200,
);

/// Valued declarations for the liquid-glass presets, including optical options
/// that settings UIs can gate on the runtime capability.
final yumeiroGlassOptions = List<YumeiroThemeOption>.unmodifiable([
  YumeiroThemeNumberOption(
    id: 'refraction',
    label: 'Refraction Strength',
    localizedLabel: (l) => l.optionGlassRefraction,
    localizedDescription: (l) => l.optionOpticalSizeLimitDescription,
    minCapability: YumeiroMaterialCapability.fullOptical,
    defaultValue: 100,
    min: 0,
    max: 200,
    adjustment: YumeiroThemeAdjustment.refraction,
  ),
  YumeiroThemeNumberOption(
    id: 'glassOpacity',
    label: 'Glass Tint Opacity',
    localizedLabel: (l) => l.optionGlassOpacity,
    localizedDescription: (l) => l.optionGlassOpacityDescription,
    defaultValue: 1.5,
    min: 0,
    max: 60,
    step: .5,
    decimalPlaces: 1,
    adjustment: YumeiroThemeAdjustment.glassOpacity,
  ),
  YumeiroThemeNumberOption(
    id: 'tagOpacity',
    label: 'Tag Opacity',
    localizedLabel: (l) => l.optionTagOpacity,
    defaultValue: 35,
    min: 0,
    max: 100,
    adjustment: YumeiroThemeAdjustment.tagOpacity,
  ),
  YumeiroThemeNumberOption(
    id: 'highlight',
    label: 'Specular Highlight',
    localizedLabel: (l) => l.optionHighlightScale,
    minCapability: YumeiroMaterialCapability.fullOptical,
    defaultValue: 100,
    min: 0,
    max: 200,
    adjustment: YumeiroThemeAdjustment.highlight,
  ),
  YumeiroThemeToggleOption(
    id: 'glassLighting',
    motion: false,
    label: 'Directional Rim Light',
    localizedLabel: (l) => l.optionGlassLighting,
    description:
        'Toggle directional edge highlights while keeping refraction and blur.',
    localizedDescription: (l) => l.optionGlassLightingDescription,
    minCapability: YumeiroMaterialCapability.fullOptical,
  ),
  yumeiroPressOption,
  yumeiroGlassEdgeOption,
  yumeiroActionOpacityOption,
]);

/// Applies declared option adjustments across all registered semantic recipes
/// while preserving custom roles and pluggable [YumeiroEffectPass] entries.
YumeiroSemanticVisualTheme customizeYumeiroVisuals(
  YumeiroSemanticVisualTheme theme,
  List<YumeiroThemeOption> declarations,
  Map<String, Object> overrides,
) {
  final adjustments = <YumeiroThemeAdjustment, Object>{
    for (final option in declarations)
      if ((option is YumeiroThemeNumberOption ||
              option.adjustment == YumeiroThemeAdjustment.borderColor) &&
          option.adjustment != null &&
          overrides.containsKey(option.id))
        option.adjustment!: option.resolve(overrides),
  };
  final parameters = <String, Object>{
    for (final option in declarations)
      if (overrides.containsKey(option.id))
        option.id: option.resolve(overrides),
  };
  if (adjustments.isEmpty &&
      !parameters.keys.any(
        const {'selectionStrength', 'surfaceOpacity', 'borderOpacity'}.contains,
      )) {
    return theme;
  }

  double parameterRatio(String id) => (parameters[id] as double? ?? 100) / 100;
  double ratio(YumeiroThemeAdjustment key) =>
      (adjustments[key] as double? ?? 100) / 100;
  final selectionStrength = parameterRatio('selectionStrength');

  YumeiroVisualAppearance apply(
    YumeiroVisualRole role,
    YumeiroVisualAppearance appearance,
    Set<WidgetState> states, [
    YumeiroVisualAppearance? resting,
  ]) {
    final effects = appearance.effects;
    final glass = effects.glass;
    var fill = appearance.fill;
    var foreground = appearance.foreground;
    if (fill is YumeiroSolidFill) {
      final opacity = role == YumeiroSurfaceRole.compact
          ? adjustments[YumeiroThemeAdjustment.tagOpacity]
          : (glass != null || role == YumeiroSurfaceRole.inset) &&
                !states.contains(WidgetState.selected) &&
                role != YumeiroControlRole.primary &&
                role != YumeiroControlRole.danger
          ? adjustments[YumeiroThemeAdjustment.glassOpacity]
          : null;
      if (opacity != null) {
        fill = YumeiroSolidFill(
          fill.color.withValues(alpha: (opacity as double) / 100),
        );
      }
    }
    if (fill is YumeiroSolidFill &&
        (role == YumeiroSurfaceRole.navigation ||
            role == YumeiroSurfaceRole.panel ||
            role == YumeiroSurfaceRole.card ||
            role == YumeiroSurfaceRole.floating ||
            role == YumeiroSurfaceRole.modal ||
            role == YumeiroSurfaceRole.toast)) {
      fill = YumeiroSolidFill(
        fill.color.withValues(
          alpha: (fill.color.a * parameterRatio('surfaceOpacity')).clamp(0, 1),
        ),
      );
    }
    if (states.contains(WidgetState.selected) &&
        resting != null &&
        selectionStrength != 1) {
      final idle = apply(
        role,
        resting,
        states.difference({WidgetState.selected}),
      );
      fill = idle.fill.lerp(fill, selectionStrength);
      if (fill case YumeiroSolidFill(color: final background)
          when background.a == 1 &&
              appearance.opacity == 1 &&
              !states.contains(WidgetState.disabled)) {
        foreground = _selectionInk(foreground, idle.foreground, background);
      }
    }

    final shadow = ratio(YumeiroThemeAdjustment.shadow);
    final shadowSoftness = ratio(YumeiroThemeAdjustment.shadowSoftness);
    final shadowDistance = ratio(YumeiroThemeAdjustment.shadowDistance);
    final adjustShadows =
        shadow != 1 || shadowSoftness != 1 || shadowDistance != 1;
    final borderColor =
        adjustments[YumeiroThemeAdjustment.borderColor] as Color?;
    final outline =
        borderColor == null ||
            role == YumeiroControlRole.danger ||
            role == YumeiroItemRole.danger
        ? appearance.outline
        : appearance.outline.copyWith(
            color: borderColor.withValues(alpha: appearance.outline.color.a),
          );

    final nextPasses = <YumeiroEffectPass>[
      for (final pass in effects.passes)
        switch (pass) {
          YumeiroOuterShadowPass(
            :final shadows,
            :final id,
            :final minCapability,
          )
              when adjustShadows =>
            YumeiroOuterShadowPass(
              [
                for (final s in shadows)
                  if (s is YumeiroOuterHighlight)
                    s
                  else
                    s.copyWith(
                      blurRadius: s.blurRadius * shadowSoftness,
                      offset: s.offset * shadowDistance,
                      color: s.color.withValues(
                        alpha: (s.color.a * shadow).clamp(0, 1),
                      ),
                    ),
              ],
              id: id,
              minCapability: minCapability,
            ),
          YumeiroInnerShadowPass(
            :final shadows,
            :final id,
            :final minCapability,
          )
              when adjustShadows =>
            YumeiroInnerShadowPass(
              [
                for (final s in shadows)
                  if (s.isHighlight)
                    s
                  else
                    YumeiroInnerShadow(
                      color: s.color.withValues(
                        alpha: (s.color.a * shadow).clamp(0, 1),
                      ),
                      blurRadius: s.blurRadius * shadowSoftness,
                      offset: s.offset * shadowDistance,
                      spreadRadius: s.spreadRadius,
                    ),
              ],
              id: id,
              minCapability: minCapability,
            ),
          YumeiroLiquidGlassPass(
            :final glass,
            :final blur,
            :final fallbackTint,
            :final id,
            :final minCapability,
          ) =>
            YumeiroLiquidGlassPass(
              glass: glass.copyWith(
                refraction:
                    glass.refraction * ratio(YumeiroThemeAdjustment.refraction),
                lighting:
                    glass.lighting * ratio(YumeiroThemeAdjustment.highlight),
              ),
              blur: blur,
              fallbackTint: fallbackTint,
              id: id,
              minCapability: minCapability,
            ),
          _ => pass,
        },
    ];

    final pressScaleRatio = ratio(YumeiroThemeAdjustment.pressScale);
    final nextTransition =
        pressScaleRatio == 1 || appearance.transition.pressedScale == 1
        ? appearance.transition
        : appearance.transition.copyWith(
            pressedScale:
                (1.0 -
                        (1.0 - appearance.transition.pressedScale) *
                            pressScaleRatio)
                    .clamp(0.85, 1.0)
                    .toDouble(),
          );

    return appearance.copyWith(
      fill: fill,
      foreground: foreground,
      outline: ratio(YumeiroThemeAdjustment.outline) == 0
          ? BorderSide.none
          : outline.copyWith(
              width: outline.width * ratio(YumeiroThemeAdjustment.outline),
              color: outline.color.withValues(
                alpha: (outline.color.a * parameterRatio('borderOpacity'))
                    .clamp(0, 1),
              ),
            ),
      effects: YumeiroEffectStack.fromPasses(nextPasses),
      transition: nextTransition,
    );
  }

  YumeiroVisualRecipe recipe(
    YumeiroVisualRole role,
    YumeiroVisualRecipe value,
  ) => YumeiroVisualRecipe(
    base: apply(role, value.base, const {}),
    states: value.states == null
        ? null
        : WidgetStateProperty.resolveWith((states) {
            final result = value.states!.resolve(states);
            return result == null
                ? null
                : apply(role, result, states, value.base);
          }),
    focusIndicator: value.focusIndicator,
  );

  final surfaces = {
    for (final e in theme.surfaces.entries) e.key: recipe(e.key, e.value),
  };
  final items = {
    for (final e in theme.items.entries) e.key: recipe(e.key, e.value),
  };
  Color surfaceBackdrop(YumeiroSurfaceRole role) => yumeiroAlphaBlend(
    surfaces[role]!.base.background,
    surfaces[YumeiroSurfaceRole.canvas]!.base.background,
  );
  final sidebar = selectionStrength == 1
      ? null
      : surfaceBackdrop(YumeiroSurfaceRole.navigation);
  final panel = selectionStrength == 1
      ? null
      : surfaceBackdrop(YumeiroSurfaceRole.panel);

  YumeiroNavigationItemVisual navigation(Set<WidgetState> states) {
    final value = theme.navigationItem(states);
    final resting = theme.navigationItem(
      states.difference({WidgetState.selected}),
    );
    var topSurface = apply(
      YumeiroItemRole.navigation,
      value.topSurface,
      states,
      resting.topSurface,
    );
    var iconForeground = value.iconForeground;
    var labelForeground = value.labelForeground;
    var destinationForeground = value.destinationForeground;
    final destinationIndicator = value.destinationIndicator == null
        ? null
        : apply(
            YumeiroItemRole.navigation,
            value.destinationIndicator!,
            states,
            resting.destinationIndicator ?? resting.topSurface,
          );
    if (sidebar != null &&
        states.contains(WidgetState.selected) &&
        !states.contains(WidgetState.disabled)) {
      final row = items[YumeiroItemRole.navigation]!.resolve(states);
      final rowFill = yumeiroAlphaBlend(row.background, sidebar);
      iconForeground = _selectionInk(
        iconForeground,
        resting.iconForeground,
        rowFill,
      );
      labelForeground = _selectionInk(
        labelForeground,
        resting.labelForeground,
        rowFill,
      );
      if (destinationIndicator != null) {
        final destinationFill = yumeiroAlphaBlend(
          destinationIndicator.background,
          sidebar,
        );
        destinationForeground = _selectionInk(
          value.destinationForeground ?? value.iconForeground,
          resting.iconForeground,
          destinationFill,
        );
      }
      final tabFill = yumeiroAlphaBlend(topSurface.background, panel!);
      topSurface = topSurface.copyWith(
        foreground: _selectionInk(
          topSurface.foreground,
          resting.topSurface.foreground,
          tabFill,
        ),
      );
    }
    return YumeiroNavigationItemVisual(
      iconForeground: iconForeground,
      labelForeground: labelForeground,
      destinationForeground: destinationForeground,
      labelWeight: value.labelWeight,
      topSurface: topSurface,
      topIndicator: value.topIndicator == null
          ? null
          : apply(
              YumeiroItemRole.navigation,
              value.topIndicator!,
              states,
              resting.topIndicator ?? resting.topSurface,
            ),
      indicator: value.indicator == null
          ? null
          : apply(
              YumeiroItemRole.navigation,
              value.indicator!,
              states,
              resting.indicator ?? resting.topSurface,
            ),
      destinationIndicator: destinationIndicator,
    );
  }

  return YumeiroSemanticVisualTheme(
    surfaces: surfaces,
    controls: {
      for (final e in theme.controls.entries) e.key: recipe(e.key, e.value),
    },
    items: items,
    statuses: theme.statuses,
    navigationItems: WidgetStateProperty.resolveWith(navigation),
    customStatusTintOpacity: theme.customStatusTintOpacity,
  );
}

Color _selectionInk(Color preferred, Color resting, Color background) {
  final luminance = yumeiroRelativeLuminance(background);
  double contrast(Color ink) {
    final inkLuminance = yumeiroRelativeLuminance(
      yumeiroAlphaBlend(ink, background),
    );
    return (math.max(inkLuminance, luminance) + .05) /
        (math.min(inkLuminance, luminance) + .05);
  }

  if (contrast(preferred) >= 4.5) return preferred;
  if (contrast(resting) >= 4.5) return resting;
  return contrast(Colors.black) >= contrast(Colors.white)
      ? Colors.black
      : Colors.white;
}
