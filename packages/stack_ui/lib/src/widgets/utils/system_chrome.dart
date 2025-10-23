import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stack_ui/stack_ui.dart';

class BottomSystemChrome extends StatelessWidget {
  const BottomSystemChrome({super.key, required this.color, required this.brightness, required this.child});

  final Color color;
  final Brightness brightness;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: color,
        systemNavigationBarIconBrightness: brightness == Brightness.light ? Brightness.dark : Brightness.light,
        systemNavigationBarDividerColor: color.withMultipliedOpacity(0.0),
        systemStatusBarContrastEnforced: false,
        systemNavigationBarContrastEnforced: false,
      ),
      child: child,
    );
  }
}
