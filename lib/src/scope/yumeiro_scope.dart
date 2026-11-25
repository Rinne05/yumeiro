import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:material_ui/material_ui.dart';

import '../components/overlays/toasts.dart';
import '../foundation/icons.dart';
import '../foundation/input.dart';
import '../foundation/modality.dart';
import '../foundation/typography.dart';
import '../l10n/localizations.dart';
import '../primitives/backdrop_group.dart';
import '../theme/effect_pass.dart';
import '../theme/theme.dart';
import '../theme/theme_extension.dart';
import '../theme/theme_preset.dart';
import '../theme/theme_registry.dart';

final _fixedPresetListenable = Listenable.merge(const []);

/// One-stop root configuration scope for Yumeiro applications.
///
/// Installs theme registry, material capability tiering, modality & density,
/// input/focus tracking, keyboard dismissal, internationalization fallback,
/// toast overlay host, and shared backdrop group in one composable widget.
///
/// Put the scope above the navigation subtree when page routes and overlays
/// should share the configuration. Hosts using [MaterialApp] can wrap the
/// navigator created in its [MaterialApp.builder].
class YumeiroScope extends StatelessWidget {
  /// Wraps [child] with resolved theme data and Yumeiro services.
  const YumeiroScope({
    super.key,
    required this.child,
    this.preset,
    this.presetId,
    this.inheritTheme = false,
    this.registry,
    this.modality,
    this.density = YumeiroDensity.standard,
    this.capability = YumeiroMaterialCapability.fullOptical,
    this.fontConfig = const YumeiroFontConfig(),
    this.icons,
    this.accentColor,
    this.backdropBlur,
    this.advancedMotionEnabled = true,
    this.motionOptions = const <String, bool>{},
    this.customizations = const <String, Object>{},
    this.visualsAugmenter,
    this.posterCardScale = 1.0,
    this.localizations,
    this.locale,
    this.toastController,
    this.inputController,
  });

  /// Subtree that receives the configuration and services.
  final Widget child;

  /// Explicit preset, taking precedence over [presetId].
  final YumeiroThemePreset? preset;

  /// Looks up a preset in [registry]. A missing or unknown ID uses Classic Dark
  /// when [preset] is absent.
  final String? presetId;

  /// Keeps the nearest Material theme and its existing Yumeiro extension.
  ///
  /// If the host supplies no Yumeiro extension, this scope derives one from
  /// its theme settings. The default applies the generated Yumeiro theme
  /// while preserving the host's other theme extensions.
  final bool inheritTheme;

  /// Registry exposed to descendants. Defaults to the shared registry.
  final YumeiroThemeRegistry? registry;

  /// Fixes interaction mode. Null infers it from platform and viewport.
  final YumeiroModality? modality;

  /// Layout density applied independently of [modality].
  final YumeiroDensity density;

  /// Requested effects tier. Runtime shader support determines the effective
  /// tier used by surfaces.
  final YumeiroMaterialCapability capability;

  /// Font families and fallback lists used by preset typography.
  final YumeiroFontConfig fontConfig;

  /// Optional replacement icon set. Null uses Material icons.
  final YumeiroIconSet? icons;

  /// Accent override with priority over a declared customization value.
  /// A preset needs an accent customizer to derive a new palette.
  final Color? accentColor;

  /// Replaces existing positive blur radii on surface recipes other than
  /// readouts. Control, item, and modal barrier blur are resolved separately.
  final double? backdropBlur;

  /// Enables preset transition durations and optional motion effects.
  final bool advancedMotionEnabled;

  /// Per-effect motion choices. [advancedMotionEnabled] takes precedence.
  final Map<String, bool> motionOptions;

  /// Overrides keyed by the active preset's option IDs.
  final Map<String, Object> customizations;

  /// Extends or replaces the visual recipes after preset options are applied.
  final YumeiroVisualsAugmenter? visualsAugmenter;

  /// Size multiplier supplied to poster-card widgets that honor it.
  final double posterCardScale;

  /// Optional fixed instance for Yumeiro's built-in messages in this subtree.
  final YumeiroLocalizations? localizations;

  /// Subtree locale override. Inherits the nearest locale when omitted, with
  /// English as the standalone fallback.
  final Locale? locale;

  /// External toast controller. The caller owns it when supplied.
  final YumeiroToastController? toastController;

  /// External input tracker. The caller owns it when supplied.
  final YumeiroInputController? inputController;

  @override
  Widget build(BuildContext context) {
    final effectiveRegistry = registry ?? YumeiroThemeRegistry.defaultInstance;
    return ListenableBuilder(
      listenable: preset == null && presetId != null
          ? effectiveRegistry
          : _fixedPresetListenable,
      builder: (context, child) => _buildScope(context, effectiveRegistry),
    );
  }

  Widget _buildScope(
    BuildContext context,
    YumeiroThemeRegistry effectiveRegistry, {
    ThemeData? preparedTheme,
  }) {
    final effectiveModality = modality ?? YumeiroModalityScope.inferModality();

    final content = YumeiroKeyboardDismissal(
      child: YumeiroToastHost(
        controller: toastController,
        child: YumeiroBackdropGroup(child: child),
      ),
    );

    final inheritedLocale = Localizations.maybeLocaleOf(context);
    final effectiveLocale = locale ?? inheritedLocale ?? const Locale('en');
    final hostLocalizations = context
        .findAncestorWidgetOfExactType<Localizations>();
    final localizedContent = _YumeiroScopeLocalizations(
      locale: effectiveLocale,
      prepareOverride: locale != null && effectiveLocale != inheritedLocale,
      delegates: [
        if (localizations case final messages?)
          _FixedYumeiroLocalizationsDelegate(messages),
        for (final hostDelegate
            in hostLocalizations?.delegates ??
                const <LocalizationsDelegate<dynamic>>[])
          _reuseHostMessages(
            context,
            hostDelegate,
            effectiveLocale,
            inheritedLocale,
          ),
        if (localizations == null) YumeiroLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      child: _YumeiroScopeDirectionality(
        inheritedDirection: locale == null
            ? Directionality.maybeOf(context)
            : null,
        child: content,
      ),
    );

    return YumeiroThemeRegistryScope(
      registry: effectiveRegistry,
      child: YumeiroMaterialCapabilityScope(
        capability: capability,
        child: YumeiroModalityScope(
          modality: effectiveModality,
          density: density,
          child: YumeiroInputListener(
            controller: inputController,
            child: _YumeiroScopeTheme(
              inheritTheme: inheritTheme,
              generate: () =>
                  preparedTheme ??
                  yumeiroThemeData(
                    preset:
                        preset ??
                        effectiveRegistry.presetById(
                          presetId,
                          fallback: YumeiroThemePresets.classicDark,
                        ),
                    modality: effectiveModality,
                    density: density,
                    advancedMotionEnabled: advancedMotionEnabled,
                    motionOptions: motionOptions,
                    customizations: customizations,
                    backdropBlur: backdropBlur,
                    fontConfig: fontConfig,
                    icons: icons,
                    accentColor: accentColor,
                    visualsAugmenter: visualsAugmenter,
                    posterCardScale: posterCardScale,
                  ),
              child: localizedContent,
            ),
          ),
        ),
      ),
    );
  }
}

class _AppScope extends YumeiroScope {
  const _AppScope({
    required this.theme,
    required YumeiroThemeRegistry super.registry,
    required super.modality,
    required super.density,
    required super.capability,
    required super.child,
  });

  final ThemeData theme;

  @override
  Widget build(BuildContext context) =>
      _buildScope(context, registry!, preparedTheme: theme);
}

class _YumeiroScopeTheme extends StatefulWidget {
  const _YumeiroScopeTheme({
    required this.inheritTheme,
    required this.generate,
    required this.child,
  });

  final bool inheritTheme;
  final ThemeData Function() generate;
  final Widget child;

  @override
  State<_YumeiroScopeTheme> createState() => _YumeiroScopeThemeState();
}

class _YumeiroScopeThemeState extends State<_YumeiroScopeTheme> {
  ThemeData? _generated;

  @override
  void didUpdateWidget(covariant _YumeiroScopeTheme oldWidget) {
    super.didUpdateWidget(oldWidget);
    _generated = null;
  }

  @override
  Widget build(BuildContext context) {
    final host = Theme.of(context);
    final inheritTheme = widget.inheritTheme;
    if (inheritTheme && host.extension<YumeiroThemeExtension>() != null) {
      return widget.child;
    }
    // The host's theme can animate independently of the Yumeiro configuration.
    final generated = _generated ??= widget.generate();
    final hostExtensions = host.extensions.values.where(
      (extension) => extension is! YumeiroThemeExtension,
    );
    final theme = !inheritTheme && hostExtensions.isEmpty
        ? generated
        : (inheritTheme ? host : generated).copyWith(
            extensions: [...hostExtensions, ...generated.extensions.values],
          );
    return Theme(data: theme, child: widget.child);
  }
}

class _YumeiroScopeDirectionality extends StatelessWidget {
  const _YumeiroScopeDirectionality({
    required this.inheritedDirection,
    required this.child,
  });

  final TextDirection? inheritedDirection;
  final Widget child;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: inheritedDirection ?? Directionality.of(context),
    child: child,
  );
}

class _YumeiroScopeLocalizations extends StatefulWidget {
  const _YumeiroScopeLocalizations({
    required this.locale,
    required this.prepareOverride,
    required this.delegates,
    required this.child,
  });

  final Locale locale;
  final bool prepareOverride;
  final List<LocalizationsDelegate<dynamic>> delegates;
  final Widget child;

  @override
  State<_YumeiroScopeLocalizations> createState() =>
      _YumeiroScopeLocalizationsState();
}

class _YumeiroScopeLocalizationsState
    extends State<_YumeiroScopeLocalizations> {
  Locale? _loadedLocale;
  List<LocalizationsDelegate<dynamic>> _loadedDelegates = const [];
  var _request = 0;

  @override
  void initState() {
    super.initState();
    _updateLocale();
  }

  @override
  void didUpdateWidget(covariant _YumeiroScopeLocalizations oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.prepareOverride ||
        !oldWidget.prepareOverride ||
        widget.locale != oldWidget.locale ||
        _delegatesChanged(oldWidget.delegates, widget.delegates)) {
      _updateLocale();
    }
  }

  bool _delegatesChanged(
    List<LocalizationsDelegate<dynamic>> previous,
    List<LocalizationsDelegate<dynamic>> next,
  ) {
    if (previous.length != next.length) return true;
    for (var i = 0; i < next.length; i++) {
      final delegate = next[i];
      final old = previous[i];
      if (delegate.runtimeType != old.runtimeType ||
          delegate.type != old.type ||
          delegate.shouldReload(old)) {
        return true;
      }
    }
    return false;
  }

  void _updateLocale() {
    final request = ++_request;
    final locale = widget.locale;
    if (!widget.prepareOverride) {
      _loadedLocale = locale;
      _loadedDelegates = widget.delegates;
      return;
    }

    // Localizations accepts any completed reload, including earlier requests.
    // Prepare explicit overrides here and install only the latest resources.
    final delegates = widget.delegates.toList();
    final handled = <Type>{};
    final pending = <Future<void>>[];
    for (var i = 0; i < delegates.length; i++) {
      final delegate = delegates[i];
      if (handled.contains(delegate.type) || !delegate.isSupported(locale)) {
        continue;
      }
      handled.add(delegate.type);
      final load = delegate.load(locale);
      final completion = load.then<void>((messages) {
        delegates[i] = _ResolvedScopeDelegate(delegate, locale, messages);
      });
      if (load is! SynchronousFuture) pending.add(completion);
    }

    void apply() {
      _loadedLocale = locale;
      _loadedDelegates = delegates;
    }

    if (pending.isEmpty) {
      apply();
    } else {
      Future.wait(pending).then(
        (_) {
          if (mounted && request == _request) setState(apply);
        },
        onError: (Object error, StackTrace stack) {
          if (!mounted || request != _request) return;
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: error,
              stack: stack,
              library: 'yumeiro',
              context: ErrorDescription('loading a scoped locale'),
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = _loadedLocale;
    if (locale == null) return const SizedBox.shrink();
    return Localizations(
      locale: locale,
      delegates: _loadedDelegates,
      child: widget.child,
    );
  }
}

LocalizationsDelegate<dynamic> _reuseHostMessages(
  BuildContext context,
  LocalizationsDelegate<dynamic> hostDelegate,
  Locale locale,
  Locale? inheritedLocale,
) {
  final delegate = hostDelegate is _ResolvedScopeDelegate
      ? hostDelegate.source
      : hostDelegate;
  if (locale == inheritedLocale) {
    final messages = Localizations.of<Object>(context, delegate.type);
    if (messages != null) {
      return _ResolvedScopeDelegate(delegate, locale, messages);
    }
  }
  return delegate;
}

/// Shares the host's loaded resources while retaining its other locales.
class _ResolvedScopeDelegate extends LocalizationsDelegate<dynamic> {
  const _ResolvedScopeDelegate(this.source, this.locale, this.messages);

  final LocalizationsDelegate<dynamic> source;
  final Locale locale;
  final Object? messages;

  @override
  Type get type => source.type;

  @override
  bool isSupported(Locale locale) =>
      locale == this.locale || source.isSupported(locale);

  @override
  Future<dynamic> load(Locale locale) =>
      locale == this.locale ? SynchronousFuture(messages) : source.load(locale);

  @override
  bool shouldReload(covariant _ResolvedScopeDelegate old) =>
      type != old.type || locale != old.locale || messages != old.messages;
}

class _FixedYumeiroLocalizationsDelegate
    extends LocalizationsDelegate<YumeiroLocalizations> {
  const _FixedYumeiroLocalizationsDelegate(this.instance);

  final YumeiroLocalizations instance;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<YumeiroLocalizations> load(Locale locale) =>
      SynchronousFuture<YumeiroLocalizations>(instance);

  @override
  bool shouldReload(_FixedYumeiroLocalizationsDelegate old) =>
      old.instance != instance;
}

/// Convenience [MaterialApp] wrapper pre-configured with [YumeiroLocalizations]
/// and [YumeiroScope].
///
/// Use [YumeiroScope] in the builder of an existing app when keeping its
/// router, theme policy, or app-level configuration.
class YumeiroApp extends StatelessWidget {
  /// Creates a Material app rooted at [home] with a Yumeiro scope.
  const YumeiroApp({
    super.key,
    required this.home,
    this.title = '',
    this.debugShowCheckedModeBanner = false,
    this.preset,
    this.presetId,
    this.registry,
    this.modality,
    this.density = YumeiroDensity.standard,
    this.capability = YumeiroMaterialCapability.fullOptical,
    this.fontConfig = const YumeiroFontConfig(),
    this.icons,
    this.accentColor,
    this.backdropBlur,
    this.advancedMotionEnabled = true,
    this.motionOptions = const <String, bool>{},
    this.customizations = const <String, Object>{},
    this.visualsAugmenter,
    this.posterCardScale = 1.0,
    this.localizations,
    this.locale,
    this.supportedLocales = YumeiroLocalizations.supportedLocales,
    this.localizationsDelegates = const <LocalizationsDelegate<dynamic>>[],
    this.restorationScopeId,
    this.builder,
  });

  /// Home route inside the app's navigator and Yumeiro scope.
  final Widget home;

  /// App title forwarded to [MaterialApp].
  final String title;

  /// Whether the underlying app shows its debug banner. Defaults to false.
  final bool debugShowCheckedModeBanner;

  /// Explicit preset. Takes precedence over the registered [presetId].
  final YumeiroThemePreset? preset;

  /// Preset ID to look up when [preset] is absent. Unknown IDs use Classic Dark.
  final String? presetId;

  /// Registry used for [presetId] lookup and exposed to descendants.
  final YumeiroThemeRegistry? registry;

  /// Explicit interaction mode, or automatic mode inside the navigator.
  final YumeiroModality? modality;

  /// Density applied to the theme and the navigator's interaction metrics.
  final YumeiroDensity density;

  /// Requested material capability applied to the navigation subtree.
  final YumeiroMaterialCapability capability;

  /// Font selection and fallbacks for the active preset.
  final YumeiroFontConfig fontConfig;

  /// Optional replacement for the standard Material icon set.
  final YumeiroIconSet? icons;

  /// Explicit accent color, taking precedence over an accent option.
  final Color? accentColor;

  /// Surface blur override, with the same policy as [YumeiroScope.backdropBlur].
  final double? backdropBlur;

  /// Sets the global switch for Yumeiro's advanced motion effects.
  final bool advancedMotionEnabled;

  /// Per-effect choices consulted when advanced motion is enabled.
  final Map<String, bool> motionOptions;

  /// User values keyed by the current preset's option IDs.
  final Map<String, Object> customizations;

  /// Host recipe transformation applied after preset customization.
  final YumeiroVisualsAugmenter? visualsAugmenter;

  /// Size multiplier for poster cards that use the active theme's scale.
  final double posterCardScale;

  /// Supplies fixed Yumeiro messages, independently of the app locale.
  final YumeiroLocalizations? localizations;

  /// Explicit locale, useful for implementing a user-controlled language switch.
  final Locale? locale;

  /// Locales considered by [MaterialApp] when resolving the active locale.
  final Iterable<Locale> supportedLocales;

  /// Additional delegates evaluated before the built-in delegates.
  /// A fixed [localizations] instance takes precedence.
  final Iterable<LocalizationsDelegate<dynamic>> localizationsDelegates;

  /// Root restoration scope for routes and fields with a restoration ID.
  final String? restorationScopeId;

  /// Receives the navigator already wrapped in [YumeiroScope].
  ///
  /// Include that child in the returned tree to keep the app's routes.
  final TransitionBuilder? builder;

  @override
  Widget build(BuildContext context) {
    final effectiveRegistry = registry ?? YumeiroThemeRegistry.defaultInstance;
    return ListenableBuilder(
      listenable: preset == null && presetId != null
          ? effectiveRegistry
          : _fixedPresetListenable,
      builder: (context, child) => _buildApp(effectiveRegistry),
    );
  }

  Widget _buildApp(YumeiroThemeRegistry effectiveRegistry) {
    final effectivePreset =
        preset ??
        effectiveRegistry.presetById(
          presetId,
          fallback: YumeiroThemePresets.classicDark,
        );
    final effectiveModality = modality ?? YumeiroModalityScope.inferModality();
    final theme = yumeiroThemeData(
      preset: effectivePreset,
      modality: effectiveModality,
      density: density,
      advancedMotionEnabled: advancedMotionEnabled,
      motionOptions: motionOptions,
      customizations: customizations,
      backdropBlur: backdropBlur,
      fontConfig: fontConfig,
      icons: icons,
      accentColor: accentColor,
      visualsAugmenter: visualsAugmenter,
      posterCardScale: posterCardScale,
    );

    return MaterialApp(
      title: title,
      debugShowCheckedModeBanner: debugShowCheckedModeBanner,
      restorationScopeId: restorationScopeId,
      locale: locale,
      supportedLocales: supportedLocales,
      localizationsDelegates: <LocalizationsDelegate<dynamic>>[
        if (localizations case final messages?)
          _FixedYumeiroLocalizationsDelegate(messages),
        ...localizationsDelegates,
        YumeiroLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      theme: theme,
      builder: (context, child) {
        final scoped = _AppScope(
          theme: theme,
          registry: effectiveRegistry,
          modality: effectiveModality,
          density: density,
          capability: capability,
          child: child ?? const SizedBox.shrink(),
        );
        return builder != null ? builder!(context, scoped) : scoped;
      },
      home: home,
    );
  }
}
