import 'package:flutter/widgets.dart';

class ActionableColor extends WidgetStateColor {
  ActionableColor({
    required this.idle,
    required this.disabled,
    this.pressed,
  }) : super(idle.toARGB32());

  final SurfaceColor idle;
  final SurfaceColor? pressed;
  final SurfaceColor disabled;

  @override
  Color resolve(Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled)) return disabled;
    if (states.contains(WidgetState.pressed)) return pressed ?? idle;
    return idle;
  }
}

@immutable
class SurfaceColor extends Color {
  const SurfaceColor.constant({
    required int background,
    required this.foreground,
  }) : super(background);

  SurfaceColor({
    required Color background,
    required this.foreground,
  }) : super(background.toARGB32());

  Color get background => this;
  final Color foreground;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SurfaceColor && super == other && other.foreground == foreground;
  }

  @override
  int get hashCode => Object.hash(background, foreground);
}
