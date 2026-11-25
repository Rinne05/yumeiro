import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yumeiro/yumeiro.dart';

void main() {
  testWidgets(
    'optical glass keeps opaque fractional edges after light-dark theme changes',
    (tester) async {
      tester.view.physicalSize = const Size(300, 250);
      tester.view.devicePixelRatio = 1.25;
      addTearDown(tester.view.reset);
      await tester.runAsync(YumeiroGlassBackdrop.warmUp);
      final selected = ValueNotifier(YumeiroThemePresets.frostedGlassLight);
      addTearDown(selected.dispose);
      final key = GlobalKey();
      await tester.pumpWidget(
        ValueListenableBuilder<YumeiroThemePreset>(
          valueListenable: selected,
          builder: (context, preset, child) => YumeiroApp(
            preset: preset,
            capability: YumeiroMaterialCapability.fullOptical,
            modality: YumeiroModality.pointer,
            home: child!,
          ),
          child: RepaintBoundary(
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
      // Keep the view and shader instances alive while exercising real theme
      // changes. Capture once at the end so repeated offscreen GPU readbacks
      // cannot perturb retained layers between the theme transitions.
      for (final preset in [
        YumeiroThemePresets.frostedGlassLight,
        YumeiroThemePresets.frostedGlassDark,
        YumeiroThemePresets.frostedGlassLight,
        YumeiroThemePresets.frostedGlassDark,
      ]) {
        selected.value = preset;
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          tester.layers.whereType<BackdropFilterLayer>().any(
            (layer) => layer.filter?.debugShortDescription == 'shader',
          ),
          isTrue,
          reason: 'This regression must exercise the optical renderer.',
        );
      }
      await tester.runAsync(() async {
        final image =
            await (key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage(pixelRatio: 1.25);
        try {
          final pixels = (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          var minimumAlpha = 255;
          for (var offset = 3; offset < pixels.lengthInBytes; offset += 4) {
            final alpha = pixels.getUint8(offset);
            if (alpha < minimumAlpha) minimumAlpha = alpha;
          }
          expect(minimumAlpha, 255, reason: selected.value.id);
        } finally {
          image.dispose();
        }
      });
      await tester.pumpWidget(const SizedBox.shrink());
    },
    // Run explicitly with flutter test --enable-impeller to cover real optics.
    skip: !ui.ImageFilter.isShaderFilterSupported,
  );
}
