import 'dart:math' as math;

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, listEquals;
import 'package:flutter/services.dart'
    show
        HardwareKeyboard,
        KeyDownEvent,
        KeyEvent,
        KeyRepeatEvent,
        LogicalKeyboardKey;
import 'package:material_ui/material_ui.dart';

import '../../foundation/modality.dart';
import '../../l10n/localizations.dart';
import '../../primitives/visual_scope.dart';
import '../../primitives/visual_surface.dart';
import '../../theme/semantic_visuals.dart';
import '../../theme/theme.dart';
import '../../theme/theme_extension.dart';
import '../../theme/visual_role.dart';
import '../overlays/dialogs.dart';
import '../overlays/picker_overlay.dart';
import '../overlays/sheets.dart'
    show
        SearchableSelectionSheet,
        YumeiroBottomSheet,
        buildMenuSelectionList,
        buildSearchSelectionResults,
        presentSingleSelectionSheet;
import '../overlays/tooltip.dart';
import 'buttons.dart';
import 'form_picker_trigger.dart';
import 'inputs.dart';
import 'select_trigger.dart';
import 'selection_menu_row.dart';
import 'selection_option.dart';
import 'text_editing_menu.dart';

part 'dropdown.dart';
part 'select_form_field.dart';

/// Unified choice selector adapting its picker presentation to [YumeiroModality]:
/// - `pointer`: anchored floating menu ([YumeiroSurfaceRole.floating])
/// - `touch`: modal bottom sheet list ([YumeiroSurfaceRole.modal])
class YumeiroSelect<T> extends StatefulWidget {
  const YumeiroSelect({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.placeholder,
    this.title,
    this.width,
    this.menuWidth,
    this.menuAutoWidth = false,
    this.maxWidth = 320.0,
    this.expand = false,
    this.dense = false,
    this.enabled = true,
    this.readOnly = false,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
    this.hasError = false,
    this.useRootNavigator = true,
  });

  /// A select whose pointer menu supports custom toolbar trigger content and
  /// layout. On touch it opens a selection sheet.
  ///
  /// [displayText] takes precedence over [selectedLabelBuilder] and the label
  /// of the selected option. Option labels in the menu remain independent.
  /// [onChanged] receives the chosen option's value. Use a nullable type
  /// argument for a menu that includes an option whose value is null.
  const factory YumeiroSelect.menu({
    Key? key,
    required T? value,
    required List<YumeiroSelectionOption<T>> options,
    required ValueChanged<T>? onChanged,
    String? placeholder,
    IconData? icon,
    IconData? trailingIcon,
    bool showTrailingIcon,
    double? width,
    double? menuWidth,
    bool menuAutoWidth,
    double maxWidth,
    bool expand,
    Widget? child,
    bool dense,
    String? tooltip,
    String? title,
    bool enabled,
    bool readOnly,
    FocusNode? focusNode,
    bool autofocus,
    String? semanticLabel,
    bool hasError,
    bool useRootNavigator,
    TextAlign textAlign,
    PopupMenuPosition position,
    bool centerMenu,
    Offset? offset,
    YumeiroVisualOverride? menuVisualOverride,
    int? maxVisibleItems,
    bool selected,
    String? displayText,
    String Function(YumeiroSelectionOption<T> item)? selectedLabelBuilder,
  }) = _MenuSelect<T>;

  /// Creates a filterable dropdown with an editable trigger on pointer devices
  /// and a search field inside the picker on touch devices.
  ///
  /// The editor keeps an in-progress query while focused. It uses [initialText]
  /// only when first mounted and [value] has no matching option.
  /// [displayText] overrides the resting trigger text. It does not change the
  /// editable query, option labels, or submitted values.
  /// [itemTextBuilder] overrides an option's trigger text and participates in
  /// default matching. [filter] overrides the list filter for nonempty queries.
  ///
  /// On pointer devices, scrolling the input fully out of view closes its menu
  /// and Enter selects the highlighted enabled option when the menu is open.
  /// Queries with no matches show their message in the anchored menu without
  /// changing the field's size.
  /// Otherwise, submission checks for an exact enabled option match.
  /// [onChanged] receives enabled option values and null on clear. Passing
  /// null disables the picker. [onFreeTextSubmitted] opts into submitting
  /// trimmed, nonempty text that matches no option. Text matching only
  /// disabled options is rejected. A string [value] outside the option list
  /// can be displayed when free-text submission is enabled.
  ///
  /// Set [clearable] to false to prevent clearing the selected value. The
  /// touch picker's separate search query can still be cleared.
  ///
  /// The popup matches the trigger width by default. When [menuWidth] is null,
  /// [menuAutoWidth] sizes the popup to its content up to [maxWidth], which
  /// defaults to 320. [maxVisibleItems] defaults to 5 and [textAlign] defaults
  /// to [TextAlign.start].
  const factory YumeiroSelect.searchable({
    Key? key,
    required List<YumeiroSelectionOption<T>> options,
    T? value,
    String? initialText,
    required ValueChanged<T?>? onChanged,
    ValueChanged<String>? onFreeTextSubmitted,
    bool clearable,
    String? placeholder,
    IconData? icon,
    double? width,
    double? menuWidth,
    bool menuAutoWidth,
    double maxWidth,
    bool expand,
    bool dense,
    int maxVisibleItems,
    TextAlign textAlign,
    String? displayText,
    String? emptyText,
    bool Function(YumeiroSelectionOption<T> item, String query)? filter,
    String Function(YumeiroSelectionOption<T> item)? itemTextBuilder,
    String? tooltip,
    String? title,
    bool enabled,
    bool readOnly,
    FocusNode? focusNode,
    bool autofocus,
    String? semanticLabel,
    bool hasError,
    bool useRootNavigator,
    YumeiroVisualOverride? menuVisualOverride,
  }) = _SearchableSelect<T>;

  /// Creates a select that participates in Flutter [Form] validation, saving,
  /// and resetting. A reset restores [initialValue].
  ///
  /// [required] marks the label. Use [validator] to require a selection.
  /// [onChanged] reports user changes after the field updates. When [clearable]
  /// is enabled, clearing reports null. Use [onReset] to observe a reset.
  /// Set [searchable] to let users filter the supplied options in place.
  static FormField<V> form<V extends Object>({
    Key? key,
    required List<YumeiroSelectionOption<V>> options,
    V? initialValue,
    FormFieldSetter<V>? onSaved,
    VoidCallback? onReset,
    FormFieldValidator<V>? validator,
    AutovalidateMode? autovalidateMode,
    String? forceErrorText,
    bool enabled = true,
    ValueChanged<V?>? onChanged,
    String? label,
    String? helperText,
    bool required = false,
    String? semanticLabel,
    String? placeholder,
    String? title,
    double? width,
    double? menuWidth,
    bool menuAutoWidth = false,
    double maxWidth = 320,
    bool expand = true,
    bool dense = false,
    bool readOnly = false,
    bool clearable = false,
    bool searchable = false,
    FocusNode? focusNode,
    bool autofocus = false,
    bool useRootNavigator = true,
  }) => _YumeiroSelectFormField<V>(
    key: key,
    options: options,
    initialValue: initialValue,
    onSaved: onSaved,
    onReset: onReset,
    validator: validator,
    autovalidateMode: autovalidateMode,
    forceErrorText: forceErrorText,
    enabled: enabled,
    onChanged: onChanged,
    label: label,
    helperText: helperText,
    required: required,
    semanticLabel: semanticLabel,
    placeholder: placeholder,
    title: title,
    width: width,
    menuWidth: menuWidth,
    menuAutoWidth: menuAutoWidth,
    maxWidth: maxWidth,
    expand: expand,
    dense: dense,
    readOnly: readOnly,
    clearable: clearable,
    searchable: searchable,
    focusNode: focusNode,
    autofocus: autofocus,
    useRootNavigator: useRootNavigator,
  );

  final List<YumeiroSelectionOption<T>> options;

  /// Value selected by the caller. An unmatched value shows the placeholder.
  final T? value;

  /// Reports an enabled option selected by the user. Null disables the picker.
  final ValueChanged<T>? onChanged;
  final String? placeholder;
  final String? title;
  final double? width;
  final double? menuWidth;

  /// When `true` and [menuWidth] is null, sizes the popup menu to content
  /// (capped at [maxWidth]) instead of matching the trigger width.
  final bool menuAutoWidth;
  final double maxWidth;
  final bool expand;
  final bool dense;

  /// Allows interaction when [onChanged] is supplied.
  final bool enabled;

  /// Displays the selection as a focusable readout without opening the picker.
  final bool readOnly;

  /// Caller-owned focus node for the trigger.
  final FocusNode? focusNode;
  final bool autofocus;

  /// Accessible name for the trigger. The visible selection becomes its value
  /// when specified.
  final String? semanticLabel;

  /// Highlights the enabled trigger's outline to show a validation error.
  final bool hasError;

  /// Set to false to open the picker on the nearest navigator in either mode.
  final bool useRootNavigator;

  bool get _canOpenFixedPicker =>
      enabled && !readOnly && onChanged != null && options.isNotEmpty;

  String? get _fixedSheetTitle => title;
  bool get _fixedSheetSearchable => false;

  bool _closesFixedPicker(YumeiroSelect<T> previous) =>
      !_canOpenFixedPicker || previous.useRootNavigator != useRootNavigator;

  bool _updatesFixedPicker(YumeiroSelect<T> previous) =>
      !listEquals(previous.options, options) ||
      previous.value != value ||
      previous.dense != dense ||
      previous._fixedSheetTitle != _fixedSheetTitle;

  void _acceptFixedOption(YumeiroSelectionOption<T>? option) {
    if (_canOpenFixedPicker &&
        option != null &&
        options.any((item) => item.enabled && item.value == option.value)) {
      onChanged!(option.value);
    }
  }

  @override
  State<YumeiroSelect<T>> createState() => _YumeiroSelectState<T>();
}

Future<YumeiroSelectionOption<T>?> _showFixedOptionsSheet<T>({
  required BuildContext context,
  required YumeiroSheetController controller,
  required YumeiroSelect<T> Function() select,
  Rect? Function()? anchor,
}) {
  final defaultTitle = YumeiroLocalizations.of(context).selectItem;
  return presentSingleSelectionSheet<T>(
    context: context,
    controller: controller,
    useRootNavigator: select().useRootNavigator,
    anchor: anchor,
    selection: () {
      final current = select();
      return (
        title: current._fixedSheetTitle ?? defaultTitle,
        options: current.options,
        value: current.value,
        searchable: current._fixedSheetSearchable,
      );
    },
  );
}

class _YumeiroSelectState<T> extends State<YumeiroSelect<T>> {
  final _sheetController = YumeiroSheetController();
  final _pointerController = PickerOverlayController();
  int _pickerGeneration = 0;
  bool _pickerOpen = false;

  @override
  void didUpdateWidget(covariant YumeiroSelect<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget._closesFixedPicker(oldWidget)) {
      _invalidatePicker();
    } else if (_pickerOpen) {
      if (widget._updatesFixedPicker(oldWidget)) _sheetController.refresh();
      // The host can move the trigger without changing the selection.
      _pointerController.refresh();
    }
  }

  void _invalidatePicker() {
    _pickerGeneration++;
    _sheetController.close();
    _pointerController.close();
  }

  @override
  void dispose() {
    _invalidatePicker();
    super.dispose();
  }

  YumeiroSelectionOption<T>? get _selectedOption {
    for (final option in widget.options) {
      if (option.value == widget.value) return option;
    }
    return null;
  }

  double _computeAutoWidth(
    BuildContext context,
    YumeiroThemeExtension theme,
    YumeiroLocalizations l10n,
    YumeiroMetrics metrics, {
    required bool clearable,
  }) {
    final dense = widget.dense;
    final maxWidth = widget.maxWidth;
    final textStyle = theme.typography.input(dense: dense);
    var maxTextWidth = yumeiroSelectTextWidth(
      context,
      widget.placeholder ?? l10n.selectPlaceholder,
      textStyle,
    );
    for (final option in widget.options) {
      final w = yumeiroSelectTextWidth(context, option.label, textStyle);
      if (w > maxTextWidth) maxTextWidth = w;
    }

    final iconSize = yumeiroPickerIconSize(theme, metrics, dense);
    final horizontalPadding = yumeiroPickerHorizontalPadding(metrics, dense);
    final iconSpace = iconSize + theme.spacing.sm;
    final hasAnyIcon = widget.options.any((option) => option.icon != null);
    final leadingChrome = hasAnyIcon ? iconSpace : 0.0;
    final double triggerChrome;
    if (clearable) {
      final (:clearExtent, :chevronExtent) = yumeiroPickerActionExtents(
        theme,
        metrics,
        dense,
      );
      triggerChrome =
          horizontalPadding + leadingChrome + clearExtent + chevronExtent + 10;
    } else {
      final trailingChrome = widget.enabled && widget.readOnly
          ? 0.0
          : iconSpace;
      triggerChrome =
          horizontalPadding * 2 + leadingChrome + trailingChrome + 10;
    }
    final rawWidth = math.max(
      triggerChrome + maxTextWidth,
      metrics.isTouch
          ? 0.0
          : selectionMenuContentWidth(
              context,
              widget.options,
              dense: dense,
              showCheckmark: true,
            ),
    );
    final lower = math.min(maxWidth, dense ? 64.0 : 76.0);
    return rawWidth.ceilToDouble().clamp(lower, maxWidth);
  }

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final metrics = YumeiroModalityScope.metricsOf(context);
    final l10n = YumeiroLocalizations.of(context);
    final selected = _selectedOption;
    final dense = widget.dense;
    final enabled = widget._canOpenFixedPicker;
    final readOnly = widget.enabled && widget.readOnly;
    final clearAction = _SelectClearAction.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final parentWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : null;
        double? measuredWidth;
        double autoWidth() => measuredWidth ??= _computeAutoWidth(
          context,
          theme,
          l10n,
          metrics,
          clearable: clearAction?.enabled ?? false,
        );
        double boundedAutoWidth() {
          final measured = autoWidth();
          return parentWidth == null
              ? measured
              : math.min(measured, parentWidth);
        }

        final resolvedWidth =
            widget.width ??
            (constraints.hasTightWidth ? parentWidth : null) ??
            (widget.expand ? parentWidth : null) ??
            boundedAutoWidth();

        final label =
            selected?.label ?? widget.placeholder ?? l10n.selectPlaceholder;
        return SizedBox(
          width: resolvedWidth,
          child: yumeiroFormPickerActions(
            context,
            maxWidth: constraints.constrainWidth(resolvedWidth),
            dense: dense,
            clearable: clearAction?.enabled ?? false,
            clearButton: clearAction?.button,
            trigger: (clearExtent, chevronExtent) =>
                YumeiroPickerTriggerSurface(
                  enabled: widget.enabled,
                  readOnly: widget.readOnly,
                  hasError: widget.hasError,
                  dense: dense,
                  focusNode: widget.focusNode,
                  autofocus: widget.autofocus,
                  onOpen: enabled
                      ? (context) => _openPicker(context, autoWidth)
                      : null,
                  semanticLabel: widget.semanticLabel,
                  semanticValue: label,
                  child: yumeiroPickerTriggerContent(
                    context,
                    text: label,
                    style: theme.typography
                        .input(dense: dense)
                        .copyWith(
                          color: selected == null ? theme.subtle : theme.text,
                        ),
                    dense: dense,
                    icon: selected?.icon,
                    showChevron: !readOnly,
                    clearExtent: clearExtent,
                    chevronExtent: chevronExtent,
                  ),
                ),
          ),
        );
      },
    );
  }

  Future<void> _openPicker(
    BuildContext context,
    double Function() autoWidth,
  ) async {
    if (_pickerOpen || !widget._canOpenFixedPicker) return;
    _pickerOpen = true;
    final generation = _pickerGeneration;
    try {
      final modality = YumeiroModalityScope.modalityOf(context);
      final picked = modality == YumeiroModality.touch
          ? await _showFixedOptionsSheet<T>(
              context: context,
              controller: _sheetController,
              select: () => widget,
            )
          : await _showPointerMenu(
              context,
              widget.menuWidth ?? (widget.menuAutoWidth ? autoWidth() : null),
            );
      if (mounted && generation == _pickerGeneration) {
        widget._acceptFixedOption(picked);
      }
    } finally {
      _pickerOpen = false;
    }
  }

  Future<YumeiroSelectionOption<T>?> _showPointerMenu(
    BuildContext context,
    double? popupWidth,
  ) {
    return showPickerOverlay<YumeiroSelectionOption<T>>(
      context: context,
      controller: _pointerController,
      useRootNavigator: widget.useRootNavigator,
      width: popupWidth,
      maxHeight: 280,
      surfacePadding: selectionMenuSurfacePadding,
      builder: (menuContext) {
        final selected = _selectedOption;
        return buildMenuSelectionList<T>(
          options: widget.options,
          values: {if (selected != null) selected.value},
          dense: widget.dense,
          onSelected: (option) => Navigator.of(menuContext).pop(option),
        );
      },
    );
  }
}
