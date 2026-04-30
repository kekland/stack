import 'dart:math' as math;
import 'dart:ui';

extension DrawDashedPath on Canvas {
  void drawDashedPath(
    Path path, {
    required Paint paint,
    required double dashLength,
    required double gapLength,
  }) {
    final dashedPath = path.dashed(dashLength: dashLength, gapLength: gapLength);
    drawPath(dashedPath, paint);
  }
}

extension DashedPath on Path {
  Path dashed({
    required double dashLength,
    required double gapLength,
  }) {
    final result = Path();

    for (final metric in computeMetrics()) {
      var distance = 0.0;
      var drawing = true;

      while (distance < metric.length) {
        final step = drawing ? dashLength : gapLength;
        final end = math.min(distance + step, metric.length);
        if (drawing) result.addPath(metric.extractPath(distance, end), Offset.zero);

        distance = end;
        drawing = !drawing;
      }
    }

    return result;
  }
}
