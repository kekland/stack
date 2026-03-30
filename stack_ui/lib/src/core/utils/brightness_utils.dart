import 'package:flutter/foundation.dart';

extension BrightnessExtensions on Brightness {
  Brightness get inverse => this == Brightness.light ? Brightness.dark : Brightness.light;
}
