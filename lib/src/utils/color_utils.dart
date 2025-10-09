import 'package:flutter/widgets.dart';

extension ColorExtensions on Color {
  Color withMultipliedOpacity(double opacity) {
    return Color.from(alpha: a * opacity, red: r, green: g, blue: b);
  }

  Color get transparent => withValues(alpha: 0.0);

  bool equalsIgnoreOpacity(Color other) {
    return r == other.r && g == other.g && b == other.b;
  }
}
