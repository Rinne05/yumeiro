import 'package:material_ui/material_ui.dart';

import '../../primitives/visual_surface.dart';
import '../../theme/semantic_visuals.dart';
import '../../theme/theme.dart';
import '../../theme/visual_role.dart';

/// Strips Material menu container chrome so [YumeiroResolvedVisualSurface] owns
/// the fill, border, and effects of floating menus.
MenuStyle yumeiroMenuHostStyle(YumeiroVisualAppearance appearance) => MenuStyle(
  shape: WidgetStatePropertyAll(appearance.shape),
  backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
  surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
  shadowColor: const WidgetStatePropertyAll(Colors.transparent),
  elevation: const WidgetStatePropertyAll(0),
  padding: const WidgetStatePropertyAll(EdgeInsets.zero),
  visualDensity: VisualDensity.standard,
  side: const WidgetStatePropertyAll(BorderSide.none),
);

/// Semantic menu item host built over Flutter's [MenuItemButton] with keyboard
/// focus ring preservation and theme-owned [YumeiroItemRole] rendering.
class YumeiroMenuVisualButton extends StatefulWidget {
  const YumeiroMenuVisualButton({
    super.key,
    required this.builder,
    required this.onPressed,
    this.selected,
    this.checked,
    this.highlighted = false,
    this.role = YumeiroItemRole.standard,
    this.autofocus = false,
    this.minHeight,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  });

  final Widget Function(
    BuildContext context,
    YumeiroVisualAppearance appearance,
  )
  builder;
  final VoidCallback? onPressed;
  final bool? selected;
  final bool? checked;
  final bool highlighted;
  final YumeiroItemRole role;
  final bool autofocus;
  final double? minHeight;
  final EdgeInsetsGeometry padding;

  @override
  State<YumeiroMenuVisualButton> createState() =>
      _YumeiroMenuVisualButtonState();
}

class _YumeiroMenuVisualButtonState extends State<YumeiroMenuVisualButton> {
  final _states = WidgetStatesController();

  @override
  void dispose() {
    _states.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget surface(BuildContext context, Set<WidgetState> states) {
      var appearance = YumeiroTheme.of(context).visuals.item(widget.role, {
        ...states,
        if (widget.highlighted) WidgetState.hovered,
        if (widget.onPressed == null) WidgetState.disabled,
        if (widget.selected == true) WidgetState.selected,
      });
      final focus = appearance.focusIndicator;
      if (focus.isVisible) {
        appearance = appearance.copyWith(
          focusIndicator: YumeiroFocusIndicator(
            side: focus.side,
            gap: -focus.side.width / 2,
            glow: focus.glow,
          ),
        );
      }
      return YumeiroResolvedVisualSurface(
        appearance: appearance,
        constraints: BoxConstraints(minHeight: widget.minHeight ?? 0),
        padding: widget.padding,
        child: widget.builder(context, appearance),
      );
    }

    final interactiveSurface = ValueListenableBuilder<Set<WidgetState>>(
      valueListenable: _states,
      builder: (context, states, _) => surface(context, states),
    );
    final child = MenuItemButton(
      onPressed: widget.onPressed,
      closeOnActivate: widget.checked == null,
      autofocus: widget.autofocus,
      statesController: _states,
      overflowAxis: Axis.vertical,
      style: const ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.transparent),
        overlayColor: WidgetStatePropertyAll(Colors.transparent),
        surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
        elevation: WidgetStatePropertyAll(0),
        side: WidgetStatePropertyAll(BorderSide.none),
        padding: WidgetStatePropertyAll(EdgeInsets.zero),
        minimumSize: WidgetStatePropertyAll(Size.zero),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.standard,
        splashFactory: NoSplash.splashFactory,
      ),
      child: interactiveSurface,
    );
    return MergeSemantics(
      child: Semantics(
        selected: widget.checked == null ? widget.selected : null,
        checked: widget.checked,
        child: child,
      ),
    );
  }
}
