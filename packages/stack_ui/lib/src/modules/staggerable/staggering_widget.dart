import 'package:flutter/material.dart';
import 'package:stack_ui/stack_ui.dart';

class StaggeringWidget extends StatefulWidget with AwareUnwrappable {
  const StaggeringWidget({
    super.key,
    required this.child,
  });

  @override
  final Widget child;

  Widget animationBuilder(BuildContext context, double t, Widget child) {
    return Opacity(opacity: t, child: child);
  }

  @override
  State<StaggeringWidget> createState() => StaggeringWidgetState();
}

class StaggeringWidgetState extends State<StaggeringWidget> {
  StaggerableContainerState? container;
  int? index;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final container = context.findAncestorStateOfType<StaggerableContainerState>();
    if (container != this.container) {
      this.container?.detach(this);
      this.container = container;
      index = this.container?.attach(this);
    }
  }

  @override
  void dispose() {
    container?.detach(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (container == null || index == null) return widget.child;

    return AnimatedBuilder(
      animation: container!.animationController,
      child: widget.child,
      builder: (context, child) {
        final interval = container!.intervalFor(index!);
        final value = interval.transform(container!.animationController.value);
        return widget.animationBuilder(context, value, child!);
      },
    );
  }
}
