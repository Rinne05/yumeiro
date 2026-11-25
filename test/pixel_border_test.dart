import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yumeiro/src/primitives/pixel_border.dart';

void main() {
  test('pixel corners cut out the corner and retain orthogonal steps', () {
    const shape = YumeiroPixelBorder(step: 3);
    final path = shape.getOuterPath(const Rect.fromLTWH(0, 0, 100, 40));
    expect(path.contains(const Offset(1, 1)), isFalse);
    expect(path.contains(const Offset(4, 1)), isFalse);
    expect(path.contains(const Offset(4, 4)), isTrue);
    expect(path.contains(const Offset(1, 7)), isTrue);
    expect(path.contains(const Offset(50, 20)), isTrue);
    expect(path.getBounds(), const Rect.fromLTWH(0, 0, 100, 40));
  });

  test('tiny bounds and a border wider than the surface stay valid', () {
    const shape = YumeiroPixelBorder(step: 8, side: BorderSide(width: 4));
    final path = shape.getOuterPath(const Rect.fromLTWH(10, 20, 3, 2));
    expect(path.getBounds(), const Rect.fromLTWH(10, 20, 3, 2));
    expect(path.contains(const Offset(11.5, 21)), isTrue);
    expect(
      shape.getInnerPath(const Rect.fromLTWH(10, 20, 3, 2)).computeMetrics(),
      isEmpty,
    );
    expect(shape.getOuterPath(Rect.zero).computeMetrics(), isEmpty);
  });

  test('inner paths respect stroke inset and stroke alignment', () {
    const rect = Rect.fromLTWH(0, 0, 100, 40);
    const inside = YumeiroPixelBorder(side: BorderSide(width: 2));
    const outside = YumeiroPixelBorder(
      side: BorderSide(width: 2, strokeAlign: BorderSide.strokeAlignOutside),
    );
    expect(inside.getInnerPath(rect).getBounds(), rect.deflate(2));
    expect(outside.getInnerPath(rect).getBounds(), rect);
  });

  test('copy, scale, and interpolation retain the stepped shape', () {
    const a = YumeiroPixelBorder(step: 2, side: BorderSide(width: 2));
    const b = YumeiroPixelBorder(step: 6, side: BorderSide(width: 4));
    expect(a.copyWith(), a);
    expect(a.scale(.5).step, 1);
    final midpoint = ShapeBorder.lerp(a, b, .5)! as YumeiroPixelBorder;
    expect(midpoint.step, 4);
    expect(midpoint.side.width, 3);
    expect(a.hashCode, a.copyWith().hashCode);
  });
}
