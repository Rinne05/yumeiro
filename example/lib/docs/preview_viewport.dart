import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

import 'preview_host_stub.dart'
    if (dart.library.js_interop) 'preview_host_web.dart';

export 'preview_host_stub.dart'
    if (dart.library.js_interop) 'preview_host_web.dart'
    show isPreviewEmbedded;

/// In an embedded preview, reports the space currently required by the demo.
class PreviewViewport extends StatefulWidget {
  const PreviewViewport({
    super.key,
    required this.title,
    required this.locale,
    required this.preset,
    required this.modality,
    required this.overlayHeight,
    required this.buildHome,
  });

  final String title;
  final Locale locale;
  final YumeiroThemePreset preset;
  final YumeiroModality? modality;
  final int overlayHeight;
  final Widget Function(Key contentKey) buildHome;

  @override
  State<PreviewViewport> createState() => _PreviewViewportState();
}

class _PreviewViewportState extends State<PreviewViewport> {
  final _scopeKey = GlobalKey();
  final _contentKey = GlobalKey();
  late final _routes = _PreviewRoutes(_reportSize);
  int? _lastHeight;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(_afterFrame);
  }

  void _afterFrame(Duration _) {
    if (!mounted) return;
    _reportSize();
    // Observe completed frames without requesting more frames while idle.
    WidgetsBinding.instance.addPostFrameCallback(_afterFrame);
  }

  void _reportSize() {
    if (!mounted) return;
    final scope = _scopeKey.currentContext;
    final content = _contentKey.currentContext?.findRenderObject();
    if (scope is! Element ||
        content is! RenderBox ||
        !content.hasSize ||
        content.size.width <= 0 ||
        !content.size.height.isFinite) {
      return;
    }

    final space = _routes.hasOverlay
        ? _OverlaySpace.full
        : _overlaySpace(scope, inDemoContent: false, isTooltip: false);
    final naturalHeight = content.size.height.ceil();
    final height = switch (space) {
      _OverlaySpace.none => naturalHeight,
      _OverlaySpace.tooltip => naturalHeight + 48,
      _OverlaySpace.full => math.max(naturalHeight, widget.overlayHeight),
    };
    if (height == _lastHeight) return;
    _lastHeight = height;
    reportPreviewSize(height);
  }

  _OverlaySpace _overlaySpace(
    Element element, {
    required bool inDemoContent,
    required bool isTooltip,
  }) {
    final child = element.widget;
    inDemoContent |= child.key == _contentKey;
    isTooltip |= child is RawTooltip;
    if ((!inDemoContent && child is YumeiroToast) ||
        (child is OverlayPortal && child.controller.isShowing && !isTooltip)) {
      return _OverlaySpace.full;
    }
    var space =
        child is OverlayPortal && child.controller.isShowing && isTooltip
        ? _OverlaySpace.tooltip
        : _OverlaySpace.none;
    element.visitChildren((descendant) {
      if (space == _OverlaySpace.full) return;
      final descendantSpace = _overlaySpace(
        descendant,
        inDemoContent: inDemoContent,
        isTooltip: isTooltip,
      );
      if (descendantSpace.index > space.index) space = descendantSpace;
    });
    return space;
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: widget.title,
    debugShowCheckedModeBanner: false,
    locale: widget.locale,
    supportedLocales: YumeiroLocalizations.supportedLocales,
    localizationsDelegates: <LocalizationsDelegate<dynamic>>[
      YumeiroLocalizations.delegate,
      ...GlobalMaterialLocalizations.delegates,
    ],
    theme: yumeiroThemeData(
      preset: widget.preset,
      modality: widget.modality ?? YumeiroModalityScope.inferModality(),
    ),
    navigatorObservers: [_routes],
    builder: (context, child) {
      final media = MediaQuery.of(context);
      final layoutHeight = math.max(
        media.size.height,
        widget.overlayHeight.toDouble(),
      );
      return OverflowBox(
        alignment: Alignment.topCenter,
        minHeight: layoutHeight,
        maxHeight: layoutHeight,
        // Keep menu geometry stable until the iframe catches up. Material's
        // menu anchors dismiss open menus if their MediaQuery size changes.
        child: MediaQuery(
          data: media.copyWith(
            size: Size(media.size.width, widget.overlayHeight.toDouble()),
          ),
          child: YumeiroScope(
            key: _scopeKey,
            preset: widget.preset,
            modality: widget.modality,
            child: child!,
          ),
        ),
      );
    },
    home: widget.buildHome(_contentKey),
  );
}

enum _OverlaySpace { none, tooltip, full }

class _PreviewRoutes extends NavigatorObserver {
  _PreviewRoutes(this.onTransitionEnded);

  final VoidCallback onTransitionEnded;
  final _overlays = <Route<dynamic>>{};

  bool get hasOverlay => _overlays.isNotEmpty;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) _overlays.add(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _removeAfterExit(route);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _removeAfterExit(route);
  }

  void _removeAfterExit(Route<dynamic> route) {
    if (!_overlays.contains(route)) return;
    if (route is TransitionRoute<dynamic>) {
      unawaited(route.completed.then<void>((_) => _remove(route)));
    } else {
      _remove(route);
    }
  }

  void _remove(Route<dynamic> route) {
    if (_overlays.remove(route)) onTransitionEnded();
  }
}
