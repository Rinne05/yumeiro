import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

import '../../foundation/modality.dart';
import '../../primitives/backdrop_group.dart';

/// Keeps one or more fields paired cleanly with a trailing submit/action button.
/// On `touch` modality, additional fields stack above the final input + action row;
/// the action moves below the final input if it needs more width. On `pointer`,
/// fields and action wrap inline.
class YumeiroInputActionGroup extends StatelessWidget {
  const YumeiroInputActionGroup({
    super.key,
    required this.inputs,
    required this.action,
    this.inputWidth = 240,
    this.actionWidth = 80,
  }) : assert(inputs.length > 0);

  final List<Widget> inputs;
  final Widget action;
  final double inputWidth;

  /// Minimum action width; longer labels expand naturally with text scaling.
  final double actionWidth;

  @override
  Widget build(BuildContext context) {
    final isTouch =
        YumeiroModalityScope.modalityOf(context) == YumeiroModality.touch;
    final button = ConstrainedBox(
      constraints: BoxConstraints(minWidth: actionWidth),
      child: action,
    );

    return YumeiroBackdropGroup(
      child: !isTouch
          ? Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final input in inputs)
                  SizedBox(width: inputWidth, child: input),
                button,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final input in inputs.take(inputs.length - 1)) ...[
                  input,
                  const SizedBox(height: 8),
                ],
                _InputActionPair(
                  inputWidth: inputWidth,
                  textDirection: Directionality.of(context),
                  input: inputs.last,
                  action: button,
                ),
              ],
            ),
    );
  }
}

class _InputActionPair extends MultiChildRenderObjectWidget {
  _InputActionPair({
    required this.inputWidth,
    required this.textDirection,
    required Widget input,
    required Widget action,
  }) : super(children: [input, action]);

  final double inputWidth;
  final TextDirection textDirection;

  @override
  _RenderInputActionPair createRenderObject(BuildContext context) =>
      _RenderInputActionPair(inputWidth, textDirection);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderInputActionPair renderObject,
  ) {
    renderObject.update(inputWidth, textDirection);
  }
}

class _InputActionParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderInputActionPair extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _InputActionParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _InputActionParentData> {
  _RenderInputActionPair(this._inputWidth, this._textDirection);

  static const _spacing = 8.0;
  double _inputWidth;
  TextDirection _textDirection;

  void update(double inputWidth, TextDirection textDirection) {
    if (_inputWidth == inputWidth && _textDirection == textDirection) return;
    _inputWidth = inputWidth;
    _textDirection = textDirection;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _InputActionParentData) {
      child.parentData = _InputActionParentData();
    }
  }

  ({bool inline, double inputWidth}) _widths(double width, double actionWidth) {
    if (!width.isFinite) return (inline: true, inputWidth: _inputWidth);
    final available = width - actionWidth - _spacing;
    final inline = available >= math.min(_inputWidth, width / 2);
    return (inline: inline, inputWidth: inline ? available : width);
  }

  double _height(double inputHeight, double actionHeight, bool inline) => inline
      ? math.max(inputHeight, actionHeight)
      : inputHeight + _spacing + actionHeight;

  @override
  double computeMinIntrinsicWidth(double height) => math.max(
    firstChild!.getMinIntrinsicWidth(height),
    lastChild!.getMinIntrinsicWidth(height),
  );

  @override
  double computeMaxIntrinsicWidth(double height) =>
      firstChild!.getMaxIntrinsicWidth(height) +
      _spacing +
      lastChild!.getMaxIntrinsicWidth(height);

  double _intrinsicHeight(double width, {required bool minimum}) {
    final input = firstChild!;
    final action = lastChild!;
    final actionWidth = math.min(
      action.getMaxIntrinsicWidth(double.infinity),
      width,
    );
    final widths = _widths(width, actionWidth);
    final inputHeight = minimum
        ? input.getMinIntrinsicHeight(widths.inputWidth)
        : input.getMaxIntrinsicHeight(widths.inputWidth);
    final actionHeight = minimum
        ? action.getMinIntrinsicHeight(actionWidth)
        : action.getMaxIntrinsicHeight(actionWidth);
    return _height(inputHeight, actionHeight, widths.inline);
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      _intrinsicHeight(width, minimum: true);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _intrinsicHeight(width, minimum: false);

  Size _measure(BoxConstraints bounds, {required bool dry}) {
    final input = firstChild!;
    final action = lastChild!;
    Size layout(RenderBox child, BoxConstraints constraints) {
      if (dry) return child.getDryLayout(constraints);
      child.layout(constraints, parentUsesSize: true);
      return child.size;
    }

    final actionSize = layout(action, bounds.loosen());
    final (:inline, :inputWidth) = _widths(bounds.maxWidth, actionSize.width);
    final inputSize = layout(input, BoxConstraints.tightFor(width: inputWidth));
    final width = inline
        ? inputSize.width + _spacing + actionSize.width
        : inputSize.width;
    final height = _height(inputSize.height, actionSize.height, inline);
    final size = bounds.constrain(Size(width, height));
    if (!dry) {
      final rtl = _textDirection == TextDirection.rtl;
      final inputPosition = input.parentData! as _InputActionParentData;
      inputPosition.offset = Offset(
        rtl ? size.width - inputSize.width : 0,
        inline ? (height - inputSize.height) / 2 : 0,
      );
      final actionPosition = action.parentData! as _InputActionParentData;
      actionPosition.offset = Offset(
        rtl ? 0 : size.width - actionSize.width,
        inline ? (height - actionSize.height) / 2 : inputSize.height + _spacing,
      );
    }
    return size;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _measure(constraints, dry: true);

  @override
  void performLayout() => size = _measure(constraints, dry: false);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);
}
