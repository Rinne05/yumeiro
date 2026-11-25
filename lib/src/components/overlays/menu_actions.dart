import 'package:material_ui/material_ui.dart';

/// An entry displayed in a context menu or action sheet.
sealed class YumeiroMenuEntry {
  const YumeiroMenuEntry();
}

/// A non-interactive label for a group of actions.
class YumeiroMenuHeader extends YumeiroMenuEntry {
  const YumeiroMenuHeader({required this.title});

  final String title;
}

/// A visual separator between menu entries.
class YumeiroMenuDivider extends YumeiroMenuEntry {
  const YumeiroMenuDivider();
}

/// A command or selectable action for a context menu or action sheet.
class YumeiroMenuAction extends YumeiroMenuEntry {
  const YumeiroMenuAction({
    required this.label,
    this.icon,
    this.shortcut,
    this.onPressed,
    this.enabled = true,
    this.destructive = false,
    this.selected,
  });

  final String label;
  final IconData? icon;

  /// Shortcut text shown in a pointer menu. The host registers the key binding.
  final String? shortcut;

  /// The callback for an enabled action. An action with no callback is disabled.
  final VoidCallback? onPressed;
  final bool enabled;
  final bool destructive;

  /// Null for an ordinary command, or the current state of a selectable action.
  final bool? selected;
}

VoidCallback? yumeiroMenuActionCallback(YumeiroMenuAction action) =>
    action.enabled ? action.onPressed : null;
