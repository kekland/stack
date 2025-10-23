import 'package:flutter/material.dart';
import 'package:stack_ui/stack_ui.dart';

class StAnimatedPadding extends StatelessWidget {
  const StAnimatedPadding({
    super.key,
    this.animationStyle,
    required this.padding,
    this.child,
    this.onEnd,
  });

  final AnimationStyle? animationStyle;
  final EdgeInsets padding;
  final VoidCallback? onEnd;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final animationStyle = this.animationStyle ?? context.stack.defaultEffectAnimation;

    if (animationStyle.duration == null) {
      return Padding(
        padding: padding,
        child: child,
      );
    }

    return AnimatedPadding(
      padding: padding,
      duration: animationStyle.duration!,
      curve: animationStyle.curve ?? Curves.linear,
      onEnd: onEnd,
      child: child,
    );
  }
}
