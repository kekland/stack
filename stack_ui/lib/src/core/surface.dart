import '_.dart';
import 'flutter/material/material.dart';

import 'package:flutter/material.dart';

class Surface extends StatelessWidget {
  const Surface({
    super.key,
    this.animationStyle,
    this.width,
    this.height,
    this.padding,
    this.color,
    this.foregroundColor,
    this.gradient,
    this.clipBehavior,
    this.borderRadius,
    this.borderSide,
    this.shadows,
    this.shape,
    this.materialIsContainer = true,
    this.child,
  });

  final AnimationStyle? animationStyle;
  final double? width;
  final double? height;
  final EdgeInsets? padding;

  final Color? color;
  final Color? foregroundColor;
  final Gradient? gradient;

  final Clip? clipBehavior;
  final BorderRadius? borderRadius;

  final BorderSide? borderSide;
  final List<BoxShadow>? shadows;

  final ShapeBorder? shape;

  final bool materialIsContainer;

  final Widget? child;

  bool get isFinite => (width?.isFinite == true) && (height?.isFinite == true);
  bool get isExpanded => (width?.isInfinite == true) || (height?.isInfinite == true);
  bool get childIsFlex => child is Flex;

  Color _computeForegroundColor(Color color) {
    final brightness = ThemeData.estimateBrightnessForColor(color);
    return brightness == Brightness.light ? Colors.black : Colors.white;
  }

  ShapeBorder? _resolveShapeBorder(BuildContext context) {
    if (shape != null) {
      return shape;
    }

    if (borderSide == null && borderRadius == null) {
      return null;
    }

    final _borderRadius = (borderRadius ?? BorderRadius.zero);
    final _borderSide = borderSide ?? BorderSide.none;

    return RoundedRectangleBorderNoPadding(
      borderRadius: _borderRadius,
      side: _borderSide,
    );
  }

  @override
  Widget build(BuildContext context) {
    final animationStyle = this.animationStyle ?? AnimationStyle.noAnimation;

    SurfaceColor surfaceColor;

    if (color is SurfaceColor) {
      surfaceColor = color as SurfaceColor;
    } else if (color is Color) {
      surfaceColor = SurfaceColor(background: color!, foreground: null);
    } else {
      surfaceColor = Surface.colorOf(context);
    }

    Color? foregroundColor;
    if (this.foregroundColor != null) {
      foregroundColor = this.foregroundColor!;
    } else if (surfaceColor.foreground == null) {
      foregroundColor = Surface.maybeColorOf(context)?.foreground ?? _computeForegroundColor(surfaceColor.background);
    }

    surfaceColor = surfaceColor.copyWithForeground(foregroundColor);

    Widget child = this.child ?? const SizedBox.shrink();

    if (animationStyle.hasDuration) {
      child = AnimatedPadding(
        duration: animationStyle.duration!,
        curve: animationStyle.curve ?? Curves.linear,
        padding: padding ?? EdgeInsets.zero,
        child: child,
      );
    } else {
      child = Padding(padding: padding ?? EdgeInsets.zero, child: child);
    }

    child = DefaultForegroundStyle(
      animationStyle: animationStyle,
      color: surfaceColor.foreground,
      child: InheritedSurfaceColor(
        color: surfaceColor,
        child: child,
      ),
    );

    final shape = _resolveShapeBorder(context);

    if (materialIsContainer) {
      child = Material(
        type: MaterialType.transparency,
        clipBehavior: Clip.none,
        shape: shape,
        child: MaterialWithNoInkClip(child: child),
      );
    }

    final decoration = ShapeDecorationWithLchLerp(
      color: gradient != null ? null : color,
      shape: shape ?? const RoundedRectangleBorder(),
      shadows: shadows,
      gradient: gradient,
    );

    var clipBehavior = this.clipBehavior;
    clipBehavior ??= color != null || shape != null ? Clip.antiAlias : Clip.none;

    if (animationStyle.duration == Duration.zero) {
      return Container(
        width: width,
        height: height,
        decoration: decoration,
        clipBehavior: clipBehavior,
        child: child,
      );
    }

    return AnimatedContainer(
      duration: animationStyle.duration!,
      curve: animationStyle.curve!,
      width: width,
      height: height,
      decoration: decoration,
      clipBehavior: clipBehavior,
      child: child,
    );
  }

  static InheritedSurfaceColor? _surfaceColorOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<InheritedSurfaceColor>();
  }

  static SurfaceColor? maybeColorOf(BuildContext context) => _surfaceColorOf(context)?.color;
  static SurfaceColor colorOf(BuildContext context) => maybeColorOf(context)!;
}

class InheritedSurfaceColor extends InheritedWidget {
  const InheritedSurfaceColor({
    super.key,
    required this.color,
    required super.child,
  });

  final SurfaceColor? color;

  @override
  bool updateShouldNotify(covariant InheritedSurfaceColor oldWidget) {
    return color != oldWidget.color;
  }
}
