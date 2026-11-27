import 'package:material_ui/material_ui.dart';

import '../../primitives/visual_scope.dart';
import '../../theme/semantic_visuals.dart';
import '../../theme/theme.dart';
import '../../theme/visual_role.dart';

/// Keeps the unavailable marker and selected fill legible without changing
/// disabled interaction or the host's visual override.
YumeiroVisualOverride unavailableSelectionVisualOverride(
  BuildContext context,
  YumeiroVisualRole role,
) {
  final theme = YumeiroTheme.of(context);
  final scope = YumeiroVisualScope.maybeOf(context);
  final effectiveRole = switch (role) {
    YumeiroSurfaceRole() => scope?.surfaceRole ?? role,
    YumeiroControlRole() => scope?.controlRole ?? role,
    YumeiroItemRole() => scope?.itemRole ?? role,
  };
  return _UnavailableSelectionVisualOverride(
    visuals: theme.visuals,
    role: effectiveRole,
    mutedForeground: theme.subtle,
    inherited: scope?.visualOverride,
  );
}

class _UnavailableSelectionVisualOverride extends YumeiroVisualOverride {
  const _UnavailableSelectionVisualOverride({
    required this.visuals,
    required this.role,
    required this.mutedForeground,
    required this.inherited,
  });

  final YumeiroSemanticVisualTheme visuals;
  final YumeiroVisualRole role;
  final Color mutedForeground;
  final YumeiroVisualOverride? inherited;

  @override
  YumeiroVisualAppearance apply(
    YumeiroVisualAppearance appearance,
    Set<WidgetState> widgetStates,
  ) {
    if (widgetStates.contains(WidgetState.disabled)) {
      final selected = widgetStates.contains(WidgetState.selected);
      appearance = visuals.resolveRole(role, {
        if (selected) WidgetState.selected,
      });
      if (!selected) {
        appearance = appearance.copyWith(foreground: mutedForeground);
      }
    }
    return inherited?.apply(appearance, widgetStates) ?? appearance;
  }
}
