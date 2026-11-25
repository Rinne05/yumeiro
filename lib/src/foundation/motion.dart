import 'package:flutter/foundation.dart';

/// Fast, normal, and slow animation durations provided by a preset.
@immutable
class YumeiroMotion {
  const YumeiroMotion({
    this.fast = const Duration(milliseconds: 160),
    this.normal = const Duration(milliseconds: 180),
    this.slow = const Duration(milliseconds: 250),
  });

  final Duration fast;
  final Duration normal;
  final Duration slow;

  YumeiroMotion copyWith({Duration? fast, Duration? normal, Duration? slow}) =>
      YumeiroMotion(
        fast: fast ?? this.fast,
        normal: normal ?? this.normal,
        slow: slow ?? this.slow,
      );

  YumeiroMotion lerp(YumeiroMotion other, double t) => YumeiroMotion(
    fast: _lerp(fast, other.fast, t),
    normal: _lerp(normal, other.normal, t),
    slow: _lerp(slow, other.slow, t),
  );

  static Duration _lerp(Duration a, Duration b, double t) => Duration(
    microseconds: (a.inMicroseconds + (b.inMicroseconds - a.inMicroseconds) * t)
        .round(),
  );
}
