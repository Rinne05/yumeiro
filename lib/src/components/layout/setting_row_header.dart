import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Wraps a heading and its controls while aligning them to opposite edges.
class YumeiroSettingRowHeader extends Wrap {
  YumeiroSettingRowHeader({
    super.key,
    required Widget title,
    Widget? trailing,
    required super.spacing,
    required super.runSpacing,
    super.crossAxisAlignment = WrapCrossAlignment.center,
  }) : super(
         alignment: WrapAlignment.spaceBetween,
         children: [title, ?trailing],
       );

  @override
  RenderWrap createRenderObject(BuildContext context) =>
      _RenderYumeiroSettingRowHeader(
        spacing: spacing,
        runSpacing: runSpacing,
        crossAxisAlignment: crossAxisAlignment,
        textDirection: Directionality.of(context),
      );
}

class _RenderYumeiroSettingRowHeader extends RenderWrap {
  _RenderYumeiroSettingRowHeader({
    required super.spacing,
    required super.runSpacing,
    required super.crossAxisAlignment,
    required super.textDirection,
  }) : super(alignment: WrapAlignment.spaceBetween);

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final measured = super.computeDryLayout(constraints);
    return constraints.hasBoundedWidth
        ? Size(constraints.maxWidth, measured.height)
        : measured;
  }

  @override
  void performLayout() {
    super.performLayout();
    // Wrap otherwise shrink-wraps loose constraints, moving the trailing edge
    // inward in page columns. Unbounded rows retain their natural width.
    if (constraints.hasBoundedWidth) {
      size = Size(constraints.maxWidth, size.height);
    }
    final title = firstChild;
    if (title == null) return;
    final rtl = textDirection == TextDirection.rtl;
    final titleData = title.parentData! as WrapParentData;
    titleData.offset = Offset(
      rtl ? size.width - title.size.width : 0,
      titleData.offset.dy,
    );
    final trailing = lastChild!;
    if (trailing == title) return;
    final trailingData = trailing.parentData! as WrapParentData;
    trailingData.offset = Offset(
      rtl ? 0 : size.width - trailing.size.width,
      trailingData.offset.dy,
    );
  }
}
