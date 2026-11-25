import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/widgets.dart';

import '../theme/semantic_visuals.dart';
import '../theme/visual_role.dart';

/// Supplies a semantic context for a composed subtree without coupling child
/// components to the parent scene.
///
/// Descendants that consult this scope resolve their contextual role and
/// override from the nearest instance.
class YumeiroVisualScope extends InheritedWidget {
  const YumeiroVisualScope({
    super.key,
    this.surfaceRole,
    this.controlRole,
    this.itemRole,
    this.visualOverride,
    required super.child,
  });

  /// Uses the overlay role for descendant controls on artwork or scrims.
  const YumeiroVisualScope.overlay({
    super.key,
    this.visualOverride,
    required super.child,
  }) : surfaceRole = null,
       controlRole = YumeiroControlRole.overlay,
       itemRole = null;

  final YumeiroSurfaceRole? surfaceRole;
  final YumeiroControlRole? controlRole;
  final YumeiroItemRole? itemRole;
  /// Optional contextual appearance adjustment. Components can supply an
  /// explicit adjustment with higher priority.
  final YumeiroVisualOverride? visualOverride;

  static YumeiroVisualScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<YumeiroVisualScope>();

  @override
  bool updateShouldNotify(YumeiroVisualScope oldWidget) =>
      surfaceRole != oldWidget.surfaceRole ||
      controlRole != oldWidget.controlRole ||
      itemRole != oldWidget.itemRole ||
      visualOverride != oldWidget.visualOverride;
}

/// Forwards interaction state owned by a composed parent to visual-only child
/// controls.
class YumeiroInteractionStateScope extends InheritedWidget {
  const YumeiroInteractionStateScope({
    super.key,
    required this.states,
    required super.child,
  });

  /// Current state snapshot. Replace it when interaction state changes.
  final Set<WidgetState> states;

  static Set<WidgetState>? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<YumeiroInteractionStateScope>()
      ?.states;

  @override
  bool updateShouldNotify(YumeiroInteractionStateScope oldWidget) =>
      !setEquals(states, oldWidget.states);
}
