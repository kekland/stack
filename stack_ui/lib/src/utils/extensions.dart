import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:vector_math/vector_math_64.dart';

extension IterableOffsetExtensions on Iterable<Offset> {
  Offset get min {
    return Offset(
      map((e) => e.dx).reduce(math.min),
      map((e) => e.dy).reduce(math.min),
    );
  }

  Offset get max {
    return Offset(
      map((e) => e.dx).reduce(math.max),
      map((e) => e.dy).reduce(math.max),
    );
  }
}

extension IterableRectExtensions on Iterable<Rect> {
  Rect get boundingBox {
    final min = map((e) => e.topLeft).min;
    final max = map((e) => e.bottomRight).max;

    return Rect.fromPoints(min, max);
  }
}

extension OffsetExtensions on Offset {
  Offset copyWith({double? dx, double? dy}) {
    return Offset(dx ?? this.dx, dy ?? this.dy);
  }

  Offset floor() => Offset(dx.floorToDouble(), dy.floorToDouble());
  Offset ceil() => Offset(dx.ceilToDouble(), dy.ceilToDouble());
  Offset round() => Offset(dx.roundToDouble(), dy.roundToDouble());
}

extension SizeExtensions on Size {
  Size copyWith({double? width, double? height}) {
    return Size(width ?? this.width, height ?? this.height);
  }
}

extension RectExtensions on Rect {
  Rect floor() => Rect.fromLTRB(
    left.floorToDouble(),
    top.floorToDouble(),
    right.floorToDouble(),
    bottom.floorToDouble(),
  );

  Rect ceil() => Rect.fromLTRB(
    left.ceilToDouble(),
    top.ceilToDouble(),
    right.ceilToDouble(),
    bottom.ceilToDouble(),
  );

  Rect round() => Rect.fromLTRB(
    left.roundToDouble(),
    top.roundToDouble(),
    right.roundToDouble(),
    bottom.roundToDouble(),
  );
}

extension Vector2Extension on Vector2 {
  Offset asOffset() => Offset(x, y);
}

extension OffsetExtension on Offset {
  Vector2 asVector2() => Vector2(dx, dy);
  Vector3 asVector3() => Vector3(dx, dy, 0);
}

extension TextStyleExtension on TextStyle {
  TextStyle get tabular => copyWith(fontFeatures: [.tabularFigures()]);
}
