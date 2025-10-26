import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import '../../widgets/flutter/draggable_scrollable_sheet.dart' as flutter;

class StDraggableScrollableController extends flutter.DraggableScrollableController {
  StDraggableScrollableController() : super();

  @override
  Future<void> animateTo(double size, {required Duration duration, required Curve curve}) {
    attachedController?.position.goIdle();
    return super.animateTo(size, duration: duration, curve: curve);
  }
}

class StDraggableScrollableSheet extends flutter.DraggableScrollableSheet {
  const StDraggableScrollableSheet({
    super.key,
    required super.builder,
    StDraggableScrollableController? super.controller,
    super.initialChildSize,
    super.minChildSize,
    super.maxChildSize,
    super.expand = true,
    super.snap = false,
    super.snapSizes,
    super.shouldCloseOnMinExtent,
    super.snapAnimationDuration,
    this.headerAreaExtent,
  });

  final double? headerAreaExtent;

  @override
  StDraggableScrollableSheetState createState() => StDraggableScrollableSheetState();
}

class StDraggableScrollableSheetState extends flutter.DraggableScrollableSheetState {
  @override
  StDraggableScrollableSheet get widget => super.widget as StDraggableScrollableSheet;

  @override
  StDraggableScrollableSheetScrollController createScrollController(flutter.DraggableSheetExtent extent) {
    return StDraggableScrollableSheetScrollController(
      extent: extent,
      headerAreaExtent: widget.headerAreaExtent,
    );
  }
}

class StDraggableScrollableSheetScrollController extends flutter.DraggableScrollableSheetScrollController {
  StDraggableScrollableSheetScrollController({
    required super.extent,
    this.headerAreaExtent,
  });

  final double? headerAreaExtent;

  @override
  StDraggableScrollableSheetScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) {
    return StDraggableScrollableSheetScrollPosition(
      physics: physics.applyTo(const AlwaysScrollableScrollPhysics()),
      context: context,
      oldPosition: oldPosition,
      getExtent: () => extent,
      headerAreaExtent: headerAreaExtent,
    );
  }
}

class StDraggableScrollableSheetScrollPosition extends flutter.DraggableScrollableSheetScrollPosition {
  StDraggableScrollableSheetScrollPosition({
    required super.physics,
    required super.context,
    required super.getExtent,
    super.oldPosition,
    this.headerAreaExtent,
  });

  var _isHeaderDragging = false;
  final double? headerAreaExtent;

  @override
  void applyUserOffset(double delta) {
    if (_isHeaderDragging) {
      extent.addPixelDelta(-delta, context.notificationContext!);
      return;
    }

    if (delta < 0.0 && !extent.isAtMax) {
      extent.addPixelDelta(-delta, context.notificationContext!);
      return;
    }

    super.applyUserOffset(delta);
  }

  @override
  void didEndScroll() {
    _isHeaderDragging = false;
    super.didEndScroll();
  }

  @override
  void goBallistic(double velocity) {
    if (_isHeaderDragging) {
      goBallisticForSheet(velocity);
      return;
    }

    super.goBallistic(velocity);
  }

  @override
  Drag drag(DragStartDetails details, VoidCallback dragCancelCallback) {
    if (headerAreaExtent != null) {
      _isHeaderDragging = details.localPosition.dy <= headerAreaExtent!;
      return super.drag(details, dragCancelCallback);
    }

    return super.drag(details, dragCancelCallback);
  }
}
