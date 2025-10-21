import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A widget that notifies when the size of [child] has changed.
///
/// This widget is useful when you want to know the size of a widget
/// after it has been rendered.
///
/// [onChanged] is called when the size of the widget has changed.
class SizeNotifierWidget extends SingleChildRenderObjectWidget {
  const SizeNotifierWidget({
    super.key,
    required this.onChanged,
    required super.child,
  });

  /// Called when the size of [child] has changed.
  final ValueChanged<Size> onChanged;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return SizeNotifierRenderObject(onChanged: onChanged);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    SizeNotifierRenderObject renderObject,
  ) {
    renderObject.onChanged = onChanged;
  }
}

class SizeNotifierRenderObject extends RenderProxyBox {
  SizeNotifierRenderObject({required this.onChanged});

  ValueChanged<Size> onChanged;

  Size? _lastSize;

  @override
  void performLayout() {
    super.performLayout();

    if (size != _lastSize) {
      _lastSize = size;
      onChanged(size);
    }
  }
}
