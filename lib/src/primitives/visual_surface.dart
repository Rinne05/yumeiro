import 'package:flutter/foundation.dart' show listEquals;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/scheduler.dart';

import '../foundation/input.dart';
import '../theme/effect_pass.dart';
import '../theme/semantic_visuals.dart';
import '../theme/theme.dart';
import '../theme/visual_role.dart';
import 'glass_backdrop.dart';
import 'visual_scope.dart';

/// Shared renderer for semantic fill, shape, outline, pluggable [YumeiroEffectPass]
/// execution, backdrop blur/glass, and keyboard focus indication.
class YumeiroVisualSurface extends StatelessWidget {
  const YumeiroVisualSurface({
    super.key,
    required this.role,
    required this.child,
    this.states = const <WidgetState>{},
    this.visualOverride,
    this.padding,
    this.visualInsets,
    this.clipBehavior = Clip.none,
  });

  final YumeiroVisualRole role;
  final Set<WidgetState> states;
  final YumeiroVisualOverride? visualOverride;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  /// Inset for the painted surface while the child keeps its layout footprint.
  final EdgeInsetsGeometry? visualInsets;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final visualTheme = YumeiroTheme.of(context).visuals;
    final scope = YumeiroVisualScope.maybeOf(context);
    final effectiveRole = switch (role) {
      YumeiroSurfaceRole() => scope?.surfaceRole ?? role,
      YumeiroControlRole() => scope?.controlRole ?? role,
      YumeiroItemRole() => scope?.itemRole ?? role,
    };
    final effectiveOverride = visualOverride ?? scope?.visualOverride;
    final appearance = visualTheme.resolveRole(
      effectiveRole,
      states,
      effectiveOverride,
    );
    return YumeiroResolvedVisualSurface(
      appearance: appearance,
      padding: padding,
      visualInsets: visualInsets,
      clipBehavior: clipBehavior,
      child: child,
    );
  }
}

Widget _surfaceContent(Widget child) => YumeiroGlassSamplingScope(child: child);

Widget _layoutSurfaceContent({
  required BuildContext context,
  required YumeiroVisualAppearance appearance,
  required Widget child,
  double? width,
  double? height,
  BoxConstraints? constraints,
  AlignmentGeometry? alignment,
  EdgeInsetsGeometry? padding,
}) => AnimatedContainer(
  duration: MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : appearance.transition.duration,
  curve: appearance.transition.curve,
  width: width,
  height: height,
  constraints: constraints,
  alignment: alignment,
  padding: padding,
  child: IconTheme.merge(
    data: IconThemeData(color: appearance.foreground),
    child: DefaultTextStyle.merge(
      style: TextStyle(color: appearance.foreground),
      child: _surfaceContent(child),
    ),
  ),
);

Widget _insetSurface({
  required BuildContext context,
  required YumeiroVisualAppearance appearance,
  required EdgeInsetsGeometry visualInsets,
  required Widget child,
  double? width,
  double? height,
  BoxConstraints? constraints,
  AlignmentGeometry? alignment,
  EdgeInsetsGeometry? padding,
  Clip clipBehavior = Clip.none,
}) {
  return Stack(
    fit: StackFit.passthrough,
    children: [
      Positioned.fill(
        child: IgnorePointer(
          child: Padding(
            padding: visualInsets,
            child: YumeiroResolvedVisualSurface(
              appearance: appearance,
              clipBehavior: clipBehavior,
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
      AnimatedOpacity(
        opacity: appearance.opacity,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : appearance.transition.duration,
        curve: appearance.transition.curve,
        child: _layoutSurfaceContent(
          context: context,
          appearance: appearance,
          width: width,
          height: height,
          constraints: constraints,
          alignment: alignment,
          padding: padding,
          child: child,
        ),
      ),
    ],
  );
}

/// Interactive adapter for semantic item/control surfaces.
///
/// Owns the focus, hover, press, and semantics for one activation target
/// while the caller owns selection.
class YumeiroInteractiveVisualSurface extends StatefulWidget {
  const YumeiroInteractiveVisualSurface({
    super.key,
    required this.role,
    required this.child,
    required this.onTap,
    this.selected = false,
    this.visualOverride,
    this.padding,
    this.focusNode,
    this.autofocus = false,
    this.mouseCursor,
    this.visualInsets,
  });

  final YumeiroVisualRole role;
  final Widget child;

  /// Activation callback. Null marks the surface disabled.
  final VoidCallback? onTap;

  /// Current selection state, supplied and updated by the caller.
  final bool selected;
  final YumeiroVisualOverride? visualOverride;
  final EdgeInsetsGeometry? padding;
  final FocusNode? focusNode;
  final bool autofocus;
  final MouseCursor? mouseCursor;
  final EdgeInsetsGeometry? visualInsets;

  @override
  State<YumeiroInteractiveVisualSurface> createState() =>
      _YumeiroInteractiveVisualSurfaceState();
}

class _YumeiroInteractiveVisualSurfaceState
    extends State<YumeiroInteractiveVisualSurface> {
  late final WidgetStatesController _statesController;
  bool _stateRefreshScheduled = false;

  @override
  void initState() {
    super.initState();
    _statesController = WidgetStatesController(_baseStates)
      ..addListener(_handleStateChange);
  }

  Set<WidgetState> get _baseStates => <WidgetState>{
    if (widget.selected) WidgetState.selected,
    if (widget.onTap == null) WidgetState.disabled,
  };

  @override
  void didUpdateWidget(covariant YumeiroInteractiveVisualSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    _statesController
      ..update(WidgetState.selected, widget.selected)
      ..update(WidgetState.disabled, widget.onTap == null);
  }

  void _handleStateChange() {
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      if (_stateRefreshScheduled) return;
      _stateRefreshScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _stateRefreshScheduled = false;
        if (mounted) setState(() {});
      });
    } else if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _statesController
      ..removeListener(_handleStateChange)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = YumeiroVisualScope.maybeOf(context);
    final role = switch (widget.role) {
      YumeiroSurfaceRole() => scope?.surfaceRole ?? widget.role,
      YumeiroControlRole() => scope?.controlRole ?? widget.role,
      YumeiroItemRole() => scope?.itemRole ?? widget.role,
    };
    final visualOverride = widget.visualOverride ?? scope?.visualOverride;
    final states = <WidgetState>{..._statesController.value, ..._baseStates};
    final visuals = YumeiroTheme.of(context).visuals;
    final appearance = visuals.resolveRole(role, states, visualOverride);

    if (widget.visualInsets != null) {
      return Material(
        type: MaterialType.transparency,
        child: InkWell(
          splashFactory: NoSplash.splashFactory,
          statesController: _statesController,
          onTap: widget.onTap,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          mouseCursor: widget.mouseCursor,
          customBorder: appearance.shape,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          child: _insetSurface(
            context: context,
            appearance: appearance,
            visualInsets: widget.visualInsets!,
            padding: widget.padding,
            child: widget.child,
          ),
        ),
      );
    }
    return YumeiroResolvedVisualSurface(
      appearance: appearance,
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: IconTheme.merge(
          data: IconThemeData(color: appearance.foreground),
          child: DefaultTextStyle.merge(
            style: TextStyle(color: appearance.foreground),
            child: InkWell(
              splashFactory: NoSplash.splashFactory,
              statesController: _statesController,
              onTap: widget.onTap,
              focusNode: widget.focusNode,
              autofocus: widget.autofocus,
              mouseCursor: widget.mouseCursor,
              customBorder: appearance.shape,
              overlayColor: const WidgetStatePropertyAll(Colors.transparent),
              child: widget.padding == null
                  ? widget.child
                  : Padding(padding: widget.padding!, child: widget.child),
            ),
          ),
        ),
      ),
    );
  }
}

/// Low-level renderer executing a resolved [YumeiroVisualAppearance] and its
/// [YumeiroEffectStack] pipeline.
class YumeiroResolvedVisualSurface extends StatelessWidget {
  const YumeiroResolvedVisualSurface({
    super.key,
    required this.appearance,
    required this.child,
    this.padding,
    this.visualInsets,
    this.width,
    this.height,
    this.constraints,
    this.alignment,
    this.clipBehavior = Clip.none,
  });

  /// A decoration-only adapter without a live backdrop or inherited scope.
  /// Optical-only decorators require an explicit capability from the caller.
  static Decoration materialDecoration(
    YumeiroVisualAppearance appearance, {
    YumeiroMaterialCapability capability = YumeiroMaterialCapability.blurOnly,
  }) => _YumeiroMaterialSurfaceDecoration(appearance, capability);

  final YumeiroVisualAppearance appearance;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  /// Insets the painted surface within the bounds set by the layout arguments.
  final EdgeInsetsGeometry? visualInsets;
  final double? width;
  final double? height;
  final BoxConstraints? constraints;
  final AlignmentGeometry? alignment;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) => _ResolvedSurfaceLayout(surface: this);

  Widget _buildLayout(BuildContext context, Widget content) {
    if (visualInsets != null) {
      return _insetSurface(
        context: context,
        appearance: appearance,
        visualInsets: visualInsets!,
        width: width,
        height: height,
        constraints: constraints,
        alignment: alignment,
        padding: padding,
        clipBehavior: clipBehavior,
        child: content,
      );
    }

    final capability = YumeiroMaterialCapabilityScope.of(context)
        .resolveForRuntime();

    return _YumeiroAppearanceAnimator(
      appearance: _appearanceForCapability(appearance, capability),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : appearance.transition.duration,
      curve: appearance.transition.curve,
      child: content,
      builder: (context, current, child) =>
          _buildSurface(context, current, capability, child!),
    );
  }

  Widget _buildSurface(
    BuildContext context,
    YumeiroVisualAppearance current,
    YumeiroMaterialCapability capability,
    Widget child,
  ) {
    final effects = _effectsForCapability(current.effects, capability);
    final innerDecoration = _YumeiroMaterialFillDecoration(
      fill: current.fill,
      shape: current.shape,
      effects: effects,
      capability: capability,
    );
    final outlineDecoration = ShapeDecoration(
      shape: current.shape.copyWith(side: current.outline),
    );

    // Geometry, paint, and opacity share one appearance animation. Keep the
    // layout animator independent so changing its dimensions or padding still
    // animates naturally without adding another tween around decorations.
    final Widget content = DecoratedBox(
      decoration: innerDecoration,
      child: DecoratedBox(
        decoration: outlineDecoration,
        position: DecorationPosition.foreground,
        child: _layoutSurfaceContent(
          context: context,
          appearance: appearance,
          width: width,
          height: height,
          constraints: constraints,
          alignment: alignment,
          padding: padding,
          child: child,
        ),
      ),
    );

    return _paintEffects(context, current, effects, capability, content);
  }

  YumeiroEffectStack _scaleBackdropEffects(
    YumeiroEffectStack effects,
    double opacity,
  ) {
    final scaledPasses = <YumeiroEffectPass>[
      for (final pass in effects.passes)
        switch (pass) {
          YumeiroOuterShadowPass(
            :final shadows,
            :final id,
            :final minCapability,
          ) =>
            YumeiroOuterShadowPass(
              [
                for (final shadow in shadows)
                  shadow.copyWith(
                    color: shadow.color.withValues(
                      alpha: shadow.color.a * opacity,
                    ),
                  ),
              ],
              id: id,
              minCapability: minCapability,
            ),
          YumeiroBackdropBlurPass(
            :final sigma,
            :final tint,
            :final id,
            :final minCapability,
          ) =>
            YumeiroBackdropBlurPass(
              sigma: sigma * opacity,
              tint: tint?.withValues(alpha: tint.a * opacity),
              id: id,
              minCapability: minCapability,
            ),
          YumeiroLiquidGlassPass(
            :final glass,
            :final blur,
            :final fallbackTint,
            :final id,
            :final minCapability,
          ) =>
            YumeiroLiquidGlassPass(
              glass: YumeiroGlassEffect.lerp(null, glass, opacity)!,
              blur: blur * opacity,
              fallbackTint: fallbackTint?.withValues(
                alpha: fallbackTint.a * opacity,
              ),
              id: id,
              minCapability: minCapability,
            ),
          _ => pass,
        },
    ];
    return YumeiroEffectStack.fromPasses(scaledPasses);
  }

  Widget _paintEffects(
    BuildContext context,
    YumeiroVisualAppearance appearance,
    YumeiroEffectStack base,
    YumeiroMaterialCapability capability,
    Widget content,
  ) {
    final hasBackdrop = base.glass != null || base.backdropBlur > 0;
    final effects = hasBackdrop && appearance.opacity < 1
        ? _scaleBackdropEffects(base, appearance.opacity)
        : base;
    final customPasses = effects.customPasses;

    final outerShadows = effects.outerShadows;
    final innerShadows = effects.innerShadows;
    final Decoration shadowDecoration = outerShadows.isEmpty
        ? const BoxDecoration()
        : ShapeDecoration(
            color: Colors.transparent,
            shape: appearance.shape.copyWith(side: BorderSide.none),
            shadows: outerShadows,
          );

    final hasForegroundPaint =
        innerShadows.isNotEmpty || customPasses.isNotEmpty;
    content = CustomPaint(
      painter: customPasses.isEmpty
          ? null
          : _YumeiroBeforeFillPainter(
              shape: appearance.shape,
              passes: customPasses,
              capability: capability,
            ),
      foregroundPainter: hasForegroundPaint
          ? _YumeiroSurfaceForegroundPainter(
              shape: appearance.shape,
              innerShadows: innerShadows,
              passes: customPasses,
              capability: capability,
              textDirection: Directionality.of(context),
            )
          : null,
      child: content,
    );

    for (final pass in customPasses) {
      content = pass.wrapSurface(
        context: context,
        shape: appearance.shape,
        capability: capability,
        child: content,
      );
    }

    final glass = effects.glass;
    final blur = effects.backdropBlur;
    content = ClipPath(
      clipper: ShapeBorderClipper(shape: appearance.shape),
      // The optical renderer owns the same shape with pixel-aligned bounds.
      // An outer clip would crop the input snapshot before replacement.
      clipBehavior: glass != null || blur > 0 ? Clip.none : clipBehavior,
      child: YumeiroGlassBackdrop(
        glass: glass,
        blur: blur,
        tint: effects.backdropTint,
        shape: appearance.shape,
        capability: capability,
        child: Opacity(
          opacity: hasBackdrop ? appearance.opacity : 1,
          child: content,
        ),
      ),
    );

    content = Opacity(
      opacity: hasBackdrop ? 1 : appearance.opacity,
      child: DecoratedBox(decoration: shadowDecoration, child: content),
    );

    final focusVisible = appearance.focusIndicator.isVisible;
    final keyboardFocus =
        focusVisible && YumeiroInputScope.keyboardFocusOf(context);
    final primaryContext = focusVisible
        ? FocusManager.instance.primaryFocus?.context
        : null;
    // Focus can still point to a subtree that was detached earlier this frame.
    final editing =
        primaryContext is Element &&
        primaryContext.renderObject?.attached == true &&
        primaryContext.findAncestorStateOfType<EditableTextState>() != null;
    final showFocus = keyboardFocus || editing;
    return CustomPaint(
      foregroundPainter: showFocus
          ? _YumeiroFocusPainter(
              shape: appearance.shape,
              indicator: appearance.focusIndicator,
              textDirection: Directionality.of(context),
            )
          : _YumeiroFocusPainter.none,
      child: content,
    );
  }
}

class _ResolvedSurfaceLayout extends StatefulWidget {
  const _ResolvedSurfaceLayout({required this.surface});

  final YumeiroResolvedVisualSurface surface;

  @override
  State<_ResolvedSurfaceLayout> createState() => _ResolvedSurfaceLayoutState();
}

class _ResolvedSurfaceLayoutState extends State<_ResolvedSurfaceLayout> {
  // Toggle the painting layout without disposing the interactive content.
  final _contentKey = GlobalKey();

  @override
  Widget build(BuildContext context) => widget.surface._buildLayout(
    context,
    KeyedSubtree(key: _contentKey, child: widget.surface.child),
  );
}

/// Keeps finishes inside the animated fill decoration, below all content.
/// The same decoration/widget types are retained even for an empty stack.
class _YumeiroMaterialFillDecoration extends ShapeDecoration {
  _YumeiroMaterialFillDecoration({
    required this.fill,
    required OutlinedBorder shape,
    required this.effects,
    required this.capability,
  }) : super(
         color: fill is YumeiroSolidFill ? fill.color : null,
         gradient: fill is YumeiroGradientFill ? fill.gradient : null,
         shape: shape.copyWith(side: BorderSide.none),
       );

  final YumeiroFill fill;
  final YumeiroEffectStack effects;
  final YumeiroMaterialCapability capability;

  _YumeiroMaterialFillDecoration _interpolate(
    _YumeiroMaterialFillDecoration other,
    double t,
  ) {
    // ShapeDecoration promotes a solid color to a matching constant gradient,
    // avoiding a midpoint jump when an idle ghost gains a glazed finish.
    final decoration = ShapeDecoration.lerp(this, other, t)!;
    return _YumeiroMaterialFillDecoration(
      fill: decoration.gradient == null
          ? YumeiroSolidFill(decoration.color ?? Colors.transparent)
          : YumeiroGradientFill(
              decoration.gradient!,
              fallbackColor: Color.lerp(
                fill.fallbackColor,
                other.fill.fallbackColor,
                t,
              )!,
            ),
      shape: OutlinedBorder.lerp(
        shape as OutlinedBorder,
        other.shape as OutlinedBorder,
        t,
      )!,
      effects: effects.lerp(other.effects, t),
      capability: t < .5 ? capability : other.capability,
    );
  }

  @override
  ShapeDecoration? lerpFrom(Decoration? a, double t) =>
      a is _YumeiroMaterialFillDecoration
      ? a._interpolate(this, t)
      : super.lerpFrom(a, t);

  @override
  ShapeDecoration? lerpTo(Decoration? b, double t) =>
      b is _YumeiroMaterialFillDecoration
      ? _interpolate(b, t)
      : super.lerpTo(b, t);

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _YumeiroMaterialFillPainter(
        super.createBoxPainter(onChanged),
        shape as OutlinedBorder,
        effects,
        capability,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _YumeiroMaterialFillDecoration &&
          super == other &&
          effects == other.effects &&
          capability == other.capability;

  @override
  int get hashCode => Object.hash(super.hashCode, effects, capability);
}

void _paintMaterialPasses(
  Canvas canvas, {
  required Size size,
  required OutlinedBorder shape,
  required YumeiroEffectStack effects,
  required YumeiroMaterialCapability capability,
  required TextDirection? textDirection,
  Offset offset = Offset.zero,
}) {
  var clipped = false;
  for (final pass in effects.customPasses) {
    if (!capability.supports(pass.minCapability)) continue;
    if (!clipped) {
      clipped = true;
      canvas.save();
      if (offset != Offset.zero) canvas.translate(offset.dx, offset.dy);
      canvas.clipPath(
        shape.getOuterPath(Offset.zero & size, textDirection: textDirection),
      );
    }
    canvas.save();
    pass.paintMaterial(
      canvas,
      size,
      shape,
      capability,
      textDirection: textDirection,
    );
    canvas.restore();
  }
  if (clipped) canvas.restore();
}

class _YumeiroMaterialFillPainter extends BoxPainter {
  _YumeiroMaterialFillPainter(
    this.base,
    this.shape,
    this.effects,
    this.capability,
  );

  final BoxPainter base;
  final OutlinedBorder shape;
  final YumeiroEffectStack effects;
  final YumeiroMaterialCapability capability;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    base.paint(canvas, offset, configuration);
    final size = configuration.size;
    if (size == null || size.isEmpty) return;
    _paintMaterialPasses(
      canvas,
      size: size,
      shape: shape,
      effects: effects,
      capability: capability,
      textDirection: configuration.textDirection,
      offset: offset,
    );
  }

  @override
  void dispose() {
    base.dispose();
    super.dispose();
  }
}

YumeiroEffectStack _effectsForCapability(
  YumeiroEffectStack effects,
  YumeiroMaterialCapability capability,
) {
  // Liquid glass owns a Gaussian fallback through YumeiroGlassBackdrop.
  bool supports(YumeiroEffectPass pass) =>
      pass is YumeiroLiquidGlassPass || capability.supports(pass.minCapability);

  return effects.passes.every(supports)
      ? effects
      : YumeiroEffectStack.fromPasses(effects.passes.where(supports));
}

YumeiroVisualAppearance _appearanceForCapability(
  YumeiroVisualAppearance appearance,
  YumeiroMaterialCapability capability,
) {
  final effects = _effectsForCapability(appearance.effects, capability);
  return identical(effects, appearance.effects)
      ? appearance
      : appearance.copyWith(effects: effects);
}

class _YumeiroMaterialSurfaceDecoration extends ShapeDecoration {
  factory _YumeiroMaterialSurfaceDecoration(
    YumeiroVisualAppearance appearance,
    YumeiroMaterialCapability capability,
  ) {
    final effective = capability.resolveForRuntime();
    return _YumeiroMaterialSurfaceDecoration._(
      _appearanceForCapability(appearance, effective),
      effective,
    );
  }

  _YumeiroMaterialSurfaceDecoration._(this.appearance, this.capability)
    : super(
        color: appearance.fill is YumeiroSolidFill
            ? (appearance.fill as YumeiroSolidFill).color
            : null,
        gradient: appearance.fill is YumeiroGradientFill
            ? (appearance.fill as YumeiroGradientFill).gradient
            : null,
        shape: appearance.shape.copyWith(side: appearance.outline),
        shadows: appearance.effects.outerShadows,
      );

  final YumeiroVisualAppearance appearance;
  final YumeiroMaterialCapability capability;

  _YumeiroMaterialSurfaceDecoration _interpolate(
    _YumeiroMaterialSurfaceDecoration other,
    double t,
  ) => _YumeiroMaterialSurfaceDecoration(
    appearance.lerp(other.appearance, t),
    t < .5 ? capability : other.capability,
  );

  _YumeiroMaterialSurfaceDecoration _fade(double t) =>
      _YumeiroMaterialSurfaceDecoration(
        appearance.copyWith(opacity: (appearance.opacity * t).clamp(0, 1)),
        capability,
      );

  @override
  ShapeDecoration? lerpFrom(Decoration? a, double t) => switch (a) {
    _YumeiroMaterialSurfaceDecoration() => a._interpolate(this, t),
    null => _fade(t),
    _ => super.lerpFrom(a, t),
  };

  @override
  ShapeDecoration? lerpTo(Decoration? b, double t) => switch (b) {
    _YumeiroMaterialSurfaceDecoration() => _interpolate(b, t),
    null => _fade(1 - t),
    _ => super.lerpTo(b, t),
  };

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _YumeiroMaterialSurfacePainter(
        ShapeDecoration(
          color: color,
          gradient: gradient,
          shape: appearance.shape.copyWith(side: BorderSide.none),
          shadows: shadows,
        ).createBoxPainter(onChanged),
        appearance,
        capability,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _YumeiroMaterialSurfaceDecoration &&
          super == other &&
          other.capability == capability &&
          other.appearance.effects == appearance.effects &&
          other.appearance.opacity == appearance.opacity;

  @override
  int get hashCode => Object.hash(
    super.hashCode,
    appearance.effects,
    appearance.opacity,
    capability,
  );
}

class _YumeiroMaterialSurfacePainter extends BoxPainter {
  _YumeiroMaterialSurfacePainter(this.base, this.appearance, this.capability);

  final BoxPainter base;
  final YumeiroVisualAppearance appearance;
  final YumeiroMaterialCapability capability;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    canvas.save();
    if (appearance.opacity < 1) {
      canvas.saveLayer(
        null,
        Paint()..color = Colors.white.withValues(alpha: appearance.opacity),
      );
    }
    base.paint(canvas, offset, configuration);
    canvas.translate(offset.dx, offset.dy);
    final size = configuration.size!;
    _paintMaterialPasses(
      canvas,
      size: size,
      shape: appearance.shape,
      effects: appearance.effects,
      capability: capability,
      textDirection: configuration.textDirection,
    );
    appearance.shape
        .copyWith(side: appearance.outline)
        .paint(
          canvas,
          Offset.zero & size,
          textDirection: configuration.textDirection,
        );
    final innerShadows = appearance.effects.innerShadows;
    if (innerShadows.isNotEmpty) {
      _paintInnerShadows(
        canvas,
        size,
        appearance.shape,
        innerShadows,
        configuration.textDirection,
      );
    }
    if (appearance.opacity < 1) canvas.restore();
    canvas.restore();
  }

  @override
  void dispose() {
    base.dispose();
    super.dispose();
  }
}

bool _sameSurfaceAppearance(
  YumeiroVisualAppearance first,
  YumeiroVisualAppearance second,
) {
  if (identical(first, second)) return true;
  final sameFill = switch ((first.fill, second.fill)) {
    (YumeiroSolidFill(color: final a), YumeiroSolidFill(color: final b)) =>
      a == b,
    (
      YumeiroGradientFill(gradient: final a, fallbackColor: final ac),
      YumeiroGradientFill(gradient: final b, fallbackColor: final bc),
    ) =>
      a == b && ac == bc,
    _ => false,
  };
  // Inherited content colors update immediately. A foreground-only change
  // must not wake the backdrop/effect paint clock.
  return sameFill &&
      first.shape == second.shape &&
      first.outline == second.outline &&
      first.effects == second.effects &&
      first.opacity == second.opacity &&
      first.focusIndicator.side == second.focusIndicator.side &&
      first.focusIndicator.gap == second.focusIndicator.gap &&
      listEquals(first.focusIndicator.glow, second.focusIndicator.glow);
}

/// One paint clock keeps the fill, outline, effects, clipping, and focus shape
/// coherent during theme transitions and state-dependent geometry changes.
class _YumeiroAppearanceAnimator extends StatefulWidget {
  const _YumeiroAppearanceAnimator({
    required this.appearance,
    required this.duration,
    required this.curve,
    required this.builder,
    required this.child,
  });

  final YumeiroVisualAppearance appearance;
  final Duration duration;
  final Curve curve;
  final ValueWidgetBuilder<YumeiroVisualAppearance> builder;
  final Widget child;

  @override
  State<_YumeiroAppearanceAnimator> createState() =>
      _YumeiroAppearanceAnimatorState();
}

class _YumeiroAppearanceAnimatorState extends State<_YumeiroAppearanceAnimator>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  CurvedAnimation? _animation;
  late YumeiroVisualAppearance _from;
  late YumeiroVisualAppearance _end;
  late YumeiroVisualAppearance _current;

  @override
  void initState() {
    super.initState();
    _from = widget.appearance;
    _end = widget.appearance;
    _current = widget.appearance;
  }

  void _handleTick() {
    final t = _animation!.value;
    final next = t <= 0
        ? _from
        : t >= 1
        ? _end
        : _from.lerp(_end, t);
    if (!_sameSurfaceAppearance(next, _current)) {
      setState(() => _current = next);
    }
  }

  @override
  void didUpdateWidget(covariant _YumeiroAppearanceAnimator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration <= Duration.zero) {
      _controller?.stop();
      _from = widget.appearance;
      _end = widget.appearance;
      _current = widget.appearance;
      return;
    }
    if (_sameSurfaceAppearance(widget.appearance, _end)) {
      _end = widget.appearance;
      if (_controller == null || !_controller!.isAnimating) {
        _from = widget.appearance;
        _current = widget.appearance;
      }
      return;
    }
    _from = _current;
    _end = widget.appearance;
    final controller = _controller ??= AnimationController(
      vsync: this,
      duration: widget.duration,
    )..addListener(_handleTick);
    controller.duration = widget.duration;
    if (_animation?.curve != widget.curve) {
      _animation?.dispose();
      _animation = CurvedAnimation(parent: controller, curve: widget.curve);
    }
    controller.forward(from: 0);
  }

  @override
  void dispose() {
    _animation?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, _current, widget.child);
}

class _YumeiroFocusPainter extends CustomPainter {
  const _YumeiroFocusPainter({
    required this.shape,
    required this.indicator,
    this.textDirection,
  });

  static const none = _YumeiroFocusPainter(
    shape: RoundedRectangleBorder(),
    indicator: YumeiroFocusIndicator.none,
  );

  final OutlinedBorder shape;
  final YumeiroFocusIndicator indicator;
  final TextDirection? textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    if (!indicator.isVisible) return;
    final rect = Offset.zero & size;
    final focusRect = rect.inflate(indicator.gap);
    final path = shape.getOuterPath(focusRect, textDirection: textDirection);
    for (final glow in indicator.glow) {
      canvas.drawPath(
        path.shift(glow.offset),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = indicator.side.width + glow.spreadRadius * 2
          ..color = glow.color
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, glow.blurRadius / 2),
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = indicator.side.width
        ..color = indicator.side.color,
    );
  }

  @override
  bool shouldRepaint(_YumeiroFocusPainter oldDelegate) {
    if (!indicator.isVisible && !oldDelegate.indicator.isVisible) {
      return false;
    }
    return oldDelegate.shape != shape ||
        oldDelegate.indicator != indicator ||
        oldDelegate.textDirection != textDirection;
  }
}

void _paintInnerShadows(
  Canvas canvas,
  Size size,
  OutlinedBorder shape,
  List<YumeiroInnerShadow> shadows,
  TextDirection? textDirection,
) {
  final rect = Offset.zero & size;
  final path = shape.getOuterPath(rect, textDirection: textDirection);
  for (final shadow in shadows) {
    canvas.saveLayer(rect, Paint());
    canvas.clipPath(path);
    final expanded = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(
        rect.inflate(
          shadow.blurRadius + shadow.spreadRadius + shadow.offset.distance,
        ),
      )
      ..addPath(
        shape.getOuterPath(
          rect.deflate(shadow.spreadRadius),
          textDirection: textDirection,
        ),
        shadow.offset,
      );
    canvas.drawPath(
      expanded,
      Paint()
        ..color = shadow.color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadow.blurRadius / 2),
    );
    canvas.restore();
  }
}

class _YumeiroBeforeFillPainter extends CustomPainter {
  const _YumeiroBeforeFillPainter({
    required this.shape,
    required this.passes,
    required this.capability,
  });

  final OutlinedBorder shape;
  final List<YumeiroEffectPass> passes;
  final YumeiroMaterialCapability capability;

  @override
  void paint(Canvas canvas, Size size) {
    for (final pass in passes) {
      pass.paintBeforeFill(canvas, size, shape, capability);
    }
  }

  @override
  bool shouldRepaint(_YumeiroBeforeFillPainter oldDelegate) =>
      oldDelegate.shape != shape ||
      oldDelegate.capability != capability ||
      oldDelegate.passes != passes;
}

class _YumeiroSurfaceForegroundPainter extends CustomPainter {
  const _YumeiroSurfaceForegroundPainter({
    required this.shape,
    required this.innerShadows,
    required this.passes,
    required this.capability,
    required this.textDirection,
  });

  final OutlinedBorder shape;
  final List<YumeiroInnerShadow> innerShadows;
  final List<YumeiroEffectPass> passes;
  final YumeiroMaterialCapability capability;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    if (innerShadows.isNotEmpty) {
      _paintInnerShadows(canvas, size, shape, innerShadows, textDirection);
    }
    for (final pass in passes) {
      pass.paintForeground(
        canvas,
        size,
        shape,
        capability,
        textDirection: textDirection,
      );
    }
  }

  @override
  bool shouldRepaint(_YumeiroSurfaceForegroundPainter oldDelegate) =>
      oldDelegate.shape != shape ||
      oldDelegate.innerShadows != innerShadows ||
      oldDelegate.capability != capability ||
      oldDelegate.textDirection != textDirection ||
      oldDelegate.passes != passes;
}
