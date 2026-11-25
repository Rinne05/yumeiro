import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoLocalizations;

import '../foundation/input.dart';
import '../foundation/modality.dart';
import '../l10n/localizations.dart';
import '../theme/effect_pass.dart';
import '../theme/theme_registry.dart';

/// Captures configuration below the destination Navigator/Overlay at opening.
/// Shared ancestors remain inherited, so application-wide changes stay live.
/// Local overrides use a snapshot and never retain the source BuildContext.
class YumeiroCapturedConfiguration {
  YumeiroCapturedConfiguration._({
    required this.themes,
    required this.modality,
    required this.capability,
    required this.registry,
    required this.keyboardFocus,
    required this.direction,
    required this.locale,
    required this.delegates,
  });

  factory YumeiroCapturedConfiguration.capture(
    BuildContext from,
    BuildContext to,
  ) {
    final modality = from.getInheritedWidgetOfExactType<YumeiroModalityScope>();
    final capability = from
        .getInheritedWidgetOfExactType<YumeiroMaterialCapabilityScope>();
    final registry = from
        .getInheritedWidgetOfExactType<YumeiroThemeRegistryScope>()
        ?.notifier;
    final input = from.getInheritedWidgetOfExactType<YumeiroInputScope>();
    final direction = from.getInheritedWidgetOfExactType<Directionality>();
    final localizations = from.findAncestorWidgetOfExactType<Localizations>();
    return YumeiroCapturedConfiguration._(
      themes: InheritedTheme.capture(from: from, to: to),
      modality:
          identical(
            modality,
            to.getInheritedWidgetOfExactType<YumeiroModalityScope>(),
          )
          ? null
          : modality,
      capability:
          identical(
            capability,
            to.getInheritedWidgetOfExactType<YumeiroMaterialCapabilityScope>(),
          )
          ? null
          : capability?.capability,
      registry:
          identical(
            registry,
            to
                .getInheritedWidgetOfExactType<YumeiroThemeRegistryScope>()
                ?.notifier,
          )
          ? null
          : registry,
      keyboardFocus:
          identical(
            input,
            to.getInheritedWidgetOfExactType<YumeiroInputScope>(),
          )
          ? null
          : input?.notifier?.showKeyboardFocus,
      direction:
          identical(
            direction,
            to.getInheritedWidgetOfExactType<Directionality>(),
          )
          ? null
          : direction?.textDirection,
      locale: Localizations.maybeLocaleOf(from),
      delegates:
          identical(
            localizations,
            to.findAncestorWidgetOfExactType<Localizations>(),
          )
          ? const []
          : [
              if (YumeiroLocalizations.maybeOf(from) case final value?)
                _SnapshotDelegate<YumeiroLocalizations>(value),
              if (Localizations.of<MaterialLocalizations>(
                    from,
                    MaterialLocalizations,
                  )
                  case final value?)
                _SnapshotDelegate<MaterialLocalizations>(value),
              if (Localizations.of<CupertinoLocalizations>(
                    from,
                    CupertinoLocalizations,
                  )
                  case final value?)
                _SnapshotDelegate<CupertinoLocalizations>(value),
              if (Localizations.of<WidgetsLocalizations>(
                    from,
                    WidgetsLocalizations,
                  )
                  case final value?)
                _SnapshotDelegate<WidgetsLocalizations>(value),
              ...?localizations?.delegates,
            ],
    );
  }

  final CapturedThemes themes;
  final YumeiroModalityScope? modality;
  final YumeiroMaterialCapability? capability;
  final YumeiroThemeRegistry? registry;
  final bool? keyboardFocus;
  final TextDirection? direction;
  final Locale? locale;
  final List<LocalizationsDelegate<dynamic>> delegates;

  Widget wrap(Widget child) {
    if (direction case final value?) {
      child = Directionality(textDirection: value, child: child);
    }
    if (delegates.isNotEmpty && locale != null) {
      child = Localizations(
        locale: locale!,
        delegates: delegates,
        child: child,
      );
    }
    if (registry case final value?) {
      child = YumeiroThemeRegistryScope(registry: value, child: child);
    }
    if (capability case final value?) {
      child = YumeiroMaterialCapabilityScope(capability: value, child: child);
    }
    if (modality case final value?) {
      child = YumeiroModalityScope(
        modality: value.modality,
        density: value.density,
        child: child,
      );
    }
    if (keyboardFocus case final value?) {
      child = YumeiroInputListener.forOverlay(
        keyboardFocus: value,
        child: child,
      );
    }
    return themes.wrap(child);
  }
}

class _SnapshotDelegate<T> extends LocalizationsDelegate<T> {
  const _SnapshotDelegate(this.value);
  final T value;
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<T> load(Locale locale) => SynchronousFuture(value);
  @override
  bool shouldReload(_SnapshotDelegate<T> old) => old.value != value;
}
