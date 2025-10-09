import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:oklch/oklch.dart';

OKLCHColor? lerpOkLch(OKLCHColor? a, OKLCHColor? b, double t) {
  if (b == null) {
    if (a == null) return null;
    return OKLCHColor.fromOKLCH(a.lightness, a.chroma, a.hue, a.alpha * (1.0 - t));
  }

  if (a == null) return OKLCHColor.fromOKLCH(b.lightness, b.chroma, b.hue, b.alpha * t);
  if (t == 0.0) return a;
  if (t == 1.0) return b;

  double hue;
  var aHue = a.hue;
  var bHue = b.hue;

  var diff = bHue - aHue;
  if (diff.abs() > 180.0) {
    if (diff > 0.0) {
      aHue += 360.0;
    } else {
      bHue += 360.0;
    }
  }

  hue = lerpDouble(aHue, bHue, t)! % 360.0;

  return OKLCHColor.fromOKLCH(
    lerpDouble(a.lightness, b.lightness, t)!,
    lerpDouble(a.chroma, b.chroma, t)!,
    hue,
    lerpDouble(a.alpha, b.alpha, t)!,
  );
}

class ShapeDecorationWithLchLerp extends ShapeDecoration {
  ShapeDecorationWithLchLerp({
    required super.shape,
    Color? color,
    OKLCHColor? lchColor,
    super.gradient,
    super.image,
    super.shadows,
  }) : lchColor = lchColor ?? (color != null ? OKLCHColor.fromColor(color) : null),
       super(color: lchColor?.color ?? color);

  final OKLCHColor? lchColor;

  @override
  ShapeDecoration? lerpFrom(Decoration? a, double t) {
    if (a is ShapeDecorationWithLchLerp) return lerp(a, this, t);
    return super.lerpFrom(a, t);
  }

  @override
  ShapeDecoration? lerpTo(Decoration? b, double t) {
    if (b is ShapeDecorationWithLchLerp) return lerp(this, b, t);
    return super.lerpTo(b, t);
  }

  static ShapeDecorationWithLchLerp? lerp(
    ShapeDecorationWithLchLerp? a,
    ShapeDecorationWithLchLerp? b,
    double t,
  ) {
    if (identical(a, b)) return a;

    if (a != null && b != null) {
      if (t == 0.0) return a;
      if (t == 1.0) return b;
    }

    return ShapeDecorationWithLchLerp(
      lchColor: lerpOkLch(a?.lchColor, b?.lchColor, t),
      gradient: Gradient.lerp(a?.gradient, b?.gradient, t),
      image: DecorationImage.lerp(a?.image, b?.image, t),
      shadows: BoxShadow.lerpList(a?.shadows, b?.shadows, t),
      shape: ShapeBorder.lerp(a?.shape, b?.shape, t)!,
    );
  }
}
