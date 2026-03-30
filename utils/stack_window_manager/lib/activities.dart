import 'package:flutter/widgets.dart';
import 'package:stack_ui/stack_ui.dart';

class WindowMoveActivity extends DragActivity {
  WindowMoveActivity({
    required this.initialRect,
    required this.onChanged,
  });

  final Rect initialRect;
  final ValueChanged<Rect> onChanged;

  @override
  void onUpdate(DragUpdateDetails details) {
    final delta = details.globalPosition - startDetails.globalPosition;
    final newRect = initialRect.shift(delta);
    onChanged(newRect);

    super.onUpdate(details);
  }
}

class WindowEdgeResizeActivity extends DragActivity {
  WindowEdgeResizeActivity({
    required this.initialRect,
    required this.onChanged,
    required this.edge,
  });

  final Edge edge;
  final Rect initialRect;
  final ValueChanged<Rect> onChanged;

  @override
  void onUpdate(DragUpdateDetails details) {
    final delta = details.globalPosition - startDetails.globalPosition;
    final newRect = initialRect.applyEdgeResize(edge, delta);
    onChanged(newRect);

    super.onUpdate(details);
  }
}

class WindowCornerResizeActivity extends DragActivity {
  WindowCornerResizeActivity({
    required this.initialRect,
    required this.onChanged,
    required this.corner,
  });

  final Corner corner;
  final Rect initialRect;
  final ValueChanged<Rect> onChanged;

  @override
  void onUpdate(DragUpdateDetails details) {
    final delta = details.globalPosition - startDetails.globalPosition;
    final newRect = initialRect.applyCornerResize(corner, delta);
    onChanged(newRect);

    super.onUpdate(details);
  }
}
