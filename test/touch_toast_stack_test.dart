import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

void main() {
  testWidgets('an idle touch toast host takes its size from its child', (
    tester,
  ) async {
    final controller = YumeiroToastController();
    addTearDown(controller.dispose);
    const hostKey = ValueKey('local toast host');
    const childSize = Size(92, 16);
    await tester.pumpWidget(
      YumeiroApp(
        modality: YumeiroModality.touch,
        home: Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              YumeiroToastHost(
                key: hostKey,
                controller: controller,
                child: SizedBox.fromSize(size: childSize),
              ),
            ],
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byKey(hostKey)), childSize);

    final id = controller.show(message: 'Saved', duration: Duration.zero);
    await tester.pumpAndSettle();
    expect(find.byType(YumeiroToast), findsOneWidget);
    controller.dismiss(id);
    await tester.pump();
    expect(find.byType(YumeiroToast), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byType(YumeiroToast), findsNothing);
    expect(tester.getSize(find.byKey(hostKey)), childSize);
  });

  testWidgets('touch toasts show one card and at most two decorative edges', (
    tester,
  ) async {
    final controller = YumeiroToastController();
    addTearDown(controller.dispose);
    var pageTaps = 0;
    await tester.pumpWidget(
      _host(
        controller,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => pageTaps++,
          child: const SizedBox.expand(),
        ),
      ),
    );
    final ids = [
      for (var index = 1; index <= 4; index++)
        controller.show(message: 'Toast $index', duration: Duration.zero),
    ];
    await tester.pumpAndSettle();
    expect(find.byType(YumeiroToast), findsOneWidget);
    expect(find.text('Toast 4'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('yumeiro-toast-back-layer-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('yumeiro-toast-back-layer-2')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('yumeiro-toast-back-layer-3')),
      findsNothing,
    );

    final front = tester.getRect(find.byType(YumeiroToast));
    await tester.tapAt(Offset(front.center.dx, front.top - 3));
    expect(pageTaps, 1);

    controller.dismiss(ids.last);
    await tester.pumpAndSettle();
    expect(find.byType(YumeiroToast), findsOneWidget);
    expect(find.text('Toast 3'), findsOneWidget);
  });

  for (final alignment in [Alignment.bottomCenter, Alignment.topCenter]) {
    testWidgets('touch toast follows the vertical axis at $alignment', (
      tester,
    ) async {
      final controller = YumeiroToastController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_host(controller, alignment: alignment));

      final id = controller.show(message: 'Saved', duration: Duration.zero);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 32));
      final toast = find.byType(YumeiroToast);
      final entering = tester.getCenter(toast);
      await tester.pumpAndSettle();
      final settled = tester.getCenter(toast);
      final direction = alignment.y.sign;
      expect(entering.dx, closeTo(settled.dx, .1));
      expect((entering.dy - settled.dy) * direction, greaterThan(0));

      controller.dismiss(id);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final exiting = tester.getCenter(toast);
      expect(exiting.dx, closeTo(settled.dx, .1));
      expect((exiting.dy - settled.dy) * direction, greaterThan(0));
      expect(toast.hitTestable(), findsNothing);
      await tester.pumpAndSettle();
      expect(toast, findsNothing);
    });
  }

  testWidgets('touch toasts switch immediately when animations are disabled', (
    tester,
  ) async {
    final controller = YumeiroToastController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_host(controller, disableAnimations: true));
    controller.show(message: 'First', duration: Duration.zero);
    final second = controller.show(message: 'Second', duration: Duration.zero);
    await tester.pump();
    expect(find.text('Second').hitTestable(), findsOneWidget);
    controller.dismiss(second);
    await tester.pump();
    expect(find.text('First').hitTestable(), findsOneWidget);
    expect(find.text('Second'), findsNothing);
  });
}

Widget _host(
  YumeiroToastController controller, {
  Alignment? alignment,
  bool disableAnimations = false,
  Widget child = const SizedBox.expand(),
}) => YumeiroApp(
  modality: YumeiroModality.touch,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: disableAnimations),
    child: child!,
  ),
  home: Material(
    child: YumeiroToastHost(
      controller: controller,
      alignment: alignment,
      child: child,
    ),
  ),
);
