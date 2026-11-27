import 'dart:ui' show Tristate;

import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/src/components/controls/select_trigger.dart';
import 'package:yumeiro/src/components/controls/selection_control.dart';
import 'package:yumeiro/src/components/controls/selection_menu_row.dart';
import 'package:yumeiro/src/components/overlays/picker_overlay.dart';
import 'package:yumeiro/yumeiro.dart';

Widget _host(YumeiroModality modality, Widget child) => YumeiroApp(
  modality: modality,
  home: Scaffold(body: Center(child: child)),
);

Future<void> _submitQuery(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(TextField), query);
  await tester.pumpAndSettle();
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
}

void main() {
  test('selection option equality includes its trailing icon', () {
    const withIcon = YumeiroSelectionOption(
      value: 1,
      label: 'One',
      trailingIcon: Icons.star,
    );
    final equivalent = YumeiroSelectionOption(
      value: withIcon.value,
      label: withIcon.label,
      trailingIcon: withIcon.trailingIcon,
    );
    expect(equivalent, withIcon);
    expect(equivalent.hashCode, withIcon.hashCode);
    expect(
      const YumeiroSelectionOption(value: 1, label: 'One'),
      isNot(withIcon),
    );
  });

  for (final (modality, menu) in [
    for (final modality in YumeiroModality.values)
      for (final menu in [false, true]) (modality, menu),
  ]) {
    testWidgets(
      'fixed select ($menu menu) keeps its ${modality.name} picker current',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final changes = <int?>[];
        var options = const [
          YumeiroSelectionOption(value: 1, label: 'Original'),
        ];
        var value = 1;
        var enabled = true;
        late StateSetter updateSelect;

        await tester.pumpWidget(
          _host(
            modality,
            StatefulBuilder(
              builder: (context, setState) {
                updateSelect = setState;
                return menu
                    ? YumeiroSelect<int>.menu(
                        options: options,
                        value: value,
                        enabled: enabled,
                        placeholder: 'Choose option',
                        onChanged: changes.add,
                      )
                    : YumeiroSelect<int>(
                        options: options,
                        value: value,
                        enabled: enabled,
                        placeholder: 'Choose option',
                        onChanged: changes.add,
                      );
              },
            ),
          ),
        );

        final picker = find.byType(YumeiroSelectionList<int>);
        Finder sheetOption(String label) =>
            find.descendant(of: picker, matching: find.text(label));
        Future<void> tap(Finder finder) async {
          await tester.tap(finder);
          await tester.pumpAndSettle();
        }

        await tap(find.text('Original'));
        expect(sheetOption('Original'), findsOneWidget);
        updateSelect(() {
          value = 2;
          options = const [
            YumeiroSelectionOption(value: 2, label: 'Current'),
            YumeiroSelectionOption(value: 3, label: 'New'),
          ];
        });
        await tester.pumpAndSettle();
        expect(sheetOption('Original'), findsNothing);
        final list = tester.widget<YumeiroSelectionList<int>>(picker);
        expect(list.values, {2});
        await tap(sheetOption('New'));
        expect(changes, [3]);

        await tap(find.text('Current'));
        expect(picker, findsOneWidget);
        updateSelect(() => enabled = false);
        await tester.pumpAndSettle();
        expect(picker, findsNothing);
        await tap(find.text('Current'));
        expect(picker, findsNothing);

        updateSelect(() => enabled = true);
        await tester.pumpAndSettle();
        await tap(find.text('Current'));
        expect(picker, findsOneWidget);
        updateSelect(() => options = const []);
        await tester.pumpAndSettle();
        expect(picker, findsNothing);
        await tap(find.text('Choose option'));
        expect(picker, findsNothing);
        expect(changes, [3]);
      },
    );
  }

  testWidgets('dropdown resolves and explicitly hides its trigger icon', (
    tester,
  ) async {
    Future<void> mount({
      IconData? icon,
      bool visible = true,
      bool itemIcon = false,
      double maxWidth = 320,
    }) => tester.pumpWidget(
      _host(
        YumeiroModality.pointer,
        YumeiroSelect<int>.menu(
          value: 1,
          trailingIcon: icon,
          showTrailingIcon: visible,
          maxWidth: maxWidth,
          options: [
            YumeiroSelectionOption(
              value: 1,
              label: 'Choice',
              trailingIcon: itemIcon ? Icons.star : null,
            ),
          ],
          onChanged: (_) {},
        ),
      ),
    );

    await mount();
    final trigger = find.byType(YumeiroSelectTriggerVisual);
    final theme = YumeiroTheme.of(tester.element(trigger));
    expect(find.byIcon(theme.icons.chevronDown), findsOneWidget);
    await mount(itemIcon: true);
    expect(find.byIcon(Icons.star), findsOneWidget);
    await mount(itemIcon: true, icon: Icons.expand_more);
    expect(find.byIcon(Icons.expand_more), findsOneWidget);
    expect(find.byIcon(Icons.star), findsNothing);
    await mount(itemIcon: true, icon: Icons.expand_more, visible: false);
    expect(
      find.descendant(of: trigger, matching: find.byType(Icon)),
      findsNothing,
    );
    await mount(maxWidth: 70);
    expect(tester.getSize(trigger).width, 70);
  });

  for (final direction in TextDirection.values) {
    testWidgets('menu labels remain centered with icons in ${direction.name}', (
      tester,
    ) async {
      const longest = 'Highest quality release';
      const options = [
        YumeiroSelectionOption(value: 1, label: 'Normal'),
        YumeiroSelectionOption(
          value: 2,
          label: longest,
          subtitle: 'High resolution source',
          icon: Icons.movie,
          trailingIcon: Icons.star,
        ),
      ];
      int? selected = 1;
      double? menuWidth;
      await tester.pumpWidget(
        _host(
          YumeiroModality.pointer,
          StatefulBuilder(
            builder: (context, setState) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.4)),
              child: Directionality(
                textDirection: direction,
                child: YumeiroSelect<int>.menu(
                  value: selected,
                  options: options,
                  width: 110,
                  maxWidth: 680,
                  menuAutoWidth: true,
                  menuWidth: menuWidth,
                  onChanged: (value) => setState(() {
                    selected = value;
                    menuWidth = 105;
                  }),
                  child: const Text('Mode'),
                ),
              ),
            ),
          ),
        ),
      );
      final row = find.widgetWithText(SelectionMenuRow<int>, longest);
      final label = find.descendant(of: row, matching: find.text(longest));
      final subtitle = find.descendant(
        of: row,
        matching: find.text('High resolution source'),
      );
      final surface = find.byType(PickerFloatingSurface);

      await tester.tap(find.text('Mode'));
      await tester.pumpAndSettle();
      final firstCenter = tester.getCenter(surface).dx;
      expect(tester.getCenter(label).dx, closeTo(firstCenter, .1));
      expect(tester.getCenter(subtitle).dx, closeTo(firstCenter, .1));
      expect(
        tester.renderObject<RenderParagraph>(label).didExceedMaxLines,
        isFalse,
      );
      expect(
        tester.renderObject<RenderParagraph>(subtitle).didExceedMaxLines,
        isFalse,
      );

      await tester.tap(label);
      await tester.pumpAndSettle();
      expect(selected, 2);
      await tester.tap(find.text('Mode'));
      await tester.pumpAndSettle();
      expect(tester.getSize(surface).width, 105);
      expect(
        tester.getCenter(label).dx,
        closeTo(tester.getCenter(surface).dx, .1),
      );
      expect(
        tester.getCenter(subtitle).dx,
        closeTo(tester.getCenter(surface).dx, .1),
      );
      expect(
        tester.renderObject<RenderParagraph>(label).didExceedMaxLines,
        isTrue,
      );
      final star = find.descendant(of: row, matching: find.byIcon(Icons.star));
      final check = find.descendant(
        of: row,
        matching: find.byIcon(YumeiroTheme.of(tester.element(row)).icons.check),
      );
      final starX = tester.getCenter(star).dx;
      final checkX = tester.getCenter(check).dx;
      expect(
        checkX,
        direction == TextDirection.ltr ? greaterThan(starX) : lessThan(starX),
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final dense in [false, true]) {
    testWidgets(
      'pointer single choice menus share row geometry, dense: $dense',
      (tester) async {
        const options = [
          YumeiroSelectionOption(value: 1, label: 'Normal'),
          YumeiroSelectionOption(value: 2, label: 'Fast'),
        ];
        final controls = [
          YumeiroSelect<int>(
            value: 1,
            options: options,
            width: 180,
            dense: dense,
            onChanged: (_) {},
          ),
          YumeiroSelect<int>.menu(
            value: 1,
            options: options,
            width: 180,
            dense: dense,
            onChanged: (_) {},
          ),
          YumeiroSelect<int>.searchable(
            value: 1,
            options: options,
            width: 180,
            dense: dense,
            onChanged: (_) {},
          ),
        ];

        for (final control in controls) {
          await tester.pumpWidget(_host(YumeiroModality.pointer, control));
          await tester.tap(find.text('Normal'));
          await tester.pumpAndSettle();
          final row = find.widgetWithText(SelectionMenuRow<int>, 'Fast');
          final surface = find.byType(PickerFloatingSurface);
          expect(tester.getSize(row).height, dense ? 27 : 31);
          expect(tester.getRect(row).left - tester.getRect(surface).left, 4);
          await tester.tapAt(Offset.zero);
          await tester.pumpAndSettle();
        }
      },
    );
  }

  testWidgets('a searchable setting submits only enabled option values', (
    tester,
  ) async {
    const modality = YumeiroModality.pointer;
    final reports = <String?>[];
    final options = [
      const YumeiroSelectionOption(value: 'alpha-id', label: 'Alpha'),
      const YumeiroSelectionOption(value: 'beta-id', label: 'Beta'),
      const YumeiroSelectionOption(
        value: 'locked-id',
        label: 'Locked',
        enabled: false,
      ),
      for (var i = 0; i < 8; i++)
        YumeiroSelectionOption(value: 'extra-$i', label: 'Extra $i'),
    ];
    var selected = 'alpha-id';
    await tester.pumpWidget(
      _host(
        modality,
        StatefulBuilder(
          builder: (context, setState) => YumeiroSettingRow.select<String>(
            title: 'Mode',
            value: selected,
            options: options,
            onChanged: (value) {
              reports.add(value);
              setState(() => selected = value!);
            },
          ),
        ),
      ),
    );

    final field = find.byType(TextField);
    await _submitQuery(tester, 'not-in-list');
    expect(reports, isEmpty);
    expect(tester.widget<TextField>(field).controller!.text, 'Alpha');
    await _submitQuery(tester, 'locked-id');
    expect(reports, isEmpty);
    expect(tester.widget<TextField>(field).controller!.text, 'Alpha');
    expect(
      find.byWidgetPredicate(
        (widget) => widget is YumeiroButton && widget.tooltip == 'Clear',
      ),
      findsNothing,
    );

    await _submitQuery(tester, 'Beta');
    expect(reports, ['beta-id']);
    expect(tester.widget<TextField>(field).controller!.text, 'Beta');
  });

  testWidgets('an empty touch setting closes and cannot reopen its picker', (
    tester,
  ) async {
    const initial = [YumeiroSelectionOption(value: 1, label: 'One')];
    var options = initial;
    late StateSetter update;
    final reports = <int?>[];
    await tester.pumpWidget(
      _host(
        YumeiroModality.touch,
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return YumeiroSettingRow.select<int>(
              title: 'Mode',
              value: 1,
              options: options,
              onChanged: reports.add,
            );
          },
        ),
      ),
    );

    final picker = find.byType(YumeiroBottomSheet);
    await tester.tap(find.text('Mode'));
    await tester.pumpAndSettle();
    expect(picker, findsOneWidget);

    update(() => options = const []);
    await tester.pumpAndSettle();
    expect(picker, findsNothing);
    await tester.tap(find.text('Mode'));
    await tester.pumpAndSettle();
    expect(picker, findsNothing);
    expect(reports, isEmpty);

    update(() => options = initial);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mode'));
    await tester.pumpAndSettle();
    expect(picker, findsOneWidget);
  });

  testWidgets('a setting uses displayLabel across its picker presentations', (
    tester,
  ) async {
    for (final (modality, optionCount) in [
      (YumeiroModality.pointer, 10),
      (YumeiroModality.pointer, 11),
      (YumeiroModality.touch, 11),
    ]) {
      await tester.pumpWidget(
        _host(
          modality,
          YumeiroSettingRow.select<int>(
            title: 'Mode',
            displayLabel: 'Current presentation',
            value: 1,
            options: [
              for (var index = 0; index < optionCount; index++)
                YumeiroSelectionOption(value: index, label: 'Mode $index'),
            ],
            onChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Current presentation'), findsOneWidget);
      expect(find.text('Mode 1'), findsNothing);
    }
  });

  testWidgets('pointer setting selects share the editor slot at both widths', (
    tester,
  ) async {
    Widget setting(String title, int optionCount) =>
        YumeiroSettingRow.select<int>(
          title: title,
          value: 0,
          options: List.generate(
            optionCount,
            (index) =>
                YumeiroSelectionOption(value: index, label: 'Mode $index'),
          ),
          onChanged: (_) {},
        );

    for (final width in [360.0, 720.0]) {
      await tester.pumpWidget(
        _host(
          YumeiroModality.pointer,
          SizedBox(
            width: width,
            child: Column(
              children: [setting('Short list', 10), setting('Long list', 11)],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final editors = find.byWidgetPredicate(
        (widget) => widget is YumeiroSelect<int>,
      );
      expect(editors, findsNWidgets(2));
      final shortEditor = tester.getRect(editors.first);
      final longEditor = tester.getRect(editors.last);
      expect(shortEditor.left, closeTo(longEditor.left, .01));
      expect(shortEditor.width, closeTo(longEditor.width, .01));
      if (width == 360) {
        expect(
          shortEditor.top,
          greaterThan(tester.getBottomLeft(find.text('Short list')).dy),
        );
      } else {
        expect(
          shortEditor.center.dy,
          closeTo(tester.getCenter(find.text('Short list')).dy, .01),
        );
      }
    }
  });

  testWidgets('a resting label does not replace the search or option labels', (
    tester,
  ) async {
    final reports = <int?>[];
    var display = 'Current presentation';
    var selected = 1;
    late StateSetter update;
    await tester.pumpWidget(
      _host(
        YumeiroModality.pointer,
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return YumeiroSelect<int>.searchable(
              options: const [
                YumeiroSelectionOption(value: 1, label: 'Alpha'),
                YumeiroSelectionOption(value: 2, label: 'Beta'),
              ],
              value: selected,
              displayText: display,
              onChanged: (value) {
                reports.add(value);
                setState(() => selected = value!);
              },
              clearable: false,
            );
          },
        ),
      ),
    );

    final field = find.byType(TextField);
    final controller = tester.widget<TextField>(field).controller!;
    expect(controller.text, 'Current presentation');
    await tester.tap(field);
    await tester.pumpAndSettle();
    expect(controller.text, 'Alpha');
    await tester.enterText(field, 'Bet');
    await tester.pumpAndSettle();
    update(() => display = 'Updated presentation');
    await tester.pumpAndSettle();
    expect(controller.text, 'Bet');
    expect(find.text('Alpha'), findsNothing);
    expect(find.text('Beta'), findsOneWidget);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(reports, [2]);
    expect(controller.text, 'Updated presentation');
    await tester.tap(field);
    await tester.pumpAndSettle();
    expect(controller.text, 'Beta');
  });

  testWidgets(
    'focused search retains its draft after Escape and option refresh',
    (tester) async {
      var secondLabel = 'Beta';
      late StateSetter update;
      await tester.pumpWidget(
        _host(
          YumeiroModality.pointer,
          StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return YumeiroSelect<int>.searchable(
                value: 1,
                options: [
                  const YumeiroSelectionOption(value: 1, label: 'Alpha'),
                  YumeiroSelectionOption(value: 2, label: secondLabel),
                ],
                onChanged: (_) {},
              );
            },
          ),
        ),
      );

      final field = find.byType(TextField);
      await tester.enterText(field, 'Bet');
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      update(() => secondLabel = 'Better');
      await tester.pumpAndSettle();

      final input = tester.widget<TextField>(field);
      expect(input.focusNode!.hasFocus, isTrue);
      expect(input.controller!.text, 'Bet');
      expect(find.byType(PickerFloatingSurface), findsNothing);
    },
  );

  testWidgets('a disabled search retains its initial text across a rebuild', (
    tester,
  ) async {
    var dense = false;
    late StateSetter update;
    await tester.pumpWidget(
      _host(
        YumeiroModality.pointer,
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return YumeiroSelect<String>.searchable(
              options: const [],
              initialText: 'Initial label',
              onChanged: null,
              onFreeTextSubmitted: (_) => fail('Disabled picker cannot submit'),
              dense: dense,
            );
          },
        ),
      ),
    );

    expect(find.text('Initial label'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    update(() => dense = true);
    await tester.pumpAndSettle();
    expect(find.text('Initial label'), findsOneWidget);
  });

  for (final modality in YumeiroModality.values) {
    testWidgets(
      'select distinguishes a null option from dismissal in $modality',
      (tester) async {
        final changes = <int?>[];
        await tester.pumpWidget(
          _host(
            modality,
            YumeiroSelect<int?>(
              value: 1,
              options: const [
                YumeiroSelectionOption(value: 1, label: 'One'),
                YumeiroSelectionOption(value: null, label: 'No assignment'),
              ],
              onChanged: changes.add,
            ),
          ),
        );

        await tester.tap(find.text('One'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('No assignment'));
        await tester.pumpAndSettle();
        expect(changes, [null]);

        await tester.tap(find.text('One'));
        await tester.pumpAndSettle();
        expect(find.text('No assignment'), findsOneWidget);
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();
        expect(find.text('No assignment'), findsNothing);
        expect(changes, [null]);
      },
    );

    testWidgets('open select reports to the current callback in $modality', (
      tester,
    ) async {
      final useCurrent = ValueNotifier(false);
      addTearDown(useCurrent.dispose);
      final previous = <int>[];
      final current = <int>[];
      await tester.pumpWidget(
        _host(
          modality,
          ValueListenableBuilder(
            valueListenable: useCurrent,
            builder: (context, useCurrent, child) => YumeiroSelect<int>(
              value: 1,
              options: const [
                YumeiroSelectionOption(value: 1, label: 'Alpha'),
                YumeiroSelectionOption(value: 2, label: 'Beta'),
              ],
              onChanged: useCurrent ? current.add : previous.add,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();
      useCurrent.value = true;
      await tester.pump();

      await tester.tap(find.text('Beta'));
      await tester.pumpAndSettle();
      expect(previous, isEmpty);
      expect(current, [2]);
    });

    testWidgets('fixed searchable picker rejects free text in $modality', (
      tester,
    ) async {
      final reports = <String?>[];
      await tester.pumpWidget(
        _host(
          modality,
          YumeiroSelect<String>.searchable(
            value: 'alpha-id',
            options: const [
              YumeiroSelectionOption(value: 'alpha-id', label: 'Alpha'),
              YumeiroSelectionOption(value: 'beta-id', label: 'Beta'),
              YumeiroSelectionOption(
                value: 'locked-id',
                label: 'Locked',
                enabled: false,
              ),
            ],
            onChanged: reports.add,
          ),
        ),
      );

      if (modality == YumeiroModality.touch) {
        await tester.tap(find.text('Alpha'));
        await tester.pumpAndSettle();
      }
      await _submitQuery(tester, 'outside the list');
      await _submitQuery(tester, 'locked-id');
      expect(reports, isEmpty);
      expect(find.byType(TextField), findsOneWidget);
      await _submitQuery(tester, 'Beta');
      expect(reports, ['beta-id']);
    });

    testWidgets(
      'searchable picker submits only unmatched free text in $modality',
      (tester) async {
        final reports = <String?>[];
        final rawText = <String>[];
        final touch = modality == YumeiroModality.touch;
        await tester.pumpWidget(
          _host(
            modality,
            StatefulBuilder(
              builder: (context, setState) => YumeiroSelect<String>.searchable(
                value: rawText.lastOrNull ?? 'Saved input',
                options: const [
                  YumeiroSelectionOption(value: 'normal-id', label: 'Normal'),
                  YumeiroSelectionOption(
                    value: 'locked-id',
                    label: 'Locked',
                    enabled: false,
                  ),
                ],
                itemTextBuilder: (item) => 'Item ${item.label}',
                onChanged: reports.add,
                onFreeTextSubmitted: (value) =>
                    setState(() => rawText.add(value)),
              ),
            ),
          ),
        );
        expect(find.text('Saved input'), findsOneWidget);
        if (touch) {
          await tester.tap(find.text('Saved input'));
          await tester.pumpAndSettle();
        }

        for (final query in [' Locked ', 'item locked', 'LOCKED-ID']) {
          await _submitQuery(tester, query);
        }
        expect(reports, isEmpty);
        expect(rawText, isEmpty);

        await _submitQuery(tester, '  custom input  ');
        expect(rawText, ['custom input']);
        expect(reports, isEmpty);
        expect(find.text('custom input'), findsOneWidget);
        if (touch) {
          await tester.tap(find.text('custom input'));
          await tester.pumpAndSettle();
        }
        await _submitQuery(tester, 'normal-id');
        expect(rawText, ['custom input']);
        expect(reports, ['normal-id']);

        final l10n = YumeiroLocalizations.of(
          tester.element(find.byType(Scaffold)),
        );
        await tester.tap(find.byTooltip(l10n.clear));
        await tester.pumpAndSettle();
        expect(rawText, ['custom input']);
        expect(reports, ['normal-id', null]);
      },
    );

    testWidgets('searchable picker keeps both option icons in $modality', (
      tester,
    ) async {
      final reports = <int?>[];
      await tester.pumpWidget(
        _host(
          modality,
          YumeiroSelect<int>.searchable(
            value: 1,
            options: const [
              YumeiroSelectionOption(value: 1, label: 'Alpha'),
              YumeiroSelectionOption(
                value: 2,
                label: 'Beta',
                icon: Icons.star_border,
                trailingIcon: Icons.bolt,
              ),
            ],
            onChanged: reports.add,
          ),
        ),
      );
      final trigger = modality == YumeiroModality.touch
          ? find.text('Alpha')
          : find.byType(TextField);
      await tester.tap(trigger);
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.star_border), findsOneWidget);
      expect(find.byIcon(Icons.bolt), findsOneWidget);
      await tester.tap(find.text('Beta'));
      await tester.pumpAndSettle();
      expect(reports, [2]);
    });

    testWidgets(
      'select exposes selected and enabled option states in $modality',
      (tester) async {
        await tester.pumpWidget(
          _host(
            modality,
            YumeiroSelect<String>(
              value: 'alpha-id',
              options: const [
                YumeiroSelectionOption(
                  value: 'alpha-id',
                  label: 'Alpha',
                  subtitle: 'Recommended choice',
                ),
                YumeiroSelectionOption(
                  value: 'locked-id',
                  label: 'Locked',
                  enabled: false,
                ),
              ],
              onChanged: (_) {},
            ),
          ),
        );
        await tester.tap(find.text('Alpha'));
        await tester.pumpAndSettle();
        expect(find.text('Recommended choice'), findsOneWidget);
        final selected = tester
            .getSemantics(find.text('Alpha').last)
            .getSemanticsData();
        expect(selected.label, contains('Alpha'));
        expect(selected.flagsCollection.isSelected, Tristate.isTrue);
        expect(selected.flagsCollection.isEnabled, Tristate.isTrue);
        final locked = tester
            .getSemantics(find.text('Locked'))
            .getSemanticsData();
        expect(locked.label, contains('Locked'));
        expect(locked.flagsCollection.isSelected, Tristate.isFalse);
        expect(locked.flagsCollection.isEnabled, Tristate.isFalse);
        final unavailable = find.byType(UnavailableSelectionMark);
        expect(unavailable, findsOneWidget);
        expect(
          tester.widget<UnavailableSelectionMark>(unavailable).selected,
          isFalse,
        );
      },
    );
  }

  testWidgets(
    'search highlights the same repeated row after an equal rebuild',
    (tester) async {
      final reports = <int?>[];
      late StateSetter update;
      await tester.pumpWidget(
        _host(
          YumeiroModality.pointer,
          StatefulBuilder(
            builder: (_, setState) {
              update = setState;
              return YumeiroSelect<int>.searchable(
                options: [
                  for (final label in const ['Alpha', 'Alpha'])
                    YumeiroSelectionOption(value: 1, label: label),
                ],
                onChanged: reports.add,
              );
            },
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Al');
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      final rows = find.byType(SelectionMenuRow<int>);
      Iterable<bool> highlights() => tester
          .widgetList<SelectionMenuRow<int>>(rows)
          .map((row) => row.highlighted);
      expect(highlights(), [false, true]);

      update(() {});
      await tester.pumpAndSettle();
      expect(highlights(), [false, true]);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(reports, [1]);
    },
  );

  testWidgets(
    'touch search reveals the selected row and keeps custom matching',
    (tester) async {
      final reports = <int?>[];
      await tester.pumpWidget(
        _host(
          YumeiroModality.touch,
          YumeiroSelect<int>.searchable(
            value: 149,
            options: [
              for (var index = 0; index < 200; index++)
                YumeiroSelectionOption(value: index, label: 'Option $index'),
            ],
            itemTextBuilder: (option) => 'Choice ${option.value}',
            filter: (option, query) => query == 'special' && option.value == 4,
            emptyText: 'No matching choices',
            onChanged: reports.add,
          ),
        ),
      );

      await tester.tap(find.text('Choice 149'));
      await tester.pumpAndSettle();
      final results = find.byType(YumeiroSelectionList<int>);
      expect(
        find
            .descendant(of: results, matching: find.text('Choice 149'))
            .hitTestable(),
        findsOneWidget,
      );
      expect(find.byType(YumeiroSelectionRow).evaluate().length, lessThan(40));

      final input = find.byType(TextField);
      await tester.enterText(input, 'missing');
      await tester.pumpAndSettle();
      final empty = find.ancestor(
        of: find.text('No matching choices'),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Semantics && widget.properties.liveRegion == true,
        ),
      );
      expect(empty, findsOneWidget);

      await tester.enterText(input, 'special');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choice 4').hitTestable());
      await tester.pumpAndSettle();
      expect(reports, [4]);
    },
  );

  testWidgets('searchable dropdown supports typed const construction', (
    tester,
  ) async {
    const YumeiroSelect<int> dropdown = YumeiroSelect.searchable(
      options: [YumeiroSelectionOption(value: 1, label: 'Alpha')],
      value: 1,
      onChanged: null,
    );
    await tester.pumpWidget(_host(YumeiroModality.pointer, dropdown));

    final input = tester.widget<TextField>(find.byType(TextField));
    expect(input.controller!.text, 'Alpha');
    expect(input.enabled, isFalse);
  });

  for (final opensAbove in [false, true]) {
    testWidgets(
      'searchable dropdown keeps empty results anchored when opensAbove is $opensAbove',
      (tester) async {
        const key = ValueKey('searchable field');
        final submitted = <String>[];
        await tester.pumpWidget(
          _host(
            YumeiroModality.pointer,
            Stack(
              children: [
                Positioned(
                  left: 80,
                  top: opensAbove ? 440 : 56,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      YumeiroSelect<int>.searchable(
                        key: key,
                        width: 180,
                        menuWidth: opensAbove ? 210 : 150,
                        emptyText: 'Nothing found',
                        options: const [
                          YumeiroSelectionOption(value: 1, label: 'Alpha'),
                        ],
                        onChanged: (_) {},
                        onFreeTextSubmitted: opensAbove ? null : submitted.add,
                      ),
                      const Text('Following field'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
        final trigger = find.byKey(key);
        final input = find.byType(TextField);
        final following = find.text('Following field');
        final popup = find.byType(PickerFloatingSurface);
        await tester.tap(input);
        await tester.pumpAndSettle();
        final triggerBounds = tester.getRect(trigger);
        final followingBounds = tester.getRect(following);
        final candidateBounds = tester.getRect(popup);
        expect(candidateBounds.width, opensAbove ? 210 : 150);
        final gap = opensAbove
            ? triggerBounds.top - candidateBounds.bottom
            : candidateBounds.top - triggerBounds.bottom;
        expect(gap, 4);

        await tester.enterText(input, 'Missing option');
        await tester.pumpAndSettle();
        final emptyBounds = tester.getRect(popup);
        expect(
          find.descendant(of: popup, matching: find.text('Nothing found')),
          findsOneWidget,
        );
        expect(tester.getRect(trigger), triggerBounds);
        expect(tester.getRect(following), followingBounds);
        expect(emptyBounds.left, candidateBounds.left);
        expect(emptyBounds.width, candidateBounds.width);
        expect(
          opensAbove
              ? triggerBounds.top - emptyBounds.bottom
              : emptyBounds.top - triggerBounds.bottom,
          gap,
        );

        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(popup, findsNothing);
        expect(tester.widget<TextField>(input).focusNode!.hasFocus, isTrue);

        final l10n = YumeiroLocalizations.of(tester.element(trigger));
        await tester.tap(find.byTooltip(l10n.showOptions));
        await tester.pumpAndSettle();
        expect(find.text('Nothing found'), findsOneWidget);
        expect(
          tester.widget<TextField>(input).controller!.text,
          'Missing option',
        );

        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        await tester.enterText(input, 'Missing optionx');
        await tester.pumpAndSettle();
        await tester.enterText(input, 'Missing option');
        await tester.pumpAndSettle();
        expect(find.text('Nothing found'), findsOneWidget);

        await tester.enterText(input, '  New label  ');
        await tester.pumpAndSettle();
        expect(find.text('Nothing found'), findsOneWidget);
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        expect(submitted, opensAbove ? isEmpty : ['New label']);
        expect(popup, findsNothing);
      },
    );
  }

  testWidgets('pointer menus fit a two-line option at scaled text size', (
    tester,
  ) async {
    const options = [
      YumeiroSelectionOption(
        value: 1,
        label: 'Production',
        subtitle: 'Primary workspace',
      ),
    ];
    final controls = [
      YumeiroSelect<int>.menu(
        options: options,
        value: null,
        width: 250,
        maxVisibleItems: 1,
        onChanged: (_) {},
      ),
      YumeiroSelect<int>.searchable(
        options: options,
        width: 250,
        maxVisibleItems: 1,
        onChanged: (_) {},
      ),
    ];
    for (final control in controls) {
      await tester.pumpWidget(
        _host(
          YumeiroModality.pointer,
          Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.5)),
              child: control,
            ),
          ),
        ),
      );
      await tester.tap(find.byWidget(control));
      await tester.pumpAndSettle();
      final menu = tester.getRect(find.byType(PickerFloatingSurface));
      final description = tester.getRect(find.text('Primary workspace'));
      expect(description.bottom, lessThan(menu.bottom - 4));
      await tester.tapAt(Offset.zero);
      await tester.pumpAndSettle();
    }
  });

  testWidgets(
    'searchable dropdown marks the saved option separately from keyboard highlight',
    (tester) async {
      final selected = <int?>[];
      await tester.pumpWidget(
        _host(
          YumeiroModality.pointer,
          YumeiroSelect<int>.searchable(
            options: const [
              YumeiroSelectionOption(value: 1, label: 'Alpha'),
              YumeiroSelectionOption(value: 2, label: 'Beta'),
              YumeiroSelectionOption(
                value: 3,
                label: 'Disabled',
                enabled: false,
              ),
              YumeiroSelectionOption(value: 4, label: 'Delta'),
            ],
            value: 2,
            onChanged: selected.add,
          ),
        ),
      );
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      Finder row(int value) => find.byWidgetPredicate(
        (widget) =>
            widget is SelectionMenuRow<int> && widget.option.value == value,
      );
      final check = find.byIcon(
        YumeiroTheme.of(tester.element(row(2))).icons.check,
      );
      expect(tester.widget<SelectionMenuRow<int>>(row(1)).highlighted, isTrue);
      expect(tester.widget<SelectionMenuRow<int>>(row(2)).selected, isTrue);
      expect(find.descendant(of: row(2), matching: check), findsOneWidget);
      expect(check, findsOneWidget);

      for (var step = 0; step < 2; step++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
      }
      expect(tester.widget<SelectionMenuRow<int>>(row(4)).highlighted, isTrue);
      expect(tester.widget<SelectionMenuRow<int>>(row(3)).highlighted, isFalse);
      expect(find.descendant(of: row(2), matching: check), findsOneWidget);
      expect(check, findsOneWidget);

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(selected, [4]);
    },
  );

  testWidgets(
    'local search keeps shared touch sheet insets and usable landscape results',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 650);
      addTearDown(tester.view.reset);
      final selected = <int?>[];
      await tester.pumpWidget(
        _host(
          YumeiroModality.touch,
          YumeiroSelect<int>.searchable(
            placeholder: 'Choose a person',
            tooltip: 'People',
            options: const [
              YumeiroSelectionOption(value: 1, label: 'Maya Chen'),
            ],
            onChanged: selected.add,
          ),
        ),
      );

      await tester.tap(find.text('Choose a person'));
      await tester.pumpAndSettle();
      final sheet = find.byWidgetPredicate(
        (widget) =>
            widget is YumeiroVisualSurface &&
            widget.role == YumeiroSurfaceRole.modal,
      );
      final field = find.byType(YumeiroTextField);
      final input = find.byType(EditableText);
      expect(
        tester.widget<EditableText>(input).textInputAction,
        TextInputAction.search,
      );
      final sheetRect = tester.getRect(sheet);
      final fieldRect = tester.getRect(field);
      expect(fieldRect.left - sheetRect.left, 8);
      expect(sheetRect.right - fieldRect.right, 8);

      await tester.enterText(input, 'Maya');
      await tester.pumpAndSettle();
      final editor = tester.state<EditableTextState>(input);
      tester.view.physicalSize = const Size(800, 390);
      tester.view.viewInsets = const FakeViewPadding(bottom: 270);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(tester.getSize(sheet).width, 360);
      expect(tester.state<EditableTextState>(input), same(editor));
      expect(editor.widget.focusNode.hasFocus, isTrue);
      expect(editor.widget.controller.text, 'Maya');
      final result = find.text('Maya Chen').hitTestable();
      expect(result, findsOneWidget);
      await tester.tap(result);
      await tester.pumpAndSettle();
      expect(selected, [1]);
    },
  );

  testWidgets('const menu preserves option icons on touch', (tester) async {
    const select = YumeiroSelect<int>.menu(
      value: 1,
      options: [
        YumeiroSelectionOption(value: 1, label: 'One'),
        YumeiroSelectionOption(
          value: 2,
          label: 'Two',
          trailingIcon: Icons.bolt,
        ),
      ],
      onChanged: _ignoreMenuSelection,
    );
    await tester.pumpWidget(_host(YumeiroModality.touch, select));

    await tester.tap(find.text('One'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.bolt), findsOneWidget);
  });

  testWidgets('toolbar menu reveals a distant choice and restores focus', (
    tester,
  ) async {
    final changes = <int?>[];
    await tester.pumpWidget(
      _host(
        YumeiroModality.pointer,
        YumeiroSelect<int?>.menu(
          value: null,
          maxVisibleItems: 5,
          options: [
            for (var index = 0; index < 200; index++)
              YumeiroSelectionOption(
                value: index == 170 ? null : index,
                label: 'Option $index',
              ),
          ],
          onChanged: changes.add,
          child: const Text('Filter'),
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(find.text('Option 170').hitTestable(), findsOneWidget);
    expect(find.byType(MenuItemButton).evaluate().length, lessThan(40));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(MenuItemButton), findsNothing);
    expect(changes, isEmpty);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Option 170').hitTestable(), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(changes, [null]);
    expect(find.byType(MenuItemButton), findsNothing);
  });
}

void _ignoreMenuSelection(int value) {}
