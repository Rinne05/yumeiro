import 'package:flutter/widgets.dart';

import 'theme_preset.dart';

/// Open registry of [YumeiroThemeFamily] and [YumeiroThemePreset] entries.
///
/// Use [YumeiroThemeRegistry.standard] for an isolated registry containing
/// built-in families, or [YumeiroThemeRegistry.empty] for a curated set. The
/// shared [defaultInstance] is used by scopes without an explicit registry.
class YumeiroThemeRegistry extends ChangeNotifier {
  YumeiroThemeRegistry({List<YumeiroThemeFamily> families = const []}) {
    for (final family in families) {
      _setFamily(family);
    }
  }

  /// Creates a new registry initialized with all built-in theme families.
  factory YumeiroThemeRegistry.standard() =>
      YumeiroThemeRegistry(families: YumeiroThemeFamilies.builtInValues);

  /// Creates an empty registry for hosts curating a custom preset set.
  factory YumeiroThemeRegistry.empty() => YumeiroThemeRegistry();

  /// Shared default registry pre-populated with built-in presets.
  static final YumeiroThemeRegistry defaultInstance =
      YumeiroThemeRegistry.standard();

  final Map<String, YumeiroThemeFamily> _families = {};
  final Map<String, YumeiroThemePreset> _standalonePresets = {};

  /// Unmodifiable snapshot of families in registration order.
  List<YumeiroThemeFamily> get families =>
      List<YumeiroThemeFamily>.unmodifiable(_families.values);

  Iterable<YumeiroThemePreset> get _registeredPresets => _families.values
      .expand((family) => family.variants.values)
      .followedBy(_standalonePresets.values);

  /// Unmodifiable snapshot of family variants followed by standalone presets.
  List<YumeiroThemePreset> get presets => List.unmodifiable(_registeredPresets);

  /// Registers or replaces a [YumeiroThemeFamily] by ID.
  ///
  /// With [replace] false an existing family is kept. A preset ID can belong
  /// to only one variant or standalone entry. A conflicting ID throws
  /// [ArgumentError] before changing the registry.
  void registerFamily(YumeiroThemeFamily family, {bool replace = true}) {
    if (!replace && _families.containsKey(family.id)) return;
    _setFamily(family);
    notifyListeners();
  }

  void _setFamily(YumeiroThemeFamily family) {
    final ids = <String>{};
    for (final preset in family.variants.values) {
      if (!ids.add(preset.id) ||
          _standalonePresets.containsKey(preset.id) ||
          _familyForPresetId(preset.id, except: family.id) != null) {
        _throwDuplicatePresetId(preset.id);
      }
    }
    _families[family.id] = family;
  }

  /// Removes a registered family by [familyId].
  bool unregisterFamily(String familyId) {
    if (_families.remove(familyId) == null) return false;
    notifyListeners();
    return true;
  }

  /// Registers a single [YumeiroThemePreset].
  ///
  /// When [familyId] is supplied, the preset is merged into that family (or
  /// creates a single-variant family if none exists). The variant is inferred
  /// from brightness if omitted. An existing family keeps its default
  /// variant. Without [familyId], registers a standalone preset. An existing
  /// entry in the same slot is replaced. To move a preset between slots,
  /// remove its previous registration first.
  void registerPreset(
    YumeiroThemePreset preset, {
    String? familyId,
    String? familyLabel,
    YumeiroThemeVariant? variant,
  }) {
    if (familyId == null) {
      if (_familyForPresetId(preset.id) != null) {
        _throwDuplicatePresetId(preset.id);
      }
      _standalonePresets[preset.id] = preset;
      notifyListeners();
      return;
    }
    final resolvedVariant =
        variant ??
        (preset.brightness == Brightness.dark
            ? YumeiroThemeVariant.dark
            : YumeiroThemeVariant.light);
    final existing = _families[familyId];
    _setFamily(
      YumeiroThemeFamily(
        id: familyId,
        label: familyLabel ?? existing?.label ?? preset.label,
        variants: {...?existing?.variants, resolvedVariant: preset},
        defaultVariant: existing?.defaultVariant ?? resolvedVariant,
        icon: existing == null ? preset.icon : existing.icon,
        iconBuilder: existing == null
            ? preset.iconBuilder
            : existing.iconBuilder,
      ),
    );
    notifyListeners();
  }

  /// Removes a standalone registration by [presetId].
  bool unregisterStandalonePreset(String presetId) {
    if (_standalonePresets.remove(presetId) == null) return false;
    notifyListeners();
    return true;
  }

  YumeiroThemeFamily? familyById(String id) => _families[id];

  YumeiroThemeFamily? familyForPreset(YumeiroThemePreset preset) =>
      _familyForPresetId(preset.id);

  YumeiroThemeFamily? _familyForPresetId(String id, {String? except}) {
    for (final family in _families.values) {
      if (family.id != except && family.containsPreset(id)) return family;
    }
    return null;
  }

  static Never _throwDuplicatePresetId(String id) => throw ArgumentError.value(
    id,
    'preset.id',
    'Preset ID is already registered',
  );

  /// Looks up the unique preset registered under [id].
  YumeiroThemePreset? maybePresetById(String? id) {
    if (id == null) return null;
    for (final family in _families.values) {
      for (final preset in family.variants.values) {
        if (preset.id == id) return preset;
      }
    }
    return _standalonePresets[id];
  }

  /// Looks up the ID, then uses the explicit fallback, the first registered
  /// preset, or Classic Dark, in that order.
  YumeiroThemePreset presetById(String? id, {YumeiroThemePreset? fallback}) =>
      maybePresetById(id) ??
      fallback ??
      _registeredPresets.firstOrNull ??
      YumeiroThemePresets.classicDark;

  /// Creates an independent shallow copy for scoped registry customization.
  YumeiroThemeRegistry copy() {
    final clone = YumeiroThemeRegistry(families: _families.values.toList());
    clone._standalonePresets.addAll(_standalonePresets);
    return clone;
  }
}

/// Provides a [YumeiroThemeRegistry] to descendant widgets.
class YumeiroThemeRegistryScope
    extends InheritedNotifier<YumeiroThemeRegistry> {
  const YumeiroThemeRegistryScope({
    super.key,
    required YumeiroThemeRegistry registry,
    required super.child,
  }) : super(notifier: registry);

  static YumeiroThemeRegistry? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<YumeiroThemeRegistryScope>()
      ?.notifier;

  /// Subscribes to the nearest supplied registry, with the shared registry as
  /// fallback.
  static YumeiroThemeRegistry of(BuildContext context) =>
      maybeOf(context) ?? YumeiroThemeRegistry.defaultInstance;
}
