import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../../foundation/modality.dart';
import '../../l10n/localizations.dart';
import '../../primitives/visual_surface.dart';
import '../../theme/semantic_visuals.dart';
import '../../theme/theme.dart';
import '../../theme/visual_role.dart';
import '../controls/buttons.dart';

/// Immutable content and lifetime of one hosted notification.
@immutable
class YumeiroToastEntry {
  const YumeiroToastEntry({
    required this.id,
    required this.message,
    this.title,
    this.statusRole = YumeiroStatusRole.neutral,
    this.icon,
    this.duration = const Duration(seconds: 3),
    this.maxLines = 3,
    this.copyOnTap = true,
    this.copyText,
    this.onTap,
  });

  final int id;
  final String message;
  final String? title;
  final YumeiroStatusRole statusRole;
  final IconData? icon;

  /// Time before automatic removal from the host. Zero leaves it in the queue
  /// until dismissed or displaced by newer entries. A host using accessible
  /// navigation defers the countdown for notifications with a tap action.
  final Duration duration;
  final int? maxLines;
  final bool copyOnTap;
  final String? copyText;
  final VoidCallback? onTap;

  bool get _hasAction => copyOnTap || onTap != null;
}

/// Manages transient toast notifications for [YumeiroToastHost].
class YumeiroToastController extends ChangeNotifier {
  final List<YumeiroToastEntry> _entries = <YumeiroToastEntry>[];
  final Map<int, Timer> _timers = <int, Timer>{};
  final Set<Object> _accessibleNavigationHosts = <Object>{};
  int _nextId = 1;

  List<YumeiroToastEntry> get entries =>
      List<YumeiroToastEntry>.unmodifiable(_entries);

  /// Adds a notification and returns the identifier accepted by [dismiss].
  /// The host keeps up to four entries and removes the oldest when full.
  int show({
    required String message,
    String? title,
    YumeiroStatusRole statusRole = YumeiroStatusRole.neutral,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
    int? maxLines = 3,
    bool copyOnTap = true,
    String? copyText,
    VoidCallback? onTap,
  }) {
    final id = _nextId++;
    final entry = YumeiroToastEntry(
      id: id,
      message: message,
      title: title,
      statusRole: statusRole,
      icon: icon,
      duration: duration,
      maxLines: maxLines,
      copyOnTap: copyOnTap,
      copyText: copyText,
      onTap: onTap,
    );
    _entries.add(entry);
    if (_entries.length > 4) {
      final oldest = _entries.removeAt(0);
      _timers.remove(oldest.id)?.cancel();
    }
    _startTimer(entry);
    notifyListeners();
    return id;
  }

  void _startTimer(YumeiroToastEntry entry) {
    if (entry.duration <= Duration.zero ||
        (entry._hasAction && _accessibleNavigationHosts.isNotEmpty)) {
      return;
    }
    _timers[entry.id] = Timer(entry.duration, () => dismiss(entry.id));
  }

  void _setAccessibleNavigation(Object host, bool enabled) {
    final wasAccessible = _accessibleNavigationHosts.isNotEmpty;
    if (enabled) {
      _accessibleNavigationHosts.add(host);
    } else {
      _accessibleNavigationHosts.remove(host);
    }
    if (wasAccessible == _accessibleNavigationHosts.isNotEmpty) return;
    for (final entry in _entries.where((entry) => entry._hasAction)) {
      if (enabled) {
        _timers.remove(entry.id)?.cancel();
      } else {
        _startTimer(entry);
      }
    }
  }

  void dismiss(int id) {
    _timers.remove(id)?.cancel();
    final before = _entries.length;
    _entries.removeWhere((e) => e.id == id);
    if (_entries.length != before) notifyListeners();
  }

  @override
  void dispose() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    _accessibleNavigationHosts.clear();
    super.dispose();
  }
}

/// Makes a toast controller visible to descendants of a [YumeiroToastHost].
class YumeiroToastScope extends InheritedNotifier<YumeiroToastController> {
  const YumeiroToastScope({
    super.key,
    required YumeiroToastController controller,
    required super.child,
  }) : super(notifier: controller);

  static YumeiroToastController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<YumeiroToastScope>()?.notifier;

  static YumeiroToastController of(BuildContext context) {
    final controller = maybeOf(context);
    assert(controller != null, 'No YumeiroToastScope found in context.');
    return controller!;
  }
}

/// Shows a toast under a [YumeiroToastHost]. The nearest [ScaffoldMessenger]
/// can present a simple themed toast if a Yumeiro host is unavailable.
void showYumeiroToast(
  BuildContext context,
  String message, {
  String? title,
  YumeiroStatusRole statusRole = YumeiroStatusRole.neutral,
  IconData? icon,
  Duration duration = const Duration(seconds: 3),
  int? maxLines = 3,
  bool copyOnTap = true,
  String? copyText,
  VoidCallback? onTap,
}) {
  final controller = YumeiroToastScope.maybeOf(context);
  if (controller != null) {
    controller.show(
      message: message,
      title: title,
      statusRole: statusRole,
      icon: icon,
      duration: duration,
      maxLines: maxLines,
      copyOnTap: copyOnTap,
      copyText: copyText,
      onTap: onTap,
    );
    return;
  }
  final messenger = ScaffoldMessenger.maybeOf(context);
  messenger?.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      padding: EdgeInsets.zero,
      duration: duration,
      content: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: YumeiroToast(
          message: message,
          title: title,
          statusRole: statusRole,
          icon: icon,
          maxLines: maxLines,
          copyOnTap: false,
        ),
      ),
    ),
  );
}

/// Overlay host rendering [YumeiroToastController] entries using
/// [YumeiroSurfaceRole.toast].
class YumeiroToastHost extends StatefulWidget {
  const YumeiroToastHost({
    super.key,
    required this.child,
    this.controller,
    this.alignment,
  });

  final Widget child;
  final YumeiroToastController? controller;
  final AlignmentGeometry? alignment;

  @override
  State<YumeiroToastHost> createState() => _YumeiroToastHostState();
}

class _YumeiroToastHostState extends State<YumeiroToastHost> {
  YumeiroToastController? _ownedController;
  YumeiroToastController? _visibleController;
  // Presentation-only retention while removed entries finish their exit.
  final List<YumeiroToastEntry> _visibleEntries = [];

  YumeiroToastController get _controller =>
      widget.controller ?? (_ownedController ??= YumeiroToastController());

  void _updateTimingPolicy() => _controller._setAccessibleNavigation(
    this,
    MediaQuery.maybeAccessibleNavigationOf(context) ?? false,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateTimingPolicy();
  }

  @override
  void didUpdateWidget(YumeiroToastHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.controller, widget.controller)) return;
    final previousController = oldWidget.controller ?? _ownedController;
    previousController?._setAccessibleNavigation(this, false);
    _updateTimingPolicy();
  }

  @override
  void dispose() {
    widget.controller?._setAccessibleNavigation(this, false);
    _ownedController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return YumeiroToastScope(
      controller: controller,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          widget.child,
          ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              final entries = controller.entries;
              if (!identical(_visibleController, controller)) {
                _visibleController = controller;
                _visibleEntries.clear();
              }
              final visibleIds = _visibleEntries
                  .map((entry) => entry.id)
                  .toSet();
              _visibleEntries.addAll(
                entries.where((entry) => !visibleIds.contains(entry.id)),
              );
              if (_visibleEntries.isEmpty) return const SizedBox.shrink();
              final activeIds = entries.map((entry) => entry.id).toSet();
              final modality = YumeiroModalityScope.modalityOf(context);
              final isTouch = modality == YumeiroModality.touch;
              final effectiveAlignment =
                  widget.alignment ??
                  (isTouch ? Alignment.bottomCenter : Alignment.topRight);
              return SafeArea(
                child: Align(
                  alignment: effectiveAlignment,
                  child: Padding(
                    padding: isTouch
                        ? const EdgeInsets.all(16)
                        : const EdgeInsets.fromLTRB(24, 56, 24, 16),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 380),
                      child: SingleChildScrollView(
                        primary: false,
                        reverse: true,
                        hitTestBehavior: HitTestBehavior.deferToChild,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: isTouch
                              ? CrossAxisAlignment.stretch
                              : CrossAxisAlignment.end,
                          children: [
                            for (final entry in _visibleEntries) ...[
                              _AnimatedToastItem(
                                key: ValueKey((controller, entry.id)),
                                exiting: !activeIds.contains(entry.id),
                                onDismissed: () {
                                  if (!mounted ||
                                      !identical(
                                        _visibleController,
                                        controller,
                                      )) {
                                    return;
                                  }
                                  setState(() => _visibleEntries.remove(entry));
                                },
                                duration:
                                    MediaQuery.disableAnimationsOf(context)
                                    ? Duration.zero
                                    : YumeiroTheme.of(context).motion.normal,
                                child: YumeiroToast(
                                  message: entry.message,
                                  title: entry.title,
                                  statusRole: entry.statusRole,
                                  icon: entry.icon,
                                  maxLines: entry.maxLines,
                                  copyOnTap: entry.copyOnTap,
                                  copyText: entry.copyText,
                                  onTap: entry.onTap,
                                  onClose: () => controller.dismiss(entry.id),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AnimatedToastItem extends StatefulWidget {
  const _AnimatedToastItem({
    super.key,
    required this.duration,
    required this.child,
    required this.exiting,
    required this.onDismissed,
  });

  final Duration duration;
  final Widget child;
  final bool exiting;
  final VoidCallback onDismissed;

  @override
  State<_AnimatedToastItem> createState() => _AnimatedToastItemState();
}

class _AnimatedToastItemState extends State<_AnimatedToastItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _slide = Tween<Offset>(
      begin: const Offset(1.1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    if (widget.duration == Duration.zero) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
    if (widget.exiting) _dismiss();
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      if (mounted && widget.exiting) widget.onDismissed();
    });
  }

  void _revealOnFocus(bool focused) {
    if (!focused || widget.exiting) return;
    final position = Scrollable.maybeOf(context)?.position;
    final target = context.findRenderObject();
    if (position == null || target == null) return;
    // Traversal can reach a card clipped at either end of the reversed stack.
    unawaited(
      position.ensureVisible(
        target,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      ),
    );
    unawaited(
      position.ensureVisible(
        target,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant _AnimatedToastItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
      if (!widget.exiting && widget.duration == Duration.zero) {
        _controller.value = 1;
      }
    }
    if (widget.exiting &&
        (!oldWidget.exiting || oldWidget.duration != widget.duration)) {
      _dismiss();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    excluding: widget.exiting,
    child: ExcludeFocus(
      excluding: widget.exiting,
      child: Focus(
        canRequestFocus: false,
        includeSemantics: false,
        onFocusChange: _revealOnFocus,
        child: IgnorePointer(
          ignoring: widget.exiting,
          child: SlideTransition(position: _slide, child: widget.child),
        ),
      ),
    ),
  );
}

/// Standalone floating feedback card backed by [YumeiroSurfaceRole.toast].
class YumeiroToast extends StatefulWidget {
  const YumeiroToast({
    super.key,
    required this.message,
    this.title,
    this.statusRole = YumeiroStatusRole.neutral,
    this.icon,
    this.maxLines = 3,
    this.copyOnTap = true,
    this.copyText,
    this.onTap,
    this.onClose,
  });

  final String message;
  final String? title;

  /// Uses the theme's status palette for the notification icon color.
  final YumeiroStatusRole statusRole;
  final IconData? icon;
  final int? maxLines;
  final bool copyOnTap;
  final String? copyText;
  final VoidCallback? onTap;
  final VoidCallback? onClose;

  @override
  State<YumeiroToast> createState() => _YumeiroToastState();
}

class _YumeiroToastState extends State<YumeiroToast> {
  bool _copied = false;
  Timer? _copiedTimer;
  int _copyRequest = 0;

  String get _resolvedCopyText {
    final explicit = widget.copyText;
    if (explicit != null) return explicit;
    final title = widget.title?.trim();
    if (title != null && title.isNotEmpty) {
      return '$title\n${widget.message}';
    }
    return widget.message;
  }

  @override
  void didUpdateWidget(covariant YumeiroToast oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message != widget.message ||
        oldWidget.title != widget.title ||
        oldWidget.copyText != widget.copyText ||
        oldWidget.copyOnTap != widget.copyOnTap) {
      _copyRequest++;
      _copiedTimer?.cancel();
      _copied = false;
    }
  }

  @override
  void dispose() {
    _copiedTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleTap() async {
    widget.onTap?.call();
    if (!mounted || !widget.copyOnTap) return;
    final text = _resolvedCopyText;
    if (text.isEmpty) return;
    final request = ++_copyRequest;
    _copiedTimer?.cancel();
    if (_copied) setState(() => _copied = false);
    try {
      await Clipboard.setData(ClipboardData(text: text));
    } on PlatformException {
      return;
    } on MissingPluginException {
      return;
    }
    if (!mounted || request != _copyRequest) return;
    if (YumeiroModalityScope.modalityOf(context) == YumeiroModality.touch) {
      unawaited(HapticFeedback.selectionClick());
    }
    setState(() => _copied = true);
    _copiedTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() => _copied = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final l10n = YumeiroLocalizations.of(context);
    final metrics = YumeiroModalityScope.metricsOf(context);
    final statusRole = widget.statusRole;
    final canTap = widget.copyOnTap || widget.onTap != null;
    final effectiveIcon = _copied
        ? theme.icons.check
        : (widget.icon ??
              resolveYumeiroStatusFeedback(statusRole, theme.icons).icon);
    final feedbackColor = theme.visuals
        .status(_copied ? YumeiroStatusRole.success : statusRole)
        .foreground;
    final anchorHeight = metrics.isTouch ? metrics.minTargetSize : 26.0;
    final outerVerticalPadding = metrics.isTouch ? 8.0 : 12.0;
    final textExtraVerticalPadding = metrics.isTouch ? 4.0 : 0.0;
    final motionDuration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : theme.motion.fast;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: metrics.isTouch ? 0 : 260,
        maxWidth: 380,
      ),
      child: IntrinsicWidth(
        child: YumeiroVisualSurface(
          role: YumeiroSurfaceRole.toast,
          clipBehavior: Clip.antiAlias,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Material(
                  type: MaterialType.transparency,
                  child: Semantics(
                    button: canTap,
                    container: true,
                    liveRegion: true,
                    hint: widget.copyOnTap ? l10n.copy : null,
                    child: InkWell(
                      splashFactory: NoSplash.splashFactory,
                      overlayColor: const WidgetStatePropertyAll(
                        Colors.transparent,
                      ),
                      mouseCursor: canTap
                          ? SystemMouseCursors.click
                          : MouseCursor.defer,
                      onTap: canTap ? _handleTap : null,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          14,
                          outerVerticalPadding,
                          widget.onClose != null ? 8 : 14,
                          outerVerticalPadding,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: anchorHeight,
                              child: Center(
                                child: AnimatedSwitcher(
                                  duration: motionDuration,
                                  child: Icon(
                                    effectiveIcon,
                                    key: ValueKey(
                                      _copied
                                          ? 'copied'
                                          : effectiveIcon.codePoint,
                                    ),
                                    size: metrics.isTouch
                                        ? 24.0
                                        : theme.iconSizes.sm,
                                    color: feedbackColor,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: textExtraVerticalPadding,
                                ),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: metrics.isTouch
                                        ? metrics.controlHeight
                                        : anchorHeight,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (widget.title != null) ...[
                                        Text(
                                          widget.title!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme
                                              .typography
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                color: theme.text,
                                                fontWeight: theme
                                                    .typography
                                                    .emphasisWeight,
                                              ),
                                        ),
                                        const SizedBox(height: 2),
                                      ],
                                      Text(
                                        widget.message,
                                        maxLines: widget.maxLines,
                                        overflow: widget.maxLines != null
                                            ? TextOverflow.ellipsis
                                            : null,
                                        style: theme
                                            .typography
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: widget.title == null
                                                  ? theme.text
                                                  : theme.muted,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (widget.copyOnTap) ...[
                              const SizedBox(width: 8),
                              SizedBox(
                                height: anchorHeight,
                                child: Center(
                                  child: AnimatedSize(
                                    duration: motionDuration,
                                    curve: Curves.easeOutCubic,
                                    child: AnimatedSwitcher(
                                      duration: motionDuration,
                                      child: _copied
                                          ? Text(
                                              l10n.copied,
                                              key: const ValueKey(
                                                'copied-label',
                                              ),
                                              style: theme.typography.caption
                                                  .copyWith(
                                                    color: feedbackColor,
                                                    fontWeight: theme
                                                        .typography
                                                        .emphasisWeight,
                                                  ),
                                            )
                                          : Icon(
                                              theme.icons.copy,
                                              key: const ValueKey('copy-icon'),
                                              size: 13,
                                              color: theme.subtle,
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.onClose != null)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    0,
                    outerVerticalPadding,
                    metrics.isTouch ? 8 : 10,
                    outerVerticalPadding,
                  ),
                  child: metrics.isTouch
                      ? YumeiroButton(
                          icon: theme.icons.close,
                          tooltip: l10n.close,
                          variant: YumeiroButtonVariant.ghost,
                          dense: false,
                          onPressed: widget.onClose,
                        )
                      : YumeiroButton(
                          icon: theme.icons.close,
                          tooltip: l10n.close,
                          variant: YumeiroButtonVariant.ghost,
                          dense: true,
                          width: 26,
                          height: 26,
                          iconSize: theme.iconSizes.sm,
                          onPressed: widget.onClose,
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
