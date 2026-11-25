part of 'sheets.dart';

class _InlineOption<T> extends StatefulWidget {
  const _InlineOption({
    required _SelectionOptionKey<T> super.key,
    required this.option,
    required this.selected,
    required this.enabled,
    required this.readOnly,
    required this.dense,
    required this.multiple,
    required this.reportRepeat,
    required this.autofocus,
    required this.revealKey,
    required this.onPressed,
  });

  final YumeiroSelectionOption<T> option;
  final bool selected;
  final bool enabled;
  final bool readOnly;
  final bool dense;
  final bool multiple;
  final bool reportRepeat;
  final bool autofocus;
  final Key? revealKey;
  final VoidCallback onPressed;

  @override
  State<_InlineOption<T>> createState() => _InlineOptionState<T>();
}

class _InlineOptionState<T> extends State<_InlineOption<T>> {
  late final _focusNode = FocusNode()..addListener(_revealFocusedRadio);

  void _revealFocusedRadio() {
    if (!_focusNode.hasPrimaryFocus ||
        !YumeiroInputScope.keyboardFocusOf(context)) {
      return;
    }
    final row = context.findRenderObject();
    if (row == null || !row.attached) return;
    final viewport = RenderAbstractViewport.maybeOf(row);
    if (viewport == null) return;
    final bounds = MatrixUtils.transformRect(
      row.getTransformTo(viewport),
      row.paintBounds,
    );
    if (bounds.top < viewport.paintBounds.top) {
      Scrollable.ensureVisible(
        context,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      );
    } else if (bounds.bottom > viewport.paintBounds.bottom) {
      Scrollable.ensureVisible(
        context,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  bool get _interactive => widget.enabled && !widget.readOnly;

  Widget _content(BuildContext context, {required bool selected}) {
    final theme = YumeiroTheme.of(context);
    final metrics = YumeiroModalityScope.metricsOf(context);
    final foreground = DefaultTextStyle.of(context).style.color;
    final option = widget.option;
    final textOverflow = metrics.isTouch
        ? TextOverflow.clip
        : TextOverflow.ellipsis;
    return ConstrainedBox(
      key: widget.revealKey,
      constraints: BoxConstraints(
        minHeight: widget.dense
            ? metrics.denseTargetSize
            : metrics.minTargetSize,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: theme.spacing.sm,
          vertical: widget.dense ? theme.spacing.xs : theme.spacing.sm,
        ),
        child: Row(
          spacing: theme.spacing.sm,
          children: [
            SizedBox(
              width: selectionIndicatorWidth(metrics),
              child: Center(
                child: buildSelectionIndicator(
                  multiple: widget.multiple,
                  selected: selected,
                  onToggle: _interactive ? widget.onPressed : null,
                  dense: widget.dense || metrics.isPointer,
                ),
              ),
            ),
            if (option.icon case final icon?)
              ExcludeSemantics(child: Icon(icon, size: theme.iconSizes.sm)),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    maxLines: metrics.isTouch ? null : 1,
                    overflow: textOverflow,
                    style: theme.typography
                        .option(selected: selected, dense: widget.dense)
                        .copyWith(color: foreground),
                  ),
                  if (option.subtitle case final subtitle?)
                    Text(
                      subtitle,
                      maxLines: metrics.isTouch ? null : 2,
                      overflow: textOverflow,
                      style: theme.typography.supporting.copyWith(
                        color: selected ? foreground : theme.muted,
                      ),
                    ),
                ],
              ),
            ),
            if (option.trailingIcon case final icon?)
              ExcludeSemantics(child: Icon(icon, size: theme.iconSizes.sm)),
          ],
        ),
      ),
    );
  }

  Widget _radio(BuildContext context) {
    final radioValue = widget.key! as _SelectionOptionKey<T>;
    final group = RadioGroup.maybeOf<_SelectionOptionKey<T>>(context)!;
    final selected = group.groupValue == radioValue;
    final theme = YumeiroTheme.of(context);
    final scope = YumeiroVisualScope.maybeOf(context);
    return MergeSemantics(
      child: RawRadio<_SelectionOptionKey<T>>(
        value: radioValue,
        groupRegistry: _interactive
            ? group
            : _InactiveSelectionRadioRegistry(selected ? radioValue : null),
        enabled: _interactive,
        toggleable: widget.reportRepeat,
        autofocus: widget.autofocus,
        focusNode: _focusNode,
        mouseCursor: WidgetStatePropertyAll(
          _interactive ? SystemMouseCursors.click : SystemMouseCursors.basic,
        ),
        builder: (context, state) {
          final appearance = theme.visuals.item(
            scope?.itemRole ?? YumeiroItemRole.selection,
            {
              if (selected) WidgetState.selected,
              if (!widget.enabled) WidgetState.disabled,
              if (_interactive && state.states.contains(WidgetState.hovered))
                WidgetState.hovered,
              if (_interactive && state.downPosition != null)
                WidgetState.pressed,
              if (_interactive &&
                  _focusNode.hasFocus &&
                  YumeiroInputScope.keyboardFocusOf(context))
                WidgetState.focused,
            },
            scope?.visualOverride,
          );
          return ColoredBox(
            color: Colors.transparent,
            child: YumeiroResolvedVisualSurface(
              appearance: appearance,
              visualInsets: rowVisualInsets(context),
              child: Builder(
                builder: (context) => _content(context, selected: selected),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.multiple) return _radio(context);
    final content = Builder(
      builder: (context) => _content(context, selected: widget.selected),
    );
    final visualInsets = rowVisualInsets(context);
    return Semantics(
      checked: widget.selected,
      enabled: widget.enabled,
      readOnly: widget.readOnly ? true : null,
      child: widget.readOnly
          ? YumeiroVisualSurface(
              role: YumeiroItemRole.selection,
              states: {
                if (widget.selected) WidgetState.selected,
                if (!widget.enabled) WidgetState.disabled,
              },
              visualInsets: visualInsets,
              child: content,
            )
          : YumeiroInteractiveVisualSurface(
              role: YumeiroItemRole.selection,
              selected: widget.selected,
              onTap: _interactive ? widget.onPressed : null,
              visualInsets: visualInsets,
              child: content,
            ),
    );
  }
}

class _InactiveSelectionRadioRegistry<T> extends RadioGroupRegistry<T> {
  _InactiveSelectionRadioRegistry(this.groupValue);

  @override
  final T? groupValue;

  @override
  ValueChanged<T?> get onChanged => (_) {};

  @override
  void registerClient(RadioClient<T> radio) {}

  @override
  void unregisterClient(RadioClient<T> radio) {}
}
