import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yumeiro/yumeiro.dart';
import 'package:yumeiro_example/src/pages/overlays_page.dart';
import 'package:yumeiro_example/src/state/gallery_controller.dart';
import 'package:yumeiro_example/src/theme/gallery_registry.dart';

void main() {
  Future<void> pumpSamples(
    WidgetTester tester,
    GalleryController controller,
    YumeiroModality modality,
  ) async {
    tester.view.physicalSize = modality == YumeiroModality.touch
        ? const Size(390, 844)
        : const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ListenableBuilder(
        listenable: controller,
        builder: (_, _) => YumeiroApp(
          modality: modality,
          locale: controller.locale,
          presetId: controller.presetId,
          customizations: controller.customizations,
          advancedMotionEnabled: controller.advancedMotionEnabled,
          home: Scaffold(
            body: SingleChildScrollView(
              child: OverlaysPage(
                controller: controller,
                profile: modality == YumeiroModality.touch
                    ? GalleryProfile.mobile
                    : GalleryProfile.desktop,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapFinder(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String label) =>
      tapFinder(tester, find.text(label));

  for (final modality in YumeiroModality.values) {
    testWidgets(
      '$modality editor saves a local draft and cancellation preserves state',
      (tester) async {
        final controller = GalleryController()
          ..setCustomization('roundness', 125.0);
        addTearDown(controller.dispose);
        final initialText = controller.textController.text;
        final initialPreset = controller.presetId;
        await pumpSamples(tester, controller, modality);
        Future<void> edit(String text, String action) async {
          await tap(tester, '打开自适应编辑器');
          final editor = find.byType(YumeiroEditor);
          await tester.enterText(
            find.descendant(of: editor, matching: find.byType(TextField)),
            text,
          );
          await tester.tap(
            find.descendant(of: editor, matching: find.byType(YumeiroSwitch)),
          );
          await tester.pumpAndSettle();
          if (action == '取消') {
            await tap(tester, action);
            expect(find.text('丢弃未保存的更改？'), findsOneWidget);
            await tap(tester, '继续编辑');
            expect(
              tester
                  .widget<EditableText>(
                    find.descendant(
                      of: editor,
                      matching: find.byType(EditableText),
                    ),
                  )
                  .controller
                  .text,
              text,
            );
            await tap(tester, action);
            await tap(tester, '丢弃');
          } else {
            final save = find.widgetWithText(YumeiroButton, action);
            await tester.ensureVisible(save);
            await tester.pumpAndSettle();
            await tester.tap(save);
            await tester.pump();
            expect(tester.widget<YumeiroEditor>(editor).busy, isTrue);
            await tester.pumpAndSettle();
          }
        }

        await edit('Discarded sample', '取消');
        expect(controller.overlaySampleName, 'Example A');
        expect(controller.overlaySampleEnabled, isTrue);
        await edit('Saved sample', '保存');
        expect(controller.overlaySampleName, 'Saved sample');
        expect(controller.overlaySampleEnabled, isFalse);
        expect(controller.textController.text, initialText);
        expect(controller.presetId, initialPreset);
        expect(controller.customizations, {'roundness': 125.0});
        expect(controller.advancedMotionEnabled, isTrue);
        await tap(tester, '打开确认弹窗');
        await tap(tester, '确认');
        expect(controller.overlaySamplePresent, isFalse);
        expect(
          tester
              .widget<YumeiroButton>(
                find.widgetWithText(YumeiroButton, '打开自适应编辑器'),
              )
              .onPressed,
          isNull,
        );
        expect(
          tester
              .widget<YumeiroButton>(
                find.widgetWithText(YumeiroButton, '打开确认弹窗'),
              )
              .onPressed,
          isNull,
        );
        await tap(tester, '更多操作');
        expect(
          find.byType(YumeiroBottomSheet),
          modality == YumeiroModality.touch ? findsOneWidget : findsNothing,
        );
        expect(find.text('选项状态'), findsOneWidget);
        expect(find.text('文本操作'), findsOneWidget);
        await tap(tester, '关闭示例选项');
        expect(controller.overlaySamplePresent, isFalse);
        expect(controller.lastOverlayEventZh, '已移除示例项目。');
        expect(find.text('重置示例内容'), findsOneWidget);
        await tap(tester, '重置示例内容');
        expect(controller.overlaySamplePresent, isTrue);
        expect(controller.overlaySampleName, 'Example A');
        expect(controller.overlaySampleEnabled, isTrue);
        expect(controller.customizations, {'roundness': 125.0});
        expect(controller.presetId, initialPreset);
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets('$modality removed sample has a direct restore action', (
      tester,
    ) async {
      final controller = GalleryController()..deleteOverlaySample();
      addTearDown(controller.dispose);
      await pumpSamples(tester, controller, modality);
      if (modality == YumeiroModality.touch) {
        await tap(tester, '打开底部面板');
        expect(
          find.descendant(
            of: find.byType(YumeiroBottomSheet),
            matching: find.text('暂无示例项目'),
          ),
          findsOneWidget,
        );
        await tap(tester, '完成');
      } else {
        expect(find.text('打开底部面板'), findsNothing);
      }
      expect(find.text('示例 A'), findsNothing);
      expect(find.text('示例 B'), findsNothing);
      await tap(tester, '重置示例项目');
      expect(controller.overlaySamplePresent, isTrue);
      expect(controller.overlaySampleName, 'Example A');
      expect(controller.overlaySampleEnabled, isTrue);
      expect(controller.lastOverlayEventZh, '已重置示例内容。');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('an explicit selection sheet distinguishes clearing and cancel', (
    tester,
  ) async {
    final controller = GalleryController();
    addTearDown(controller.dispose);
    await pumpSamples(tester, controller, YumeiroModality.touch);

    final single = find.byKey(const ValueKey('gallery-open-single-sheet'));
    final multiple = find.byKey(const ValueKey('gallery-open-multiple-sheet'));
    final sheet = find.byType(YumeiroBottomSheet);
    Finder option(String letter) =>
        find.descendant(of: sheet, matching: find.text('选项 $letter'));
    final results = find.byKey(const ValueKey('gallery-multiple-sheet-result'));
    String? resultText() => tester.widget<Text>(results).data;

    await tapFinder(tester, single);
    await tapFinder(tester, option('B'));
    expect(sheet, findsNothing);
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('gallery-single-sheet-result')),
          )
          .data,
      contains('选项 B'),
    );

    await tapFinder(tester, multiple);
    final selected = tester
        .widgetList<YumeiroSelectionRow>(
          find.descendant(
            of: sheet,
            matching: find.byType(YumeiroSelectionRow),
          ),
        )
        .where((row) => row.selected)
        .map((row) => (row.title as Text).data!)
        .toList();
    for (final label in selected) {
      await tapFinder(
        tester,
        find.descendant(of: sheet, matching: find.text(label)),
      );
    }
    final confirmEmpty = YumeiroLocalizations.of(tester.element(sheet))
        .confirmWithCount(0);
    await tapFinder(
      tester,
      find.descendant(
        of: sheet,
        matching: find.widgetWithText(YumeiroButton, confirmEmpty),
      ),
    );
    expect(resultText(), '已确认空选择。');

    await tapFinder(tester, multiple);
    await tapFinder(tester, option('A'));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(resultText(), startsWith('已取消。'));
    expect(resultText(), isNot(contains('选项 A')));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final modality in YumeiroModality.values) {
    testWidgets(
      '$modality context menu copies the sample before reporting success',
      (tester) async {
        final controller = GalleryController();
        addTearDown(controller.dispose);
        String? copied;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'Clipboard.setData') {
              copied = (call.arguments as Map)['text'] as String;
            }
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          ),
        );
        await pumpSamples(tester, controller, modality);
        final region = find.byType(YumeiroContextMenuRegion);
        await tester.ensureVisible(region);
        await tester.pumpAndSettle();
        if (modality == YumeiroModality.touch) {
          await tester.longPress(region);
        } else {
          await tester.tap(
            region,
            kind: PointerDeviceKind.mouse,
            buttons: kSecondaryMouseButton,
          );
        }
        await tester.pumpAndSettle();
        expect(find.text('选项状态'), findsOneWidget);
        expect(find.text('文本操作'), findsOneWidget);
        await tap(tester, '复制示例文本');
        expect(copied, '示例 A');
        expect(controller.lastOverlayEventZh, '已复制示例文本。');
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets('removed sample cannot copy stale text from the context menu', (
    tester,
  ) async {
    final controller = GalleryController()..deleteOverlaySample();
    addTearDown(controller.dispose);
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await pumpSamples(tester, controller, YumeiroModality.pointer);
    final region = find.byType(YumeiroContextMenuRegion);
    await tester.ensureVisible(region);
    await tester.pumpAndSettle();
    await tester.tap(
      region,
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();
    await tap(tester, '复制示例文本');
    expect(copied, isNull);
    expect(controller.overlaySamplePresent, isFalse);
    expect(controller.lastOverlayEvent, isEmpty);
    await tap(tester, '重置示例内容');
    expect(controller.overlaySamplePresent, isTrue);
    expect(controller.lastOverlayEventZh, '已重置示例内容。');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('touch tooltip example opens on long press', (tester) async {
    final controller = GalleryController();
    addTearDown(controller.dispose);
    await pumpSamples(tester, controller, YumeiroModality.touch);
    final trigger = find.text('长按查看提示');
    await tester.ensureVisible(trigger);
    await tester.pumpAndSettle();
    await tester.longPress(trigger);
    await tester.pumpAndSettle();
    expect(find.text('这是一条悬浮提示示例。'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  for (final modality in YumeiroModality.values) {
    testWidgets('$modality persistent toast stays until dismissed', (
      tester,
    ) async {
      final controller = GalleryController();
      addTearDown(controller.dispose);
      await pumpSamples(tester, controller, modality);

      final show = find.widgetWithText(YumeiroButton, '显示常驻通知');
      final dismiss = find.widgetWithText(YumeiroButton, '关闭常驻通知');
      final message = find.widgetWithText(YumeiroToast, '等待手动关闭。');
      final host = YumeiroToastScope.of(tester.element(show));
      expect(tester.widget<YumeiroButton>(dismiss).onPressed, isNull);

      await tapFinder(tester, show);
      expect(message, findsOneWidget);
      expect(host.entries.single.duration, Duration.zero);
      await tester.pump(const Duration(seconds: 6));
      expect(message, findsOneWidget);

      await tapFinder(tester, dismiss);
      expect(message, findsNothing);
      expect(host.entries, isEmpty);
      expect(tester.widget<YumeiroButton>(show).onPressed, isNotNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('touch tooltip tap variant opens with its own trigger', (
    tester,
  ) async {
    final controller = GalleryController();
    addTearDown(controller.dispose);
    await pumpSamples(tester, controller, YumeiroModality.touch);
    expect(find.text('YumeiroTooltip(triggerMode: tap)'), findsOneWidget);
    await tap(tester, '点击查看提示');
    expect(find.text('这是示例 B 的提示。'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('standard confirmation records an action with a primary button', (
    tester,
  ) async {
    final controller = GalleryController();
    addTearDown(controller.dispose);
    await pumpSamples(tester, controller, YumeiroModality.pointer);
    expect(find.text('YumeiroDialog.confirm'), findsOneWidget);
    expect(
      find.text('YumeiroDialog.confirm(destructive: true)'),
      findsOneWidget,
    );
    await tap(tester, '确认示例操作');
    final confirm = find.widgetWithText(YumeiroButton, '确认');
    expect(
      tester.widget<YumeiroButton>(confirm).variant,
      YumeiroButtonVariant.primary,
    );
    await tap(tester, '确认');
    expect(controller.lastOverlayEventZh, '已应用示例操作。');
    expect(controller.overlaySamplePresent, isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  for (final modality in YumeiroModality.values) {
    testWidgets('$modality compound filter preserves the draft until Apply', (
      tester,
    ) async {
      final controller = GalleryController();
      addTearDown(controller.dispose);
      await pumpSamples(tester, controller, modality);
      await tap(tester, '打开组合筛选');
      final isTouch = modality == YumeiroModality.touch;
      expect(
        find.byType(YumeiroBottomSheet),
        isTouch ? findsOneWidget : findsNothing,
      );
      expect(
        find.byType(YumeiroDialog),
        isTouch ? findsNothing : findsOneWidget,
      );
      expect(find.byType(YumeiroCascadingSelection<String>), findsOneWidget);

      if (isTouch) {
        expect(find.text('分组 A'), findsOneWidget);
        expect(find.text('选项 A'), findsNothing);
      }
      await tap(tester, '分组 B');
      await tap(tester, '选项 D');
      expect(find.byType(YumeiroCascadingSelection<String>), findsOneWidget);
      expect(controller.overlayCascadeValue, 'render/optical');
      expect(controller.cascadeValue, 'render/optical');

      await tap(tester, '应用');
      expect(controller.overlayCascadeValue, 'theme/radii');
      expect(controller.cascadeValue, 'render/optical');
      expect(controller.lastOverlayEventZh, '已选择 2 个分类和选项 D。');
      await tap(tester, '打开组合筛选');
      await tap(tester, '重置');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(controller.overlayCascadeValue, 'theme/radii');
      expect(controller.activeCategories, {'Category A', 'Category B'});
      expect(controller.cascadeValue, 'render/optical');
      await tester.pumpWidget(const SizedBox());
    });
  }
}
