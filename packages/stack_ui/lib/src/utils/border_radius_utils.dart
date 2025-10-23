import 'package:flutter/widgets.dart';

extension RadiusExtensions on Radius {
  bool get isCircular => x == y;
}

extension BorderRadiusExtensions on BorderRadius {
  bool get isCircular {
    return topLeft.isCircular && topRight.isCircular && bottomLeft.isCircular && bottomRight.isCircular;
  }

  double get circularRadius {
    if (isCircular) {
      return topLeft.x;
    }

    throw Exception('BorderRadius is not circular');
  }
}
