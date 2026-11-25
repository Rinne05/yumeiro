import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yumeiro/yumeiro.dart';
import 'package:yumeiro_example/src/state/gallery_controller.dart';

void main() {
  GalleryController createController({YumeiroThemeRegistry? registry}) {
    if (registry != null) addTearDown(registry.dispose);
    final controller = GalleryController(registry: registry);
    addTearDown(controller.dispose);
    return controller;
  }

  test(
    'initial selection resolves its family, actual mode, and preference',
    () {
      final controller = createController();
      expect(controller.activePreset, same(YumeiroThemePresets.classicDark));
      expect(controller.activeFamily!.id, 'classic');
      expect(controller.preferredVariant, YumeiroThemeVariant.dark);
      expect(controller.effectiveVariant, YumeiroThemeVariant.dark);
      expect(controller.canSelectVariant, isTrue);
    },
  );

  test(
    'changing a family resolves the preference and resets its overrides once',
    () {
      final controller = createController();
      controller.setCustomization('accent', Colors.orange);
      controller.setCustomization('roundness', 125.0);
      controller.setNavIndex(3);
      controller.setSliderValue(.2);
      var notifications = 0;
      controller.addListener(() {
        notifications++;
        expect(controller.activeFamily!.id, 'ceramic');
        expect(controller.effectiveVariant, YumeiroThemeVariant.dark);
        expect(controller.customizations, isEmpty);
      });

      controller.setThemeFamily('ceramic');
      expect(controller.presetId, YumeiroThemePresetIds.ceramicDark);
      expect(controller.preferredVariant, YumeiroThemeVariant.dark);
      expect(controller.navIndex, 3);
      expect(controller.sliderValue, .2);
      expect(notifications, 1);
      controller.setThemeFamily('ceramic');
      expect(notifications, 1);
    },
  );

  test(
    'switching modes within a family preserves customizations and accent',
    () {
      final controller = createController();
      controller.setThemeFamily('ceramic');
      controller.setCustomization('accent', Colors.teal);
      controller.setCustomization('materialHighlight', 75.0);
      final customizations = controller.customizations;
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.setPreferredVariant(YumeiroThemeVariant.light);
      expect(controller.activePreset, same(YumeiroThemePresets.ceramicLight));
      expect(controller.preferredVariant, YumeiroThemeVariant.light);
      expect(controller.effectiveVariant, YumeiroThemeVariant.light);
      expect(controller.customizations, same(customizations));
      expect(notifications, 1);
      controller.setPreferredVariant(YumeiroThemeVariant.light);
      controller.setThemeFamily('ceramic');
      expect(notifications, 1);
      expect(controller.customizations, same(customizations));

      controller.setPreferredVariant(YumeiroThemeVariant.dark);
      expect(controller.activePreset, same(YumeiroThemePresets.ceramicDark));
      expect(controller.customizations, same(customizations));
      expect(notifications, 2);
    },
  );

  test('fixed families retain the preference and report their actual mode', () {
    final controller = createController();
    controller.setThemeFamily('sketch');
    expect(controller.activePreset, same(YumeiroThemePresets.sketch));
    expect(controller.preferredVariant, YumeiroThemeVariant.dark);
    expect(controller.effectiveVariant, YumeiroThemeVariant.light);
    expect(controller.canSelectVariant, isFalse);
    controller.setThemeFamily('ceramic');
    expect(controller.activePreset, same(YumeiroThemePresets.ceramicDark));

    controller.setThemeFamily('geek');
    controller.setCustomization('outlineWidth', 2.0);
    controller.setCustomization('accent', Colors.orange);
    final customizations = controller.customizations;
    var notifications = 0;
    controller.addListener(() => notifications++);
    controller.setPreferredVariant(YumeiroThemeVariant.light);
    expect(controller.activePreset, same(YumeiroThemePresets.geek));
    expect(controller.effectiveVariant, YumeiroThemeVariant.dark);
    expect(controller.preferredVariant, YumeiroThemeVariant.light);
    expect(controller.customizations, same(customizations));
    expect(notifications, 1);
    controller.setThemeFamily('ceramic');
    expect(controller.activePreset, same(YumeiroThemePresets.ceramicLight));
    expect(controller.preferredVariant, YumeiroThemeVariant.light);
    expect(notifications, 2);
  });

  test(
    'mobile sync copies a preference change with an unchanged fixed preset',
    () {
      final source = createController();
      final target = createController();
      source.setThemeFamily('geek');
      target.setThemeFamily('geek');
      target.setNavIndex(3);
      target.setSliderValue(.17);
      source.setNavIndex(1);
      source.setSliderValue(.9);
      source.setPreferredVariant(YumeiroThemeVariant.light);
      expect(source.presetId, target.presetId);
      var notifications = 0;
      target.addListener(() => notifications++);

      target.copyDesignSettingsFrom(source);
      expect(target.preferredVariant, YumeiroThemeVariant.light);
      expect(target.effectiveVariant, YumeiroThemeVariant.dark);
      expect(target.navIndex, 3);
      expect(target.sliderValue, .17);
      expect(notifications, 1);
      target.copyDesignSettingsFrom(source);
      expect(notifications, 1);
      target.setThemeFamily('ceramic');
      expect(target.activePreset, same(YumeiroThemePresets.ceramicLight));
      expect(notifications, 2);
    },
  );

  test('unknown family selection has no side effects or notification', () {
    final controller = createController();
    controller.setCustomization('accent', Colors.orange);
    controller.setCustomization('roundness', 120.0);
    final customizations = controller.customizations;
    var notifications = 0;
    controller.addListener(() => notifications++);
    controller.setThemeFamily('does-not-exist');
    expect(controller.activePreset, same(YumeiroThemePresets.classicDark));
    expect(controller.preferredVariant, YumeiroThemeVariant.dark);
    expect(controller.customizations, same(customizations));
    expect(notifications, 0);
  });

  test('custom registries fall back to their available family and preset', () {
    final registry = YumeiroThemeRegistry.empty();
    final preset = YumeiroThemePresets.acrylicLight.copyWith(
      id: 'host.acrylic',
    );
    registry.registerPreset(preset, familyId: 'host');
    final controller = createController(registry: registry);
    expect(controller.activePreset, same(preset));
    expect(controller.activeFamily!.id, 'host');
    expect(controller.effectiveVariant, YumeiroThemeVariant.light);
    expect(controller.preferredVariant, YumeiroThemeVariant.dark);
    expect(controller.canSelectVariant, isFalse);
    controller.setThemeFamily('host');
    expect(controller.presetId, preset.id);
    expect(controller.preferredVariant, YumeiroThemeVariant.dark);
  });

  test(
    'standalone presets have an actual mode without a selectable family',
    () {
      final registry = YumeiroThemeRegistry.empty();
      final preset = YumeiroThemePresets.acrylicLight.copyWith(
        id: 'host.standalone',
      );
      registry.registerPreset(preset);
      final controller = createController(registry: registry);
      expect(controller.activePreset, same(preset));
      expect(controller.activeFamily, isNull);
      expect(controller.effectiveVariant, YumeiroThemeVariant.light);
      expect(controller.canSelectVariant, isFalse);
      controller.setPreferredVariant(YumeiroThemeVariant.light);
      expect(controller.activePreset, same(preset));
      expect(controller.preferredVariant, YumeiroThemeVariant.light);
    },
  );
}
