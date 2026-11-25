import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, visibleForTesting;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show AssetManifest, rootBundle;

import '../theme/effect_pass.dart';

/// Associates backdrop blur descendants with a shared sampling key.
///
/// A null key establishes a new boundary. Optical glass samples
/// independently to keep its texture aligned with the surface clip.
class YumeiroGlassSamplingScope extends InheritedWidget {
  const YumeiroGlassSamplingScope({
    this.backdropKey,
    required super.child,
    super.key,
  });

  /// Key shared by non-overlapping blur surfaces on the same background.
  final BackdropKey? backdropKey;

  static YumeiroGlassSamplingScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<YumeiroGlassSamplingScope>();

  @override
  bool updateShouldNotify(YumeiroGlassSamplingScope oldWidget) =>
      backdropKey != oldWidget.backdropKey;
}

/// Renders liquid glass refraction when its optical shader is ready.
///
/// Gaussian blur and tint are available while loading or on a fallback tier.
class YumeiroGlassBackdrop extends StatefulWidget {
  const YumeiroGlassBackdrop({
    required this.glass,
    required this.blur,
    required this.tint,
    required this.shape,
    required this.child,
    this.capability,
    super.key,
  });

  /// Optical parameters. Null selects regular blur and tint.
  final YumeiroGlassEffect? glass;

  /// Requested Gaussian blur radius in logical pixels.
  /// On the fallback tier a glass effect can supply blur when this is zero.
  final double blur;

  /// Explicit tint. A glass effect can supply its own fallback tint.
  final Color? tint;

  /// Geometry used to clip the rendered effect.
  final OutlinedBorder shape;

  /// Content painted in front of the effect, outside its sampling input.
  final Widget child;

  /// Requested tier. Null uses the nearest material scope.
  final YumeiroMaterialCapability? capability;

  /// Preloads the shared liquid-glass shader program when shader filters are supported.
  static Future<void> warmUp() async {
    if (!ui.ImageFilter.isShaderFilterSupported) return;
    await _YumeiroGlassBackdropState.ensureProgramLoaded();
  }

  @override
  State<YumeiroGlassBackdrop> createState() => _YumeiroGlassBackdropState();
}

@visibleForTesting
void debugSetYumeiroGlassShaderLoader(
  Future<ui.FragmentProgram> Function()? loader,
) {
  _YumeiroGlassBackdropState._loadAsset =
      loader ?? _YumeiroGlassBackdropState._loadBundledShader;
  _YumeiroGlassBackdropState._program = null;
  _YumeiroGlassBackdropState._loadedProgram = null;
  _YumeiroGlassBackdropState._hasDirectBackdrop = false;
}

class _YumeiroGlassBackdropState extends State<YumeiroGlassBackdrop> {
  static var _loadAsset = _loadBundledShader;
  static Future<ui.FragmentProgram?>? _program;
  static ui.FragmentProgram? _loadedProgram;
  static bool _hasDirectBackdrop = false;
  ui.FragmentShader? _shader;
  ui.UniformFloatSlot? _directBackdrop;
  bool _requested = false;

  static Future<ui.FragmentProgram> _loadBundledShader() async {
    const rootShader = 'shaders/liquid_glass.frag';
    const packageShader = 'packages/yumeiro/$rootShader';
    // Consumers use a package prefix. A root Flutter test bundle uses the
    // declared asset path directly.
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets = manifest.listAssets();
    final shader =
        !assets.contains(packageShader) && assets.contains(rootShader)
        ? rootShader
        : packageShader;
    return ui.FragmentProgram.fromAsset(shader);
  }

  static Future<ui.FragmentProgram?> _loadProgram() async {
    try {
      final program = await _loadAsset();
      // The uniform is reflected only by the OpenGL ES shader stage.
      final shader = program.fragmentShader();
      try {
        shader.getUniformFloat('u_directBackdrop');
        _hasDirectBackdrop = true;
      } on ArgumentError {
        // Vulkan and Metal use the controlled input pass.
      } finally {
        shader.dispose();
      }
      return _loadedProgram = program;
    } catch (error, stack) {
      _reportShaderError(error, stack, 'loading');
      return null;
    }
  }

  static void _reportShaderError(Object error, StackTrace stack, String phase) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'yumeiro',
        context: ErrorDescription('$phase the liquid glass shader'),
      ),
    );
  }

  static Future<ui.FragmentProgram?> ensureProgramLoaded() =>
      _program ??= _loadProgram();

  void _createShader(ui.FragmentProgram program) {
    ui.FragmentShader? shader;
    try {
      shader = program.fragmentShader();
      _directBackdrop = _hasDirectBackdrop
          ? shader.getUniformFloat('u_directBackdrop')
          : null;
      _shader = shader;
    } catch (error, stack) {
      shader?.dispose();
      _reportShaderError(error, stack, 'creating');
    }
  }

  void _ensureProgram() {
    if (_requested) return;
    _requested = true;
    final loaded = _loadedProgram;
    if (loaded != null) {
      _createShader(loaded);
      return;
    }
    ensureProgramLoaded().then((program) {
      if (!mounted || program == null) return;
      setState(() => _createShader(program));
    });
  }

  @override
  void dispose() {
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = YumeiroGlassSamplingScope.maybeOf(context);
    final rawCapability =
        widget.capability ?? YumeiroMaterialCapabilityScope.of(context);
    final canUseOptical =
        rawCapability.resolveForRuntime() ==
        YumeiroMaterialCapability.fullOptical;
    final glass = widget.glass;
    if (glass != null && canUseOptical) _ensureProgram();
    final optical = glass != null && canUseOptical && _shader != null;
    var blur = widget.blur;
    var tint = widget.tint;
    if (glass != null && !optical) {
      if (blur <= 0) blur = 14.0 * glass.intensity.clamp(0.0, 1.0);
      tint ??= glass.tint.withValues(
        alpha: (glass.tint.a * glass.intensity).clamp(0.0, 1.0),
      );
    }

    return _GlassFilter(
      glass: optical ? glass : null,
      shader: optical ? _shader : null,
      directBackdrop: _directBackdrop,
      backdropKey: scope?.backdropKey,
      blur: blur,
      tint: tint,
      shape: widget.shape,
      direction: Directionality.of(context),
      view: View.of(context),
      child: widget.child,
    );
  }
}

class _GlassFilter extends SingleChildRenderObjectWidget {
  const _GlassFilter({
    required this.glass,
    required this.shader,
    required this.directBackdrop,
    required this.backdropKey,
    required this.blur,
    required this.tint,
    required this.shape,
    required this.direction,
    required this.view,
    required super.child,
  });

  final YumeiroGlassEffect? glass;
  final ui.FragmentShader? shader;
  final ui.UniformFloatSlot? directBackdrop;
  final BackdropKey? backdropKey;
  final double blur;
  final Color? tint;
  final OutlinedBorder shape;
  final TextDirection direction;
  final ui.FlutterView view;

  @override
  _RenderGlassFilter createRenderObject(BuildContext context) =>
      _RenderGlassFilter(this);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderGlassFilter renderObject,
  ) => renderObject.update(this);
}

class _RenderGlassFilter extends RenderProxyBox {
  _RenderGlassFilter(this._configuration);

  static const int _uniformFloatCount = 33;
  // Rasterize the cropped backdrop with an identity filter. Fresh runtime
  // shaders can contain uninitialized uniforms and are only used for optics.
  static const _backdropCopyFilter = ui.ColorFilter.matrix(<double>[
    1, 0, 0, 0, 0, // Red
    0, 1, 0, 0, 0, // Green
    0, 0, 1, 0, 0, // Blue
    0, 0, 0, 1, 0, // Alpha
  ]);

  _GlassFilter _configuration;
  final _layer = LayerHandle<BackdropFilterLayer>();
  final _inputLayer = LayerHandle<_BackdropReplacementLayer>();
  final _inputClipLayer = LayerHandle<_OpticalInputClipLayer>();
  Offset _inputClipOffset = Offset.zero;
  final Matrix4 _planeMatrix = Matrix4.identity();
  final Matrix4 _inverseMatrix = Matrix4.identity();
  final Float64List _cachedPlane = Float64List(9);
  final Float64List _valuesBuffer = Float64List(_uniformFloatCount);
  final Float64List _filterValues = Float64List(_uniformFloatCount);
  bool _hasCachedPlane = false;
  Offset? _cachedInputOrigin;
  double? _cachedDevicePixelRatio;
  bool _cachedDirectSampling = false;
  bool _lastPlaneSingular = false;
  bool _hasFilterValues = false;
  bool _materialDirty = true;
  ui.ImageFilter? _cachedFilter;
  ui.ImageFilter? _cachedBackgroundBlur;
  Path? _cachedLocalInputPath;
  List<(RenderObject, RenderObject)>? _ancestorClips;
  bool _followsLayer = false;

  void update(_GlassFilter configuration) {
    final previous = _configuration;
    final shapeChanged =
        previous.shape != configuration.shape ||
        previous.direction != configuration.direction;
    if (previous.blur != configuration.blur) _cachedBackgroundBlur = null;
    if (!identical(previous.shape, configuration.shape) ||
        previous.direction != configuration.direction) {
      _cachedLocalInputPath = null;
    }
    if (previous.shader != configuration.shader ||
        previous.blur != configuration.blur ||
        (previous.glass == null) != (configuration.glass == null)) {
      _hasFilterValues = false;
      _cachedFilter = null;
    }
    if (previous.glass != configuration.glass ||
        previous.shader != configuration.shader ||
        previous.blur != configuration.blur ||
        shapeChanged ||
        previous.view != configuration.view) {
      _materialDirty = true;
    }
    final wasComposited = alwaysNeedsCompositing;
    _configuration = configuration;
    if (wasComposited != alwaysNeedsCompositing) {
      markNeedsCompositingBitsUpdate();
    }
    if (previous.glass != configuration.glass ||
        previous.shader != configuration.shader ||
        previous.blur != configuration.blur ||
        previous.tint != configuration.tint ||
        shapeChanged ||
        previous.view != configuration.view ||
        previous.backdropKey != configuration.backdropKey) {
      markNeedsPaint();
    }
  }

  @override
  void performLayout() {
    final previousSize = hasSize ? size : null;
    super.performLayout();
    if (previousSize != size) {
      _materialDirty = true;
      _cachedLocalInputPath = null;
    }
  }

  @override
  bool get alwaysNeedsCompositing =>
      (_configuration.glass != null && _configuration.shader != null) ||
      _configuration.blur > 0;

  @override
  bool hitTestSelf(Offset position) => _configuration.glass != null;

  BorderRadius _radii() => switch (_configuration.shape) {
    RoundedRectangleBorder(:final borderRadius) ||
    ContinuousRectangleBorder(:final borderRadius) ||
    RoundedSuperellipseBorder(
      :final borderRadius,
    ) => borderRadius.resolve(_configuration.direction),
    StadiumBorder() ||
    CircleBorder() => BorderRadius.circular(size.shortestSide / 2),
    _ => BorderRadius.zero,
  };

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _hasCachedPlane = false;
    _materialDirty = true;
  }

  @override
  void detach() {
    _ancestorClips = null;
    _cachedLocalInputPath = null;
    super.detach();
  }

  List<(RenderObject, RenderObject)> _samplingAncestors() {
    // Plain fills and Gaussian blur do not need optical sampling coordinates.
    if (_ancestorClips case final clips?) return clips;
    final clips = <(RenderObject, RenderObject)>[];
    _followsLayer = false;
    RenderObject child = this;
    for (
      RenderObject? ancestor = parent;
      ancestor != null;
      ancestor = ancestor.parent
    ) {
      clips.add((ancestor, child));
      if (ancestor is RenderFollowerLayer) _followsLayer = true;
      child = ancestor;
    }
    return _ancestorClips = clips;
  }

  bool _hasFollowerAncestor() {
    _samplingAncestors();
    return _followsLayer;
  }

  Rect? _paintClipBounds(RenderObject ancestor, RenderObject child) {
    final approximate = ancestor.describeApproximatePaintClip(child);
    if (approximate == null) return null;
    // Custom clippers may conservatively describe their whole box. The
    // backdrop texture is cropped to the actual path/rectangle bounds.
    return switch (ancestor) {
      RenderClipRect(:final clipper?, :final size) => clipper.getClip(size),
      RenderClipRRect(:final clipper?, :final size) =>
        clipper.getClip(size).outerRect,
      RenderClipRSuperellipse(:final clipper?, :final size) =>
        clipper.getClip(size).outerRect,
      RenderClipOval(:final clipper?, :final size) => clipper.getClip(size),
      RenderClipPath(:final clipper?, :final size) =>
        clipper.getClip(size).getBounds(),
      RenderPhysicalShape(:final clipper?, :final size) =>
        clipper.getClip(size).getBounds(),
      _ => approximate,
    };
  }

  Rect _visibleScreenBounds(Matrix4 transform) {
    var bounds = MatrixUtils.transformRect(transform, paintBounds);
    for (final (ancestor, child) in _samplingAncestors()) {
      // RenderView.paintBounds is physical; the material matrices and clip
      // bounds below use logical coordinates in the view.
      final clip = ancestor is RenderView
          ? Offset.zero & ancestor.size
          : _paintClipBounds(ancestor, child);
      if (clip == null) continue;
      bounds = bounds.intersect(
        MatrixUtils.transformRect(ancestor.getTransformTo(null), clip),
      );
      if (bounds.isEmpty) break;
    }
    return bounds;
  }

  static void _copyPlane(Matrix4 plane, Matrix4 transform) {
    final t = transform.storage;
    plane.setIdentity();
    final p = plane.storage;
    p[0] = t[0];
    p[1] = t[1];
    p[3] = t[3];
    p[4] = t[4];
    p[5] = t[5];
    p[7] = t[7];
    p[12] = t[12];
    p[13] = t[13];
    p[15] = t[15];
  }

  Path _localInputPath() {
    if (_cachedLocalInputPath case final path?) return path;
    final shape = _configuration.shape;
    final path = shape.getOuterPath(
      Offset.zero & size,
      textDirection: _configuration.direction,
    );
    // These rounded rectangles depend only on size, shape, and direction.
    // Custom borders or radii can derive geometry from additional state.
    if (shape is RoundedRectangleBorder &&
        shape.runtimeType == RoundedRectangleBorder) {
      final radiusType = shape.borderRadius.runtimeType;
      if (radiusType == BorderRadius || radiusType == BorderRadiusDirectional) {
        _cachedLocalInputPath = path;
      }
    }
    return path;
  }

  _OpticalInputClip _inputClip() {
    final transform = getTransformTo(null);
    final plane = Matrix4.identity();
    _copyPlane(plane, transform);
    final toScreen = Matrix4.copy(plane)
      ..multiply(
        Matrix4.translationValues(
          -_inputClipOffset.dx,
          -_inputClipOffset.dy,
          0,
        ),
      );
    final inverse = Matrix4.copy(toScreen);
    final determinant = inverse.invert();
    if (!determinant.isFinite || determinant.abs() < 1e-12) {
      return (
        path: Path(),
        toScreen: Matrix4.identity(),
        fromScreen: Matrix4.identity(),
      );
    }
    final bounds = MatrixUtils.transformRect(transform, paintBounds);
    if (!bounds.isFinite) {
      return (
        path: Path(),
        toScreen: Matrix4.identity(),
        fromScreen: Matrix4.identity(),
      );
    }
    final dpr = _configuration.view.devicePixelRatio;
    final aligned = Rect.fromLTRB(
      (bounds.left * dpr).floorToDouble() / dpr,
      (bounds.top * dpr).floorToDouble() / dpr,
      (bounds.right * dpr).ceilToDouble() / dpr,
      (bounds.bottom * dpr).ceilToDouble() / dpr,
    );
    final path = _localInputPath().transform(plane.storage);
    // Empty contours extend only the conservative layer bounds, not its
    // filled geometry. Snapshot allocation/restoration must cover complete
    // physical pixels while the actual shape retains its AA coverage.
    for (final point in [
      aligned.topLeft,
      aligned.topRight,
      aligned.bottomRight,
      aligned.bottomLeft,
    ]) {
      path
        ..moveTo(point.dx, point.dy)
        ..lineTo(point.dx, point.dy);
    }
    return (path: path, toScreen: toScreen, fromScreen: inverse);
  }

  bool _canSampleDirectly(
    _BackdropReplacementLayer? input,
    Matrix4 transform,
    Rect bounds,
    double dpr,
  ) {
    final config = _configuration;
    if (config.directBackdrop == null ||
        defaultTargetPlatform != TargetPlatform.linux ||
        config.blur != 0 ||
        config.glass!.pressure != 0 ||
        config.glass!.lighting != 0 ||
        config.shape.runtimeType != RoundedRectangleBorder ||
        _hasFollowerAncestor() ||
        input == null ||
        MatrixUtils.getAsTranslation(transform) == null) {
      return false;
    }
    final viewport = config.view.physicalSize;
    // A cropped texture can pick a different nearest texel on sharp edges.
    // Only elide the copy when both passes use the same texture extent and
    // origin, including after an ancestor scrolls or changes the clip.
    return viewport.width * viewport.height >= 1024 * 1024 &&
        bounds.left == 0 &&
        bounds.top == 0 &&
        bounds.right * dpr == viewport.width &&
        bounds.bottom * dpr == viewport.height &&
        input.coversViewport(viewport, dpr);
  }

  ui.ImageFilter? _filter([_BackdropReplacementLayer? input]) {
    final config = _configuration;
    final glass = config.glass;
    final shader = config.shader;
    if (glass != null && shader != null && !size.isEmpty) {
      final transform = getTransformTo(null);
      final visibleBounds = _visibleScreenBounds(transform);
      if (visibleBounds.isEmpty) {
        input?.sampleDirectly = false;
        return null;
      }
      final t = transform.storage;
      final p0 = t[0], p1 = t[1], p2 = t[3];
      final p3 = t[4], p4 = t[5], p5 = t[7];
      final p6 = t[12], p7 = t[13], p8 = t[15];
      // The same view can change scale without rebuilding this widget.
      final dpr = config.view.devicePixelRatio;
      final directSampling = _canSampleDirectly(
        input,
        transform,
        visibleBounds,
        dpr,
      );
      input?.sampleDirectly = directSampling;
      final sameSampling = _cachedDirectSampling == directSampling;
      final inputOrigin = Offset(
        (visibleBounds.left * dpr).floorToDouble() / dpr,
        (visibleBounds.top * dpr).floorToDouble() / dpr,
      );
      final samePlane =
          _hasCachedPlane &&
          _cachedPlane[0] == p0 &&
          _cachedPlane[1] == p1 &&
          _cachedPlane[2] == p2 &&
          _cachedPlane[3] == p3 &&
          _cachedPlane[4] == p4 &&
          _cachedPlane[5] == p5 &&
          _cachedPlane[6] == p6 &&
          _cachedPlane[7] == p7 &&
          _cachedPlane[8] == p8;
      if (!_materialDirty &&
          samePlane &&
          _cachedInputOrigin == inputOrigin &&
          _cachedDevicePixelRatio == dpr &&
          sameSampling) {
        if (_lastPlaneSingular) return null;
        if (_cachedFilter != null) return _cachedFilter;
      }
      _cachedPlane[0] = p0;
      _cachedPlane[1] = p1;
      _cachedPlane[2] = p2;
      _cachedPlane[3] = p3;
      _cachedPlane[4] = p4;
      _cachedPlane[5] = p5;
      _cachedPlane[6] = p6;
      _cachedPlane[7] = p7;
      _cachedPlane[8] = p8;
      _hasCachedPlane = true;
      _cachedInputOrigin = inputOrigin;
      _cachedDevicePixelRatio = dpr;
      _cachedDirectSampling = directSampling;

      _copyPlane(_planeMatrix, transform);

      _inverseMatrix.setFrom(_planeMatrix);
      final determinant = _inverseMatrix.invert();
      if (!determinant.isFinite || determinant.abs() < 1e-12) {
        _lastPlaneSingular = true;
        _materialDirty = false;
        return null;
      }
      _lastPlaneSingular = false;

      final radii = _radii();
      final shortSide = size.shortestSide;
      final opticalScale = (shortSide / 40).clamp(0.0, 1.4);
      final refraction = (glass.refraction * opticalScale).clamp(
        0.0,
        shortSide * .4,
      );
      final thickness = (glass.thickness * opticalScale).clamp(
        0.0,
        shortSide * .28,
      );
      final inv = _inverseMatrix.storage;
      final values = _valuesBuffer;
      values[0] = size.width;
      values[1] = size.height;
      values[2] = dpr;
      values[3] = inputOrigin.dx;
      values[4] = inputOrigin.dy;
      values[5] = p0;
      values[6] = p1;
      values[7] = p2;
      values[8] = p3;
      values[9] = p4;
      values[10] = p5;
      values[11] = p6;
      values[12] = p7;
      values[13] = p8;
      values[14] = inv[0];
      values[15] = inv[1];
      values[16] = inv[3];
      values[17] = inv[4];
      values[18] = inv[5];
      values[19] = inv[7];
      values[20] = inv[12];
      values[21] = inv[13];
      values[22] = inv[15];
      values[23] = math.max(0.0, radii.topLeft.x);
      values[24] = math.max(0.0, radii.topRight.x);
      values[25] = math.max(0.0, radii.bottomRight.x);
      values[26] = math.max(0.0, radii.bottomLeft.x);
      values[27] = refraction;
      values[28] = thickness;
      values[29] = glass.pressure;
      values[30] = glass.intensity;
      values[31] = config.blur <= 1.5 ? config.blur : 0.0;
      values[32] = glass.lighting;

      _materialDirty = false;
      if (_cachedFilter != null && _hasFilterValues && sameSampling) {
        var equal = true;
        for (var i = 0; i < _uniformFloatCount; i++) {
          if (values[i] != _filterValues[i]) {
            equal = false;
            break;
          }
        }
        if (equal) return _cachedFilter;
      }
      _filterValues.setAll(0, values);
      _hasFilterValues = true;
      for (var i = 0; i < _uniformFloatCount; i++) {
        shader.setFloat(i + 2, values[i]);
      }
      config.directBackdrop?.set(directSampling ? 1.0 : 0.0);
      return _cachedFilter = ui.ImageFilter.shader(shader);
    }
    _materialDirty = false;
    final blur = config.blur;
    return blur > 0
        ? _cachedFilter ??= ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur)
        : null;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_configuration.glass case final glass?
        when glass.intensity <= 0 && _configuration.blur <= 0) {
      // An invisible material must not even copy its input: srcOver would
      // otherwise accumulate alpha on a translucent page.
      _layer.layer = null;
      _inputLayer.layer = null;
      _inputClipLayer.layer = null;
      _cachedLocalInputPath = null;
      context.pushClipPath(
        alwaysNeedsCompositing,
        offset,
        Offset.zero & size,
        _configuration.shape.getOuterPath(
          Offset.zero & size,
          textDirection: _configuration.direction,
        ),
        super.paint,
      );
      return;
    }
    final optical =
        _configuration.glass != null &&
        _configuration.shader != null &&
        !size.isEmpty;
    final filtered = optical || _configuration.blur > 0;
    final filter = optical ? null : _filter();

    void paintCoating(PaintingContext context, Offset childOffset) {
      final config = _configuration;
      final tint = config.glass == null ? config.tint : null;
      if (tint != null) {
        context.canvas.drawRect(childOffset & size, Paint()..color = tint);
      }
    }

    void paintMaterial(PaintingContext context, Offset offset) {
      if (!optical && filter == null) {
        _layer.layer = null;
        paintCoating(context, offset);
      } else {
        if (_layer.layer == null ||
            (_layer.layer is _GlassBackdropLayer) != optical) {
          _layer.layer = optical
              ? _GlassBackdropLayer(_filter, _hasFollowerAncestor)
              : _BackdropReplacementLayer();
        }
        final layer = _layer.layer!;
        if (!optical) {
          layer.filter = filter;
          layer.backdropKey = _configuration.backdropKey;
        }
        context.pushLayer(layer, paintCoating, offset);
      }
    }

    void paintInput(PaintingContext context, Offset offset) {
      if (optical) {
        // Keep the optical snapshot unkeyed so it retains its local origin.
        final layer = _inputLayer.layer ??= _BackdropReplacementLayer();
        layer.filter = _configuration.blur > 1.5
            ? _cachedBackgroundBlur ??= ui.ImageFilter.blur(
                sigmaX: _configuration.blur,
                sigmaY: _configuration.blur,
              )
            : _backdropCopyFilter;
        context.pushLayer(layer, paintMaterial, offset);
      } else {
        _inputLayer.layer = null;
        paintMaterial(context, offset);
      }
      super.paint(context, offset);
    }

    if (filtered) {
      // Align the snapshot bounds without changing the antialiased shape.
      // Refresh this at composition time as ancestor scroll/follower layers
      // can move the surface without repainting it.
      _inputClipOffset = offset;
      final layer = _inputClipLayer.layer ??= _OpticalInputClipLayer(
        _inputClip,
      );
      context.pushLayer(layer, paintInput, offset);
    } else {
      _inputClipLayer.layer = null;
      _cachedLocalInputPath = null;
      if (_configuration.glass != null) {
        // Keep a zero-size optical surface clipped.
        context.pushClipPath(
          alwaysNeedsCompositing,
          offset,
          Offset.zero & size,
          _configuration.shape.getOuterPath(
            Offset.zero & size,
            textDirection: _configuration.direction,
          ),
          paintInput,
        );
      } else {
        paintInput(context, offset);
      }
    }
  }

  @override
  void dispose() {
    _layer.layer = null;
    _inputLayer.layer = null;
    _inputClipLayer.layer = null;
    super.dispose();
  }
}

typedef _OpticalInputClip = ({Path path, Matrix4 toScreen, Matrix4 fromScreen});

class _OpticalInputClipLayer extends ContainerLayer {
  _OpticalInputClipLayer(this.createClip);

  final _OpticalInputClip Function() createClip;

  @override
  bool get alwaysNeedsAddToScene => true;

  @override
  void addToScene(ui.SceneBuilder builder) {
    // Compute after any follower's transform has been installed. Clipping in
    // screen coordinates also avoids inflating a rotated local path's AABB.
    final clip = createClip();
    builder.pushTransform(clip.fromScreen.storage);
    builder.pushClipPath(clip.path, clipBehavior: Clip.antiAlias);
    builder.pushTransform(clip.toScreen.storage);
    addChildrenToScene(builder);
    builder.pop();
    builder.pop();
    builder.pop();
  }
}

class _BackdropReplacementLayer extends BackdropFilterLayer {
  // The input and optical passes form one replacement, never a second copy
  // of a translucent backdrop. The enclosing shape's bounds are pixel-aligned.
  _BackdropReplacementLayer() : super(blendMode: ui.BlendMode.src);

  bool _sampleDirectly = false;

  set sampleDirectly(bool value) {
    if (_sampleDirectly == value) return;
    _sampleDirectly = value;
    markNeedsAddToScene();
  }

  bool coversViewport(Size viewport, double dpr) {
    final clip = parent;
    if (clip is! _OpticalInputClipLayer) return false;
    // Groups with their own render target or nonrectangular clip can
    // change the sampling bounds. Keep a controlled input for those layers.
    Rect? bounds;
    for (Layer? layer = clip.parent; layer != null; layer = layer.parent) {
      if (layer.runtimeType == TransformLayer) {
        final transformLayer = layer as TransformLayer;
        final transform = transformLayer.transform;
        if (transform == null) return false;
        if (layer.parent == null) {
          return transformLayer.offset == Offset.zero &&
              MatrixUtils.getAsScale(transform) == dpr &&
              (bounds == null ||
                  (bounds.left <= 0 &&
                      bounds.top <= 0 &&
                      bounds.right * dpr >= viewport.width &&
                      bounds.bottom * dpr >= viewport.height));
        }
        final translation = MatrixUtils.getAsTranslation(transform);
        if (translation == null) return false;
        bounds = bounds?.shift(translation + transformLayer.offset);
      } else if (layer.runtimeType == OffsetLayer ||
          (layer.runtimeType == OpacityLayer &&
              (layer as OpacityLayer).alpha == 255)) {
        bounds = bounds?.shift((layer as OffsetLayer).offset);
      } else if (layer.runtimeType == ClipRectLayer) {
        final rect = layer as ClipRectLayer;
        if (rect.clipBehavior != Clip.hardEdge || rect.clipRect == null) {
          return false;
        }
        final layerBounds = rect.clipRect!;
        bounds = bounds?.intersect(layerBounds) ?? layerBounds;
      } else {
        return false;
      }
    }
    return false;
  }

  @override
  void updateSubtreeNeedsAddToScene() {
    // An explicit ancestor Opacity applies its group fade to this saveLayer.
    // Preserve that host composition instead of replacing the page with the
    // faded group's alpha. Ordinary backdrop sampling is a source replacement.
    blendMode = _hasTranslucentOpacityAncestor(parent)
        ? ui.BlendMode.srcOver
        : ui.BlendMode.src;
    super.updateSubtreeNeedsAddToScene();
  }

  @override
  void addToScene(ui.SceneBuilder builder) {
    if (_sampleDirectly) {
      engineLayer = null;
      addChildrenToScene(builder);
    } else {
      super.addToScene(builder);
    }
  }
}

bool _hasTranslucentOpacityAncestor(Layer? start) {
  for (Layer? layer = start; layer != null; layer = layer.parent) {
    if (layer is OpacityLayer && layer.alpha != 255) {
      return true;
    }
  }
  return false;
}

class _GlassBackdropLayer extends BackdropFilterLayer {
  _GlassBackdropLayer(this.createFilter, this.followsLayer)
    : super(blendMode: ui.BlendMode.src);

  final ui.ImageFilter? Function(_BackdropReplacementLayer) createFilter;
  final bool Function() followsLayer;
  bool _visible = false;

  void _refresh() {
    // The input layer owns any surrounding opacity, even in direct mode.
    final nextFilter = createFilter(parent as _BackdropReplacementLayer);
    final active = nextFilter != null;
    if (_visible != active) {
      _visible = active;
      markNeedsAddToScene();
    }
    if (nextFilter != null) filter = nextFilter;
  }

  @override
  void updateSubtreeNeedsAddToScene() {
    if (followsLayer()) {
      markNeedsAddToScene();
    } else {
      _refresh();
    }
    super.updateSubtreeNeedsAddToScene();
  }

  @override
  void addToScene(ui.SceneBuilder builder) {
    if (followsLayer()) _refresh();
    if (_visible) {
      super.addToScene(builder);
    } else {
      engineLayer = null;
    }
  }
}
