import 'dart:async';

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

void main() {
  testWidgets('artwork placeholder sizes to content while a frame is pending', (
    tester,
  ) async {
    await tester.pumpWidget(
      YumeiroApp(
        home: Scaffold(
          body: Column(
            children: [
              YumeiroArtworkImage(
                image: _PendingArtwork(),
                loading: const SizedBox(width: 80, height: 60),
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(YumeiroArtworkImage)),
      const Size(80, 60),
    );
  });

  testWidgets('poster grid budgets the rendered column gap', (tester) async {
    await tester.pumpWidget(
      YumeiroApp(
        modality: YumeiroModality.pointer,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 334,
              height: 320,
              child: YumeiroPosterGrid(
                itemCount: 2,
                itemBuilder: (_, index) => SizedBox(key: ValueKey(index)),
              ),
            ),
          ),
        ),
      ),
    );

    final first = tester.getRect(find.byKey(const ValueKey(0)));
    final second = tester.getRect(find.byKey(const ValueKey(1)));
    expect(YumeiroPosterGrid.calculateColumns(width: 334), 2);
    expect(first.width, 160);
    expect(second.top, first.top);
    expect(second.left - first.right, 14);
  });

  testWidgets('poster sliver reuses built items until layout inputs change', (
    tester,
  ) async {
    final controller = ScrollController();
    final textScale = ValueNotifier<double>(1);
    addTearDown(controller.dispose);
    addTearDown(textScale.dispose);
    const firstTileKey = ValueKey(0);
    var firstTileBuilds = 0;
    await tester.pumpWidget(
      YumeiroApp(
        modality: YumeiroModality.touch,
        builder: (context, child) => ValueListenableBuilder(
          valueListenable: textScale,
          child: child,
          builder: (context, scale, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
        ),
        home: Scaffold(
          body: CustomScrollView(
            controller: controller,
            slivers: [
              YumeiroPosterGrid.sliver(
                itemCount: 100,
                itemBuilder: (_, index) {
                  if (index == 0) firstTileBuilds++;
                  return SizedBox(key: ValueKey(index));
                },
              ),
            ],
          ),
        ),
      ),
    );

    final firstTile = find.byKey(firstTileKey);
    final initialRect = tester.getRect(firstTile);
    final initialBuilds = firstTileBuilds;
    controller.jumpTo(16);
    await tester.pump();
    expect(tester.getRect(firstTile), initialRect.translate(0, -16));
    expect(firstTileBuilds, initialBuilds);

    textScale.value = 2;
    await tester.pump();
    expect(tester.getSize(firstTile).height, greaterThan(initialRect.height));
  });

  testWidgets('poster hover changes lighting while reusing its artwork', (
    tester,
  ) async {
    await tester.pumpWidget(
      const YumeiroApp(
        modality: YumeiroModality.pointer,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 170,
              child: YumeiroMediaCard(title: 'Poster'),
            ),
          ),
        ),
      ),
    );
    final artworkFinder = find.byType(YumeiroArtworkImage);
    final highlightFinder = find.byKey(
      const ValueKey('poster-positional-highlight'),
    );
    final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await pointer.addPointer(location: const Offset(1, 1));
    final center = tester.getCenter(artworkFinder);
    await pointer.moveTo(center);
    await tester.pumpAndSettle();

    final artwork = tester.widget<YumeiroArtworkImage>(artworkFinder);
    final highlight = tester.widget<DecoratedBox>(highlightFinder).decoration;
    await pointer.moveTo(center - const Offset(20, 48));
    await tester.pump();
    expect(
      tester.widget<DecoratedBox>(highlightFinder).decoration,
      isNot(equals(highlight)),
    );
    expect(tester.widget<YumeiroArtworkImage>(artworkFinder), same(artwork));
    await pointer.removePointer();
  });
}

class _PendingArtwork extends ImageProvider<_PendingArtwork> {
  @override
  Future<_PendingArtwork> obtainKey(ImageConfiguration configuration) async =>
      this;

  @override
  ImageStreamCompleter loadImage(
    _PendingArtwork key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(Completer<ImageInfo>().future);
}
