import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yumeiro/yumeiro.dart';

void main() {
  testWidgets(
    'search redraws the clear action only when its visibility changes',
    (tester) async {
      final first = TextEditingController(text: 'First');
      final second = TextEditingController();
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      var controller = first;
      late StateSetter reconfigure;
      const searchKey = ValueKey('search');
      final changes = <String>[];

      await tester.pumpWidget(
        YumeiroApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                reconfigure = setState;
                return YumeiroTextField.search(
                  key: searchKey,
                  controller: controller,
                  onChanged: (value) => changes.add('change:$value'),
                  onCleared: () => changes.add('clear'),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final field = tester.element(find.byKey(searchKey));
      final clear = find.byWidgetPredicate(
        (widget) => widget is YumeiroButton && widget.tooltip == 'Clear',
      );
      expect(clear, findsOneWidget);
      for (var index = 0; index < 5; index++) {
        first.selection = TextSelection.collapsed(offset: index);
        expect(field.dirty, isFalse);
        await tester.pump();
      }
      first.text = 'Updated';
      expect(field.dirty, isFalse);
      await tester.pump();
      expect(find.text('Updated'), findsOneWidget);

      reconfigure(() => controller = second);
      await tester.pumpAndSettle();
      expect(clear, findsNothing);
      first.clear();
      expect(field.dirty, isFalse);

      second.text = 'Second';
      expect(field.dirty, isTrue);
      await tester.pumpAndSettle();
      expect(clear, findsOneWidget);
      await tester.tap(clear);
      await tester.pumpAndSettle();
      expect(second.text, isEmpty);
      expect(clear, findsNothing);
      expect(changes, ['change:', 'clear']);
    },
  );

  testWidgets('search restores its owned draft after using a controller', (
    tester,
  ) async {
    final external = TextEditingController(text: 'External query');
    addTearDown(external.dispose);
    TextEditingController? controller;
    late StateSetter reconfigure;
    await tester.pumpWidget(
      YumeiroApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              reconfigure = setState;
              return YumeiroTextField.search(controller: controller);
            },
          ),
        ),
      ),
    );
    final input = find.byType(EditableText);
    await tester.enterText(input, 'Draft query');
    reconfigure(() => controller = external);
    await tester.pump();
    expect(
      tester.widget<EditableText>(input).controller.text,
      'External query',
    );
    reconfigure(() => controller = null);
    await tester.pump();
    expect(tester.widget<EditableText>(input).controller.text, 'Draft query');
  });

  testWidgets('clearable fields rebuild when the clear action changes', (
    tester,
  ) async {
    final first = TextEditingController(text: 'First');
    final second = TextEditingController(text: 'Second');
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    var controller = first;
    var clearable = true;
    late StateSetter reconfigure;

    await tester.pumpWidget(
      YumeiroApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              reconfigure = setState;
              return YumeiroTextField(
                controller: controller,
                clearable: clearable,
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final field = tester.element(find.byType(YumeiroTextField));
    final clear = find.byWidgetPredicate(
      (widget) => widget is YumeiroButton && widget.tooltip == 'Clear',
    );
    expect(clear, findsOneWidget);
    var rebuildsScheduled = 0;
    for (var index = 0; index < 5; index++) {
      first.text = 'Edit $index';
      if (field.dirty) rebuildsScheduled++;
      await tester.pump();
      expect(find.text('Edit $index'), findsOneWidget);
    }
    first.selection = const TextSelection.collapsed(offset: 1);
    if (field.dirty) rebuildsScheduled++;
    expect(rebuildsScheduled, 0);

    first.clear();
    expect(field.dirty, isTrue);
    await tester.pump();
    expect(clear, findsNothing);

    reconfigure(() {
      controller = second;
      clearable = false;
    });
    await tester.pumpAndSettle();
    expect(clear, findsNothing);
    reconfigure(() => clearable = true);
    await tester.pumpAndSettle();
    expect(clear, findsOneWidget);
    await tester.tap(clear);
    await tester.pumpAndSettle();
    expect(second.text, isEmpty);
    expect(clear, findsNothing);
  });
}
