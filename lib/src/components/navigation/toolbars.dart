import 'package:material_ui/material_ui.dart';

import '../../foundation/modality.dart';
import '../../l10n/localizations.dart';
import '../../primitives/backdrop_group.dart';
import '../../theme/theme.dart';
import '../controls/buttons.dart';
import '../controls/inputs.dart';
import '../layout/page_header.dart';

/// Compact search + filter/sort/more toolbar adapting cleanly via
/// [YumeiroBackdropGroup] and [YumeiroTextField].
class YumeiroSearchToolbar extends StatefulWidget {
  const YumeiroSearchToolbar({
    super.key,
    this.query,
    this.controller,
    required this.onQueryChanged,
    this.onSubmitted,
    this.focusNode,
    this.placeholder,
    this.onFilter,
    this.filterCount = 0,
    this.onSort,
    this.onMore,
  }) : assert(query == null || controller == null);

  /// Host query used to synchronize the internally owned text field.
  final String? query;

  /// Caller-owned controller. When supplied, the caller controls text
  /// synchronization.
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String>? onSubmitted;
  final String? placeholder;
  final VoidCallback? onFilter;

  /// Positive values highlight the filter button and annotate its tooltip.
  final int filterCount;
  final VoidCallback? onSort;
  final VoidCallback? onMore;

  @override
  State<YumeiroSearchToolbar> createState() => _YumeiroSearchToolbarState();
}

class _YumeiroSearchToolbarState extends State<YumeiroSearchToolbar> {
  TextEditingController? _ownedController;

  TextEditingController get _controller =>
      widget.controller ??
      (_ownedController ??= TextEditingController(text: widget.query));

  @override
  void didUpdateWidget(YumeiroSearchToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != null) return;
    final query = widget.query;
    if (oldWidget.controller case final previous?
        when query == null || previous.text == query) {
      _controller.value = previous.value;
    } else if (query != null && _controller.text != query) {
      _controller.text = query;
    }
  }

  @override
  void dispose() {
    _ownedController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final l10n = YumeiroLocalizations.of(context);
    final gap = theme.spacing.sm;
    final target = YumeiroModalityScope.metricsOf(context).minTargetSize;
    final field = YumeiroTextField.search(
      controller: _controller,
      focusNode: widget.focusNode,
      hintText: widget.placeholder ?? l10n.search,
      onChanged: widget.onQueryChanged,
      onSubmitted: widget.onSubmitted,
    );
    final actions = [
      if (widget.onFilter != null)
        YumeiroButton(
          icon: theme.icons.filter,
          tooltip: widget.filterCount == 0
              ? l10n.filter
              : l10n.filterWithCount(widget.filterCount),
          selected: widget.filterCount > 0,
          onPressed: widget.onFilter,
        ),
      if (widget.onMore != null)
        YumeiroButton(
          icon: theme.icons.more,
          tooltip: l10n.moreActions,
          onPressed: widget.onMore,
        ),
      if (widget.onSort != null)
        YumeiroButton(
          icon: theme.icons.sort,
          tooltip: l10n.sort,
          onPressed: widget.onSort,
        ),
    ];
    return YumeiroBackdropGroup(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final inlineWidth =
              constraints.maxWidth - actions.length * (target + gap);
          final minimumInputWidth = target * 3 + 2 * gap;
          return Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: gap,
            runSpacing: gap,
            children: [
              SizedBox(
                width: inlineWidth >= minimumInputWidth
                    ? inlineWidth
                    : constraints.maxWidth,
                child: field,
              ),
              if (actions.isNotEmpty)
                Wrap(spacing: gap, runSpacing: gap, children: actions),
            ],
          );
        },
      ),
    );
  }
}

/// Multi-selection toolbar with a leading count and trailing actions.
/// Actions wrap when the available width is insufficient.
class YumeiroSelectionToolbar extends StatelessWidget {
  const YumeiroSelectionToolbar({
    super.key,
    required this.selectedCount,
    required this.onClose,
    required this.onSelectAll,
    this.actions = const [],
  });

  final int selectedCount;

  /// Requests closing the selection mode. Null hides the close button.
  final VoidCallback? onClose;

  /// Host callback for Select All. The toolbar does not own the items or scope.
  final VoidCallback? onSelectAll;

  /// Additional actions displayed beside Select All when space allows.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final l10n = YumeiroLocalizations.of(context);
    final theme = YumeiroTheme.of(context);
    return buildYumeiroCompactHeader(
      context,
      title: l10n.selectedCount(selectedCount),
      leading: onClose == null
          ? null
          : YumeiroButton(
              variant: YumeiroButtonVariant.ghost,
              icon: theme.icons.close,
              tooltip: l10n.close,
              onPressed: onClose,
            ),
      actionSpacing: theme.spacing.sm,
      actions: [
        YumeiroButton(label: l10n.selectAll, onPressed: onSelectAll),
        ...actions,
      ],
    );
  }
}
