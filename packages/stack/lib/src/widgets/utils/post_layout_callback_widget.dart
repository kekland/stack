import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class PostLayoutCallbackWidget extends SingleChildRenderObjectWidget {
  const PostLayoutCallbackWidget({
    super.key,
    required this.onLayout,
    required super.child,
  });

  final void Function() onLayout;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return PostLayoutCallbackRenderObject(onLayout);
  }

  @override
  void updateRenderObject(BuildContext context, covariant PostLayoutCallbackRenderObject renderObject) {
    renderObject.onLayout = onLayout;
  }
}

class PostLayoutCallbackRenderObject extends RenderProxyBox {
  PostLayoutCallbackRenderObject(this.onLayout);

  void Function() onLayout;

  @override
  void performLayout() {
    super.performLayout();
    onLayout();
  }
}
