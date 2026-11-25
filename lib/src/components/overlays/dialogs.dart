import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import '../../foundation/modality.dart';
import '../../scope/captured_configuration.dart';
import '../../l10n/localizations.dart';
import '../../primitives/backdrop_group.dart';
import '../../primitives/visual_surface.dart';
import '../../theme/theme.dart';
import '../../theme/visual_role.dart';
import '../controls/buttons.dart';
import '../layout/action_bar.dart';
import '../layout/page_header.dart';
import '../layout/scroll_view.dart';
import 'selection_overlay.dart';

/// Unified adaptive dialog shell powered by [YumeiroSurfaceRole.modal].
/// Automatically switches between compact touch action-bar chrome and pointer
/// header/footer chrome while preserving body [State] across modality changes.
class YumeiroDialog extends StatefulWidget {
  const YumeiroDialog({
    super.key,
    required this.title,
    this.headerAccessory,
    this.child,
    this.actions,
    this.maxWidth = 520,
    this.maxHeight = 680,
    this.showClose = true,
    this.onClose,
    this.scrollable = true,
    this.contentPadding = defaultContentPadding,
    this.canDismiss = true,
  });

  static const defaultContentPadding = EdgeInsets.all(22);

  /// Presents a dialog or custom content in a modal route.
  ///
  /// The returned future completes with the route's result, or null when
  /// dismissed without a result. Use the builder's context to pop the dialog.
  /// Set [useRootNavigator] to false to open on the nearest navigator.
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
    bool useRootNavigator = true,
  }) => _presentModal<T>(
    context: context,
    builder: builder,
    barrierDismissible: barrierDismissible,
    useRootNavigator: useRootNavigator,
  );

  /// Shows a standard confirmation dialog using [YumeiroLocalizations] defaults
  /// when [confirmLabel] or [cancelLabel] are omitted.
  /// The result is true when confirmed and false when canceled or dismissed.
  /// Set [useRootNavigator] to false to open on the nearest navigator.
  static Future<bool> confirm({
    required BuildContext context,
    required String title,
    String? message,
    String? confirmLabel,
    String? cancelLabel,
    bool destructive = false,
    bool useRootNavigator = true,
  }) async {
    final l10n = YumeiroLocalizations.of(context);
    final result = await show<bool>(
      context: context,
      useRootNavigator: useRootNavigator,
      builder: (dialogContext) => YumeiroDialog(
        title: title,
        maxWidth: 440,
        actions: [
          YumeiroButton(
            label: cancelLabel ?? l10n.cancel,
            variant: YumeiroButtonVariant.ghost,
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          YumeiroButton(
            label: confirmLabel ?? l10n.confirm,
            variant: destructive
                ? YumeiroButtonVariant.danger
                : YumeiroButtonVariant.primary,
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
        child: message == null
            ? null
            : Text(
                message,
                style: YumeiroTheme.of(dialogContext).typography.body
                    .copyWith(color: YumeiroTheme.of(dialogContext).muted),
              ),
      ),
    );
    return result ?? false;
  }

  final String title;

  /// A badge or control displayed with the heading.
  final Widget? headerAccessory;

  /// Main content of the dialog.
  final Widget? child;

  /// Footer controls. The last control is the primary action in touch mode.
  final List<Widget>? actions;
  final double maxWidth;
  final double maxHeight;

  /// Whether the dialog shows a close control.
  final bool showClose;

  /// Overrides the close control's default route dismissal.
  final VoidCallback? onClose;

  /// Wraps the body in a scroll view. Disable for a body with its own viewport.
  final bool scrollable;
  final EdgeInsetsGeometry contentPadding;

  /// Enables the close control and route back navigation. Configure barrier
  /// taps separately through [show] by setting its barrierDismissible flag.
  final bool canDismiss;

  @override
  State<YumeiroDialog> createState() => _YumeiroDialogState();
}

class _YumeiroDialogState extends State<YumeiroDialog> {
  final _bodyKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final rawBody = widget.child;
    final body = rawBody == null
        ? null
        : KeyedSubtree(key: _bodyKey, child: rawBody);
    return YumeiroModalityScope.metricsOf(context).isTouch
        ? _TouchDialogShell(dialog: widget, child: body)
        : _PointerDialogShell(dialog: widget, child: body);
  }
}

Widget _dialogBody(Widget child, {required bool scrollable}) => Material(
  type: MaterialType.transparency,
  child: scrollable ? YumeiroScrollView(child: child) : child,
);

class _PointerDialogShell extends StatelessWidget {
  const _PointerDialogShell({required this.dialog, required this.child});

  final YumeiroDialog dialog;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final YumeiroDialog(
      :title,
      :headerAccessory,
      :actions,
      :maxWidth,
      :maxHeight,
      :showClose,
      :onClose,
      :scrollable,
      :contentPadding,
      :canDismiss,
    ) = dialog;
    final theme = YumeiroTheme.of(context);
    final l10n = YumeiroLocalizations.of(context);
    final metrics = YumeiroModalityScope.metricsOf(context);
    final gap = theme.spacing.sm;
    final heading = Semantics(
      container: true,
      header: true,
      namesRoute: title.isNotEmpty,
      child: Text(
        title,
        style: theme.typography.textTheme.titleLarge?.copyWith(
          fontWeight: theme.typography.headingWeight,
          color: theme.text,
        ),
      ),
    );
    final close = showClose
        ? YumeiroButton(
            variant: YumeiroButtonVariant.ghost,
            icon: theme.icons.close,
            tooltip: l10n.close,
            onPressed: canDismiss
                ? (onClose ?? () => Navigator.of(context).maybePop())
                : null,
          )
        : null;
    final inlineAccessoryMinWidth =
        320 + (showClose ? metrics.minTargetSize + gap : 0);

    return PopScope(
      canPop: canDismiss,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
          child: YumeiroVisualSurface(
            role: YumeiroSurfaceRole.modal,
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(
                    22,
                    metrics.verticalPadding,
                    16,
                    metrics.verticalPadding,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final stacked =
                          headerAccessory != null &&
                          constraints.maxWidth < inlineAccessoryMinWidth;
                      final row = ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: metrics.minTargetSize,
                        ),
                        child: Row(
                          spacing: gap,
                          children: [
                            Expanded(child: heading),
                            if (!stacked) ?headerAccessory,
                            ?close,
                          ],
                        ),
                      );
                      if (!stacked) return row;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: gap,
                        children: [row, headerAccessory],
                      );
                    },
                  ),
                ),
                if (child case final body?) ...[
                  Divider(height: 1, color: theme.line),
                  Flexible(
                    child: _dialogBody(
                      Padding(
                        key: const Key('yumeiro-dialog-body-padding'),
                        padding: contentPadding,
                        child: body,
                      ),
                      scrollable: scrollable,
                    ),
                  ),
                ],
                if (actions != null && actions.isNotEmpty) ...[
                  Divider(height: 1, color: theme.line),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: metrics.verticalPadding,
                    ),
                    child: YumeiroBackdropGroup(
                      child: Wrap(
                        alignment: WrapAlignment.end,
                        runSpacing: 10,
                        spacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: actions,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TouchDialogShell extends StatelessWidget {
  const _TouchDialogShell({required this.dialog, required this.child});

  final YumeiroDialog dialog;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final YumeiroDialog(
      :title,
      :headerAccessory,
      :actions,
      :maxWidth,
      :maxHeight,
      :onClose,
      :scrollable,
      :contentPadding,
      :canDismiss,
    ) = dialog;
    final theme = YumeiroTheme.of(context);
    final l10n = YumeiroLocalizations.of(context);
    const contentInset = yumeiroActionBarInset;
    final padding = contentPadding == YumeiroDialog.defaultContentPadding
        ? const EdgeInsets.all(contentInset)
        : contentPadding;
    final appBar = YumeiroPageHeader.compact(
      title: title,
      namesRoute: true,
      actions: [
        if (dialog.showClose)
          YumeiroButton(
            variant: YumeiroButtonVariant.ghost,
            icon: theme.icons.close,
            tooltip: l10n.close,
            onPressed: canDismiss
                ? (onClose ?? () => Navigator.of(context).maybePop())
                : null,
          ),
      ],
    );
    final footer = actions != null && actions.isNotEmpty
        ? YumeiroActionBar(
            showBackground: false,
            primaryAction: actions.last,
            secondaryActions: actions.take(actions.length - 1).toList(),
          )
        : null;
    return PopScope(
      canPop: canDismiss,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
          child: YumeiroVisualSurface(
            role: YumeiroSurfaceRole.modal,
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: contentInset),
                  child: appBar,
                ),
                if (headerAccessory != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: contentInset,
                      vertical: 8,
                    ),
                    child: headerAccessory,
                  ),
                if (child case final body?)
                  Flexible(
                    child: _dialogBody(
                      Padding(
                        key: scrollable
                            ? const Key('yumeiro-dialog-body-padding')
                            : null,
                        padding: padding,
                        child: body,
                      ),
                      scrollable: scrollable,
                    ),
                  ),
                ?footer,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Controls an active sheet modal route for external live updates or dismissal.
class YumeiroSheetController {
  _YumeiroModalRoute<Object?>? _route;

  /// Rebuilds the open sheet from its owner's current inputs.
  void refresh() {
    final route = _route;
    if (route == null) return;
    final binding = WidgetsBinding.instance;
    binding.addPostFrameCallback((_) {
      if (route.isActive) route.refreshContent();
    });
    binding.ensureVisualUpdate();
  }

  /// Closes the attached sheet on the next frame without a result.
  void close() {
    final route = _route;
    if (route == null) return;
    final binding = WidgetsBinding.instance;
    binding.addPostFrameCallback((_) {
      if (route.isActive) route.navigator?.removeRoute(route);
    });
    binding.ensureVisualUpdate();
  }
}

/// Internal route entry for sheets using the shared modal backdrop.
Future<T?> presentYumeiroSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  required bool barrierDismissible,
  required bool useRootNavigator,
  YumeiroSheetController? controller,
}) => _presentModal<T>(
  context: context,
  builder: builder,
  barrierDismissible: barrierDismissible,
  useRootNavigator: useRootNavigator,
  sheet: true,
  controller: controller,
);

Future<T?> _presentModal<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  required bool barrierDismissible,
  required bool useRootNavigator,
  bool sheet = false,
  YumeiroSheetController? controller,
}) {
  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  final route = _YumeiroModalRoute<T>(
    themes: YumeiroCapturedConfiguration.capture(context, navigator.context),
    builder: builder,
    barrierDismissible: barrierDismissible,
    barrierLabel: YumeiroLocalizations.of(context).close,
    transitionDuration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : YumeiroTheme.of(context).motion.normal,
    sheet: sheet,
  );
  controller?._route = route;
  final result = navigator.push<T>(route);
  if (controller == null) return result;
  return result.whenComplete(() {
    if (identical(controller._route, route)) controller._route = null;
  });
}

class _YumeiroModalRoute<T> extends PopupRoute<T> {
  _YumeiroModalRoute({
    required this.builder,
    required this.themes,
    required this.barrierDismissible,
    required this.barrierLabel,
    required this.transitionDuration,
    this.sheet = false,
  });

  final WidgetBuilder builder;
  final YumeiroCapturedConfiguration themes;
  final bool sheet;

  @override
  final bool barrierDismissible;

  @override
  Color get barrierColor => Colors.transparent;

  @override
  final String? barrierLabel;

  @override
  final Duration transitionDuration;

  CurvedAnimation? _curved;
  ui.ImageFilter? _backdropFilter;
  double? _backdropSigma;

  void refreshContent() => changedExternalState();

  CurvedAnimation _curve(Animation<double> animation) {
    if (_curved?.parent != animation) {
      _curved?.dispose();
      _curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    }
    return _curved!;
  }

  ui.ImageFilter _filterFor(double sigma) {
    if (_backdropSigma != sigma) {
      _backdropSigma = sigma;
      _backdropFilter = ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma);
    }
    return _backdropFilter!;
  }

  @override
  void dispose() {
    _curved?.dispose();
    super.dispose();
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => Semantics(
    scopesRoute: true,
    explicitChildNodes: true,
    child: DisplayFeatureSubScreen(child: Builder(builder: builder)),
  );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = _curve(animation);
    return themes.wrap(
      Builder(
        builder: (context) {
          final modalVisuals = YumeiroTheme.of(context).modalVisuals;
          final reduceMotion = MediaQuery.disableAnimationsOf(context);
          final size = MediaQuery.sizeOf(context);
          final bottomSheet =
              sheet && yumeiroDocksSelectionSheet(context, size);

          final backdropProgress = animation.status == AnimationStatus.reverse
              ? animation.value
              : 1.0;
          final effectiveBlur = modalVisuals.backdropBlur;

          final Widget backdrop;
          if (backdropProgress <= 0) {
            backdrop = const SizedBox.shrink();
          } else if (effectiveBlur > 0) {
            final fading = backdropProgress < 1.0;
            final filtered = BackdropFilter(
              filter: _filterFor(effectiveBlur),
              blendMode: fading ? BlendMode.srcOver : BlendMode.src,
              child: ColoredBox(color: modalVisuals.barrierColor),
            );
            backdrop = fading
                ? Opacity(opacity: backdropProgress, child: filtered)
                : filtered;
          } else {
            backdrop = ColoredBox(
              color: modalVisuals.barrierColor.withValues(
                alpha: modalVisuals.barrierColor.a * backdropProgress,
              ),
            );
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(child: IgnorePointer(child: backdrop)),
              Align(
                alignment: bottomSheet
                    ? Alignment.bottomCenter
                    : Alignment.center,
                child: bottomSheet
                    ? SlideTransition(
                        position: Tween<Offset>(
                          begin: reduceMotion
                              ? Offset.zero
                              : const Offset(0, 0.15),
                          end: Offset.zero,
                        ).animate(curved),
                        child: child,
                      )
                    : ScaleTransition(
                        scale: Tween<double>(
                          begin: reduceMotion ? 1 : modalVisuals.entryScale,
                          end: 1,
                        ).animate(curved),
                        child: child,
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
