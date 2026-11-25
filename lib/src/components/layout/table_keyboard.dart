import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Coordinates arrow-key selection for table rows and their radio controls.
class TableKeyboard extends StatefulWidget {
  const TableKeyboard({
    super.key,
    required this.rowKeys,
    required this.toggleFor,
    this.rovingTabStop = false,
    this.selectedKey,
    required this.child,
  });

  final List<Key> rowKeys;
  final VoidCallback? Function(int index) toggleFor;
  final bool rovingTabStop;
  final Key? selectedKey;
  final Widget child;

  @override
  State<TableKeyboard> createState() => _TableKeyboardState();
}

class _TableKeyboardState extends State<TableKeyboard> {
  final _targets = <Key, FocusNode>{};
  bool _seeking = false;

  void unregister(Key key, FocusNode node) {
    if (_targets[key] == node) _targets.remove(key);
  }

  FocusNode? _mountedTarget(Key key) {
    final node = _targets[key];
    var renderObject = node?.context?.findRenderObject();
    if (renderObject == null || !renderObject.attached) return null;
    while (renderObject != null && renderObject is! RenderViewportBase) {
      // A cell can keep a row alive in the sliver's offscreen cache.
      if (renderObject.parentData case SliverMultiBoxAdaptorParentData(
        keptAlive: true,
      )) {
        return null;
      }
      renderObject = renderObject.parent;
    }
    return node;
  }

  KeyEventResult move(Key source, int direction, BuildContext context) {
    if (_seeking) return KeyEventResult.handled;
    final index = widget.rowKeys.indexOf(source);
    if (index == -1) return KeyEventResult.ignored;
    for (
      var next = index + direction;
      next >= 0 && next < widget.rowKeys.length;
      next += direction
    ) {
      final toggle = widget.toggleFor(next);
      if (toggle == null) continue;

      final key = widget.rowKeys[next];
      final target = _mountedTarget(key);
      if (target != null) {
        _focus(target, direction);
        toggle();
      } else {
        final scroller = Scrollable.maybeOf(context, axis: Axis.vertical);
        if (scroller != null) {
          _seeking = true;
          unawaited(_reveal(key, next, direction, scroller));
        }
      }
      break;
    }
    return KeyEventResult.handled;
  }

  Future<void> _reveal(
    Key key,
    int index,
    int direction,
    ScrollableState scroller,
  ) async {
    while (mounted && scroller.mounted) {
      if (index >= widget.rowKeys.length || widget.rowKeys[index] != key) break;
      if (_mountedTarget(key) case final target?) {
        final toggle = widget.toggleFor(index);
        if (toggle != null) {
          _focus(target, direction);
          toggle();
        }
        break;
      }

      // Advance by part of a viewport so variable-height rows enter layout.
      final position = scroller.position;
      final next =
          (position.pixels + position.viewportDimension / 2 * direction).clamp(
            position.minScrollExtent,
            position.maxScrollExtent,
          );
      if (position.pixels == next) break;
      position.jumpTo(next);
      await WidgetsBinding.instance.endOfFrame;
    }
    _seeking = false;
  }

  void _focus(FocusNode node, int direction) {
    node.requestFocus();
    final targetContext = node.context!;
    final target = targetContext.findRenderObject()!;
    var context = targetContext;
    var scrollable = Scrollable.maybeOf(context);
    while (scrollable != null) {
      if (axisDirectionToAxis(scrollable.axisDirection) == Axis.vertical) {
        // Use the enclosing row's position in the vertical viewport. An
        // overflowing row also has its own horizontal viewport.
        unawaited(
          scrollable.position.ensureVisible(
            context.findRenderObject()!,
            targetRenderObject: target,
            alignmentPolicy: direction > 0
                ? ScrollPositionAlignmentPolicy.keepVisibleAtEnd
                : ScrollPositionAlignmentPolicy.keepVisibleAtStart,
          ),
        );
        return;
      }
      context = scrollable.context;
      scrollable = Scrollable.maybeOf(context);
    }
  }

  @override
  Widget build(BuildContext context) => _TableKeyboardScope(
    keyboard: this,
    child: widget.rovingTabStop
        ? FocusTraversalGroup(
            policy: _TableRadioTraversalPolicy(this),
            child: widget.child,
          )
        : widget.child,
  );
}

// Keep the table's cells and header controls in the usual reading order while
// exposing only one Tab stop for the column of lazy radio controls.
class _TableRadioTraversalPolicy extends ReadingOrderTraversalPolicy {
  _TableRadioTraversalPolicy(this.keyboard);

  final _TableKeyboardState keyboard;

  @override
  Iterable<FocusNode> sortDescendants(
    Iterable<FocusNode> descendants,
    FocusNode currentNode,
  ) {
    final nodes = super.sortDescendants(descendants, currentNode);
    final mounted = {
      for (final key in keyboard._targets.keys) ?keyboard._mountedTarget(key),
    };
    final selected = keyboard._targets[keyboard.widget.selectedKey];
    final tabStop = mounted.contains(selected) && nodes.contains(selected)
        ? selected
        : nodes.where(mounted.contains).firstOrNull;
    final targets = keyboard._targets.values.toSet();
    return nodes.where(
      (node) =>
          node == currentNode || node == tabStop || !targets.contains(node),
    );
  }
}

class _TableKeyboardScope extends InheritedWidget {
  const _TableKeyboardScope({required this.keyboard, required super.child});

  final _TableKeyboardState keyboard;

  @override
  bool updateShouldNotify(_TableKeyboardScope oldWidget) =>
      keyboard != oldWidget.keyboard;
}

/// Supplies the focus node of the exact control that can change selection.
class TableKeyboardTarget extends StatefulWidget {
  const TableKeyboardTarget({
    super.key,
    required this.rowKey,
    required this.builder,
  });

  final Key rowKey;
  final Widget Function(FocusNode focusNode) builder;

  @override
  State<TableKeyboardTarget> createState() => _TableKeyboardTargetState();
}

class _TableKeyboardTargetState extends State<TableKeyboardTarget> {
  final _focusNode = FocusNode();
  _TableKeyboardState? _keyboard;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final keyboard = context
        .dependOnInheritedWidgetOfExactType<_TableKeyboardScope>()
        ?.keyboard;
    if (keyboard == _keyboard) return;
    _keyboard?.unregister(widget.rowKey, _focusNode);
    _keyboard = keyboard;
    _keyboard?._targets[widget.rowKey] = _focusNode;
  }

  @override
  void didUpdateWidget(TableKeyboardTarget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rowKey == widget.rowKey) return;
    _keyboard?.unregister(oldWidget.rowKey, _focusNode);
    _keyboard?._targets[widget.rowKey] = _focusNode;
  }

  @override
  void dispose() {
    _keyboard?.unregister(widget.rowKey, _focusNode);
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (!_focusNode.hasPrimaryFocus ||
        (event is! KeyDownEvent && event is! KeyRepeatEvent)) {
      return KeyEventResult.ignored;
    }
    final direction = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowUp || LogicalKeyboardKey.arrowLeft => -1,
      LogicalKeyboardKey.arrowDown || LogicalKeyboardKey.arrowRight => 1,
      _ => 0,
    };
    if (direction == 0 ||
        !SingleActivator(event.logicalKey)
            .accepts(event, HardwareKeyboard.instance)) {
      return KeyEventResult.ignored;
    }
    return _keyboard?.move(widget.rowKey, direction, context) ??
        KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: false,
    includeSemantics: false,
    onKeyEvent: _onKeyEvent,
    child: widget.builder(_focusNode),
  );
}
