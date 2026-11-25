import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yumeiro/yumeiro.dart';

void main() {
  const options = [
    YumeiroSelectionOption(value: 0, label: 'Option A'),
    YumeiroSelectionOption(value: 1, label: 'Option B'),
    YumeiroSelectionOption(value: 2, label: 'Option C'),
  ];
  Widget select() => YumeiroSelect<int>(
    value: 0,
    width: 140,
    options: options,
    onChanged: (_) {},
  );
  Finder menu() => find.byWidgetPredicate(
    (widget) =>
        widget is YumeiroVisualSurface &&
        widget.role == YumeiroSurfaceRole.floating,
  );

  testWidgets('pointer pickers share their gap above and below the trigger', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const triggerKey = ValueKey('trigger');
    const gap = 7.0;
    final preset = YumeiroThemePresets.classicDark.copyWith(
      spacing: const YumeiroSpacing(xs: gap),
    );
    final triggers = <String, Widget Function()>{
      'fixed': select,
      'toolbar': () => YumeiroSelect<int>.menu(
        value: 0,
        options: options,
        onChanged: (_) {},
      ),
      'local search': () =>
          YumeiroSelect<int>.searchable(options: options, onChanged: (_) {}),
      'remote search': () => YumeiroAsyncSelect<int>(
        value: null,
        onChanged: (_) {},
        loadOptions: (_) async => options,
      ),
      'multi-select with search': () => YumeiroMultiSelect<int>(
        value: const {},
        options: options,
        searchable: true,
        onChanged: (_) {},
      ),
      'cascading select': () => YumeiroCascadingSelect<int>(
        title: 'Category',
        value: null,
        options: const [
          YumeiroCascadingOption(id: 'first', label: 'First', value: 0),
        ],
        onChanged: (_) {},
      ),
    };

    for (final above in [false, true]) {
      for (final MapEntry(key: name, value: trigger) in triggers.entries) {
        // Remove the previous picker and its overlay before the next case.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(
          YumeiroApp(
            modality: YumeiroModality.pointer,
            preset: preset,
            home: Scaffold(
              body: Stack(
                children: [
                  Positioned(
                    top: above ? 729 : 70,
                    left: 130,
                    width: 230,
                    child: SizedBox(key: triggerKey, child: trigger()),
                  ),
                ],
              ),
            ),
          ),
        );
        final field = find.byKey(triggerKey);
        await tester.tap(field);
        await tester.pumpAndSettle();
        expect(menu(), findsOneWidget, reason: name);
        final editor = find.descendant(
          of: field,
          matching: find.byType(YumeiroTextField),
        );
        final triggerBounds = tester.getRect(
          editor.evaluate().isEmpty ? field : editor,
        );
        final menuBounds = tester.getRect(menu());
        expect(
          above
              ? triggerBounds.top - menuBounds.bottom
              : menuBounds.top - triggerBounds.bottom,
          closeTo(gap, .01),
          reason: '$name (above: $above)',
        );
      }
    }
  });

  testWidgets('a toolbar menu keeps its explicit anchor offset', (
    tester,
  ) async {
    const offset = Offset(12, 9);
    const triggerKey = ValueKey('toolbar');
    await tester.pumpWidget(
      YumeiroApp(
        modality: YumeiroModality.pointer,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: YumeiroSelect<int>.menu(
              key: triggerKey,
              value: 0,
              options: options,
              offset: offset,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    final trigger = find.byKey(triggerKey);
    await tester.tap(trigger);
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(menu()) - tester.getBottomLeft(trigger), offset);
  });

  testWidgets('wide pointer menus align to the trigger start in RTL', (
    tester,
  ) async {
    const triggerKey = ValueKey('trigger');
    final controls = [
      YumeiroSelect<int>.menu(
        options: options,
        value: null,
        width: 150,
        menuWidth: 250,
        onChanged: (_) {},
      ),
      YumeiroSelect<int>.searchable(
        options: options,
        width: 150,
        menuWidth: 250,
        onChanged: (_) {},
      ),
    ];
    for (final control in controls) {
      await tester.pumpWidget(
        YumeiroApp(
          modality: YumeiroModality.pointer,
          home: Scaffold(
            body: Directionality(
              textDirection: TextDirection.rtl,
              child: Center(
                child: SizedBox(key: triggerKey, child: control),
              ),
            ),
          ),
        ),
      );
      final trigger = find.byKey(triggerKey);
      final input = find.byType(TextField);
      await tester.tap(input.evaluate().isEmpty ? trigger : input);
      await tester.pumpAndSettle();
      final popup = tester.getRect(menu());
      expect(popup.width, 250);
      expect(popup.right, closeTo(tester.getRect(trigger).right, .01));
      await tester.tapAt(Offset.zero);
      await tester.pumpAndSettle();
    }
  });

  for (final top in [560.0, 720.0]) {
    testWidgets('pointer select anchors against actual menu height at y=$top', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        YumeiroApp(
          modality: YumeiroModality.pointer,
          home: Scaffold(
            body: Stack(
              children: [Positioned(left: 60, top: top, child: select())],
            ),
          ),
        ),
      );
      final trigger = tester.getRect(find.byType(YumeiroSelect<int>));
      await tester.tap(find.byType(YumeiroSelect<int>));
      await tester.pumpAndSettle();
      final popup = tester.getRect(menu());
      expect(popup.left, closeTo(trigger.left, .01));
      if (top == 560) {
        expect(popup.top, closeTo(trigger.bottom + 4, .01));
      } else {
        expect(popup.bottom, closeTo(trigger.top - 4, .01));
      }
    });
  }

  testWidgets(
    'an open pointer select follows moves with or without new options',
    (tester) async {
      const triggerKey = ValueKey('moving select');
      var offset = const Offset(60, 80);
      var choices = options;
      late StateSetter updateHost;
      await tester.pumpWidget(
        YumeiroApp(
          modality: YumeiroModality.pointer,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                updateHost = setState;
                return Stack(
                  children: [
                    Positioned(
                      left: offset.dx,
                      top: offset.dy,
                      child: YumeiroSelect<int>(
                        key: triggerKey,
                        value: 0,
                        width: 140,
                        options: choices,
                        onChanged: (_) {},
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      final trigger = find.byKey(triggerKey);
      await tester.tap(trigger);
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(menu()) - tester.getBottomLeft(trigger),
        const Offset(0, 4),
      );

      updateHost(() {
        offset += const Offset(40, 116);
        choices = const [
          YumeiroSelectionOption(value: 0, label: 'Current'),
          YumeiroSelectionOption(value: 3, label: 'Just added'),
        ];
      });
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: menu(), matching: find.text('Just added')),
        findsOneWidget,
      );
      expect(
        tester.getTopLeft(menu()) - tester.getBottomLeft(trigger),
        const Offset(0, 4),
      );

      updateHost(() => offset += const Offset(15, 40));
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(menu()) - tester.getBottomLeft(trigger),
        const Offset(0, 4),
      );
    },
  );

  testWidgets(
    'pointer select uses the destination overlay coordinates in nested navigators',
    (tester) async {
      final navigator = Navigator(
        onGenerateRoute: (_) => MaterialPageRoute<void>(
          builder: (_) => Scaffold(body: Center(child: select())),
        ),
      );
      await tester.pumpWidget(
        YumeiroApp(
          modality: YumeiroModality.pointer,
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.only(left: 160, top: 100),
              child: SizedBox(width: 400, height: 400, child: navigator),
            ),
          ),
        ),
      );
      final trigger = tester.getRect(find.byType(YumeiroSelect<int>));
      await tester.tap(find.byType(YumeiroSelect<int>));
      await tester.pumpAndSettle();
      final popup = tester.getRect(menu());
      expect(popup.left, closeTo(trigger.left, .01));
      expect(popup.top, closeTo(trigger.bottom + 4, .01));
    },
  );
}
