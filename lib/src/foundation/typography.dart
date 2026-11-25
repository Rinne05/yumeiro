import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import 'modality.dart';

/// Cross-platform sans-serif fallback list covering Latin and CJK scripts.
const List<String> kYumeiroFontFallback = <String>[
  'Segoe UI',
  'PingFang SC',
  'Hiragino Sans GB',
  'Microsoft YaHei UI',
  'Noto Sans SC',
  'Noto Sans CJK SC',
  'Source Han Sans SC',
  'SF Pro Display',
  'SF Pro Text',
  'Roboto',
  'Helvetica Neue',
  'Arial',
  'sans-serif',
];

// Prefer native font families to avoid fuzzy cross-platform matches.
List<String> _platformDefaultFontFallback() {
  if (kIsWeb) return kYumeiroFontFallback;
  return switch (defaultTargetPlatform) {
    TargetPlatform.windows => const <String>[
      'Segoe UI',
      'Microsoft YaHei UI',
      'Microsoft YaHei',
      'Noto Sans SC',
      'Noto Sans CJK SC',
      'Source Han Sans SC',
      'Arial',
      'sans-serif',
    ],
    TargetPlatform.macOS || TargetPlatform.iOS => const <String>[
      'SF Pro Text',
      'SF Pro Display',
      'PingFang SC',
      'Hiragino Sans GB',
      'Helvetica Neue',
      'Arial',
      'sans-serif',
    ],
    TargetPlatform.linux => const <String>[
      'sans-serif',
      'Noto Sans',
      'Noto Sans SC',
      'Noto Sans CJK SC',
      'Source Han Sans SC',
      'Source Han Sans CN',
      'WenQuanYi Micro Hei',
    ],
    TargetPlatform.android || TargetPlatform.fuchsia => const <String>[
      'Roboto',
      'Noto Sans SC',
      'Noto Sans CJK SC',
      'Source Han Sans SC',
      'sans-serif',
    ],
  };
}

/// Canonical monospaced fallback list for tabular numbers, code, and readouts.
const List<String> kYumeiroMonoFontFallback = <String>[
  'Cascadia Code',
  'JetBrains Mono',
  'SF Mono',
  'Fira Code',
  'Menlo',
  'Consolas',
  'monospace',
];

/// Host-configurable typography family and fallback configuration.
@immutable
class YumeiroFontConfig {
  const YumeiroFontConfig({
    this.fontFamily,
    this.fontFallback = kYumeiroFontFallback,
    this.monoFontFamily = 'Cascadia Code',
    this.monoFontFallback = kYumeiroMonoFontFallback,
  });

  final String? fontFamily;

  /// Sans-serif fallback order. The default list resolves to the active
  /// platform's stack.
  final List<String> fontFallback;
  final String monoFontFamily;
  final List<String> monoFontFallback;

  /// Computed sans-serif stack with a nonempty [fontFamily] first.
  List<String> get resolvedFontFallback {
    final fallback = identical(fontFallback, kYumeiroFontFallback)
        ? _platformDefaultFontFallback()
        : fontFallback;
    final primary = fontFamily?.trim();
    if (primary == null || primary.isEmpty) return fallback;
    return List<String>.unmodifiable([primary, ...fallback]);
  }

  YumeiroFontConfig copyWith({
    String? fontFamily,
    List<String>? fontFallback,
    String? monoFontFamily,
    List<String>? monoFontFallback,
  }) => YumeiroFontConfig(
    fontFamily: fontFamily ?? this.fontFamily,
    fontFallback: fontFallback ?? this.fontFallback,
    monoFontFamily: monoFontFamily ?? this.monoFontFamily,
    monoFontFallback: monoFontFallback ?? this.monoFontFallback,
  );
}

/// Theme text styles and font configuration for Yumeiro components.
@immutable
class YumeiroTypographyTokens {
  /// Wraps a text theme containing the styles and weights read by the tokens.
  /// Use [forModality] to adapt the resolved scale for touch.
  const YumeiroTypographyTokens({
    required this.textTheme,
    this.fontConfig = const YumeiroFontConfig(),
  });

  final TextTheme textTheme;
  final YumeiroFontConfig fontConfig;

  String get monoFontFamily => fontConfig.monoFontFamily;

  FontWeight get bodyWeight => textTheme.bodyMedium!.fontWeight!;
  FontWeight get emphasisWeight => textTheme.labelMedium!.fontWeight!;
  FontWeight get headingWeight => textTheme.displaySmall!.fontWeight!;

  FontWeight controlWeight({bool selected = false}) =>
      selected ? emphasisWeight : textTheme.labelLarge!.fontWeight!;

  TextStyle get body => textTheme.bodyMedium!;
  TextStyle get supporting => textTheme.bodySmall!;
  TextStyle get caption => textTheme.labelSmall!;
  TextStyle get title => textTheme.titleMedium!;
  TextStyle get pageTitle => textTheme.displaySmall!;

  TextStyle control({
    bool selected = false,
    bool dense = false,
    bool monospace = false,
  }) => (dense ? caption : textTheme.labelLarge!).copyWith(
    fontWeight: controlWeight(selected: selected),
    fontFamily: monospace ? fontConfig.monoFontFamily : null,
    fontFamilyFallback: monospace ? fontConfig.monoFontFallback : null,
    fontFeatures: monospace ? const [FontFeature.tabularFigures()] : null,
  );

  TextStyle tag({
    bool selected = false,
    bool interactive = false,
    bool dense = false,
  }) => (dense ? caption : textTheme.labelMedium!).copyWith(
    fontWeight: interactive ? controlWeight(selected: selected) : bodyWeight,
  );

  TextStyle input({bool dense = false}) =>
      (dense ? caption : body).copyWith(fontWeight: bodyWeight);

  TextStyle option({bool selected = false, bool dense = false}) =>
      input(dense: dense)
          .copyWith(fontWeight: selected ? emphasisWeight : bodyWeight);

  TextStyle mono({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    List<FontFeature>? fontFeatures,
  }) => body.copyWith(
    fontFamily: fontConfig.monoFontFamily,
    fontFamilyFallback: fontConfig.monoFontFallback,
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
    fontFeatures: fontFeatures ?? const [FontFeature.tabularFigures()],
  );

  /// Adapts type scale for [modality] while preserving the preset's font
  /// family, weights, letter spacing, and line heights.
  YumeiroTypographyTokens forModality(YumeiroModality modality) {
    if (modality == YumeiroModality.pointer) return this;
    return copyWith(
      textTheme: textTheme.copyWith(
        displaySmall: textTheme.displaySmall?.copyWith(fontSize: 20),
        titleLarge: textTheme.titleLarge?.copyWith(fontSize: 20),
        titleMedium: textTheme.titleMedium?.copyWith(fontSize: 16),
        titleSmall: textTheme.titleSmall?.copyWith(fontSize: 16),
        bodyLarge: textTheme.bodyLarge?.copyWith(fontSize: 16),
        bodyMedium: textTheme.bodyMedium?.copyWith(fontSize: 16),
        bodySmall: textTheme.bodySmall?.copyWith(fontSize: 14),
        labelLarge: textTheme.labelLarge?.copyWith(fontSize: 16),
        labelMedium: textTheme.labelMedium?.copyWith(fontSize: 14),
        labelSmall: textTheme.labelSmall?.copyWith(fontSize: 12),
      ),
    );
  }

  factory YumeiroTypographyTokens.fromColors({
    required Color text,
    required Color muted,
    YumeiroFontConfig fontConfig = const YumeiroFontConfig(),
  }) {
    final rawTheme = TextTheme(
      displaySmall: TextStyle(
        color: text,
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        height: 1.25,
      ),
      headlineSmall: TextStyle(
        color: text,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        height: 1.25,
      ),
      titleLarge: TextStyle(
        color: text,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.25,
      ),
      titleMedium: TextStyle(
        color: text,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),
      titleSmall: TextStyle(
        color: text,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),
      bodyLarge: TextStyle(
        color: text,
        fontSize: 13.5,
        height: 1.5,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: TextStyle(
        color: text,
        fontSize: 12.5,
        height: 1.5,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: TextStyle(
        color: muted,
        fontSize: 11.5,
        height: 1.45,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: TextStyle(
        color: text,
        fontSize: 12.5,
        fontWeight: FontWeight.w500,
        height: 1.25,
      ),
      labelMedium: TextStyle(
        color: muted,
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),
      labelSmall: TextStyle(
        color: muted,
        fontSize: 11,
        fontWeight: FontWeight.w400,
        height: 1.25,
      ),
    );

    final effectiveFallback = fontConfig.resolvedFontFallback;
    final primaryFamily = fontConfig.fontFamily?.trim();
    final effectiveFamily = (primaryFamily != null && primaryFamily.isNotEmpty)
        ? primaryFamily
        : effectiveFallback.firstOrNull;

    return YumeiroTypographyTokens(
      fontConfig: fontConfig,
      textTheme: rawTheme.apply(
        fontFamily: effectiveFamily,
        fontFamilyFallback: effectiveFallback,
      ),
    );
  }

  YumeiroTypographyTokens copyWith({
    TextTheme? textTheme,
    YumeiroFontConfig? fontConfig,
  }) => YumeiroTypographyTokens(
    textTheme: textTheme ?? this.textTheme,
    fontConfig: fontConfig ?? this.fontConfig,
  );

  YumeiroTypographyTokens lerp(YumeiroTypographyTokens other, double t) =>
      YumeiroTypographyTokens(
        textTheme: TextTheme.lerp(textTheme, other.textTheme, t),
        fontConfig: t < .5 ? fontConfig : other.fontConfig,
      );
}

/// Applies typography while preserving the foreground color owned by the
/// enclosing semantic surface.
class YumeiroTextStyle extends StatelessWidget {
  const YumeiroTextStyle({super.key, required this.style, required this.child});

  final TextStyle style;
  final Widget child;

  @override
  Widget build(BuildContext context) => DefaultTextStyle.merge(
    style: style.copyWith(color: DefaultTextStyle.of(context).style.color),
    child: child,
  );
}
