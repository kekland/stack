import 'package:flutter/widgets.dart';

mixin SizedImageProviderMixin<T extends Object> on ImageProvider<T> {
  double? get width;
  double? get height;
  Size? get size => (width != null && height != null) ? Size(width!, height!) : null;
  double? get aspectRatio => size?.aspectRatio;
}
