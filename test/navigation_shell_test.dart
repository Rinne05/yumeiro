import 'dart:ui' show PointerDeviceKind, Tristate;

import 'package:flutter/semantics.dart' show SemanticsRole;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

const _badgeKey = ValueKey('library-badge');
const _pageKey = ValueKey('navigation-page');
const _destinations = [
  YumeiroNavDestination(id: 'home', label: 'Home', icon: Icons.home_outlined),
  YumeiroNavDestination(
    id: 'library',
    label: 'Library',
    icon: Icons.video_library_outlined,
    selectedIcon: Icons.video_library,
    badge: ColoredBox(
      key: _badgeKey,
      color: Colors.red,
      child: SizedBox.square(dimension: 10),
    ),
  ),
];

Finder _railIndicator(String destinationId) => find.descendant(
  of: find.byKey(ValueKey(destinationId)),
  matching: find.byWidgetPredicate(
    (widget) =>
        widget is YumeiroResolvedVisualSurface && widget.visualInsets == null,
  ),
);

void main() {
  testWidgets('narrow desktop windows keep pointer controls and the sidebar', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1024, 640);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      YumeiroApp(
        home: YumeiroNavigationShell(
          destinations: _destinations,
          selectedIndex: 0,
          onSelectedIndex: (_) {},
          body: const SizedBox.expand(key: _pageKey),
        ),
      ),
    );
    final page = find.byKey(_pageKey);
    expect(tester.getSize(page).width, 1024 - 210);

    tester.view.physicalSize = const Size(390, 640);
    await tester.pumpAndSettle();
    final context = tester.element(page);
    expect(YumeiroResponsive.of(context).isCompact, isTrue);
    expect(YumeiroModalityScope.modalityOf(context), YumeiroModality.pointer);
    expect(tester.getSize(page).width, 390 - 76);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(SingleChildScrollView), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('touch rail leaves the primary scroll controller to the body', (
    tester,
  ) async {
    late ScrollController primary;
    await tester.pumpWidget(
      YumeiroApp(
        modality: YumeiroModality.touch,
        home: YumeiroNavigationShell(
          destinations: _destinations,
          selectedIndex: 0,
          onSelectedIndex: (_) {},
          body: Builder(
            builder: (context) {
              primary = PrimaryScrollController.of(context);
              return ListView.builder(
                itemCount: 40,
                itemBuilder: (_, index) => Text('Article $index'),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final body = find.descendant(
      of: find.byType(ListView),
      matching: find.byType(Scrollable),
    );
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(primary.positions, [tester.state<ScrollableState>(body).position]);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('touch rail and a tall footer can scroll independently', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(640, 320);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      YumeiroApp(
        modality: YumeiroModality.touch,
        home: YumeiroNavigationShell(
          destinations: [
            for (var index = 0; index < 8; index++)
              YumeiroNavDestination(
                id: 'page-$index',
                label: 'Page $index',
                icon: Icons.article,
              ),
          ],
          selectedIndex: 0,
          onSelectedIndex: (_) {},
          body: const SizedBox.expand(),
          sidebarFooter: SizedBox(
            width: 96,
            child: ListView.builder(
              itemExtent: 44,
              itemCount: 12,
              itemBuilder: (_, index) => Text('Shortcut $index'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final rail = find.byType(SingleChildScrollView);
    final footer = find.byType(ListView);
    ScrollPosition positionOf(Finder finder) => tester
        .state<ScrollableState>(
          find.descendant(of: finder, matching: find.byType(Scrollable)),
        )
        .position;
    final destinationPosition = positionOf(rail);
    final footerPosition = positionOf(footer);
    expect(find.text('Page 0').hitTestable(), findsOneWidget);
    expect(find.text('Shortcut 0').hitTestable(), findsOneWidget);
    await tester.drag(footer, const Offset(0, -130));
    await tester.pumpAndSettle();
    final footerOffset = footerPosition.pixels;
    expect(footerOffset, greaterThan(0));
    expect(destinationPosition.pixels, 0);
    await tester.drag(rail, const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(destinationPosition.pixels, greaterThan(0));
    expect(footerPosition.pixels, footerOffset);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'short touch rail scrolls its selected material with the destination',
    (tester) async {
      tester.view.physicalSize = const Size(640, 320);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final selected = ValueNotifier(0);
      addTearDown(selected.dispose);
      final destinations = [
        for (var i = 0; i < 6; i++)
          YumeiroNavDestination(
            id: 'nav-$i',
            label: 'Destination $i',
            icon: Icons.home,
          ),
      ];
      await tester.pumpWidget(
        YumeiroApp(
          preset: YumeiroThemePresets.liquidGlassDark,
          capability: YumeiroMaterialCapability.blurOnly,
          modality: YumeiroModality.touch,
          home: ValueListenableBuilder(
            valueListenable: selected,
            builder: (context, index, _) => YumeiroNavigationShell(
              destinations: destinations,
              selectedIndex: index,
              onSelectedIndex: (index) => selected.value = index,
              sidebarHeader: const Text('Header'),
              sidebarFooter: const Text('Footer'),
              body: const SizedBox.expand(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final scrolling = find.byType(SingleChildScrollView);
      final lastLabel = find.text('Destination 5');
      final firstLabel = find.text('Destination 0');
      final footer = find.text('Footer');
      final footerPosition = tester.getCenter(footer);
      expect(lastLabel.hitTestable(), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.drag(scrolling, const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(lastLabel.hitTestable(), findsOneWidget);
      await tester.tap(lastLabel);
      await tester.pumpAndSettle();
      expect(selected.value, 5);
      final indicator = _railIndicator('nav-5');
      expect(
        tester
            .widget<YumeiroResolvedVisualSurface>(indicator)
            .appearance
            .opacity,
        greaterThan(0),
      );
      expect(
        tester.getRect(indicator).contains(tester.getCenter(lastLabel)),
        isTrue,
      );
      final previousTop = tester.getTopLeft(indicator).dy;
      final labelOffset = tester.getCenter(lastLabel).dy - previousTop;

      await tester.drag(scrolling, const Offset(0, 450));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(indicator).dy, greaterThan(previousTop));
      expect(
        tester.getCenter(lastLabel).dy - tester.getTopLeft(indicator).dy,
        labelOffset,
      );
      expect(firstLabel.hitTestable(), findsOneWidget);
      expect(tester.getCenter(footer), footerPosition);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('touch rail paints hover and keyboard focus with theme states', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final calls = <int>[];
    await tester.pumpWidget(
      YumeiroApp(
        preset: YumeiroThemePresets.liquidGlassDark,
        capability: YumeiroMaterialCapability.blurOnly,
        modality: YumeiroModality.touch,
        home: YumeiroNavigationShell(
          destinations: _destinations,
          selectedIndex: 0,
          onSelectedIndex: calls.add,
          body: const SizedBox.expand(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final library = find.text('Library');
    final hoverIndicator = _railIndicator('library');
    final selectedIndicator = _railIndicator('home');
    final visuals = YumeiroTheme.of(tester.element(library)).visuals;
    final home = tester.getSemantics(find.text('Home')).getSemanticsData();
    semantics.dispose();
    expect(home.role, SemanticsRole.tab);
    expect(home.flagsCollection.isSelected, Tristate.isTrue);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);

    await mouse.moveTo(tester.getCenter(library));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<YumeiroResolvedVisualSurface>(hoverIndicator)
          .appearance
          .background,
      visuals.item(YumeiroItemRole.navigation, const {
        WidgetState.hovered,
      }).background,
    );
    final hoverBounds = tester.getRect(hoverIndicator);
    expect(hoverBounds.size, tester.getSize(selectedIndicator));
    expect(hoverBounds.contains(tester.getCenter(library)), isTrue);
    expect(
      hoverBounds.contains(
        tester.getCenter(find.byIcon(Icons.video_library_outlined)),
      ),
      isTrue,
    );

    await mouse.moveTo(const Offset(200, 80));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<YumeiroResolvedVisualSurface>(hoverIndicator)
          .appearance
          .focusIndicator
          .isVisible,
      isTrue,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(calls, [1]);
  });

  testWidgets('layout and modality changes keep the body and its focus', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    Future<void> show(Size size, YumeiroModality modality) async {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        MaterialApp(
          home: YumeiroScope(
            modality: modality,
            child: YumeiroNavigationShell(
              destinations: _destinations,
              selectedIndex: 0,
              onSelectedIndex: (_) {},
              body: const Scaffold(body: Center(child: TextField())),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await show(const Size(1280, 800), YumeiroModality.pointer);
    final editor = find.byType(EditableText);
    await tester.enterText(editor, 'Existing draft');
    await tester.pumpAndSettle();
    final element = tester.element(editor);
    final focus = tester.widget<EditableText>(editor).focusNode;
    expect(focus.hasFocus, isTrue);

    for (final (size, modality, navigationType) in [
      (const Size(760, 800), YumeiroModality.pointer, ListView),
      (const Size(760, 800), YumeiroModality.touch, SingleChildScrollView),
      (const Size(390, 800), YumeiroModality.touch, NavigationBar),
      (const Size(390, 800), YumeiroModality.pointer, ListView),
      (const Size(1280, 800), YumeiroModality.pointer, ListView),
    ]) {
      await show(size, modality);
      expect(find.byType(navigationType), findsOneWidget);
      expect(tester.element(editor), same(element));
      expect(
        tester.widget<EditableText>(editor).controller.text,
        'Existing draft',
      );
      expect(tester.widget<EditableText>(editor).focusNode, same(focus));
      expect(focus.hasFocus, isTrue);
      expect(tester.takeException(), isNull);
    }

    await tester.enterText(editor, 'Updated draft');
    expect(
      tester.widget<EditableText>(editor).controller.text,
      'Updated draft',
    );
  });

  testWidgets(
    'fewer than two destinations leave the full viewport to the body',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      for (final (size, modality) in [
        (const Size(390, 800), YumeiroModality.touch),
        (const Size(760, 800), YumeiroModality.touch),
        (const Size(1280, 800), YumeiroModality.pointer),
      ]) {
        tester.view.physicalSize = size;
        for (final count in [0, 1, 2, 0]) {
          await tester.pumpWidget(
            YumeiroApp(
              modality: modality,
              home: YumeiroNavigationShell(
                destinations: _destinations.take(count).toList(),
                selectedIndex: count < 2 ? -1 : 0,
                onSelectedIndex: (_) => fail('Unexpected navigation'),
                sidebarHeader: const Text('Sidebar header'),
                body: const SizedBox.expand(key: _pageKey),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final bounds = tester.getRect(find.byKey(_pageKey));
          if (count < 2) {
            expect(bounds, Offset.zero & size);
            expect(find.byIcon(Icons.home_outlined), findsNothing);
            expect(find.text('Sidebar header'), findsNothing);
          } else {
            expect(bounds.size, isNot(size));
            expect(find.byIcon(Icons.home_outlined), findsOneWidget);
          }
          expect(tester.takeException(), isNull);
        }
      }
    },
  );

  testWidgets('a collapsed sidebar keeps the badge with its selected icon', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final calls = <int>[];

    for (final (width, collapsed, labelVisible) in [
      (760.0, false, false),
      (1280.0, true, false),
      (1280.0, false, true),
      (1280.0, true, false),
    ]) {
      tester.view.physicalSize = Size(width, 800);
      await tester.pumpWidget(
        YumeiroApp(
          modality: YumeiroModality.pointer,
          home: YumeiroNavigationShell(
            destinations: _destinations,
            selectedIndex: 1,
            onSelectedIndex: calls.add,
            collapsed: collapsed,
            body: const SizedBox.expand(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final item = find.ancestor(
        of: find.byIcon(Icons.video_library),
        matching: find.byType(YumeiroInteractiveVisualSurface),
      );
      final badge = find.descendant(of: item, matching: find.byKey(_badgeKey));
      expect(badge, findsOneWidget);
      expect(tester.getRect(item).contains(tester.getCenter(badge)), isTrue);
      expect(
        find.text('Library'),
        labelVisible ? findsOneWidget : findsNothing,
      );
      await tester.tap(find.byIcon(Icons.video_library));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    expect(calls, [1, 1, 1, 1]);
  });
}
