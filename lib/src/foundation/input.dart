import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/foundation.dart' show internal;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import 'modality.dart';

/// Most recent input source, tracked independently of layout modality.
enum YumeiroLastInputKind { pointer, touch, keyboard }

/// Tracks recent meaningful input source to coordinate keyboard focus rings
/// without changing logical focus.
class YumeiroInputController extends ChangeNotifier {
  YumeiroInputController();

  YumeiroLastInputKind _lastInputKind = YumeiroLastInputKind.pointer;
  final _keyboardFocus = ValueNotifier(false);

  /// Most recently recorded source. Initially [YumeiroLastInputKind.pointer].
  YumeiroLastInputKind get lastInputKind => _lastInputKind;

  /// Whether to use keyboard-focus styling. Keyboard input enables it, and
  /// pressing a pointer disables it. Mere movement retains the styling.
  bool get showKeyboardFocus => _keyboardFocus.value;

  void recordKeyboard() => _record(YumeiroLastInputKind.keyboard, focus: true);

  void recordPointerEvent(PointerEvent event) {
    _record(
      event.kind == PointerDeviceKind.touch
          ? YumeiroLastInputKind.touch
          : YumeiroLastInputKind.pointer,
      focus: event is PointerDownEvent ? false : null,
    );
  }

  void _record(YumeiroLastInputKind value, {bool? focus}) {
    final nextFocus = focus ?? _keyboardFocus.value;
    if (_lastInputKind == value && _keyboardFocus.value == nextFocus) return;
    _lastInputKind = value;
    _keyboardFocus.value = nextFocus;
    notifyListeners();
  }

  @override
  void dispose() {
    _keyboardFocus.dispose();
    super.dispose();
  }
}

/// Exposes an input controller for descendants that react to recent input.
class YumeiroInputScope extends InheritedNotifier<YumeiroInputController> {
  const YumeiroInputScope({
    super.key,
    required super.notifier,
    required super.child,
  });

  /// Subscribes to the nearest controller. Use [maybeOf] when an ancestor is
  /// optional.
  static YumeiroInputController of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<YumeiroInputScope>()!
      .notifier!;

  static YumeiroInputController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<YumeiroInputScope>()?.notifier;

  @internal
  static bool keyboardFocusOf(BuildContext context) {
    final controller = context
        .getInheritedWidgetOfExactType<YumeiroInputScope>()
        ?.notifier;
    final keyboardFocus = context
        .getInheritedWidgetOfExactType<_YumeiroKeyboardFocusScope>()
        ?.notifier;
    if (keyboardFocus != null &&
        identical(keyboardFocus, controller?._keyboardFocus)) {
      context.dependOnInheritedWidgetOfExactType<_YumeiroKeyboardFocusScope>();
      return keyboardFocus.value;
    }
    return maybeOf(context)?.showKeyboardFocus ?? true;
  }
}

class _YumeiroKeyboardFocusScope
    extends InheritedNotifier<ValueNotifier<bool>> {
  const _YumeiroKeyboardFocusScope({
    required super.notifier,
    required super.child,
  });
}

/// Tracks local pointer and keyboard input for Yumeiro focus styling.
///
/// Native controls continue to use the host's focus highlight strategy.
class YumeiroInputListener extends StatefulWidget {
  const YumeiroInputListener({super.key, required this.child, this.controller})
    : _initialKeyboardFocus = false;

  /// Seeds the local tracker when presenting an overlay outside its source scope.
  @internal
  const YumeiroInputListener.forOverlay({
    super.key,
    required this.child,
    required bool keyboardFocus,
  }) : controller = null,
       _initialKeyboardFocus = keyboardFocus;

  final Widget child;

  /// External tracker. When omitted, this listener creates and disposes one.
  final YumeiroInputController? controller;

  final bool _initialKeyboardFocus;

  @override
  State<YumeiroInputListener> createState() => _YumeiroInputListenerState();
}

class _YumeiroInputListenerState extends State<YumeiroInputListener> {
  static int _listenerCount = 0;
  static bool _traversalPending = false;

  late YumeiroInputController _controller;
  var _ownsController = false;

  @override
  void initState() {
    super.initState();
    _setController(widget.controller);
    if (_listenerCount++ == 0) {
      FocusManager.instance.addEarlyKeyEventHandler(_handleKeyEvent);
    }
  }

  static YumeiroInputController? _focusedController() {
    final context = FocusManager.instance.primaryFocus?.context;
    if (context == null || !context.mounted) return null;
    return context.getInheritedWidgetOfExactType<YumeiroInputScope>()?.notifier;
  }

  static KeyEventResult _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final controller = _focusedController();
    controller?.recordKeyboard();

    // Tab can land inside a different input scope after Flutter handles the key.
    if (event.logicalKey == LogicalKeyboardKey.tab && !_traversalPending) {
      _traversalPending = true;
      final binding = WidgetsBinding.instance;
      binding.addPostFrameCallback((_) {
        _traversalPending = false;
        if (_listenerCount == 0) return;
        final destination = _focusedController();
        if (!identical(destination, controller)) destination?.recordKeyboard();
      });
      binding.ensureVisualUpdate();
    }
    return KeyEventResult.ignored;
  }

  @override
  void didUpdateWidget(covariant YumeiroInputListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      final previous = _controller;
      final previousOwned = _ownsController;
      _setController(widget.controller);
      if (previousOwned && previous != _controller) previous.dispose();
    }
  }

  void _setController(YumeiroInputController? controller) {
    _controller = controller ?? YumeiroInputController();
    _ownsController = controller == null;
    if (_ownsController && widget._initialKeyboardFocus) {
      _controller.recordKeyboard();
    }
  }

  @override
  void dispose() {
    if (--_listenerCount == 0) {
      FocusManager.instance.removeEarlyKeyEventHandler(_handleKeyEvent);
    }
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => YumeiroInputScope(
    notifier: _controller,
    child: Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _controller.recordPointerEvent,
      onPointerMove: _controller.recordPointerEvent,
      onPointerHover: _controller.recordPointerEvent,
      onPointerSignal: _controller.recordPointerEvent,
      child: _YumeiroKeyboardFocusScope(
        notifier: _controller.runtimeType == YumeiroInputController
            ? _controller._keyboardFocus
            : null,
        child: widget.child,
      ),
    ),
  );
}

/// Touch modality dismisses active text editing on outside taps and scroll drags.
class YumeiroKeyboardDismissal extends StatelessWidget {
  const YumeiroKeyboardDismissal({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final touch =
        YumeiroModalityScope.modalityOf(context) == YumeiroModality.touch;
    final scrollBehavior = ScrollConfiguration.of(context);
    return Actions(
      actions: <Type, Action<Intent>>{
        if (touch)
          EditableTextTapOutsideIntent:
              CallbackAction<EditableTextTapOutsideIntent>(
                onInvoke: (intent) {
                  intent.focusNode.unfocus();
                  return null;
                },
              ),
      },
      child: ScrollConfiguration(
        behavior: touch
            ? scrollBehavior.copyWith(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
              )
            : scrollBehavior,
        child: child,
      ),
    );
  }
}
