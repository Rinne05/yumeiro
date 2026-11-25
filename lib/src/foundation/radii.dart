import 'package:flutter/foundation.dart';

/// Preset corner radius scale in logical pixels for component families.
@immutable
class YumeiroRadiiTokens {
  const YumeiroRadiiTokens({
    this.chip = 8,
    this.button = 10,
    this.md = 14,
    this.lg = 18,
    this.checkbox = 4,
    this.poster = 14,
  });

  final double chip;
  final double button;
  final double md;
  final double lg;
  final double checkbox;
  final double poster;

  /// Multiplies every corner radius by [factor].
  YumeiroRadiiTokens scaled(double factor) => YumeiroRadiiTokens(
    chip: chip * factor,
    button: button * factor,
    md: md * factor,
    lg: lg * factor,
    checkbox: checkbox * factor,
    poster: poster * factor,
  );

  YumeiroRadiiTokens copyWith({
    double? chip,
    double? button,
    double? md,
    double? lg,
    double? checkbox,
    double? poster,
  }) => YumeiroRadiiTokens(
    chip: chip ?? this.chip,
    button: button ?? this.button,
    md: md ?? this.md,
    lg: lg ?? this.lg,
    checkbox: checkbox ?? this.checkbox,
    poster: poster ?? this.poster,
  );

  YumeiroRadiiTokens lerp(YumeiroRadiiTokens other, double t) =>
      YumeiroRadiiTokens(
        chip: _lerp(chip, other.chip, t),
        button: _lerp(button, other.button, t),
        md: _lerp(md, other.md, t),
        lg: _lerp(lg, other.lg, t),
        checkbox: _lerp(checkbox, other.checkbox, t),
        poster: _lerp(poster, other.poster, t),
      );

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}
