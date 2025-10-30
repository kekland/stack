import 'dart:ui';

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

class StDraggableScrollableNotification extends flutter.DraggableScrollableNotification {
  StDraggableScrollableNotification({
    required super.extent,
    required super.minExtent,
    required super.maxExtent,
    required super.initialExtent,
    required super.context,
    super.shouldCloseOnMinExtent,
  });
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
  StDraggableSheetExtent createExtent() {
    return StDraggableSheetExtent(
      minSize: widget.minChildSize,
      maxSize: widget.maxChildSize,
      snap: widget.snap,
      snapSizes: impliedSnapSizes(),
      snapAnimationDuration: widget.snapAnimationDuration,
      initialSize: widget.initialChildSize,
      shouldCloseOnMinExtent: widget.shouldCloseOnMinExtent,
    );
  }

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

class StDraggableSheetExtent extends flutter.DraggableSheetExtent {
  StDraggableSheetExtent({
    required super.minSize,
    required super.maxSize,
    required super.snap,
    required super.snapSizes,
    required super.initialSize,
    super.currentSize,
    super.hasChanged,
    super.hasDragged,
    super.shouldCloseOnMinExtent,
    super.snapAnimationDuration,
  });

  @override
  StDraggableScrollableNotification createNotification(BuildContext context) {
    return StDraggableScrollableNotification(
      minExtent: minSize,
      maxExtent: maxSize,
      extent: currentSize,
      initialExtent: initialSize,
      context: context,
      shouldCloseOnMinExtent: shouldCloseOnMinExtent,
    );
  }

  @override
  StDraggableSheetExtent copyWith({
    required double minSize,
    required double maxSize,
    required bool snap,
    required List<double> snapSizes,
    required double initialSize,
    required Duration? snapAnimationDuration,
    required bool shouldCloseOnMinExtent,
  }) {
    return StDraggableSheetExtent(
      minSize: minSize,
      maxSize: maxSize,
      snap: snap,
      snapSizes: snapSizes,
      snapAnimationDuration: snapAnimationDuration,
      initialSize: initialSize,
      currentSize: ValueNotifier<double>(hasChanged ? clampDouble(currentSizeValue, minSize, maxSize) : initialSize),
      hasDragged: hasDragged,
      hasChanged: hasChanged,
      shouldCloseOnMinExtent: shouldCloseOnMinExtent,
    );
  }
}
