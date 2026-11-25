import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

void main() {
  testWidgets('inline selection follows the option value when reordered', (
    tester,
  ) async {
    final options = ValueNotifier(const [
      YumeiroSelectionOption(value: 1, label: 'Alpha'),
      YumeiroSelectionOption(value: 2, label: 'Beta'),
    ]);
    final field = GlobalKey<FormFieldState<Set<int>>>();
    addTearDown(options.dispose);
    await tester.pumpWidget(
      YumeiroApp(
        home: Scaffold(
          body: ValueListenableBuilder(
            valueListenable: options,
            builder: (_, choices, _) =>
                YumeiroSelectionList.multiForm(key: field, options: choices),
          ),
        ),
      ),
    );

    final alpha = find.text('Alpha');
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(tester.getSemantics(alpha), isSemantics(isFocused: true));
    options.value = options.value.reversed.toList();
    await tester.pumpAndSettle();
    expect(tester.getSemantics(alpha), isSemantics(isFocused: true));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(field.currentState!.value, {1});
  });

  testWidgets('scrollable selection still reveals its first selected row', (
    tester,
  ) async {
    await tester.pumpWidget(
      YumeiroApp(
        home: Scaffold(
          body: SizedBox(
            height: 220,
            child: YumeiroSelectionList(
              options: [
                for (var i = 0; i < 30; i++)
                  YumeiroSelectionOption(value: i, label: 'Option $i'),
              ],
              values: const {23},
              onSelected: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Option 23').hitTestable(), findsOneWidget);
    final position = tester
        .state<ScrollableState>(find.byType(Scrollable))
        .position;
    expect(position.pixels, greaterThan(position.minScrollExtent));
  });

  testWidgets('reveals a distant selected row without mounting the full list', (
    tester,
  ) async {
    final chosen = <int>[];
    await tester.pumpWidget(
      YumeiroApp(
        home: Scaffold(
          body: SizedBox(
            height: 240,
            child: YumeiroSelectionList(
              options: [
                for (var i = 0; i < 1500; i++)
                  YumeiroSelectionOption(
                    value: i,
                    label: 'Option $i',
                    subtitle: i.isEven ? 'Additional details' : null,
                  ),
              ],
              values: const {1250},
              onSelected: (item) => chosen.add(item.value),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final mountedOptions = find.byWidgetPredicate(
      (widget) => widget is Text && widget.data?.startsWith('Option ') == true,
    );
    expect(find.text('Option 1250').hitTestable(), findsOneWidget);
    expect(mountedOptions.evaluate().length, lessThan(40));
    await tester.tap(find.text('Option 1250'));
    expect(chosen, [1250]);
    await tester.drag(
      find.byType(YumeiroSelectionList<int>),
      const Offset(0, 200),
    );
    await tester.pumpAndSettle();
    expect(find.text('Option 1248').hitTestable(), findsOneWidget);
    expect(mountedOptions.evaluate().length, lessThan(40));
  });

  testWidgets('single choice arrows skip unbuilt disabled rows and wrap', (
    tester,
  ) async {
    var values = const {0};
    await tester.pumpWidget(
      YumeiroApp(
        home: Scaffold(
          body: SizedBox(
            height: 200,
            child: StatefulBuilder(
              builder: (context, setState) => YumeiroSelectionList(
                options: [
                  for (var i = 0; i <= 70; i++)
                    YumeiroSelectionOption(
                      value: i,
                      label: 'Option $i',
                      enabled: i == 0 || i == 60 || i == 70,
                    ),
                ],
                values: values,
                onChanged: (next) => setState(() => values = next),
                autofocus: true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Option 60'), findsNothing);

    Future<void> move(LogicalKeyboardKey key, int index) async {
      await tester.sendKeyEvent(key);
      await tester.pumpAndSettle();
      expect(values, {index});
      final row = find.text('Option $index').hitTestable();
      expect(row, findsOneWidget);
      expect(Focus.of(tester.element(row)).hasPrimaryFocus, isTrue);
    }

    await move(LogicalKeyboardKey.arrowDown, 60);
    await move(LogicalKeyboardKey.arrowUp, 0);
    await move(LogicalKeyboardKey.arrowUp, 70);
    await move(LogicalKeyboardKey.arrowDown, 0);
  });

  testWidgets(
    'a visible option keeps focus when reordered across the selected row',
    (tester) async {
      final options = ValueNotifier([
        for (var i = 0; i < 100; i++)
          YumeiroSelectionOption(
            value: i,
            label: 'Option $i',
            subtitle: i.isEven ? 'Additional details' : null,
          ),
      ]);
      final chosen = <int>[];
      addTearDown(options.dispose);
      await tester.pumpWidget(
        YumeiroApp(
          home: Scaffold(
            body: SizedBox(
              height: 240,
              child: ValueListenableBuilder(
                valueListenable: options,
                builder: (_, choices, _) => YumeiroSelectionList(
                  options: choices,
                  values: const {60},
                  onSelected: (option) => chosen.add(option.value),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final selected = find.text('Option 60').hitTestable();
      final focused = find.text('Option 61').hitTestable();
      FocusNode rowFocus(Finder row) =>
          Focus.of(tester.element(row), createDependency: false);
      expect(
        tester.getCenter(focused).dy,
        greaterThan(tester.getCenter(selected).dy),
      );
      rowFocus(focused).requestFocus();
      await tester.pumpAndSettle();
      expect(rowFocus(focused).hasPrimaryFocus, isTrue);

      final reordered = options.value.toList();
      reordered.insert(60, reordered.removeAt(61));
      options.value = reordered;
      await tester.pumpAndSettle();
      expect(
        tester.getCenter(focused).dy,
        lessThan(tester.getCenter(selected).dy),
      );
      expect(rowFocus(focused).hasPrimaryFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(chosen, [61]);
    },
  );

  testWidgets('repeated option values still build separate rows', (
    tester,
  ) async {
    await tester.pumpWidget(
      YumeiroApp(
        home: Scaffold(
          body: YumeiroSelectionList(
            options: const [
              YumeiroSelectionOption(value: 1, label: 'First'),
              YumeiroSelectionOption(value: 1, label: 'Second'),
            ],
            values: const {1},
            onSelected: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('First'), findsOneWidget);
    expect(find.text('Second'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
