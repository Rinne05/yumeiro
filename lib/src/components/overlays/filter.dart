import 'package:material_ui/material_ui.dart';

import '../../l10n/localizations.dart';
import '../controls/buttons.dart';
import 'editor.dart';

/// Presents a compound filter editor in the active interaction modality.
abstract final class YumeiroFilter {
  /// Opens a dialog for pointer input or a sheet for touch input.
  ///
  /// [builder] receives the current draft and a callback to replace it. Reset
  /// replaces the draft with [resetValue], Apply returns it, and dismissal
  /// returns null. Set [useRootNavigator] to false for the nearest navigator.
  static Future<T?> show<T>({
    required BuildContext context,
    required T initialValue,
    required T resetValue,
    required Widget Function(BuildContext, T, ValueChanged<T>) builder,
    String? title,
    bool useRootNavigator = true,
  }) {
    var draft = initialValue;
    return YumeiroEditor.show<T>(
      context: context,
      useRootNavigator: useRootNavigator,
      builder: (routeContext) => StatefulBuilder(
        builder: (context, setState) {
          final l10n = YumeiroLocalizations.of(context);
          void updateDraft(T value) => setState(() => draft = value);
          return YumeiroEditor(
            title: title ?? l10n.filter,
            actions: [
              YumeiroButton(
                label: l10n.reset,
                onPressed: () => updateDraft(resetValue),
              ),
              YumeiroButton(
                label: l10n.apply,
                variant: YumeiroButtonVariant.primary,
                onPressed: () => Navigator.of(routeContext).pop(draft),
              ),
            ],
            child: builder(context, draft, updateDraft),
          );
        },
      ),
    );
  }
}
