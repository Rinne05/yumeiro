import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yumeiro/yumeiro.dart';

const _dpr = 1.25;
const _background = Color(0xFF2E4961);

enum _LayerKind { plain, opacity, saveLayer, imageFilter }

YumeiroVisualAppearance _appearance(double blur, {double opacity = 1}) =>
    YumeiroVisualAppearance(
      opacity: opacity,
      fill: const YumeiroSolidFill(Colors.transparent),
      foreground: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      transition: YumeiroVisualTransition.instant,
      effects: YumeiroEffectStack(
        backdropBlur: blur,
        backdropTint: Colors.transparent,
        glass: const YumeiroGlassEffect(
          tint: Colors.transparent,
          refraction: 0,
          thickness: 16,
          lighting: 1,
        ),
      ),
    );

class _LayerScene {
  _LayerScene(this.blur, this.kind, {this.scale = 1})
    : panelKey = GlobalKey(debugLabel: '$blur/${kind.name}/$scale');

  final double blur;
  final _LayerKind kind;
  final double scale;
  final GlobalKey panelKey;

  Widget build() {
    Widget content = ColoredBox(
      color: _background,
      child: Stack(
        children: [
          Positioned(
            left: 15,
            top: 15,
            width: 150,
            height: 100,
            child: SizedBox(
              key: panelKey,
              // Each scene samples its own pass. Sharing a backdrop key could
              // mask an incorrect origin by reusing another scene's texture.
              child: YumeiroGlassSamplingScope(
                child: YumeiroResolvedVisualSurface(
                  appearance: _appearance(blur),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    content = switch (kind) {
      _LayerKind.plain => content,
      _LayerKind.opacity => Opacity(opacity: .5, child: content),
      _LayerKind.saveLayer => ClipRect(
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: content,
      ),
      _LayerKind.imageFilter => ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: .01, sigmaY: .01),
        child: content,
      ),
    };
    if (scale != 1) {
      content = Transform.scale(
        scale: scale,
        alignment: Alignment.topLeft,
        child: content,
      );
    }
    return RepaintBoundary(child: content);
  }
}

({int bright, int changed}) _measureRegion(
  ByteData pixels,
  int imageWidth,
  int imageHeight,
  Rect region,
) {
  var bright = 0;
  var changed = 0;
  // Include pixels whose centers lie in the region. A scaled lip can be only
  // one physical pixel wide, including a fractional pixel at its true edge.
  final left = math.max(0, (region.left * _dpr - .5).ceil());
  final right = math.min(imageWidth, (region.right * _dpr - .5).ceil());
  final top = math.max(0, (region.top * _dpr - .5).ceil());
  final bottom = math.min(imageHeight, (region.bottom * _dpr - .5).ceil());
  for (var y = top; y < bottom; y++) {
    for (var x = left; x < right; x++) {
      final offset = (y * imageWidth + x) * 4;
      final red = pixels.getUint8(offset);
      final green = pixels.getUint8(offset + 1);
      final blue = pixels.getUint8(offset + 2);
      if (red > 48 && green > 75 && blue > 99) bright++;
      if ((red - 46).abs() > 2 ||
          (green - 73).abs() > 2 ||
          (blue - 97).abs() > 2) {
        changed++;
      }
    }
  }
  return (bright: bright, changed: changed);
}

void main() {
  testWidgets(
    'optical coordinates stay aligned across isolated rendering layers',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 975);
      tester.view.devicePixelRatio = _dpr;
      addTearDown(tester.view.reset);
      await tester.runAsync(YumeiroGlassBackdrop.warmUp);
      final boundaryKey = GlobalKey();
      final fadedPanelKey = GlobalKey();
      final fadedOpacity = ValueNotifier(1.0);
      addTearDown(fadedOpacity.dispose);
      final scenes = [
        for (final blur in [0.0, 1.0, 24.0])
          for (final kind in _LayerKind.values) _LayerScene(blur, kind),
        _LayerScene(1, _LayerKind.opacity, scale: .85),
      ];
      await tester.pumpWidget(
        YumeiroApp(
          preset: YumeiroThemePresets.liquidGlassLight,
          capability: YumeiroMaterialCapability.fullOptical,
          home: RepaintBoundary(
            key: boundaryKey,
            child: Stack(
              children: [
                const Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: 680,
                  child: ColoredBox(color: _background),
                ),
                for (var index = 0; index < scenes.length; index++)
                  Positioned(
                    left: 10 + (index % 4) * 195,
                    top: 10 + (index ~/ 4) * 170,
                    width: 180,
                    height: 140,
                    child: scenes[index].build(),
                  ),
                Positioned(
                  left: 10,
                  top: 690,
                  width: 180,
                  height: 70,
                  child: ColoredBox(
                    color: const Color(0x802E4961),
                    child: Stack(
                      children: [
                        Positioned(
                          left: 15,
                          top: 15,
                          width: 150,
                          height: 40,
                          child: SizedBox(
                            key: fadedPanelKey,
                            child: YumeiroGlassSamplingScope(
                              child: ValueListenableBuilder<double>(
                                valueListenable: fadedOpacity,
                                builder: (context, opacity, child) =>
                                    YumeiroResolvedVisualSurface(
                                      appearance: _appearance(
                                        24,
                                        opacity: opacity,
                                      ),
                                      child: const SizedBox.expand(),
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      fadedOpacity.value = 0;
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        tester.layers
            .whereType<BackdropFilterLayer>()
            .where((layer) => layer.filter?.debugShortDescription == 'shader')
            .length,
        greaterThanOrEqualTo(scenes.length),
      );
      final boundaryOrigin = tester.getTopLeft(find.byKey(boundaryKey));
      final panels = {
        for (final scene in scenes)
          scene: tester
              .getRect(find.byKey(scene.panelKey))
              .shift(-boundaryOrigin),
      };
      final fadedPanel = tester
          .getRect(find.byKey(fadedPanelKey))
          .shift(-boundaryOrigin);

      // Capture the complete view once, after every pass has been composed.
      // Repeated offscreen readbacks can disturb retained GPU layers and would
      // make comparisons between separate captures unreliable.
      await tester.runAsync(() async {
        final boundary =
            boundaryKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: _dpr);
        try {
          final pixels = (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          var minimumAlpha = 255;
          // The upper region is opaque; the lower scene deliberately has alpha
          // 128 so a fully faded filter cannot hide behind an opaque baseline.
          final opaqueBytes = (680 * _dpr).floor() * image.width * 4;
          for (var offset = 3; offset < opaqueBytes; offset += 4) {
            minimumAlpha = math.min(minimumAlpha, pixels.getUint8(offset));
          }
          expect(
            minimumAlpha,
            255,
            reason: 'Isolated inputs must not cut seams into an opaque page.',
          );
          for (final scene in scenes) {
            final panel = panels[scene]!;
            final reason =
                'blur=${scene.blur}, layer=${scene.kind.name}, scale=${scene.scale}';
            final edge = _measureRegion(
              pixels,
              image.width,
              image.height,
              Rect.fromLTWH(panel.left, panel.top + 30, 6, 40),
            );
            expect(
              edge.bright,
              greaterThan(30),
              reason: 'The highlight must follow the actual left edge: $reason',
            );
            final interior = _measureRegion(
              pixels,
              image.width,
              image.height,
              panel.deflate(20),
            );
            expect(
              interior.changed,
              0,
              reason: 'An offscreen pass must not create a false rim: $reason',
            );
          }
          int alphaAt(Offset point) {
            final x = (point.dx * _dpr).floor();
            final y = (point.dy * _dpr).floor();
            return pixels.getUint8((y * image.width + x) * 4 + 3);
          }

          expect(alphaAt(fadedPanel.topLeft - const Offset(10, 10)), 128);
          expect(
            alphaAt(fadedPanel.center),
            128,
            reason: 'Fully faded glass must restore the original page alpha.',
          );
        } finally {
          image.dispose();
        }
      });
      await tester.pumpWidget(const SizedBox.shrink());
    },
    // Runtime shader filters need the real optical backend for this regression.
    skip: !ui.ImageFilter.isShaderFilterSupported,
  );
}
