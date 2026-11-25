import 'package:material_ui/material_ui.dart';

import '../../foundation/modality.dart';
import '../../foundation/typography.dart';
import '../../l10n/localizations.dart';
import '../../theme/semantic_visuals.dart';
import '../../theme/theme.dart';
import '../../theme/visual_role.dart';
import '../controls/buttons.dart';
import 'compact_label.dart';

/// Shared appearance and delete affordance for chips and token input values.
class ChipView extends StatefulWidget {
  const ChipView({
    super.key,
    required this.label,
    this.token = false,
    this.icon,
    this.selected,
    this.onTap,
    this.onDeleted,
    this.dense = false,
    this.enabled = true,
  });

  final String label;
  final bool token;
  final IconData? icon;
  final bool? selected;
  final VoidCallback? onTap;
  final VoidCallback? onDeleted;
  final bool dense;
  final bool enabled;

  @override
  State<ChipView> createState() => _ChipViewState();
}

class _ChipViewState extends State<ChipView> {
  var _hovered = false;
  var _removeFocused = false;

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final metrics = YumeiroModalityScope.metricsOf(context);
    final touch = metrics.isTouch;
    final token = widget.token;
    final interactive = widget.onTap != null || widget.onDeleted != null;
    final labelStyle = theme.typography.tag(
      selected: widget.selected == true,
      interactive: interactive,
      dense: widget.dense,
    );
    final disabled = widget.enabled
        ? null
        : theme.visuals.control(YumeiroControlRole.neutral, const {
            WidgetState.disabled,
          });
    final surface = CompactLabel(
      label: YumeiroTextStyle(
        style: labelStyle,
        child: Text(widget.label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      icon: widget.icon,
      dense: widget.dense,
      role: interactive && !token
          ? YumeiroControlRole.secondary
          : YumeiroSurfaceRole.compact,
      onTap: widget.onTap,
      selected: widget.selected == true,
      removeAction: widget.onDeleted == null
          ? null
          : Builder(
              builder: (context) =>
                  _deleteButton(context, revealOnInteraction: token && !touch),
            ),
      visualOverride: disabled == null
          ? null
          : YumeiroVisualOverride(
              base: YumeiroVisualDelta(
                opacity: disabled.opacity,
                foreground: disabled.foreground,
              ),
            ),
    );
    return token && !touch
        ? MouseRegion(
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: surface,
          )
        : surface;
  }

  Widget _deleteButton(
    BuildContext context, {
    required bool revealOnInteraction,
  }) {
    final theme = YumeiroTheme.of(context);
    final metrics = YumeiroModalityScope.metricsOf(context);
    final touch = metrics.isTouch;
    final dense = widget.dense;
    final size = touch ? (dense ? 20.0 : 24.0) : (dense ? 18.0 : 20.0);
    final iconSize = touch ? (dense ? 13.0 : 15.0) : (dense ? 11.0 : 13.0);
    final button = YumeiroButton(
      icon: theme.icons.close,
      customLeading: widget.selected == true
          ? Icon(
              theme.icons.close,
              size: iconSize,
              color: IconTheme.of(context).color,
            )
          : null,
      variant: YumeiroButtonVariant.ghost,
      tooltip: YumeiroLocalizations.of(context).removeItem(widget.label),
      height: touch ? metrics.minTargetSize : size,
      width: size,
      iconSize: iconSize,
      visualOverride: widget.enabled
          ? null
          : const YumeiroVisualOverride(base: YumeiroVisualDelta(opacity: 1)),
      onPressed: widget.enabled ? widget.onDeleted : null,
    );
    if (!revealOnInteraction) return button;

    return Focus(
      canRequestFocus: false,
      onFocusChange: (focused) => setState(() => _removeFocused = focused),
      child: AnimatedOpacity(
        opacity: _hovered || _removeFocused ? 1 : 0,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : theme.motion.fast,
        alwaysIncludeSemantics: true,
        child: button,
      ),
    );
  }
}
