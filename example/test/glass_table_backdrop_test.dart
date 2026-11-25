import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yumeiro/yumeiro.dart';

const _dpr = 1.5;
const _viewport = Rect.fromLTWH(23.5, 27.25, 440, 258);
const _actions = [
  (Icons.info_outline, 'Show info'),
  (Icons.open_in_new, 'Open'),
  (Icons.delete, 'Delete'),
  (Icons.more_horiz, 'More actions'),
];

void main() {
  testWidgets('optical table actions keep their local backdrop while scrolling', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(750, 480);
    tester.view.devicePixelRatio = _dpr;
    addTearDown(tester.view.reset);
    await tester.runAsync(YumeiroGlassBackdrop.warmUp);

    final boundaryKey = GlobalKey();
    final vertical = ScrollController();
    final showActions = ValueNotifier(true);
    addTearDown(vertical.dispose);
    addTearDown(showActions.dispose);
    await tester.pumpWidget(
      YumeiroApp(
        preset: YumeiroThemePresets.liquidGlassDark,
        modality: YumeiroModality.pointer,
        home: RepaintBoundary(
          key: boundaryKey,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [Color(0xAC50BEB8), Color(0x72E060A0)],
              ),
            ),
            child: Stack(
              children: [
                Positioned.fromRect(
                  rect: _viewport,
                  child: YumeiroScrollView(
                    controller: vertical,
                    child: YumeiroDataTable<int>(
                      minWidth: 590,
                      items: List.generate(8, (index) => index),
                      columns: [
                        YumeiroTableColumn(
                          title: 'Task',
                          cellBuilder: (_, item, _) => Text('Task $item'),
                        ),
                        YumeiroTableColumn(
                          title: 'Actions',
                          fixedWidth: 212,
                          alignment: Alignment.centerRight,
                          cellBuilder: (_, item, _) => ValueListenableBuilder(
                            valueListenable: showActions,
                            child: Wrap(
                              spacing: 8,
                              children: [
                                for (
                                  var column = 0;
                                  column < _actions.length;
                                  column++
                                )
                                  YumeiroButton(
                                    key: ValueKey((item, column)),
                                    variant: YumeiroButtonVariant.secondary,
                                    icon: _actions[column].$1,
                                    semanticLabel: _actions[column].$2,
                                    onPressed: () {},
                                  ),
                              ],
                            ),
                            builder: (_, visible, child) =>
                                Opacity(opacity: visible ? 1 : 0, child: child),
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
      ),
    );
    await tester.pumpAndSettle();
    final opticalLayers = tester.layers.whereType<BackdropFilterLayer>().where(
      (layer) => layer.filter?.debugShortDescription == 'shader',
    );
    expect(opticalLayers, isNotEmpty);
    // A fresh process can happen to have zeroed shader buffers. Check that
    // this scene's copy passes avoid runtime uniforms as well as checking pixels.
    for (final layer in opticalLayers) {
      expect(
        layer.parent,
        isA<BackdropFilterLayer>().having(
          (input) => input.filter,
          'input filter',
          isA<ui.ColorFilter>(),
        ),
      );
    }

    final horizontal = tester
        .stateList<ScrollableState>(find.byType(Scrollable))
        .singleWhere((state) => state.axisDirection == AxisDirection.right)
        .position;
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(boundaryKey),
    );

    Future<List<List<int>>> readPixels(List<Offset> points) async =>
        (await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: _dpr);
          try {
            final bytes = (await image.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            ))!;
            return [
              for (final point in points)
                [
                  for (var channel = 0; channel < 4; channel++)
                    bytes.getUint8(
                      (((point.dy * _dpr).floor() * image.width) +
                                  (point.dx * _dpr).floor()) *
                              4 +
                          channel,
                    ),
                ],
            ];
          } finally {
            image.dispose();
          }
        }))!;

    for (final (x, y) in [(88.5, 41.25), (150.0, 112.5), (122.25, 157.5)]) {
      horizontal.jumpTo(x);
      vertical.jumpTo(y);
      await tester.pump();
      final samples = [
        for (final button in find.byType(YumeiroButton).evaluate())
          for (final delta in const [Offset(-9, -9), Offset(9, 9)])
            if (tester.getCenter(find.byWidget(button.widget)) + delta
                case final point when _viewport.deflate(3).contains(point))
              (key: button.widget.key, point: point),
      ];
      expect(samples.length, greaterThanOrEqualTo(10));
      final points = [for (final sample in samples) sample.point];
      final scrolling = await readPixels(points);
      await tester.pumpAndSettle();
      final settled = await readPixels(points);
      // Keep the table and scroll positions fixed for the unfiltered reference.
      showActions.value = false;
      await tester.pump();
      final backdrop = await readPixels(points);
      for (var index = 0; index < samples.length; index++) {
        for (final (phase, pixels) in [
          ('scrolling', scrolling),
          ('settled', settled),
        ]) {
          final reason = '${samples[index].key} at ($x, $y), $phase';
          for (var channel = 0; channel < 3; channel++) {
            expect(
              pixels[index][channel],
              closeTo(backdrop[index][channel], 6),
              reason: reason,
            );
          }
          // The normal button fill can add a few alpha levels to the backdrop.
          expect(
            pixels[index][3],
            closeTo(backdrop[index][3], 3),
            reason: reason,
          );
        }
      }
      showActions.value = true;
      await tester.pump();
    }
  }, skip: !ui.ImageFilter.isShaderFilterSupported);
}
