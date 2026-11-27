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
  String get _separator => switch (_format) {
    TimeOfDayFormat.HH_dot_mm => '.',
    TimeOfDayFormat.frenchCanadian => 'h',
    _ => ':',
  };

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
    required TextStyle style,
    required double? height,
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
        style: style,
        height: height,
      ),
    );
  }

  Widget _numberReadouts(BuildContext context, MaterialLocalizations messages) {
    final theme = YumeiroTheme.of(context);
    final metrics = YumeiroModalityScope.metricsOf(context);
    final number = theme.typography.mono(
      fontSize: 22,
      fontWeight: theme.typography.emphasisWeight,
    );
    final fieldHeight = math.max(
      44.0,
      yumeiroPickerMinHeight(context, metrics, !widget.touch, style: number),
    );
    final fieldWidth = math.max(
      84.0,
      MediaQuery.textScalerOf(context).scale(number.fontSize!) * 2 +
          yumeiroPickerHorizontalPadding(metrics, !widget.touch) * 2,
    );
    Widget readout(String text) => YumeiroVisualSurface(
      role: YumeiroSurfaceRole.readout,
      child: SizedBox(
        height: fieldHeight,
        child: Center(child: Text(text, style: number, maxLines: 1)),
      ),
    );
    final hour = _showFields
        ? _numberField(
            isHour: true,
            messages: messages,
            style: number,
            height: widget.touch ? null : fieldHeight,
          )
        : readout(_hourText(messages, _displayHour(_draft)));
    final minute = _showFields
        ? _numberField(
            isHour: false,
            messages: messages,
            style: number,
            height: widget.touch ? null : fieldHeight,
          )
        : readout(_minuteText(messages, _draft.minute));
    final pair = ConstrainedBox(
      constraints: BoxConstraints(minHeight: widget.touch ? 0 : 48),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: theme.spacing.xs,
          children: [
            Flexible(
              child: SizedBox(width: fieldWidth, child: hour),
            ),
            Text(
              _separator,
              style: number.copyWith(fontSize: 20, color: theme.muted),
            ),
            Flexible(
              child: SizedBox(width: fieldWidth, child: minute),
            ),
          ],
        ),
      ),
    );
    return YumeiroFieldLayout(
      errorText: _showFields && _showError ? messages.invalidTimeLabel : null,
      child: pair,
    );
  }

  Widget _touchReadout(BuildContext context, MaterialLocalizations messages) {
    final theme = YumeiroTheme.of(context);
    final metrics = YumeiroModalityScope.metricsOf(context);
    final formattedTime = messages.formatTimeOfDay(
      _draft,
      alwaysUse24HourFormat: widget.alwaysUse24HourFormat,
    );
    final iconSize = theme.iconSizes.sm;
    final content = ConstrainedBox(
      constraints: BoxConstraints(minHeight: metrics.minTargetSize),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: theme.spacing.sm),
        child: Row(
          children: [
            if (_canSwitch) SizedBox(width: iconSize),
            Expanded(
              child: Text(
                formattedTime,
                textAlign: TextAlign.center,
                style: theme.typography.mono(
                  fontSize: 24,
                  fontWeight: theme.typography.emphasisWeight,
                ),
              ),
            ),
            if (_canSwitch)
              Icon(theme.icons.edit, size: iconSize, color: theme.muted),
          ],
        ),
      ),
    );
    if (!_canSwitch) {
      return YumeiroVisualSurface(
        role: YumeiroSurfaceRole.readout,
        child: content,
      );
    }
    final readout = theme.visuals.surface(YumeiroSurfaceRole.readout);
    return Tooltip(
      message: messages.inputTimeModeButtonLabel,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        label: messages.inputTimeModeButtonLabel,
        value: formattedTime,
        child: YumeiroInteractiveVisualSurface(
          role: YumeiroControlRole.secondary,
          visualOverride: YumeiroVisualOverride(
            base: YumeiroVisualDelta(
              fill: readout.fill,
              shape: readout.shape,
              outline: readout.outline,
              effects: readout.effects,
              foreground: readout.foreground,
            ),
          ),
          onTap: _switchMode,
          child: ExcludeSemantics(child: content),
        ),
      ),
    );
  }

  Widget _choices(BuildContext context, MaterialLocalizations messages) {
    final theme = YumeiroTheme.of(context);
    final metrics = YumeiroModalityScope.metricsOf(context);
    final touch = widget.touch;
    final numberStyle = theme.typography.mono(fontSize: touch ? 20 : 13);
    final extent = math.max(
      metrics.minTargetSize,
      MediaQuery.textScalerOf(context).scale(numberStyle.fontSize!) *
              (numberStyle.height ?? 1.2) +
          theme.spacing.xs,
    );
    Widget label(String text) => Expanded(
      child: ExcludeSemantics(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: theme.spacing.xs),
          child: Text(
            text,
            style: theme.typography.caption.copyWith(color: theme.muted),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
    final hours = messages.timePickerHourLabel;
    final minutes = messages.timePickerMinuteLabel;
    final columns = Row(
      children: [
        Expanded(
          child: _TimeChoices(
            key: ValueKey(('hours', _hourCount, touch, extent)),
            count: _hourCount,
            selectedIndex: _displayHour(_draft) - _firstHour,
            label: hours,
            text: (index) => _hourText(messages, index + _firstHour),
            onChanged: (index) => _selectHour(index + _firstHour),
            extent: extent,
            touch: touch,
          ),
        ),
        if (!touch) VerticalDivider(width: 1, thickness: 1, color: theme.line),
        Expanded(
          child: _TimeChoices(
            key: ValueKey(('minutes', touch, extent)),
            count: 60,
            selectedIndex: _draft.minute,
            label: minutes,
            text: (index) => _minuteText(messages, index),
            onChanged: _selectMinute,
            extent: extent,
            touch: touch,
          ),
        ),
      ],
    );
    final accent = theme.visuals.status(YumeiroStatusRole.accent);
    final readout = theme.visuals.surface(YumeiroSurfaceRole.readout);
    return YumeiroVisualSurface(
      role: YumeiroSurfaceRole.inset,
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: touch ? 28 : 26),
            child: Row(children: [label(hours), label(minutes)]),
          ),
          SizedBox(
            height: extent * (touch ? 5 : 6),
            child: touch
                ? Stack(
                    alignment: Alignment.center,
                    fit: StackFit.expand,
                    children: [
                      Positioned(
                        left: theme.spacing.sm,
                        right: theme.spacing.sm,
                        top: extent * 2,
                        height: extent,
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: ShapeDecoration(
                              color: accent.subtleFill,
                              shape: readout.shape.copyWith(
                                side: BorderSide(
                                  color: accent.foreground.withValues(
                                    alpha: .25,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      columns,
                      IgnorePointer(
                        child: ExcludeSemantics(
                          child: Center(
                            child: Text(
                              _separator,
                              style: theme.typography.mono(
                                fontSize: 18,
                                fontWeight: theme.typography.emphasisWeight,
                                color: theme.muted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : columns,
          ),
        ],
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
    final toggle = _canSwitch
        ? YumeiroButton(
            icon: _inputMode ? Icons.schedule_outlined : theme.icons.edit,
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
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.spacing.sm,
      children: [
        if (_showFields || !widget.touch)
          _numberReadouts(context, messages)
        else
          _touchReadout(context, messages),
        if (!_use24Hours)
          YumeiroSegmentedControl<DayPeriod>(
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
        if (!_inputMode) _choices(context, messages),
      ],
    );
    if (widget.touch) {
      return buildYumeiroPickerSheet(
        title: title,
        anchor: widget.anchor,
        maxWidth: 360,
        minAnchoredHeight: _inputMode ? 260 : 460,
        headerActions: [?toggle],
        actions: [cancel, confirm],
        child: body,
      );
    }
    return YumeiroScrollView(
      padding: EdgeInsets.fromLTRB(
        theme.spacing.md,
        0,
        theme.spacing.md,
        theme.spacing.xs,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: theme.spacing.xs,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: theme.line)),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: metrics.minTargetSize),
              child: Row(
                spacing: theme.spacing.xs,
                children: [
                  Expanded(
                    child: Semantics(
                      container: true,
                      namesRoute: true,
                      child: Text(title, style: theme.typography.title),
                    ),
                  ),
                  ?toggle,
                ],
              ),
            ),
          ),
          body,
          Container(
            padding: EdgeInsets.only(top: theme.spacing.sm),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: theme.line)),
            ),
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: theme.spacing.sm,
              runSpacing: theme.spacing.xs,
              children: [cancel, confirm],
            ),
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
    Widget choice(BuildContext context, int index) {
      final distance = (index - widget.selectedIndex).abs();
      final selected = distance == 0;
      final text = widget.text(index);
      final style = theme.typography.mono(
        fontSize: widget.touch
            ? switch (distance) {
                0 => 20,
                1 => 16,
                _ => 14,
              }
            : 13,
        fontWeight: selected
            ? theme.typography.emphasisWeight
            : theme.typography.bodyWeight,
      );
      return Semantics(
        button: true,
        selected: selected,
        label: '${widget.label} $text',
        child: YumeiroInteractiveVisualSurface(
          role: selected && !widget.touch
              ? YumeiroControlRole.primary
              : YumeiroItemRole.selection,
          // The touch wheels share a single selection surface behind the rows.
          visualOverride: widget.touch
              ? const YumeiroVisualOverride(
                  base: YumeiroVisualDelta(
                    fillOpacity: 0,
                    outline: BorderSide.none,
                    effects: YumeiroEffectStack.none,
                  ),
                )
              : null,
          visualInsets: widget.touch
              ? null
              : const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          selected: selected,
          onTap: () => widget.onChanged(index),
          child: Center(
            child: ExcludeSemantics(
              child: Builder(
                builder: (context) => Text(
                  text,
                  style: style.copyWith(
                    color: widget.touch
                        ? switch (distance) {
                            0 => theme.text,
                            1 => theme.muted,
                            _ => theme.subtle,
                          }
                        : DefaultTextStyle.of(context).style.color,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return widget.touch
        ? ListWheelScrollView.useDelegate(
            key: ValueKey(widget.label),
            controller: _controller,
            itemExtent: widget.extent,
            diameterRatio: 4,
            perspective: .001,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: widget.onChanged,
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: widget.count,
              builder: choice,
            ),
          )
        : ListView.builder(
            padding: EdgeInsets.zero,
            controller: _controller,
            itemExtent: widget.extent,
            itemCount: widget.count,
            itemBuilder: choice,
          );
  }
}
