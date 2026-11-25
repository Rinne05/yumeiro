part of 'theme_preset.dart';

const _neoBrutalistColors = YumeiroColorTokens(
  background: Color(0xFFFFF5B8),
  sidebar: Color(0xFFFCE75B),
  surface: Color(0xFFFF9B91),
  panel: Color(0xFFFF9B91),
  surfaceSecondary: Color(0xFFFFFDF2),
  surfaceElevated: Color(0xFFFFF9DB),
  surfaceHover: Color(0xFFE6F8BF),
  line: Color(0x80201F1B),
  lineStrong: Color(0xFF201F1B),
  text: Color(0xFF201F1B),
  muted: Color(0xFF494538),
  subtle: Color(0xFF625A48),
  accent: Color(0xFF5BE078),
  accentSoft: Color(0xFF19532D),
  info: Color(0xFF235BA8),
  success: Color(0xFF216237),
  warning: Color(0xFF80500C),
  rating: Color(0xFF80500C),
  danger: Color(0xFFC73C37),
  supporting: Color(0xFF7448A5),
  neutral: Color(0xFF5E594C),
  onAccent: Color(0xFF142B1B),
);

const _neoBrutalistDarkColors = YumeiroColorTokens(
  background: Color(0xFF181D1B),
  sidebar: Color(0xFF202722),
  surface: Color(0xFF352B2A),
  panel: Color(0xFF352B2A),
  surfaceSecondary: Color(0xFF29312D),
  surfaceElevated: Color(0xFF343D36),
  surfaceHover: Color(0xFF40503D),
  line: Color(0x668B9A83),
  lineStrong: Color(0xFFB7C6AC),
  text: Color(0xFFF5F3E7),
  muted: Color(0xFFC3C6B6),
  subtle: Color(0xFFA4AF9C),
  accent: Color(0xFFB4EE5B),
  accentSoft: Color(0xFFD0F3A1),
  info: Color(0xFF8DBAFF),
  success: Color(0xFF98DDA3),
  warning: Color(0xFFF0CB7B),
  rating: Color(0xFFF0CB7B),
  danger: Color(0xFFF48C96),
  supporting: Color(0xFFCCACEE),
  neutral: Color(0xFFAABBA7),
  onAccent: Color(0xFF18230F),
);

const _pixelColors = YumeiroColorTokens(
  background: Color(0xFFF8F1DC),
  sidebar: Color(0xFFECE8D2),
  surface: Color(0xFFFFFBED),
  surfaceSecondary: Color(0xFFE6ECD8),
  surfaceElevated: Color(0xFFFFFDF3),
  surfaceHover: Color(0xFFD1F0BD),
  line: Color(0x66232E4A),
  lineStrong: Color(0xFF232E4A),
  text: Color(0xFF18253F),
  muted: Color(0xFF4C5564),
  subtle: Color(0xFF646B6F),
  accent: Color(0xFF81D99A),
  accentSoft: Color(0xFF285B3B),
  info: Color(0xFF285E9D),
  success: Color(0xFF2C663C),
  warning: Color(0xFF845410),
  rating: Color(0xFF845410),
  danger: Color(0xFFAD3C4F),
  supporting: Color(0xFF74549D),
  neutral: Color(0xFF576273),
  onAccent: Color(0xFF182D25),
);

const _pixelDarkColors = YumeiroColorTokens(
  background: Color(0xFF121B29),
  sidebar: Color(0xFF192536),
  surface: Color(0xFF1E2D41),
  surfaceSecondary: Color(0xFF26394D),
  surfaceElevated: Color(0xFF2C4056),
  surfaceHover: Color(0xFF355264),
  line: Color(0x665F809D),
  lineStrong: Color(0xFF9BBBD8),
  text: Color(0xFFE8F1FA),
  muted: Color(0xFFB7C9DA),
  subtle: Color(0xFF96ACC1),
  accent: Color(0xFF8EE2AE),
  accentSoft: Color(0xFFB8EDCD),
  info: Color(0xFF8ABDF3),
  success: Color(0xFF96DBAC),
  warning: Color(0xFFF0CA82),
  rating: Color(0xFFF0CA82),
  danger: Color(0xFFF095AE),
  supporting: Color(0xFFC8B0ED),
  neutral: Color(0xFFA8B9CD),
  onAccent: Color(0xFF152D25),
);

final _graphicOptions = <YumeiroThemeOption>[
  yumeiroOutlineOption,
  yumeiroShadowOption,
  yumeiroShadowDistanceOption,
];

List<YumeiroThemeOption> _neoBrutalistOptions(YumeiroColorTokens colors) => [
  _surfaceColorOption(colors),
  YumeiroThemeColorOption(
    id: 'surfaceHoverColor',
    label: 'Hover Surface Color',
    localizedLabel: (l) => l.optionSurfaceHoverColor,
    localizedDescription: (l) => l.optionSurfaceHoverColorDescription,
    defaultValue: colors.surfaceHover,
    adjustment: YumeiroThemeAdjustment.surfaceHoverColor,
  ),
  ..._graphicOptions,
];

List<YumeiroThemeOption> _pixelOptions(YumeiroColorTokens colors) => [
  YumeiroThemeColorOption(
    id: 'secondarySurfaceColor',
    label: 'Secondary Surface Color',
    localizedLabel: (l) => l.optionSecondarySurfaceColor,
    localizedDescription: (l) => l.optionSecondarySurfaceColorDescription,
    defaultValue: colors.surfaceSecondary,
    adjustment: YumeiroThemeAdjustment.secondarySurfaceColor,
  ),
  ..._graphicOptions,
];

bool _graphicIsDark(YumeiroColorTokens colors) =>
    yumeiroRelativeLuminance(colors.background) <
    yumeiroRelativeLuminance(colors.text);

// Dark borders must stay visible against the surface while their offset
// shadows remain dark. Using the outline color for both creates a bright
// duplicate outline instead of a hard, raised shadow in the dark variants.
Color _graphicShadowColor(
  YumeiroColorTokens colors, [
  Map<String, Object> parameters = const {},
]) =>
    (parameters['hardShadowColor'] as Color?) ??
    (_graphicIsDark(colors) ? const Color(0xFF050907) : colors.lineStrong);

YumeiroSemanticVisualTheme _neoBrutalistVisuals(
  YumeiroColorTokens colors,
  YumeiroRadiiTokens radii,
  YumeiroMotion motion, [
  Map<String, Object> parameters = const {},
]) => _variantVisuals(
  colors,
  radii,
  motion,
  destinationBackground: true,
  focus: YumeiroFocusIndicator(side: BorderSide(color: colors.text, width: 3)),
  pressedScale: .99,
  navigationForeground: colors.text,
  selectedNavigationForeground: colors.onAccent,
  paint: (role, value, states) {
    if (role == YumeiroControlRole.overlay ||
        role == YumeiroSurfaceRole.canvas ||
        role == YumeiroSurfaceRole.navigation) {
      return value.copyWith(effects: YumeiroEffectStack.none);
    }
    final solid = _isSolidControl(role);
    final raised = _isRaisedSurface(role);
    final active = _isActiveLightweight(role, states);
    final nested =
        role == YumeiroSurfaceRole.inset || role == YumeiroSurfaceRole.compact;
    final panel = role == YumeiroSurfaceRole.panel;
    if (!solid && !raised && !active && !nested && !panel) {
      return value.copyWith(effects: YumeiroEffectStack.none);
    }
    final pressed = states.contains(WidgetState.pressed);
    final selected = states.contains(WidgetState.selected);
    if (_graphicIsDark(colors) && role == YumeiroControlRole.danger) {
      value = value.copyWith(foreground: colors.background);
    }
    if (selected && role != YumeiroControlRole.danger) {
      value = value.copyWith(
        fill: YumeiroSolidFill(colors.accent),
        foreground: colors.onAccent,
      );
    } else if (active) {
      // The hard shadow is painted beneath the entire face. Back the
      // interaction tint with an opaque fill so the shadow stays at the edge.
      value = value.copyWith(
        fill: YumeiroSolidFill(
          yumeiroAlphaBlend(value.background, colors.surfaceHover),
        ),
        foreground: colors.text,
      );
    } else if (nested) {
      value = value.copyWith(fill: YumeiroSolidFill(colors.surfaceSecondary));
    }
    return value.copyWith(
      outline: BorderSide(color: colors.lineStrong, width: nested ? 1.5 : 2.5),
      effects: YumeiroEffectStack(
        outerShadows: [
          if (solid || raised || active)
            BoxShadow(
              color: _graphicShadowColor(colors, parameters),
              offset: pressed
                  ? const Offset(1, 1)
                  : Offset(solid || active ? 3 : 4, solid || active ? 3 : 4),
            ),
        ],
      ),
    );
  },
);

YumeiroSemanticVisualTheme _pixelVisuals(
  YumeiroColorTokens colors,
  YumeiroRadiiTokens radii,
  YumeiroMotion motion, [
  Map<String, Object> parameters = const {},
]) => _variantVisuals(
  colors,
  radii,
  motion,
  destinationBackground: true,
  focus: YumeiroFocusIndicator(side: BorderSide(color: colors.text, width: 2)),
  pressedScale: 1,
  navigationForeground: colors.text,
  selectedNavigationForeground: colors.onAccent,
  paint: (role, value, states) {
    final canvas =
        role == YumeiroSurfaceRole.canvas ||
        role == YumeiroSurfaceRole.navigation;
    if (canvas) return value.copyWith(effects: YumeiroEffectStack.none);
    final solid = _isSolidControl(role);
    final raised = _isRaisedSurface(role);
    final active = _isActiveLightweight(role, states);
    final panel = role == YumeiroSurfaceRole.panel;
    final nested =
        role == YumeiroSurfaceRole.inset || role == YumeiroSurfaceRole.compact;
    final selected = states.contains(WidgetState.selected);
    final pressed = states.contains(WidgetState.pressed);
    final outline = solid || raised || panel || nested || active;
    if (_graphicIsDark(colors) && role == YumeiroControlRole.danger) {
      value = value.copyWith(foreground: colors.background);
    }
    if (selected && role != YumeiroControlRole.danger) {
      value = value.copyWith(
        fill: YumeiroSolidFill(colors.accent),
        foreground: colors.onAccent,
      );
    }
    return value.copyWith(
      shape: YumeiroPixelBorder(
        step: nested
            ? radii.chip * 2 / 3
            : raised || panel
            ? radii.md
            : radii.button,
      ),
      outline: outline
          ? BorderSide(color: colors.lineStrong, width: 2)
          : BorderSide.none,
      effects: YumeiroEffectStack(
        outerShadows: [
          if ((solid || raised) && !pressed)
            BoxShadow(
              color: _graphicShadowColor(colors, parameters),
              offset: const Offset(2, 2),
            ),
        ],
      ),
    );
  },
);

YumeiroTypographyTokens _neoBrutalistTypographyBuilder(
  YumeiroColorTokens colors,
  YumeiroFontConfig fontConfig,
) {
  final base = _defaultTypographyBuilder(colors, fontConfig);
  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      displaySmall: base.pageTitle.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: -.7,
      ),
      titleMedium: base.title.copyWith(fontWeight: FontWeight.w800),
      labelLarge: base.textTheme.labelLarge!.copyWith(
        fontWeight: FontWeight.w800,
      ),
      labelMedium: base.textTheme.labelMedium!.copyWith(
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

YumeiroTypographyTokens _pixelTypographyBuilder(
  YumeiroColorTokens colors,
  YumeiroFontConfig fontConfig,
) {
  // A host-supplied pixel font takes precedence. Monospace is the portable
  // default; CJK glyphs retain the host's fallback coverage.
  final effective = fontConfig.copyWith(
    fontFamily: fontConfig.fontFamily ?? fontConfig.monoFontFamily,
    fontFallback: [
      ...fontConfig.monoFontFallback,
      ...fontConfig.resolvedFontFallback,
    ],
  );
  final base = _defaultTypographyBuilder(colors, effective);
  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      displaySmall: base.pageTitle.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: .4,
      ),
      labelLarge: base.textTheme.labelLarge!.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: .2,
      ),
    ),
  );
}

SliderThemeData _neoBrutalistSliderThemeBuilder(
  YumeiroColorTokens colors,
  YumeiroTypographyTokens typography, {
  required Map<String, Object> parameters,
}) => _graphicSliderTheme(colors, typography, parameters, trackHeight: 6);

SliderThemeData _pixelSliderThemeBuilder(
  YumeiroColorTokens colors,
  YumeiroTypographyTokens typography, {
  required Map<String, Object> parameters,
}) => _graphicSliderTheme(
  colors,
  typography,
  parameters,
  trackHeight: 5,
  step: 2,
);

SliderThemeData _graphicSliderTheme(
  YumeiroColorTokens colors,
  YumeiroTypographyTokens typography,
  Map<String, Object> parameters, {
  required double trackHeight,
  double step = 0,
}) {
  final thumb = _GraphicSliderThumb(
    borderColor: colors.lineStrong,
    outlineWidth: 2 * _materialRatio(parameters, 'outline'),
    shadowColor: _graphicShadowColor(colors, parameters),
    shadowStrength: _materialRatio(parameters, 'shadow'),
    shadowDistance: _materialRatio(parameters, 'shadowDistance'),
    step: step,
  );
  return _baseSliderTheme(
    colors,
    typography,
    trackShape: const RectangularSliderTrackShape(),
    trackHeight: trackHeight,
    thumbShape: thumb,
    rangeThumbShape: _GraphicRangeSliderThumb(thumb),
  );
}

class _GraphicSliderThumb extends SliderComponentShape {
  const _GraphicSliderThumb({
    required this.borderColor,
    required this.outlineWidth,
    required this.shadowColor,
    required this.shadowStrength,
    required this.shadowDistance,
    this.step = 0,
  });

  final Color borderColor;
  final double outlineWidth;
  final Color shadowColor;
  final double shadowStrength;
  final double shadowDistance;
  final double step;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(20, 20);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) => paintThumb(
    context.canvas,
    center,
    sliderTheme,
    activation: activationAnimation.value,
    enabled: enableAnimation.value,
  );

  void paintThumb(
    Canvas canvas,
    Offset center,
    SliderThemeData theme, {
    required double activation,
    required double enabled,
    double outlineSeparation = 0,
  }) {
    final size = 14 + activation * 2;
    final rect = Rect.fromCenter(center: center, width: size, height: size);
    final color = Color.lerp(
      theme.disabledThumbColor,
      theme.thumbColor,
      enabled,
    )!;
    final stateOpacity = .4 + enabled * .6;
    final border = YumeiroPixelBorder(
      step: step,
      side: outlineWidth == 0
          ? BorderSide.none
          : BorderSide(
              color: borderColor.withValues(alpha: stateOpacity),
              width: outlineWidth,
            ),
    );
    final shadowOpacity = (shadowColor.a * shadowStrength).clamp(0.0, 1.0);
    if (shadowOpacity > 0) {
      final offset = Offset(shadowDistance, shadowDistance);
      canvas.drawPath(
        border.getOuterPath(rect.shift(offset)),
        Paint()
          ..color = shadowColor.withValues(alpha: shadowOpacity * stateOpacity)
          ..isAntiAlias = false,
      );
    }
    if (outlineSeparation > 0) {
      canvas.drawPath(
        border.getOuterPath(rect.inflate(outlineSeparation)),
        Paint()
          ..color = theme.overlappingShapeStrokeColor!
          ..isAntiAlias = false,
      );
    }
    canvas.drawPath(
      border.getOuterPath(rect),
      Paint()
        ..color = color
        ..isAntiAlias = false,
    );
    border.paint(canvas, rect);
  }
}

class _GraphicRangeSliderThumb extends RangeSliderThumbShape {
  const _GraphicRangeSliderThumb(this.shape);

  final _GraphicSliderThumb shape;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      shape.getPreferredSize(isEnabled, isDiscrete);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    bool isDiscrete = false,
    bool isEnabled = false,
    bool isOnTop = false,
    TextDirection? textDirection,
    required SliderThemeData sliderTheme,
    Thumb? thumb,
    bool isPressed = false,
  }) => shape.paintThumb(
    context.canvas,
    center,
    sliderTheme,
    activation: isPressed ? activationAnimation.value : 0,
    enabled: enableAnimation.value,
    outlineSeparation: isOnTop ? 1 : 0,
  );
}

YumeiroCheckboxVisuals _pixelCheckboxVisualsBuilder(
  YumeiroColorTokens colors,
  YumeiroRadiiTokens radii,
  YumeiroSemanticVisualTheme visuals,
) => _defaultCheckboxVisualsBuilder(
  colors,
  radii,
  visuals,
).copyWith(shape: YumeiroPixelBorder(step: radii.checkbox));

YumeiroCheckboxVisuals _neoBrutalistCheckboxVisualsBuilder(
  YumeiroColorTokens colors,
  YumeiroRadiiTokens radii,
  YumeiroSemanticVisualTheme visuals,
) => _defaultCheckboxVisualsBuilder(colors, radii, visuals).copyWith(
  side: WidgetStateBorderSide.resolveWith(
    (states) => BorderSide(
      color: colors.lineStrong.withValues(
        alpha: states.contains(WidgetState.disabled) ? .5 : 1,
      ),
      width: 2,
    ),
  ),
);

YumeiroSwitchVisuals _neoBrutalistSwitchVisualsBuilder(
  YumeiroColorTokens colors,
  YumeiroSemanticVisualTheme visuals,
) {
  YumeiroVisualAppearance switchSurface(
    YumeiroVisualAppearance value,
    Set<WidgetState> states,
    Color outlineColor,
  ) {
    final shadow = value.effects.outerShadows.firstOrNull;
    return value.copyWith(
      // Switches have a 2px border and a 1px shadow offset at the same
      // settings that give their control recipes a 2.5px border and 3px offset.
      outline: value.outline.copyWith(
        color: outlineColor,
        width: value.outline.width * (2 / 2.5),
      ),
      effects: YumeiroEffectStack(
        outerShadows: [
          if (!states.contains(WidgetState.pressed) &&
              shadow != null &&
              shadow.color.a > 0)
            shadow.copyWith(offset: shadow.offset / 3),
        ],
      ),
    );
  }

  YumeiroVisualAppearance track(Set<WidgetState> states) => switchSurface(
    visuals.control(
      states.contains(WidgetState.selected)
          ? YumeiroControlRole.primary
          : YumeiroControlRole.neutral,
      states,
    ),
    states,
    colors.lineStrong,
  );

  YumeiroVisualAppearance thumb(Set<WidgetState> states) =>
      switchSurface(
        visuals.control(
          YumeiroControlRole.secondary,
          states.difference(const {WidgetState.selected, WidgetState.focused}),
        ),
        states,
        _graphicIsDark(colors) ? colors.onAccent : colors.lineStrong,
      ).copyWith(
        fill: YumeiroSolidFill(
          states.contains(WidgetState.pressed)
              ? _graphicIsDark(colors)
                    ? Color.lerp(colors.text, colors.surfaceSecondary, .12)!
                    : colors.surfaceSecondary
              : _graphicIsDark(colors)
              ? colors.text
              : Color.lerp(colors.surfaceSecondary, Colors.white, .65)!,
        ),
        focusIndicator: YumeiroFocusIndicator.none,
      );

  return YumeiroSwitchVisuals(
    track: YumeiroVisualRecipe(
      base: track(const {}),
      states: WidgetStateProperty.resolveWith(track),
      focusIndicator: YumeiroFocusIndicator(
        side: BorderSide(color: colors.text, width: 3),
      ),
    ),
    thumb: YumeiroVisualRecipe(
      base: thumb(const {}),
      states: WidgetStateProperty.resolveWith(thumb),
    ),
  );
}

YumeiroSwitchVisuals _pixelSwitchVisualsBuilder(
  YumeiroColorTokens colors,
  YumeiroSemanticVisualTheme visuals,
) {
  final controlShape = visuals
      .control(YumeiroControlRole.neutral, const {})
      .shape;
  final shape = YumeiroPixelBorder(
    step: controlShape is YumeiroPixelBorder ? controlShape.step * 2 / 3 : 2,
  );

  YumeiroVisualAppearance track(Set<WidgetState> states) => visuals
      .control(
        states.contains(WidgetState.selected)
            ? YumeiroControlRole.primary
            : YumeiroControlRole.neutral,
        states,
      )
      .copyWith(shape: shape);

  YumeiroVisualAppearance thumb(Set<WidgetState> states) => visuals
      .control(
        YumeiroControlRole.secondary,
        states.difference(const {WidgetState.selected, WidgetState.focused}),
      )
      .copyWith(
        fill: YumeiroSolidFill(colors.surfaceElevated),
        shape: shape,
        focusIndicator: YumeiroFocusIndicator.none,
      );

  return YumeiroSwitchVisuals(
    track: YumeiroVisualRecipe(
      base: track(const {}),
      states: WidgetStateProperty.resolveWith(track),
      focusIndicator: YumeiroFocusIndicator(
        side: BorderSide(color: colors.text, width: 2),
      ),
    ),
    thumb: YumeiroVisualRecipe(
      base: thumb(const {}),
      states: WidgetStateProperty.resolveWith(thumb),
    ),
    trackSize: const Size(46, 26),
    thumbSize: 18,
  );
}
