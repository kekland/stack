import 'package:flutter/widgets.dart';

class ActionableColor extends SurfaceColor implements WidgetStateProperty<Color> {
  ActionableColor({
    required SurfaceColor idle,
    required this.disabled,
    this.hovered,
    this.pressed,
  }) : super(background: idle.background, foreground: idle.foreground);

  SurfaceColor get idle => this;
  final SurfaceColor? hovered;
  final SurfaceColor? pressed;
  final SurfaceColor disabled;

  @override
  Color resolve(Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled)) return disabled;
    if (states.contains(WidgetState.pressed)) return pressed ?? hovered ?? idle;
    if (states.contains(WidgetState.hovered)) return hovered ?? idle;
    return idle;
  }

  @override
  ActionableColor copyWithForeground(Color? foreground) {
    return ActionableColor(
      idle: SurfaceColor(background: idle.background, foreground: foreground ?? idle.foreground),
      hovered: hovered?.copyWithForeground(foreground),
      pressed: pressed?.copyWithForeground(foreground),
      disabled: disabled.copyWithForeground(foreground),
    );
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
  final Color? foreground;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SurfaceColor && super == other && other.foreground == foreground;
  }

  @override
  int get hashCode => Object.hash(background.toARGB32(), foreground);

  SurfaceColor copyWithForeground(Color? foreground) {
    return SurfaceColor(
      background: this,
      foreground: foreground ?? this.foreground,
    );
  }
}
