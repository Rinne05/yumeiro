import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../foundation/color_math.dart';
import 'effect_pass.dart';
import 'semantic_visuals.dart';

/// Material recipes independent of a theme's typography, shape, and colors.
///
/// Use [YumeiroVisualMaterial.appearance] to bind a material to a semantic role,
/// or reuse its fill, outline, and effect stack in a local visual override.
/// Strength parameters use `1` for their normal appearance and `0` to remove
/// the corresponding effect. Non-finite parameters fall back to their defaults.
/// An optional brightness selects the light response without replacing supplied
/// colors. When omitted, very dark base colors receive restrained dark lighting.
abstract final class YumeiroMaterials {
  /// Opaque glazed porcelain with a broad, soft reflection and a lit rim.
  static YumeiroVisualMaterial ceramic({
    Color color = const Color(0xFFF3EEE6),
    Brightness? brightness,
    double highlight = 1,
    double shadow = 1,
  }) {
    final base = color.withValues(alpha: 1);
    final light = _level(highlight);
    final depth = _level(shadow);
    final dark = _usesDarkLighting(brightness, base);
    final reflection = dark ? .22 : _reflectionScale(base);
    return YumeiroVisualMaterial(
      fill: YumeiroGradientFill(
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: List<Color>.unmodifiable([
            _lighter(base, .14 * reflection),
            base,
            _darker(base, .055),
          ]),
          stops: const [0, .6, 1],
        ),
        fallbackColor: base,
      ),
      outline: BorderSide(
        color: _lighter(base, dark ? .16 + .04 * light : .55),
        width: 1,
      ),
      effects: YumeiroEffectStack(
        outerShadows: [
          if (depth > 0)
            BoxShadow(
              color: (dark ? Colors.black : const Color(0xFF655447)).withValues(
                alpha: (dark ? .45 : .17) * depth,
              ),
              blurRadius: 9,
              offset: const Offset(0, 3),
            ),
        ],
        innerShadows: [
          if (light > 0)
            YumeiroInnerShadow(
              color: Colors.white.withValues(alpha: (dark ? .12 : .28) * light),
              blurRadius: 2,
              offset: const Offset(0, 2),
              isHighlight: true,
            ),
          if (depth > 0)
            YumeiroInnerShadow(
              color: (dark ? Colors.black : const Color(0xFF665245)).withValues(
                alpha: (dark ? .25 : .08) * depth,
              ),
              blurRadius: 3,
              offset: const Offset(0, -2),
            ),
        ],
        extraPasses: [
          YumeiroSheenPass(
            id: 'ceramic-glaze',
            opacity: light / 2 * reflection,
            gradient: const RadialGradient(
              center: Alignment(-.65, -.95),
              radius: 1.3,
              colors: [Color(0xAAFFFFFF), Color(0x18FFFFFF), Color(0x00FFFFFF)],
              stops: [0, .4, 1],
            ),
          ),
        ],
      ),
    );
  }

  /// Opaque machined metal with deterministic horizontal grain and soft bands.
  static YumeiroVisualMaterial brushedMetal({
    Color color = const Color(0xFFD3D5D6),
    Brightness? brightness,
    double texture = 1,
    double highlight = 1,
    double shadow = 1,
  }) {
    final base = color.withValues(alpha: 1);
    final grain = _level(texture);
    final light = _level(highlight);
    final depth = _level(shadow);
    final dark = _usesDarkLighting(brightness, base);
    final reflection = dark ? .3 : _reflectionScale(base);
    return YumeiroVisualMaterial(
      fill: YumeiroGradientFill(
        LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: List<Color>.unmodifiable([
            _lighter(base, .2 * reflection),
            _darker(base, .055),
            _lighter(base, .19 * reflection),
            base,
            _darker(base, .12),
          ]),
          stops: const [0, .25, .49, .7, 1],
        ),
        fallbackColor: base,
      ),
      outline: BorderSide(
        color: dark ? _lighter(base, .18) : _darker(base, .28),
        width: 1,
      ),
      effects: YumeiroEffectStack(
        outerShadows: [
          if (depth > 0)
            BoxShadow(
              color: Colors.black.withValues(alpha: (dark ? .42 : .15) * depth),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
        ],
        innerShadows: [
          if (light > 0)
            YumeiroInnerShadow(
              color: Colors.white.withValues(alpha: (dark ? .16 : .38) * light),
              blurRadius: 1,
              offset: const Offset(0, 1.5),
              isHighlight: true,
            ),
          if (depth > 0)
            YumeiroInnerShadow(
              color: Colors.black.withValues(alpha: (dark ? .3 : .13) * depth),
              blurRadius: 1.5,
              offset: const Offset(0, -1.5),
            ),
        ],
        extraPasses: [
          YumeiroBrushedTexturePass(
            opacity: .17 * grain * (dark ? .5 : reflection),
          ),
          YumeiroSheenPass(
            id: 'metal-reflection',
            opacity: light / 2 * reflection,
            gradient: const LinearGradient(
              begin: Alignment(-1, -.3),
              end: Alignment(1, .3),
              colors: [
                Color(0x00FFFFFF),
                Color(0x00FFFFFF),
                Color(0x77FFFFFF),
                Color(0x00FFFFFF),
                Color(0x00FFFFFF),
              ],
              stops: [0, .25, .46, .7, 1],
            ),
          ),
        ],
      ),
    );
  }

  /// Diffusing translucent acrylic. Supply artwork behind the surface to
  /// reveal its material; the tint is painted once, independently of blur.
  static YumeiroVisualMaterial acrylic({
    Color tint = const Color(0x66E8F5F6),
    Brightness? brightness,
    double blur = 24,
    double highlight = 1,
    double shadow = 1,
  }) {
    final light = _level(highlight);
    final depth = _level(shadow);
    final dark = _usesDarkLighting(brightness, tint.withValues(alpha: 1));
    return YumeiroVisualMaterial(
      fill: YumeiroSolidFill(tint),
      outline: BorderSide(
        color: Colors.white.withValues(
          alpha: ((dark ? .1 : .32) + (dark ? .12 : .41) * light).clamp(0, 1),
        ),
        width: 1,
      ),
      effects: YumeiroEffectStack(
        backdropBlur: _bounded(blur, fallback: 24, max: 80),
        outerShadows: [
          if (depth > 0)
            BoxShadow(
              color: (dark ? Colors.black : const Color(0xFF254953)).withValues(
                alpha: (dark ? .42 : .12) * depth,
              ),
              blurRadius: 18,
              offset: const Offset(0, 5),
            ),
        ],
        innerShadows: [
          if (light > 0)
            YumeiroInnerShadow(
              color: Colors.white.withValues(alpha: (dark ? .09 : .33) * light),
              blurRadius: 1,
              offset: const Offset(0, 1),
              isHighlight: true,
            ),
        ],
      ),
    );
  }

  /// Opaque powder-matte silicone, optionally recessed for a pressed control.
  static YumeiroVisualMaterial silicone({
    Color color = const Color(0xFFE4D8EE),
    Brightness? brightness,
    bool pressed = false,
    double highlight = 1,
    double shadow = 1,
  }) {
    final base = color.withValues(alpha: 1);
    final light = _level(highlight);
    final depth = _level(shadow);
    final dark = _usesDarkLighting(brightness, base);
    return YumeiroVisualMaterial(
      fill: YumeiroGradientFill(
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: List<Color>.unmodifiable([
            pressed ? _darker(base, .035) : _lighter(base, .04 * light),
            base,
          ]),
        ),
        fallbackColor: base,
      ),
      outline: BorderSide(color: _lighter(base, .07), width: .5),
      effects: YumeiroEffectStack(
        outerShadows: [
          if (!pressed && depth > 0)
            BoxShadow(
              color: (dark ? Colors.black : const Color(0xFF5A4567)).withValues(
                alpha: (dark ? .46 : .15) * depth,
              ),
              blurRadius: 12,
              offset: const Offset(3, 5),
            ),
          if (!pressed && light > 0)
            YumeiroOuterHighlight(
              color: Colors.white.withValues(alpha: (dark ? .06 : .31) * light),
              blurRadius: 10,
              offset: const Offset(-3, -3),
            ),
        ],
        innerShadows: [
          if (pressed && depth > 0)
            YumeiroInnerShadow(
              color: (dark ? Colors.black : const Color(0xFF5A4567)).withValues(
                alpha: (dark ? .46 : .16) * depth,
              ),
              blurRadius: 7,
              offset: const Offset(3, 3),
            ),
          if (light > 0)
            YumeiroInnerShadow(
              color: Colors.white.withValues(
                alpha: (dark ? .065 : .19) * light,
              ),
              blurRadius: pressed ? 5 : 4,
              offset: pressed ? const Offset(-2, -2) : const Offset(0, 2),
              isHighlight: true,
            ),
        ],
      ),
    );
  }

  /// Thick frosted glass combining backdrop diffusion, optical edges, and
  /// broad static reflections painted below content.
  ///
  /// The renderer falls back to Gaussian blur when optical filters are not
  /// supported. The fill supplies the same tint in either capability tier.
  /// The decorative gradients simulate reflections; they do not introduce
  /// spatially varying interior refraction or physically simulated caustics.
  static YumeiroVisualMaterial frostedGlass({
    Color tint = const Color(0x44CEE4EB),
    Brightness? brightness,
    double blur = 26,
    double refraction = 10,
    double thickness = 18,
    double highlight = 1,
    double shadow = 1,
  }) {
    final light = _level(highlight);
    final depth = _level(shadow);
    final dark = _usesDarkLighting(brightness, tint.withValues(alpha: 1));
    final reflection = dark ? .24 : _reflectionScale(tint.withValues(alpha: 1));
    return YumeiroVisualMaterial(
      fill: YumeiroSolidFill(tint),
      outline: BorderSide(
        color: Colors.white.withValues(
          alpha: (dark ? .1 : .38) + (dark ? .1 : .2) * light,
        ),
        width: 1.2,
      ),
      effects: YumeiroEffectStack(
        backdropBlur: _bounded(blur, fallback: 26, max: 80),
        backdropTint: Colors.transparent,
        glass: YumeiroGlassEffect(
          tint: tint,
          refraction: _bounded(refraction, fallback: 10, max: 48),
          thickness: _bounded(thickness, fallback: 18, max: 64),
          lighting: light * (dark ? .65 : 1),
        ),
        outerShadows: [
          if (depth > 0)
            BoxShadow(
              color: (dark ? Colors.black : const Color(0xFF274454)).withValues(
                alpha: (dark ? .44 : .17) * depth,
              ),
              blurRadius: 22,
              offset: const Offset(0, 6),
            ),
        ],
        innerShadows: [
          if (light > 0)
            YumeiroInnerShadow(
              color: Colors.white.withValues(alpha: (dark ? .1 : .25) * light),
              blurRadius: 2,
              offset: const Offset(0, 2),
              isHighlight: true,
            ),
          if (depth > 0)
            YumeiroInnerShadow(
              color: (dark ? Colors.black : const Color(0xFF274454)).withValues(
                alpha: (dark ? .22 : .07) * depth,
              ),
              blurRadius: 3,
              offset: const Offset(0, -2),
            ),
        ],
        extraPasses: [
          YumeiroSheenPass(
            id: 'frosted-reflection',
            opacity: light / 2 * reflection,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0x05FFFFFF),
                Color(0x88FFFFFF),
                Color(0x0AFFFFFF),
                Color(0x00FFFFFF),
                Color(0x66FFFFFF),
                Color(0x00FFFFFF),
              ],
              stops: [0, .24, .42, .53, .76, 1],
            ),
          ),
          YumeiroSheenPass(
            id: 'frosted-soft-glint',
            opacity: light / 2 * reflection,
            gradient: const RadialGradient(
              center: Alignment(-.6, .1),
              radius: .9,
              colors: [Color(0x66FFFFFF), Color(0x14FFFFFF), Color(0x00FFFFFF)],
              stops: [0, .4, 1],
            ),
          ),
        ],
      ),
    );
  }

  static double _level(double value) => _bounded(value, fallback: 1, max: 2);

  static bool _usesDarkLighting(Brightness? brightness, Color base) =>
      brightness == Brightness.dark ||
      (brightness == null && yumeiroRelativeLuminance(base) < .08);

  // Restrained white reflections leave room for light labels on dark accent
  // controls. A smooth ramp avoids sudden sheen changes as hosts tune a color.
  static double _reflectionScale(Color color) {
    final ramp = ((yumeiroRelativeLuminance(color) - .2) / .5).clamp(0.0, 1.0);
    return .14 + .86 * ramp * ramp * (3 - 2 * ramp);
  }

  static double _bounded(
    double value, {
    required double fallback,
    required double max,
  }) => value.isFinite ? value.clamp(0, max).toDouble() : fallback;

  static Color _lighter(Color color, double amount) =>
      Color.lerp(color, Colors.white, amount)!;

  static Color _darker(Color color, double amount) =>
      Color.lerp(color, Colors.black, amount)!;
}

/// A reusable gradient reflection clipped to the material's shape.
///
/// Decorations run below text and icons through [paintMaterial]. Distinct [id]s
/// allow several reflections to coexist in one [YumeiroEffectStack].
@immutable
class YumeiroSheenPass extends YumeiroEffectPass {
  const YumeiroSheenPass({
    this.gradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0x66FFFFFF), Color(0x00FFFFFF)],
    ),
    this.opacity = 1,
    super.id = 'sheen',
    super.minCapability = YumeiroMaterialCapability.blurOnly,
  }) : assert(opacity >= 0 && opacity <= 1);

  final Gradient gradient;
  final double opacity;

  @override
  void paintMaterial(
    Canvas canvas,
    Size size,
    OutlinedBorder shape,
    YumeiroMaterialCapability capability, {
    TextDirection? textDirection,
  }) {
    if (opacity <= .001 || size.isEmpty) return;
    canvas.drawPath(
      shape.getOuterPath(Offset.zero & size, textDirection: textDirection),
      Paint()
        ..shader = gradient
            .scale(opacity)
            .createShader(Offset.zero & size, textDirection: textDirection),
    );
  }

  @override
  YumeiroEffectPass? lerp(YumeiroEffectPass? other, double t) {
    if (other != null && other is! YumeiroSheenPass) {
      return t < .5 ? this : other;
    }
    final target = other as YumeiroSheenPass?;
    final nextOpacity = (opacity + ((target?.opacity ?? 0) - opacity) * t)
        .clamp(0.0, 1.0)
        .toDouble();
    if (nextOpacity <= .001) return null;
    return YumeiroSheenPass(
      gradient: target == null
          ? gradient
          : Gradient.lerp(gradient, target.gradient, t)!,
      opacity: nextOpacity,
      id: id,
      minCapability: minCapability,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is YumeiroSheenPass &&
      id == other.id &&
      minCapability == other.minCapability &&
      gradient == other.gradient &&
      opacity == other.opacity;

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, minCapability, gradient, opacity);
}

/// Deterministic brushed-metal grain painted below content.
///
/// Grain positions do not depend on animation time or randomness. Painting is
/// bounded to 384 rows, including on very tall surfaces, to keep scrolling and
/// hover transitions predictable. [spacing] is measured in logical pixels.
@immutable
class YumeiroBrushedTexturePass extends YumeiroEffectPass {
  const YumeiroBrushedTexturePass({
    this.opacity = .17,
    this.spacing = 1.5,
    this.light = Colors.white,
    this.dark = Colors.black,
    super.id = 'brushed-texture',
    super.minCapability = YumeiroMaterialCapability.blurOnly,
  }) : assert(opacity >= 0 && opacity <= 1),
       assert(spacing >= .5 && spacing <= 12);

  final double opacity;
  final double spacing;
  final Color light;
  final Color dark;

  @override
  void paintMaterial(
    Canvas canvas,
    Size size,
    OutlinedBorder shape,
    YumeiroMaterialCapability capability, {
    TextDirection? textDirection,
  }) {
    if (opacity <= .001 || size.isEmpty) return;
    final rows = math.min(384, (size.height / spacing).ceil());
    if (rows == 0) return;
    final step = size.height / rows;
    final paint = Paint()
      ..strokeWidth = .5
      ..isAntiAlias = false;
    canvas.save();
    canvas.clipPath(
      shape.getOuterPath(Offset.zero & size, textDirection: textDirection),
    );
    for (var row = 0; row < rows; row++) {
      final variation = ((row * 73 + 19) % 127) / 126;
      final tint = row.isEven ? light : dark;
      paint.color = tint.withValues(
        alpha: tint.a * opacity * (.2 + variation * .8),
      );
      final y = (row + .5) * step;
      final inset = ((row * 37 + 11) % 29) / 29 * size.width * .18;
      canvas.drawLine(
        Offset(inset, y),
        Offset(size.width - inset / 2, y),
        paint,
      );
    }
    canvas.restore();
  }

  @override
  YumeiroEffectPass? lerp(YumeiroEffectPass? other, double t) {
    if (other != null && other is! YumeiroBrushedTexturePass) {
      return t < .5 ? this : other;
    }
    final target = other as YumeiroBrushedTexturePass?;
    final nextOpacity = (opacity + ((target?.opacity ?? 0) - opacity) * t)
        .clamp(0.0, 1.0)
        .toDouble();
    if (nextOpacity <= .001) return null;
    return YumeiroBrushedTexturePass(
      opacity: nextOpacity,
      spacing: spacing + ((target?.spacing ?? spacing) - spacing) * t,
      light: Color.lerp(light, target?.light ?? light, t)!,
      dark: Color.lerp(dark, target?.dark ?? dark, t)!,
      id: id,
      minCapability: minCapability,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is YumeiroBrushedTexturePass &&
      id == other.id &&
      minCapability == other.minCapability &&
      opacity == other.opacity &&
      spacing == other.spacing &&
      light == other.light &&
      dark == other.dark;

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    minCapability,
    opacity,
    spacing,
    light,
    dark,
  );
}
