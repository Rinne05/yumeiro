import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yumeiro/yumeiro.dart';

void main() {
  group('YumeiroThemeRegistry', () {
    test('standard registry exposes built-in theme families and presets', () {
      final registry = YumeiroThemeRegistry.standard();
      expect(
        registry.families.map((f) => f.id),
        containsAll(<String>[
          'classic',
          'geek',
          'sketch',
          'neumorphic',
          'minimal',
          'liquid-glass',
          'ceramic',
          'brushed-metal',
          'neo-brutalist',
          'pixel',
          'acrylic',
          'silicone',
          'frosted-glass',
        ]),
      );
      expect(registry.presets, containsAll(YumeiroThemePresets.builtInValues));
    });

    test('host can register custom theme family and preset', () {
      final registry = YumeiroThemeRegistry.standard();
      final customPreset = YumeiroThemePreset(
        id: 'host.ocean.dark',
        label: 'Oceanic Dark',
        brightness: Brightness.dark,
        colors: YumeiroColorTokens.dark.copyWith(
          accent: const Color(0xFF00B4D8),
        ),
        materialSchemeBuilder:
            YumeiroThemePresets.classicDark.materialSchemeBuilder,
        visualsBuilder: YumeiroThemePresets.classicDark.visualsBuilder,
        categoricalPaletteBuilder:
            YumeiroThemePresets.classicDark.categoricalPaletteBuilder,
      );

      registry.registerPreset(
        customPreset,
        familyId: 'ocean',
        familyLabel: 'Ocean',
      );

      final light = customPreset.copyWith(
        id: 'host.ocean.light',
        brightness: Brightness.light,
      );
      registry.registerPreset(light, familyId: 'ocean');

      final family = registry.familyById('ocean')!;
      expect(family.label, 'Ocean');
      expect(family.resolve(), same(customPreset));
      expect(family.resolve(YumeiroThemeVariant.light), same(light));
      expect(registry.presetById('host.ocean.dark'), same(customPreset));
    });

    test('preset slots reject cross-registration ID conflicts atomically', () {
      final registry = YumeiroThemeRegistry.empty();
      final dark = YumeiroThemePresets.classicDark;
      final light = YumeiroThemePresets.classicLight;
      registry.registerPreset(dark, familyId: 'classic');
      registry.registerPreset(light);
      final before = registry.presets;
      var notifications = 0;
      registry.addListener(() => notifications++);

      for (final fail in <VoidCallback>[
        () => registry.registerPreset(dark),
        () => registry.registerPreset(dark, familyId: 'other'),
        () => registry.registerPreset(
          dark,
          familyId: 'classic',
          variant: YumeiroThemeVariant.light,
        ),
        () => registry.registerFamily(
          YumeiroThemeFamily(
            id: 'other',
            label: 'Other',
            variants: {YumeiroThemeVariant.light: light},
            defaultVariant: YumeiroThemeVariant.light,
          ),
        ),
      ]) {
        expect(fail, throwsArgumentError);
        expect(registry.presets, before);
        expect(notifications, 0);
      }

      final replacement = dark.copyWith(label: 'New label');
      registry.registerPreset(replacement, familyId: 'classic');
      expect(registry.presetById(dark.id), same(replacement));
      expect(notifications, 1);
      expect(registry.unregisterStandalonePreset(light.id), isTrue);
      registry.registerPreset(light, familyId: 'classic');
      expect(registry.familyForPreset(light)?.id, 'classic');
      expect(registry.presets, [replacement, light]);
      expect(notifications, 3);
    });

    test('initial families reject a repeated preset ID', () {
      final preset = YumeiroThemePresets.classicDark;
      final invalid = YumeiroThemeFamily(
        id: 'invalid',
        label: 'Invalid',
        variants: {
          YumeiroThemeVariant.dark: preset,
          YumeiroThemeVariant.light: preset,
        },
        defaultVariant: YumeiroThemeVariant.dark,
      );
      expect(
        () => YumeiroThemeRegistry(families: [invalid]),
        throwsArgumentError,
      );
    });

    for (final asApplication in [true, false]) {
      testWidgets(
        'active preset changes keep content state in ${asApplication ? 'app' : 'scope'}',
        (tester) async {
          final base = YumeiroThemePresets.classicDark;
          final preset = base.copyWith(id: 'host.active');
          const accent = Color(0xFF9966BB);
          final registry = YumeiroThemeRegistry.empty()..registerPreset(preset);
          late YumeiroThemeExtension theme;
          final field = TextEditingController();
          addTearDown(field.dispose);
          final content = Builder(
            builder: (context) {
              theme = YumeiroTheme.of(context);
              return Scaffold(body: TextField(controller: field));
            },
          );
          await tester.pumpWidget(
            asApplication
                ? YumeiroApp(
                    registry: registry,
                    presetId: preset.id,
                    home: content,
                  )
                : MaterialApp(
                    home: YumeiroScope(
                      registry: registry,
                      presetId: preset.id,
                      child: content,
                    ),
                  ),
          );
          expect(theme.accent, preset.colors.accent);
          await tester.enterText(find.byType(TextField), 'form draft');
          final inputState = tester.state(find.byType(EditableText));

          registry.registerPreset(
            preset.copyWith(colors: preset.colors.copyWith(accent: accent)),
          );
          await tester.pumpAndSettle();
          expect(theme.accent, accent);
          expect(tester.state(find.byType(EditableText)), same(inputState));
          expect(field.text, 'form draft');

          registry.unregisterStandalonePreset(preset.id);
          await tester.pumpAndSettle();
          expect(theme.presetId, base.id);
          expect(tester.state(find.byType(EditableText)), same(inputState));
        },
      );
    }

    testWidgets(
      'YumeiroScope exposes custom registry via YumeiroThemeRegistryScope',
      (tester) async {
        final registry = YumeiroThemeRegistry.empty()
          ..registerPreset(
            YumeiroThemePresets.geek,
            familyId: 'geek',
            familyLabel: 'Geek',
          );

        late YumeiroThemeRegistry captured;
        await tester.pumpWidget(
          YumeiroApp(
            registry: registry,
            presetId: YumeiroThemePresetIds.geek,
            home: Builder(
              builder: (context) {
                captured = YumeiroThemeRegistryScope.of(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(captured.families.length, 1);
        expect(captured.families.first.id, 'geek');
      },
    );
  });
}
