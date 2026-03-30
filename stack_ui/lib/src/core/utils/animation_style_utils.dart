import 'package:flutter/widgets.dart';

extension AnimationStyleExtensions on AnimationStyle {
  bool get hasDuration => duration != null && duration! > Duration.zero;
}
