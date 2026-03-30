import 'package:flutter/widgets.dart';
import '../../../stack_ui.dart';

class HeroTarget extends StatefulWidget {
  const HeroTarget({
    super.key,
    required this.isActive,
    required this.child,
    this.heroContainer,
  });

  final Hero child;
  final bool isActive;
  final HeroContainerState? heroContainer;

  @override
  State<HeroTarget> createState() => HeroTargetState();
}

class HeroTargetState extends State<HeroTarget> {
  late final HeroContainerState _heroContainerState;
  HeroHandleState? _heroHandleState;

  @override
  void initState() {
    super.initState();

    // Obtain states
    _heroContainerState = widget.heroContainer ?? HeroContainer.of(context);
    _heroHandleState = _heroContainerState.getHandleFor(widget.child.tag);

    // Set initial value
    _heroHandleState?.setActive(widget.isActive, potentiallyStartsFlight: true);
  }

  @override
  void didUpdateWidget(covariant HeroTarget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.child.tag != widget.child.tag) {
      _heroHandleState?.setActive(true);
      _heroHandleState = _heroContainerState.getHandleFor(widget.child.tag);
    }

    if (oldWidget.isActive != widget.isActive) {
      _heroHandleState?.setActive(
        widget.isActive,
        potentiallyStartsFlight: true,
      );
    }
  }

  @override
  void dispose() {
    _heroHandleState?.setActive(true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HeroMode(enabled: widget.isActive, child: widget.child);
  }
}
