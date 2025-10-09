import 'package:flutter/material.dart';
import 'package:stack/stack.dart';

Widget gestureSurfaceMaterialEffect(BuildContext context, GestureSurface surface) {
  return surface.buildSurface(
    context,
    padding: EdgeInsets.zero,
    state: null,
    materialIsContainer: true,
    child: GestureRegion(
      behavior: surface.behavior,
      onTap: surface.onTap,
      detectorBuilder: materialInkWellMnGestureRegionDetectorBuilder(context, surface),
      builder: (context, state) => Padding(
        padding: surface.padding ?? EdgeInsets.zero,
        child: surface.child,
      ),
    ),
  );
}
