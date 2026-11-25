import 'package:flutter/rendering.dart' show BackdropFilterLayer;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

@immutable
class _TestCustomEffectPass extends YumeiroEffectPass {
  const _TestCustomEffectPass({
    required this.strength,
    required this.onPaint,
    super.id = 'test-custom',
    super.minCapability = YumeiroMaterialCapability.fullOptical,
  });

  final double strength;
  final VoidCallback onPaint;

  @override
  void paintForeground(
    Canvas canvas,
    Size size,
    OutlinedBorder shape,
    YumeiroMaterialCapability capability, {
    TextDirection? textDirection,
  }) {
    onPaint();
  }

  @override
  YumeiroEffectPass? lerp(YumeiroEffectPass? other, double t) {
    if (other is! _TestCustomEffectPass) {
      final next = strength * (1 - t);
      return next <= 0.01
          ? null
          : _TestCustomEffectPass(
              strength: next,
              onPaint: onPaint,
              id: id,
              minCapability: minCapability,
            );
    }
    return _TestCustomEffectPass(
      strength: strength + (other.strength - strength) * t,
      onPaint: onPaint,
      id: id,
      minCapability: minCapability,
    );
  }
}

void main() {
  group('Pluggable EffectPass & MaterialCapability tiering', () {
    test('full optical capability includes Gaussian blur', () {
      expect(
        YumeiroMaterialCapability.fullOptical.supports(
          YumeiroMaterialCapability.blurOnly,
        ),
        isTrue,
      );
      expect(
        YumeiroMaterialCapability.blurOnly.supports(
          YumeiroMaterialCapability.fullOptical,
        ),
        isFalse,
      );
    });

    test('YumeiroEffectStack interpolates custom passes by type and id', () {
      var painted = 0;
      final a = YumeiroEffectStack(
        extraPasses: [
          _TestCustomEffectPass(strength: 0.2, onPaint: () => painted++),
        ],
      );
      final b = YumeiroEffectStack(
        extraPasses: [
          _TestCustomEffectPass(strength: 0.8, onPaint: () => painted++),
        ],
      );

      final mid = a.lerp(b, 0.5);
      final pass = mid.passOf<_TestCustomEffectPass>();
      expect(pass, isNotNull);
      expect(pass!.strength, closeTo(0.5, 0.001));
      expect(painted, 0);
    });

    test('effect and shadow lists are immutable snapshots', () {
      final outer = <BoxShadow>[const BoxShadow(color: Colors.black)];
      final inner = <YumeiroInnerShadow>[
        const YumeiroInnerShadow(color: Colors.black),
      ];
      final passes = <YumeiroEffectPass>[
        YumeiroOuterShadowPass(outer),
        YumeiroInnerShadowPass(inner),
      ];
      final stack = YumeiroEffectStack.fromPasses(passes);
      final factoryStack = YumeiroEffectStack(
        outerShadows: outer,
        innerShadows: inner,
      );
      final indicator = YumeiroFocusIndicator(
        side: const BorderSide(),
        glow: outer,
      );
      final hash = stack.hashCode;

      outer.clear();
      inner.clear();
      passes.clear();
      expect(stack.hashCode, hash);
      expect(stack.passes, hasLength(2));
      expect(indicator.glow, hasLength(1));
      expect(indicator.glow.clear, throwsUnsupportedError);

      for (final effects in [
        stack,
        factoryStack,
        stack.lerp(YumeiroEffectStack.none, .5),
      ]) {
        expect(effects.outerShadows, hasLength(1));
        expect(effects.innerShadows, hasLength(1));
        expect(effects.passes.clear, throwsUnsupportedError);
        expect(effects.outerShadows.clear, throwsUnsupportedError);
        expect(effects.innerShadows.clear, throwsUnsupportedError);
      }
      final blendedGlow = indicator.lerp(YumeiroFocusIndicator.none, .5).glow;
      expect(blendedGlow.clear, throwsUnsupportedError);

      final cached = yumeiroThemeData();
      final cachedCard = cached
          .extension<YumeiroThemeExtension>()!
          .visuals
          .surface(YumeiroSurfaceRole.card)
          .effects;
      expect(cachedCard.outerShadows, isNotEmpty);
      expect(cachedCard.passes.clear, throwsUnsupportedError);
      expect(yumeiroThemeData(), same(cached));
    });

    final standardBlur = YumeiroEffectStack.fromPasses(const [
      YumeiroBackdropBlurPass(sigma: 2),
    ]);
    final opticalBlur = YumeiroEffectStack.fromPasses(const [
      YumeiroBackdropBlurPass(
        sigma: 20,
        minCapability: YumeiroMaterialCapability.fullOptical,
      ),
    ]);

    test('effect interpolation keeps each pass within its original tier', () {
      final outgoing = standardBlur.lerp(opticalBlur, .25);
      expect(outgoing.backdropBlur, 1);
      expect(
        outgoing.passes.single.minCapability,
        YumeiroMaterialCapability.blurOnly,
      );
      expect(standardBlur.lerp(opticalBlur, .5).passes, isEmpty);
      final incoming = standardBlur.lerp(opticalBlur, .75);
      expect(incoming.backdropBlur, 10);
      expect(
        incoming.passes.single.minCapability,
        YumeiroMaterialCapability.fullOptical,
      );
    });

    testWidgets('a restricted target cannot strengthen an animated blur', (
      tester,
    ) async {
      Future<void> paint(YumeiroEffectStack effects) => tester.pumpWidget(
        YumeiroApp(
          capability: YumeiroMaterialCapability.blurOnly,
          home: Center(
            child: YumeiroResolvedVisualSurface(
              appearance: YumeiroVisualAppearance(
                fill: const YumeiroSolidFill(Colors.transparent),
                foreground: Colors.white,
                shape: const RoundedRectangleBorder(),
                transition: const YumeiroVisualTransition(
                  duration: Duration(milliseconds: 200),
                  curve: Curves.linear,
                ),
                effects: effects,
              ),
              width: 100,
              height: 40,
              child: const SizedBox.shrink(),
            ),
          ),
        ),
      );

      double blur() => tester
          .widget<YumeiroGlassBackdrop>(find.byType(YumeiroGlassBackdrop))
          .blur;
      const midpoint = Duration(milliseconds: 100);

      await paint(standardBlur);
      expect(blur(), 2);
      await paint(opticalBlur);
      await tester.pump(midpoint);
      expect(blur(), closeTo(1, .01));
      await tester.pumpAndSettle();
      expect(blur(), 0);
      await paint(standardBlur);
      await tester.pump(midpoint);
      expect(blur(), closeTo(1, .01));
      await tester.pumpAndSettle();
      expect(blur(), 2);
    });

    testWidgets('capability gates core passes and keeps the glass fallback', (
      tester,
    ) async {
      final appearance = YumeiroVisualAppearance(
        fill: const YumeiroSolidFill(Colors.transparent),
        foreground: Colors.white,
        shape: const RoundedRectangleBorder(),
        transition: YumeiroVisualTransition.instant,
        opacity: .5,
        effects: YumeiroEffectStack.fromPasses([
          YumeiroOuterShadowPass(const [
            BoxShadow(blurRadius: 4),
          ], minCapability: YumeiroMaterialCapability.fullOptical),
          YumeiroInnerShadowPass(const [
            YumeiroInnerShadow(color: Colors.black, blurRadius: 4),
          ], minCapability: YumeiroMaterialCapability.fullOptical),
          const YumeiroBackdropBlurPass(
            sigma: 15,
            minCapability: YumeiroMaterialCapability.fullOptical,
          ),
          const YumeiroBackdropBlurPass(sigma: 8),
        ]),
      );
      Future<void> paint(YumeiroVisualAppearance appearance) =>
          tester.pumpWidget(
            YumeiroApp(
              capability: YumeiroMaterialCapability.blurOnly,
              home: Center(
                child: YumeiroResolvedVisualSurface(
                  appearance: appearance,
                  width: 100,
                  height: 40,
                  child: const SizedBox.shrink(),
                ),
              ),
            ),
          );

      await paint(appearance);
      YumeiroGlassBackdrop backdrop() => tester.widget<YumeiroGlassBackdrop>(
        find.byType(YumeiroGlassBackdrop),
      );
      expect(backdrop().blur, 4);
      final shadows = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .map((widget) => widget.decoration)
          .whereType<ShapeDecoration>()
          .expand((decoration) => decoration.shadows ?? const <BoxShadow>[]);
      expect(shadows, isEmpty);

      final glassAppearance = appearance.copyWith(
        effects: YumeiroEffectStack.fromPasses(const [
          YumeiroLiquidGlassPass(glass: YumeiroGlassEffect(tint: Colors.blue)),
        ]),
      );
      await paint(glassAppearance);
      expect(backdrop().capability, YumeiroMaterialCapability.blurOnly);
      expect(backdrop().glass!.intensity, .5);
      expect(tester.layers.whereType<BackdropFilterLayer>(), isNotEmpty);
    });

    testWidgets('capability tier gates custom passes with minCapability', (
      tester,
    ) async {
      var paintCount = 0;
      final customAppearance = YumeiroVisualAppearance(
        fill: const YumeiroSolidFill(Color(0xFF223344)),
        foreground: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        transition: YumeiroVisualTransition.instant,
        effects: YumeiroEffectStack(
          extraPasses: [
            _TestCustomEffectPass(
              strength: 1.0,
              minCapability: YumeiroMaterialCapability.fullOptical,
              onPaint: () => paintCount++,
            ),
          ],
        ),
      );

      // Under blurOnly capability, fullOptical pass must NOT run.
      await tester.pumpWidget(
        YumeiroScope(
          capability: YumeiroMaterialCapability.blurOnly,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: SizedBox(
                width: 100,
                height: 40,
                child: YumeiroResolvedVisualSurface(
                  appearance: customAppearance,
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        ),
      );
      expect(paintCount, 0);

      // Under fullOptical capability, fullOptical pass runs (if runtime supports shaders,
      // or check supports semantics directly if headless test runner lacks shader filter).
      await tester.pumpWidget(
        YumeiroScope(
          capability: YumeiroMaterialCapability.fullOptical,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: SizedBox(
                width: 100,
                height: 40,
                child: YumeiroResolvedVisualSurface(
                  appearance: customAppearance,
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        ),
      );
      if (YumeiroMaterialCapability.fullOptical.resolveForRuntime() ==
          YumeiroMaterialCapability.fullOptical) {
        expect(paintCount, greaterThan(0));
      }
    });

    testWidgets(
      'liquid glass backdrop degrades cleanly across capability tiers',
      (tester) async {
        for (final tier in YumeiroMaterialCapability.values) {
          await tester.pumpWidget(
            YumeiroScope(
              preset: YumeiroThemePresets.liquidGlassDark,
              capability: tier,
              child: const Material(
                type: MaterialType.transparency,
                child: Center(
                  child: YumeiroCard(child: Text('Glass Tier Test')),
                ),
              ),
            ),
          );
          expect(find.text('Glass Tier Test'), findsOneWidget);
        }
      },
    );
  });
}
