import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

void main() {
  testWidgets('range slider can adjust each endpoint by keyboard', (
    tester,
  ) async {
    var values = const RangeValues(2, 8);
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) => YumeiroRangeSlider(
            values: values,
            min: 0,
            max: 10,
            divisions: 10,
            onChanged: (next) => setState(() => values = next),
          ),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(values, const RangeValues(3, 8));

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(values, const RangeValues(3, 7));
  });

  testWidgets('touch drag updates and commits only the selected endpoint', (
    tester,
  ) async {
    const initial = RangeValues(.2, .8);
    var values = initial;
    final started = <RangeValues>[];
    final completed = <RangeValues>[];
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) => YumeiroRangeSlider(
            values: values,
            divisions: 10,
            onChangeStart: started.add,
            onChanged: (next) => setState(() => values = next),
            onChangeEnd: completed.add,
          ),
        ),
        modality: YumeiroModality.touch,
      ),
    );
    final slider = tester.getRect(find.byType(RangeSlider));
    await tester.dragFrom(
      Offset(slider.left + slider.width * .2, slider.center.dy),
      const Offset(70, 0),
    );
    await tester.pumpAndSettle();
    expect(started, [initial]);
    expect(values.start, greaterThan(initial.start));
    expect(values.end, initial.end);
    expect(completed, [values]);
  });

  testWidgets('range slider clamps endpoints and applies Yumeiro touch theme', (
    tester,
  ) async {
    String formatter(double value) => '${value.round()} minutes';
    const padding = EdgeInsets.symmetric(horizontal: 18);
    await tester.pumpWidget(
      _host(
        YumeiroRangeSlider(
          values: const RangeValues(-1, 12),
          min: 0,
          max: 10,
          onChanged: null,
          activeColor: Colors.green,
          thumbColor: Colors.blue,
          semanticFormatterCallback: formatter,
          padding: padding,
        ),
        modality: YumeiroModality.touch,
      ),
    );
    final slider = find.byType(RangeSlider);
    final native = tester.widget<RangeSlider>(slider);
    final context = tester.element(slider);
    final sliderTheme = SliderTheme.of(context);
    final theme = YumeiroTheme.of(context).sliderTheme;
    expect(native.values, const RangeValues(0, 10));
    expect(native.onChanged, isNull);
    expect(native.semanticFormatterCallback, formatter);
    expect(native.padding, padding);
    expect(sliderTheme.trackHeight, theme.trackHeight);
    expect(sliderTheme.disabledThumbColor, theme.disabledThumbColor);
    expect(sliderTheme.activeTrackColor, Colors.green);
    expect(sliderTheme.thumbColor, Colors.blue);
    expect(
      tester.getSize(slider).height,
      YumeiroModalityScope.metricsOf(context).minTargetSize,
    );
  });
}

Widget _host(
  Widget child, {
  YumeiroModality modality = YumeiroModality.pointer,
}) => YumeiroApp(
  modality: modality,
  home: Scaffold(
    body: Center(child: SizedBox(width: 320, child: child)),
  ),
);
