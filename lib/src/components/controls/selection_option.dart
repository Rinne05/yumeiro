import 'package:material_ui/material_ui.dart';

/// A value and its visible details for a selection control or picker.
@immutable
class YumeiroSelectionOption<T> {
  const YumeiroSelectionOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
    this.trailingIcon,
    this.enabled = true,
  });

  final T value;
  final String label;
  final String? subtitle;
  final IconData? icon;
  final IconData? trailingIcon;

  /// Whether the user can select this option. Existing selected values may
  /// still include it. Selection indicators mark unavailable options with a slash.
  final bool enabled;

  @override
  bool operator ==(Object other) =>
      other is YumeiroSelectionOption<T> &&
      other.runtimeType == runtimeType &&
      other.value == value &&
      other.label == label &&
      other.subtitle == subtitle &&
      other.icon == icon &&
      other.trailingIcon == trailingIcon &&
      other.enabled == enabled;

  @override
  int get hashCode =>
      Object.hash(value, label, subtitle, icon, trailingIcon, enabled);
}
