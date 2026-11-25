import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/src/components/controls/form_picker_trigger.dart';
import 'package:yumeiro/yumeiro.dart';

void main() {
  for (final (modality, dense) in [
    for (final modality in YumeiroModality.values) ...[
      (modality, false),
      (modality, true),
    ],
  ]) {
    testWidgets(
      'form pickers share dimensions in ${modality.name}, dense: $dense',
      (tester) async {
        const workspace = ValueKey('workspace');
        const reviewers = ValueKey('reviewers');
        const assignee = ValueKey('assignee');
        final textScaler = dense
            ? const TextScaler.linear(1.8)
            : TextScaler.noScaling;
        await tester.pumpWidget(
          YumeiroApp(
            modality: modality,
            home: Scaffold(
              body: Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(textScaler: textScaler),
                  child: SizedBox(
                    width: 280,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        YumeiroSelect.form<int>(
                          key: workspace,
                          label: 'Workspace',
                          placeholder: 'Choose a workspace',
                          options: const [
                            YumeiroSelectionOption(value: 1, label: 'Design'),
                          ],
                          dense: dense,
                        ),
                        YumeiroMultiSelect.form<int>(
                          key: reviewers,
                          label: 'Reviewers',
                          placeholder: 'Choose reviewers',
                          options: const [
                            YumeiroSelectionOption(value: 1, label: 'Taylor'),
                          ],
                          dense: dense,
                        ),
                        YumeiroAsyncSelect.form<int>(
                          key: assignee,
                          label: 'Assignee',
                          initialValue: const YumeiroSelectionOption(
                            value: 1,
                            label: 'Jordan',
                          ),
                          loadOptions: (_) async => const [],
                          dense: dense,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        Size fieldSize(Key field, {Finder? control}) => tester.getSize(
          find.descendant(
            of: find.byKey(field),
            matching: control ?? find.byType(YumeiroInteractiveVisualSurface),
          ),
        );
        final field = fieldSize(workspace);
        expect(field.width, 280);
        expect(fieldSize(reviewers), field);
        expect(
          fieldSize(
            assignee,
            control: modality == YumeiroModality.pointer
                ? find.byType(YumeiroTextField)
                : null,
          ),
          field,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('a Form manages typed fields alongside an independent input', (
    tester,
  ) async {
    final form = GlobalKey<FormState>();
    final title = GlobalKey<FormFieldState<String>>();
    final priority = GlobalKey<FormFieldState<String>>();
    final query = TextEditingController();
    addTearDown(query.dispose);
    final saved = <String, String?>{};

    await tester.pumpWidget(
      YumeiroApp(
        home: Scaffold(
          body: Form(
            key: form,
            child: Column(
              children: [
                YumeiroTextField.form(
                  key: title,
                  label: 'Task name',
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a task name'
                      : null,
                  onSaved: (value) => saved['title'] = value,
                ),
                YumeiroSelect.form<String>(
                  key: priority,
                  label: 'Priority',
                  options: const [
                    YumeiroSelectionOption(value: 'normal', label: 'Normal'),
                    YumeiroSelectionOption(value: 'urgent', label: 'Urgent'),
                  ],
                  validator: (value) =>
                      value == null ? 'Choose a priority' : null,
                  onSaved: (value) => saved['priority'] = value,
                ),
                YumeiroFieldLayout(
                  label: 'Search',
                  child: YumeiroTextField(controller: query),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(form.currentState!.fields, hasLength(2));
    expect(form.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Enter a task name'), findsOneWidget);
    expect(find.text('Choose a priority'), findsOneWidget);

    await tester.enterText(
      find.descendant(of: find.byKey(title), matching: find.byType(TextField)),
      'Ship documentation',
    );
    priority.currentState!.didChange('urgent');
    query.text = 'example';
    expect(form.currentState!.validate(), isTrue);
    form.currentState!.save();
    await tester.pump();
    expect(find.text('Urgent'), findsOneWidget);
    expect(saved, {'title': 'Ship documentation', 'priority': 'urgent'});

    form.currentState!.reset();
    await tester.pump();
    expect(title.currentState!.value, '');
    expect(priority.currentState!.value, isNull);
    expect(query.text, 'example');
    expect(find.text('Urgent'), findsNothing);
    expect(find.text('Enter a task name'), findsNothing);
    expect(find.text('Choose a priority'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('narrow touch pickers keep their clear actions reachable', (
    tester,
  ) async {
    final selection = GlobalKey<FormFieldState<int>>();
    final time = GlobalKey<FormFieldState<TimeOfDay>>();
    final focus = FocusNode();
    final widths = ValueNotifier((select: 200.0, time: 200.0));
    addTearDown(focus.dispose);
    addTearDown(widths.dispose);

    await tester.pumpWidget(
      YumeiroApp(
        modality: YumeiroModality.touch,
        home: Scaffold(
          body: ValueListenableBuilder(
            valueListenable: widths,
            builder: (context, width, _) => Column(
              children: [
                YumeiroSelect.form(
                  key: selection,
                  label: 'Priority',
                  width: width.select,
                  focusNode: focus,
                  clearable: true,
                  initialValue: 1,
                  options: const [
                    YumeiroSelectionOption(value: 1, label: 'Normal'),
                  ],
                ),
                YumeiroTimePicker.form(
                  key: time,
                  label: 'Start time',
                  width: width.time,
                  clearable: true,
                  initialValue: const TimeOfDay(hour: 12, minute: 0),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    focus.requestFocus();
    await tester.pumpAndSettle();
    expect(focus.hasPrimaryFocus, isTrue);

    widths.value = (select: 100, time: 110);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(focus.hasPrimaryFocus, isTrue);

    for (final field in [selection, time]) {
      final trigger = find.descendant(
        of: find.byKey(field),
        matching: find.byType(YumeiroPickerTriggerSurface),
      );
      final clear = find.descendant(
        of: find.byKey(field),
        matching: find.byType(YumeiroButton),
      );
      final before = tester.getRect(trigger);
      final action = tester.getRect(clear);
      expect(action.width, greaterThanOrEqualTo(48));
      expect(action.height, greaterThanOrEqualTo(48));
      expect(before.right - action.right, greaterThanOrEqualTo(48));
      expect(action.top, before.top);
      expect(action.bottom, before.bottom);
      await tester.tap(clear);
      await tester.pumpAndSettle();
      expect(field.currentState!.value, isNull);
      expect(tester.getRect(trigger), before);
    }
    widths.value = (select: 100, time: 86);
    await tester.pumpAndSettle();
    final narrowTime = find.byKey(time);
    final emptyField = tester.getSize(narrowTime);
    time.currentState!.didChange(const TimeOfDay(hour: 12, minute: 0));
    await tester.pumpAndSettle();
    expect(tester.getSize(narrowTime), emptyField);
    expect(tester.takeException(), isNull);
  });
}
