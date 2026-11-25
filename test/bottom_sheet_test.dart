import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

void main() {
  testWidgets('touch select docks and swipes away without choosing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final selected = <int>[];
    await tester.pumpWidget(
      YumeiroApp(
        modality: YumeiroModality.touch,
        home: Scaffold(
          body: YumeiroSelect(
            title: 'Workspace',
            value: 1,
            options: const [
              YumeiroSelectionOption(value: 1, label: 'Design'),
              YumeiroSelectionOption(value: 2, label: 'Editorial'),
            ],
            onChanged: selected.add,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Design'));
    await tester.pumpAndSettle();

    final surface = find.ancestor(
      of: find.text('Editorial'),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is YumeiroVisualSurface &&
            widget.role == YumeiroSurfaceRole.modal,
      ),
    );
    final bounds = tester.getRect(surface);
    expect(bounds.left, 0);
    expect(bounds.right, 390);
    expect(bounds.bottom, 844);

    await tester.fling(find.text('Workspace'), const Offset(0, 140), 1000);
    await tester.pumpAndSettle();
    expect(find.text('Editorial'), findsNothing);
    expect(selected, isEmpty);
  });

  testWidgets('a pointer sheet stays centered in a narrow window', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      YumeiroApp(
        modality: YumeiroModality.pointer,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => YumeiroBottomSheet.show<void>(
                context: context,
                builder: (_) => const YumeiroBottomSheet(
                  title: 'Sheet',
                  child: Text('Sheet content'),
                ),
              ),
              child: const Text('Open sheet'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open sheet'));
    await tester.pumpAndSettle();

    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();
    final surface = find.byWidgetPredicate(
      (widget) =>
          widget is YumeiroVisualSurface &&
          widget.role == YumeiroSurfaceRole.modal,
    );
    final bounds = tester.getRect(surface);
    expect(bounds.center, const Offset(195, 422));
    expect(bounds.width, lessThan(390));
  });

  testWidgets('pointer select reveals a distant selected option', (
    tester,
  ) async {
    await tester.pumpWidget(
      YumeiroApp(
        modality: YumeiroModality.pointer,
        home: Scaffold(
          body: Center(
            child: YumeiroSelect<int>(
              value: 78,
              options: [
                for (var i = 0; i < 100; i++)
                  YumeiroSelectionOption(value: i, label: 'Option $i'),
              ],
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Option 78'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(YumeiroSelectionList<int>),
        matching: find.text('Option 78').hitTestable(),
      ),
      findsOneWidget,
    );
  });

  testWidgets('multi-select confirms an empty draft and cancels with null', (
    tester,
  ) async {
    final selected = <int>{1};
    final controller = YumeiroSheetController();
    var completed = false;
    Set<int>? result;
    await tester.pumpWidget(
      YumeiroApp(
        locale: const Locale('en'),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                completed = false;
                result = await YumeiroBottomSheet.multiSelect<int>(
                  context: context,
                  title: 'Pick items',
                  options: const [
                    YumeiroSelectionOption(value: 1, label: 'One'),
                  ],
                  values: selected,
                  controller: controller,
                );
                completed = true;
              },
              child: const Text('Open picker'),
            ),
          ),
        ),
      ),
    );

    Future<void> tap(String label) async {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }

    await tap('Open picker');
    await tap('One');
    expect(selected, {1});
    await tap('Confirm (0)');
    expect(completed, isTrue);
    expect(result, isEmpty);

    await tap('Open picker');
    expect(find.text('Confirm (1)'), findsOneWidget);
    controller.close();
    await tester.pumpAndSettle();
    expect(find.text('Pick items'), findsNothing);
    expect(completed, isTrue);
    expect(result, isNull);
    expect(selected, {1});
  });

  testWidgets('single-select can return an option with a null value', (
    tester,
  ) async {
    const automatic = YumeiroSelectionOption<int?>(
      value: null,
      label: 'Automatic',
    );
    YumeiroSelectionOption<int?>? result;
    await tester.pumpWidget(
      YumeiroApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await YumeiroBottomSheet.select<int?>(
                  context: context,
                  title: 'Pick a setting',
                  options: const [automatic],
                );
              },
              child: const Text('Open picker'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open picker'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Automatic'));
    await tester.pumpAndSettle();
    expect(result, same(automatic));
  });

  testWidgets('controller refreshes a route whose frame has settled', (
    tester,
  ) async {
    final controller = YumeiroSheetController();
    var title = 'Original title';
    await tester.pumpWidget(
      YumeiroApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => YumeiroBottomSheet.show<void>(
                context: context,
                controller: controller,
                builder: (_) => YumeiroBottomSheet(
                  title: title,
                  child: const Text('Sheet content'),
                ),
              ),
              child: const Text('Open sheet'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open sheet'));
    await tester.pumpAndSettle();
    expect(find.text('Original title'), findsOneWidget);

    title = 'Updated title';
    controller.refresh();
    await tester.pumpAndSettle();
    expect(find.text('Updated title'), findsOneWidget);
  });
}
