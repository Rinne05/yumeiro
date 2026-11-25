import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// An orthogonal, two-step corner border for retro pixel interfaces.
///
/// [step] is the logical-pixel size of each corner step. It is clamped to fit
/// the available bounds, so the same border also works on small indicators.
/// Hosts can reuse this shape independently of the built-in pixel preset.
class YumeiroPixelBorder extends OutlinedBorder {
  const YumeiroPixelBorder({super.side, this.step = 3})
    : assert(step >= 0 && step < double.infinity);

  final double step;

  @override
  YumeiroPixelBorder copyWith({BorderSide? side, double? step}) =>
      YumeiroPixelBorder(side: side ?? this.side, step: step ?? this.step);

  @override
  YumeiroPixelBorder scale(double t) =>
      YumeiroPixelBorder(side: side.scale(t), step: math.max(0, step * t));

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is YumeiroPixelBorder) {
      return YumeiroPixelBorder(
        side: BorderSide.lerp(a.side, side, t),
        step: math.max(0, a.step + (step - a.step) * t),
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is YumeiroPixelBorder) {
      return YumeiroPixelBorder(
        side: BorderSide.lerp(side, b.side, t),
        step: math.max(0, step + (b.step - step) * t),
      );
    }
    return super.lerpTo(b, t);
  }

  Path _path(Rect rect, double cornerStep) {
    if (rect.isEmpty) return Path();
    final s = cornerStep.clamp(0.0, rect.shortestSide / 4);
    if (s == 0) return Path()..addRect(rect);
    final Rect(:left, :top, :right, :bottom) = rect;
    return Path()
      ..moveTo(left + 2 * s, top)
      ..lineTo(right - 2 * s, top)
      ..lineTo(right - 2 * s, top + s)
      ..lineTo(right - s, top + s)
      ..lineTo(right - s, top + 2 * s)
      ..lineTo(right, top + 2 * s)
      ..lineTo(right, bottom - 2 * s)
      ..lineTo(right - s, bottom - 2 * s)
      ..lineTo(right - s, bottom - s)
      ..lineTo(right - 2 * s, bottom - s)
      ..lineTo(right - 2 * s, bottom)
      ..lineTo(left + 2 * s, bottom)
      ..lineTo(left + 2 * s, bottom - s)
      ..lineTo(left + s, bottom - s)
      ..lineTo(left + s, bottom - 2 * s)
      ..lineTo(left, bottom - 2 * s)
      ..lineTo(left, top + 2 * s)
      ..lineTo(left + s, top + 2 * s)
      ..lineTo(left + s, top + s)
      ..lineTo(left + 2 * s, top + s)
      ..close();
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      _path(rect, step);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => _path(
    rect.deflate(side.strokeInset),
    math.max(0, step - side.strokeInset / 2),
  );

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (rect.isEmpty || side.style == BorderStyle.none) return;
    final paint = Paint()
      ..color = side.color
      ..isAntiAlias = false;
    if (side.width == 0) {
      paint.style = PaintingStyle.stroke;
      canvas.drawPath(_path(rect, step), paint);
      return;
    }
    final ring =
        _path(rect.inflate(side.strokeOutset), step + side.strokeOutset / 2)
          ..fillType = PathFillType.evenOdd
          ..addPath(getInnerPath(rect), Offset.zero);
    canvas.drawPath(ring, paint);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is YumeiroPixelBorder && other.side == side && other.step == step;

  @override
  int get hashCode => Object.hash(side, step);

  @override
  String toString() => 'YumeiroPixelBorder($side, step: $step)';
}
