import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yumeiro/yumeiro.dart';

void main() {
  for (final (preset, defaultPanel) in [
    (YumeiroThemePresets.neoBrutalistLight, const Color(0xFFFF9B91)),
    (YumeiroThemePresets.neoBrutalistDark, const Color(0xFF352B2A)),
  ]) {
    test('${preset.id} preserves independent surface colors', () {
      final options = {
        for (final option
            in preset.options.whereType<YumeiroThemeColorOption>())
          option.id: option.defaultValue,
      };
      expect(options['panelColor'], defaultPanel);
      expect(options['surfaceColor'], preset.colors.surface);
      expect(options['surfaceHoverColor'], preset.colors.surfaceHover);

      final baseline = YumeiroThemeExtension.fromPreset(preset: preset);
      final tinted = YumeiroThemeExtension.fromPreset(
        preset: preset,
        customizations: const {'backgroundTone': '#F9F0BB'},
      );
      final custom = YumeiroThemeExtension.fromPreset(
        preset: preset,
        customizations: const {
          'backgroundTone': '#F9F0BB',
          'panelColor': '#7EABC8',
          'surfaceColor': '#CB8828',
          'surfaceHoverColor': '#CA9BCD',
        },
      );
      final baselinePanel = baseline.visuals.surface(YumeiroSurfaceRole.panel);
      final tintedPanel = tinted.visuals.surface(YumeiroSurfaceRole.panel);
      final customPanel = custom.visuals.surface(YumeiroSurfaceRole.panel);
      expect(baselinePanel.background, defaultPanel);
      expect(tintedPanel.background, defaultPanel);
      expect(customPanel.background, const Color(0xFF7EABC8));
      expect(customPanel.foreground, baselinePanel.foreground);
      expect(customPanel.outline, baselinePanel.outline);

      for (final role in [
        YumeiroSurfaceRole.canvas,
        YumeiroSurfaceRole.navigation,
      ]) {
        final tintedFill = tinted.visuals.surface(role).background;
        expect(tintedFill, isNot(baseline.visuals.surface(role).background));
        expect(custom.visuals.surface(role).background, tintedFill);
      }
      for (final role in [
        YumeiroSurfaceRole.card,
        YumeiroSurfaceRole.modal,
        YumeiroSurfaceRole.media,
      ]) {
        expect(tinted.visuals.surface(role).background, preset.colors.surface);
        expect(
          custom.visuals.surface(role).background,
          const Color(0xFFCB8828),
        );
      }
      expect(tinted.colors.surfaceHover, preset.colors.surfaceHover);
      expect(custom.colors.surfaceHover, const Color(0xFFCA9BCD));
      for (final state in [WidgetState.hovered, WidgetState.pressed]) {
        final before = baseline.visuals.control(YumeiroControlRole.ghost, {
          state,
        });
        final withTone = tinted.visuals.control(YumeiroControlRole.ghost, {
          state,
        });
        final after = custom.visuals.control(YumeiroControlRole.ghost, {state});
        expect(withTone.background, before.background);
        expect(after.background, isNot(before.background));
        expect(after.effects, before.effects);
      }
    });
  }

  for (final preset in [
    YumeiroThemePresets.pixelLight,
    YumeiroThemePresets.pixelDark,
  ]) {
    test(
      '${preset.id} preserves its secondary surfaces under background tint',
      () {
        final option = preset.options
            .whereType<YumeiroThemeColorOption>()
            .singleWhere((option) => option.id == 'secondarySurfaceColor');
        expect(option.defaultValue, preset.colors.surfaceSecondary);
        for (final tone in [
          preset.colors.background,
          const Color(0xFFF9F0BB),
        ]) {
          final tinted = yumeiroThemeData(
            preset: preset,
            customizations: {'backgroundTone': tone},
          );
          const chosen = Color(0xFFD0E7DA);
          final custom = yumeiroThemeData(
            preset: preset,
            customizations: {
              'backgroundTone': tone,
              'secondarySurfaceColor': chosen,
            },
          );
          expect(tinted.inputDecorationTheme.fillColor, option.defaultValue);
          expect(custom.inputDecorationTheme.fillColor, chosen);
          expect(
            custom.scaffoldBackgroundColor,
            tinted.scaffoldBackgroundColor,
          );
          final visuals = custom.extension<YumeiroThemeExtension>()!.visuals;
          expect(
            visuals.surface(YumeiroSurfaceRole.readout).background,
            chosen,
          );
          expect(visuals.surface(YumeiroSurfaceRole.inset).background, chosen);
          expect(
            visuals.surface(YumeiroSurfaceRole.inset).shape,
            isA<YumeiroPixelBorder>(),
          );
        }
      },
    );
  }

  test('graphic navigation uses readable ink on selected accent surfaces', () {
    for (final preset in [
      YumeiroThemePresets.neoBrutalistLight,
      YumeiroThemePresets.neoBrutalistDark,
      YumeiroThemePresets.pixelLight,
      YumeiroThemePresets.pixelDark,
    ]) {
      final theme = YumeiroThemeExtension.fromPreset(preset: preset);
      for (final states in <Set<WidgetState>>[
        {WidgetState.selected},
        {WidgetState.selected, WidgetState.hovered},
        {WidgetState.selected, WidgetState.pressed},
      ]) {
        final navigation = theme.visuals.navigationItem(states);
        final surface = navigation.destinationIndicator!;
        expect(
          navigation.iconForeground,
          surface.foreground,
          reason: preset.id,
        );
        expect(
          navigation.labelForeground,
          surface.foreground,
          reason: preset.id,
        );
        expect(navigation.labelForeground, theme.colors.onAccent);
      }
      expect(
        theme.visuals.navigationItem({}).labelForeground,
        theme.colors.text,
      );
    }
  });

  test('pixel corner customization reaches surfaces and binary controls', () {
    final square = YumeiroThemeExtension.fromPreset(
      preset: YumeiroThemePresets.pixelLight,
      customizations: const {'roundness': 0.0},
    );
    final half = YumeiroThemeExtension.fromPreset(
      preset: YumeiroThemePresets.pixelLight,
      customizations: const {'roundness': 50.0},
    );
    expect(
      (square.visuals.control(YumeiroControlRole.neutral, const {}).shape
              as YumeiroPixelBorder)
          .step,
      0,
    );
    expect(
      (square.visuals.surface(YumeiroSurfaceRole.card).shape
              as YumeiroPixelBorder)
          .step,
      0,
    );
    expect((square.checkboxVisuals.shape as YumeiroPixelBorder).step, 0);
    expect(
      (square.switchVisuals.track.base.shape as YumeiroPixelBorder).step,
      0,
    );
    expect(
      (square.switchVisuals.thumb.base.shape as YumeiroPixelBorder).step,
      0,
    );
    expect(
      (half.switchVisuals.thumb.base.shape as YumeiroPixelBorder).step,
      half.switchVisuals.thumbSize / 14,
    );
    expect(
      (half.visuals.control(YumeiroControlRole.neutral, const {}).shape
              as YumeiroPixelBorder)
          .step,
      YumeiroThemePresets.pixelLight.radii.button / 2,
    );
  });

  test('pixel typography retains a host-supplied pixel font', () {
    final theme = YumeiroThemeExtension.fromPreset(
      preset: YumeiroThemePresets.pixelLight,
      fontConfig: const YumeiroFontConfig(
        fontFamily: 'Host Pixel',
        fontFallback: ['Host CJK'],
      ),
    );
    expect(theme.typography.body.fontFamily, 'Host Pixel');
    expect(theme.typography.body.fontFamilyFallback, contains('Host CJK'));
  });

  test('brutalist controls retain light thumbs and press feedback', () {
    final theme = YumeiroThemeExtension.fromPreset(
      preset: YumeiroThemePresets.neoBrutalistLight,
    );
    final visuals = theme.switchVisuals;
    final on = visuals.track.resolve(const {WidgetState.selected});
    final thumb = visuals.thumb.resolve(const {WidgetState.selected});
    expect(on.background, theme.colors.accent);
    expect(thumb.background.computeLuminance(), greaterThan(.8));
    expect(thumb.outline.color, theme.colors.lineStrong);
    expect(thumb.outline.width, greaterThanOrEqualTo(2));
    expect(thumb.effects.outerShadows, isNotEmpty);
    expect(
      visuals.thumb.resolve(const {WidgetState.pressed}).effects.outerShadows,
      isEmpty,
    );
    expect(
      visuals.track
          .resolve(const {WidgetState.focused})
          .focusIndicator
          .isVisible,
      isTrue,
    );
    expect(
      visuals.track.resolve(const {WidgetState.disabled}).opacity,
      lessThan(visuals.track.base.opacity),
    );
    expect(theme.checkboxVisuals.side.resolve(const {})!.width, 2);
  });

  const tint = Color(0xFF9D323A);
  const ink = Color(0xFF3350AE);
  for (final preset in [
    YumeiroThemePresets.neoBrutalistLight,
    YumeiroThemePresets.neoBrutalistDark,
    YumeiroThemePresets.pixelLight,
    YumeiroThemePresets.pixelDark,
  ]) {
    test('${preset.id} resolves hard shadows independently of outlines', () {
      final defaultInk = preset.brightness == Brightness.dark
          ? const Color(0xFF050907)
          : preset.colors.lineStrong;
      final declaration = preset.options
          .whereType<YumeiroThemeColorOption>()
          .singleWhere((option) => option.id == 'hardShadowColor');
      expect(declaration.defaultValue, defaultInk);
      final borderOnly = YumeiroThemeExtension.fromPreset(
        preset: preset,
        customizations: const {'borderColor': tint},
      );
      final button = borderOnly.visuals.control(YumeiroControlRole.neutral, {});
      expect(button.outline.color, tint);
      expect(button.effects.outerShadows.single.color, defaultInk);
      final adjusted = YumeiroThemeExtension.fromPreset(
        preset: preset,
        customizations: const {
          'outline': 50,
          'hardShadowColor': ink,
          'shadow': 50,
          'shadowDistance': 200,
        },
      );
      final defaultDepth = preset.id.startsWith('yumeiro.neo-brutalist')
          ? 1
          : 2;
      for (final recipe in [
        adjusted.switchVisuals.track,
        adjusted.switchVisuals.thumb,
      ]) {
        final shadow = recipe.base.effects.outerShadows.single;
        expect(shadow.color, ink.withValues(alpha: .5));
        expect(shadow.offset, const Offset(2, 2) * defaultDepth.toDouble());
        expect(recipe.base.outline.width, 1);
      }
    });

    testWidgets(
      '${preset.id} sliders paint their chosen border and hard shadow',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetDevicePixelRatio);
        final sample = GlobalKey();

        Future<(int, int)> countRenderedColors(
          Map<String, Object> adjustments, {
          required bool range,
        }) async {
          await tester.pumpWidget(
            YumeiroApp(
              preset: preset,
              customizations: {
                'borderColor': tint,
                'hardShadowColor': ink,
                ...adjustments,
              },
              home: Center(
                child: RepaintBoundary(
                  key: sample,
                  child: SizedBox(
                    width: 180,
                    child: Material(
                      color: Colors.white,
                      child: range
                          ? YumeiroRangeSlider(
                              values: const RangeValues(.3, .7),
                              onChanged: (_) {},
                            )
                          : YumeiroSlider(value: .5, onChanged: (_) {}),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          if (range) {
            final theme = SliderTheme.of(
              tester.element(find.byType(RangeSlider)),
            );
            expect(
              theme.rangeTrackShape,
              isA<RectangularRangeSliderTrackShape>(),
            );
          }
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(sample),
          );
          return (await tester.runAsync(() async {
            final image = await boundary.toImage();
            try {
              final pixels = (await image.toByteData(
                format: ui.ImageByteFormat.rawRgba,
              ))!;
              var shadowPixels = 0;
              var borderPixels = 0;
              for (var offset = 0; offset < pixels.lengthInBytes; offset += 4) {
                final rgba = pixels.getUint32(offset);
                if (rgba == 0x3350AEFF) shadowPixels++;
                if (rgba == 0x9D323AFF) borderPixels++;
              }
              return (shadowPixels, borderPixels);
            } finally {
              image.dispose();
            }
          }))!;
        }

        for (final range in [false, true]) {
          final (shadow, outline) = await countRenderedColors({}, range: range);
          expect(shadow, greaterThan(0));
          expect(outline, greaterThan(0));
          final (longShadow, _) = await countRenderedColors({
            'shadowDistance': 200,
          }, range: range);
          expect(longShadow, greaterThan(shadow));
          final (noShadow, noOutline) = await countRenderedColors({
            'shadow': 0,
            'outline': 0,
          }, range: range);
          expect(noShadow, 0);
          expect(noOutline, 0);
        }
      },
    );
  }

  testWidgets('progress caps follow the active theme geometry', (tester) async {
    for (final preset in [
      YumeiroThemePresets.classicLight,
      YumeiroThemePresets.neoBrutalistLight,
      YumeiroThemePresets.pixelLight,
    ]) {
      await tester.pumpWidget(
        YumeiroApp(
          preset: preset,
          home: const Center(
            child: SizedBox(width: 120, child: YumeiroProgress(value: .65)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final indicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      final stepped = find.descendant(
        of: find.byType(YumeiroProgress),
        matching: find.byWidgetPredicate(
          (widget) => switch (widget) {
            ClipPath(
              clipper: ShapeBorderClipper(shape: YumeiroPixelBorder()),
            ) =>
              true,
            _ => false,
          },
        ),
      );
      expect(
        indicator.borderRadius,
        preset == YumeiroThemePresets.classicLight
            ? BorderRadius.circular(preset.radii.chip)
            : BorderRadius.zero,
      );
      expect(
        stepped,
        preset == YumeiroThemePresets.pixelLight
            ? findsOneWidget
            : findsNothing,
      );
    }
  });

  test('graphic hard shadow defaults come from a host preset palette', () {
    final source = YumeiroThemePresets.neoBrutalistLight;
    final cloned = source.copyWith(
      colors: source.colors.copyWith(lineStrong: ink),
    );
    final option = cloned.options
        .whereType<YumeiroThemeColorOption>()
        .singleWhere((option) => option.id == 'hardShadowColor');
    final themed = YumeiroThemeExtension.fromPreset(
      preset: cloned,
      customizations: const {'borderColor': tint},
    );
    expect(option.defaultValue, ink);
    expect(themed.switchVisuals.track.base.outline.color, tint);
    expect(
      themed.switchVisuals.track.base.effects.outerShadows.single.color,
      ink,
    );
  });
}
