import 'package:material_ui/material_ui.dart';

import '../overlays/picker_overlay.dart';
import 'buttons.dart';

/// Applies Yumeiro menu visuals to Flutter's in-app text editing toolbar.
Widget buildYumeiroTextEditingMenu(
  BuildContext context,
  EditableTextState field,
) {
  if (SystemContextMenu.isSupportedByField(field)) {
    return SystemContextMenu.editableText(editableTextState: field);
  }

  final items = field.contextMenuButtonItems;
  if (items.isEmpty) return const SizedBox.shrink();
  final anchors = field.contextMenuAnchors;
  return TextSelectionToolbar(
    anchorAbove: anchors.primaryAnchor,
    anchorBelow: anchors.secondaryAnchor ?? anchors.primaryAnchor,
    toolbarBuilder: (context, child) =>
        PickerFloatingSurface(padding: EdgeInsets.zero, child: child),
    children: [
      for (final item in items)
        YumeiroButton(
          variant: YumeiroButtonVariant.ghost,
          dense: true,
          onPressed: item.onPressed,
          label: AdaptiveTextSelectionToolbar.getButtonLabel(context, item),
        ),
    ],
  );
}
