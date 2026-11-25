import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yumeiro/yumeiro.dart';

const _dpr = 1.25;
const _columns = 9;
const _cell = Size(240, 200);
const _opaqueBackground = Color(0xFF2E4961);
const _edgeClip = Rect.fromLTRB(30.3, 70.25, 220.4, 170.35);
const _backgrounds = [
  (color: Color(0x00008040), rgba: [0, 0, 0, 0]),
  (color: Color(0x40008040), rgba: [0, 32, 16, 64]),
  (color: Color(0x80008040), rgba: [0, 64, 32, 128]),
];

class _Scene {
  _Scene({
    required this.preset,
    required this.background,
    required this.rgba,
    required this.blur,
    required this.intensity,
    this.edges = false,
  });

  final YumeiroThemePreset preset;
  final Color background;
  final List<int> rgba;
  final double blur;
  final double intensity;
  final bool edges;
  final boundsKey = GlobalKey();
  final panelKey = GlobalKey();

  String get label =>
      '${preset.id}, alpha=${rgba[3]}, blur=$blur, '
      'intensity=$intensity';

  Widget build() => Theme(
    data: yumeiroThemeData(preset: preset),
    child: Builder(
      builder: (context) {
        final recipe = YumeiroTheme.of(
          context,
        ).visuals.control(YumeiroControlRole.neutral, const {});
        // Preserve preset geometry while removing all deliberate color layers.
        // The transparent matrix measures only sampling/compositing; the opaque
        // scenes separately keep lighting to prove real optical rims survive.
        final appearance = recipe.copyWith(
          fill: const YumeiroSolidFill(Colors.transparent),
          outline: BorderSide.none,
          transition: YumeiroVisualTransition.instant,
          effects: YumeiroEffectStack(
            backdropBlur: blur,
            backdropTint: Colors.transparent,
            glass: recipe.effects.glass!.copyWith(
              tint: Colors.transparent,
              intensity: intensity,
              lighting: edges ? 1 : 0,
            ),
          ),
        );
        final panel = Stack(
          children: [
            Positioned(
              left: edges ? 45.4 : 56,
              top: edges ? 40.35 : 52,
              width: edges ? 150 : 128,
              height: edges ? 120 : 96,
              child: SizedBox(
                key: panelKey,
                child: YumeiroResolvedVisualSurface(
                  appearance: appearance,
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ],
        );
        return ClipRect(
          key: boundsKey,
          child: ColoredBox(
            color: background,
            // The background is painted before this independent snapshot.
            child: YumeiroGlassSamplingScope(
              child: edges
                  ? ClipRect(
                      clipper: const _FractionalClip(),
                      clipBehavior: Clip.antiAliasWithSaveLayer,
                      child: panel,
                    )
                  : panel,
            ),
          ),
        );
      },
    ),
  );
}

class _FractionalClip extends CustomClipper<Rect> {
  const _FractionalClip();

  @override
  Rect getClip(Size size) => _edgeClip;

  @override
  bool shouldReclip(_FractionalClip oldClipper) => false;
}

Iterable<(int, int)> _pixels(Rect region, int width, int height) sync* {
  final left = math.max(0, (region.left * _dpr - .5).ceil());
  final right = math.min(width, (region.right * _dpr - .5).ceil());
  final top = math.max(0, (region.top * _dpr - .5).ceil());
  final bottom = math.min(height, (region.bottom * _dpr - .5).ceil());
  for (var y = top; y < bottom; y++) {
    for (var x = left; x < right; x++) {
      yield (x, y);
    }
  }
}

List<int> _rgba(ByteData pixels, int width, int x, int y) {
  final offset = (y * width + x) * 4;
  return [
    for (var channel = 0; channel < 4; channel++)
      pixels.getUint8(offset + channel),
  ];
}

bool _matches(List<int> actual, List<int> expected) => List.generate(
  4,
  (channel) => (actual[channel] - expected[channel]).abs(),
).every((difference) => difference <= 1);

void main() {
  testWidgets(
    'optical sampling preserves original premultiplied pixels and opaque edges',
    (tester) async {
      final presets = [
        YumeiroThemePresets.liquidGlassLight,
        YumeiroThemePresets.liquidGlassDark,
      ];
      final transparentScenes = [
        for (final preset in presets)
          for (final background in _backgrounds)
            for (final blur in [0.0, 1.0, 24.0])
              for (final intensity in [0.0, .5, 1.0])
                _Scene(
                  preset: preset,
                  background: background.color,
                  rgba: background.rgba,
                  blur: blur,
                  intensity: intensity,
                ),
      ];
      final edgeScenes = [
        for (final preset in presets)
          for (final blur in [0.0, 1.0, 24.0])
            _Scene(
              preset: preset,
              background: _opaqueBackground,
              rgba: const [46, 73, 97, 255],
              blur: blur,
              intensity: 1,
              edges: true,
            ),
      ];
      final reflection = _Scene(
        preset: YumeiroThemePresets.liquidGlassDark,
        background: const Color(0x00008040),
        rgba: const [0, 0, 0, 0],
        blur: 0,
        intensity: 1,
        edges: true,
      );
      final scenes = [...transparentScenes, ...edgeScenes, reflection];
      expect(transparentScenes, hasLength(54));
      expect(edgeScenes, hasLength(6));
      tester.view.physicalSize = Size(
        _columns * _cell.width * _dpr,
        (scenes.length / _columns).ceil() * _cell.height * _dpr,
      );
      tester.view.devicePixelRatio = _dpr;
      addTearDown(tester.view.reset);
      await tester.runAsync(YumeiroGlassBackdrop.warmUp);
      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        YumeiroApp(
          capability: YumeiroMaterialCapability.fullOptical,
          home: RepaintBoundary(
            key: boundaryKey,
            child: Stack(
              children: [
                for (var index = 0; index < scenes.length; index++)
                  Positioned(
                    left: (index % _columns) * _cell.width,
                    top: (index ~/ _columns) * _cell.height,
                    width: _cell.width,
                    height: _cell.height,
                    child: scenes[index].build(),
                  ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        tester.layers.whereType<BackdropFilterLayer>().any(
          (layer) => layer.filter?.debugShortDescription == 'shader',
        ),
        isTrue,
      );
      final origin = tester.getTopLeft(find.byKey(boundaryKey));
      final panels = {
        for (final scene in scenes)
          scene: tester.getRect(find.byKey(scene.panelKey)).shift(-origin),
      };
      final bounds = {
        for (final scene in scenes)
          scene: tester.getRect(find.byKey(scene.boundsKey)).shift(-origin),
      };
      // One final GPU readback for the whole matrix avoids retained-layer
      // artifacts caused by repeated Impeller snapshots in the same process.
      await tester.runAsync(() async {
        final image =
            await (boundaryKey.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage(pixelRatio: _dpr);
        try {
          final pixels = (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          final failures = <String>[];
          for (final scene in scenes) {
            final panel = panels[scene]!;
            for (final region in [
              Rect.fromCenter(center: panel.center, width: 4, height: 4),
              Rect.fromLTWH(
                bounds[scene]!.left + 18,
                bounds[scene]!.top + 18,
                4,
                4,
              ),
            ]) {
              for (final (x, y) in _pixels(region, image.width, image.height)) {
                final actual = _rgba(pixels, image.width, x, y);
                if (!_matches(actual, scene.rgba)) {
                  failures.add(
                    '${scene.label}: original premultiplied RGBA '
                    '${scene.rgba}, actual $actual at ($x,$y), tolerance ±1',
                  );
                  break;
                }
              }
            }
          }
          for (final scene in edgeScenes) {
            final panel = panels[scene]!;
            var damaged = 0;
            for (final (x, y) in _pixels(
              bounds[scene]!,
              image.width,
              image.height,
            )) {
              final actual = _rgba(pixels, image.width, x, y);
              if (actual[3] != 255 ||
                  actual[0] < scene.rgba[0] - 1 ||
                  actual[1] < scene.rgba[1] - 1 ||
                  actual[2] < scene.rgba[2] - 1) {
                damaged++;
              }
            }
            if (damaged != 0) {
              failures.add('${scene.label}: $damaged opaque seam pixels');
            }
            var bright = 0;
            for (final (x, y) in _pixels(
              Rect.fromLTWH(panel.left, panel.top + 50, 6, 40),
              image.width,
              image.height,
            )) {
              final actual = _rgba(pixels, image.width, x, y);
              if (actual[0] > 48 && actual[1] > 75 && actual[2] > 99) bright++;
            }
            if (bright <= 30) {
              failures.add('${scene.label}: only $bright real rim pixels');
            }
            final cropTop = bounds[scene]!.top + _edgeClip.top;
            final interior = Rect.fromLTRB(
              panel.left + 30,
              cropTop + .8,
              panel.right - 30,
              cropTop + 5.6,
            );
            for (final (x, y) in _pixels(interior, image.width, image.height)) {
              if (!_matches(_rgba(pixels, image.width, x, y), scene.rgba)) {
                failures.add(
                  '${scene.label}: a cropped interior created a false rim',
                );
                break;
              }
            }
          }
          // Alpha-preserving compositing must not mask deliberate specular
          // reflection, as srcATop would do on a fully transparent background.
          var reflectedPixels = 0;
          final reflectionPanel = panels[reflection]!;
          for (final (x, y) in _pixels(
            Rect.fromLTWH(
              reflectionPanel.left,
              reflectionPanel.top + 50,
              6,
              40,
            ),
            image.width,
            image.height,
          )) {
            if (_rgba(pixels, image.width, x, y)[3] > 0) reflectedPixels++;
          }
          if (reflectedPixels <= 30) {
            failures.add(
              'The transparent backdrop lost its optical reflection.',
            );
          }
          expect(failures, isEmpty, reason: failures.join('\n'));
        } finally {
          image.dispose();
        }
      });
      await tester.pumpWidget(const SizedBox.shrink());
    },
    skip: !ui.ImageFilter.isShaderFilterSupported,
  );
}
