import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:stack_ui/stack_ui.dart';

class SizedPositioned extends Positioned {
  const SizedPositioned({
    super.key,
    required double super.left,
    required double super.top,
    required double super.width,
    required double super.height,
    required super.child,
  }) : super();

  SizedPositioned.fromRect({
    super.key,
    required Rect rect,
    required super.child,
  }) : super(left: rect.left, top: rect.top, width: rect.width, height: rect.height);
}

class SizedStack extends Stack {
  const SizedStack({super.key, required super.children}) : super();
}

class RenderSizedStack extends RenderStack {
  RenderSizedStack();

  @override
  void performLayout() {
    var child = firstChild;
    final childRects = <Rect>[];

    while (child != null) {
      final childParentData = child.parentData as StackParentData;
      final left = childParentData.left;
      final top = childParentData.top;
      final width = childParentData.width;
      final height = childParentData.height;

      assert(
        left != null && top != null && width != null && height != null,
        'All children of SizedStack must be SizedPositioned widgets.',
      );

      final rect = Rect.fromLTWH(left!, top!, width!, height!);
      childRects.add(rect);
      child.layout(BoxConstraints());

      child = childParentData.nextSibling;
      childParentData.offset = rect.topLeft;
    }

    final boundingBox = childRects.boundingBox;
    size = boundingBox.size;
  }
}
