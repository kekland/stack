import 'package:flutter/material.dart';

class CheckerboardWidget extends StatelessWidget {
  const CheckerboardWidget({
    super.key,
    this.color1,
    this.color2,
    this.size = 8.0,
  });

  final Color? color1;
  final Color? color2;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CheckerboardPainter(color1: color1, color2: color2, size: size),
      child: Container(),
    );
  }
}

class _CheckerboardPainter extends CustomPainter {
  _CheckerboardPainter({required this.color1, required this.color2, required this.size});

  final Color? color1;
  final Color? color2;
  final double size;

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()..color = color1 ?? Colors.white;
    final paint2 = Paint()..color = color2 ?? Colors.black;

    for (var y = 0.0; y < size.height; y += this.size) {
      for (var x = 0.0; x < size.width; x += this.size) {
        final paint = ((x / this.size).floor() + (y / this.size).floor()) % 2 == 0 ? paint1 : paint2;
        canvas.drawRect(Rect.fromLTWH(x, y, this.size, this.size), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_CheckerboardPainter oldDelegate) =>
      oldDelegate.color1 != color1 || oldDelegate.color2 != color2 || oldDelegate.size != size;
}
