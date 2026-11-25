import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yumeiro/yumeiro.dart';

Finder _paintedSurfaceUnder(Finder control) => find
    .descendant(
      of: control,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is YumeiroResolvedVisualSurface &&
            widget.visualInsets == null,
        description: 'resolved surface that paints at its own bounds',
      ),
    )
    .first;

void main() {
  group('Unified Modality & Density convergence', () {
    testWidgets('pointer token delete appears on hover or keyboard focus', (
      tester,
    ) async {
      var values = <String>['Shader'];
      await tester.pumpWidget(
        YumeiroApp(
          modality: YumeiroModality.pointer,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 440,
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: StatefulBuilder(
                    builder: (context, setState) => YumeiroTokenInput<String>(
                      title: 'Tags',
                      values: values,
                      onChanged: (next) => setState(() => values = next),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final label = find.text('Shader');
      final delete = find.byTooltip('Remove Shader');
      final fade = find
          .ancestor(of: delete, matching: find.byType(AnimatedOpacity))
          .first;
      final labelBounds = tester.getRect(label);
      final deleteBounds = tester.getRect(delete);
      expect(tester.widget<AnimatedOpacity>(fade).opacity, 0);
      expect(deleteBounds.right, lessThan(labelBounds.left));

      final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await pointer.addPointer(location: labelBounds.center);
      await tester.pumpAndSettle();
      expect(tester.widget<AnimatedOpacity>(fade).opacity, 1);
      expect(tester.getRect(label), labelBounds);
      expect(tester.getRect(delete), deleteBounds);
      await pointer.removePointer();
      await tester.pumpAndSettle();
      expect(tester.widget<AnimatedOpacity>(fade).opacity, 0);

      await tester.tap(find.byType(EditableText));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(tester.widget<AnimatedOpacity>(fade).opacity, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(values, isEmpty);
    });

    testWidgets(
      'YumeiroNavigationShell adapts across pointer sidebar, wide touch rail, and compact bottom bar',
      (tester) async {
        const destinations = [
          YumeiroNavDestination(
            id: 'home',
            label: 'Home',
            icon: Icons.home_outlined,
          ),
          YumeiroNavDestination(
            id: 'settings',
            label: 'Settings',
            icon: Icons.settings_outlined,
          ),
        ];

        // Wide pointer viewport -> sidebar
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          YumeiroApp(
            modality: YumeiroModality.pointer,
            home: YumeiroNavigationShell(
              destinations: destinations,
              selectedIndex: 0,
              onSelectedIndex: (_) {},
              body: const Center(child: Text('Body')),
            ),
          ),
        );
        expect(find.byType(ListView), findsOneWidget);
        expect(find.byType(SingleChildScrollView), findsNothing);

        // Wide touch viewport -> touch navigation rail
        await tester.pumpWidget(
          YumeiroApp(
            modality: YumeiroModality.touch,
            home: YumeiroNavigationShell(
              destinations: destinations,
              selectedIndex: 0,
              onSelectedIndex: (_) {},
              body: const Center(child: Text('Body')),
            ),
          ),
        );
        expect(find.byType(SingleChildScrollView), findsOneWidget);
        expect(find.byType(ListView), findsNothing);

        // Compact touch viewport -> bottom navigation bar
        tester.view.physicalSize = const Size(390, 844);
        await tester.pumpWidget(
          YumeiroApp(
            modality: YumeiroModality.touch,
            home: YumeiroNavigationShell(
              destinations: destinations,
              selectedIndex: 0,
              onSelectedIndex: (_) {},
              body: const Center(child: Text('Body')),
            ),
          ),
        );
        expect(find.byType(NavigationBar), findsOneWidget);
        expect(find.byType(SingleChildScrollView), findsNothing);
        expect(find.byType(ListView), findsNothing);
        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Settings'), findsOneWidget);
      },
    );

    testWidgets(
      'desktop sidebar indicator aligns to item left edge and stylized presets omit redundant strip',
      (tester) async {
        const destinations = [
          YumeiroNavDestination(
            id: 'home',
            label: 'Home',
            icon: Icons.home_outlined,
          ),
          YumeiroNavDestination(
            id: 'settings',
            label: 'Settings',
            icon: Icons.settings_outlined,
          ),
        ];

        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          YumeiroApp(
            preset: YumeiroThemePresets.classicDark,
            modality: YumeiroModality.pointer,
            home: YumeiroNavigationShell(
              destinations: destinations,
              selectedIndex: 0,
              onSelectedIndex: (_) {},
              body: const SizedBox.shrink(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final selectedItem = find
            .ancestor(
              of: find.text('Home'),
              matching: find.byType(YumeiroInteractiveVisualSurface),
            )
            .first;
        final itemRect = tester.getRect(selectedItem);
        final indicator = find.descendant(
          of: selectedItem,
          matching: find.byWidgetPredicate(
            (w) => w is YumeiroResolvedVisualSurface && w.width == 3,
          ),
        );
        expect(indicator, findsOneWidget);
        final indicatorRect = tester.getRect(indicator);
        expect(indicatorRect.left, closeTo(itemRect.left, 0.01));
        expect(indicatorRect.width, 3);

        // Stylized presets with destinationBackground emphasize the row/pill,
        // so they should not inject an extra edge strip into `indicator`.
        await tester.pumpWidget(
          YumeiroApp(
            preset: YumeiroThemePresets.liquidGlassDark,
            modality: YumeiroModality.pointer,
            home: YumeiroNavigationShell(
              destinations: destinations,
              selectedIndex: 0,
              onSelectedIndex: (_) {},
              body: const SizedBox.shrink(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final glassVisual = YumeiroTheme.of(tester.element(find.text('Home')))
            .visuals
            .navigationItem(const {WidgetState.selected});
        expect(glassVisual.indicator, isNull);
        expect(glassVisual.destinationIndicator, isNotNull);
      },
    );

    testWidgets(
      'mobile bottom navigation destinationIndicator encloses both icon and label',
      (tester) async {
        const destinations = [
          YumeiroNavDestination(
            id: 'home',
            label: 'Home',
            icon: Icons.home_outlined,
          ),
          YumeiroNavDestination(
            id: 'library',
            label: 'Library',
            icon: Icons.video_library_outlined,
          ),
        ];

        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        var selectedIndex = 0;
        await tester.pumpWidget(
          YumeiroApp(
            preset: YumeiroThemePresets.liquidGlassDark,
            modality: YumeiroModality.touch,
            home: StatefulBuilder(
              builder: (context, setState) => YumeiroNavigationShell(
                destinations: destinations,
                selectedIndex: selectedIndex,
                onSelectedIndex: (index) =>
                    setState(() => selectedIndex = index),
                body: const SizedBox.shrink(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final bar = find.byType(NavigationBar);
        expect(bar, findsOneWidget);
        final indicator = find.byType(AnimatedPositioned);
        expect(indicator, findsOneWidget);

        final bounds = tester.getRect(indicator);
        final iconCenter = tester.getCenter(find.byIcon(Icons.home_outlined));
        final labelRect = tester.getRect(find.text('Home'));
        expect(bounds.contains(iconCenter), isTrue);
        expect(bounds.contains(labelRect.topLeft), isTrue);
        expect(bounds.contains(labelRect.bottomRight), isTrue);

        await tester.tap(find.text('Library'));
        await tester.pumpAndSettle();
        expect(selectedIndex, 1);

        final nextBounds = tester.getRect(indicator);
        final nextIconCenter = tester.getCenter(
          find.byIcon(Icons.video_library_outlined),
        );
        final nextLabelRect = tester.getRect(find.text('Library'));
        expect(nextBounds.contains(nextIconCenter), isTrue);
        expect(nextBounds.contains(nextLabelRect.topLeft), isTrue);
        expect(nextBounds.contains(nextLabelRect.bottomRight), isTrue);
      },
    );

    testWidgets(
      'mobile bottom navigation hover highlight encloses both icon and label identically to selected indicator',
      (tester) async {
        const destinations = [
          YumeiroNavDestination(
            id: 'home',
            label: 'Home',
            icon: Icons.home_outlined,
          ),
          YumeiroNavDestination(
            id: 'library',
            label: 'Library',
            icon: Icons.video_library_outlined,
          ),
        ];

        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          YumeiroApp(
            preset: YumeiroThemePresets.liquidGlassDark,
            modality: YumeiroModality.touch,
            home: YumeiroNavigationShell(
              destinations: destinations,
              selectedIndex: 0,
              onSelectedIndex: (_) {},
              body: const SizedBox.shrink(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final navBarTheme = NavigationBarTheme.of(
          tester.element(find.byType(NavigationBar)),
        );
        expect(
          navBarTheme.overlayColor?.resolve(const {WidgetState.hovered}),
          Colors.transparent,
        );

        final selectedBounds = tester.getRect(find.byType(AnimatedPositioned));
        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);

        await gesture.moveTo(tester.getCenter(find.text('Library')));
        await tester.pumpAndSettle();

        final hoverSurfaceFinder = find.byWidgetPredicate(
          (widget) =>
              widget is YumeiroVisualSurface &&
              widget.role == YumeiroItemRole.navigation &&
              widget.states.contains(WidgetState.hovered),
        );
        expect(hoverSurfaceFinder, findsOneWidget);

        final hoverBounds = tester.getRect(hoverSurfaceFinder);
        final libraryIconCenter = tester.getCenter(
          find.byIcon(Icons.video_library_outlined),
        );
        final libraryLabelRect = tester.getRect(find.text('Library'));
        expect(hoverBounds.size, selectedBounds.size);
        expect(hoverBounds.top, selectedBounds.top);
        expect(hoverBounds.contains(libraryIconCenter), isTrue);
        expect(hoverBounds.contains(libraryLabelRect.topLeft), isTrue);
        expect(hoverBounds.contains(libraryLabelRect.bottomRight), isTrue);
      },
    );

    testWidgets(
      'badges and chips share standard and dense visual heights across modalities',
      (tester) async {
        Future<void> pumpShowcase(YumeiroModality modality) async {
          await tester.pumpWidget(
            YumeiroApp(
              modality: modality,
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const YumeiroBadge(
                        label: 'Status',
                        statusRole: YumeiroStatusRole.success,
                      ),
                      const YumeiroBadge(label: 'Meta'),
                      const YumeiroBadge(label: 'DenseMeta', dense: true),
                      const YumeiroChip(label: 'PassiveChip'),
                      const YumeiroChip(label: 'DenseChip', dense: true),
                      YumeiroChip(
                        label: 'InteractiveChip',
                        selected: true,
                        onTap: () {},
                        onDeleted: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
        }

        // Pointer modality: standard 26.0, dense 22.0
        await pumpShowcase(YumeiroModality.pointer);
        expect(
          tester.getSize(find.widgetWithText(YumeiroBadge, 'Status')).height,
          26.0,
        );
        expect(
          tester.getSize(find.widgetWithText(YumeiroBadge, 'Meta')).height,
          26.0,
        );
        expect(
          tester.getSize(find.widgetWithText(YumeiroBadge, 'DenseMeta')).height,
          22.0,
        );
        expect(
          tester
              .getSize(find.widgetWithText(YumeiroChip, 'PassiveChip'))
              .height,
          26.0,
        );
        expect(
          tester.getSize(find.widgetWithText(YumeiroChip, 'DenseChip')).height,
          22.0,
        );
        expect(
          tester
              .getSize(find.widgetWithText(YumeiroChip, 'InteractiveChip'))
              .height,
          26.0,
        );

        // Touch modality: standard 30.0, dense 24.0, interactive hit box 48.0 with centered 30.0 visual pill
        await pumpShowcase(YumeiroModality.touch);
        expect(
          tester.getSize(find.widgetWithText(YumeiroBadge, 'Status')).height,
          30.0,
        );
        expect(
          tester.getSize(find.widgetWithText(YumeiroBadge, 'Meta')).height,
          30.0,
        );
        expect(
          tester.getSize(find.widgetWithText(YumeiroBadge, 'DenseMeta')).height,
          24.0,
        );
        expect(
          tester
              .getSize(find.widgetWithText(YumeiroChip, 'PassiveChip'))
              .height,
          30.0,
        );
        expect(
          tester.getSize(find.widgetWithText(YumeiroChip, 'DenseChip')).height,
          24.0,
        );
        final interactiveChipFinder = find.widgetWithText(
          YumeiroChip,
          'InteractiveChip',
        );
        expect(tester.getSize(interactiveChipFinder).height, 48.0);
        final interactiveVisualSurface = find
            .descendant(
              of: interactiveChipFinder,
              matching: find.byType(YumeiroResolvedVisualSurface),
            )
            .first;
        expect(tester.getSize(interactiveVisualSurface).height, 30.0);
      },
    );

    testWidgets(
      'inline controls converge on standard and dense heights across modalities',
      (tester) async {
        Future<void> pumpControls(YumeiroModality modality) async {
          await tester.pumpWidget(
            YumeiroApp(
              modality: modality,
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      YumeiroButton(
                        key: const Key('std-btn'),
                        label: 'Button',
                        onPressed: () {},
                      ),
                      const YumeiroTextField(
                        key: Key('std-input'),
                        hintText: 'Input',
                      ),
                      YumeiroSelect<String>(
                        key: const Key('std-select'),
                        value: 'a',
                        options: const [
                          YumeiroSelectionOption(value: 'a', label: 'Alpha'),
                        ],
                        onChanged: (_) {},
                      ),
                      YumeiroSelect<String>.menu(
                        key: const Key('std-dropdown'),
                        value: 'a',
                        options: const [
                          YumeiroSelectionOption(value: 'a', label: 'Alpha'),
                        ],
                        onChanged: (_) {},
                      ),
                      YumeiroSelect<String>.searchable(
                        key: const Key('std-search-dropdown'),
                        value: 'a',
                        options: const [
                          YumeiroSelectionOption(value: 'a', label: 'Alpha'),
                        ],
                        onChanged: (_) {},
                      ),
                      YumeiroSegmentedControl<int>(
                        key: const Key('std-seg'),
                        value: 0,
                        options: const [
                          YumeiroSegmentOption(value: 0, label: 'One'),
                          YumeiroSegmentOption(value: 1, label: 'Two'),
                        ],
                        onChanged: (_) {},
                      ),
                      YumeiroSelectionRow(
                        card: true,
                        key: const Key('std-checktile'),
                        selected: true,
                        onChanged: (_) {},
                        title: const Text('Tile'),
                      ),
                      YumeiroRatingEditor(
                        key: const Key('std-rating'),
                        value: 3,
                        onChanged: (_) {},
                      ),
                      YumeiroButton(
                        key: const Key('dense-btn'),
                        label: 'DenseBtn',
                        dense: true,
                        onPressed: () {},
                      ),
                      const YumeiroTextField(
                        key: Key('dense-input'),
                        hintText: 'DenseInput',
                        dense: true,
                      ),
                      YumeiroSelect<String>(
                        key: const Key('dense-select'),
                        value: 'a',
                        dense: true,
                        options: const [
                          YumeiroSelectionOption(value: 'a', label: 'Alpha'),
                        ],
                        onChanged: (_) {},
                      ),
                      YumeiroSelect<String>.menu(
                        key: const Key('dense-dropdown'),
                        value: 'a',
                        dense: true,
                        options: const [
                          YumeiroSelectionOption(value: 'a', label: 'Alpha'),
                        ],
                        onChanged: (_) {},
                      ),
                      YumeiroSelect<String>.searchable(
                        key: const Key('dense-search-dropdown'),
                        value: 'a',
                        dense: true,
                        options: const [
                          YumeiroSelectionOption(value: 'a', label: 'Alpha'),
                        ],
                        onChanged: (_) {},
                      ),
                      YumeiroSegmentedControl<int>(
                        key: const Key('dense-seg'),
                        value: 0,
                        dense: true,
                        options: const [
                          YumeiroSegmentOption(value: 0, label: 'One'),
                          YumeiroSegmentOption(value: 1, label: 'Two'),
                        ],
                        onChanged: (_) {},
                      ),
                      YumeiroSelectionRow(
                        card: true,
                        key: const Key('dense-checktile'),
                        selected: true,
                        dense: true,
                        onChanged: (_) {},
                        title: const Text('DenseTile'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
        }

        const standardControls = [
          'std-btn',
          'std-input',
          'std-select',
          'std-dropdown',
          'std-search-dropdown',
          'std-seg',
          'std-checktile',
          'std-rating',
        ];
        const denseControls = [
          'dense-btn',
          'dense-input',
          'dense-select',
          'dense-dropdown',
          'dense-search-dropdown',
          'dense-seg',
          'dense-checktile',
        ];

        for (final modality in YumeiroModality.values) {
          await pumpControls(modality);
          final touch = modality == YumeiroModality.touch;
          for (final (controls, height) in [
            (standardControls, touch ? 48.0 : 40.0),
            (denseControls, touch ? 48.0 : 30.0),
          ]) {
            for (final key in controls) {
              expect(
                tester.getSize(find.byKey(Key(key))).height,
                height,
                reason: '$modality $key',
              );
            }
          }
          if (touch) {
            for (final key in const [
              'std-select',
              'std-dropdown',
              'std-search-dropdown',
            ]) {
              final visualSurface = _paintedSurfaceUnder(find.byKey(Key(key)));
              expect(
                tester.getSize(visualSurface).height,
                40.0,
                reason: '$key visual pill',
              );
            }
          }
        }
      },
    );

    testWidgets(
      'token chips, callout, settings rows, headers, and slider readout align typography and geometry',
      (tester) async {
        Future<void> pumpLayoutAndDisplay(YumeiroModality modality) async {
          await tester.pumpWidget(
            YumeiroApp(
              modality: modality,
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const YumeiroPageHeader(
                        title: 'Header',
                        subtitle: 'Header Subtitle',
                      ),
                      YumeiroSettingsSection(
                        title: 'Section',
                        subtitle: 'Section Subtitle',
                        children: [
                          const YumeiroSettingRow(
                            title: 'Setting Title',
                            subtitle: 'Setting Subtitle',
                          ),
                          YumeiroSettingRow.select<String>(
                            title: 'Selection Title',
                            subtitle: 'Selection Subtitle',
                            value: 'a',
                            options: const [
                              YumeiroSelectionOption(value: 'a', label: 'A'),
                            ],
                            onChanged: (_) {},
                          ),
                        ],
                      ),
                      const YumeiroCallout(
                        title: 'Callout Title',
                        message: 'Callout Message',
                      ),
                      const YumeiroEmptyState(
                        title: 'Compact Empty',
                        message: 'Nothing here',
                        compact: true,
                      ),
                      YumeiroSlider(
                        value: 0.5,
                        valueLabel: '50%',
                        onChanged: (_) {},
                      ),
                      YumeiroTokenInput<String>(
                        title: 'Tokens',
                        values: const ['Shader'],
                        onChanged: (_) {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
        }

        // Pointer verification
        await pumpLayoutAndDisplay(YumeiroModality.pointer);
        final pointerCalloutTitle = tester.widget<Text>(
          find.text('Callout Title'),
        );
        final pointerCalloutMsg = tester.widget<Text>(
          find.text('Callout Message'),
        );
        expect(pointerCalloutTitle.style?.fontSize, 14.0);
        expect(pointerCalloutMsg.style?.fontSize, 11.5);
        expect(
          DefaultTextStyle.of(tester.element(find.text('Setting Title')))
              .style
              .fontSize,
          14.0,
        );
        expect(
          tester.widget<Text>(find.text('Compact Empty')).style?.fontSize,
          14.0,
        );
        expect(
          tester.widget<Text>(find.text('Header Subtitle')).style?.fontSize,
          11.5,
        );
        expect(
          tester.widget<Text>(find.text('Section Subtitle')).style?.fontSize,
          11.5,
        );
        final pointerTokenSurface = find
            .ancestor(
              of: find.text('Shader'),
              matching: find.byType(YumeiroResolvedVisualSurface),
            )
            .first;
        expect(tester.getSize(pointerTokenSurface).height, 26.0);
        expect(
          tester.getTopLeft(pointerTokenSurface).dx,
          tester.getTopLeft(find.text('Tokens')).dx,
        );

        // Touch verification
        await pumpLayoutAndDisplay(YumeiroModality.touch);
        final touchCalloutTitle = tester.widget<Text>(
          find.text('Callout Title'),
        );
        final touchCalloutMsg = tester.widget<Text>(
          find.text('Callout Message'),
        );
        expect(touchCalloutTitle.style?.fontSize, 16.0);
        expect(touchCalloutMsg.style?.fontSize, 14.0);
        expect(
          touchCalloutTitle.style!.fontSize!,
          greaterThan(touchCalloutMsg.style!.fontSize!),
        );

        // Touch setting rows share an inset for the label and trailing edge.
        final selectionTitle = find.text('Selection Title');
        final selectionSurface = find.ancestor(
          of: selectionTitle,
          matching: find.byType(YumeiroInteractiveVisualSurface),
        );
        final context = tester.element(selectionTitle);
        final theme = YumeiroTheme.of(context);
        final padding = YumeiroModalityScope.metricsOf(context)
            .horizontalPadding;
        final rowBounds = tester.getRect(selectionSurface);
        final chevron = find.descendant(
          of: selectionSurface,
          matching: find.byIcon(theme.icons.chevronRight),
        );
        final settingLeft = tester.getTopLeft(find.text('Setting Title')).dx;
        final selectionLeft = tester.getTopLeft(selectionTitle).dx;
        expect(selectionLeft, settingLeft);
        expect(selectionLeft, rowBounds.left + padding);
        expect(tester.getTopRight(chevron).dx, rowBounds.right - padding);

        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: rowBounds.center);
        await tester.pumpAndSettle();
        expect(
          tester.getRect(_paintedSurfaceUnder(selectionSurface)),
          rowBounds.deflate(theme.spacing.xs / 2),
        );
        await mouse.removePointer();

        // The remove action uses the full 48-pixel target of the 30-pixel pill.
        final touchTokenWrapper = find
            .ancestor(
              of: find.text('Shader'),
              matching: find.byType(YumeiroVisualSurface),
            )
            .first;
        expect(
          tester.getTopLeft(touchTokenWrapper).dx,
          tester.getTopLeft(find.text('Tokens')).dx,
        );
        expect(tester.getSize(touchTokenWrapper).height, 48.0);
        final touchTokenSurface = _paintedSurfaceUnder(touchTokenWrapper);
        expect(tester.getSize(touchTokenSurface).height, 30.0);
        expect(
          tester.getSize(find.byTooltip('Remove Shader')),
          const Size(24.0, 48.0),
        );
      },
    );
  });
}
