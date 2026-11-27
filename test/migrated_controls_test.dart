import 'dart:collection';

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yumeiro/src/components/controls/select_trigger.dart';
import 'package:yumeiro/src/components/controls/selection_control.dart';
import 'package:yumeiro/yumeiro.dart';

Widget _wrap({
  required Widget child,
  YumeiroModality modality = YumeiroModality.pointer,
}) => YumeiroApp(
  modality: modality,
  home: Scaffold(
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: child,
    ),
  ),
);

class _MeasuredDropdownItems extends ListBase<YumeiroSelectionOption<int>> {
  _MeasuredDropdownItems(this.items, this.onLastRead);

  final List<YumeiroSelectionOption<int>> items;
  final VoidCallback onLastRead;

  @override
  int get length => items.length;

  @override
  set length(int value) => throw UnsupportedError('Read-only options');

  @override
  YumeiroSelectionOption<int> operator [](int index) {
    if (index == items.length - 1) onLastRead();
    return items[index];
  }

  @override
  void operator []=(int index, YumeiroSelectionOption<int> item) =>
      throw UnsupportedError('Read-only options');
}

class _DynamicDropdownItem extends YumeiroSelectionOption<int> {
  const _DynamicDropdownItem(this.resolveLabel) : super(value: 2, label: '');

  final String Function() resolveLabel;

  @override
  String get label => resolveLabel();
}

void main() {
  group('Migrated controls', () {
    for (final modality in YumeiroModality.values) {
      testWidgets(
        'embedded cascading selection keeps its draft open in $modality',
        (tester) async {
          String? value;
          final selected = <String>[];
          await tester.pumpWidget(
            _wrap(
              modality: modality,
              child: StatefulBuilder(
                builder: (context, setState) =>
                    YumeiroCascadingSelection<String>(
                      value: value,
                      options: const [
                        YumeiroCascadingOption.branch(
                          id: 'group',
                          label: 'Group',
                          children: [
                            YumeiroCascadingOption(
                              id: 'alpha',
                              value: 'a',
                              label: 'Alpha',
                            ),
                            YumeiroCascadingOption(
                              id: 'beta',
                              value: 'b',
                              label: 'Beta',
                            ),
                            YumeiroCascadingOption(
                              id: 'disabled',
                              value: 'c',
                              label: 'Disabled',
                              enabled: false,
                            ),
                          ],
                        ),
                      ],
                      onChanged: (next) {
                        selected.add(next);
                        setState(() => value = next);
                      },
                    ),
              ),
            ),
          );
          await tester.tap(find.text('Group'));
          await tester.pumpAndSettle();
          expect(selected, isEmpty);
          await tester.tap(find.text('Beta'));
          await tester.pumpAndSettle();
          expect(selected, ['b']);
          expect(
            find.byType(YumeiroCascadingSelection<String>),
            findsOneWidget,
          );
          expect(find.text('Alpha'), findsOneWidget);
          await tester.tap(find.text('Disabled'));
          await tester.pumpAndSettle();
          expect(selected, ['b']);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets(
      'YumeiroSelect.menu selects option in pointer and touch modalities',
      (tester) async {
        String? value = 'a';
        await tester.pumpWidget(
          _wrap(
            child: StatefulBuilder(
              builder: (context, setState) => YumeiroSelect<String>.menu(
                value: value,
                options: const [
                  YumeiroSelectionOption(value: 'a', label: 'Alpha'),
                  YumeiroSelectionOption(value: 'b', label: 'Beta'),
                ],
                onChanged: (next) => setState(() => value = next),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Alpha'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Beta').last);
        await tester.pumpAndSettle();
        expect(value, 'b');

        // Touch modality opens modal sheet
        await tester.pumpWidget(
          _wrap(
            modality: YumeiroModality.touch,
            child: StatefulBuilder(
              builder: (context, setState) => YumeiroSelect<String>.menu(
                value: value,
                options: const [
                  YumeiroSelectionOption(value: 'a', label: 'Alpha'),
                  YumeiroSelectionOption(value: 'b', label: 'Beta'),
                ],
                onChanged: (next) => setState(() => value = next),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Beta'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Alpha').last);
        await tester.pumpAndSettle();
        expect(value, 'a');
      },
    );

    testWidgets(
      'searchable dropdown keeps selection current when reusing matches',
      (tester) async {
        var optionReads = 0;
        List<YumeiroSelectionOption<int>> track(
          List<YumeiroSelectionOption<int>> options,
        ) => _MeasuredDropdownItems(options, () => optionReads++);
        var items = track(const [
          YumeiroSelectionOption(value: 0, label: 'Match 0'),
          YumeiroSelectionOption(value: 1, label: 'Match 1', enabled: false),
          YumeiroSelectionOption(value: 2, label: 'Match 2'),
          YumeiroSelectionOption(value: 3, label: 'Unrelated'),
        ]);
        late StateSetter reconfigure;
        final selected = <int?>[];
        await tester.pumpWidget(
          _wrap(
            child: StatefulBuilder(
              builder: (context, setState) {
                reconfigure = setState;
                return YumeiroSelect<int>.searchable(
                  value: 0,
                  options: items,
                  width: 180,
                  menuWidth: 180,
                  onChanged: selected.add,
                );
              },
            ),
          ),
        );

        final input = find.byType(TextField);
        await tester.tap(input);
        await tester.pumpAndSettle();
        optionReads = 0;
        await tester.enterText(input, 'Match');
        await tester.pumpAndSettle();
        expect(optionReads, greaterThan(0));
        final afterQuery = optionReads;
        expect(find.text('Match 1'), findsOneWidget);
        expect(find.text('Unrelated'), findsNothing);

        tester.widget<TextField>(input).controller!.selection =
            const TextSelection.collapsed(offset: 1);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        expect(optionReads, afterQuery);

        reconfigure(
          () => items = track(const [
            YumeiroSelectionOption(value: 4, label: 'Match new'),
            YumeiroSelectionOption(value: 3, label: 'Unrelated'),
          ]),
        );
        await tester.pumpAndSettle();
        expect(find.text('Match 2'), findsNothing);
        expect(find.text('Match new'), findsOneWidget);
        expect(optionReads, greaterThan(afterQuery));
        await tester.tap(find.text('Match new'));
        await tester.pumpAndSettle();
        expect(selected, [4]);
        expect(tester.widget<TextField>(input).controller!.text, 'Match new');
      },
    );

    testWidgets('searchable dropdown refreshes callback-driven rows', (
      tester,
    ) async {
      final page = ScrollController();
      addTearDown(page.dispose);
      var showSecond = false;
      var suffix = 'before';
      await tester.pumpWidget(
        YumeiroApp(
          modality: YumeiroModality.pointer,
          home: Scaffold(
            body: SingleChildScrollView(
              controller: page,
              padding: const EdgeInsets.fromLTRB(24, 80, 24, 700),
              child: YumeiroSelect<int>.searchable(
                options: const [
                  YumeiroSelectionOption(value: 1, label: 'First'),
                  YumeiroSelectionOption(value: 2, label: 'Second'),
                ],
                width: 180,
                menuWidth: 180,
                onChanged: (_) {},
                filter: (item, _) => item.value == 1 || showSecond,
                itemTextBuilder: (item) => '${item.label} $suffix',
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'query');
      await tester.pumpAndSettle();
      expect(find.text('First before'), findsOneWidget);
      expect(find.text('Second before'), findsNothing);

      showSecond = true;
      suffix = 'after';
      page.jumpTo(10);
      await tester.pumpAndSettle();
      expect(find.text('First after'), findsOneWidget);
      expect(find.text('Second after'), findsOneWidget);
    });

    testWidgets('searchable dropdown refreshes custom option getters', (
      tester,
    ) async {
      final page = ScrollController();
      addTearDown(page.dispose);
      var label = 'Unrelated';
      await tester.pumpWidget(
        YumeiroApp(
          modality: YumeiroModality.pointer,
          home: Scaffold(
            body: SingleChildScrollView(
              controller: page,
              padding: const EdgeInsets.fromLTRB(24, 80, 24, 700),
              child: YumeiroSelect<int>.searchable(
                options: [
                  const YumeiroSelectionOption(value: 1, label: 'Match first'),
                  _DynamicDropdownItem(() => label),
                ],
                width: 180,
                menuWidth: 180,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Match');
      await tester.pumpAndSettle();
      expect(find.text('Match first'), findsOneWidget);
      expect(find.text('Unrelated'), findsNothing);

      label = 'Match updated';
      page.jumpTo(10);
      await tester.pumpAndSettle();
      expect(find.text('Match updated'), findsOneWidget);
    });

    testWidgets('filtered dropdown keyboard navigation scrolls only its menu', (
      tester,
    ) async {
      const dropdownKey = ValueKey('searchable dropdown');
      final page = ScrollController(initialScrollOffset: 60);
      addTearDown(page.dispose);
      final nextFieldFocus = FocusNode();
      addTearDown(nextFieldFocus.dispose);
      final selections = <int?>[];
      await tester.pumpWidget(
        YumeiroApp(
          modality: YumeiroModality.pointer,
          home: Scaffold(
            body: YumeiroScrollView(
              controller: page,
              child: Column(
                children: [
                  const SizedBox(height: 100),
                  SizedBox(
                    width: 370,
                    height: 450,
                    child: Overlay(
                      initialEntries: [
                        OverlayEntry(
                          builder: (_) => Align(
                            alignment: Alignment.topLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 35),
                              child: YumeiroSelect<int>.searchable(
                                key: dropdownKey,
                                width: 180,
                                maxVisibleItems: 3,
                                options: [
                                  const YumeiroSelectionOption(
                                    value: -1,
                                    label: 'Unrelated',
                                  ),
                                  for (var i = 0; i < 12; i++)
                                    YumeiroSelectionOption(
                                      value: i,
                                      label: 'Result $i',
                                    ),
                                ],
                                onChanged: selections.add,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  YumeiroTextField(focusNode: nextFieldFocus),
                  const SizedBox(height: 800),
                ],
              ),
            ),
          ),
        ),
      );

      final input = find.descendant(
        of: find.byKey(dropdownKey),
        matching: find.byType(TextField),
      );
      await tester.enterText(input, 'Result');
      await tester.pumpAndSettle();
      expect(find.text('Unrelated'), findsNothing);
      final options = tester.widget<ListView>(find.byType(ListView));
      final pageOffset = page.offset;
      final menuOffset = options.controller!.offset;

      for (final key in [
        ...List.filled(5, LogicalKeyboardKey.arrowDown),
        LogicalKeyboardKey.arrowUp,
      ]) {
        await tester.sendKeyEvent(key);
        await tester.pumpAndSettle();
        expect(page.offset, pageOffset);
        expect(tester.widget<TextField>(input).focusNode!.hasFocus, isTrue);
      }
      expect(options.controller!.offset, greaterThan(menuOffset));
      expect(selections, isEmpty);

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(selections, [4]);

      await tester.enterText(input, 'Result');
      await tester.pumpAndSettle();
      expect(find.byType(ListView), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(nextFieldFocus.hasPrimaryFocus, isFalse);
      expect(find.byType(ListView), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(nextFieldFocus.hasPrimaryFocus, isTrue);
    });

    testWidgets('YumeiroCascadingSelect opens branches on click or tap', (
      tester,
    ) async {
      const options = [
        YumeiroCascadingOption<String>.branch(
          id: 'render',
          label: 'Render',
          children: [
            YumeiroCascadingOption(
              id: 'render/optical',
              value: 'render/optical',
              label: 'Optical',
            ),
            YumeiroCascadingOption(
              id: 'render/blur',
              value: 'render/blur',
              label: 'Blur',
            ),
            YumeiroCascadingOption(
              id: 'render/locked',
              value: 'render/locked',
              label: 'Locked rendering',
              enabled: false,
            ),
          ],
        ),
        YumeiroCascadingOption<String>.branch(
          id: 'layout',
          label: 'Layout',
          children: [
            YumeiroCascadingOption(
              id: 'layout/touch',
              value: 'layout/touch',
              label: 'Touch',
            ),
          ],
        ),
        YumeiroCascadingOption<String>.branch(
          id: 'locked',
          label: 'Locked branch',
          enabled: false,
          children: [
            YumeiroCascadingOption(
              id: 'locked/child',
              value: 'locked/child',
              label: 'Locked child',
            ),
          ],
        ),
      ];

      String selected = 'render/optical';
      await tester.pumpWidget(
        _wrap(
          child: StatefulBuilder(
            builder: (context, setState) => YumeiroCascadingSelect<String>(
              title: 'Mode',
              value: selected,
              options: options,
              onChanged: (next) => setState(() => selected = next),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(YumeiroSelectTriggerVisual));
      await tester.pumpAndSettle();
      expect(find.text('Optical'), findsOneWidget);
      expect(find.text('Touch'), findsNothing);
      expect(find.byType(UnavailableSelectionMark), findsNWidgets(2));
      await tester.tap(find.text('Locked branch'));
      await tester.tap(find.text('Locked rendering'));
      await tester.pumpAndSettle();
      expect(find.text('Locked child'), findsNothing);
      expect(selected, 'render/optical');

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: tester.getCenter(find.text('Render')));
      final layout = tester.getCenter(find.text('Layout'));
      await mouse.moveTo(layout);
      await tester.pumpAndSettle();
      expect(find.text('Optical'), findsOneWidget);
      expect(find.text('Touch'), findsNothing);

      await mouse.down(layout);
      await mouse.up();
      await tester.pumpAndSettle();
      expect(find.text('Optical'), findsNothing);
      expect(selected, 'render/optical');
      final touch = tester.getCenter(find.text('Touch'));
      await mouse.moveTo(touch);
      await mouse.down(touch);
      await mouse.up();
      await tester.pumpAndSettle();
      expect(selected, 'layout/touch');

      await tester.pumpWidget(
        _wrap(
          modality: YumeiroModality.touch,
          child: StatefulBuilder(
            builder: (context, setState) => YumeiroCascadingSelect<String>(
              title: 'Mode',
              value: selected,
              options: options,
              onChanged: (next) => setState(() => selected = next),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(YumeiroSelectTriggerVisual));
      await tester.pumpAndSettle();
      final panel = find.byType(YumeiroCascadingSelection<String>);
      Finder option(String label) =>
          find.descendant(of: panel, matching: find.text(label));
      bool isHighlighted(String label) => tester
          .widget<YumeiroInteractiveVisualSurface>(
            find.ancestor(
              of: option(label),
              matching: find.byType(YumeiroInteractiveVisualSurface),
            ),
          )
          .selected;
      expect(option('Render'), findsOneWidget);
      expect(option('Touch'), findsNothing);
      expect(find.byType(UnavailableSelectionMark), findsOneWidget);
      await tester.tap(option('Locked branch'));
      await tester.pumpAndSettle();
      expect(option('Locked child'), findsNothing);
      expect(isHighlighted('Layout'), isTrue);

      await tester.tap(option('Layout'));
      await tester.pumpAndSettle();
      expect(option('Render'), findsNothing);
      expect(isHighlighted('Touch'), isTrue);
      await tester.tap(find.widgetWithText(YumeiroButton, 'Layout'));
      await tester.pumpAndSettle();
      await tester.tap(option('Render'));
      await tester.pumpAndSettle();
      expect(isHighlighted('Optical'), isFalse);
      await tester.tap(option('Blur'));
      await tester.pumpAndSettle();
      expect(selected, 'render/blur');

      await tester.tap(find.byType(YumeiroSelectTriggerVisual));
      await tester.pumpAndSettle();
      expect(option('Blur'), findsNothing);
      expect(isHighlighted('Render'), isTrue);
    });

    testWidgets('YumeiroColorPickerButton picks preset color', (tester) async {
      Color? color = const Color(0xFF19857B);
      const amber = Color(0xFFF59E0B);
      await tester.pumpWidget(
        _wrap(
          child: StatefulBuilder(
            builder: (context, setState) => YumeiroColorPickerButton(
              value: color,
              defaultColor: const Color(0xFF19857B),
              presets: const [
                YumeiroColorPickerPreset(
                  label: 'Teal',
                  color: Color(0xFF19857B),
                ),
                YumeiroColorPickerPreset(label: 'Amber', color: amber),
              ],
              onChanged: (next) => setState(() => color = next),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(YumeiroColorPickerButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Amber'));
      await tester.pumpAndSettle();
      expect(color, amber);
    });

    for (final modality in YumeiroModality.values) {
      testWidgets('HEX editing preserves the default color in $modality', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(850, 900);
        addTearDown(tester.view.reset);

        const defaultColor = Color(0xFFF3DDD9);
        const customColor = Color(0xFF7287BA);
        final changes = <Color?>[];
        Color? color;
        await tester.pumpWidget(
          _wrap(
            modality: modality,
            child: StatefulBuilder(
              builder: (context, setState) => YumeiroColorPickerButton(
                value: color,
                defaultColor: defaultColor,
                onChanged: (value) {
                  changes.add(value);
                  setState(() => color = value);
                },
              ),
            ),
          ),
        );

        final trigger = find.byType(YumeiroColorPickerButton);
        final input = find.byKey(const ValueKey('yumeiro-color-hex-input'));
        final close = modality == YumeiroModality.pointer
            ? find.byTooltip('Close')
            : find.text('Done');

        await tester.tap(trigger);
        await tester.pumpAndSettle();
        await tester.tap(input);
        final editable = tester.widget<EditableText>(
          find.descendant(of: input, matching: find.byType(EditableText)),
        );
        editable.controller.selection = const TextSelection.collapsed(
          offset: 2,
        );
        await tester.pumpAndSettle();
        expect(editable.controller.text, '#F3DDD9');
        await tester.tap(close);
        await tester.pumpAndSettle();
        expect(changes, isEmpty);

        await tester.tap(trigger);
        await tester.pumpAndSettle();
        await tester.enterText(input, '#7287BA');
        await tester.enterText(input, '#f3ddd9');
        await tester.tap(close);
        await tester.pumpAndSettle();
        expect(changes, isEmpty);

        await tester.tap(trigger);
        await tester.pumpAndSettle();
        await tester.enterText(input, '#7287BA');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        expect(changes, [customColor]);

        await tester.tap(find.byTooltip('Default').hitTestable());
        await tester.pumpAndSettle();
        await tester.tap(close);
        await tester.pumpAndSettle();
        expect(changes, [customColor, null]);
      });
    }

    testWidgets('YumeiroTokenInput adds and removes tokens', (tester) async {
      var tokens = <String>['Alpha'];
      await tester.pumpWidget(
        _wrap(
          child: StatefulBuilder(
            builder: (context, setState) => YumeiroTokenInput<String>(
              title: 'Tags',
              values: tokens,
              onChanged: (next) => setState(() => tokens = next),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Beta');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(tokens, ['Alpha', 'Beta']);

      // Remove Alpha via its remove button tooltip
      await tester.tap(find.byTooltip('Remove Alpha'));
      await tester.pumpAndSettle();
      expect(tokens, ['Beta']);
    });

    testWidgets('YumeiroRatingEditor updates rating on tap', (tester) async {
      double? rating = 2.0;
      await tester.pumpWidget(
        _wrap(
          child: StatefulBuilder(
            builder: (context, setState) => Center(
              child: YumeiroRatingEditor(
                value: rating,
                onChanged: (next) => setState(() => rating = next),
              ),
            ),
          ),
        ),
      );

      final rect = tester.getRect(find.byType(YumeiroRatingEditor));
      await tester.tapAt(rect.centerRight - const Offset(2, 0));
      await tester.pumpAndSettle();
      expect(rating, 5.0);
    });

    testWidgets(
      'YumeiroSearchHost and YumeiroSearchButton submit search query',
      (tester) async {
        var submitted = '';
        await tester.pumpWidget(
          YumeiroApp(
            modality: YumeiroModality.pointer,
            home: YumeiroSearchHost(
              child: StatefulBuilder(
                builder: (context, setState) => YumeiroSearchScope(
                  query: submitted,
                  placeholder: 'Find presets',
                  onSubmitted: (value) => setState(() => submitted = value),
                  child: const Scaffold(
                    body: Center(
                      child: YumeiroSearchButton(
                        variant: YumeiroButtonVariant.ghost,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        final searchButton = find.byType(YumeiroSearchButton);
        final control = find.descendant(
          of: searchButton,
          matching: find.byType(YumeiroButton),
        );
        expect(
          tester.widget<YumeiroButton>(control).variant,
          YumeiroButtonVariant.ghost,
        );
        await tester.tap(searchButton);
        await tester.pumpAndSettle();
        expect(find.byType(YumeiroDialog), findsOneWidget);
        await tester.enterText(find.byType(TextField), 'liquid');
        await tester.tap(find.text('Search').last);
        await tester.pumpAndSettle();
        expect(submitted, 'liquid');
        expect(tester.widget<YumeiroButton>(control).selected, isTrue);
      },
    );

    testWidgets('touch search submits from a bottom sheet', (tester) async {
      tester.view.physicalSize = const Size(390, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final submitted = <String>[];
      await tester.pumpWidget(
        YumeiroApp(
          modality: YumeiroModality.touch,
          home: Scaffold(
            body: YumeiroSearchScope(
              query: 'initial',
              placeholder: 'Find presets',
              onSubmitted: submitted.add,
              child: const YumeiroSearchButton(),
            ),
          ),
        ),
      );

      final button = find.byType(YumeiroSearchButton);
      final sheet = find.byType(YumeiroBottomSheet);
      final field = find.byType(EditableText);
      expect(find.byTooltip('Search'), findsOneWidget);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(sheet, findsOneWidget);
      await tester.enterText(field, 'discarded');
      await tester.tap(find.widgetWithText(YumeiroButton, 'Cancel'));
      await tester.pumpAndSettle();
      expect(sheet, findsNothing);
      expect(submitted, isEmpty);

      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(tester.widget<EditableText>(field).controller.text, 'initial');
      await tester.enterText(field, '  liquid  ');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(sheet, findsNothing);
      expect(submitted, ['liquid']);
    });

    testWidgets(
      'Find prioritizes the focused search scope in split panes',
      (tester) async {
        final focus = FocusNode();
        addTearDown(focus.dispose);
        await tester.pumpWidget(
          YumeiroApp(
            modality: YumeiroModality.pointer,
            home: Scaffold(
              body: YumeiroSearchHost(
                child: Row(
                  children: [
                    Expanded(
                      child: YumeiroSearchScope(
                        query: '',
                        placeholder: 'Search left pane',
                        onSubmitted: (_) {},
                        child: YumeiroButton(
                          label: 'Focus left pane',
                          focusNode: focus,
                          onPressed: () {},
                        ),
                      ),
                    ),
                    Expanded(
                      child: YumeiroSearchScope(
                        query: '',
                        placeholder: 'Search right pane',
                        onSubmitted: (_) {},
                        child: const YumeiroSearchButton(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        focus.requestFocus();
        await tester.pumpAndSettle();

        final mac = defaultTargetPlatform == TargetPlatform.macOS;
        final shortcut = mac ? '⌘F' : 'Ctrl+F';
        expect(find.byTooltip('Search right pane ($shortcut)'), findsOneWidget);
        final modifier = mac
            ? LogicalKeyboardKey.metaLeft
            : LogicalKeyboardKey.controlLeft;
        await tester.sendKeyDownEvent(modifier);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
        await tester.sendKeyUpEvent(modifier);
        await tester.pumpAndSettle();

        expect(
          tester.widget<YumeiroDialog>(find.byType(YumeiroDialog)).title,
          'Search left pane',
        );
      },
      variant: const TargetPlatformVariant({
        TargetPlatform.linux,
        TargetPlatform.macOS,
      }),
    );

    testWidgets(
      'YumeiroSettingRow.select adapts across pointer dropdown and touch sheet',
      (tester) async {
        String? selected = 'one';
        await tester.pumpWidget(
          _wrap(
            modality: YumeiroModality.pointer,
            child: StatefulBuilder(
              builder: (context, setState) => YumeiroSettingRow.select<String>(
                title: 'Capability',
                value: selected,
                options: const [
                  YumeiroSelectionOption(value: 'one', label: 'One'),
                  YumeiroSelectionOption(value: 'two', label: 'Two'),
                ],
                onChanged: (next) => setState(() => selected = next),
              ),
            ),
          ),
        );

        // Pointer modality opens YumeiroSelect.menu popup from trailing trigger
        await tester.tap(find.text('One'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Two').last);
        await tester.pumpAndSettle();
        expect(selected, 'two');

        // Touch modality opens the selection sheet on row tap.
        await tester.pumpWidget(
          _wrap(
            modality: YumeiroModality.touch,
            child: StatefulBuilder(
              builder: (context, setState) => YumeiroSettingRow.select<String>(
                title: 'Capability',
                value: selected,
                options: const [
                  YumeiroSelectionOption(value: 'one', label: 'One'),
                  YumeiroSelectionOption(value: 'two', label: 'Two'),
                ],
                onChanged: (next) => setState(() => selected = next),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Capability'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('One').last);
        await tester.pumpAndSettle();
        expect(selected, 'one');
      },
    );

    testWidgets(
      'YumeiroSelect aligns trigger and menu width to widest item and caps at maxWidth',
      (tester) async {
        String value = 'fast';
        await tester.pumpWidget(
          _wrap(
            child: StatefulBuilder(
              builder: (context, setState) => Wrap(
                children: [
                  YumeiroSelect<String>(
                    value: value,
                    options: const [
                      YumeiroSelectionOption(value: 'fast', label: 'Fast'),
                      YumeiroSelectionOption(
                        value: 'balanced',
                        label: 'Balanced Render',
                      ),
                    ],
                    onChanged: (next) => setState(() => value = next),
                  ),
                ],
              ),
            ),
          ),
        );

        final triggerFinder = find.byType(YumeiroSelect<String>);
        final initialWidth = tester.getSize(triggerFinder).width;
        expect(initialWidth, lessThan(320.0));

        await tester.tap(triggerFinder);
        await tester.pumpAndSettle();

        final menuFinder = find.byWidgetPredicate(
          (w) =>
              w is YumeiroVisualSurface &&
              w.role == YumeiroSurfaceRole.floating,
        );
        expect(tester.getSize(menuFinder).width, initialWidth);

        await tester.tap(find.text('Balanced Render').last);
        await tester.pumpAndSettle();
        expect(value, 'balanced');
        expect(tester.getSize(triggerFinder).width, initialWidth);

        // Long labels cap both trigger and popup menu at default 320.0
        await tester.pumpWidget(
          _wrap(
            child: Wrap(
              children: [
                YumeiroSelect<String>(
                  value: 'long',
                  options: const [
                    YumeiroSelectionOption(
                      value: 'long',
                      label: 'Extremely Long Option Label That Exceeds Default Maximum Width',
                    ),
                  ],
                  onChanged: (_) {},
                ),
              ],
            ),
          ),
        );
        expect(tester.getSize(triggerFinder).width, 320.0);
        await tester.tap(triggerFinder);
        await tester.pumpAndSettle();
        expect(tester.getSize(menuFinder).width, 320.0);
      },
    );

    testWidgets(
      'YumeiroSelect.menu aligns trigger and MenuAnchor width and caps at maxWidth',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            child: Wrap(
              children: [
                YumeiroSelect<String>.menu(
                  value: 'low',
                  options: const [
                    YumeiroSelectionOption(value: 'low', label: 'Low'),
                    YumeiroSelectionOption(
                      value: 'med',
                      label: 'Medium Quality Mode',
                    ),
                  ],
                  onChanged: (_) {},
                ),
              ],
            ),
          ),
        );

        final triggerWidth = tester
            .getSize(find.byType(YumeiroSelectTriggerVisual))
            .width;
        expect(triggerWidth, lessThan(320.0));

        await tester.tap(find.byType(YumeiroSelectTriggerVisual));
        await tester.pumpAndSettle();

        final popupFinder = find
            .ancestor(
              of: find.byType(MenuItemButton).first,
              matching: find.byType(YumeiroGlassSamplingScope),
            )
            .first;
        final popupWidth = tester.getSize(popupFinder).width;
        expect(popupWidth, triggerWidth);

        // Dismiss menu before rebuilding with long labels
        await tester.tapAt(Offset.zero);
        await tester.pumpAndSettle();

        await tester.pumpWidget(
          _wrap(
            child: Wrap(
              children: [
                YumeiroSelect<String>.menu(
                  value: 'long',
                  options: const [
                    YumeiroSelectionOption(
                      value: 'long',
                      label: 'Extremely Long Dropdown Option Label Exceeding Maximum Width',
                    ),
                  ],
                  onChanged: (_) {},
                ),
              ],
            ),
          ),
        );
        expect(
          tester.getSize(find.byType(YumeiroSelectTriggerVisual)).width,
          320.0,
        );
        await tester.tap(find.byType(YumeiroSelectTriggerVisual));
        await tester.pumpAndSettle();
        expect(tester.getSize(popupFinder).width, 320.0);
      },
    );

    testWidgets(
      'searchable dropdown aligns trigger and popup width and caps at maxWidth',
      (tester) async {
        const dropdownKey = ValueKey('searchable dropdown');
        await tester.pumpWidget(
          _wrap(
            child: SizedBox(
              width: 600,
              child: Wrap(
                children: [
                  YumeiroSelect<String>.searchable(
                    key: dropdownKey,
                    value: 'sketch',
                    options: const [
                      YumeiroSelectionOption(value: 'sketch', label: 'Sketch'),
                      YumeiroSelectionOption(
                        value: 'glass',
                        label: 'Liquid Glass',
                      ),
                    ],
                    onChanged: (_) {},
                  ),
                ],
              ),
            ),
          ),
        );

        final triggerFinder = find.byKey(dropdownKey);
        final triggerWidth = tester.getSize(triggerFinder).width;
        expect(triggerWidth, lessThan(320.0));

        await tester.tap(find.byType(TextField));
        await tester.pumpAndSettle();

        final popupFinder = find
            .ancestor(
              of: find.byType(MenuItemButton).first,
              matching: find.byType(YumeiroGlassSamplingScope),
            )
            .first;
        final popupWidth = tester.getSize(popupFinder).width;
        expect(popupWidth, triggerWidth);

        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();

        // Long items cap both trigger and popup at maxWidth (320.0)
        await tester.pumpWidget(
          _wrap(
            child: SizedBox(
              width: 600,
              child: Wrap(
                children: [
                  YumeiroSelect<String>.searchable(
                    key: dropdownKey,
                    value: 'long',
                    options: const [
                      YumeiroSelectionOption(
                        value: 'long',
                        label: 'Extremely Long Searchable Dropdown Option Exceeding Default Max Width',
                      ),
                    ],
                    onChanged: (_) {},
                  ),
                ],
              ),
            ),
          ),
        );
        expect(tester.getSize(triggerFinder).width, 320.0);
        await tester.tap(find.byType(TextField));
        await tester.pumpAndSettle();
        expect(tester.getSize(popupFinder).width, 320.0);

        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();

        // expand matches parent width for both trigger and popup
        await tester.pumpWidget(
          _wrap(
            child: SizedBox(
              width: 480,
              child: YumeiroSelect<String>.searchable(
                key: dropdownKey,
                expand: true,
                value: 'sketch',
                options: const [
                  YumeiroSelectionOption(value: 'sketch', label: 'Sketch'),
                ],
                onChanged: (_) {},
              ),
            ),
          ),
        );
        expect(tester.getSize(triggerFinder).width, 480.0);
        await tester.tap(find.byType(TextField));
        await tester.pumpAndSettle();
        expect(tester.getSize(popupFinder).width, 480.0);
      },
    );

    testWidgets(
      'menuAutoWidth and explicit menuWidth decouple popup width from trigger width',
      (tester) async {
        // YumeiroSelect: expand trigger (480) + menuAutoWidth (content < 320)
        await tester.pumpWidget(
          _wrap(
            child: SizedBox(
              width: 480,
              child: YumeiroSelect<String>(
                expand: true,
                menuAutoWidth: true,
                value: 'fast',
                options: const [
                  YumeiroSelectionOption(value: 'fast', label: 'Fast'),
                  YumeiroSelectionOption(value: 'balanced', label: 'Balanced'),
                ],
                onChanged: (_) {},
              ),
            ),
          ),
        );
        final selectFinder = find.byType(YumeiroSelect<String>);
        expect(tester.getSize(selectFinder).width, 480.0);
        await tester.tap(selectFinder);
        await tester.pumpAndSettle();
        final selectMenuFinder = find.byWidgetPredicate(
          (w) =>
              w is YumeiroVisualSurface &&
              w.role == YumeiroSurfaceRole.floating,
        );
        final selectMenuW = tester.getSize(selectMenuFinder).width;
        expect(selectMenuW, lessThan(320.0));
        expect(selectMenuW, greaterThan(80.0));
        await tester.tap(find.text('Balanced').last);
        await tester.pumpAndSettle();

        // YumeiroSelect.menu: narrow fixed trigger (100) + menuAutoWidth (> 100)
        await tester.pumpWidget(
          _wrap(
            child: YumeiroSelect<String>.menu(
              width: 100,
              menuAutoWidth: true,
              value: 'a',
              options: const [
                YumeiroSelectionOption(
                  value: 'a',
                  label: 'Medium Option Label',
                ),
              ],
              onChanged: (_) {},
            ),
          ),
        );
        expect(
          tester.getSize(find.byType(YumeiroSelectTriggerVisual)).width,
          100.0,
        );
        await tester.tap(find.byType(YumeiroSelectTriggerVisual));
        await tester.pumpAndSettle();
        final popupFinder = find
            .ancestor(
              of: find.byType(MenuItemButton).first,
              matching: find.byType(YumeiroGlassSamplingScope),
            )
            .first;
        final dropdownMenuW = tester.getSize(popupFinder).width;
        expect(dropdownMenuW, greaterThan(100.0));
        expect(dropdownMenuW, lessThanOrEqualTo(320.0));
        await tester.tapAt(Offset.zero);
        await tester.pumpAndSettle();

        // Searchable dropdown: expanded trigger (480) with a content-sized menu.
        const dropdownKey = ValueKey('searchable dropdown');
        await tester.pumpWidget(
          _wrap(
            child: SizedBox(
              width: 480,
              child: YumeiroSelect<String>.searchable(
                key: dropdownKey,
                expand: true,
                menuAutoWidth: true,
                value: 'sketch',
                options: const [
                  YumeiroSelectionOption(value: 'sketch', label: 'Sketch'),
                  YumeiroSelectionOption(value: 'glass', label: 'Liquid Glass'),
                ],
                onChanged: (_) {},
              ),
            ),
          ),
        );
        final searchTriggerFinder = find.byKey(dropdownKey);
        expect(tester.getSize(searchTriggerFinder).width, 480.0);
        await tester.tap(find.byType(TextField));
        await tester.pumpAndSettle();
        final searchMenuW = tester.getSize(popupFinder).width;
        expect(searchMenuW, lessThanOrEqualTo(320.0));
        expect(searchMenuW, lessThan(480.0));
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();

        // Explicit menuWidth overrides menuAutoWidth
        await tester.pumpWidget(
          _wrap(
            child: SizedBox(
              width: 480,
              child: YumeiroSelect<String>.searchable(
                expand: true,
                menuAutoWidth: true,
                menuWidth: 260,
                value: 'sketch',
                options: const [
                  YumeiroSelectionOption(value: 'sketch', label: 'Sketch'),
                ],
                onChanged: (_) {},
              ),
            ),
          ),
        );
        await tester.tap(find.byType(TextField));
        await tester.pumpAndSettle();
        expect(tester.getSize(popupFinder).width, 260.0);
      },
    );

    testWidgets('sized cascading triggers look up only the selected label', (
      tester,
    ) async {
      const options = [
        YumeiroCascadingOption(id: 'a', label: 'A', value: 'a'),
        YumeiroCascadingOption(id: 'b', label: 'B', value: 'b'),
      ];
      final trigger = find.byType(YumeiroSelectTriggerVisual);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);

      for (final (width, tight, expand) in [
        (double.infinity, false, false),
        (null, true, false),
        (null, false, true),
      ]) {
        final lookedUp = <String>{};
        final select = YumeiroCascadingSelect<String>(
          title: 'Scope',
          width: width,
          expand: expand,
          value: 'a',
          options: options,
          onChanged: (_) {},
          valueLabel: (value) {
            lookedUp.add(value);
            return 'Selected path $value';
          },
        );
        await tester.pumpWidget(
          _wrap(
            child: SizedBox(
              width: 360,
              child: Wrap(
                children: [
                  tight ? SizedBox(width: 360, child: select) : select,
                ],
              ),
            ),
          ),
        );
        expect(tester.getSize(trigger).width, 360);
        expect(find.text('Selected path a'), findsOneWidget);
        expect(lookedUp, {'a'});

        await mouse.moveTo(tester.getCenter(trigger));
        await tester.pump();
        expect(lookedUp, {'a'});
        await mouse.moveTo(Offset.zero);
        await tester.pump();
      }
    });

    testWidgets(
      'YumeiroCascadingSelect keeps trigger and menu widths independent',
      (tester) async {
        const options = [
          YumeiroCascadingOption<String>.branch(
            id: 'render',
            label: 'Render',
            children: [
              YumeiroCascadingOption(
                id: 'render/optical',
                value: 'render/optical',
                label: 'Optical',
              ),
            ],
          ),
        ];

        await tester.pumpWidget(
          _wrap(
            child: Wrap(
              children: [
                YumeiroCascadingSelect<String>(
                  title: 'Mode',
                  value: 'render/optical',
                  options: options,
                  onChanged: (_) {},
                ),
              ],
            ),
          ),
        );
        final triggerW = tester
            .getSize(find.byType(YumeiroSelectTriggerVisual))
            .width;
        expect(triggerW, lessThan(320.0));
        await tester.tap(find.byType(YumeiroSelectTriggerVisual));
        await tester.pumpAndSettle();
        final floatingPopupFinder = find.ancestor(
          of: find.text('Render'),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is YumeiroVisualSurface &&
                widget.role == YumeiroSurfaceRole.floating,
          ),
        );
        expect(tester.getSize(floatingPopupFinder).width, 360.0);
        await tester.tapAt(Offset.zero);
        await tester.pumpAndSettle();

        // Explicit independent trigger width & menuWidth
        await tester.pumpWidget(
          _wrap(
            child: Wrap(
              children: [
                YumeiroCascadingSelect<String>(
                  title: 'Mode',
                  width: 200,
                  menuWidth: 420,
                  value: 'render/optical',
                  options: options,
                  onChanged: (_) {},
                ),
              ],
            ),
          ),
        );
        expect(
          tester.getSize(find.byType(YumeiroSelectTriggerVisual)).width,
          200.0,
        );
        await tester.tap(find.byType(YumeiroSelectTriggerVisual));
        await tester.pumpAndSettle();
        expect(tester.getSize(floatingPopupFinder).width, 420.0);
      },
    );
  });
}
