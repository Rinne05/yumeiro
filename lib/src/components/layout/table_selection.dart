import 'package:material_ui/material_ui.dart';

// Keeps the table's selection group separate from radios in its cells.
class TableRadioIndex extends ValueKey<int> {
  const TableRadioIndex(super.value);
}

/// How a table allows its rows to be selected.
enum YumeiroTableSelectionMode {
  /// Selecting a different eligible row replaces the set with one key.
  /// Activating the selected row again does not clear it.
  single,

  /// Toggles eligible rows independently.
  multiple,
}

/// Controlled selection for data table rows.
///
/// [selectedKeys] refer to the table's row keys. The default key for a unique
/// item is `ValueKey<T>(item)`. Provide a stable row key when values may be
/// equal or a row's data can be replaced.
@immutable
class YumeiroTableSelection<T> {
  const YumeiroTableSelection({
    required this.mode,
    this.selectedKeys = const <Key>{},
    this.onChanged,
    this.isItemEnabled,
    this.moveDisabledToEnd = false,
  });

  /// How the current view presents and updates [selectedKeys].
  final YumeiroTableSelectionMode mode;

  /// Current selection. Single mode uses the first key, if present. Bulk
  /// selection in multiple mode applies to eligible items currently supplied
  /// to the table and preserves keys outside that set.
  final Set<Key> selectedKeys;

  /// Reports a new selection set. Store it in the host and pass it back as
  /// [selectedKeys]. Null makes the selection read-only.
  final ValueChanged<Set<Key>>? onChanged;

  /// Whether the user can change this row's selection. The row's other
  /// actions keep their own enabled state.
  final bool Function(T item)? isItemEnabled;

  /// Displays rows rejected by [isItemEnabled] after eligible rows. Both
  /// groups retain their supplied order. Applies only to the supplied items.
  ///
  /// When enabled, the table checks eligibility for all supplied items,
  /// including rows that have yet to be built in a sliver.
  final bool moveDisabledToEnd;
}

List<Key> buildTableRowKeys<T>(List<T> items, Key Function(T item)? rowKey) {
  if (rowKey != null) return items.map(rowKey).toList(growable: false);

  final occurrences = <T, int>{};
  return [
    for (final item in items)
      switch (occurrences.update(
        item,
        (count) => count + 1,
        ifAbsent: () => 0,
      )) {
        0 => ValueKey<T>(item),
        final count => _RepeatedTableRowKey(item, count),
      },
  ];
}

class _RepeatedTableRowKey<T> extends ValueKey<(T, int)> {
  const _RepeatedTableRowKey(T item, int count) : super((item, count));
}

/// The selection and actions resolved for the current rows.
final class TableSelectionState {
  const TableSelectionState._({
    required this.mode,
    required this.isSelected,
    required this.isItemEnabled,
    required this.toggleFor,
    this.allSelected = false,
    this.toggleAll,
  });

  final YumeiroTableSelectionMode? mode;
  final bool Function(int index) isSelected;

  /// Resolves eligibility by index in the supplied items.
  final bool Function(int index) isItemEnabled;
  final VoidCallback? Function(int index) toggleFor;
  final bool? allSelected;
  final VoidCallback? toggleAll;

  static TableSelectionState controlled<T>({
    required YumeiroTableSelection<T>? selection,
    required List<T> items,
    required List<Key> keys,
    bool includeBulkSelection = true,
  }) {
    if (selection == null) {
      return TableSelectionState._(
        mode: null,
        isSelected: (_) => false,
        isItemEnabled: (_) => true,
        toggleFor: (_) => null,
      );
    }

    final onChanged = selection.onChanged;
    final itemEnabled = selection.isItemEnabled;
    final eligibility = <int, bool>{};
    bool isItemEnabled(int index) =>
        itemEnabled == null ||
        eligibility.putIfAbsent(index, () => itemEnabled(items[index]));

    if (selection.mode == YumeiroTableSelectionMode.single) {
      final selectedKey = selection.selectedKeys.firstOrNull;
      return TableSelectionState._(
        mode: YumeiroTableSelectionMode.single,
        isSelected: (index) => keys[index] == selectedKey,
        isItemEnabled: isItemEnabled,
        toggleFor: (index) => onChanged != null && isItemEnabled(index)
            ? () {
                final key = keys[index];
                if (key != selectedKey) onChanged({key});
              }
            : null,
      );
    }

    final selected = selection.selectedKeys;
    final eligible = !includeBulkSelection
        ? null
        : itemEnabled == null
        ? keys.toSet()
        : {
            for (var index = 0; index < items.length; index++)
              if (isItemEnabled(index)) keys[index],
          };
    final allSelected = eligible == null
        ? false
        : _scopeSelection(eligible, selected);
    return TableSelectionState._(
      mode: YumeiroTableSelectionMode.multiple,
      isSelected: (index) => selected.contains(keys[index]),
      isItemEnabled: isItemEnabled,
      toggleFor: (index) => onChanged != null && isItemEnabled(index)
          ? () {
              final key = keys[index];
              final updated = Set<Key>.of(selected);
              if (!updated.remove(key)) updated.add(key);
              onChanged(updated);
            }
          : null,
      allSelected: allSelected,
      toggleAll: onChanged == null || eligible == null || eligible.isEmpty
          ? null
          : () {
              final updated = Set<Key>.of(selected);
              if (allSelected == true) {
                updated.removeAll(eligible);
              } else {
                updated.addAll(eligible);
              }
              onChanged(updated);
            },
    );
  }
}

bool? _scopeSelection(Set<Key> eligible, Set<Key> selected) {
  if (selected.isEmpty) return false;
  var hasSelected = false;
  var hasUnselected = false;
  for (final id in eligible) {
    if (selected.contains(id)) {
      hasSelected = true;
    } else {
      hasUnselected = true;
    }
    if (hasSelected && hasUnselected) return null;
  }
  return hasSelected;
}
