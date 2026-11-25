import 'package:material_ui/material_ui.dart';

/// Size scale for semantic icons across Yumeiro components.
@immutable
class YumeiroIconSizes {
  const YumeiroIconSizes({
    this.xs = 14,
    this.sm = 16,
    this.md = 18,
    this.lg = 28,
    this.xl = 40,
  });

  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;

  YumeiroIconSizes copyWith({
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
  }) => YumeiroIconSizes(
    xs: xs ?? this.xs,
    sm: sm ?? this.sm,
    md: md ?? this.md,
    lg: lg ?? this.lg,
    xl: xl ?? this.xl,
  );

  YumeiroIconSizes lerp(YumeiroIconSizes other, double t) => YumeiroIconSizes(
    xs: _lerp(xs, other.xs, t),
    sm: _lerp(sm, other.sm, t),
    md: _lerp(md, other.md, t),
    lg: _lerp(lg, other.lg, t),
    xl: _lerp(xl, other.xl, t),
  );

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}

/// Replaceable icon slot configuration for all built-in framework widgets
/// and theme family indicators.
///
/// Defaults to standard Flutter Material [Icons] so the framework requires no
/// external icon font dependency, while allowing host apps to inject any icon
/// pack (e.g., Lucide, Phosphor, MingCute, Cupertino) via [YumeiroScope].
@immutable
class YumeiroIconSet {
  const YumeiroIconSet({
    required this.search,
    required this.close,
    required this.check,
    required this.chevronDown,
    required this.chevronUp,
    required this.chevronLeft,
    required this.chevronRight,
    required this.add,
    required this.remove,
    required this.edit,
    required this.delete,
    required this.settings,
    required this.info,
    required this.success,
    required this.warning,
    required this.error,
    required this.menu,
    required this.more,
    required this.refresh,
    required this.copy,
    required this.filter,
    required this.sort,
    required this.visibilityOn,
    required this.visibilityOff,
    required this.palette,
    required this.layers,
    required this.themeDark,
    required this.themeLight,
    required this.themeGeek,
    required this.themeSketch,
    required this.themeNeumorphic,
    required this.themeMinimal,
    required this.themeLiquidGlass,
    this.themeCeramic = Icons.coffee_outlined,
    this.themeBrushedMetal = Icons.memory_outlined,
    this.themeNeoBrutalist = Icons.view_quilt_outlined,
    this.themePixel = Icons.grid_on_outlined,
    this.themeAcrylic = Icons.blur_on_outlined,
    this.themeSilicone = Icons.bubble_chart_outlined,
    this.themeFrostedGlass = Icons.auto_awesome_outlined,
    this.back = Icons.arrow_back_rounded,
    this.star = Icons.star_outline_rounded,
    this.starFilled = Icons.star_rounded,
    this.starHalf = Icons.star_half_rounded,
    this.person = Icons.person_outline_rounded,
    this.imageUnavailable = Icons.broken_image_outlined,
    this.play = Icons.play_arrow_rounded,
    this.auto = Icons.auto_awesome_outlined,
    this.media = Icons.perm_media_outlined,
  });

  factory YumeiroIconSet.material() => const YumeiroIconSet(
    search: Icons.search_rounded,
    close: Icons.close_rounded,
    check: Icons.check_rounded,
    chevronDown: Icons.keyboard_arrow_down_rounded,
    chevronUp: Icons.keyboard_arrow_up_rounded,
    chevronLeft: Icons.keyboard_arrow_left_rounded,
    chevronRight: Icons.keyboard_arrow_right_rounded,
    add: Icons.add_rounded,
    remove: Icons.remove_rounded,
    edit: Icons.edit_outlined,
    delete: Icons.delete_outline_rounded,
    settings: Icons.tune_rounded,
    info: Icons.info_outline_rounded,
    success: Icons.check_circle_outline_rounded,
    warning: Icons.warning_amber_rounded,
    error: Icons.error_outline_rounded,
    menu: Icons.menu_rounded,
    more: Icons.more_horiz_rounded,
    refresh: Icons.refresh_rounded,
    copy: Icons.content_copy_rounded,
    filter: Icons.filter_list_rounded,
    sort: Icons.sort_rounded,
    visibilityOn: Icons.visibility_outlined,
    visibilityOff: Icons.visibility_off_outlined,
    palette: Icons.palette_outlined,
    layers: Icons.layers_outlined,
    themeDark: Icons.dark_mode_outlined,
    themeLight: Icons.light_mode_outlined,
    themeGeek: Icons.terminal_rounded,
    themeSketch: Icons.draw_outlined,
    themeNeumorphic: Icons.circle_outlined,
    themeMinimal: Icons.crop_square_rounded,
    themeLiquidGlass: Icons.water_drop_outlined,
    back: Icons.arrow_back_rounded,
    star: Icons.star_outline_rounded,
    starFilled: Icons.star_rounded,
    starHalf: Icons.star_half_rounded,
    person: Icons.person_outline_rounded,
    imageUnavailable: Icons.broken_image_outlined,
    play: Icons.play_arrow_rounded,
    auto: Icons.auto_awesome_outlined,
    media: Icons.perm_media_outlined,
  );

  final IconData search;
  final IconData close;
  final IconData check;
  final IconData chevronDown;
  final IconData chevronUp;
  final IconData chevronLeft;
  final IconData chevronRight;
  final IconData add;
  final IconData remove;
  final IconData edit;
  final IconData delete;
  final IconData settings;
  final IconData info;
  final IconData success;
  final IconData warning;
  final IconData error;
  final IconData menu;
  final IconData more;
  final IconData refresh;
  final IconData copy;
  final IconData filter;
  final IconData sort;
  final IconData visibilityOn;
  final IconData visibilityOff;
  final IconData palette;
  final IconData layers;
  final IconData themeDark;
  final IconData themeLight;
  final IconData themeGeek;
  final IconData themeSketch;
  final IconData themeNeumorphic;
  final IconData themeMinimal;
  final IconData themeLiquidGlass;
  final IconData themeCeramic;
  final IconData themeBrushedMetal;
  final IconData themeNeoBrutalist;
  final IconData themePixel;
  final IconData themeAcrylic;
  final IconData themeSilicone;
  final IconData themeFrostedGlass;
  final IconData back;
  final IconData star;
  final IconData starFilled;
  final IconData starHalf;
  final IconData person;
  final IconData imageUnavailable;
  final IconData play;
  final IconData auto;
  final IconData media;

  IconData? forThemeFamily(String familyId) => switch (familyId) {
    'classic' => themeDark,
    'geek' => themeGeek,
    'sketch' => themeSketch,
    'neumorphic' => themeNeumorphic,
    'minimal' => themeMinimal,
    'liquid-glass' => themeLiquidGlass,
    'ceramic' => themeCeramic,
    'brushed-metal' => themeBrushedMetal,
    'neo-brutalist' => themeNeoBrutalist,
    'pixel' => themePixel,
    'acrylic' => themeAcrylic,
    'silicone' => themeSilicone,
    'frosted-glass' => themeFrostedGlass,
    _ => null,
  };

  YumeiroIconSet copyWith({
    IconData? search,
    IconData? close,
    IconData? check,
    IconData? chevronDown,
    IconData? chevronUp,
    IconData? chevronLeft,
    IconData? chevronRight,
    IconData? add,
    IconData? remove,
    IconData? edit,
    IconData? delete,
    IconData? settings,
    IconData? info,
    IconData? success,
    IconData? warning,
    IconData? error,
    IconData? menu,
    IconData? more,
    IconData? refresh,
    IconData? copy,
    IconData? filter,
    IconData? sort,
    IconData? visibilityOn,
    IconData? visibilityOff,
    IconData? palette,
    IconData? layers,
    IconData? themeDark,
    IconData? themeLight,
    IconData? themeGeek,
    IconData? themeSketch,
    IconData? themeNeumorphic,
    IconData? themeMinimal,
    IconData? themeLiquidGlass,
    IconData? themeCeramic,
    IconData? themeBrushedMetal,
    IconData? themeNeoBrutalist,
    IconData? themePixel,
    IconData? themeAcrylic,
    IconData? themeSilicone,
    IconData? themeFrostedGlass,
    IconData? back,
    IconData? star,
    IconData? starFilled,
    IconData? starHalf,
    IconData? person,
    IconData? imageUnavailable,
    IconData? play,
    IconData? auto,
    IconData? media,
  }) => YumeiroIconSet(
    search: search ?? this.search,
    close: close ?? this.close,
    check: check ?? this.check,
    chevronDown: chevronDown ?? this.chevronDown,
    chevronUp: chevronUp ?? this.chevronUp,
    chevronLeft: chevronLeft ?? this.chevronLeft,
    chevronRight: chevronRight ?? this.chevronRight,
    add: add ?? this.add,
    remove: remove ?? this.remove,
    edit: edit ?? this.edit,
    delete: delete ?? this.delete,
    settings: settings ?? this.settings,
    info: info ?? this.info,
    success: success ?? this.success,
    warning: warning ?? this.warning,
    error: error ?? this.error,
    menu: menu ?? this.menu,
    more: more ?? this.more,
    refresh: refresh ?? this.refresh,
    copy: copy ?? this.copy,
    filter: filter ?? this.filter,
    sort: sort ?? this.sort,
    visibilityOn: visibilityOn ?? this.visibilityOn,
    visibilityOff: visibilityOff ?? this.visibilityOff,
    palette: palette ?? this.palette,
    layers: layers ?? this.layers,
    themeDark: themeDark ?? this.themeDark,
    themeLight: themeLight ?? this.themeLight,
    themeGeek: themeGeek ?? this.themeGeek,
    themeSketch: themeSketch ?? this.themeSketch,
    themeNeumorphic: themeNeumorphic ?? this.themeNeumorphic,
    themeMinimal: themeMinimal ?? this.themeMinimal,
    themeLiquidGlass: themeLiquidGlass ?? this.themeLiquidGlass,
    themeCeramic: themeCeramic ?? this.themeCeramic,
    themeBrushedMetal: themeBrushedMetal ?? this.themeBrushedMetal,
    themeNeoBrutalist: themeNeoBrutalist ?? this.themeNeoBrutalist,
    themePixel: themePixel ?? this.themePixel,
    themeAcrylic: themeAcrylic ?? this.themeAcrylic,
    themeSilicone: themeSilicone ?? this.themeSilicone,
    themeFrostedGlass: themeFrostedGlass ?? this.themeFrostedGlass,
    back: back ?? this.back,
    star: star ?? this.star,
    starFilled: starFilled ?? this.starFilled,
    starHalf: starHalf ?? this.starHalf,
    person: person ?? this.person,
    imageUnavailable: imageUnavailable ?? this.imageUnavailable,
    play: play ?? this.play,
    auto: auto ?? this.auto,
    media: media ?? this.media,
  );
}
