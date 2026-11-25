import 'package:flutter/services.dart' show AutofillHints, MaxLengthEnforcement;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

Widget _host(Widget child, {String? restorationScopeId}) => YumeiroApp(
  restorationScopeId: restorationScopeId,
  home: Scaffold(
    body: Padding(padding: const EdgeInsets.all(24), child: child),
  ),
);

void main() {
  testWidgets('native form validates, saves and resets the visible text', (
    tester,
  ) async {
    final form = GlobalKey<FormState>();
    final field = GlobalKey<FormFieldState<String>>();
    final focus = FocusNode();
    addTearDown(focus.dispose);
    final saves = <String?>[];
    final reports = <String>[];
    await tester.pumpWidget(
      _host(
        Form(
          key: form,
          child: YumeiroTextField.form(
            key: field,
            initialValue: 'Initial',
            label: 'Name',
            required: true,
            helperText: 'Your display name',
            focusNode: focus,
            validator: (text) => text!.trim().isEmpty ? 'Enter a name' : null,
            onSaved: saves.add,
            onChanged: reports.add,
            clearable: true,
          ),
        ),
      ),
    );

    expect(find.text('Your display name'), findsOneWidget);
    final input = find.byType(TextField);
    await tester.tap(input);
    await tester.pump();
    expect(focus.hasFocus, isTrue);
    await tester.tap(find.byTooltip('Clear'));
    await tester.pump();
    expect(reports, ['']);
    expect(form.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Enter a name'), findsOneWidget);
    expect(find.text('Your display name'), findsNothing);
    expect(
      tester.widget<YumeiroTextField>(find.byType(YumeiroTextField)).hasError,
      isTrue,
    );
    expect(focus.hasFocus, isTrue);

    await tester.enterText(input, 'Updated');
    expect(form.currentState!.validate(), isTrue);
    form.currentState!.save();
    await tester.pump();
    expect(saves, ['Updated']);
    expect(reports, ['', 'Updated']);

    form.currentState!.reset();
    await tester.pump();
    expect(tester.widget<TextField>(input).controller!.text, 'Initial');
    expect(field.currentState!.value, 'Initial');
    expect(field.currentState!.hasInteractedByUser, isFalse);
    expect(find.text('Enter a name'), findsNothing);
    expect(reports, ['', 'Updated']);
  });

  testWidgets(
    'same external controller keeps its reset value across rebuilds',
    (tester) async {
      final form = GlobalKey<FormState>();
      final field = GlobalKey<FormFieldState<String>>();
      final controller = TextEditingController(text: 'Seed');
      final rebuild = ValueNotifier<bool>(false);
      addTearDown(controller.dispose);
      addTearDown(rebuild.dispose);
      final reports = <String>[];
      final resets = <(String, String?, bool)>[];
      await tester.pumpWidget(
        _host(
          Form(
            key: form,
            child: ValueListenableBuilder(
              valueListenable: rebuild,
              builder: (context, value, child) => YumeiroTextField.form(
                key: field,
                label: value ? 'Updated name' : 'Name',
                controller: controller,
                validator: (text) => text!.isEmpty ? 'Missing name' : null,
                onChanged: reports.add,
                onReset: () => resets.add((
                  controller.text,
                  field.currentState!.value,
                  field.currentState!.hasInteractedByUser,
                )),
                autovalidateMode: AutovalidateMode.always,
              ),
            ),
          ),
        ),
      );

      controller.clear();
      await tester.pump();
      expect(find.text('Missing name'), findsOneWidget);
      expect(field.currentState!.value, '');
      expect(field.currentState!.hasInteractedByUser, isFalse);
      expect(reports, isEmpty);

      await tester.enterText(find.byType(TextField), 'Draft');
      await tester.pump();
      expect(find.text('Missing name'), findsNothing);
      expect(field.currentState!.hasInteractedByUser, isTrue);
      rebuild.value = true;
      await tester.pump();
      expect(find.text('Updated name'), findsOneWidget);
      expect(field.currentState!.value, 'Draft');
      form.currentState!.reset();
      await tester.pump();
      expect(resets, [('Seed', 'Seed', false)]);
      expect(controller.text, 'Seed');
      expect(field.currentState!.value, 'Seed');
      expect(reports, ['Draft']);
    },
  );

  testWidgets('switching to an owned controller retains the external draft', (
    tester,
  ) async {
    final field = GlobalKey<FormFieldState<String>>();
    final controller = TextEditingController(text: 'Outside');
    final external = ValueNotifier<TextEditingController?>(null);
    addTearDown(controller.dispose);
    addTearDown(external.dispose);
    await tester.pumpWidget(
      _host(
        ValueListenableBuilder(
          valueListenable: external,
          builder: (context, value, child) => YumeiroTextField.form(
            key: field,
            controller: value,
            initialValue: value == null ? 'Local' : null,
          ),
        ),
      ),
    );

    external.value = controller;
    await tester.pump();
    expect(field.currentState!.value, 'Outside');
    controller.value = const TextEditingValue(
      text: 'Draft',
      selection: TextSelection.collapsed(offset: 2),
    );
    external.value = null;
    await tester.pump();
    final owned = tester.widget<TextField>(find.byType(TextField)).controller!;
    expect(owned.text, 'Draft');
    expect(owned.selection.baseOffset, 2);
    expect(field.currentState!.value, 'Draft');
    controller.text = 'Detached';
    await tester.pump();
    expect(field.currentState!.value, 'Draft');
    field.currentState!.reset();
    await tester.pump();
    expect(owned.text, 'Local');
  });

  testWidgets('external errors, native input constraints and autofill bind', (
    tester,
  ) async {
    final form = GlobalKey<FormState>();
    await tester.pumpWidget(
      _host(
        Form(
          key: form,
          child: YumeiroTextField.form(
            label: 'Email',
            forceErrorText: 'Already registered',
            maxLength: 2,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            autofillHints: [AutofillHints.email],
          ),
        ),
      ),
    );
    final input = find.byType(TextField);
    expect(tester.widget<TextField>(input).autofillHints, [
      AutofillHints.email,
    ]);
    expect(find.text('Already registered'), findsOneWidget);
    expect(form.currentState!.validate(), isFalse);
    await tester.enterText(input, 'a👩‍💻x');
    expect(tester.widget<TextField>(input).controller!.text, 'a👩‍💻');
  });

  testWidgets('standalone input restores its internally owned text', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const YumeiroTextField(
          initialValue: 'Initial',
          restorationId: 'raw',
          clearable: true,
        ),
        restorationScopeId: 'text-app',
      ),
    );
    final input = find.byType(TextField);
    await tester.enterText(input, 'Restored draft');
    await tester.pump();
    await tester.restartAndRestore();
    expect(tester.widget<TextField>(input).controller!.text, 'Restored draft');
    expect(find.byTooltip('Clear'), findsOneWidget);
  });

  testWidgets('form input restores the text and its native field state', (
    tester,
  ) async {
    final form = GlobalKey<FormState>();
    final field = GlobalKey<FormFieldState<String>>();
    await tester.pumpWidget(
      _host(
        Form(
          key: form,
          child: YumeiroTextField.form(
            key: field,
            initialValue: 'Initial',
            restorationId: 'form-input',
            validator: (text) => text == 'Initial' ? null : 'Check draft',
          ),
        ),
        restorationScopeId: 'form-app',
      ),
    );
    final input = find.byType(TextField);
    await tester.enterText(input, 'Restored draft');
    expect(form.currentState!.validate(), isFalse);
    await tester.pump();
    await tester.restartAndRestore();
    expect(tester.widget<TextField>(input).controller!.text, 'Restored draft');
    expect(field.currentState!.value, 'Restored draft');
    expect(field.currentState!.hasInteractedByUser, isTrue);
    expect(find.text('Check draft'), findsOneWidget);
    form.currentState!.reset();
    await tester.pump();
    expect(tester.widget<TextField>(input).controller!.text, 'Initial');
    expect(field.currentState!.value, 'Initial');
    expect(find.text('Check draft'), findsNothing);
  });
}
