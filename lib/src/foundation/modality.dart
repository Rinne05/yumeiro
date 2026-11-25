import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:material_ui/material_ui.dart';

/// Unified interaction modality controlling hit targets, spacing density,
/// typography scale, and responsive presentation patterns.
enum YumeiroModality {
  /// Precision pointer/keyboard interaction (desktop, web cursor, trackpad).
  pointer,

  /// Coarse touch interaction (mobile, tablet, touch-first shells).
  touch,
}

/// Layout density factor orthogonal to [YumeiroModality].
enum YumeiroDensity { compact, standard, comfortable }

/// Viewport width classification independent of interaction modality.
enum YumeiroScreenClass { compact, medium, expanded, wide }

/// Logical-pixel width thresholds used by responsive layouts.
abstract final class YumeiroBreakpoints {
  static const compact = 600.0;
  static const medium = 840.0;
  static const expanded = 1280.0;
  static const wide = 1440.0;

  /// Assigns a width class. The boundaries 600, 840, and 1280 start the
  /// medium, expanded, and wide classes respectively.
  static YumeiroScreenClass classify(double width) {
    if (width < compact) return YumeiroScreenClass.compact;
    if (width < medium) return YumeiroScreenClass.medium;
    if (width < expanded) return YumeiroScreenClass.expanded;
    return YumeiroScreenClass.wide;
  }
}

/// Resolved layout & sizing metrics derived from ([modality], [density]).
@immutable
class YumeiroMetrics {
  const YumeiroMetrics({
    required this.modality,
    required this.density,
    required this.minTargetSize,
    required this.controlHeight,
    required this.denseControlHeight,
    required this.checkboxSize,
    required this.chipHeight,
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.rowGap,
  });

  factory YumeiroMetrics.resolve({
    required YumeiroModality modality,
    YumeiroDensity density = YumeiroDensity.standard,
  }) {
    final densityDelta = switch (density) {
      YumeiroDensity.compact => -4.0,
      YumeiroDensity.standard => 0.0,
      YumeiroDensity.comfortable => 4.0,
    };
    final controlHeight = 40.0 + densityDelta;
    final denseDelta = densityDelta / 2;
    if (modality == YumeiroModality.touch) {
      return YumeiroMetrics(
        modality: modality,
        density: density,
        minTargetSize: 48.0 + densityDelta,
        controlHeight: controlHeight,
        denseControlHeight: 36.0 + denseDelta,
        checkboxSize: 20.0,
        chipHeight: 30.0 + denseDelta,
        horizontalPadding: 16.0 + denseDelta,
        verticalPadding: 12.0 + denseDelta,
        rowGap: 12.0 + denseDelta,
      );
    }
    return YumeiroMetrics(
      modality: modality,
      density: density,
      minTargetSize: controlHeight,
      controlHeight: controlHeight,
      denseControlHeight: 30.0 + denseDelta,
      checkboxSize: 18.0,
      chipHeight: 26.0 + denseDelta,
      horizontalPadding: 12.0 + denseDelta,
      verticalPadding: 8.0 + denseDelta,
      rowGap: 8.0 + denseDelta,
    );
  }

  final YumeiroModality modality;
  final YumeiroDensity density;
  final double minTargetSize;
  final double controlHeight;
  final double denseControlHeight;
  final double checkboxSize;
  final double chipHeight;
  final double horizontalPadding;
  final double verticalPadding;
  final double rowGap;

  bool get isTouch => modality == YumeiroModality.touch;
  bool get isPointer => modality == YumeiroModality.pointer;

  /// Dense visuals retain the modality's minimum interactive target.
  double get denseTargetSize => isTouch ? minTargetSize : denseControlHeight;
  EdgeInsets get denseControlVisualInsets => EdgeInsets.symmetric(
    vertical: ((denseTargetSize - denseControlHeight) / 2).clamp(0.0, 12.0),
  );

  double get denseChipHeight => isTouch
      ? (chipHeight - 6.0).clamp(22.0, 28.0)
      : (chipHeight - 4.0).clamp(20.0, 26.0);

  /// Vertical/horizontal visual inset to keep a compact visual shell inside
  /// a touch-compliant hit target.
  EdgeInsets get controlVisualInsets {
    final inset = ((minTargetSize - controlHeight) / 2).clamp(0.0, 12.0);
    return EdgeInsets.symmetric(vertical: inset);
  }

  @override
  bool operator ==(Object other) =>
      other is YumeiroMetrics &&
      modality == other.modality &&
      density == other.density;

  @override
  int get hashCode => Object.hash(modality, density);
}

/// Responsive snapshot combining viewport size with [YumeiroModality].
@immutable
class YumeiroResponsive {
  const YumeiroResponsive({required this.width, required this.modality});

  /// Resolves against the current MediaQuery viewport.
  ///
  /// Use [YumeiroLayoutBuilder] for the local width of a constrained panel.
  factory YumeiroResponsive.of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final modality = YumeiroModalityScope.modalityOf(context);
    return YumeiroResponsive(width: width, modality: modality);
  }

  final double width;
  final YumeiroModality modality;

  YumeiroScreenClass get screenClass => YumeiroBreakpoints.classify(width);
  bool get isCompact => screenClass == YumeiroScreenClass.compact;
  bool get isMedium => screenClass == YumeiroScreenClass.medium;
  bool get isExpanded =>
      screenClass == YumeiroScreenClass.expanded ||
      screenClass == YumeiroScreenClass.wide;
  bool get isWide => screenClass == YumeiroScreenClass.wide;

  double get pageHorizontalPadding => isCompact
      ? 16
      : isWide
      ? 48
      : isExpanded
      ? 34
      : 28;

  double sidebarWidth({required bool collapsed}) => collapsed ? 76 : 210;
}

/// Provides unified [YumeiroModality], [YumeiroDensity], and resolved
/// [YumeiroMetrics] to the widget subtree.
class YumeiroModalityScope extends InheritedWidget {
  const YumeiroModalityScope({
    super.key,
    required this.modality,
    this.density = YumeiroDensity.standard,
    required super.child,
  });

  final YumeiroModality modality;
  final YumeiroDensity density;

  YumeiroMetrics get metrics =>
      YumeiroMetrics.resolve(modality: modality, density: density);

  /// Resolves the default interaction mode for the current platform.
  static YumeiroModality inferModality() => switch (defaultTargetPlatform) {
    TargetPlatform.iOS ||
    TargetPlatform.android ||
    TargetPlatform.fuchsia => YumeiroModality.touch,
    TargetPlatform.linux ||
    TargetPlatform.macOS ||
    TargetPlatform.windows => YumeiroModality.pointer,
  };

  static YumeiroModalityScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<YumeiroModalityScope>();

  static YumeiroModality modalityOf(BuildContext context) =>
      maybeOf(context)?.modality ?? inferModality();

  static YumeiroDensity densityOf(BuildContext context) =>
      maybeOf(context)?.density ?? YumeiroDensity.standard;

  static YumeiroMetrics metricsOf(BuildContext context) =>
      maybeOf(context)?.metrics ??
      YumeiroMetrics.resolve(
        modality: inferModality(),
        density: YumeiroDensity.standard,
      );

  @override
  bool updateShouldNotify(YumeiroModalityScope oldWidget) =>
      modality != oldWidget.modality || density != oldWidget.density;
}

/// Builds a subtree with responsive information for its enclosing constraints.
typedef YumeiroLayoutWidgetBuilder = Widget Function(
  BuildContext context,
  YumeiroResponsive responsive,
);

/// LayoutBuilder supplying [YumeiroResponsive] for the enclosing constraints.
class YumeiroLayoutBuilder extends StatelessWidget {
  const YumeiroLayoutBuilder({super.key, required this.builder});

  final YumeiroLayoutWidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    final modality = YumeiroModalityScope.modalityOf(context);
    return LayoutBuilder(
      builder: (context, constraints) => builder(
        context,
        YumeiroResponsive(width: constraints.maxWidth, modality: modality),
      ),
    );
  }
}
