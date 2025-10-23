import 'dart:ui';

void drawDashedLine(
  Canvas canvas, {
  required Offset from,
  required Offset to,
  required Iterable<double> pattern,
  required Paint paint,
}) {
  assert(pattern.length.isEven);
  final distance = (to - from).distance;
  final normalizedPattern = pattern.map((width) => width / distance).toList();
  final points = <Offset>[];
  double t = 0;
  int i = 0;

  while (t < 1) {
    points.add(Offset.lerp(from, to, t)!);
    t += normalizedPattern[i++]; // dashWidth
    points.add(Offset.lerp(from, to, t.clamp(0, 1))!);
    t += normalizedPattern[i++]; // dashSpace
    i %= normalizedPattern.length;
  }

  canvas.drawPoints(PointMode.lines, points, paint);
}
