import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

Future<void> _pumpInput(WidgetTester tester, Widget input) => tester.pumpWidget(
  YumeiroApp(
    modality: YumeiroModality.touch,
    home: Scaffold(body: input),
  ),
);

void main() {
  testWidgets('slider input uses a signed keyboard and submits negatives', (
    tester,
  ) async {
    double? committed;
    await _pumpInput(
      tester,
      YumeiroSliderInput(
        value: 0,
        min: -10,
        max: 10,
        onChanged: (value) => committed = value,
      ),
    );

    final editable = find.byType(EditableText);
    expect(
      tester.widget<EditableText>(editable).keyboardType,
      const TextInputType.numberWithOptions(decimal: true, signed: true),
    );
    await tester.enterText(editable, '-3');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(committed, -3);
  });

  testWidgets('slider input shows a reset button only when configured', (
    tester,
  ) async {
    var resets = 0;
    YumeiroSliderInput buildInput({
      VoidCallback? onReset,
      bool Function(double)? isResetEnabled,
    }) => YumeiroSliderInput(
      value: 0,
      min: 0,
      max: 1,
      onChanged: (_) {},
      onReset: onReset,
      isResetEnabled: isResetEnabled,
    );

    final button = find.byType(YumeiroButton);
    await _pumpInput(tester, buildInput());
    expect(button, findsNothing);

    await _pumpInput(tester, buildInput(onReset: () => resets++));
    expect(button, findsOneWidget);
    await tester.tap(button);
    expect(resets, 1);

    await _pumpInput(
      tester,
      buildInput(onReset: () => resets++, isResetEnabled: (value) => value > 0),
    );
    expect(tester.widget<YumeiroButton>(button).onPressed, isNull);
  });

  testWidgets('touch slider moves the numeric field below reset when needed', (
    tester,
  ) async {
    await _pumpInput(
      tester,
      SizedBox(
        width: 140,
        child: YumeiroSliderInput(
          value: .5,
          min: 0,
          max: 1,
          defaultValue: 0,
          onChanged: (_) {},
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final reset = tester.getRect(find.byType(YumeiroButton));
    final field = tester.getRect(find.byType(YumeiroTextField));
    expect(field.top, greaterThan(reset.bottom));
    expect(field.right, reset.right);
  });
}
