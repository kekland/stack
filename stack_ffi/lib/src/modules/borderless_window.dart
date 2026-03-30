import 'dart:io';

import 'package:stack_ffi/macos.dart' as macos;

void makeWindowBorderless() {
  if (Platform.isMacOS) _macosSetWindowBorderless();
}

void _macosSetWindowBorderless() {
  final application = macos.NSApplication.getSharedApplication();
  final window = application.flutterWindow;

  window.styleMask |= macos.NSWindowStyleMask.NSWindowStyleMaskFullSizeContentView;
  window.titlebarAppearsTransparent = true;
  window.titleVisibility = macos.NSWindowTitleVisibility.NSWindowTitleHidden;
}
