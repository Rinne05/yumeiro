import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yumeiro/yumeiro.dart';

void main() {
  group('Theme customization & option models', () {
    test(
      'pressScale customization adjusts control transition.pressedScale',
      () {
        final baseline = YumeiroThemeExtension.fromPreset(
          preset: YumeiroThemePresets.classicDark,
        );
        final baseScale = baseline.visuals
            .control(YumeiroControlRole.primary, const {})
            .transition
            .pressedScale;
        expect(baseScale, lessThan(1.0));

        final disabledPress = YumeiroThemeExtension.fromPreset(
          preset: YumeiroThemePresets.classicDark,
          customizations: const {'pressScale': 0},
        );
        expect(
          disabledPress.visuals
              .control(YumeiroControlRole.primary, const {})
              .transition
              .pressedScale,
          1.0,
        );

        final doubledPress = YumeiroThemeExtension.fromPreset(
          preset: YumeiroThemePresets.classicDark,
          customizations: const {'pressScale': 200},
        );
        expect(
          doubledPress.visuals
              .control(YumeiroControlRole.primary, const {})
              .transition
              .pressedScale,
          lessThan(baseScale),
        );
      },
    );

    test('customizations accent and borderColor apply to color tokens', () {
      const customAccent = Color(0xFFE11D48);
      const customBorder = Color(0xFF38BDF8);
      final tokens = YumeiroThemeExtension.fromPreset(
        preset: YumeiroThemePresets.classicDark,
        customizations: const {
          'accent': customAccent,
          'borderColor': customBorder,
        },
      );

      expect(tokens.accent, customAccent);
      expect(tokens.line.r, closeTo(customBorder.r, 0.01));
      expect(tokens.line.g, closeTo(customBorder.g, 0.01));
      expect(tokens.line.b, closeTo(customBorder.b, 0.01));
      expect(tokens.lineStrong.r, closeTo(customBorder.r, 0.01));
      expect(
        tokens.visuals.surface(YumeiroSurfaceRole.panel).outline.color.b,
        closeTo(customBorder.b, 0.01),
      );
    });

    test('YumeiroThemeChoiceOption, YumeiroMotionOptions, and mediaBackdropTone work', () {
      const choice = YumeiroThemeChoiceOption(
        id: 'surfaceStyle',
        label: 'Surface Style',
        defaultValue: 'soft',
        choices: {'soft': 'Soft', 'sharp': 'Sharp'},
      );
      expect(choice.resolve(const {'surfaceStyle': 'sharp'}), 'sharp');
      expect(choice.resolve(const {'surfaceStyle': 'invalid'}), 'soft');

      expect(YumeiroMotionOptions.values, isNotEmpty);
      const prefs = YumeiroMotionPreferences(
        enabled: true,
        options: {'posterTilt': false},
        pressScale: false,
      );
      expect(prefs.posterTilt, isFalse);
      expect(prefs.posterScale, isTrue);
      expect(prefs.controlPressScale, isFalse);

      expect(
        YumeiroThemePresets.classicDark.mediaBackdropTone,
        YumeiroMediaBackdropTone.cinematicDark,
      );
      expect(
        YumeiroThemePresets.classicLight.mediaBackdropTone,
        YumeiroMediaBackdropTone.airyLight,
      );
      expect(
        YumeiroThemePresets.liquidGlassLight.mediaBackdropTone,
        YumeiroMediaBackdropTone.airyLight,
      );
    });
  });

  group('Migrated components & accessibility fixes', () {
    testWidgets(
      'YumeiroLoadingCard & YumeiroSpinner render safely under tight constraints',
      (tester) async {
        final semantics = tester.ensureSemantics();
        const spinnerBoxKey = Key('constrained-spinner-box');
        await tester.pumpWidget(
          const YumeiroApp(
            home: Scaffold(
              body: Column(
                children: [
                  SizedBox(
                    key: spinnerBoxKey,
                    width: 12,
                    height: 32,
                    child: YumeiroSpinner(size: 24),
                  ),
                  Expanded(
                    child: YumeiroLoadingCard(message: 'Fetching catalog...'),
                  ),
                ],
              ),
            ),
          ),
        );

        final spinnerSize = tester.getSize(
          find.descendant(
            of: find.byKey(spinnerBoxKey),
            matching: find.byType(CircularProgressIndicator),
          ),
        );
        expect(spinnerSize.width, 12);
        expect(spinnerSize.height, 12);
        expect(find.text('Fetching catalog...'), findsOneWidget);
        expect(find.bySemanticsLabel('Fetching catalog...'), findsOneWidget);
        expect(
          tester.getSemantics(find.text('Fetching catalog...')),
          isSemantics(label: 'Fetching catalog...', isLiveRegion: true),
        );
        semantics.dispose();
      },
    );

    testWidgets(
      'YumeiroSwitch exposes semanticLabel and YumeiroToast supports custom icon',
      (tester) async {
        var closed = false;
        await tester.pumpWidget(
          YumeiroApp(
            home: Scaffold(
              body: Column(
                children: [
                  YumeiroSwitch(
                    value: true,
                    semanticLabel: 'Auto Play',
                    onChanged: (_) {},
                  ),
                  YumeiroToast(
                    title: 'Synced',
                    message: 'Saved 3 items',
                    icon: Icons.cloud_done_outlined,
                    statusRole: YumeiroStatusRole.success,
                    onClose: () => closed = true,
                  ),
                  Builder(
                    builder: (context) => YumeiroButton(
                      label: 'Fire',
                      onPressed: () => showYumeiroToast(
                        context,
                        'Custom Icon Toast',
                        icon: Icons.star_outline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.bySemanticsLabel('Auto Play'), findsOneWidget);
        expect(find.byIcon(Icons.cloud_done_outlined), findsOneWidget);
        await tester.tap(find.byIcon(YumeiroIconSet.material().close));
        expect(closed, isTrue);

        await tester.tap(find.text('Fire'));
        await tester.pump();
        expect(find.text('Custom Icon Toast'), findsOneWidget);
        expect(find.byIcon(Icons.star_outline), findsOneWidget);
      },
    );
  });

  group('Audit alignment regressions', () {
    testWidgets(
      'YumeiroDialog.show presents centered Dialog on compact touch',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          YumeiroApp(
            modality: YumeiroModality.touch,
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: YumeiroButton(
                    label: 'Open Dialog',
                    onPressed: () => YumeiroDialog.show<void>(
                      context: context,
                      builder: (_) => const YumeiroDialog(
                        title: 'Touch Modal',
                        child: Text('Centered content'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        expect(find.byType(Dialog), findsOneWidget);
        expect(find.byType(BottomSheet), findsNothing);
        expect(find.text('Touch Modal'), findsOneWidget);
      },
    );

    testWidgets(
      'YumeiroTooltip uses RawTooltip with visual surface and guards missing Overlay',
      (tester) async {
        await tester.pumpWidget(
          Theme(
            data: yumeiroThemeData(),
            child: const Directionality(
              textDirection: TextDirection.ltr,
              child: YumeiroTooltip(
                message: 'No overlay',
                child: Text('Plain'),
              ),
            ),
          ),
        );
        expect(find.byType(RawTooltip), findsNothing);
        expect(find.text('Plain'), findsOneWidget);

        await tester.pumpWidget(
          const YumeiroApp(
            home: Scaffold(
              body: Center(
                child: YumeiroTooltip(
                  message: 'Tooltip Surface',
                  triggerMode: TooltipTriggerMode.longPress,
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('Hover target'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.longPress(find.text('Hover target'));
        await tester.pumpAndSettle();

        expect(find.byType(RawTooltip), findsOneWidget);
        expect(find.text('Tooltip Surface'), findsOneWidget);
      },
    );

    testWidgets(
      'YumeiroTextField, YumeiroSegmentedControl, and YumeiroSwitch align behaviors',
      (tester) async {
        var switchValue = false;
        await tester.pumpWidget(
          YumeiroApp(
            home: Scaffold(
              body: Column(
                children: [
                  const YumeiroTextField(hintText: 'Title', enabled: false),
                  const YumeiroSegmentedControl<int>(
                    value: 1,
                    onChanged: null,
                    options: [
                      YumeiroSegmentOption(value: 0, label: 'One'),
                      YumeiroSegmentOption(value: 1, label: 'Two'),
                    ],
                  ),
                  StatefulBuilder(
                    builder: (context, setState) => YumeiroSwitch(
                      value: switchValue,
                      onChanged: (next) => setState(() => switchValue = next),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.byType(YumeiroResolvedVisualSurface), findsWidgets);
        expect(find.text('Two'), findsOneWidget);

        await tester.drag(find.byType(YumeiroSwitch), const Offset(30, 0));
        await tester.pumpAndSettle();
        expect(switchValue, isTrue);

        await tester.drag(find.byType(YumeiroSwitch), const Offset(-30, 0));
        await tester.pumpAndSettle();
        expect(switchValue, isFalse);
      },
    );

    testWidgets(
      'vertical segments share a themed frame and adapt their option rows',
      (tester) async {
        const options = [
          YumeiroSegmentOption(
            value: 'a',
            label: 'Alpha',
            subtitle: 'First option',
            icon: Icons.bolt_outlined,
          ),
          YumeiroSegmentOption(
            value: 'b',
            label: 'Beta',
            icon: Icons.layers_outlined,
            leading: Icon(Icons.favorite_border),
          ),
          YumeiroSegmentOption(value: 'c', label: 'Gamma', enabled: false),
        ];
        var selected = 'a';

        final shell = find.byWidgetPredicate(
          (widget) =>
              widget is YumeiroVisualSurface &&
              widget.role == YumeiroControlRole.secondary,
        );
        await tester.pumpWidget(
          YumeiroApp(
            modality: YumeiroModality.pointer,
            preset: YumeiroThemePresets.pixelDark,
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) =>
                    YumeiroSegmentedControl.vertical<String>(
                      options: options,
                      value: selected,
                      onChanged: (next) => setState(() => selected = next),
                    ),
              ),
            ),
          ),
        );
        expect(find.byType(YumeiroListTile), findsNothing);
        expect(find.text('First option'), findsOneWidget);
        expect(find.byIcon(Icons.favorite_border), findsOneWidget);
        expect(find.byIcon(Icons.layers_outlined), findsNothing);
        final checkmark = YumeiroTheme.of(tester.element(find.text('Alpha')))
            .icons
            .check;
        expect(find.byIcon(checkmark), findsOneWidget);
        expect(shell, findsOneWidget);
        await tester.tap(find.text('Beta'));
        await tester.pumpAndSettle();
        expect(selected, 'b');

        await tester.tap(find.text('Gamma'));
        await tester.pumpAndSettle();
        expect(selected, 'b');

        await tester.pumpWidget(
          YumeiroApp(
            modality: YumeiroModality.touch,
            preset: YumeiroThemePresets.pixelDark,
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) =>
                    YumeiroSegmentedControl.vertical<String>(
                      options: options,
                      value: selected,
                      onChanged: (next) => setState(() => selected = next),
                      showCheckmark: false,
                    ),
              ),
            ),
          ),
        );
        expect(shell, findsOneWidget);
        expect(
          find.descendant(of: shell, matching: find.byType(YumeiroListTile)),
          findsNWidgets(3),
        );
        final appearance = tester
            .widget<YumeiroResolvedVisualSurface>(
              find
                  .descendant(
                    of: shell,
                    matching: find.byType(YumeiroResolvedVisualSurface),
                  )
                  .first,
            )
            .appearance;
        expect(appearance.background.a, greaterThan(0));
        expect(appearance.outline.style, BorderStyle.solid);
        expect(appearance.shape, isA<YumeiroPixelBorder>());
        expect(find.text('First option'), findsOneWidget);
        expect(find.byIcon(Icons.favorite_border), findsOneWidget);
        expect(find.byIcon(Icons.layers_outlined), findsNothing);
        expect(find.byIcon(checkmark), findsNothing);
        await tester.tap(find.text('Alpha'));
        await tester.pumpAndSettle();
        expect(selected, 'a');

        await tester.tap(find.text('Gamma'));
        await tester.pumpAndSettle();
        expect(selected, 'a');
      },
    );

    testWidgets(
      'Fullscreen touch editor uses a canvas surface and scrolls body instructions',
      (tester) async {
        await tester.pumpWidget(
          YumeiroApp(
            modality: YumeiroModality.touch,
            home: Scaffold(
              body: Builder(
                builder: (context) => YumeiroButton(
                  label: 'Launch Touch Editor',
                  onPressed: () => YumeiroEditor.show<void>(
                    context: context,
                    fullscreenOnTouch: true,
                    builder: (_) => const YumeiroEditor(
                      title: 'Edit Rule',
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Adjust playback priority'),
                          Text('Editor Form'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Launch Touch Editor'));
        await tester.pumpAndSettle();

        final canvasFinder = find.ancestor(
          of: find.byType(YumeiroPageScaffold),
          matching: find.byWidgetPredicate(
            (w) =>
                w is YumeiroVisualSurface &&
                w.role == YumeiroSurfaceRole.canvas,
          ),
        );
        expect(canvasFinder, findsOneWidget);

        expect(
          find.descendant(
            of: find.byType(YumeiroScrollView),
            matching: find.text('Adjust playback priority'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'YumeiroSwitch toggles with Space and Enter keys when focused',
      (tester) async {
        var value = false;
        final focusNode = FocusNode();
        addTearDown(focusNode.dispose);

        await tester.pumpWidget(
          YumeiroApp(
            home: Scaffold(
              body: Center(
                child: StatefulBuilder(
                  builder: (context, setState) => YumeiroSwitch(
                    value: value,
                    focusNode: focusNode,
                    autofocus: true,
                    semanticLabel: 'Keyboard Switch',
                    onChanged: (next) => setState(() => value = next),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(focusNode.hasFocus, isTrue);

        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expect(value, isTrue);

        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(value, isFalse);
      },
    );
  });
}
