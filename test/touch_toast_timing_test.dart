import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

void main() {
  testWidgets('touch toast pauses and gets at least 1.5 seconds on return', (
    tester,
  ) async {
    final controller = YumeiroToastController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_host(controller));

    final first = controller.show(
      message: 'Save finished',
      duration: const Duration(milliseconds: 400),
    );
    await tester.pump(const Duration(milliseconds: 150));
    final second = controller.show(
      message: 'Upload finished',
      duration: Duration.zero,
    );
    await tester.pump(const Duration(seconds: 4));
    expect(controller.entries.map((entry) => entry.id), [first, second]);

    controller.dismiss(second);
    await tester.pump(const Duration(milliseconds: 1499));
    expect(controller.entries.single.id, first);
    await tester.pump(const Duration(milliseconds: 1));
    expect(controller.entries, isEmpty);
    await tester.pumpAndSettle();
  });

  testWidgets('touch overflow evicts an ordinary queued toast first', (
    tester,
  ) async {
    final controller = YumeiroToastController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_host(controller));

    final persistent = controller.show(
      message: 'Connection offline',
      duration: Duration.zero,
    );
    final warning = controller.show(
      message: 'Storage warning',
      statusRole: const YumeiroStatusRole(
        'test.storage',
        fallback: YumeiroStatusRole.warning,
      ),
    );
    final action = controller.show(
      message: 'Open report',
      onTap: () {},
      copyOnTap: false,
    );
    controller.show(message: 'Cache cleared');
    final danger = controller.show(
      message: 'Upload failed',
      statusRole: YumeiroStatusRole.danger,
    );
    expect(controller.entries.map((entry) => entry.id), [
      persistent,
      warning,
      action,
      danger,
    ]);

    final newest = controller.show(message: 'Saved');
    expect(controller.entries.map((entry) => entry.id), [
      warning,
      action,
      danger,
      newest,
    ]);

    for (final entry in controller.entries) {
      controller.dismiss(entry.id);
    }
    await tester.pumpAndSettle();
  });
}

Widget _host(YumeiroToastController controller) => YumeiroApp(
  modality: YumeiroModality.touch,
  home: YumeiroToastHost(controller: controller, child: const Scaffold()),
);
