
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:stack_ui/src/widgets/flutter/material/material.dart';
import 'package:stack_ui/stack_ui.dart';

enum _InkResponseType {
  overflowing,
  contained,
}

class _OverflowingBorder extends ShapeBorder {
  const _OverflowingBorder({required this.forcedCircle});

  final bool forcedCircle;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    if (forcedCircle || rect.width == rect.height) {
      return Path()..addOval(rect);
    } else {
      return Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4.0)));
    }
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => getInnerPath(rect, textDirection: textDirection);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) {
    return _OverflowingBorder(forcedCircle: forcedCircle);
  }
}

class _InkResponse extends InkResponseWithNoInkClip {
  const _InkResponse({
    required this.surface,
    required this.inkResponseType,
    super.onTap,
    super.onTapDown,
    super.onTapUp,
    super.onTapCancel,
    super.child,
    this.offset = Offset.zero,
  });

  final GestureSurface surface;
  final Offset offset;
  final _InkResponseType inkResponseType;

  bool get forcedCircle => inkResponseType == _InkResponseType.overflowing && offset != Offset.zero;

  @override
  InteractiveInkFeatureFactoryWithNoInkClip get splashFactory => InkSparkleWithNoInkClip.splashFactory;

  @override
  Color? get splashColor {
    final hasBackgroundColor = surface.color != null && surface.color?.a != 0.0;
    final hasForegroundColor = surface.foregroundColor != null && surface.foregroundColor?.a != 0.0;
    final hasBorderSide = surface.borderSide != null;

    if (hasBackgroundColor) {
      return super.splashColor;
    } else if (hasBorderSide) {
      return surface.borderSide?.color.withMultipliedOpacity(0.2);
    } else if (hasForegroundColor) {
      return surface.foregroundColor?.withMultipliedOpacity(0.2);
    }

    return super.splashColor;
  }

  @override
  Color? get highlightColor => splashColor?.withMultipliedOpacity(0.15 * surface.effectIntensity);

  @override
  Color? get hoverColor => splashColor?.withMultipliedOpacity(0.1 * surface.effectIntensity);

  @override
  BoxShape get highlightShape => BoxShape.rectangle;

  @override
  ShapeBorder? get customBorder => switch (inkResponseType) {
    _InkResponseType.overflowing => _OverflowingBorder(forcedCircle: forcedCircle),
    _InkResponseType.contained => null,
  };

  @override
  bool get containedInkWell => true;

  @override
  RectCallback? getRectCallback(RenderBox referenceBox) {
    if (inkResponseType == _InkResponseType.overflowing) {
      return () {
        final size = referenceBox.size;
        final smallestSide = min(size.width, size.height);

        if (forcedCircle || size.width == size.height) {
          return Rect.fromCenter(
            center: size.center(Offset.zero) + offset,
            width: smallestSide,
            height: smallestSide,
          );
        } else {
          return (Offset.zero & size).inflate(2.0);
        }
      };
    } else {
      return () {
        final size = referenceBox.size;
        return (Offset.zero & size).shift(offset);
      };
    }
  }
}

GestureRegionDetectorBuilder materialInkWellMnGestureRegionDetectorBuilder(
  BuildContext context,
  GestureSurface surface,
) {
  return (
    BuildContext context,
    HitTestBehavior behavior,
    Widget child,
    VoidCallback? onTapStart,
    VoidCallback? onTapEnd,
    VoidCallback? onTap,
  ) {
    final enabled = onTap != null || onTapStart != null || onTapEnd != null;

    final _InkResponseType inkResponseType;
    if (surface.isExpanded || surface.color != null || surface.borderSide != null || surface.borderRadius != null) {
      inkResponseType = _InkResponseType.contained;
    } else {
      inkResponseType = _InkResponseType.overflowing;
    }

    return _InkResponse(
      surface: surface,
      inkResponseType: inkResponseType,
      onTap: enabled ? onTap : null,
      onTapDown: enabled ? (_) => onTapStart?.call() : null,
      onTapCancel: enabled ? onTapEnd : null,
      onTapUp: enabled ? (_) => onTapEnd?.call() : null,
      offset: surface.materialInkResponseOffset ?? Offset.zero,
      child: child,
    );
  };
}