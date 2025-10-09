import 'package:flutter/material.dart';
import 'package:stack/src/widgets/flutter/material/material.dart';
import 'package:stack/stack.dart';

class Surface extends StatelessWidget {
  const Surface({
    super.key,
    this.animationStyle,
    this.width,
    this.height,
    this.padding,
    this.color,
    this.foregroundColor,
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

    final isCircle =
        borderRadius != null &&
        borderRadius!.isCircular &&
        borderRadius!.circularRadius * 2.0 == width &&
        borderRadius!.circularRadius * 2.0 == height;

    final _borderRadius = (borderRadius ?? BorderRadius.zero);
    final _borderSide = borderSide ?? BorderSide.none;

    if (context.stack.platform == ThemePlatform.cupertino && !isCircle) {
      return RoundedSuperellipseBorderNoPadding(borderRadius: _borderRadius, side: _borderSide);
    } else {
      return RoundedRectangleBorderNoPadding(borderRadius: _borderRadius, side: _borderSide);
    }
  }

  @override
  Widget build(BuildContext context) {
    final animationStyle = this.animationStyle ?? context.stack.defaultAnimation;

    final color = this.color;

    final Color? backgroundColor;
    final Color? foregroundColor;

    if (color is SurfaceColor) {
      backgroundColor = color.background;
    } else {
      backgroundColor = color;
    }

    if (this.foregroundColor != null) {
      foregroundColor = this.foregroundColor!;
    } else if (color is SurfaceColor) {
      foregroundColor = color.foreground;
    } else if (backgroundColor != null) {
      foregroundColor = _computeForegroundColor(backgroundColor);
    } else {
      foregroundColor = null;
    }

    final surfaceColor = SurfaceColor(
      background: backgroundColor ?? Surface.colorOf(context).background,
      foreground: foregroundColor ?? Surface.colorOf(context).foreground,
    );

    Widget child = DefaultForegroundStyle(
      animationStyle: animationStyle,
      color: surfaceColor.foreground,
      child: InheritedSurfaceColor(
        color: surfaceColor,
        child: AnimatedPadding(
          duration: animationStyle.duration!,
          curve: animationStyle.curve!,
          padding: padding ?? EdgeInsets.zero,
          child: this.child ?? const SizedBox.shrink(),
        ),
      ),
    );

    final shape = _resolveShapeBorder(context);

    if (materialIsContainer) {
      child = Material(
        type: MaterialType.transparency,
        clipBehavior: Clip.none,
        shape: shape,
        child: MaterialWithNoInkClip(
          child: child,
        ),
      );
    }

    final decoration = ShapeDecoration(
      color: backgroundColor,
      shape: shape ?? const RoundedRectangleBorder(),
      shadows: shadows,
    );

    var clipBehavior = this.clipBehavior;
    clipBehavior ??= backgroundColor != null || shape != null ? Clip.antiAlias : Clip.none;

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
