import 'package:material_ui/material_ui.dart';

/// Local, clipped artwork for showing live glass backdrop sampling.
/// Intended for bounded material examples, independently of the page theme.
class GalleryBackdrop extends StatelessWidget {
  const GalleryBackdrop({
    super.key,
    this.enabled = true,
    this.brightness,
    required this.child,
  });

  final bool enabled;

  /// Defaults to the host theme; fixed material samples can choose their own.
  final Brightness? brightness;
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: IgnorePointer(
          child: ClipRect(
            child: CustomPaint(
              painter: _GalleryBackdropPainter(
                enabled: enabled,
                dark:
                    (brightness ?? Theme.of(context).brightness) ==
                    Brightness.dark,
              ),
            ),
          ),
        ),
      ),
      child,
    ],
  );
}

class _GalleryBackdropPainter extends CustomPainter {
  const _GalleryBackdropPainter({required this.enabled, required this.dark});

  final bool enabled;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    if (!enabled || size.isEmpty) return;
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [Color(0xFF17243A), Color(0xFF30263E), Color(0xFF162E34)]
              : const [Color(0xFFF2EAE2), Color(0xFFE2EEF0), Color(0xFFE8E1EE)],
        ).createShader(rect),
    );
    final scale = size.shortestSide;
    final colors = dark
        ? const [Color(0x99643D8D), Color(0x99377F86), Color(0x9971534C)]
        : const [Color(0xB3A6CDE1), Color(0xB3DDAB98), Color(0xB3AEC6AE)];
    for (var i = 0; i < colors.length; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(
            size.width * [.18, .82, .46][i],
            size.height * [.22, .48, .83][i],
          ),
          width: scale * [.85, .7, 1.1][i],
          height: scale * [.62, 1.0, .6][i],
        ),
        Paint()..color = colors[i],
      );
    }
    final ribbon = Path()
      ..moveTo(-size.width * .1, size.height * .54)
      ..cubicTo(
        size.width * .3,
        size.height * .2,
        size.width * .45,
        size.height * .92,
        size.width * 1.1,
        size.height * .36,
      )
      ..lineTo(size.width * 1.1, size.height * .43)
      ..cubicTo(
        size.width * .45,
        size.height * .99,
        size.width * .3,
        size.height * .27,
        -size.width * .1,
        size.height * .61,
      )
      ..close();
    canvas.drawPath(
      ribbon,
      Paint()..color = Colors.white.withValues(alpha: dark ? .05 : .32),
    );
  }

  @override
  bool shouldRepaint(_GalleryBackdropPainter oldDelegate) =>
      oldDelegate.enabled != enabled || oldDelegate.dark != dark;
}
