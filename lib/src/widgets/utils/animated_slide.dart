import 'package:flutter/material.dart';
import 'package:stack/stack.dart';

class StAnimatedSlide extends StatelessWidget {
  const StAnimatedSlide({
    super.key,
    this.animationStyle,
    this.onEnd,
    required this.offset,
    required this.child,
  });

  final Offset offset;
  final AnimationStyle? animationStyle;
  final VoidCallback? onEnd;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final animationStyle = this.animationStyle ?? context.stack.defaultEffectAnimation;

    return AnimatedSlide(
      offset: offset,
      duration: animationStyle.duration!,
      curve: animationStyle.curve!,
      onEnd: onEnd,
      child: child,
    );
  }
}
