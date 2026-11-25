import 'package:material_ui/material_ui.dart';

/// Presentation-only slide transition shared by pushed routes and full-screen editors.
class YumeiroPageTransition extends StatefulWidget {
  const YumeiroPageTransition({
    super.key,
    required this.animation,
    this.secondaryAnimation,
    this.slideIn = true,
    required this.child,
  });

  final Animation<double> animation;
  final Animation<double>? secondaryAnimation;
  final bool slideIn;
  final Widget child;

  @override
  State<YumeiroPageTransition> createState() => _YumeiroPageTransitionState();
}

class _YumeiroPageTransitionState extends State<YumeiroPageTransition> {
  late CurvedAnimation _entrance;
  CurvedAnimation? _exit;

  @override
  void initState() {
    super.initState();
    _createAnimations();
  }

  void _createAnimations() {
    _entrance = CurvedAnimation(
      parent: widget.animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final secondary = widget.secondaryAnimation;
    _exit = secondary == null
        ? null
        : CurvedAnimation(
            parent: secondary,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
  }

  @override
  void didUpdateWidget(YumeiroPageTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation ||
        oldWidget.secondaryAnimation != widget.secondaryAnimation) {
      _entrance.dispose();
      _exit?.dispose();
      _createAnimations();
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    _exit?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    final textDirection = Directionality.maybeOf(context);
    var child = widget.child;
    if (widget.slideIn) {
      child = SlideTransition(
        textDirection: textDirection,
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(_entrance),
        child: child,
      );
    }
    final secondary = _exit;
    if (secondary != null) {
      child = SlideTransition(
        textDirection: textDirection,
        position: Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(-1, 0),
        ).animate(secondary),
        child: child,
      );
    }
    return ClipRect(child: child);
  }
}
