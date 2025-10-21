import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// This scroll physics acts like a [BouncingScrollPhysics], but clamps the
/// scroll to the top when the user tries to scroll past the top.
class TopClampedBouncingScrollPhysics extends BouncingScrollPhysics {
  const TopClampedBouncingScrollPhysics({
    super.parent,
    super.decelerationRate,
  });

  @override
  TopClampedBouncingScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return TopClampedBouncingScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    // This part is copied from [ClampingScrollPhysics], but with overscroll
    // clamping removed.
    assert(() {
      if (value == position.pixels) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('$runtimeType.applyBoundaryConditions() was called redundantly.'),
          ErrorDescription(
            'The proposed new position, $value, is exactly equal to the current position of the '
            'given ${position.runtimeType}, ${position.pixels}.\n'
            'The applyBoundaryConditions method should only be called when the value is '
            'going to actually change the pixels, otherwise it is redundant.',
          ),
          DiagnosticsProperty<ScrollPhysics>('The physics object in question was', this,
              style: DiagnosticsTreeStyle.errorProperty),
          DiagnosticsProperty<ScrollMetrics>('The position object in question was', position,
              style: DiagnosticsTreeStyle.errorProperty),
        ]);
      }
      return true;
    }());
    if (value < position.pixels && position.pixels <= position.minScrollExtent) {
      // Underscroll.
      return value - position.pixels;
    }

    if (value < position.minScrollExtent && position.minScrollExtent < position.pixels) {
      // Hit top edge.
      return value - position.minScrollExtent;
    }

    return 0.0;
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    // This part is copied from [BouncingScrollPhysics], but with overscroll
    // clamping removed.
    final Tolerance tolerance = toleranceFor(position);

    if (position.pixels < position.minScrollExtent) {
      double? end;
      if (position.pixels > position.maxScrollExtent) {
        end = position.maxScrollExtent;
      }
      if (position.pixels < position.minScrollExtent) {
        end = position.minScrollExtent;
      }

      return ScrollSpringSimulation(
        spring,
        position.pixels,
        end!,
        math.min(0.0, velocity),
        tolerance: tolerance,
      );
    }

    return super.createBallisticSimulation(position, velocity);
  }
}
