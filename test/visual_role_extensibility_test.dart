import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yumeiro/yumeiro.dart';

const _customBannerRole = YumeiroSurfaceRole(
  'example.banner',
  fallback: YumeiroSurfaceRole.card,
);
const _customNestedRole = YumeiroSurfaceRole(
  'example.banner.nested',
  fallback: _customBannerRole,
);
const _customCtaControl = YumeiroControlRole(
  'example.cta',
  fallback: YumeiroControlRole.primary,
);
const _customStatus = YumeiroStatusRole(
  'example.highlight',
  fallback: YumeiroStatusRole.accent,
);

// A host theme authored before built-in roles could grow independently.
const _legacySurfaces = [
  YumeiroSurfaceRole.canvas,
  YumeiroSurfaceRole.navigation,
  YumeiroSurfaceRole.panel,
  YumeiroSurfaceRole.inset,
  YumeiroSurfaceRole.compact,
  YumeiroSurfaceRole.readout,
  YumeiroSurfaceRole.card,
  YumeiroSurfaceRole.floating,
  YumeiroSurfaceRole.modal,
  YumeiroSurfaceRole.toast,
  YumeiroSurfaceRole.scrim,
  YumeiroSurfaceRole.media,
];
const _legacyControls = [
  YumeiroControlRole.neutral,
  YumeiroControlRole.secondary,
  YumeiroControlRole.primary,
  YumeiroControlRole.danger,
  YumeiroControlRole.ghost,
  YumeiroControlRole.overlay,
];
const _legacyItems = [
  YumeiroItemRole.standard,
  YumeiroItemRole.danger,
  YumeiroItemRole.navigation,
  YumeiroItemRole.selection,
];
const _legacyStatuses = [
  YumeiroStatusRole.neutral,
  YumeiroStatusRole.info,
  YumeiroStatusRole.accent,
  YumeiroStatusRole.success,
  YumeiroStatusRole.warning,
  YumeiroStatusRole.danger,
];

void main() {
  group('Open extensible semantic roles', () {
    test('the original recipe maps resolve all catalog roles', () {
      final legacy = _legacyTheme();
      expect(legacy.surfaces.keys, unorderedEquals(_legacySurfaces));
      expect(legacy.controls.keys, unorderedEquals(_legacyControls));
      expect(legacy.items.keys, unorderedEquals(_legacyItems));
      expect(legacy.statuses.keys, unorderedEquals(_legacyStatuses));
      _expectCatalogFallbacks(
        YumeiroSurfaceRole.builtInValues,
        legacy.surfaces,
        (role) => role.fallback,
        legacy.surfaceRecipe,
      );
      _expectCatalogFallbacks(
        YumeiroControlRole.builtInValues,
        legacy.controls,
        (role) => role.fallback,
        legacy.controlRecipe,
      );
      _expectCatalogFallbacks(
        YumeiroItemRole.builtInValues,
        legacy.items,
        (role) => role.fallback,
        legacy.itemRecipe,
      );
      _expectCatalogFallbacks(
        YumeiroStatusRole.builtInValues,
        legacy.statuses,
        (role) => role.fallback,
        legacy.status,
      );
    });

    test('every original recipe is still required', () {
      for (final role in [
        ..._legacySurfaces,
        ..._legacyControls,
        ..._legacyItems,
        ..._legacyStatuses,
      ]) {
        expect(
          () => _legacyTheme(excluding: role),
          throwsArgumentError,
          reason: '$role is part of the original recipe set',
        );
      }
    });

    test('custom roles fall back recursively when unregistered', () {
      final theme = YumeiroThemePresets.classicDark.visualsBuilder(
        YumeiroColorTokens.dark,
        const YumeiroRadiiTokens(),
        const YumeiroMotion(),
      );

      final cardAppearance = theme.surface(YumeiroSurfaceRole.card);
      final nestedAppearance = theme.surface(_customNestedRole);
      expect(
        nestedAppearance.fill.fallbackColor,
        cardAppearance.fill.fallbackColor,
      );

      final primaryAppearance = theme.control(
        YumeiroControlRole.primary,
        const {},
      );
      final ctaAppearance = theme.control(_customCtaControl, const {});
      expect(
        ctaAppearance.fill.fallbackColor,
        primaryAppearance.fill.fallbackColor,
      );

      final accentStatus = theme.status(YumeiroStatusRole.accent);
      final customStatus = theme.status(_customStatus);
      expect(customStatus.foreground, accentStatus.foreground);

      final overriddenCard = YumeiroVisualRecipe(
        base: cardAppearance.copyWith(foreground: Colors.purple),
      );
      final customized = theme.extend(
        surfaces: {YumeiroSurfaceRole.card: overriddenCard},
      );
      expect(customized.surfaceRecipe(_customNestedRole), same(overriddenCard));
      expect(customized.surfaces.containsKey(_customNestedRole), isFalse);
    });

    test(
      'extend() registers custom role recipes and lerp() preserves them',
      () {
        final baseDark = YumeiroThemePresets.classicDark.visualsBuilder(
          YumeiroColorTokens.dark,
          const YumeiroRadiiTokens(),
          const YumeiroMotion(),
        );
        final baseLight = YumeiroThemePresets.classicLight.visualsBuilder(
          YumeiroColorTokens.light,
          const YumeiroRadiiTokens(),
          const YumeiroMotion(),
        );

        final customDark = baseDark.extend(
          surfaces: {
            _customBannerRole: YumeiroVisualRecipe(
              base: YumeiroVisualAppearance(
                fill: const YumeiroSolidFill(Color(0xFF334455)),
                foreground: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                transition: YumeiroVisualTransition.instant,
              ),
            ),
          },
          statuses: {
            _customStatus: const YumeiroStatusVisual(
              foreground: Color(0xFFFF6600),
              subtleFill: Color(0x22FF6600),
            ),
          },
        );

        expect(
          customDark.surface(_customBannerRole).fill.fallbackColor,
          const Color(0xFF334455),
        );
        expect(
          customDark.status(_customStatus).foreground,
          const Color(0xFFFF6600),
        );

        final mid = customDark.lerp(baseLight, 0.5);
        final expectedColor = Color.lerp(
          const Color(0xFF334455),
          baseLight.surface(YumeiroSurfaceRole.card).fill.fallbackColor,
          0.5,
        );
        expect(
          mid.surface(_customBannerRole).fill.fallbackColor,
          expectedColor,
        );
        expect(mid.surfaces.containsKey(_customNestedRole), isFalse);
        expect(
          mid.surfaceRecipe(_customNestedRole),
          same(mid.surfaces[_customBannerRole]),
        );
      },
    );
  });
}

YumeiroSemanticVisualTheme _legacyTheme({Object? excluding}) {
  final preset = YumeiroThemePresets.classicDark;
  final original = preset.visualsBuilder(
    preset.colors,
    preset.radii,
    preset.motion,
  );
  Map<R, V> recipes<R, V extends Object>(List<R> roles, Map<R, V> source) => {
    for (final role in roles)
      if (role != excluding) role: source[role]!,
  };

  return YumeiroSemanticVisualTheme(
    surfaces: recipes(_legacySurfaces, original.surfaces),
    controls: recipes(_legacyControls, original.controls),
    items: recipes(_legacyItems, original.items),
    statuses: recipes(_legacyStatuses, original.statuses),
    navigationItems: original.navigationItems,
  );
}

void _expectCatalogFallbacks<R, V>(
  List<R> catalog,
  Map<R, V> recipes,
  R? Function(R) fallback,
  V Function(R) resolve,
) {
  expect(catalog, containsAll(recipes.keys));
  for (final role in catalog) {
    if (recipes.containsKey(role)) continue;
    final visited = {role};
    var inherited = fallback(role);
    while (inherited != null &&
        !recipes.containsKey(inherited) &&
        visited.add(inherited)) {
      inherited = fallback(inherited);
    }
    expect(
      recipes.containsKey(inherited),
      isTrue,
      reason: '$role needs a fallback to an original role',
    );
    expect(resolve(role), same(recipes[inherited]));
  }
}
