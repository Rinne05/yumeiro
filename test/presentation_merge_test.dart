import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

void main() {
  testWidgets('badge styles custom content and overlay keeps its size', (
    tester,
  ) async {
    const palette = YumeiroVisualOverride(
      base: YumeiroVisualDelta(foreground: Colors.purple),
    );
    const badge = ValueKey('metadata');
    const overlay = ValueKey('artwork badge');
    await tester.pumpWidget(
      const YumeiroApp(
        home: Scaffold(
          body: Wrap(
            children: [
              YumeiroVisualScope(
                visualOverride: palette,
                child: YumeiroBadge(
                  key: badge,
                  dense: true,
                  height: 28,
                  padding: EdgeInsets.all(2),
                  child: Text('Metadata'),
                ),
              ),
              YumeiroBadge.overlay(
                key: overlay,
                label: 'HD',
                icon: Icons.hd,
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
    );

    final metadata = tester.element(find.text('Metadata'));
    final typography = YumeiroTheme.of(metadata).typography;
    final inheritedStyle = DefaultTextStyle.of(metadata).style;
    expect(inheritedStyle.color, Colors.purple);
    expect(inheritedStyle.fontWeight, typography.bodyWeight);
    expect(tester.getSize(find.byKey(badge)).height, 28);
    expect(tester.getSize(find.byKey(overlay)).height, lessThan(28));
    expect(tester.widget<Text>(find.text('HD')).style!.color, Colors.white);
    expect(tester.widget<Icon>(find.byIcon(Icons.hd)).size, 11);
  });

  testWidgets('media tile keeps its thumbnail and modality line limits', (
    tester,
  ) async {
    var taps = 0;

    for (final modality in YumeiroModality.values) {
      await tester.pumpWidget(
        YumeiroApp(
          modality: modality,
          home: Scaffold(
            body: Column(
              children: [
                const YumeiroArtworkImage.thumbnail(
                  width: 38,
                  height: 50,
                  semanticLabel: 'Alternative text',
                  icon: Icons.photo,
                ),
                YumeiroListTile.media(
                  title: 'Media result',
                  meta: 'Release information',
                  onTap: () => taps++,
                ),
              ],
            ),
          ),
        ),
      );

      final expectedLines = modality == YumeiroModality.touch ? 2 : 1;
      final title = find.text('Media result');
      final metadata = find.text('Release information');
      expect(tester.widget<Text>(title).maxLines, expectedLines);
      expect(tester.widget<Text>(metadata).maxLines, expectedLines);
      expect(find.bySemanticsLabel('Alternative text'), findsOne);
      expect(
        tester.getSize(find.byType(YumeiroArtworkImage).first),
        const Size(38, 50),
      );
      final thumbnail = find.descendant(
        of: find.byType(YumeiroListTile),
        matching: find.byType(YumeiroArtworkImage),
      );
      expect(tester.getSize(thumbnail), const Size(44, 58));
      await tester.tap(title);
    }

    expect(taps, YumeiroModality.values.length);
  });
}
