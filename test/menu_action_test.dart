import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/src/components/controls/selection_control.dart';
import 'package:yumeiro/yumeiro.dart';

void main() {
  for (final (modality, direction) in [
    for (final modality in YumeiroModality.values)
      for (final direction in TextDirection.values) (modality, direction),
  ]) {
    testWidgets(
      'menu aligns icons and selections in ${modality.name} ${direction.name}',
      (tester) async {
        tester.view.physicalSize = const Size(390, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          YumeiroApp(
            modality: modality,
            home: Directionality(
              textDirection: direction,
              child: Scaffold(
                body: Builder(
                  builder: (context) => YumeiroButton(
                    label: 'Open menu',
                    onPressed: () => YumeiroActionMenu.show(
                      context: context,
                      globalPosition: const Offset(100, 80),
                      items: [
                        YumeiroMenuAction(label: 'Plain', onPressed: () {}),
                        YumeiroMenuAction(
                          label: 'Artwork',
                          icon: Icons.image_outlined,
                          selected: true,
                          shortcut: 'Ctrl+A',
                          onPressed: () {},
                        ),
                        YumeiroMenuAction(
                          label: 'List',
                          selected: true,
                          onPressed: () {},
                        ),
                        YumeiroMenuAction(
                          label: 'Grid',
                          selected: false,
                          onPressed: () {},
                        ),
                        const YumeiroMenuAction(
                          label: 'Locked view',
                          selected: true,
                          enabled: false,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open menu'));
        await tester.pumpAndSettle();

        double startOf(String label) {
          final bounds = tester.getRect(find.text(label));
          return direction == TextDirection.ltr ? bounds.left : bounds.right;
        }

        final start = startOf('Plain');
        for (final label in ['Artwork', 'List', 'Grid', 'Locked view']) {
          expect(startOf(label), closeTo(start, .01));
        }

        final rowType = modality == YumeiroModality.pointer
            ? MenuItemButton
            : YumeiroListTile;
        Finder row(String label) =>
            find.ancestor(of: find.text(label), matching: find.byType(rowType));
        final check = YumeiroTheme.of(tester.element(row('Artwork')))
            .icons
            .check;
        Finder mark(String label) =>
            find.descendant(of: row(label), matching: find.byIcon(check));
        expect(find.byIcon(Icons.image_outlined), findsOneWidget);
        expect(mark('Artwork'), findsOneWidget);
        expect(mark('List'), findsOneWidget);
        expect(mark('Grid'), findsNothing);
        expect(mark('Locked view'), findsNothing);
        final unavailable = find.byType(UnavailableSelectionMark);
        expect(unavailable, findsOneWidget);
        expect(
          tester.widget<UnavailableSelectionMark>(unavailable).selected,
          isTrue,
        );
        expect(
          tester.getCenter(mark('Artwork')).dx,
          tester.getCenter(mark('List')).dx,
        );
        expect(
          tester.getCenter(mark('List')).dx,
          tester.getCenter(unavailable).dx,
        );
      },
    );
  }

  for (final modality in YumeiroModality.values) {
    testWidgets('menu action availability is consistent in $modality', (
      tester,
    ) async {
      var activated = 0;
      var disabledActivated = 0;
      await tester.pumpWidget(
        YumeiroApp(
          modality: modality,
          home: Scaffold(
            body: Builder(
              builder: (context) => YumeiroButton(
                label: 'Open context menu',
                onPressed: () => YumeiroActionMenu.show(
                  context: context,
                  title: 'Menu title',
                  items: [
                    const YumeiroMenuHeader(title: 'Document actions'),
                    const YumeiroMenuAction(label: 'Unavailable command'),
                    YumeiroMenuAction(
                      label: 'Disabled command',
                      enabled: false,
                      onPressed: () => disabledActivated++,
                    ),
                    const YumeiroMenuDivider(),
                    const YumeiroMenuHeader(title: 'Editing'),
                    YumeiroMenuAction(
                      label: 'Run command',
                      shortcut: 'Ctrl+R',
                      onPressed: () => activated++,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open context menu'));
      await tester.pumpAndSettle();

      final missingCallback = find.text('Unavailable command');
      final explicitlyDisabled = find.text('Disabled command');
      final active = find.text('Run command');
      final heading = find.text('Document actions');
      final secondHeading = find.text('Editing');
      final divider = find.byType(Divider);
      expect(find.text('Menu title'), findsOneWidget);
      expect(heading, findsOneWidget);
      expect(secondHeading, findsOneWidget);
      expect(divider, findsOneWidget);
      expect(find.byType(UnavailableSelectionMark), findsNothing);
      expect(
        tester.getTopLeft(heading).dy,
        lessThan(tester.getTopLeft(missingCallback).dy),
      );
      expect(
        tester.getTopLeft(explicitlyDisabled).dy,
        lessThan(tester.getTopLeft(divider).dy),
      );
      expect(
        tester.getTopLeft(divider).dy,
        lessThan(tester.getTopLeft(secondHeading).dy),
      );
      expect(
        tester.getTopLeft(secondHeading).dy,
        lessThan(tester.getTopLeft(active).dy),
      );
      if (modality == YumeiroModality.pointer) {
        expect(find.byType(YumeiroBottomSheet), findsNothing);
        MenuItemButton item(Finder label) => tester.widget<MenuItemButton>(
          find.ancestor(of: label, matching: find.byType(MenuItemButton)),
        );

        expect(item(missingCallback).onPressed, isNull);
        expect(item(explicitlyDisabled).onPressed, isNull);
        expect(item(active).autofocus, isTrue);
        expect(find.text('Ctrl+R'), findsOneWidget);
      } else {
        expect(find.byType(YumeiroBottomSheet), findsOneWidget);
        YumeiroListTile tile(Finder label) => tester.widget<YumeiroListTile>(
          find.ancestor(of: label, matching: find.byType(YumeiroListTile)),
        );

        expect(tile(missingCallback).enabled, isFalse);
        expect(tile(explicitlyDisabled).enabled, isFalse);
        expect(tile(active).enabled, isTrue);
      }

      await tester.tap(missingCallback);
      await tester.tap(explicitlyDisabled);
      await tester.pumpAndSettle();
      expect(active, findsOneWidget);
      expect(disabledActivated, 0);

      await tester.tap(active);
      await tester.pumpAndSettle();
      expect(activated, 1);
      expect(active, findsNothing);
    });
  }
}
