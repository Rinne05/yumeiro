part of 'multi_select.dart';

/// Keeps the draft editor in the field while the anchored menu shows choices.
class _PointerMultiSelect<T extends Object> extends StatefulWidget {
  const _PointerMultiSelect({
    required this.field,
    required this.name,
    required this.generation,
    required this.onCommit,
  });

  final YumeiroMultiSelect<T> field;
  final String name;
  final int generation;
  final ValueChanged<Set<T>> onCommit;

  @override
  State<_PointerMultiSelect<T>> createState() => _PointerMultiSelectState<T>();
}

class _PointerMultiSelectState<T extends Object>
    extends State<_PointerMultiSelect<T>> {
  final _ownedFocus = FocusNode(debugLabel: 'YumeiroMultiSelect field');
  final _query = TextEditingController();
  final _scroll = ScrollController();
  final _portal = OverlayPortalController();
  final _anchorKey = GlobalKey();
  final _tapGroup = Object();
  late final _anchorVisibility = PickerAnchorVisibility(
    anchorContext: () => _anchorKey.currentContext,
    onHidden: _close,
  );

  MultiSelectionDraft<T>? _draft;
  T? _highlightedValue;
  double _openingWidth = 0;
  bool _movingFocus = false;

  YumeiroMultiSelect<T> get _field => widget.field;
  FocusNode get _focus => _field.focusNode ?? _ownedFocus;
  bool get _editable =>
      _field.enabled && !_field.readOnly && _field.onChanged != null;
  bool get _canOpen => _editable && _field.options.isNotEmpty;
  bool get _isOpen => _draft != null;
  Set<T> get _selection => _field._readValue?.call() ?? _field.value;
  Set<T> get _preview => _draft!.resolve(_selection, _field.options);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isOpen) _anchorVisibility.track(context);
  }

  @override
  void didUpdateWidget(covariant _PointerMultiSelect<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.generation != widget.generation ||
        oldWidget.field.focusNode != _field.focusNode ||
        oldWidget.field.searchable != _field.searchable ||
        oldWidget.field.useRootNavigator != _field.useRootNavigator ||
        !_canOpen) {
      _close(duringBuild: true);
    }
  }

  @override
  void dispose() {
    _anchorVisibility.track(null);
    _query.dispose();
    _scroll.dispose();
    _ownedFocus.dispose();
    super.dispose();
  }

  void _restoreFieldFocus() {
    _movingFocus = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _movingFocus = false;
      if (_editable) _focus.requestFocus();
    });
  }

  void _open() {
    if (!_canOpen || _isOpen) return;
    final anchor = _anchorKey.currentContext?.findRenderObject();
    if (anchor is! RenderBox || !anchor.hasSize) return;

    _query.clear();
    _restoreFieldFocus();
    final draft = MultiSelectionDraft<T>();
    setState(() {
      _draft = draft;
      _highlightedValue = null;
      _openingWidth = anchor.size.width;
    });
    _portal.show();
    _anchorVisibility.track(context);
    final selection = _selection;
    if (selection.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted ||
            !identical(_draft, draft) ||
            _highlightedValue != null ||
            _query.text.isNotEmpty) {
          return;
        }
        final options = _field.options;
        final index = options.indexWhere(
          (option) => selection.contains(option.value),
        );
        if (index > 0) _revealOption(index, options);
      });
    }
  }

  void _close({bool restoreFocus = false, bool duringBuild = false}) {
    if (!_isOpen) return;
    _draft = null;
    _anchorVisibility.track(null);
    if (restoreFocus) _restoreFieldFocus();
    if (duringBuild) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isOpen) _portal.hide();
      });
    } else {
      _portal.hide();
      setState(() {});
    }
  }

  void _confirm() {
    if (!_isOpen || !_editable) return;
    final next = _preview;
    _close(restoreFocus: true);
    widget.onCommit(next);
  }

  void _toggle(YumeiroSelectionOption<T> option) {
    if (!_isOpen || !_editable || !option.enabled) return;
    setState(() => _draft!.toggle(option.value, _selection));
  }

  void _onQueryChanged(String _) {
    setState(() => _highlightedValue = null);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  Iterable<YumeiroSelectionOption<T>> get _visibleOptions =>
      filterSelectionOptions(_field.options, _query.text);

  void _toggleHighlighted() {
    final enabled = _visibleOptions.where((option) => option.enabled);
    final option =
        enabled
            .where((option) => option.value == _highlightedValue)
            .firstOrNull ??
        enabled.firstOrNull;
    if (option != null) _toggle(option);
  }

  void _moveHighlight(int direction) {
    final options = _visibleOptions.toList(growable: false);
    if (options.isEmpty) return;
    var index = options.indexWhere(
      (option) => option.value == _highlightedValue,
    );
    if (index < 0 && direction < 0) index = 0;
    for (var candidate = 0; candidate < options.length; candidate++) {
      index = (index + direction) % options.length;
      final option = options[index];
      if (!option.enabled) continue;
      setState(() => _highlightedValue = option.value);
      if (_scroll.hasClients) {
        _revealOption(index, options);
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _isOpen && _highlightedValue == option.value) {
            _revealOption(index, options);
          }
        });
      }
      return;
    }
  }

  void _revealOption(int index, List<YumeiroSelectionOption<T>> options) {
    if (!_scroll.hasClients) return;
    final extent = _rowExtent(context, options);
    final position = _scroll.position;
    final top = extent * index;
    final bottom = top + extent;
    final next = top < position.pixels
        ? top
        : math.max(position.pixels, bottom - position.viewportDimension);
    final bounded = next.clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if (position.pixels != bounded) _scroll.jumpTo(bounded);
  }

  KeyEventResult _handleKey(FocusNode _, KeyEvent event) {
    if (!_editable || (event is! KeyDownEvent && event is! KeyRepeatEvent)) {
      return KeyEventResult.ignored;
    }
    final composing = _query.value.composing;
    if (_isOpen && composing.isValid && !composing.isCollapsed) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final enter =
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter;
    if (_isOpen && key == LogicalKeyboardKey.escape) {
      _close(restoreFocus: true);
      return KeyEventResult.handled;
    }
    if (_isOpen &&
        enter &&
        (HardwareKeyboard.instance.isControlPressed ||
            HardwareKeyboard.instance.isMetaPressed)) {
      if (event is KeyDownEvent && !setEquals(_preview, _selection)) _confirm();
      return KeyEventResult.handled;
    }
    if (!_focus.hasPrimaryFocus) return KeyEventResult.ignored;
    if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowUp) {
      if (!_isOpen) _open();
      if (_isOpen) {
        _moveHighlight(key == LogicalKeyboardKey.arrowDown ? 1 : -1);
        return KeyEventResult.handled;
      }
    }
    if (_isOpen &&
        (enter || (!_field.searchable && key == LogicalKeyboardKey.space))) {
      if (event is KeyDownEvent) _toggleHighlighted();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: false,
    onKeyEvent: _handleKey,
    onFocusChange: (focused) {
      if (!focused && !_movingFocus) _close();
    },
    child: OverlayPortal.overlayChildLayoutBuilder(
      controller: _portal,
      overlayLocation: _field.useRootNavigator
          ? OverlayChildLocation.rootOverlay
          : OverlayChildLocation.nearestOverlay,
      overlayChildBuilder: _buildOptions,
      child: TapRegion(
        key: _anchorKey,
        groupId: _tapGroup,
        behavior: HitTestBehavior.translucent,
        onTapOutside: _isOpen ? (_) => _close() : null,
        child: TextFieldTapRegion(
          child: _isOpen ? _buildOpenField() : _buildClosedField(context),
        ),
      ),
    ),
  );

  Widget _buildClosedField(BuildContext context) {
    final selected = _selection;
    final clearable = _field.clearable && _editable;
    return YumeiroFormPickerTrigger(
      width: _field.width,
      text: _multiSelectSummary(context, _field, selected),
      isPlaceholder: selected.isEmpty,
      enabled: _field.enabled && (_field.readOnly || _editable),
      readOnly: _field.readOnly,
      hasError: _field._errorText != null,
      dense: _field.dense,
      expand: _field.expand || _field.width != null,
      focusNode: _focus,
      autofocus: _field.autofocus,
      onOpen: _canOpen ? (_) => _open() : null,
      clearable: clearable,
      clearButton: clearable && selected.isNotEmpty
          ? yumeiroPickerClearButton(
              context,
              fieldLabel: widget.name,
              dense: _field.dense,
              onPressed: () => widget.onCommit(<T>{}),
            )
          : null,
    );
  }

  Widget _buildOpenField() => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.constrainWidth(
        _field.width ??
            (_field.expand && constraints.hasBoundedWidth
                ? constraints.maxWidth
                : _openingWidth),
      );
      final l10n = YumeiroLocalizations.of(context);
      final theme = YumeiroTheme.of(context);
      final metrics = YumeiroModalityScope.metricsOf(context);
      final selected = _selection;
      final preview = _preview;
      final dirty = !setEquals(preview, selected);
      final actionLabel = dirty
          ? l10n.confirmWithCount(preview.length)
          : l10n.cancel;
      void cancel() => _close(restoreFocus: true);
      final available =
          width -
          yumeiroPickerHorizontalPadding(metrics, _field.dense) * 2 -
          theme.spacing.sm -
          metrics.minTargetSize;
      final iconExtent = metrics.denseTargetSize;
      final iconActionsWidth = iconExtent * 2 + theme.spacing.xs;
      final textButtonWidth =
          yumeiroSelectTextWidth(
            context,
            actionLabel,
            theme.typography.control(dense: true),
          ) +
          metrics.horizontalPadding * 1.5;
      final stacked = available < iconActionsWidth;
      final showLabel =
          (stacked ? width : available) >=
          textButtonWidth + (dirty ? iconExtent + theme.spacing.xs : 0);
      final actions = YumeiroVisualScope(
        visualOverride: YumeiroVisualScope.maybeOf(context)?.visualOverride,
        child: Wrap(
          spacing: theme.spacing.xs,
          runSpacing: theme.spacing.xs,
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (dirty)
              YumeiroButton(
                icon: theme.icons.close,
                tooltip: l10n.cancel,
                variant: YumeiroButtonVariant.ghost,
                dense: true,
                onPressed: cancel,
              ),
            YumeiroButton(
              label: showLabel ? actionLabel : null,
              icon: showLabel
                  ? null
                  : (dirty ? theme.icons.check : theme.icons.close),
              tooltip: showLabel ? null : actionLabel,
              variant: dirty
                  ? YumeiroButtonVariant.primary
                  : YumeiroButtonVariant.ghost,
              dense: true,
              onPressed: dirty ? _confirm : cancel,
            ),
          ],
        ),
      );
      final input = Semantics(
        expanded: true,
        child: _multiSelectSearchSurface(
          context,
          YumeiroTextField(
            controller: _query,
            focusNode: _focus,
            hintText: _field.searchable
                ? l10n.searchHint
                : selected.isEmpty
                ? _field.placeholder ?? l10n.selectPlaceholder
                : l10n.selectedCount(selected.length),
            semanticLabel: widget.name,
            readOnly: !_field.searchable,
            dense: _field.dense,
            hasError: _field._errorText != null,
            textInputAction: TextInputAction.search,
            onEditingComplete: () {},
            onSubmitted: (_) => _toggleHighlighted(),
            onChanged: _field.searchable ? _onQueryChanged : null,
            trailing: stacked ? null : actions,
          ),
        ),
      );
      return SizedBox(
        width: width,
        child: stacked
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  input,
                  SizedBox(height: theme.spacing.xs),
                  actions,
                ],
              )
            : input,
      );
    },
  );

  double _rowExtent(
    BuildContext context,
    Iterable<YumeiroSelectionOption<T>> options,
  ) => selectionMenuRowHeight(
    context,
    options,
    dense: _field.dense,
    multiple: true,
  );

  Widget _buildOptions(BuildContext context, OverlayChildLayoutInfo info) {
    if (!_isOpen) return const SizedBox.shrink();
    final anchor = MatrixUtils.transformRect(
      info.childPaintTransform,
      Offset.zero & info.childSize,
    );
    if (!anchor.isFinite || anchor.isEmpty) return const SizedBox.shrink();
    final media = MediaQuery.of(context);
    return Positioned.fill(
      child: PickerOverlayLayout(
        anchor: anchor,
        maxHeight: 280,
        padding: media.viewPadding.copyWith(
          bottom: math.max(media.viewPadding.bottom, media.viewInsets.bottom),
        ),
        child: TapRegion(
          groupId: _tapGroup,
          behavior: HitTestBehavior.translucent,
          child: TextFieldTapRegion(
            child: ExcludeFocus(
              child: PickerFloatingSurface(
                padding: selectionMenuSurfacePadding,
                child: buildMultiSelectOptions<T>(
                  options: _field.options,
                  values: _preview,
                  onSelected: _toggle,
                  query: _query.text,
                  dense: _field.dense,
                  highlightedValue: _highlightedValue,
                  controller: _scroll,
                  itemExtent: _rowExtent(context, _visibleOptions),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
