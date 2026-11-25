import 'selection_option.dart';

/// Stages edits while preserving external changes to untouched choices.
class MultiSelectionDraft<T> {
  final _edits = <T, bool>{};

  void toggle(T value, Set<T> current) {
    final wasSelected = current.contains(value);
    final selected = !(_edits[value] ?? wasSelected);
    if (selected == wasSelected) {
      _edits.remove(value);
    } else {
      _edits[value] = selected;
    }
  }

  Set<T> resolve(Set<T> current, List<YumeiroSelectionOption<T>> options) {
    final values = Set<T>.of(current);
    for (final option in options) {
      if (!option.enabled) continue;
      switch (_edits[option.value]) {
        case true:
          values.add(option.value);
        case false:
          values.remove(option.value);
        case null:
          break;
      }
    }
    return values;
  }
}
