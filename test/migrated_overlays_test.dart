import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yumeiro/yumeiro.dart';

void main() {
  group('Migrated overlays', () {
    for (final reducedMotion in [false, true]) {
      testWidgets(
        'dismissed toast finishes exiting with reduced motion=$reducedMotion',
        (tester) async {
          final controller = YumeiroToastController();
          addTearDown(controller.dispose);
          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(disableAnimations: reducedMotion),
                child: YumeiroScope(
                  toastController: controller,
                  child: const Scaffold(),
                ),
              ),
            ),
          );
          final id = controller.show(message: 'Saved', duration: Duration.zero);
          await tester.pumpAndSettle();
          expect(find.text('Saved'), findsOneWidget);
          controller.dismiss(id);
          await tester.pump();
          expect(controller.entries, isEmpty);
          if (!reducedMotion) {
            await tester.pump(const Duration(milliseconds: 90));
            expect(find.text('Saved'), findsOneWidget);
          }
          await tester.pumpAndSettle();
          expect(find.text('Saved'), findsNothing);
          await tester.pumpWidget(const SizedBox.shrink());
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('pointer editor opens a dialog', (tester) async {
      await tester.pumpWidget(
        YumeiroApp(
          modality: YumeiroModality.pointer,
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: YumeiroButton(
                  label: 'Open Editor',
                  onPressed: () => YumeiroEditor.show<void>(
                    context: context,
                    builder: (_) => const YumeiroEditor(
                      title: 'Pointer Editor',
                      child: Text('Body'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Editor'));
      await tester.pumpAndSettle();
      expect(find.byType(YumeiroDialog), findsOneWidget);
      expect(find.text('Pointer Editor'), findsOneWidget);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();

      expect(find.byType(YumeiroDialog), findsNothing);
    });

    testWidgets('touch editor responds to the keyboard and viewport size', (
      tester,
    ) async {
      const portrait = Size(390, 700);
      tester.view.physicalSize = portrait;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        YumeiroApp(
          modality: YumeiroModality.touch,
          home: Scaffold(
            body: Builder(
              builder: (context) => YumeiroButton(
                label: 'Open touch editor',
                onPressed: () => YumeiroEditor.show<void>(
                  context: context,
                  builder: (routeContext) => YumeiroEditor(
                    title: 'Touch editor',
                    headerAccessory: const Text('Editor context'),
                    actions: [
                      YumeiroButton(
                        label: 'Save',
                        onPressed: () => Navigator.of(routeContext).pop(),
                      ),
                    ],
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        YumeiroTextField(initialValue: 'Initial value'),
                        SizedBox(height: 600),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open touch editor'));
      await tester.pumpAndSettle();
      final sheet = find.byType(YumeiroBottomSheet);
      final surface = find.descendant(
        of: sheet,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is YumeiroVisualSurface &&
              widget.role == YumeiroSurfaceRole.modal,
        ),
      );
      expect(sheet, findsOneWidget);
      expect(tester.getRect(surface).bottom, portrait.height);
      final start = tester.getTopLeft(find.text('Touch editor')).dx;
      expect(tester.getTopLeft(find.text('Editor context')).dx, start);
      expect(tester.getTopLeft(find.byType(YumeiroTextField)).dx, start);
      final save = find.widgetWithText(YumeiroButton, 'Save');
      expect(tester.getTopLeft(save).dx, start);

      final field = find.byType(EditableText);
      await tester.enterText(field, 'Edited value');
      final draftController = tester.widget<EditableText>(field).controller;
      const keyboardHeight = 330.0;
      tester.view.viewInsets = const FakeViewPadding(bottom: keyboardHeight);
      await tester.pumpAndSettle();
      expect(tester.getRect(surface).bottom, portrait.height - keyboardHeight);
      expect(
        tester.widget<EditableText>(field).controller,
        same(draftController),
      );
      expect(draftController.text, 'Edited value');
      expect(save.hitTestable(), findsOneWidget);

      const landscape = Size(844, 390);
      tester.view.resetViewInsets();
      tester.view.physicalSize = landscape;
      await tester.pumpAndSettle();
      expect(tester.getCenter(surface), landscape.center(Offset.zero));
      expect(
        tester.widget<EditableText>(field).controller,
        same(draftController),
      );
      expect(draftController.text, 'Edited value');
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(sheet, findsNothing);
    });

    for (final modality in YumeiroModality.values) {
      testWidgets('filter applies or discards the draft in $modality', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final results = <String?>[];
        await tester.pumpWidget(
          YumeiroApp(
            modality: modality,
            locale: const Locale('en'),
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: YumeiroButton(
                    label: 'Open filter',
                    onPressed: () async {
                      final result = await YumeiroFilter.show<String>(
                        context: context,
                        initialValue: 'initial',
                        resetValue: 'reset',
                        builder: (context, value, onChanged) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Draft: $value'),
                            YumeiroButton(
                              label: 'Pick Custom',
                              onPressed: () => onChanged('custom'),
                            ),
                          ],
                        ),
                      );
                      results.add(result);
                    },
                  ),
                ),
              ),
            ),
          ),
        );

        Future<void> tap(Finder finder) async {
          await tester.tap(finder);
          await tester.pumpAndSettle();
        }

        await tap(find.text('Open filter'));
        final touch = modality == YumeiroModality.touch;
        expect(
          find.byType(YumeiroBottomSheet),
          touch ? findsOne : findsNothing,
        );
        expect(find.byType(YumeiroDialog), touch ? findsNothing : findsOne);
        expect(find.text('Draft: initial'), findsOneWidget);

        await tap(find.text('Pick Custom'));
        expect(find.text('Draft: custom'), findsOneWidget);
        await tap(find.text('Reset'));
        expect(find.text('Draft: reset'), findsOneWidget);
        expect(results, isEmpty);
        await tap(find.byTooltip('Close'));
        expect(results, [null]);

        await tap(find.text('Open filter'));
        expect(find.text('Draft: initial'), findsOneWidget);
        await tap(find.text('Pick Custom'));
        await tap(find.text('Apply'));
        expect(results, [null, 'custom']);
      });
    }

    testWidgets('YumeiroActionMenu.show executes selected action', (
      tester,
    ) async {
      var deleted = false;
      await tester.pumpWidget(
        YumeiroApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: YumeiroButton(
                  label: 'Actions',
                  onPressed: () => YumeiroActionMenu.show(
                    context: context,
                    title: 'Row Actions',
                    items: [
                      YumeiroMenuAction(
                        label: 'Delete Row',
                        destructive: true,
                        onPressed: () => deleted = true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete Row'));
      await tester.pumpAndSettle();
      expect(deleted, isTrue);
    });

    testWidgets(
      'context menu accepts secondary click and long press, and ignores drag',
      (tester) async {
        var copied = 0;
        await tester.pumpWidget(
          YumeiroApp(
            modality: YumeiroModality.pointer,
            home: Scaffold(
              body: Center(
                child: YumeiroContextMenuRegion(
                  menuBuilder: (_, _) => [
                    const YumeiroMenuHeader(title: 'Node'),
                    YumeiroMenuAction(
                      label: 'Copy Item',
                      onPressed: () => copied++,
                    ),
                  ],
                  child: const SizedBox(
                    width: 200,
                    height: 120,
                    child: Center(child: Text('Context target')),
                  ),
                ),
              ),
            ),
          ),
        );

        final target = tester.getCenter(find.text('Context target'));
        final command = find.text('Copy Item');
        await tester.tapAt(
          target,
          kind: PointerDeviceKind.mouse,
          buttons: kSecondaryMouseButton,
        );
        await tester.pumpAndSettle();
        await tester.tap(command);
        await tester.pumpAndSettle();
        expect(copied, 1);

        final drag = await tester.startGesture(target);
        await drag.moveBy(const Offset(30, 0));
        await tester.pump(const Duration(milliseconds: 600));
        expect(command, findsNothing);
        await drag.up();

        await tester.longPressAt(target);
        await tester.pumpAndSettle();
        await tester.tap(command);
        await tester.pumpAndSettle();
        expect(copied, 2);
      },
    );

    testWidgets(
      'a touch long press opens only the nearest menu and skips tap',
      (tester) async {
        var taps = 0;
        var hasActions = true;
        await tester.pumpWidget(
          YumeiroApp(
            modality: YumeiroModality.pointer,
            home: Scaffold(
              body: Center(
                child: YumeiroContextMenuRegion(
                  longPressDelay: const Duration(milliseconds: 100),
                  menuBuilder: (_, _) => [
                    YumeiroMenuAction(label: 'Outer action', onPressed: () {}),
                  ],
                  child: YumeiroContextMenuRegion(
                    menuBuilder: (_, _) => [
                      if (hasActions)
                        YumeiroMenuAction(
                          label: 'Row action',
                          onPressed: () {},
                        ),
                    ],
                    child: YumeiroListTile(
                      title: const Text('Details'),
                      onTap: () => taps++,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        final row = find.text('Details');
        await tester.tap(row);
        expect(taps, 1);
        await tester.longPress(row);
        await tester.pumpAndSettle();
        expect(find.text('Row action'), findsOneWidget);
        expect(find.text('Outer action'), findsNothing);
        expect(taps, 1);

        await tester.tap(find.text('Row action'));
        await tester.pumpAndSettle();
        hasActions = false;
        await tester.longPress(row);
        expect(taps, 2);
        expect(find.text('Outer action'), findsNothing);
      },
    );

    testWidgets(
      'tooltip anchors on hover and applies theme, visual scope and semantics',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: yumeiroThemeData().copyWith(
              tooltipTheme: const TooltipThemeData(
                constraints: BoxConstraints.tightFor(width: 180, height: 80),
                padding: EdgeInsets.zero,
                excludeFromSemantics: true,
              ),
            ),
            home: const Scaffold(
              body: Align(
                alignment: Alignment(0.5, 0.3),
                child: YumeiroVisualScope(
                  visualOverride: YumeiroVisualOverride(
                    base: YumeiroVisualDelta(
                      fill: YumeiroSolidFill(Colors.red),
                    ),
                  ),
                  child: YumeiroTooltip(
                    message: 'Anchored Tooltip',
                    child: Text('Hover Target'),
                  ),
                ),
              ),
            ),
          ),
        );

        final targetRect = tester.getRect(find.text('Hover Target'));
        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);
        await tester.pump();
        await gesture.moveTo(targetRect.center);
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();

        final tooltip = tester.widget<RawTooltip>(find.byType(RawTooltip));
        expect(tooltip.semanticsTooltip, isNull);
        final tooltipRect = tester.getRect(find.text('Anchored Tooltip'));
        expect(tooltipRect.size, const Size(180, 80));
        expect(
          (tooltipRect.center.dx - targetRect.center.dx).abs(),
          lessThan(24),
        );
        expect(tooltipRect.top, greaterThanOrEqualTo(targetRect.bottom));
        final surface = tester.widget<YumeiroResolvedVisualSurface>(
          find.byType(YumeiroResolvedVisualSurface),
        );
        expect(surface.appearance.background.toARGB32(), 0xFFF44336);
      },
    );

    testWidgets(
      'YumeiroToast aligns close button to trailing edge, preserves vertical padding, clamps maxLines, and copies on tap',
      (tester) async {
        String? clipboardText;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, (call) async {
              if (call.method == 'Clipboard.setData') {
                clipboardText = (call.arguments as Map)['text'] as String?;
              }
              return null;
            });
        addTearDown(() {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(SystemChannels.platform, null);
        });

        var closed = false;
        await tester.pumpWidget(
          YumeiroApp(
            modality: YumeiroModality.pointer,
            home: Scaffold(
              body: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Center(
                    child: YumeiroToast(
                      key: const ValueKey('short-toast'),
                      title: 'Synced',
                      message: 'Saved.',
                      onClose: () => closed = true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: YumeiroToast(
                      key: ValueKey('long-toast'),
                      title: 'Diagnostics',
                      message: 'Line one wraps across the toast card cleanly and keeps consistent top and bottom padding even as additional lines are rendered up to the configured maxLines limit before truncating with an ellipsis.',
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        final shortToastFinder = find.byKey(const ValueKey('short-toast'));
        final shortToastRect = tester.getRect(shortToastFinder);
        final shortMessageRect = tester.getRect(find.text('Saved.'));
        final closeFinder = find.descendant(
          of: shortToastFinder,
          matching: find.byIcon(YumeiroIconSet.material().close),
        );
        final closeRect = tester.getRect(closeFinder);

        // Close button stays pinned near the trailing edge rather than hugging text.
        expect(shortToastRect.width, greaterThanOrEqualTo(260));
        expect(shortToastRect.right - closeRect.right, lessThanOrEqualTo(24));
        expect(closeRect.left - shortMessageRect.right, greaterThan(40));

        // Long toast grows taller, preserves symmetric >= 12px top/bottom padding, and clamps maxLines.
        final longToastFinder = find.byKey(const ValueKey('long-toast'));
        final longToastRect = tester.getRect(longToastFinder);
        final longTitleRect = tester.getRect(find.text('Diagnostics'));
        final longMessageFinder = find.descendant(
          of: longToastFinder,
          matching: find.byType(Text),
        );
        final longMessageWidget = tester.widget<Text>(longMessageFinder.last);
        final longMessageRect = tester.getRect(longMessageFinder.last);

        expect(longToastRect.height, greaterThan(shortToastRect.height));
        expect(longMessageWidget.maxLines, 3);
        expect(longMessageWidget.overflow, TextOverflow.ellipsis);
        final topPad = longTitleRect.top - longToastRect.top;
        final bottomPad = longToastRect.bottom - longMessageRect.bottom;
        expect(topPad, greaterThanOrEqualTo(11.5));
        expect(bottomPad, greaterThanOrEqualTo(11.5));
        expect((topPad - bottomPad).abs(), lessThanOrEqualTo(2.0));

        // Clicking close dismisses without copying to clipboard.
        await tester.tap(closeFinder);
        await tester.pump();
        expect(closed, isTrue);
        expect(clipboardText, isNull);

        // Clicking toast body copies title + message and shows inline Copied feedback.
        await tester.tap(find.text('Saved.'));
        await tester.pump();
        expect(clipboardText, 'Synced\nSaved.');
        expect(find.text('Copied'), findsOneWidget);
      },
    );

    testWidgets(
      'YumeiroToastHost touch modality stretches to right edge with consistent multi-line padding',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          YumeiroApp(
            modality: YumeiroModality.touch,
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: YumeiroButton(
                    label: 'Show Touch Toast',
                    onPressed: () => showYumeiroToast(
                      context,
                      'Multi-line touch toast message verifying balanced vertical padding and trailing close alignment inside YumeiroToastHost.',
                      title: 'Touch Toast',
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Touch Toast'));
        await tester.pump();

        final toastFinder = find.byType(YumeiroToast);
        final toastRect = tester.getRect(toastFinder);
        final titleRect = tester.getRect(find.text('Touch Toast'));
        final messageRect = tester.getRect(
          find.textContaining('Multi-line touch toast'),
        );
        final closeFinder = find.descendant(
          of: toastFinder,
          matching: find.byIcon(YumeiroIconSet.material().close),
        );
        final closeRect = tester.getRect(closeFinder);

        expect(toastRect.right - closeRect.right, lessThanOrEqualTo(32));
        final topPad = titleRect.top - toastRect.top;
        final bottomPad = toastRect.bottom - messageRect.bottom;
        expect(topPad, greaterThanOrEqualTo(11.5));
        expect(bottomPad, greaterThanOrEqualTo(11.5));
        expect((topPad - bottomPad).abs(), lessThanOrEqualTo(2.0));
      },
    );
  });
}
