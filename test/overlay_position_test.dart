import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yumeiro/src/components/overlays/selection_overlay.dart';
import 'package:yumeiro/yumeiro.dart';

void main() {
  testWidgets('free-text dropdown keeps its draft when scrolled out of view', (
    tester,
  ) async {
    final vertical = ScrollController();
    final horizontal = ScrollController();
    addTearDown(vertical.dispose);
    addTearDown(horizontal.dispose);
    final changes = <int?>[];
    final submitted = <String>[];
    const viewportKey = ValueKey('dropdown viewport');
    const dropdownKey = ValueKey('searchable dropdown');
    await tester.pumpWidget(
      YumeiroApp(
        modality: YumeiroModality.pointer,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.only(top: 160, left: 64),
            child: SizedBox(
              key: viewportKey,
              width: 280,
              height: 200,
              child: YumeiroScrollView(
                controller: vertical,
                child: Column(
                  children: [
                    const SizedBox(height: 80),
                    YumeiroScrollView(
                      controller: horizontal,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(left: 40, right: 400),
                      child: YumeiroSelect<int>.searchable(
                        key: dropdownKey,
                        width: 180,
                        maxVisibleItems: 3,
                        options: List.generate(
                          8,
                          (i) => YumeiroSelectionOption(
                            value: i,
                            label: 'Option $i',
                          ),
                        ),
                        onChanged: changes.add,
                        onFreeTextSubmitted: submitted.add,
                      ),
                    ),
                    const SizedBox(height: 400),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final input = find.byType(TextField);
    final menu = find.byType(ListView);
    final viewport = tester.getRect(find.byKey(viewportKey));
    final trigger = tester.getRect(find.byKey(dropdownKey));
    await tester.enterText(input, 'Option');
    await tester.pumpAndSettle();
    expect(menu, findsOneWidget);

    final optionsController = tester.widget<ListView>(menu).controller!;
    await tester.drag(menu, const Offset(0, -65));
    await tester.pumpAndSettle();
    expect(optionsController.offset, greaterThan(0));

    for (final (controller, exitOffset) in [
      (vertical, trigger.bottom - viewport.top),
      (horizontal, trigger.right - viewport.left),
    ]) {
      controller.jumpTo(exitOffset - 10);
      await tester.pumpAndSettle();
      expect(menu, findsOneWidget);
      expect(tester.widget<TextField>(input).focusNode!.hasFocus, isTrue);

      controller.jumpTo(exitOffset);
      await tester.pumpAndSettle();
      expect(menu, findsNothing);
      expect(tester.widget<TextField>(input).focusNode!.hasFocus, isFalse);
      expect(tester.widget<TextField>(input).controller!.text, 'Option');

      controller.jumpTo(0);
      await tester.pumpAndSettle();
      expect(menu, findsNothing);
      await tester.tap(input);
      await tester.pumpAndSettle();
      expect(menu, findsOneWidget);
    }
    expect(changes, isEmpty);
    expect(submitted, isEmpty);
  });

  testWidgets('searchable dropdown releases focus in a lazy scroll view', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      YumeiroApp(
        modality: YumeiroModality.pointer,
        home: Scaffold(
          body: ListView.builder(
            controller: controller,
            itemCount: 30,
            itemExtent: 64,
            itemBuilder: (context, index) => index == 1
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: YumeiroSelect<int>.searchable(
                      options: const [
                        YumeiroSelectionOption(value: 1, label: 'One'),
                      ],
                      onChanged: (_) {},
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );

    final input = find.byType(TextField);
    await tester.tap(input);
    await tester.pumpAndSettle();
    final focus = tester.widget<TextField>(input).focusNode!;
    expect(focus.hasFocus, isTrue);
    expect(find.text('One'), findsOneWidget);

    controller.jumpTo(1000);
    await tester.pumpAndSettle();
    expect(find.text('One'), findsNothing);
    expect(FocusManager.instance.primaryFocus, isNot(same(focus)));

    controller.jumpTo(0);
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(input).focusNode!.hasFocus, isFalse);
    expect(find.text('One'), findsNothing);
  });

  testWidgets(
    'anchored selection panels use available space without covering their trigger',
    (tester) async {
      tester.view.physicalSize = const Size(800, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const anchor = Rect.fromLTWH(60, 380, 120, 40);
      await tester.pumpWidget(
        const YumeiroApp(
          modality: YumeiroModality.pointer,
          home: YumeiroSelectionOverlay(
            anchor: anchor,
            child: SizedBox(key: ValueKey('panel'), height: 600),
          ),
        ),
      );
      final popup = tester.getRect(find.byKey(const ValueKey('panel')));
      expect(
        popup.top >= anchor.bottom + 8 || popup.bottom <= anchor.top - 8,
        isTrue,
      );
    },
  );

  testWidgets(
    'selection sheets convert global anchors through scaled navigators',
    (tester) async {
      const scale = .75;
      await tester.pumpWidget(
        Transform.scale(
          scale: scale,
          alignment: Alignment.topLeft,
          child: YumeiroApp(
            modality: YumeiroModality.pointer,
            advancedMotionEnabled: false,
            home: Scaffold(
              body: Center(
                child: Builder(
                  builder: (context) => TextButton(
                    onPressed: () {
                      final box = context.findRenderObject()! as RenderBox;
                      YumeiroBottomSheet.select<int>(
                        context: context,
                        title: 'Pick',
                        anchor:
                            box.localToGlobal(Offset.zero) & box.size * scale,
                        options: const [
                          YumeiroSelectionOption(value: 1, label: 'One'),
                        ],
                      );
                    },
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final trigger = tester.getRect(find.byType(TextButton));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final popup = tester.getRect(
        find.byWidgetPredicate(
          (widget) =>
              widget is YumeiroVisualSurface &&
              widget.role == YumeiroSurfaceRole.modal,
        ),
      );
      expect(popup.right, closeTo(trigger.right, .1));
      expect(popup.top, closeTo(trigger.bottom + 8 * scale, .1));
    },
  );

  testWidgets('local searchable sheet centers when the anchor is too short', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(660, 200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    int? choice;
    await tester.pumpWidget(
      YumeiroApp(
        locale: const Locale('en'),
        modality: YumeiroModality.pointer,
        home: Scaffold(
          body: Center(
            child: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  final box = context.findRenderObject()! as RenderBox;
                  final result = await YumeiroBottomSheet.select<int>(
                    context: context,
                    anchor: box.localToGlobal(Offset.zero) & box.size,
                    title: 'Pick a number',
                    searchable: true,
                    options: const [
                      YumeiroSelectionOption(value: 1, label: 'One'),
                      YumeiroSelectionOption(value: 2, label: 'Two'),
                    ],
                  );
                  choice = result?.value;
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final panel = tester.getRect(
      find.byWidgetPredicate(
        (widget) =>
            widget is YumeiroVisualSurface &&
            widget.role == YumeiroSurfaceRole.modal,
      ),
    );
    expect(panel.center.dy, closeTo(100, 1));
    expect(tester.takeException(), isNull);
    await tester.enterText(find.byType(EditableText), 'Tw');
    await tester.pumpAndSettle();
    expect(find.text('Two').hitTestable(), findsOneWidget);
    await tester.tap(find.text('Two'));
    await tester.pumpAndSettle();
    expect(choice, 2);
  });

  testWidgets(
    'touch dropdown supplies transformed global trigger bounds to its sheet',
    (tester) async {
      await tester.pumpWidget(
        Transform.scale(
          scale: .75,
          alignment: Alignment.topLeft,
          child: YumeiroApp(
            modality: YumeiroModality.touch,
            advancedMotionEnabled: false,
            home: Scaffold(
              body: Center(
                child: YumeiroSelect<int>.menu(
                  key: const ValueKey('menu select'),
                  value: 1,
                  width: 140,
                  options: const [
                    YumeiroSelectionOption(value: 1, label: 'One'),
                    YumeiroSelectionOption(value: 2, label: 'Two'),
                  ],
                  onChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      final trigger = tester.getRect(find.byKey(const ValueKey('menu select')));
      await tester.tap(find.byKey(const ValueKey('menu select')));
      await tester.pumpAndSettle();
      final popup = tester.getRect(
        find.byWidgetPredicate(
          (widget) =>
              widget is YumeiroVisualSurface &&
              widget.role == YumeiroSurfaceRole.modal,
        ),
      );
      expect(popup.right, closeTo(trigger.right, .1));
      expect(popup.top, closeTo(trigger.bottom + 6, .1));
    },
  );

  testWidgets(
    'color picker fits a narrow pointer viewport with long labels and scaled text',
    (tester) async {
      tester.view.physicalSize = const Size(240, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        YumeiroApp(
          modality: YumeiroModality.pointer,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: Center(
              child: YumeiroColorPickerButton(
                value: Colors.blue,
                defaultColor: Colors.blue,
                onChanged: (_) {},
                tooltip: 'A long example color picker title',
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(YumeiroColorPickerButton));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('open select remains anchored when the viewport is resized', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      YumeiroApp(
        modality: YumeiroModality.pointer,
        home: Scaffold(
          body: Center(
            child: YumeiroSelect<int>(
              value: 1,
              width: 140,
              options: const [
                YumeiroSelectionOption(value: 1, label: 'One'),
                YumeiroSelectionOption(value: 2, label: 'Two'),
              ],
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(YumeiroSelect<int>));
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(600, 800);
    await tester.pumpAndSettle();
    final trigger = tester.getRect(find.byType(YumeiroSelect<int>));
    final popup = tester.getRect(
      find.byWidgetPredicate(
        (widget) =>
            widget is YumeiroVisualSurface &&
            widget.role == YumeiroSurfaceRole.floating,
      ),
    );
    expect(popup.left, closeTo(trigger.left, .1));
  });
}
