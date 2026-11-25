import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../../foundation/modality.dart';
import '../../l10n/localizations.dart';
import '../../theme/theme.dart';
import '../overlays/editor.dart';
import 'buttons.dart';
import 'inputs.dart';

bool _searchUsesCommand(BuildContext context) =>
    Theme.of(context).platform == TargetPlatform.macOS;

SingleActivator _searchShortcut(BuildContext context) {
  final command = _searchUsesCommand(context);
  return SingleActivator(
    LogicalKeyboardKey.keyF,
    control: !command,
    meta: command,
  );
}

/// Routes the platform's Find shortcut to the visible [YumeiroSearchScope].
class YumeiroSearchHost extends StatefulWidget {
  const YumeiroSearchHost({super.key, required this.child});

  final Widget child;

  @override
  State<YumeiroSearchHost> createState() => _YumeiroSearchHostState();
}

class _YumeiroSearchHostState extends State<YumeiroSearchHost> {
  final _pages = <_YumeiroSearchScopeState>{};

  void _search() {
    final focusedPage = FocusManager.instance.primaryFocus?.context
        ?.getInheritedWidgetOfExactType<_SearchScope>()
        ?.state;
    if (focusedPage != null &&
        _pages.contains(focusedPage) &&
        focusedPage._isAvailable) {
      focusedPage._search();
      return;
    }
    for (final page in _pages.toList().reversed) {
      if (page._isAvailable) {
        page._search();
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) => _SearchHost(
    state: this,
    child: CallbackShortcuts(
      bindings: {_searchShortcut(context): _search},
      child: Focus(autofocus: true, skipTraversal: true, child: widget.child),
    ),
  );
}

class _SearchHost extends InheritedWidget {
  const _SearchHost({required this.state, required super.child});

  final _YumeiroSearchHostState state;

  @override
  bool updateShouldNotify(_SearchHost oldWidget) => state != oldWidget.state;
}

/// Page-scoped search shared by [YumeiroSearchButton] and the Find shortcut.
class YumeiroSearchScope extends StatefulWidget {
  const YumeiroSearchScope({
    super.key,
    required this.query,
    required this.placeholder,
    required this.onSubmitted,
    required this.child,
    this.enabled = true,
  });

  /// Initial query shown each time the search panel opens.
  final String query;
  final String placeholder;

  /// Reports a confirmed search string. Canceling the panel leaves this
  /// callback untouched.
  final ValueChanged<String> onSubmitted;
  final Widget child;

  /// Whether this page accepts search requests and confirmed results.
  final bool enabled;

  @override
  State<YumeiroSearchScope> createState() => _YumeiroSearchScopeState();
}

class _YumeiroSearchScopeState extends State<YumeiroSearchScope> {
  bool _open = false;
  _YumeiroSearchHostState? _host;

  bool get _isAvailable =>
      mounted &&
      widget.enabled &&
      TickerMode.valuesOf(context).enabled &&
      (ModalRoute.of(context)?.isCurrent ?? true);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final host = context
        .dependOnInheritedWidgetOfExactType<_SearchHost>()
        ?.state;
    if (host != _host) {
      _host?._pages.remove(this);
      _host = host;
      _host?._pages.add(this);
    }
  }

  @override
  void dispose() {
    _host?._pages.remove(this);
    super.dispose();
  }

  Future<void> _search() async {
    if (_open || !widget.enabled) return;
    _open = true;
    try {
      final result = await YumeiroEditor.show<String>(
        context: context,
        builder: (context) =>
            _SearchPanel(query: widget.query, placeholder: widget.placeholder),
      );
      if (mounted && widget.enabled && result != null) {
        widget.onSubmitted(result);
      }
    } finally {
      _open = false;
    }
  }

  @override
  Widget build(BuildContext context) => _SearchScope(
    state: this,
    child: CallbackShortcuts(
      bindings: {
        if (widget.enabled && _host == null) _searchShortcut(context): _search,
      },
      child: Focus(autofocus: true, skipTraversal: true, child: widget.child),
    ),
  );
}

class _SearchScope extends InheritedWidget {
  const _SearchScope({required this.state, required super.child});

  final _YumeiroSearchScopeState state;

  @override
  bool updateShouldNotify(_SearchScope oldWidget) => true;
}

/// Toolbar search action bound to the nearest [YumeiroSearchScope].
class YumeiroSearchButton extends StatelessWidget {
  const YumeiroSearchButton({
    super.key,
    this.variant = YumeiroButtonVariant.neutral,
  });

  final YumeiroButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final theme = YumeiroTheme.of(context);
    final l10n = YumeiroLocalizations.of(context);
    final touch = YumeiroModalityScope.metricsOf(context).isTouch;
    final scope = context
        .dependOnInheritedWidgetOfExactType<_SearchScope>()!
        .state;
    return YumeiroButton(
      icon: theme.icons.search,
      variant: variant,
      tooltip: touch
          ? l10n.search
          : l10n.searchHotkeyTooltip(
              scope.widget.placeholder,
              _searchUsesCommand(context) ? '⌘F' : 'Ctrl+F',
            ),
      selected: scope.widget.query.isNotEmpty,
      onPressed: scope.widget.enabled ? scope._search : null,
    );
  }
}

class _SearchPanel extends StatefulWidget {
  const _SearchPanel({required this.query, required this.placeholder});

  final String query;
  final String placeholder;

  @override
  State<_SearchPanel> createState() => _SearchPanelState();
}

class _SearchPanelState extends State<_SearchPanel> {
  late final _controller = TextEditingController(text: widget.query);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text.trim());

  @override
  Widget build(BuildContext context) {
    final l10n = YumeiroLocalizations.of(context);
    final actions = [
      YumeiroButton(
        label: l10n.cancel,
        variant: YumeiroButtonVariant.ghost,
        onPressed: () => Navigator.of(context).pop(),
      ),
      YumeiroButton(
        label: l10n.search,
        variant: YumeiroButtonVariant.primary,
        onPressed: _submit,
      ),
    ];
    return YumeiroEditor(
      title: widget.placeholder,
      maxWidth: 480,
      actions: actions,
      child: YumeiroTextField.search(
        controller: _controller,
        autofocus: true,
        hintText: widget.placeholder,
        onSubmitted: (_) => _submit(),
      ),
    );
  }
}
