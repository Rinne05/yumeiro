import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../foundation/modality.dart';

bool yumeiroDocksSelectionSheet(BuildContext context, Size size) =>
    YumeiroModalityScope.modalityOf(context) == YumeiroModality.touch &&
    size.width < YumeiroBreakpoints.compact &&
    size.height > size.width;

/// Content-sized overlay that docks in compact portrait touch layouts and
/// positions near [anchor] or centers in other layouts.
class YumeiroSelectionOverlay extends StatelessWidget {
  const YumeiroSelectionOverlay({
    super.key,
    required this.child,
    this.anchor,
    this.maxWidth = 320,
    this.minAnchoredHeight = 0,
  }) : assert(minAnchoredHeight >= 0);

  final Widget child;
  final Rect? anchor;
  final double maxWidth;

  /// Centers the overlay when neither side of [anchor] can fit this height.
  final double minAnchoredHeight;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final media = MediaQuery.of(context);
      final padding = media.viewPadding.copyWith(
        bottom: math.max(media.viewPadding.bottom, media.viewInsets.bottom),
      );
      final bottomPanel = yumeiroDocksSelectionSheet(
        context,
        constraints.biggest,
      );
      final trigger = anchor;
      final anchorFits =
          trigger != null &&
          _anchorSpace(
                trigger,
                yumeiroFloatingSafeBounds(constraints.biggest, padding),
              ) >=
              minAnchoredHeight;
      return CustomSingleChildLayout(
        delegate: _SelectionLayout(
          bottomPanel: bottomPanel,
          maxWidth: maxWidth,
          padding: padding,
          anchor: anchorFits ? trigger : null,
        ),
        child: child,
      );
    },
  );
}

Rect yumeiroFloatingSafeBounds(Size size, EdgeInsets padding) {
  final left = math.min(size.width, padding.left + 8);
  final top = math.min(size.height, padding.top + 8);
  return Rect.fromLTRB(
    left,
    top,
    math.max(left, size.width - padding.right - 8),
    math.max(top, size.height - padding.bottom - 8),
  );
}

double _anchorSpace(Rect trigger, Rect bounds) =>
    math.max(bounds.bottom - trigger.bottom - 8, trigger.top - 8 - bounds.top);

class _SelectionLayout extends SingleChildLayoutDelegate {
  const _SelectionLayout({
    required this.bottomPanel,
    required this.maxWidth,
    required this.padding,
    required this.anchor,
  });

  final bool bottomPanel;
  final double maxWidth;
  final EdgeInsets padding;
  final Rect? anchor;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final availableWidth = math.max(
      0.0,
      constraints.maxWidth - padding.horizontal,
    );
    final width = bottomPanel
        ? availableWidth
        : math.min(maxWidth, math.max(0.0, availableWidth - 16));
    var height =
        math.max(0.0, constraints.maxHeight - padding.vertical - 16) * .9;
    if (!bottomPanel && anchor != null) {
      final trigger = anchor!;
      final bounds = yumeiroFloatingSafeBounds(constraints.biggest, padding);
      height = math.min(
        height,
        _anchorSpace(trigger, bounds).clamp(0.0, bounds.height),
      );
    }
    return BoxConstraints(minWidth: width, maxWidth: width, maxHeight: height);
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    if (bottomPanel) {
      return Offset(
        padding.left,
        size.height - padding.bottom - childSize.height,
      );
    }
    final bounds = yumeiroFloatingSafeBounds(size, padding);
    final trigger = anchor;
    if (trigger == null) {
      return bounds.center - Offset(childSize.width / 2, childSize.height / 2);
    }
    final below = trigger.bottom + 8;
    final top = below + childSize.height <= bounds.bottom
        ? below
        : trigger.top - childSize.height - 8;
    return Offset(
      (trigger.right - childSize.width)
          .clamp(bounds.left, bounds.right - childSize.width)
          .toDouble(),
      top.clamp(bounds.top, bounds.bottom - childSize.height).toDouble(),
    );
  }

  @override
  bool shouldRelayout(_SelectionLayout oldDelegate) =>
      bottomPanel != oldDelegate.bottomPanel ||
      maxWidth != oldDelegate.maxWidth ||
      padding != oldDelegate.padding ||
      anchor != oldDelegate.anchor;
}
