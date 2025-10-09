import 'package:flutter/material.dart';
import 'package:stack/stack.dart';

Widget gestureSurfaceCupertinoHighlightEffect(BuildContext context, GestureSurface surface) {
  return GestureRegion(
    behavior: surface.behavior,
    onTap: surface.onTap,
    detectorBuilder: defaultGestureRegionDetectorBuilder,
    builder: (context, state) => surface.buildSurface(
      context,
      state: state,
      padding: EdgeInsets.zero,
      child: _CupertinoHighlightEffectAnimator(
        state: state,
        animateOpacityOnDisabled: !surface.ignoreDisabled,
        intensity: surface.effectIntensity,
        child: Padding(
          padding: surface.padding ?? EdgeInsets.zero,
          child: surface.child,
        ),
      ),
    ),
  );
}

class _CupertinoHighlightEffectAnimator extends StatefulWidget {
  const _CupertinoHighlightEffectAnimator({
    required this.state,
    required this.intensity,
    required this.child,
    this.animateOpacityOnDisabled = false,
  });

  final Set<WidgetState> state;
  final bool animateOpacityOnDisabled;
  final double intensity;
  final Widget? child;

  @override
  State<_CupertinoHighlightEffectAnimator> createState() => _CupertinoHighlightEffectAnimatorState();
}

class _CupertinoHighlightEffectAnimatorState extends State<_CupertinoHighlightEffectAnimator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    if (widget.state.contains(WidgetState.pressed)) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_CupertinoHighlightEffectAnimator oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.state != oldWidget.state) {
      if (widget.state.contains(WidgetState.pressed)) {
        _controller.value = 1.0;
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color overlayColor;

    overlayColor = context.stack.brightness == Brightness.light
        ? Colors.black.withValues(alpha: 0.1)
        : Colors.white.withValues(alpha: 0.12);

    return StAnimatedOpacity(
      animationStyle: context.stack.defaultEffectAnimation,
      opacity: widget.animateOpacityOnDisabled && widget.state.contains(WidgetState.disabled) ? 0.35 : 1.0,
      child: AnimatedBuilder(
        animation: _animation,
        child: widget.child,
        builder: (context, child) {
          return DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              color: overlayColor.withValues(alpha: overlayColor.a * _animation.value * widget.intensity),
            ),
            child: child,
          );
        },
      ),
    );
  }
}
