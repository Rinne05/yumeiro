import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

void main() {
  testWidgets('a ScaffoldMessenger can present the themed toast surface', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showYumeiroToast(
                context,
                'Example A',
                statusRole: YumeiroStatusRole.warning,
              ),
              child: const Text('Show'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();
    final toast = tester.widget<YumeiroToast>(find.byType(YumeiroToast));
    expect(toast.message, 'Example A');
    expect(toast.statusRole, YumeiroStatusRole.warning);
    expect(toast.copyOnTap, isFalse);
  });

  testWidgets('feedback follows the fallback status role', (tester) async {
    const customRole = YumeiroStatusRole(
      'example.syncFailure',
      fallback: YumeiroStatusRole.danger,
    );
    await tester.pumpWidget(
      const YumeiroApp(
        home: Scaffold(
          body: Column(
            children: [
              YumeiroCallout(
                message: 'Sync needs attention',
                statusRole: customRole,
              ),
              YumeiroToast(message: 'Sync interrupted', statusRole: customRole),
            ],
          ),
        ),
      ),
    );
    final callout = find.byType(YumeiroCallout);
    final theme = YumeiroTheme.of(tester.element(callout));
    expect(find.byIcon(theme.icons.error), findsNWidgets(2));
    expect(
      find.descendant(
        of: callout,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Semantics && widget.properties.liveRegion == true,
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('hosted and standalone toasts resolve status role icons', (
    tester,
  ) async {
    const customRole = YumeiroStatusRole(
      'example.notification',
      fallback: YumeiroStatusRole.info,
    );
    const customColor = Color(0xFF623DD4);
    const infoColor = Color(0xFF178F7B);
    final controller = YumeiroToastController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      YumeiroApp(
        modality: YumeiroModality.pointer,
        visualsAugmenter: (visuals, _, _) => visuals.extend(
          statuses: {
            customRole: const YumeiroStatusVisual(
              foreground: customColor,
              subtleFill: Colors.transparent,
            ),
            YumeiroStatusRole.info: const YumeiroStatusVisual(
              foreground: infoColor,
              subtleFill: Colors.transparent,
            ),
          },
        ),
        home: YumeiroToastHost(
          controller: controller,
          child: Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  const YumeiroToast(
                    message: 'Informational notification',
                    statusRole: YumeiroStatusRole.info,
                    copyOnTap: false,
                  ),
                  YumeiroButton(
                    label: 'Notify',
                    onPressed: () => showYumeiroToast(
                      context,
                      'Hosted notification',
                      statusRole: customRole,
                      copyOnTap: false,
                      duration: Duration.zero,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Notify'));
    await tester.pumpAndSettle();
    expect(controller.entries.single.statusRole, customRole);

    Icon toastIcon(String message) {
      final subject = find.widgetWithText(YumeiroToast, message);
      final theme = YumeiroTheme.of(tester.element(subject));
      return tester.widget<Icon>(
        find.descendant(of: subject, matching: find.byIcon(theme.icons.info)),
      );
    }

    expect(toastIcon('Informational notification').color, infoColor);
    expect(toastIcon('Hosted notification').color, customColor);
  });
}
