import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

void main() {
  testWidgets('vertical segments keep the same highlight inset in both modes', (
    tester,
  ) async {
    const label = 'Selected option';
    final shell = find.byWidgetPredicate(
      (widget) =>
          widget is YumeiroVisualSurface &&
          widget.role == YumeiroControlRole.secondary,
    );
    final row = find.ancestor(
      of: find.text(label),
      matching: find.byType(YumeiroInteractiveVisualSurface),
    );
    final highlight = find.descendant(
      of: row,
      matching: find.byType(YumeiroResolvedVisualSurface),
    );

    final pixel = YumeiroThemePresets.pixelDark;
    for (final (preset, gap) in [
      (pixel, 3.0),
      (pixel.copyWith(spacing: pixel.spacing.copyWith(xs: 12)), 6.0),
    ]) {
      for (final modality in YumeiroModality.values) {
        await tester.pumpWidget(
          YumeiroApp(
            preset: preset,
            modality: modality,
            home: Scaffold(
              body: YumeiroSegmentedControl.vertical(
                options: const [YumeiroSegmentOption(value: 0, label: label)],
                value: 0,
                onChanged: (_) {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final outer = tester.getRect(shell);
        final inner = tester.getRect(highlight);
        expect(inner, outer.deflate(gap), reason: modality.name);
      }
    }
  });

  testWidgets('pointer vertical segments reserve space for the checkmark', (
    tester,
  ) async {
    const segmentKey = ValueKey('vertical segments');
    var selected = 0;
    await tester.pumpWidget(
      YumeiroApp(
        modality: YumeiroModality.pointer,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => SizedBox(
              width: 190,
              child: YumeiroSegmentedControl.vertical(
                key: segmentKey,
                options: const [
                  YumeiroSegmentOption(value: 0, label: 'First'),
                  YumeiroSegmentOption(
                    value: 1,
                    label: 'Second',
                    subtitle: 'short caption',
                  ),
                ],
                value: selected,
                onChanged: (next) => setState(() => selected = next),
              ),
            ),
          ),
        ),
      ),
    );
    final segments = find.byKey(segmentKey);
    final before = tester.getSize(segments);
    await tester.tap(find.text('Second'));
    await tester.pumpAndSettle();
    expect(selected, 1);
    expect(tester.getSize(segments), before);
  });

  for (final modality in YumeiroModality.values) {
    testWidgets(
      'shared segment options retain both layouts in ${modality.name}',
      (tester) async {
        const options = [
          YumeiroSegmentOption(
            value: 'images',
            icon: Icons.image,
            tooltip: 'Show images',
          ),
          YumeiroSegmentOption(
            value: 'details',
            label: 'Details',
            subtitle: 'More about this item',
            leading: Icon(Icons.layers_outlined),
          ),
        ];
        var value = 'details';

        Future<void> pump({required bool vertical}) => tester.pumpWidget(
          YumeiroApp(
            modality: modality,
            home: Scaffold(
              body: vertical
                  ? YumeiroSegmentedControl.vertical(
                      options: options,
                      value: value,
                      onChanged: (next) => value = next,
                    )
                  : YumeiroSegmentedControl(
                      options: options,
                      value: value,
                      onChanged: (next) => value = next,
                    ),
            ),
          ),
        );

        await pump(vertical: false);
        expect(find.byIcon(Icons.layers_outlined), findsNothing);
        expect(find.text('More about this item'), findsNothing);
        await tester.tap(find.byIcon(Icons.image));
        expect(value, 'images');

        await pump(vertical: true);
        expect(find.byIcon(Icons.layers_outlined), findsOneWidget);
        expect(find.text('More about this item'), findsOneWidget);
        expect(find.bySemanticsLabel('Show images'), findsOneWidget);
        await tester.tap(find.text('Details'));
        expect(value, 'details');
      },
    );
  }
}
