import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yumeiro/yumeiro.dart';

double _contrast(Color first, Color second) {
  final a = first.computeLuminance();
  final b = second.computeLuminance();
  return (math.max(a, b) + .05) / (math.min(a, b) + .05);
}

void main() {
  test('custom slider theme builders receive resolved preset parameters', () {
    final preset = YumeiroThemePresets.classicLight.copyWith(
      sliderThemeBuilder: (colors, typography, {required parameters}) =>
          SliderThemeData(
            activeTrackColor: colors.accent,
            trackHeight: parameters['selectionStrength'] == 55 ? 7 : 3,
          ),
    );
    final defaultTheme = YumeiroThemeExtension.fromPreset(preset: preset);
    final customizedTheme = YumeiroThemeExtension.fromPreset(
      preset: preset,
      customizations: const {'selectionStrength': 55},
    );
    expect(defaultTheme.sliderTheme.trackHeight, 3);
    expect(customizedTheme.sliderTheme.trackHeight, 7);
  });

  test('built-in glass customization options are read-only', () {
    expect(
      () => yumeiroGlassOptions[0] = yumeiroGlassOptions.first,
      throwsUnsupportedError,
    );
  });

  test('cached themes expose immutable generated gradient and font lists', () {
    const fontConfig = YumeiroFontConfig(fontFamily: 'Host Sans');
    for (final preset in [
      YumeiroThemePresets.ceramicLight,
      YumeiroThemePresets.brushedMetalLight,
      YumeiroThemePresets.siliconeLight,
    ]) {
      final theme = yumeiroThemeData(preset: preset, fontConfig: fontConfig);
      final tokens = theme.extension<YumeiroThemeExtension>()!;
      final card = tokens.visuals.surface(YumeiroSurfaceRole.card);
      final fill = card.fill as YumeiroGradientFill;
      final colors = fill.gradient.colors;
      final fallback =
          tokens.typography.textTheme.bodyMedium!.fontFamilyFallback!;
      expect(() => colors[0] = Colors.pink, throwsUnsupportedError);
      expect(() => fallback[0] = 'Other Font', throwsUnsupportedError);
      expect(
        yumeiroThemeData(preset: preset, fontConfig: fontConfig),
        same(theme),
      );
    }
  });

  test('Material error labels stay readable across all built-in presets', () {
    for (final preset in YumeiroThemePresets.builtInValues) {
      final scheme = yumeiroThemeData(preset: preset).colorScheme;
      expect(
        _contrast(scheme.onError, scheme.error),
        greaterThanOrEqualTo(4.5),
        reason: preset.id,
      );
    }
  });

  test(
    'built-in card surfaces distinguish selection without changing shape',
    () {
      for (final preset in YumeiroThemePresets.builtInValues) {
        final theme = YumeiroThemeExtension.fromPreset(preset: preset);
        final idle = theme.visuals.surface(YumeiroSurfaceRole.card);
        final selected = theme.visuals.surface(YumeiroSurfaceRole.card, {
          WidgetState.selected,
        });
        expect(selected.background, isNot(idle.background), reason: preset.id);
        expect(selected.shape, idle.shape, reason: preset.id);
      }
    },
  );

  test('navigation stays readable in built-in interaction states', () {
    for (final preset in YumeiroThemePresets.builtInValues) {
      final theme = YumeiroThemeExtension.fromPreset(preset: preset);
      final visuals = theme.visuals;
      final sidebar = Color.alphaBlend(
        visuals.surface(YumeiroSurfaceRole.navigation).background,
        theme.colors.background,
      );
      final panel = Color.alphaBlend(
        visuals.surface(YumeiroSurfaceRole.panel).background,
        theme.colors.background,
      );
      for (final states in <Set<WidgetState>>[
        {WidgetState.focused},
        {WidgetState.hovered},
        {WidgetState.pressed},
        {WidgetState.selected},
        {WidgetState.selected, WidgetState.hovered},
        {WidgetState.selected, WidgetState.pressed},
      ]) {
        final navigation = visuals.navigationItem(states);
        final row = visuals.item(YumeiroItemRole.navigation, states);
        final rowFill = Color.alphaBlend(row.background, sidebar);
        final tabFill = Color.alphaBlend(
          navigation.topSurface.background,
          panel,
        );
        final reason = '${preset.id} $states';
        expect(
          _contrast(navigation.iconForeground, rowFill),
          greaterThanOrEqualTo(3),
          reason: '$reason sidebar icon',
        );
        expect(
          _contrast(navigation.labelForeground, rowFill),
          greaterThanOrEqualTo(4.5),
          reason: '$reason sidebar label',
        );
        expect(
          _contrast(navigation.topSurface.foreground, tabFill),
          greaterThanOrEqualTo(4.5),
          reason: '$reason tab label',
        );
      }
    }
  });

  test(
    'dark graphic navigation keeps contrast after selection fill changes',
    () {
      for (final preset in [
        YumeiroThemePresets.neoBrutalistDark,
        YumeiroThemePresets.pixelDark,
      ]) {
        for (final strength in [40, 55, 100, 180]) {
          final theme = YumeiroThemeExtension.fromPreset(
            preset: preset,
            customizations: {'selectionStrength': strength},
          );
          final visuals = theme.visuals;
          final sidebar = Color.alphaBlend(
            visuals.surface(YumeiroSurfaceRole.navigation).background,
            theme.background,
          );
          for (final states in <Set<WidgetState>>[
            {WidgetState.selected},
            {WidgetState.selected, WidgetState.hovered},
            {WidgetState.selected, WidgetState.pressed},
          ]) {
            final item = visuals.navigationItem(states);
            for (final (selectionFill, label, icon) in [
              (
                visuals.item(YumeiroItemRole.navigation, states).background,
                item.labelForeground,
                item.iconForeground,
              ),
              (
                item.destinationIndicator!.background,
                item.destinationForeground ?? item.iconForeground,
                item.destinationForeground ?? item.iconForeground,
              ),
            ]) {
              final background = Color.alphaBlend(selectionFill, sidebar);
              expect(
                _contrast(label, background),
                greaterThanOrEqualTo(4.5),
                reason: '${preset.id}/$strength/$states',
              );
              expect(_contrast(icon, background), greaterThanOrEqualTo(3));
            }
            if (strength == 100) {
              expect(item.labelForeground, theme.colors.onAccent);
            }
            final button = visuals.control(
              YumeiroControlRole.secondary,
              states,
            );
            expect(
              _contrast(button.foreground, button.background),
              greaterThanOrEqualTo(4.5),
              reason: '${preset.id}/$strength/$states selected button',
            );
          }
        }
      }
    },
  );

  test('Geek custom borders preserve accent states', () {
    const outline = Color(0xFFFF6677);
    final theme = YumeiroThemeExtension.fromPreset(
      preset: YumeiroThemePresets.geek,
      customizations: const {'borderColor': outline, 'outline': 120},
    );
    final visuals = theme.visuals;
    final neutral = visuals.control(YumeiroControlRole.neutral, const {});
    expect(neutral.outline.color.withValues(alpha: 1), outline);
    for (final states in <Set<WidgetState>>[
      {WidgetState.hovered},
      {WidgetState.selected},
      {WidgetState.focused},
    ]) {
      final active = visuals.control(YumeiroControlRole.neutral, states);
      expect(active.border.color.withValues(alpha: 1), theme.accent);
    }
    expect(
      visuals
          .control(YumeiroControlRole.primary, const {})
          .outline
          .color
          .withValues(alpha: 1),
      theme.accent,
    );
  });

  test(
    'Sketch keeps hard shadows and customizes only the resting checkbox ink',
    () {
      final preset = YumeiroThemePresets.sketch;
      expect(
        preset.options.map((option) => option.id),
        isNot(contains('shadowSoftness')),
      );
      const outline = Color(0xFFB3735E);
      final theme = YumeiroThemeExtension.fromPreset(
        preset: preset,
        customizations: const {'borderColor': outline, 'shadowSoftness': 200},
      );
      expect(theme.checkboxVisuals.side.resolve(const {})!.color, outline);
      expect(
        theme.checkboxVisuals.side.resolve(const {WidgetState.selected})!.color,
        theme.accent,
      );
      expect(
        theme.visuals
            .surface(YumeiroSurfaceRole.card)
            .shadows
            .single
            .blurRadius,
        0,
      );
    },
  );

  test(
    'all general families provide light and dark variants with stable defaults',
    () {
      final registry = YumeiroThemeRegistry.standard();
      addTearDown(registry.dispose);
      for (final family in registry.families) {
        if (family.id == 'geek' || family.id == 'sketch') {
          expect(family.variants, hasLength(1));
          continue;
        }
        expect(
          family.variants.keys,
          containsAll(YumeiroThemeVariant.values),
          reason: family.id,
        );
        for (final variant in YumeiroThemeVariant.values) {
          final preset = family.resolve(variant);
          expect(
            preset.brightness,
            variant == YumeiroThemeVariant.dark
                ? Brightness.dark
                : Brightness.light,
          );
          expect(registry.presetById(preset.id), same(preset));
          expect(family.variantOf(preset), variant);
        }
      }
      expect(
        registry.presets.map((preset) => preset.id).toSet(),
        hasLength(24),
      );
      expect(
        registry.familyById('geek')!.resolve(YumeiroThemeVariant.light),
        same(YumeiroThemePresets.geek),
      );
      expect(
        registry.familyById('sketch')!.resolve(YumeiroThemeVariant.dark),
        same(YumeiroThemePresets.sketch),
      );
    },
  );

  for (final preset in [
    YumeiroThemePresets.siliconeLight,
    YumeiroThemePresets.siliconeDark,
  ]) {
    test(
      '${preset.id} keeps the panel and cards independent of backdrop tint',
      () {
        final options = {
          for (final option
              in preset.options.whereType<YumeiroThemeColorOption>())
            option.id: option.defaultValue,
        };
        expect(options['panelColor'], preset.colors.surface);
        expect(options['surfaceColor'], preset.colors.surface);
        final baseline = YumeiroThemeExtension.fromPreset(preset: preset);
        for (final tone in [
          preset.colors.background,
          const Color(0xFFF9F0BB),
        ]) {
          final tinted = YumeiroThemeExtension.fromPreset(
            preset: preset,
            customizations: {'backgroundTone': tone},
          );
          final custom = YumeiroThemeExtension.fromPreset(
            preset: preset,
            customizations: {
              'backgroundTone': tone,
              'panelColor': '#D3E0EF',
              'surfaceColor': '#D7D9AD',
            },
          );
          expect(custom.background, tinted.background);
          for (final (role, color) in const [
            (YumeiroSurfaceRole.panel, Color(0xFFD3E0EF)),
            (YumeiroSurfaceRole.card, Color(0xFFD7D9AD)),
          ]) {
            final original = baseline.visuals.surface(role);
            final withTone = tinted.visuals.surface(role);
            final recolored = custom.visuals.surface(role);
            expect(withTone.background, original.background);
            expect(
              (withTone.fill as YumeiroGradientFill).gradient,
              (original.fill as YumeiroGradientFill).gradient,
            );
            expect(recolored.background, color);
            expect(recolored.fill, isA<YumeiroGradientFill>());
            expect(recolored.effects, original.effects);
          }
        }
      },
    );
  }

  final variants = <(String, YumeiroThemePreset, YumeiroThemePreset)>[
    (
      'yumeiro.neumorphic',
      YumeiroThemePresets.neumorphicLight,
      YumeiroThemePresets.neumorphicDark,
    ),
    (
      'yumeiro.ceramic',
      YumeiroThemePresets.ceramicLight,
      YumeiroThemePresets.ceramicDark,
    ),
    (
      'yumeiro.brushed-metal',
      YumeiroThemePresets.brushedMetalLight,
      YumeiroThemePresets.brushedMetalDark,
    ),
    (
      'yumeiro.neo-brutalist',
      YumeiroThemePresets.neoBrutalistLight,
      YumeiroThemePresets.neoBrutalistDark,
    ),
    (
      'yumeiro.pixel',
      YumeiroThemePresets.pixelLight,
      YumeiroThemePresets.pixelDark,
    ),
    (
      'yumeiro.acrylic',
      YumeiroThemePresets.acrylicLight,
      YumeiroThemePresets.acrylicDark,
    ),
    (
      'yumeiro.silicone',
      YumeiroThemePresets.siliconeLight,
      YumeiroThemePresets.siliconeDark,
    ),
    (
      'yumeiro.frosted-glass',
      YumeiroThemePresets.frostedGlassLight,
      YumeiroThemePresets.frostedGlassDark,
    ),
  ];

  for (final (lightId, light, dark) in variants) {
    test(
      '${dark.id} preserves the persisted light and dark preset identifiers',
      () {
        expect(light.id, lightId);
        expect(dark.id, '$lightId.dark');
        expect(YumeiroThemePresets.byId(lightId), same(light));
        expect(YumeiroThemePresets.byId('$lightId.dark'), same(dark));
        expect(dark.colors.background.computeLuminance(), lessThan(.08));
        expect(light.colors.background.computeLuminance(), greaterThan(.5));
        expect(dark.mediaBackdropTone, YumeiroMediaBackdropTone.cinematicDark);
        expect(
          dark.options.map((option) => option.id),
          light.options.map((option) => option.id),
        );
        final lightFamily = YumeiroThemeRegistry.defaultInstance
            .familyForPreset(light)!;
        expect(lightFamily.resolve(), same(light));
        final theme = yumeiroThemeData(preset: dark);
        expect(theme.brightness, Brightness.dark);
        expect(theme.colorScheme.brightness, Brightness.dark);
        expect(theme.colorScheme.onPrimary, dark.colors.onAccent);
      },
    );

    test(
      '${dark.id} keeps enabled control labels readable in interaction states',
      () {
        final theme = YumeiroThemeExtension.fromPreset(preset: dark);
        for (final role in [
          YumeiroControlRole.neutral,
          YumeiroControlRole.secondary,
          YumeiroControlRole.primary,
          YumeiroControlRole.danger,
        ]) {
          for (final states in <Set<WidgetState>>[
            {},
            {WidgetState.hovered},
            {WidgetState.pressed},
            {WidgetState.selected},
            {WidgetState.focused},
          ]) {
            final appearance = theme.visuals.control(role, states);
            final fill = appearance.fill;
            final stops = switch (fill) {
              YumeiroSolidFill(:final color) => [color],
              YumeiroGradientFill(:final gradient) => gradient.colors,
            };
            for (final color in stops) {
              final background = Color.alphaBlend(
                color,
                theme.colors.background,
              );
              final foreground = Color.alphaBlend(
                appearance.foreground,
                background,
              );
              expect(
                _contrast(foreground, background),
                greaterThanOrEqualTo(4.5),
                reason: '${dark.id} $role $states',
              );
            }
          }
          final disabled = theme.visuals.control(role, {WidgetState.disabled});
          expect(
            disabled.opacity,
            lessThan(theme.visuals.control(role, {}).opacity),
          );
          expect(
            theme.visuals
                .control(role, {WidgetState.focused})
                .focusIndicator
                .isVisible,
            isTrue,
          );
        }
      },
    );
  }
}
