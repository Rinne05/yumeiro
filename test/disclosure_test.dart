import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

void main() {
  testWidgets('header exposes controlled expansion and supports keyboard', (
    tester,
  ) async {
    final focus = FocusNode();
    final expanded = ValueNotifier(false);
    final requests = <bool>[];
    addTearDown(focus.dispose);
    addTearDown(expanded.dispose);

    await tester.pumpWidget(
      YumeiroApp(
        home: Scaffold(
          body: ValueListenableBuilder(
            valueListenable: expanded,
            builder: (context, isExpanded, child) => YumeiroDisclosure(
              title: const Text('Advanced settings'),
              expanded: isExpanded,
              focusNode: focus,
              onChanged: requests.add,
              child: child!,
            ),
            child: const Text('Extra settings'),
          ),
        ),
      ),
    );
    final header = find.text('Advanced settings');
    expect(
      tester.getSemantics(header),
      isSemantics(isButton: true, isExpanded: false, hasTapAction: true),
    );
    expect(find.bySemanticsLabel('Extra settings'), findsNothing);
    focus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(requests, [true]);
    expect(find.text('Extra settings'), findsNothing);

    expanded.value = true;
    await tester.pumpAndSettle();
    expect(tester.getSemantics(header), isSemantics(isExpanded: true));
    expect(find.bySemanticsLabel('Extra settings'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(requests, [true, false]);
  });

  testWidgets('collapse restores focus and keeps a hidden form draft', (
    tester,
  ) async {
    final form = GlobalKey<FormState>();
    final header = FocusNode();
    final body = FocusNode();
    final next = FocusNode();
    final expanded = ValueNotifier(true);
    addTearDown(header.dispose);
    addTearDown(body.dispose);
    addTearDown(next.dispose);
    addTearDown(expanded.dispose);
    var saved = '';
    String? validate(String? text) => text == 'draft' ? 'Needs review' : null;
    await tester.pumpWidget(
      YumeiroApp(
        home: Scaffold(
          body: Form(
            key: form,
            child: Column(
              children: [
                ValueListenableBuilder(
                  valueListenable: expanded,
                  builder: (context, isExpanded, child) => YumeiroDisclosure(
                    title: const Text('Details'),
                    expanded: isExpanded,
                    focusNode: header,
                    onChanged: (value) => expanded.value = value,
                    child: child!,
                  ),
                  child: TextFormField(
                    initialValue: 'seed',
                    focusNode: body,
                    validator: validate,
                    onSaved: (value) => saved = value!,
                  ),
                ),
                YumeiroButton(
                  label: 'Continue',
                  focusNode: next,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final field = find.byType(TextFormField);
    await tester.enterText(field, 'draft');
    await tester.pump();
    expect(body.hasFocus, isTrue);

    expanded.value = false;
    await tester.pumpAndSettle();
    expect(header.hasPrimaryFocus, isTrue);
    expect(body.hasFocus, isFalse);
    expect(field.hitTestable(), findsNothing);
    expect(find.byType(TextFormField, skipOffstage: false), findsOneWidget);
    form.currentState!.save();
    expect(saved, 'draft');
    expect(form.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.bySemanticsLabel('Needs review'), findsNothing);

    body.requestFocus();
    await tester.pump();
    expect(header.hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(next.hasPrimaryFocus, isTrue);

    expanded.value = true;
    await tester.pumpAndSettle();
    expect(find.text('draft'), findsOneWidget);
    expect(find.text('Needs review'), findsOneWidget);
    expect(next.hasPrimaryFocus, isTrue);

    expanded.value = false;
    await tester.pumpAndSettle();
    expect(next.hasPrimaryFocus, isTrue);
  });

  testWidgets('maintainState false replaces the collapsed body', (
    tester,
  ) async {
    final expanded = ValueNotifier(true);
    addTearDown(expanded.dispose);
    await tester.pumpWidget(
      YumeiroApp(
        modality: YumeiroModality.touch,
        home: Scaffold(
          body: ValueListenableBuilder(
            valueListenable: expanded,
            builder: (context, isExpanded, child) => YumeiroDisclosure(
              title: const Text('Details'),
              expanded: isExpanded,
              maintainState: false,
              onChanged: (value) => expanded.value = value,
              child: child!,
            ),
            child: TextFormField(initialValue: 'seed'),
          ),
        ),
      ),
    );
    final field = find.byType(TextFormField);
    final header = find.byType(YumeiroInteractiveVisualSurface);
    expect(tester.getSize(header).height, greaterThanOrEqualTo(48));
    await tester.enterText(field, 'draft');
    expanded.value = false;
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField, skipOffstage: false), findsNothing);
    await tester.tap(find.text('Details'));
    await tester.pumpAndSettle();
    expect(find.text('seed'), findsOneWidget);
    expect(find.text('draft'), findsNothing);
  });

  testWidgets(
    'collapse returns focus to a header enabled in the same rebuild',
    (tester) async {
      final collapsed = ValueNotifier(false);
      final header = FocusNode();
      final body = FocusNode();
      addTearDown(collapsed.dispose);
      addTearDown(header.dispose);
      addTearDown(body.dispose);

      await tester.pumpWidget(
        YumeiroApp(
          home: Scaffold(
            body: ValueListenableBuilder(
              valueListenable: collapsed,
              builder: (context, isCollapsed, child) => YumeiroDisclosure(
                title: const Text('Details'),
                expanded: !isCollapsed,
                focusNode: header,
                onChanged: isCollapsed ? (_) {} : null,
                child: child!,
              ),
              child: TextField(focusNode: body),
            ),
          ),
        ),
      );
      body.requestFocus();
      await tester.pump();
      expect(body.hasPrimaryFocus, isTrue);

      collapsed.value = true;
      await tester.pumpAndSettle();
      expect(header.hasPrimaryFocus, isTrue);
    },
  );

  testWidgets('disabled header keeps expansion semantics without activation', (
    tester,
  ) async {
    await tester.pumpWidget(
      const YumeiroApp(
        home: Scaffold(
          body: YumeiroDisclosure(
            title: Text('Details'),
            expanded: false,
            onChanged: null,
            child: Text('Body'),
          ),
        ),
      ),
    );
    final header = find.text('Details');
    expect(
      tester.getSemantics(header),
      isSemantics(
        isButton: true,
        isEnabled: false,
        isExpanded: false,
        hasTapAction: false,
      ),
    );
    await tester.tap(header, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Body'), findsNothing);
  });
}
