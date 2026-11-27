part of 'date_time_pickers.dart';

enum _RangeTarget { newStart, start, end }

class _CalendarPickerPanel<T extends Object> extends StatefulWidget {
  const _CalendarPickerPanel({
    required this.firstDate,
    required this.lastDate,
    required this.currentDate,
    required this.initialEntryMode,
    required this.touch,
    required this.anchor,
    this.range = false,
    this.initialDate,
    this.initialRange,
    this.selectableDayPredicate,
    this.selectableDayForRangePredicate,
  });

  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime? currentDate;
  final DatePickerEntryMode initialEntryMode;
  final bool touch;
  final Rect? anchor;
  final bool range;
  final DateTime? initialDate;
  final DateTimeRange<DateTime>? initialRange;
  final SelectableDayPredicate? selectableDayPredicate;
  final SelectableDayForRangePredicate? selectableDayForRangePredicate;

  @override
  State<_CalendarPickerPanel<T>> createState() =>
      _CalendarPickerPanelState<T>();
}

class _CalendarPickerPanelState<T extends Object>
    extends State<_CalendarPickerPanel<T>> {
  final _startText = TextEditingController();
  final _endText = TextEditingController();
  final _dayFocus = <DateTime, FocusNode>{};
  late final _today = DateUtils.dateOnly(widget.currentDate ?? DateTime.now());
  late DateTime? _start = widget.initialDate ?? widget.initialRange?.start;
  late DateTime? _end = widget.initialRange?.end;
  late DateTime _focusDay = _clampDay(_start ?? _today);
  late DateTime _month = _monthOf(_focusDay);
  late bool _typing = switch (widget.initialEntryMode) {
    DatePickerEntryMode.input || DatePickerEntryMode.inputOnly => true,
    DatePickerEntryMode.calendar || DatePickerEntryMode.calendarOnly => false,
  };
  _RangeTarget _target = _RangeTarget.newStart;
  DateTime? _hoverDate;
  DateTime? _yearPickerMonth;
  String? _startError;
  String? _endError;
  bool _seededInputs = false;

  DateTime _monthOf(DateTime day) => DateTime(day.year, day.month);
  DateTime get _firstMonth => _monthOf(widget.firstDate);
  DateTime get _lastMonth => _monthOf(widget.lastDate);
  MaterialLocalizations get _messages => MaterialLocalizations.of(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seededInputs) return;
    _seededInputs = true;
    _syncInput();
  }

  @override
  void dispose() {
    _startText.dispose();
    _endText.dispose();
    super.dispose();
  }

  DateTime _clampDay(DateTime day) {
    if (day.isBefore(widget.firstDate)) return widget.firstDate;
    if (day.isAfter(widget.lastDate)) return widget.lastDate;
    return day;
  }

  bool _inBounds(DateTime day) =>
      !day.isBefore(widget.firstDate) && !day.isAfter(widget.lastDate);

  (DateTime, DateTime?) _rangeWith(DateTime day) => switch (_target) {
    _RangeTarget.newStart => (day, null),
    _RangeTarget.start => (
      day,
      _end != null && !day.isAfter(_end!) ? _end : null,
    ),
    _RangeTarget.end =>
      _start == null || day.isBefore(_start!) ? (day, null) : (_start!, day),
  };

  bool _allowedRangeDay(DateTime day, DateTime? start, DateTime? end) =>
      widget.selectableDayForRangePredicate?.call(day, start, end) ?? true;

  bool _canPick(DateTime day) {
    if (!_inBounds(day)) return false;
    if (!widget.range) return widget.selectableDayPredicate?.call(day) ?? true;
    if (!_allowedRangeDay(day, _start, _end)) return false;
    final (start, end) = _rangeWith(day);
    return end == null ||
        (_allowedRangeDay(start, start, end) &&
            _allowedRangeDay(end, start, end));
  }

  bool get _canConfirm {
    final start = _start;
    final end = _end;
    if (start == null) return false;
    if (!widget.range) return _canPick(start);
    return end != null &&
        _allowedRangeDay(start, start, end) &&
        _allowedRangeDay(end, start, end);
  }

  void _select(DateTime day) {
    setState(() {
      _hoverDate = null;
      if (widget.range) {
        final (start, end) = _rangeWith(day);
        _start = start;
        _end = end;
        _target = _end == null ? _RangeTarget.end : _RangeTarget.newStart;
      } else {
        _start = day;
      }
      // A revised range predicate can disable the day that was just picked.
      // Keep keyboard selection in the rendered grid when that happens.
      final fallback = _dayFocus.keys.where(_canPick);
      _focusDay = _canPick(day)
          ? day
          : fallback.where((candidate) => candidate.isAfter(day)).firstOrNull ??
                fallback.lastOrNull ??
                day;
    });
    _dayFocus[_focusDay]?.requestFocus();
  }

  void _editRangeEndpoint(_RangeTarget target) {
    final day = target == _RangeTarget.start ? _start : _end ?? _start;
    setState(() {
      _target = target;
      _hoverDate = null;
      if (day != null) {
        _focusDay = day;
        _month = _monthOf(day);
      }
    });
  }

  void _syncInput() {
    _startText.text = _start == null
        ? ''
        : _messages.formatCompactDate(_start!);
    _endText.text = _end == null ? '' : _messages.formatCompactDate(_end!);
  }

  bool _readInput({required bool showErrors}) {
    final start = _messages.parseCompactDate(_startText.text.trim());
    final end = widget.range
        ? _messages.parseCompactDate(_endText.text.trim())
        : null;
    final reversed = start != null && end != null && start.isAfter(end);
    final startError = _inputError(start, start, reversed ? null : end);
    final endError = !widget.range
        ? null
        : reversed
        ? _messages.invalidDateRangeLabel
        : _inputError(end, start, end);
    if (showErrors) {
      setState(() {
        _startError = startError;
        _endError = endError;
      });
    }
    if (startError != null || endError != null) return false;
    _start = start;
    _end = end;
    _target = _RangeTarget.newStart;
    return true;
  }

  String? _inputError(DateTime? day, DateTime? start, DateTime? end) {
    if (day == null) return _messages.invalidDateFormatLabel;
    final allowed = widget.range
        ? _allowedRangeDay(day, start, end)
        : widget.selectableDayPredicate?.call(day) ?? true;
    return _inBounds(day) && allowed ? null : _messages.dateOutOfRangeLabel;
  }

  void _toggleEntry() {
    if (_typing) {
      _readInput(showErrors: false);
    } else {
      _syncInput();
    }
    setState(() {
      _typing = !_typing;
      _yearPickerMonth = null;
      _startError = null;
      _endError = null;
      if (!_typing && _start != null) {
        _focusDay = _start!;
        _month = _monthOf(_focusDay);
      }
    });
  }

  void _confirm() {
    if (_typing && !_readInput(showErrors: true)) return;
    if (!_canConfirm) return;
    final Object value = widget.range
        ? DateTimeRange(start: _start!, end: _end!)
        : _start!;
    Navigator.of(context).pop(value as T);
  }

  void _showMonth(DateTime month) {
    setState(() {
      _month = month;
      _hoverDate = null;
      _yearPickerMonth = null;
    });
  }

  KeyEventResult _onDayKey(DateTime day, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final step = switch (key) {
      LogicalKeyboardKey.arrowLeft => rtl ? 1 : -1,
      LogicalKeyboardKey.arrowRight => rtl ? -1 : 1,
      LogicalKeyboardKey.arrowUp => -DateTime.daysPerWeek,
      LogicalKeyboardKey.arrowDown => DateTime.daysPerWeek,
      _ => 0,
    };
    if (step != 0) {
      _moveFocus(DateUtils.addDaysToDate(day, step), step);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.home || key == LogicalKeyboardKey.end) {
      final weekday = day.weekday % DateTime.daysPerWeek;
      final offset =
          (weekday - _messages.firstDayOfWeekIndex) % DateTime.daysPerWeek;
      final last = key == LogicalKeyboardKey.end;
      _moveFocus(
        _clampDay(DateUtils.addDaysToDate(day, last ? 6 - offset : -offset)),
        last ? -1 : 1,
        limit: day,
      );
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.pageUp ||
        key == LogicalKeyboardKey.pageDown) {
      final direction = key == LogicalKeyboardKey.pageUp ? -1 : 1;
      final month = DateUtils.addMonthsToMonthDate(day, direction);
      final target = DateTime(
        month.year,
        month.month,
        math.min(day.day, DateUtils.getDaysInMonth(month.year, month.month)),
      );
      _moveFocus(_clampDay(target), direction);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _moveFocus(DateTime next, int step, {DateTime? limit}) {
    while (_inBounds(next) && !_canPick(next)) {
      if (next == limit) return;
      next = DateUtils.addDaysToDate(next, step);
    }
    if (!_inBounds(next)) return;
    final day = next;
    final visible = _dayFocus.containsKey(day);
    setState(() {
      _focusDay = day;
      _hoverDate = null;
      if (!visible) _month = _monthOf(day);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final node = _dayFocus[day];
      node?.requestFocus();
      if (node?.context case final focusContext?) {
        Scrollable.ensureVisible(focusContext);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final messages = _messages;
    final compactHeader =
        !widget.touch && !widget.range && !_typing && _yearPickerMonth == null;
    final title = widget.range
        ? messages.dateRangePickerHelpText
        : messages.datePickerHelpText;
    final toggleMode = switch (widget.initialEntryMode) {
      DatePickerEntryMode.input ||
      DatePickerEntryMode.calendar => YumeiroButton(
        key: const ValueKey('yumeiro-calendar-toggle-input'),
        variant: YumeiroButtonVariant.ghost,
        icon: _typing ? Icons.calendar_today_outlined : Icons.edit_outlined,
        tooltip: _typing
            ? messages.calendarModeButtonLabel
            : messages.inputDateModeButtonLabel,
        onPressed: _toggleEntry,
      ),
      DatePickerEntryMode.inputOnly || DatePickerEntryMode.calendarOnly => null,
    };
    final cancel = YumeiroButton(
      label: messages.cancelButtonLabel,
      variant: YumeiroButtonVariant.ghost,
      onPressed: () => Navigator.of(context).pop(),
    );
    final confirm = YumeiroButton(
      key: const ValueKey('yumeiro-calendar-confirm'),
      label: messages.okButtonLabel,
      variant: YumeiroButtonVariant.primary,
      onPressed: _typing || _canConfirm ? _confirm : null,
    );
    final body = _typing
        ? _inputFields()
        : _calendar(modeToggle: compactHeader ? toggleMode : null);
    if (widget.touch) {
      final targetSize = YumeiroModalityScope.metricsOf(context).minTargetSize;
      return buildYumeiroPickerSheet(
        maxWidth: widget.range ? 776 : 392,
        anchor: widget.anchor,
        minAnchoredHeight: _typing
            ? targetSize * (widget.range ? 6 : 4)
            : _dayHeight(context) * 6 + targetSize * (widget.range ? 4 : 3),
        title: title,
        headerActions: [?toggleMode],
        actions: [cancel, confirm],
        child: body,
      );
    }
    return Semantics(
      container: compactHeader,
      namesRoute: compactHeader,
      label: compactHeader ? title : null,
      child: YumeiroScrollView(
        padding: EdgeInsets.symmetric(horizontal: theme.spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!compactHeader)
              YumeiroPageHeader.compact(
                title: title,
                namesRoute: true,
                actions: [?toggleMode],
              ),
            Padding(
              padding: EdgeInsets.only(
                top: compactHeader ? 0 : theme.spacing.xs,
                bottom: theme.spacing.sm,
              ),
              child: body,
            ),
            const YumeiroDivider(),
            Padding(
              padding: EdgeInsets.symmetric(vertical: theme.spacing.sm),
              child: Wrap(
                spacing: theme.spacing.sm,
                runSpacing: theme.spacing.xs,
                alignment: WrapAlignment.end,
                children: [cancel, confirm],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputFields() {
    final messages = _messages;
    Widget field({required bool end}) {
      final label = end
          ? messages.dateRangeEndLabel
          : widget.range
          ? messages.dateRangeStartLabel
          : messages.dateInputLabel;
      final error = end ? _endError : _startError;
      final done = end || !widget.range;
      return YumeiroFieldLayout(
        label: label,
        errorText: error,
        child: YumeiroTextField(
          key: ValueKey(
            end ? 'yumeiro-calendar-input-end' : 'yumeiro-calendar-input-start',
          ),
          controller: end ? _endText : _startText,
          semanticLabel: label,
          hintText: messages.dateHelpText,
          hasError: error != null,
          autofocus: !widget.touch && !end,
          keyboardType: TextInputType.datetime,
          textInputAction: done ? TextInputAction.done : TextInputAction.next,
          onSubmitted: done ? (_) => _confirm() : null,
          onChanged: (_) {
            if (_startError != null || _endError != null) {
              _readInput(showErrors: true);
            }
          },
        ),
      );
    }

    if (!widget.range) return field(end: false);
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = YumeiroTheme.of(context).spacing.md;
        final start = field(end: false);
        final end = field(end: true);
        final targetSize = YumeiroModalityScope.metricsOf(context)
            .minTargetSize;
        if (constraints.maxWidth >= targetSize * 10 + spacing) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: spacing,
            children: [
              Expanded(child: start),
              Expanded(child: end),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: spacing,
          children: [start, end],
        );
      },
    );
  }

  double _dayHeight(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final metrics = YumeiroModalityScope.metricsOf(context);
    final style = theme.typography.control(monospace: true);
    final lineHeight =
        MediaQuery.textScalerOf(context).scale(style.fontSize!) *
        (style.height ?? 1.2);
    return math.max(metrics.minTargetSize, lineHeight + theme.spacing.sm);
  }

  Widget _calendar({Widget? modeToggle}) => LayoutBuilder(
    builder: (context, constraints) {
      final theme = YumeiroTheme.of(context);
      final spacing = theme.spacing;
      final dayHeight = _dayHeight(context);
      final monthGap = spacing.md + spacing.xs;
      final doubleMonth =
          widget.range &&
          _firstMonth != _lastMonth &&
          constraints.maxWidth >= 14 * dayHeight + monthGap;
      final first = doubleMonth && _month == _lastMonth
          ? DateUtils.addMonthsToMonthDate(_month, -1)
          : _month;
      final last = doubleMonth
          ? DateUtils.addMonthsToMonthDate(first, 1)
          : first;
      final yearPicker = _yearPickerMonth;
      final focusDay =
          _monthOf(_focusDay).isBefore(first) ||
              _monthOf(_focusDay).isAfter(last) ||
              !_canPick(_focusDay)
          ? _firstSelectableDay(first, last)
          : _focusDay;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: spacing.sm,
        children: [
          if (widget.range) _rangeSummary(),
          if (yearPicker != null)
            _years(yearPicker, dayHeight)
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: monthGap,
              children: [
                Expanded(
                  child: _monthGrid(
                    first,
                    focusDay: focusDay,
                    dayHeight: dayHeight,
                    previous: true,
                    next: !doubleMonth,
                    canPrevious: first != _firstMonth,
                    canNext: last != _lastMonth,
                    modeToggle: modeToggle,
                  ),
                ),
                if (doubleMonth)
                  Expanded(
                    child: _monthGrid(
                      last,
                      focusDay: focusDay,
                      dayHeight: dayHeight,
                      previous: false,
                      next: true,
                      canPrevious: false,
                      canNext: last != _lastMonth,
                    ),
                  ),
              ],
            ),
        ],
      );
    },
  );

  DateTime? _firstSelectableDay(DateTime first, DateTime last) {
    final until = DateUtils.addMonthsToMonthDate(last, 1);
    for (
      var day = _clampDay(first);
      day.isBefore(until);
      day = DateUtils.addDaysToDate(day, 1)
    ) {
      if (_canPick(day)) return day;
    }
    return null;
  }

  Widget _rangeSummary() {
    final theme = YumeiroTheme.of(context);
    final inset = theme.visuals.surface(YumeiroSurfaceRole.inset);
    final accent = theme.visuals.status(YumeiroStatusRole.accent);
    final inherited = YumeiroVisualScope.maybeOf(context)?.visualOverride;
    final targetSize = YumeiroModalityScope.metricsOf(context).minTargetSize;
    Widget endpoint(String label, DateTime? value, _RangeTarget target) {
      final active =
          _target == target ||
          (_target == _RangeTarget.newStart && target == _RangeTarget.start);
      return Expanded(
        child: YumeiroInteractiveVisualSurface(
          role: YumeiroControlRole.neutral,
          selected: active,
          visualOverride: _CalendarEndpointAppearance(
            inset,
            active
                ? BorderSide(
                    color: accent.foreground,
                    width: math.max(1.0, inset.outline.width),
                  )
                : inset.outline,
            inherited,
          ),
          onTap: () => _editRangeEndpoint(target),
          padding: EdgeInsets.symmetric(
            horizontal: theme.spacing.sm,
            vertical: theme.spacing.xs,
          ),
          child: Builder(
            builder: (context) {
              final foreground = DefaultTextStyle.of(context).style.color;
              return ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: math.max(0, targetSize - 2 * theme.spacing.xs),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.typography.caption.copyWith(
                        color: foreground,
                      ),
                    ),
                    Text(
                      value == null
                          ? _messages.unspecifiedDate
                          : _messages.formatCompactDate(value),
                      style: theme.typography.body.copyWith(color: foreground),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    }

    return Row(
      children: [
        endpoint(_messages.dateRangeStartLabel, _start, _RangeTarget.start),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: theme.spacing.sm),
          child: Icon(Icons.arrow_forward, size: theme.iconSizes.sm),
        ),
        endpoint(_messages.dateRangeEndLabel, _end, _RangeTarget.end),
      ],
    );
  }

  Widget _monthGrid(
    DateTime month, {
    required DateTime? focusDay,
    required double dayHeight,
    required bool previous,
    required bool next,
    required bool canPrevious,
    required bool canNext,
    Widget? modeToggle,
  }) {
    final theme = YumeiroTheme.of(context);
    final metrics = YumeiroModalityScope.metricsOf(context);
    final targetSize = metrics.minTargetSize;
    final columnGap = widget.touch || widget.range ? 0.0 : theme.spacing.xs;
    final rowGap = widget.touch ? 0.0 : theme.spacing.xs / 2;
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final firstDayOffset = DateUtils.firstDayOffset(
      month.year,
      month.month,
      _messages,
    );
    const weekdayCount = DateTime.daysPerWeek;

    Widget arrow({required bool forward, required bool enabled}) =>
        YumeiroButton(
          key: ValueKey(
            forward
                ? 'yumeiro-calendar-next-month'
                : 'yumeiro-calendar-previous-month',
          ),
          icon: forward ? Icons.chevron_right : Icons.chevron_left,
          tooltip: forward
              ? _messages.nextMonthTooltip
              : _messages.previousMonthTooltip,
          variant: YumeiroButtonVariant.ghost,
          onPressed: enabled
              ? () {
                  // Both calendars move by one month. The next arrow lives on the later grid.
                  final base = previous
                      ? month
                      : DateUtils.addMonthsToMonthDate(month, -1);
                  _showMonth(
                    DateUtils.addMonthsToMonthDate(base, forward ? 1 : -1),
                  );
                }
              : null,
        );

    final monthTitle = YumeiroButton(
      label: _messages.formatMonthYear(month),
      tooltip: _messages.selectYearSemanticsLabel,
      trailingIcon: theme.icons.chevronDown,
      variant: YumeiroButtonVariant.ghost,
      onPressed: () => setState(() => _yearPickerMonth = month),
    );
    final days = Column(
      children: [
        Row(
          spacing: columnGap,
          children: [
            for (var i = 0; i < weekdayCount; i++)
              Expanded(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: widget.touch ? 28 : 24,
                  ),
                  child: Center(
                    child: ExcludeSemantics(
                      child: Text(
                        _messages.narrowWeekdays[(_messages
                                    .firstDayOfWeekIndex +
                                i) %
                            weekdayCount],
                        textAlign: TextAlign.center,
                        style: theme.typography.caption.copyWith(
                          color: theme.muted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        Column(
          key: ValueKey('yumeiro-calendar-month-${month.year}-${month.month}'),
          spacing: rowGap,
          children: [
            for (var week = 0; week < 6; week++)
              Row(
                spacing: columnGap,
                children: [
                  for (var col = 0; col < weekdayCount; col++)
                    Expanded(
                      child: SizedBox(
                        height: dayHeight,
                        child: _gridCell(
                          month,
                          week * weekdayCount + col - firstDayOffset + 1,
                          daysInMonth,
                          focusDay,
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ],
    );
    final actionGap = widget.touch ? 0.0 : theme.spacing.xs;
    return Column(
      children: [
        if (widget.range)
          Row(
            children: [
              if (previous)
                arrow(forward: false, enabled: canPrevious)
              else
                SizedBox(width: targetSize),
              Expanded(child: monthTitle),
              if (next)
                arrow(forward: true, enabled: canNext)
              else
                SizedBox(width: targetSize),
            ],
          )
        else ...[
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: metrics.minTargetSize),
            child: YumeiroSettingRowHeader(
              title: monthTitle,
              spacing: actionGap,
              runSpacing: theme.spacing.xs,
              trailing: Wrap(
                spacing: actionGap,
                runSpacing: theme.spacing.xs,
                alignment: WrapAlignment.end,
                children: [
                  arrow(forward: false, enabled: canPrevious),
                  arrow(forward: true, enabled: canNext),
                  ?modeToggle,
                ],
              ),
            ),
          ),
          if (!widget.touch) const YumeiroDivider(),
        ],
        if (widget.range || widget.touch)
          days
        else
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth:
                  weekdayCount * targetSize + (weekdayCount - 1) * columnGap,
            ),
            child: days,
          ),
      ],
    );
  }

  Widget? _gridCell(
    DateTime month,
    int dayOfMonth,
    int daysInMonth,
    DateTime? focusDay,
  ) {
    if (dayOfMonth < 1 || dayOfMonth > daysInMonth) return null;
    final day = DateTime(month.year, month.month, dayOfMonth);
    final selectable = _canPick(day);
    final start = _start;
    final hoveringEnd = _hoverDate;
    final end = _end ?? hoveringEnd;
    final today = day == _today;
    final selected = day == start || day == _end;
    final band =
        widget.range &&
        start != null &&
        end != null &&
        start != end &&
        !day.isBefore(start) &&
        !day.isAfter(end);
    final formatted = _messages.formatFullDate(day);
    var label = formatted;
    if (widget.range && day == start) {
      label = _messages.dateRangeStartDateSemanticLabel(formatted);
    }
    if (widget.range && day == _end) {
      final endLabel = _messages.dateRangeEndDateSemanticLabel(formatted);
      label = day == start ? '$label, $endLabel' : endLabel;
    }
    if (today) label = '$label, ${_messages.currentDateLabel}';
    final previewable =
        !widget.touch &&
        selectable &&
        _target == _RangeTarget.end &&
        start != null &&
        _end == null &&
        !day.isBefore(start);

    return _CalendarDayCell(
      key: ValueKey('yumeiro-calendar-day-${day.year}-${day.month}-${day.day}'),
      day: day,
      nodes: _dayFocus,
      label: label,
      text: _messages.formatDecimal(day.day),
      selected: selected,
      today: today,
      tabStop: focusDay == day,
      band: band,
      bandStarts: day == start,
      bandEnds: day == end,
      preview: _end == null,
      onTap: selectable ? () => _select(day) : null,
      onHover: previewable
          ? (inside) {
              if (!inside && _hoverDate != day) return;
              setState(() => _hoverDate = inside ? day : null);
            }
          : null,
      onKey: (event) => _onDayKey(day, event),
    );
  }

  Widget _years(DateTime from, double rowHeight) {
    final theme = YumeiroTheme.of(context);
    final firstYear = widget.firstDate.year;
    final count = widget.lastDate.year - firstYear + 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        YumeiroButton(
          label: _messages.formatMonthYear(from),
          tooltip: _messages.calendarModeButtonLabel,
          trailingIcon: theme.icons.chevronUp,
          variant: YumeiroButtonVariant.ghost,
          onPressed: () => setState(() => _yearPickerMonth = null),
        ),
        SizedBox(
          height: math.min(6, (count + 2) ~/ 3) * rowHeight,
          child: _CalendarYearGrid(
            key: const ValueKey('yumeiro-calendar-year-picker'),
            firstYear: firstYear,
            count: count,
            currentYear: from.year,
            rowHeight: rowHeight,
            rowGap: theme.spacing.xs,
            onSelected: (year) =>
                _showMonth(_monthOf(_clampDay(DateTime(year, from.month)))),
          ),
        ),
      ],
    );
  }
}

class _CalendarEndpointAppearance extends YumeiroVisualOverride {
  const _CalendarEndpointAppearance(this.inset, this.outline, this.inherited);

  final YumeiroVisualAppearance inset;
  final BorderSide outline;
  final YumeiroVisualOverride? inherited;

  @override
  YumeiroVisualAppearance apply(
    YumeiroVisualAppearance appearance,
    Set<WidgetState> widgetStates,
  ) {
    final resolved = appearance.copyWith(
      fill: inset.fill,
      foreground: inset.foreground,
      shape: inset.shape,
      outline: outline,
      effects: inset.effects,
    );
    return inherited?.apply(resolved, widgetStates) ?? resolved;
  }
}

class _CalendarDayCell extends StatefulWidget {
  const _CalendarDayCell({
    super.key,
    required this.day,
    required this.nodes,
    required this.label,
    required this.text,
    required this.selected,
    required this.today,
    required this.tabStop,
    required this.band,
    required this.bandStarts,
    required this.bandEnds,
    required this.preview,
    required this.onTap,
    required this.onHover,
    required this.onKey,
  });

  final DateTime day;
  final Map<DateTime, FocusNode> nodes;
  final String label;
  final String text;
  final bool selected;
  final bool today;
  final bool tabStop;
  final bool band;
  final bool bandStarts;
  final bool bandEnds;
  final bool preview;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onHover;
  final KeyEventResult Function(KeyEvent) onKey;

  @override
  State<_CalendarDayCell> createState() => _CalendarDayCellState();
}

class _CalendarDayCellState extends State<_CalendarDayCell> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.nodes[widget.day] = _focus;
  }

  @override
  void dispose() {
    if (widget.nodes[widget.day] == _focus) widget.nodes.remove(widget.day);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final metrics = YumeiroModalityScope.metricsOf(context);
    final accent = theme.visuals.status(YumeiroStatusRole.accent);
    final inset = metrics.controlVisualInsets.top;
    final fill = accent.subtleFill;
    final band = Padding(
      padding: EdgeInsets.symmetric(vertical: inset),
      child: ColoredBox(
        color: widget.preview ? fill.withValues(alpha: fill.a * .65) : fill,
      ),
    );
    final endpoint = widget.bandStarts || widget.bandEnds;
    final target = YumeiroInteractiveVisualSurface(
      role: widget.selected
          ? YumeiroControlRole.primary
          : YumeiroItemRole.selection,
      selected: widget.selected,
      visualInsets: EdgeInsets.symmetric(horizontal: 1, vertical: inset),
      focusNode: _focus,
      onTap: widget.onTap,
      child: ExcludeSemantics(
        child: Builder(
          builder: (context) {
            final foreground =
                DefaultTextStyle.of(context).style.color ?? theme.text;
            final tint = widget.selected || widget.onTap == null
                ? foreground
                : accent.foreground;
            final style = theme.typography
                .control(monospace: true)
                .copyWith(
                  fontWeight:
                      widget.selected || (widget.today && widget.onTap != null)
                      ? theme.typography.emphasisWeight
                      : null,
                  color: widget.today ? tint : foreground,
                );
            final label = Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(widget.text, style: style, maxLines: 1),
              ),
            );
            if (!widget.today) return label;

            final shape = theme.visuals
                .surface(YumeiroSurfaceRole.compact)
                .shape;
            final side = BorderSide(color: tint, width: 1.5);
            final markerShape = switch (shape) {
              RoundedRectangleBorder(:final borderRadius) => shape.copyWith(
                borderRadius: borderRadius * 2,
                side: side,
              ),
              _ => shape.copyWith(side: side),
            };
            final painter = TextPainter(
              text: TextSpan(text: widget.text, style: style),
              textDirection: Directionality.of(context),
              textScaler: MediaQuery.textScalerOf(context),
              maxLines: 1,
            )..layout();
            final labelExtent = painter.size.longestSide;
            painter.dispose();
            return Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final available = constraints
                      .deflate(
                        EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: inset + 1,
                        ),
                      )
                      .biggest
                      .shortestSide;
                  final diameter = math.min(
                    available,
                    math.max(
                      metrics.denseChipHeight,
                      labelExtent + theme.spacing.sm,
                    ),
                  );
                  return SizedBox.square(
                    dimension: diameter,
                    child: DecoratedBox(
                      key: const ValueKey('yumeiro-calendar-today-marker'),
                      decoration: ShapeDecoration(shape: markerShape),
                      child: label,
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
    final preview = widget.onHover;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (widget.band)
          if (endpoint)
            FractionallySizedBox(
              widthFactor: .5,
              alignment: widget.bandStarts
                  ? AlignmentDirectional.centerEnd
                  : AlignmentDirectional.centerStart,
              child: band,
            )
          else
            band,
        Focus(
          canRequestFocus: false,
          descendantsAreTraversable: widget.tabStop,
          onKeyEvent: (_, event) => widget.onKey(event),
          child: MouseRegion(
            onEnter: preview == null ? null : (_) => preview(true),
            onExit: preview == null ? null : (_) => preview(false),
            child: Semantics(
              label: widget.label,
              button: true,
              selected: widget.selected,
              enabled: widget.onTap != null,
              child: target,
            ),
          ),
        ),
      ],
    );
  }
}

class _CalendarYearGrid extends StatefulWidget {
  const _CalendarYearGrid({
    super.key,
    required this.firstYear,
    required this.count,
    required this.currentYear,
    required this.rowHeight,
    required this.rowGap,
    required this.onSelected,
  });

  final int firstYear;
  final int count;
  final int currentYear;
  final double rowHeight;
  final double rowGap;
  final ValueChanged<int> onSelected;

  @override
  State<_CalendarYearGrid> createState() => _CalendarYearGridState();
}

class _CalendarYearGridState extends State<_CalendarYearGrid> {
  late final _scroll = ScrollController(
    initialScrollOffset:
        math.max(0, (widget.currentYear - widget.firstYear) ~/ 3 - 2) *
        widget.rowHeight,
  );

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = MaterialLocalizations.of(context);
    final fontSize = YumeiroTheme.of(context).typography.caption.fontSize;
    return Semantics(
      label: messages.selectYearSemanticsLabel,
      child: GridView.builder(
        controller: _scroll,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisExtent: widget.rowHeight,
          crossAxisSpacing: widget.rowGap,
        ),
        itemCount: widget.count,
        itemBuilder: (context, index) {
          final year = widget.firstYear + index;
          return YumeiroButton(
            label: messages.formatYear(DateTime(year)),
            monospace: true,
            selected: year == widget.currentYear,
            variant: YumeiroButtonVariant.ghost,
            fontSize: fontSize,
            onPressed: () => widget.onSelected(year),
          );
        },
      ),
    );
  }
}
