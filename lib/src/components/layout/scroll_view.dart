import 'package:material_ui/material_ui.dart';

/// Explicit themed scrollbar and viewport with single-controller ownership.
/// Padding stays inside the viewport so the scrollbar remains flush at the edge.
class YumeiroScrollView extends StatefulWidget {
  const YumeiroScrollView({
    super.key,
    required Widget this.child,
    this.controller,
    this.padding = EdgeInsets.zero,
    this.scrollDirection = Axis.vertical,
  }) : children = null;

  const YumeiroScrollView.list({
    super.key,
    required List<Widget> this.children,
    this.controller,
    this.padding = EdgeInsets.zero,
    this.scrollDirection = Axis.vertical,
  }) : child = null;

  final Widget? child;
  final List<Widget>? children;

  /// Optional caller-owned controller. The viewport and its scrollbar
  /// share this controller.
  final ScrollController? controller;

  /// Insets the scrollable content while keeping the scrollbar at the edge.
  final EdgeInsetsGeometry padding;
  final Axis scrollDirection;

  @override
  State<YumeiroScrollView> createState() => _YumeiroScrollViewState();
}

class _YumeiroScrollViewState extends State<YumeiroScrollView> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller ?? _controller;
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: Scrollbar(
        controller: controller,
        notificationPredicate: (notification) =>
            notification.depth == 0 &&
            notification.metrics.axis == widget.scrollDirection,
        child: widget.children != null
            ? ListView(
                controller: controller,
                scrollDirection: widget.scrollDirection,
                padding: widget.padding,
                children: widget.children!,
              )
            : SingleChildScrollView(
                controller: controller,
                scrollDirection: widget.scrollDirection,
                padding: widget.padding,
                child: widget.child,
              ),
      ),
    );
  }
}
