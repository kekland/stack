import 'package:flutter/widgets.dart';
import 'package:stack/stack.dart';

class StackDefaults extends InheritedWidget {
  const StackDefaults({
    super.key,
    required this.defaultEffectAnimation,
    required this.defaultSpatialAnimation,
    required this.platform,
    required this.backgroundColor,
    required this.defaultDisplayColor,
    required this.defaultAccentColor,
    required this.brightness,
    required super.child,
  });

  static StackDefaults of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<StackDefaults>()!;
  }

  final AnimationStyle defaultEffectAnimation;
  static AnimationStyle defaultEffectAnimationOf(BuildContext context) => of(context).defaultEffectAnimation;

  final AnimationStyle defaultSpatialAnimation;
  static AnimationStyle defaultSpatialAnimationOf(BuildContext context) => of(context).defaultSpatialAnimation;

  final ThemePlatform platform;
  static ThemePlatform platformOf(BuildContext context) => of(context).platform;

  final Color backgroundColor;
  static Color backgroundColorOf(BuildContext context) => of(context).backgroundColor;

  final Color defaultDisplayColor;
  static Color defaultDisplayColorOf(BuildContext context) => of(context).defaultDisplayColor;

  final Color defaultAccentColor;
  static Color defaultAccentColorOf(BuildContext context) => of(context).defaultAccentColor;

  final Brightness brightness;
  static Brightness brightnessOf(BuildContext context) => of(context).brightness;

  @override
  bool updateShouldNotify(StackDefaults oldWidget) {
    return defaultEffectAnimation != oldWidget.defaultEffectAnimation || platform != oldWidget.platform;
  }
}

class StackDefaultsContext {
  StackDefaultsContext._(this.context);

  final BuildContext context;

  AnimationStyle get defaultEffectAnimation => StackDefaults.defaultEffectAnimationOf(context);
  AnimationStyle get defaultSpatialAnimation => StackDefaults.defaultSpatialAnimationOf(context);
  ThemePlatform get platform => StackDefaults.platformOf(context);
  Color get backgroundColor => StackDefaults.backgroundColorOf(context);
  Color get defaultDisplayColor => StackDefaults.defaultDisplayColorOf(context);
  Color get defaultAccentColor => StackDefaults.defaultAccentColorOf(context);
  Brightness get brightness => StackDefaults.brightnessOf(context);
}

extension StackBuildContextExtension on BuildContext {
  StackDefaultsContext get stack => StackDefaultsContext._(this);
}
