import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

void main() {
  testWidgets('date, time and range clear and reset through Flutter Form', (
    tester,
  ) async {
    final form = GlobalKey<FormState>();
    final date = GlobalKey<FormFieldState<DateTime>>();
    final time = GlobalKey<FormFieldState<TimeOfDay>>();
    final range = GlobalKey<FormFieldState<DateTimeRange<DateTime>>>();
    final seedDate = DateTime.utc(2027, 1, 11, 23, 10);
    const seedTime = TimeOfDay(hour: 17, minute: 5);
    final seedRange = DateTimeRange(
      start: DateTime.utc(2027, 1, 12, 22),
      end: DateTime.utc(2027, 1, 14, 2),
    );
    final saved = <Object?>[];
    final changes = <String>[];
    final resets = <String>[];

    await tester.pumpWidget(
      _page(
        Form(
          key: form,
          child: Column(
            children: [
              YumeiroDatePicker.form(
                key: date,
                label: 'Start date',
                firstDate: DateTime(2027, 1),
                lastDate: DateTime(2027, 12, 31),
                initialValue: seedDate,
                required: true,
                clearable: true,
                validator: (value) => value == null ? 'Choose a date' : null,
                onChanged: (value) => changes.add('date:$value'),
                onSaved: saved.add,
                onReset: () => resets.add('date'),
              ),
              YumeiroTimePicker.form(
                key: time,
                label: 'Start time',
                initialValue: seedTime,
                required: true,
                clearable: true,
                validator: (value) => value == null ? 'Choose a time' : null,
                onChanged: (value) => changes.add('time:$value'),
                onSaved: saved.add,
                onReset: () => resets.add('time'),
              ),
              YumeiroDateRangePicker.form(
                key: range,
                label: 'Booking window',
                firstDate: DateTime(2027, 1),
                lastDate: DateTime(2027, 12, 31),
                initialValue: seedRange,
                required: true,
                clearable: true,
                validator: (value) => value == null ? 'Choose a range' : null,
                onChanged: (value) => changes.add('range:$value'),
                onSaved: saved.add,
                onReset: () => resets.add('range'),
              ),
            ],
          ),
        ),
        use24HourFormat: true,
      ),
    );

    final canonicalRange = DateTimeRange(
      start: DateTime(2027, 1, 12),
      end: DateTime(2027, 1, 14),
    );
    expect(date.currentState!.value, DateTime(2027, 1, 11));
    expect(range.currentState!.value, canonicalRange);
    expect(find.text('17:05'), findsOneWidget);
    expect(form.currentState!.validate(), isTrue);
    form.currentState!.save();
    expect(
      saved,
      unorderedEquals([DateTime(2027, 1, 11), seedTime, canonicalRange]),
    );
    await tester.pumpAndSettle();

    for (final key in [date, time, range]) {
      await tester.tap(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(YumeiroButton),
        ),
      );
      await tester.pumpAndSettle();
      expect(key.currentState!.value, isNull);
    }
    expect(changes, ['date:null', 'time:null', 'range:null']);
    expect(find.byType(DatePickerDialog), findsNothing);
    expect(find.byType(TimePickerDialog), findsNothing);
    expect(find.byType(DateRangePickerDialog), findsNothing);

    expect(form.currentState!.validate(), isFalse);
    await tester.pumpAndSettle();
    expect(find.text('Choose a date'), findsOneWidget);
    expect(find.text('Choose a time'), findsOneWidget);
    expect(find.text('Choose a range'), findsOneWidget);

    form.currentState!.reset();
    await tester.pumpAndSettle();
    expect(date.currentState!.value, DateTime(2027, 1, 11));
    expect(time.currentState!.value, seedTime);
    expect(range.currentState!.value, canonicalRange);
    expect(changes, hasLength(3));
    expect(resets, unorderedEquals(['date', 'time', 'range']));
    expect(find.text('Choose a date'), findsNothing);
    expect(find.text('Choose a time'), findsNothing);
    expect(find.text('Choose a range'), findsNothing);
  });

  testWidgets('adaptive calendar applies bounds, cancel and confirm', (
    tester,
  ) async {
    final changes = <DateTime?>[];
    final key = GlobalKey<FormFieldState<DateTime>>();
    await tester.pumpWidget(
      _page(
        YumeiroDatePicker.form(
          key: key,
          placeholder: 'Pick date',
          firstDate: DateTime(2027, 1, 10, 20),
          lastDate: DateTime(2027, 1, 20, 2),
          currentDate: DateTime(2027, 1, 14),
          selectableDayPredicate: (value) => value.day.isEven,
          onChanged: changes.add,
        ),
      ),
    );

    await _open(tester, 'Pick date');
    expect(find.byType(DatePickerDialog), findsNothing);
    await tester.tap(_day(2027, 1, 9));
    await tester.tap(_day(2027, 1, 15));
    expect(_confirmedDateButton(tester).onPressed, isNull);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(key.currentState!.value, isNull);
    expect(changes, isEmpty);

    await _open(tester, 'Pick date');
    await tester.tap(_day(2027, 1, 16));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(key.currentState!.value, DateTime(2027, 1, 16));
    expect(changes, [DateTime(2027, 1, 16)]);
  });

  testWidgets('date range arrows mirror once in RTL', (tester) async {
    await tester.pumpWidget(
      _page(
        Directionality(
          textDirection: TextDirection.rtl,
          child: YumeiroDateRangePicker(
            firstDate: DateTime(2027, 1),
            lastDate: DateTime(2027, 8),
            currentDate: DateTime(2027, 3),
            value: null,
            onChanged: (_) {},
            placeholder: 'Pick range',
          ),
        ),
      ),
    );
    await _open(tester, 'Pick range');

    Finder monthArrow(String direction) => find.descendant(
      of: find.byKey(ValueKey('yumeiro-calendar-$direction-month')),
      matching: find.byType(Icon),
    );
    final previous = monthArrow('previous');
    final next = monthArrow('next');
    expect(
      tester.getCenter(previous).dx,
      greaterThan(tester.getCenter(next).dx),
    );
    for (final (arrow, icon) in [
      (previous, Icons.chevron_left),
      (next, Icons.chevron_right),
      (find.byIcon(Icons.arrow_forward), Icons.arrow_forward),
    ]) {
      expect(tester.widget<Icon>(arrow).icon, icon);
      final transform = tester.widget<Transform>(
        find.descendant(of: arrow, matching: find.byType(Transform)),
      );
      expect(transform.transform.entry(0, 0), -1);
    }
  });

  for (final (preset, pixel) in [
    (YumeiroThemePresets.classicDark, false),
    (YumeiroThemePresets.pixelDark, true),
  ]) {
    testWidgets('${preset.id} centers a themed background on today', (
      tester,
    ) async {
      await tester.pumpWidget(
        _page(
          YumeiroDatePicker(
            firstDate: DateTime(2027, 1),
            lastDate: DateTime(2027, 1, 31),
            currentDate: DateTime(2027, 1, 14),
            value: null,
            onChanged: (_) {},
            placeholder: 'Pick date',
          ),
          preset: preset,
        ),
      );
      await _open(tester, 'Pick date');
      final day = _day(2027, 1, 14);
      final marker = find.byKey(
        const ValueKey('yumeiro-calendar-today-marker'),
      );
      expect(find.descendant(of: day, matching: marker), findsOneWidget);
      final size = tester.getSize(marker);
      expect(size.width, size.height);
      expect(size.width, greaterThan(tester.getSize(find.text('14')).width));
      expect(size.height, lessThan(tester.getSize(day).height));
      expect(
        (tester.getCenter(marker) - tester.getCenter(day)).distance,
        closeTo(0, .01),
      );

      ShapeDecoration decoration() =>
          tester.widget<DecoratedBox>(marker).decoration as ShapeDecoration;
      final shape = decoration().shape;
      if (pixel) {
        expect(shape, isA<YumeiroPixelBorder>());
      } else {
        expect(
          (shape as RoundedRectangleBorder).borderRadius
              .resolve(TextDirection.ltr)
              .topLeft
              .x,
          greaterThanOrEqualTo(size.width / 2),
        );
      }
      final unselectedColor = decoration().color;
      await tester.tap(day);
      await tester.pumpAndSettle();
      expect(decoration().color, isNot(unselectedColor));
      expect(
        (tester.getCenter(marker) - tester.getCenter(day)).distance,
        closeTo(0, .01),
      );
    });
  }

  for (final modality in YumeiroModality.values) {
    testWidgets('a ${modality.name} date picker remains controlled', (
      tester,
    ) async {
      tester.view.physicalSize = modality == YumeiroModality.touch
          ? const Size(390, 844)
          : const Size(760, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final value = ValueNotifier<DateTime?>(null);
      addTearDown(value.dispose);
      final changes = <DateTime?>[];
      await tester.pumpWidget(
        _page(
          ValueListenableBuilder(
            valueListenable: value,
            builder: (_, current, _) => YumeiroDatePicker(
              firstDate: DateTime(2027, 1, 10),
              lastDate: DateTime(2027, 1, 20),
              currentDate: DateTime(2027, 1, 14),
              value: current,
              onChanged: changes.add,
              placeholder: 'Pick date',
              clearable: true,
            ),
          ),
          modality: modality,
        ),
      );

      await _open(tester, 'Pick date');
      final calendar = _day(2027, 1, 14);
      expect(calendar, findsOneWidget);
      expect(find.byType(DatePickerDialog), findsNothing);
      expect(
        find.byType(YumeiroBottomSheet),
        modality == YumeiroModality.touch ? findsOneWidget : findsNothing,
      );
      await tester.tap(_day(2027, 1, 16));
      await tester.pump();
      await tester.tap(find.text('OK').hitTestable());
      await tester.pumpAndSettle();
      expect(changes, [DateTime(2027, 1, 16)]);
      expect(find.text('Pick date'), findsOneWidget);

      await _open(tester, 'Pick date');
      value.value = DateTime.utc(2027, 1, 18, 22);
      await tester.pump();
      Navigator.of(tester.element(calendar)).pop(DateTime(2027, 1, 17));
      await tester.pumpAndSettle();
      expect(changes, [DateTime(2027, 1, 16)]);

      final picker = find.byType(YumeiroDatePicker);
      expect(
        tester.widget<YumeiroDatePicker>(picker).value,
        DateTime(2027, 1, 18),
      );
      await tester.tap(find.byType(YumeiroButton));
      await tester.pumpAndSettle();
      expect(changes, [DateTime(2027, 1, 16), null]);
      expect(
        tester.widget<YumeiroDatePicker>(picker).value,
        DateTime(2027, 1, 18),
      );
    });
  }

  testWidgets('adaptive calendar validates its typed date before confirming', (
    tester,
  ) async {
    final changes = <DateTime?>[];
    await tester.pumpWidget(
      _page(
        YumeiroDatePicker(
          firstDate: DateTime(2027, 1, 10),
          lastDate: DateTime(2027, 1, 20),
          currentDate: DateTime(2027, 1, 14),
          value: null,
          onChanged: changes.add,
          placeholder: 'Pick date',
        ),
      ),
    );
    await _open(tester, 'Pick date');
    final messages = MaterialLocalizations.of(
      tester.element(_day(2027, 1, 14)),
    );
    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is YumeiroButton &&
            widget.tooltip == messages.inputDateModeButtonLabel,
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('yumeiro-calendar-input-start')),
      findsOneWidget,
    );

    await tester.enterText(find.byType(EditableText), 'invalid');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text(messages.invalidDateFormatLabel), findsOneWidget);
    expect(changes, isEmpty);

    final selected = DateTime(2027, 1, 14);
    await tester.enterText(
      find.byType(EditableText),
      messages.formatCompactDate(selected),
    );
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(changes, [selected]);
  });

  testWidgets('input mode and small or large-text layouts stay themed', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final (mode, viewport, textScaler) in [
      (
        DatePickerEntryMode.inputOnly,
        const Size(760, 900),
        TextScaler.noScaling,
      ),
      (
        DatePickerEntryMode.calendar,
        const Size(700, 390),
        TextScaler.noScaling,
      ),
      (
        DatePickerEntryMode.calendar,
        const Size(760, 900),
        const TextScaler.linear(2),
      ),
    ]) {
      tester.view.physicalSize = viewport;
      await tester.pumpWidget(
        _page(
          YumeiroDatePicker(
            firstDate: DateTime(2027, 1, 10),
            lastDate: DateTime(2027, 1, 20),
            currentDate: DateTime(2027, 1, 14),
            initialEntryMode: mode,
            value: null,
            onChanged: (_) {},
            placeholder: 'Pick date',
          ),
          textScaler: textScaler,
        ),
      );
      await _open(tester, 'Pick date');
      final panelContent = mode == DatePickerEntryMode.inputOnly
          ? find.byKey(const ValueKey('yumeiro-calendar-input-start'))
          : _day(2027, 1, 14);
      expect(panelContent, findsOneWidget);
      expect(find.byType(DatePickerDialog), findsNothing);
      Navigator.of(tester.element(panelContent)).pop();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('forced errors take precedence over automatic validation', (
    tester,
  ) async {
    final key = GlobalKey<FormFieldState<TimeOfDay>>();
    final forced = ValueNotifier<String?>('Time slot is unavailable');
    addTearDown(forced.dispose);
    var validationCalls = 0;
    await tester.pumpWidget(
      _page(
        ValueListenableBuilder(
          valueListenable: forced,
          builder: (_, error, _) => YumeiroTimePicker.form(
            key: key,
            initialValue: const TimeOfDay(hour: 17, minute: 5),
            clearable: true,
            forceErrorText: error,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (value) {
              validationCalls++;
              return value == null ? 'Choose a time' : null;
            },
          ),
        ),
      ),
    );
    await tester.tap(find.byType(YumeiroButton));
    await tester.pumpAndSettle();
    expect(key.currentState!.value, isNull);
    expect(find.text('Time slot is unavailable'), findsOneWidget);
    expect(validationCalls, 0);

    forced.value = null;
    await tester.pumpAndSettle();
    expect(find.text('Time slot is unavailable'), findsNothing);
    expect(find.text('Choose a time'), findsOneWidget);
    expect(validationCalls, greaterThan(0));
  });

  testWidgets('range checks both endpoints and can use a nested navigator', (
    tester,
  ) async {
    final outer = GlobalKey<NavigatorState>();
    final inner = GlobalKey<NavigatorState>();
    final key = GlobalKey<FormFieldState<DateTimeRange<DateTime>>>();
    final changes = <DateTimeRange<DateTime>?>[];
    final historic = DateTimeRange(
      start: DateTime(2026, 12, 30),
      end: DateTime(2027, 1, 11),
    );
    final accepted = DateTimeRange(
      start: DateTime(2027, 1, 12),
      end: DateTime(2027, 1, 14),
    );
    var allowEnd = true;

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: outer,
        home: YumeiroScope(
          child: Navigator(
            key: inner,
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (context) => Scaffold(
                body: YumeiroDateRangePicker.form(
                  key: key,
                  firstDate: DateTime(2027, 1, 10),
                  lastDate: DateTime(2027, 1, 20),
                  initialValue: historic,
                  currentDate: DateTime(2027, 1, 14),
                  selectableDayPredicate: (day, start, end) =>
                      allowEnd || day != end,
                  useRootNavigator: false,
                  onChanged: changes.add,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Finder fieldText() => find.descendant(
      of: find.byKey(key),
      matching: find.textContaining(' – '),
    );
    await tester.tap(fieldText());
    await tester.pumpAndSettle();
    expect(find.byType(DateRangePickerDialog), findsNothing);
    expect(_day(2027, 1, 12), findsOneWidget);
    expect(_confirmedDateButton(tester).onPressed, isNull);
    expect(outer.currentState!.canPop(), isFalse);
    expect(inner.currentState!.canPop(), isTrue);

    allowEnd = false;
    inner.currentState!.pop(accepted);
    await tester.pumpAndSettle();
    expect(key.currentState!.value, historic);
    expect(changes, isEmpty);

    allowEnd = true;
    await tester.tap(fieldText());
    await tester.pumpAndSettle();
    await tester.tap(_day(2027, 1, 12));
    await tester.pump();
    await tester.tap(_day(2027, 1, 14));
    await tester.pump();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(key.currentState!.value, accepted);
    expect(changes, [accepted]);
  });

  testWidgets('time uses picker seed without changing the empty field', (
    tester,
  ) async {
    final key = GlobalKey<FormFieldState<TimeOfDay>>();
    final changes = <TimeOfDay?>[];
    const seed = TimeOfDay(hour: 18, minute: 20);
    await tester.pumpWidget(
      _page(
        YumeiroTimePicker.form(
          key: key,
          placeholder: 'Pick time',
          initialPickerTime: seed,
          onChanged: changes.add,
        ),
        use24HourFormat: true,
      ),
    );
    await _open(tester, 'Pick time');
    final hour = find.byKey(const ValueKey('yumeiro-time-hour'));
    final minute = find.byKey(const ValueKey('yumeiro-time-minute'));
    expect(find.byType(TimePickerDialog), findsNothing);
    expect(tester.widget<YumeiroTextField>(hour).controller!.text, '18');
    expect(tester.widget<YumeiroTextField>(minute).controller!.text, '20');
    expect(MediaQuery.alwaysUse24HourFormatOf(tester.element(hour)), isTrue);
    expect(key.currentState!.value, isNull);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(changes, [seed]);
    expect(key.currentState!.value, seed);
    expect(find.text('18:20'), findsOneWidget);
  });

  testWidgets('a wide date range selects across adjacent months', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final changes = <DateTimeRange<DateTime>?>[];
    await tester.pumpWidget(
      _page(
        YumeiroDateRangePicker(
          firstDate: DateTime(2027, 1),
          lastDate: DateTime(2027, 3, 31),
          currentDate: DateTime(2027, 1, 30),
          value: null,
          onChanged: changes.add,
          placeholder: 'Pick range',
        ),
      ),
    );
    await _open(tester, 'Pick range');
    await tester.tap(_day(2027, 1, 30));
    await tester.pumpAndSettle();
    expect(_confirmedDateButton(tester).onPressed, isNull);
    await tester.tap(_day(2027, 2, 3));
    await tester.pumpAndSettle();
    expect(changes, isEmpty);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(changes, [
      DateTimeRange(start: DateTime(2027, 1, 30), end: DateTime(2027, 2, 3)),
    ]);
  });

  testWidgets('range summary text follows the active endpoint surface', (
    tester,
  ) async {
    final range = DateTimeRange(
      start: DateTime(2027, 1, 30),
      end: DateTime(2027, 2, 3),
    );
    await tester.pumpWidget(
      _page(
        YumeiroDateRangePicker(
          firstDate: DateTime(2027, 1),
          lastDate: DateTime(2027, 3, 31),
          value: range,
          onChanged: (_) {},
        ),
        preset: YumeiroThemePresets.pixelDark,
      ),
    );
    final context = tester.element(find.byType(YumeiroDateRangePicker));
    final messages = MaterialLocalizations.of(context);
    final start = messages.formatCompactDate(range.start);
    final end = messages.formatCompactDate(range.end);
    await _open(tester, '$start – $end');

    final visuals = YumeiroTheme.of(context).visuals;
    final idle = visuals
        .control(YumeiroControlRole.neutral, const {})
        .foreground;
    final active = visuals.control(YumeiroControlRole.neutral, const {
      WidgetState.selected,
    }).foreground;
    expect(active, isNot(idle));

    void expectEndpointColors({required bool startActive}) {
      final startColor = startActive ? active : idle;
      final endColor = startActive ? idle : active;
      expect(
        _renderedTextColor(tester, messages.dateRangeStartLabel),
        startColor,
      );
      expect(_renderedTextColor(tester, start), startColor);
      expect(_renderedTextColor(tester, messages.dateRangeEndLabel), endColor);
      expect(_renderedTextColor(tester, end), endColor);
    }

    expectEndpointColors(startActive: true);
    await tester.tap(find.text(messages.dateRangeEndLabel));
    await tester.pumpAndSettle();
    expectEndpointColors(startActive: false);
  });

  testWidgets('time choice numbers follow the selected and idle surfaces', (
    tester,
  ) async {
    await tester.pumpWidget(
      _page(
        YumeiroTimePicker(
          value: const TimeOfDay(hour: 14, minute: 30),
          initialEntryMode: YumeiroTimePickerEntryMode.listOnly,
          onChanged: (_) {},
        ),
        preset: YumeiroThemePresets.pixelDark,
        use24HourFormat: true,
      ),
    );
    await _open(tester, '14:30');
    final pickerTexts = find.byType(YumeiroTextField);
    expect(pickerTexts, findsNothing);
    final context = tester.element(find.byType(YumeiroTimePicker));
    expect(
      find.byTooltip(
        MaterialLocalizations.of(context).inputTimeModeButtonLabel,
      ),
      findsNothing,
    );
    final visuals = YumeiroTheme.of(context).visuals;
    final active = visuals.item(YumeiroItemRole.selection, const {
      WidgetState.selected,
    }).foreground;
    final idle = visuals.item(YumeiroItemRole.selection, const {}).foreground;
    expect(active, isNot(idle));
    expect(_renderedTextColor(tester, '14'), active);
    expect(_renderedTextColor(tester, '30'), active);
    expect(_renderedTextColor(tester, '15'), idle);
    expect(_renderedTextColor(tester, '31'), idle);

    await tester.tap(find.text('15'));
    await tester.pumpAndSettle();
    expect(_renderedTextColor(tester, '14'), idle);
    expect(_renderedTextColor(tester, '15'), active);
  });

  testWidgets('typed 12-hour time validates both fields', (tester) async {
    final changes = <TimeOfDay?>[];
    await tester.pumpWidget(
      _page(
        YumeiroTimePicker.form(
          initialValue: const TimeOfDay(hour: 19, minute: 20),
          initialEntryMode: YumeiroTimePickerEntryMode.inputOnly,
          onChanged: changes.add,
        ),
      ),
    );
    await _open(tester, '7:20 PM');
    final hour = find.byKey(const ValueKey('yumeiro-time-hour'));
    final minute = find.byKey(const ValueKey('yumeiro-time-minute'));
    await tester.enterText(hour, '13');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    final messages = MaterialLocalizations.of(tester.element(hour));
    expect(find.text(messages.invalidTimeLabel), findsOneWidget);
    expect(changes, isEmpty);

    await tester.enterText(hour, '12');
    await tester.enterText(minute, '05');
    await tester.tap(find.text(messages.anteMeridiemAbbreviation));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(changes, [const TimeOfDay(hour: 0, minute: 5)]);
  });

  testWidgets('touch time choices are drafts until confirmed', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final changes = <TimeOfDay?>[];
    await tester.pumpWidget(
      _page(
        YumeiroTimePicker(
          value: null,
          initialPickerTime: const TimeOfDay(hour: 10, minute: 20),
          onChanged: changes.add,
          placeholder: 'Pick time',
        ),
        modality: YumeiroModality.touch,
        use24HourFormat: true,
      ),
    );
    await _open(tester, 'Pick time');
    expect(find.byType(YumeiroBottomSheet), findsOneWidget);
    final wheels = find.byType(ListWheelScrollView);
    expect(wheels, findsNWidgets(2));
    await tester.tap(
      find.descendant(of: wheels.first, matching: find.text('11')),
    );
    await tester.pumpAndSettle();
    expect(find.text('11:20'), findsOneWidget);
    expect(changes, isEmpty);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(changes, [const TimeOfDay(hour: 11, minute: 20)]);
  });

  testWidgets('late picks cannot overwrite resets, edits or new restrictions', (
    tester,
  ) async {
    final key = GlobalKey<FormFieldState<DateTime>>();
    final changes = <DateTime?>[];
    final state = ValueNotifier((enabled: true, readOnly: false, lastDay: 20));
    addTearDown(state.dispose);

    await tester.pumpWidget(
      _page(
        ValueListenableBuilder(
          valueListenable: state,
          builder: (_, configuration, _) => YumeiroDatePicker.form(
            key: key,
            label: 'Date',
            placeholder: 'Pick date',
            firstDate: DateTime(2027, 1, 10),
            lastDate: DateTime(2027, 1, configuration.lastDay),
            currentDate: DateTime(2027, 1, 10),
            enabled: configuration.enabled,
            readOnly: configuration.readOnly,
            onChanged: changes.add,
          ),
        ),
      ),
    );

    Future<void> finish(int day) async {
      Navigator.of(tester.element(_day(2027, 1, 10)))
          .pop(DateTime(2027, 1, day));
      await tester.pumpAndSettle();
    }

    await _open(tester, 'Pick date');
    key.currentState!.reset();
    await finish(17);
    expect(key.currentState!.value, isNull);

    await _open(tester, 'Pick date');
    key.currentState!.didChange(DateTime.utc(2027, 1, 16, 23));
    await finish(17);
    expect(key.currentState!.value, DateTime(2027, 1, 16));
    key.currentState!.reset();
    await tester.pumpAndSettle();

    await _open(tester, 'Pick date');
    state.value = (enabled: false, readOnly: false, lastDay: 20);
    await tester.pump();
    state.value = (enabled: true, readOnly: true, lastDay: 20);
    await tester.pump();
    state.value = (enabled: true, readOnly: false, lastDay: 20);
    await tester.pump();
    await finish(17);
    expect(key.currentState!.value, isNull);

    await _open(tester, 'Pick date');
    state.value = (enabled: true, readOnly: false, lastDay: 15);
    await tester.pump();
    await finish(17);
    expect(key.currentState!.value, isNull);
    expect(changes, isEmpty);

    await _open(tester, 'Pick date');
    await finish(15);
    expect(key.currentState!.value, DateTime(2027, 1, 15));
    expect(changes, [DateTime(2027, 1, 15)]);
  });

  testWidgets('read-only fields can focus without opening or clearing', (
    tester,
  ) async {
    final node = FocusNode();
    addTearDown(node.dispose);
    await tester.pumpWidget(
      _page(
        YumeiroTimePicker.form(
          initialValue: const TimeOfDay(hour: 17, minute: 5),
          clearable: true,
          focusNode: node,
          autofocus: true,
          readOnly: true,
        ),
        use24HourFormat: true,
      ),
    );
    await tester.pumpAndSettle();
    expect(node.hasFocus, isTrue);
    expect(find.byType(YumeiroButton), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsNothing);
    expect(find.text('17:05'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

Finder _day(int year, int month, int day) =>
    find.byKey(ValueKey('yumeiro-calendar-day-$year-$month-$day'));

YumeiroButton _confirmedDateButton(WidgetTester tester) =>
    tester.widget(find.byKey(const ValueKey('yumeiro-calendar-confirm')));

Color? _renderedTextColor(WidgetTester tester, String text) => tester
    .widget<RichText>(
      find.descendant(of: find.text(text), matching: find.byType(RichText)),
    )
    .text
    .style
    ?.color;

Widget _page(
  Widget child, {
  bool use24HourFormat = false,
  YumeiroModality modality = YumeiroModality.pointer,
  TextScaler? textScaler,
  YumeiroThemePreset? preset,
}) => YumeiroApp(
  modality: modality,
  preset: preset,
  home: Scaffold(
    body: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          alwaysUse24HourFormat: use24HourFormat,
          textScaler: textScaler,
        ),
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  ),
);

Future<void> _open(WidgetTester tester, String text) async {
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}
