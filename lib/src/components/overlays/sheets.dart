import 'dart:ui' show SemanticsValidationResult;

import 'package:flutter/foundation.dart' show internal;
import 'package:flutter/rendering.dart' show RenderAbstractViewport;
import 'package:flutter/services.dart'
    show KeyDownEvent, KeyEvent, KeyRepeatEvent, LogicalKeyboardKey;
import 'package:material_ui/material_ui.dart';

import '../../foundation/input.dart';
import '../../foundation/modality.dart';
import '../../l10n/localizations.dart';
import '../../primitives/backdrop_group.dart';
import '../../primitives/visual_scope.dart';
import '../../primitives/visual_surface.dart';
import '../../theme/theme.dart';
import '../../theme/visual_role.dart';
import '../controls/buttons.dart';
import '../controls/form_picker_trigger.dart';
import '../controls/inputs.dart';
import '../controls/multi_selection_draft.dart';
import '../controls/selection_appearance.dart';
import '../controls/selection_control.dart';
import '../controls/selection_menu_row.dart';
import '../controls/selection_option.dart';
import '../controls/selection_set_form_field.dart';
import '../layout/action_bar.dart';
import '../layout/panels.dart';
import '../layout/row_visuals.dart';
import '../layout/scroll_view.dart';
import '../layout/selection_row.dart';
import '../layout/page_header.dart';
import 'dialogs.dart' show YumeiroSheetController, presentYumeiroSheet;
import 'selection_overlay.dart';
import 'selection_sheet_layout.dart';

export '../controls/selection_option.dart';

part 'selection_list.dart';
part 'selection_list_row.dart';

class SearchableSelectionSheet extends StatelessWidget {
  const SearchableSelectionSheet({
    super.key,
    required this.title,
    required this.hintText,
    required this.onQueryChanged,
    required this.onSubmitted,
    required this.results,
  });

  final String title;
  final String hintText;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onSubmitted;
  final Widget results;

  @override
  Widget build(BuildContext context) => YumeiroBottomSheet(
    title: title,
    minAnchoredHeight: yumeiroSelectionSheetMinHeight(
      context,
      title: title,
      searchable: true,
    ),
    maxWidth: YumeiroSelectionSheetLayout.searchMaxWidth,
    scrollable: false,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Builder(
          builder: (context) => Padding(
            padding: YumeiroSelectionSheetLayout.searchPaddingOf(context),
            child: YumeiroTextField(
              clearable: true,
              hintText: hintText,
              textInputAction: TextInputAction.search,
              onChanged: onQueryChanged,
              onSubmitted: onSubmitted,
            ),
          ),
        ),
        Flexible(child: results),
      ],
    ),
  );
}

/// Modal sheet surface that docks in compact portrait touch layouts.
/// In other layouts it appears near [anchor] or centers in the viewport.
class YumeiroBottomSheet extends StatelessWidget {
  const YumeiroBottomSheet({
    super.key,
    required this.title,
    this.headerAccessory,
    this._actions = const <Widget>[],
    this.showClose = true,
    this.onClose,
    this.canDismiss = true,
    this.scrollable = true,
    this.contentPadding,
    this.anchor,
    this.maxWidth = 520,
    this.maxHeight = double.infinity,
    this.minAnchoredHeight = 0,
    required this.child,
  }) : _swipeToDismiss = false,
       _headerActions = const [],
       _pickerLayout = false;

  const YumeiroBottomSheet._selection({
    required this.title,
    required this.anchor,
    required this.minAnchoredHeight,
    required this.child,
    required this._actions,
    required this._swipeToDismiss,
  }) : canDismiss = true,
       headerAccessory = null,
       showClose = true,
       onClose = null,
       scrollable = false,
       contentPadding = null,
       maxWidth = 320,
       maxHeight = double.infinity,
       _headerActions = const [],
       _pickerLayout = false;

  const YumeiroBottomSheet._picker({
    required this.title,
    required this.anchor,
    required this.maxWidth,
    required this.minAnchoredHeight,
    required this._headerActions,
    required this._actions,
    required this.child,
  }) : _swipeToDismiss = false,
       _pickerLayout = true,
       headerAccessory = null,
       showClose = true,
       onClose = null,
       canDismiss = true,
       scrollable = true,
       contentPadding = null,
       maxHeight = double.infinity;

  /// Presents custom content in a modal sheet route.
  ///
  /// Pop from the builder's context to return a value. Dismissal without a
  /// result returns null. Set [useRootNavigator] to false for the nearest
  /// navigator.
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
    bool useRootNavigator = true,
    YumeiroSheetController? controller,
  }) => presentYumeiroSheet<T>(
    context: context,
    builder: builder,
    barrierDismissible: barrierDismissible,
    useRootNavigator: useRootNavigator,
    controller: controller,
  );

  /// Shows a single-choice sheet and returns the selected option.
  ///
  /// Dismissal without selecting returns null. [anchor] takes a global
  /// rectangle. Set [useRootNavigator] to false for the nearest navigator.
  static Future<YumeiroSelectionOption<T>?> select<T>({
    required BuildContext context,
    required String title,
    required List<YumeiroSelectionOption<T>> options,
    T? value,
    bool searchable = false,
    Rect? anchor,
    YumeiroSheetController? controller,
    bool useRootNavigator = true,
  }) => presentSingleSelectionSheet<T>(
    context: context,
    controller: controller,
    useRootNavigator: useRootNavigator,
    anchor: () => anchor,
    selection: () =>
        (title: title, options: options, value: value, searchable: searchable),
  );

  /// Shows a multi-choice sheet with a local copy of [values].
  ///
  /// Confirmation returns the selected set, which can be empty. Dismissal
  /// returns null. [anchor] takes a global rectangle. Set [useRootNavigator]
  /// to false for the nearest navigator.
  static Future<Set<T>?> multiSelect<T>({
    required BuildContext context,
    required String title,
    required List<YumeiroSelectionOption<T>> options,
    required Set<T> values,
    bool searchable = false,
    Rect? anchor,
    YumeiroSheetController? controller,
    bool useRootNavigator = true,
  }) async {
    final initial = Set<T>.of(values);
    final draft = await presentMultiSelectionSheet<T>(
      context: context,
      controller: controller,
      useRootNavigator: useRootNavigator,
      anchor: anchor,
      selection: () => (
        title: title,
        options: options,
        values: initial,
        searchable: searchable,
      ),
    );
    return draft?.resolve(initial, options);
  }

  final String title;
  final Widget? headerAccessory;
  final Rect? anchor;
  final double maxWidth;
  final double maxHeight;

  /// Minimum space to keep the sheet anchored. In a shorter viewport the
  /// sheet can center itself and move actions to give the body more space.
  final double minAnchoredHeight;

  final List<Widget> _actions;
  final List<Widget> _headerActions;
  final bool _pickerLayout;
  final bool _swipeToDismiss;
  final bool showClose;

  /// Handles the close button when provided. Route back remains independent.
  final VoidCallback? onClose;
  final bool canDismiss;
  final bool scrollable;

  /// Overrides the theme's body padding. With a custom scroll view, the
  /// default leaves its padding to the caller.
  final EdgeInsetsGeometry? contentPadding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final l10n = YumeiroLocalizations.of(context);
    final accessory = headerAccessory;
    const inset = yumeiroActionBarInset;
    final content = scrollable
        ? YumeiroScrollView(
            padding: contentPadding ?? const EdgeInsets.all(inset),
            child: child,
          )
        : contentPadding == null
        ? child
        : Padding(padding: contentPadding!, child: child);
    final surface = YumeiroVisualSurface(
      role: YumeiroSurfaceRole.modal,
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final sideActions =
                minAnchoredHeight > 0 &&
                constraints.maxHeight <
                    yumeiroSelectionSheetMinHeight(
                      context,
                      title: title,
                      searchable: true,
                    );
            final actionInHeader =
                !sideActions &&
                title.isNotEmpty &&
                _actions.length == 1 &&
                constraints.maxHeight < minAnchoredHeight;
            final close = showClose && title.isNotEmpty
                ? YumeiroButton(
                    variant: YumeiroButtonVariant.ghost,
                    icon: theme.icons.close,
                    tooltip: l10n.close,
                    onPressed: canDismiss
                        ? (onClose ?? () => Navigator.of(context).maybePop())
                        : null,
                  )
                : null;
            final namePanel = sideActions && title.isNotEmpty;
            return Semantics(
              container: namePanel,
              namesRoute: namePanel,
              label: namePanel ? title : null,
              child: Flex(
                direction: sideActions ? Axis.horizontal : Axis.vertical,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!sideActions && title.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: inset),
                      child: YumeiroPageHeader.compact(
                        title: title,
                        namesRoute: true,
                        actions: [
                          ..._headerActions,
                          if (actionInHeader) _actions.single,
                          ?close,
                        ],
                      ),
                    ),
                  if (!sideActions && accessory != null)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: inset,
                        vertical: theme.spacing.sm,
                      ),
                      child: accessory,
                    ),
                  // Keep the query editor mounted while the keyboard
                  // changes the position of the sheet actions.
                  Flexible(
                    key: const ValueKey('sheet-body'),
                    child: YumeiroSelectionSheetLayout(
                      compact: sideActions,
                      child: content,
                    ),
                  ),
                  if (sideActions &&
                      (close != null ||
                          accessory != null ||
                          _headerActions.isNotEmpty ||
                          _actions.isNotEmpty))
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth * .45,
                      ),
                      child: YumeiroScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            ?close,
                            ..._headerActions,
                            ?accessory,
                            ..._actions,
                          ],
                        ),
                      ),
                    ),
                  if (!sideActions && !actionInHeader && _actions.isNotEmpty)
                    if (_pickerLayout)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: inset,
                          vertical: 8,
                        ),
                        child: YumeiroBackdropGroup(
                          child: Row(
                            spacing: theme.spacing.sm,
                            children: [
                              for (final action in _actions)
                                Expanded(child: action),
                            ],
                          ),
                        ),
                      )
                    else
                      YumeiroActionBar(
                        showBackground: false,
                        primaryAction: _actions.last,
                        secondaryActions: _actions
                            .take(_actions.length - 1)
                            .toList(),
                      ),
                ],
              ),
            );
          },
        ),
      ),
    );
    final body = ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: surface,
    );
    final size = MediaQuery.sizeOf(context);
    return PopScope(
      canPop: canDismiss,
      child: YumeiroSelectionOverlay(
        anchor: anchor,
        maxWidth: maxWidth,
        minAnchoredHeight: minAnchoredHeight,
        child: _swipeToDismiss && yumeiroDocksSelectionSheet(context, size)
            ? Dismissible(
                key: const ValueKey('yumeiro-sheet-dismiss'),
                direction: DismissDirection.down,
                resizeDuration: null,
                confirmDismiss: (_) async {
                  await Navigator.of(context).maybePop();
                  return false;
                },
                child: body,
              )
            : body,
      ),
    );
  }
}

/// Builds a date or time picker with mode switches above its scrollable body.
@internal
YumeiroBottomSheet buildYumeiroPickerSheet({
  required String title,
  required double maxWidth,
  required Rect? anchor,
  required double minAnchoredHeight,
  required List<Widget> headerActions,
  required List<Widget> actions,
  required Widget child,
}) => YumeiroBottomSheet._picker(
  title: title,
  maxWidth: maxWidth,
  anchor: anchor,
  minAnchoredHeight: minAnchoredHeight,
  headerActions: headerActions,
  actions: actions,
  child: child,
);

Rect? _selectionAnchor(BuildContext context, Rect? anchor) {
  if (anchor == null) return null;
  final viewport =
      Navigator.of(context).context.findRenderObject()! as RenderBox;
  return Rect.fromPoints(
    viewport.globalToLocal(anchor.topLeft),
    viewport.globalToLocal(anchor.bottomRight),
  );
}

/// Presents a single-choice sheet that can rebuild from its owner's inputs.
Future<YumeiroSelectionOption<T>?> presentSingleSelectionSheet<T>({
  required BuildContext context,
  required ({
    String title,
    List<YumeiroSelectionOption<T>> options,
    T? value,
    bool searchable,
  })
  Function()
  selection,
  Rect? Function()? anchor,
  YumeiroSheetController? controller,
  bool useRootNavigator = true,
}) => YumeiroBottomSheet.show<YumeiroSelectionOption<T>>(
  context: context,
  controller: controller,
  useRootNavigator: useRootNavigator,
  builder: (context) {
    final current = selection();
    return YumeiroBottomSheet._selection(
      title: current.title,
      anchor: _selectionAnchor(context, anchor?.call()),
      minAnchoredHeight: yumeiroSelectionSheetMinHeight(
        context,
        title: current.title,
        searchable: current.searchable,
      ),
      swipeToDismiss: true,
      actions: const [],
      child: YumeiroSelectionList<T>._picker(
        options: current.options,
        values: {
          for (final option in current.options)
            if (option.value == current.value) option.value,
        },
        searchable: current.searchable,
        onSelected: (item) => Navigator.of(context).pop(item),
      ),
    );
  },
);

/// Presents a confirmation sheet that keeps eligible edits as options change.
Future<MultiSelectionDraft<T>?> presentMultiSelectionSheet<T>({
  required BuildContext context,
  required ({
    String title,
    List<YumeiroSelectionOption<T>> options,
    Set<T> values,
    bool searchable,
  })
  Function()
  selection,
  Rect? anchor,
  YumeiroSheetController? controller,
  bool useRootNavigator = true,
}) => YumeiroBottomSheet.show<MultiSelectionDraft<T>>(
  context: context,
  controller: controller,
  useRootNavigator: useRootNavigator,
  builder: (_) {
    final current = selection();
    return _MultiSelectionSheet<T>(
      title: current.title,
      anchor: anchor,
      options: current.options,
      values: current.values,
      searchable: current.searchable,
    );
  },
);

class _MultiSelectionSheet<T> extends StatefulWidget {
  const _MultiSelectionSheet({
    required this.title,
    required this.anchor,
    required this.options,
    required this.values,
    required this.searchable,
  });

  final String title;
  final Rect? anchor;
  final List<YumeiroSelectionOption<T>> options;
  final Set<T> values;
  final bool searchable;

  @override
  State<_MultiSelectionSheet<T>> createState() =>
      _MultiSelectionSheetState<T>();
}

class _MultiSelectionSheetState<T> extends State<_MultiSelectionSheet<T>> {
  final _draft = MultiSelectionDraft<T>();

  @override
  Widget build(BuildContext context) {
    final l10n = YumeiroLocalizations.of(context);
    final values = _draft.resolve(widget.values, widget.options);
    return YumeiroBottomSheet._selection(
      title: widget.title,
      anchor: _selectionAnchor(context, widget.anchor),
      minAnchoredHeight: yumeiroSelectionSheetMinHeight(
        context,
        title: widget.title,
        searchable: widget.searchable,
        hasConfirmation: true,
      ),
      swipeToDismiss: false,
      actions: [
        YumeiroButton(
          label: l10n.confirmWithCount(values.length),
          variant: YumeiroButtonVariant.primary,
          onPressed: () => Navigator.of(context).pop(_draft),
        ),
      ],
      child: YumeiroSelectionList<T>._picker(
        options: widget.options,
        values: values,
        searchable: widget.searchable,
        multiple: true,
        onSelected: (item) => setState(() {
          _draft.toggle(item.value, widget.values);
        }),
      ),
    );
  }
}
