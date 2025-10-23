import 'package:flutter/material.dart';
import 'package:stack/stack.dart';

class StAnimatedScaleVisibility extends StatelessWidget {
  const StAnimatedScaleVisibility({
    super.key,
    required this.isVisible,
    required this.child,
    this.alignment = Alignment.center,
    this.animationStyle,
    this.opacityAnimationStyle,
    this.scaleAnimationStyle,
  });

  final AnimationStyle? animationStyle;
  final AnimationStyle? opacityAnimationStyle;
  final AnimationStyle? scaleAnimationStyle;
  final bool isVisible;
  final Alignment alignment;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return StAnimatedOpacity(
      animationStyle: opacityAnimationStyle ?? animationStyle ?? context.stack.defaultEffectAnimation,
      opacity: isVisible ? 1.0 : 0.0,
      child: StAnimatedScale(
        animationStyle: scaleAnimationStyle?? animationStyle ?? context.stack.defaultSpatialAnimation,
        alignment: alignment,
        scale: isVisible ? 1.0 : 0.0,
        child: child,
      ),
    );
  }
}
