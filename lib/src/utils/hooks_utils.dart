import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

HeroController useHeroController() {
  final controller = useMemoized(() => HeroController());
  useEffect(() => controller.dispose, [controller]);
  return controller;
}
