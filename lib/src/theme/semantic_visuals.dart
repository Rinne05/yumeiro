import 'package:flutter/foundation.dart' show internal;
import 'package:material_ui/material_ui.dart';

import '../foundation/color_math.dart';
import '../foundation/icons.dart';
import 'effect_pass.dart';
import 'visual_role.dart';

final _feedbackRoles = {
  for (final role in YumeiroStatusRole.builtInValues) role: role,
};

/// Resolves a status role's conventional feedback along its fallback chain.
@internal
({IconData icon, bool liveRegion}) resolveYumeiroStatusFeedback(
  YumeiroStatusRole role,
  YumeiroIconSet icons,
) {
  final effective = YumeiroSemanticVisualTheme._resolveRole(
    role,
    _feedbackRoles,
    (role) => role.fallback,
    YumeiroStatusRole.neutral,
  );
  return (
    icon: switch (effective) {
      YumeiroStatusRole.success => icons.success,
      YumeiroStatusRole.warning => icons.warning,
      YumeiroStatusRole.danger => icons.error,
      _ => icons.info,
    },
    liveRegion: effective == YumeiroStatusRole.danger,
  );
}

/// Preset-owned colors for a semantic status tone.
@immutable
class YumeiroStatusVisual {
  const YumeiroStatusVisual({
    required this.foreground,
    required this.subtleFill,
    this.tint,
  });

  final Color foreground;
  final Color subtleFill;
  final Color? tint;

  YumeiroStatusVisual lerp(YumeiroStatusVisual other, double t) =>
      YumeiroStatusVisual(
        foreground: Color.lerp(foreground, other.foreground, t)!,
        subtleFill: Color.lerp(subtleFill, other.subtleFill, t)!,
        tint: Color.lerp(tint, other.tint, t),
      );
}

/// Selected and idle navigation-item visuals plus optional active indicators.
@immutable
class YumeiroNavigationItemVisual {
  const YumeiroNavigationItemVisual({
    required this.iconForeground,
    required this.labelForeground,
    required this.labelWeight,
    required this.topSurface,
    this.topIndicator,
    this.indicator,
    this.destinationIndicator,
    this.destinationForeground,
  });

  final Color iconForeground;
  final Color labelForeground;
  final FontWeight labelWeight;
  final YumeiroVisualAppearance topSurface;
  final YumeiroVisualAppearance? topIndicator;
  final YumeiroVisualAppearance? indicator;
  final YumeiroVisualAppearance? destinationIndicator;

  /// Optional ink for a selected bottom destination and its indicator fill.
  final Color? destinationForeground;

  YumeiroNavigationItemVisual lerp(
    YumeiroNavigationItemVisual other,
    double t,
  ) => YumeiroNavigationItemVisual(
    iconForeground: Color.lerp(iconForeground, other.iconForeground, t)!,
    labelForeground: Color.lerp(labelForeground, other.labelForeground, t)!,
    labelWeight: FontWeight.lerp(labelWeight, other.labelWeight, t)!,
    topSurface: topSurface.lerp(other.topSurface, t),
    topIndicator: topIndicator == null || other.topIndicator == null
        ? (t < .5 ? topIndicator : other.topIndicator)
        : topIndicator!.lerp(other.topIndicator!, t),
    indicator: indicator == null || other.indicator == null
        ? (t < .5 ? indicator : other.indicator)
        : indicator!.lerp(other.indicator!, t),
    destinationIndicator:
        destinationIndicator == null || other.destinationIndicator == null
        ? (t < .5 ? destinationIndicator : other.destinationIndicator)
        : destinationIndicator!.lerp(other.destinationIndicator!, t),
    destinationForeground:
        destinationForeground == null && other.destinationForeground == null
        ? null
        : Color.lerp(
            destinationForeground ?? iconForeground,
            other.destinationForeground ?? other.iconForeground,
            t,
          ),
  );
}

/// State-aware colors, outline, and shape used to render a checkbox.
@immutable
class YumeiroCheckboxVisuals {
  const YumeiroCheckboxVisuals({
    required this.fillColor,
    required this.checkColor,
    required this.overlayColor,
    required this.side,
    required this.shape,
  });

  final WidgetStateProperty<Color?> fillColor;
  final WidgetStateProperty<Color?> checkColor;
  final WidgetStateProperty<Color?> overlayColor;
  final WidgetStateBorderSide side;
  final OutlinedBorder shape;

  /// Adapts these visuals to Material's compact checkbox styling.
  CheckboxThemeData get materialTheme => CheckboxThemeData(
    fillColor: fillColor,
    checkColor: checkColor,
    overlayColor: overlayColor,
    side: side,
    shape: shape,
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    visualDensity: VisualDensity.compact,
    splashRadius: 12,
  );

  YumeiroCheckboxVisuals copyWith({
    WidgetStateProperty<Color?>? fillColor,
    WidgetStateProperty<Color?>? checkColor,
    WidgetStateProperty<Color?>? overlayColor,
    WidgetStateBorderSide? side,
    OutlinedBorder? shape,
  }) => YumeiroCheckboxVisuals(
    fillColor: fillColor ?? this.fillColor,
    checkColor: checkColor ?? this.checkColor,
    overlayColor: overlayColor ?? this.overlayColor,
    side: side ?? this.side,
    shape: shape ?? this.shape,
  );

  YumeiroCheckboxVisuals lerp(YumeiroCheckboxVisuals other, double t) =>
      YumeiroCheckboxVisuals(
        fillColor: WidgetStateProperty.lerp<Color?>(
          fillColor,
          other.fillColor,
          t,
          Color.lerp,
        )!,
        checkColor: WidgetStateProperty.lerp<Color?>(
          checkColor,
          other.checkColor,
          t,
          Color.lerp,
        )!,
        overlayColor: WidgetStateProperty.lerp<Color?>(
          overlayColor,
          other.overlayColor,
          t,
          Color.lerp,
        )!,
        side: WidgetStateBorderSide.resolveWith(
          (states) => BorderSide.lerp(
            side.resolve(states) ?? BorderSide.none,
            other.side.resolve(states) ?? BorderSide.none,
            t,
          ),
        ),
        shape: OutlinedBorder.lerp(shape, other.shape, t)!,
      );
}

/// State recipes and visual dimensions for a switch track and thumb.
@immutable
class YumeiroSwitchVisuals {
  /// Defines geometry in logical pixels with the thumb inside the track.
  /// The track width must exceed its height, which exceeds [thumbSize].
  YumeiroSwitchVisuals({
    required this.track,
    required this.thumb,
    this.trackSize = const Size(48, 28),
    this.thumbSize = 20,
  }) : assert(thumbSize > 0),
       assert(trackSize.height > thumbSize),
       assert(trackSize.width > trackSize.height);

  final YumeiroVisualRecipe track;
  final YumeiroVisualRecipe thumb;
  final Size trackSize;
  final double thumbSize;

  YumeiroSwitchVisuals lerp(YumeiroSwitchVisuals other, double t) =>
      YumeiroSwitchVisuals(
        track: track.lerp(other.track, t),
        thumb: thumb.lerp(other.thumb, t),
        trackSize: Size.lerp(trackSize, other.trackSize, t)!,
        thumbSize: thumbSize + (other.thumbSize - thumbSize) * t,
      );
}

/// Paint for a semantic surface, represented by a solid or gradient fill.
sealed class YumeiroFill {
  const YumeiroFill();

  /// Representative color for consumers that only accept a solid color.
  Color get fallbackColor;

  YumeiroFill lerp(YumeiroFill other, double t);
}

/// Surface fill painted with a single color.
@immutable
final class YumeiroSolidFill extends YumeiroFill {
  const YumeiroSolidFill(this.color);

  final Color color;

  @override
  Color get fallbackColor => color;

  @override
  YumeiroFill lerp(YumeiroFill other, double t) {
    if (other is YumeiroGradientFill) return other.lerp(this, 1 - t);
    other as YumeiroSolidFill;
    final target = other.color;
    if (t > 0 && t < 1) {
      // Fade only opacity when either endpoint has no visible color.
      final faded = Color.lerp(
        color.a == 0 ? null : color,
        target.a == 0 ? null : target,
        t,
      );
      if (faded != null) return YumeiroSolidFill(faded);
    }
    return YumeiroSolidFill(Color.lerp(color, target, t)!);
  }
}

/// Gradient paint with a caller-supplied representative solid color.
@immutable
final class YumeiroGradientFill extends YumeiroFill {
  const YumeiroGradientFill(this.gradient, {required this.fallbackColor});

  final Gradient gradient;

  @override
  final Color fallbackColor;

  @override
  YumeiroFill lerp(YumeiroFill other, double t) {
    final target = switch (other) {
      YumeiroGradientFill(:final gradient) => gradient,
      YumeiroSolidFill(:final color) => gradient.fromColor(color),
    };
    return YumeiroGradientFill(
      Gradient.lerp(gradient, target, t)!,
      fallbackColor: Color.lerp(fallbackColor, other.fallbackColor, t)!,
    );
  }
}

/// Keyboard focus outline and optional glow for a semantic recipe.
@immutable
class YumeiroFocusIndicator {
  YumeiroFocusIndicator({
    required this.side,
    this.gap = 2,
    List<BoxShadow> glow = const <BoxShadow>[],
  }) : glow = List.unmodifiable(glow);

  const YumeiroFocusIndicator._none()
    : side = BorderSide.none,
      gap = 0,
      glow = const [];

  /// Focus indicator with no visible paint.
  static const none = YumeiroFocusIndicator._none();

  final BorderSide side;

  /// Spacing from the outline of the surface, in logical pixels.
  final double gap;

  /// The immutable snapshot of the focus glow shadows.
  final List<BoxShadow> glow;

  bool get isVisible => side.style != BorderStyle.none && side.width > 0;

  YumeiroFocusIndicator lerp(YumeiroFocusIndicator other, double t) =>
      YumeiroFocusIndicator(
        side: BorderSide.lerp(side, other.side, t),
        gap: gap + (other.gap - gap) * t,
        glow: BoxShadow.lerpList(glow, other.glow, t) ?? const <BoxShadow>[],
      );
}

/// Timing and press scale used when a surface changes appearance.
@immutable
class YumeiroVisualTransition {
  const YumeiroVisualTransition({
    required this.duration,
    required this.curve,
    this.pressedScale = 1,
  });

  static const instant = YumeiroVisualTransition(
    duration: Duration.zero,
    curve: Curves.linear,
  );

  final Duration duration;
  final Curve curve;

  /// Scale used by controls that opt in to press feedback.
  final double pressedScale;

  YumeiroVisualTransition copyWith({
    Duration? duration,
    Curve? curve,
    double? pressedScale,
  }) => YumeiroVisualTransition(
    duration: duration ?? this.duration,
    curve: curve ?? this.curve,
    pressedScale: pressedScale ?? this.pressedScale,
  );

  YumeiroVisualTransition lerp(YumeiroVisualTransition other, double t) =>
      YumeiroVisualTransition(
        duration: Duration(
          microseconds:
              duration.inMicroseconds +
              ((other.duration.inMicroseconds - duration.inMicroseconds) * t)
                  .round(),
        ),
        curve: t < .5 ? curve : other.curve,
        pressedScale: pressedScale + (other.pressedScale - pressedScale) * t,
      );
}

/// Viewport backdrop and entry transform for modal overlays.
@immutable
class YumeiroModalVisuals {
  const YumeiroModalVisuals({
    this.barrierColor = const Color(0x80000000),
    this.backdropBlur = 24,
    this.entryScale = .94,
  });

  final Color barrierColor;
  final double backdropBlur;
  final double entryScale;

  YumeiroModalVisuals lerp(YumeiroModalVisuals other, double t) =>
      YumeiroModalVisuals(
        barrierColor: Color.lerp(barrierColor, other.barrierColor, t)!,
        backdropBlur: backdropBlur + (other.backdropBlur - backdropBlur) * t,
        entryScale: entryScale + (other.entryScale - entryScale) * t,
      );
}

/// Reusable visual material shared across semantic roles.
@immutable
class YumeiroVisualMaterial {
  const YumeiroVisualMaterial({
    required this.fill,
    this.outline = BorderSide.none,
    this.effects = YumeiroEffectStack.none,
  });

  final YumeiroFill fill;
  final BorderSide outline;
  final YumeiroEffectStack effects;

  YumeiroVisualMaterial copyWith({
    YumeiroFill? fill,
    BorderSide? outline,
    YumeiroEffectStack? effects,
  }) => YumeiroVisualMaterial(
    fill: fill ?? this.fill,
    outline: outline ?? this.outline,
    effects: effects ?? this.effects,
  );

  /// Adds a finish, replacing a pass with the same type and identifier.
  /// Core blur/glass effects keep the renderer's single-backdrop semantics.
  YumeiroVisualMaterial withPass(YumeiroEffectPass pass) =>
      copyWith(effects: effects.withPass(pass));

  /// Applies material while preserving content, geometry, focus, and motion.
  /// The destination's effect stack is explicitly replaced, not merged.
  YumeiroVisualAppearance applyTo(YumeiroVisualAppearance appearance) =>
      appearance.copyWith(fill: fill, outline: outline, effects: effects);

  YumeiroVisualAppearance appearance({
    required Color foreground,
    required OutlinedBorder shape,
    required YumeiroVisualTransition transition,
    double opacity = 1,
  }) => YumeiroVisualAppearance(
    fill: fill,
    foreground: foreground,
    shape: shape,
    outline: outline,
    effects: effects,
    opacity: opacity,
    transition: transition,
  );
}

/// Resolved paint instructions consumed by [YumeiroResolvedVisualSurface].
@immutable
class YumeiroVisualAppearance {
  const YumeiroVisualAppearance({
    required this.fill,
    required this.foreground,
    required this.shape,
    required this.transition,
    this.outline = BorderSide.none,
    this.focusIndicator = YumeiroFocusIndicator.none,
    this.effects = YumeiroEffectStack.none,
    this.opacity = 1,
  });

  final YumeiroFill fill;
  final Color foreground;
  final OutlinedBorder shape;
  final BorderSide outline;
  final YumeiroFocusIndicator focusIndicator;
  final YumeiroEffectStack effects;
  final double opacity;
  final YumeiroVisualTransition transition;

  Color get background =>
      fill.fallbackColor.withValues(alpha: fill.fallbackColor.a * opacity);
  BorderSide get border =>
      focusIndicator.isVisible ? focusIndicator.side : outline;
  List<BoxShadow> get shadows => effects.outerShadows;

  YumeiroVisualAppearance copyWith({
    YumeiroFill? fill,
    Color? foreground,
    OutlinedBorder? shape,
    BorderSide? outline,
    YumeiroFocusIndicator? focusIndicator,
    YumeiroEffectStack? effects,
    double? opacity,
    YumeiroVisualTransition? transition,
  }) => YumeiroVisualAppearance(
    fill: fill ?? this.fill,
    foreground: foreground ?? this.foreground,
    shape: shape ?? this.shape,
    outline: outline ?? this.outline,
    focusIndicator: focusIndicator ?? this.focusIndicator,
    effects: effects ?? this.effects,
    opacity: opacity ?? this.opacity,
    transition: transition ?? this.transition,
  );

  /// Applies a sparse delta to this appearance.
  ///
  /// Null fields keep their values. Fill opacity multiplies the alpha of the
  /// chosen fill after applying any replacement fill. Effects are replaced
  /// as a stack, and the focus indicator is retained.
  YumeiroVisualAppearance apply(YumeiroVisualDelta? delta) {
    if (delta == null) return this;
    var nextFill = delta.fill ?? fill;
    if (delta.fillOpacity case final double alpha) {
      nextFill = switch (nextFill) {
        YumeiroSolidFill(:final color) => YumeiroSolidFill(
          color.withValues(alpha: color.a * alpha),
        ),
        YumeiroGradientFill(:final gradient, :final fallbackColor) =>
          YumeiroGradientFill(
            gradient.scale(alpha),
            fallbackColor: fallbackColor.withValues(
              alpha: fallbackColor.a * alpha,
            ),
          ),
      };
    }
    return copyWith(
      fill: nextFill,
      foreground: delta.foreground,
      shape: delta.shape,
      outline: delta.outline,
      effects: delta.effects,
      opacity: delta.opacity,
      transition: delta.transition,
    );
  }

  YumeiroVisualAppearance lerp(YumeiroVisualAppearance other, double t) =>
      YumeiroVisualAppearance(
        fill: fill.lerp(other.fill, t),
        foreground: Color.lerp(foreground, other.foreground, t)!,
        shape: OutlinedBorder.lerp(shape, other.shape, t)!,
        outline: BorderSide.lerp(outline, other.outline, t),
        focusIndicator: focusIndicator.lerp(other.focusIndicator, t),
        effects: effects.lerp(other.effects, t),
        opacity: opacity + (other.opacity - opacity) * t,
        transition: transition.lerp(other.transition, t),
      );
}

/// Incremental appearance delta. Focus is deliberately omitted so callers
/// cannot accidentally strip accessibility focus indicators.
@immutable
class YumeiroVisualDelta {
  const YumeiroVisualDelta({
    this.fill,
    this.fillOpacity,
    this.foreground,
    this.shape,
    this.outline,
    this.effects,
    this.opacity,
    this.transition,
  });

  final YumeiroFill? fill;

  /// Multiplier for the selected fill's alpha. The rest of the surface
  /// retains its opacity.
  final double? fillOpacity;
  final Color? foreground;
  final OutlinedBorder? shape;
  final BorderSide? outline;

  /// Replacement effect stack. Use [YumeiroEffectStack.none] to remove effects.
  final YumeiroEffectStack? effects;

  /// Replacement overall surface opacity, independent of [fillOpacity].
  final double? opacity;
  final YumeiroVisualTransition? transition;
}

/// Common and state-specific adjustments applied after a recipe is resolved.
@immutable
class YumeiroVisualOverride {
  const YumeiroVisualOverride({
    this.base = const YumeiroVisualDelta(),
    this.states,
  });

  /// Adjustment applied for every state.
  final YumeiroVisualDelta base;

  /// Optional adjustment applied on top of [base] for the current states.
  final WidgetStateProperty<YumeiroVisualDelta?>? states;

  YumeiroVisualAppearance apply(
    YumeiroVisualAppearance appearance,
    Set<WidgetState> widgetStates,
  ) => appearance.apply(base).apply(states?.resolve(widgetStates));
}

/// Resolves a semantic role's appearance for resting and interactive states.
@immutable
class YumeiroVisualRecipe {
  const YumeiroVisualRecipe({
    required this.base,
    this.states,
    this.focusIndicator = YumeiroFocusIndicator.none,
  });

  /// Resting appearance, also used when [states] returns null.
  final YumeiroVisualAppearance base;

  /// Optional source of complete appearances for the current state set.
  final WidgetStateProperty<YumeiroVisualAppearance?>? states;

  /// Indicator applied when the widget is focused and enabled.
  final YumeiroFocusIndicator focusIndicator;

  YumeiroVisualAppearance _resolveBody(Set<WidgetState> widgetStates) =>
      states?.resolve(widgetStates) ?? base;

  /// Resolves the state appearance, adds the enabled focus indicator, then
  /// applies the optional host override.
  YumeiroVisualAppearance resolve(
    Set<WidgetState> widgetStates, {
    YumeiroVisualOverride? override,
  }) {
    final disabled = widgetStates.contains(WidgetState.disabled);
    var appearance = _resolveBody(widgetStates);
    if (!disabled && widgetStates.contains(WidgetState.focused)) {
      appearance = appearance.copyWith(focusIndicator: focusIndicator);
    }
    return override?.apply(appearance, widgetStates) ?? appearance;
  }

  YumeiroVisualRecipe lerp(YumeiroVisualRecipe other, double t) =>
      YumeiroVisualRecipe(
        base: base.lerp(other.base, t),
        states: WidgetStateProperty.resolveWith(
          (widgetStates) =>
              _resolveBody(widgetStates)
                  .lerp(other._resolveBody(widgetStates), t),
        ),
        focusIndicator: focusIndicator.lerp(other.focusIndicator, t),
      );
}

/// Extensible semantic visual rule table for a theme preset.
///
/// The constructor requires the original built-in recipe set. Later built-in
/// roles can inherit a fallback, just like custom roles. Use the recipe lookup
/// methods to resolve registered roles and their fallback chains.
@immutable
class YumeiroSemanticVisualTheme {
  YumeiroSemanticVisualTheme({
    required Map<YumeiroSurfaceRole, YumeiroVisualRecipe> surfaces,
    required Map<YumeiroControlRole, YumeiroVisualRecipe> controls,
    required Map<YumeiroItemRole, YumeiroVisualRecipe> items,
    required Map<YumeiroStatusRole, YumeiroStatusVisual> statuses,
    required this.navigationItems,
    this.customStatusTintOpacity = .12,
  }) : surfaces = Map.unmodifiable(surfaces),
       controls = Map.unmodifiable(controls),
       items = Map.unmodifiable(items),
       statuses = Map.unmodifiable(statuses) {
    _validateRequiredRecipes(this.surfaces, _requiredSurfaceRoles, 'surface');
    _validateRequiredRecipes(this.controls, _requiredControlRoles, 'control');
    _validateRequiredRecipes(this.items, _requiredItemRoles, 'item');
    _validateRequiredRecipes(this.statuses, _requiredStatusRoles, 'status');
    assert(customStatusTintOpacity >= 0 && customStatusTintOpacity <= 1);
  }

  // Keep this constructor contract fixed when the built-in catalogs grow.
  // New built-in roles must fall back to an existing recipe.
  static const _requiredSurfaceRoles = [
    YumeiroSurfaceRole.canvas,
    YumeiroSurfaceRole.navigation,
    YumeiroSurfaceRole.panel,
    YumeiroSurfaceRole.inset,
    YumeiroSurfaceRole.compact,
    YumeiroSurfaceRole.readout,
    YumeiroSurfaceRole.card,
    YumeiroSurfaceRole.floating,
    YumeiroSurfaceRole.modal,
    YumeiroSurfaceRole.toast,
    YumeiroSurfaceRole.scrim,
    YumeiroSurfaceRole.media,
  ];
  static const _requiredControlRoles = [
    YumeiroControlRole.neutral,
    YumeiroControlRole.secondary,
    YumeiroControlRole.primary,
    YumeiroControlRole.danger,
    YumeiroControlRole.ghost,
    YumeiroControlRole.overlay,
  ];
  static const _requiredItemRoles = [
    YumeiroItemRole.standard,
    YumeiroItemRole.danger,
    YumeiroItemRole.navigation,
    YumeiroItemRole.selection,
  ];
  static const _requiredStatusRoles = [
    YumeiroStatusRole.neutral,
    YumeiroStatusRole.info,
    YumeiroStatusRole.accent,
    YumeiroStatusRole.success,
    YumeiroStatusRole.warning,
    YumeiroStatusRole.danger,
  ];

  /// Explicitly registered surface recipes. Use [surfaceRecipe] for fallbacks.
  final Map<YumeiroSurfaceRole, YumeiroVisualRecipe> surfaces;

  /// Explicitly registered control recipes. Use [controlRecipe] for fallbacks.
  final Map<YumeiroControlRole, YumeiroVisualRecipe> controls;

  /// Explicitly registered item recipes. [itemRecipe] also resolves fallbacks.
  final Map<YumeiroItemRole, YumeiroVisualRecipe> items;

  /// Explicitly registered status visuals. [status] also resolves fallbacks.
  final Map<YumeiroStatusRole, YumeiroStatusVisual> statuses;
  final WidgetStateProperty<YumeiroNavigationItemVisual> navigationItems;
  final double customStatusTintOpacity;

  YumeiroVisualRecipe surfaceRecipe(YumeiroSurfaceRole role) =>
      _resolveRole(role, surfaces, (r) => r.fallback, YumeiroSurfaceRole.panel);

  YumeiroVisualRecipe controlRecipe(YumeiroControlRole role) => _resolveRole(
    role,
    controls,
    (r) => r.fallback,
    YumeiroControlRole.neutral,
  );

  YumeiroVisualRecipe itemRecipe(YumeiroItemRole role) =>
      _resolveRole(role, items, (r) => r.fallback, YumeiroItemRole.standard);

  YumeiroStatusVisual status(YumeiroStatusRole role) => _resolveRole(
    role,
    statuses,
    (r) => r.fallback,
    YumeiroStatusRole.neutral,
  );

  YumeiroVisualAppearance surface(
    YumeiroSurfaceRole role, [
    Set<WidgetState> states = const <WidgetState>{},
    YumeiroVisualOverride? override,
  ]) => surfaceRecipe(role).resolve(states, override: override);

  YumeiroVisualAppearance control(
    YumeiroControlRole role,
    Set<WidgetState> states, [
    YumeiroVisualOverride? override,
  ]) => controlRecipe(role).resolve(states, override: override);

  YumeiroVisualAppearance item(
    YumeiroItemRole role,
    Set<WidgetState> states, [
    YumeiroVisualOverride? override,
  ]) => itemRecipe(role).resolve(states, override: override);

  YumeiroVisualAppearance resolveRole(
    YumeiroVisualRole role, [
    Set<WidgetState> states = const <WidgetState>{},
    YumeiroVisualOverride? override,
  ]) => switch (role) {
    final YumeiroSurfaceRole r => surface(r, states, override),
    final YumeiroControlRole r => control(r, states, override),
    final YumeiroItemRole r => item(r, states, override),
  };

  YumeiroNavigationItemVisual navigationItem(Set<WidgetState> states) =>
      navigationItems.resolve(states);

  Color customStatusFill(Color tint) => yumeiroAlphaBlend(
    tint.withValues(alpha: customStatusTintOpacity),
    surface(YumeiroSurfaceRole.compact).background.withValues(alpha: 1),
  );

  Color customStatusForeground(Color tint) =>
      statuses.values
          .where((status) => status.tint == tint)
          .firstOrNull
          ?.foreground ??
      tint;

  /// Returns a new [YumeiroSemanticVisualTheme] augmented or overridden with
  /// custom role recipes and/or status visuals.
  YumeiroSemanticVisualTheme extend({
    Map<YumeiroSurfaceRole, YumeiroVisualRecipe> surfaces = const {},
    Map<YumeiroControlRole, YumeiroVisualRecipe> controls = const {},
    Map<YumeiroItemRole, YumeiroVisualRecipe> items = const {},
    Map<YumeiroStatusRole, YumeiroStatusVisual> statuses = const {},
    WidgetStateProperty<YumeiroNavigationItemVisual>? navigationItems,
    double? customStatusTintOpacity,
  }) => YumeiroSemanticVisualTheme(
    surfaces: {...this.surfaces, ...surfaces},
    controls: {...this.controls, ...controls},
    items: {...this.items, ...items},
    statuses: {...this.statuses, ...statuses},
    navigationItems: navigationItems ?? this.navigationItems,
    customStatusTintOpacity:
        customStatusTintOpacity ?? this.customStatusTintOpacity,
  );

  YumeiroSemanticVisualTheme lerp(YumeiroSemanticVisualTheme other, double t) {
    final surfaceKeys = <YumeiroSurfaceRole>{
      ...surfaces.keys,
      ...other.surfaces.keys,
    };
    final controlKeys = <YumeiroControlRole>{
      ...controls.keys,
      ...other.controls.keys,
    };
    final itemKeys = <YumeiroItemRole>{...items.keys, ...other.items.keys};
    final statusKeys = <YumeiroStatusRole>{
      ...statuses.keys,
      ...other.statuses.keys,
    };

    return YumeiroSemanticVisualTheme(
      surfaces: {
        for (final role in surfaceKeys)
          role: surfaceRecipe(role).lerp(other.surfaceRecipe(role), t),
      },
      controls: {
        for (final role in controlKeys)
          role: controlRecipe(role).lerp(other.controlRecipe(role), t),
      },
      items: {
        for (final role in itemKeys)
          role: itemRecipe(role).lerp(other.itemRecipe(role), t),
      },
      statuses: {
        for (final role in statusKeys)
          role: status(role).lerp(other.status(role), t),
      },
      navigationItems: WidgetStateProperty.resolveWith(
        (states) =>
            navigationItem(states).lerp(other.navigationItem(states), t),
      ),
      customStatusTintOpacity:
          customStatusTintOpacity +
          (other.customStatusTintOpacity - customStatusTintOpacity) * t,
    );
  }

  static V _resolveRole<R extends Object, V>(
    R role,
    Map<R, V> table,
    R? Function(R) nextFallback,
    R rootDefault,
  ) {
    final direct = table[role];
    if (direct != null) return direct;
    final visited = <R>{role};
    var cursor = nextFallback(role);
    while (cursor != null && visited.add(cursor)) {
      final hit = table[cursor];
      if (hit != null) return hit;
      cursor = nextFallback(cursor);
    }
    return table[rootDefault]!;
  }

  static void _validateRequiredRecipes<T, V>(
    Map<T, V> recipes,
    List<T> requiredRoles,
    String category,
  ) {
    final missing = requiredRoles
        .where((role) => !recipes.containsKey(role))
        .toList();
    if (missing.isNotEmpty) {
      throw ArgumentError('Missing built-in $category recipes: $missing');
    }
  }
}
