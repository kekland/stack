import 'package:flutter/material.dart';
import 'package:stack/stack.dart';

export 'gesture_surface_effects/gesture_surface_material_effect.dart';
export 'gesture_surface_effects/gesture_surface_cupertino_opacity_effect.dart';
export 'gesture_surface_effects/gesture_surface_cupertino_highlight_effect.dart';

typedef GestureSurfaceEffectBuilder = Widget Function(BuildContext context, GestureSurface surface);

class GestureSurface extends Surface {
  const GestureSurface({
    super.key,
    super.animationStyle,
    super.width,
    super.height,
    super.padding,
    super.color,
    super.foregroundColor,
    super.clipBehavior,
    super.borderRadius,
    super.shadows,
    super.borderSide,
    super.child,
    super.shape,
    this.behavior = HitTestBehavior.opaque,
    this.onTap,
    this.materialInkResponseOffset,
    this.ignoreDisabled = false,
    this.effectIntensity = 1.0,
    this.effectBuilder,
  });

  final GestureSurfaceEffectBuilder? effectBuilder;
  final VoidCallback? onTap;
  final HitTestBehavior behavior;
  final Offset? materialInkResponseOffset;
  final bool ignoreDisabled;
  final double effectIntensity;

  Color? _resolveColor(BuildContext context, Set<WidgetState>? state) {
    if (color is WidgetStateColor) {
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
      color: _resolveColor(context, state),
      foregroundColor: foregroundColor,
      clipBehavior: clipBehavior,
      borderRadius: borderRadius,
      borderSide: borderSide,
      shadows: shadows,
      materialIsContainer: materialIsContainer,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final GestureSurfaceEffectBuilder effectBuilder;

    if (this.effectBuilder != null) {
      effectBuilder = this.effectBuilder!;
    } else if (context.stack.platform == ThemePlatform.material) {
      effectBuilder = gestureSurfaceMaterialEffect;
    } else {
      if (isExpanded || borderSide != null || color != null) {
        effectBuilder = gestureSurfaceCupertinoHighlightEffect;
      } else {
        effectBuilder = gestureSurfaceCupertinoOpacityEffect;
      }
    }

    return effectBuilder(context, this);
  }
}
