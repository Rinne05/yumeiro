import 'package:flutter/foundation.dart';

/// Extensible semantic role token consumed by surface renderers and recipes.
///
/// Built-in roles are provided as static constants on [YumeiroSurfaceRole],
/// [YumeiroControlRole], and [YumeiroItemRole]. Host applications can declare
/// custom roles anywhere using `const YumeiroSurfaceRole('app.banner', fallback: YumeiroSurfaceRole.card)`
/// without modifying the framework.
@immutable
sealed class YumeiroVisualRole {
  const YumeiroVisualRole(this.id);

  /// Unique dot-delimited identifier (e.g. `'surface.card'`, `'app.hero'`).
  final String id;

  YumeiroVisualRole? get fallbackRole;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other.runtimeType == runtimeType &&
          other is YumeiroVisualRole &&
          other.id == id);

  @override
  int get hashCode => Object.hash(runtimeType, id);

  @override
  String toString() => '$runtimeType($id)';
}

/// Extensible semantic surface categories.
@immutable
final class YumeiroSurfaceRole extends YumeiroVisualRole {
  const YumeiroSurfaceRole(super.id, {this.fallback});

  final YumeiroSurfaceRole? fallback;

  @override
  YumeiroSurfaceRole? get fallbackRole => fallback;

  static const canvas = YumeiroSurfaceRole('yumeiro.surface.canvas');
  static const navigation = YumeiroSurfaceRole('yumeiro.surface.navigation');
  static const panel = YumeiroSurfaceRole('yumeiro.surface.panel');

  /// Quiet nested container that does not imply interaction or elevation.
  static const inset = YumeiroSurfaceRole(
    'yumeiro.surface.inset',
    fallback: panel,
  );

  /// Compact passive badge/tag capsule using chip geometry.
  static const compact = YumeiroSurfaceRole(
    'yumeiro.surface.compact',
    fallback: inset,
  );

  /// Read-only value container sharing resting neutral control aesthetics.
  static const readout = YumeiroSurfaceRole(
    'yumeiro.surface.readout',
    fallback: inset,
  );

  static const card = YumeiroSurfaceRole(
    'yumeiro.surface.card',
    fallback: panel,
  );
  static const floating = YumeiroSurfaceRole(
    'yumeiro.surface.floating',
    fallback: card,
  );
  static const modal = YumeiroSurfaceRole(
    'yumeiro.surface.modal',
    fallback: floating,
  );
  static const toast = YumeiroSurfaceRole(
    'yumeiro.surface.toast',
    fallback: floating,
  );

  /// Translucent scrim / backdrop surface over layered artwork or content.
  static const scrim = YumeiroSurfaceRole(
    'yumeiro.surface.scrim',
    fallback: floating,
  );

  /// Poster / artwork media card surface.
  static const media = YumeiroSurfaceRole(
    'yumeiro.surface.media',
    fallback: card,
  );

  static const List<YumeiroSurfaceRole> builtInValues = <YumeiroSurfaceRole>[
    canvas,
    navigation,
    panel,
    inset,
    compact,
    readout,
    card,
    floating,
    modal,
    toast,
    scrim,
    media,
  ];
}

/// Extensible interactive control categories shared across buttons, inputs,
/// switches, and selectors.
@immutable
final class YumeiroControlRole extends YumeiroVisualRole {
  const YumeiroControlRole(super.id, {this.fallback});

  final YumeiroControlRole? fallback;

  @override
  YumeiroControlRole? get fallbackRole => fallback;

  static const neutral = YumeiroControlRole('yumeiro.control.neutral');
  static const secondary = YumeiroControlRole(
    'yumeiro.control.secondary',
    fallback: neutral,
  );
  static const primary = YumeiroControlRole(
    'yumeiro.control.primary',
    fallback: neutral,
  );
  static const danger = YumeiroControlRole(
    'yumeiro.control.danger',
    fallback: primary,
  );
  static const ghost = YumeiroControlRole(
    'yumeiro.control.ghost',
    fallback: neutral,
  );
  static const overlay = YumeiroControlRole(
    'yumeiro.control.overlay',
    fallback: neutral,
  );

  static const List<YumeiroControlRole> builtInValues = <YumeiroControlRole>[
    neutral,
    secondary,
    primary,
    danger,
    ghost,
    overlay,
  ];
}

/// Extensible list/menu/navigation item interaction roles.
@immutable
final class YumeiroItemRole extends YumeiroVisualRole {
  const YumeiroItemRole(super.id, {this.fallback});

  final YumeiroItemRole? fallback;

  @override
  YumeiroItemRole? get fallbackRole => fallback;

  static const standard = YumeiroItemRole('yumeiro.item.standard');
  static const danger = YumeiroItemRole(
    'yumeiro.item.danger',
    fallback: standard,
  );
  static const navigation = YumeiroItemRole(
    'yumeiro.item.navigation',
    fallback: standard,
  );
  static const selection = YumeiroItemRole(
    'yumeiro.item.selection',
    fallback: standard,
  );

  static const List<YumeiroItemRole> builtInValues = <YumeiroItemRole>[
    standard,
    danger,
    navigation,
    selection,
  ];
}

/// Extensible semantic status tone role for callouts, badges, and alerts.
@immutable
final class YumeiroStatusRole {
  const YumeiroStatusRole(this.id, {this.fallback});

  final String id;
  final YumeiroStatusRole? fallback;

  static const neutral = YumeiroStatusRole('yumeiro.status.neutral');
  static const info = YumeiroStatusRole('yumeiro.status.info', fallback: neutral);
  static const accent = YumeiroStatusRole(
    'yumeiro.status.accent',
    fallback: neutral,
  );
  static const success = YumeiroStatusRole(
    'yumeiro.status.success',
    fallback: neutral,
  );
  static const warning = YumeiroStatusRole(
    'yumeiro.status.warning',
    fallback: neutral,
  );
  static const danger = YumeiroStatusRole(
    'yumeiro.status.danger',
    fallback: neutral,
  );

  static const List<YumeiroStatusRole> builtInValues = <YumeiroStatusRole>[
    neutral,
    info,
    accent,
    success,
    warning,
    danger,
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is YumeiroStatusRole && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'YumeiroStatusRole($id)';
}
