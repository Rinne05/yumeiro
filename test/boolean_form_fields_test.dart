import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

void main() {
  testWidgets('checkbox and switch validate, save and reset with the form', (
    tester,
  ) async {
    final form = GlobalKey<FormState>();
    final checkbox = GlobalKey<FormFieldState<bool>>();
    final switchField = GlobalKey<FormFieldState<bool>>();
    final focus = FocusNode();
    addTearDown(focus.dispose);
    final edited = <bool?>[];
    final saved = <bool?>[];
    var resets = 0;

    await tester.pumpWidget(
      _app(
        Form(
          key: form,
          child: Column(
            children: [
              YumeiroCheckbox.form(
                key: checkbox,
                label: 'Accept the terms',
                required: true,
                focusNode: focus,
                validator: (value) => value == true ? null : 'Please accept',
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onChanged: edited.add,
                onSaved: saved.add,
                onReset: () => resets++,
              ),
              YumeiroSwitch.form(
                key: switchField,
                label: 'Send reminders',
                initialValue: true,
                onChanged: edited.add,
                onSaved: saved.add,
                onReset: () => resets++,
              ),
            ],
          ),
        ),
      ),
    );
    expect(form.currentState!.validate(), isFalse);
    await tester.pumpAndSettle();
    expect(find.text('Please accept'), findsOneWidget);
    focus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.tap(find.byType(YumeiroSwitch));
    await tester.pumpAndSettle();
    expect(form.currentState!.validate(), isTrue);
    expect(find.text('Please accept'), findsNothing);
    expect(edited, [true, false]);
    form.currentState!.save();
    expect(saved, [true, false]);

    form.currentState!.reset();
    await tester.pumpAndSettle();
    expect(checkbox.currentState!.value, isFalse);
    expect(switchField.currentState!.value, isTrue);
    expect(edited, [true, false]);
    expect(resets, 2);
  });

  testWidgets('read-only remains focusable and disabled cannot be edited', (
    tester,
  ) async {
    final focus = FocusNode();
    final disabledFocus = FocusNode();
    addTearDown(focus.dispose);
    addTearDown(disabledFocus.dispose);
    final checkbox = GlobalKey<FormFieldState<bool>>();
    final switchField = GlobalKey<FormFieldState<bool>>();
    final edited = <bool?>[];

    await tester.pumpWidget(
      _app(
        Column(
          children: [
            YumeiroCheckbox.form(
              key: checkbox,
              label: 'Mixed permission',
              tristate: true,
              initialValue: null,
              readOnly: true,
              focusNode: focus,
              autofocus: true,
              onChanged: edited.add,
            ),
            YumeiroSwitch.form(
              key: switchField,
              label: 'Reminders unavailable',
              enabled: false,
              focusNode: disabledFocus,
              autofocus: true,
              onChanged: edited.add,
              forceErrorText: 'Server rejected reminders',
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(focus.hasPrimaryFocus, isTrue);
    expect(disabledFocus.hasFocus, isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.tap(find.byType(YumeiroCheckbox), warnIfMissed: false);
    await tester.tap(find.byType(YumeiroSwitch));
    await tester.pumpAndSettle();
    expect(edited, isEmpty);
    expect(checkbox.currentState!.value, isNull);
    expect(switchField.currentState!.value, isFalse);
    expect(find.text('Server rejected reminders'), findsOneWidget);
  });

  testWidgets('tri-state changes retain null as a legitimate value', (
    tester,
  ) async {
    final field = GlobalKey<FormFieldState<bool>>();
    final changes = <bool?>[];
    await tester.pumpWidget(
      _app(
        YumeiroCheckbox.form(
          key: field,
          label: 'Apply to all',
          tristate: true,
          initialValue: true,
          onChanged: changes.add,
        ),
      ),
    );
    await tester.tap(find.byType(YumeiroCheckbox));
    await tester.pumpAndSettle();
    expect(field.currentState!.value, isNull);
    expect(changes, [null]);
    field.currentState!.reset();
    await tester.pumpAndSettle();
    expect(field.currentState!.value, isTrue);
    expect(changes, [null]);
  });

  testWidgets('a checkbox and a switch keep distinct field state', (
    tester,
  ) async {
    final key = GlobalKey<FormFieldState<bool>>();
    await tester.pumpWidget(
      _app(
        YumeiroCheckbox.form(
          key: key,
          label: 'Apply to all',
          tristate: true,
          initialValue: null,
        ),
      ),
    );
    final checkbox = key.currentState!;
    expect(checkbox.value, isNull);

    await tester.pumpWidget(
      _app(YumeiroCheckbox.form(key: key, label: 'Apply to all')),
    );
    expect(key.currentState, same(checkbox));
    expect(checkbox.value, isFalse);

    await tester.pumpWidget(
      _app(
        YumeiroSwitch.form(key: key, label: 'Apply to all', initialValue: true),
      ),
    );
    expect(key.currentState, isNot(same(checkbox)));
    expect(key.currentState!.value, isTrue);
  });
}

Widget _app(Widget child) => YumeiroApp(
  modality: YumeiroModality.pointer,
  home: Scaffold(body: child),
);
