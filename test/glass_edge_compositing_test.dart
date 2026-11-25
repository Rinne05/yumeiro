import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yumeiro/yumeiro.dart';

void main() {
  for (final dpr in [1.0, 1.25, 1.5, 2.0]) {
    testWidgets('nested frosted edges preserve an opaque page at DPR $dpr', (
      tester,
    ) async {
      tester.view.physicalSize = Size(240 * dpr, 200 * dpr);
      tester.view.devicePixelRatio = dpr;
      addTearDown(tester.view.reset);
      final key = GlobalKey();
      await tester.pumpWidget(
        YumeiroApp(
          preset: YumeiroThemePresets.frostedGlassLight,
          modality: YumeiroModality.pointer,
          capability: YumeiroMaterialCapability.blurOnly,
          home: RepaintBoundary(
            key: key,
            child: ColoredBox(
              color: const Color(0xFFD9E7ED),
              child: Center(
                child: Transform.translate(
                  offset: const Offset(.4, .35),
                  child: YumeiroCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const YumeiroButton(
                          label: 'Reset',
                          width: 100.5,
                          onPressed: null,
                        ),
                        const SizedBox(height: 20),
                        YumeiroButton(
                          label: 'Preset',
                          width: 100.5,
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final layers = tester.layers.whereType<BackdropFilterLayer>();
      expect(layers, isNotEmpty);
      expect(layers.every((layer) => layer.blendMode == BlendMode.src), isTrue);
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: dpr);
        try {
          final bytes = (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          var minimumAlpha = 255;
          for (var offset = 3; offset < bytes.lengthInBytes; offset += 4) {
            final alpha = bytes.getUint8(offset);
            if (alpha < minimumAlpha) minimumAlpha = alpha;
          }
          expect(
            minimumAlpha,
            255,
            reason:
                'Blur must not punch transparent seams into an opaque page.',
          );
        } finally {
          image.dispose();
        }
      });
    });
  }

  for (final alpha in [0, 128]) {
    testWidgets('Gaussian blur preserves a backdrop with alpha $alpha', (
      tester,
    ) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: RepaintBoundary(
              key: key,
              child: ColoredBox(
                color: Color.fromARGB(alpha, 255, 0, 0),
                child: SizedBox(
                  width: 200,
                  height: 100,
                  child: Center(
                    child: SizedBox(
                      width: 80,
                      height: 40,
                      child: ClipRect(
                        child: YumeiroGlassBackdrop(
                          glass: null,
                          blur: 8,
                          tint: null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          capability: YumeiroMaterialCapability.blurOnly,
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.runAsync(() async {
        final image =
            await (key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        try {
          final bytes = (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          if (alpha == 0) {
            for (var offset = 3; offset < bytes.lengthInBytes; offset += 4) {
              expect(bytes.getUint8(offset), 0);
            }
          } else {
            final center = (50 * image.width + 100) * 4;
            final outside = (10 * image.width + 10) * 4;
            expect(bytes.getUint8(center + 3), 128);
            expect(bytes.getUint8(outside + 3), 128);
          }
        } finally {
          image.dispose();
        }
      });
    });
  }
}
