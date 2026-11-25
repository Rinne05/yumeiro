import 'dart:ui';

Color yumeiroSrgb(Color color) => switch (color.colorSpace) {
  ColorSpace.sRGB => color,
  ColorSpace.extendedSRGB => color.withValues(colorSpace: ColorSpace.sRGB),
  // Flutter 3.50.1's direct conversion clips without applying the gamut
  // transform. Convert through extended sRGB before clipping.
  ColorSpace.displayP3 =>
    color
        .withValues(colorSpace: ColorSpace.extendedSRGB)
        .withValues(colorSpace: ColorSpace.sRGB),
};

/// Composites colors in a shared gamut. Flutter requires both inputs to use
/// the same non-extended color space.
Color yumeiroAlphaBlend(Color foreground, Color background) {
  final foregroundSpace = foreground.colorSpace;
  final backgroundSpace = background.colorSpace;
  if (foregroundSpace == backgroundSpace &&
      foregroundSpace != ColorSpace.extendedSRGB) {
    return Color.alphaBlend(foreground, background);
  }
  final shared =
      foregroundSpace == ColorSpace.displayP3 ||
          backgroundSpace == ColorSpace.displayP3
      ? ColorSpace.displayP3
      : ColorSpace.sRGB;
  return Color.alphaBlend(
    foreground.withValues(colorSpace: shared),
    background.withValues(colorSpace: shared),
  );
}

/// Evaluates relative luminance using the sRGB coefficients Flutter applies.
double yumeiroRelativeLuminance(Color color) =>
    yumeiroSrgb(color).computeLuminance();
