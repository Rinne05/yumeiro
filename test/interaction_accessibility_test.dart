import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

void main() {
  for (final modality in YumeiroModality.values) {
    for (final editor in [false, true]) {
      testWidgets(
        'default close honors a form guard ($modality, editor=$editor)',
        (tester) async {
          final canPop = ValueNotifier(false);
          addTearDown(canPop.dispose);
          var editorChecks = 0;
          final form = ValueListenableBuilder(
            valueListenable: canPop,
            builder: (_, allowed, child) =>
                Form(canPop: allowed, child: child!),
            child: const Text('Unsaved draft'),
          );
          await tester.pumpWidget(
            YumeiroApp(
              modality: modality,
              home: Scaffold(
                body: Builder(
                  builder: (context) => YumeiroButton(
                    label: 'Open draft',
                    onPressed: () {
                      if (editor) {
                        YumeiroEditor.show<void>(
                          context: context,
                          builder: (_) => YumeiroEditor(
                            title: 'Edit record',
                            onLeave: () async {
                              editorChecks++;
                              return true;
                            },
                            child: form,
                          ),
                        );
                      } else {
                        YumeiroDialog.show<void>(
                          context: context,
                          builder: (_) =>
                              YumeiroDialog(title: 'Edit record', child: form),
                        );
                      }
                    },
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Open draft'));
          await tester.pumpAndSettle();
          final close = find.byTooltip('Close');
          await tester.tap(close);
          await tester.pumpAndSettle();
          expect(find.text('Unsaved draft'), findsOneWidget);
          expect(editorChecks, editor ? 1 : 0);

          canPop.value = true;
          await tester.pump();
          await tester.tap(close);
          await tester.pumpAndSettle();
          expect(find.text('Unsaved draft'), findsNothing);
          expect(editorChecks, editor ? 2 : 0);
        },
      );
    }

    testWidgets(
      'editor approval only closes its own current route ($modality)',
      (tester) async {
        final pending = Completer<bool>();
        await tester.pumpWidget(
          YumeiroApp(
            modality: modality,
            home: Scaffold(
              body: Builder(
                builder: (context) => YumeiroButton(
                  label: 'Open editor',
                  onPressed: () => YumeiroEditor.show<void>(
                    context: context,
                    builder: (_) => YumeiroEditor(
                      title: 'Editor',
                      onLeave: () => pending.future,
                      child: const Text('Draft'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open editor'));
        await tester.pumpAndSettle();
        final navigator = Navigator.of(tester.element(find.text('Draft')));
        await navigator.maybePop();
        unawaited(
          navigator.push<void>(
            MaterialPageRoute(
              builder: (_) => const Scaffold(body: Text('Unrelated page')),
            ),
          ),
        );
        await tester.pumpAndSettle();
        pending.complete(true);
        await tester.pumpAndSettle();
        expect(find.text('Unrelated page'), findsOneWidget);

        navigator.pop();
        await tester.pumpAndSettle();
        expect(find.text('Draft'), findsOneWidget);
        await navigator.maybePop();
        await tester.pumpAndSettle();
        expect(find.text('Draft'), findsNothing);
        expect(find.text('Open editor'), findsOneWidget);
      },
    );

    for (final isSheet in [false, true]) {
      testWidgets('modal title names its route ($modality, sheet=$isSheet)', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        const title = 'Profile permissions';
        await tester.pumpWidget(
          YumeiroApp(
            modality: modality,
            home: Scaffold(
              body: Builder(
                builder: (context) => YumeiroButton(
                  label: 'Open modal',
                  onPressed: () {
                    if (isSheet) {
                      YumeiroBottomSheet.show<void>(
                        context: context,
                        builder: (_) => const YumeiroBottomSheet(
                          title: title,
                          child: Text('Content'),
                        ),
                      );
                    } else {
                      YumeiroDialog.show<void>(
                        context: context,
                        builder: (_) => const YumeiroDialog(
                          title: title,
                          child: Text('Content'),
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open modal'));
        await tester.pumpAndSettle();
        final titleData = tester
            .getSemantics(find.text(title))
            .getSemanticsData();
        semantics.dispose();
        expect(titleData.label, title);
        expect(titleData.flagsCollection.namesRoute, isTrue);
      });
    }
  }

  for (final barrierDismissible in [true, false]) {
    testWidgets(
      'touch editor respects the barrier setting and leave guard ($barrierDismissible)',
      (tester) async {
        tester.view.physicalSize = const Size(390, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        var leaveChecks = 0;
        var allowLeave = false;
        await tester.pumpWidget(
          YumeiroApp(
            modality: YumeiroModality.touch,
            home: Scaffold(
              body: Builder(
                builder: (context) => YumeiroButton(
                  label: 'Open editor',
                  onPressed: () => YumeiroEditor.show<void>(
                    context: context,
                    barrierDismissible: barrierDismissible,
                    builder: (_) => YumeiroEditor(
                      title: 'Editor',
                      onLeave: () async {
                        leaveChecks++;
                        return allowLeave;
                      },
                      child: const Text('Keep draft'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open editor'));
        await tester.pumpAndSettle();
        final draft = find.text('Keep draft');
        await tester.tapAt(const Offset(12, 12));
        await tester.pumpAndSettle();
        expect(draft, findsOneWidget);
        expect(leaveChecks, barrierDismissible ? 1 : 0);

        allowLeave = true;
        await Navigator.of(tester.element(draft)).maybePop();
        await tester.pumpAndSettle();
        expect(draft, findsNothing);
        expect(leaveChecks, barrierDismissible ? 2 : 1);
      },
    );
  }

  testWidgets('exiting toast can no longer be activated from focus', (
    tester,
  ) async {
    final controller = YumeiroToastController();
    addTearDown(controller.dispose);
    var actions = 0;
    await tester.pumpWidget(
      YumeiroApp(
        modality: YumeiroModality.pointer,
        home: YumeiroToastHost(controller: controller, child: const Scaffold()),
      ),
    );
    final id = controller.show(
      message: 'Action message',
      copyOnTap: false,
      duration: Duration.zero,
      onTap: () => actions++,
    );
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(actions, 1);

    controller.dismiss(id);
    await tester.pump();
    expect(controller.entries, isEmpty);
    expect(find.text('Action message'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(actions, 1);
  });

  testWidgets('toast only shows copied for a successful current write', (
    tester,
  ) async {
    final writes = <Completer<Object?>>[];
    final message = ValueNotifier('First text');
    addTearDown(message.dispose);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method != 'Clipboard.setData') return null;
        final write = Completer<Object?>();
        writes.add(write);
        return write.future;
      },
    );
    await tester.pumpWidget(
      YumeiroApp(
        home: Scaffold(
          body: ValueListenableBuilder(
            valueListenable: message,
            builder: (_, text, _) => YumeiroToast(message: text),
          ),
        ),
      ),
    );
    final toastContext = tester.element(find.byType(YumeiroToast));
    final copied = find.text(YumeiroLocalizations.of(toastContext).copied);

    await tester.tap(find.text('First text'));
    await tester.pumpAndSettle();
    expect(copied, findsNothing);
    writes.first.completeError(PlatformException(code: 'permission_denied'));
    await tester.pumpAndSettle();
    expect(copied, findsNothing);

    await tester.tap(find.text('First text'));
    await tester.pumpAndSettle();
    message.value = 'Updated text';
    await tester.pump();
    writes[1].complete();
    await tester.pumpAndSettle();
    expect(copied, findsNothing);

    await tester.tap(find.text('Updated text'));
    await tester.pumpAndSettle();
    expect(copied, findsNothing);
    writes[2].complete();
    await tester.pumpAndSettle();
    expect(copied, findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  testWidgets('accessible navigation defers tap actions until it is disabled', (
    tester,
  ) async {
    final controller = YumeiroToastController();
    final accessibleNavigation = ValueNotifier(false);
    addTearDown(controller.dispose);
    addTearDown(accessibleNavigation.dispose);
    await tester.pumpWidget(
      YumeiroApp(
        modality: YumeiroModality.pointer,
        builder: (context, child) => ValueListenableBuilder(
          valueListenable: accessibleNavigation,
          builder: (_, enabled, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(accessibleNavigation: enabled),
            child: child!,
          ),
          child: child,
        ),
        home: YumeiroToastHost(controller: controller, child: const Scaffold()),
      ),
    );

    final action = controller.show(
      message: 'Can undo',
      copyOnTap: false,
      onTap: () {},
    );
    controller.show(message: 'Informational only', copyOnTap: false);
    await tester.pumpAndSettle();
    accessibleNavigation.value = true;
    await tester.pump();
    final copy = controller.show(message: 'Can copy');
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(controller.entries.map((entry) => entry.id), [action, copy]);

    accessibleNavigation.value = false;
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(controller.entries.map((entry) => entry.id), [action, copy]);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(controller.entries, isEmpty);
  });

  testWidgets('only the foreground toast can receive focus on a short screen', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = YumeiroToastController();
    addTearDown(controller.dispose);
    final activated = <int>[];
    final ids = <int>[];
    await tester.pumpWidget(
      YumeiroApp(
        modality: YumeiroModality.touch,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            accessibleNavigation: true,
            textScaler: const TextScaler.linear(2),
          ),
          child: child!,
        ),
        home: YumeiroToastHost(controller: controller, child: const Scaffold()),
      ),
    );
    for (var number = 1; number <= 4; number++) {
      ids.add(
        controller.show(
          title: 'Attachment $number failed',
          message:
              'Unable to upload the selected file. Retry after reconnecting.',
          copyOnTap: false,
          onTap: () => activated.add(number),
        ),
      );
    }
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(YumeiroToast), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Attachment [123] failed')),
      findsNothing,
    );
    expect(find.text('Attachment 4 failed').hitTestable(), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(activated, [4]);

    controller.dismiss(ids.last);
    await tester.pumpAndSettle();
    expect(find.byType(YumeiroToast), findsOneWidget);
    expect(find.text('Attachment 3 failed').hitTestable(), findsOneWidget);
  });

  testWidgets('toast spacing lets pointer events reach the page below', (
    tester,
  ) async {
    final controller = YumeiroToastController();
    addTearDown(controller.dispose);
    var pageTaps = 0;
    var toastTaps = 0;
    await tester.pumpWidget(
      YumeiroApp(
        modality: YumeiroModality.pointer,
        home: YumeiroToastHost(
          controller: controller,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => pageTaps++,
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
    controller.show(
      message: 'Action message',
      copyOnTap: false,
      duration: Duration.zero,
      onTap: () => toastTaps++,
    );
    await tester.pumpAndSettle();
    final toast = tester.getRect(find.byType(YumeiroToast));

    await tester.tapAt(Offset(toast.center.dx, toast.bottom + 4));
    expect(pageTaps, 1);
    expect(toastTaps, 0);

    await tester.tap(find.text('Action message'));
    expect(pageTaps, 1);
    expect(toastTaps, 1);
  });

  for (final direction in TextDirection.values) {
    testWidgets('cascading forward key and icon follow $direction', (
      tester,
    ) async {
      await tester.pumpWidget(
        YumeiroApp(
          modality: YumeiroModality.pointer,
          home: Scaffold(
            body: Directionality(
              textDirection: direction,
              child: Center(
                child: SizedBox(
                  width: 400,
                  child: YumeiroCascadingSelection<String>(
                    value: null,
                    options: const [
                      YumeiroCascadingOption.branch(
                        id: 'branch',
                        label: 'Branch',
                        children: [
                          YumeiroCascadingOption(
                            id: 'leaf',
                            label: 'Leaf',
                            value: 'leaf',
                          ),
                        ],
                      ),
                    ],
                    onChanged: (_) {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final branch = find.text('Branch');
      final leaf = find.text('Leaf');
      final icons = YumeiroTheme.of(tester.element(branch)).icons;
      final rtl = direction == TextDirection.rtl;
      expect(
        find.byIcon(rtl ? icons.chevronLeft : icons.chevronRight),
        findsOneWidget,
      );
      expect(leaf, findsNothing);
      await tester.sendKeyEvent(
        rtl ? LogicalKeyboardKey.arrowLeft : LogicalKeyboardKey.arrowRight,
      );
      await tester.pumpAndSettle();
      expect(leaf, findsOneWidget);
      final branchX = tester.getCenter(branch).dx;
      expect(
        tester.getCenter(leaf).dx,
        rtl ? lessThan(branchX) : greaterThan(branchX),
      );
    });
  }

  for (final keyboard in [false, true]) {
    testWidgets('a third cascading column is reachable (keyboard=$keyboard)', (
      tester,
    ) async {
      final selected = <String>[];
      await tester.pumpWidget(
        YumeiroApp(
          modality: YumeiroModality.pointer,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 280,
                child: YumeiroCascadingSelection<String>(
                  value: null,
                  options: const [
                    YumeiroCascadingOption.branch(
                      id: 'root',
                      label: 'Root',
                      children: [
                        YumeiroCascadingOption.branch(
                          id: 'child',
                          label: 'Child',
                          children: [
                            YumeiroCascadingOption(
                              id: 'leaf',
                              label: 'Leaf',
                              value: 'leaf',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                  onChanged: selected.add,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (final label in ['Root', 'Child']) {
        if (keyboard) {
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        } else {
          await tester.tap(find.text(label));
        }
        await tester.pumpAndSettle();
      }

      final leaf = find.text('Leaf').hitTestable();
      expect(leaf, findsOneWidget);
      if (keyboard) {
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      } else {
        await tester.tap(leaf);
      }
      expect(selected, ['leaf']);
    });
  }

  testWidgets('checkbox tile semantics follows its keyboard focus', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final checked = ValueNotifier(false);
    addTearDown(checked.dispose);
    await tester.pumpWidget(
      YumeiroApp(
        modality: YumeiroModality.pointer,
        home: Scaffold(
          body: ValueListenableBuilder(
            valueListenable: checked,
            builder: (_, value, _) => YumeiroSelectionRow(
              card: true,
              title: const Text('Publish changes'),
              subtitle: const Text('Send a notification'),
              selected: value,
              onChanged: (next) => checked.value = next,
            ),
          ),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    final tile = find.byType(YumeiroSelectionRow);
    final focused = tester.getSemantics(tile).getSemanticsData();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    final selected = tester.getSemantics(tile).getSemanticsData();
    semantics.dispose();
    expect(focused.label, 'Publish changes\nSend a notification');
    expect(focused.flagsCollection.isFocused, ui.Tristate.isTrue);
    expect(focused.flagsCollection.isChecked, ui.CheckedState.isFalse);
    expect(selected.flagsCollection.isChecked, ui.CheckedState.isTrue);
  });

  testWidgets(
    'selection card keeps its trailing action and editor independent',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final editorFocus = FocusNode();
      addTearDown(editorFocus.dispose);
      var toggles = 0;
      var inspections = 0;
      await tester.pumpWidget(
        YumeiroApp(
          modality: YumeiroModality.pointer,
          home: Scaffold(
            body: YumeiroSelectionRow(
              title: const Text('Publish changes'),
              card: true,
              selected: false,
              onChanged: (_) => toggles++,
              trailing: YumeiroButton(
                label: 'Inspect',
                onPressed: () => inspections++,
              ),
              footer: YumeiroTextField(
                hintText: 'Note',
                focusNode: editorFocus,
              ),
            ),
          ),
        ),
      );

      final inspect = tester
          .getSemantics(find.bySemanticsLabel('Inspect'))
          .getSemanticsData();
      final note = tester
          .getSemantics(find.byType(EditableText))
          .getSemanticsData();
      semantics.dispose();
      expect(inspect.hasAction(ui.SemanticsAction.tap), isTrue);
      expect(note.flagsCollection.isTextField, isTrue);

      await tester.tap(find.text('Inspect'));
      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(inspections, 1);
      expect(editorFocus.hasFocus, isTrue);
      expect(toggles, 0);

      await tester.tap(find.text('Publish changes'));
      expect(toggles, 1);
    },
  );
}
