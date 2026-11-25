import 'dart:ui' show ColorSpace;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

const _shadowOverrides = {
  'shadow': 0,
  'shadowDistance': 50,
  'shadowSoftness': 25,
};

void main() {
  test('roundness adjusts radii using an application-defined option ID', () {
    final base = YumeiroThemePresets.classicDark;
    final preset = base.copyWith(
      customizationOptions: [
        ...base.customizationOptions,
        const YumeiroThemeNumberOption(
          id: 'app.corner',
          label: 'Corner',
          defaultValue: 100,
          adjustment: YumeiroThemeAdjustment.roundness,
        ),
      ],
    );
    final adjusted = YumeiroThemeExtension.fromPreset(
      preset: preset,
      customizations: const {'app.corner': 0},
    );
    expect(adjusted.buttonRadius, 0);
    expect(
      YumeiroThemeExtension.fromPreset(preset: preset).buttonRadius,
      base.radii.button,
    );
  });

  testWidgets('extended sRGB accents are clipped before theme transitions', (
    tester,
  ) async {
    const accent = Color.from(
      alpha: 1,
      red: 1.1,
      green: .15,
      blue: .45,
      colorSpace: ColorSpace.extendedSRGB,
    );
    late Color resolved;
    Widget app(Color color) => YumeiroApp(
      accentColor: color,
      home: Builder(
        builder: (context) {
          resolved = YumeiroTheme.of(context).accent;
          return Center(
            child: YumeiroButton(
              onPressed: () {},
              variant: YumeiroButtonVariant.primary,
              label: 'Accent',
            ),
          );
        },
      ),
    );
    await tester.pumpWidget(app(Colors.blue));
    await tester.pumpWidget(app(accent));
    await tester.pumpAndSettle();
    expect(resolved, accent.withValues(colorSpace: ColorSpace.sRGB));
    expect(tester.takeException(), isNull);
  });

  test('the accent contrast floor uses Display P3 converted to sRGB', () {
    const accent = Color.from(
      alpha: 1,
      red: .75,
      green: 139 / 255,
      blue: 1,
      colorSpace: ColorSpace.displayP3,
    );
    final colors = YumeiroThemePresets.classicLight.colors.withAccent(
      accent,
      lighten: true,
    );
    expect(colors.accent, accent);
    expect(colors.onAccent, Colors.black);
  });

  test('Display P3 accents remain valid throughout built-in theme states', () {
    const accent = Color.from(
      alpha: 1,
      red: .28,
      green: .75,
      blue: .38,
      colorSpace: ColorSpace.displayP3,
    );
    final presets = YumeiroThemePresets.builtInValues.where(
      (preset) => preset.supportsAccentCustomization,
    );

    for (final preset in presets) {
      final material = yumeiroThemeData(
        preset: preset,
        accentColor: accent,
        customizations: const {'selectionStrength': 140},
      );
      final theme = material.extension<YumeiroThemeExtension>()!;
      expect(theme.colors.accent, accent, reason: preset.id);
      final visuals = theme.visuals;
      for (final state in [WidgetState.hovered, WidgetState.pressed]) {
        final control = visuals.control(YumeiroControlRole.primary, {state});
        expect(control.background.a, greaterThan(0));
        final navigation = visuals.navigationItem({
          WidgetState.selected,
          state,
        });
        expect(navigation.labelForeground.a, greaterThan(0));
      }
      expect(visuals.customStatusFill(accent).a, 1);
    }
  });

  test('custom accent only replaces the preferred ink at extreme contrast', () {
    final light = YumeiroThemePresets.classicLight;
    final dark = YumeiroThemePresets.classicDark;
    for (final preset in [light, dark]) {
      const extreme = Color(0xFFADADAD);
      final adjusted = YumeiroThemeExtension.fromPreset(
        preset: preset,
        accentColor: extreme,
      );
      expect(adjusted.colors.accent, extreme);
      expect(adjusted.colors.onAccent, Colors.black);
      expect(
        adjusted.visuals
            .control(YumeiroControlRole.primary, const {})
            .foreground,
        Colors.black,
      );

      final muted = YumeiroThemeExtension.fromPreset(
        preset: preset,
        accentColor: const Color(0xFFA0A0A0),
      );
      expect(muted.colors.onAccent, Colors.white);
      expect(
        YumeiroThemeExtension.fromPreset(preset: preset).colors.onAccent,
        preset.colors.onAccent,
      );
    }
  });

  for (final preset in [
    YumeiroThemePresets.minimalLight,
    YumeiroThemePresets.minimalDark,
  ]) {
    test('${preset.id} preserves the inner highlight at zero shadow', () {
      YumeiroEffectStack effects(
        Map<String, Object> shadow,
        Set<WidgetState> states,
      ) => YumeiroThemeExtension.fromPreset(
        preset: preset,
        customizations: {'innerHighlight': 200, ...shadow},
      ).visuals.control(YumeiroControlRole.neutral, states).effects;

      final light = effects({}, {}).innerShadows.single;
      expect(light.color.a, .12);
      expect(effects(_shadowOverrides, {}).innerShadows.single, light);

      final pressed = effects(_shadowOverrides, {
        WidgetState.pressed,
      }).innerShadows.single;
      expect(pressed.color.a, 0);
      expect(pressed.offset, const Offset(0, .5));
      expect(pressed.blurRadius, .5);
    });
  }

  for (final preset in [
    YumeiroThemePresets.neumorphicLight,
    YumeiroThemePresets.neumorphicDark,
  ]) {
    test('${preset.id} keeps raised and recessed highlights independent', () {
      final baseline = YumeiroThemeExtension.fromPreset(preset: preset).visuals;
      final adjusted = YumeiroThemeExtension.fromPreset(
        preset: preset,
        customizations: _shadowOverrides,
      ).visuals;

      for (final role in [
        YumeiroSurfaceRole.card,
        YumeiroControlRole.neutral,
      ]) {
        final before = baseline.resolveRole(role).effects;
        final after = adjusted.resolveRole(role).effects;
        // The inset bevel places its light edge after its dark edge.
        final lightIndex = role == YumeiroSurfaceRole.card ? 0 : 1;
        expect(after.innerShadows[lightIndex], before.innerShadows[lightIndex]);
        expect(after.innerShadows[1 - lightIndex].color.a, 0);
        expect(
          after.outerShadows.whereType<YumeiroOuterHighlight>(),
          before.outerShadows.whereType<YumeiroOuterHighlight>(),
        );
      }
    });
  }

  for (final preset in [
    YumeiroThemePresets.ceramicLight,
    YumeiroThemePresets.ceramicDark,
    YumeiroThemePresets.brushedMetalLight,
    YumeiroThemePresets.brushedMetalDark,
    YumeiroThemePresets.acrylicLight,
    YumeiroThemePresets.acrylicDark,
    YumeiroThemePresets.siliconeLight,
    YumeiroThemePresets.siliconeDark,
    YumeiroThemePresets.frostedGlassLight,
    YumeiroThemePresets.frostedGlassDark,
  ]) {
    test('${preset.id} preserves material highlights while tuning shadows', () {
      YumeiroEffectStack panelEffects(Map<String, Object> customizations) =>
          YumeiroThemeExtension.fromPreset(
            preset: preset,
            customizations: customizations,
          ).visuals.surface(YumeiroSurfaceRole.panel).effects;

      final original = panelEffects({});
      final shadowless = panelEffects(_shadowOverrides);
      final unlit = panelEffects({'materialHighlight': 0});
      final light = original.innerShadows.where((s) => s.isHighlight).single;
      expect(light.color.a, greaterThan(0));
      expect(shadowless.innerShadows.where((s) => s.isHighlight).single, light);
      expect(
        shadowless.innerShadows.where((s) => !s.isHighlight),
        everyElement(predicate<YumeiroInnerShadow>((s) => s.color.a == 0)),
      );
      expect(unlit.innerShadows.where((s) => s.isHighlight), isEmpty);
      expect(
        unlit.outerShadows,
        original.outerShadows.where((s) => s is! YumeiroOuterHighlight),
      );
      expect(
        shadowless.outerShadows.whereType<YumeiroOuterHighlight>(),
        original.outerShadows.whereType<YumeiroOuterHighlight>(),
      );
      expect(shadowless.outerShadows.first.color.a, 0);
      expect(
        shadowless.outerShadows.first.offset,
        original.outerShadows.first.offset * .5,
      );
    });
  }

  test('shadow list interpolation preserves light markers and order', () {
    const depth = BoxShadow(color: Colors.black, offset: Offset(2, 2));
    const light = YumeiroOuterHighlight(
      color: Colors.white,
      offset: Offset(-2, -2),
    );
    final from = YumeiroEffectStack(outerShadows: const [depth, light]);
    final to = YumeiroEffectStack(
      outerShadows: [
        depth,
        light.copyWith(color: Colors.white54),
      ],
    );
    final blended = from.lerp(to, .5).outerShadows;
    expect(blended.first, depth);
    expect(blended.last, isA<YumeiroOuterHighlight>());
    expect(blended.last.color.a, lessThan(1));
    final fading = from.lerp(YumeiroEffectStack.none, .5).outerShadows;
    expect(fading.last, isA<YumeiroOuterHighlight>());
    expect(fading.last.offset, const Offset(-1, -1));
  });
}
