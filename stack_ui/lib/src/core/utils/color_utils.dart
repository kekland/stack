import 'dart:ui' as ui;

extension ColorExtensions on ui.Color {
  ui.Color withScaledAlpha(double opacity) {
    return ui.Color.from(alpha: a * opacity, red: r, green: g, blue: b, colorSpace: colorSpace);
  }
}
