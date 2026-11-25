part of 'data_table.dart';

const _selectionColumnKey = ValueKey('selection-column');

/// Column calculations are shared by the header and every box or sliver row.
class _TableLayout<T> {
  _TableLayout({
    required List<List<YumeiroTableColumn<T>>> bands,
    required List<YumeiroTableColumn<T>> trailing,
    required this.selectionWidth,
    required this.gap,
    required this.inset,
    required double minFlexWidth,
    required double minWidth,
  }) : _bands = [for (final band in bands) _columnTracks(band, minFlexWidth)],
       _trailing = _columnTracks(trailing, minFlexWidth) {
    final bodyWidth = _bands.fold<double>(
      0,
      (width, band) =>
          math.max(width, _fixedTrackWidth(band) + _gapWidth(band, gap)),
    );
    final bodyMin = _bands.fold<double>(
      bodyWidth,
      (width, band) => math.max(width, _minimumTrackWidth(band, gap)),
    );
    final bodyPreferred = _bands.fold<double>(
      bodyMin,
      (width, band) => math.max(
        width,
        _minimumTrackWidth(band, gap) + _preferredTrackWidth(band),
      ),
    );
    _outer = [
      if (selectionWidth > 0) _TableTrack(fixed: selectionWidth),
      _TableTrack(
        fixed: bodyWidth,
        minFlex: bodyMin - bodyWidth,
        preferred: bodyPreferred - bodyMin,
        flex: _bands.fold<int>(
          1,
          (flex, band) => math.max(flex, _flexWeight(band)),
        ),
      ),
      ..._trailing,
    ];
    minimumWidth = math.max(
      minWidth,
      inset * 2 + _minimumTrackWidth(_outer, gap),
    );
    naturalWidth = math.max(
      minimumWidth,
      inset * 2 +
          _minimumTrackWidth(_outer, gap) +
          _preferredTrackWidth(_outer),
    );
  }

  final double selectionWidth;
  final double gap;
  final double inset;
  final List<List<_TableTrack>> _bands;
  final List<_TableTrack> _trailing;
  late final List<_TableTrack> _outer;
  late final double minimumWidth;
  late final double naturalWidth;

  _TableTracks resolve(double width) {
    final outer = _resolveTracks(math.max(0, width - inset * 2), _outer, gap);
    final bodyIndex = selectionWidth > 0 ? 1 : 0;
    final body = outer.widths[bodyIndex];
    return (
      gap: outer.gap,
      leading: bodyIndex == 0 ? 0 : outer.widths.first,
      body: body,
      bands: [for (final band in _bands) _resolveTracks(body, band, gap)],
      trailing: outer.widths.sublist(bodyIndex + 1),
    );
  }

  static List<_TableTrack> _columnTracks<T>(
    List<YumeiroTableColumn<T>> columns,
    double minFlexWidth,
  ) => [
    for (final column in columns)
      if (column.fixedWidth case final width?)
        _TableTrack(fixed: width)
      else if (column.preferredWidth case final width?)
        _TableTrack(preferred: width)
      else
        _TableTrack(
          minFlex: (column.flex ?? 1) > 0 ? minFlexWidth : 0,
          flex: math.max(0, column.flex ?? 1),
        ),
  ];
}

class _TableTrack {
  const _TableTrack({
    this.fixed = 0,
    this.minFlex = 0,
    this.preferred = 0,
    this.flex = 0,
  });

  final double fixed;
  final double minFlex;
  final double preferred;
  final int flex;
}

typedef _TrackWidths = ({double gap, List<double> widths});
typedef _TableTracks = ({
  double gap,
  double leading,
  double body,
  List<_TrackWidths> bands,
  List<double> trailing,
});

int _flexWeight(List<_TableTrack> tracks) =>
    tracks.fold(0, (sum, track) => sum + track.flex);

double _fixedTrackWidth(List<_TableTrack> tracks) =>
    tracks.fold(0, (sum, track) => sum + track.fixed);

double _preferredTrackWidth(List<_TableTrack> tracks) =>
    tracks.fold(0, (sum, track) => sum + track.preferred);

double _gapWidth(List<_TableTrack> tracks, double gap) =>
    gap * math.max(0, tracks.length - 1);

double _minFlexibleWidth(List<_TableTrack> tracks, int weight) => tracks.fold(
  0,
  (largest, track) => track.flex == 0
      ? largest
      : math.max(largest, track.minFlex * weight / track.flex),
);

double _minimumTrackWidth(List<_TableTrack> tracks, double gap) =>
    _fixedTrackWidth(tracks) +
    _minFlexibleWidth(tracks, _flexWeight(tracks)) +
    _gapWidth(tracks, gap);

_TrackWidths _resolveTracks(
  double width,
  List<_TableTrack> tracks,
  double gap,
) {
  if (tracks.isEmpty) return (gap: 0, widths: const []);
  final fixed = _fixedTrackWidth(tracks);
  final totalFlex = _flexWeight(tracks);
  final minFlex = _minFlexibleWidth(tracks, totalFlex);
  final available = math.max(0.0, width - fixed - minFlex);
  final spacing = math.min(gap, available / tracks.length);
  final space = math.max(0.0, width - fixed - spacing * (tracks.length - 1));
  final preferred = _preferredTrackWidth(tracks);
  final softSpace = math.max(0.0, space - minFlex);
  final scale = preferred > softSpace ? softSpace / preferred : 1.0;
  final flexUnit =
      math.max(0.0, space - preferred * scale) / math.max(1, totalFlex);
  return (
    gap: spacing,
    widths: [
      for (final track in tracks)
        track.fixed + track.flex * flexUnit + track.preferred * scale,
    ],
  );
}

class _TableRows<T> {
  _TableRows({
    required this.table,
    required this.selection,
    required this.metrics,
    required this.theme,
    required this.compact,
    required this.summary,
    required this.showHeader,
    required this.showIndicator,
    required this.behavior,
    required this.rowKeys,
    required this.navigateRows,
  });

  final YumeiroDataTable<T> table;
  final TableSelectionState selection;
  final YumeiroMetrics metrics;
  final YumeiroThemeExtension theme;
  final bool compact;
  final Widget Function(BuildContext, T, int)? summary;
  final bool showHeader;
  final bool showIndicator;
  final YumeiroTableRowTapBehavior behavior;
  final List<Key> rowKeys;
  final bool navigateRows;

  bool get _isSummary => summary != null;
  bool get _dense => !compact && !_isSummary;
  bool get _selectBody =>
      selection.mode != null && behavior == YumeiroTableRowTapBehavior.select;
  double get _inset => _dense ? 16 : metrics.horizontalPadding;
  AlignmentGeometry get _indicatorAlignment =>
      compact ? Alignment.center : AlignmentDirectional.centerStart;
  late final List<List<YumeiroTableColumn<T>>> _bands = [
    table.columns,
    ...table.additionalColumnBands.where((band) => band.isNotEmpty),
  ];
  List<YumeiroTableColumn<T>> get _trailing =>
      _isSummary ? const [] : table.trailingColumns;

  _TableLayout<T> columnLayout({bool bounded = true}) => _TableLayout(
    bands: _isSummary ? const [] : _bands,
    trailing: _trailing,
    selectionWidth: showIndicator ? selectionIndicatorWidth(metrics) : 0,
    gap: _dense ? 0 : metrics.rowGap,
    inset: _inset,
    minFlexWidth: _dense || !bounded ? metrics.minTargetSize : 0,
    minWidth: _isSummary ? 0 : table.minWidth ?? (compact ? 0 : 720),
  );

  Widget buildEmpty() => Semantics(
    role: SemanticsRole.row,
    container: true,
    explicitChildNodes: true,
    child: Semantics(
      role: SemanticsRole.cell,
      container: true,
      child: const TableEmptyMessage(),
    ),
  );

  Widget? buildHeader(BuildContext context, _TableTracks tracks) {
    if (!showHeader) return null;
    final multiple = selection.mode == YumeiroTableSelectionMode.multiple;
    final l10n = YumeiroLocalizations.of(context);
    final toggleAll = selection.toggleAll;
    final selectAll = YumeiroCheckbox(
      dense: !_isSummary,
      label: _isSummary || !showIndicator ? l10n.selectAll : null,
      tristate: true,
      value: selection.allSelected,
      spacing: metrics.rowGap,
      onChanged: toggleAll == null ? null : (_) => toggleAll(),
    );
    if (_isSummary) {
      return multiple
          ? Semantics(
              role: SemanticsRole.row,
              container: true,
              child: Semantics(
                role: SemanticsRole.cell,
                container: true,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: _inset,
                    vertical: metrics.verticalPadding,
                  ),
                  child: selectAll,
                ),
              ),
            )
          : null;
    }
    Widget headerCell(YumeiroTableColumn<T> column, double width) => SizedBox(
      width: width,
      child: Align(
        alignment: column.headerAlignment ?? column.alignment,
        child: Semantics(
          role: SemanticsRole.columnHeader,
          container: true,
          explicitChildNodes: column.titleWidget != null,
          label: column.title,
          child:
              column.titleWidget ??
              ExcludeSemantics(
                child: Text(
                  column.title,
                  style: theme.typography.caption.copyWith(
                    color: theme.subtle,
                    fontWeight: theme.typography.emphasisWeight,
                  ),
                ),
              ),
        ),
      ),
    );
    final bands = _bands;
    return YumeiroResolvedVisualSurface(
      appearance: theme.visuals
          .surface(YumeiroSurfaceRole.inset)
          .copyWith(shape: const RoundedRectangleBorder()),
      padding: EdgeInsets.symmetric(horizontal: _inset, vertical: 10),
      child: Semantics(
        role: SemanticsRole.row,
        container: true,
        explicitChildNodes: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (multiple && !showIndicator)
              Semantics(
                role: SemanticsRole.cell,
                container: true,
                child: selectAll,
              ),
            Row(
              spacing: tracks.gap,
              children: [
                if (showIndicator)
                  SizedBox(
                    key: _selectionColumnKey,
                    width: tracks.leading,
                    child: Semantics(
                      role: SemanticsRole.cell,
                      container: true,
                      label: multiple ? l10n.selectAll : null,
                      child: multiple
                          ? Align(
                              alignment: _indicatorAlignment,
                              child: selectAll,
                            )
                          : null,
                    ),
                  ),
                SizedBox(
                  width: tracks.body,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    spacing: theme.spacing.xs,
                    children: [
                      for (var i = 0; i < bands.length; i++)
                        Row(
                          spacing: tracks.bands[i].gap,
                          children: [
                            for (var j = 0; j < bands[i].length; j++)
                              headerCell(
                                bands[i][j],
                                tracks.bands[i].widths[j],
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
                for (var i = 0; i < _trailing.length; i++)
                  headerCell(_trailing[i], tracks.trailing[i]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildRow(
    BuildContext context,
    _TableTracks tracks,
    int index, {
    Widget Function(Widget)? fitRow,
    YumeiroVisualAppearance? surface,
  }) {
    final item = table.items[index];
    final mode = selection.mode;
    final toggle = showIndicator || _selectBody
        ? selection.toggleFor(index)
        : null;
    final selected = selection.isSelected(index);
    final rowLabel = table.rowSemanticsLabel?.call(item);
    final activate = switch (behavior) {
      YumeiroTableRowTapBehavior.select => toggle,
      YumeiroTableRowTapBehavior.activate
          when table.onRowTap != null &&
              (table.rowTapEnabled?.call(item) ?? true) =>
        () => table.onRowTap!(item),
      _ => null,
    };
    Widget cell(
      YumeiroTableColumn<T> column,
      double width, {
      bool trailing = false,
    }) {
      final content = column.cellBuilder(context, item, index);
      final expose = trailing || !_selectBody;
      return SizedBox(
        width: width,
        child: Semantics(
          role: expose ? SemanticsRole.cell : null,
          container: expose,
          label: !showHeader && content != null && column.title.isNotEmpty
              ? column.title
              : null,
          child: Align(alignment: column.alignment, child: content),
        ),
      );
    }

    final bands = _bands;
    final Widget contents;
    if (summary case final builder?) {
      final content = _TableSummary(
        selected: selected,
        child: builder(context, item, index),
      );
      contents = _selectBody
          ? content
          : Semantics(
              role: SemanticsRole.cell,
              container: true,
              child: content,
            );
    } else {
      contents = Column(
        mainAxisSize: MainAxisSize.min,
        spacing: theme.spacing.xs,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < bands.length; i++)
            Row(
              spacing: tracks.bands[i].gap,
              children: [
                for (var j = 0; j < bands[i].length; j++)
                  cell(bands[i][j], tracks.bands[i].widths[j]),
              ],
            ),
        ],
      );
    }
    final dense = metrics.isPointer;
    final vertical = _dense ? 12.0 : metrics.verticalPadding;
    final trailing = _trailing;
    final bodyWidth =
        tracks.body + (showIndicator ? tracks.leading + tracks.gap : 0);
    final body = Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        _inset,
        vertical,
        trailing.isEmpty ? _inset : 0,
        vertical,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: compact
              ? math.max(
                  0,
                  metrics.minTargetSize - (mode == null ? vertical * 2 : 0),
                )
              : 0,
        ),
        child: SizedBox(
          width: bodyWidth,
          child: Row(
            spacing: tracks.gap,
            children: [
              if (showIndicator)
                SizedBox(
                  key: _selectionColumnKey,
                  width: tracks.leading,
                  child: Align(
                    alignment: _indicatorAlignment,
                    child: _selectBody
                        ? buildSelectionIndicator(
                            multiple:
                                mode == YumeiroTableSelectionMode.multiple,
                            selected: selected,
                            onToggle: toggle,
                            dense: dense,
                          )
                        : _buildControl(
                            mode!,
                            index,
                            selected,
                            toggle,
                            dense: dense && !_isSummary,
                            label:
                                rowLabel ??
                                YumeiroLocalizations.of(context).selectItem,
                          ),
                  ),
                ),
              SizedBox(
                key: const ValueKey('bands'),
                width: tracks.body,
                child: contents,
              ),
            ],
          ),
        ),
      ),
    );

    final menu = table.contextMenuBuilder;
    final row = DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: index == table.items.length - 1
          ? const BoxDecoration()
          : rowDividerDecoration(theme.line),
      child: _TableRowFrame(
        selectable: mode != null,
        bodySelects: _selectBody,
        single: mode == YumeiroTableSelectionMode.single,
        selected: selected,
        onTap: activate,
        keyboardKey: navigateRows && _selectBody && toggle != null
            ? rowKeys[index]
            : null,
        label: rowLabel,
        body: body,
        layout: (body) => Row(
          spacing: tracks.gap,
          children: [
            Expanded(child: body),
            for (var i = 0; i < trailing.length; i++)
              cell(trailing[i], tracks.trailing[i], trailing: true),
            if (trailing.isNotEmpty)
              SizedBox(width: math.max(0, _inset - tracks.gap)),
          ],
        ),
      ),
    );
    Widget content = menu == null
        ? row
        : YumeiroContextMenuRegion(
            focusable: true,
            menuBuilder: (context, _) => menu(context, item),
            child: row,
          );
    if (surface != null) {
      content = YumeiroResolvedVisualSurface(
        appearance: surface,
        child: content,
      );
    }
    if (fitRow != null) {
      content = fitRow(IndexedSemantics(index: index, child: content));
    }
    return Semantics(
      role: SemanticsRole.row,
      container: true,
      label: _selectBody ? null : rowLabel,
      selected: !_selectBody && mode != null ? selected : null,
      child: content,
    );
  }

  Widget _buildControl(
    YumeiroTableSelectionMode mode,
    int index,
    bool selected,
    VoidCallback? toggle, {
    required bool dense,
    required String label,
  }) {
    final indexValue = TableRadioIndex(index);
    final registry = navigateRows
        ? _TableRadioRegistry(selected ? indexValue : null, toggle)
        : null;
    Widget control([FocusNode? focusNode]) => buildSelectionControl(
      multiple: mode == YumeiroTableSelectionMode.multiple,
      radioValue: indexValue,
      selected: selected,
      onToggle: toggle,
      dense: dense,
      focusNode: focusNode,
      groupRegistry: registry,
    );
    final indicator = registry != null && toggle != null
        ? TableKeyboardTarget(rowKey: rowKeys[index], builder: control)
        : control();
    return Semantics(
      role: SemanticsRole.cell,
      container: true,
      label: label,
      child: toggle == null
          ? GestureDetector(
              behavior: HitTestBehavior.opaque,
              excludeFromSemantics: true,
              onTap: () {},
              child: indicator,
            )
          : indicator,
    );
  }
}

// Each radio reads its controlled selection here. The table's keyboard scope
// moves across available rows, including those outside the sliver viewport.
class _TableRadioRegistry implements RadioGroupRegistry<TableRadioIndex> {
  const _TableRadioRegistry(this.groupValue, this.toggle);

  @override
  final TableRadioIndex? groupValue;
  final VoidCallback? toggle;

  @override
  ValueChanged<TableRadioIndex?> get onChanged =>
      (_) => toggle?.call();

  @override
  void registerClient(RadioClient<TableRadioIndex> radio) {}

  @override
  void unregisterClient(RadioClient<TableRadioIndex> radio) {}
}

/// Paint covers the whole row while the tap target covers its body.
class _TableRowFrame extends StatefulWidget {
  const _TableRowFrame({
    required this.selectable,
    required this.bodySelects,
    required this.single,
    required this.selected,
    required this.onTap,
    required this.keyboardKey,
    required this.label,
    required this.body,
    required this.layout,
  });

  final bool selectable;
  final bool bodySelects;
  final bool single;
  final bool selected;
  final VoidCallback? onTap;
  final Key? keyboardKey;
  final String? label;
  final Widget body;
  final Widget Function(Widget) layout;

  @override
  State<_TableRowFrame> createState() => _TableRowFrameState();
}

class _TableRowFrameState extends State<_TableRowFrame> {
  final _bodyKey = GlobalKey();
  final _states = WidgetStatesController();
  bool _refreshScheduled = false;

  @override
  void initState() {
    super.initState();
    _states.addListener(_refresh);
  }

  void _refresh() {
    // InkWell can update its controller during a parent rebuild.
    if (SchedulerBinding.instance.schedulerPhase !=
        SchedulerPhase.persistentCallbacks) {
      if (mounted) setState(() {});
      return;
    }
    if (_refreshScheduled) return;
    _refreshScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshScheduled = false;
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _states.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = YumeiroVisualScope.maybeOf(context);
    final appearance = YumeiroTheme.of(context).visuals.resolveRole(
      scope?.itemRole ??
          (widget.selectable
              ? YumeiroItemRole.selection
              : YumeiroItemRole.standard),
      {
        ..._states.value.where((state) => state != WidgetState.disabled),
        if (widget.selected) WidgetState.selected,
        if (widget.bodySelects && widget.onTap == null) WidgetState.disabled,
      },
      scope?.visualOverride,
    );
    final painted = widget.selectable || widget.onTap != null;
    final insets = rowVisualInsets(context);
    final content = KeyedSubtree(key: _bodyKey, child: widget.body);
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : appearance.transition.duration;
    Widget inkWell([FocusNode? focusNode]) => InkWell(
      statesController: _states,
      focusNode: focusNode,
      canRequestFocus: widget.onTap != null,
      onTap: widget.onTap,
      customBorder: appearance.shape,
      splashFactory: NoSplash.splashFactory,
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      child: content,
    );
    final body = !painted
        ? content
        : AnimatedOpacity(
            opacity: appearance.opacity,
            duration: duration,
            curve: appearance.transition.curve,
            child: switch (widget.keyboardKey) {
              final key? => TableKeyboardTarget(rowKey: key, builder: inkWell),
              null => inkWell(),
            },
          );
    final row = widget.layout(
      widget.bodySelects
          ? Semantics(
              role: SemanticsRole.cell,
              container: true,
              label: widget.label,
              checked: widget.selected,
              enabled: widget.onTap != null,
              inMutuallyExclusiveGroup: widget.single ? true : null,
              child: body,
            )
          : body,
    );
    return Stack(
      fit: StackFit.passthrough,
      clipBehavior: Clip.none,
      children: [
        if (painted)
          Positioned.fill(
            left: insets.left,
            top: insets.top,
            right: insets.right,
            bottom: insets.bottom,
            child: IgnorePointer(
              child: YumeiroResolvedVisualSurface(
                appearance: appearance,
                clipBehavior: Clip.antiAlias,
                child: const SizedBox.expand(),
              ),
            ),
          ),
        YumeiroGlassSamplingScope(
          backdropKey: painted
              ? null
              : YumeiroGlassSamplingScope.maybeOf(context)?.backdropKey,
          child: YumeiroBackdropGroup(
            child: Material(
              type: MaterialType.transparency,
              child: painted
                  ? IconTheme.merge(
                      data: IconThemeData(color: appearance.foreground),
                      child: DefaultTextStyle.merge(
                        style: TextStyle(color: appearance.foreground),
                        child: row,
                      ),
                    )
                  : row,
            ),
          ),
        ),
      ],
    );
  }
}
