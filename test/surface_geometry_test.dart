import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yumeiro/yumeiro.dart';

class _RecordingBorder extends OutlinedBorder {
  const _RecordingBorder({
    required this.radius,
    required this.onPath,
    super.side,
  });

  final double radius;
  final ValueChanged<double> onPath;

  RoundedRectangleBorder get _border => RoundedRectangleBorder(
    side: side,
    borderRadius: BorderRadius.circular(radius),
  );

  @override
  _RecordingBorder copyWith({BorderSide? side}) =>
      _RecordingBorder(radius: radius, onPath: onPath, side: side ?? this.side);

  @override
  _RecordingBorder scale(double t) => _RecordingBorder(
    radius: (radius * t).clamp(0.0, double.infinity),
    onPath: onPath,
    side: side.scale(t),
  );

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) => a is _RecordingBorder
      ? _RecordingBorder(
          radius: a.radius + (radius - a.radius) * t,
          onPath: onPath,
          side: BorderSide.lerp(a.side, side, t),
        )
      : super.lerpFrom(a, t);

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) => b is _RecordingBorder
      ? _RecordingBorder(
          radius: radius + (b.radius - radius) * t,
          onPath: onPath,
          side: BorderSide.lerp(side, b.side, t),
        )
      : super.lerpTo(b, t);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    onPath(radius);
    return _border.getOuterPath(rect, textDirection: textDirection);
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _border.getInnerPath(rect, textDirection: textDirection);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) =>
      _border.paint(canvas, rect, textDirection: textDirection);

  @override
  bool operator ==(Object other) =>
      other is _RecordingBorder &&
      other.radius == radius &&
      other.side == side &&
      other.onPath == onPath;

  @override
  int get hashCode => Object.hash(radius, side, onPath);
}

@immutable
class _ShapeProbePass extends YumeiroEffectPass {
  const _ShapeProbePass({required this.onShape});

  final ValueChanged<OutlinedBorder> onShape;

  @override
  void paintMaterial(
    Canvas canvas,
    Size size,
    OutlinedBorder shape,
    YumeiroMaterialCapability capability, {
    TextDirection? textDirection,
  }) => onShape(shape);

  @override
  YumeiroEffectPass? lerp(YumeiroEffectPass? other, double t) =>
      other is _ShapeProbePass ? other : (t < 1 ? this : null);
}

void main() {
  testWidgets('switching modality keeps an editing field mounted and focused', (
    tester,
  ) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    Widget app(YumeiroModality modality) => YumeiroApp(
      modality: modality,
      home: Scaffold(body: YumeiroTextField(focusNode: focus)),
    );
    final input = find.byType(EditableText);

    await tester.pumpWidget(app(YumeiroModality.pointer));
    await tester.enterText(input, 'draft');
    await tester.pumpAndSettle();
    final state = tester.state<EditableTextState>(input);
    final controller = state.widget.controller;
    const caret = TextSelection.collapsed(offset: 2);
    controller.selection = caret;
    expect(focus.hasPrimaryFocus, isTrue);

    for (final mode in [YumeiroModality.touch, YumeiroModality.pointer]) {
      await tester.pumpWidget(app(mode));
      await tester.pumpAndSettle();
      expect(tester.state<EditableTextState>(input), same(state));
      expect(controller.text, 'draft');
      expect(controller.selection, caret);
      expect(focus.hasPrimaryFocus, isTrue);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('visual insets keep explicit size, constraints, and alignment', (
    tester,
  ) async {
    const surfaceKey = ValueKey('surface');
    const childKey = ValueKey('content');
    const appearance = YumeiroVisualAppearance(
      fill: YumeiroSolidFill(Colors.blue),
      foreground: Colors.white,
      shape: RoundedRectangleBorder(),
      transition: YumeiroVisualTransition.instant,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: YumeiroResolvedVisualSurface(
            key: surfaceKey,
            appearance: appearance,
            width: 160,
            height: 40,
            constraints: BoxConstraints(maxWidth: 120),
            alignment: Alignment.bottomRight,
            padding: EdgeInsets.all(4),
            visualInsets: EdgeInsets.all(3),
            child: SizedBox(key: childKey, width: 20, height: 10),
          ),
        ),
      ),
    );

    final surface = find.byKey(surfaceKey);
    final child = find.byKey(childKey);
    expect(tester.getSize(surface), const Size(120, 40));
    expect(tester.getSize(child), const Size(20, 10));
    expect(
      tester.getBottomRight(child),
      tester.getBottomRight(surface) - const Offset(4, 4),
    );
  });

  testWidgets('the shadow layer never paints a shape-owned border', (
    tester,
  ) async {
    final boundaryKey = GlobalKey();
    final appearance = YumeiroVisualAppearance(
      fill: const YumeiroSolidFill(Colors.transparent),
      foreground: Colors.black,
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: Color(0xFFFF0000), width: 5),
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      outline: BorderSide.none,
      effects: YumeiroEffectStack.fromPasses([
        YumeiroOuterShadowPass(const [BoxShadow(color: Colors.transparent)]),
      ]),
      transition: YumeiroVisualTransition.instant,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: RepaintBoundary(
            key: boundaryKey,
            child: SizedBox(
              width: 100,
              height: 50,
              child: YumeiroResolvedVisualSurface(
                appearance: appearance,
                child: const SizedBox.expand(),
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
        final data = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        final pixels = data.buffer.asUint8List();
        expect(
          [for (var i = 3; i < pixels.length; i += 4) pixels[i]],
          everyElement(0),
          reason: 'A transparent shadow must not introduce the red shape.side.',
        );
      } finally {
        image.dispose();
      }
    });
  });

  testWidgets('all paint layers share the animated shape and retain content', (
    tester,
  ) async {
    final pathRadii = <double>[];
    final materialShapes = <OutlinedBorder>[];
    final surfaceKey = GlobalKey();
    late StateSetter update;
    var radius = 2.0;
    var reducedMotion = false;
    final ValueChanged<double> recordPath = pathRadii.add;
    final probe = _ShapeProbePass(onShape: materialShapes.add);

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(disableAnimations: reducedMotion),
              child: Center(
                child: SizedBox(
                  width: 160,
                  height: 60,
                  child: YumeiroMaterialCapabilityScope(
                    capability: YumeiroMaterialCapability.blurOnly,
                    child: YumeiroResolvedVisualSurface(
                      key: surfaceKey,
                      appearance: YumeiroVisualAppearance(
                        fill: const YumeiroSolidFill(Color(0xFFCCEEDD)),
                        foreground: Colors.black,
                        shape: _RecordingBorder(
                          radius: radius,
                          onPath: recordPath,
                        ),
                        outline: const BorderSide(color: Colors.blue, width: 1),
                        focusIndicator: YumeiroFocusIndicator(
                          side: const BorderSide(
                            color: Colors.purple,
                            width: 2,
                          ),
                        ),
                        effects: YumeiroEffectStack(
                          backdropBlur: 1,
                          outerShadows: const [
                            BoxShadow(color: Color(0x22000000), blurRadius: 2),
                          ],
                          extraPasses: [probe],
                        ),
                        transition: const YumeiroVisualTransition(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.linear,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: const Text('stable content'),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    final childElement = tester.element(find.text('stable content'));
    update(() => radius = 22);
    await tester.pump();
    pathRadii.clear();
    materialShapes.clear();
    await tester.pump(const Duration(milliseconds: 150));

    final descendants = find.descendant(
      of: find.byKey(surfaceKey),
      matching: find.byType(DecoratedBox),
    );
    final paintedShapes = tester
        .widgetList<DecoratedBox>(descendants)
        .map((box) => box.decoration)
        .whereType<ShapeDecoration>()
        .map((decoration) => decoration.shape)
        .whereType<_RecordingBorder>()
        .toList();
    expect(paintedShapes, hasLength(3));
    for (final shape in paintedShapes) {
      expect(shape.radius, closeTo(12, .001));
    }
    final clip = tester.widget<ClipPath>(
      find.descendant(
        of: find.byKey(surfaceKey),
        matching: find.byType(ClipPath),
      ),
    );
    expect(
      ((clip.clipper! as ShapeBorderClipper).shape as _RecordingBorder).radius,
      closeTo(12, .001),
    );
    final backdrop = tester.widget<YumeiroGlassBackdrop>(
      find.descendant(
        of: find.byKey(surfaceKey),
        matching: find.byType(YumeiroGlassBackdrop),
      ),
    );
    expect((backdrop.shape as _RecordingBorder).radius, closeTo(12, .001));
    expect(materialShapes, isNotEmpty);
    expect(
      materialShapes.cast<_RecordingBorder>().map((shape) => shape.radius),
      everyElement(closeTo(12, .001)),
    );
    // This includes paths requested by the focus painter, material clipping,
    // and shadow/fill painters, so a target-shape jump in any layer is caught.
    expect(pathRadii, isNotEmpty);
    expect(pathRadii, everyElement(closeTo(12, .001)));
    expect(tester.element(find.text('stable content')), same(childElement));

    update(() {
      radius = 6;
      reducedMotion = true;
    });
    await tester.pump();
    final reducedBackdrop = tester.widget<YumeiroGlassBackdrop>(
      find.descendant(
        of: find.byKey(surfaceKey),
        matching: find.byType(YumeiroGlassBackdrop),
      ),
    );
    expect((reducedBackdrop.shape as _RecordingBorder).radius, 6);
    expect(tester.element(find.text('stable content')), same(childElement));
    expect(tester.takeException(), isNull);
  });
}
