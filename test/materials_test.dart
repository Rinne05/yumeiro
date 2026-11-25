import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yumeiro/yumeiro.dart';

void main() {
  test(
    'material decorations survive blur-only rendering without optical glass',
    () {
      final metal = YumeiroMaterials.brushedMetal();
      final ceramic = YumeiroMaterials.ceramic();
      final acrylic = YumeiroMaterials.acrylic();
      final glass = YumeiroMaterials.frostedGlass();

      expect(metal.effects.passOf<YumeiroBrushedTexturePass>(), isNotNull);
      expect(ceramic.effects.passOf<YumeiroSheenPass>(), isNotNull);
      expect(acrylic.effects.glass, isNull);
      expect(acrylic.effects.backdropBlur, greaterThan(0));
      expect(glass.effects.glass, isNotNull);
      expect(glass.effects.backdropBlur, greaterThan(0));
      expect(glass.effects.backdropTint, Colors.transparent);
      for (final material in [metal, ceramic, acrylic, glass]) {
        expect(
          material.effects.customPasses.every(
            (pass) =>
                YumeiroMaterialCapability.blurOnly.supports(pass.minCapability),
          ),
          isTrue,
        );
      }
    },
  );

  test('invalid host parameters stay bounded and silicone can be recessed', () {
    final glass = YumeiroMaterials.frostedGlass(
      blur: double.infinity,
      refraction: double.nan,
      thickness: -1,
      highlight: double.infinity,
      shadow: -1,
    );
    expect(glass.effects.backdropBlur, 26);
    expect(glass.effects.glass!.refraction, 10);
    expect(glass.effects.glass!.thickness, 0);
    expect(glass.effects.outerShadows, isEmpty);

    final raised = YumeiroMaterials.silicone();
    final recessed = YumeiroMaterials.silicone(pressed: true);
    expect(raised.effects.outerShadows, isNotEmpty);
    expect(recessed.effects.outerShadows, isEmpty);
    expect(recessed.effects.innerShadows, isNotEmpty);

    final quietAcrylic = YumeiroMaterials.acrylic(highlight: 0);
    final brightAcrylic = YumeiroMaterials.acrylic(highlight: 2);
    expect(quietAcrylic.effects.innerShadows, isEmpty);
    expect(brightAcrylic.effects.innerShadows, isNotEmpty);
    expect(
      brightAcrylic.outline.color.a,
      greaterThan(quietAcrylic.outline.color.a),
    );
  });

  test(
    'independent reflections compose by id and fade on theme transitions',
    () {
      const first = YumeiroSheenPass(id: 'first', opacity: .2);
      const second = YumeiroSheenPass(id: 'second', opacity: .8);
      final combined = YumeiroEffectStack.none.withPass(first).withPass(second);
      expect(combined.customPasses, hasLength(2));
      final faded = combined.lerp(YumeiroEffectStack.none, .5);
      expect(
        faded.customPasses.cast<YumeiroSheenPass>().map((pass) => pass.opacity),
        [.1, .4],
      );
      expect(combined.lerp(YumeiroEffectStack.none, 1).customPasses, isEmpty);
      final replaced = combined.withPass(
        const YumeiroSheenPass(id: 'first', opacity: .5),
      );
      expect(replaced.customPasses, hasLength(2));
      expect((replaced.customPasses.first as YumeiroSheenPass).opacity, .5);
    },
  );

  testWidgets(
    'brushed grain is stable across frames and respects rounded clips',
    (tester) async {
      await tester.runAsync(() async {
        Future<List<int>> render() async {
          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder);
          const YumeiroBrushedTexturePass().paintMaterial(
            canvas,
            const Size(64, 32),
            const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            YumeiroMaterialCapability.blurOnly,
          );
          final picture = recorder.endRecording();
          final image = await picture.toImage(64, 32);
          try {
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            );
            return bytes!.buffer.asUint8List().toList();
          } finally {
            image.dispose();
            picture.dispose();
          }
        }

        final first = await render();
        expect(first, orderedEquals(await render()));
        expect(first.any((channel) => channel > 0), isTrue);
        expect(first.take(4), everyElement(0));
      });
    },
  );

  testWidgets('saturated material actions keep light labels readable', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final materials = <String, YumeiroVisualMaterial>{
        'ceramic primary': YumeiroMaterials.ceramic(
          color: const Color(0xFF24786F),
          highlight: 2,
        ),
        'metal primary': YumeiroMaterials.brushedMetal(
          color: const Color(0xFF006E7B),
          highlight: 2,
          texture: 2,
        ),
      };
      for (final preset in [
        YumeiroThemePresets.ceramicLight,
        YumeiroThemePresets.brushedMetalLight,
        YumeiroThemePresets.acrylicLight,
        YumeiroThemePresets.siliconeLight,
        YumeiroThemePresets.frostedGlassLight,
      ]) {
        final theme = YumeiroThemeExtension.fromPreset(
          preset: preset,
          customizations: const {
            'materialHighlight': 200.0,
            'textureStrength': 200.0,
          },
        );
        for (final states in <Set<WidgetState>>[
          {},
          {WidgetState.hovered},
          {WidgetState.pressed},
        ]) {
          final appearance = theme.visuals.control(
            YumeiroControlRole.danger,
            states,
          );
          expect(appearance.foreground, Colors.white);
          materials['${preset.id} danger $states'] = YumeiroVisualMaterial(
            fill: appearance.fill,
            effects: appearance.effects,
          );
        }
      }
      for (final entry in materials.entries) {
        final material = entry.value;
        const size = Size(180, 48);
        const shape = RoundedRectangleBorder();
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        // White is the brightest backdrop for translucent danger actions.
        canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
        final fill = material.fill;
        canvas.drawRect(Offset.zero & size, switch (fill) {
          YumeiroSolidFill(:final color) => Paint()..color = color,
          YumeiroGradientFill(:final gradient) =>
            Paint()..shader = gradient.createShader(Offset.zero & size),
        });
        for (final pass in material.effects.customPasses) {
          pass.paintMaterial(
            canvas,
            size,
            shape,
            YumeiroMaterialCapability.blurOnly,
          );
        }
        final picture = recorder.endRecording();
        final image = await picture.toImage(
          size.width.toInt(),
          size.height.toInt(),
        );
        try {
          final bytes = (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          // Sample the central label region, including reflection bands and
          // grain, without the deliberately illuminated outer rim.
          for (var y = 14; y <= 34; y += 2) {
            for (var x = 36; x <= 144; x += 4) {
              final pixel = (y * image.width + x) * 4;
              final color = Color.fromARGB(
                255,
                bytes.getUint8(pixel),
                bytes.getUint8(pixel + 1),
                bytes.getUint8(pixel + 2),
              );
              final contrast = 1.05 / (color.computeLuminance() + .05);
              expect(
                contrast,
                greaterThanOrEqualTo(4.5),
                reason: '${entry.key} at ($x, $y)',
              );
            }
          }
        } finally {
          image.dispose();
          picture.dispose();
        }
      }
    });
  });

  testWidgets('dark material highlights retain dark surfaces and readable ink', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final materials = [
        YumeiroMaterials.ceramic(
          color: const Color(0xFF2C2925),
          brightness: Brightness.dark,
          highlight: 2,
        ),
        YumeiroMaterials.brushedMetal(
          color: const Color(0xFF2A353F),
          brightness: Brightness.dark,
          highlight: 2,
          texture: 2,
        ),
        YumeiroMaterials.silicone(
          color: const Color(0xFF37303F),
          brightness: Brightness.dark,
          highlight: 2,
        ),
        YumeiroMaterials.acrylic(
          tint: const Color(0x9E213C43),
          brightness: Brightness.dark,
          highlight: 2,
        ),
        YumeiroMaterials.frostedGlass(
          tint: const Color(0x7A263B4D),
          brightness: Brightness.dark,
          highlight: 2,
        ),
      ];
      for (final material in materials) {
        const size = Size(180, 48);
        const shape = RoundedRectangleBorder();
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        canvas.drawRect(
          Offset.zero & size,
          Paint()..color = const Color(0xFF111A22),
        );
        final fill = material.fill;
        canvas.drawRect(Offset.zero & size, switch (fill) {
          YumeiroSolidFill(:final color) => Paint()..color = color,
          YumeiroGradientFill(:final gradient) =>
            Paint()..shader = gradient.createShader(Offset.zero & size),
        });
        for (final pass in material.effects.customPasses) {
          pass.paintMaterial(
            canvas,
            size,
            shape,
            YumeiroMaterialCapability.blurOnly,
          );
        }
        final picture = recorder.endRecording();
        final image = await picture.toImage(180, 48);
        try {
          final bytes = (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          for (var y = 14; y <= 34; y += 2) {
            for (var x = 36; x <= 144; x += 4) {
              final offset = (y * image.width + x) * 4;
              final color = Color.fromARGB(
                255,
                bytes.getUint8(offset),
                bytes.getUint8(offset + 1),
                bytes.getUint8(offset + 2),
              );
              expect(
                1.05 / (color.computeLuminance() + .05),
                greaterThanOrEqualTo(4.5),
                reason:
                    'Dark material reflections must leave room for light labels.',
              );
            }
          }
        } finally {
          image.dispose();
          picture.dispose();
        }
      }
      final darkMetal = YumeiroMaterials.brushedMetal(
        color: const Color(0xFF2A353F),
        brightness: Brightness.dark,
      );
      expect(
        darkMetal.effects.passOf<YumeiroBrushedTexturePass>()!.opacity,
        greaterThan(.05),
      );
      final darkGlass = YumeiroMaterials.frostedGlass(
        tint: const Color(0x7A263B4D),
        brightness: Brightness.dark,
      );
      final lightGlass = YumeiroMaterials.frostedGlass();
      expect(darkGlass.outline.color.a, lessThan(lightGlass.outline.color.a));
      expect(darkGlass.fill.fallbackColor, const Color(0x7A263B4D));
    });
  });

  testWidgets('material reflections are below content and clipped to the shape', (
    tester,
  ) async {
    final boundaryKey = GlobalKey();
    final appearance =
        YumeiroVisualMaterial(
          fill: const YumeiroSolidFill(Colors.blue),
          effects: YumeiroEffectStack.fromPasses(const [
            YumeiroSheenPass(
              gradient: LinearGradient(colors: [Colors.white, Colors.white]),
            ),
          ]),
        ).appearance(
          foreground: Colors.black,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          transition: YumeiroVisualTransition.instant,
        );
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: RepaintBoundary(
            key: boundaryKey,
            child: SizedBox(
              width: 80,
              height: 40,
              child: YumeiroResolvedVisualSurface(
                appearance: appearance,
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: ColoredBox(color: Color(0xFFFF0000)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      final boundary =
          boundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await boundary.toImage();
      try {
        final bytes = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        int channel(int x, int y, int channel) =>
            bytes.getUint8((y * image.width + x) * 4 + channel);
        // A white material reflection paints the exposed blue fill.
        expect(channel(10, 20, 0), 255);
        expect(channel(10, 20, 1), 255);
        expect(channel(10, 20, 2), 255);
        // Opaque content retains its original red, with no reflection above it.
        expect(channel(40, 20, 0), 255);
        expect(channel(40, 20, 1), 0);
        expect(channel(40, 20, 2), 0);
        // The rounded shape excludes the corner.
        expect(channel(0, 0, 3), 0);
      } finally {
        image.dispose();
      }
    });
  });
}
