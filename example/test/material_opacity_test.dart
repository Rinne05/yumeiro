import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yumeiro/yumeiro.dart';

const _sceneWidth = 160.0;
const _pixelRatio = 1.25;

class _Stripes extends CustomPainter {
  const _Stripes();

  @override
  void paint(Canvas canvas, Size size) {
    for (var x = 0.0; x < size.width; x += 4) {
      canvas.drawRect(
        Rect.fromLTWH(x, 0, 4, size.height),
        Paint()..color = x % 8 == 0 ? Colors.white : Colors.black,
      );
    }
  }

  @override
  bool shouldRepaint(_Stripes oldDelegate) => false;
}

Widget _scene({bool? optical, double opacity = 1, bool fallback = false}) =>
    YumeiroMaterialCapabilityScope(
      capability: fallback
          ? YumeiroMaterialCapability.blurOnly
          : YumeiroMaterialCapability.fullOptical,
      // Each scene paints its own backdrop after the app's shared group.
      child: YumeiroGlassSamplingScope(
        child: SizedBox(
          width: _sceneWidth,
          height: 120,
          child: CustomPaint(
            painter: const _Stripes(),
            child: optical == null
                ? const SizedBox.expand()
                : Center(
                    child: YumeiroResolvedVisualSurface(
                      width: 100,
                      height: 80,
                      appearance: YumeiroVisualAppearance(
                        fill: const YumeiroSolidFill(Colors.transparent),
                        foreground: Colors.black,
                        opacity: opacity,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                        ),
                        transition: const YumeiroVisualTransition(
                          duration: Duration(milliseconds: 160),
                          curve: Curves.linear,
                        ),
                        effects: YumeiroEffectStack(
                          backdropBlur: 12,
                          backdropTint: optical
                              ? const Color(0x806090C0)
                              : null,
                          glass: optical
                              ? const YumeiroGlassEffect(
                                  tint: Colors.transparent,
                                  refraction: 0,
                                  lighting: 0,
                                )
                              : null,
                        ),
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
          ),
        ),
      ),
    );

int _differences(ByteData pixels, int width, int scene) {
  var differences = 0;
  for (var y = 40; y < 110; y++) {
    for (var x = 55; x < 145; x++) {
      final reference = (y * width + x) * 4;
      final sample = (y * width + x + scene * 200) * 4;
      for (var channel = 0; channel < 4; channel++) {
        if ((pixels.getUint8(reference + channel) -
                    pixels.getUint8(sample + channel))
                .abs() >
            2) {
          differences++;
          break;
        }
      }
    }
  }
  return differences;
}

void main() {
  testWidgets(
    'fully transparent materials leave the live backdrop unchanged',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 150);
      tester.view.devicePixelRatio = _pixelRatio;
      addTearDown(tester.view.reset);
      await tester.runAsync(YumeiroGlassBackdrop.warmUp);
      final boundaryKey = GlobalKey();
      final opacity = ValueNotifier(1.0);
      addTearDown(opacity.dispose);
      await tester.pumpWidget(
        YumeiroApp(
          preset: YumeiroThemePresets.frostedGlassLight,
          capability: YumeiroMaterialCapability.fullOptical,
          home: RepaintBoundary(
            key: boundaryKey,
            child: ValueListenableBuilder<double>(
              valueListenable: opacity,
              builder: (context, value, child) => Row(
                children: [
                  _scene(),
                  _scene(optical: true, opacity: value),
                  _scene(optical: true),
                  _scene(optical: false, opacity: value),
                  _scene(optical: false),
                  _scene(optical: true, opacity: value, fallback: true),
                  _scene(optical: true, fallback: true),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final value in [.35, 0.0, 1.0, 0.0]) {
        opacity.value = value;
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
      expect(
        tester.layers.whereType<BackdropFilterLayer>().any(
          (layer) => layer.filter?.debugShortDescription == 'shader',
        ),
        isTrue,
      );
      await tester.runAsync(() async {
        final boundary =
            boundaryKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: _pixelRatio);
        try {
          final pixels = (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          expect(
            _differences(pixels, image.width, 1),
            0,
            reason: 'Invisible optical glass must not leave blur behind.',
          );
          expect(
            _differences(pixels, image.width, 3),
            0,
            reason: 'Invisible Gaussian acrylic must not leave blur behind.',
          );
          expect(
            _differences(pixels, image.width, 5),
            0,
            reason: 'Invisible glass fallback must leave no blur or tint.',
          );
          expect(
            _differences(pixels, image.width, 2),
            greaterThan(1000),
            reason: 'The visible optical sample must actually blur.',
          );
          expect(
            _differences(pixels, image.width, 4),
            greaterThan(1000),
            reason: 'The visible Gaussian sample must actually blur.',
          );
          expect(
            _differences(pixels, image.width, 6),
            greaterThan(1000),
            reason: 'The visible glass fallback must actually blur and tint.',
          );
        } finally {
          image.dispose();
        }
      });
      await tester.pumpWidget(const SizedBox.shrink());
    },
    // Run explicitly with flutter test --enable-impeller.
    skip: !ui.ImageFilter.isShaderFilterSupported,
  );
}
