part of 'sheets.dart';

/// Renders fixed options in a pointer menu with the shared selection list.
Widget buildMenuSelectionList<T>({
  required List<YumeiroSelectionOption<T>> options,
  required Set<T> values,
  required ValueChanged<YumeiroSelectionOption<T>> onSelected,
  bool dense = false,
  TextAlign textAlign = TextAlign.start,
}) => YumeiroSelectionList<T>._picker(
  options: options,
  values: values,
  onSelected: onSelected,
  pointerMenu: (dense: dense, textAlign: textAlign),
);

/// Renders the results of a search owned by an external input.
Widget buildSearchSelectionResults<T>({
  required Key key,
  required List<YumeiroSelectionOption<T>> options,
  required Set<T> values,
  required ValueChanged<YumeiroSelectionOption<T>> onSelected,
  required bool revealSelection,
  String Function(YumeiroSelectionOption<T>)? optionLabel,
  String? emptyText,
}) => YumeiroSelectionList<T>._picker(
  key: key,
  options: options,
  values: values,
  onSelected: onSelected,
  revealSelection: revealSelection,
  optionLabel: optionLabel,
  emptyText: emptyText,
);

/// Option rows for the multi-select's separate search field.
Widget buildMultiSelectOptions<T extends Object>({
  required List<YumeiroSelectionOption<T>> options,
  required Set<T> values,
  required ValueChanged<YumeiroSelectionOption<T>> onSelected,
  required String query,
  bool dense = false,
  T? highlightedValue,
  ScrollController? controller,
  double? itemExtent,
}) => YumeiroSelectionList<T>._picker(
  options: options,
  values: values,
  onSelected: onSelected,
  multiple: true,
  pointerMenu: (dense: dense, textAlign: TextAlign.start),
  revealSelection: false,
  externalQuery: query.trim().toLowerCase(),
  highlightedValue: highlightedValue,
  controller: controller,
  itemExtent: itemExtent,
);

/// Renders sheet options with the sheet's own row treatment.
Widget buildSheetSelectionList<T>({
  required List<YumeiroSelectionOption<T>> options,
  required Set<T> values,
  required ValueChanged<YumeiroSelectionOption<T>> onSelected,
}) => YumeiroSelectionList<T>._picker(
  options: options,
  values: values,
  onSelected: onSelected,
);

/// Applies the selection list's label and subtitle matching in option order.
Iterable<YumeiroSelectionOption<T>> filterSelectionOptions<T>(
  Iterable<YumeiroSelectionOption<T>> options,
  String query,
) {
  final normalizedQuery = query.trim().toLowerCase();
  return normalizedQuery.isEmpty
      ? options
      : options.where(
          (option) => _matchesSelectionQuery(option, normalizedQuery),
        );
}

bool _matchesSelectionQuery<T>(
  YumeiroSelectionOption<T> option,
  String normalizedQuery,
) =>
    normalizedQuery.isEmpty ||
    '${option.label} ${option.subtitle ?? ''}'.toLowerCase().contains(
      normalizedQuery,
    );

/// Controlled inline single or multiple selection with optional local search.
class YumeiroSelectionList<T> extends StatefulWidget {
  const YumeiroSelectionList({
    super.key,
    required this.options,
    required this.values,
    this.onChanged,
    this.onSelected,
    this.searchable = false,
    this.multiple = false,
    this.scrollable = true,
    this.enabled = true,
    this.readOnly = false,
    this.label,
    this.helperText,
    this.semanticLabel,
    this.width,
    this.expand = true,
    this.dense = false,
    this.clearable = false,
    this.focusNode,
    this.autofocus = false,
    this.hasError = false,
  }) : _inline = true,
       _pointerMenu = null,
       _optionLabel = null,
       _emptyText = null,
       _revealSelection = true,
       _externalQuery = null,
       _highlightedValue = null,
       _controller = null,
       _itemExtent = null,
       _formState = null;

  const YumeiroSelectionList._form({
    required this.options,
    required this.values,
    required this.onChanged,
    required this.multiple,
    required this.searchable,
    required this.scrollable,
    required this.enabled,
    required this.readOnly,
    required this.label,
    required this.helperText,
    required this.semanticLabel,
    required this.width,
    required this.expand,
    required this.dense,
    required this.clearable,
    required this.focusNode,
    required this.autofocus,
    required this.hasError,
    required this._formState,
  }) : _inline = true,
       onSelected = null,
       _pointerMenu = null,
       _optionLabel = null,
       _emptyText = null,
       _revealSelection = true,
       _externalQuery = null,
       _highlightedValue = null,
       _controller = null,
       _itemExtent = null;

  const YumeiroSelectionList._picker({
    super.key,
    required this.options,
    required this.values,
    required this.onSelected,
    this.searchable = false,
    this.multiple = false,
    this.scrollable = true,
    this._pointerMenu,
    this._optionLabel,
    this._emptyText,
    this._revealSelection = true,
    this._externalQuery,
    this._highlightedValue,
    this._controller,
    this._itemExtent,
  }) : _inline = false,
       onChanged = null,
       enabled = true,
       readOnly = false,
       label = null,
       helperText = null,
       semanticLabel = null,
       width = null,
       expand = true,
       dense = false,
       clearable = false,
       focusNode = null,
       autofocus = false,
       hasError = false,
       _formState = null;

  /// Creates a single-choice field. A null [initialValue] means no choice.
  static FormField<V> form<V extends Object>({
    Key? key,
    required List<YumeiroSelectionOption<V>> options,
    V? initialValue,
    FormFieldSetter<V>? onSaved,
    VoidCallback? onReset,
    FormFieldValidator<V>? validator,
    AutovalidateMode? autovalidateMode,
    String? forceErrorText,
    ValueChanged<V>? onChanged,
    String? label,
    String? helperText,
    String? semanticLabel,
    bool required = false,
    bool enabled = true,
    bool readOnly = false,
    bool dense = false,
    FocusNode? focusNode,
    bool autofocus = false,
    bool searchable = false,
    bool scrollable = false,
  }) => _SingleSelectionFormField<V>(
    key: key,
    initialValue: initialValue,
    onSaved: onSaved,
    onReset: onReset,
    validator: validator,
    autovalidateMode: autovalidateMode,
    forceErrorText: forceErrorText,
    enabled: enabled,
    builder: (field) => YumeiroSelectionList<V>._form(
      options: options,
      values: {?field.value},
      onChanged: (values) {
        final value = values.single;
        field.didChange(value);
        onChanged?.call(value);
      },
      multiple: false,
      searchable: searchable,
      scrollable: scrollable,
      enabled: enabled,
      readOnly: readOnly,
      label: label,
      helperText: helperText,
      semanticLabel: semanticLabel,
      width: null,
      expand: true,
      dense: dense,
      clearable: false,
      focusNode: focusNode,
      autofocus: autofocus,
      hasError: field.hasError,
      formState: (
        required: required,
        error: field.errorText,
        readValues: () => {?field.value},
      ),
    ),
  );

  /// Creates an immediate multiple-choice field. Disabled options can remain
  /// selected. Set [retainMissingValues] to false to prune unavailable values
  /// when [options] change and when the field resets.
  static FormField<Set<V>> multiForm<V extends Object>({
    Key? key,
    required List<YumeiroSelectionOption<V>> options,
    Set<V>? initialValue,
    FormFieldSetter<Set<V>>? onSaved,
    VoidCallback? onReset,
    FormFieldValidator<Set<V>>? validator,
    AutovalidateMode? autovalidateMode,
    String? forceErrorText,
    ValueChanged<Set<V>>? onChanged,
    String? label,
    String? helperText,
    String? semanticLabel,
    bool required = false,
    bool enabled = true,
    bool readOnly = false,
    double? width,
    bool expand = true,
    bool dense = false,
    bool clearable = false,
    bool retainMissingValues = true,
    FocusNode? focusNode,
    bool autofocus = false,
    bool searchable = false,
    bool scrollable = false,
  }) => SelectionSetFormField<V>(
    key: key,
    options: options,
    initialValue: initialValue,
    onSaved: onSaved,
    onReset: onReset,
    validator: validator,
    autovalidateMode: autovalidateMode,
    forceErrorText: forceErrorText,
    enabled: enabled,
    retainMissingValues: retainMissingValues,
    builder: (field) => YumeiroSelectionList<V>._form(
      options: options,
      values: field.value!,
      onChanged: (values) {
        field.didChange(values);
        onChanged?.call(field.value!);
      },
      multiple: true,
      searchable: searchable,
      scrollable: scrollable,
      enabled: enabled,
      readOnly: readOnly,
      label: label,
      helperText: helperText,
      semanticLabel: semanticLabel,
      width: width,
      expand: expand,
      dense: dense,
      clearable: clearable,
      focusNode: focusNode,
      autofocus: autofocus,
      hasError: field.hasError,
      formState: (
        required: required,
        error: field.errorText,
        readValues: () => field.value!,
      ),
    ),
  );

  final List<YumeiroSelectionOption<T>> options;

  /// Selected values. In single mode, provide at most one value. An empty set
  /// represents no selection, including when null is an available option.
  final Set<T> values;

  /// Reports the updated selection after a change as an immutable set.
  final ValueChanged<Set<T>>? onChanged;

  /// Reports activation of an option, including an already selected item.
  /// A host can use this to close a custom panel after choosing an option.
  final ValueChanged<YumeiroSelectionOption<T>>? onSelected;
  final bool searchable;
  final bool multiple;

  /// Builds rows on demand when the list has a finite scrollable viewport.
  /// Set to false when the list is part of an already scrollable form.
  final bool scrollable;
  final bool enabled;
  final bool readOnly;
  final String? label;
  final String? helperText;
  final String? semanticLabel;
  final double? width;
  final bool expand;
  final bool dense;

  /// Shows a separate clear-selection action when [onChanged] is provided.
  final bool clearable;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool hasError;
  final bool _inline;
  final ({bool required, String? error, ValueGetter<Set<T>> readValues})?
  _formState;
  final ({bool dense, TextAlign textAlign})? _pointerMenu;
  final String Function(YumeiroSelectionOption<T>)? _optionLabel;
  final String? _emptyText;
  final bool _revealSelection;
  final String? _externalQuery;
  final T? _highlightedValue;
  final ScrollController? _controller;
  final double? _itemExtent;

  @override
  State<YumeiroSelectionList<T>> createState() =>
      _YumeiroSelectionListState<T>();
}

// Gives this field its own state when replacing a plain FormField in a slot.
class _SingleSelectionFormField<T> extends FormField<T> {
  const _SingleSelectionFormField({
    super.key,
    required super.builder,
    super.initialValue,
    super.onSaved,
    super.onReset,
    super.validator,
    super.autovalidateMode,
    super.forceErrorText,
    super.enabled,
  });
}

typedef _SelectionOptionKey<T> = ValueKey<(T, int)>;
typedef _SelectionListEntry<T> = ({
  YumeiroSelectionOption<T> option,
  _SelectionOptionKey<T> key,
});

class _YumeiroSelectionListState<T> extends State<YumeiroSelectionList<T>> {
  final _selectedKey = GlobalKey();
  ScrollController? _ownedScrollController;
  ScrollController get _scrollController =>
      widget._controller ?? (_ownedScrollController ??= ScrollController());
  String _query = '';
  Key? _revealKey;
  Key? _initialFocusKey;
  Key? _scrollCenter;

  bool get _enabled =>
      widget.enabled &&
      (widget.readOnly ||
          widget.onChanged != null ||
          widget.onSelected != null);
  bool get _editable => _enabled && !widget.readOnly;
  Set<T> get _values => widget._formState?.readValues() ?? widget.values;

  void _choose(YumeiroSelectionOption<T> option) {
    if (!_editable || !option.enabled) return;
    final values = _values;
    if (widget.onChanged case final onChanged?) {
      if (widget.multiple) {
        final next = Set<T>.of(values);
        if (!next.remove(option.value)) next.add(option.value);
        onChanged(Set<T>.unmodifiable(next));
      } else if (!values.contains(option.value)) {
        onChanged(Set<T>.unmodifiable({option.value}));
      }
    }
    widget.onSelected?.call(option);
  }

  void _clearSelection() {
    if (_editable && _values.isNotEmpty) {
      widget.onChanged?.call(Set<T>.unmodifiable(<T>{}));
    }
  }

  @override
  void initState() {
    super.initState();
    final focusOptions =
        !widget.multiple &&
        (widget._inline
            ? widget.autofocus && !widget.searchable && _editable
            : widget.scrollable &&
                  widget._revealSelection &&
                  widget._pointerMenu != null);
    final revealSelection = widget.scrollable && widget._revealSelection;
    if (!revealSelection && !focusOptions) return;
    final selected = widget.options
        .where((option) => widget.values.contains(option.value))
        .firstOrNull;
    final firstFocusable = focusOptions
        ? (selected?.enabled == true
              ? selected
              : widget.options.where((option) => option.enabled).firstOrNull)
        : null;
    if (firstFocusable != null) {
      final firstIndex = widget.options.indexOf(firstFocusable);
      final occurrence = widget.options
          .take(firstIndex)
          .where((option) => option.value == firstFocusable.value)
          .length;
      _initialFocusKey = ValueKey((firstFocusable.value, occurrence));
    }
    if (!revealSelection) return;
    final revealKey =
        _initialFocusKey ??
        (selected == null ? null : ValueKey((selected.value, 0)));
    if (revealKey == null) return;
    _revealKey = revealKey;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.scrollable || _revealKey != revealKey) return;
      final builtOption = _selectedKey.currentContext;
      if (builtOption == null) {
        setState(() => _scrollCenter = revealKey);
      } else {
        Scrollable.ensureVisible(builtOption, alignment: .4);
      }
    });
  }

  @override
  void didUpdateWidget(covariant YumeiroSelectionList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchable && !widget.searchable) _query = '';
    if (_scrollCenter == null ||
        !widget.scrollable ||
        !widget.enabled ||
        widget.readOnly) {
      return;
    }
    final focusManager = FocusManager.instance;
    final previous = focusManager.primaryFocus;
    final key = _optionKeyOf(previous);
    final scope = previous?.enclosingScope;
    if (key == null || scope == null) return;

    // A reorder can move the focused row to the other sliver, where its local
    // key can no longer keep the original element alive.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || focusManager.primaryFocus != null) return;
      final replacement = scope.traversalDescendants
          .where((node) => _optionKeyOf(node) == key)
          .firstOrNull;
      if (replacement != null && _overlapsViewport(replacement)) {
        replacement.requestFocus();
      }
    });
  }

  Key? _optionKeyOf(FocusNode? node) {
    final focusContext = node?.context;
    if (focusContext == null ||
        !focusContext.mounted ||
        focusContext.findAncestorStateOfType<_YumeiroSelectionListState<T>>() !=
            this) {
      return null;
    }
    if (widget._inline) {
      return focusContext
          .findAncestorWidgetOfExactType<_InlineOption<T>>()
          ?.key;
    }
    return widget._pointerMenu == null
        ? focusContext.findAncestorWidgetOfExactType<YumeiroSelectionRow>()?.key
        : focusContext
              .findAncestorWidgetOfExactType<SelectionMenuRow<T>>()
              ?.key;
  }

  static bool _overlapsViewport(FocusNode node) {
    final row = node.context?.findRenderObject();
    if (row == null || !row.attached) return false;
    final viewport = RenderAbstractViewport.maybeOf(row);
    if (viewport == null) return false;
    final bounds = MatrixUtils.transformRect(
      row.getTransformTo(viewport),
      row.paintBounds,
    );
    return bounds.isFinite &&
        !bounds.isEmpty &&
        bounds.overlaps(viewport.paintBounds);
  }

  @override
  void dispose() {
    _ownedScrollController?.dispose();
    super.dispose();
  }

  void _filter(String value) {
    final query = value.trim().toLowerCase();
    setState(() {
      _query = query;
      _revealKey = null;
      _scrollCenter = null;
    });
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  KeyEventResult _navigateUnbuiltOption(
    FocusNode group,
    KeyEvent event,
    List<_SelectionListEntry<T>> items,
  ) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final direction = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowUp || LogicalKeyboardKey.arrowLeft => -1,
      LogicalKeyboardKey.arrowDown || LogicalKeyboardKey.arrowRight => 1,
      _ => 0,
    };
    if (direction == 0) return KeyEventResult.ignored;
    final currentKey = _optionKeyOf(FocusManager.instance.primaryFocus);
    if (currentKey == null) return KeyEventResult.ignored;
    final choices = items.where((item) => item.option.enabled).toList();
    final current = choices.indexWhere((item) => item.key == currentKey);
    if (current == -1) return KeyEventResult.ignored;
    final target = choices[(current + direction) % choices.length];
    FocusNode? targetFocus() => group.traversalDescendants
        .where((node) => _optionKeyOf(node) == target.key)
        .firstOrNull;

    // Flutter's group navigates the registered radio nodes. Recenter the
    // virtualized list when the next enabled choice has yet to be built.
    if (targetFocus() != null || !_scrollController.hasClients) {
      return KeyEventResult.ignored;
    }
    _scrollController.jumpTo(0);
    setState(() {
      _revealKey = target.key;
      _scrollCenter = target.key;
    });
    _choose(target.option);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) targetFocus()?.requestFocus();
    });
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final l10n = YumeiroLocalizations.of(context);
    final query = widget._externalQuery ?? _query;
    final occurrences = <T, int>{};
    final items = <_SelectionListEntry<T>>[];
    for (final option in widget.options) {
      final occurrence = occurrences.update(
        option.value,
        (count) => count + 1,
        ifAbsent: () => 0,
      );
      if (_matchesSelectionQuery(option, query)) {
        items.add((option: option, key: ValueKey((option.value, occurrence))));
      }
    }
    final empty = Padding(
      padding: EdgeInsets.all(theme.spacing.md),
      child: Semantics(
        liveRegion: true,
        child: Text(
          widget._emptyText ?? l10n.noResults,
          style: theme.typography.supporting.copyWith(color: theme.muted),
        ),
      ),
    );

    Widget rows = widget.scrollable
        ? LayoutBuilder(
            builder: (context, constraints) => _scrollableRows(
              items,
              empty,
              widget._pointerMenu == null && !widget._inline
                  ? theme.spacing.sm
                  : 0,
              canCenter: constraints.hasBoundedHeight,
            ),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (items.isEmpty) empty,
              for (final item in items) _option(item.option, item.key),
            ],
          );
    if (widget._inline) {
      if (!widget.multiple) {
        final groupValue = items
            .where((item) => widget.values.contains(item.option.value))
            .firstOrNull
            ?.key;
        final options = {for (final item in items) item.key: item.option};
        rows = RadioGroup<_SelectionOptionKey<T>>(
          groupValue: groupValue,
          onChanged: (key) {
            // The group reports null when an already selected, toggleable row
            // is activated. Keep the value and report the original option.
            if (options[key ?? groupValue] case final option?) _choose(option);
          },
          child: Semantics(
            label: widget.semanticLabel ?? widget.label,
            readOnly: widget.readOnly ? true : null,
            validationResult: widget.hasError
                ? SemanticsValidationResult.invalid
                : SemanticsValidationResult.none,
            child: widget.scrollable && _editable
                ? Focus(
                    canRequestFocus: false,
                    onKeyEvent: (node, event) =>
                        _navigateUnbuiltOption(node, event, items),
                    child: rows,
                  )
                : rows,
          ),
        );
      }
      return _buildInline(context, rows);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget._externalQuery == null &&
            (widget.searchable || _query.isNotEmpty))
          Padding(
            padding: YumeiroSelectionSheetLayout.searchPaddingOf(context),
            child: YumeiroTextField(
              hintText: l10n.searchHint,
              clearable: true,
              enabled: widget.enabled,
              onChanged: _filter,
            ),
          ),
        if (widget.scrollable) Flexible(child: rows) else rows,
      ],
    );
  }

  Widget _buildInline(BuildContext context, Widget rows) {
    final theme = YumeiroTheme.of(context);
    final metrics = YumeiroModalityScope.metricsOf(context);
    final name =
        widget.semanticLabel ??
        widget.label ??
        YumeiroLocalizations.of(context).selectItem;
    final reservesClear =
        widget.clearable && _editable && widget.onChanged != null;
    final target = widget.dense
        ? metrics.denseTargetSize
        : metrics.minTargetSize;
    final clearSlot = reservesClear
        ? YumeiroVisualScope(
            controlRole: YumeiroControlRole.ghost,
            visualOverride: YumeiroVisualScope.maybeOf(context)?.visualOverride,
            child: SizedBox.square(
              dimension: target,
              child: widget.values.isEmpty
                  ? null
                  : yumeiroPickerClearButton(
                      context,
                      fieldLabel: name,
                      dense: widget.dense,
                      onPressed: _clearSelection,
                      includeFieldLabelInTooltip: widget.searchable,
                    ),
            ),
          )
        : null;
    final card = YumeiroCard.panel(
      role: metrics.isPointer && widget.searchable
          ? YumeiroSurfaceRole.floating
          : YumeiroSurfaceRole.panel,
      visualOverride: yumeiroPickerErrorOverride(
        context,
        enabled: _enabled,
        hasError: widget.hasError && !widget.searchable,
      ),
      padding: EdgeInsets.all(theme.spacing.xs),
      child: rows,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.constrainWidth(
          widget.width ??
              (widget.expand && constraints.hasBoundedWidth
                  ? constraints.maxWidth
                  : 240),
        );
        final inputPadding = yumeiroPickerHorizontalPadding(
          metrics,
          widget.dense,
        );
        final minWidthForBothActions =
            3 * target + inputPadding + 2 * theme.spacing.sm;
        return SizedBox(
          width: width,
          child: YumeiroFieldLayout(
            label: widget.label,
            semanticLabel: widget.multiple && !widget.searchable
                ? widget.semanticLabel
                : '',
            helperText: widget.helperText,
            required: widget._formState?.required ?? false,
            errorText: widget._formState?.error,
            dense: widget.dense,
            bottomSpacing:
                widget._formState != null ||
                    widget.label != null ||
                    widget.helperText != null
                ? null
                : 0,
            labelTrailing: widget.searchable ? null : clearSlot,
            flexibleChild: widget.scrollable,
            child: widget.searchable
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: theme.spacing.xs,
                    children: [
                      YumeiroTextField(
                        focusNode: widget.focusNode,
                        autofocus: _enabled && widget.autofocus,
                        enabled: _enabled,
                        hasError: widget.hasError,
                        semanticLabel: name,
                        hintText: YumeiroLocalizations.of(context).searchHint,
                        dense: widget.dense,
                        clearable:
                            !reservesClear || width >= minWidthForBothActions,
                        onChanged: _filter,
                        contentPadding: reservesClear
                            ? EdgeInsetsDirectional.only(start: inputPadding)
                            : null,
                        trailing: clearSlot,
                      ),
                      if (widget.scrollable) Flexible(child: card) else card,
                    ],
                  )
                : Focus(
                    focusNode: widget.focusNode,
                    autofocus: widget.multiple && _enabled && widget.autofocus,
                    canRequestFocus: _enabled,
                    skipTraversal: !widget.readOnly,
                    child: card,
                  ),
          ),
        );
      },
    );
  }

  Widget _scrollableRows(
    List<_SelectionListEntry<T>> items,
    Widget empty,
    double padding, {
    required bool canCenter,
  }) {
    if (items.isEmpty) {
      return SingleChildScrollView(
        controller: _scrollController,
        padding: EdgeInsets.all(padding),
        child: empty,
      );
    }
    final indices = {for (var i = 0; i < items.length; i++) items[i].key: i};
    final pivot = canCenter ? indices[_scrollCenter] ?? 0 : 0;
    if (pivot == 0) {
      return ListView.builder(
        controller: _scrollController,
        shrinkWrap: true,
        padding: EdgeInsets.all(padding),
        itemCount: items.length,
        itemExtent: widget._itemExtent,
        findChildIndexCallback: (key) => indices[key],
        itemBuilder: (context, index) =>
            _option(items[index].option, items[index].key),
      );
    }

    // A centered viewport can reveal a distant variable-height row without
    // measuring the preceding rows. Its first sliver grows toward the start.
    const center = ValueKey('selected-options');
    return CustomScrollView(
      controller: _scrollController,
      center: center,
      anchor: .4,
      semanticChildCount: items.length,
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(padding, padding, padding, 0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = items[pivot - 1 - index];
                return _option(item.option, item.key);
              },
              childCount: pivot,
              findChildIndexCallback: (key) {
                final index = indices[key];
                return index == null || index >= pivot
                    ? null
                    : pivot - 1 - index;
              },
              semanticIndexCallback: (_, index) => pivot - 1 - index,
            ),
          ),
        ),
        SliverPadding(
          key: center,
          padding: EdgeInsets.fromLTRB(padding, 0, padding, padding),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = items[pivot + index];
                return _option(item.option, item.key);
              },
              childCount: items.length - pivot,
              findChildIndexCallback: (key) {
                final index = indices[key];
                return index == null || index < pivot ? null : index - pivot;
              },
              semanticIndexOffset: pivot,
            ),
          ),
        ),
      ],
    );
  }

  Widget _option(YumeiroSelectionOption<T> item, _SelectionOptionKey<T> key) {
    final selected = widget.values.contains(item.value);
    if (widget._inline) {
      return _InlineOption<T>(
        key: key,
        option: item,
        selected: selected,
        enabled: _enabled && item.enabled,
        disabledForItem: _editable && !item.enabled,
        readOnly: widget.readOnly,
        dense: widget.dense,
        multiple: widget.multiple,
        reportRepeat: widget.onSelected != null,
        autofocus: key == _initialFocusKey,
        revealKey: key == _revealKey ? _selectedKey : null,
        onPressed: () => _choose(item),
      );
    }
    if (widget._pointerMenu case final menu?) {
      final row = SelectionMenuRow<T>(
        key: key,
        option: item,
        selected: selected,
        dense: menu.dense,
        textAlign: menu.textAlign,
        showCheckmark: !widget.multiple,
        showCheckbox: widget.multiple,
        highlighted:
            widget._highlightedValue != null &&
            item.value == widget._highlightedValue,
        autofocus: key == _initialFocusKey,
        onPressed: () => _choose(item),
      );
      return Padding(
        key: key,
        padding: selectionMenuRowInsets,
        child: key == _revealKey
            ? KeyedSubtree(key: _selectedKey, child: row)
            : row,
      );
    }

    Widget? optionIcon(IconData? icon) =>
        icon == null ? null : ExcludeSemantics(child: Icon(icon, size: 24));
    final row = YumeiroSelectionRow(
      key: key,
      selected: selected,
      enabled: widget.enabled && item.enabled,
      readOnly: widget.readOnly,
      multiple: widget.multiple,
      title: Text(
        widget._optionLabel?.call(item) ?? item.label,
        key: key == _revealKey ? _selectedKey : null,
      ),
      subtitle: item.subtitle == null ? null : Text(item.subtitle!),
      leading: optionIcon(item.icon),
      trailing: optionIcon(item.trailingIcon),
      onChanged: item.enabled ? (_) => _choose(item) : null,
    );
    return widget.multiple ? row : MergeSemantics(key: key, child: row);
  }
}
