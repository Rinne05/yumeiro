import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

void main() {
  testWidgets('the spectrum markers use the active theme’s circular contour', (
    tester,
  ) async {
    for (final (preset, pixel) in [
      (YumeiroThemePresets.classicLight, false),
      (YumeiroThemePresets.pixelDark, true),
    ]) {
      await tester.pumpWidget(
        YumeiroApp(
          key: ValueKey(preset),
          preset: preset,
          modality: YumeiroModality.pointer,
          home: Scaffold(
            body: Center(
              child: YumeiroColorPickerButton(
                value: const Color(0xFF408040),
                defaultColor: Colors.blue,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(YumeiroColorPickerButton));
      await tester.pumpAndSettle();
      for (final (key, radius) in [
        ('yumeiro-color-saturation-value', 6.0),
        ('yumeiro-color-hue', 5.0),
      ]) {
        final spectrum = find.descendant(
          of: find.byKey(ValueKey(key)),
          matching: find.byWidgetPredicate(
            (widget) => widget is CustomPaint && widget.painter != null,
          ),
        );
        expect(spectrum, findsOneWidget);
        if (pixel) {
          expect(
            spectrum,
            paints
              ..path()
              ..path(color: Colors.white),
          );
          expect(spectrum, paintsExactlyCountTimes(#drawCircle, 0));
        } else {
          expect(
            spectrum,
            paints
              ..circle(radius: radius + 2)
              ..circle(radius: radius, color: Colors.white),
          );
        }
      }
    }
  });

  testWidgets('pointer color picker anchors in RTL and avoids the keyboard', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(840, 800);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      YumeiroApp(
        modality: YumeiroModality.pointer,
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            body: Center(
              child: YumeiroColorPickerButton(
                value: Colors.red,
                defaultColor: Colors.blue,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    final trigger = find.byType(YumeiroColorPickerButton);
    final picker = find.byWidgetPredicate(
      (widget) =>
          widget is YumeiroVisualSurface &&
          widget.role == YumeiroSurfaceRole.floating,
    );
    final triggerRect = tester.getRect(trigger);
    final gap = YumeiroTheme.of(tester.element(trigger)).spacing.xs;
    await tester.tap(trigger);
    await tester.pumpAndSettle();

    final below = tester.getRect(picker);
    expect(below.width, 304);
    expect(below.right, closeTo(triggerRect.right, .1));
    expect(below.top, closeTo(triggerRect.bottom + gap, .1));

    tester.view.viewInsets = const FakeViewPadding(bottom: 400);
    await tester.pumpAndSettle();

    final above = tester.getRect(picker);
    expect(above.right, closeTo(triggerRect.right, .1));
    expect(above.bottom, closeTo(triggerRect.top - gap, .1));
    expect(above.bottom, lessThan(400));
  });

  for (final modality in YumeiroModality.values) {
    testWidgets('color spectrum uses the reset hue in $modality', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(850, 900);
      addTearDown(tester.view.reset);

      const defaultColor = Color(0xFFFF0000);
      Color? selected = const Color(0xFF0000FF);
      await tester.pumpWidget(
        YumeiroApp(
          modality: modality,
          home: Scaffold(
            body: Center(
              child: StatefulBuilder(
                builder: (context, setState) => YumeiroColorPickerButton(
                  value: selected,
                  defaultColor: defaultColor,
                  onChanged: (value) => setState(() => selected = value),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(YumeiroColorPickerButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Default').hitTestable());
      await tester.pumpAndSettle();
      expect(selected, isNull);

      final spectrum = find.byKey(
        const ValueKey('yumeiro-color-saturation-value'),
      );
      await tester.tap(spectrum);
      await tester.pumpAndSettle();
      expect(selected, isNotNull);
      expect(HSVColor.fromColor(selected!).hue, closeTo(0, 1));
    });

    testWidgets(
      'open color editor follows the host and preserves alpha in $modality',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(850, 900);
        addTearDown(tester.view.reset);

        const next = Color(0x80223388);
        final current = ValueNotifier(const Color(0x80336633));
        final changes = <Color?>[];
        addTearDown(current.dispose);
        await tester.pumpWidget(
          YumeiroApp(
            modality: modality,
            home: Scaffold(
              body: Center(
                child: ValueListenableBuilder(
                  valueListenable: current,
                  builder: (_, value, _) => YumeiroColorPickerButton(
                    value: value,
                    defaultColor: Colors.red,
                    onChanged: changes.add,
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.byType(YumeiroColorPickerButton));
        await tester.pumpAndSettle();
        final hue = find.byKey(const ValueKey('yumeiro-color-hue'));
        final hueSemantics = find.descendant(
          of: hue,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                widget.properties.slider == true &&
                widget.properties.label ==
                    const YumeiroLocalizationsEn().hueSlider,
          ),
        );
        final editor = find.byType(EditableText);
        expect(tester.widget<Semantics>(hueSemantics).properties.value, '120°');
        await tester.enterText(editor, '#008080');

        current.value = next;
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          tester.widget<EditableText>(editor).controller.text,
          '#80223388',
        );
        expect(
          tester.widget<Semantics>(hueSemantics).properties.value,
          '${HSVColor.fromColor(next).hue.round()}°',
        );
        expect(changes, isEmpty);

        await tester.tap(hue);
        await tester.pumpAndSettle();
        final spectrum = find.byKey(
          const ValueKey('yumeiro-color-saturation-value'),
        );
        await tester.tap(spectrum);
        await tester.pumpAndSettle();
        expect(changes, hasLength(2));
        expect(
          changes.map((color) => color!.toARGB32() >> 24),
          everyElement(0x80),
        );

        await tester.enterText(editor, '#7F112233');
        expect(changes, hasLength(2));
        if (modality == YumeiroModality.touch) {
          await tester.binding.handlePopRoute();
        } else {
          await tester.tapAt(const Offset(10, 10));
        }
        await tester.pumpAndSettle();
        expect(changes, hasLength(3));
        expect(changes.last, const Color(0x7F112233));
        expect(editor, findsNothing);
      },
    );
  }
}
