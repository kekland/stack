import 'package:flutter/material.dart';
import 'package:stack/stack.dart';

class StAnimatedScaleVisibility extends StatelessWidget {
  const StAnimatedScaleVisibility({
    super.key,
    required this.isVisible,
    required this.child,
    this.alignment = Alignment.center,
  });

  final bool isVisible;
  final Alignment alignment;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return StAnimatedOpacity(
      animationStyle: context.stack.defaultEffectAnimation,
      opacity: isVisible ? 1.0 : 0.0,
      child: StAnimatedScale(
        animationStyle: context.stack.defaultSpatialAnimation,
        alignment: alignment,
        scale: isVisible ? 1.0 : 0.0,
        child: child,
      ),
    );
  }
}
