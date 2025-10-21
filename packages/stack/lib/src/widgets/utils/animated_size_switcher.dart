import 'package:flutter/material.dart';
import 'package:stack/stack.dart';

class StAnimatedSizeSwitcher extends StatelessWidget {
  const StAnimatedSizeSwitcher({
    super.key,
    this.animationStyle,
    this.sizeAnimationStyle,
    this.switcherAnimationStyle,
    this.transitionBuilder,
    required this.alignment,
    required this.child,
  });

  final AnimationStyle? animationStyle;
  final AnimationStyle? sizeAnimationStyle;
  final AnimationStyle? switcherAnimationStyle;
  final AnimatedSwitcherTransitionBuilder? transitionBuilder;
  final Alignment alignment;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return StAnimatedSize(
      animationStyle: sizeAnimationStyle ?? animationStyle ?? context.stack.defaultEffectAnimation,
      alignment: alignment,
      child: StAnimatedSwitcher(
        animationStyle: switcherAnimationStyle ?? animationStyle ?? context.stack.defaultEffectAnimation,
        transitionBuilder:
            transitionBuilder ??
            (Widget child, Animation<double> animation) {
              final _animation = CurvedAnimation(
                parent: animation,
                curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
                reverseCurve: const Interval(0.55, 1.0, curve: Curves.easeIn),
              );

              return ScaleTransition(
                scale: _animation,
                alignment: alignment,
                child: FadeTransition(
                  opacity: _animation,
                  child: child,
                ),
              );
            },
        layoutBuilder: StAnimatedSwitcher.layoutBuilderWithCurrentChildSize(alignment),
        child: child,
      ),
    );
  }
}
