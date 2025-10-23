import 'package:flutter/material.dart';
import 'package:stack_ui/src/modules/staggerable/staggering_widget.dart';

class StaggerableContainer extends StatefulWidget {
  const StaggerableContainer({
    super.key,
    required this.child,
    this.delay = const Duration(milliseconds: 150),
    this.initialDelay = Duration.zero,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  final Duration initialDelay;
  final Duration delay;
  final Duration animationDuration;
  final Widget child;

  @override
  State<StaggerableContainer> createState() => StaggerableContainerState();
}

class StaggerableContainerState extends State<StaggerableContainer> with SingleTickerProviderStateMixin {
  late final animationController = AnimationController(vsync: this);
  final children = <StaggeringWidgetState>[];

  int get length => children.length;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(widget.initialDelay);
      if (mounted) animationController.forward();
    });
  }

  int attach(StaggeringWidgetState child) {
    assert(!children.contains(child));
    children.add(child);
    animationController.duration = widget.animationDuration * children.length + widget.delay * (children.length - 1);
    return children.length - 1;
  }

  void detach(StaggeringWidgetState child) {
    assert(children.contains(child));
    children.remove(child);
    animationController.duration = widget.animationDuration * children.length + widget.delay * (children.length - 1);
  }

  Interval intervalFor(int index) {
    final start = widget.delay * index;
    final end = start + widget.animationDuration;

    return Interval(
      start.inMilliseconds / animationController.duration!.inMilliseconds,
      end.inMilliseconds / animationController.duration!.inMilliseconds,
      curve: Curves.linear,
    );
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
