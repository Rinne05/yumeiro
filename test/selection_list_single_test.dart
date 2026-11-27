import 'dart:ui' show SemanticsRole;

import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/src/components/controls/selection_control.dart';
import 'package:yumeiro/yumeiro.dart';

const _options = [
  YumeiroSelectionOption(
    value: 'alpha',
    label: 'Alpha',
    subtitle: 'First choice',
  ),
  YumeiroSelectionOption(value: 'locked', label: 'Locked', enabled: false),
  YumeiroSelectionOption(value: 'beta', label: 'Beta'),
];

Widget _host(
  Widget child, {
  YumeiroModality modality = YumeiroModality.pointer,
}) => YumeiroApp(
  modality: modality,
  home: Scaffold(
    body: Align(
      alignment: Alignment.topCenter,
      child: SizedBox(width: 400, child: child),
    ),
  ),
);

Finder _row(String label) => find.ancestor(
  of: find.text(label),
  matching: find.byWidgetPredicate((widget) => widget is RawRadio),
);

Finder _group(String label) => find.ancestor(
  of: _row(label),
  matching: find.byWidgetPredicate((widget) => widget is RadioGroup),
);

Finder _marksWithin(Finder rows) => find.descendant(
  of: find.descendant(of: rows, matching: find.byType(SelectionControlMark)),
  matching: find.byWidgetPredicate(
    (widget) => widget is CustomPaint && widget.foregroundPainter != null,
  ),
);

FocusNode _focusOf(WidgetTester tester, String label) =>
    tester.widget<RawRadio<Object?>>(_row(label)).focusNode;

bool _hasFocusIndicator(WidgetTester tester, String label) => tester
    .widget<YumeiroResolvedVisualSurface>(
      find
          .descendant(
            of: _row(label),
            matching: find.byType(YumeiroResolvedVisualSurface),
          )
          .first,
    )
    .appearance
    .focusIndicator
    .isVisible;

Future<void> _press(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'inline option marks adapt to the theme and distinguish disabled choices',
    (tester) async {
      const disabledForeground = Color(0xff6a2c92);
      final changes = <Set<String>>[];
      Widget list(YumeiroThemePreset preset, {bool readOnly = false}) =>
          YumeiroApp(
            preset: preset,
            modality: YumeiroModality.pointer,
            home: Scaffold(
              body: YumeiroVisualScope(
                visualOverride: YumeiroVisualOverride(
                  states: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.disabled)
                        ? const YumeiroVisualDelta(
                            foreground: disabledForeground,
                          )
                        : null,
                  ),
                ),
                child: YumeiroSelectionList<String>(
                  options: _options,
                  values: const {'locked'},
                  onChanged: changes.add,
                  readOnly: readOnly,
                  scrollable: false,
                ),
              ),
            ),
          );
      Finder marksIn(String label) => _marksWithin(_row(label));

      await tester.pumpWidget(list(YumeiroThemePresets.classicLight));
      await tester.pumpAndSettle();
      expect(marksIn('Alpha'), findsNothing);
      expect(marksIn('Locked'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('Locked')).style?.color,
        disabledForeground,
      );

      await tester.pumpWidget(list(YumeiroThemePresets.pixelDark));
      await tester.pumpAndSettle();
      for (final option in _options) {
        expect(marksIn(option.label), findsOneWidget);
      }
      final locked = find.semantics.byLabel('Locked');
      expect(
        locked.evaluate().single,
        isSemantics(
          hasCheckedState: true,
          isChecked: true,
          hasEnabledState: true,
          isEnabled: false,
          isInMutuallyExclusiveGroup: true,
          hasTapAction: false,
        ),
      );
      await tester.tapAt(tester.getCenter(marksIn('Locked')));
      await tester.pumpAndSettle();
      expect(changes, isEmpty);

      _focusOf(tester, 'Alpha').requestFocus();
      await tester.pumpAndSettle();
      await _press(tester, LogicalKeyboardKey.arrowDown);
      expect(changes, [
        {'beta'},
      ]);

      await tester.pumpWidget(
        list(YumeiroThemePresets.classicLight, readOnly: true),
      );
      await tester.pumpAndSettle();
      expect(marksIn('Locked'), findsNothing);
    },
  );

  testWidgets('an explicit disabled option uses the shared checkbox mark', (
    tester,
  ) async {
    final changes = <Set<String>>[];
    await tester.pumpWidget(
      _host(
        Column(
          children: [
            YumeiroSelectionList<String>(
              multiple: true,
              options: _options,
              values: const {'locked'},
              onChanged: changes.add,
              scrollable: false,
            ),
            const YumeiroSelectionRow(
              title: Text('Disabled row'),
              selected: false,
              enabled: false,
              onChanged: null,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      _marksWithin(find.byType(YumeiroSelectionList<String>)),
      findsOneWidget,
    );
    expect(_marksWithin(find.byType(YumeiroSelectionRow)), findsOneWidget);

    await tester.tapAt(tester.getCenter(find.text('Locked')));
    await tester.pumpAndSettle();
    expect(changes, isEmpty);
    await tester.tap(find.text('Beta'));
    expect(changes, [
      {'locked', 'beta'},
    ]);
  });

  testWidgets(
    'single selection has one Tab stop and arrow keys skip disabled choices',
    (tester) async {
      final before = FocusNode();
      final after = FocusNode();
      addTearDown(before.dispose);
      addTearDown(after.dispose);
      final choices = <String>[];
      var values = const <String>{};
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              TextButton(
                focusNode: before,
                onPressed: () {},
                child: const Text('Before'),
              ),
              StatefulBuilder(
                builder: (_, setState) => YumeiroSelectionList(
                  options: _options,
                  values: values,
                  scrollable: false,
                  semanticLabel: 'Layout choices',
                  onChanged: (next) {
                    choices.add(next.single);
                    setState(() => values = next);
                  },
                ),
              ),
              TextButton(
                focusNode: after,
                onPressed: () {},
                child: const Text('After'),
              ),
            ],
          ),
        ),
      );

      final group = tester.semantics.find(_group('Alpha'));
      expect(
        group,
        isSemantics(label: 'Layout choices', role: SemanticsRole.radioGroup),
      );
      expect(find.byType(EditableText), findsNothing);
      final alpha = find.semantics.byLabel(RegExp('Alpha'));
      expect(
        alpha.evaluate().single,
        isSemantics(
          hasCheckedState: true,
          isChecked: false,
          isInMutuallyExclusiveGroup: true,
          hasTapAction: true,
        ),
      );
      expect(
        find.semantics.byLabel('Locked').evaluate().single,
        isSemantics(
          hasCheckedState: true,
          hasEnabledState: true,
          isEnabled: false,
          isInMutuallyExclusiveGroup: true,
          hasTapAction: false,
        ),
      );

      await _press(tester, LogicalKeyboardKey.tab);
      expect(before.hasFocus, isTrue);
      await _press(tester, LogicalKeyboardKey.tab);
      expect(_focusOf(tester, 'Alpha').hasFocus, isTrue);
      expect(_hasFocusIndicator(tester, 'Alpha'), isTrue);
      expect(choices, isEmpty);
      await _press(tester, LogicalKeyboardKey.space);
      expect(choices, ['alpha']);
      await _press(tester, LogicalKeyboardKey.arrowDown);
      expect(_focusOf(tester, 'Beta').hasFocus, isTrue);
      expect(_hasFocusIndicator(tester, 'Beta'), isTrue);
      expect(_hasFocusIndicator(tester, 'Alpha'), isFalse);
      expect(choices, ['alpha', 'beta']);
      await _press(tester, LogicalKeyboardKey.arrowDown);
      expect(_focusOf(tester, 'Alpha').hasFocus, isTrue);
      expect(choices, ['alpha', 'beta', 'alpha']);
      await _press(tester, LogicalKeyboardKey.arrowUp);
      expect(_focusOf(tester, 'Beta').hasFocus, isTrue);
      expect(choices, ['alpha', 'beta', 'alpha', 'beta']);
      await _press(tester, LogicalKeyboardKey.tab);
      expect(after.hasFocus, isTrue);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await _press(tester, LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      expect(_focusOf(tester, 'Beta').hasFocus, isTrue);
      expect(values, {'beta'});
    },
  );

  testWidgets('a nullable option remains distinct from an empty selection', (
    tester,
  ) async {
    var values = const <String?>{};
    final changes = <Set<String?>>[];
    final clicks = <String?>[];
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (_, setState) => YumeiroSelectionList<String?>(
            options: const [
              YumeiroSelectionOption(value: null, label: 'Off'),
              YumeiroSelectionOption(value: 'on', label: 'On'),
            ],
            values: values,
            onChanged: (next) {
              changes.add(next);
              setState(() => values = next);
            },
            onSelected: (option) => clicks.add(option.value),
          ),
        ),
      ),
    );

    final off = find.text('Off');
    expect(tester.getSemantics(off), isSemantics(hasCheckedState: true));
    expect(tester.getSemantics(off), isSemantics(isChecked: false));

    await tester.tap(off);
    await tester.pumpAndSettle();
    expect(tester.getSemantics(off), isSemantics(isChecked: true));
    await tester.tap(off);
    await tester.pumpAndSettle();
    expect(changes, [
      {null},
    ]);
    expect(clicks, [null, null]);
  });

  testWidgets(
    'selected disabled choice stays checked while another row can activate',
    (tester) async {
      final reports = <String>[];
      await tester.pumpWidget(
        _host(
          YumeiroSelectionList(
            options: _options,
            values: const {'locked'},
            onChanged: (values) => reports.add(values.single),
            dense: true,
          ),
          modality: YumeiroModality.touch,
        ),
      );
      expect(
        find.semantics.byLabel('Locked').evaluate().single,
        isSemantics(
          hasCheckedState: true,
          isChecked: true,
          isEnabled: false,
          hasTapAction: false,
        ),
      );
      await _press(tester, LogicalKeyboardKey.tab);
      expect(_focusOf(tester, 'Alpha').hasFocus, isTrue);
      await tester.tap(find.text('Locked'));
      expect(reports, isEmpty);
      final target = tester.getRect(_row('Beta'));
      expect(target.height, greaterThanOrEqualTo(48));
      await tester.tapAt(Offset(target.right - 5, target.center.dy));
      await tester.pumpAndSettle();
      expect(reports, ['beta']);
      expect(
        find.semantics.byLabel('Beta').evaluate().single,
        isSemantics(hasCheckedState: true, isChecked: false),
      );
    },
  );

  testWidgets(
    'single selection form validates, saves, resets and respects read-only state',
    (tester) async {
      final form = GlobalKey<FormState>();
      final field = GlobalKey<FormFieldState<String>>();
      final readOnly = ValueNotifier(false);
      addTearDown(readOnly.dispose);
      final saves = <String?>[];
      final changes = <String>[];
      var resets = 0;
      await tester.pumpWidget(
        _host(
          Form(
            key: form,
            child: ValueListenableBuilder(
              valueListenable: readOnly,
              builder: (_, value, _) => YumeiroSelectionList.form<String>(
                key: field,
                options: _options,
                label: 'Display mode',
                helperText: 'Choose the density',
                required: true,
                readOnly: value,
                validator: (value) => value == null ? 'Choose a mode' : null,
                onChanged: changes.add,
                onSaved: saves.add,
                onReset: () => resets++,
              ),
            ),
          ),
        ),
      );

      expect(field.currentState!.value, isNull);
      expect(form.currentState!.validate(), isFalse);
      await tester.pumpAndSettle();
      expect(find.text('Choose a mode'), findsOneWidget);
      expect(find.text('Choose the density'), findsNothing);
      await tester.tap(find.text('Beta'));
      expect(field.currentState!.value, 'beta');
      expect(form.currentState!.validate(), isTrue);
      form.currentState!.save();
      await tester.pumpAndSettle();
      expect(saves, ['beta']);
      expect(changes, ['beta']);
      expect(find.text('Choose the density'), findsOneWidget);

      readOnly.value = true;
      await tester.pumpAndSettle();
      expect(
        tester.semantics.find(_group('Beta')),
        isSemantics(
          label: 'Display mode',
          role: SemanticsRole.radioGroup,
          isReadOnly: true,
        ),
      );
      expect(
        find.semantics.byLabel('Beta').evaluate().single,
        isSemantics(
          hasCheckedState: true,
          isChecked: true,
          hasEnabledState: true,
          isEnabled: false,
          hasTapAction: false,
        ),
      );
      expect(tester.widget<RawRadio<Object?>>(_row('Beta')).enabled, isFalse);
      await tester.tap(find.text('Alpha'));
      expect(field.currentState!.value, 'beta');
      expect(changes, ['beta']);

      form.currentState!.reset();
      await tester.pumpAndSettle();
      expect(field.currentState!.value, isNull);
      expect(field.currentState!.hasInteractedByUser, isFalse);
      expect(resets, 1);
      expect(changes, ['beta']);
      expect(find.text('Choose a mode'), findsNothing);
    },
  );

  testWidgets(
    'a single selection field starts fresh when replacing a plain form field',
    (tester) async {
      final showSelection = ValueNotifier(false);
      addTearDown(showSelection.dispose);
      final field = GlobalKey<FormFieldState<String>>();
      await tester.pumpWidget(
        _host(
          Form(
            child: ValueListenableBuilder(
              valueListenable: showSelection,
              builder: (_, show, _) => show
                  ? YumeiroSelectionList.form<String>(
                      key: field,
                      options: _options,
                      initialValue: 'beta',
                    )
                  : FormField<String>(
                      key: field,
                      builder: (_) => const SizedBox.shrink(),
                    ),
            ),
          ),
        ),
      );

      final plain = field.currentState!;
      plain.didChange('alpha');
      showSelection.value = true;
      await tester.pumpAndSettle();

      expect(field.currentState, isNot(same(plain)));
      expect(field.currentState!.value, 'beta');
      expect(field.currentState!.hasInteractedByUser, isFalse);
    },
  );
}
