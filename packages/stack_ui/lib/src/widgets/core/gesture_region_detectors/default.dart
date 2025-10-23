import 'package:flutter/widgets.dart';

Widget defaultGestureRegionDetectorBuilder(
  BuildContext context,
  HitTestBehavior behavior,
  Widget child,
  VoidCallback? onTapStart,
  VoidCallback? onTapEnd,
  VoidCallback? onTap,
) {
  return MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      behavior: behavior,
      onTap: onTap,
      onTapDown: onTap != null ? (_) => onTapStart?.call() : null,
      onTapUp: onTap != null ? (_) => onTapEnd?.call() : null,
      onTapCancel: onTapEnd,
      child: child,
    ),
  );
}
