import 'dart:ui' show ColorSpace;

import 'package:material_ui/material_ui.dart';

import 'color_math.dart';

/// Semantic color palette tokens for a Yumeiro theme preset.
@immutable
class YumeiroColorTokens {
  const YumeiroColorTokens({
    required this.background,
    required this.sidebar,
    required this.surface,
    this.panel,
    required this.surfaceSecondary,
    required this.surfaceElevated,
    required this.surfaceHover,
    required this.line,
    required this.lineStrong,
    required this.text,
    required this.muted,
    required this.subtle,
    required this.accent,
    required this.accentSoft,
    required this.info,
    required this.success,
    required this.warning,
    this.rating = const Color(0xFFFBBF24),
    required this.danger,
    required this.supporting,
    required this.neutral,
    required this.onAccent,
  });

  final Color background;
  final Color sidebar;
  final Color surface;

  /// Independent panel fill that is preserved by [withBackgroundTone].
  /// Presets that set this token expose a `panelColor` option.
  final Color? panel;

  final Color surfaceSecondary;
  final Color surfaceElevated;
  final Color surfaceHover;
  final Color line;
  final Color lineStrong;
  final Color text;
  final Color muted;
  final Color subtle;
  final Color accent;
  final Color accentSoft;
  final Color info;
  final Color success;
  final Color warning;
  final Color rating;
  final Color danger;
  final Color supporting;
  final Color neutral;
  final Color onAccent;

  /// Derives an accent-adapted palette, switching the usual foreground only
  /// when its contrast against the new accent falls below 2.5:1.
  ///
  /// Extended sRGB accents are clipped to sRGB for Flutter color animations.
  YumeiroColorTokens withAccent(Color accent, {required bool lighten}) {
    final accentSrgb = yumeiroSrgb(accent);
    final hsl = HSLColor.fromColor(accentSrgb);
    final softLightness = (hsl.lightness + (lighten ? .20 : -.14))
        .clamp(0.0, 1.0)
        .toDouble();
    final preferred = accentSrgb.computeLuminance() > .5
        ? Colors.black
        : Colors.white;
    final luminance = Color.alphaBlend(
      accentSrgb,
      yumeiroSrgb(surface),
    ).computeLuminance();
    final blackContrast = (luminance + .05) / .05;
    final whiteContrast = 1.05 / (luminance + .05);
    final preferredContrast = preferred == Colors.black
        ? blackContrast
        : whiteContrast;

    return copyWith(
      accent: accent.colorSpace == ColorSpace.extendedSRGB
          ? accentSrgb
          : accent,
      accentSoft: hsl.withLightness(softLightness).toColor(),
      onAccent: preferredContrast >= 2.5
          ? preferred
          : (blackContrast > whiteContrast ? Colors.black : Colors.white),
    );
  }

  /// Shifts base surfaces toward [tone]'s hue and saturation while preserving
  /// their HSL lightness and any independent [panel] fill.
  YumeiroColorTokens withBackgroundTone(Color tone) {
    final target = HSLColor.fromColor(tone);
    Color shift(Color source) {
      final hsl = HSLColor.fromColor(source);
      return hsl
          .withHue(target.hue)
          .withSaturation(
            (target.saturation * 0.45 + hsl.saturation * 0.55).clamp(0.0, 1.0),
          )
          .toColor();
    }

    return copyWith(
      background: shift(background),
      sidebar: shift(sidebar),
      surface: shift(surface),
      surfaceSecondary: shift(surfaceSecondary),
      surfaceElevated: shift(surfaceElevated),
      surfaceHover: shift(surfaceHover),
    );
  }

  static const dark = YumeiroColorTokens(
    background: Color(0xFF0D0E11),
    sidebar: Color(0xFF101115),
    surface: Color(0xFF17181D),
    surfaceSecondary: Color(0xFF1E2026),
    surfaceElevated: Color(0xFF262830),
    surfaceHover: Color(0xFF2E313A),
    line: Color(0x12FFFFFF),
    lineStrong: Color(0x22FFFFFF),
    text: Color(0xFFF3F4F6),
    muted: Color(0xFFBCC2CC),
    subtle: Color(0xFFA3AAB5),
    accent: Color(0xFF19857B),
    accentSoft: Color(0xFF6DE8DF),
    info: Color(0xFF06B6D4),
    success: Color(0xFF10B981),
    warning: Color(0xFFF59E0B),
    rating: Color(0xFFFBBF24),
    danger: Color(0xFFD64C5D),
    supporting: Color(0xFF8B5CF6),
    neutral: Color(0xFF6B7280),
    onAccent: Color(0xFFF3F4F6),
  );

  static const light = YumeiroColorTokens(
    background: Color(0xFFF8FAFC),
    sidebar: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surfaceSecondary: Color(0xFFF1F5F9),
    surfaceElevated: Color(0xFFFFFFFF),
    surfaceHover: Color(0xFFE2E8F0),
    line: Color(0x0F0F172A),
    lineStrong: Color(0x1F0F172A),
    text: Color(0xFF0F172A),
    muted: Color(0xFF374151),
    subtle: Color(0xFF3D4652),
    accent: Color(0xFF238F86),
    accentSoft: Color(0xFF115E59),
    info: Color(0xFF0E7490),
    success: Color(0xFF047857),
    warning: Color(0xFFB45309),
    rating: Color(0xFF92400E),
    danger: Color(0xFFEF4444),
    supporting: Color(0xFF6D28D9),
    neutral: Color(0xFF4B5563),
    onAccent: Color(0xFF0F172A),
  );

  YumeiroColorTokens copyWith({
    Color? background,
    Color? sidebar,
    Color? surface,
    Color? panel,
    Color? surfaceSecondary,
    Color? surfaceElevated,
    Color? surfaceHover,
    Color? line,
    Color? lineStrong,
    Color? text,
    Color? muted,
    Color? subtle,
    Color? accent,
    Color? accentSoft,
    Color? info,
    Color? success,
    Color? warning,
    Color? rating,
    Color? danger,
    Color? supporting,
    Color? neutral,
    Color? onAccent,
  }) => YumeiroColorTokens(
    background: background ?? this.background,
    sidebar: sidebar ?? this.sidebar,
    surface: surface ?? this.surface,
    panel: panel ?? this.panel,
    surfaceSecondary: surfaceSecondary ?? this.surfaceSecondary,
    surfaceElevated: surfaceElevated ?? this.surfaceElevated,
    surfaceHover: surfaceHover ?? this.surfaceHover,
    line: line ?? this.line,
    lineStrong: lineStrong ?? this.lineStrong,
    text: text ?? this.text,
    muted: muted ?? this.muted,
    subtle: subtle ?? this.subtle,
    accent: accent ?? this.accent,
    accentSoft: accentSoft ?? this.accentSoft,
    info: info ?? this.info,
    success: success ?? this.success,
    warning: warning ?? this.warning,
    rating: rating ?? this.rating,
    danger: danger ?? this.danger,
    supporting: supporting ?? this.supporting,
    neutral: neutral ?? this.neutral,
    onAccent: onAccent ?? this.onAccent,
  );

  YumeiroColorTokens lerp(YumeiroColorTokens other, double t) =>
      YumeiroColorTokens(
        background: Color.lerp(background, other.background, t)!,
        sidebar: Color.lerp(sidebar, other.sidebar, t)!,
        surface: Color.lerp(surface, other.surface, t)!,
        panel: panel == null && other.panel == null
            ? null
            : Color.lerp(panel ?? surface, other.panel ?? other.surface, t),
        surfaceSecondary: Color.lerp(
          surfaceSecondary,
          other.surfaceSecondary,
          t,
        )!,
        surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
        surfaceHover: Color.lerp(surfaceHover, other.surfaceHover, t)!,
        line: Color.lerp(line, other.line, t)!,
        lineStrong: Color.lerp(lineStrong, other.lineStrong, t)!,
        text: Color.lerp(text, other.text, t)!,
        muted: Color.lerp(muted, other.muted, t)!,
        subtle: Color.lerp(subtle, other.subtle, t)!,
        accent: Color.lerp(accent, other.accent, t)!,
        accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
        info: Color.lerp(info, other.info, t)!,
        success: Color.lerp(success, other.success, t)!,
        warning: Color.lerp(warning, other.warning, t)!,
        rating: Color.lerp(rating, other.rating, t)!,
        danger: Color.lerp(danger, other.danger, t)!,
        supporting: Color.lerp(supporting, other.supporting, t)!,
        neutral: Color.lerp(neutral, other.neutral, t)!,
        onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      );
}
