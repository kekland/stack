import 'package:flutter/material.dart';
import 'package:stack_ui/stack_ui.dart';

class PlatformDependentWidget extends StatelessWidget {
  const PlatformDependentWidget({
    super.key,
    required this.materialBuilder,
    required this.cupertinoBuilder,
  });

  final WidgetBuilder materialBuilder;
  final WidgetBuilder cupertinoBuilder;

  @override
  Widget build(BuildContext context) {
    return switch (context.stack.platform) {
      ThemePlatform.material => materialBuilder(context),
      ThemePlatform.cupertino => cupertinoBuilder(context),
    };
  }
}
