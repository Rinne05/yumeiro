import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yumeiro/yumeiro.dart';

class _ForegroundPass extends YumeiroEffectPass {
  const _ForegroundPass(this.onPaint);

  final ValueChanged<TextDirection?> onPaint;

  @override
  void paintForeground(
    Canvas canvas,
    Size size,
    OutlinedBorder shape,
    YumeiroMaterialCapability capability, {
    TextDirection? textDirection,
  }) {
    onPaint(textDirection);
    canvas.drawRect(
      Rect.fromCenter(center: size.center(Offset.zero), width: 8, height: 8),
      Paint()..color = Colors.green,
    );
  }

  @override
  YumeiroEffectPass? lerp(YumeiroEffectPass? other, double t) => this;
}

class _DirectionalMaterialPass extends YumeiroEffectPass {
  const _DirectionalMaterialPass(this.onDirection);

  final ValueChanged<TextDirection?> onDirection;

  @override
  void paintMaterial(
    Canvas canvas,
    Size size,
    OutlinedBorder shape,
    YumeiroMaterialCapability capability, {
    TextDirection? textDirection,
  }) {
    onDirection(textDirection);
    canvas.drawPath(
      shape.getOuterPath(Offset.zero & size, textDirection: textDirection),
      Paint()..color = Colors.red,
    );
  }

  @override
  YumeiroEffectPass? lerp(YumeiroEffectPass? other, double t) => this;
}

class _ForegroundTintPass extends YumeiroTintOverlayPass {
  const _ForegroundTintPass(this.onPaint) : super(color: Colors.red);

  final ValueChanged<OutlinedBorder> onPaint;

  @override
  void paintForeground(
    Canvas canvas,
    Size size,
    OutlinedBorder shape,
    YumeiroMaterialCapability capability, {
    TextDirection? textDirection,
  }) {
    onPaint(shape);
    super.paintForeground(
      canvas,
      size,
      shape,
      capability,
      textDirection: textDirection,
    );
    canvas.drawRect(
      Rect.fromCenter(center: size.center(Offset.zero), width: 8, height: 8),
      Paint()..color = Colors.green,
    );
  }
}

YumeiroVisualAppearance _appearance(List<YumeiroEffectPass> passes) =>
    YumeiroVisualAppearance(
      fill: const YumeiroSolidFill(Colors.blue),
      foreground: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadiusDirectional.only(
          topStart: Radius.circular(28),
        ),
      ),
      effects: YumeiroEffectStack(extraPasses: passes),
      transition: YumeiroVisualTransition.instant,
    );

Widget _sample({
  required TextDirection direction,
  required GlobalKey boundaryKey,
  required Widget child,
}) => MaterialApp(
  home: Directionality(
    textDirection: direction,
    child: Center(
      child: RepaintBoundary(
        key: boundaryKey,
        child: SizedBox(
          width: 160,
          height: 80,
          child: ColoredBox(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: child,
            ),
          ),
        ),
      ),
    ),
  ),
);

Future<void> _expectPixels(
  WidgetTester tester,
  GlobalKey boundaryKey,
  TextDirection direction, {
  Color center = Colors.red,
}) async {
  await tester.runAsync(() async {
    final boundary =
        boundaryKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    final image = await boundary.toImage();
    try {
      final data = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      Color pixel(int x, int y) {
        final offset = (y * image.width + x) * 4;
        return Color.fromARGB(
          data.getUint8(offset + 3),
          data.getUint8(offset),
          data.getUint8(offset + 1),
          data.getUint8(offset + 2),
        );
      }

      final roundedCornerX = direction == TextDirection.ltr ? 14 : 145;
      final squareCornerX = direction == TextDirection.ltr ? 145 : 14;
      expect(pixel(roundedCornerX, 10).toARGB32(), Colors.white.toARGB32());
      expect(pixel(squareCornerX, 10).toARGB32(), Colors.red.toARGB32());
      expect(pixel(80, 40).toARGB32(), center.toARGB32());
    } finally {
      image.dispose();
    }
  });
}

void main() {
  for (final direction in TextDirection.values) {
    testWidgets(
      'tint subclasses can extend directional foreground painting in $direction',
      (tester) async {
        final boundaryKey = GlobalKey();
        final paintedShapes = <OutlinedBorder>[];
        final appearance = _appearance([
          _ForegroundTintPass(paintedShapes.add),
        ]);
        await tester.pumpWidget(
          _sample(
            direction: direction,
            boundaryKey: boundaryKey,
            child: YumeiroResolvedVisualSurface(
              appearance: appearance,
              child: const SizedBox.expand(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(paintedShapes, isNotEmpty);
        expect(paintedShapes, everyElement(same(appearance.shape)));
        await _expectPixels(
          tester,
          boundaryKey,
          direction,
          center: Colors.green,
        );
      },
    );

    testWidgets('foreground passes paint above content in $direction', (
      tester,
    ) async {
      final boundaryKey = GlobalKey();
      final directions = <TextDirection?>[];
      await tester.pumpWidget(
        _sample(
          direction: direction,
          boundaryKey: boundaryKey,
          child: YumeiroResolvedVisualSurface(
            appearance: _appearance([
              const YumeiroTintOverlayPass(color: Colors.red),
              _ForegroundPass(directions.add),
            ]),
            child: const Center(
              child: SizedBox(
                width: 12,
                height: 12,
                child: ColoredBox(color: Colors.purple),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(directions, isNotEmpty);
      expect(directions, everyElement(direction));
      await _expectPixels(tester, boundaryKey, direction, center: Colors.green);
    });

    testWidgets('material decorations retain directional hooks in $direction', (
      tester,
    ) async {
      final boundaryKey = GlobalKey();
      final directions = <TextDirection?>[];
      await tester.pumpWidget(
        _sample(
          direction: direction,
          boundaryKey: boundaryKey,
          child: DecoratedBox(
            decoration: YumeiroResolvedVisualSurface.materialDecoration(
              _appearance([_DirectionalMaterialPass(directions.add)]),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(directions, isNotEmpty);
      expect(directions, everyElement(direction));
      await _expectPixels(tester, boundaryKey, direction);
    });
  }
}
