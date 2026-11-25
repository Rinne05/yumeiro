import 'package:material_ui/material_ui.dart';

import '../../foundation/modality.dart';
import '../../l10n/localizations.dart';
import '../../primitives/backdrop_group.dart';
import '../../theme/theme.dart';
import '../display/chip_view.dart';
import '../layout/row_visuals.dart';
import '../layout/setting_row.dart';
import 'buttons.dart';
import 'inputs.dart';

/// Setting-row editor for small collections of independent tokens/tags.
class YumeiroTokenInput<T extends Object> extends StatefulWidget {
  const YumeiroTokenInput({
    super.key,
    required this.title,
    this.subtitle,
    required this.values,
    required this.onChanged,
    this.placeholder,
    this.addTooltip,
    this.parseInput,
    this.labelBuilder,
    this.valueKey,
    this.enabled = true,
  });

  final String title;
  final String? subtitle;

  /// Current tokens. Keep their identity stable via [valueKey].
  final List<T> values;

  /// Reports a new unmodifiable snapshot after addition or removal.
  final ValueChanged<List<T>> onChanged;
  final String? placeholder;
  final String? addTooltip;

  /// Converts non-blank input into tokens. Required for non-string tokens.
  /// String tokens default to one item containing the trimmed input.
  final Iterable<T> Function(String rawInput)? parseInput;
  final String Function(T value)? labelBuilder;

  /// Identity used for duplicates and removal. Defaults to the token value.
  final Object Function(T value)? valueKey;
  final bool enabled;

  @override
  State<YumeiroTokenInput<T>> createState() => _YumeiroTokenInputState<T>();
}

class _YumeiroTokenInputState<T extends Object>
    extends State<YumeiroTokenInput<T>> {
  final TextEditingController _controller = TextEditingController();

  Object _valueKey(T value) => widget.valueKey?.call(value) ?? value;

  String _label(T value) =>
      widget.labelBuilder?.call(value) ?? value.toString();

  void _addCurrentValue() {
    if (!widget.enabled) return;
    final raw = _controller.text;
    if (raw.trim().isEmpty) return;

    final Iterable<T> parsed;
    if (widget.parseInput case final parseInput?) {
      parsed = parseInput(raw);
    } else if (T == String) {
      parsed = <T>[raw.trim() as T];
    } else {
      throw StateError('YumeiroTokenInput<$T> requires parseInput.');
    }
    final additions = parsed.toList(growable: false);
    if (additions.isEmpty) return;

    final updated = [...widget.values];
    var changed = false;
    for (final value in additions) {
      final existingIndex = updated.indexWhere(
        (current) => _valueKey(current) == _valueKey(value),
      );
      if (existingIndex < 0) {
        updated.add(value);
        changed = true;
      } else if (_label(updated[existingIndex]) != _label(value)) {
        updated[existingIndex] = value;
        changed = true;
      }
    }
    if (changed) {
      widget.onChanged(List<T>.unmodifiable(updated));
    }
    _controller.clear();
    setState(() {});
  }

  void _removeValue(Object valueKey) {
    if (!widget.enabled) return;
    final updated = widget.values
        .where((value) => _valueKey(value) != valueKey)
        .toList(growable: false);
    if (updated.length != widget.values.length) {
      widget.onChanged(List<T>.unmodifiable(updated));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final l10n = YumeiroLocalizations.of(context);
    final metrics = YumeiroModalityScope.metricsOf(context);
    final touch = metrics.isTouch;
    final editor = SizedBox(
      width: touch ? double.infinity : 240,
      child: Row(
        children: [
          Expanded(
            child: YumeiroTextField(
              controller: _controller,
              enabled: widget.enabled,
              hintText: widget.placeholder ?? l10n.tokenInputHint,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _addCurrentValue(),
            ),
          ),
          SizedBox(width: theme.spacing.sm),
          YumeiroButton(
            icon: theme.icons.add,
            tooltip: widget.addTooltip ?? l10n.add,
            onPressed: widget.enabled && _controller.text.trim().isNotEmpty
                ? _addCurrentValue
                : null,
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        YumeiroSettingRow(
          title: widget.title,
          subtitle: widget.subtitle,
          trailing: touch ? null : editor,
          editor: touch ? editor : null,
        ),
        if (widget.values.isNotEmpty) ...[
          SizedBox(height: theme.spacing.sm),
          Padding(
            padding: rowContentPadding(context).copyWith(top: 0, bottom: 0),
            child: YumeiroBackdropGroup(
              child: Wrap(
                spacing: theme.spacing.sm,
                runSpacing: theme.spacing.sm,
                children: [
                  for (final value in widget.values)
                    ChipView(
                      key: ValueKey<Object>(_valueKey(value)),
                      label: _label(value),
                      token: true,
                      enabled: widget.enabled,
                      onDeleted: () => _removeValue(_valueKey(value)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
