part of 'theme_preset.dart';

const _minimalRadii = YumeiroRadiiTokens(
  chip: 6,
  button: 8,
  md: 12,
  lg: 14,
  checkbox: 4,
  poster: 10,
);

const _liquidGlassRadii = YumeiroRadiiTokens(
  chip: 12,
  button: 22,
  md: 22,
  lg: 26,
  checkbox: 5,
  poster: 16,
);

final _minimalDarkColors = YumeiroColorTokens.dark.copyWith(
  background: const Color(0xFF1C2227),
  sidebar: const Color(0xFF161C20),
  surface: const Color(0xFF252D33),
  surfaceSecondary: const Color(0xFF20282E),
  surfaceElevated: const Color(0xFF2B353D),
  surfaceHover: const Color(0xFF34414A),
  line: const Color(0xFF3D4851),
  lineStrong: const Color(0xFF677783),
  text: const Color(0xFFE4EAEE),
  muted: const Color(0xFFB7C1C9),
  subtle: const Color(0xFFA6B3BD),
  accent: const Color(0xFF275FE3),
  accentSoft: const Color(0xFFBED7FF),
  danger: const Color(0xFFB93440),
  onAccent: const Color(0xFFE4EAEE),
);

final _minimalLightColors = YumeiroColorTokens.light.copyWith(
  background: const Color(0xFFF0F3F5),
  sidebar: const Color(0xFFE7ECEF),
  surface: const Color(0xFFF9FAFB),
  surfaceSecondary: const Color(0xFFE6ECEF),
  surfaceElevated: const Color(0xFFFFFFFF),
  surfaceHover: const Color(0xFFDCE3E8),
  line: const Color(0xFFC6CFD5),
  lineStrong: const Color(0xFF8D9DA9),
  text: const Color(0xFF25313A),
  muted: const Color(0xFF56636E),
  subtle: const Color(0xFF606C76),
  accent: const Color(0xFF88B6FF),
  accentSoft: const Color(0xFF17458F),
  danger: const Color(0xFFFFA3AD),
  onAccent: const Color(0xFF25313A),
);

final _liquidGlassLightColors = YumeiroColorTokens.light.copyWith(
  background: const Color(0xFFF3F2F0),
  sidebar: const Color(0xFFF5F5F4),
  surface: const Color(0xFFFCFCFB),
  surfaceSecondary: const Color(0xFFEAEAE8),
  surfaceElevated: const Color(0xFFFAFAF9),
  surfaceHover: const Color(0xFFE2E2E0),
  line: const Color(0x18232325),
  lineStrong: const Color(0x7058585C),
  text: const Color(0xFF202124),
  muted: const Color(0xFF34363C),
  subtle: const Color(0xFF626368),
  accent: const Color(0xFF1756C0),
  accentSoft: const Color(0xFF154CA8),
  danger: const Color(0xFFBA3040),
  onAccent: const Color(0xFFFFFFFF),
);

final _liquidGlassDarkColors = YumeiroColorTokens.dark.copyWith(
  background: const Color(0xFF1C1D20),
  sidebar: const Color(0xFF25262A),
  surface: const Color(0xFF242528),
  surfaceSecondary: const Color(0xFF303136),
  surfaceElevated: const Color(0xFF303136),
  surfaceHover: const Color(0xFF3C3D43),
  line: const Color(0x20FFFFFF),
  lineStrong: const Color(0x708E8F96),
  text: const Color(0xFFF5F5F7),
  muted: const Color(0xFFE2E3E8),
  subtle: const Color(0xFFB4B4BC),
  accent: const Color(0xFFAACBFF),
  accentSoft: const Color(0xFFD3E4FF),
  danger: const Color(0xFFFFA7B4),
  onAccent: Colors.black,
);

enum _MaterialStyle { minimal, liquidGlass }

YumeiroSemanticVisualTheme _minimalVisuals(
  YumeiroColorTokens colors,
  YumeiroRadiiTokens radii,
  YumeiroMotion motion,
  Map<String, Object> parameters, {
  required Color dangerForeground,
}) => _materialStyleVisuals(
  colors,
  radii,
  motion,
  _MaterialStyle.minimal,
  parameters,
  statusForegrounds: {
    YumeiroStatusRole.accent: colors.accentSoft,
    YumeiroStatusRole.danger: dangerForeground,
  },
);

YumeiroSemanticVisualTheme _liquidGlassVisuals(
  YumeiroColorTokens colors,
  YumeiroRadiiTokens radii,
  YumeiroMotion motion, [
  Map<String, Object> parameters = const {},
]) => _materialStyleVisuals(
  colors,
  radii,
  motion,
  _MaterialStyle.liquidGlass,
  parameters,
);

YumeiroSemanticVisualTheme _materialStyleVisuals(
  YumeiroColorTokens colors,
  YumeiroRadiiTokens radii,
  YumeiroMotion motion,
  _MaterialStyle style,
  Map<String, Object> parameters, {
  Map<YumeiroStatusRole, Color> statusForegrounds = const {},
}) => _variantVisuals(
  colors,
  radii,
  motion,
  statusForegrounds: statusForegrounds,
  destinationBackground: style == _MaterialStyle.liquidGlass,
  focus: YumeiroFocusIndicator(side: BorderSide(color: colors.accent, width: 2)),
  pressedScale: style == _MaterialStyle.liquidGlass ? .985 : 1,
  navigationForeground: style == _MaterialStyle.liquidGlass
      ? colors.text
      : null,
  paint: (role, value, states) {
    if (role == YumeiroControlRole.overlay) return value;
    final primary = role == YumeiroControlRole.primary;
    final danger = role == YumeiroControlRole.danger;
    final action = primary || danger;
    final neutral =
        role == YumeiroControlRole.neutral ||
        role == YumeiroControlRole.secondary;
    final raised = _isRaisedSurface(role);
    final inset = role == YumeiroSurfaceRole.inset;
    final compact = role == YumeiroSurfaceRole.compact;
    final control = action || neutral;
    final pressed = states.contains(WidgetState.pressed);

    if (style == _MaterialStyle.liquidGlass) {
      return _liquidGlassPaint(role, value, states, colors, parameters);
    }
    if (role == YumeiroSurfaceRole.canvas ||
        role == YumeiroSurfaceRole.navigation) {
      return value.copyWith(effects: YumeiroEffectStack.none);
    }
    final outlined =
        neutral ||
        inset ||
        raised ||
        compact ||
        role == YumeiroSurfaceRole.panel;
    final shadows = <BoxShadow>[
      if (role == YumeiroSurfaceRole.floating ||
          role == YumeiroSurfaceRole.modal ||
          role == YumeiroSurfaceRole.toast)
        BoxShadow(
          color: Colors.black.withValues(alpha: .14),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
    ];
    final innerHighlight = _materialRatio(
      parameters,
      'innerHighlight',
      defaultValue: 0,
    );
    return value.copyWith(
      outline: outlined ? BorderSide(color: colors.line) : BorderSide.none,
      effects: YumeiroEffectStack(
        outerShadows: shadows,
        innerShadows: [
          if (control && (pressed || innerHighlight > 0))
            YumeiroInnerShadow(
              color: pressed
                  ? Colors.black.withValues(alpha: .06)
                  : _materialAlpha(
                      Colors.white.withValues(alpha: .06),
                      innerHighlight,
                    ),
              blurRadius: pressed ? 2 : 1,
              offset: const Offset(0, 1),
              isHighlight: !pressed,
            ),
        ],
      ),
    );
  },
);

const _glassBaseOpacity = .015;

YumeiroVisualAppearance _liquidGlassPaint(
  YumeiroVisualRole role,
  YumeiroVisualAppearance value,
  Set<WidgetState> states,
  YumeiroColorTokens colors,
  Map<String, Object> parameters,
) {
  if (role == YumeiroSurfaceRole.canvas) return value;
  final navigation = role == YumeiroSurfaceRole.navigation;
  final floating =
      role == YumeiroSurfaceRole.floating || role == YumeiroSurfaceRole.toast;
  final modal = role == YumeiroSurfaceRole.modal;
  final backgroundCard =
      role == YumeiroSurfaceRole.panel || role == YumeiroSurfaceRole.card;
  final container = navigation || floating || modal || backgroundCard;
  final tintedAction =
      role == YumeiroControlRole.primary || role == YumeiroControlRole.danger;
  final secondary = role == YumeiroControlRole.secondary;
  final neutral = role == YumeiroControlRole.neutral;
  final choice = role == YumeiroItemRole.selection;
  final navigationItem = role == YumeiroItemRole.navigation;
  final ghost = role == YumeiroControlRole.ghost;
  final lightweight = _isActiveLightweight(role, states);
  final pressed = states.contains(WidgetState.pressed);
  final selected = states.contains(WidgetState.selected);
  if (role == YumeiroSurfaceRole.compact && !selected) {
    value = value.copyWith(foreground: colors.muted);
  }
  final selectionTint = colors.accent;

  if (navigationItem || ghost || secondary || neutral || choice) {
    value = value.copyWith(foreground: colors.text);
  }
  final optical =
      container ||
      tintedAction ||
      neutral ||
      secondary ||
      (navigationItem && selected) ||
      ((ghost || choice) && lightweight);
  if (!optical) {
    var fill = value.background;
    if (role == YumeiroSurfaceRole.media) {
      fill = fill.withValues(alpha: .58);
    } else if (role == YumeiroSurfaceRole.inset ||
        role == YumeiroSurfaceRole.compact) {
      fill = fill.withValues(
        alpha: role == YumeiroSurfaceRole.compact ? .35 : _glassBaseOpacity,
      );
    }
    if (lightweight) {
      fill = selected
          ? yumeiroAlphaBlend(
              selectionTint.withValues(alpha: .36),
              colors.surfaceElevated.withValues(alpha: .88),
            )
          : colors.text.withValues(alpha: pressed ? .10 : .05);
    }
    return value.copyWith(
      fill: YumeiroSolidFill(fill),
      outline: BorderSide.none,
      effects: YumeiroEffectStack.none,
    );
  }
  if (tintedAction) {
    value = value.copyWith(
      fill: YumeiroSolidFill(
        Color.lerp(
          role == YumeiroControlRole.danger ? colors.danger : colors.accent,
          colors.text,
          pressed
              ? .12
              : states.contains(WidgetState.hovered)
              ? .06
              : 0,
        )!,
      ),
    );
  }
  final tint = tintedAction
      ? value.background
      : navigation
      ? colors.sidebar
      : colors.surfaceElevated;
  final actionOpacity = (parameters['actionOpacity'] as double? ?? 40) / 100;
  final glassEdgeRatio = _materialRatio(parameters, 'glassEdge');

  return value.copyWith(
    fill: YumeiroSolidFill(
      yumeiroAlphaBlend(
        selected && !tintedAction
            ? selectionTint.withValues(alpha: pressed ? .42 : .36)
            : Colors.transparent,
        tint.withValues(
          alpha: tintedAction ? actionOpacity : _glassBaseOpacity,
        ),
      ),
    ),
    outline: BorderSide.none,
    effects: YumeiroEffectStack(
      backdropBlur: navigation || floating
          ? 18
          : container
          ? 0
          : tintedAction
          ? .4
          : .6,
      backdropTint: tint.withValues(alpha: tintedAction ? 1 : .76),
      glass: YumeiroGlassEffect(
        tint: tint,
        refraction: navigation ? 20 : 16,
        thickness: (navigation ? 14 : 11) * glassEdgeRatio,
        pressure: !container && pressed ? 1 : 0,
        lighting: container || parameters['glassLighting'] == false ? 0 : 1,
      ),
      outerShadows: [
        if (floating || modal)
          BoxShadow(
            color: Colors.black.withValues(alpha: .14),
            blurRadius: 24,
            offset: const Offset(0, 3),
          )
        else if (tintedAction)
          BoxShadow(
            color: Colors.black.withValues(alpha: .08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
      ],
    ),
  );
}
