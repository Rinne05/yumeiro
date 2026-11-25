import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

void main() {
  testWidgets('keyboard focus tracking leaves the host strategy in place', (
    tester,
  ) async {
    final manager = FocusManager.instance;
    final originalStrategy = manager.highlightStrategy;
    const hostStrategy = FocusHighlightStrategy.alwaysTraditional;
    manager.highlightStrategy = hostStrategy;
    addTearDown(() => manager.highlightStrategy = originalStrategy);

    final outside = FocusNode();
    final first = FocusNode();
    final second = FocusNode();
    final firstInput = YumeiroInputController();
    final secondInput = YumeiroInputController();
    addTearDown(outside.dispose);
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    addTearDown(firstInput.dispose);
    addTearDown(secondInput.dispose);

    Widget host({required bool showFirst}) => MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            TextButton(
              focusNode: outside,
              onPressed: () {},
              child: const Text('Host'),
            ),
            if (showFirst)
              YumeiroScope(
                key: const ValueKey('first'),
                inputController: firstInput,
                child: TextButton(
                  focusNode: first,
                  onPressed: () {},
                  child: const Text('First'),
                ),
              ),
            YumeiroScope(
              key: const ValueKey('second'),
              inputController: secondInput,
              child: TextButton(
                focusNode: second,
                onPressed: () {},
                child: const Text('Second'),
              ),
            ),
          ],
        ),
      ),
    );

    await tester.pumpWidget(host(showFirst: true));
    expect(manager.highlightStrategy, hostStrategy);
    outside.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    expect(firstInput.showKeyboardFocus, isFalse);
    expect(secondInput.showKeyboardFocus, isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(first.hasFocus, isTrue);
    expect(firstInput.showKeyboardFocus, isTrue);
    expect(secondInput.showKeyboardFocus, isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(second.hasFocus, isTrue);
    expect(secondInput.showKeyboardFocus, isTrue);

    await tester.tap(find.text('Second'));
    expect(secondInput.showKeyboardFocus, isFalse);
    expect(firstInput.showKeyboardFocus, isTrue);

    await tester.pumpWidget(host(showFirst: false));
    expect(manager.highlightStrategy, hostStrategy);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(manager.highlightStrategy, hostStrategy);
  });

  testWidgets('nested dialog uses its requested navigator and local config', (
    tester,
  ) async {
    final outer = GlobalKey<NavigatorState>();
    final inner = GlobalKey<NavigatorState>();
    late BuildContext source;
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: outer,
        builder: (context, child) => YumeiroScope(
          preset: YumeiroThemePresets.classicDark,
          child: child!,
        ),
        home: Navigator(
          key: inner,
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            builder: (_) => YumeiroScope(
              preset: YumeiroThemePresets.classicLight,
              locale: const Locale('zh'),
              modality: YumeiroModality.touch,
              child: Builder(
                builder: (context) {
                  source = context;
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      ),
    );

    for (final useRootNavigator in [false, true]) {
      Widget body(BuildContext context) {
        expect(YumeiroLocalizations.of(context).localeName, 'zh');
        expect(YumeiroModalityScope.modalityOf(context), YumeiroModality.touch);
        expect(
          YumeiroTheme.of(context).presetId,
          YumeiroThemePresets.classicLight.id,
        );
        return Center(
          child: YumeiroButton(
            label: 'Return value',
            onPressed: () => Navigator.of(context).pop(17),
          ),
        );
      }

      final result = useRootNavigator
          ? YumeiroDialog.show<int>(context: source, builder: body)
          : YumeiroDialog.show<int>(
              context: source,
              useRootNavigator: false,
              builder: body,
            );
      await tester.pumpAndSettle();
      expect(outer.currentState!.canPop(), useRootNavigator);
      expect(inner.currentState!.canPop(), !useRootNavigator);
      await tester.tap(find.text('Return value'));
      await tester.pumpAndSettle();
      expect(await result, 17);
    }
  });

  testWidgets(
    'selection sheet positions its global anchor in a nested navigator',
    (tester) async {
      late BuildContext source;
      await tester.pumpWidget(
        YumeiroApp(
          modality: YumeiroModality.pointer,
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 116, top: 74),
                child: SizedBox(
                  width: 520,
                  height: 350,
                  child: Navigator(
                    onGenerateRoute: (_) => MaterialPageRoute<void>(
                      builder: (context) {
                        source = context;
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      const anchor = Rect.fromLTWH(426, 106, 112, 44);
      final result = YumeiroBottomSheet.select<int>(
        context: source,
        useRootNavigator: false,
        title: 'Pick one',
        options: const [YumeiroSelectionOption(value: 1, label: 'One')],
        anchor: anchor,
      );
      await tester.pumpAndSettle();
      final popup = tester.getRect(
        find.byWidgetPredicate(
          (widget) =>
              widget is YumeiroVisualSurface &&
              widget.role == YumeiroSurfaceRole.modal,
        ),
      );
      expect(popup.right, closeTo(anchor.right, .1));
      expect(popup.top, closeTo(anchor.bottom + 8, .1));
      await tester.tap(find.text('One'));
      await tester.pumpAndSettle();
      expect((await result)?.value, 1);
    },
  );
}
