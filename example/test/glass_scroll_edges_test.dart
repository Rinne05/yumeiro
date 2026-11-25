import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yumeiro/yumeiro.dart';

const _pixelRatio = 1.25;
const _background = Color(0xFF2E4961);
const _viewportSize = Size(300, 180);

final _appearance = YumeiroVisualAppearance(
  fill: const YumeiroSolidFill(Colors.transparent),
  foreground: Colors.white,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(24)),
  ),
  transition: YumeiroVisualTransition.instant,
  effects: YumeiroEffectStack(
    backdropBlur: 24,
    backdropTint: Colors.transparent,
    glass: const YumeiroGlassEffect(
      tint: Colors.transparent,
      refraction: 0,
      thickness: 18,
      lighting: 1,
    ),
  ),
);

enum _Kind { vertical, horizontal, hidden, sliver, movingClip, rotated }

class _Scene {
  _Scene(this.kind);

  final _Kind kind;
  final viewportKey = GlobalKey();
  final panelKey = GlobalKey();
  final scroll = ScrollController();
  final clipTop = ValueNotifier(0.0);

  Widget get _panel => SizedBox(
    key: panelKey,
    width: kind == _Kind.horizontal ? 500 : 260,
    height: kind == _Kind.horizontal ? 140 : 400,
    child: YumeiroResolvedVisualSurface(
      appearance: _appearance,
      child: const SizedBox.expand(),
    ),
  );

  Widget build() {
    final Widget content;
    switch (kind) {
      case _Kind.movingClip:
        content = ClipRect(
          clipper: const _RectClipper(Rect.fromLTRB(8, 0, 292, 180)),
          child: ValueListenableBuilder<double>(
            valueListenable: clipTop,
            child: Stack(
              children: [Positioned(left: 20, top: 20, child: _panel)],
            ),
            builder: (context, top, child) => ClipRect(
              clipper: _RectClipper(Rect.fromLTRB(0, top, 300, 180)),
              child: child,
            ),
          ),
        );
      case _Kind.horizontal:
        content = SingleChildScrollView(
          controller: scroll,
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const SizedBox(width: 40),
              _panel,
              const SizedBox(width: 700),
            ],
          ),
        );
      case _Kind.sliver:
        content = CustomScrollView(
          controller: scroll,
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _panel,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 700)),
          ],
        );
      case _Kind.vertical:
      case _Kind.hidden:
      case _Kind.rotated:
        content = SingleChildScrollView(
          controller: scroll,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: kind == _Kind.rotated
                    ? Transform.rotate(
                        angle: .04,
                        alignment: Alignment.topLeft,
                        child: _panel,
                      )
                    : _panel,
              ),
              const SizedBox(height: 700),
            ],
          ),
        );
    }
    return SizedBox(key: viewportKey, child: content);
  }

  Rect visibleClip(WidgetTester tester) {
    final viewport = tester.getRect(find.byKey(viewportKey));
    return kind == _Kind.movingClip
        ? Rect.fromLTRB(
            viewport.left + 8,
            viewport.top + clipTop.value,
            viewport.right - 8,
            viewport.bottom,
          )
        : viewport;
  }

  Rect get localEdge => switch (kind) {
    _Kind.horizontal => const Rect.fromLTWH(240, 0, 50, 5),
    _Kind.movingClip => const Rect.fromLTWH(0, 100, 5, 40),
    _ => const Rect.fromLTWH(0, 240, 5, 50),
  };

  void dispose() {
    scroll.dispose();
    clipTop.dispose();
  }
}

// Deliberately leave getApproximateClipRect at its default. The renderer must
// use the actual clipper bounds, including changes without a surface transform.
class _RectClipper extends CustomClipper<Rect> {
  const _RectClipper(this.rect);

  final Rect rect;

  @override
  Rect getClip(Size size) => rect.intersect(Offset.zero & size);

  @override
  bool shouldReclip(_RectClipper oldClipper) => rect != oldClipper.rect;
}

({int changed, int bright, int maximumDelta}) _pixelsIn(
  ByteData pixels,
  int width,
  int height,
  bool Function(Offset) contains,
) {
  var changed = 0;
  var bright = 0;
  var maximumDelta = 0;
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      if (!contains(Offset((x + .5) / _pixelRatio, (y + .5) / _pixelRatio))) {
        continue;
      }
      final offset = (y * width + x) * 4;
      final red = pixels.getUint8(offset);
      final green = pixels.getUint8(offset + 1);
      final blue = pixels.getUint8(offset + 2);
      final alpha = pixels.getUint8(offset + 3);
      final delta = math.max(
        math.max((red - 46).abs(), (green - 73).abs()),
        math.max((blue - 97).abs(), (alpha - 255).abs()),
      );
      maximumDelta = math.max(maximumDelta, delta);
      if (delta > 2) changed++;
      if (red > 49 && green > 76 && blue > 100 && alpha == 255) bright++;
    }
  }
  return (changed: changed, bright: bright, maximumDelta: maximumDelta);
}

void main() {
  testWidgets(
    'optical rims follow material edges through scrolling and changing clips',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 700);
      tester.view.devicePixelRatio = _pixelRatio;
      addTearDown(tester.view.reset);
      await tester.runAsync(YumeiroGlassBackdrop.warmUp);
      final boundaryKey = GlobalKey();
      final scenes = [for (final kind in _Kind.values) _Scene(kind)];
      for (final scene in scenes) {
        addTearDown(scene.dispose);
      }
      await tester.pumpWidget(
        YumeiroApp(
          preset: YumeiroThemePresets.frostedGlassLight,
          capability: YumeiroMaterialCapability.fullOptical,
          home: RepaintBoundary(
            key: boundaryKey,
            child: ColoredBox(
              color: _background,
              child: Stack(
                children: [
                  for (var index = 0; index < scenes.length; index++)
                    Positioned(
                      left: 30 + (index % 3) * 360,
                      top: 40 + (index ~/ 3) * 260,
                      width: _viewportSize.width,
                      height: _viewportSize.height,
                      child: scenes[index].build(),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final offset in [60.0, 120.0, 180.0, 80.0, 180.0]) {
        for (final scene in scenes.where((scene) => scene.scroll.hasClients)) {
          scene.scroll.jumpTo(offset);
        }
        await tester.pumpAndSettle();
      }
      scenes
          .singleWhere((scene) => scene.kind == _Kind.hidden)
          .scroll
          .jumpTo(600);
      final movingClip = scenes.singleWhere(
        (scene) => scene.kind == _Kind.movingClip,
      );
      final fixedPanelRect = tester.getRect(find.byKey(movingClip.panelKey));
      for (final top in [32.0, 64.0, 24.0, 80.0]) {
        movingClip.clipTop.value = top;
        await tester.pumpAndSettle();
      }
      expect(tester.getRect(find.byKey(movingClip.panelKey)), fixedPanelRect);
      expect(tester.takeException(), isNull);
      expect(
        tester.layers
            .whereType<BackdropFilterLayer>()
            .where((layer) => layer.filter?.debugShortDescription == 'shader')
            .length,
        greaterThanOrEqualTo(scenes.length - 1),
      );

      final clips = [for (final scene in scenes) scene.visibleClip(tester)];
      final boundary =
          boundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final edgeRegions = <_Scene, Rect>{};
      for (final scene in scenes) {
        final clip = scene.visibleClip(tester);
        final panel = tester.getRect(find.byKey(scene.panelKey));
        if (scene.kind == _Kind.hidden) {
          expect(panel.bottom, lessThan(clip.top - 64));
        } else {
          if (scene.kind == _Kind.horizontal) {
            expect(panel.left, lessThan(clip.left - 40));
            expect(panel.right, greaterThan(clip.right + 40));
          } else {
            expect(panel.top, lessThan(clip.top - 40));
            expect(panel.bottom, greaterThan(clip.bottom + 40));
          }
          final panelBox =
              scene.panelKey.currentContext!.findRenderObject()! as RenderBox;
          edgeRegions[scene] = MatrixUtils.transformRect(
            panelBox.getTransformTo(boundary),
            scene.localEdge,
          );
        }
      }

      // A single final readback covers every scene. Repeated Impeller readbacks
      // can themselves perturb retained backdrop layers between frames.
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: _pixelRatio);
        try {
          final pixels = (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          for (final scene in scenes) {
            final clip = scene.visibleClip(tester);
            final Rect interior;
            if (scene.kind == _Kind.hidden) {
              interior = clip;
            } else if (scene.kind == _Kind.horizontal) {
              interior = Rect.fromLTRB(
                clip.left + .8,
                clip.top + 60,
                clip.left + 6.4,
                clip.bottom - 40,
              );
            } else {
              interior = Rect.fromLTRB(
                clip.left + 80,
                clip.top + .8,
                clip.right - 80,
                clip.top + 6.4,
              );
            }
            final stats = _pixelsIn(
              pixels,
              image.width,
              image.height,
              interior.contains,
            );
            expect(
              stats.changed,
              0,
              reason:
                  '${scene.kind.name}: crop interiors must not create a rim '
                  'or retain offscreen paint (maximum delta ${stats.maximumDelta}).',
            );
            if (scene.kind != _Kind.hidden) {
              final edge = _pixelsIn(
                pixels,
                image.width,
                image.height,
                edgeRegions[scene]!.contains,
              );
              expect(
                edge.bright,
                greaterThan(10),
                reason:
                    '${scene.kind.name}: the real visible edge must still '
                    'have shader lighting.',
              );
            }
          }
          final outside = _pixelsIn(
            pixels,
            image.width,
            image.height,
            // Allow one physical pixel for fractional clip rasterization.
            (point) => !clips.any((clip) => clip.inflate(.8).contains(point)),
          );
          expect(
            outside.changed,
            0,
            reason: 'No material may escape its clip.',
          );
        } finally {
          image.dispose();
        }
      });
      await tester.pumpWidget(const SizedBox.shrink());
    },
    // Exercise real shader filters with flutter test --enable-impeller.
    skip: !ui.ImageFilter.isShaderFilterSupported,
  );
}
