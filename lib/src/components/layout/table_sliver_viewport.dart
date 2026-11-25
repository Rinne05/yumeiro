import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

/// Keeps the horizontal position shared by the header and the mounted rows
/// while the parent viewport builds rows on demand along the vertical axis.
class TableSliverViewport extends StatefulWidget {
  const TableSliverViewport({
    super.key,
    required this.contentWidth,
    required this.viewportWidth,
    required this.sliverBuilder,
    this.header,
    this.pinnedHeader = false,
  });

  final double contentWidth;
  final double viewportWidth;
  final Widget Function(Widget Function(Widget) fitRow) sliverBuilder;
  final Widget? header;
  final bool pinnedHeader;

  @override
  State<TableSliverViewport> createState() => _TableSliverViewportState();
}

class _TableSliverViewportState extends State<TableSliverViewport> {
  final _TableHorizontalController _controller = _TableHorizontalController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final overflow = widget.contentWidth - widget.viewportWidth;
    _controller.limitOffset(overflow > 0 ? overflow : 0);

    final reverse = Directionality.of(context) == TextDirection.rtl;
    Widget fitRow(Widget row) => _TableViewportSlice(
      scrollable: overflow <= 0
          ? null
          : (child) => Scrollable(
              controller: _controller,
              axisDirection: reverse ? AxisDirection.left : AxisDirection.right,
              physics: const ClampingScrollPhysics(),
              // Expose the horizontal action on the table's semantics node.
              excludeFromSemantics: true,
              viewportBuilder: (_, offset) => _TableHorizontalViewport(
                offset: offset,
                reverse: reverse,
                child: SizedBox(width: widget.contentWidth, child: child),
              ),
            ),
      child: row,
    );

    final body = widget.sliverBuilder(fitRow);
    final header = widget.header;
    final sliver = SliverMainAxisGroup(
      slivers: [
        if (header != null)
          widget.pinnedHeader
              ? _TablePinnedHeader(child: fitRow(header))
              : SliverToBoxAdapter(child: fitRow(header)),
        body,
      ],
    );
    final step = widget.viewportWidth * (reverse ? -0.8 : 0.8);
    return SliverSemantics(
      sliver: sliver,
      role: SemanticsRole.table,
      container: true,
      explicitChildNodes: true,
      onScrollLeft: overflow > 0 ? () => _controller.pageBy(step) : null,
      onScrollRight: overflow > 0 ? () => _controller.pageBy(-step) : null,
    );
  }
}

class _TableHorizontalController extends ScrollController {
  _TableHorizontalController() : super(keepScrollOffset: false);

  double _sharedOffset = 0;
  bool _synchronizing = false;

  void limitOffset(double maxOffset) {
    _sharedOffset = _sharedOffset.clamp(0.0, maxOffset);
  }

  void pageBy(double distance) {
    final position = positions
        .where((position) => position.hasContentDimensions)
        .firstOrNull;
    if (position == null) return;
    position.jumpTo(
      (_sharedOffset + distance).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      ),
    );
  }

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) => _TableHorizontalPosition(
    physics: physics,
    context: context,
    initialPixels: _sharedOffset,
    oldPosition: oldPosition,
    controller: this,
  );

  void synchronizeFrom(_TableHorizontalPosition source) {
    if (_synchronizing || _sharedOffset == source.pixels) return;

    _sharedOffset = source.pixels;
    _synchronizing = true;
    for (final position in positions.cast<_TableHorizontalPosition>()) {
      if (position != source) position.synchronizeTo(_sharedOffset);
    }
    _synchronizing = false;
  }
}

class _TableHorizontalPosition extends ScrollPositionWithSingleContext {
  _TableHorizontalPosition({
    required super.physics,
    required super.context,
    required super.initialPixels,
    required super.oldPosition,
    required this.controller,
  }) : super(keepScrollOffset: false);

  final _TableHorizontalController controller;

  @override
  bool applyContentDimensions(double minScrollExtent, double maxScrollExtent) {
    final offset = controller._sharedOffset.clamp(
      minScrollExtent,
      maxScrollExtent,
    );
    if (pixels != offset) correctPixels(offset);
    return super.applyContentDimensions(minScrollExtent, maxScrollExtent);
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
    controller.synchronizeFrom(this);
  }

  void synchronizeTo(double offset) {
    if (pixels == offset) return;
    // A new gesture can start on a different row during a fling.
    if (isScrollingNotifier.value) goIdle();
    forcePixels(offset);
  }
}

// Reparent the measured content if a resize introduces or removes scrolling.
class _TableViewportSlice extends StatefulWidget {
  const _TableViewportSlice({required this.child, required this.scrollable});

  final Widget child;
  final Widget Function(Widget)? scrollable;

  @override
  State<_TableViewportSlice> createState() => _TableViewportSliceState();
}

class _TableViewportSliceState extends State<_TableViewportSlice> {
  final _contentKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final content = KeyedSubtree(key: _contentKey, child: widget.child);
    return widget.scrollable?.call(content) ?? content;
  }
}

// A horizontal viewport with the height of its row and no extra semantics node.
class _TableHorizontalViewport extends SingleChildRenderObjectWidget {
  const _TableHorizontalViewport({
    required this.offset,
    required this.reverse,
    required super.child,
  });

  final ViewportOffset offset;
  final bool reverse;

  @override
  _RenderTableHorizontalViewport createRenderObject(BuildContext context) =>
      _RenderTableHorizontalViewport(offset, reverse);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderTableHorizontalViewport renderObject,
  ) {
    renderObject
      ..scrollOffset = offset
      ..reverse = reverse;
  }
}

class _RenderTableHorizontalViewport extends RenderShiftedBox
    implements RenderAbstractViewport {
  _RenderTableHorizontalViewport(this._offset, this._reverse) : super(null);

  ViewportOffset _offset;
  bool _reverse;

  set scrollOffset(ViewportOffset value) {
    if (value == _offset) return;
    if (attached) _offset.removeListener(_didScroll);
    _offset = value;
    if (attached) _offset.addListener(_didScroll);
    markNeedsLayout();
  }

  set reverse(bool value) {
    if (value == _reverse) return;
    _reverse = value;
    _didScroll();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _offset.addListener(_didScroll);
  }

  @override
  void detach() {
    _offset.removeListener(_didScroll);
    super.detach();
  }

  void _didScroll() {
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.constrain(
    child!.getDryLayout(constraints.heightConstraints()),
  );

  @override
  void performLayout() {
    child!.layout(constraints.heightConstraints(), parentUsesSize: true);
    size = constraints.constrain(child!.size);
    _offset.applyViewportDimension(size.width);
    _offset.applyContentDimensions(0, child!.size.width - size.width);
  }

  Offset _translation(double pixels) =>
      Offset(_reverse ? pixels + size.width - child!.size.width : -pixels, 0);

  @override
  void paint(PaintingContext context, Offset offset) {
    context.pushClipRect(
      needsCompositing,
      offset,
      Offset.zero & size,
      (context, offset) =>
          context.paintChild(child!, offset + _translation(_offset.pixels)),
    );
  }

  @override
  Rect describeApproximatePaintClip(RenderObject child) => Offset.zero & size;

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      result.addWithPaintOffset(
        offset: _translation(_offset.pixels),
        position: position,
        hitTest: (result, position) =>
            child!.hitTest(result, position: position),
      );

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.translateByDouble(_translation(_offset.pixels).dx, 0, 0, 1);
  }

  @override
  RevealedOffset getOffsetToReveal(
    RenderObject target,
    double alignment, {
    Rect? rect,
    Axis? axis,
  }) {
    final bounds = MatrixUtils.transformRect(
      target.getTransformTo(child),
      rect ?? target.paintBounds,
    );
    final leading = _reverse ? child!.size.width - bounds.right : bounds.left;
    final pixels = leading - (size.width - bounds.width) * alignment;
    return RevealedOffset(
      offset: pixels,
      rect: bounds.shift(_translation(pixels)),
    );
  }

  @override
  void showOnScreen({
    RenderObject? descendant,
    Rect? rect,
    Duration duration = Duration.zero,
    Curve curve = Curves.ease,
  }) {
    final visible = _offset.allowImplicitScrolling
        ? RenderViewportBase.showInViewport(
            descendant: descendant,
            viewport: this,
            offset: _offset,
            rect: rect,
            duration: duration,
            curve: curve,
          )
        : rect;
    super.showOnScreen(
      descendant: _offset.allowImplicitScrolling ? null : descendant,
      rect: visible,
      duration: duration,
      curve: curve,
    );
  }
}

// Pin the measured header without inserting an anonymous node inside the
// table's required table → row → cell semantics hierarchy.
class _TablePinnedHeader extends SingleChildRenderObjectWidget {
  const _TablePinnedHeader({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderTablePinnedHeader();
}

class _RenderTablePinnedHeader extends RenderSliverSingleBoxAdapter {
  bool _pinned = false;
  @override
  double childMainAxisPosition(RenderObject child) => 0;

  @override
  void performLayout() {
    final header = child!;
    header.layout(constraints.asBoxConstraints(), parentUsesSize: true);
    final extent = header.size.height;
    final pinned = constraints.scrollOffset > 0;
    if (_pinned != pinned) {
      _pinned = pinned;
      markNeedsSemanticsUpdate();
    }
    final paint = (constraints.remainingPaintExtent - constraints.overlap)
        .clamp(0.0, extent);
    geometry = SliverGeometry(
      scrollExtent: extent,
      paintOrigin: constraints.overlap,
      paintExtent: paint,
      layoutExtent: (extent - constraints.scrollOffset).clamp(0.0, paint),
      maxPaintExtent: extent,
      maxScrollObstructionExtent: extent,
      cacheExtent: calculateCacheOffset(constraints, from: 0, to: extent),
      hasVisualOverflow: true,
    );
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    if (_pinned) {
      config.addTagForChildren(RenderViewport.excludeFromScrolling);
    }
  }
}
