import 'package:ffi/ffi.dart';
import 'package:flutter/widgets.dart';

import 'package:stack_ffi/macos.dart' as macos;
import 'package:stack_ffi/darwin.dart' as darwin;

extension NSViewUtils on macos.NSView {
  void setFrameRect(Rect rect) {
    withZoneArena(() {
      Rect _rect = rect;
      if (superview != null) {
        final superviewSize = superview!.frame.size;
        _rect = Rect.fromLTWH(
          rect.left,
          superviewSize.height - rect.top - rect.height,
          rect.width,
          rect.height,
        );
      }


      frame = darwin.Structs.CGRect(
        _rect.left,
        _rect.top,
        _rect.width,
        _rect.height,
      );
    });
  }
}
