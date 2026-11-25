import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';
import 'package:yumeiro_example/src/state/gallery_controller.dart';
import 'package:yumeiro_example/src/widgets/gallery_widgets.dart';

import 'support/gallery_presets.dart';

void main() {
  for (final (preset, defaultPanel) in [
    (YumeiroThemePresets.neoBrutalistLight, const Color(0xFFFF9B91)),
    (YumeiroThemePresets.siliconeLight, const Color(0xFFE5D8ED)),
  ]) {
    testWidgets('${preset.id} gallery panel can be recolored and reset', (
      tester,
    ) async {
      final controller = GalleryController();
      selectGalleryPreset(controller, preset.id);
      addTearDown(controller.dispose);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1100, 900);
      addTearDown(tester.view.reset);
      final panelKey = GlobalKey();

      await tester.pumpWidget(
        ListenableBuilder(
          listenable: controller,
          builder: (_, _) => YumeiroApp(
            preset: controller.activePreset,
            locale: const Locale('zh'),
            customizations: controller.customizations,
            home: Scaffold(
              body: SingleChildScrollView(
                child: RepaintBoundary(
                  key: panelKey,
                  child: GalleryCard(
                    title: 'Preset customization',
                    child: GalleryPresetOptionsEditor(
                      preset: controller.activePreset,
                      controller: controller,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      Future<Color> panelPixel() async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(panelKey),
        );
        final pixel = await tester.runAsync(() async {
          final image = await boundary.toImage();
          try {
            final bytes = (await image.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            ))!;
            // Sample inside the border and outside the card content.
            final offset = (12 * image.width + 12) * 4;
            return Color.fromARGB(
              bytes.getUint8(offset + 3),
              bytes.getUint8(offset),
              bytes.getUint8(offset + 1),
              bytes.getUint8(offset + 2),
            );
          } finally {
            image.dispose();
          }
        });
        return pixel!;
      }

      const sky = Color(0xFF0EA5E9);
      final originalPixel = await panelPixel();
      controller.setCustomization('backgroundTone', '#F9F0BB');
      await tester.pumpAndSettle();
      expect(await panelPixel(), originalPixel);

      final picker = find.descendant(
        of: find.ancestor(
          of: find.text('面板底色'),
          matching: find.byType(YumeiroSettingRow),
        ),
        matching: find.byType(YumeiroColorPickerButton),
      );
      expect(
        tester.widget<YumeiroColorPickerButton>(picker).defaultColor,
        defaultPanel,
      );
      await tester.tap(picker);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Sky'));
      await tester.pumpAndSettle();
      expect(controller.customizations['panelColor'], sky);
      expect(await panelPixel(), isNot(originalPixel));

      await tester.tap(find.byTooltip('预设默认'));
      await tester.pumpAndSettle();
      expect(controller.customizations, {'backgroundTone': '#F9F0BB'});
      expect(await panelPixel(), originalPixel);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('material border picker distinguishes preset and custom colors', (
    tester,
  ) async {
    final controller = GalleryController();
    selectGalleryPreset(controller, YumeiroThemePresetIds.ceramicLight);
    addTearDown(controller.dispose);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1100, 900);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ListenableBuilder(
        listenable: controller,
        builder: (_, _) => YumeiroApp(
          preset: controller.activePreset,
          customizations: controller.customizations,
          home: Scaffold(
            body: SingleChildScrollView(
              child: GalleryPresetOptionsEditor(
                preset: controller.activePreset,
                controller: controller,
              ),
            ),
          ),
        ),
      ),
    );
    const l10n = YumeiroLocalizationsEn();
    final picker = find.descendant(
      of: find.ancestor(
        of: find.text(l10n.optionBorderColor),
        matching: find.byType(YumeiroSettingRow),
      ),
      matching: find.byType(YumeiroColorPickerButton),
    );
    Color panelBorder() =>
        YumeiroTheme.of(tester.element(picker)).visuals
            .surface(YumeiroSurfaceRole.panel)
            .outline
            .color;
    final original = panelBorder();
    expect(original.toARGB32(), 0xFFFCFAF6);
    expect(
      tester.widget<YumeiroColorPickerButton>(picker).showDefaultSwatch,
      isFalse,
    );
    expect(find.text(l10n.optionPresetBorder), findsOneWidget);

    await tester.tap(picker);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Sky'));
    await tester.pumpAndSettle();
    expect(panelBorder(), const Color(0xFF0EA5E9));
    await tester.tap(find.byTooltip(l10n.optionPresetBorder));
    await tester.pumpAndSettle();
    expect(controller.customizations, isEmpty);
    expect(panelBorder(), original);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('color option editors accept the same values as theme recipes', (
    tester,
  ) async {
    final controller = GalleryController()..setThemeFamily('sketch');
    addTearDown(controller.dispose);
    final option = controller.activePreset.options
        .whereType<YumeiroThemeColorOption>()
        .firstWhere((option) => option.id == 'shadowColor');
    await tester.pumpWidget(
      ListenableBuilder(
        listenable: controller,
        builder: (_, _) => YumeiroApp(
          preset: controller.activePreset,
          locale: const Locale('zh'),
          customizations: controller.customizations,
          home: Scaffold(
            body: SingleChildScrollView(
              child: GalleryPresetOptionsEditor(
                preset: controller.activePreset,
                controller: controller,
              ),
            ),
          ),
        ),
      ),
    );
    final row = find.byWidgetPredicate(
      (widget) =>
          widget is YumeiroSettingRow &&
          widget.title == option.resolveLabel(const YumeiroLocalizationsZh()),
    );
    final picker = find.descendant(
      of: row,
      matching: find.byType(YumeiroColorPickerButton),
    );
    for (final (value, expected) in <(Object, Color)>[
      ('#123456', const Color(0xFF123456)),
      (0xFF654321, const Color(0xFF654321)),
      (const Color(0xFF336699), const Color(0xFF336699)),
      ('invalid', option.defaultValue),
    ]) {
      controller.setCustomization(option.id, value);
      await tester.pumpAndSettle();
      expect(tester.widget<YumeiroColorPickerButton>(picker).value, expected);
      expect(tester.takeException(), isNull);
    }
    controller.clearCustomization(option.id);
    await tester.pumpAndSettle();
    expect(tester.widget<YumeiroColorPickerButton>(picker).value, isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
