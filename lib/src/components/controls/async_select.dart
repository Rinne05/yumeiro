import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart'
    show KeyDownEvent, KeyEvent, KeyRepeatEvent, LogicalKeyboardKey;
import 'package:material_ui/material_ui.dart';

import '../../foundation/modality.dart';
import '../../l10n/localizations.dart';
import '../../primitives/visual_scope.dart';
import '../../theme/theme.dart';
import '../../theme/visual_role.dart';
import '../display/callouts.dart';
import '../display/loading.dart';
import '../overlays/dialogs.dart';
import '../overlays/picker_overlay.dart';
import '../overlays/sheets.dart';
import 'buttons.dart';
import 'form_picker_trigger.dart';
import 'inputs.dart';
import 'selection_menu_row.dart';

/// Selects one remote option and displays its label independently of results.
///
/// Pointer users type directly in the field. Touch users search in a sheet.
/// Selection and clearing report changes to the caller, who owns [value].
class YumeiroAsyncSelect<T extends Object> extends StatefulWidget {
  const YumeiroAsyncSelect({
    super.key,
    required this.value,
    required this.loadOptions,
    required this.onChanged,
    this.sourceKey,
    this.semanticLabel,
    this.placeholder,
    this.title,
    this.searchHint,
    this.loadErrorText,
    this.debounce = const Duration(milliseconds: 250),
    this.width,
    this.expand = true,
    this.dense = false,
    this.enabled = true,
    this.readOnly = false,
    this.clearable = false,
    this.focusNode,
    this.autofocus = false,
    this.hasError = false,
    this.useRootNavigator = true,
  });

  /// Registers a remote selection with the enclosing Flutter [Form].
  ///
  /// The field retains the selected option even when it is absent from the
  /// search results. Read its `value` property to save the entity identifier.
  static FormField<YumeiroSelectionOption<V>> form<V extends Object>({
    Key? key,
    required Future<List<YumeiroSelectionOption<V>>> Function(String)
    loadOptions,
    Object? sourceKey,
    YumeiroSelectionOption<V>? initialValue,
    FormFieldSetter<YumeiroSelectionOption<V>>? onSaved,
    VoidCallback? onReset,
    FormFieldValidator<YumeiroSelectionOption<V>>? validator,
    AutovalidateMode? autovalidateMode,
    String? forceErrorText,
    bool enabled = true,
    ValueChanged<YumeiroSelectionOption<V>?>? onChanged,
    String? label,
    String? helperText,
    bool required = false,
    String? semanticLabel,
    String? placeholder,
    String? title,
    String? searchHint,
    String? loadErrorText,
    Duration debounce = const Duration(milliseconds: 250),
    double? width,
    bool expand = true,
    bool dense = false,
    bool readOnly = false,
    bool clearable = false,
    FocusNode? focusNode,
    bool autofocus = false,
    bool useRootNavigator = true,
  }) {
    assert(!debounce.isNegative);
    return _AsyncSelectFormField<V>(
      key: key,
      initialValue: initialValue,
      onSaved: onSaved,
      onReset: onReset,
      validator: validator,
      autovalidateMode: autovalidateMode,
      forceErrorText: forceErrorText,
      enabled: enabled,
      builder: (state) {
        final field = state as _AsyncSelectFormFieldState<V>;
        final name =
            semanticLabel ??
            label ??
            title ??
            YumeiroLocalizations.of(state.context).selectItem;
        return YumeiroFieldLayout(
          label: label,
          semanticLabel: '',
          required: required,
          helperText: helperText,
          errorText: state.errorText,
          dense: dense,
          crossAxisAlignment: expand && width == null
              ? CrossAxisAlignment.stretch
              : CrossAxisAlignment.start,
          child: YumeiroAsyncSelect<V>(
            key: field._pickerKey,
            value: field.value,
            loadOptions: loadOptions,
            sourceKey: sourceKey,
            onChanged: (choice) {
              field.didChange(choice);
              onChanged?.call(choice);
            },
            semanticLabel: name,
            placeholder: placeholder,
            title: title ?? label,
            searchHint: searchHint,
            loadErrorText: loadErrorText,
            debounce: debounce,
            width: width,
            expand: expand,
            dense: dense,
            enabled: enabled,
            readOnly: readOnly,
            clearable: clearable,
            focusNode: focusNode,
            autofocus: autofocus,
            hasError: state.hasError,
            useRootNavigator: useRootNavigator,
          ),
        );
      },
    );
  }

  /// The selected option. Its label remains available between searches.
  final YumeiroSelectionOption<T>? value;

  /// Receives a trimmed query, including the empty query on opening. Results
  /// must have unique values. A thrown exception offers a retry.
  final Future<List<YumeiroSelectionOption<T>>> Function(String) loadOptions;

  /// Reports a selected option, or null on clear. Null disables editing.
  final ValueChanged<YumeiroSelectionOption<T>?>? onChanged;

  /// Source identity or revision. Changing it closes the active search and
  /// discards in-flight responses without clearing [value].
  final Object? sourceKey;
  final String? semanticLabel;
  final String? placeholder;
  final String? title;
  final String? searchHint;

  /// Replaces the localized failure message. Exceptions are kept internal.
  final String? loadErrorText;

  /// Delay for user edits. Opening and retry load immediately.
  final Duration debounce;

  /// Width of the control. The pointer popup follows the measured trigger.
  final double? width;
  final bool expand;
  final bool dense;
  final bool enabled;
  final bool readOnly;
  final bool clearable;

  /// The caller owns this node when supplied.
  final FocusNode? focusNode;

  final bool autofocus;
  final bool hasError;

  /// Uses the root navigator or overlay. Set false for the nearest one.
  final bool useRootNavigator;

  @override
  State<YumeiroAsyncSelect<T>> createState() => _YumeiroAsyncSelectState<T>();
}

class _AsyncSelectFormField<T extends Object>
    extends FormField<YumeiroSelectionOption<T>> {
  const _AsyncSelectFormField({
    super.key,
    super.initialValue,
    super.onSaved,
    super.onReset,
    super.validator,
    super.autovalidateMode,
    super.forceErrorText,
    super.enabled,
    required super.builder,
  });

  @override
  FormFieldState<YumeiroSelectionOption<T>> createState() =>
      _AsyncSelectFormFieldState<T>();
}

class _AsyncSelectFormFieldState<T extends Object>
    extends FormFieldState<YumeiroSelectionOption<T>> {
  final _pickerKey = GlobalKey<_YumeiroAsyncSelectState<T>>();

  @override
  void didChange(YumeiroSelectionOption<T>? value) {
    _pickerKey.currentState?._invalidatePicker();
    super.didChange(value);
  }

  @override
  void reset() {
    _pickerKey.currentState?._invalidatePicker();
    super.reset();
  }
}

class _YumeiroAsyncSelectState<T extends Object>
    extends State<YumeiroAsyncSelect<T>> {
  final _ownedFocusNode = FocusNode(debugLabel: 'YumeiroAsyncSelect input');
  final _text = TextEditingController();
  final _scroll = ScrollController();
  final _portal = OverlayPortalController();
  final _triggerKey = GlobalKey();
  late final _anchorVisibility = PickerAnchorVisibility(
    anchorContext: () => _triggerKey.currentContext,
    onHidden: () => _focus.unfocus(),
  );
  final _tapGroup = Object();
  final _sheet = YumeiroSheetController();
  late final _search = _RemoteSearch<T>((query) => widget.loadOptions(query));

  bool? _touch;
  bool _pointerOpen = false;
  bool _sheetOpen = false;
  int _session = 0;
  int _highlightedIndex = -1;

  FocusNode get _focus => widget.focusNode ?? _ownedFocusNode;
  bool get _editable =>
      widget.enabled && !widget.readOnly && widget.onChanged != null;

  @override
  void initState() {
    super.initState();
    _restoreLabel();
    _focus.addListener(_onFocusChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final touch = YumeiroModalityScope.metricsOf(context).isTouch;
    if (_touch != null && _touch != touch) {
      _invalidatePicker(duringBuild: true);
    }
    _touch = touch;
    if (_pointerOpen) _anchorVisibility.track(context);
  }

  @override
  void didUpdateWidget(covariant YumeiroAsyncSelect<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final focusChanged = oldWidget.focusNode != widget.focusNode;
    if (focusChanged) {
      (oldWidget.focusNode ?? _ownedFocusNode).removeListener(_onFocusChanged);
      _focus.addListener(_onFocusChanged);
    }
    if (!_editable ||
        oldWidget.useRootNavigator != widget.useRootNavigator ||
        oldWidget.sourceKey != widget.sourceKey ||
        oldWidget.value?.value != widget.value?.value ||
        focusChanged) {
      _invalidatePicker(duringBuild: true);
    }
    if (!_pointerOpen) _restoreLabel();
  }

  @override
  void dispose() {
    _session++;
    _focus.removeListener(_onFocusChanged);
    _anchorVisibility.track(null);
    _sheet.close();
    _search.dispose();
    _scroll.dispose();
    _text.dispose();
    _ownedFocusNode.dispose();
    super.dispose();
  }

  void _invalidatePicker({bool duringBuild = false}) {
    _session++;
    if (_pointerOpen) {
      _closePointer(duringBuild: duringBuild);
    } else {
      _search.stop();
    }
    _sheet.close();
  }

  void _restoreLabel() {
    final label = widget.value?.label ?? '';
    if (_text.text != label || _focus.hasFocus) {
      _text.value = TextEditingValue(
        text: label,
        selection: TextSelection(baseOffset: 0, extentOffset: label.length),
      );
    }
  }

  void _onFocusChanged() {
    if (_touch != false) return;
    if (_focus.hasFocus) {
      _openPointer();
    } else {
      _closePointer();
    }
  }

  void _openPointer({String? query}) {
    if (!_editable || _pointerOpen) return;
    setState(() => _pointerOpen = true);
    if (query == null) _text.clear();
    _runSearch(
      query ?? '',
      delay: query == null ? Duration.zero : widget.debounce,
    );
    _portal.show();
    _anchorVisibility.track(context);
  }

  void _closePointer({bool duringBuild = false}) {
    if (!_pointerOpen) return;
    _pointerOpen = false;
    _anchorVisibility.track(null);
    _search.stop();
    _restoreLabel();
    if (duringBuild) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_pointerOpen) _portal.hide();
      });
    } else {
      _portal.hide();
      setState(() {});
    }
  }

  void _runSearch(String query, {required Duration delay}) {
    _highlightedIndex = -1;
    if (_scroll.hasClients) _scroll.jumpTo(0);
    _search.run(query.trim(), delay: delay);
  }

  void _onPointerEdit(String query) {
    if (!_editable) return;
    if (!_pointerOpen) {
      _openPointer(query: query);
    } else if (_search.query != query.trim()) {
      _runSearch(query, delay: widget.debounce);
    }
  }

  void _choosePointer(YumeiroSelectionOption<T> option, int revision) {
    if (!_pointerOpen || !_editable || !_search.canChoose(option, revision)) {
      return;
    }
    _closePointer();
    widget.onChanged?.call(option);
  }

  YumeiroSelectionOption<T>? get _highlighted {
    final options = _search.options;
    if (_highlightedIndex >= 0 && _highlightedIndex < options.length) {
      return options[_highlightedIndex];
    }
    return options.where((option) => option.enabled).firstOrNull;
  }

  void _submitPointer() {
    if (!_pointerOpen) return;
    if (_search.isPending || _search.status == _SearchStatus.failed) {
      _runSearch(_search.query, delay: Duration.zero);
    } else if (_highlighted case final option?) {
      _choosePointer(option, _search.revision);
    }
  }

  KeyEventResult _handlePointerKey(BuildContext context, KeyEvent event) {
    if (!_editable || (event is! KeyDownEvent && event is! KeyRepeatEvent)) {
      return KeyEventResult.ignored;
    }
    final composing = _text.value.composing;
    if (composing.isValid && !composing.isCollapsed) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowUp) {
      if (!_pointerOpen) {
        _openPointer();
      } else {
        _moveHighlight(context, key == LogicalKeyboardKey.arrowDown ? 1 : -1);
      }
      return KeyEventResult.handled;
    }
    if (!_pointerOpen) return KeyEventResult.ignored;
    if (key == LogicalKeyboardKey.escape) {
      _closePointer();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      if (event is KeyDownEvent) _submitPointer();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _moveHighlight(BuildContext context, int direction) {
    final options = _search.options;
    if (options.isEmpty) return;
    var index = options.indexOf(_highlighted ?? options.first);
    for (var offset = 0; offset < options.length; offset++) {
      index = (index + direction) % options.length;
      if (!options[index].enabled) continue;
      setState(() => _highlightedIndex = index);
      if (_scroll.hasClients) {
        final rowHeight = _rowHeight(context, options);
        final position = _scroll.position;
        final top = rowHeight * index;
        final bottom = top + rowHeight;
        final next = top < position.pixels
            ? top
            : math.max(position.pixels, bottom - position.viewportDimension);
        final bounded = next.clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        );
        if (position.pixels != bounded) _scroll.jumpTo(bounded);
      }
      return;
    }
  }

  Future<void> _openTouch(BuildContext origin) async {
    if (_sheetOpen || !_editable) return;
    _sheetOpen = true;
    final session = ++_session;
    final l10n = YumeiroLocalizations.of(origin);
    final title = widget.title ?? l10n.selectItem;
    final selected = widget.value?.value;
    final searchHint = widget.searchHint;
    final loadErrorText = widget.loadErrorText;
    _search.run('', delay: Duration.zero);
    try {
      final result = await YumeiroBottomSheet.show<YumeiroSelectionOption<T>>(
        context: origin,
        controller: _sheet,
        useRootNavigator: widget.useRootNavigator,
        builder: (context) => _AsyncTouchPanel<T>(
          title: title,
          value: selected,
          search: _search,
          searchHint: searchHint,
          loadErrorText: loadErrorText,
          onQueryChanged: (query) {
            if (session == _session && _editable) {
              _search.run(query, delay: widget.debounce);
            }
          },
          onSubmitted: (query) {
            if (session == _session &&
                _editable &&
                (_search.query != query || _search.isPending)) {
              _search.run(query, delay: Duration.zero);
            }
          },
        ),
      );
      if (mounted && session == _session && _editable && result != null) {
        widget.onChanged?.call(result);
      }
    } finally {
      _sheetOpen = false;
      if (mounted && session == _session) _search.stop();
    }
  }

  Widget _buildPointerTrigger(
    BuildContext context, {
    required double width,
    required double clearExtent,
    required double chevronExtent,
  }) {
    final theme = YumeiroTheme.of(context);
    final metrics = YumeiroModalityScope.metricsOf(context);
    final l10n = YumeiroLocalizations.of(context);
    final visualScope = YumeiroVisualScope.maybeOf(context);
    final iconSize = yumeiroPickerIconSize(theme, metrics, widget.dense);
    final horizontalPadding = yumeiroPickerHorizontalPadding(
      metrics,
      widget.dense,
    );
    final inputChrome = 2 * horizontalPadding + theme.spacing.sm;
    final actionSpace = clearExtent == 0
        ? 0.0
        : clearExtent + chevronExtent - horizontalPadding - iconSize;
    return Focus(
      canRequestFocus: false,
      onKeyEvent: (node, event) => _handlePointerKey(context, event),
      child: OverlayPortal.overlayChildLayoutBuilder(
        overlayLocation: widget.useRootNavigator
            ? OverlayChildLocation.rootOverlay
            : OverlayChildLocation.nearestOverlay,
        controller: _portal,
        overlayChildBuilder: _buildPointerOverlay,
        child: TapRegion(
          key: _triggerKey,
          groupId: _tapGroup,
          onTapInside: (_) {
            if (!_editable) return;
            _focus.requestFocus();
            _openPointer();
          },
          onTapOutside: (_) => _closePointer(),
          child: Semantics(
            expanded: _editable ? _pointerOpen : null,
            child: YumeiroVisualScope(
              controlRole:
                  visualScope?.controlRole ?? YumeiroControlRole.secondary,
              visualOverride: visualScope?.visualOverride,
              child: YumeiroTextField(
                controller: _text,
                focusNode: _focus,
                autofocus: widget.autofocus && widget.enabled,
                enabled: widget.enabled && (widget.readOnly || _editable),
                readOnly: widget.readOnly,
                semanticLabel: widget.semanticLabel,
                hintText: _pointerOpen
                    ? widget.searchHint ?? l10n.searchHint
                    : widget.placeholder ?? l10n.selectPlaceholder,
                dense: widget.dense,
                hasError: widget.hasError,
                trailing: widget.readOnly
                    ? null
                    : Padding(
                        padding: EdgeInsetsDirectional.only(start: actionSpace),
                        child: ExcludeSemantics(
                          child: Icon(
                            theme.icons.chevronDown,
                            size: math.min(
                              iconSize,
                              math.max(0.0, width - actionSpace - inputChrome),
                            ),
                            color: theme.muted,
                          ),
                        ),
                      ),
                textInputAction: TextInputAction.search,
                onEditingComplete: () {},
                onChanged: _onPointerEdit,
                onSubmitted: (_) => _submitPointer(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _rowHeight(
    BuildContext context,
    List<YumeiroSelectionOption<T>> options,
  ) => selectionMenuRowHeight(context, options, dense: widget.dense);

  Widget _buildPointerOverlay(
    BuildContext context,
    OverlayChildLayoutInfo info,
  ) {
    if (!_pointerOpen) return const SizedBox.shrink();
    final media = MediaQuery.of(context);
    final anchor = MatrixUtils.transformRect(
      info.childPaintTransform,
      Offset.zero & info.childSize,
    );
    if (!anchor.isFinite || anchor.isEmpty) return const SizedBox.shrink();
    final padding = media.viewPadding.copyWith(
      bottom: math.max(media.viewPadding.bottom, media.viewInsets.bottom),
    );
    return Positioned.fill(
      child: PickerOverlayLayout(
        anchor: anchor,
        maxHeight: 280,
        minHeight: 42,
        padding: padding,
        child: TapRegion(
          groupId: _tapGroup,
          child: TextFieldTapRegion(
            child: ExcludeFocus(
              child: PickerFloatingSurface(
                padding: selectionMenuSurfacePadding,
                child: _AsyncResults<T>(
                  search: _search,
                  loadErrorText: widget.loadErrorText,
                  builder: (context, options) {
                    final revision = _search.revision;
                    final highlighted = _highlighted;
                    return ListView.builder(
                      controller: _scroll,
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemExtent: _rowHeight(context, options),
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options[index];
                        return _pointerOption(
                          option,
                          highlighted: identical(option, highlighted),
                          revision: revision,
                        );
                      },
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

  Widget _pointerOption(
    YumeiroSelectionOption<T> option, {
    required bool highlighted,
    required int revision,
  }) => Padding(
    padding: selectionMenuRowInsets,
    child: SelectionMenuRow<T>(
      option: option,
      selected: option.value == widget.value?.value,
      highlighted: highlighted,
      dense: widget.dense,
      showCheckmark: true,
      onPressed: () => _choosePointer(option, revision),
    ),
  );

  @override
  Widget build(BuildContext context) {
    assert(!widget.debounce.isNegative);
    final l10n = YumeiroLocalizations.of(context);
    final name = widget.semanticLabel ?? widget.title ?? l10n.selectItem;
    final clearable = widget.clearable && _editable;
    final clearButton = clearable && widget.value != null
        ? yumeiroPickerClearButton(
            context,
            fieldLabel: name,
            dense: widget.dense,
            onPressed: () {
              _invalidatePicker();
              widget.onChanged?.call(null);
            },
          )
        : null;
    if (_touch == true) {
      return Semantics(
        label: widget.semanticLabel,
        child: YumeiroFormPickerTrigger(
          text:
              widget.value?.label ??
              widget.placeholder ??
              l10n.selectPlaceholder,
          isPlaceholder: widget.value == null,
          enabled: widget.enabled && (widget.readOnly || _editable),
          readOnly: widget.readOnly,
          hasError: widget.hasError,
          dense: widget.dense,
          width: widget.width,
          expand: widget.expand || widget.width != null,
          focusNode: _focus,
          autofocus: widget.autofocus,
          onOpen: _openTouch,
          clearable: clearable,
          clearButton: clearButton,
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = YumeiroModalityScope.metricsOf(context);
        final width = constraints.constrainWidth(
          widget.width ??
              (widget.expand && constraints.hasBoundedWidth
                  ? constraints.maxWidth
                  : 240),
        );
        return SizedBox(
          width: width,
          child: yumeiroFormPickerActions(
            context,
            maxWidth: width,
            dense: widget.dense,
            clearable: clearable,
            clearButton: clearButton,
            leadingExtent:
                yumeiroPickerHorizontalPadding(metrics, widget.dense) +
                YumeiroTheme.of(context).spacing.sm,
            trigger: (clearExtent, chevronExtent) => _buildPointerTrigger(
              context,
              width: width,
              clearExtent: clearExtent,
              chevronExtent: chevronExtent,
            ),
          ),
        );
      },
    );
  }
}

enum _SearchStatus { idle, loading, ready, failed }

class _RemoteSearch<T extends Object> extends ChangeNotifier {
  _RemoteSearch(this._loadOptions);

  final Future<List<YumeiroSelectionOption<T>>> Function(String) _loadOptions;
  Timer? _timer;
  var _revision = 0;
  var _query = '';
  var _status = _SearchStatus.idle;
  List<YumeiroSelectionOption<T>> _options = const [];

  String get query => _query;
  int get revision => _revision;
  _SearchStatus get status => _status;
  List<YumeiroSelectionOption<T>> get options => _options;
  bool get isPending => _timer?.isActive ?? false;

  void run(String query, {required Duration delay}) {
    stop();
    _query = query;
    _status = _SearchStatus.loading;
    final revision = _revision;
    notifyListeners();
    if (delay == Duration.zero) {
      unawaited(_load(query, revision));
    } else {
      _timer = Timer(delay, () => unawaited(_load(query, revision)));
    }
  }

  Future<void> _load(String query, int revision) async {
    try {
      final options = await _loadOptions(query);
      if (_revision != revision) return;
      _options = List.unmodifiable(options);
      _status = _SearchStatus.ready;
    } catch (_) {
      if (_revision != revision) return;
      _status = _SearchStatus.failed;
    }
    notifyListeners();
  }

  bool canChoose(YumeiroSelectionOption<T> option, int revision) =>
      _revision == revision &&
      _status == _SearchStatus.ready &&
      option.enabled &&
      _options.contains(option);

  void stop() {
    _timer?.cancel();
    _timer = null;
    _revision++;
    _status = _SearchStatus.idle;
    _options = const [];
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}

class _AsyncResults<T extends Object> extends StatelessWidget {
  const _AsyncResults({
    required this.search,
    required this.loadErrorText,
    required this.builder,
  });

  final _RemoteSearch<T> search;
  final String? loadErrorText;
  final Widget Function(BuildContext, List<YumeiroSelectionOption<T>>) builder;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: search,
    builder: (context, _) {
      final l10n = YumeiroLocalizations.of(context);
      final theme = YumeiroTheme.of(context);
      final status = search.status;
      if (status == _SearchStatus.idle) return const SizedBox.shrink();
      if (status == _SearchStatus.ready && search.options.isNotEmpty) {
        return builder(context, search.options);
      }
      return SingleChildScrollView(
        padding: EdgeInsets.all(theme.spacing.sm),
        child: switch (status) {
          _SearchStatus.loading => YumeiroSpinner(label: l10n.loading),
          _SearchStatus.failed => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: theme.spacing.xs,
            children: [
              YumeiroCallout(
                message: loadErrorText ?? l10n.actionFailed,
                statusRole: YumeiroStatusRole.danger,
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: YumeiroButton(
                  label: l10n.retry,
                  dense: true,
                  onPressed: () {
                    if (search.status == _SearchStatus.failed) {
                      search.run(search.query, delay: Duration.zero);
                    }
                  },
                ),
              ),
            ],
          ),
          _ => Semantics(
            liveRegion: true,
            child: Text(
              l10n.noResults,
              style: theme.typography.supporting.copyWith(color: theme.muted),
            ),
          ),
        },
      );
    },
  );
}

class _AsyncTouchPanel<T extends Object> extends StatelessWidget {
  const _AsyncTouchPanel({
    required this.title,
    required this.value,
    required this.search,
    required this.searchHint,
    required this.loadErrorText,
    required this.onQueryChanged,
    required this.onSubmitted,
  });

  final String title;
  final T? value;
  final _RemoteSearch<T> search;
  final String? searchHint;
  final String? loadErrorText;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final l10n = YumeiroLocalizations.of(context);
    return SearchableSelectionSheet(
      title: title,
      hintText: searchHint ?? l10n.searchHint,
      onQueryChanged: (text) {
        final query = text.trim();
        if (query != search.query) onQueryChanged(query);
      },
      onSubmitted: (text) => onSubmitted(text.trim()),
      results: _AsyncResults<T>(
        search: search,
        loadErrorText: loadErrorText,
        builder: (context, options) {
          final revision = search.revision;
          return buildSheetSelectionList<T>(
            options: options,
            values: {?value},
            onSelected: (option) {
              if (search.canChoose(option, revision)) {
                Navigator.of(context).pop(option);
              }
            },
          );
        },
      ),
    );
  }
}
