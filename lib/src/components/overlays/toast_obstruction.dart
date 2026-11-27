import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

/// Measures bottom obstructions within a touch toast host's viewport.
class ToastObstruction
    extends ValueNotifier<({double navigation, double system})> {
  ToastObstruction(this._host) : super((navigation: 0, system: 0));

  final BuildContext _host;
  final _bars = <_RenderToastBottomBar>{};
  MediaQueryData? _media;
  bool _scheduled = false;
  bool _disposed = false;

  void updateMedia(MediaQueryData? media) {
    if (_media == media) return;
    _media = media;
    _scheduleRead();
  }

  void _register(_RenderToastBottomBar bar) {
    if (_disposed) return;
    _bars.add(bar);
    _scheduleRead();
  }

  void _unregister(_RenderToastBottomBar bar) {
    if (!_bars.remove(bar)) return;
    _scheduleRead();
  }

  void _scheduleRead() {
    if (_scheduled || _disposed) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (_disposed) return;
      _measure();
      // Parent layout and animations can move an unchanged child. Sample on
      // frames the app already paints, without requesting another frame.
      if (_bars.isNotEmpty || _hasSystemInsets) _scheduleRead();
    });
  }

  bool get _hasSystemInsets {
    final media = _media;
    return media != null &&
        (media.padding.bottom > 0 ||
            media.viewPadding.bottom > 0 ||
            media.viewInsets.bottom > 0);
  }

  void _measure() {
    final viewport = _host.findRenderObject();
    var navigation = 0.0;
    var system = 0.0;
    if (viewport is RenderBox && viewport.attached && viewport.hasSize) {
      final available = Offset.zero & viewport.size;
      final (safeArea, keyboard) = _systemInsets(viewport, available);
      system = math.max(safeArea, keyboard);
      for (final bar in _bars) {
        if (!bar.hasSize ||
            !bar._hasPaintedLayer ||
            !_isPaintedWithin(bar, viewport)) {
          continue;
        }
        final bounds = MatrixUtils.transformRect(
          bar.getTransformTo(viewport),
          Offset.zero & bar.size,
        );
        final gap = available.bottom - bounds.bottom;
        // Inline navigation samples can render anywhere in the app. Only
        // bars at the host's lower edge or a consumed inset obstruct it.
        const tolerance = 1.0;
        final atBottom =
            gap <= tolerance ||
            (gap - safeArea).abs() <= tolerance ||
            (gap - keyboard).abs() <= tolerance;
        if (bounds.isFinite && bounds.overlaps(available) && atBottom) {
          navigation = math.max(
            navigation,
            available.bottom - math.max(0, bounds.top),
          );
        }
      }
    }
    value = (navigation: navigation, system: system);
  }

  (double, double) _systemInsets(RenderBox viewport, Rect available) {
    final media = _media;
    if (media == null || !_hasSystemInsets || available.isEmpty) return (0, 0);
    // Insets start at the bottom of the view. A scoped host may sit above
    // that edge already, for example inside a resized Scaffold.
    final top = viewport.localToGlobal(available.topCenter).dy;
    final bottom = viewport.localToGlobal(available.bottomCenter).dy;
    final scale = (bottom - top) / available.height;
    if (!scale.isFinite || scale <= 0) return (0, 0);
    double overlap(double inset) => inset <= 0
        ? 0
        : ((bottom - media.size.height + inset) / scale).clamp(
            0.0,
            available.height,
          );
    return (
      overlap(math.max(media.padding.bottom, media.viewPadding.bottom)),
      overlap(media.viewInsets.bottom),
    );
  }

  bool _isPaintedWithin(RenderObject bar, RenderObject viewport) {
    var child = bar;
    while (child != viewport) {
      final parent = child.parent;
      if (parent == null || !parent.paintsChild(child)) return false;
      child = parent;
    }
    return true;
  }

  @override
  void dispose() {
    _disposed = true;
    _bars.clear();
    super.dispose();
  }
}

/// Limits bottom-bar measurements to the nearest toast host.
class ToastObstructionScope extends InheritedWidget {
  const ToastObstructionScope({
    super.key,
    required this.obstruction,
    required super.child,
  });

  final ToastObstruction obstruction;

  static ToastObstruction? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<ToastObstructionScope>()
      ?.obstruction;

  @override
  bool updateShouldNotify(ToastObstructionScope oldWidget) =>
      oldWidget.obstruction != obstruction;
}

/// Reports the rendered bounds of Yumeiro's bottom navigation bar.
class ToastBottomBar extends SingleChildRenderObjectWidget {
  const ToastBottomBar({super.key, required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderToastBottomBar(ToastObstructionScope.maybeOf(context));

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderToastBottomBar).obstruction =
        ToastObstructionScope.maybeOf(context);
  }
}

class _RenderToastBottomBar extends RenderRepaintBoundary {
  _RenderToastBottomBar(this._obstruction);

  ToastObstruction? _obstruction;

  // An opaque route drops the covered bar's layer, while a dialog leaves it
  // painted behind its barrier. Both routes can retain the render object.
  bool get _hasPaintedLayer => layer?.attached ?? false;

  set obstruction(ToastObstruction? value) {
    if (_obstruction == value) return;
    if (attached) _obstruction?._unregister(this);
    _obstruction = value;
    if (attached) _obstruction?._register(this);
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _obstruction?._register(this);
  }

  @override
  void detach() {
    _obstruction?._unregister(this);
    super.detach();
  }
}
