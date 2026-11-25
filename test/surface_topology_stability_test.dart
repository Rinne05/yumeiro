import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yumeiro/yumeiro.dart';

enum _ClickTiming { immediateAfterEnter, afterHoverSettled }

void main() {
  group('Widget tree topology stability on multi-frame mouse clicks', () {
    Future<void> verifyMouseClickStability(
      WidgetTester tester, {
      required YumeiroThemePreset preset,
      required Widget target,
      required int Function() readCount,
      required _ClickTiming timing,
    }) async {
      await tester.pumpWidget(
        YumeiroApp(
          preset: preset,
          modality: YumeiroModality.pointer,
          home: Scaffold(body: Center(child: target)),
        ),
      );
      await tester.pumpAndSettle();

      final inkWellFinder = find.descendant(
        of: find.byWidget(target),
        matching: find.byType(InkWell),
      );
      final restInkWell = tester.element(inkWellFinder);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer(location: Offset.zero);
      await tester.pump();

      final center = tester.getCenter(find.byWidget(target));
      await gesture.moveTo(center);
      if (timing == _ClickTiming.immediateAfterEnter) {
        await tester.pump();
      } else {
        await tester.pumpAndSettle();
      }

      expect(tester.takeException(), isNull);
      expect(
        tester.element(inkWellFinder),
        same(restInkWell),
        reason: '${preset.id} ($timing): InkWell element rebuilt on hover',
      );
      await gesture.down(center);
      for (var frame = 0; frame < 4; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(
          tester.takeException(),
          isNull,
          reason: '${preset.id} ($timing): exception at press frame $frame',
        );
        expect(
          tester.element(inkWellFinder),
          same(restInkWell),
          reason:
              '${preset.id} ($timing): InkWell unmounted at press frame $frame',
        );
      }

      await gesture.up();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        readCount(),
        1,
        reason: '${preset.id} ($timing): expected single click to trigger once',
      );
      expect(tester.element(inkWellFinder), same(restInkWell));
    }

    void testButton(
      YumeiroThemePreset preset,
      YumeiroButtonVariant variant,
      _ClickTiming timing,
    ) {
      testWidgets(
        '${preset.id} ${variant.name} button handles ${timing.name} click',
        (tester) async {
          var count = 0;
          await verifyMouseClickStability(
            tester,
            preset: preset,
            target: YumeiroButton(
              label: 'Action',
              icon: Icons.play_arrow_rounded,
              variant: variant,
              onPressed: () => count++,
            ),
            readCount: () => count,
            timing: timing,
          );
        },
      );
    }

    // Exercise every preset's state recipe. The same stable tap target wraps
    // all button variants, so one representative preset per other variant
    // is enough to cover the settled-hover path.
    for (final preset in YumeiroThemePresets.builtInValues) {
      testButton(
        preset,
        YumeiroButtonVariant.primary,
        _ClickTiming.immediateAfterEnter,
      );
    }
    final settledButtons = [
      (YumeiroThemePresets.classicLight, YumeiroButtonVariant.neutral),
      (YumeiroThemePresets.liquidGlassDark, YumeiroButtonVariant.secondary),
      (YumeiroThemePresets.frostedGlassDark, YumeiroButtonVariant.primary),
      (YumeiroThemePresets.neoBrutalistLight, YumeiroButtonVariant.danger),
      (YumeiroThemePresets.ceramicLight, YumeiroButtonVariant.ghost),
      (YumeiroThemePresets.pixelLight, YumeiroButtonVariant.mediaOverlay),
    ];
    for (final (preset, variant) in settledButtons) {
      testButton(preset, variant, _ClickTiming.afterHoverSettled);
    }

    final surfaces = [
      (YumeiroThemePresets.classicLight, YumeiroItemRole.navigation),
      (YumeiroThemePresets.liquidGlassDark, YumeiroItemRole.standard),
      (YumeiroThemePresets.ceramicLight, YumeiroControlRole.ghost),
      (YumeiroThemePresets.neumorphicLight, YumeiroControlRole.primary),
      (YumeiroThemePresets.pixelLight, YumeiroControlRole.secondary),
    ];
    for (final (preset, role) in surfaces) {
      for (final timing in _ClickTiming.values) {
        testWidgets('${preset.id} $role surface handles ${timing.name} click', (
          tester,
        ) async {
          var count = 0;
          await verifyMouseClickStability(
            tester,
            preset: preset,
            target: YumeiroInteractiveVisualSurface(
              role: role,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              onTap: () => count++,
              child: const Text('Interactive Item'),
            ),
            readCount: () => count,
            timing: timing,
          );
        });
      }
    }

    for (final preset in [
      YumeiroThemePresets.classicLight,
      YumeiroThemePresets.liquidGlassDark,
      YumeiroThemePresets.ceramicLight,
    ]) {
      testWidgets(
        '${preset.id} text field keeps its input across hover and focus',
        (tester) async {
          final focusNode = FocusNode();
          addTearDown(focusNode.dispose);
          await tester.pumpWidget(
            YumeiroApp(
              preset: preset,
              modality: YumeiroModality.pointer,
              home: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: 240,
                    child: YumeiroTextField(
                      focusNode: focusNode,
                      hintText: 'Search',
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final editableFinder = find.byType(EditableText);
          final restEditable = tester.element(editableFinder);

          final gesture = await tester.createGesture(
            kind: PointerDeviceKind.mouse,
          );
          addTearDown(gesture.removePointer);
          await gesture.addPointer(location: Offset.zero);
          await tester.pump();

          final center = tester.getCenter(find.byType(YumeiroTextField));
          await gesture.moveTo(center);
          await gesture.down(center);
          for (var frame = 0; frame < 4; frame++) {
            await tester.pump(const Duration(milliseconds: 16));
            expect(tester.takeException(), isNull);
            expect(tester.element(editableFinder), same(restEditable));
          }
          await gesture.up();
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(focusNode.hasFocus, isTrue);
          expect(tester.element(editableFinder), same(restEditable));
        },
      );
    }

    testWidgets(
      'YumeiroButton with tooltip keeps InkWell element across enabled/disabled transitions',
      (tester) async {
        var enabled = true;
        var count = 0;
        late StateSetter setHostState;
        await tester.pumpWidget(
          YumeiroApp(
            preset: YumeiroThemePresets.liquidGlassDark,
            modality: YumeiroModality.pointer,
            home: Scaffold(
              body: Center(
                child: StatefulBuilder(
                  builder: (context, setState) {
                    setHostState = setState;
                    return YumeiroButton(
                      label: 'Toggleable',
                      tooltip: 'Tooltip',
                      variant: YumeiroButtonVariant.primary,
                      onPressed: enabled ? () => count++ : null,
                    );
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final inkWellFinder = find.descendant(
          of: find.byType(YumeiroButton),
          matching: find.byType(InkWell),
        );
        final initialInkWell = tester.element(inkWellFinder);

        setHostState(() => enabled = false);
        await tester.pumpAndSettle();
        expect(tester.element(inkWellFinder), same(initialInkWell));
        await tester.tap(find.byType(YumeiroButton));
        expect(count, 0);

        setHostState(() => enabled = true);
        await tester.pumpAndSettle();
        expect(tester.element(inkWellFinder), same(initialInkWell));

        await tester.tap(find.byType(YumeiroButton));
        await tester.pumpAndSettle();
        expect(count, 1);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
