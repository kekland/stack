import 'package:flutter/widgets.dart';

class AugmentedTextStyle extends TextStyle {
  AugmentedTextStyle(TextStyle base, {super.package})
    : super(
        color: null,
        inherit: true,
        background: base.background,
        backgroundColor: base.backgroundColor,
        debugLabel: base.debugLabel,
        decoration: base.decoration,
        decorationColor: base.decorationColor,
        decorationStyle: base.decorationStyle,
        decorationThickness: base.decorationThickness,
        fontFamily: base.fontFamily,
        fontFamilyFallback: base.fontFamilyFallback,
        fontFeatures: base.fontFeatures,
        fontSize: base.fontSize,
        fontStyle: base.fontStyle,
        fontVariations: base.fontVariations,
        fontWeight: base.fontWeight,
        foreground: base.foreground,
        height: base.height,
        leadingDistribution: base.leadingDistribution,
        letterSpacing: base.letterSpacing,
        locale: base.locale,
        overflow: base.overflow,
        shadows: base.shadows,
        textBaseline: base.textBaseline,
        wordSpacing: base.wordSpacing,
      );
}
