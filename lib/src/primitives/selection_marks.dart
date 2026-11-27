import 'package:flutter/rendering.dart';

import '../foundation/color_math.dart';

/// Picks the contrasting ink for a mark painted over a resolved fill.
Color unavailableMarkInk(Color background) =>
    yumeiroRelativeLuminance(background) > .179
    ? const Color(0xFF000000)
    : const Color(0xFFFFFFFF);

/// Draws the unavailable mark within an existing selection or toggle shape.
void paintUnavailableSlash(
  Canvas canvas,
  Offset center, {
  required double extent,
  required Color color,
  required bool pixel,
}) {
  final paint = Paint()
    ..color = color
    ..isAntiAlias = !pixel;
  if (pixel) {
    final unit = extent / 18;
    final steps = Path();
    for (var i = 0; i < 6; i++) {
      steps.addRect(
        Rect.fromCenter(
          center: center + Offset(i - 2.5, 2.5 - i) * unit,
          width: unit * 2,
          height: unit * 2,
        ),
      );
    }
    canvas.drawPath(steps, paint);
  } else {
    final diagonal = Offset(extent / 5, -extent / 5);
    canvas.drawLine(
      center - diagonal,
      center + diagonal,
      paint
        ..strokeWidth = extent / 11
        ..strokeCap = StrokeCap.round,
    );
  }
}

/// Paints over a control's native mark or thumb without changing its layout.
class UnavailableSlashPainter extends CustomPainter {
  const UnavailableSlashPainter({
    required this.color,
    required this.pixel,
    this.extent,
  });

  final Color color;
  final bool pixel;
  final double? extent;

  @override
  void paint(Canvas canvas, Size size) {
    final markSize = (extent ?? size.shortestSide).clamp(
      0.0,
      size.shortestSide,
    );
    paintUnavailableSlash(
      canvas,
      size.center(Offset.zero),
      extent: markSize,
      color: color,
      pixel: pixel,
    );
  }

  @override
  bool shouldRepaint(UnavailableSlashPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.pixel != pixel ||
      oldDelegate.extent != extent;
}
