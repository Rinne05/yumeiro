import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yumeiro/yumeiro.dart';
import 'package:yumeiro_example/src/widgets/gallery_widgets.dart';

void main() {
  for (final preset in [
    YumeiroThemePresets.neoBrutalistDark,
    YumeiroThemePresets.pixelDark,
  ]) {
    testWidgets(
      '${preset.id} selected family card keeps its semantic foreground',
      (tester) async {
        final registry = YumeiroThemeRegistry.standard();
        addTearDown(registry.dispose);
        final family = registry.familyForPreset(preset)!;
        await tester.pumpWidget(
          YumeiroApp(
            preset: preset,
            locale: const Locale('en'),
            home: Scaffold(
              body: Center(
                child: GalleryPresetCard(
                  family: family,
                  preset: preset,
                  selected: true,
                  onTap: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final title = tester.element(
          find.text(family.resolveLabel(const YumeiroLocalizationsEn())),
        );
        final theme = YumeiroTheme.of(title);
        final appearance = theme.visuals.surface(YumeiroSurfaceRole.card, {
          WidgetState.selected,
        });
        final foreground = DefaultTextStyle.of(title).style.color!;
        expect(foreground, appearance.foreground);
        final marker = tester.element(find.byIcon(theme.icons.check));
        expect(IconTheme.of(marker).color, foreground);
        final textLuminance = foreground.computeLuminance();
        final fillLuminance = appearance.fill.fallbackColor.computeLuminance();
        expect(
          (math.max(textLuminance, fillLuminance) + .05) /
              (math.min(textLuminance, fillLuminance) + .05),
          greaterThanOrEqualTo(4.5),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
