part of 'select.dart';

class _MenuSelect<T> extends YumeiroSelect<T> {
  const _MenuSelect({
    super.key,
    required super.value,
    required super.options,
    required super.onChanged,
    super.placeholder,
    this.icon,
    this.trailingIcon,
    this.showTrailingIcon = true,
    super.width,
    super.menuWidth,
    super.menuAutoWidth,
    super.maxWidth,
    super.expand,
    this.child,
    super.dense,
    this.tooltip,
    super.title,
    super.enabled,
    super.readOnly,
    super.focusNode,
    super.autofocus,
    super.semanticLabel,
    super.hasError,
    super.useRootNavigator,
    this.textAlign = TextAlign.center,
    this.position = PopupMenuPosition.under,
    this.centerMenu = false,
    this.offset,
    this.menuVisualOverride,
    this.maxVisibleItems,
    this.selected = false,
    this.displayText,
    this.selectedLabelBuilder,
  });

  final IconData? icon;
  final IconData? trailingIcon;
  final bool showTrailingIcon;
  final Widget? child;
  final String? tooltip;
  final TextAlign textAlign;
  final PopupMenuPosition position;
  final bool centerMenu;
  final Offset? offset;
  final YumeiroVisualOverride? menuVisualOverride;
  final int? maxVisibleItems;
  final bool selected;
  final String? displayText;
  final String Function(YumeiroSelectionOption<T> item)? selectedLabelBuilder;

  @override
  String? get _fixedSheetTitle => title ?? tooltip ?? placeholder;

  @override
  bool get _fixedSheetSearchable => options.length > 10;

  @override
  State<_MenuSelect<T>> createState() => _MenuSelectState<T>();

  double _computeAutoWidth(
    BuildContext context,
    YumeiroThemeExtension theme,
    YumeiroLocalizations l10n,
  ) {
    final textStyle = theme.typography.control(selected: true, dense: dense);
    var maxTriggerTextWidth = 0.0;

    final placeholderText = placeholder ?? l10n.selectPlaceholder;
    final pw = yumeiroSelectTextWidth(context, placeholderText, textStyle);
    if (pw > maxTriggerTextWidth) maxTriggerTextWidth = pw;

    if (displayText != null && displayText!.isNotEmpty) {
      final dw = yumeiroSelectTextWidth(context, displayText!, textStyle);
      if (dw > maxTriggerTextWidth) maxTriggerTextWidth = dw;
    }

    YumeiroSelectionOption<T>? currentItem;
    for (final item in options) {
      if (item.value == value) {
        currentItem = item;
        break;
      }
    }
    final currentActiveText =
        displayText ??
        (currentItem != null && selectedLabelBuilder != null
            ? selectedLabelBuilder!(currentItem)
            : currentItem?.label ?? placeholderText);
    if (currentActiveText.isNotEmpty) {
      final cw = yumeiroSelectTextWidth(context, currentActiveText, textStyle);
      if (cw > maxTriggerTextWidth) maxTriggerTextWidth = cw;
    }

    for (final item in options) {
      final triggerText = selectedLabelBuilder != null
          ? selectedLabelBuilder!(item)
          : item.label;
      if (triggerText.isNotEmpty) {
        final tw = yumeiroSelectTextWidth(context, triggerText, textStyle);
        if (tw > maxTriggerTextWidth) maxTriggerTextWidth = tw;
      }
    }

    final isTouch = YumeiroModalityScope.metricsOf(context).isTouch;
    final triggerWidth = yumeiroSelectAutoWidth(
      context,
      triggerTextWidth: maxTriggerTextWidth,
      hasLeadingIcon:
          icon != null ||
          (!isTouch && options.any((item) => item.icon != null)),
      hasTrailingIcon: showTrailingIcon,
      dense: dense,
      maxWidth: maxWidth,
    );
    if (isTouch) return math.min(maxWidth, triggerWidth);

    final menuWidth = selectionMenuContentWidth(
      context,
      options,
      dense: dense,
      showCheckmark: true,
      textAlign: textAlign,
    );
    return math.min(maxWidth, math.max(triggerWidth, menuWidth.ceilToDouble()));
  }
}

class _MenuSelectState<T> extends State<_MenuSelect<T>> {
  final MenuController _menuController = MenuController();
  final FocusNode _ownedFocus = FocusNode(
    debugLabel: 'YumeiroSelect.menu trigger',
  );
  final _sheetController = YumeiroSheetController();
  bool _menuOpen = false;
  bool _sheetOpen = false;
  bool _isHovered = false;
  bool _isPressed = false;
  double? _autoWidth;

  bool get _isOpen => _menuOpen || _sheetOpen;
  bool get _canOpen => widget._canOpenFixedPicker;
  FocusNode get _triggerFocusNode => widget.focusNode ?? _ownedFocus;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _autoWidth = null;
  }

  @override
  void didUpdateWidget(covariant _MenuSelect<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _autoWidth = null;
    if (widget._closesFixedPicker(oldWidget)) {
      if (_isOpen) _hideMenu();
      _isPressed = false;
    } else if (_sheetOpen && widget._updatesFixedPicker(oldWidget)) {
      _sheetController.refresh();
    }
  }

  @override
  void dispose() {
    _sheetController.close();
    _ownedFocus.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    if (!_canOpen) return;
    if (_isOpen) {
      _hideMenu();
    } else if (YumeiroModalityScope.modalityOf(context) ==
        YumeiroModality.touch) {
      _showSheet();
    } else {
      _menuController.open();
    }
  }

  void _setPressed(bool value) {
    if (_isPressed == value) return;
    setState(() => _isPressed = value);
  }

  void _hideMenu() {
    if (_sheetOpen) {
      _sheetController.close();
    } else {
      _menuController.close();
    }
  }

  Future<void> _showSheet() async {
    setState(() => _sheetOpen = true);
    try {
      final box = context.findRenderObject()! as RenderBox;
      final result = await _showFixedOptionsSheet<T>(
        context: context,
        controller: _sheetController,
        anchor: () => pickerGlobalBounds(box),
        select: () => widget,
      );
      if (mounted) widget._acceptFixedOption(result);
    } finally {
      if (mounted) {
        setState(() => _sheetOpen = false);
        if (_canOpen) {
          _triggerFocusNode.requestFocus();
        }
      }
    }
  }

  KeyEventResult _handleTriggerKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent || !_canOpen) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space ||
        event.logicalKey == LogicalKeyboardKey.arrowDown ||
        event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _toggleMenu();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  YumeiroSelectionOption<T>? get _selectedItem {
    for (final item in widget.options) {
      if (item.value == widget.value) return item;
    }
    return null;
  }

  Widget _buildDefaultTrigger(
    BuildContext context,
    YumeiroThemeExtension theme,
    YumeiroSelectionOption<T>? selectedItem, {
    required String label,
    required Set<WidgetState> states,
    required bool fillsWidth,
  }) {
    final trailing =
        widget.trailingIcon ??
        selectedItem?.trailingIcon ??
        theme.icons.chevronDown;
    return YumeiroSelectTriggerVisual(
      label: label,
      states: states,
      icon: YumeiroModalityScope.metricsOf(context).isTouch
          ? widget.icon
          : widget.icon ?? selectedItem?.icon,
      trailingIcon: trailing,
      showTrailingIcon:
          widget.showTrailingIcon && !(widget.enabled && widget.readOnly),
      visualOverride: yumeiroPickerErrorOverride(
        context,
        enabled: widget.enabled && (_canOpen || widget.readOnly),
        hasError: widget.hasError,
      ),
      selected: widget.selected,
      isPlaceholder: selectedItem == null && widget.displayText == null,
      fillsWidth: fillsWidth,
      dense: widget.dense,
      textAlign: widget.textAlign,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final l10n = YumeiroLocalizations.of(context);
    final isReadOnly = widget.enabled && widget.readOnly;
    final isEnabled = _canOpen || isReadOnly;
    final selectedItem = _selectedItem;

    return LayoutBuilder(
      builder: (_, parentConstraints) {
        final parentWidth = parentConstraints.hasBoundedWidth
            ? parentConstraints.maxWidth
            : null;
        double contentAutoWidth() =>
            _autoWidth ??= widget._computeAutoWidth(context, theme, l10n);
        double autoWidth() {
          final computed = contentAutoWidth();
          return parentWidth == null
              ? computed
              : math.min(computed, parentWidth);
        }

        final resolvedWidth =
            widget.width ??
            (parentConstraints.hasTightWidth ? parentWidth : null) ??
            (widget.expand && widget.child == null ? parentWidth : null) ??
            (widget.child == null ? autoWidth() : null);

        final selectedLabel =
            widget.displayText ??
            (selectedItem != null && widget.selectedLabelBuilder != null
                ? widget.selectedLabelBuilder!(selectedItem)
                : selectedItem?.label ??
                      widget.placeholder ??
                      l10n.selectPlaceholder);
        final states = {
          if (!isEnabled) WidgetState.disabled,
          if (_triggerFocusNode.hasPrimaryFocus) WidgetState.focused,
          if (_canOpen && _isHovered) WidgetState.hovered,
          if (_isPressed) WidgetState.pressed,
          if (widget.selected) WidgetState.selected,
        };
        final content = widget.child != null
            ? YumeiroInteractionStateScope(states: states, child: widget.child!)
            : _buildDefaultTrigger(
                context,
                theme,
                selectedItem,
                label: selectedLabel,
                states: states,
                fillsWidth: resolvedWidth != null,
              );
        Widget trigger = resolvedWidth == null
            ? content
            : SizedBox(width: resolvedWidth, child: content);
        if (widget.tooltip case final tip? when tip.isNotEmpty) {
          trigger = YumeiroTooltip(message: tip, child: trigger);
        }

        final menuWidth =
            widget.menuWidth ??
            (widget.menuAutoWidth
                ? contentAutoWidth()
                : resolvedWidth ?? contentAutoWidth());
        final media = MediaQuery.of(context);
        final viewportHeight = math.max(
          0.0,
          media.size.height -
              media.viewPadding.top -
              math.max(media.viewPadding.bottom, media.viewInsets.bottom) -
              16,
        );
        final count = widget.maxVisibleItems;
        final menuHeight = count == null
            ? viewportHeight
            : math.min(
                viewportHeight,
                selectionMenuRowHeight(
                          context,
                          widget.options,
                          dense: widget.dense,
                        ) *
                        count +
                    selectionMenuSurfacePadding.vertical,
              );
        return PickerMenuAnchor(
          controller: _menuController,
          focusNode: _triggerFocusNode,
          width: menuWidth,
          crossAxisUnconstrained: false,
          useRootOverlay: widget.useRootNavigator,
          maxHeight: menuHeight,
          position: widget.position,
          center: widget.centerMenu,
          offset: widget.offset,
          visualOverride: widget.menuVisualOverride,
          onOpen: () => setState(() => _menuOpen = true),
          onClose: () => setState(() => _menuOpen = false),
          // MenuAnchor scrolls its menu children in an unbounded column. Give
          // the lazy list its own finite viewport so it can reveal a distant
          // selected row without laying out all preceding options.
          menu: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: menuHeight),
            child: PickerFloatingSurface(
              visualOverride: widget.menuVisualOverride,
              padding: selectionMenuSurfacePadding,
              child: buildMenuSelectionList<T>(
                options: widget.options,
                values: {if (selectedItem != null) selectedItem.value},
                dense: widget.dense,
                textAlign: widget.textAlign,
                onSelected: (option) {
                  if (!_canOpen) return;
                  _hideMenu();
                  widget._acceptFixedOption(option);
                },
              ),
            ),
          ),
          child: Focus(
            focusNode: _triggerFocusNode,
            canRequestFocus: isEnabled,
            autofocus: isEnabled && widget.autofocus,
            onKeyEvent: _handleTriggerKey,
            onFocusChange: (_) {
              if (mounted) setState(() {});
            },
            child: Semantics(
              button: !isReadOnly,
              enabled: isEnabled,
              readOnly: isReadOnly ? true : null,
              expanded: isReadOnly ? null : _isOpen,
              selected: widget.selected ? true : null,
              label:
                  widget.semanticLabel ?? l10n.dropdownSelection(selectedLabel),
              value: widget.semanticLabel == null ? null : selectedLabel,
              hint: _canOpen ? l10n.selectOptionsHint : null,
              onTap: _canOpen ? _toggleMenu : null,
              child: ExcludeSemantics(
                child: MouseRegion(
                  cursor: _canOpen
                      ? SystemMouseCursors.click
                      : SystemMouseCursors.basic,
                  onEnter: (_) => setState(() => _isHovered = true),
                  onExit: (_) => setState(() => _isHovered = false),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: _canOpen ? (_) => _setPressed(true) : null,
                    onTapUp: _canOpen ? (_) => _setPressed(false) : null,
                    onTapCancel: _canOpen ? () => _setPressed(false) : null,
                    onTap: _canOpen ? _toggleMenu : null,
                    child: trigger,
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

class _SearchableSelect<T> extends YumeiroSelect<T> {
  const _SearchableSelect({
    super.key,
    required super.options,
    super.value,
    this.initialText,
    required this._onChanged,
    this.onFreeTextSubmitted,
    this.clearable = true,
    super.placeholder,
    this.icon,
    super.width,
    super.menuWidth,
    super.menuAutoWidth,
    super.maxWidth,
    super.expand,
    super.dense,
    this.maxVisibleItems = 5,
    this.textAlign = TextAlign.start,
    this.displayText,
    this.emptyText,
    this.filter,
    this.itemTextBuilder,
    this.tooltip,
    super.title,
    super.enabled,
    super.readOnly,
    super.focusNode,
    super.autofocus,
    super.semanticLabel,
    super.hasError,
    super.useRootNavigator,
    this.menuVisualOverride,
  }) : super(onChanged: null);

  @override
  ValueChanged<T?>? get onChanged => _onChanged;

  final ValueChanged<T?>? _onChanged;
  final String? initialText;
  final ValueChanged<String>? onFreeTextSubmitted;
  final bool clearable;
  final String? emptyText;
  final bool Function(YumeiroSelectionOption<T> item, String query)? filter;
  final String Function(YumeiroSelectionOption<T> item)? itemTextBuilder;
  final IconData? icon;
  final int maxVisibleItems;
  final TextAlign textAlign;
  final String? displayText;
  final String? tooltip;
  final YumeiroVisualOverride? menuVisualOverride;

  bool get _editable => enabled && !readOnly && onChanged != null;

  @override
  State<_SearchableSelect<T>> createState() => _SearchableSelectState<T>();

  double _computeSearchableAutoWidth(
    BuildContext context,
    YumeiroThemeExtension theme,
    YumeiroLocalizations l10n,
  ) {
    final metrics = YumeiroModalityScope.metricsOf(context);
    final inputStyle = theme.typography.input(dense: dense);

    var maxTriggerTextWidth = yumeiroSelectTextWidth(
      context,
      placeholder ?? l10n.searchOrSelectHint,
      inputStyle,
    );

    if (initialText != null && initialText!.isNotEmpty) {
      final iw = yumeiroSelectTextWidth(context, initialText!, inputStyle);
      if (iw > maxTriggerTextWidth) maxTriggerTextWidth = iw;
    }
    if (displayText case final text?) {
      maxTriggerTextWidth = math.max(
        maxTriggerTextWidth,
        yumeiroSelectTextWidth(context, text, inputStyle),
      );
    }

    for (final item in options) {
      final text = itemTextBuilder?.call(item) ?? item.label;
      if (text.isNotEmpty) {
        final tw = yumeiroSelectTextWidth(context, text, inputStyle);
        if (tw > maxTriggerTextWidth) maxTriggerTextWidth = tw;
      }
    }

    if (metrics.isTouch) {
      final lower = math.min(maxWidth, 112.0);
      return (112.0 + maxTriggerTextWidth).ceilToDouble().clamp(
        lower,
        maxWidth,
      );
    }

    final editable = _editable;
    final (:clearExtent, :chevronExtent) = yumeiroPickerActionExtents(
      theme,
      metrics,
      dense,
    );
    final trailingButtons = !editable && readOnly
        ? 0.0
        : editable && clearable
        ? clearExtent + chevronExtent
        : clearExtent;
    final leadingChrome = icon != null
        ? yumeiroPickerIconSize(theme, metrics, dense) + theme.spacing.sm
        : 0.0;
    final triggerChrome =
        yumeiroPickerHorizontalPadding(metrics, dense) +
        2.0 +
        leadingChrome +
        trailingButtons +
        8.0;

    final rawWidth = math.max(
      triggerChrome + maxTriggerTextWidth,
      selectionMenuContentWidth(
        context,
        options,
        dense: dense,
        showCheckmark: true,
        textAlign: textAlign,
        labelBuilder: itemTextBuilder,
      ),
    );
    final lower = math.min(maxWidth, dense ? 112.0 : 132.0);
    return rawWidth.ceilToDouble().clamp(lower, maxWidth);
  }
}

class _SearchableSelectState<T> extends State<_SearchableSelect<T>> {
  final _triggerKey = GlobalKey();
  final _sheetController = YumeiroSheetController();
  final _menu = OverlayPortalController();
  final _textController = TextEditingController();
  final _ownedFocusNode = FocusNode(
    debugLabel: 'YumeiroSelect.searchable input',
  );
  final _scrollController = ScrollController();
  final _tapGroup = Object();
  late final _anchorVisibility = PickerAnchorVisibility(
    anchorContext: () => _triggerKey.currentContext,
    onHidden: () => _focusNode.unfocus(),
  );

  TextEditingValue? _editingValue;
  bool _formValueUpdated = false;
  bool _isOpen = false;
  bool _sheetOpen = false;
  bool _isHovered = false;
  int _sheetSession = 0;
  int _highlighted = 0;
  double? _autoWidth;
  bool? _cacheDefaultMatches;
  String? _matchedQuery;
  List<YumeiroSelectionOption<T>>? _matchedRows;

  FocusNode get _focusNode => widget.focusNode ?? _ownedFocusNode;
  bool get _editable => widget._editable;
  bool get _enabled => _editable || (widget.enabled && widget.readOnly);

  @override
  void initState() {
    super.initState();
    _updateDisplayText(
      TextEditingValue(text: _selectedText(fallback: widget.initialText)),
    );
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _autoWidth = null;
    if (_isOpen) {
      if (YumeiroModalityScope.metricsOf(context).isTouch) {
        _invalidatePicker(duringBuild: true);
        _restoreSelectedText();
      } else {
        _anchorVisibility.track(context);
      }
    }
  }

  @override
  void didUpdateWidget(covariant _SearchableSelect<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _autoWidth = null;
    _cacheDefaultMatches = null;
    _matchedQuery = null;
    _matchedRows = null;
    final focusChanged = oldWidget.focusNode != widget.focusNode;
    if (focusChanged) {
      (oldWidget.focusNode ?? _ownedFocusNode).removeListener(
        _handleFocusChange,
      );
      _focusNode.addListener(_handleFocusChange);
    }
    final pickerChanged =
        (oldWidget._editable && !_editable) ||
        focusChanged ||
        oldWidget.useRootNavigator != widget.useRootNavigator;
    if (pickerChanged) {
      _invalidatePicker(duringBuild: true);
    }
    final itemsChanged = !listEquals(oldWidget.options, widget.options);
    final optionsChanged =
        itemsChanged ||
        oldWidget.itemTextBuilder != widget.itemTextBuilder ||
        oldWidget.filter != widget.filter;
    if (optionsChanged ||
        oldWidget.value != widget.value ||
        oldWidget.title != widget.title ||
        oldWidget.tooltip != widget.tooltip ||
        oldWidget.placeholder != widget.placeholder) {
      _sheetController.refresh();
    }
    if (optionsChanged) _highlighted = 0;
    final isEditing =
        _editable &&
        _focusNode.hasFocus &&
        YumeiroModalityScope.metricsOf(context).isPointer;
    if (pickerChanged || _formValueUpdated) {
      _formValueUpdated = false;
      _restoreSelectedText();
    } else if (!isEditing) {
      if (oldWidget.value != widget.value ||
          itemsChanged ||
          oldWidget.itemTextBuilder != widget.itemTextBuilder ||
          (oldWidget.onFreeTextSubmitted == null) !=
              (widget.onFreeTextSubmitted == null)) {
        _restoreSelectedText();
      } else if (oldWidget.displayText != widget.displayText) {
        _updateDisplayText();
      }
    }
  }

  @override
  void dispose() {
    _sheetController.close();
    _anchorVisibility.track(null);
    _focusNode.removeListener(_handleFocusChange);
    _ownedFocusNode.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String? _findItemLabel(T? value) {
    for (final item in widget.options) {
      if (item.value == value) {
        return widget.itemTextBuilder?.call(item) ?? item.label;
      }
    }
    return null;
  }

  String _displayOption(YumeiroSelectionOption<T> item) =>
      widget.itemTextBuilder?.call(item) ?? item.label;

  String _selectedText({String? fallback}) =>
      _findItemLabel(widget.value) ??
      fallback ??
      (widget.onFreeTextSubmitted != null && widget.value is String
          ? widget.value as String
          : '');

  String get _editingText => _editingValue?.text ?? _textController.text;

  // While the field shows a resting label, keep the actual editor value for
  // autocomplete and restore it before the user resumes editing.
  void _updateDisplayText([TextEditingValue? newValue]) {
    final editingValue = newValue ?? _editingValue ?? _textController.value;
    final displayText = _focusNode.hasFocus ? null : widget.displayText;
    _editingValue = displayText == null ? null : editingValue;
    final shownValue = displayText == null
        ? editingValue
        : TextEditingValue(text: displayText);
    if (_textController.value != shownValue) _textController.value = shownValue;
  }

  void _restoreSelectedText() {
    final text = _selectedText();
    _updateDisplayText(
      _editingText == text ? null : TextEditingValue(text: text),
    );
  }

  // Custom callbacks, option subtypes and toString implementations can read
  // external state. Only plain options with scalar values use the snapshot.
  bool get _canReuseMatches => _cacheDefaultMatches ??=
      widget.filter == null &&
      widget.itemTextBuilder == null &&
      (T == String || T == int || T == double || T == num || T == bool) &&
      widget.options.every(
        (item) => item.runtimeType == YumeiroSelectionOption<T>,
      );

  List<YumeiroSelectionOption<T>> _filterItems(String query) {
    final trimmed = query.trim();
    if (!_canReuseMatches) return _findMatches(trimmed);
    if (_matchedQuery != trimmed) {
      _matchedRows = _findMatches(trimmed);
      _matchedQuery = trimmed;
    }
    return _matchedRows!;
  }

  List<YumeiroSelectionOption<T>> _findMatches(String trimmed) {
    if (trimmed.isEmpty || trimmed == _findItemLabel(widget.value)) {
      return widget.options;
    }
    if (widget.filter case final filter?) {
      return widget.options
          .where((item) => filter(item, trimmed))
          .toList(growable: false);
    }
    final lower = trimmed.toLowerCase();
    final canDifferFromLabel = !_canReuseMatches;
    return widget.options
        .where((item) {
          return _displayOption(item).toLowerCase().contains(lower) ||
              (canDifferFromLabel &&
                  item.label.toLowerCase().contains(lower)) ||
              (item.subtitle?.toLowerCase().contains(lower) ?? false) ||
              item.value.toString().toLowerCase().contains(lower);
        })
        .toList(growable: false);
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      _updateDisplayText();
      if (YumeiroModalityScope.metricsOf(context).isPointer) _openPointer();
    } else {
      _closePointer();
      _updateDisplayText();
    }
    setState(() {});
  }

  void _handleControlFocusChange(bool focused) {
    // Keep the clear button mounted when Tab moves focus to it.
    if (!focused && widget.onFreeTextSubmitted == null) {
      setState(_restoreSelectedText);
    }
  }

  void _openPointer() {
    if (_isOpen || !_editable) return;
    setState(() {
      _highlighted = 0;
      _isOpen = true;
    });
    _menu.show();
    _anchorVisibility.track(context);
  }

  void _closePointer({bool duringBuild = false}) {
    if (!_isOpen) return;
    _isOpen = false;
    _anchorVisibility.track(null);
    if (duringBuild) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isOpen) _menu.hide();
      });
    } else {
      _menu.hide();
      setState(() {});
    }
  }

  void _invalidatePicker({bool duringBuild = false}) {
    _sheetSession++;
    _sheetController.close();
    _closePointer(duringBuild: duringBuild);
  }

  void _formValueDidChange() {
    _formValueUpdated = true;
    _invalidatePicker();
  }

  void _showMenu() {
    _focusNode.requestFocus();
    _openPointer();
  }

  void _toggleMenu() {
    if (_isOpen) {
      _closePointer();
    } else {
      _showMenu();
    }
  }

  void _editQuery() {
    if (!_isOpen) {
      _openPointer();
      return;
    }
    if (_scrollController.hasClients && _scrollController.offset != 0) {
      _scrollController.jumpTo(0);
    }
    setState(() => _highlighted = 0);
  }

  List<int> _enabledIndices(List<YumeiroSelectionOption<T>> rows) => [
    for (final (index, row) in rows.indexed)
      if (row.enabled) index,
  ];

  void _submitPointer(String text) {
    final rows = _filterItems(_editingText);
    final enabled = _enabledIndices(rows);
    if (_isOpen && enabled.isNotEmpty) {
      _selectItem(rows[enabled[_highlighted.clamp(0, enabled.length - 1)]]);
    } else {
      _onInputSubmitted(text);
    }
  }

  KeyEventResult _handlePointerKey(FocusNode _, KeyEvent event) {
    if (!_editable || (event is! KeyDownEvent && event is! KeyRepeatEvent)) {
      return KeyEventResult.ignored;
    }
    final composing = _textController.value.composing;
    if (composing.isValid && !composing.isCollapsed) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape && _isOpen) {
      _closePointer();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.pageUp ||
        key == LogicalKeyboardKey.pageDown) {
      if (!_isOpen) {
        _openPointer();
      } else {
        _moveHighlight(key);
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _moveHighlight(LogicalKeyboardKey key) {
    final rows = _filterItems(_editingText);
    final enabled = _enabledIndices(rows);
    if (enabled.isEmpty) return;

    final hardware = HardwareKeyboard.instance;
    final jumpToEdge = switch (defaultTargetPlatform) {
      TargetPlatform.iOS || TargetPlatform.macOS => hardware.isMetaPressed,
      _ => hardware.isControlPressed,
    };
    final direction =
        key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.pageUp
        ? -1
        : 1;
    final page =
        key == LogicalKeyboardKey.pageUp || key == LogicalKeyboardKey.pageDown;
    final steps = page ? widget.maxVisibleItems : 1;
    final next = jumpToEdge && !page
        ? (direction < 0 ? 0 : enabled.length - 1)
        : (_highlighted + direction * steps).clamp(0, enabled.length - 1);
    setState(() => _highlighted = next);
    if (!_scrollController.hasClients) return;

    final rowHeight = selectionMenuRowHeight(
      context,
      rows,
      dense: widget.dense,
    );
    final position = _scrollController.position;
    final rowTop = rowHeight * enabled[next];
    final rowBottom = rowTop + rowHeight;
    final offset = rowTop < position.pixels
        ? rowTop
        : math.max(position.pixels, rowBottom - position.viewportDimension);
    final target = offset.clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if (target != position.pixels) _scrollController.jumpTo(target);
  }

  void _onInputSubmitted(String text) {
    if (!_editable) return;
    _closePointer();
    _focusNode.unfocus();
    switch (_selectionForText(text)) {
      case final YumeiroSelectionOption<T> option:
        _selectItem(option);
      case final String text:
        _updateDisplayText(TextEditingValue(text: text));
        if (text.isEmpty) {
          widget.onChanged!(null);
        } else {
          widget.onFreeTextSubmitted!(text);
        }
      case _:
        _restoreSelectedText();
    }
  }

  // Returns the matching option or a text submission. An empty string clears
  // the value, while null leaves the current selection unchanged.
  Object? _selectionForText(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return widget.clearable ? '' : null;

    final lower = trimmed.toLowerCase();
    var matchedDisabledOption = false;
    for (final item in widget.options) {
      if (_displayOption(item).toLowerCase() == lower ||
          item.label.toLowerCase() == lower ||
          item.value.toString().toLowerCase() == lower) {
        if (item.enabled) return item;
        matchedDisabledOption = true;
      }
    }
    return !matchedDisabledOption && widget.onFreeTextSubmitted != null
        ? trimmed
        : null;
  }

  void _selectItem(YumeiroSelectionOption<T> item) {
    if (!_editable) return;
    final current = widget.options
        .where(
          (candidate) => candidate.value == item.value && candidate.enabled,
        )
        .firstOrNull;
    if (current == null) return;
    _closePointer();
    final text = _displayOption(current);
    if (_editingText != text) {
      _updateDisplayText(
        TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        ),
      );
    }
    widget.onChanged!(current.value);
  }

  void _clearInput() {
    _updateDisplayText(
      const TextEditingValue(selection: TextSelection.collapsed(offset: 0)),
    );
    widget.onChanged?.call(null);
    if (_isOpen) {
      _editQuery();
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final l10n = YumeiroLocalizations.of(context);
    final metrics = YumeiroModalityScope.metricsOf(context);
    final action = _SelectClearAction.of(context);
    final clearable = action?.enabled ?? (widget.clearable && _editable);
    final clear = action != null
        ? action.button
        : clearable && _editingText.isNotEmpty
        ? yumeiroPickerClearButton(
            context,
            fieldLabel: widget.semanticLabel ?? widget.title ?? l10n.selectItem,
            dense: widget.dense,
            onPressed: _clearInput,
          )
        : null;

    final layout = LayoutBuilder(
      builder: (context, constraints) {
        final parentWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : null;
        final resolvedWidth = constraints.constrainWidth(
          widget.width ??
              (constraints.hasTightWidth ? parentWidth : null) ??
              (widget.expand ? parentWidth : null) ??
              (_autoWidth ??= widget._computeSearchableAutoWidth(
                context,
                theme,
                l10n,
              )),
        );

        if (metrics.isTouch) {
          final displayText = widget.displayText ?? _editingText;
          final isPlaceholder =
              widget.displayText == null && displayText.isEmpty;
          return YumeiroFormPickerTrigger(
            width: resolvedWidth,
            expand: true,
            icon: widget.icon ?? theme.icons.search,
            dense: widget.dense,
            enabled: _enabled,
            readOnly: widget.readOnly,
            hasError: widget.hasError,
            focusNode: _focusNode,
            autofocus: widget.autofocus,
            semanticLabel: widget.semanticLabel,
            isPlaceholder: isPlaceholder,
            textAlign: widget.textAlign,
            text: isPlaceholder
                ? (widget.placeholder ?? l10n.selectPlaceholder)
                : displayText,
            clearable: clearable,
            clearButton: clear,
            onOpen: _editable ? (_) => _chooseTouch() : null,
          );
        }

        return TapRegion(
          groupId: _tapGroup,
          onTapOutside: (_) {
            if (_isOpen) _focusNode.unfocus();
          },
          child: SizedBox(
            width: resolvedWidth,
            child: yumeiroFormPickerActions(
              context,
              maxWidth: resolvedWidth,
              dense: widget.dense,
              clearable: clearable,
              clearButton: clear,
              leadingExtent:
                  yumeiroPickerHorizontalPadding(metrics, widget.dense) +
                  (widget.icon == null
                      ? 0
                      : yumeiroPickerIconSize(theme, metrics, widget.dense) +
                            theme.spacing.sm) +
                  theme.spacing.sm,
              trigger: (clearExtent, chevronExtent) =>
                  OverlayPortal.overlayChildLayoutBuilder(
                    key: _triggerKey,
                    controller: _menu,
                    overlayLocation: widget.useRootNavigator
                        ? OverlayChildLocation.rootOverlay
                        : OverlayChildLocation.nearestOverlay,
                    overlayChildBuilder: _buildOptions,
                    child: TextFieldTapRegion(
                      child: Focus(
                        canRequestFocus: false,
                        skipTraversal: true,
                        includeSemantics: false,
                        onKeyEvent: _handlePointerKey,
                        child: MouseRegion(
                          cursor: _editable
                              ? SystemMouseCursors.text
                              : SystemMouseCursors.basic,
                          onEnter: (_) => setState(() => _isHovered = true),
                          onExit: (_) => setState(() => _isHovered = false),
                          child: _buildTrigger(
                            context,
                            theme,
                            l10n,
                            clearExtent: clearExtent,
                            chevronExtent: chevronExtent,
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
    return Focus(
      canRequestFocus: false,
      includeSemantics: false,
      onFocusChange: _handleControlFocusChange,
      child: layout,
    );
  }

  Future<void> _chooseTouch() async {
    if (_sheetOpen || !_editable) return;
    _sheetOpen = true;
    final session = ++_sheetSession;
    var query = '';
    final l10n = YumeiroLocalizations.of(context);
    try {
      final result = await YumeiroBottomSheet.show<Object>(
        context: context,
        controller: _sheetController,
        useRootNavigator: widget.useRootNavigator,
        builder: (sheetContext) => StatefulBuilder(
          builder: (context, update) {
            final title = widget.title ?? widget.tooltip ?? l10n.selectItem;
            final options = _filterItems(query);
            return SearchableSelectionSheet(
              title: title,
              hintText: widget.placeholder ?? l10n.searchOrSelectHint,
              onQueryChanged: (value) => update(() => query = value),
              onSubmitted: (value) {
                if (_selectionForText(value) case final result?) {
                  Navigator.of(sheetContext).pop(result);
                }
              },
              results: buildSearchSelectionResults<T>(
                key: ValueKey(query),
                options: options,
                values: {
                  for (final option in options)
                    if (option.value == widget.value) option.value,
                },
                revealSelection: query.isEmpty,
                optionLabel: widget.itemTextBuilder,
                emptyText: widget.emptyText,
                onSelected: (item) => Navigator.of(sheetContext).pop(item),
              ),
            );
          },
        ),
      );
      if (!mounted || session != _sheetSession || !_editable) return;
      if (result is YumeiroSelectionOption<T>) {
        _selectItem(result);
      } else if (result is String) {
        _onInputSubmitted(result);
      }
      if (mounted) setState(() {});
    } finally {
      _sheetOpen = false;
    }
  }

  Widget _buildTrigger(
    BuildContext context,
    YumeiroThemeExtension theme,
    YumeiroLocalizations l10n, {
    required double clearExtent,
    required double chevronExtent,
  }) {
    final metrics = YumeiroModalityScope.metricsOf(context);
    final height = yumeiroPickerMinHeight(context, metrics, widget.dense);
    final iconSize = yumeiroPickerIconSize(theme, metrics, widget.dense);
    final isFocused = _focusNode.hasFocus;
    final isReadOnly = _enabled && widget.readOnly;
    final triggerStates = <WidgetState>{
      if (!_enabled) WidgetState.disabled,
      if (isFocused) WidgetState.focused,
      if (_editable && _isHovered) WidgetState.hovered,
    };
    final triggerVisual = theme.visuals.control(
      YumeiroControlRole.neutral,
      triggerStates,
      yumeiroPickerErrorOverride(
        context,
        enabled: _enabled,
        hasError: widget.hasError,
      ),
    );
    final horizontalPadding = yumeiroPickerHorizontalPadding(
      metrics,
      widget.dense,
    );

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: height),
      child: YumeiroResolvedVisualSurface(
        appearance: triggerVisual,
        clipBehavior: Clip.antiAlias,
        padding: EdgeInsetsDirectional.only(
          start: horizontalPadding,
          end: isReadOnly ? horizontalPadding : 0,
        ),
        child: Row(
          children: [
            if (widget.icon != null) ...[
              Icon(
                widget.icon,
                size: iconSize,
                color: !_enabled
                    ? triggerVisual.foreground
                    : isFocused
                    ? theme.accent
                    : theme.muted,
              ),
              SizedBox(width: theme.spacing.sm),
            ],
            Expanded(
              child: Semantics(
                label:
                    widget.semanticLabel ??
                    widget.tooltip ??
                    widget.placeholder ??
                    l10n.searchOrSelectHint,
                hint: _editable ? l10n.searchFilterHint : null,
                child: TextField(
                  controller: _textController,
                  contextMenuBuilder: buildYumeiroTextEditingMenu,
                  focusNode: _focusNode,
                  autofocus: _enabled && widget.autofocus,
                  enabled: _enabled,
                  readOnly: isReadOnly,
                  textAlign: widget.textAlign,
                  textAlignVertical: TextAlignVertical.center,
                  cursorColor: theme.accent,
                  style: theme.typography
                      .input(dense: widget.dense)
                      .copyWith(color: triggerVisual.foreground),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    isDense: true,
                    filled: false,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: widget.placeholder ?? l10n.searchOrSelectHint,
                    hintStyle: theme.typography
                        .input(dense: widget.dense)
                        .copyWith(
                          color: _enabled
                              ? theme.subtle
                              : triggerVisual.foreground,
                        ),
                  ),
                  onChanged: _editable ? (_) => _editQuery() : null,
                  onTap: _editable ? _showMenu : null,
                  onSubmitted: _editable ? _submitPointer : null,
                ),
              ),
            ),
            if (clearExtent > 0) SizedBox(width: clearExtent),
            if (!isReadOnly)
              SizedBox(
                width: chevronExtent > 0
                    ? chevronExtent
                    : widget.dense
                    ? metrics.denseTargetSize
                    : metrics.minTargetSize,
                child: FocusTraversalGroup(
                  descendantsAreTraversable: false,
                  child: Semantics(
                    expanded: _isOpen,
                    child: YumeiroButton(
                      icon: _isOpen
                          ? theme.icons.chevronUp
                          : theme.icons.chevronDown,
                      tooltip: _isOpen ? l10n.hideOptions : l10n.showOptions,
                      dense: widget.dense,
                      visualOverride: _enabled
                          ? null
                          : const YumeiroVisualOverride(
                              base: YumeiroVisualDelta(opacity: 1),
                            ),
                      variant: YumeiroButtonVariant.ghost,
                      onPressed: _editable ? _toggleMenu : null,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptions(BuildContext context, OverlayChildLayoutInfo info) {
    if (!_isOpen) return const SizedBox.shrink();
    final anchor = MatrixUtils.transformRect(
      info.childPaintTransform,
      Offset.zero & info.childSize,
    );
    if (!anchor.isFinite || anchor.isEmpty) return const SizedBox.shrink();
    final media = MediaQuery.of(context);
    final theme = YumeiroTheme.of(context);
    final l10n = YumeiroLocalizations.of(context);
    final rows = _filterItems(_editingText);
    final enabled = _enabledIndices(rows);
    final active = enabled.isEmpty
        ? null
        : enabled[_highlighted.clamp(0, enabled.length - 1)];
    final width =
        widget.menuWidth ??
        (widget.menuAutoWidth
            ? (_autoWidth ??= widget._computeSearchableAutoWidth(
                context,
                theme,
                l10n,
              ))
            : anchor.width);
    final rowHeight = selectionMenuRowHeight(
      context,
      rows,
      dense: widget.dense,
    );
    return Positioned.fill(
      child: PickerOverlayLayout(
        anchor: anchor,
        width: width,
        maxHeight:
            rowHeight * widget.maxVisibleItems +
            selectionMenuSurfacePadding.vertical,
        preferLargerSide: true,
        padding: media.viewPadding.copyWith(
          bottom: math.max(media.viewPadding.bottom, media.viewInsets.bottom),
        ),
        child: TapRegion(
          groupId: _tapGroup,
          child: TextFieldTapRegion(
            child: ExcludeFocus(
              child: PickerFloatingSurface(
                padding: selectionMenuSurfacePadding,
                visualOverride: widget.menuVisualOverride,
                child: rows.isEmpty
                    ? SingleChildScrollView(
                        padding: EdgeInsets.all(theme.spacing.sm),
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            widget.emptyText ?? l10n.noResults,
                            style: theme.typography.supporting.copyWith(
                              color: theme.muted,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemExtent: rowHeight,
                        itemCount: rows.length,
                        itemBuilder: (_, index) {
                          final item = rows[index];
                          return Padding(
                            padding: selectionMenuRowInsets,
                            child: SelectionMenuRow<T>(
                              option: item,
                              selected: item.value == widget.value,
                              highlighted: index == active,
                              dense: widget.dense,
                              showCheckmark: true,
                              textAlign: widget.textAlign,
                              onPressed: () => _selectItem(item),
                              displayLabel: widget.itemTextBuilder?.call(item),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
