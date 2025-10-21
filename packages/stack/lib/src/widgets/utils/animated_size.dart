import 'package:flutter/material.dart';
import 'package:stack/stack.dart';

class StAnimatedSize extends StatelessWidget {
  const StAnimatedSize({
    super.key,
    this.animationStyle,
    this.alignment = Alignment.center,
    this.clipBehavior = Clip.none,
    this.onEnd,
    required this.child,
  });

  final AnimationStyle? animationStyle;
  final Alignment alignment;
  final Clip clipBehavior;
  final VoidCallback? onEnd;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final animationStyle = this.animationStyle ?? context.stack.defaultEffectAnimation;

    return AnimatedSize(
      duration: animationStyle.duration!,
      reverseDuration: animationStyle.reverseDuration,
      curve: animationStyle.curve!,
      clipBehavior: clipBehavior,
      alignment: alignment,
      onEnd: onEnd,
      child: child,
    );
  }
}
