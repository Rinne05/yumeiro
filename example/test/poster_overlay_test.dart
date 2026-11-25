import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/gestures.dart' show PointerScrollEvent;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yumeiro/yumeiro.dart';
import 'package:yumeiro_example/src/pages/display_page.dart';
import 'package:yumeiro_example/src/state/gallery_controller.dart';
import 'package:yumeiro_example/src/widgets/gallery_widgets.dart';

import 'support/gallery_presets.dart';

void main() {
  for (final modality in YumeiroModality.values) {
    testWidgets('poster play actions stay compact and centered in $modality', (
      tester,
    ) async {
      final touch = modality == YumeiroModality.touch;
      tester.view.physicalSize = touch
          ? const Size(390, 844)
          : const Size(680, 920);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final controller = GalleryController()
        ..setThemeFamily('pixel')
        ..setCapability(YumeiroMaterialCapability.blurOnly);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) => YumeiroApp(
            registry: controller.registry,
            preset: controller.activePreset,
            capability: controller.capability,
            modality: modality,
            locale: controller.locale,
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: DisplayPage(controller: controller),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      Finder example(String api) => find.byWidgetPredicate(
        (widget) => widget is GalleryComponent && widget.api == api,
      );
      final standaloneCard = example('YumeiroMediaCard');
      expect(standaloneCard, findsOneWidget);
      expect(
        find.descendant(
          of: standaloneCard,
          matching: find.byType(YumeiroMediaCard),
        ),
        findsOneWidget,
      );
      final cards = find.descendant(
        of: example('YumeiroPosterGrid.sliver'),
        matching: find.byType(YumeiroMediaCard),
      );
      for (final presetId in [
        YumeiroThemePresetIds.pixelDark,
        YumeiroThemePresetIds.pixelLight,
        YumeiroThemePresetIds.classicLight,
        YumeiroThemePresetIds.frostedGlassDark,
      ]) {
        selectGalleryPreset(controller, presetId);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(cards, findsNWidgets(GalleryController.mediaItems.length));
        for (
          var index = 0;
          index < GalleryController.mediaItems.length;
          index++
        ) {
          final card = cards.at(index);
          final action = find.descendant(
            of: card,
            matching: find.byType(YumeiroMediaPlayButton),
          );
          final artwork = find.descendant(
            of: card,
            matching: find.byType(YumeiroArtworkImage),
          );
          expect(tester.getSize(action), const Size(42, 42), reason: presetId);
          expect(
            (tester.getCenter(action) - tester.getCenter(artwork)).distance,
            lessThan(.001),
          );
        }
        expect(tester.takeException(), isNull, reason: presetId);
      }

      final standaloneGrid = find.descendant(
        of: example('YumeiroPosterGrid(shrinkWrap: false)'),
        matching: find.byType(YumeiroPosterGrid),
      );
      final gridViewport = find.descendant(
        of: standaloneGrid,
        matching: find.byType(Scrollable),
      );
      final pageViewport = find.ancestor(
        of: standaloneGrid,
        matching: find.byType(Scrollable),
      );
      await tester.ensureVisible(standaloneGrid);
      await tester.pump();
      final pagePosition = tester.state<ScrollableState>(pageViewport).position;
      final gridPosition = tester.state<ScrollableState>(gridViewport).position;
      final pageOffset = pagePosition.pixels;
      expect(gridPosition.maxScrollExtent, greaterThan(0));
      if (touch) {
        await tester.drag(gridViewport, const Offset(0, -130));
      } else {
        await tester.sendEventToBinding(
          PointerScrollEvent(
            kind: PointerDeviceKind.mouse,
            position: tester.getCenter(gridViewport),
            scrollDelta: const Offset(0, 130),
          ),
        );
      }
      await tester.pump(const Duration(milliseconds: 400));
      expect(gridPosition.pixels, greaterThan(0));
      expect(pagePosition.pixels, pageOffset);

      final firstCard = cards.first;
      final play = find.descendant(
        of: firstCard,
        matching: find.byType(YumeiroMediaPlayButton),
      );
      await tester.ensureVisible(firstCard);
      await tester.pump(const Duration(milliseconds: 400));
      if (!touch) {
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        addTearDown(mouse.removePointer);
        await mouse.addPointer(location: Offset.zero);
        await mouse.moveTo(tester.getCenter(play));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.getSize(play), const Size(42, 42));
        final artwork = find.descendant(
          of: firstCard,
          matching: find.byType(YumeiroArtworkImage),
        );
        expect(
          (tester.getCenter(play) - tester.getCenter(artwork)).distance,
          lessThan(.001),
        );
      }
      final titleCount = find.text('示例项目 01').evaluate().length;
      await tester.tap(play);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('已点击播放示例按钮。'), findsOneWidget);
      expect(find.text('示例项目 01'), findsNWidgets(titleCount));

      final artwork = tester.getRect(
        find.descendant(
          of: firstCard,
          matching: find.byType(YumeiroArtworkImage),
        ),
      );
      await tester.tapAt(
        Offset(artwork.center.dx, artwork.top + artwork.height * .25),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('示例项目 01'), findsNWidgets(titleCount + 1));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
