import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yumeiro/yumeiro.dart';

void main() {
  test('solid fill fades to transparency without shifting color', () {
    const visible = YumeiroSolidFill(Color(0xFFFFCB78));
    const transparent = YumeiroSolidFill(Colors.transparent);
    const expected = Color.fromRGBO(255, 203, 120, .25);
    expect(visible.lerp(transparent, .75).fallbackColor, expected);
    expect(transparent.lerp(visible, .25).fallbackColor, expected);
  });

  test('added and removed outer shadows fade without dimming shared ones', () {
    const shared = BoxShadow(color: Colors.black, blurRadius: 6);
    const extra = BoxShadow(color: Color(0xFF201F1B), offset: Offset(4, 4));
    final single = YumeiroEffectStack(outerShadows: const [shared]);
    final pair = YumeiroEffectStack(outerShadows: const [shared, extra]);
    for (final effects in [single.lerp(pair, .25), pair.lerp(single, .75)]) {
      expect(effects.outerShadows.first, shared);
      expect(effects.outerShadows.last.color.a, .25);
      expect(effects.outerShadows.last.offset, const Offset(1, 1));
    }
  });

  test(
    'solid and glazed themes interpolate their fills without a midpoint jump',
    () {
      const solid = YumeiroSolidFill(Color(0xFF000000));
      const glazed = YumeiroGradientFill(
        LinearGradient(colors: [Color(0xFFFFFFFF), Color(0xFF808080)]),
        fallbackColor: Color(0xFFC0C0C0),
      );
      final forward = solid.lerp(glazed, .25) as YumeiroGradientFill;
      final backward = glazed.lerp(solid, .75) as YumeiroGradientFill;
      expect(forward.gradient, backward.gradient);
      expect(forward.gradient.colors.first.r, closeTo(.25, .005));
      expect(forward.gradient.colors.last.r, closeTo(.125, .005));
    },
  );

  for (final modality in YumeiroModality.values) {
    testWidgets('live material changes retain input and actions in $modality', (
      tester,
    ) async {
      final preset = ValueNotifier(YumeiroThemePresets.classicDark);
      final text = TextEditingController(text: 'Keep my draft');
      final focus = FocusNode();
      addTearDown(preset.dispose);
      addTearDown(text.dispose);
      addTearDown(focus.dispose);
      var actions = 0;
      final content = Scaffold(
        body: Center(
          child: SizedBox(
            width: 300,
            child: YumeiroCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  YumeiroTextField(controller: text, focusNode: focus),
                  const SizedBox(height: 20),
                  YumeiroButton(
                    label: 'Save',
                    variant: YumeiroButtonVariant.primary,
                    onPressed: () => actions++,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpWidget(
        ValueListenableBuilder(
          valueListenable: preset,
          builder: (_, value, _) => YumeiroApp(
            preset: value,
            modality: modality,
            capability: YumeiroMaterialCapability.blurOnly,
            home: content,
          ),
        ),
      );
      focus.requestFocus();
      await tester.pumpAndSettle();
      final editable = tester.element(find.byType(EditableText));
      Finder ink() => find.descendant(
        of: find.byType(YumeiroButton),
        matching: find.byType(InkWell),
      );
      final buttonInk = tester.element(ink());
      for (final value in YumeiroThemePresets.builtInValues) {
        preset.value = value;
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 70));
        expect(tester.takeException(), isNull, reason: value.id);
        expect(tester.element(find.byType(EditableText)), same(editable));
        expect(focus.hasFocus, isTrue, reason: value.id);
        expect(text.text, 'Keep my draft');
        await tester.pumpAndSettle();
        expect(tester.element(ink()), same(buttonInk));
      }
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(actions, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
