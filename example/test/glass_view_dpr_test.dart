import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yumeiro/yumeiro.dart';

void main() {
  testWidgets('mounted optical glass tracks changes to the view pixel ratio', (
    tester,
  ) async {
    const logicalSize = Size(200, 150);
    const initialDpr = 2.0;
    const currentDpr = 1.25;
    tester.view.devicePixelRatio = initialDpr;
    tester.view.physicalSize = logicalSize * initialDpr;
    addTearDown(tester.view.reset);
    await tester.runAsync(YumeiroGlassBackdrop.warmUp);

    final key = GlobalKey();
    final scene = RepaintBoundary(
      key: key,
      child: const Directionality(
        textDirection: TextDirection.ltr,
        child: ColoredBox(
          color: Color(0xFF2E4961),
          child: Stack(
            children: [
              Positioned(
                // The origin aligns at both DPRs, so it cannot invalidate the
                // cached uniforms on its own.
                left: 20,
                top: 24,
                width: 140.5,
                height: 95.25,
                child: YumeiroGlassBackdrop(
                  glass: YumeiroGlassEffect(
                    tint: Colors.transparent,
                    refraction: 0,
                  ),
                  blur: 0,
                  tint: null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(18)),
                  ),
                  capability: YumeiroMaterialCapability.fullOptical,
                  child: SizedBox.expand(),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Future<List<int>> readPixels() async => (await tester.runAsync(() async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(key),
      );
      final image = await boundary.toImage(pixelRatio: currentDpr);
      try {
        return (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!
            .buffer
            .asUint8List();
      } finally {
        image.dispose();
      }
    }))!;

    await tester.pumpWidget(scene);
    await tester.pumpAndSettle();
    expect(
      tester.layers.whereType<BackdropFilterLayer>().any(
        (layer) => layer.filter?.debugShortDescription == 'shader',
      ),
      isTrue,
    );

    // Change the view metrics while keeping the layout and widgets in place.
    tester.view.devicePixelRatio = currentDpr;
    tester.view.physicalSize = logicalSize * currentDpr;
    await tester.pumpAndSettle();
    final retained = await readPixels();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(scene);
    await tester.pumpAndSettle();
    final fresh = await readPixels();
    expect(retained, orderedEquals(fresh));
  }, skip: !ui.ImageFilter.isShaderFilterSupported);
}
