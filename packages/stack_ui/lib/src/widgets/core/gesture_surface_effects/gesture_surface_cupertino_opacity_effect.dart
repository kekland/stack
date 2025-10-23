import 'package:flutter/material.dart';
import 'package:stack_ui/stack_ui.dart';

Widget gestureSurfaceCupertinoOpacityEffect(BuildContext context, GestureSurface surface) {
  return GestureRegion(
    behavior: surface.behavior,
    onTap: surface.onTap,
    detectorBuilder: defaultGestureRegionDetectorBuilder,
    builder: (context, state) => _CupertinoOpacityEffectAnimator(
      state: state,
      animateOpacityOnDisabled: !surface.ignoreDisabled,
      intensity: surface.effectIntensity,
      child: surface.buildSurface(
        context,
        state: null,
        padding: surface.padding,
        child: surface.child,
      ),
    ),
  );
}

class _CupertinoOpacityEffectAnimator extends StatefulWidget {
  const _CupertinoOpacityEffectAnimator({
    required this.state,
    required this.child,
    required this.intensity,
    this.animateOpacityOnDisabled = true,
  });

  static const opacityIdle = 1.0;
  static const opacityPressed = 0.7;
  static const opacityDisabled = 0.5;

  static double resolveOpacity(Set<WidgetState> state) {
    if (state.contains(WidgetState.disabled)) return opacityDisabled;
    if (state.contains(WidgetState.pressed)) return opacityPressed;

    return opacityIdle;
  }

  final bool animateOpacityOnDisabled;
  final Set<WidgetState> state;
  final double intensity;
  final Widget child;

  double get opacity => resolveOpacity(state);

  @override
  State<_CupertinoOpacityEffectAnimator> createState() => _CupertinoOpacityEffectAnimatorState();
}

class _CupertinoOpacityEffectAnimatorState extends State<_CupertinoOpacityEffectAnimator>
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
      curve: Curves.linear,
    );

    _onStateUpdated(animate: false);
  }

  @override
  void didUpdateWidget(covariant _CupertinoOpacityEffectAnimator oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.state != oldWidget.state) _onStateUpdated(animate: true);
  }

  void _onStateUpdated({bool animate = false}) {
    if (widget.state.isEmpty) {
      if (animate) {
        _controller.forward();
      } else {
        _controller.value = widget.opacity;
      }

      return;
    }

    if (widget.state.contains(WidgetState.pressed)) {
      _controller.value = widget.opacity;
      return;
    }

    if (widget.animateOpacityOnDisabled && widget.state.contains(WidgetState.disabled)) {
      _controller.value = widget.opacity;
      return;
    }

    _controller.value = 1.0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      child: widget.child,
      builder: (context, child) {
        final opacity = 1.0 - ((1.0 - _animation.value) * widget.intensity);

        return Opacity(
          opacity: opacity,
          child: child,
        );
      },
    );
  }
}
