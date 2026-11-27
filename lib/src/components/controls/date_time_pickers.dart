import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../foundation/modality.dart';
import '../../primitives/visual_scope.dart';
import '../../primitives/visual_surface.dart';
import '../../theme/effect_pass.dart';
import '../../theme/semantic_visuals.dart';
import '../../theme/theme.dart';
import '../../theme/visual_role.dart';
import '../layout/page_header.dart';
import '../layout/panels.dart';
import '../layout/scroll_view.dart';
import '../layout/setting_row_header.dart';
import '../overlays/picker_overlay.dart';
import '../overlays/sheets.dart';
import 'buttons.dart';
import 'form_picker_trigger.dart';
import 'inputs.dart';
import 'segmented.dart';

part 'date_calendar_panel.dart';
part 'time_picker_panel.dart';

/// A controlled calendar date input with a picker and optional clear action.
///
/// Dates retain their civil year, month and day at midnight. The default
/// calendar presentation adapts to pointer or touch input.
class YumeiroDatePicker extends _DateTimePicker<DateTime> {
  YumeiroDatePicker({
    super.key,
    required DateTime firstDate,
    required DateTime lastDate,
    this.currentDate,
    this.selectableDayPredicate,
    this.initialEntryMode = DatePickerEntryMode.calendar,
    required DateTime? value,
    required super.onChanged,
    super.enabled,
    super.label,
    super.semanticLabel,
    super.helperText,
    super.required,
    super.placeholder,
    super.clearable,
    super.readOnly,
    super.focusNode,
    super.autofocus,
    super.useRootNavigator,
    super.width,
    super.expand,
    super.dense,
  }) : _bounds = _DateBounds(firstDate, lastDate),
       super(value: value == null ? null : DateUtils.dateOnly(value));

  /// Creates a picker integrated with Flutter [Form].
  ///
  /// A form reset restores [initialValue]. [onChanged] reports user edits
  /// after updating the field. Clearing a value reports null.
  static FormField<DateTime> form({
    Key? key,
    required DateTime firstDate,
    required DateTime lastDate,
    DateTime? currentDate,
    SelectableDayPredicate? selectableDayPredicate,
    DatePickerEntryMode initialEntryMode = DatePickerEntryMode.calendar,
    DateTime? initialValue,
    FormFieldSetter<DateTime>? onSaved,
    VoidCallback? onReset,
    FormFieldValidator<DateTime>? validator,
    AutovalidateMode? autovalidateMode,
    String? forceErrorText,
    ValueChanged<DateTime?>? onChanged,
    bool enabled = true,
    String? label,
    String? semanticLabel,
    String? helperText,
    bool required = false,
    String? placeholder,
    bool clearable = false,
    bool readOnly = false,
    FocusNode? focusNode,
    bool autofocus = false,
    bool useRootNavigator = true,
    double? width,
    bool expand = true,
    bool dense = false,
  }) => _PickerFormField<DateTime>(
    key: key,
    onSaved: onSaved,
    onReset: onReset,
    validator: validator,
    autovalidateMode: autovalidateMode,
    forceErrorText: forceErrorText,
    picker: YumeiroDatePicker(
      value: initialValue,
      onChanged: onChanged,
      firstDate: firstDate,
      lastDate: lastDate,
      currentDate: currentDate,
      selectableDayPredicate: selectableDayPredicate,
      initialEntryMode: initialEntryMode,
      enabled: enabled,
      label: label,
      semanticLabel: semanticLabel,
      helperText: helperText,
      required: required,
      placeholder: placeholder,
      clearable: clearable,
      readOnly: readOnly,
      focusNode: focusNode,
      autofocus: autofocus,
      useRootNavigator: useRootNavigator,
      width: width,
      expand: expand,
      dense: dense,
    ),
  );

  final _DateBounds _bounds;

  /// Earliest selectable day, inclusive.
  DateTime get firstDate => _bounds.first;

  /// Latest selectable day, inclusive.
  DateTime get lastDate => _bounds.last;

  /// Day highlighted as today in the picker. Defaults to the current date.
  final DateTime? currentDate;

  /// Additional rule used by the picker to determine which days can be picked.
  final SelectableDayPredicate? selectableDayPredicate;
  final DatePickerEntryMode initialEntryMode;

  @override
  IconData get _icon => Icons.today_outlined;

  @override
  String _placeholder(MaterialLocalizations messages) =>
      messages.datePickerHelpText;

  @override
  String _format(BuildContext context, DateTime value) =>
      MaterialLocalizations.of(context).formatCompactDate(value);

  @override
  DateTime _normalize(DateTime value) => DateUtils.dateOnly(value);

  @override
  bool _accepts(DateTime value) =>
      _bounds.includes(value) && (selectableDayPredicate?.call(value) ?? true);

  @override
  Future<DateTime?> _pick(BuildContext context, DateTime? value) {
    final initialDate = value != null && _accepts(value) ? value : null;
    return _showDateTimePanel<DateTime>(
      context,
      useRootNavigator: useRootNavigator,
      width: _calendarPanelWidth(context, range: false),
      maxHeight: 560,
      preferredHeight: 400,
      panel: (presentation) => _CalendarPickerPanel<DateTime>(
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
        currentDate: currentDate,
        selectableDayPredicate: selectableDayPredicate,
        initialEntryMode: initialEntryMode,
        touch: presentation.touch,
        anchor: presentation.anchor,
      ),
    );
  }
}

/// The starting view and available entry methods of a [YumeiroTimePicker].
enum YumeiroTimePickerEntryMode {
  /// Opens the hour and minute lists. Users can switch to text input.
  list,

  /// Opens text input. Users can switch to the hour and minute lists.
  input,

  /// Only the hour and minute lists are available.
  listOnly,

  /// Only the text inputs are available.
  inputOnly,
}

/// A controlled time input with keyboard entry and scrollable hour and minute
/// choices.
class YumeiroTimePicker extends _DateTimePicker<TimeOfDay> {
  const YumeiroTimePicker({
    super.key,
    this.initialPickerTime,
    this.initialEntryMode = YumeiroTimePickerEntryMode.list,
    required super.value,
    required super.onChanged,
    super.enabled,
    super.label,
    super.semanticLabel,
    super.helperText,
    super.required,
    super.placeholder,
    super.clearable,
    super.readOnly,
    super.focusNode,
    super.autofocus,
    super.useRootNavigator,
    super.width,
    super.expand,
    super.dense,
  });

  /// Creates a picker integrated with Flutter [Form].
  ///
  /// A form reset restores [initialValue]. [onChanged] reports user edits
  /// after updating the field. Clearing a value reports null.
  static FormField<TimeOfDay> form({
    Key? key,
    TimeOfDay? initialPickerTime,
    YumeiroTimePickerEntryMode initialEntryMode =
        YumeiroTimePickerEntryMode.list,
    TimeOfDay? initialValue,
    FormFieldSetter<TimeOfDay>? onSaved,
    VoidCallback? onReset,
    FormFieldValidator<TimeOfDay>? validator,
    AutovalidateMode? autovalidateMode,
    String? forceErrorText,
    ValueChanged<TimeOfDay?>? onChanged,
    bool enabled = true,
    String? label,
    String? semanticLabel,
    String? helperText,
    bool required = false,
    String? placeholder,
    bool clearable = false,
    bool readOnly = false,
    FocusNode? focusNode,
    bool autofocus = false,
    bool useRootNavigator = true,
    double? width,
    bool expand = true,
    bool dense = false,
  }) => _PickerFormField<TimeOfDay>(
    key: key,
    onSaved: onSaved,
    onReset: onReset,
    validator: validator,
    autovalidateMode: autovalidateMode,
    forceErrorText: forceErrorText,
    picker: YumeiroTimePicker(
      value: initialValue,
      onChanged: onChanged,
      initialPickerTime: initialPickerTime,
      initialEntryMode: initialEntryMode,
      enabled: enabled,
      label: label,
      semanticLabel: semanticLabel,
      helperText: helperText,
      required: required,
      placeholder: placeholder,
      clearable: clearable,
      readOnly: readOnly,
      focusNode: focusNode,
      autofocus: autofocus,
      useRootNavigator: useRootNavigator,
      width: width,
      expand: expand,
      dense: dense,
    ),
  );

  /// Starting time for an empty field. Defaults to the current time.
  final TimeOfDay? initialPickerTime;

  /// Starting view and whether the user can switch entry methods.
  final YumeiroTimePickerEntryMode initialEntryMode;

  @override
  IconData get _icon => Icons.schedule_outlined;

  @override
  String _placeholder(MaterialLocalizations messages) =>
      messages.timePickerDialHelpText;

  @override
  String _format(BuildContext context, TimeOfDay value) =>
      value.format(context);

  @override
  Future<TimeOfDay?> _pick(BuildContext context, TimeOfDay? value) =>
      _showDateTimePanel<TimeOfDay>(
        context,
        useRootNavigator: useRootNavigator,
        width: 264,
        maxHeight: 540,
        preferredHeight: 420,
        panel: (presentation) => _TimePickerPanel(
          initialTime: value ?? initialPickerTime ?? TimeOfDay.now(),
          initialEntryMode: initialEntryMode,
          touch: presentation.touch,
          anchor: presentation.anchor,
          alwaysUse24HourFormat: presentation.alwaysUse24HourFormat,
        ),
      );
}

/// A controlled date range input with a responsive one- or two-month calendar.
///
/// Both endpoints use their civil dates. A range can start and end on the same day.
class YumeiroDateRangePicker extends _DateTimePicker<DateTimeRange<DateTime>> {
  YumeiroDateRangePicker({
    super.key,
    required DateTime firstDate,
    required DateTime lastDate,
    this.currentDate,
    this.selectableDayPredicate,
    this.initialEntryMode = DatePickerEntryMode.calendar,
    required DateTimeRange<DateTime>? value,
    required super.onChanged,
    super.enabled,
    super.label,
    super.semanticLabel,
    super.helperText,
    super.required,
    super.placeholder,
    super.clearable,
    super.readOnly,
    super.focusNode,
    super.autofocus,
    super.useRootNavigator,
    super.width,
    super.expand,
    super.dense,
  }) : _bounds = _DateBounds(firstDate, lastDate),
       super(value: value == null ? null : _civilRange(value));

  /// Creates a picker integrated with Flutter [Form].
  ///
  /// A form reset restores [initialValue]. [onChanged] reports user edits
  /// after updating the field. Clearing a value reports null.
  static FormField<DateTimeRange<DateTime>> form({
    Key? key,
    required DateTime firstDate,
    required DateTime lastDate,
    DateTime? currentDate,
    SelectableDayForRangePredicate? selectableDayPredicate,
    DatePickerEntryMode initialEntryMode = DatePickerEntryMode.calendar,
    DateTimeRange<DateTime>? initialValue,
    FormFieldSetter<DateTimeRange<DateTime>>? onSaved,
    VoidCallback? onReset,
    FormFieldValidator<DateTimeRange<DateTime>>? validator,
    AutovalidateMode? autovalidateMode,
    String? forceErrorText,
    ValueChanged<DateTimeRange<DateTime>?>? onChanged,
    bool enabled = true,
    String? label,
    String? semanticLabel,
    String? helperText,
    bool required = false,
    String? placeholder,
    bool clearable = false,
    bool readOnly = false,
    FocusNode? focusNode,
    bool autofocus = false,
    bool useRootNavigator = true,
    double? width,
    bool expand = true,
    bool dense = false,
  }) => _PickerFormField<DateTimeRange<DateTime>>(
    key: key,
    onSaved: onSaved,
    onReset: onReset,
    validator: validator,
    autovalidateMode: autovalidateMode,
    forceErrorText: forceErrorText,
    picker: YumeiroDateRangePicker(
      value: initialValue,
      onChanged: onChanged,
      firstDate: firstDate,
      lastDate: lastDate,
      currentDate: currentDate,
      selectableDayPredicate: selectableDayPredicate,
      initialEntryMode: initialEntryMode,
      enabled: enabled,
      label: label,
      semanticLabel: semanticLabel,
      helperText: helperText,
      required: required,
      placeholder: placeholder,
      clearable: clearable,
      readOnly: readOnly,
      focusNode: focusNode,
      autofocus: autofocus,
      useRootNavigator: useRootNavigator,
      width: width,
      expand: expand,
      dense: dense,
    ),
  );

  final _DateBounds _bounds;

  /// Earliest selectable endpoint, inclusive.
  DateTime get firstDate => _bounds.first;

  /// Latest selectable endpoint, inclusive.
  DateTime get lastDate => _bounds.last;

  /// Day highlighted as today in the picker. Defaults to the current date.
  final DateTime? currentDate;

  /// Additional Material rule for selecting an endpoint of a range.
  final SelectableDayForRangePredicate? selectableDayPredicate;
  final DatePickerEntryMode initialEntryMode;

  @override
  IconData get _icon => Icons.date_range_outlined;

  @override
  String _placeholder(MaterialLocalizations messages) =>
      messages.dateRangePickerHelpText;

  @override
  String _format(BuildContext context, DateTimeRange<DateTime> value) {
    final messages = MaterialLocalizations.of(context);
    return '${messages.formatCompactDate(value.start)} – ${messages.formatCompactDate(value.end)}';
  }

  @override
  DateTimeRange<DateTime> _normalize(DateTimeRange<DateTime> value) =>
      _civilRange(value);

  @override
  bool _accepts(DateTimeRange<DateTime> value) {
    final predicate = selectableDayPredicate;
    final start = value.start;
    final end = value.end;
    return _bounds.includes(start) &&
        _bounds.includes(end) &&
        (predicate == null ||
            (predicate(start, start, end) && predicate(end, start, end)));
  }

  @override
  Future<DateTimeRange<DateTime>?> _pick(
    BuildContext context,
    DateTimeRange<DateTime>? value,
  ) => _showDateTimePanel<DateTimeRange<DateTime>>(
    context,
    useRootNavigator: useRootNavigator,
    width: _calendarPanelWidth(context, range: true),
    maxHeight: 640,
    preferredHeight: 470,
    panel: (presentation) => _CalendarPickerPanel<DateTimeRange<DateTime>>(
      initialRange: value != null && _accepts(value) ? value : null,
      firstDate: firstDate,
      lastDate: lastDate,
      currentDate: currentDate,
      selectableDayForRangePredicate: selectableDayPredicate,
      initialEntryMode: initialEntryMode,
      touch: presentation.touch,
      anchor: presentation.anchor,
      range: true,
    ),
  );
}

class _DateBounds {
  _DateBounds(DateTime firstDate, DateTime lastDate)
    : first = DateUtils.dateOnly(firstDate),
      last = DateUtils.dateOnly(lastDate) {
    if (last.isBefore(first)) {
      throw ArgumentError.value(
        lastDate,
        'lastDate',
        'Must be on or after firstDate.',
      );
    }
  }

  final DateTime first;
  final DateTime last;

  bool includes(DateTime date) => !date.isBefore(first) && !date.isAfter(last);
}

DateTimeRange<DateTime> _civilRange(DateTimeRange<DateTime> range) {
  final start = DateUtils.dateOnly(range.start);
  final end = DateUtils.dateOnly(range.end);
  if (end.isBefore(start)) {
    throw ArgumentError.value(
      range,
      'range',
      'The end day must be on or after the start day.',
    );
  }
  return DateTimeRange(start: start, end: end);
}

abstract class _DateTimePicker<T extends Object> extends StatelessWidget {
  const _DateTimePicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.label,
    this.semanticLabel,
    this.helperText,
    this.required = false,
    this.placeholder,
    this.clearable = false,
    this.readOnly = false,
    this.focusNode,
    this.autofocus = false,
    this.useRootNavigator = true,
    this.width,
    this.expand = true,
    this.dense = false,
  });

  /// Current selection, owned by the caller.
  final T? value;

  /// Reports a confirmed selection, or null when the user clears it.
  /// A null callback prevents editing.
  final ValueChanged<T?>? onChanged;
  final bool enabled;
  final String? label;
  final String? semanticLabel;
  final String? helperText;

  /// Marks the label. Supply a validator when a form requires a selection.
  final bool required;
  final String? placeholder;
  final bool clearable;

  /// Keeps the picker focusable while blocking edits.
  final bool readOnly;
  final FocusNode? focusNode;
  final bool autofocus;

  /// Set to false to open the picker on the nearest navigator.
  final bool useRootNavigator;
  final double? width;
  final bool expand;
  final bool dense;

  IconData get _icon;
  String _placeholder(MaterialLocalizations messages);
  String _format(BuildContext context, T value);
  T _normalize(T value) => value;
  bool _accepts(T value) => true;
  Future<T?> _pick(BuildContext context, T? value);

  @override
  Widget build(BuildContext context) =>
      _PickerInput<T>(picker: this, value: value, onChanged: onChanged);
}

class _PickerFormField<T extends Object> extends FormField<T> {
  _PickerFormField({
    super.key,
    super.onSaved,
    super.onReset,
    super.validator,
    super.autovalidateMode,
    super.forceErrorText,
    required this.picker,
  }) : super(
         initialValue: picker.value,
         enabled: picker.enabled,
         builder: (field) => (field as _PickerFormFieldState<T>)._buildField(),
       );

  final _DateTimePicker<T> picker;

  @override
  FormFieldState<T> createState() => _PickerFormFieldState<T>();
}

class _PickerFormFieldState<T extends Object> extends FormFieldState<T> {
  var _revision = 0;

  _DateTimePicker<T> get _picker => (widget as _PickerFormField<T>).picker;

  @override
  void didChange(T? value) {
    _revision++;
    super.didChange(value == null ? null : _picker._normalize(value));
  }

  @override
  void reset() {
    _revision++;
    super.reset();
  }

  void _changeFromUser(T? value) {
    didChange(value);
    _picker.onChanged?.call(value);
  }

  Widget _buildField() => _PickerInput<T>(
    picker: _picker,
    value: value,
    onChanged: _changeFromUser,
    errorText: errorText,
    formRevision: () => _revision,
  );
}

class _PickerInput<T extends Object> extends StatefulWidget {
  const _PickerInput({
    required this.picker,
    required this.value,
    required this.onChanged,
    this.errorText,
    this.formRevision,
  });

  final _DateTimePicker<T> picker;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final String? errorText;

  // Read before and after awaiting the picker. A Form may reset or edit the
  // value before the updated widget configuration has been built.
  final int Function()? formRevision;

  @override
  State<_PickerInput<T>> createState() => _PickerInputState<T>();
}

class _PickerInputState<T extends Object> extends State<_PickerInput<T>> {
  var _revision = 0;
  var _pickerOpen = false;

  bool get _enabled =>
      widget.picker.enabled &&
      (widget.picker.readOnly || widget.onChanged != null);
  bool get _editable => _enabled && !widget.picker.readOnly;

  @override
  void didUpdateWidget(covariant _PickerInput<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editable ||
        widget.value != oldWidget.value ||
        widget.picker.useRootNavigator != oldWidget.picker.useRootNavigator) {
      _revision++;
    }
  }

  void _changeFromUser(T? value) {
    _revision++;
    widget.onChanged?.call(value);
  }

  Future<void> _openPicker(BuildContext context) async {
    if (!_editable || _pickerOpen) return;
    final revision = _revision;
    final formRevision = widget.formRevision?.call();
    _pickerOpen = true;
    try {
      final picked = await widget.picker._pick(context, widget.value);
      if (!mounted ||
          !_editable ||
          revision != _revision ||
          formRevision != widget.formRevision?.call() ||
          picked == null) {
        return;
      }
      final normalized = widget.picker._normalize(picked);
      if (widget.picker._accepts(normalized)) _changeFromUser(normalized);
    } finally {
      _pickerOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final picker = widget.picker;
    final current = widget.value;
    final fallbackLabel = picker._placeholder(
      MaterialLocalizations.of(context),
    );
    final accessibleLabel =
        picker.semanticLabel ?? picker.label ?? fallbackLabel;

    return YumeiroFieldLayout(
      label: picker.label,
      semanticLabel: accessibleLabel,
      helperText: picker.helperText,
      required: picker.required,
      errorText: widget.errorText,
      dense: picker.dense,
      crossAxisAlignment: picker.expand && picker.width == null
          ? CrossAxisAlignment.stretch
          : CrossAxisAlignment.start,
      child: YumeiroFormPickerTrigger(
        width: picker.width,
        text: current == null
            ? picker.placeholder ?? fallbackLabel
            : picker._format(context, current),
        isPlaceholder: current == null,
        enabled: _enabled,
        readOnly: picker.readOnly,
        hasError: widget.errorText != null,
        dense: picker.dense,
        expand: picker.expand || picker.width != null,
        icon: picker._icon,
        focusNode: picker.focusNode,
        autofocus: picker.autofocus,
        onOpen: _openPicker,
        clearable: picker.clearable && _editable,
        clearButton: current != null && picker.clearable && _editable
            ? yumeiroPickerClearButton(
                context,
                fieldLabel: accessibleLabel,
                dense: picker.dense,
                onPressed: () => _changeFromUser(null),
              )
            : null,
      ),
    );
  }
}

typedef _DateTimePresentation = ({
  bool touch,
  Rect? anchor,
  bool alwaysUse24HourFormat,
});

double _calendarPanelWidth(BuildContext context, {required bool range}) {
  final spacing = YumeiroTheme.of(context).spacing;
  final targetSize = YumeiroModalityScope.metricsOf(context).minTargetSize;
  final monthWidth = DateTime.daysPerWeek * targetSize;
  final horizontalPadding = spacing.md * 2;
  return range
      ? math.max(
          616,
          2 * monthWidth + horizontalPadding + spacing.md + spacing.xs,
        )
      : math.max(
          312,
          monthWidth +
              horizontalPadding +
              (DateTime.daysPerWeek - 1) * spacing.xs,
        );
}

Future<T?> _showDateTimePanel<T>(
  BuildContext context, {
  required bool useRootNavigator,
  required double width,
  required double maxHeight,
  required double preferredHeight,
  required Widget Function(_DateTimePresentation) panel,
}) {
  final touch = YumeiroModalityScope.metricsOf(context).isTouch;
  final renderObject = context.findRenderObject();
  Rect? anchor;
  if (touch && renderObject is RenderBox) {
    final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
    final overlay = navigator.overlay!.context.findRenderObject();
    anchor = MatrixUtils.transformRect(
      renderObject.getTransformTo(overlay),
      Offset.zero & renderObject.size,
    );
  }
  final media = MediaQuery.of(context);
  Widget content(BuildContext context) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      alwaysUse24HourFormat: media.alwaysUse24HourFormat,
      textScaler: media.textScaler,
    ),
    child: panel((
      touch: touch,
      anchor: anchor,
      alwaysUse24HourFormat: media.alwaysUse24HourFormat,
    )),
  );
  if (touch) {
    return YumeiroBottomSheet.show<T>(
      context: context,
      builder: content,
      useRootNavigator: useRootNavigator,
    );
  }
  return showPickerOverlay<T>(
    context: context,
    builder: content,
    useRootNavigator: useRootNavigator,
    width: width,
    maxHeight: maxHeight,
    minHeight: preferredHeight,
    surfacePadding: EdgeInsets.zero,
  );
}
