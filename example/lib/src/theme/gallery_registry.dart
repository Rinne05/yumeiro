import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

/// Target UI modality profile for the example gallery.
enum GalleryProfile { desktop, mobile }

/// Custom semantic surface role demonstrating host-level role extension.
const gallerySampleSurfaceRole = YumeiroSurfaceRole(
  'gallery.sample',
  fallback: YumeiroSurfaceRole.card,
);

/// Custom semantic status role demonstrating host-level status extension.
const gallerySampleStatusRole = YumeiroStatusRole(
  'gallery.sample_status',
  fallback: YumeiroStatusRole.accent,
);

/// Custom [YumeiroEffectPass] rendering a subtle diagonal sheen stripe gated
/// by [minCapability].
@immutable
class GalleryPrismPass extends YumeiroEffectPass {
  const GalleryPrismPass({
    required this.color,
    this.opacity = 0.16,
    super.id = 'gallery-prism',
    super.minCapability = YumeiroMaterialCapability.blurOnly,
  });

  final Color color;
  final double opacity;

  @override
  void paintForeground(
    Canvas canvas,
    Size size,
    OutlinedBorder shape,
    YumeiroMaterialCapability capability, {
    TextDirection? textDirection,
  }) {
    if (opacity <= 0.001) return;
    final path = shape.getOuterPath(
      Offset.zero & size,
      textDirection: textDirection,
    );
    canvas.save();
    canvas.clipPath(path);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color.withValues(alpha: opacity),
          color.withValues(alpha: 0),
          color.withValues(alpha: opacity * 0.65),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint);
    canvas.restore();
  }

  @override
  YumeiroEffectPass? lerp(YumeiroEffectPass? other, double t) {
    if (other is! GalleryPrismPass) {
      final faded = opacity * (1 - t);
      return faded <= 0.001
          ? null
          : GalleryPrismPass(
              color: color,
              opacity: faded,
              id: id,
              minCapability: minCapability,
            );
    }
    return GalleryPrismPass(
      color: Color.lerp(color, other.color, t)!,
      opacity: opacity + (other.opacity - opacity) * t,
      id: id,
      minCapability: minCapability,
    );
  }
}

/// Builds a [YumeiroThemeRegistry] populated with all 13 built-in theme
/// families (24 presets) plus a host-registered custom preset (`gallery.nordic_amber`).
YumeiroThemeRegistry createGalleryRegistry() {
  final registry = YumeiroThemeRegistry.standard();
  final customPreset = YumeiroThemePreset(
    id: 'gallery.nordic_amber',
    label: 'Nordic Amber (Custom)',
    brightness: Brightness.dark,
    icon: Icons.auto_awesome_rounded,
    colors: YumeiroColorTokens.dark.copyWith(
      background: const Color(0xFF14181E),
      sidebar: const Color(0xFF101419),
      surface: const Color(0xFF1D232B),
      surfaceSecondary: const Color(0xFF181D24),
      surfaceElevated: const Color(0xFF252D38),
      surfaceHover: const Color(0xFF2E3845),
      accent: const Color(0xFFF59E0B),
      accentSoft: const Color(0xFFFCD34D),
      onAccent: const Color(0xFF1A1204),
    ),
    materialSchemeBuilder:
        YumeiroThemePresets.classicDark.materialSchemeBuilder,
    visualsBuilder: YumeiroThemePresets.classicDark.visualsBuilder,
    categoricalPaletteBuilder:
        YumeiroThemePresets.classicDark.categoricalPaletteBuilder,
    accentCustomizer: (colors, accent) =>
        colors.withAccent(accent, lighten: true),
    customizationOptions: YumeiroThemePresets.classicDark.customizationOptions,
  );

  registry.registerPreset(
    customPreset,
    familyId: 'nordic-amber',
    familyLabel: 'Nordic Amber',
  );
  return registry;
}

/// Extends resolved theme visuals with custom host surface and status roles.
YumeiroSemanticVisualTheme augmentGalleryVisuals(
  YumeiroSemanticVisualTheme base,
  YumeiroColorTokens colors,
  YumeiroRadiiTokens radii,
) {
  final cardBase = base.surface(YumeiroSurfaceRole.card);
  return base.extend(
    surfaces: {
      gallerySampleSurfaceRole: YumeiroVisualRecipe(
        base: cardBase.copyWith(
          effects: cardBase.effects.withPass(
            GalleryPrismPass(
              color: colors.accent,
              minCapability: YumeiroMaterialCapability.blurOnly,
            ),
          ),
        ),
      ),
    },
    statuses: {
      gallerySampleStatusRole: YumeiroStatusVisual(
        foreground: colors.accentSoft,
        subtleFill: colors.accent.withValues(alpha: 0.16),
        tint: colors.accent,
      ),
    },
  );
}
