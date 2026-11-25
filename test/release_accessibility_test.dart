import 'package:flutter/gestures.dart'
    show PointerDeviceKind, kSecondaryMouseButton;
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

void main() {
  testWidgets('icon actions have a name and show the tooltip on Tab', (
    tester,
  ) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await tester.pumpWidget(
      YumeiroApp(
        home: Scaffold(
          body: Column(
            children: [
              YumeiroButton(
                variant: YumeiroButtonVariant.ghost,
                icon: Icons.archive,
                semanticLabel: 'Archive document',
                tooltip: 'Archive explanation',
                focusNode: focus,
                onPressed: () {},
              ),
              YumeiroButton(label: 'Next', onPressed: () {}),
            ],
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Archive document'), findsOneWidget);
    expect(find.text('Archive explanation'), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(focus.hasFocus, isTrue);
    expect(find.text('Archive explanation'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(focus.hasFocus, isFalse);
    expect(find.text('Archive explanation'), findsNothing);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpAndSettle();
    expect(focus.hasFocus, isTrue);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: const Offset(500, 500));
    await mouse.moveTo(
      tester.getCenter(find.bySemanticsLabel('Archive document')),
    );
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(focus.hasFocus, isFalse);
    expect(find.text('Archive explanation'), findsOneWidget);

    await mouse.moveTo(const Offset(500, 500));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('Archive explanation'), findsNothing);
  });

  testWidgets('text buttons grow to fit large system text', (tester) async {
    await tester.pumpWidget(
      YumeiroApp(
        modality: YumeiroModality.touch,
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(4)),
            child: Scaffold(
              body: YumeiroButton(label: 'Continue', onPressed: () {}),
            ),
          ),
        ),
      ),
    );

    final button = tester.getSize(find.byType(YumeiroButton));
    expect(button.height, greaterThan(48));
    expect(
      tester.getSize(find.text('Continue')).height,
      lessThanOrEqualTo(button.height),
    );
    expect(find.bySemanticsLabel('Continue'), findsOneWidget);
  });

  testWidgets('searchable dropdown exposes its clear action in Tab order', (
    tester,
  ) async {
    final changes = <int?>[];
    var nextActions = 0;
    await tester.pumpWidget(
      YumeiroApp(
        locale: const Locale('en'),
        modality: YumeiroModality.pointer,
        home: Scaffold(
          body: Column(
            children: [
              YumeiroSelect<int>.searchable(
                value: 1,
                options: const [
                  YumeiroSelectionOption(value: 1, label: 'Alpha'),
                  YumeiroSelectionOption(value: 2, label: 'Beta'),
                ],
                clearable: true,
                onChanged: changes.add,
              ),
              YumeiroButton(label: 'Next', onPressed: () => nextActions++),
            ],
          ),
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(changes, [null]);
    expect(nextActions, 0);
  });

  testWidgets('disabling page search drops an open dialog result', (
    tester,
  ) async {
    final enabled = ValueNotifier(true);
    addTearDown(enabled.dispose);
    final queries = <String>[];
    await tester.pumpWidget(
      YumeiroApp(
        locale: const Locale('en'),
        home: Scaffold(
          body: ValueListenableBuilder(
            valueListenable: enabled,
            builder: (_, value, _) => YumeiroSearchScope(
              query: '',
              placeholder: 'Find titles',
              enabled: value,
              onSubmitted: queries.add,
              child: const YumeiroSearchButton(),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(YumeiroSearchButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'old title');
    enabled.value = false;
    await tester.pump();
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    expect(queries, isEmpty);

    enabled.value = true;
    await tester.pump();
    await tester.tap(find.byType(YumeiroSearchButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'new title');
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    expect(queries, ['new title']);
  });

  testWidgets('context menus support keyboard opening and restore focus', (
    tester,
  ) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    var activations = 0;
    await tester.pumpWidget(
      YumeiroApp(
        locale: const Locale('en'),
        modality: YumeiroModality.pointer,
        home: Scaffold(
          body: Center(
            child: YumeiroContextMenuRegion(
              menuBuilder: (_, _) => [
                YumeiroMenuAction(
                  label: 'Archive',
                  onPressed: () => activations++,
                ),
              ],
              child: YumeiroButton(
                label: 'Document',
                focusNode: focus,
                onPressed: () {},
              ),
            ),
          ),
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(focus.hasFocus, isTrue);
    for (final key in [
      LogicalKeyboardKey.contextMenu,
      LogicalKeyboardKey.f10,
    ]) {
      if (key == LogicalKeyboardKey.f10) {
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      }
      await tester.sendKeyEvent(key);
      if (key == LogicalKeyboardKey.f10) {
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      }
      await tester.pumpAndSettle();
      expect(find.text('Archive'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Archive'), findsNothing);
      expect(focus.hasFocus, isTrue);
    }
    tester.semantics.customAction(
      find.semantics.byLabel('Document'),
      const CustomSemanticsAction(label: 'More actions'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();
    expect(activations, 1);
  });

  testWidgets('data table uses a fallback stop only for text-only menu rows', (
    tester,
  ) async {
    final before = FocusNode();
    final cell = FocusNode();
    final after = FocusNode();
    addTearDown(before.dispose);
    addTearDown(cell.dispose);
    addTearDown(after.dispose);
    await tester.pumpWidget(
      YumeiroApp(
        modality: YumeiroModality.pointer,
        home: Scaffold(
          body: Column(
            children: [
              YumeiroButton(
                label: 'Before table',
                focusNode: before,
                onPressed: () {},
              ),
              YumeiroDataTable<String>(
                items: const ['Text record', 'Control record'],
                contextMenuBuilder: (_, item) => [
                  YumeiroMenuAction(label: 'Show actions for $item'),
                ],
                columns: [
                  YumeiroTableColumn(
                    title: 'Record',
                    cellBuilder: (_, item, index) => index == 0
                        ? Text(item)
                        : YumeiroButton(
                            label: item,
                            focusNode: cell,
                            onPressed: () {},
                          ),
                  ),
                ],
              ),
              YumeiroButton(
                label: 'After table',
                focusNode: after,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
    Future<void> tab() async {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
    }

    await tab();
    expect(before.hasPrimaryFocus, isTrue);
    await tab();
    final region = Focus.of(
      tester.element(find.text('Text record')),
      createDependency: false,
    );
    expect(region.hasPrimaryFocus, isTrue);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.f10);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpAndSettle();
    expect(find.text('Show actions for Text record'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(region.hasPrimaryFocus, isTrue);

    await tab();
    expect(cell.hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
    await tester.pumpAndSettle();
    expect(find.text('Show actions for Control record'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await tab();
    expect(after.hasPrimaryFocus, isTrue);
  });

  testWidgets('disabling a context menu keeps its child draft and focus', (
    tester,
  ) async {
    final enabled = ValueNotifier(true);
    addTearDown(enabled.dispose);
    await tester.pumpWidget(
      YumeiroApp(
        home: Scaffold(
          body: ValueListenableBuilder(
            valueListenable: enabled,
            child: const YumeiroTextField(),
            builder: (_, available, child) => YumeiroContextMenuRegion(
              enabled: available,
              focusable: true,
              menuBuilder: (_, _) => const [],
              child: child!,
            ),
          ),
        ),
      ),
    );
    final editable = find.byType(EditableText);
    await tester.enterText(editable, 'Unsaved draft');
    await tester.pumpAndSettle();
    enabled.value = false;
    await tester.pumpAndSettle();
    expect(
      tester.widget<EditableText>(editable).controller.text,
      'Unsaved draft',
    );
    expect(tester.widget<EditableText>(editable).focusNode.hasFocus, isTrue);
  });

  for (final modality in YumeiroModality.values) {
    testWidgets('disabling a context menu closes its open popup ($modality)', (
      tester,
    ) async {
      final enabled = ValueNotifier(true);
      addTearDown(enabled.dispose);
      var actions = 0;
      await tester.pumpWidget(
        YumeiroApp(
          modality: modality,
          home: Scaffold(
            body: ValueListenableBuilder(
              valueListenable: enabled,
              builder: (_, available, _) => YumeiroContextMenuRegion(
                enabled: available,
                menuBuilder: (_, _) => [
                  YumeiroMenuAction(
                    label: 'Mutate record',
                    onPressed: () => actions++,
                  ),
                ],
                child: const Text('Record'),
              ),
            ),
          ),
        ),
      );
      final target = find.text('Record');
      if (modality == YumeiroModality.pointer) {
        final gesture = await tester.startGesture(
          tester.getCenter(target),
          kind: PointerDeviceKind.mouse,
          buttons: kSecondaryMouseButton,
        );
        await gesture.up();
      } else {
        await tester.longPress(target);
      }
      await tester.pumpAndSettle();
      expect(find.text('Mutate record'), findsOneWidget);
      enabled.value = false;
      await tester.pumpAndSettle();
      expect(find.text('Mutate record'), findsNothing);
      expect(actions, 0);
    });
  }

  testWidgets('table keeps sort actions and provides full touch targets', (
    tester,
  ) async {
    var sortRequests = 0;
    var activations = 0;
    final choices = <Set<Key>>[];
    await tester.pumpWidget(
      YumeiroApp(
        modality: YumeiroModality.touch,
        home: Scaffold(
          body: YumeiroDataTable<String>(
            items: const ['Report'],
            rowKey: ValueKey.new,
            rowSemanticsLabel: (item) => 'Open $item',
            onRowTap: (_) => activations++,
            contextMenuBuilder: (_, _) => const [
              YumeiroMenuAction(label: 'Archive'),
            ],
            selection: YumeiroTableSelection(
              mode: YumeiroTableSelectionMode.multiple,
              selectedKeys: const {},
              onChanged: choices.add,
            ),
            columns: [
              YumeiroTableColumn(
                title: 'Name',
                titleWidget: YumeiroButton(
                  label: 'Sort by name',
                  onPressed: () => sortRequests++,
                ),
                cellBuilder: (_, item, _) => Text(item),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final table = tester.getSemantics(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.role == SemanticsRole.table,
      ),
    );
    final nodes = _semanticSubtree(table).toList();
    expect(nodes.where((node) => node.role == SemanticsRole.row), hasLength(2));
    final header = nodes.singleWhere(
      (node) => node.role == SemanticsRole.columnHeader,
    );
    expect(header.label, 'Name');
    final sort = _semanticSubtree(header)
        .singleWhere((node) => node.label == 'Sort by name');
    expect(sort.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    await tester.tap(find.text('Sort by name'));
    expect(sortRequests, 1);

    final checkboxes = find.byType(Checkbox);
    expect(checkboxes, findsNWidgets(2));
    for (var i = 0; i < 2; i++) {
      final size = tester.getSize(checkboxes.at(i));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    }
    await tester.tapAt(
      tester.getTopLeft(checkboxes.last) + const Offset(2, 24),
    );
    expect(choices, [
      {const ValueKey('Report')},
    ]);
    expect(activations, 0);
  });
}

Iterable<SemanticsNode> _semanticSubtree(SemanticsNode root) sync* {
  yield root;
  final children = <SemanticsNode>[];
  root.visitChildren((child) {
    children.add(child);
    return true;
  });
  for (final child in children) {
    yield* _semanticSubtree(child);
  }
}
