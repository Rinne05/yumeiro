import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yumeiro/yumeiro.dart';

double _contrast(Color foreground, Color background) {
  final first = foreground.computeLuminance();
  final second = background.computeLuminance();
  return (math.max(first, second) + .05) / (math.min(first, second) + .05);
}

void main() {
  for (final preset in [
    YumeiroThemePresets.neoBrutalistDark,
    YumeiroThemePresets.pixelDark,
  ]) {
    test('${preset.id} separates visible outlines from hard dark shadows', () {
      final theme = YumeiroThemeExtension.fromPreset(preset: preset);
      final resting = theme.visuals.control(
        YumeiroControlRole.secondary,
        const {},
      );
      final selected = theme.visuals.control(YumeiroControlRole.neutral, const {
        WidgetState.selected,
      });
      expect(resting.outline.width, greaterThanOrEqualTo(2));
      expect(resting.outline.color.computeLuminance(), greaterThan(.3));
      expect(resting.effects.outerShadows, isNotEmpty);
      expect(resting.effects.outerShadows.single.blurRadius, 0);
      expect(
        resting.effects.outerShadows.single.color.computeLuminance(),
        lessThan(.01),
      );
      expect(
        _contrast(selected.foreground, selected.background),
        greaterThanOrEqualTo(7),
      );
      expect(
        theme.visuals
            .control(YumeiroControlRole.secondary, const {WidgetState.focused})
            .focusIndicator
            .isVisible,
        isTrue,
      );
      final pressed = theme.visuals.control(
        YumeiroControlRole.secondary,
        const {WidgetState.pressed},
      );
      expect(
        pressed.effects.outerShadows.isEmpty ||
            pressed.effects.outerShadows.single.offset.distance <
                resting.effects.outerShadows.single.offset.distance,
        isTrue,
      );
      if (preset == YumeiroThemePresets.pixelDark) {
        expect(resting.shape, isA<YumeiroPixelBorder>());
        expect(theme.checkboxVisuals.shape, isA<YumeiroPixelBorder>());
        expect(theme.switchVisuals.track.base.shape, isA<YumeiroPixelBorder>());
      } else {
        expect(
          theme.switchVisuals.thumb.base.background.computeLuminance(),
          greaterThan(.8),
        );
      }
    });
  }

  test('dark neumorphic depth uses restrained highlights and deep shadows', () {
    final theme = YumeiroThemeExtension.fromPreset(
      preset: YumeiroThemePresets.neumorphicDark,
    );
    final raised = theme.visuals.surface(YumeiroSurfaceRole.card);
    final inset = theme.visuals.control(YumeiroControlRole.neutral, const {});
    expect(raised.effects.outerShadows.first.color.a, greaterThan(.5));
    expect(
      raised.effects.outerShadows.first.color.computeLuminance(),
      lessThan(.01),
    );
    final upperLight = raised.effects.outerShadows.singleWhere(
      (shadow) => shadow.offset.dx < 0,
    );
    expect(upperLight.color.computeLuminance(), lessThan(.3));
    expect(upperLight.color.a, lessThan(.3));
    expect(inset.effects.outerShadows, isEmpty);
    expect(
      inset.effects.innerShadows.first.color.computeLuminance(),
      lessThan(.01),
    );

    final flatLight = YumeiroThemeExtension.fromPreset(
      preset: YumeiroThemePresets.neumorphicDark,
      customizations: const {'raisedHighlight': 0.0},
    );
    final noLight = flatLight.visuals.surface(YumeiroSurfaceRole.card);
    expect(
      noLight.effects.outerShadows.where((shadow) => shadow.offset.dx < 0),
      isEmpty,
    );
    expect(noLight.effects.innerShadows.first.color.a, 0);

    const customShadow = Color(0xFF351018);
    final tinted = YumeiroThemeExtension.fromPreset(
      preset: YumeiroThemePresets.neumorphicDark,
      customizations: const {'shadowColor': customShadow},
    );
    final shadow = tinted.visuals
        .surface(YumeiroSurfaceRole.card)
        .effects
        .outerShadows
        .first
        .color;
    expect(shadow.r, customShadow.r);
    expect(shadow.g, customShadow.g);
    expect(shadow.b, customShadow.b);
  });

  test('dark danger labels and statuses remain readable', () {
    for (final preset in [
      YumeiroThemePresets.neoBrutalistDark,
      YumeiroThemePresets.pixelDark,
      YumeiroThemePresets.neumorphicDark,
    ]) {
      final theme = YumeiroThemeExtension.fromPreset(preset: preset);
      for (final states in <Set<WidgetState>>[
        {},
        {WidgetState.hovered},
        {WidgetState.pressed},
        {WidgetState.selected},
      ]) {
        final button = theme.visuals.control(YumeiroControlRole.danger, states);
        expect(
          _contrast(button.foreground, button.background),
          greaterThanOrEqualTo(4.5),
          reason: '${preset.id} danger $states',
        );
      }
      for (final role in [
        YumeiroStatusRole.danger,
        YumeiroStatusRole.info,
        YumeiroStatusRole.success,
        YumeiroStatusRole.warning,
      ]) {
        final status = theme.visuals.status(role);
        expect(
          _contrast(
            status.foreground,
            Color.alphaBlend(status.subtleFill, theme.colors.surface),
          ),
          greaterThanOrEqualTo(4.5),
          reason: '${preset.id} status ${role.id}',
        );
      }
    }
  });
}
