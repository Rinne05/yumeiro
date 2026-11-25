part of 'date_time_pickers.dart';

class _TimePickerPanel extends StatefulWidget {
  const _TimePickerPanel({
    required this.initialTime,
    required this.initialEntryMode,
    required this.touch,
    required this.anchor,
    required this.alwaysUse24HourFormat,
  });

  final TimeOfDay initialTime;
  final YumeiroTimePickerEntryMode initialEntryMode;
  final bool touch;
  final Rect? anchor;
  final bool alwaysUse24HourFormat;

  @override
  State<_TimePickerPanel> createState() => _TimePickerPanelState();
}

class _TimePickerPanelState extends State<_TimePickerPanel> {
  final _hour = TextEditingController();
  final _minute = TextEditingController();
  late TimeOfDay _draft = widget.initialTime;
  late bool _inputMode = switch (widget.initialEntryMode) {
    YumeiroTimePickerEntryMode.input ||
    YumeiroTimePickerEntryMode.inputOnly => true,
    _ => false,
  };
  late TimeOfDayFormat _format;
  bool _initialized = false;
  bool _showError = false;

  bool get _canSwitch => switch (widget.initialEntryMode) {
    YumeiroTimePickerEntryMode.list || YumeiroTimePickerEntryMode.input => true,
    _ => false,
  };
  bool get _showFields =>
      _inputMode ||
      (!widget.touch &&
          widget.initialEntryMode != YumeiroTimePickerEntryMode.listOnly);
  bool get _use24Hours => hourFormat(of: _format) != HourFormat.h;
  int get _firstHour => _use24Hours ? 0 : 1;
  int get _hourCount => _use24Hours ? 24 : 12;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final messages = MaterialLocalizations.of(context);
    final format = messages.timeOfDayFormat(
      alwaysUse24HourFormat: widget.alwaysUse24HourFormat,
    );
    if (_initialized && format == _format) return;
    _initialized = true;
    _format = format;
    _writeFields(messages);
  }

  @override
  void dispose() {
    _hour.dispose();
    _minute.dispose();
    super.dispose();
  }

  int _displayHour(TimeOfDay value) =>
      _use24Hours ? value.hour : value.hourOfPeriod;

  int _clockHour(int hour) =>
      _use24Hours ? hour : hour % 12 + _draft.periodOffset;

  String _hourText(MaterialLocalizations messages, int hour) =>
      messages.formatHour(
        TimeOfDay(hour: _clockHour(hour), minute: 0),
        alwaysUse24HourFormat: widget.alwaysUse24HourFormat,
      );

  String _minuteText(MaterialLocalizations messages, int minute) =>
      messages.formatMinute(TimeOfDay(hour: 0, minute: minute));

  void _writeFields(MaterialLocalizations messages) {
    _hour.text = _hourText(messages, _displayHour(_draft));
    _minute.text = _minuteText(messages, _draft.minute);
  }

  int? _readNumber(String text) {
    final messages = MaterialLocalizations.of(context);
    var digits = text.trim();
    for (var digit = 0; digit <= 9; digit++) {
      digits = digits.replaceAll(messages.formatDecimal(digit), '$digit');
    }
    return int.tryParse(digits);
  }

  TimeOfDay? _readFields() {
    final hour = _readNumber(_hour.text);
    final minute = _readNumber(_minute.text);
    if (hour == null ||
        hour < _firstHour ||
        hour >= _firstHour + _hourCount ||
        minute == null ||
        minute < 0 ||
        minute > 59) {
      return null;
    }
    return TimeOfDay(hour: _clockHour(hour), minute: minute);
  }

  void _textChanged(String _) {
    setState(() {
      _draft = _readFields() ?? _draft;
      _showError = false;
    });
  }

  void _selectHour(int hour) {
    setState(() {
      _draft = _draft.replacing(hour: _clockHour(hour));
      _hour.text = _hourText(MaterialLocalizations.of(context), hour);
      _showError = false;
    });
  }

  void _selectMinute(int minute) {
    setState(() {
      _draft = _draft.replacing(minute: minute);
      _minute.text = _minuteText(MaterialLocalizations.of(context), minute);
      _showError = false;
    });
  }

  void _setPeriod(DayPeriod period) {
    setState(() {
      _draft = _draft.replacing(
        hour: _draft.hour % 12 + (period == DayPeriod.pm ? 12 : 0),
      );
      _draft = _readFields() ?? _draft;
    });
  }

  void _switchMode() {
    setState(() {
      _draft = _readFields() ?? _draft;
      _writeFields(MaterialLocalizations.of(context));
      _inputMode = !_inputMode;
      _showError = false;
    });
  }

  void _confirm() {
    final value = _showFields ? _readFields() : _draft;
    if (value == null) {
      setState(() => _showError = true);
      return;
    }
    Navigator.of(context).pop(value);
  }

  Widget _numberField({
    required bool isHour,
    required MaterialLocalizations messages,
  }) {
    final first = isHour ? _firstHour : 0;
    final count = isHour ? _hourCount : 60;
    final current = isHour ? _displayHour(_draft) : _draft.minute;
    final select = isHour ? _selectHour : _selectMinute;
    return Focus(
      canRequestFocus: false,
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
          return KeyEventResult.ignored;
        }
        final step = switch (event.logicalKey) {
          LogicalKeyboardKey.arrowUp => 1,
          LogicalKeyboardKey.arrowDown => -1,
          _ => 0,
        };
        if (step == 0) return KeyEventResult.ignored;
        select(first + (current - first + step) % count);
        return KeyEventResult.handled;
      },
      child: YumeiroTextField(
        key: ValueKey(isHour ? 'yumeiro-time-hour' : 'yumeiro-time-minute'),
        controller: isHour ? _hour : _minute,
        semanticLabel: isHour
            ? messages.timePickerHourLabel
            : messages.timePickerMinuteLabel,
        autofocus: isHour && _inputMode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [LengthLimitingTextInputFormatter(2)],
        textInputAction: isHour ? TextInputAction.next : TextInputAction.done,
        onChanged: _textChanged,
        onSubmitted: isHour ? null : (_) => _confirm(),
        dense: !widget.touch,
        hasError: _showError,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final metrics = YumeiroModalityScope.metricsOf(context);
    final messages = MaterialLocalizations.of(context);
    final title = _inputMode
        ? messages.timePickerInputHelpText
        : messages.timePickerDialHelpText;
    final formattedTime = messages.formatTimeOfDay(
      _draft,
      alwaysUse24HourFormat: widget.alwaysUse24HourFormat,
    );
    final toggle = _canSwitch
        ? YumeiroButton(
            icon: _inputMode ? Icons.schedule_outlined : Icons.edit_outlined,
            variant: YumeiroButtonVariant.ghost,
            tooltip: _inputMode
                ? messages.timePickerDialHelpText
                : messages.inputTimeModeButtonLabel,
            onPressed: _switchMode,
          )
        : null;
    final cancel = YumeiroButton(
      variant: YumeiroButtonVariant.ghost,
      label: messages.cancelButtonLabel,
      onPressed: () => Navigator.of(context).pop(),
    );
    final confirm = YumeiroButton(
      variant: YumeiroButtonVariant.primary,
      label: messages.okButtonLabel,
      onPressed: _confirm,
    );
    final numberStyle = theme.typography.control(monospace: true);
    final extent = math.max(
      metrics.denseTargetSize,
      MediaQuery.textScalerOf(context).scale(numberStyle.fontSize!) *
              (numberStyle.height ?? 1.2) +
          theme.spacing.xs,
    );
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.spacing.sm,
      children: [
        if (_showFields)
          YumeiroFieldLayout(
            errorText: _showError ? messages.invalidTimeLabel : null,
            child: Row(
              spacing: theme.spacing.xs,
              children: [
                Expanded(child: _numberField(isHour: true, messages: messages)),
                Text(switch (_format) {
                  TimeOfDayFormat.HH_dot_mm => '.',
                  TimeOfDayFormat.frenchCanadian => 'h',
                  _ => ':',
                }),
                Expanded(
                  child: _numberField(isHour: false, messages: messages),
                ),
              ],
            ),
          )
        else if (_canSwitch)
          YumeiroButton(
            label: formattedTime,
            tooltip: messages.inputTimeModeButtonLabel,
            onPressed: _switchMode,
          )
        else
          YumeiroVisualSurface(
            role: YumeiroSurfaceRole.readout,
            padding: EdgeInsets.all(theme.spacing.sm),
            child: Center(
              child: Text(formattedTime, style: theme.typography.title),
            ),
          ),
        if (!_use24Hours)
          YumeiroSegmentedControl<DayPeriod>(
            dense: !widget.touch,
            expand: true,
            value: _draft.period,
            onChanged: _setPeriod,
            options: [
              YumeiroSegmentOption(
                value: DayPeriod.am,
                label: messages.anteMeridiemAbbreviation,
              ),
              YumeiroSegmentOption(
                value: DayPeriod.pm,
                label: messages.postMeridiemAbbreviation,
              ),
            ],
          ),
        if (!_inputMode)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: theme.spacing.sm,
            children: [
              Expanded(
                child: _TimeChoices(
                  key: ValueKey(('hours', _hourCount)),
                  count: _hourCount,
                  selectedIndex: _displayHour(_draft) - _firstHour,
                  label: messages.timePickerHourLabel,
                  text: (index) => _hourText(messages, index + _firstHour),
                  onChanged: (index) => _selectHour(index + _firstHour),
                  extent: extent,
                  touch: widget.touch,
                ),
              ),
              Expanded(
                child: _TimeChoices(
                  count: 60,
                  selectedIndex: _draft.minute,
                  label: messages.timePickerMinuteLabel,
                  text: (index) => _minuteText(messages, index),
                  onChanged: _selectMinute,
                  extent: extent,
                  touch: widget.touch,
                ),
              ),
            ],
          ),
      ],
    );
    if (widget.touch) {
      return YumeiroBottomSheet(
        title: title,
        anchor: widget.anchor,
        maxWidth: 392,
        minAnchoredHeight: _inputMode ? 260 : 370,
        actions: [cancel, confirm],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_inputMode && toggle != null)
              Align(alignment: AlignmentDirectional.centerEnd, child: toggle),
            body,
          ],
        ),
      );
    }
    return YumeiroScrollView(
      padding: EdgeInsets.all(theme.spacing.xs),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: theme.spacing.sm,
        children: [
          YumeiroPageHeader.compact(
            title: title,
            namesRoute: true,
            actions: [?toggle],
          ),
          body,
          Wrap(
            alignment: WrapAlignment.end,
            spacing: theme.spacing.sm,
            runSpacing: theme.spacing.xs,
            children: [cancel, confirm],
          ),
        ],
      ),
    );
  }
}

class _TimeChoices extends StatefulWidget {
  const _TimeChoices({
    super.key,
    required this.count,
    required this.selectedIndex,
    required this.label,
    required this.text,
    required this.onChanged,
    required this.extent,
    required this.touch,
  });

  final int count;
  final int selectedIndex;
  final String label;
  final String Function(int) text;
  final ValueChanged<int> onChanged;
  final double extent;
  final bool touch;

  @override
  State<_TimeChoices> createState() => _TimeChoicesState();
}

class _TimeChoicesState extends State<_TimeChoices> {
  late final ScrollController _controller = widget.touch
      ? FixedExtentScrollController(initialItem: widget.selectedIndex)
      : ScrollController(
          initialScrollOffset:
              (widget.selectedIndex > 2 ? widget.selectedIndex - 2 : 0) *
              widget.extent,
        );

  @override
  void didUpdateWidget(_TimeChoices oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex == widget.selectedIndex ||
        !_controller.hasClients) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients) return;
      final index = widget.selectedIndex;
      final controller = _controller;
      if (controller is FixedExtentScrollController) {
        if (controller.selectedItem != index) controller.jumpToItem(index);
      } else {
        final position = controller.position;
        final start = index * widget.extent;
        final end = start + widget.extent;
        if (start < position.pixels ||
            end > position.pixels + position.viewportDimension) {
          controller.jumpTo(
            start.clamp(position.minScrollExtent, position.maxScrollExtent),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final style = theme.typography.control(monospace: true);
    Widget? choice(BuildContext context, int index) =>
        YumeiroInteractiveVisualSurface(
          role: YumeiroItemRole.selection,
          selected: widget.selectedIndex == index,
          onTap: () => widget.onChanged(index),
          child: Center(
            child: Semantics(
              label: '${widget.label} ${widget.text(index)}',
              excludeSemantics: true,
              child: Builder(
                builder: (context) => Text(
                  widget.text(index),
                  style: style.copyWith(
                    color: DefaultTextStyle.of(context).style.color,
                  ),
                ),
              ),
            ),
          ),
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.spacing.xs,
      children: [
        ExcludeSemantics(
          child: Text(
            widget.label,
            style: theme.typography.supporting.copyWith(color: theme.muted),
            textAlign: TextAlign.center,
          ),
        ),
        YumeiroVisualSurface(
          role: YumeiroSurfaceRole.inset,
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: widget.extent * (widget.touch ? 3 : 5),
            child: widget.touch
                ? ListWheelScrollView.useDelegate(
                    key: ValueKey(widget.label),
                    controller: _controller,
                    itemExtent: widget.extent,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: widget.onChanged,
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: widget.count,
                      builder: choice,
                    ),
                  )
                : ListView.builder(
                    controller: _controller,
                    itemExtent: widget.extent,
                    itemCount: widget.count,
                    itemBuilder: choice,
                  ),
          ),
        ),
      ],
    );
  }
}
