import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../../foundation/modality.dart';
import '../../foundation/typography.dart';
import '../../l10n/localizations.dart';
import '../../primitives/visual_surface.dart';
import '../../theme/theme.dart';
import '../../theme/visual_role.dart';
import '../layout/scroll_view.dart';
import '../overlays/dialogs.dart';
import '../overlays/picker_overlay.dart';
import '../overlays/sheets.dart';
import '../overlays/tooltip.dart';
import 'buttons.dart';
import 'select_trigger.dart';

/// Sibling IDs must be unique. Only leaves carry values; branches only navigate.
@immutable
class YumeiroCascadingOption<T extends Object> {
  const YumeiroCascadingOption({
    required this.id,
    required this.label,
    required T this.value,
    this.subtitle,
    this.enabled = true,
  }) : children = const [];

  const YumeiroCascadingOption.branch({
    required this.id,
    required this.label,
    required this.children,
    this.subtitle,
    this.enabled = true,
  }) : value = null;

  final Object id;
  final String label;
  final String? subtitle;

  /// Leaf value returned on selection. Branches have no value.
  final T? value;

  /// Whether this node can be selected or entered.
  final bool enabled;
  final List<YumeiroCascadingOption<T>> children;
}

List<YumeiroCascadingOption<T>>? _findPath<T extends Object>(
  List<YumeiroCascadingOption<T>> options,
  T? value,
) {
  if (value == null) return null;
  for (final option in options) {
    if (option.value == value) return [option];
    final path = _findPath(option.children, value);
    if (path != null) return [option, ...path];
  }
  return null;
}

/// Multi-level cascading selector adapting between floating cascading columns
/// on pointer modality and root-first drill-down sheets on touch modality.
class YumeiroCascadingSelect<T extends Object> extends StatefulWidget {
  const YumeiroCascadingSelect({
    super.key,
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
    this.valueLabel,
    this.width,
    this.menuWidth,
    this.maxWidth = 320.0,
    this.expand = false,
    this.icon,
    this.selected = false,
  });

  final String title;

  /// Current leaf selection. Use distinct values to identify paths.
  final T? value;
  final List<YumeiroCascadingOption<T>> options;

  /// Reports an enabled leaf selection. Null disables the selector.
  final ValueChanged<T>? onChanged;
  final String Function(T)? valueLabel;

  /// Explicit trigger width. When neither this nor the parent determines the
  /// width, measure the leaf display labels to keep the trigger width stable.
  final double? width;

  /// Width of the floating cascading panel on pointer modality.
  /// Defaults to `360.0` independently of the trigger width.
  final double? menuWidth;

  /// Maximum auto-computed trigger width when [width] is null and [expand] is false.
  final double maxWidth;
  final bool expand;
  final IconData? icon;
  final bool selected;

  @override
  State<YumeiroCascadingSelect<T>> createState() =>
      _YumeiroCascadingSelectState<T>();
}

class _YumeiroCascadingSelectState<T extends Object>
    extends State<YumeiroCascadingSelect<T>> {
  final _menu = MenuController();
  final _focus = FocusNode();
  final _sheet = YumeiroSheetController();
  bool _sheetOpen = false;
  bool _hovered = false;
  bool _pressed = false;
  int _opening = 0;

  @override
  void dispose() {
    _sheet.close();
    _focus.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(YumeiroCascadingSelect<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sheet.refresh();
    if (widget.onChanged == null) {
      if (_menu.isOpen) _menu.close();
      _sheet.close();
    }
  }

  Widget _panel(ValueChanged<T> choose) => YumeiroCascadingSelection<T>(
    key: ValueKey(_opening),
    value: widget.value,
    options: widget.options,
    onChanged: choose,
  );

  void _commit(T value) {
    final path = _findPath(widget.options, value);
    final enabled = path != null && path.every((option) => option.enabled);
    if (enabled && value != widget.value) widget.onChanged?.call(value);
  }

  Future<void> _open() async {
    if (widget.onChanged == null || _sheetOpen) return;
    if (YumeiroModalityScope.modalityOf(context) != YumeiroModality.touch) {
      if (_menu.isOpen) {
        _menu.close();
      } else {
        setState(() => _opening++);
        _menu.open();
      }
      return;
    }
    setState(() {
      _sheetOpen = true;
      _opening++;
    });
    try {
      final result = await YumeiroBottomSheet.show<T>(
        context: context,
        controller: _sheet,
        builder: (context) => YumeiroBottomSheet(
          title: widget.title,
          scrollable: false,
          child: _panel((value) => Navigator.of(context).pop(value)),
        ),
      );
      if (mounted && result != null && widget.onChanged != null) {
        _commit(result);
      }
    } finally {
      if (mounted) {
        setState(() => _sheetOpen = false);
        _focus.requestFocus();
      }
    }
  }

  Iterable<String> _labels(
    List<YumeiroCascadingOption<T>> options, [
    List<String> ancestors = const [],
  ]) sync* {
    for (final option in options) {
      final path = [...ancestors, option.label];
      if (option.value case final value?) {
        yield widget.valueLabel?.call(value) ?? path.join(' / ');
      } else {
        yield* _labels(option.children, path);
      }
    }
  }

  double _autoWidth(BuildContext context, String label) {
    final style = YumeiroTheme.of(context).typography.control(selected: true);
    var longest = 0.0;
    for (final candidate in [widget.title, label, ..._labels(widget.options)]) {
      final width = yumeiroSelectTextWidth(context, candidate, style);
      if (width > longest) longest = width;
    }
    return yumeiroSelectAutoWidth(
      context,
      triggerTextWidth: longest,
      hasLeadingIcon: widget.icon != null,
      maxWidth: widget.maxWidth,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = YumeiroLocalizations.of(context);
    final value = widget.value;
    final label = value == null
        ? widget.title
        : widget.valueLabel?.call(value) ??
              _findPath(
                widget.options,
                value,
              )?.map((o) => o.label).join(' / ') ??
              widget.title;

    return LayoutBuilder(
      builder: (context, constraints) {
        final parentWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : null;
        final resolvedWidth =
            widget.width ??
            (constraints.hasTightWidth || widget.expand ? parentWidth : null) ??
            math.min(_autoWidth(context, label), constraints.maxWidth);

        return PickerMenuAnchor(
          controller: _menu,
          focusNode: _focus,
          width: widget.menuWidth ?? 360.0,
          onOpen: () => setState(() {}),
          onClose: () => setState(() {}),
          menu: PickerFloatingSurface(
            padding: EdgeInsets.zero,
            child: _panel((value) {
              _menu.close();
              _commit(value);
              _focus.requestFocus();
            }),
          ),
          child: Focus(
            focusNode: _focus,
            canRequestFocus: widget.onChanged != null,
            onFocusChange: (_) {
              if (mounted) setState(() {});
            },
            onKeyEvent: (_, event) {
              if (event is KeyDownEvent &&
                  widget.onChanged != null &&
                  (event.logicalKey == LogicalKeyboardKey.enter ||
                      event.logicalKey == LogicalKeyboardKey.space ||
                      event.logicalKey == LogicalKeyboardKey.arrowDown)) {
                _open();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: YumeiroTooltip(
              message: widget.title,
              child: Semantics(
                button: true,
                enabled: widget.onChanged != null,
                expanded: _menu.isOpen || _sheetOpen,
                selected: widget.selected ? true : null,
                label: '${widget.title}: $label',
                hint: widget.onChanged == null ? null : l10n.selectOptionsHint,
                onTap: widget.onChanged == null ? null : _open,
                child: ExcludeSemantics(
                  child: MouseRegion(
                    cursor: widget.onChanged == null
                        ? SystemMouseCursors.basic
                        : SystemMouseCursors.click,
                    onEnter: (_) => setState(() => _hovered = true),
                    onExit: (_) => setState(() => _hovered = false),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: widget.onChanged == null
                          ? null
                          : (_) => setState(() => _pressed = true),
                      onTapUp: widget.onChanged == null
                          ? null
                          : (_) => setState(() => _pressed = false),
                      onTapCancel: widget.onChanged == null
                          ? null
                          : () => setState(() => _pressed = false),
                      onTap: widget.onChanged == null ? null : _open,
                      child: SizedBox(
                        width: resolvedWidth,
                        child: YumeiroSelectTriggerVisual(
                          label: label,
                          icon: widget.icon,
                          selected: widget.selected,
                          isPlaceholder: value == null,
                          fillsWidth: true,
                          states: {
                            if (widget.onChanged == null) WidgetState.disabled,
                            if (_focus.hasPrimaryFocus) WidgetState.focused,
                            if (_hovered) WidgetState.hovered,
                            if (_pressed) WidgetState.pressed,
                            if (widget.selected) WidgetState.selected,
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Embeddable cascading option browser shared by menus, sheets, and filter drafts.
///
/// Clicking, tapping, or using the keyboard opens a branch. Hovering highlights
/// the row.
/// Selecting a leaf calls [onChanged] without dismissing the host route.
/// The caller owns [value] and decides when a draft is committed.
class YumeiroCascadingSelection<T extends Object> extends StatefulWidget {
  const YumeiroCascadingSelection({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final T? value;
  final List<YumeiroCascadingOption<T>> options;
  final ValueChanged<T> onChanged;

  @override
  State<YumeiroCascadingSelection<T>> createState() =>
      _YumeiroCascadingSelectionState<T>();
}

class _YumeiroCascadingSelectionState<T extends Object>
    extends State<YumeiroCascadingSelection<T>> {
  List<Object> _path = [];
  final _scopes = <FocusScopeNode>[];
  final _activeKeys = <GlobalKey>[];
  bool? _isTouch;
  bool _revealPath = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isTouch = YumeiroModalityScope.metricsOf(context).isTouch;
    if (_isTouch == null && !isTouch) _resetPath();
    _isTouch = isTouch;
  }

  void _resetPath() {
    final path = _findPath(widget.options, widget.value);
    _path = path == null || path.length < 2
        ? []
        : path.take(path.length - 1).map((o) => o.id).toList();
    _revealPath = true;
  }

  @override
  void didUpdateWidget(YumeiroCascadingSelection<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isTouch == false && oldWidget.value != widget.value) _resetPath();
  }

  @override
  void dispose() {
    for (final scope in _scopes) {
      scope.dispose();
    }
    super.dispose();
  }

  void _revealLevel(int level, {bool focus = false}) =>
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || level >= _activeKeys.length) return;
        final target = _activeKeys[level].currentContext;
        if (target == null) return;
        if (focus) _scopes[level].requestFocus();

        final list = Scrollable.of(target, axis: Axis.vertical);
        list.position.ensureVisible(target.findRenderObject()!, alignment: .5);
        if (YumeiroModalityScope.metricsOf(context).isPointer) {
          final columns = Scrollable.of(list.context, axis: Axis.horizontal);
          columns.position.ensureVisible(
            list.context.findRenderObject()!,
            alignment: .5,
          );
        }
      });

  void _choose(YumeiroCascadingOption<T> option, int level) {
    if (!option.enabled) return;
    if (option.value case final value?) {
      widget.onChanged(value);
    } else {
      setState(() => _path = [..._path.take(level), option.id]);
      _revealLevel(level + 1, focus: true);
    }
  }

  Widget _column(List<YumeiroCascadingOption<T>> options, int level) {
    while (_scopes.length <= level) {
      _scopes.add(FocusScopeNode());
      _activeKeys.add(GlobalKey());
    }
    final theme = YumeiroTheme.of(context);
    final isTouch = _isTouch == true;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final forwardKey = rtl
        ? LogicalKeyboardKey.arrowLeft
        : LogicalKeyboardKey.arrowRight;
    final backKey = rtl
        ? LogicalKeyboardKey.arrowRight
        : LogicalKeyboardKey.arrowLeft;
    final currentOption = isTouch
        ? _findPath(options, widget.value)?.first
        : null;
    final focused =
        currentOption ??
        options
            .where(
              (o) =>
                  (o.value != null && o.value == widget.value) ||
                  (level < _path.length && o.id == _path[level]),
            )
            .firstOrNull;
    final initialFocus = focused?.enabled == true
        ? focused
        : options.where((option) => option.enabled).firstOrNull;
    final revealTarget = initialFocus ?? options.firstOrNull;

    return FocusScope(
      node: _scopes[level],
      child: YumeiroScrollView(
        key: ValueKey((level, level == 0 ? null : _path[level - 1])),
        padding: EdgeInsets.all(theme.spacing.xs),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final option in options)
              Builder(
                builder: (rowContext) {
                  final branch = option.children.isNotEmpty;
                  final active =
                      branch &&
                      level < _path.length &&
                      _path[level] == option.id;
                  final selected = branch
                      ? identical(option, currentOption)
                      : option.value == widget.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1.5),
                    child: Focus(
                      canRequestFocus: false,
                      key: identical(option, revealTarget)
                          ? _activeKeys[level]
                          : null,
                      onKeyEvent: (_, event) {
                        if (event is! KeyDownEvent) {
                          return KeyEventResult.ignored;
                        }
                        if (event.logicalKey == forwardKey && branch) {
                          _choose(option, level);
                        } else if (event.logicalKey == backKey && level > 0) {
                          if (isTouch) {
                            setState(
                              () => _path = _path.take(level - 1).toList(),
                            );
                          }
                          _revealLevel(level - 1, focus: true);
                        } else if (event.logicalKey ==
                                LogicalKeyboardKey.arrowUp ||
                            event.logicalKey == LogicalKeyboardKey.arrowDown) {
                          FocusScope.of(rowContext).focusInDirection(
                            event.logicalKey == LogicalKeyboardKey.arrowUp
                                ? TraversalDirection.up
                                : TraversalDirection.down,
                          );
                        } else {
                          return KeyEventResult.ignored;
                        }
                        return KeyEventResult.handled;
                      },
                      child: Semantics(
                        button: true,
                        enabled: option.enabled,
                        selected: branch && !isTouch ? null : selected,
                        expanded: branch ? active : null,
                        child: YumeiroInteractiveVisualSurface(
                          role: YumeiroItemRole.standard,
                          autofocus: identical(option, initialFocus),
                          selected: active || selected,
                          onTap: option.enabled
                              ? () => _choose(option, level)
                              : null,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: isTouch ? 40 : 23,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      YumeiroTextStyle(
                                        style: theme.typography.option(
                                          selected: selected || active,
                                        ),
                                        child: Text(option.label),
                                      ),
                                      if (option.subtitle != null)
                                        YumeiroTextStyle(
                                          style: theme.typography.caption,
                                          child: Text(option.subtitle!),
                                        ),
                                    ],
                                  ),
                                ),
                                if (branch)
                                  Icon(
                                    rtl
                                        ? theme.icons.chevronLeft
                                        : theme.icons.chevronRight,
                                    textDirection: TextDirection.ltr,
                                    size: theme.iconSizes.sm,
                                  ),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final levels = <List<YumeiroCascadingOption<T>>>[widget.options];
    for (final id in _path) {
      final branch = levels.last
          .where((o) => o.id == id && o.children.isNotEmpty && o.enabled)
          .firstOrNull;
      if (branch == null) break;
      levels.add(branch.children);
    }
    final isTouch = _isTouch == true;
    final lastLevel = levels.length - 1;
    if (_revealPath || _path.length != lastLevel) {
      _path = _path.take(lastLevel).toList();
      _revealPath = false;
      _revealLevel(lastLevel);
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 320),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isTouch && lastLevel > 0)
            YumeiroButton(
              label: levels[lastLevel - 1]
                  .firstWhere((o) => o.id == _path.last)
                  .label,
              icon: theme.icons.back,
              variant: YumeiroButtonVariant.ghost,
              onPressed: () {
                setState(() => _path.removeLast());
                _revealLevel(lastLevel - 1, focus: true);
              },
            ),
          Flexible(
            child: isTouch
                ? _column(levels.last, lastLevel)
                : IntrinsicHeight(
                    child: YumeiroScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < levels.length; i++)
                            SizedBox(width: 180, child: _column(levels[i], i)),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
