part of 'setting_row.dart';

class _SelectionSetting<T> extends StatefulWidget {
  const _SelectionSetting({
    super.key,
    required this.title,
    this.subtitle,
    this.displayLabel,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String title;
  final String? subtitle;

  /// Overrides the label shown when the setting is not being edited.
  final String? displayLabel;
  final T? value;
  final List<YumeiroSelectionOption<T>> options;

  /// Reports a value from the current enabled options. Null disables the row.
  final ValueChanged<T?>? onChanged;

  @override
  State<_SelectionSetting<T>> createState() => _SelectionSettingState<T>();
}

class _SelectionSettingState<T> extends State<_SelectionSetting<T>> {
  final _controller = YumeiroSheetController();
  bool _open = false;
  bool get _canChoose => widget.onChanged != null && widget.options.isNotEmpty;

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  void didUpdateWidget(_SelectionSetting<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_canChoose) {
      _controller.close();
    } else if (oldWidget.options != widget.options ||
        oldWidget.value != widget.value ||
        oldWidget.title != widget.title) {
      _controller.refresh();
    }
  }

  Future<void> _choose() async {
    if (_open || !_canChoose) return;
    _open = true;
    try {
      final box = context.findRenderObject()! as RenderBox;
      final result = await presentSingleSelectionSheet<T>(
        context: context,
        controller: _controller,
        anchor: () => pickerGlobalBounds(box),
        selection: () => (
          title: widget.title,
          options: widget.options,
          value: widget.value,
          searchable: widget.options.length > 10,
        ),
      );
      if (mounted && result != null) _reportSelection(result.value);
    } finally {
      _open = false;
    }
  }

  void _reportSelection(T? value) {
    if (widget.options.any(
      (option) => option.value == value && option.enabled,
    )) {
      widget.onChanged?.call(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final l10n = YumeiroLocalizations.of(context);
    final metrics = YumeiroModalityScope.metricsOf(context);
    if (!metrics.isTouch) {
      final onChanged = _canChoose ? _reportSelection : null;
      final editor = widget.options.length > 10
          ? YumeiroSelect<T>.searchable(
              value: widget.value,
              options: widget.options,
              placeholder: l10n.selectPlaceholder,
              displayText: widget.displayLabel,
              clearable: false,
              expand: true,
              onChanged: onChanged,
            )
          : YumeiroSelect<T>.menu(
              value: widget.value,
              options: widget.options,
              displayText: widget.displayLabel,
              placeholder: l10n.selectPlaceholder,
              expand: true,
              onChanged: onChanged,
            );
      return YumeiroSettingRow(
        title: widget.title,
        subtitle: widget.subtitle,
        enabled: _canChoose,
        editor: editor,
      );
    }

    final currentLabel =
        widget.displayLabel ??
        widget.options
            .where((option) => option.value == widget.value)
            .firstOrNull
            ?.label ??
        l10n.selectPlaceholder;

    return YumeiroListTile(
      title: Text(widget.title),
      subtitle: widget.subtitle == null || widget.subtitle!.isEmpty
          ? null
          : Text(widget.subtitle!),
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 180),
        child: Text(
          currentLabel,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.end,
          style: theme.typography.supporting.copyWith(color: theme.muted),
        ),
      ),
      enabled: _canChoose,
      onTap: _canChoose ? _choose : null,
    );
  }
}
