import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';

import '../../foundation/modality.dart';
import '../../l10n/localizations.dart';
import '../../primitives/pixel_border.dart';
import '../../primitives/visual_surface.dart';
import '../../theme/semantic_visuals.dart';
import '../../theme/theme.dart';
import '../../theme/theme_extension.dart';
import '../../theme/visual_role.dart';
import '../controls/rating_stars.dart';
import 'badges.dart';

/// Shared image frame for artwork, thumbnails, and avatars.
///
/// The design system receives an [ImageProvider] only; URI parsing, headers,
/// and decode sizing belong to the host image infrastructure.
class YumeiroArtworkImage extends StatelessWidget {
  const YumeiroArtworkImage({
    super.key,
    this.fit = BoxFit.cover,
    this.image,
    this.backgroundColor,
    this.borderRadius,
    this.fallback,
    this.loading,
    this.fallbackIcon,
    this.fallbackIconSize,
    this.semanticLabel,
  }) : _thumbnailWidth = null,
       _thumbnailHeight = null;

  /// Fixed-size thumbnail for list rows and compact media details.
  const YumeiroArtworkImage.thumbnail({
    super.key,
    this.image,
    double width = 44,
    double height = 58,
    this.borderRadius,
    this.fallback,
    this.loading,
    IconData? icon,
    this.semanticLabel,
  }) : _thumbnailWidth = width,
       _thumbnailHeight = height,
       fit = BoxFit.cover,
       backgroundColor = null,
       fallbackIcon = icon,
       fallbackIconSize = null;

  final ImageProvider<Object>? image;
  final BoxFit fit;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  /// Replacement when the provider is absent or an image fails to load.
  final Widget? fallback;

  /// Replacement while waiting for the first frame. Defaults to [fallback]
  /// or the theme placeholder.
  final Widget? loading;
  final IconData? fallbackIcon;
  final double? fallbackIconSize;
  final String? semanticLabel;
  final double? _thumbnailWidth;
  final double? _thumbnailHeight;

  Widget _fallback(BuildContext context, BorderRadius? radius) {
    final theme = YumeiroTheme.of(context);
    final width = _thumbnailWidth;
    final placeholderIcon = width == null
        ? theme.icons.imageUnavailable
        : theme.icons.media;
    final placeholderSize = width == null
        ? theme.iconSizes.lg
        : math.min(width, _thumbnailHeight!) * .42;
    return YumeiroVisualSurface(
      role: YumeiroSurfaceRole.inset,
      visualOverride: YumeiroVisualOverride(
        base: YumeiroVisualDelta(
          shape: RoundedRectangleBorder(
            borderRadius: radius ?? BorderRadius.zero,
          ),
          fill: backgroundColor == null
              ? null
              : YumeiroSolidFill(backgroundColor!),
        ),
      ),
      child: Center(
        child: Icon(
          fallbackIcon ?? placeholderIcon,
          size: fallbackIconSize ?? placeholderSize,
          color: theme.accentSoft,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final radius =
        borderRadius ??
        (_thumbnailWidth == null
            ? null
            : BorderRadius.circular(YumeiroTheme.of(context).chipRadius));
    final placeholder = fallback ?? _fallback(context, radius);
    final body = DecoratedBox(
      decoration: BoxDecoration(color: backgroundColor),
      child: image == null
          ? placeholder
          : Image(
              image: image!,
              fit: fit,
              excludeFromSemantics: semanticLabel != null,
              frameBuilder: (_, child, frame, _) =>
                  frame == null ? loading ?? placeholder : child,
              errorBuilder: (context, _, _) => placeholder,
            ),
    );
    final framed = radius == null
        ? body
        : ClipRRect(borderRadius: radius, child: body);
    final described = semanticLabel == null
        ? framed
        : Semantics(image: true, label: semanticLabel, child: framed);
    if (_thumbnailWidth == null) return described;
    return SizedBox(
      width: _thumbnailWidth,
      height: _thumbnailHeight,
      child: described,
    );
  }
}

/// A circular avatar following the same image fallback policy.
class YumeiroAvatar extends StatelessWidget {
  const YumeiroAvatar({
    super.key,
    this.image,
    this.radius = 18,
    this.fallback,
    this.semanticLabel,
  });

  final ImageProvider<Object>? image;
  final double radius;
  final Widget? fallback;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    return SizedBox.square(
      dimension: radius * 2,
      child: ClipOval(
        child: YumeiroArtworkImage(
          image: image,
          fallback:
              fallback ??
              Icon(theme.icons.person, size: radius, color: theme.muted),
          semanticLabel: semanticLabel,
        ),
      ),
    );
  }
}

/// Standard progress bar used by media cards and list rows.
class YumeiroProgress extends StatelessWidget {
  const YumeiroProgress({
    super.key,
    required this.value,
    this.height = 3,
    this.color,
    this.backgroundColor,
  });

  final double? value;
  final double height;
  final Color? color;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final shape = theme.visuals.surface(YumeiroSurfaceRole.compact).shape;
    final squareCaps =
        theme.sliderTheme.trackShape is RectangularSliderTrackShape;
    final indicator = LinearProgressIndicator(
      value: value?.clamp(0, 1),
      backgroundColor: backgroundColor ?? theme.surfaceHover,
      color: color ?? theme.accent,
      borderRadius: squareCaps
          ? BorderRadius.zero
          : BorderRadius.circular(theme.chipRadius),
      trackGap: 0,
      stopIndicatorRadius: 0,
    );
    return SizedBox(
      height: height,
      child: shape is YumeiroPixelBorder
          ? ClipPath(
              clipper: ShapeBorderClipper(shape: shape),
              clipBehavior: Clip.hardEdge,
              child: indicator,
            )
          : indicator,
    );
  }
}

/// A compact five-star rating display supporting half-star values.
class YumeiroStarRating extends StatelessWidget {
  const YumeiroStarRating({
    super.key,
    required this.value,
    this.size = 14,
    this.spacing = 1,
    this.color,
  });

  final double value;
  final double size;
  final double spacing;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final l10n = YumeiroLocalizations.of(context);
    final normalizedValue = normalizeRating(value);

    return Semantics(
      label: l10n.ratingValue(
        l10n.ratingOutOfFive(formatRating(normalizedValue)),
      ),
      child: RatingStars(
        value: normalizedValue,
        size: size,
        spacing: spacing,
        color: color ?? theme.rating,
      ),
    );
  }
}

TextStyle _posterTitleStyle(YumeiroThemeExtension theme) =>
    theme.typography.textTheme.titleSmall!;

/// Responsive poster grid preserving aspect ratio and metadata footer height.
class YumeiroPosterGrid extends StatelessWidget {
  const YumeiroPosterGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.minimumTileWidth = 160,
    this.spacing = 14,
    this.runSpacing = 14,
    this.footerExtent = 60,
    this.maximumColumns = 8,
    this.maxRows,
    this.shrinkWrap = false,
    this.physics,
    this.padding,
    this.clipBehavior = Clip.hardEdge,
  }) : _sliver = false;

  /// Builds the grid inside a vertical [CustomScrollView].
  const YumeiroPosterGrid.sliver({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.minimumTileWidth = 160,
    this.spacing = 14,
    this.runSpacing = 14,
    this.footerExtent = 60,
    this.maximumColumns = 8,
    this.maxRows,
    this.padding,
  }) : _sliver = true,
       shrinkWrap = false,
       physics = null,
       clipBehavior = Clip.hardEdge;

  final bool _sliver;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double minimumTileWidth;

  /// Horizontal space between columns, included when calculating their count.
  final double spacing;
  final double runSpacing;
  final double footerExtent;
  final int maximumColumns;

  /// Caps visible items to this number of rows at the current column count.
  final int? maxRows;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;
  final Clip clipBehavior;

  static int calculateColumns({
    required double width,
    double minimumTileWidth = 160,
    double spacing = 14,
    int maximumColumns = 8,
  }) {
    if (width <= 0) return 1;
    return ((width + spacing) / (minimumTileWidth + spacing)).floor().clamp(
      1,
      maximumColumns,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final isTouch = YumeiroModalityScope.metricsOf(context).isTouch;
    final direction = Directionality.of(context);
    final textScaler = MediaQuery.textScalerOf(context);
    Widget buildGrid(double availableWidth) =>
        _grid(availableWidth, theme, isTouch, direction, textScaler);

    if (!_sliver) {
      return LayoutBuilder(
        builder: (_, constraints) => buildGrid(constraints.maxWidth),
      );
    }

    // A new widget or inherited configuration creates a fresh cache. During
    // scrolling, reuse the grid unless its cross-axis extent changes.
    (double, Widget)? cachedGrid;
    return SliverLayoutBuilder(
      builder: (_, constraints) {
        assert(
          constraints.axis == Axis.vertical,
          'YumeiroPosterGrid.sliver requires a vertical scroll view.',
        );
        final width = constraints.crossAxisExtent;
        if (cachedGrid case (final previousWidth, final grid)
            when previousWidth == width) {
          return grid;
        }
        final grid = buildGrid(width);
        cachedGrid = (width, grid);
        return grid;
      },
    );
  }

  Widget _grid(
    double availableWidth,
    YumeiroThemeExtension theme,
    bool isTouch,
    TextDirection direction,
    TextScaler textScaler,
  ) {
    final scale = theme.posterCardScale;
    final effectiveMinimumTileWidth =
        (isTouch ? math.min(minimumTileWidth, 140.0) : minimumTileWidth) *
        scale;
    final effectiveMaxColumns = (maximumColumns / scale).round().clamp(1, 24);
    final resolvedPadding = padding?.resolve(direction) ?? EdgeInsets.zero;
    final width = availableWidth.isFinite
        ? math.max(0.0, availableWidth - resolvedPadding.horizontal)
        : 0.0;
    final columns = calculateColumns(
      width: width,
      minimumTileWidth: effectiveMinimumTileWidth,
      spacing: spacing,
      maximumColumns: effectiveMaxColumns,
    );
    final tileWidth = (width - spacing * (columns - 1)) / columns;
    final effectiveItemCount = maxRows == null
        ? itemCount
        : math.min(itemCount, columns * maxRows!);
    var metadataExtent = textScaler.scale(footerExtent);
    if (isTouch) {
      double textHeight(String text, TextStyle style) {
        final painter = TextPainter(
          text: TextSpan(text: text, style: style),
          textDirection: direction,
          textScaler: textScaler,
        )..layout(maxWidth: tileWidth);
        final height = painter.height;
        painter.dispose();
        return height;
      }

      metadataExtent = math.max(
        metadataExtent,
        8 +
            textHeight('Ag\nAg', _posterTitleStyle(theme)) +
            3 +
            textHeight('Ag', theme.typography.caption),
      );
    }
    final delegate = SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: columns,
      mainAxisExtent: (tileWidth * 1.5 + metadataExtent).ceilToDouble(),
      crossAxisSpacing: spacing,
      mainAxisSpacing: runSpacing,
    );
    if (_sliver) {
      return SliverPadding(
        padding: padding ?? EdgeInsets.zero,
        sliver: SliverGrid(
          gridDelegate: delegate,
          delegate: SliverChildBuilderDelegate(
            itemBuilder,
            childCount: effectiveItemCount,
          ),
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: padding,
      clipBehavior: clipBehavior,
      gridDelegate: delegate,
      itemCount: effectiveItemCount,
      itemBuilder: itemBuilder,
    );
  }
}

/// Interactive poster/artwork card with pointer-driven 3D tilt, directional
/// highlight/shadow, hover scale, badges, progress bar, and overlay actions.
class YumeiroMediaCard extends StatefulWidget {
  const YumeiroMediaCard({
    super.key,
    required this.title,
    this.supportingLines = const [],
    this.footer,
    this.image,
    this.onTap,
    this.progress,
    this.rating,
    this.topLeft,
    this.topRight,
    this.bottomLeft,
    this.bottomRight,
    this.overlayActions,
    this.icon,
    this.semanticsLabel,
  });

  final String title;

  /// Additional single-line captions, displayed in order below the title.
  final List<String> supportingLines;
  final Widget? footer;
  final ImageProvider<Object>? image;
  final VoidCallback? onTap;
  final double? progress;
  final num? rating;
  final Widget? topLeft;
  final Widget? topRight;
  final Widget? bottomLeft;
  final Widget? bottomRight;

  /// Additional children in the artwork's expanding [Stack]. Use [Center],
  /// [Align], or [Positioned] to give overlay controls their intended bounds.
  final List<Widget>? overlayActions;
  final IconData? icon;
  final String? semanticsLabel;

  @override
  State<YumeiroMediaCard> createState() => _YumeiroMediaCardState();
}

class _YumeiroCardRatingBadge extends StatelessWidget {
  const _YumeiroCardRatingBadge({required this.rating});

  final num rating;

  String get _label =>
      rating % 1 == 0 ? '${rating.toInt()}' : rating.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final l10n = YumeiroLocalizations.of(context);
    return Semantics(
      label: l10n.ratingValue(_label),
      child: ExcludeSemantics(
        child: YumeiroBadge.overlay(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(theme.icons.starFilled, size: 10, color: theme.rating),
              const SizedBox(width: 2),
              Text(
                _label,
                style: theme.typography.body.copyWith(
                  fontWeight: theme.typography.headingWeight,
                  color: theme.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _YumeiroMediaCardState extends State<YumeiroMediaCard>
    with SingleTickerProviderStateMixin {
  static const _posterScale = 1.04;
  static const _tiltFactorRadians = 15 * math.pi / 180;
  static const _perspectiveDepth = 800.0;
  final FocusNode _focusNode = FocusNode(debugLabel: 'yumeiro-media-card');
  late final AnimationController _posterHoverProgress;
  bool _focused = false;
  bool _posterPointerInside = false;
  final ValueNotifier<Offset> _posterPointerNotifier = ValueNotifier(
    Offset.zero,
  );

  @override
  void initState() {
    super.initState();
    _posterHoverProgress = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _posterHoverProgress.dispose();
    _posterPointerNotifier.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _updatePosterPointer(Offset localPosition, Size posterSize) {
    if (posterSize.isEmpty) return;
    final pointer = Offset(
      (localPosition.dx / posterSize.width - 0.5).clamp(-0.5, 0.5),
      (localPosition.dy / posterSize.height - 0.5).clamp(-0.5, 0.5),
    );
    _posterPointerNotifier.value = pointer;
  }

  void _setPosterPointerInside(bool inside) {
    if (_posterPointerInside == inside) return;
    _posterPointerInside = inside;
    _posterHoverProgress.animateTo(
      inside ? 1 : 0,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : YumeiroTheme.of(context).motion.slow,
      curve: Curves.easeOutCubic,
    );
  }

  Matrix4 _posterTiltTransform(double progress, Offset pointer) =>
      Matrix4.identity()
        ..setEntry(3, 2, 1 / _perspectiveDepth)
        ..rotateX(pointer.dy * _tiltFactorRadians * progress)
        ..rotateY(-pointer.dx * _tiltFactorRadians * progress);

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final isTouch = YumeiroModalityScope.metricsOf(context).isTouch;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final tiltOption = theme.isMotionEnabled('posterTilt');
    final lightingOption = theme.isMotionEnabled('posterLighting');
    final scaleOption = theme.isMotionEnabled('posterScale');
    final pointerMotion = !reduceMotion && (tiltOption || lightingOption);
    final hoverMotion = pointerMotion || (!reduceMotion && scaleOption);
    final accentSoft = theme.accentSoft;
    final radius = theme.posterRadius;
    final fallbackIcon = widget.icon ?? theme.icons.media;
    final fallback = Center(
      child: Icon(
        fallbackIcon,
        size: 34,
        color: accentSoft.withValues(alpha: .7),
      ),
    );

    final topRight =
        widget.topRight ??
        (widget.rating == null
            ? null
            : _YumeiroCardRatingBadge(rating: widget.rating!));

    final metadata = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          maxLines: isTouch ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          style: _posterTitleStyle(theme),
        ),
        for (final line in widget.supportingLines)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              line,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.typography.caption.copyWith(color: theme.subtle),
            ),
          ),
        if (widget.footer != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: widget.footer!,
          ),
      ],
    );

    final card = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 2 / 3,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final posterSize = constraints.biggest;
              return MouseRegion(
                onEnter: (event) {
                  if (pointerMotion) {
                    _updatePosterPointer(event.localPosition, posterSize);
                  }
                  if (hoverMotion) {
                    _setPosterPointerInside(true);
                  }
                },
                onHover: pointerMotion
                    ? (event) =>
                          _updatePosterPointer(event.localPosition, posterSize)
                    : null,
                onExit: (_) => _setPosterPointerInside(false),
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _posterHoverProgress,
                    _posterPointerNotifier,
                  ]),
                  child: YumeiroArtworkImage(
                    image: widget.image,
                    fallback: fallback,
                    loading: const SizedBox.expand(),
                    backgroundColor: Colors.transparent,
                  ),
                  builder: (context, artwork) {
                    final progress = hoverMotion
                        ? _posterHoverProgress.value
                        : 0.0;
                    final posterPointer = _posterPointerNotifier.value;
                    final tiltEnabled = tiltOption && progress > 0;
                    final lighting = lightingOption
                        ? posterPointer.dy * progress * .7
                        : 0.0;
                    final topAlpha = math.max(-lighting, 0.0);
                    final bottomAlpha = math.max(lighting, 0.0);
                    final posterVisual = theme.visuals.surface(
                      YumeiroSurfaceRole.media,
                      {
                        if (progress > 0) WidgetState.hovered,
                        if (_focused) WidgetState.focused,
                      },
                    );
                    final hoverGlow = ShapeDecoration(
                      shape: posterVisual.shape,
                      shadows: [
                        if (progress > 0)
                          BoxShadow(
                            color: theme.accent.withValues(
                              alpha: .15 * progress,
                            ),
                            blurRadius: 16 * progress,
                            offset: const Offset(0, 4),
                          ),
                      ],
                    );
                    final poster = Transform(
                      transform: tiltEnabled
                          ? _posterTiltTransform(progress, posterPointer)
                          : Matrix4.identity(),
                      alignment: Alignment.center,
                      filterQuality: tiltEnabled ? FilterQuality.low : null,
                      child: _PosterFilterInput(
                        enabled: tiltEnabled,
                        child: RepaintBoundary(
                          child: YumeiroResolvedVisualSurface(
                            appearance: posterVisual,
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                artwork!,
                                IgnorePointer(
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      DecoratedBox(
                                        key: const ValueKey(
                                          'poster-positional-highlight',
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.white.withValues(
                                                alpha: topAlpha,
                                              ),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),
                                      DecoratedBox(
                                        key: const ValueKey(
                                          'poster-positional-shadow',
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withValues(
                                                alpha: bottomAlpha,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (widget.topLeft case final topLeft?)
                                  Positioned(top: 9, left: 9, child: topLeft),
                                if (topRight != null)
                                  Positioned(top: 8, right: 8, child: topRight),
                                if (widget.bottomLeft != null)
                                  Positioned(
                                    left: 9,
                                    bottom: 9,
                                    child: widget.bottomLeft!,
                                  ),
                                if (widget.bottomRight != null)
                                  Positioned(
                                    right: 8,
                                    bottom: 7,
                                    child: widget.bottomRight!,
                                  ),
                                if (widget.progress != null)
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    bottom: 0,
                                    child: YumeiroProgress(
                                      value: widget.progress!,
                                    ),
                                  ),
                                if (widget.overlayActions != null)
                                  ...widget.overlayActions!,
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                    return Transform.scale(
                      key: const ValueKey('poster-hover-transform'),
                      scale:
                          1 + (_posterScale - 1) * (scaleOption ? progress : 0),
                      child: DecoratedBox(decoration: hoverGlow, child: poster),
                    );
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        metadata,
      ],
    );

    return Semantics(
      container: true,
      button: widget.onTap != null,
      label: widget.semanticsLabel ?? widget.title,
      child: InkWell(
        splashFactory: NoSplash.splashFactory,
        focusNode: _focusNode,
        onFocusChange: (value) {
          if (_focused != value) setState(() => _focused = value);
        },
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(radius),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        child: card,
      ),
    );
  }
}

class _PosterFilterInput extends SingleChildRenderObjectWidget {
  const _PosterFilterInput({required this.enabled, required super.child});

  final bool enabled;

  @override
  _RenderPosterFilterInput createRenderObject(BuildContext context) =>
      _RenderPosterFilterInput(enabled);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderPosterFilterInput renderObject,
  ) => renderObject.enabled = enabled;
}

class _RenderPosterFilterInput extends RenderProxyBox {
  _RenderPosterFilterInput(this._enabled);

  bool _enabled;

  set enabled(bool value) {
    if (value == _enabled) return;
    _enabled = value;
    markNeedsPaint();
  }

  @override
  Rect get paintBounds =>
      _enabled ? super.paintBounds.inflate(1) : super.paintBounds;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_enabled) {
      context.canvas.drawRect(
        paintBounds.shift(offset),
        Paint()
          ..color = Colors.transparent
          ..blendMode = BlendMode.src,
      );
    }
    super.paint(context, offset);
  }
}
