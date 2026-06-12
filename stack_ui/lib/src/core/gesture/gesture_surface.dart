import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../_.dart';

typedef GestureSurfaceEffectBuilder = Widget Function(BuildContext context, GestureSurface surface);

mixin GestureSurfaceMixin on Surface {
  Widget Function(BuildContext, Set<WidgetState> state)? get builder;
  GestureSurfaceEffectBuilder? get effectBuilder;
  Set<PointerDeviceKind>? get supportedDevices;
  VoidCallback? get onTap;
  HitTestBehavior get behavior;
  bool get ignoreDisabled;
  double get effectIntensity;

  GestureDragStartCallback? get onHorizontalDragStart;
  GestureDragUpdateCallback? get onHorizontalDragUpdate;
  GestureDragEndCallback? get onHorizontalDragEnd;
  GestureDragCancelCallback? get onHorizontalDragCancel;
  GestureDragDownCallback? get onHorizontalDragDown;

  GestureDragStartCallback? get onVerticalDragStart;
  GestureDragUpdateCallback? get onVerticalDragUpdate;
  GestureDragEndCallback? get onVerticalDragEnd;
  GestureDragCancelCallback? get onVerticalDragCancel;
  GestureDragDownCallback? get onVerticalDragDown;

  GestureDragStartCallback? get onPanStart;
  GestureDragUpdateCallback? get onPanUpdate;
  GestureDragEndCallback? get onPanEnd;
  GestureDragCancelCallback? get onPanCancel;
  GestureDragDownCallback? get onPanDown;

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
    this.supportedDevices,
    this.onHorizontalDragDown,
    this.onHorizontalDragStart,
    this.onHorizontalDragUpdate,
    this.onHorizontalDragEnd,
    this.onHorizontalDragCancel,
    this.onVerticalDragDown,
    this.onVerticalDragStart,
    this.onVerticalDragUpdate,
    this.onVerticalDragEnd,
    this.onVerticalDragCancel,
    this.onPanDown,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.onPanCancel,
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

  @override
  final Set<PointerDeviceKind>? supportedDevices;

  final MouseCursor cursor;

  // dart format off
  @override final GestureDragStartCallback? onHorizontalDragStart;
  @override final GestureDragUpdateCallback? onHorizontalDragUpdate;
  @override final GestureDragEndCallback? onHorizontalDragEnd;
  @override final GestureDragCancelCallback? onHorizontalDragCancel;
  @override final GestureDragDownCallback? onHorizontalDragDown;

  @override final GestureDragStartCallback? onVerticalDragStart;
  @override final GestureDragUpdateCallback? onVerticalDragUpdate;
  @override final GestureDragEndCallback? onVerticalDragEnd;
  @override final GestureDragCancelCallback? onVerticalDragCancel;
  @override final GestureDragDownCallback? onVerticalDragDown;

  @override final GestureDragStartCallback? onPanStart;
  @override final GestureDragUpdateCallback? onPanUpdate;
  @override final GestureDragEndCallback? onPanEnd;
  @override final GestureDragCancelCallback? onPanCancel;
  @override final GestureDragDownCallback? onPanDown;
  // dart format on

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
