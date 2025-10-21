import 'package:flutter/material.dart';
import 'package:stack/stack.dart';

class StAnimatedOpacity extends StatelessWidget {
  const StAnimatedOpacity({
    super.key,
    this.animationStyle,
    required this.opacity,
    this.child,
    this.onEnd,
  });

  final AnimationStyle? animationStyle;
  final double opacity;
  final VoidCallback? onEnd;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final animationStyle = this.animationStyle ?? context.stack.defaultEffectAnimation;

    if (animationStyle.duration == null) {
      return Opacity(
        opacity: opacity,
        child: child,
      );
    }

    return AnimatedOpacity(
      opacity: opacity,
      duration: animationStyle.duration!,
      curve: animationStyle.curve ?? Curves.linear,
      onEnd: onEnd,
      child: child,
    );
  }
}
