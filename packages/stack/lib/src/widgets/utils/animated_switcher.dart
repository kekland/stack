import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:stack/stack.dart';

class StAnimatedSwitcher extends StatelessWidget {
  const StAnimatedSwitcher({
    super.key,
    this.animationStyle,
    this.transitionBuilder = AnimatedSwitcher.defaultTransitionBuilder,
    this.layoutBuilder = AnimatedSwitcher.defaultLayoutBuilder,
    this.child,
  });

  static AnimatedSwitcherLayoutBuilder layoutBuilderWithAlignment(Alignment alignment) {
    return (Widget? currentChild, List<Widget> previousChildren) {
      return Stack(
        alignment: alignment,
        clipBehavior: Clip.none,
        children: [
          ...previousChildren,
          if (currentChild != null) currentChild,
        ],
      );
    };
  }

  static AnimatedSwitcherLayoutBuilder layoutBuilderWithCurrentChildSize(Alignment alignment) {
    return (Widget? currentChild, List<Widget> previousChildren) {
      return LayoutBuilder(
        builder: (context, constraints) => Align(
          alignment: alignment,
          widthFactor: 1.0,
          child: Stack(
            alignment: alignment,
            clipBehavior: Clip.none,
            children: <Widget>[
              if (currentChild != null)
                ...previousChildren.map(
                  (v) => Positioned.fill(
                    child: OverflowBox(
                      alignment: alignment,
                      fit: OverflowBoxFit.deferToChild,
                      minWidth: constraints.minWidth,
                      maxWidth: constraints.maxWidth,
                      minHeight: constraints.minHeight,
                      maxHeight: constraints.maxHeight,
                      child: v,
                    ),
                  ),
                )
              else
                ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          ),
        ),
      );
    };
  }

  final AnimationStyle? animationStyle;
  final AnimatedSwitcherLayoutBuilder layoutBuilder;
  final AnimatedSwitcherTransitionBuilder transitionBuilder;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final animationStyle = this.animationStyle ?? context.stack.defaultEffectAnimation;
    if (animationStyle == AnimationStyle.noAnimation) {
      return child ?? const SizedBox.shrink();
    }

    return AnimatedSwitcher(
      duration: animationStyle.duration!,
      reverseDuration: animationStyle.reverseDuration,
      switchInCurve: animationStyle.curve!,
      switchOutCurve: animationStyle.curve!,
      layoutBuilder: layoutBuilder,
      transitionBuilder: transitionBuilder,
      child: child,
    );
  }
}
