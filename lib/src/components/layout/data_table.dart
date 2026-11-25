import 'dart:math' as math;
import 'dart:ui' show SemanticsRole;

import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

import '../../foundation/modality.dart';
import '../../foundation/typography.dart';
import '../../l10n/localizations.dart';
import '../../primitives/backdrop_group.dart';
import '../../primitives/glass_backdrop.dart';
import '../../primitives/visual_scope.dart';
import '../../primitives/visual_surface.dart';
import '../../theme/semantic_visuals.dart';
import '../../theme/theme.dart';
import '../../theme/theme_extension.dart';
import '../../theme/visual_role.dart';
import '../controls/checkboxes.dart';
import '../controls/selection_control.dart';
import '../overlays/context_menu.dart';
import '../overlays/menu_actions.dart' show YumeiroMenuEntry;
import 'row_visuals.dart';
import 'scroll_view.dart';
import 'table_empty_message.dart';
import 'table_keyboard.dart';
import 'table_selection.dart';
import 'table_sliver_viewport.dart';

part 'data_table_rows.dart';

/// Appearance of a [YumeiroDataTable].
enum YumeiroTableVariant { standard, compact }

/// Action for a tap on the body of a table row.
enum YumeiroTableRowTapBehavior {
  /// Calls the table's row activation callback.
  activate,

  /// Updates the controlled selection.
  select,

  /// Leaves the row body passive. Cell controls still work.
  none,
}

/// Column definition for [YumeiroDataTable].
class YumeiroTableColumn<T> {
  const YumeiroTableColumn({
    this.title = '',
    this.titleWidget,
    required this.cellBuilder,
    this.flex = 1,
    this.fixedWidth,
    this.preferredWidth,
    this.alignment = AlignmentDirectional.centerStart,
    this.headerAlignment,
  });

  /// Visible header label, or the accessible cell label in a headerless table.
  final String title;

  /// Replaces the visible header label while retaining its accessible name.
  final Widget? titleWidget;

  /// Builds a cell using the item's index in the supplied list.
  /// A null cell still occupies its column's width.
  final Widget? Function(BuildContext context, T item, int index) cellBuilder;

  /// Share of the remaining width when neither width is supplied.
  /// Null uses the default weight of one.
  final int? flex;

  /// Exact width in logical pixels. Takes precedence over [preferredWidth].
  final double? fixedWidth;

  /// Width in logical pixels which can shrink to fit the viewport.
  final double? preferredWidth;

  final AlignmentGeometry alignment;
  final AlignmentGeometry? headerAlignment;
}

/// Displays column bands and controlled row selection for the supplied items.
class YumeiroDataTable<T> extends StatefulWidget {
  const YumeiroDataTable({
    super.key,
    required this.columns,
    required this.items,
    this.additionalColumnBands = const [],
    this.trailingColumns = const [],
    this.variant = YumeiroTableVariant.standard,
    this.showHeader,
    this.showSelectionIndicator,
    this.rowTapBehavior,
    this.onRowTap,
    this.rowTapEnabled,
    this.contextMenuBuilder,
    this.emptyPlaceholder,
    this.selection,
    this.rowKey,
    this.minWidth,
    this.rowSemanticsLabel,
    this.compactRowBuilder,
  }) : _sliver = false,
       pinnedHeader = false;

  /// Builds rows as needed inside a vertical sliver viewport.
  const YumeiroDataTable.sliver({
    super.key,
    required this.columns,
    required this.items,
    this.additionalColumnBands = const [],
    this.trailingColumns = const [],
    this.variant = YumeiroTableVariant.standard,
    this.showHeader,
    this.showSelectionIndicator,
    this.rowTapBehavior,
    this.onRowTap,
    this.rowTapEnabled,
    this.contextMenuBuilder,
    this.emptyPlaceholder,
    this.selection,
    this.rowKey,
    this.minWidth,
    this.rowSemanticsLabel,
    this.compactRowBuilder,
    this.pinnedHeader = false,
  }) : _sliver = true;

  final List<YumeiroTableColumn<T>> columns;

  /// Column bands below [columns]. Each band uses the same body width.
  final List<List<YumeiroTableColumn<T>>> additionalColumnBands;

  /// Columns beside the entire body, independently of its tap behavior.
  final List<YumeiroTableColumn<T>> trailingColumns;

  final YumeiroTableVariant variant;

  /// Displays column headers. Defaults to true for the standard variant.
  final bool? showHeader;

  /// Displays a checkbox or radio before the body when selection is supplied.
  /// Defaults to true for the standard variant.
  final bool? showSelectionIndicator;

  /// Keeps the sliver's header visible as its rows scroll past it.
  final bool pinnedHeader;

  /// Supplied items in display order. Bulk selection covers eligible items
  /// from this list, including items outside the viewport of a sliver.
  final List<T> items;

  /// Defaults to row activation for standard tables and to selection for
  /// compact tables with a selection model.
  final YumeiroTableRowTapBehavior? rowTapBehavior;

  /// Activates the body when [rowTapBehavior] resolves to activation.
  final ValueChanged<T>? onRowTap;

  /// Gates [onRowTap] for an item.
  final bool Function(T item)? rowTapEnabled;

  /// Supplies the row's pointer context menu or touch actions.
  final List<YumeiroMenuEntry> Function(BuildContext context, T item)?
  contextMenuBuilder;

  /// Replaces the whole table when [items] is empty.
  final Widget? emptyPlaceholder;

  /// Controlled single or multiple selection.
  final YumeiroTableSelection<T>? selection;

  /// Stable key for each row, unique among [items]. Defaults to a key based
  /// on the item value and its occurrence in the list.
  final Key Function(T item)? rowKey;

  /// Minimum column layout width. Defaults to 720 for standard tables and
  /// zero for compact tables. A narrower viewport scrolls horizontally.
  final double? minWidth;

  /// Accessible name for the row and its selection control.
  final String Function(T item)? rowSemanticsLabel;

  /// In touch mode, replaces the column layout with a custom row summary.
  /// An embedded [YumeiroDataRow] uses the table's padding by default.
  final Widget Function(BuildContext context, T item, int index)?
  compactRowBuilder;

  final bool _sliver;

  @override
  State<YumeiroDataTable<T>> createState() => _YumeiroDataTableState<T>();
}

class _YumeiroDataTableState<T> extends State<YumeiroDataTable<T>> {
  // Keep cells mounted when single selection introduces keyboard navigation.
  final _tableKey = GlobalKey();
  final _boxContentKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final compact = widget.variant == YumeiroTableVariant.compact;
    final metrics = YumeiroModalityScope.metricsOf(context);
    final summary = metrics.isTouch ? widget.compactRowBuilder : null;
    final showHeader = widget.showHeader ?? !compact;
    if (widget.items.isEmpty &&
        (widget.emptyPlaceholder != null || !showHeader || summary != null)) {
      final empty =
          widget.emptyPlaceholder ?? const TableEmptyMessage(compact: true);
      return widget._sliver ? SliverToBoxAdapter(child: empty) : empty;
    }

    final keys = buildTableRowKeys(widget.items, widget.rowKey);
    final selection = TableSelectionState.controlled(
      selection: widget.selection,
      items: widget.items,
      keys: keys,
      includeBulkSelection: showHeader,
    );
    final tapBehavior =
        widget.rowTapBehavior ??
        (compact && widget.selection != null
            ? YumeiroTableRowTapBehavior.select
            : YumeiroTableRowTapBehavior.activate);
    final showIndicator =
        selection.mode != null && (widget.showSelectionIndicator ?? !compact);
    final single = selection.mode == YumeiroTableSelectionMode.single;
    final selectBody = tapBehavior == YumeiroTableRowTapBehavior.select;
    final navigateRows = single && (selectBody || showIndicator);
    final rows = _TableRows<T>(
      table: widget,
      selection: selection,
      metrics: metrics,
      theme: YumeiroTheme.of(context),
      compact: compact,
      summary: summary,
      showHeader: showHeader,
      showIndicator: showIndicator,
      behavior: tapBehavior,
      rowKeys: keys,
      navigateRows: navigateRows,
    );
    final surface = compact || summary != null
        ? null
        : rows.theme.visuals.surface(YumeiroSurfaceRole.card);
    final flatRowSurface = surface?.copyWith(
      shape: const RoundedRectangleBorder(),
    );

    Widget buildTable(
      BuildContext context,
      double viewportWidth,
      _TableLayout<T> layout,
    ) {
      final width = math.max(viewportWidth, layout.minimumWidth);
      final tracks = layout.resolve(width);
      final header = rows.buildHeader(context, tracks);
      if (widget._sliver) {
        final indices = {for (var i = 0; i < keys.length; i++) keys[i]: i};
        return TableSliverViewport(
          viewportWidth: viewportWidth,
          contentWidth: width,
          header: header,
          pinnedHeader: widget.pinnedHeader,
          sliverBuilder: (fitRow) => keys.isEmpty
              ? SliverToBoxAdapter(child: rows.buildEmpty())
              : SliverList.builder(
                  addSemanticIndexes: false,
                  itemCount: keys.length,
                  findChildIndexCallback: (key) => indices[key],
                  itemBuilder: (context, i) => KeyedSubtree(
                    key: keys[i],
                    child: rows.buildRow(
                      context,
                      tracks,
                      i,
                      fitRow: fitRow,
                      surface: flatRowSurface,
                    ),
                  ),
                ),
        );
      }

      final content = SizedBox(
        key: _boxContentKey,
        width: width,
        child: Semantics(
          role: SemanticsRole.table,
          container: true,
          explicitChildNodes: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ?header,
              if (keys.isEmpty)
                rows.buildEmpty()
              else
                for (var i = 0; i < keys.length; i++)
                  KeyedSubtree(
                    key: keys[i],
                    child: rows.buildRow(context, tracks, i),
                  ),
            ],
          ),
        ),
      );
      if (width <= viewportWidth) return content;
      return YumeiroScrollView(
        scrollDirection: Axis.horizontal,
        child: content,
      );
    }

    final Widget viewport;
    if (widget._sliver) {
      (double, Widget)? cached;
      viewport = SliverLayoutBuilder(
        builder: (context, constraints) {
          assert(
            constraints.axis == Axis.vertical,
            'YumeiroDataTable.sliver requires a vertical scroll view.',
          );
          final width = constraints.crossAxisExtent;
          if (cached case (final previousWidth, final child)
              when previousWidth == width) {
            return child;
          }
          final child = buildTable(context, width, rows.columnLayout());
          cached = (width, child);
          return child;
        },
      );
    } else {
      final box = LayoutBuilder(
        builder: (context, constraints) {
          final layout = rows.columnLayout(
            bounded: constraints.hasBoundedWidth,
          );
          final width = constraints.hasBoundedWidth
              ? constraints.maxWidth
              : math.max(constraints.minWidth, layout.naturalWidth);
          return buildTable(context, width, layout);
        },
      );
      viewport = surface == null
          ? box
          : YumeiroResolvedVisualSurface(
              appearance: surface,
              clipBehavior: Clip.antiAlias,
              child: box,
            );
    }

    final body = KeyedSubtree(key: _tableKey, child: viewport);
    if (!navigateRows) return body;
    return TableKeyboard(
      rowKeys: keys,
      toggleFor: selection.toggleFor,
      rovingTabStop: !selectBody,
      selectedKey: widget.selection!.selectedKeys.firstOrNull,
      child: body,
    );
  }
}

class _TableSummary extends InheritedWidget {
  const _TableSummary({required this.selected, required super.child});

  final bool selected;

  @override
  bool updateShouldNotify(_TableSummary oldWidget) =>
      selected != oldWidget.selected;
}

/// Structured summary data row supporting leading thumbnail/icon, status,
/// subtitle, progress bar, auxiliary metadata, inline actions, and tap affordance.
class YumeiroDataRow extends StatelessWidget {
  const YumeiroDataRow({
    super.key,
    required this.title,
    this.leading,
    this.subtitle,
    this.status,
    this.metadata,
    this.progress,
    this.message,
    this.actions,
    this.trailing,
    this.onTap,
    this.selected,
    this.enabled = true,
    this.contentPadding,
    this.showChevron = true,
    this.tapIcon,
  });

  final Widget title;
  final Widget? leading;
  final Widget? subtitle;
  final Widget? status;
  final Widget? metadata;
  final Widget? progress;
  final Widget? message;
  final Widget? actions;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool? selected;
  final bool enabled;

  /// Overrides the row's internal padding. A summary in a [YumeiroDataTable]
  /// uses the table's row padding when this is omitted.
  final EdgeInsetsGeometry? contentPadding;
  final bool showChevron;
  final IconData? tapIcon;

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final metrics = YumeiroModalityScope.metricsOf(context);
    final hasSurface = onTap != null || selected == true || !enabled;
    final paddedTouchRow = metrics.isTouch && hasSurface;
    final summary = context.dependOnInheritedWidgetOfExactType<_TableSummary>();
    final useRowForeground = selected == true || summary?.selected == true;
    Widget supportingStyle(TextStyle style, Widget child) =>
        useRowForeground || !enabled
        ? YumeiroTextStyle(style: style, child: child)
        : DefaultTextStyle.merge(
            style: style.copyWith(color: theme.muted),
            child: child,
          );
    Widget detail(Widget child, {bool auxiliary = false}) => Padding(
      padding: EdgeInsets.only(top: theme.spacing.xs),
      child: supportingStyle(
        auxiliary ? theme.typography.caption : theme.typography.supporting,
        child,
      ),
    );
    final heading = YumeiroTextStyle(
      style: theme.typography.title.copyWith(
        fontWeight: theme.typography.emphasisWeight,
      ),
      child: DefaultTextStyle.merge(
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        child: title,
      ),
    );
    final padding =
        contentPadding ??
        (summary != null
            ? EdgeInsets.zero
            : EdgeInsets.symmetric(
                horizontal: paddedTouchRow
                    ? metrics.horizontalPadding
                    : theme.spacing.xs,
                vertical: paddedTouchRow
                    ? metrics.verticalPadding
                    : theme.spacing.md,
              ));
    final content = Padding(
      padding: padding,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (leading != null) ...[
                  leading!,
                  SizedBox(width: theme.spacing.md),
                ],
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final inline =
                              status != null &&
                              constraints.maxWidth >= 260 &&
                              MediaQuery.textScalerOf(context).scale(16) <= 20;
                          if (!inline) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                heading,
                                if (status != null)
                                  detail(
                                    Align(
                                      alignment:
                                          AlignmentDirectional.centerStart,
                                      child: status,
                                    ),
                                  ),
                              ],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: heading),
                              SizedBox(width: theme.spacing.sm),
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: constraints.maxWidth * .45,
                                ),
                                child: supportingStyle(
                                  theme.typography.supporting,
                                  status!,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      if (subtitle != null) detail(subtitle!),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  SizedBox(width: theme.spacing.sm),
                  trailing!,
                ],
                if (onTap != null &&
                    enabled &&
                    (tapIcon != null || showChevron)) ...[
                  SizedBox(width: theme.spacing.sm),
                  rowNavigationIcon(
                    context,
                    icon: tapIcon,
                    color: useRowForeground ? null : theme.muted,
                  ),
                ],
              ],
            ),
            if (progress != null)
              Padding(
                padding: EdgeInsets.only(top: theme.spacing.sm),
                child: progress!,
              ),
            if (message != null) detail(message!),
            if (metadata != null) detail(metadata!, auxiliary: true),
            if (actions != null)
              Padding(
                padding: EdgeInsets.only(top: theme.spacing.sm),
                child: YumeiroBackdropGroup(child: actions!),
              ),
          ],
        ),
      ),
    );
    return Semantics(
      selected: selected,
      enabled: enabled,
      child: onTap == null
          ? hasSurface
                ? YumeiroVisualSurface(
                    role: YumeiroItemRole.standard,
                    states: {
                      if (selected == true) WidgetState.selected,
                      if (!enabled) WidgetState.disabled,
                    },
                    visualInsets: rowVisualInsets(context),
                    child: content,
                  )
                : content
          : YumeiroInteractiveVisualSurface(
              role: YumeiroItemRole.standard,
              selected: selected == true,
              onTap: enabled ? onTap : null,
              visualInsets: rowVisualInsets(context),
              child: content,
            ),
    );
  }
}
