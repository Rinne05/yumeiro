import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yumeiro/yumeiro.dart';
import 'package:yumeiro_example/src/pages/controls_page.dart';
import 'package:yumeiro_example/src/pages/display_page.dart';
import 'package:yumeiro_example/src/state/gallery_controller.dart';

void main() {
  testWidgets('cover states retain the thumbnail and layout', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = GalleryController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      YumeiroApp(
        locale: const Locale('zh'),
        modality: YumeiroModality.touch,
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: DisplayPage(controller: controller),
          ),
        ),
      ),
    );
    final cover = find.byKey(const ValueKey('display-cover'));
    final thumbnail = find.byKey(const ValueKey('display-thumbnail'));
    final thumbImage = tester.widget<YumeiroArtworkImage>(thumbnail).image;

    Future<void> selectState(String label) async {
      final option = find.text(label);
      await tester.ensureVisible(option);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(option);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    await selectState('加载中');
    expect(find.text('正在加载图片'), findsOneWidget);
    expect(tester.getSize(cover), const Size(92, 138));
    await selectState('加载失败');
    expect(find.text('图片暂不可用'), findsOneWidget);
    expect(tester.getSize(cover), const Size(92, 138));
    expect(tester.getSize(thumbnail), const Size(44, 58));
    await selectState('已加载');
    expect(tester.widget<YumeiroArtworkImage>(cover).image, same(thumbImage));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final modality in YumeiroModality.values) {
    testWidgets(
      'interactive chips delete and reset only their own group in $modality',
      (tester) async {
        tester.view.physicalSize = modality == YumeiroModality.touch
            ? const Size(390, 844)
            : const Size(1000, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final controller = GalleryController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          ListenableBuilder(
            listenable: controller,
            builder: (context, _) => YumeiroApp(
              registry: controller.registry,
              preset: controller.activePreset,
              capability: YumeiroMaterialCapability.blurOnly,
              modality: modality,
              locale: controller.locale,
              home: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: YumeiroSearchScope(
                    query: controller.searchScopeQuery,
                    placeholder: '搜索',
                    onSubmitted: controller.setSearchScopeQuery,
                    child: ControlsPage(controller: controller),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        Finder chip(String tag) =>
            find.byKey(ValueKey('display-removable-$tag'));
        final fixedChip = find.byKey(const ValueKey('display-fixed-chip'));
        final denseChip = find.byKey(
          const ValueKey('display-fixed-dense-chip'),
        );
        Future<void> tap(Finder target) async {
          await tester.ensureVisible(target);
          await tester.pump(const Duration(milliseconds: 400));
          await tester.tap(target);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
        }

        Future<void> remove(String tag) async {
          await tap(
            find.descendant(
              of: chip(tag),
              matching: find.byType(YumeiroButton),
            ),
          );
          expect(chip(tag), findsNothing);
        }

        await tap(fixedChip);
        await tap(denseChip);
        expect(controller.displayChipSelected, isTrue);
        expect(controller.displayDenseChipSelected, isTrue);
        expect(controller.selectedTags, {'Tag A', 'Tag B'});
        expect(controller.multiSelectTags, {'Tag A', 'Tag B'});

        // Unselected chips still expose a real removal action.
        await remove('Tag C');
        expect(fixedChip, findsOneWidget);
        expect(tester.widget<YumeiroChip>(fixedChip).selected, isTrue);
        await remove('Tag B');
        expect(controller.selectedTags, {'Tag A'});
        await remove('Tag A');
        expect(controller.removableTags, isEmpty);
        expect(controller.selectedTags, isEmpty);
        expect(find.text('暂无标签。'), findsOneWidget);

        await tap(find.widgetWithText(YumeiroButton, '重置可移除标签'));
        expect(controller.removableTags, ['Tag A', 'Tag B', 'Tag C']);
        expect(controller.selectedTags, {'Tag A', 'Tag B'});
        for (final tag in controller.removableTags) {
          expect(chip(tag), findsOneWidget);
        }
        expect(controller.displayChipSelected, isTrue);
        expect(controller.displayDenseChipSelected, isTrue);
        expect(controller.multiSelectTags, {'Tag A', 'Tag B'});
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
