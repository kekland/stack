import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stack/stack.dart';

class ActivityIndicator extends StatelessWidget {
  const ActivityIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    var color = DefaultTextStyle.of(context).style.color;
    if (color != null) {
      final brightness = color.computeLuminance() > 0.5 ? Brightness.dark : Brightness.light;
      color = brightness == Brightness.dark ? Colors.white : Colors.black;
    }

    return SizedBox.square(
      dimension: 20.0,
      child: PlatformDependentWidget(
        materialBuilder: (_) => CircularProgressIndicator(
          strokeWidth: 2.0,
          color: color ?? context.stack.defaultAccentColor,
        ),
        cupertinoBuilder: (_) => CupertinoActivityIndicator(
          color: color,
        ),
      ),
    );
  }
}
