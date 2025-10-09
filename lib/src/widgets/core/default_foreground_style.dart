import 'package:flutter/material.dart';
import 'package:stack/src/widgets/core/defaults.dart';
import 'package:stack/stack.dart';

class DefaultForegroundStyle extends StatelessWidget {
  const DefaultForegroundStyle({
    super.key,
    this.animationStyle,
    this.textStyle,
    this.color,
    this.maxLines,
    this.overflow,
    this.iconSize,
    this.iconFill,
    this.textAlign,
    required this.child,
  });

  final AnimationStyle? animationStyle;
  final TextStyle? textStyle;
  final Color? color;
  final double? iconSize;
  final double? iconFill;
  final int? maxLines;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final animationStyle = this.animationStyle ?? context.stack.defaultAnimation;
    final color = this.color ?? textStyle?.color;

    if (animationStyle.duration == Duration.zero) {
      return DefaultTextStyle.merge(
        style: TextStyle(color: color).merge(textStyle),
        maxLines: maxLines,
        textAlign: textAlign,
        overflow: overflow ?? TextOverflow.visible,
        child: IconTheme.merge(
          data: IconThemeData(
            color: color,
            fill: iconFill,
            size: iconSize,
          ),
          child: child,
        ),
      );
    }

    final parentTextStyle = DefaultTextStyle.of(context);
    final parentIconTheme = IconTheme.of(context);

    return AnimatedDefaultTextStyle(
      duration: animationStyle.duration!,
      curve: animationStyle.curve!,
      maxLines: maxLines ?? parentTextStyle.maxLines,
      overflow: overflow ?? parentTextStyle.overflow,
      textAlign: textAlign ?? parentTextStyle.textAlign,
      style: parentTextStyle.style.merge(TextStyle(color: color).merge(textStyle)),
      child: AnimatedIconTheme(
        duration: animationStyle.duration!,
        curve: animationStyle.curve!,
        data: IconThemeData(
          color: color ?? parentIconTheme.color,
          fill: iconFill ?? parentIconTheme.fill,
          size: iconSize ?? parentIconTheme.size,
          opticalSize: parentIconTheme.opticalSize,
          weight: parentIconTheme.weight,
          grade: parentIconTheme.grade,
          opacity: parentIconTheme.opacity,
          applyTextScaling: parentIconTheme.applyTextScaling,
          shadows: parentIconTheme.shadows,
        ),
        child: child,
      ),
    );
  }
}
