import 'package:material_ui/material_ui.dart';

import '../../l10n/localizations.dart';
import '../../primitives/pixel_border.dart';
import '../../primitives/pixel_circle.dart';
import '../../primitives/visual_surface.dart';
import '../../theme/semantic_visuals.dart';
import '../../theme/theme.dart';
import '../../theme/visual_role.dart';
import '../controls/buttons.dart';

/// Unified circular play button overlay placed atop media cards or artwork.
class YumeiroMediaPlayButton extends StatelessWidget {
  const YumeiroMediaPlayButton({
    super.key,
    this.size = 42,
    this.iconSize = 23,
    this.active = true,
    this.onPressed,
    this.tooltip,
    this.fillColor,
  });

  final double size;
  final double iconSize;
  final bool active;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? fillColor;

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final label = tooltip ?? YumeiroLocalizations.of(context).play;
    final role = active
        ? YumeiroControlRole.primary
        : YumeiroControlRole.overlay;
    final visualOverride = YumeiroVisualOverride(
      base: YumeiroVisualDelta(
        shape: theme.checkboxVisuals.shape is YumeiroPixelBorder
            ? pixelCircleBorder(size)
            : const CircleBorder(),
        fill: !active && fillColor != null
            ? YumeiroSolidFill(fillColor!)
            : null,
      ),
    );

    if (onPressed == null) {
      return Semantics(
        label: label,
        child: SizedBox.square(
          dimension: size,
          child: YumeiroVisualSurface(
            role: role,
            visualOverride: visualOverride,
            clipBehavior: Clip.antiAlias,
            child: Center(child: Icon(theme.icons.play, size: iconSize)),
          ),
        ),
      );
    }

    return YumeiroButton(
      icon: theme.icons.play,
      iconSize: iconSize,
      width: size,
      height: size,
      tooltip: label,
      onPressed: onPressed,
      variant: active
          ? YumeiroButtonVariant.primary
          : YumeiroButtonVariant.mediaOverlay,
      visualOverride: visualOverride,
    );
  }
}
