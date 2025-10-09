import 'package:flutter/material.dart';
import 'package:stack/stack.dart';

class StAnimatedScale extends StatelessWidget {
  const StAnimatedScale({
    super.key,
    this.animationStyle,
    required this.scale,
    this.child,
    this.onEnd,
    this.alignment = Alignment.center,
  });

  final AnimationStyle? animationStyle;
  final Alignment alignment;
  final double scale;
  final VoidCallback? onEnd;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final animationStyle = this.animationStyle ?? context.stack.defaultEffectAnimation;

    return AnimatedScale(
      scale: scale,
      alignment: alignment,
      duration: animationStyle.duration!,
      curve: animationStyle.curve ?? Curves.linear,
      onEnd: onEnd,
      child: child,
    );
  }
}
