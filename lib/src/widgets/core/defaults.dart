import 'package:flutter/widgets.dart';
import 'package:stack/stack.dart';

class StackDefaults extends InheritedWidget {
  const StackDefaults({
    super.key,
    required this.animation,
    required this.platform,
    required super.child,
  });

  static StackDefaults of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<StackDefaults>()!;
  }

  final AnimationStyle animation;
  static AnimationStyle animationOf(BuildContext context) => of(context).animation;

  final ThemePlatform platform;
  static ThemePlatform platformOf(BuildContext context) => of(context).platform;

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
}

extension StackBuildContextExtension on BuildContext {
  StackDefaultsContext get stack => StackDefaultsContext._(this);
}
