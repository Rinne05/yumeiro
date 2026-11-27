import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

const _window = Size(390, 844);
const _safePadding = FakeViewPadding(top: 24, bottom: 24);
const _gap = 12.0;

void main() {
  testWidgets('an inline navigation bar leaves the global toast inset alone', (
    tester,
  ) async {
    _configureWindow(tester);
    final controller = YumeiroToastController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(
        controller: controller,
        home: const Align(
          alignment: Alignment.topCenter,
          child: SizedBox(height: 320, child: _NavigationPage()),
        ),
      ),
    );
    controller.show(message: 'Saved', duration: Duration.zero);
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(
      tester.getRect(find.byType(YumeiroToast)).bottom,
      closeTo(_window.height - _safePadding.bottom - _gap, .01),
    );
  });

  testWidgets('a bounded toast host clears its own bottom navigation', (
    tester,
  ) async {
    _configureWindow(tester);
    final controller = YumeiroToastController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      YumeiroApp(
        modality: YumeiroModality.touch,
        home: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            height: 320,
            child: YumeiroToastHost(
              controller: controller,
              child: const _NavigationPage(),
            ),
          ),
        ),
      ),
    );
    controller.show(message: 'Saved', duration: Duration.zero);
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byType(YumeiroToast)).bottom,
      closeTo(tester.getTopLeft(find.byType(NavigationBar)).dy - _gap, .01),
    );
  });

  testWidgets('bounded hosts only clear overlapping bottom view insets', (
    tester,
  ) async {
    _configureWindow(tester);
    final controller = YumeiroToastController();
    final top = ValueNotifier(0.0);
    addTearDown(controller.dispose);
    addTearDown(top.dispose);
    const hostHeight = 320.0;
    await tester.pumpWidget(
      YumeiroApp(
        modality: YumeiroModality.touch,
        home: ValueListenableBuilder<double>(
          valueListenable: top,
          builder: (_, offset, child) => Stack(
            children: [
              Positioned(
                top: offset,
                left: 0,
                right: 0,
                height: hostHeight,
                child: child!,
              ),
            ],
          ),
          child: YumeiroToastHost(
            controller: controller,
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
    controller.show(message: 'Saved', duration: Duration.zero);
    await tester.pumpAndSettle();
    final toast = find.byType(YumeiroToast);
    expect(tester.getRect(toast).bottom, closeTo(hostHeight - _gap, .01));

    const keyboard = 300.0;
    tester.view.viewInsets = const FakeViewPadding(bottom: keyboard);
    tester.view.padding = const FakeViewPadding(top: 24);
    await tester.pumpAndSettle();
    expect(tester.getRect(toast).bottom, closeTo(hostHeight - _gap, .01));

    top.value = 300;
    await tester.pumpAndSettle();
    expect(
      tester.getRect(toast).bottom,
      closeTo(_window.height - keyboard - _gap, .01),
    );
  });

  testWidgets('touch toast clears the actual navigation bar and keyboard', (
    tester,
  ) async {
    _configureWindow(tester);
    final controller = YumeiroToastController();
    final showBar = ValueNotifier(true);
    addTearDown(controller.dispose);
    addTearDown(showBar.dispose);
    await tester.pumpWidget(
      _app(
        controller: controller,
        home: SafeArea(
          top: false,
          child: ValueListenableBuilder(
            valueListenable: showBar,
            builder: (_, visible, _) =>
                visible ? const _NavigationPage() : const Scaffold(),
          ),
        ),
      ),
    );
    controller.show(message: 'Saved', duration: Duration.zero);
    await tester.pumpAndSettle();

    final toast = find.byType(YumeiroToast);
    final bar = find.byType(NavigationBar);
    expect(
      tester.getRect(toast).bottom,
      closeTo(tester.getTopLeft(bar).dy - _gap, .01),
    );

    const keyboard = 300.0;
    tester.view.viewInsets = const FakeViewPadding(bottom: keyboard);
    tester.view.padding = const FakeViewPadding(top: 24);
    await tester.pumpAndSettle();
    expect(
      tester.getRect(toast).bottom,
      closeTo(_window.height - keyboard - _gap, .01),
    );

    tester.view.viewInsets = const FakeViewPadding();
    tester.view.padding = _safePadding;
    showBar.value = false;
    await tester.pumpAndSettle();
    expect(bar, findsNothing);
    expect(
      tester.getRect(toast).bottom,
      closeTo(_window.height - _safePadding.bottom - _gap, .01),
    );
  });

  testWidgets('touch toast follows the current route navigation', (
    tester,
  ) async {
    _configureWindow(tester);
    final controller = YumeiroToastController();
    final navigator = GlobalKey<NavigatorState>();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(
        controller: controller,
        navigatorKey: navigator,
        home: const _NavigationPage(),
      ),
    );
    controller.show(message: 'Saved', duration: Duration.zero);
    await tester.pumpAndSettle();
    final toast = find.byType(YumeiroToast);
    final bar = find.byType(NavigationBar);
    final navigationClearance = tester.getTopLeft(bar).dy - _gap;
    expect(tester.getRect(toast).bottom, closeTo(navigationClearance, .01));

    unawaited(
      navigator.currentState!.push<void>(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Details')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Details'), findsOneWidget);
    expect(
      tester.getRect(toast).bottom,
      closeTo(_window.height - _safePadding.bottom - _gap, .01),
    );

    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(tester.getRect(toast).bottom, closeTo(navigationClearance, .01));
  });

  testWidgets('touch toast still clears navigation behind a dialog', (
    tester,
  ) async {
    _configureWindow(tester);
    final controller = YumeiroToastController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(controller: controller, home: const _NavigationPage()),
    );
    controller.show(message: 'Saved', duration: Duration.zero);
    await tester.pumpAndSettle();

    final toast = find.byType(YumeiroToast);
    final bar = find.byType(NavigationBar);
    final clearance = tester.getTopLeft(bar).dy - _gap;
    expect(tester.getRect(toast).bottom, closeTo(clearance, .01));

    unawaited(
      showDialog<void>(
        context: tester.element(bar),
        builder: (_) => const AlertDialog(content: Text('Details')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Details'), findsOneWidget);
    expect(bar, findsOneWidget);
    expect(tester.getRect(toast).bottom, closeTo(clearance, .01));
  });
}

void _configureWindow(WidgetTester tester) {
  tester.view.physicalSize = _window;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = _safePadding;
  tester.view.viewPadding = _safePadding;
  addTearDown(tester.view.reset);
}

Widget _app({
  required YumeiroToastController controller,
  required Widget home,
  GlobalKey<NavigatorState>? navigatorKey,
}) => MaterialApp(
  navigatorKey: navigatorKey,
  builder: (_, child) => YumeiroScope(
    modality: YumeiroModality.touch,
    toastController: controller,
    child: child!,
  ),
  home: home,
);

class _NavigationPage extends StatelessWidget {
  const _NavigationPage();

  static void _select(int _) {}

  @override
  Widget build(BuildContext context) => const YumeiroNavigationShell(
    destinations: [
      YumeiroNavDestination(id: 'home', label: 'Home', icon: Icons.home),
      YumeiroNavDestination(
        id: 'settings',
        label: 'Settings',
        icon: Icons.settings,
      ),
    ],
    selectedIndex: 0,
    onSelectedIndex: _select,
    body: SizedBox.expand(),
  );
}
