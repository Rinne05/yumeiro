part of 'theme_preset.dart';

const _geekColors = YumeiroColorTokens(
  background: Color(0xFF101410),
  sidebar: Color(0xFF141917),
  surface: Color(0xFF1C211E),
  surfaceSecondary: Color(0xFF242B26),
  surfaceElevated: Color(0xFF2C342F),
  surfaceHover: Color(0xFF343F38),
  line: Color(0x3357D957),
  lineStrong: Color(0x9965D96D),
  text: Color(0xFFEDF1ED),
  muted: Color(0xFFBDC7BF),
  subtle: Color(0xFFA7B3AA),
  accent: Color(0xFF7FED65),
  accentSoft: Color(0xFFACF59C),
  info: Color(0xFF75CFE9),
  success: Color(0xFF67DFA7),
  warning: Color(0xFFF1CA71),
  rating: Color(0xFFF1CA71),
  danger: Color(0xFFD64C5D),
  supporting: Color(0xFFC2A5EF),
  neutral: Color(0xFF9CB19F),
  onAccent: Color(0xFF10210D),
);

const _sketchColors = YumeiroColorTokens(
  background: Color(0xFFF3EDE1),
  sidebar: Color(0xFFF8F3E9),
  surface: Color(0xFFFFFBF3),
  surfaceSecondary: Color(0xFFECE5D8),
  surfaceElevated: Color(0xFFFFFCF7),
  surfaceHover: Color(0xFFE4DAC9),
  line: Color(0x332D322D),
  lineStrong: Color(0x99333A32),
  text: Color(0xFF292F2B),
  muted: Color(0xFF575D53),
  subtle: Color(0xFF63685D),
  accent: Color(0xFF245E57),
  accentSoft: Color(0xFF194C46),
  info: Color(0xFF286881),
  success: Color(0xFF326A43),
  warning: Color(0xFF8C570B),
  rating: Color(0xFF8C570B),
  danger: Color(0xFFCE5E6C),
  supporting: Color(0xFF77538A),
  neutral: Color(0xFF62665D),
  onAccent: Color(0xFFFFFFFF),
);

const _neumorphicColors = YumeiroColorTokens(
  background: Color(0xFFE8EDF3),
  sidebar: Color(0xFFE8EDF3),
  surface: Color(0xFFE8EDF3),
  surfaceSecondary: Color(0xFFE8EDF3),
  surfaceElevated: Color(0xFFE8EDF3),
  surfaceHover: Color(0xFFDDE5F0),
  line: Color(0x1F405578),
  lineStrong: Color(0x66405578),
  text: Color(0xFF202D43),
  muted: Color(0xFF4C5D77),
  subtle: Color(0xFF596A83),
  accent: Color(0xFF245DBC),
  accentSoft: Color(0xFF1E4F9C),
  info: Color(0xFF26688B),
  success: Color(0xFF246B51),
  warning: Color(0xFF8D570F),
  rating: Color(0xFF8D570F),
  danger: Color(0xFFCE5E6C),
  supporting: Color(0xFF7351A0),
  neutral: Color(0xFF5A687D),
  onAccent: Color(0xFFFFFFFF),
);

const _neumorphicDarkColors = YumeiroColorTokens(
  background: Color(0xFF252D38),
  sidebar: Color(0xFF252D38),
  surface: Color(0xFF252D38),
  surfaceSecondary: Color(0xFF252D38),
  surfaceElevated: Color(0xFF29333F),
  surfaceHover: Color(0xFF354252),
  line: Color(0x405D6E87),
  lineStrong: Color(0xB37D90A9),
  text: Color(0xFFECF1F8),
  muted: Color(0xFFBAC7D9),
  subtle: Color(0xFF9DADC3),
  accent: Color(0xFF8CB8F6),
  accentSoft: Color(0xFFACCCFA),
  info: Color(0xFF8BCBE5),
  success: Color(0xFF8BD4B4),
  warning: Color(0xFFECC782),
  rating: Color(0xFFECC782),
  danger: Color(0xFFF098AA),
  supporting: Color(0xFFC8AEED),
  neutral: Color(0xFFAFBDCF),
  onAccent: Color(0xFF14263F),
);

typedef _VariantPaint = YumeiroVisualAppearance Function(
  YumeiroVisualRole role,
  YumeiroVisualAppearance appearance,
  Set<WidgetState> states,
);

YumeiroVisualAppearance _tintedPrimary(
  YumeiroVisualRole role,
  YumeiroVisualAppearance value,
  Set<WidgetState> states,
  YumeiroColorTokens colors,
) {
  if (role != YumeiroControlRole.primary) return value;
  return value.copyWith(
    fill: YumeiroSolidFill(
      yumeiroAlphaBlend(
        colors.accent.withValues(
          alpha: states.contains(WidgetState.pressed)
              ? .28
              : states.contains(WidgetState.hovered)
              ? .23
              : .18,
        ),
        colors.surfaceSecondary,
      ),
    ),
    foreground: colors.text,
  );
}

YumeiroSemanticVisualTheme _variantVisuals(
  YumeiroColorTokens colors,
  YumeiroRadiiTokens radii,
  YumeiroMotion motion, {
  required _VariantPaint paint,
  required YumeiroFocusIndicator focus,
  required double pressedScale,
  Color? navigationForeground,
  Color? selectedNavigationForeground,
  bool destinationBackground = false,
  Map<YumeiroStatusRole, Color> statusForegrounds = const {},
}) {
  final base = _buildBaseVisuals(
    colors,
    radii,
    motion,
    navigationFill: colors.sidebar,
    panelFill: colors.surface,
    cardFill: colors.surface,
    floatingFill: colors.surfaceElevated,
    toastFill: colors.surfaceElevated,
    controlFill: colors.surfaceSecondary,
    hoverOverlay: colors.text.withValues(alpha: .06),
    pressedOverlay: colors.accent.withValues(alpha: .12),
    selectedControlFill: yumeiroAlphaBlend(
      colors.accent.withValues(alpha: .16),
      colors.surfaceSecondary,
    ),
    selectedItemFill: colors.accent.withValues(alpha: .12),
    cardShadowOpacity: 0,
    controlShadowOpacity: 0,
    floatingShadowOpacity: .14,
    modalShadowOpacity: .16,
    toastShadowOpacity: .14,
    focusIndicator: focus,
  );

  Set<WidgetState> enabledStates(Set<WidgetState> states) =>
      states.contains(WidgetState.disabled)
      ? states.difference(const {
          WidgetState.disabled,
          WidgetState.hovered,
          WidgetState.pressed,
          WidgetState.focused,
        })
      : states;

  YumeiroVisualAppearance decorateAppearance(
    YumeiroVisualRole role,
    YumeiroVisualAppearance value,
    Set<WidgetState> materialStates, {
    required bool disabled,
  }) {
    final painted = paint(
      role,
      value.copyWith(
        transition: YumeiroVisualTransition(
          duration: value.transition.duration,
          curve: value.transition.curve,
          pressedScale: pressedScale,
        ),
      ),
      materialStates,
    );
    return disabled ? _disabledVisual(painted) : painted;
  }

  YumeiroVisualRecipe decorate(
    YumeiroVisualRole role,
    YumeiroVisualRecipe recipe,
  ) {
    YumeiroVisualAppearance resolve(Set<WidgetState> states) {
      final materialStates = enabledStates(states);
      return decorateAppearance(
        role,
        recipe.resolve(materialStates),
        materialStates,
        disabled: states.contains(WidgetState.disabled),
      );
    }

    final resting = resolve(const {});
    return YumeiroVisualRecipe(
      base: resting,
      states: WidgetStateProperty.resolveWith(
        (states) => states.isEmpty ? resting : resolve(states),
      ),
      focusIndicator: recipe.focusIndicator,
    );
  }

  final controls = {
    for (final entry in base.controls.entries)
      entry.key: decorate(entry.key, entry.value),
  };

  return YumeiroSemanticVisualTheme(
    surfaces: {
      for (final entry in base.surfaces.entries)
        entry.key: switch (entry.key) {
          YumeiroSurfaceRole.readout => YumeiroVisualRecipe(
            base: controls[YumeiroControlRole.neutral]!.base,
          ),
          YumeiroSurfaceRole.scrim => entry.value,
          _ => decorate(entry.key, entry.value),
        },
    },
    controls: controls,
    items: {
      for (final entry in base.items.entries)
        entry.key: decorate(entry.key, entry.value),
    },
    statuses: {
      for (final entry in base.statuses.entries)
        entry.key: YumeiroStatusVisual(
          foreground: statusForegrounds[entry.key] ?? entry.value.foreground,
          subtleFill: entry.value.subtleFill,
          tint: entry.value.tint,
        ),
    },
    navigationItems: WidgetStateProperty.resolveWith((states) {
      final materialStates = enabledStates(states);
      final disabled = states.contains(WidgetState.disabled);
      final visual = base.navigationItem(materialStates);
      final indicator =
          destinationBackground && materialStates.contains(WidgetState.selected)
          ? base.item(YumeiroItemRole.navigation, materialStates)
          : null;
      return YumeiroNavigationItemVisual(
        iconForeground: materialStates.contains(WidgetState.selected)
            ? selectedNavigationForeground ??
                  navigationForeground ??
                  visual.iconForeground
            : navigationForeground ?? visual.iconForeground,
        labelForeground: materialStates.contains(WidgetState.selected)
            ? selectedNavigationForeground ??
                  navigationForeground ??
                  visual.labelForeground
            : navigationForeground ?? visual.labelForeground,
        labelWeight: visual.labelWeight,
        topSurface: decorateAppearance(
          YumeiroControlRole.ghost,
          visual.topSurface,
          materialStates,
          disabled: disabled,
        ),
        topIndicator: visual.topIndicator == null
            ? null
            : decorateAppearance(
                YumeiroSurfaceRole.compact,
                visual.topIndicator!,
                materialStates,
                disabled: disabled,
              ),
        destinationIndicator: indicator == null
            ? null
            : decorateAppearance(
                YumeiroItemRole.navigation,
                indicator,
                materialStates,
                disabled: disabled,
              ),
      );
    }),
  );
}

bool _isRaisedSurface(YumeiroVisualRole role) =>
    role == YumeiroSurfaceRole.card ||
    role == YumeiroSurfaceRole.media ||
    role == YumeiroSurfaceRole.floating ||
    role == YumeiroSurfaceRole.modal ||
    role == YumeiroSurfaceRole.toast;

bool _isActiveLightweight(YumeiroVisualRole role, Set<WidgetState> states) =>
    (role == YumeiroControlRole.ghost ||
        role == YumeiroItemRole.standard ||
        role == YumeiroItemRole.selection ||
        role == YumeiroItemRole.navigation) &&
    (states.contains(WidgetState.selected) ||
        states.contains(WidgetState.hovered) ||
        states.contains(WidgetState.pressed));

bool _isSolidControl(YumeiroVisualRole role) =>
    role == YumeiroControlRole.neutral ||
    role == YumeiroControlRole.secondary ||
    role == YumeiroControlRole.primary ||
    role == YumeiroControlRole.danger;

YumeiroSemanticVisualTheme _geekVisuals(
  YumeiroColorTokens colors,
  YumeiroRadiiTokens radii,
  YumeiroMotion motion, [
  Map<String, Object> parameters = const {},
]) => _variantVisuals(
  colors,
  radii,
  motion,
  destinationBackground: true,
  focus: YumeiroFocusIndicator(
    side: BorderSide(color: colors.accent, width: 1.5),
    glow: [
      BoxShadow(
        color: colors.accent.withValues(alpha: .22),
        blurRadius: 9,
        spreadRadius: 1,
      ),
    ],
  ),
  pressedScale: 1,
  paint: (role, value, states) {
    value = _tintedPrimary(role, value, states, colors);
    final control = _isSolidControl(role) || _isActiveLightweight(role, states);
    final outlined =
        control ||
        _isRaisedSurface(role) ||
        role == YumeiroSurfaceRole.panel ||
        role == YumeiroSurfaceRole.inset ||
        role == YumeiroSurfaceRole.compact;
    if (!outlined) return value;
    final active =
        states.contains(WidgetState.selected) ||
        states.contains(WidgetState.hovered) ||
        role == YumeiroControlRole.primary;
    final border =
        role == YumeiroControlRole.danger || role == YumeiroItemRole.danger
        ? colors.danger
        : active
        ? colors.accent
        : colors.lineStrong;
    return value.copyWith(
      outline: BorderSide(color: border.withValues(alpha: active ? .85 : .48)),
      effects: YumeiroEffectStack(
        outerShadows: [
          if (role == YumeiroSurfaceRole.floating ||
              role == YumeiroSurfaceRole.modal ||
              role == YumeiroSurfaceRole.toast)
            const BoxShadow(
              color: Color(0x30000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
        ],
      ),
    );
  },
);

YumeiroSemanticVisualTheme _sketchVisuals(
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
  paint: (role, value, states) {
    value = _tintedPrimary(role, value, states, colors);
    final control = _isSolidControl(role) || _isActiveLightweight(role, states);
    final raised = _isRaisedSurface(role);
    if (!control &&
        !raised &&
        role != YumeiroSurfaceRole.panel &&
        role != YumeiroSurfaceRole.inset &&
        role != YumeiroSurfaceRole.compact) {
      return value;
    }
    return value.copyWith(
      outline: BorderSide(
        color: control || raised ? colors.text : colors.lineStrong,
        width: control || raised ? 1.5 : 1,
      ),
      effects: YumeiroEffectStack(
        outerShadows: [
          if ((_isSolidControl(role) || raised) &&
              !states.contains(WidgetState.pressed))
            BoxShadow(
              color: _materialColor(
                parameters,
                'shadowColor',
                colors.text,
              ).withValues(alpha: .75),
              offset: Offset(control ? 2 : 3, control ? 2 : 3),
            ),
        ],
      ),
    );
  },
);

YumeiroSemanticVisualTheme _neumorphicVisuals(
  YumeiroColorTokens colors,
  YumeiroRadiiTokens radii,
  YumeiroMotion motion, [
  Map<String, Object> parameters = const {},
]) {
  final dark =
      yumeiroRelativeLuminance(colors.background) <
      yumeiroRelativeLuminance(colors.text);
  final tone = parameters['backgroundTone'] as Color?;
  final defaultShadow = dark
      ? const Color(0xFF080C12)
      : const Color(0xFF546B92);
  final shadow = _materialColor(
    parameters,
    'shadowColor',
    tone == null
        ? defaultShadow
        : HSLColor.fromColor(defaultShadow)
              .withHue(HSLColor.fromColor(tone).hue)
              .withSaturation(HSLColor.fromColor(tone).saturation)
              .toColor(),
  );
  final lightShadowColor = dark
      ? Color.lerp(colors.surface, colors.text, .22)!
      : tone == null
      ? Colors.white
      : Color.lerp(Colors.white, colors.surface, .4)!;
  final highlightRatio = _materialRatio(parameters, 'raisedHighlight');
  return _variantVisuals(
    colors,
    radii,
    motion,
    destinationBackground: true,
    focus: YumeiroFocusIndicator(
      side: BorderSide(color: colors.accent, width: 1.5),
    ),
    pressedScale: 1,
    paint: (role, value, states) {
      if (role == YumeiroControlRole.overlay) return value;
      value = _tintedPrimary(role, value, states, colors);
      if (dark && role == YumeiroControlRole.danger) {
        value = value.copyWith(foreground: colors.background);
      }
      final control =
          _isSolidControl(role) || _isActiveLightweight(role, states);
      final raised = _isRaisedSurface(role);
      if (!control && !raised) {
        return value.copyWith(effects: YumeiroEffectStack.none);
      }
      final inset =
          role == YumeiroControlRole.neutral ||
          (control &&
              (states.contains(WidgetState.pressed) ||
                  states.contains(WidgetState.selected)));
      final fill = yumeiroAlphaBlend(value.background, colors.surface);
      final lightShadow = _materialAlpha(
        lightShadowColor,
        (dark ? .24 : .35) * highlightRatio,
      );
      return value.copyWith(
        fill: YumeiroSolidFill(fill),
        outline: BorderSide.none,
        effects: YumeiroEffectStack(
          outerShadows: inset
              ? const []
              : [
                  BoxShadow(
                    color: dark
                        ? _materialAlpha(shadow, .72)
                        : shadow.withValues(alpha: .18),
                    blurRadius: dark ? (raised ? 7 : 4) : (raised ? 4 : 2),
                    offset: raised ? const Offset(3, 3) : const Offset(2, 2),
                  ),
                  if (dark && highlightRatio > 0)
                    YumeiroOuterHighlight(
                      color: _materialAlpha(
                        lightShadowColor,
                        .16 * highlightRatio,
                      ),
                      blurRadius: raised ? 5 : 3,
                      offset: const Offset(-2, -2),
                    ),
                ],
          innerShadows: [
            YumeiroInnerShadow(
              color: inset
                  ? dark
                        ? _materialAlpha(shadow, .66)
                        : shadow.withValues(alpha: .24)
                  : lightShadow,
              blurRadius: dark ? 2 : 1,
              offset: const Offset(1, 1),
              isHighlight: !inset,
            ),
            YumeiroInnerShadow(
              color: inset
                  ? lightShadow
                  : dark
                  ? _materialAlpha(shadow, .48)
                  : shadow.withValues(alpha: .24),
              blurRadius: dark ? 2 : 1,
              offset: const Offset(-1, -1),
              isHighlight: inset,
            ),
          ],
        ),
      );
    },
  );
}

SliderThemeData _geekSliderTheme(
  YumeiroColorTokens colors,
  YumeiroTypographyTokens typography, {
  required Map<String, Object> parameters,
}) => _baseSliderTheme(
  colors,
  typography,
  trackShape: const RectangularSliderTrackShape(),
  thumbShape: const RoundSliderThumbShape(
    enabledThumbRadius: 6,
    elevation: 0,
    pressedElevation: 0,
  ),
);

SliderThemeData _sketchSliderTheme(
  YumeiroColorTokens colors,
  YumeiroTypographyTokens typography, {
  required Map<String, Object> parameters,
}) => _baseSliderTheme(
  colors,
  typography,
  inactiveTrackColor: colors.lineStrong,
  thumbShape: const RoundSliderThumbShape(
    enabledThumbRadius: 6,
    elevation: 0,
    pressedElevation: 0,
  ),
);

SliderThemeData _neumorphicSliderTheme(
  YumeiroColorTokens colors,
  YumeiroTypographyTokens typography, {
  required Map<String, Object> parameters,
}) => _baseSliderTheme(
  colors,
  typography,
  trackHeight: 4,
  thumbShape: const RoundSliderThumbShape(
    enabledThumbRadius: 7,
    elevation: 3,
    pressedElevation: 1,
  ),
);

YumeiroCheckboxVisuals _sketchCheckboxVisuals(
  YumeiroColorTokens colors,
  YumeiroRadiiTokens radii,
  YumeiroSemanticVisualTheme visuals,
) {
  final outline = visuals.control(YumeiroControlRole.neutral, const {}).outline;
  final restingColor = outline.style == BorderStyle.none
      ? colors.text
      : outline.color;
  return _defaultCheckboxVisualsBuilder(colors, radii, visuals).copyWith(
    side: WidgetStateBorderSide.resolveWith(
      (states) => BorderSide(
        color: states.contains(WidgetState.disabled)
            ? colors.text.withValues(alpha: colors.line.a * .7)
            : states.contains(WidgetState.selected) ||
                  states.contains(WidgetState.focused)
            ? colors.accent
            : restingColor,
        width:
            !states.contains(WidgetState.disabled) &&
                states.contains(WidgetState.focused)
            ? 2
            : 1.5,
      ),
    ),
  );
}
