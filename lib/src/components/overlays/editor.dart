import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../foundation/modality.dart';
import '../../scope/captured_configuration.dart';
import '../../primitives/visual_surface.dart';
import '../../theme/theme.dart';
import '../../theme/visual_role.dart';
import '../layout/action_bar.dart';
import '../layout/scaffolds.dart';
import '../layout/scroll_view.dart';
import '../navigation/page_transition.dart';
import 'dialogs.dart';
import 'selection_sheet_layout.dart';
import 'sheets.dart';

/// Adaptive editor with a scrollable body and fixed actions.
///
/// [show] opens a [YumeiroDialog] for pointer input and a [YumeiroBottomSheet]
/// for touch input by default. Use the widget directly in a touch page that
/// supplies its background, or use [show] with `fullscreenOnTouch: true`.
///
/// Body [State] and controllers are preserved via an internal [GlobalKey].
class YumeiroEditor extends StatefulWidget {
  const YumeiroEditor({
    super.key,
    required this.title,
    this.headerAccessory,
    required this.child,
    this.actions,
    this.maxWidth = 520,
    this.maxHeight = 680,
    this.showClose = true,
    this.onClose,
    this.scrollable = true,
    this.contentPadding = defaultContentPadding,
    this.canDismiss = true,
    this.busy = false,
    this.onLeave,
  });

  static const defaultContentPadding = EdgeInsets.all(22);

  /// Opens an editor as a dialog with pointer input or a sheet with touch.
  ///
  /// Await the route result to apply a completed edit. A dismissal without a
  /// result yields null. [barrierDismissible] applies to both modal surfaces.
  /// [fullscreenOnTouch] opens a page for longer touch workflows. That page
  /// uses the theme's canvas by default. Set [pageBackground] to
  /// [Colors.transparent] to expose a host background behind the navigator.
  /// Set [useRootNavigator] to false to open on the nearest navigator.
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
    bool useRootNavigator = true,
    bool fullscreenOnTouch = false,
    Color? pageBackground,
  }) {
    final isTouch = YumeiroModalityScope.metricsOf(context).isTouch;
    if (!isTouch) {
      return YumeiroDialog.show<T>(
        context: context,
        builder: builder,
        barrierDismissible: barrierDismissible,
        useRootNavigator: useRootNavigator,
      );
    }
    if (!fullscreenOnTouch) {
      return YumeiroBottomSheet.show<T>(
        context: context,
        barrierDismissible: barrierDismissible,
        useRootNavigator: useRootNavigator,
        builder: (_) => _EditorSheetScope(child: Builder(builder: builder)),
      );
    }

    final density = YumeiroModalityScope.densityOf(context);
    final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
    final themes = YumeiroCapturedConfiguration.capture(
      context,
      navigator.context,
    );
    final page = Builder(builder: builder);
    return navigator.push<T>(
      _YumeiroTouchEditorRoute<T>(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : YumeiroTheme.of(context).motion.slow,
        builder: (context) => themes.wrap(
          YumeiroModalityScope(
            modality: YumeiroModality.touch,
            density: density,
            child: switch (pageBackground) {
              final color? => ColoredBox(color: color, child: page),
              null => YumeiroVisualSurface(
                role: YumeiroSurfaceRole.canvas,
                child: page,
              ),
            },
          ),
        ),
      ),
    );
  }

  final String title;

  /// A badge or control displayed with the heading.
  final Widget? headerAccessory;
  final Widget child;

  /// Footer actions. In touch mode the last action occupies the primary slot.
  final List<Widget>? actions;
  final double maxWidth;
  final double maxHeight;
  final bool showClose;

  /// Replaces the default pop after a user-requested close is allowed.
  final VoidCallback? onClose;

  /// Enables the editor's own scrolling wrapper.
  final bool scrollable;
  final EdgeInsetsGeometry contentPadding;
  final bool canDismiss;

  /// Prevents dismissal while an operation is in progress.
  final bool busy;

  /// Optional asynchronous leave guard, shared by close and route back actions.
  /// Draft ownership and confirmation UI remain with the host application.
  final Future<bool> Function()? onLeave;

  @override
  State<YumeiroEditor> createState() => _YumeiroEditorState();
}

class _YumeiroEditorState extends State<YumeiroEditor> {
  final _bodyKey = GlobalKey();

  bool _closing = false;
  bool _allowPop = false;

  bool get _canDismiss => widget.canDismiss && !widget.busy;
  bool get _canPop => _canDismiss && (widget.onLeave == null || _allowPop);

  bool _canCloseRoute(ModalRoute<Object?>? route) =>
      _canDismiss &&
      (route == null || route.isCurrent) &&
      identical(ModalRoute.of(context), route);

  Future<void> _requestClose() async {
    if (!_canDismiss || _closing) return;
    final route = ModalRoute.of(context);
    if (route?.isCurrent == false) return;
    final onLeave = widget.onLeave;
    _closing = true;
    try {
      if (onLeave != null) {
        final allowed = await onLeave();
        if (!mounted || !allowed || !_canCloseRoute(route)) return;
        setState(() => _allowPop = true);
        await WidgetsBinding.instance.endOfFrame;
      }
      if (!mounted || !_canCloseRoute(route)) return;
      if (widget.onClose case final close?) {
        close();
      } else {
        await Navigator.of(context).maybePop();
      }
    } finally {
      if (mounted && _allowPop) setState(() => _allowPop = false);
      _closing = false;
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _canPop,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop && widget.onLeave != null) unawaited(_requestClose());
    },
    child: _buildShell(context),
  );

  Widget _buildShell(BuildContext context) {
    final body = KeyedSubtree(key: _bodyKey, child: widget.child);
    final isTouch = YumeiroModalityScope.metricsOf(context).isTouch;
    final inSheet =
        context.dependOnInheritedWidgetOfExactType<_EditorSheetScope>() != null;

    if (isTouch || inSheet) {
      final padding =
          widget.contentPadding == YumeiroEditor.defaultContentPadding
          ? const EdgeInsets.all(yumeiroActionBarInset)
          : widget.contentPadding;
      final actions = widget.actions ?? const <Widget>[];
      if (inSheet) {
        return YumeiroBottomSheet(
          title: widget.title,
          headerAccessory: widget.headerAccessory,
          actions: actions,
          maxWidth: widget.maxWidth,
          maxHeight: widget.maxHeight,
          showClose: widget.showClose,
          onClose: () => unawaited(_requestClose()),
          canDismiss: _canDismiss,
          scrollable: widget.scrollable,
          contentPadding: padding,
          minAnchoredHeight: yumeiroSelectionSheetMinHeight(
            context,
            title: widget.title,
            searchable: true,
            hasConfirmation: actions.isNotEmpty,
          ),
          child: body,
        );
      }
      final scrolledBody = Material(
        type: MaterialType.transparency,
        child: widget.scrollable
            ? YumeiroScrollView(padding: padding, child: body)
            : Padding(padding: padding, child: body),
      );
      return YumeiroPageScaffold.detail(
        title: widget.title,
        onBack: widget.showClose && _canDismiss
            ? () => unawaited(_requestClose())
            : null,
        scrollable: false,
        padding: EdgeInsets.zero,
        bottomBar: actions.isEmpty
            ? null
            : YumeiroActionBar(
                primaryAction: actions.last,
                secondaryActions: actions.sublist(0, actions.length - 1),
              ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.headerAccessory != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: yumeiroActionBarInset,
                  vertical: 8,
                ),
                child: widget.headerAccessory!,
              ),
            Expanded(child: scrolledBody),
          ],
        ),
      );
    }

    return YumeiroDialog(
      title: widget.title,
      headerAccessory: widget.headerAccessory,
      actions: widget.actions,
      maxWidth: widget.maxWidth,
      maxHeight: widget.maxHeight,
      showClose: widget.showClose,
      onClose: () => unawaited(_requestClose()),
      scrollable: widget.scrollable,
      contentPadding: widget.contentPadding,
      canDismiss: _canDismiss,
      child: body,
    );
  }
}

class _EditorSheetScope extends InheritedWidget {
  const _EditorSheetScope({required super.child});

  @override
  bool updateShouldNotify(_EditorSheetScope oldWidget) => false;
}

class _YumeiroTouchEditorRoute<T> extends PageRouteBuilder<T> {
  _YumeiroTouchEditorRoute({
    required WidgetBuilder builder,
    required Duration duration,
  }) : super(
         opaque: true,
         fullscreenDialog: true,
         transitionDuration: duration,
         reverseTransitionDuration: duration,
         pageBuilder: (context, _, _) => builder(context),
       );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => YumeiroPageTransition(
    animation: animation,
    secondaryAnimation: secondaryAnimation,
    child: child,
  );
}
