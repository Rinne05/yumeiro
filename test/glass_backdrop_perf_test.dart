import 'dart:async' show Completer;
import 'dart:ui' show FragmentProgram, ImageFilter;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yumeiro/src/primitives/glass_backdrop.dart'
    show debugSetYumeiroGlassShaderLoader;
import 'package:yumeiro/yumeiro.dart';

Future<void> _settleGlass(WidgetTester tester) async {
  await tester.runAsync(YumeiroGlassBackdrop.warmUp);
  await tester.pump();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'glass paints Gaussian fallback before and after an optical loading failure',
    (tester) async {
      final loading = Completer<FragmentProgram>();
      var requests = 0;
      debugSetYumeiroGlassShaderLoader(() {
        requests++;
        return loading.future;
      });
      addTearDown(() => debugSetYumeiroGlassShaderLoader(null));

      Widget app(Key key) => MaterialApp(
        home: Center(
          child: SizedBox(
            width: 120,
            height: 60,
            child: YumeiroGlassBackdrop(
              key: key,
              glass: const YumeiroGlassEffect(tint: Colors.blue, intensity: .5),
              blur: 0,
              tint: null,
              shape: const RoundedRectangleBorder(),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );
      void expectGaussian() {
        final layers = tester.layers.whereType<BackdropFilterLayer>();
        expect(
          layers.map((layer) => layer.filter),
          contains(ImageFilter.blur(sigmaX: 7, sigmaY: 7)),
        );
      }

      await tester.pumpWidget(app(const ValueKey(1)));
      expect(requests, 1);
      expectGaussian();

      final errors = <FlutterErrorDetails>[];
      final oldErrorHandler = FlutterError.onError;
      FlutterError.onError = errors.add;
      try {
        loading.completeError(StateError('Unusable liquid-glass shader'));
        await tester.pumpAndSettle();
      } finally {
        FlutterError.onError = oldErrorHandler;
      }
      expect(errors.single.exception, isA<StateError>());
      expectGaussian();

      await tester.pumpWidget(app(const ValueKey(2)));
      await tester.pumpAndSettle();
      expectGaussian();
      expect(requests, 1);
    },
    skip: !ImageFilter.isShaderFilterSupported,
  );

  testWidgets(
    'glass tolerates singular transforms, negative radii, extra shapes, and pass switches',
    (tester) async {
      await tester.runAsync(YumeiroGlassBackdrop.warmUp);
      var scale = 1.0;
      var blur = 0.0;
      OutlinedBorder shape = const RoundedSuperellipseBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
      );
      late StateSetter change;
      await tester.pumpWidget(
        MaterialApp(
          theme: yumeiroThemeData(preset: YumeiroThemePresets.liquidGlassLight),
          home: StatefulBuilder(
            builder: (context, setState) {
              change = setState;
              return Center(
                child: Transform.scale(
                  scale: scale,
                  child: SizedBox(
                    width: 160,
                    height: 60,
                    child: YumeiroVisualSurface(
                      role: YumeiroControlRole.secondary,
                      visualOverride: YumeiroVisualOverride(
                        base: YumeiroVisualDelta(
                          shape: shape,
                          effects: YumeiroEffectStack(
                            backdropBlur: blur,
                            glass: const YumeiroGlassEffect(
                              tint: Colors.white,
                              refraction: 14,
                            ),
                          ),
                        ),
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await _settleGlass(tester);
      expect(tester.takeException(), isNull);

      change(() => scale = 0.0);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      change(() {
        scale = 1.0;
        blur = 18.0;
        shape = const ContinuousRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(-8)),
        );
      });
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      change(() => blur = 0.0);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'optical glass isolates its input inside translucent Opacity layers',
    (tester) async {
      await tester.pumpWidget(
        YumeiroMaterialCapabilityScope(
          capability: YumeiroMaterialCapability.fullOptical,
          child: MaterialApp(
            theme: yumeiroThemeData(
              preset: YumeiroThemePresets.liquidGlassLight,
            ),
            home: Stack(
              children: [
                const Positioned.fill(child: ColoredBox(color: Colors.amber)),
                Center(
                  child: Opacity(
                    opacity: 0.5,
                    child: SizedBox(
                      width: 140,
                      height: 60,
                      child: YumeiroVisualSurface(
                        role: YumeiroControlRole.secondary,
                        visualOverride: YumeiroVisualOverride(
                          base: YumeiroVisualDelta(
                            effects: YumeiroEffectStack(
                              glass: const YumeiroGlassEffect(
                                tint: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await _settleGlass(tester);
      if (ImageFilter.isShaderFilterSupported) {
        final layers = tester.layers.whereType<BackdropFilterLayer>().toList();
        expect(layers, hasLength(2));
        expect(layers.first.blendMode, BlendMode.srcOver);
        expect(layers.last.blendMode, BlendMode.src);
      }
      expect(tester.takeException(), isNull);
    },
  );

  for (final modality in YumeiroModality.values) {
    testWidgets(
      'input action group shares a backdrop key across inputs and action modality=$modality',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: yumeiroThemeData(
              preset: YumeiroThemePresets.liquidGlassLight,
              modality: modality,
            ),
            home: YumeiroModalityScope(
              modality: modality,
              child: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: 640,
                    child: YumeiroInputActionGroup(
                      inputs: const [
                        YumeiroTextField(hintText: 'A'),
                        YumeiroTextField(hintText: 'B'),
                      ],
                      action: YumeiroButton(label: 'Submit', onPressed: () {}),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await _settleGlass(tester);
        final inputScopes = find
            .byType(YumeiroTextField)
            .evaluate()
            .map((e) => YumeiroGlassSamplingScope.maybeOf(e)?.backdropKey)
            .toList();
        final buttonScope = YumeiroGlassSamplingScope.maybeOf(
          tester.element(find.byType(YumeiroButton)),
        )?.backdropKey;
        expect(inputScopes, hasLength(2));
        expect(inputScopes[0], isNotNull);
        expect(inputScopes[1], same(inputScopes[0]));
        expect(buttonScope, same(inputScopes[0]));
      },
    );
  }

  for (final showBackground in [false, true]) {
    testWidgets(
      'action bar shares a backdrop key across primary and secondary actions showBackground=$showBackground',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: yumeiroThemeData(
              preset: YumeiroThemePresets.liquidGlassLight,
              modality: YumeiroModality.touch,
            ),
            home: YumeiroModalityScope(
              modality: YumeiroModality.touch,
              child: Scaffold(
                body: YumeiroActionBar(
                  showBackground: showBackground,
                  primaryAction: YumeiroButton(
                    label: 'Primary',
                    variant: YumeiroButtonVariant.primary,
                    onPressed: () {},
                  ),
                  secondaryActions: [
                    YumeiroButton(label: 'Secondary 1', onPressed: () {}),
                    YumeiroButton(label: 'Secondary 2', onPressed: () {}),
                  ],
                ),
              ),
            ),
          ),
        );
        await _settleGlass(tester);
        final keys = find
            .byType(YumeiroButton)
            .evaluate()
            .map((e) => YumeiroGlassSamplingScope.maybeOf(e)?.backdropKey)
            .toList();
        expect(keys, hasLength(3));
        expect(keys[0], isNotNull);
        expect(keys[1], same(keys[0]));
        expect(keys[2], same(keys[0]));
      },
    );
  }

  testWidgets('dialog actions share a backdrop key', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: yumeiroThemeData(
          preset: YumeiroThemePresets.liquidGlassLight,
          modality: YumeiroModality.pointer,
        ),
        home: YumeiroModalityScope(
          modality: YumeiroModality.pointer,
          child: Scaffold(
            body: YumeiroDialog(
              title: 'Confirm',
              actions: [
                YumeiroButton(label: 'Cancel', onPressed: () {}),
                YumeiroButton(
                  label: 'OK',
                  variant: YumeiroButtonVariant.primary,
                  onPressed: () {},
                ),
              ],
              child: const SizedBox(width: 240, height: 80),
            ),
          ),
        ),
      ),
    );
    await _settleGlass(tester);
    final cancelKey = YumeiroGlassSamplingScope.maybeOf(
      tester.element(find.widgetWithText(YumeiroButton, 'Cancel')),
    )?.backdropKey;
    final okKey = YumeiroGlassSamplingScope.maybeOf(
      tester.element(find.widgetWithText(YumeiroButton, 'OK')),
    )?.backdropKey;
    expect(cancelKey, isNotNull);
    expect(okKey, same(cancelKey));
  });

  testWidgets('desktop table row cells share a single backdrop key per row', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: yumeiroThemeData(
          preset: YumeiroThemePresets.liquidGlassLight,
          modality: YumeiroModality.pointer,
        ),
        home: YumeiroModalityScope(
          modality: YumeiroModality.pointer,
          child: Scaffold(
            body: SizedBox(
              width: 900,
              child: YumeiroDataTable<int>(
                selection: YumeiroTableSelection(
                  mode: YumeiroTableSelectionMode.multiple,
                  selectedKeys: {const ValueKey(0)},
                  onChanged: (_) {},
                ),
                columns: [
                  YumeiroTableColumn<int>(
                    title: 'A',
                    cellBuilder: (_, item, _) =>
                        YumeiroButton(label: 'A$item', onPressed: () {}),
                  ),
                  YumeiroTableColumn<int>(
                    title: 'B',
                    cellBuilder: (_, item, _) =>
                        YumeiroButton(label: 'B$item', onPressed: () {}),
                  ),
                ],
                items: const [0, 1],
              ),
            ),
          ),
        ),
      ),
    );
    await _settleGlass(tester);
    final a0 = YumeiroGlassSamplingScope.maybeOf(
      tester.element(find.widgetWithText(YumeiroButton, 'A0')),
    )?.backdropKey;
    final b0 = YumeiroGlassSamplingScope.maybeOf(
      tester.element(find.widgetWithText(YumeiroButton, 'B0')),
    )?.backdropKey;
    final a1 = YumeiroGlassSamplingScope.maybeOf(
      tester.element(find.widgetWithText(YumeiroButton, 'A1')),
    )?.backdropKey;
    expect(a0, isNotNull);
    expect(b0, same(a0));
    expect(a1, isNotNull);
    expect(a1, isNot(same(a0)));
  });

  testWidgets(
    'search and selection toolbars share backdrop keys across controls',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: yumeiroThemeData(
            preset: YumeiroThemePresets.liquidGlassLight,
            modality: YumeiroModality.touch,
          ),
          home: YumeiroModalityScope(
            modality: YumeiroModality.touch,
            child: Scaffold(
              body: Column(
                children: [
                  YumeiroSearchToolbar(
                    query: '',
                    onQueryChanged: (_) {},
                    onFilter: () {},
                    onSort: () {},
                  ),
                  YumeiroSelectionToolbar(
                    selectedCount: 2,
                    onClose: () {},
                    onSelectAll: () {},
                    actions: [
                      YumeiroButton(label: 'Cache', onPressed: () {}),
                      YumeiroButton(label: 'Delete', onPressed: () {}),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await _settleGlass(tester);
      final searchKey = YumeiroGlassSamplingScope.maybeOf(
        tester.element(
          find.byWidgetPredicate((widget) => widget is YumeiroTextField),
        ),
      )?.backdropKey;
      final filterKey = YumeiroGlassSamplingScope.maybeOf(
        tester.element(find.byTooltip('Filter')),
      )?.backdropKey;
      final sortKey = YumeiroGlassSamplingScope.maybeOf(
        tester.element(find.byTooltip('Sort')),
      )?.backdropKey;
      expect(searchKey, isNotNull);
      expect(filterKey, same(searchKey));
      expect(sortKey, same(searchKey));

      final actionA = YumeiroGlassSamplingScope.maybeOf(
        tester.element(find.widgetWithText(YumeiroButton, 'Cache')),
      )?.backdropKey;
      final actionB = YumeiroGlassSamplingScope.maybeOf(
        tester.element(find.widgetWithText(YumeiroButton, 'Delete')),
      )?.backdropKey;
      expect(actionA, isNotNull);
      expect(actionB, same(actionA));
      expect(actionA, isNot(same(searchKey)));
    },
  );

  testWidgets(
    'resolved visual surface does not schedule effect ticks when mounted or when effects are unchanged',
    (tester) async {
      var foreground = Colors.black;
      late StateSetter update;
      await tester.pumpWidget(
        MaterialApp(
          theme: yumeiroThemeData(preset: YumeiroThemePresets.liquidGlassLight),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                final base = YumeiroTheme.of(context).visuals
                    .control(YumeiroControlRole.secondary, const {});
                return Center(
                  child: YumeiroResolvedVisualSurface(
                    appearance: base.copyWith(foreground: foreground),
                    child: const Text('Static'),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await _settleGlass(tester);
      expect(tester.binding.hasScheduledFrame, isFalse);

      update(() => foreground = Colors.red);
      await tester.pump();
      // Only foreground changed (effects and fill/outline did not change),
      // so no effect-stack animation frame should be scheduled.
      expect(tester.binding.hasScheduledFrame, isFalse);
    },
  );

  testWidgets(
    'modal dismiss omits zero-sigma BackdropFilter at progress zero',
    (tester) async {
      late BuildContext root;
      await tester.pumpWidget(
        MaterialApp(
          theme: yumeiroThemeData(preset: YumeiroThemePresets.liquidGlassLight),
          home: Builder(
            builder: (context) {
              root = context;
              return const SizedBox.expand();
            },
          ),
        ),
      );
      YumeiroDialog.show<void>(
        context: root,
        builder: (_) => const YumeiroDialog(
          title: 'Dialog',
          child: SizedBox(width: 100, height: 100),
        ),
      );
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(YumeiroDialog));
      final route = ModalRoute.of(context)!;
      final reverseZero = _FixedReverseZeroAnimation();
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(800, 600)),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: route.buildTransitions(
              context,
              reverseZero,
              kAlwaysDismissedAnimation,
              const SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(BackdropFilter), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('modal dismiss reuses fixed blur filter while fading', (
    tester,
  ) async {
    final key = GlobalKey();
    late BuildContext root;
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          theme: yumeiroThemeData(preset: YumeiroThemePresets.liquidGlassLight),
          home: Scaffold(
            backgroundColor: const Color(0xFF00AAFF),
            body: Builder(
              builder: (context) {
                root = context;
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      ),
    );
    YumeiroDialog.show<void>(
      context: root,
      builder: (_) => const SizedBox(width: 40, height: 40),
    );
    await tester.pumpAndSettle();
    final openingFilter = tester
        .widget<BackdropFilter>(find.byType(BackdropFilter))
        .filter;

    final width =
        tester.view.physicalSize.width ~/ tester.view.devicePixelRatio;
    final offset = (10 * width + 10) * 4;

    Navigator.of(root, rootNavigator: true).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 110));

    final halfBackdrop = find.byType(BackdropFilter);
    expect(halfBackdrop, findsOneWidget);
    expect(
      identical(
        tester.widget<BackdropFilter>(halfBackdrop).filter,
        openingFilter,
      ),
      isTrue,
    );

    final byteData = await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final bytes = await image.toByteData();
      image.dispose();
      return bytes;
    });
    expect(byteData, isNotNull);
    final r = byteData!.getUint8(offset);
    final g = byteData.getUint8(offset + 1);
    final b = byteData.getUint8(offset + 2);
    final a = byteData.getUint8(offset + 3);
    // Corner pixel (10, 10) must stay opaque tinted blue over 0xFF00AAFF.
    expect(a, 255);
    expect(b, greaterThan(g));
    expect(b, greaterThan(r));

    await tester.pump(const Duration(milliseconds: 50));
    final quarterBackdrop = find.byType(BackdropFilter);
    expect(quarterBackdrop, findsOneWidget);
    expect(
      identical(
        tester.widget<BackdropFilter>(quarterBackdrop).filter,
        openingFilter,
      ),
      isTrue,
    );
    await tester.pumpAndSettle();
    expect(find.byType(BackdropFilter), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _FixedReverseZeroAnimation extends Animation<double> {
  @override
  double get value => 0;

  @override
  AnimationStatus get status => AnimationStatus.reverse;

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}

  @override
  void addStatusListener(AnimationStatusListener listener) {}

  @override
  void removeStatusListener(AnimationStatusListener listener) {}
}
