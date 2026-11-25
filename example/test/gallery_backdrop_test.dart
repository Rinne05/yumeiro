import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yumeiro_example/src/widgets/gallery_backdrop.dart';

void main() {
  for (final enabled in [true, false]) {
    testWidgets(
      'light artwork stays local under a dark host with enabled=$enabled',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final boundaryKey = GlobalKey();
        const background = Color(0xFF172B41);

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: Center(
              child: RepaintBoundary(
                key: boundaryKey,
                child: SizedBox(
                  width: 300,
                  height: 300,
                  child: ColoredBox(
                    color: background,
                    child: Center(
                      child: SizedBox(
                        width: 120,
                        height: 120,
                        child: GalleryBackdrop(
                          enabled: enabled,
                          brightness: Brightness.light,
                          child: const SizedBox.expand(),
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
          final boundary =
              boundaryKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 1);
          try {
            expect(image.width, 300);
            expect(image.height, 300);
            final pixels = (await image.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            ))!;
            var outsideChanges = 0;
            var insideChanges = 0;
            for (var y = 0; y < image.height; y++) {
              for (var x = 0; x < image.width; x++) {
                final offset = (y * image.width + x) * 4;
                final unchanged =
                    pixels.getUint8(offset) == 0x17 &&
                    pixels.getUint8(offset + 1) == 0x2B &&
                    pixels.getUint8(offset + 2) == 0x41 &&
                    pixels.getUint8(offset + 3) == 0xFF;
                if (unchanged) continue;
                if (x >= 90 && x < 210 && y >= 90 && y < 210) {
                  insideChanges++;
                } else {
                  outsideChanges++;
                }
              }
            }
            expect(
              outsideChanges,
              0,
              reason: 'Artwork must not paint beyond its centered 120×120 box.',
            );
            expect(insideChanges, enabled ? greaterThan(0) : 0);
            if (enabled) {
              final center = (150 * image.width + 150) * 4;
              for (var channel = 0; channel < 3; channel++) {
                expect(
                  pixels.getUint8(center + channel),
                  greaterThan(160),
                  reason: 'The light artwork must override the dark host.',
                );
              }
            }
          } finally {
            image.dispose();
          }
        });
      },
    );
  }
}
