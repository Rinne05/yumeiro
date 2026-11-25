import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:material_ui/material_ui.dart';

/// Global rendering pipeline capability tier controlling optical shader fallback.
///
/// Automatically resolves from [fullOptical] to [blurOnly] when the active
/// engine does not support [ui.ImageFilter.isShaderFilterSupported], or can be
/// overridden via [YumeiroMaterialCapabilityScope] for testing fallback rendering.
enum YumeiroMaterialCapability {
  /// Blur-only rendering: runs Gaussian backdrop blur + tint fallback without
  /// optical refraction shaders.
  blurOnly,

  /// Full optical pipeline: enables custom liquid-glass fragment shaders,
  /// backdrop blur, and all registered passes.
  fullOptical;

  /// Whether this tier includes a feature requiring [required].
  bool supports(YumeiroMaterialCapability required) => index >= required.index;

  /// Resolves an effective capability considering engine shader support.
  YumeiroMaterialCapability resolveForRuntime() {
    if (this == YumeiroMaterialCapability.fullOptical &&
        !ui.ImageFilter.isShaderFilterSupported) {
      return YumeiroMaterialCapability.blurOnly;
    }
    return this;
  }
}

/// Inherited scope controlling the active [YumeiroMaterialCapability] tier.
class YumeiroMaterialCapabilityScope extends InheritedWidget {
  const YumeiroMaterialCapabilityScope({
    super.key,
    required this.capability,
    required super.child,
  });

  /// Requested tier before runtime shader support is checked.
  final YumeiroMaterialCapability capability;

  static YumeiroMaterialCapability? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<YumeiroMaterialCapabilityScope>()
      ?.capability;

  /// Reads the requested tier, defaulting to the full optical request.
  ///
  /// Call [YumeiroMaterialCapability.resolveForRuntime] to check actual support.
  static YumeiroMaterialCapability of(BuildContext context) =>
      maybeOf(context) ?? YumeiroMaterialCapability.fullOptical;

  @override
  bool updateShouldNotify(YumeiroMaterialCapabilityScope oldWidget) =>
      capability != oldWidget.capability;
}

/// Shadow or highlight clipped inside a surface's outline.
@immutable
class YumeiroInnerShadow {
  const YumeiroInnerShadow({
    required this.color,
    this.blurRadius = 0,
    this.offset = Offset.zero,
    this.spreadRadius = 0,
    this.isHighlight = false,
  });

  final Color color;
  final double blurRadius;
  final Offset offset;
  final double spreadRadius;

  /// Whether this edge represents light and is independent of shadow tuning.
  final bool isHighlight;

  @override
  bool operator ==(Object other) =>
      other is YumeiroInnerShadow &&
      color == other.color &&
      blurRadius == other.blurRadius &&
      offset == other.offset &&
      spreadRadius == other.spreadRadius &&
      isHighlight == other.isHighlight;

  @override
  int get hashCode =>
      Object.hash(color, blurRadius, offset, spreadRadius, isHighlight);

  YumeiroInnerShadow lerp(YumeiroInnerShadow other, double t) =>
      YumeiroInnerShadow(
        color: Color.lerp(color, other.color, t)!,
        blurRadius: blurRadius + (other.blurRadius - blurRadius) * t,
        offset: Offset.lerp(offset, other.offset, t)!,
        spreadRadius: spreadRadius + (other.spreadRadius - spreadRadius) * t,
        isHighlight: t < .5 ? isHighlight : other.isHighlight,
      );
}

/// A light rim drawn as a box shadow and independent of shadow tuning.
@immutable
final class YumeiroOuterHighlight extends BoxShadow {
  const YumeiroOuterHighlight({
    required super.color,
    super.offset,
    super.blurRadius,
    super.spreadRadius,
    super.blurStyle,
  });

  YumeiroOuterHighlight._fromShadow(BoxShadow shadow)
    : this(
        color: shadow.color,
        offset: shadow.offset,
        blurRadius: shadow.blurRadius,
        spreadRadius: shadow.spreadRadius,
        blurStyle: shadow.blurStyle,
      );

  @override
  YumeiroOuterHighlight copyWith({
    Color? color,
    Offset? offset,
    double? blurRadius,
    double? spreadRadius,
    BlurStyle? blurStyle,
  }) => YumeiroOuterHighlight(
    color: color ?? this.color,
    offset: offset ?? this.offset,
    blurRadius: blurRadius ?? this.blurRadius,
    spreadRadius: spreadRadius ?? this.spreadRadius,
    blurStyle: blurStyle ?? this.blurStyle,
  );

  @override
  YumeiroOuterHighlight scale(double factor) => copyWith(
    offset: offset * factor,
    blurRadius: blurRadius * factor,
    spreadRadius: spreadRadius * factor,
  );
}

/// Optical parameters for edge refraction and directional rim lighting.
@immutable
class YumeiroGlassEffect {
  const YumeiroGlassEffect({
    required this.tint,
    this.refraction = 8,
    this.thickness = 18,
    this.pressure = 0,
    this.intensity = 1,
    this.lighting = 1,
  });

  final Color tint;
  final double refraction;
  final double thickness;
  final double pressure;
  final double intensity;
  final double lighting;

  YumeiroGlassEffect copyWith({
    Color? tint,
    double? refraction,
    double? thickness,
    double? pressure,
    double? intensity,
    double? lighting,
  }) => YumeiroGlassEffect(
    tint: tint ?? this.tint,
    refraction: refraction ?? this.refraction,
    thickness: thickness ?? this.thickness,
    pressure: pressure ?? this.pressure,
    intensity: intensity ?? this.intensity,
    lighting: lighting ?? this.lighting,
  );

  @override
  bool operator ==(Object other) =>
      other is YumeiroGlassEffect &&
      tint == other.tint &&
      refraction == other.refraction &&
      thickness == other.thickness &&
      pressure == other.pressure &&
      intensity == other.intensity &&
      lighting == other.lighting;

  @override
  int get hashCode =>
      Object.hash(tint, refraction, thickness, pressure, intensity, lighting);

  static YumeiroGlassEffect? lerp(
    YumeiroGlassEffect? a,
    YumeiroGlassEffect? b,
    double t,
  ) {
    if (a == null && b == null) return null;
    return YumeiroGlassEffect(
      tint: Color.lerp(a?.tint ?? b!.tint, b?.tint ?? a!.tint, t)!,
      refraction:
          (a?.refraction ?? 0) +
          ((b?.refraction ?? 0) - (a?.refraction ?? 0)) * t,
      thickness:
          (a?.thickness ?? b!.thickness) +
          ((b?.thickness ?? a!.thickness) - (a?.thickness ?? b!.thickness)) * t,
      pressure:
          (a?.pressure ?? 0) + ((b?.pressure ?? 0) - (a?.pressure ?? 0)) * t,
      intensity:
          (a?.intensity ?? 0) + ((b?.intensity ?? 0) - (a?.intensity ?? 0)) * t,
      lighting:
          (a?.lighting ?? b!.lighting) +
          ((b?.lighting ?? a!.lighting) - (a?.lighting ?? b!.lighting)) * t,
    );
  }
}

/// Pluggable rendering pass executed by the Yumeiro surface pipeline.
///
/// Subclass [YumeiroEffectPass] to attach custom shaders, grain/noise layers,
/// directional glows, or custom canvas decorators to any visual recipe.
@immutable
abstract class YumeiroEffectPass {
  const YumeiroEffectPass({
    this.id,
    this.minCapability = YumeiroMaterialCapability.blurOnly,
  });

  /// Optional identifier used to match passes across recipe states/presets.
  final String? id;

  /// Minimum capability tier required to execute this pass without degradation.
  final YumeiroMaterialCapability minCapability;

  /// Whether this pass samples or filters the live backdrop behind the surface.
  bool get usesBackdrop => false;

  /// Interpolates from this pass toward [other] at [t] in `[0, 1]`.
  /// When [other] is `null`, fades this pass toward its neutral/no-op state.
  YumeiroEffectPass? lerp(YumeiroEffectPass? other, double t);

  /// Wraps the surface widget subtree when active under [capability].
  Widget wrapSurface({
    required BuildContext context,
    required OutlinedBorder shape,
    required YumeiroMaterialCapability capability,
    required Widget child,
  }) => child;

  /// Optional canvas hook painted behind surface fill inside the surface bounds.
  void paintBeforeFill(
    Canvas canvas,
    Size size,
    OutlinedBorder shape,
    YumeiroMaterialCapability capability,
  ) {}

  /// Paints material decoration after fill and before the surface's content.
  ///
  /// Use this for texture, sheen, and other surface finishes that must never
  /// cover labels or icons. The renderer clips this layer to [shape] and
  /// supplies [textDirection] for directional shapes and gradients.
  void paintMaterial(
    Canvas canvas,
    Size size,
    OutlinedBorder shape,
    YumeiroMaterialCapability capability, {
    TextDirection? textDirection,
  }) {}

  /// Direction-aware foreground hook painted above the surface's content.
  ///
  /// The renderer supplies [textDirection] for directional shapes and gradients.
  /// Use [paintMaterial] for decoration between the fill and the content.
  void paintForeground(
    Canvas canvas,
    Size size,
    OutlinedBorder shape,
    YumeiroMaterialCapability capability, {
    TextDirection? textDirection,
  }) {}
}

/// Outer drop shadows owned by the surface renderer.
@immutable
class YumeiroOuterShadowPass extends YumeiroEffectPass {
  YumeiroOuterShadowPass(
    List<BoxShadow> shadows, {
    super.id = 'outer-shadow',
    super.minCapability = YumeiroMaterialCapability.blurOnly,
  }) : shadows = List.unmodifiable(shadows);

  /// The immutable snapshot of the shadows in this pass.
  final List<BoxShadow> shadows;

  @override
  YumeiroEffectPass? lerp(YumeiroEffectPass? other, double t) {
    if (other != null && other is! YumeiroOuterShadowPass) {
      return t < .5 ? this : other;
    }
    final target = (other as YumeiroOuterShadowPass?)?.shadows ?? const [];
    if (shadows.isEmpty && target.isEmpty) return null;
    if (identical(shadows, target)) return this;
    final commonLength = shadows.length < target.length
        ? shadows.length
        : target.length;

    // Flutter scales just the geometry when a shadow has no counterpart.
    BoxShadow fade(BoxShadow shadow, double weight) => shadow
        .scale(weight)
        .copyWith(color: Color.lerp(null, shadow.color, weight));

    BoxShadow interpolate(BoxShadow first, BoxShadow second) {
      final shadow = BoxShadow.lerp(first, second, t)!;
      return (t < .5 ? first : second) is YumeiroOuterHighlight &&
              shadow is! YumeiroOuterHighlight
          ? YumeiroOuterHighlight._fromShadow(shadow)
          : shadow;
    }

    final lerped = [
      for (var i = 0; i < commonLength; i++) interpolate(shadows[i], target[i]),
      for (final shadow in shadows.skip(commonLength)) fade(shadow, 1 - t),
      for (final shadow in target.skip(commonLength)) fade(shadow, t),
    ];
    return YumeiroOuterShadowPass(lerped, id: id, minCapability: minCapability);
  }

  @override
  bool operator ==(Object other) =>
      other is YumeiroOuterShadowPass &&
      id == other.id &&
      minCapability == other.minCapability &&
      listEquals(shadows, other.shadows);

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, minCapability, Object.hashAll(shadows));
}

/// Inner directional bevel or recessed shadow pass.
@immutable
class YumeiroInnerShadowPass extends YumeiroEffectPass {
  YumeiroInnerShadowPass(
    List<YumeiroInnerShadow> shadows, {
    super.id = 'inner-shadow',
    super.minCapability = YumeiroMaterialCapability.blurOnly,
  }) : shadows = List.unmodifiable(shadows);

  /// The immutable snapshot of the shadows in this pass.
  final List<YumeiroInnerShadow> shadows;

  @override
  YumeiroEffectPass? lerp(YumeiroEffectPass? other, double t) {
    if (other != null && other is! YumeiroInnerShadowPass) {
      return t < .5 ? this : other;
    }
    final target = (other as YumeiroInnerShadowPass?)?.shadows ?? const [];
    final maxLen = shadows.length > target.length
        ? shadows.length
        : target.length;
    if (maxLen == 0) return null;
    final lerped = List<YumeiroInnerShadow>.generate(maxLen, (index) {
      final first = index < shadows.length ? shadows[index] : null;
      final second = index < target.length ? target[index] : null;
      YumeiroInnerShadow transparent(YumeiroInnerShadow s) =>
          YumeiroInnerShadow(
            color: s.color.withValues(alpha: 0),
            blurRadius: s.blurRadius,
            offset: s.offset,
            spreadRadius: s.spreadRadius,
            isHighlight: s.isHighlight,
          );
      return (first ?? transparent(second!)).lerp(
        second ?? transparent(first!),
        t,
      );
    }, growable: false);
    return YumeiroInnerShadowPass(lerped, id: id, minCapability: minCapability);
  }

  @override
  bool operator ==(Object other) =>
      other is YumeiroInnerShadowPass &&
      id == other.id &&
      minCapability == other.minCapability &&
      listEquals(shadows, other.shadows);

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, minCapability, Object.hashAll(shadows));
}

/// Gaussian backdrop blur + optional tint pass.
@immutable
class YumeiroBackdropBlurPass extends YumeiroEffectPass {
  const YumeiroBackdropBlurPass({
    required this.sigma,
    this.tint,
    super.id = 'backdrop-blur',
    super.minCapability = YumeiroMaterialCapability.blurOnly,
  });

  final double sigma;
  final Color? tint;

  @override
  bool get usesBackdrop => sigma > 0;

  @override
  YumeiroEffectPass? lerp(YumeiroEffectPass? other, double t) {
    if (other != null && other is! YumeiroBackdropBlurPass) {
      return t < .5 ? this : other;
    }
    final target = other as YumeiroBackdropBlurPass?;
    final nextSigma = sigma + ((target?.sigma ?? 0) - sigma) * t;
    final nextTint = Color.lerp(tint, target?.tint, t);
    if (nextSigma <= 0.001 && nextTint == null) return null;
    return YumeiroBackdropBlurPass(
      sigma: nextSigma,
      tint: nextTint,
      id: id,
      minCapability: minCapability,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is YumeiroBackdropBlurPass &&
      id == other.id &&
      minCapability == other.minCapability &&
      sigma == other.sigma &&
      tint == other.tint;

  @override
  int get hashCode => Object.hash(runtimeType, id, minCapability, sigma, tint);
}

/// Optical liquid-glass refraction & rim lighting pass with shader fallback.
///
/// - Under [YumeiroMaterialCapability.fullOptical]: runs `shaders/liquid_glass.frag`
///   plus optional background Gaussian blur.
/// - Under [YumeiroMaterialCapability.blurOnly]: degrades cleanly to Gaussian
///   blur + [fallbackTint].
@immutable
class YumeiroLiquidGlassPass extends YumeiroEffectPass {
  const YumeiroLiquidGlassPass({
    required this.glass,
    this.blur = 0,
    this.fallbackTint,
    super.id = 'liquid-glass',
    super.minCapability = YumeiroMaterialCapability.fullOptical,
  });

  final YumeiroGlassEffect glass;
  final double blur;
  final Color? fallbackTint;

  @override
  bool get usesBackdrop => true;

  @override
  YumeiroEffectPass? lerp(YumeiroEffectPass? other, double t) {
    if (other != null && other is! YumeiroLiquidGlassPass) {
      return t < .5 ? this : other;
    }
    final target = other as YumeiroLiquidGlassPass?;
    final nextGlass = YumeiroGlassEffect.lerp(glass, target?.glass, t);
    if (nextGlass == null) return null;
    return YumeiroLiquidGlassPass(
      glass: nextGlass,
      blur: blur + ((target?.blur ?? 0) - blur) * t,
      fallbackTint: Color.lerp(fallbackTint, target?.fallbackTint, t),
      id: id,
      minCapability: minCapability,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is YumeiroLiquidGlassPass &&
      id == other.id &&
      minCapability == other.minCapability &&
      glass == other.glass &&
      blur == other.blur &&
      fallbackTint == other.fallbackTint;

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, minCapability, glass, blur, fallbackTint);
}

/// Optional tint/blend overlay pass painted inside the clipped surface shape.
@immutable
class YumeiroTintOverlayPass extends YumeiroEffectPass {
  const YumeiroTintOverlayPass({
    required this.color,
    this.blendMode = BlendMode.srcOver,
    super.id = 'tint-overlay',
    super.minCapability = YumeiroMaterialCapability.blurOnly,
  });

  final Color color;
  final BlendMode blendMode;

  @override
  void paintForeground(
    Canvas canvas,
    Size size,
    OutlinedBorder shape,
    YumeiroMaterialCapability capability, {
    TextDirection? textDirection,
  }) {
    if (color.a <= 0) return;
    canvas.drawPath(
      shape.getOuterPath(Offset.zero & size, textDirection: textDirection),
      Paint()
        ..color = color
        ..blendMode = blendMode,
    );
  }

  @override
  YumeiroEffectPass? lerp(YumeiroEffectPass? other, double t) {
    if (other != null && other is! YumeiroTintOverlayPass) {
      return t < .5 ? this : other;
    }
    final target = other as YumeiroTintOverlayPass?;
    final lerped = Color.lerp(
      color,
      target?.color ?? color.withValues(alpha: 0),
      t,
    );
    if (lerped == null || lerped.a <= 0.001) return null;
    return YumeiroTintOverlayPass(
      color: lerped,
      blendMode: t < .5 ? blendMode : (target?.blendMode ?? blendMode),
      id: id,
      minCapability: minCapability,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is YumeiroTintOverlayPass &&
      id == other.id &&
      minCapability == other.minCapability &&
      color == other.color &&
      blendMode == other.blendMode;

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, minCapability, color, blendMode);
}

/// Ordered stack of [YumeiroEffectPass]es owned by the Yumeiro renderer.
@immutable
class YumeiroEffectStack {
  factory YumeiroEffectStack({
    List<BoxShadow> outerShadows = const <BoxShadow>[],
    List<YumeiroInnerShadow> innerShadows = const <YumeiroInnerShadow>[],
    double backdropBlur = 0,
    Color? backdropTint,
    YumeiroGlassEffect? glass,
    List<YumeiroEffectPass> extraPasses = const <YumeiroEffectPass>[],
  }) {
    final passes = <YumeiroEffectPass>[
      if (outerShadows.isNotEmpty) YumeiroOuterShadowPass(outerShadows),
      if (innerShadows.isNotEmpty) YumeiroInnerShadowPass(innerShadows),
      if (glass != null)
        YumeiroLiquidGlassPass(
          glass: glass,
          blur: backdropBlur,
          fallbackTint: backdropTint,
        )
      else if (backdropBlur > 0 || backdropTint != null)
        YumeiroBackdropBlurPass(sigma: backdropBlur, tint: backdropTint),
      ...extraPasses,
    ];
    return YumeiroEffectStack.fromPasses(passes);
  }

  /// Takes an immutable snapshot of [passes] in their original order.
  YumeiroEffectStack.fromPasses(Iterable<YumeiroEffectPass> passes)
    : passes = List.unmodifiable(passes);

  const YumeiroEffectStack._(this.passes);

  static const none = YumeiroEffectStack._(<YumeiroEffectPass>[]);

  /// The immutable snapshot of the passes in this stack.
  final List<YumeiroEffectPass> passes;

  List<BoxShadow> get outerShadows =>
      passOf<YumeiroOuterShadowPass>()?.shadows ?? const <BoxShadow>[];

  List<YumeiroInnerShadow> get innerShadows =>
      passOf<YumeiroInnerShadowPass>()?.shadows ?? const <YumeiroInnerShadow>[];

  YumeiroGlassEffect? get glass => passOf<YumeiroLiquidGlassPass>()?.glass;

  double get backdropBlur =>
      passOf<YumeiroLiquidGlassPass>()?.blur ??
      passOf<YumeiroBackdropBlurPass>()?.sigma ??
      0;

  Color? get backdropTint =>
      passOf<YumeiroLiquidGlassPass>()?.fallbackTint ??
      passOf<YumeiroBackdropBlurPass>()?.tint;

  /// Extra custom passes beyond the core shadow/blur/glass passes.
  List<YumeiroEffectPass> get customPasses => List.unmodifiable(
    passes.where(
      (pass) =>
          pass is! YumeiroOuterShadowPass &&
          pass is! YumeiroInnerShadowPass &&
          pass is! YumeiroBackdropBlurPass &&
          pass is! YumeiroLiquidGlassPass,
    ),
  );

  T? passOf<T extends YumeiroEffectPass>() {
    for (final pass in passes) {
      if (pass is T) return pass;
    }
    return null;
  }

  bool get usesBackdrop => passes.any((p) => p.usesBackdrop);

  YumeiroEffectStack withPass(YumeiroEffectPass pass) {
    final next = <YumeiroEffectPass>[];
    var replaced = false;
    for (final existing in passes) {
      if (existing.runtimeType == pass.runtimeType && existing.id == pass.id) {
        next.add(pass);
        replaced = true;
      } else {
        next.add(existing);
      }
    }
    if (!replaced) next.add(pass);
    return YumeiroEffectStack.fromPasses(next);
  }

  YumeiroEffectStack withoutPass<T extends YumeiroEffectPass>({String? id}) =>
      YumeiroEffectStack.fromPasses(
        passes.where((p) => !(p is T && (id == null || p.id == id))),
      );

  @override
  bool operator ==(Object other) =>
      other is YumeiroEffectStack && listEquals(passes, other.passes);

  @override
  int get hashCode => Object.hashAll(passes);

  YumeiroEffectStack lerp(YumeiroEffectStack other, double t) {
    if (t <= 0) return this;
    if (t >= 1) return other;
    final result = <YumeiroEffectPass>[];
    final matchedOther = <int>{};

    for (final first in passes) {
      int matchIdx = -1;
      for (var i = 0; i < other.passes.length; i++) {
        if (matchedOther.contains(i)) continue;
        final candidate = other.passes[i];
        if (candidate.runtimeType == first.runtimeType &&
            candidate.id == first.id) {
          matchIdx = i;
          break;
        }
      }
      if (matchIdx >= 0) {
        matchedOther.add(matchIdx);
        final target = other.passes[matchIdx];
        // Preserve each pass's capability while transitioning between tiers.
        final lerped = first.minCapability == target.minCapability
            ? first.lerp(target, t)
            : switch (t) {
                < .5 => first.lerp(null, 2 * t),
                > .5 => target.lerp(null, 2 * (1 - t)),
                _ => null,
              };
        if (lerped != null) result.add(lerped);
      } else {
        final lerped = first.lerp(null, t);
        if (lerped != null) result.add(lerped);
      }
    }

    for (var i = 0; i < other.passes.length; i++) {
      if (matchedOther.contains(i)) continue;
      final lerped = other.passes[i].lerp(null, 1 - t);
      if (lerped != null) result.add(lerped);
    }

    return YumeiroEffectStack.fromPasses(result);
  }
}
