import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yumeiro/yumeiro.dart';

void main() {
  for (final modality in YumeiroModality.values) {
    for (final direction in TextDirection.values) {
      testWidgets(
        'page subtitle aligns beside the back action in $modality $direction',
        (tester) async {
          var returned = false;
          await tester.pumpWidget(
            YumeiroApp(
              modality: modality,
              home: Directionality(
                textDirection: direction,
                child: Scaffold(
                  body: YumeiroNavigationScope(
                    onBack: () => returned = true,
                    child: const YumeiroPageHeader(
                      title: 'Notifications',
                      subtitle: 'Choose delivery times.',
                    ),
                  ),
                ),
              ),
            ),
          );
          final heading = tester.getRect(find.text('Notifications'));
          final subtitle = tester.getRect(find.text('Choose delivery times.'));
          if (direction == TextDirection.ltr) {
            expect(heading.left, closeTo(subtitle.left, .01));
          } else {
            expect(heading.right, closeTo(subtitle.right, .01));
          }
          expect(subtitle.top, greaterThanOrEqualTo(heading.bottom));
          await tester.tap(find.byType(YumeiroButton));
          expect(returned, isTrue);
        },
      );
    }
  }

  testWidgets('pointer dialog uses matching header and footer padding', (
    tester,
  ) async {
    await tester.pumpWidget(
      const YumeiroApp(
        modality: YumeiroModality.pointer,
        density: YumeiroDensity.standard,
        home: Scaffold(
          body: YumeiroDialog(
            title: 'Edit workspace',
            actions: [YumeiroButton(label: 'Confirm', onPressed: null)],
            child: Text('Dialog body'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final surface = find.byWidgetPredicate(
      (widget) =>
          widget is YumeiroVisualSurface &&
          widget.role == YumeiroSurfaceRole.modal,
    );
    final dialog = tester.getRect(surface);
    final dividers = find.byType(Divider);
    final heading = tester.getRect(find.text('Edit workspace'));
    final close = tester.getRect(find.byType(YumeiroButton).first);
    final action = tester.getRect(
      find.widgetWithText(YumeiroButton, 'Confirm'),
    );
    final headerBottom = tester.getTopLeft(dividers.first).dy;
    final footerTop = tester.getBottomLeft(dividers.last).dy;

    expect(heading.center.dy, closeTo(close.center.dy, .01));
    expect(close.top - dialog.top, closeTo(8, .01));
    expect(headerBottom - close.bottom, closeTo(8, .01));
    expect(action.top - footerTop, closeTo(8, .01));
    expect(dialog.bottom - action.bottom, closeTo(8, .01));
  });

  testWidgets(
    'narrow pointer dialog places its accessory below the close row',
    (tester) async {
      await tester.pumpWidget(
        const YumeiroApp(
          modality: YumeiroModality.pointer,
          home: Scaffold(
            body: YumeiroDialog(
              maxWidth: 320,
              title: 'Edit workspace',
              headerAccessory: Text('Draft'),
              child: Text('Dialog body'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final heading = tester.getRect(find.text('Edit workspace'));
      final close = tester.getRect(find.byType(YumeiroButton));
      final accessory = tester.getRect(find.text('Draft'));

      expect(heading.center.dy, closeTo(close.center.dy, .01));
      expect(accessory.top, greaterThanOrEqualTo(close.bottom));
      expect(accessory.left, closeTo(heading.left, .01));
    },
  );

  testWidgets('touch dialog aligns the heading, accessory, body, and footer', (
    tester,
  ) async {
    await tester.pumpWidget(
      YumeiroApp(
        modality: YumeiroModality.touch,
        home: Scaffold(
          body: YumeiroDialog(
            title: 'Edit workspace',
            headerAccessory: const Text('Draft'),
            actions: [YumeiroButton(label: 'Save', onPressed: () {})],
            child: const Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text('Dialog body'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final start = tester.getTopLeft(find.text('Edit workspace')).dx;
    expect(tester.getTopLeft(find.text('Draft')).dx, closeTo(start, .01));
    expect(tester.getTopLeft(find.text('Dialog body')).dx, closeTo(start, .01));
    expect(
      tester.getTopLeft(find.widgetWithText(YumeiroButton, 'Save')).dx,
      closeTo(start, .01),
    );
  });

  testWidgets('ordinary list and settings rows align in the same group', (
    tester,
  ) async {
    for (final modality in YumeiroModality.values) {
      await tester.pumpWidget(
        YumeiroApp(
          modality: modality,
          home: const Scaffold(
            body: YumeiroSettingsSection(
              title: 'Preferences',
              children: [
                YumeiroSettingRow(
                  leading: Icon(Icons.tune),
                  title: 'Setting',
                  subtitle: 'Setting details',
                ),
                YumeiroListTile(
                  leading: Icon(Icons.settings),
                  title: Text('List item'),
                  subtitle: Text('List details'),
                ),
              ],
            ),
          ),
        ),
      );
      final setting = tester.getRect(find.text('Setting'));
      final settingDetails = tester.getRect(find.text('Setting details'));
      final tile = tester.getRect(find.text('List item'));
      final tileDetails = tester.getRect(find.text('List details'));

      expect(setting.left, closeTo(tile.left, .01));
      expect(setting.height, closeTo(tile.height, .01));
      expect(
        settingDetails.top - setting.bottom,
        closeTo(tileDetails.top - tile.bottom, .01),
      );
    }
  });

  test(
    'declared options normalize persisted values before material construction',
    () {
      for (final family in YumeiroThemeFamilies.builtInValues) {
        for (final preset in family.variants.values) {
          for (final option in preset.options) {
            final Object value = switch (option) {
              YumeiroThemeNumberOption() => option.max.toInt(),
              YumeiroThemeColorOption() => '#778899',
              _ => option.initialValue,
            };
            final raw = yumeiroThemeData(
              preset: preset,
              customizations: {option.id: value},
            );
            final normalized = yumeiroThemeData(
              preset: preset,
              customizations: {
                option.id: option.resolve({option.id: value}),
              },
            );
            final rawTheme = raw.extension<YumeiroThemeExtension>()!;
            final normalizedTheme = normalized
                .extension<YumeiroThemeExtension>()!;
            expect(
              rawTheme.visuals
                  .surface(YumeiroSurfaceRole.panel)
                  .fill
                  .fallbackColor,
              normalizedTheme.visuals
                  .surface(YumeiroSurfaceRole.panel)
                  .fill
                  .fallbackColor,
              reason: '${preset.id}/${option.id}',
            );
            final rawFill = rawTheme.visuals
                .surface(YumeiroSurfaceRole.panel)
                .fill;
            final normalizedFill = normalizedTheme.visuals
                .surface(YumeiroSurfaceRole.panel)
                .fill;
            expect(rawFill.runtimeType, normalizedFill.runtimeType);
            if (rawFill case YumeiroGradientFill(:final gradient)) {
              expect(
                gradient,
                (normalizedFill as YumeiroGradientFill).gradient,
                reason: '${preset.id}/${option.id} gradient',
              );
            }
          }
        }
      }
    },
  );

  for (final kind in ['dialog', 'sheet', 'editor', 'menu']) {
    testWidgets(
      '$kind preserves local configuration across the root route boundary',
      (tester) async {
        final registry = YumeiroThemeRegistry.defaultInstance.copy();
        BuildContext? opened;
        Widget content(BuildContext context) {
          opened = context;
          return const YumeiroDialog(title: 'content');
        }

        await tester.pumpWidget(
          YumeiroApp(
            modality: YumeiroModality.touch,
            home: YumeiroScope(
              modality: YumeiroModality.pointer,
              density: YumeiroDensity.compact,
              capability: YumeiroMaterialCapability.blurOnly,
              registry: registry,
              locale: const Locale('zh'),
              child: Builder(
                builder: (context) => TextButton(
                  onPressed: () {
                    switch (kind) {
                      case 'dialog':
                        YumeiroDialog.show(context: context, builder: content);
                      case 'sheet':
                        YumeiroBottomSheet.show(
                          context: context,
                          builder: content,
                        );
                      case 'editor':
                        YumeiroEditor.show(context: context, builder: content);
                      case 'menu':
                        YumeiroActionMenu.show(
                          context: context,
                          globalPosition: const Offset(80, 80),
                          items: [const YumeiroMenuAction(label: 'menu-entry')],
                        );
                    }
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        final context = kind == 'menu'
            ? tester.element(find.text('menu-entry'))
            : opened!;
        expect(
          YumeiroModalityScope.modalityOf(context),
          YumeiroModality.pointer,
        );
        expect(YumeiroModalityScope.densityOf(context), YumeiroDensity.compact);
        expect(
          YumeiroMaterialCapabilityScope.of(context),
          YumeiroMaterialCapability.blurOnly,
        );
        expect(YumeiroThemeRegistryScope.of(context), same(registry));
        expect(YumeiroLocalizations.of(context).close, '关闭');
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        registry.dispose();
      },
    );
  }

  testWidgets('open dialog follows shared application configuration changes', (
    tester,
  ) async {
    var modality = YumeiroModality.pointer;
    var locale = const Locale('en');
    StateSetter? update;
    BuildContext? dialog;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (_, setState) {
          update = setState;
          return YumeiroApp(
            modality: modality,
            locale: locale,
            capability: modality == YumeiroModality.touch
                ? YumeiroMaterialCapability.blurOnly
                : YumeiroMaterialCapability.fullOptical,
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () => YumeiroDialog.show(
                  context: context,
                  builder: (context) {
                    dialog = context;
                    return const YumeiroDialog(title: 'live');
                  },
                ),
                child: const Text('open'),
              ),
            ),
          );
        },
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    update!(() {
      modality = YumeiroModality.touch;
      locale = const Locale('zh');
    });
    await tester.pumpAndSettle();
    expect(YumeiroModalityScope.modalityOf(dialog!), YumeiroModality.touch);
    expect(
      YumeiroMaterialCapabilityScope.of(dialog!),
      YumeiroMaterialCapability.blurOnly,
    );
    expect(YumeiroLocalizations.of(dialog!).close, '关闭');
  });

  testWidgets('leave completion is harmless after editor disposal', (
    tester,
  ) async {
    final pending = Completer<bool>();
    await tester.pumpWidget(
      YumeiroApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => YumeiroEditor.show(
              context: context,
              builder: (_) => YumeiroEditor(
                title: 'edit',
                onLeave: () => pending.future,
                child: const Text('draft'),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final context = tester.element(find.text('draft'));
    await Navigator.of(context).maybePop();
    await tester.pumpWidget(const SizedBox());
    pending.complete(true);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'touch dense controls accept taps near the edge of their minimum targets',
    (tester) async {
      var count = 0;
      await tester.pumpWidget(
        YumeiroApp(
          modality: YumeiroModality.touch,
          home: Scaffold(
            body: Column(
              children: [
                YumeiroButton(
                  semanticLabel: 'Add item',
                  key: const ValueKey('button'),
                  icon: Icons.add,
                  dense: true,
                  onPressed: () => count++,
                ),
                YumeiroSegmentedControl<int>(
                  dense: true,
                  value: 0,
                  onChanged: (_) => count++,
                  options: const [
                    YumeiroSegmentOption(value: 0, label: 'segment'),
                  ],
                ),
                YumeiroSegmentedControl.vertical<int>(
                  key: const ValueKey('vertical-segmented-control'),
                  dense: true,
                  value: 0,
                  onChanged: (_) => count++,
                  options: const [
                    YumeiroSegmentOption(value: 0, label: 'vertical'),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      for (final finder in [
        find.byKey(const ValueKey('button')),
        find.byType(YumeiroSegmentedControl<int>),
        find.byKey(const ValueKey('vertical-segmented-control')),
      ]) {
        final rect = tester.getRect(finder);
        expect(rect.height, greaterThanOrEqualTo(48));
        await tester.tapAt(Offset(rect.center.dx, rect.top + 2));
        await tester.pump();
      }
      expect(count, 3);
    },
  );

  testWidgets('long labels and trailing controls fit narrow scaled layouts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const label = '很长的中文和LongUnbrokenEnglishTextWithoutSpaces0123456789';
    await tester.pumpWidget(
      YumeiroApp(
        modality: YumeiroModality.touch,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              YumeiroChip(label: label, onTap: () {}),
              YumeiroSettingRow(
                title: label,
                trailing: YumeiroButton(
                  label: 'trailing control',
                  onPressed: () {},
                ),
              ),
              YumeiroSlider(value: .5, onChanged: (_) {}, valueLabel: label),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  for (final modality in YumeiroModality.values) {
    testWidgets(
      'setting input keeps its focused draft when wrapping $modality',
      (tester) async {
        tester.view.physicalSize = const Size(760, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        const title = 'Bind account';
        const input = YumeiroTextField(width: 300, initialValue: '3');
        final touch = modality == YumeiroModality.touch;
        await tester.pumpWidget(
          YumeiroApp(
            modality: modality,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: Scaffold(
              body: YumeiroSettingRow(
                title: title,
                trailing: touch ? input : null,
                editor: touch ? null : input,
                editorMaxWidth: 300,
              ),
            ),
          ),
        );
        final field = find.byType(YumeiroTextField);
        final heading = find.text(title);
        expect(tester.getCenter(field).dy, tester.getCenter(heading).dy);
        final headingHeight = tester.getSize(heading).height;

        final editable = find.byType(EditableText);
        await tester.enterText(editable, '17');
        await tester.pumpAndSettle();
        for (final width in [460.0, 440.0, 760.0]) {
          tester.view.physicalSize = Size(width, 900);
          await tester.pumpAndSettle();
          final draft = tester.widget<EditableText>(editable);
          expect(draft.controller.text, '17');
          expect(draft.focusNode.hasFocus, isTrue);
          expect(tester.getSize(heading).height, headingHeight);
          if (width < 760) {
            expect(
              tester.getTopLeft(field).dy,
              greaterThanOrEqualTo(tester.getBottomLeft(heading).dy),
            );
          } else {
            expect(tester.getCenter(field).dy, tester.getCenter(heading).dy);
          }
          expect(tester.takeException(), isNull);
        }
      },
    );
  }

  testWidgets('context menu closes and completes when its source route exits', (
    tester,
  ) async {
    late BuildContext home;
    var completed = false;
    await tester.pumpWidget(
      YumeiroApp(
        modality: YumeiroModality.pointer,
        home: Builder(
          builder: (context) {
            home = context;
            return const Scaffold();
          },
        ),
      ),
    );
    final navigator = Navigator.of(home);
    navigator.push(
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () {
              YumeiroActionMenu.show(
                context: context,
                globalPosition: const Offset(60, 60),
                items: [const YumeiroMenuAction(label: 'owned-menu')],
              ).then((_) => completed = true);
            },
            child: const Text('open-owned-menu'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('open-owned-menu'));
    await tester.pumpAndSettle();
    expect(find.text('owned-menu'), findsOneWidget);
    navigator.pop();
    await tester.pumpAndSettle();
    expect(find.text('owned-menu'), findsNothing);
    expect(completed, isTrue);
  });

  testWidgets('context menu completes during navigator teardown', (
    tester,
  ) async {
    var completed = false;
    await tester.pumpWidget(
      YumeiroApp(
        modality: YumeiroModality.pointer,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () {
              YumeiroActionMenu.show(
                context: context,
                globalPosition: const Offset(60, 60),
                items: [const YumeiroMenuAction(label: 'teardown-menu')],
              ).then((_) => completed = true);
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(completed, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('removing the context menu region closes its menu', (
    tester,
  ) async {
    var visible = true;
    late StateSetter update;
    await tester.pumpWidget(
      YumeiroApp(
        modality: YumeiroModality.pointer,
        home: StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return Scaffold(
              body: visible
                  ? YumeiroContextMenuRegion(
                      menuBuilder: (_, _) => [
                        const YumeiroMenuAction(label: 'region-menu'),
                      ],
                      child: const SizedBox(
                        width: 150,
                        height: 100,
                        child: Text('region'),
                      ),
                    )
                  : const SizedBox(),
            );
          },
        ),
      ),
    );
    await tester.tap(
      find.text('region'),
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();
    expect(find.text('region-menu'), findsOneWidget);
    update(() => visible = false);
    await tester.pumpAndSettle();
    expect(find.text('region-menu'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final modality in YumeiroModality.values) {
    testWidgets(
      'editor $modality closes without waiting for a frame when unguarded',
      (tester) async {
        var closed = false;
        await tester.pumpWidget(
          YumeiroApp(
            modality: modality,
            home: YumeiroEditor(
              title: 'edit',
              onClose: () => closed = true,
              child: const Text('draft'),
            ),
          ),
        );
        await tester.tap(
          find.byTooltip(modality == YumeiroModality.touch ? 'Back' : 'Close'),
        );
        expect(closed, isTrue);
      },
    );

    testWidgets(
      'editor $modality serializes leave checks and honors rejection and busy',
      (tester) async {
        final navigator = GlobalKey<NavigatorState>();
        var busy = false;
        var calls = 0;
        var pending = Completer<bool>();
        StateSetter? update;
        await tester.pumpWidget(
          YumeiroApp(
            modality: modality,
            home: Navigator(
              key: navigator,
              onGenerateRoute: (_) => MaterialPageRoute<void>(
                builder: (_) => const Scaffold(body: Text('home')),
              ),
            ),
          ),
        );
        navigator.currentState!.push(
          MaterialPageRoute<void>(
            builder: (_) => StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return YumeiroEditor(
                  title: 'edit',
                  busy: busy,
                  onLeave: () {
                    calls++;
                    return pending.future;
                  },
                  child: const Text('draft'),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byTooltip(modality == YumeiroModality.touch ? 'Back' : 'Close'),
        );
        await navigator.currentState!.maybePop();
        expect(calls, 1);
        pending.complete(false);
        await tester.pumpAndSettle();
        expect(find.text('draft'), findsOneWidget);
        busy = true;
        update!(() {});
        await tester.pump();
        await navigator.currentState!.maybePop();
        expect(calls, 1);
        busy = false;
        pending = Completer<bool>();
        update!(() {});
        await tester.pump();
        await navigator.currentState!.maybePop();
        expect(calls, 2);
        pending.complete(true);
        await tester.pumpAndSettle();
        expect(find.text('draft'), findsNothing);
        expect(find.text('home'), findsOneWidget);
      },
    );
  }
}
