import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../../foundation/modality.dart';
import '../../l10n/localizations.dart';
import '../../primitives/visual_surface.dart';
import '../../theme/semantic_visuals.dart';
import '../../theme/theme.dart';
import '../../theme/visual_role.dart';
import '../controls/buttons.dart';
import 'toast_obstruction.dart';

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

  /// Time before automatic removal from the host. Touch-only hosts count
  /// time while this notification is in front. Zero leaves it in the queue
  /// until dismissed or displaced by newer entries. Accessible navigation
  /// defers the countdown for notifications with a tap action.
  final Duration duration;
  final int? maxLines;
  final bool copyOnTap;
  final String? copyText;
  final VoidCallback? onTap;

  bool get _hasAction => copyOnTap || onTap != null;

  bool get _hasPriority {
    if (duration <= Duration.zero || onTap != null) return true;
    for (
      YumeiroStatusRole? role = statusRole;
      role != null;
      role = role.fallback
    ) {
      if (role == YumeiroStatusRole.warning ||
          role == YumeiroStatusRole.danger) {
        return true;
      }
    }
    return false;
  }
}

/// Manages transient toast notifications for [YumeiroToastHost].
class YumeiroToastController extends ChangeNotifier {
  static const _capacity = 4;
  static const _returnDuration = Duration(milliseconds: 1500);
  final List<YumeiroToastEntry> _entries = <YumeiroToastEntry>[];
  final _timers = <int, _ToastCountdown>{};
  final _pausedDurations = <int, Duration>{};
  final _hosts = <Object, ({bool touch, bool accessibleNavigation})>{};
  int? _touchForegroundId;
  int _nextId = 1;

  List<YumeiroToastEntry> get entries =>
      List<YumeiroToastEntry>.unmodifiable(_entries);

  // A pointer host still displays every entry even when a touch host shares
  // its controller.
  bool get _onlyTouchHosts =>
      _hosts.isNotEmpty && _hosts.values.every((policy) => policy.touch);

  /// Adds a notification and returns the identifier accepted by [dismiss].
  /// The controller keeps up to four entries. When full, touch-only hosts
  /// prefer to remove the oldest timed entry without an explicit tap action
  /// or warning or danger status before removing a higher priority entry.
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
    if (_entries.length == _capacity) {
      final firstOrdinary = _onlyTouchHosts
          ? _entries.indexWhere((entry) => !entry._hasPriority)
          : -1;
      _removeAt(firstOrdinary < 0 ? 0 : firstOrdinary);
    }
    _entries.add(entry);
    _syncTimers();
    notifyListeners();
    return id;
  }

  void _setHostTimingPolicy(
    Object host, {
    required bool touch,
    required bool accessibleNavigation,
  }) {
    final policy = (touch: touch, accessibleNavigation: accessibleNavigation);
    if (_hosts[host] == policy) return;
    _hosts[host] = policy;
    _syncTimers();
  }

  void _removeHostTimingPolicy(Object host) {
    if (_hosts.remove(host) != null) _syncTimers();
  }

  void _syncTimers() {
    final previousForeground = _touchForegroundId;
    final foreground = _onlyTouchHosts && _entries.isNotEmpty
        ? _entries.last.id
        : null;
    final accessible = _hosts.values.any(
      (policy) => policy.accessibleNavigation,
    );
    _touchForegroundId = foreground;

    for (final entry in _entries) {
      if (entry.duration <= Duration.zero) continue;
      final id = entry.id;
      if (foreground != null && id != foreground) {
        final active = _timers.remove(id);
        if (active != null || id == previousForeground) {
          final remaining =
              active?.pause() ?? _pausedDurations[id] ?? entry.duration;
          _pausedDurations[id] = remaining < _returnDuration
              ? _returnDuration
              : remaining;
        }
      } else if (accessible && entry._hasAction) {
        _timers.remove(id)?.cancel();
      } else {
        _timers[id] ??= _ToastCountdown(
          _pausedDurations.remove(id) ?? entry.duration,
          () => dismiss(id),
        );
      }
    }
  }

  void _removeAt(int index) {
    final entry = _entries.removeAt(index);
    _timers.remove(entry.id)?.cancel();
    _pausedDurations.remove(entry.id);
  }

  void dismiss(int id) {
    final index = _entries.indexWhere((entry) => entry.id == id);
    if (index < 0) return;
    _removeAt(index);
    _syncTimers();
    notifyListeners();
  }

  @override
  void dispose() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    _pausedDurations.clear();
    _hosts.clear();
    super.dispose();
  }
}

class _ToastCountdown {
  _ToastCountdown(this.duration, VoidCallback onElapsed)
    : _timer = Timer(duration, onElapsed);

  final Duration duration;
  final Timer _timer;
  final Stopwatch _elapsed = Stopwatch()..start();

  Duration pause() {
    cancel();
    return duration - _elapsed.elapsed;
  }

  void cancel() {
    _timer.cancel();
    _elapsed.stop();
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
  late final _obstruction = ToastObstruction(context);
  YumeiroToastController? _ownedController;
  YumeiroToastController? _visibleController;
  // Presentation-only retention while removed entries finish their exit.
  final List<YumeiroToastEntry> _visibleEntries = [];

  YumeiroToastController get _controller =>
      widget.controller ?? (_ownedController ??= YumeiroToastController());

  void _updateTimingPolicy() {
    final touch =
        YumeiroModalityScope.modalityOf(context) == YumeiroModality.touch;
    final media = touch ? MediaQuery.maybeOf(context) : null;
    _obstruction.updateMedia(media);
    _controller._setHostTimingPolicy(
      this,
      touch: touch,
      accessibleNavigation:
          media?.accessibleNavigation ??
          MediaQuery.maybeAccessibleNavigationOf(context) ??
          false,
    );
  }

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
    previousController?._removeHostTimingPolicy(this);
    _updateTimingPolicy();
  }

  @override
  void dispose() {
    _controller._removeHostTimingPolicy(this);
    _ownedController?.dispose();
    _obstruction.dispose();
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
          ToastObstructionScope(obstruction: _obstruction, child: widget.child),
          ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              final entries = controller.entries;
              final isTouch =
                  YumeiroModalityScope.modalityOf(context) ==
                  YumeiroModality.touch;
              if (isTouch) {
                _visibleController = null;
                _visibleEntries.clear();
                return _buildTouch(context, controller, entries);
              }
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
              final effectiveAlignment = widget.alignment ?? Alignment.topRight;
              return SafeArea(
                child: Align(
                  alignment: effectiveAlignment,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 56, 24, 16),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 380),
                      child: SingleChildScrollView(
                        primary: false,
                        reverse: true,
                        hitTestBehavior: HitTestBehavior.deferToChild,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
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
                                child: _hostedToast(controller, entry),
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

  Widget _buildTouch(
    BuildContext context,
    YumeiroToastController controller,
    List<YumeiroToastEntry> entries,
  ) {
    final alignment = (widget.alignment ?? Alignment.bottomCenter).resolve(
      Directionality.of(context),
    );
    final media = MediaQuery.of(context);
    final duration = media.disableAnimations
        ? Duration.zero
        : YumeiroTheme.of(context).motion.normal;
    return ValueListenableBuilder(
      valueListenable: _obstruction,
      builder: (context, insets, _) => _TouchToastStack(
        key: ObjectKey(controller),
        controller: controller,
        entries: entries,
        alignment: alignment,
        bottomInset: math.max(
          widget.alignment == null ? insets.navigation : 0.0,
          insets.system,
        ),
        duration: duration,
      ),
    );
  }
}

YumeiroToast _hostedToast(
  YumeiroToastController controller,
  YumeiroToastEntry entry,
) => YumeiroToast(
  key: ValueKey(entry.id),
  message: entry.message,
  title: entry.title,
  statusRole: entry.statusRole,
  icon: entry.icon,
  maxLines: entry.maxLines,
  copyOnTap: entry.copyOnTap,
  copyText: entry.copyText,
  onTap: entry.onTap,
  onClose: () => controller.dismiss(entry.id),
);

class _TouchToastStack extends StatefulWidget {
  const _TouchToastStack({
    super.key,
    required this.controller,
    required this.entries,
    required this.alignment,
    required this.bottomInset,
    required this.duration,
  });

  final YumeiroToastController controller;
  final List<YumeiroToastEntry> entries;
  final Alignment alignment;
  final double bottomInset;
  final Duration duration;

  bool get fromTop => alignment.y < 0;

  @override
  State<_TouchToastStack> createState() => _TouchToastStackState();
}

class _TouchToastStackState extends State<_TouchToastStack>
    with SingleTickerProviderStateMixin {
  static const _exitDuration = Duration(milliseconds: 150);
  static const _edge = 6.0;

  late final _transition = AnimationController(vsync: this, value: 1)
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed && _outgoing != null) {
        setState(() => _outgoing = null);
      }
    });
  YumeiroToastEntry? _outgoing;

  @override
  void initState() {
    super.initState();
    if (widget.entries.isNotEmpty) _startTransition();
  }

  @override
  void didUpdateWidget(covariant _TouchToastStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previous = oldWidget.entries.lastOrNull;
    if (previous?.id != widget.entries.lastOrNull?.id) {
      _outgoing =
          previous != null &&
              !widget.entries.any((entry) => entry.id == previous.id)
          ? previous
          : null;
      _startTransition();
    } else if (widget.duration == Duration.zero &&
        oldWidget.duration != Duration.zero) {
      _startTransition();
    }
  }

  void _startTransition() {
    if (widget.duration == Duration.zero) {
      _outgoing = null;
      _transition.value = 1;
      return;
    }
    _transition.duration =
        _outgoing != null &&
            (widget.entries.isEmpty || widget.duration < _exitDuration)
        ? _exitDuration
        : widget.duration;
    _transition.forward(from: 0);
  }

  double _elapsed(Duration duration) {
    if (duration == Duration.zero || _transition.isCompleted) return 1;
    final elapsed =
        _transition.value * (_transition.duration?.inMicroseconds ?? 0);
    return (elapsed / duration.inMicroseconds).clamp(0.0, 1.0);
  }

  Widget _animate(YumeiroToastEntry entry, {required bool leaving}) {
    final direction = widget.fromTop ? -1.0 : 1.0;
    return AnimatedBuilder(
      key: ValueKey(entry.id),
      animation: _transition,
      child: _hostedToast(widget.controller, entry),
      builder: (context, child) {
        final animation = _elapsed(leaving ? _exitDuration : widget.duration);
        final progress = leaving
            ? Curves.easeInCubic.transform(animation)
            : Curves.easeOutCubic.transform(animation);
        final offset = leaving
            ? 12 * progress
            : (_outgoing == null ? 16 : -_edge) * (1 - progress);
        return Opacity(
          opacity: leaving ? 1 - progress : progress,
          child: Transform.translate(
            offset: Offset(0, offset * direction),
            child: Transform.scale(
              alignment: widget.fromTop
                  ? Alignment.topCenter
                  : Alignment.bottomCenter,
              scale: leaving ? 1 : .96 + .04 * progress,
              child: child,
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _transition.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final front = widget.entries.lastOrNull;
    final outgoing = _outgoing;
    if (front == null && outgoing == null) return const SizedBox.shrink();
    final leaving = outgoing == null
        ? null
        : ExcludeSemantics(
            child: ExcludeFocus(
              child: IgnorePointer(child: _animate(outgoing, leaving: true)),
            ),
          );
    final cards = SingleChildScrollView(
      primary: false,
      reverse: !widget.fromTop,
      hitTestBehavior: HitTestBehavior.deferToChild,
      clipBehavior: Clip.none,
      child: front == null ? leaving! : _buildStack(context, front, leaving),
    );
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: widget.bottomInset),
        child: ClipRect(
          child: Align(
            alignment: widget.alignment,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: SizedBox(width: double.infinity, child: cards),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStack(
    BuildContext context,
    YumeiroToastEntry front,
    Widget? leaving,
  ) {
    final appearance = YumeiroTheme.of(context).visuals
        .surface(YumeiroSurfaceRole.toast);
    final shape = appearance.shape.copyWith(side: appearance.outline);
    final foreground = _animate(front, leaving: false);
    final above = !widget.fromTop;
    final depth = math.min(2, widget.entries.length - 1).toDouble();
    return TweenAnimationBuilder<double>(
      duration: widget.duration,
      tween: Tween(begin: 0, end: depth),
      child: foreground,
      builder: (context, visibleDepth, child) {
        Widget edge(int level) {
          final reveal = (visibleDepth - level + 1).clamp(0.0, 1.0);
          final offset = _edge * level * reveal * (above ? -1 : 1);
          final inset = 8.0 * level;
          return Positioned(
            key: ValueKey('yumeiro-toast-back-layer-$level'),
            top: offset,
            bottom: -offset,
            left: inset,
            right: inset,
            child: IgnorePointer(
              child: Opacity(
                opacity: reveal * (level == 1 ? .85 : .65),
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    color: appearance.background,
                    shape: shape,
                  ),
                ),
              ),
            ),
          );
        }

        final extension = _edge * visibleDepth;
        return Padding(
          padding: EdgeInsets.only(
            top: above ? extension : 0,
            bottom: above ? 0 : extension,
          ),
          child: Stack(
            fit: StackFit.passthrough,
            clipBehavior: Clip.none,
            children: [
              if (visibleDepth > 1) edge(2),
              if (visibleDepth > 0) edge(1),
              if (leaving != null)
                Positioned(
                  left: 0,
                  right: 0,
                  top: above ? null : 0,
                  bottom: above ? 0 : null,
                  child: leaving,
                ),
              child!,
            ],
          ),
        );
      },
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
