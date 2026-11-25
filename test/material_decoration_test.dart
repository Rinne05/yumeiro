import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yumeiro/yumeiro.dart';

class _MeasuredBorder extends RoundedRectangleBorder {
  const _MeasuredBorder(this.onPath, {super.side, super.borderRadius});

  final VoidCallback onPath;

  @override
  RoundedRectangleBorder copyWith({
    BorderSide? side,
    BorderRadiusGeometry? borderRadius,
  }) => _MeasuredBorder(
    onPath,
    side: side ?? this.side,
    borderRadius: borderRadius ?? this.borderRadius,
  );

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    onPath();
    return super.getOuterPath(rect, textDirection: textDirection);
  }
}

void main() {
  test('decoration skips paths for unavailable material effects', () {
    var paths = 0;
    final decoration = YumeiroResolvedVisualSurface.materialDecoration(
      YumeiroVisualAppearance(
        fill: const YumeiroSolidFill(Colors.blue),
        foreground: Colors.white,
        shape: _MeasuredBorder(() => paths++),
        transition: YumeiroVisualTransition.instant,
        effects: YumeiroEffectStack.fromPasses([
          const YumeiroSheenPass(
            minCapability: YumeiroMaterialCapability.fullOptical,
          ),
          YumeiroOuterShadowPass(
            const [BoxShadow(blurRadius: 4)],
            minCapability: YumeiroMaterialCapability.fullOptical,
          ),
          YumeiroInnerShadowPass(
            const [YumeiroInnerShadow(color: Colors.black, blurRadius: 4)],
            minCapability: YumeiroMaterialCapability.fullOptical,
          ),
        ]),
      ),
      capability: YumeiroMaterialCapability.blurOnly,
    );
    expect((decoration as ShapeDecoration).shadows, isEmpty);
    final painter = decoration.createBoxPainter(() {});
    final recorder = ui.PictureRecorder();
    painter.paint(
      Canvas(recorder),
      Offset.zero,
      const ImageConfiguration(size: Size(80, 40)),
    );
    recorder.endRecording().dispose();
    painter.dispose();
    expect(paths, 0);
  });

  testWidgets('decoration tweens retain finishes below the outline', (
    tester,
  ) async {
    YumeiroVisualAppearance appearance(double sheen) => YumeiroVisualAppearance(
      fill: const YumeiroSolidFill(Colors.blue),
      foreground: Colors.black,
      shape: const RoundedRectangleBorder(),
      outline: const BorderSide(color: Colors.green, width: 4),
      effects: YumeiroEffectStack.fromPasses([
        YumeiroSheenPass(
          opacity: sheen,
          gradient: const LinearGradient(colors: [Colors.white, Colors.white]),
        ),
      ]),
      transition: YumeiroVisualTransition.instant,
    );

    final begin = YumeiroResolvedVisualSurface.materialDecoration(
      appearance(0),
    );
    final end = YumeiroResolvedVisualSurface.materialDecoration(appearance(1));
    await tester.runAsync(() async {
      for (final t in [.25, .5, .75]) {
        final decoration = DecorationTween(begin: begin, end: end).lerp(t);
        final painter = decoration.createBoxPainter(() {});
        final recorder = ui.PictureRecorder();
        painter.paint(
          Canvas(recorder),
          Offset.zero,
          const ImageConfiguration(size: Size(80, 40)),
        );
        final picture = recorder.endRecording();
        final image = await picture.toImage(80, 40);
        try {
          final bytes = (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          int channel(int x, int y, int channel) =>
              bytes.getUint8((y * image.width + x) * 4 + channel);
          expect(channel(40, 20, 0), closeTo(33 + (255 - 33) * t, 2));
          expect(channel(40, 20, 1), closeTo(150 + (255 - 150) * t, 2));
          expect(channel(2, 20, 0), 76);
          expect(channel(2, 20, 1), 175);
          expect(channel(2, 20, 2), 80);
        } finally {
          image.dispose();
          picture.dispose();
          painter.dispose();
        }
      }
      expect(Decoration.lerp(null, end, .5).runtimeType, end.runtimeType);
      expect(Decoration.lerp(end, null, .5).runtimeType, end.runtimeType);
    });
  });

  for (final direction in TextDirection.values) {
    testWidgets('material painters resolve directional shapes in $direction', (
      tester,
    ) async {
      final material = YumeiroMaterials.brushedMetal().withPass(
        const YumeiroSheenPass(
          gradient: LinearGradient(
            begin: AlignmentDirectional.centerStart,
            end: AlignmentDirectional.centerEnd,
            colors: [Colors.white, Colors.transparent],
          ),
        ),
      );
      final appearance = material
          .appearance(
            foreground: Colors.black,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadiusDirectional.only(
                topStart: Radius.circular(16),
              ),
            ),
            transition: YumeiroVisualTransition.instant,
          )
          .copyWith(
            focusIndicator: YumeiroFocusIndicator(
              side: const BorderSide(color: Colors.blue, width: 2),
            ),
          );
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: direction,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 100,
                    height: 40,
                    child: YumeiroResolvedVisualSurface(
                      appearance: appearance,
                      child: const Text('Surface'),
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    height: 40,
                    child: DecoratedBox(
                      decoration:
                          YumeiroResolvedVisualSurface.materialDecoration(
                            appearance,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
