import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:stack/stack.dart';
import 'package:stack_ui/stack_ui.dart';
import 'package:vector_math/vector_math_64.dart';

Vector3? _lerpVector3(Vector3? a, Vector3? b, double t) {
  if (a == null && b == null) return null;
  if (a == null) return b;
  if (b == null) return a;

  final x = lerpDouble(a.x, b.x, t)!;
  final y = lerpDouble(a.y, b.y, t)!;
  final z = lerpDouble(a.z, b.z, t)!;

  return Vector3(x, y, z);
}

Quaternion? _slerpQuaternion(Quaternion? a, Quaternion? b, double t) {
  if (a == null && b == null) return null;
  if (a == null) return b;
  if (b == null) return a;

  final cosHalfTheta = a.w * b.w + a.x * b.x + a.y * b.y + a.z * b.z;
  if (cosHalfTheta.abs() >= 1.0) {
    return a;
  }

  final halfTheta = acos(cosHalfTheta);
  final sinHalfTheta = sqrt(1.0 - cosHalfTheta * cosHalfTheta);

  if (sinHalfTheta.abs() < Tolerance.defaultTolerance.distance) {
    return Quaternion(
      (a.x * 0.5 + b.x * 0.5),
      (a.y * 0.5 + b.y * 0.5),
      (a.z * 0.5 + b.z * 0.5),
      (a.w * 0.5 + b.w * 0.5),
    );
  } else {
    final ratioA = sin((1 - t) * halfTheta) / sinHalfTheta;
    final ratioB = sin(t * halfTheta) / sinHalfTheta;

    return Quaternion(
      (a.x * ratioA + b.x * ratioB),
      (a.y * ratioA + b.y * ratioB),
      (a.z * ratioA + b.z * ratioB),
      (a.w * ratioA + b.w * ratioB),
    );
  }
}

class StAnimatedTransform extends HookWidget {
  const StAnimatedTransform({
    super.key,
    this.animationStyle,
    this.rotationAnimationStyle,
    this.translationAnimationStyle,
    this.scaleAnimationStyle,
    required this.transform,
    this.child,
    this.alignment = Alignment.center,
  });

  final AnimationStyle? animationStyle;
  final AnimationStyle? rotationAnimationStyle;
  final AnimationStyle? translationAnimationStyle;
  final AnimationStyle? scaleAnimationStyle;
  final Alignment alignment;
  final Matrix4 transform;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final rotationAS = rotationAnimationStyle ?? animationStyle ?? context.stack.defaultEffectAnimation;
    final translationAS = translationAnimationStyle ?? animationStyle ?? context.stack.defaultEffectAnimation;
    final scaleAS = scaleAnimationStyle ?? animationStyle ?? context.stack.defaultEffectAnimation;

    final _translation = Vector3.zero();
    final _rotation = Quaternion.identity();
    final _scale = Vector3.zero();
    transform.decompose(_translation, _rotation, _scale);

    final translation = useImplicitAnimation(_translation, animationStyle: translationAS, lerp: _lerpVector3);
    final rotation = useImplicitAnimation(_rotation, animationStyle: rotationAS, lerp: _slerpQuaternion);
    final scale = useImplicitAnimation(_scale, animationStyle: scaleAS, lerp: _lerpVector3);
    final _transform = Matrix4.compose(translation, rotation, scale);

    final alignment = useImplicitAnimation(
      this.alignment,
      animationStyle: animationStyle ?? context.stack.defaultEffectAnimation,
      lerp: Alignment.lerp,
    );

    return Transform(
      transform: _transform,
      alignment: alignment,
      child: child,
    );
  }
}
