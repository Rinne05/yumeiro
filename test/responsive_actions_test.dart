import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

void main() {
  Widget largeText(BuildContext context, Widget? child) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: const TextScaler.linear(2)),
    child: child!,
  );

  testWidgets('selection toolbar keeps batch actions inline when they fit', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1600, 720);
    addTearDown(tester.view.reset);
    var selectedAll = false;
    var removed = false;
    var closed = false;
    const label = 'Remove selected files';

    await tester.pumpWidget(
      YumeiroApp(
        locale: const Locale('en'),
        modality: YumeiroModality.touch,
        builder: largeText,
        home: Scaffold(
          body: YumeiroSelectionToolbar(
            selectedCount: 3,
            onClose: () => closed = true,
            onSelectAll: () => selectedAll = true,
            actions: [
              YumeiroButton(label: label, onPressed: () => removed = true),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final title = find.text('3 selected');
    final selectAll = find.widgetWithText(YumeiroButton, 'Select All');
    final remove = find.widgetWithText(YumeiroButton, label);
    final close = find.byTooltip('Close');
    expect(find.byTooltip('Back'), findsNothing);
    expect(
      find.descendant(of: close, matching: find.byIcon(Icons.close_rounded)),
      findsOneWidget,
    );
    expect(tester.getCenter(title).dy, tester.getCenter(selectAll).dy);
    expect(tester.getCenter(remove).dy, tester.getCenter(selectAll).dy);
    expect(
      tester.getTopLeft(remove).dx - tester.getTopRight(selectAll).dx,
      YumeiroTheme.of(tester.element(selectAll)).spacing.sm,
    );

    tester.view.physicalSize = const Size(320, 720);
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(remove).dy,
      greaterThan(tester.getBottomLeft(title).dy),
    );
    await tester.tap(selectAll);
    await tester.tap(remove);
    await tester.tap(close);
    expect((selectedAll, removed, closed), (true, true, true));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    '320-wide touch header wraps its long action and preserves back',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 720);
      addTearDown(tester.view.reset);
      var backs = 0;
      var downloads = 0;
      const label = 'Download selected files';
      await tester.pumpWidget(
        YumeiroApp(
          locale: const Locale('en'),
          modality: YumeiroModality.touch,
          builder: largeText,
          home: YumeiroPageScaffold.detail(
            title: 'Downloads',
            onBack: () => backs++,
            actions: [
              YumeiroButton(label: label, onPressed: () => downloads++),
            ],
            body: const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final action = find.widgetWithText(YumeiroButton, label);
      final title = find.text('Downloads');
      expect(
        tester.getTopLeft(action).dy,
        greaterThan(tester.getBottomLeft(title).dy),
      );
      await tester.tap(action);
      await tester.tap(
        find.byWidgetPredicate(
          (widget) => widget is YumeiroButton && widget.tooltip == 'Back',
        ),
      );
      expect((backs, downloads), (1, 1));
      expect(tester.takeException(), isNull);
    },
  );

  for (final direction in TextDirection.values) {
    testWidgets(
      'touch input and action reflow without losing a $direction draft',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(1280, 720);
        addTearDown(tester.view.reset);
        var applies = 0;
        const label = 'Apply advanced settings';
        await tester.pumpWidget(
          YumeiroApp(
            modality: YumeiroModality.touch,
            builder: largeText,
            home: Directionality(
              textDirection: direction,
              child: Scaffold(
                body: YumeiroInputActionGroup(
                  inputs: const [YumeiroTextField(hintText: 'Destination')],
                  action: YumeiroButton(
                    label: label,
                    onPressed: () => applies++,
                  ),
                ),
              ),
            ),
          ),
        );
        final input = find.byType(YumeiroTextField);
        final action = find.widgetWithText(YumeiroButton, label);
        final editable = find.byType(EditableText);
        await tester.enterText(editable, 'Downloads');
        await tester.pumpAndSettle();
        final field = tester.widget<EditableText>(editable);
        expect(tester.getCenter(input).dy, tester.getCenter(action).dy);

        tester.view.physicalSize = const Size(320, 720);
        await tester.pumpAndSettle();
        expect(
          tester.getTopLeft(action).dy,
          greaterThan(tester.getBottomLeft(input).dy),
        );
        expect(tester.getSize(input).width, 320);
        expect(field.focusNode.hasFocus, isTrue);
        expect(
          tester.widget<EditableText>(editable).controller.text,
          'Downloads',
        );
        await tester.tap(action);
        expect(applies, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('touch input and action provide intrinsic width and height', (
    tester,
  ) async {
    Widget host(Widget child) => YumeiroApp(
      modality: YumeiroModality.touch,
      home: Scaffold(body: Center(child: child)),
    );
    final pair = YumeiroInputActionGroup(
      inputs: const [SizedBox(width: 180, height: 38)],
      action: const SizedBox(width: 100, height: 38),
    );
    final group = find.byType(YumeiroInputActionGroup);

    await tester.pumpWidget(host(IntrinsicWidth(child: pair)));
    expect(tester.getSize(group).width, 288);

    await tester.pumpWidget(
      host(SizedBox(width: 200, child: IntrinsicHeight(child: pair))),
    );
    expect(tester.getSize(group), const Size(200, 84));
    expect(tester.takeException(), isNull);
  });
}
