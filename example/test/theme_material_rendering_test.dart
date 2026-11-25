import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yumeiro/yumeiro.dart';

// Use integer-pixel translations for strict color comparisons. Fractional-DPR
// optical geometry has separate coverage in glass_scroll_edges_test.dart.
const _pixelRatio = 1.0;
const _background = Color(0xFF354963);
const _columns = 4;
const _tileSize = Size(384, 248);
const _sampleWidth = 112.0;
const _capabilities = [
  YumeiroMaterialCapability.fullOptical,
  YumeiroMaterialCapability.blurOnly,
];

class _Sample {
  _Sample({required this.control});

  final bool control;
  final referenceKey = GlobalKey();
  final scrolledKey = GlobalKey();
  final viewportKey = GlobalKey();
  final referenceWindowKey = GlobalKey();
  final candidateWindowKey = GlobalKey();
  final scroll = ScrollController();

  double get height => control ? 64 : 128;
  double get cropHeight => control ? 48 : 80;
  double get finalOffset => control ? 32 : 56;
  double get top => control ? 160 : 0;
  double get windowHeight => control ? 88 : 152;
  String get name => control ? 'neutral control' : 'panel';

  Widget material(GlobalKey key) => SizedBox(
    key: key,
    width: _sampleWidth,
    height: height,
    child: control
        ? YumeiroButton(
            customLeading: const SizedBox.shrink(),
            width: _sampleWidth,
            height: height,
            onPressed: () {},
          )
        : const YumeiroCard.panel(
            padding: EdgeInsets.zero,
            child: SizedBox.expand(),
          ),
  );

  Widget reference({required bool matchBackdropClip}) => Positioned(
    left: 0,
    top: top,
    width: 128,
    height: windowHeight,
    child: _window(
      key: referenceWindowKey,
      child: ClipRect(
        // A translucent material blurs its own outer shadow. Match that input
        // footprint so viewport-truncated shadows are not mistaken for a rim.
        clipper: matchBackdropClip
            ? _StaticSampleClip(Rect.fromLTWH(0, finalOffset, 128, cropHeight))
            : null,
        child: Stack(
          children: [
            Positioned(left: 8, top: 8, child: material(referenceKey)),
          ],
        ),
      ),
    ),
  );

  Widget cropped() => Positioned(
    left: 224,
    top: top,
    width: 128,
    height: windowHeight,
    child: _window(
      key: candidateWindowKey,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 8,
            height: cropHeight,
            child: SizedBox(
              key: viewportKey,
              child: SingleChildScrollView(
                controller: scroll,
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    material(scrolledKey),
                    const SizedBox(height: 320),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _window({required Key key, required Widget child}) => ClipRect(
  key: key,
  child: ColoredBox(
    color: _background,
    // A snapshot captured before another window painted its background must
    // not be reused here. Every sample has its own uniform backdrop.
    child: YumeiroGlassSamplingScope(child: child),
  ),
);

class _StaticSampleClip extends CustomClipper<Rect> {
  const _StaticSampleClip(this.rect);

  final Rect rect;

  @override
  Rect getClip(Size size) => rect;

  @override
  bool shouldReclip(_StaticSampleClip oldClipper) => rect != oldClipper.rect;
}

YumeiroVisualAppearance _appearance(ThemeData theme, _Sample sample) {
  final visuals = theme.extension<YumeiroThemeExtension>()!.visuals;
  return sample.control
      ? visuals.control(YumeiroControlRole.neutral, const {})
      : visuals.surface(YumeiroSurfaceRole.panel);
}

class _ThemeCase {
  _ThemeCase({
    required this.themeIndex,
    required this.gridIndex,
    required this.preset,
    required this.capability,
  });

  final int themeIndex;
  final int gridIndex;
  final YumeiroThemePreset preset;
  final YumeiroMaterialCapability capability;
  final panel = _Sample(control: false);
  final control = _Sample(control: true);
  final hiddenScroll = ScrollController();
  final hiddenViewportKey = GlobalKey();
  final hiddenPanelKey = GlobalKey();

  Iterable<_Sample> get samples => [panel, control];
  String get label => '${capability.name}/${preset.id}';

  late final Widget candidate = Stack(
    children: [
      for (final sample in samples) sample.cropped(),
      Positioned(
        left: 224,
        top: 104,
        width: 128,
        height: 48,
        child: SizedBox(
          key: hiddenViewportKey,
          child: SingleChildScrollView(
            controller: hiddenScroll,
            child: Column(
              children: [
                const SizedBox(height: 8),
                panel.material(hiddenPanelKey),
                const SizedBox(height: 320),
              ],
            ),
          ),
        ),
      ),
    ],
  );

  Widget build(int phase, List<ThemeData> themes) {
    final activeIndex = switch (phase) {
      1 => (themeIndex + 8) % themes.length,
      3 => (themeIndex + 13) % themes.length,
      _ => themeIndex,
    };
    return Positioned(
      left: (gridIndex % _columns) * _tileSize.width,
      top: (gridIndex ~/ _columns) * _tileSize.height,
      width: _tileSize.width,
      height: _tileSize.height,
      child: YumeiroMaterialCapabilityScope(
        capability: capability,
        child: _window(
          key: ValueKey('material-case-$label'),
          child: Stack(
            children: [
              if (phase == 4)
                Theme(
                  key: const ValueKey('reference'),
                  data: themes[themeIndex],
                  child: Stack(
                    children: [
                      for (final sample in samples)
                        sample.reference(
                          matchBackdropClip:
                              _appearance(
                                    themes[themeIndex],
                                    sample,
                                  ).effects.backdropBlur >
                                  0 &&
                              _appearance(
                                themes[themeIndex],
                                sample,
                              ).effects.outerShadows.isNotEmpty,
                        ),
                    ],
                  ),
                ),
              Theme(
                key: const ValueKey('candidate'),
                data: themes[activeIndex],
                child: candidate,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void dispose() {
    for (final sample in samples) {
      sample.scroll.dispose();
    }
    hiddenScroll.dispose();
  }
}

int _delta(ByteData pixels, int first, int second) {
  var result = 0;
  for (var channel = 0; channel < 4; channel++) {
    result = math.max(
      result,
      (pixels.getUint8(first + channel) - pixels.getUint8(second + channel))
          .abs(),
    );
  }
  return result;
}

int _backgroundDelta(ByteData pixels, int offset) {
  var result = 0;
  const channels = [53, 73, 99, 255];
  for (var channel = 0; channel < channels.length; channel++) {
    result = math.max(
      result,
      (pixels.getUint8(offset + channel) - channels[channel]).abs(),
    );
  }
  return result;
}

void main() {
  testWidgets(
    'all built-in materials retain local rendering after scroll and theme changes',
    (tester) async {
      final presets = YumeiroThemePresets.builtInValues;
      expect(presets, hasLength(24));
      expect(presets.map((preset) => preset.id).toSet(), hasLength(24));
      final rows = (presets.length * _capabilities.length / _columns).ceil();
      tester.view.physicalSize = Size(
        _columns * _tileSize.width * _pixelRatio,
        rows * _tileSize.height * _pixelRatio,
      );
      tester.view.devicePixelRatio = _pixelRatio;
      addTearDown(tester.view.reset);
      await tester.runAsync(YumeiroGlassBackdrop.warmUp);
      final themes = [
        for (final preset in presets) yumeiroThemeData(preset: preset),
      ];
      final cases = [
        for (final (capabilityIndex, capability) in _capabilities.indexed)
          for (var themeIndex = 0; themeIndex < presets.length; themeIndex++)
            _ThemeCase(
              themeIndex: themeIndex,
              gridIndex: capabilityIndex * presets.length + themeIndex,
              preset: presets[themeIndex],
              capability: capability,
            ),
      ];
      expect(cases, hasLength(48));
      for (final item in cases) {
        addTearDown(item.dispose);
      }
      final phase = ValueNotifier(0);
      addTearDown(phase.dispose);
      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        YumeiroApp(
          capability: YumeiroMaterialCapability.fullOptical,
          modality: YumeiroModality.pointer,
          home: RepaintBoundary(
            key: boundaryKey,
            child: ColoredBox(
              color: _background,
              child: ValueListenableBuilder<int>(
                valueListenable: phase,
                builder: (context, value, child) => Stack(
                  children: [
                    for (final item in cases) item.build(value, themes),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final retainedElements = {
        for (final item in cases)
          for (final sample in item.samples)
            sample: sample.scrolledKey.currentContext,
      };
      for (final fraction in [.25, 1.0, .5, 1.0]) {
        for (final item in cases) {
          for (final sample in item.samples) {
            sample.scroll.jumpTo(sample.finalOffset * fraction);
          }
          item.hiddenScroll.jumpTo(304 * fraction);
        }
        await tester.pumpAndSettle();
      }
      // Reuse the same surfaces through two different material families, then
      // mount fresh final-theme references that never joined those transitions.
      for (var value = 1; value <= 4; value++) {
        phase.value = value;
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      final windows = <Rect>[];
      final comparisons =
          <
            ({
              String label,
              String caseLabel,
              Rect region,
              Offset referenceShift,
            })
          >[];
      final hiddenRegions = <({String label, Rect region})>[];
      final textureSamples = <({String label, Offset origin})>[];
      var opticalSurfaces = 0;
      for (final item in cases) {
        final visuals = themes[item.themeIndex]
            .extension<YumeiroThemeExtension>()!
            .visuals;
        for (final sample in item.samples) {
          final reference = tester.getRect(find.byKey(sample.referenceKey));
          final scrolled = tester.getRect(find.byKey(sample.scrolledKey));
          final viewport = tester.getRect(find.byKey(sample.viewportKey));
          expect(scrolled.top, lessThan(viewport.top - 12));
          expect(scrolled.size, reference.size);
          expect(
            identical(
              sample.scrolledKey.currentContext,
              retainedElements[sample],
            ),
            isTrue,
          );
          expect(
            YumeiroTheme.of(sample.scrolledKey.currentContext!).presetId,
            item.preset.id,
          );
          expect(
            YumeiroMaterialCapabilityScope.of(
              sample.scrolledKey.currentContext!,
            ),
            item.capability,
          );
          final shift = reference.topLeft - scrolled.topLeft;
          expect(
            shift.dx * _pixelRatio,
            closeTo((shift.dx * _pixelRatio).round(), .0001),
          );
          expect(
            shift.dy * _pixelRatio,
            closeTo((shift.dy * _pixelRatio).round(), .0001),
          );
          comparisons.add((
            label: '${item.label} ${sample.name}',
            caseLabel: item.label,
            region: scrolled.intersect(viewport).deflate(.4),
            referenceShift: shift,
          ));
          if (!sample.control &&
              (item.preset.id == YumeiroThemePresetIds.brushedMetalLight ||
                  item.preset.id == YumeiroThemePresetIds.brushedMetalDark)) {
            textureSamples.add((
              label: item.label,
              origin: reference.topLeft + const Offset(56, 64),
            ));
          }
          windows.addAll([
            tester.getRect(find.byKey(sample.referenceWindowKey)),
            tester.getRect(find.byKey(sample.candidateWindowKey)),
          ]);
          final appearance = sample.control
              ? visuals.control(YumeiroControlRole.neutral, const {})
              : visuals.surface(YumeiroSurfaceRole.panel);
          if (item.capability == YumeiroMaterialCapability.fullOptical &&
              appearance.effects.glass != null) {
            opticalSurfaces += 2;
          }
        }
        final hidden = tester.getRect(find.byKey(item.hiddenViewportKey));
        expect(
          tester.getRect(find.byKey(item.hiddenPanelKey)).bottom,
          lessThan(hidden.top - 64),
        );
        hiddenRegions.add((label: item.label, region: hidden.deflate(.8)));
      }
      expect(comparisons, hasLength(96));
      expect(hiddenRegions, hasLength(48));
      expect(textureSamples, hasLength(4));
      expect(opticalSurfaces, greaterThan(0));
      expect(
        tester.layers
            .whereType<BackdropFilterLayer>()
            .where((layer) => layer.filter?.debugShortDescription == 'shader')
            .length,
        greaterThanOrEqualTo(opticalSurfaces),
      );
      for (final preset in [
        YumeiroThemePresets.brushedMetalLight,
        YumeiroThemePresets.brushedMetalDark,
      ]) {
        expect(
          themes[presets.indexOf(preset)]
              .extension<YumeiroThemeExtension>()!
              .visuals
              .surface(YumeiroSurfaceRole.panel)
              .effects
              .passes
              .whereType<YumeiroBrushedTexturePass>(),
          isNotEmpty,
        );
      }

      // Exactly one readback for the entire matrix. Multiple Impeller readbacks
      // can perturb retained filter layers and create screenshot-only artifacts.
      await tester.runAsync(() async {
        final image =
            await (boundaryKey.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage(pixelRatio: _pixelRatio);
        try {
          final pixels = (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          final failures = <String>[];
          final paintedByCase = <String, int>{};
          final allowed = Uint8List(image.width * image.height);
          for (final window in windows) {
            final bounds = window.inflate(.8);
            final left = (bounds.left * _pixelRatio).floor().clamp(
              0,
              image.width,
            );
            final right = (bounds.right * _pixelRatio).ceil().clamp(
              0,
              image.width,
            );
            final top = (bounds.top * _pixelRatio).floor().clamp(
              0,
              image.height,
            );
            final bottom = (bounds.bottom * _pixelRatio).ceil().clamp(
              0,
              image.height,
            );
            for (var y = top; y < bottom; y++) {
              allowed.fillRange(
                y * image.width + left,
                y * image.width + right,
                1,
              );
            }
          }
          for (final comparison in comparisons) {
            final shiftX = (comparison.referenceShift.dx * _pixelRatio).round();
            final shiftY = (comparison.referenceShift.dy * _pixelRatio).round();
            final region = comparison.region;
            var mismatches = 0;
            var maximumDelta = 0;
            var painted = 0;
            for (
              var y = (region.top * _pixelRatio).ceil();
              y < (region.bottom * _pixelRatio).floor();
              y++
            ) {
              for (
                var x = (region.left * _pixelRatio).ceil();
                x < (region.right * _pixelRatio).floor();
                x++
              ) {
                final offset = (y * image.width + x) * 4;
                final reference = ((y + shiftY) * image.width + x + shiftX) * 4;
                final delta = _delta(pixels, offset, reference);
                maximumDelta = math.max(maximumDelta, delta);
                if (delta > 2) mismatches++;
                if (_backgroundDelta(pixels, offset) > 2) painted++;
              }
            }
            paintedByCase.update(
              comparison.caseLabel,
              (value) => value + painted,
              ifAbsent: () => painted,
            );
            if (mismatches != 0) {
              failures.add(
                '${comparison.label}: $mismatches mismatched pixels, '
                'maximum delta $maximumDelta, $painted painted pixels',
              );
            }
          }
          // Liquid Glass's quiet panel can be indistinguishable from this
          // uniform backdrop. Its control must still render visible material.
          for (final entry in paintedByCase.entries) {
            if (entry.value <= 10) {
              failures.add('${entry.key}: no visible material');
            }
          }
          for (final texture in textureSamples) {
            final x = (texture.origin.dx * _pixelRatio).round();
            final firstY = (texture.origin.dy * _pixelRatio).round();
            var previousValue = 0;
            var previousStep = 0;
            var reversals = 0;
            for (var row = 0; row < 32; row++) {
              final offset = ((firstY + row) * image.width + x) * 4;
              final value =
                  pixels.getUint8(offset) +
                  pixels.getUint8(offset + 1) +
                  pixels.getUint8(offset + 2);
              final step = value - previousValue;
              if (row > 1 &&
                  step.abs() > 2 &&
                  previousStep.abs() > 2 &&
                  step * previousStep < 0) {
                reversals++;
              }
              previousValue = value;
              previousStep = step;
            }
            if (reversals <= 4) {
              failures.add(
                '${texture.label}: brushed grain must visibly alternate',
              );
            }
          }
          for (final hidden in hiddenRegions) {
            var changed = 0;
            for (
              var y = (hidden.region.top * _pixelRatio).ceil();
              y < (hidden.region.bottom * _pixelRatio).floor();
              y++
            ) {
              for (
                var x = (hidden.region.left * _pixelRatio).ceil();
                x < (hidden.region.right * _pixelRatio).floor();
                x++
              ) {
                if (_backgroundDelta(pixels, (y * image.width + x) * 4) > 2) {
                  changed++;
                }
              }
            }
            if (changed != 0) {
              failures.add('${hidden.label}: $changed residual pixels');
            }
          }
          var transparent = 0;
          var escaped = 0;
          for (var y = 0; y < image.height; y++) {
            for (var x = 0; x < image.width; x++) {
              final offset = (y * image.width + x) * 4;
              if (pixels.getUint8(offset + 3) != 255) transparent++;
              if (allowed[y * image.width + x] == 0 &&
                  _backgroundDelta(pixels, offset) > 2) {
                escaped++;
              }
            }
          }
          expect(
            transparent,
            0,
            reason: 'Opaque backgrounds must have no alpha holes.',
          );
          expect(
            escaped,
            0,
            reason: 'Material paint must stay inside its window.',
          );
          expect(failures, isEmpty, reason: failures.join('\n'));
        } finally {
          image.dispose();
        }
      });
      await tester.pumpWidget(const SizedBox.shrink());
    },
    // Run with flutter test --enable-impeller for native shader rendering.
    skip: !ui.ImageFilter.isShaderFilterSupported,
  );
}
