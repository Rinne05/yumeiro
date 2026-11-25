import 'package:flutter/foundation.dart';

/// Preset spacing scale in logical pixels for gaps and content insets.
@immutable
class YumeiroSpacing {
  const YumeiroSpacing({
    this.xs = 4,
    this.sm = 8,
    this.md = 12,
    this.lg = 14,
    this.xl = 20,
    this.page = 28,
  });

  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double page;

  YumeiroSpacing copyWith({
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? page,
  }) => YumeiroSpacing(
    xs: xs ?? this.xs,
    sm: sm ?? this.sm,
    md: md ?? this.md,
    lg: lg ?? this.lg,
    xl: xl ?? this.xl,
    page: page ?? this.page,
  );

  YumeiroSpacing lerp(YumeiroSpacing other, double t) => YumeiroSpacing(
    xs: _lerp(xs, other.xs, t),
    sm: _lerp(sm, other.sm, t),
    md: _lerp(md, other.md, t),
    lg: _lerp(lg, other.lg, t),
    xl: _lerp(xl, other.xl, t),
    page: _lerp(page, other.page, t),
  );

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}
