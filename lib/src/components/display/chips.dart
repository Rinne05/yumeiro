import 'package:material_ui/material_ui.dart';

import '../../theme/visual_role.dart';
import '../overlays/tooltip.dart';
import 'chip_view.dart';

/// A selectable, tappable, or removable label.
///
/// Interactive chips use [YumeiroControlRole.secondary] and preserve the
/// modality's touch target around the compact label.
class YumeiroChip extends StatelessWidget {
  const YumeiroChip({
    super.key,
    required this.label,
    this.icon,
    this.selected,
    this.onTap,
    this.onDeleted,
    this.tooltip,
    this.dense = false,
  });

  final String label;
  final IconData? icon;

  /// Null for ordinary actions, false or true for selectable chips.
  final bool? selected;
  final VoidCallback? onTap;
  final VoidCallback? onDeleted;
  final String? tooltip;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final chip = Semantics(
      selected: selected,
      button: onTap != null,
      enabled: onTap == null ? null : true,
      child: ChipView(
        label: label,
        icon: icon,
        selected: selected,
        onTap: onTap,
        onDeleted: onDeleted,
        dense: dense,
      ),
    );
    return tooltip == null
        ? chip
        : YumeiroTooltip(message: tooltip!, child: chip);
  }
}
