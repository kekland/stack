import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

mixin OverflowHitTestable on RenderBox {
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (hitTestChildren(result, position: position) || hitTestSelf(position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }

    return false;
  }
}

class OverflowHitTestableStack extends Stack {
  const OverflowHitTestableStack({
    super.key,
    super.alignment,
    super.textDirection,
    super.fit,
    super.clipBehavior,
    super.children,
  });

  @override
  RenderStack createRenderObject(BuildContext context) {
    return RenderOverflowHitTestableStack(
      alignment: alignment,
      textDirection: textDirection ?? Directionality.maybeOf(context),
      fit: fit,
      clipBehavior: clipBehavior,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderStack renderObject) {
    renderObject
      ..alignment = alignment
      ..textDirection = textDirection ?? Directionality.maybeOf(context)
      ..fit = fit
      ..clipBehavior = clipBehavior;
  }
}

class RenderOverflowHitTestableStack extends RenderStack with OverflowHitTestable {
  RenderOverflowHitTestableStack({
    super.alignment,
    super.textDirection,
    super.fit,
    super.clipBehavior,
    super.children,
  });
}
