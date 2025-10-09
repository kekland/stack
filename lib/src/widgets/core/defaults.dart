import 'package:flutter/widgets.dart';
import 'package:stack/stack.dart';

class StackDefaults extends InheritedWidget {
  const StackDefaults({
    super.key,
    required this.animation,
    required this.platform,
    required this.backgroundColor,
    required this.defaultDisplayColor,
    required this.brightness,
    required super.child,
  });

  static StackDefaults of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<StackDefaults>()!;
  }

  final AnimationStyle animation;
  static AnimationStyle animationOf(BuildContext context) => of(context).animation;

  final ThemePlatform platform;
  static ThemePlatform platformOf(BuildContext context) => of(context).platform;

  final Color backgroundColor;
  static Color backgroundColorOf(BuildContext context) => of(context).backgroundColor;
  
  final Color defaultDisplayColor;
  static Color defaultDisplayColorOf(BuildContext context) => of(context).defaultDisplayColor;

  final Brightness brightness;
  static Brightness brightnessOf(BuildContext context) => of(context).brightness;

  @override
  bool updateShouldNotify(StackDefaults oldWidget) {
    return animation != oldWidget.animation || platform != oldWidget.platform;
  }
}

class StackDefaultsContext {
  StackDefaultsContext._(this.context);

  final BuildContext context;

  AnimationStyle get defaultAnimation => StackDefaults.animationOf(context);
  ThemePlatform get platform => StackDefaults.platformOf(context);
  Color get backgroundColor => StackDefaults.backgroundColorOf(context);
  Color get defaultDisplayColor => StackDefaults.defaultDisplayColorOf(context);
  Brightness get brightness => StackDefaults.brightnessOf(context);
}

extension StackBuildContextExtension on BuildContext {
  StackDefaultsContext get stack => StackDefaultsContext._(this);
}
