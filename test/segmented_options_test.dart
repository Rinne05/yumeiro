import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/src/components/controls/selection_control.dart';
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
      'unavailable segments keep selection without a tap action in ${modality.name}',
      (tester) async {
        const options = [
          YumeiroSegmentOption(value: 'ready', label: 'Ready'),
          YumeiroSegmentOption(
            value: 'locked',
            label: 'Locked',
            enabled: false,
          ),
        ];
        final changes = <String>[];

        Future<void> pump({
          required bool vertical,
          required bool expanded,
          required bool editable,
        }) => tester.pumpWidget(
          YumeiroApp(
            preset: YumeiroThemePresets.pixelDark,
            modality: modality,
            home: Scaffold(
              body: SizedBox(
                width: 160,
                child: vertical
                    ? YumeiroSegmentedControl.vertical(
                        options: options,
                        value: 'locked',
                        onChanged: editable ? changes.add : null,
                        showCheckmark: false,
                      )
                    : YumeiroSegmentedControl(
                        options: options,
                        value: 'locked',
                        onChanged: editable ? changes.add : null,
                        expand: expanded,
                      ),
              ),
            ),
          ),
        );

        for (final (vertical, expanded) in [
          (false, false),
          (false, true),
          (true, false),
        ]) {
          changes.clear();
          await pump(vertical: vertical, expanded: expanded, editable: true);
          await tester.pumpAndSettle();
          final marker = find.byType(UnavailableSelectionMark);
          expect(marker, findsOneWidget);
          expect(
            tester.widget<UnavailableSelectionMark>(marker).selected,
            true,
          );

          final locked = find.text('Locked');
          final lockedContext = tester.element(locked);
          final selectedVisual = YumeiroTheme.of(lockedContext).visuals
              .item(YumeiroItemRole.selection, {WidgetState.selected});
          expect(
            DefaultTextStyle.of(lockedContext).style.color,
            selectedVisual.foreground,
          );
          final rowOpacity = find.ancestor(
            of: marker,
            matching: find.byType(AnimatedOpacity),
          );
          expect(
            tester
                .widgetList<AnimatedOpacity>(rowOpacity)
                .map((widget) => widget.opacity),
            everyElement(1.0),
          );
          expect(
            tester.getSemantics(locked),
            isSemantics(
              isSelected: true,
              hasEnabledState: true,
              isEnabled: false,
              hasTapAction: false,
            ),
          );
          await tester.tapAt(tester.getCenter(locked));
          expect(changes, isEmpty);
          await tester.tap(find.text('Ready'));
          expect(changes, ['ready']);

          await pump(vertical: vertical, expanded: expanded, editable: false);
          await tester.pumpAndSettle();
          expect(marker, findsNothing);
        }
      },
    );

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
