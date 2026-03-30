import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../_.dart';

typedef GestureSurfaceEffectBuilder = Widget Function(BuildContext context, GestureSurface surface);

mixin GestureSurfaceMixin on Surface {
  Widget Function(BuildContext, Set<WidgetState> state)? get builder;
  GestureSurfaceEffectBuilder? get effectBuilder;
  VoidCallback? get onTap;
  HitTestBehavior get behavior;
  bool get ignoreDisabled;
  double get effectIntensity;

  Widget? resolveChild(BuildContext context, Set<WidgetState>? states) {
    return builder?.call(context, states ?? {}) ?? child;
  }

  Color? resolveColor(BuildContext context, Set<WidgetState>? state) {
    if (color is WidgetStateProperty<Color>) {
      final $color = color as ActionableColor;
      final $state = state ?? (onTap != null ? {} : {WidgetState.disabled});
      if (ignoreDisabled) $state.remove(WidgetState.disabled);

      return $color.resolve($state);
    }

    return color;
  }

  Widget buildSurface(
    BuildContext context, {
    required Set<WidgetState>? state,
    required Widget? child,
    required EdgeInsets? padding,
    bool materialIsContainer = true,
  }) {
    return Surface(
      animationStyle: animationStyle,
      width: width,
      height: height,
      padding: padding,
      shape: shape,
      color: resolveColor(context, state),
      gradient: gradient,
      foregroundColor: foregroundColor,
      clipBehavior: clipBehavior,
      borderRadius: borderRadius,
      borderSide: borderSide,
      shadows: shadows,
      materialIsContainer: materialIsContainer,
      child: child,
    );
  }
}

class GestureSurface extends Surface with GestureSurfaceMixin {
  const GestureSurface({
    super.key,
    super.animationStyle,
    super.width,
    super.height,
    super.padding,
    super.color,
    super.foregroundColor,
    super.gradient,
    super.clipBehavior,
    super.borderRadius,
    super.shadows,
    super.borderSide,
    super.child,
    super.shape,
    this.behavior = HitTestBehavior.opaque,
    this.onTap,
    this.ignoreDisabled = false,
    this.effectIntensity = 1.0,
    this.effectBuilder,
    this.cursor = SystemMouseCursors.click,
    this.builder,
  });

  @override
  final Widget Function(BuildContext context, Set<WidgetState> states)? builder;

  @override
  final GestureSurfaceEffectBuilder? effectBuilder;

  @override
  final VoidCallback? onTap;

  @override
  final HitTestBehavior behavior;

  @override
  final bool ignoreDisabled;

  @override
  final double effectIntensity;

  final MouseCursor cursor;

  @override
  Widget build(BuildContext context) {
    final GestureSurfaceEffectBuilder effectBuilder;

    final isCupertino = defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS;

    if (this.effectBuilder != null) {
      effectBuilder = this.effectBuilder!;
    } else if (isCupertino) {
      if (isExpanded || borderSide != null || color != null) {
        effectBuilder = gestureSurfaceCupertinoHighlightEffect;
      } else {
        effectBuilder = gestureSurfaceCupertinoOpacityEffect;
      }
    } else {
      effectBuilder = gestureSurfaceMaterialEffect;
    }

    return effectBuilder(context, this);
  }
}
