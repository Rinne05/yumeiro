import 'package:flutter/gestures.dart'
    show PointerDeviceKind, PointerHoverEvent;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

void main() {
  test(
    'built-in themes reuse identical configuration and snapshot options',
    () {
      final customizations = <String, Object>{'roundness': 80};
      ThemeData resolve() => yumeiroThemeData(customizations: customizations);

      final original = resolve();
      expect(resolve(), same(original));

      customizations['roundness'] = 120;
      final adjusted = resolve();
      expect(
        adjusted.extension<YumeiroThemeExtension>()!.buttonRadius,
        greaterThan(original.extension<YumeiroThemeExtension>()!.buttonRadius),
      );
      expect(resolve(), same(adjusted));

      var builds = 0;
      final preset = YumeiroThemePresets.classicDark;
      final custom = preset.copyWith(
        materialSchemeBuilder: (colors) {
          builds++;
          return preset.materialSchemeBuilder(colors);
        },
      );
      yumeiroThemeData(preset: custom);
      yumeiroThemeData(preset: custom);
      expect(builds, 2);
    },
  );

  testWidgets('unchanged theme configuration keeps its dependents clean', (
    tester,
  ) async {
    final revision = ValueNotifier(0);
    addTearDown(revision.dispose);
    var builds = 0;
    await tester.pumpWidget(
      ValueListenableBuilder(
        valueListenable: revision,
        child: Builder(
          builder: (context) {
            builds++;
            return ColoredBox(color: YumeiroTheme.of(context).accent);
          },
        ),
        builder: (context, value, child) => YumeiroApp(
          title: 'Revision $value',
          modality: YumeiroModality.pointer,
          accentColor: value == 2 ? Colors.orange : null,
          home: child!,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final initialBuilds = builds;

    revision.value = 1;
    await tester.pumpAndSettle();
    expect(builds, initialBuilds);

    revision.value = 2;
    await tester.pumpAndSettle();
    expect(builds, greaterThan(initialBuilds));
  });

  testWidgets('input-kind changes keep keyboard-focus consumers clean', (
    tester,
  ) async {
    final input = YumeiroInputController();
    addTearDown(input.dispose);
    var builds = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: YumeiroScope(
          inputController: input,
          child: Scaffold(body: _CountingCheckbox(onBuild: () => builds++)),
        ),
      ),
    );
    final initialBuilds = builds;
    input.recordKeyboard();
    await tester.pump();
    expect(builds, greaterThan(initialBuilds));

    final keyboardBuilds = builds;
    input.recordPointerEvent(
      const PointerHoverEvent(kind: PointerDeviceKind.mouse),
    );
    await tester.pump();
    expect(input.lastInputKind, YumeiroLastInputKind.pointer);
    expect(input.showKeyboardFocus, isTrue);
    expect(builds, keyboardBuilds);
  });

  testWidgets(
    'paging only rebuilds page wrappers when scrolling starts or ends',
    (tester) async {
      final previousObserver = debugOnRebuildDirtyWidget;
      addTearDown(() => debugOnRebuildDirtyWidget = previousObserver);
      var wrapperBuilds = 0;
      debugOnRebuildDirtyWidget = (element, _) {
        if (element.widget is AnimatedBuilder &&
            element
                    .findAncestorWidgetOfExactType<
                      YumeiroNavigationPager<int>
                    >() !=
                null) {
          wrapperBuilds++;
        }
      };
      await tester.pumpWidget(
        YumeiroApp(
          home: Scaffold(
            body: YumeiroNavigationPager(
              value: 0,
              values: const [0, 1],
              onChanged: (_) {},
              itemBuilder: (context, value) =>
                  Center(child: Text('Page $value')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final controller = tester
          .widget<PageView>(find.byType(PageView))
          .controller!;
      final animation = controller.animateTo(
        200,
        duration: const Duration(milliseconds: 320),
        curve: Curves.linear,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      expect(controller.position.isScrollingNotifier.value, isTrue);
      wrapperBuilds = 0;

      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 40));
      }
      expect(controller.offset, greaterThan(80));
      expect(wrapperBuilds, 0);

      await tester.pumpAndSettle();
      await animation;
      expect(controller.position.isScrollingNotifier.value, isFalse);
      expect(wrapperBuilds, greaterThan(0));
    },
  );
}

class _CountingCheckbox extends YumeiroCheckbox {
  const _CountingCheckbox({required this.onBuild})
    : super(value: false, onChanged: _ignore);

  final VoidCallback onBuild;

  static void _ignore(bool? value) {}

  @override
  Widget build(BuildContext context) {
    onBuild();
    return super.build(context);
  }
}
