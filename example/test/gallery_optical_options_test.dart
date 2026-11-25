import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';
import 'package:yumeiro_example/main_mobile.dart';
import 'package:yumeiro_example/src/state/gallery_controller.dart';
import 'package:yumeiro_example/src/widgets/gallery_widgets.dart';

void main() {
  const l10n = YumeiroLocalizationsZh();

  testWidgets('mobile theme sliders fit a narrow screen with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const YumeiroGalleryMobileApp());
    await tester.pumpAndSettle();

    final sliders = find.byType(YumeiroSliderInput);
    expect(sliders, findsWidgets);
    expect(
      MediaQuery.textScalerOf(tester.element(sliders.first)).scale(12),
      24,
    );
    expect(tester.takeException(), isNull);
  });

  if (const bool.fromEnvironment('YUMEIRO_REQUIRE_OPTICAL')) {
    test('the Impeller test runner supports optical shader filters', () {
      expect(
        YumeiroMaterialCapability.fullOptical.resolveForRuntime(),
        YumeiroMaterialCapability.fullOptical,
      );
    });
  }

  Future<GalleryController> pumpOptions(
    WidgetTester tester,
    YumeiroThemePreset preset,
  ) async {
    final controller = GalleryController()
      ..setCapability(YumeiroMaterialCapability.blurOnly);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      ListenableBuilder(
        listenable: controller,
        builder: (context, child) => YumeiroApp(
          locale: const Locale('zh'),
          capability: controller.capability,
          home: Scaffold(
            body: SingleChildScrollView(
              child: GalleryPresetOptionsEditor(
                preset: preset,
                controller: controller,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  YumeiroSliderInput slider(WidgetTester tester, String label) =>
      tester.widget(find.widgetWithText(YumeiroSliderInput, label));

  for (final preset in [
    YumeiroThemePresets.liquidGlassLight,
    YumeiroThemePresets.liquidGlassDark,
  ]) {
    test('${preset.id} tint default matches the actual material recipe', () {
      final tint = preset.options
          .whereType<YumeiroThemeNumberOption>()
          .singleWhere((option) => option.id == 'glassOpacity');
      final standard = YumeiroThemeExtension.fromPreset(preset: preset);
      final configured = YumeiroThemeExtension.fromPreset(
        preset: preset,
        customizations: {tint.id: tint.defaultValue},
      );
      final panel = standard.visuals.surface(YumeiroSurfaceRole.panel);
      expect(tint.defaultValue, 1.5);
      expect(panel.background.a, closeTo(tint.defaultValue / 100, .0001));
      expect(
        configured.visuals.surface(YumeiroSurfaceRole.panel).background,
        panel.background,
      );
    });
  }

  testWidgets('liquid glass editors follow the effective optical capability', (
    tester,
  ) async {
    final controller = await pumpOptions(
      tester,
      YumeiroThemePresets.liquidGlassLight,
    );
    final effectiveOptics =
        YumeiroMaterialCapability.fullOptical.resolveForRuntime() ==
        YumeiroMaterialCapability.fullOptical;
    final opticalSliders = [
      l10n.optionGlassRefraction,
      l10n.optionGlassEdgeThickness,
      l10n.optionHighlightScale,
      l10n.optionActionOpacity,
    ];
    final lighting = find.descendant(
      of: find.widgetWithText(YumeiroSettingRow, l10n.optionGlassLighting),
      matching: find.byType(YumeiroSwitch),
    );
    for (final label in opticalSliders) {
      expect(slider(tester, label).enabled, isFalse, reason: label);
    }
    expect(tester.widget<YumeiroSwitch>(lighting).onChanged, isNull);
    expect(
      find.text(l10n.optionActionOpacityFallbackDescription),
      findsOneWidget,
    );
    expect(
      slider(tester, l10n.optionGlassOpacity),
      isA<YumeiroSliderInput>()
          .having((slider) => slider.enabled, 'enabled', isTrue)
          .having((slider) => slider.value, 'value', 1.5)
          .having((slider) => slider.decimalPlaces, 'decimal places', 1),
    );
    expect(
      find.text(l10n.optionGlassOpacityFallbackDescription),
      findsOneWidget,
    );
    final tintRow = find.widgetWithText(
      YumeiroSliderInput,
      l10n.optionGlassOpacity,
    );
    final tintField = find.descendant(
      of: tintRow,
      matching: find.byType(EditableText),
    );
    expect(tester.widget<EditableText>(tintField).controller.text, '1.5');
    controller.setCustomization('glassOpacity', 2.0);
    await tester.pumpAndSettle();
    final resetTint = find.descendant(
      of: tintRow,
      matching: find.byType(YumeiroButton),
    );
    await tester.ensureVisible(resetTint);
    await tester.tap(resetTint);
    await tester.pumpAndSettle();
    expect(controller.customizations, isNot(contains('glassOpacity')));
    expect(tester.widget<EditableText>(tintField).controller.text, '1.5');

    controller.setCustomization('refraction', 132.0);
    controller.setCapability(YumeiroMaterialCapability.fullOptical);
    await tester.pumpAndSettle();
    for (final label in opticalSliders) {
      expect(slider(tester, label).enabled, effectiveOptics, reason: label);
    }
    expect(slider(tester, l10n.optionGlassRefraction).value, 132);
    if (effectiveOptics) {
      controller.setCustomization('glassLighting', false);
      await tester.pumpAndSettle();
      expect(slider(tester, l10n.optionHighlightScale).enabled, isFalse);
      expect(find.text(l10n.optionRimLightDisabledDescription), findsOneWidget);
    }
  });

  testWidgets(
    'frosted glass keeps its blur and decorative highlight controls',
    (tester) async {
      await pumpOptions(tester, YumeiroThemePresets.frostedGlassLight);
      expect(slider(tester, l10n.optionGlassRefraction).enabled, isFalse);
      expect(slider(tester, l10n.optionGlassEdgeThickness).enabled, isFalse);
      expect(slider(tester, l10n.optionHighlightScale).enabled, isTrue);
      expect(slider(tester, l10n.optionBackdropBlur).enabled, isTrue);
      expect(slider(tester, l10n.optionMaterialOpacity).enabled, isTrue);
    },
  );
}
