import 'dart:math' as math;

import 'package:flutter/painting.dart';

import 'pixel_border.dart';

/// Uses the slider thumb's contour for small marks and adds finer steps to
/// larger circles, so the corners stay round at media and avatar sizes.
OutlinedBorder pixelCircleBorder(double diameter) => diameter <= 18
    ? YumeiroPixelBorder(step: diameter / 7)
    : const _PixelCircleBorder();

class _PixelCircleBorder extends OutlinedBorder {
  const _PixelCircleBorder({super.side});

  @override
  _PixelCircleBorder copyWith({BorderSide? side}) =>
      _PixelCircleBorder(side: side ?? this.side);

  @override
  _PixelCircleBorder scale(double t) => copyWith(side: side.scale(t));

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) => a is _PixelCircleBorder
      ? copyWith(side: BorderSide.lerp(a.side, side, t))
      : super.lerpFrom(a, t);

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) => b is _PixelCircleBorder
      ? copyWith(side: BorderSide.lerp(side, b.side, t))
      : super.lerpTo(b, t);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    if (rect.isEmpty) return Path();
    final radius = rect.shortestSide / 2;
    final top = rect.center.dy - radius;
    final rows = radius.ceil();
    final cell = 2 * radius / rows;

    // Keep each cell whose center falls within the circle. Trace the left
    // and right edges as a single path to avoid seams inside the fill.
    final halfWidths = List<double>.generate(rows, (row) {
      final dy = (row + .5) * cell - radius;
      final dx = math.sqrt(radius * radius - dy * dy);
      final excluded = math.max(0, ((radius - dx) / cell - .5).ceil());
      return radius - excluded * cell;
    });
    final x = rect.center.dx;
    final path = Path()..moveTo(x - halfWidths.first, top);
    for (var row = 0; row < rows; row++) {
      path
        ..lineTo(x - halfWidths[row], top + row * cell)
        ..lineTo(x - halfWidths[row], top + (row + 1) * cell);
    }
    for (var row = rows - 1; row >= 0; row--) {
      path
        ..lineTo(x + halfWidths[row], top + (row + 1) * cell)
        ..lineTo(x + halfWidths[row], top + row * cell);
    }
    return path..close();
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect.deflate(side.strokeInset));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (rect.isEmpty || side.style == BorderStyle.none) return;
    final paint = Paint()
      ..color = side.color
      ..isAntiAlias = false;
    final outline = getOuterPath(rect.inflate(side.strokeOutset));
    if (side.width == 0) {
      paint.style = PaintingStyle.stroke;
    } else {
      outline
        ..addPath(getInnerPath(rect), Offset.zero)
        ..fillType = PathFillType.evenOdd;
    }
    canvas.drawPath(outline, paint);
  }

  @override
  bool operator ==(Object other) =>
      other is _PixelCircleBorder && other.side == side;

  @override
  int get hashCode => Object.hash(runtimeType, side);
}
