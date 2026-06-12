import '../../_.dart';

import 'package:flutter/material.dart';

Widget gestureSurfaceMaterialEffect(BuildContext context, GestureSurface surface) {
  return surface.buildSurface(
    context,
    padding: EdgeInsets.zero,
    state: null,
    materialIsContainer: true,
    child: GestureRegion.fromSurface(
      surface: surface,
      detectorBuilder: materialInkWellMnGestureRegionDetectorBuilder(context, surface),
      builder: (context, state) => Padding(
        padding: surface.padding ?? EdgeInsets.zero,
        child: surface.resolveChild(context, state),
      ),
    ),
  );
}
