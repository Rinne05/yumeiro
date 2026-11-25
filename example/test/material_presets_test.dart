import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yumeiro/yumeiro.dart';
import 'package:yumeiro_example/main.dart';
import 'package:yumeiro_example/src/shell/gallery_shell.dart';
import 'package:yumeiro_example/src/state/gallery_controller.dart';
import 'package:yumeiro_example/src/widgets/gallery_backdrop.dart';
import 'package:yumeiro_example/src/widgets/gallery_widgets.dart';
import 'package:yumeiro_example/src/widgets/materials_demo.dart';

import 'support/gallery_presets.dart';

void main() {
  const lightLabels = {
    YumeiroThemePresetIds.neumorphicLight: '新拟态 · 浅色',
    YumeiroThemePresetIds.ceramicLight: '釉面陶瓷 · 浅色',
    YumeiroThemePresetIds.brushedMetalLight: '拉丝金属 · 浅色',
    YumeiroThemePresetIds.neoBrutalistLight: '新粗野主义 · 浅色',
    YumeiroThemePresetIds.pixelLight: '复古像素 · 浅色',
    YumeiroThemePresetIds.acrylicLight: '磨砂亚克力 · 浅色',
    YumeiroThemePresetIds.siliconeLight: '软硅胶 · 浅色',
    YumeiroThemePresetIds.frostedGlassLight: '厚磨砂玻璃 · 浅色',
  };
  const darkLabels = {
    YumeiroThemePresetIds.neumorphicDark: '新拟态 · 深色',
    YumeiroThemePresetIds.ceramicDark: '釉面陶瓷 · 深色',
    YumeiroThemePresetIds.brushedMetalDark: '拉丝金属 · 深色',
    YumeiroThemePresetIds.neoBrutalistDark: '新粗野主义 · 深色',
    YumeiroThemePresetIds.pixelDark: '复古像素 · 深色',
    YumeiroThemePresetIds.acrylicDark: '磨砂亚克力 · 深色',
    YumeiroThemePresetIds.siliconeDark: '软硅胶 · 深色',
    YumeiroThemePresetIds.frostedGlassDark: '厚磨砂玻璃 · 深色',
  };
  const labels = {...lightLabels, ...darkLabels};

  test('gallery exposes material variants and distinguishes optical glass', () {
    final controller = GalleryController();
    addTearDown(controller.dispose);
    const zh = YumeiroLocalizationsZh();
    const en = YumeiroLocalizationsEn();

    for (final entry in labels.entries) {
      final preset = controller.registry.presetById(entry.key);
      expect(preset.id, entry.key);
      final isDark = darkLabels.containsKey(entry.key);
      expect(preset.brightness, isDark ? Brightness.dark : Brightness.light);
      expect(preset.resolveLabel(zh), entry.value);
      final family = controller.registry.familyForPreset(preset)!;
      expect(family.resolveLabel(zh), entry.value.split(' · ').first);
      expect(family.variants, hasLength(2));
      expect(family.defaultVariant, YumeiroThemeVariant.light);
      expect(
        preset.resolveLabel(en),
        endsWith(isDark ? ' · Dark' : ' · Light'),
      );
      selectGalleryPreset(controller, entry.key);
      expect(controller.isLiquidGlassPreset, isFalse);
      expect(
        controller.isOpticalGlassPreset,
        entry.key == YumeiroThemePresetIds.frostedGlassLight ||
            entry.key == YumeiroThemePresetIds.frostedGlassDark,
      );
    }

    for (final presetId in [
      YumeiroThemePresetIds.liquidGlassDark,
      YumeiroThemePresetIds.liquidGlassLight,
    ]) {
      selectGalleryPreset(controller, presetId);
      expect(controller.isLiquidGlassPreset, isTrue);
      expect(controller.isOpticalGlassPreset, isTrue);
    }
  });

  test('variant labels follow the localized family name', () {
    const host = _HostVariantLabels();
    expect(
      host.resolvePresetLabel('yumeiro.ceramic', ''),
      'Host ceramic · Light',
    );
    expect(
      host.resolvePresetLabel('yumeiro.ceramic.dark', ''),
      'Host ceramic · Dark',
    );
    const hostZh = _HostVariantLabelsZh();
    expect(hostZh.resolvePresetLabel('yumeiro.neumorphic', ''), '自定义拟态 · 浅色');
    expect(
      hostZh.resolvePresetLabel('yumeiro.neumorphic.dark', ''),
      '自定义拟态 · 深色',
    );
  });

  testWidgets('family cards preview modes while keeping artwork local', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = GalleryController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(YumeiroGalleryMobileApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('主题风格与外观模式'), findsOneWidget);
    _expectCardPreviews(tester, controller.preferredVariant);

    for (final (family, variant) in [
      ('liquid-glass', YumeiroThemeVariant.light),
      ('liquid-glass', YumeiroThemeVariant.dark),
      ('frosted-glass', YumeiroThemeVariant.dark),
      ('ceramic', YumeiroThemeVariant.light),
    ]) {
      await _tapFamily(tester, family);
      await _tapVariant(tester, variant);
      final preset = controller.registry.familyById(family)!.resolve(variant);
      expect(controller.activePreset, same(preset));
      expect(
        find.text(preset.resolveLabel(const YumeiroLocalizationsZh())),
        findsNWidgets(2),
      );
      _expectCardPreviews(tester, variant);
      expect(find.byType(GalleryBackdrop), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(GalleryMaterialsDemo),
          matching: find.byType(GalleryBackdrop),
        ),
        findsOneWidget,
      );
      expect(
        find.text('厚磨砂玻璃降级模拟'),
        family == 'frosted-glass' ? findsOneWidget : findsNothing,
      );
      expect(
        find.text('液态玻璃降级模拟'),
        family == 'liquid-glass' ? findsOneWidget : findsNothing,
      );
    }

    final header = find.byType(YumeiroPageHeader);
    expect(header, findsOneWidget);
    expect(
      find.ancestor(of: header, matching: find.byType(GalleryBackdrop)),
      findsNothing,
    );

    for (var page = 1; page < 5; page++) {
      controller.setNavIndex(page);
      // Display samples include continuously animated loading indicators.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(GalleryMaterialsDemo), findsNothing);
      expect(find.byType(GalleryBackdrop), findsNothing);
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'fixed styles disable mode selection and restore the preference',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final controller = GalleryController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(YumeiroGalleryMobileApp(controller: controller));
      await tester.pumpAndSettle();

      await _tapVariant(tester, YumeiroThemeVariant.light);
      await _tapFamily(tester, 'geek');
      expect(_modeWidget(tester).value, YumeiroThemeVariant.dark);
      expect(_modeWidget(tester).onChanged, isNull);
      expect(find.text('固定深色'), findsAtLeastNWidgets(1));
      await _tapFamily(tester, 'classic');
      expect(controller.presetId, YumeiroThemePresetIds.classicLight);
      expect(_modeWidget(tester).onChanged, isNotNull);

      await _tapVariant(tester, YumeiroThemeVariant.dark);
      await _tapFamily(tester, 'sketch');
      expect(_modeWidget(tester).value, YumeiroThemeVariant.light);
      expect(_modeWidget(tester).onChanged, isNull);
      expect(find.text('固定浅色'), findsAtLeastNWidgets(1));
      await _tapFamily(tester, 'ceramic');
      expect(controller.presetId, YumeiroThemePresetIds.ceramicDark);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'desktop mode preference syncs without changing mobile navigation',
    (tester) async {
      tester.view.physicalSize = const Size(1700, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        const YumeiroGalleryDesktopApp(initialShowMobilePreview: true),
      );
      await tester.pumpAndSettle();
      final desktop = find.byWidgetPredicate(
        (widget) =>
            widget is GalleryShellPage &&
            widget.profile == GalleryProfile.desktop,
      );
      final mobile = find.byWidgetPredicate(
        (widget) =>
            widget is GalleryShellPage &&
            widget.profile == GalleryProfile.mobile,
      );
      final source = tester.widget<GalleryShellPage>(desktop).controller;
      final target = tester.widget<GalleryShellPage>(mobile).controller;
      expect(identical(source, target), isFalse);

      await _tapVariant(tester, YumeiroThemeVariant.light, root: desktop);
      await _tapFamily(tester, 'geek', root: desktop);
      expect(source.preferredVariant, YumeiroThemeVariant.light);
      expect(target.preferredVariant, YumeiroThemeVariant.light);
      // Independently select the same fixed style on mobile with a dark preference.
      await _tapFamily(tester, 'classic', root: mobile);
      await _tapVariant(tester, YumeiroThemeVariant.dark, root: mobile);
      await _tapFamily(tester, 'geek', root: mobile);
      expect(target.presetId, source.presetId);
      expect(target.preferredVariant, YumeiroThemeVariant.dark);
      await _tapVisible(
        tester,
        find.descendant(of: mobile, matching: find.text('交互控件')),
      );
      // A desktop settings change must resync preference even though the active
      // fixed preset is identical on both sides.
      await _tapVisible(
        tester,
        find.descendant(of: desktop, matching: find.text('EN')),
      );
      expect(target.presetId, YumeiroThemePresetIds.geek);
      expect(target.preferredVariant, YumeiroThemeVariant.light);
      expect(target.navIndex, 1);
      expect(source.navIndex, 0);

      await _tapFamily(tester, 'frosted-glass', root: desktop);
      expect(source.presetId, YumeiroThemePresetIds.frostedGlassLight);
      expect(target.presetId, YumeiroThemePresetIds.frostedGlassLight);
      await _tapVariant(tester, YumeiroThemeVariant.dark, root: desktop);
      source.setCapability(YumeiroMaterialCapability.blurOnly);
      source.setCustomization('materialBlur', 36.0);
      await tester.pumpAndSettle();
      for (final shell in [desktop, mobile]) {
        final context = tester.element(shell);
        expect(
          YumeiroTheme.of(context).presetId,
          YumeiroThemePresetIds.frostedGlassDark,
        );
        expect(Theme.of(context).brightness, Brightness.dark);
      }
      expect(target.isOpticalGlassPreset, isTrue);
      expect(target.capability, YumeiroMaterialCapability.blurOnly);
      expect(target.customizations, {'materialBlur': 36.0});
      expect(target.navIndex, 1);
      await _tapVariant(tester, YumeiroThemeVariant.light, root: desktop);
      for (final shell in [desktop, mobile]) {
        final context = tester.element(shell);
        expect(
          YumeiroTheme.of(context).presetId,
          YumeiroThemePresetIds.frostedGlassLight,
        );
        expect(Theme.of(context).brightness, Brightness.light);
      }
      expect(target.preferredVariant, YumeiroThemeVariant.light);
      expect(target.customizations, {'materialBlur': 36.0});
      expect(target.navIndex, 1);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('mobile app applies the available custom registry preset', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final registry = YumeiroThemeRegistry.empty()
      ..registerPreset(YumeiroThemePresets.ceramicLight, familyId: 'host.only');
    addTearDown(registry.dispose);
    final controller = GalleryController(registry: registry);
    addTearDown(controller.dispose);
    await tester.pumpWidget(YumeiroGalleryMobileApp(controller: controller));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(GalleryShellPage));
    expect(controller.activePreset.id, YumeiroThemePresetIds.ceramicLight);
    expect(YumeiroTheme.of(context).presetId, controller.activePreset.id);
    expect(Theme.of(context).brightness, Brightness.light);
    expect(find.byType(GalleryPresetCard), findsOneWidget);
    expect(_modeWidget(tester).value, YumeiroThemeVariant.light);
    expect(_modeWidget(tester).onChanged, isNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('mixed material example keeps its ceramic action interactive', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const YumeiroApp(
        modality: YumeiroModality.touch,
        locale: Locale('zh'),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: GalleryMaterialsDemo(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('YumeiroMaterials.brushedMetal'), findsOneWidget);
    expect(find.text('YumeiroMaterials.acrylic'), findsOneWidget);
    expect(find.text('YumeiroMaterials.ceramic'), findsOneWidget);
    await tester.tap(find.text('示例 A'));
    await tester.pumpAndSettle();
    expect(find.text('已选中'), findsOneWidget);
    await tester.tap(find.text('已选中'));
    await tester.pumpAndSettle();
    expect(find.text('示例 A'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _HostVariantLabels extends YumeiroLocalizationsEn {
  const _HostVariantLabels();

  @override
  String get familyCeramic => 'Host ceramic';
}

class _HostVariantLabelsZh extends YumeiroLocalizationsZh {
  const _HostVariantLabelsZh();

  @override
  String get familyNeumorphic => '自定义拟态';
}

Finder _within(Finder finder, Finder? root) =>
    root == null ? finder : find.descendant(of: root, matching: finder);

Finder _modeFinder({Finder? root}) =>
    _within(find.byKey(const ValueKey('theme-appearance-mode')), root);

YumeiroSegmentedControl<YumeiroThemeVariant> _modeWidget(
  WidgetTester tester, {
  Finder? root,
}) => tester.widget<YumeiroSegmentedControl<YumeiroThemeVariant>>(
  _modeFinder(root: root),
);

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _tapFamily(WidgetTester tester, String familyId, {Finder? root}) =>
    _tapVisible(
      tester,
      _within(find.byKey(ValueKey('theme-family-$familyId')), root),
    );

Future<void> _tapVariant(
  WidgetTester tester,
  YumeiroThemeVariant variant, {
  Finder? root,
}) {
  final mode = _modeWidget(tester, root: root);
  expect(mode.onChanged, isNotNull);
  final label = mode.options
      .singleWhere((option) => option.value == variant)
      .label!;
  return _tapVisible(
    tester,
    find.descendant(
      of: _modeFinder(root: root),
      matching: find.text(label),
    ),
  );
}

void _expectCardPreviews(WidgetTester tester, YumeiroThemeVariant preference) {
  final cards = tester
      .widgetList<GalleryPresetCard>(find.byType(GalleryPresetCard))
      .toList();
  expect(cards, hasLength(14));
  expect(cards.where((card) => card.selected), hasLength(1));
  for (final card in cards) {
    final preview = card.family.resolve(preference);
    expect(card.preset.id, preview.id);
    final swatches = tester
        .widgetList<Container>(
          find.descendant(
            of: find.byWidget(card),
            matching: find.byType(Container),
          ),
        )
        .map((container) => container.decoration)
        .whereType<BoxDecoration>()
        .where((decoration) => decoration.shape == BoxShape.circle)
        .map((decoration) => decoration.color)
        .toList();
    expect(swatches, [
      preview.colors.background,
      preview.colors.surface,
      preview.colors.accent,
      preview.colors.accentSoft,
    ], reason: '${card.family.id} palette must preview $preference');
  }
}
