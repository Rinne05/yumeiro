import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../foundation/modality.dart';
import '../../scope/captured_configuration.dart';
import '../../l10n/localizations.dart';
import '../../primitives/glass_backdrop.dart';
import '../../primitives/visual_surface.dart';
import '../../theme/theme.dart';
import '../../theme/visual_role.dart';
import '../layout/list_tile.dart';
import 'dialogs.dart' show YumeiroSheetController;
import 'menu_actions.dart';
import 'menu_visuals.dart';
import 'sheets.dart';

/// Context menu region supporting secondary click, long press and keyboard
/// activation from a focused descendant.
class YumeiroContextMenuRegion extends StatefulWidget {
  const YumeiroContextMenuRegion({
    super.key,
    required this.child,
    required this.menuBuilder,
    this.enabled = true,
    this.focusable = false,
    this.longPressDelay = const Duration(milliseconds: 500),
    this.useRootNavigator = true,
  });

  final Widget child;

  /// Builds the menu using the trigger's local position within [child].
  final List<YumeiroMenuEntry> Function(
    BuildContext context,
    Offset localPosition,
  )
  menuBuilder;
  final bool enabled;

  /// Allows Tab to reach this region when its child has no keyboard stop.
  /// Descendant controls keep their own stops and open the same menu.
  final bool focusable;
  final Duration longPressDelay;

  /// Whether the menu opens above the root navigator. Use false to keep it
  /// with the enclosing route's overlay.
  final bool useRootNavigator;

  @override
  State<YumeiroContextMenuRegion> createState() =>
      _YumeiroContextMenuRegionState();
}

class _YumeiroContextMenuRegionState extends State<YumeiroContextMenuRegion> {
  static final _claimedPointerDowns = Expando<bool>();

  final _focus = _ContextMenuFocusNode();
  _ContextMenuLongPress? _longPress;
  VoidCallback? _closeMenu;

  _ContextMenuLongPress _createLongPress() => _ContextMenuLongPress(
    duration: widget.longPressDelay,
    menuFor: (position) => widget.menuBuilder(context, position),
    open: _openMenu,
  );

  void _cancelLongPress() {
    _longPress?.dispose();
    _longPress = null;
  }

  @override
  void didUpdateWidget(covariant YumeiroContextMenuRegion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.longPressDelay != widget.longPressDelay ||
        oldWidget.enabled && !widget.enabled) {
      _cancelLongPress();
    }
    if (!widget.enabled) {
      _closeMenu?.call();
    }
  }

  @override
  void dispose() {
    _cancelLongPress();
    _closeMenu?.call();
    _focus.dispose();
    super.dispose();
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (!widget.enabled) return;
    final original = event.original ?? event;
    if (_claimedPointerDowns[original] == true) return;

    if (event.kind == PointerDeviceKind.mouse &&
        (event.buttons & kSecondaryMouseButton) != 0) {
      _claimedPointerDowns[original] = true;
      _cancelLongPress();
      _showMenu(event.localPosition, event.position);
    } else if (event.kind == PointerDeviceKind.touch &&
        event.buttons == kPrimaryButton) {
      _claimedPointerDowns[original] = true;
      (_longPress ??= _createLongPress())
        ..gestureSettings = MediaQuery.maybeGestureSettingsOf(context)
        ..addPointer(event);
    }
  }

  bool _showMenu(Offset localPosition, Offset globalPosition) {
    if (!widget.enabled) return false;
    final items = widget.menuBuilder(context, localPosition);
    if (items.isEmpty) return false;
    _openMenu(globalPosition, items);
    return true;
  }

  void _openMenu(Offset globalPosition, List<YumeiroMenuEntry> items) {
    _closeMenu?.call();
    VoidCallback? openedMenu;
    _showActionMenu(
      context,
      globalPosition: globalPosition,
      items: [
        for (final entry in items)
          if (entry is YumeiroMenuAction && entry.onPressed != null)
            YumeiroMenuAction(
              label: entry.label,
              icon: entry.icon,
              shortcut: entry.shortcut,
              enabled: entry.enabled,
              destructive: entry.destructive,
              selected: entry.selected,
              onPressed: () {
                if (mounted && widget.enabled) entry.onPressed!();
              },
            )
          else
            entry,
      ],
      useRootNavigator: widget.useRootNavigator,
      onOpened: (close) => _closeMenu = openedMenu = close,
    ).whenComplete(() {
      if (identical(_closeMenu, openedMenu)) _closeMenu = null;
    });
  }

  bool _showMenuAtTarget({RenderObject? target}) {
    final region = context.findRenderObject();
    if (region is! RenderBox || !region.attached || !region.hasSize) {
      return false;
    }
    final box = target is RenderBox && target.attached && target.hasSize
        ? target
        : region;
    final globalPosition = box.localToGlobal(box.size.center(Offset.zero));
    _cancelLongPress();
    return _showMenu(region.globalToLocal(globalPosition), globalPosition);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent ||
        (event.logicalKey != LogicalKeyboardKey.contextMenu &&
            !(event.logicalKey == LogicalKeyboardKey.f10 &&
                HardwareKeyboard.instance.isShiftPressed))) {
      return KeyEventResult.ignored;
    }
    final target = FocusManager.instance.primaryFocus?.context
        ?.findRenderObject();
    return _showMenuAtTarget(target: target)
        ? KeyEventResult.handled
        : KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focus,
      canRequestFocus: widget.enabled && widget.focusable,
      skipTraversal: false,
      includeSemantics: false,
      onKeyEvent: widget.enabled ? _handleKeyEvent : null,
      child: Listener(
        behavior: widget.enabled
            ? HitTestBehavior.translucent
            : HitTestBehavior.deferToChild,
        onPointerDown: _handlePointerDown,
        child: ListenableBuilder(
          listenable: _focus,
          child: widget.child,
          builder: (context, child) {
            final focused = widget.enabled && _focus.hasPrimaryFocus;
            final theme = focused ? YumeiroTheme.of(context) : null;
            return Semantics(
              focused: focused ? true : null,
              customSemanticsActions: widget.enabled
                  ? {
                      CustomSemanticsAction(
                        label: YumeiroLocalizations.of(context).moreActions,
                      ): _showMenuAtTarget,
                    }
                  : null,
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: theme == null
                    ? const BoxDecoration()
                    : BoxDecoration(
                        borderRadius: BorderRadius.circular(theme.buttonRadius),
                        border: Border.all(color: theme.accent, width: 2),
                      ),
                child: child,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ContextMenuLongPress extends LongPressGestureRecognizer {
  _ContextMenuLongPress({
    required super.duration,
    required this.menuFor,
    required void Function(Offset, List<YumeiroMenuEntry>) open,
  }) {
    onLongPressStart = (details) => open(details.globalPosition, _items);
  }

  final List<YumeiroMenuEntry> Function(Offset) menuFor;
  List<YumeiroMenuEntry> _items = const [];

  @override
  void didExceedDeadline() {
    _items = menuFor(initialPosition!.local);
    if (_items.isEmpty) {
      resolve(GestureDisposition.rejected);
    } else {
      super.didExceedDeadline();
      _items = const [];
    }
  }
}

class _ContextMenuFocusNode extends FocusNode {
  @override
  bool get skipTraversal =>
      super.skipTraversal || traversalDescendants.isNotEmpty;
}

/// Presents the same menu entries at an anchor or in a touch sheet.
abstract final class YumeiroActionMenu {
  /// On pointer devices, anchors the menu at [globalPosition] or at the
  /// bottom of the trigger identified by [context]. On touch devices, opens
  /// a bottom sheet. [title] supplies the menu heading in either mode.
  static Future<void> show({
    required BuildContext context,
    required List<YumeiroMenuEntry> items,
    String? title,
    Offset? globalPosition,
    double minWidth = 180,
    double maxWidth = 260,
    bool useRootNavigator = true,
  }) => _showActionMenu(
    context,
    items: items,
    title: title,
    globalPosition: globalPosition,
    minWidth: minWidth,
    maxWidth: maxWidth,
    useRootNavigator: useRootNavigator,
  );
}

Offset _triggerMenuPosition(BuildContext context) {
  final trigger = context.findRenderObject();
  if (trigger is RenderBox && trigger.hasSize) {
    final gap = Offset(0, YumeiroTheme.of(context).spacing.xs);
    return trigger.localToGlobal(trigger.size.bottomLeft(gap));
  }
  return MediaQuery.sizeOf(context).center(Offset.zero);
}

Future<void> _showActionMenu(
  BuildContext context, {
  required List<YumeiroMenuEntry> items,
  String? title,
  Offset? globalPosition,
  double minWidth = 180,
  double maxWidth = 260,
  required bool useRootNavigator,
  ValueChanged<VoidCallback>? onOpened,
}) async {
  if (items.isEmpty) return;

  if (YumeiroModalityScope.modalityOf(context) == YumeiroModality.touch) {
    final controller = onOpened == null ? null : YumeiroSheetController();
    final heading = title ?? YumeiroLocalizations.of(context).actions;
    final route = YumeiroBottomSheet.show<void>(
      context: context,
      useRootNavigator: useRootNavigator,
      controller: controller,
      builder: (_) => YumeiroBottomSheet(
        title: heading,
        child: _SheetMenuItems(items: items),
      ),
    );
    if (controller != null) onOpened?.call(controller.close);
    await route;
    return;
  }

  final overlay = Overlay.of(context, rootOverlay: useRootNavigator);
  final themes = YumeiroCapturedConfiguration.capture(context, overlay.context);
  final anchor = globalPosition ?? _triggerMenuPosition(context);
  final entries = title == null
      ? items
      : [YumeiroMenuHeader(title: title), ...items];
  final completion = Completer<void>();
  final previousFocus = FocusManager.instance.primaryFocus;
  late OverlayEntry entry;
  void close() {
    if (completion.isCompleted) return;
    completion.complete();
    entry.remove();
    entry.dispose();
  }

  entry = OverlayEntry(
    builder: (_) => themes.wrap(
      _YumeiroContextMenuAnchor(
        globalPosition: anchor,
        items: entries,
        minWidth: minWidth,
        maxWidth: maxWidth,
        previousFocus: previousFocus,
        useRootOverlay: useRootNavigator,
        onClose: close,
      ),
    ),
  );
  overlay.insert(entry);
  onOpened?.call(close);
  final route = ModalRoute.of(context);
  if (route != null) {
    // Stop retaining the menu once either it closes or its source route exits.
    unawaited(
      Future.any<Object?>([route.popped, completion.future])
          .then((_) => close()),
    );
  }
  await completion.future;
}

Widget _actionIconSlot(IconData? icon, double size) => SizedBox.square(
  dimension: size,
  child: icon == null ? null : ExcludeSemantics(child: Icon(icon, size: size)),
);

class _SheetMenuItems extends StatelessWidget {
  const _SheetMenuItems({required this.items});

  final List<YumeiroMenuEntry> items;

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final actions = items.whereType<YumeiroMenuAction>();
    final hasIcons = actions.any((action) => action.icon != null);
    final hasSelection = actions.any((action) => action.selected != null);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in items)
          switch (entry) {
            YumeiroMenuHeader(:final title) => Semantics(
              header: true,
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  theme.spacing.md,
                  theme.spacing.sm,
                  theme.spacing.md,
                  0,
                ),
                child: Text(
                  title,
                  style: theme.typography.supporting.copyWith(
                    color: theme.muted,
                  ),
                ),
              ),
            ),
            YumeiroMenuDivider() => Divider(color: theme.line),
            YumeiroMenuAction() => _sheetAction(
              context,
              entry,
              hasIcons: hasIcons,
              hasSelection: hasSelection,
            ),
          },
      ],
    );
  }

  Widget _sheetAction(
    BuildContext context,
    YumeiroMenuAction action, {
    required bool hasIcons,
    required bool hasSelection,
  }) {
    final theme = YumeiroTheme.of(context);
    final iconSize = theme.iconSizes.md;
    final onPressed = yumeiroMenuActionCallback(action);
    return YumeiroListTile(
      leading: hasIcons ? _actionIconSlot(action.icon, iconSize) : null,
      trailing: hasSelection
          ? _actionIconSlot(
              action.selected == true ? theme.icons.check : null,
              iconSize,
            )
          : null,
      title: Text(action.label),
      padding: EdgeInsets.all(theme.spacing.md),
      showChevron: false,
      role: action.destructive
          ? YumeiroItemRole.danger
          : YumeiroItemRole.standard,
      enabled: onPressed != null,
      selected: action.selected,
      onTap: onPressed == null
          ? null
          : () {
              Navigator.of(context).pop();
              onPressed();
            },
    );
  }
}

class _YumeiroContextMenuAnchor extends StatefulWidget {
  const _YumeiroContextMenuAnchor({
    required this.globalPosition,
    required this.items,
    required this.minWidth,
    required this.maxWidth,
    required this.previousFocus,
    required this.useRootOverlay,
    required this.onClose,
  });

  final Offset globalPosition;
  final List<YumeiroMenuEntry> items;
  final double minWidth;
  final double maxWidth;
  final FocusNode? previousFocus;
  final bool useRootOverlay;
  final VoidCallback onClose;

  @override
  State<_YumeiroContextMenuAnchor> createState() =>
      _YumeiroContextMenuAnchorState();
}

class _YumeiroContextMenuAnchorState extends State<_YumeiroContextMenuAnchor> {
  final _controller = MenuController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = context.findRenderObject()! as RenderBox;
      _controller.open(position: box.globalToLocal(widget.globalPosition));
    });
  }

  @override
  void dispose() {
    // Overlay teardown can unmount the anchor without MenuAnchor.onClose.
    scheduleMicrotask(widget.onClose);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final appearance = theme.visuals.surface(YumeiroSurfaceRole.floating);
    final actions = widget.items.whereType<YumeiroMenuAction>();
    final firstEnabled = actions
        .where((action) => yumeiroMenuActionCallback(action) != null)
        .firstOrNull;
    final hasIcons = actions.any((action) => action.icon != null);
    final hasSelection = actions.any((action) => action.selected != null);
    return SizedBox.expand(
      child: MenuAnchor(
        controller: _controller,
        childFocusNode: widget.previousFocus,
        consumeOutsideTap: true,
        useRootOverlay: widget.useRootOverlay,
        clipBehavior: Clip.antiAlias,
        style: yumeiroMenuHostStyle(appearance)
            .copyWith(alignment: Alignment.topLeft),
        onClose: widget.onClose,
        menuChildren: [
          IntrinsicWidth(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: 190.0.clamp(widget.minWidth, widget.maxWidth),
                maxWidth: widget.maxWidth,
              ),
              child: YumeiroGlassSamplingScope(
                child: YumeiroResolvedVisualSurface(
                  appearance: appearance,
                  clipBehavior: Clip.antiAlias,
                  padding: const EdgeInsets.symmetric(
                    vertical: 5,
                    horizontal: 4,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final entry in widget.items)
                        if (entry is YumeiroMenuDivider)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 6,
                            ),
                            child: Divider(
                              height: 1,
                              thickness: 1,
                              color: theme.line,
                            ),
                          )
                        else if (entry is YumeiroMenuHeader)
                          Semantics(
                            header: true,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(10, 5, 10, 3),
                              child: Text(
                                entry.title,
                                style: theme.typography.caption.copyWith(
                                  color: theme.subtle,
                                  fontWeight: theme.typography.emphasisWeight,
                                ),
                              ),
                            ),
                          )
                        else if (entry is YumeiroMenuAction)
                          _YumeiroContextMenuAction(
                            action: entry,
                            autofocus: identical(entry, firstEnabled),
                            hasIcons: hasIcons,
                            hasSelection: hasSelection,
                          ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _YumeiroContextMenuAction extends StatelessWidget {
  const _YumeiroContextMenuAction({
    required this.action,
    required this.autofocus,
    required this.hasIcons,
    required this.hasSelection,
  });

  final YumeiroMenuAction action;
  final bool autofocus;
  final bool hasIcons;
  final bool hasSelection;

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final onPressed = yumeiroMenuActionCallback(action);
    final iconSize = theme.iconSizes.sm;
    return YumeiroMenuVisualButton(
      selected: action.selected,
      role: action.destructive
          ? YumeiroItemRole.danger
          : YumeiroItemRole.standard,
      autofocus: autofocus,
      onPressed: onPressed,
      minHeight: 30,
      builder: (context, appearance) => Row(
        spacing: theme.spacing.sm,
        children: [
          if (hasIcons) _actionIconSlot(action.icon, iconSize),
          Expanded(
            child: Text(
              action.label,
              style: theme.typography
                  .control(selected: action.selected == true)
                  .copyWith(color: appearance.foreground),
            ),
          ),
          if (action.shortcut != null)
            Text(
              action.shortcut!,
              style: theme.typography.caption.copyWith(
                color: onPressed != null && action.selected != true
                    ? theme.subtle
                    : appearance.foreground,
              ),
            ),
          if (hasSelection)
            _actionIconSlot(
              action.selected == true ? theme.icons.check : null,
              iconSize,
            ),
        ],
      ),
    );
  }
}
