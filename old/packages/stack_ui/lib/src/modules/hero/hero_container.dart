import 'package:flutter/widgets.dart';
import '../../../stack_ui.dart';

class HeroContainer extends StatefulWidget {
  const HeroContainer({
    super.key,
    required this.child,
  });

  final Widget child;

  static HeroContainerState of(BuildContext context) => maybeOf(context)!;
  static HeroContainerState? maybeOf(BuildContext context) => context.findAncestorStateOfType<HeroContainerState>();

  @override
  State<HeroContainer> createState() => HeroContainerState();
}

class HeroContainerState extends State<HeroContainer> {
  final Map<Object, HeroHandleState> _heroes = {};

  HeroHandleState? getHandleFor(Object tag) => _heroes[tag];

  HeroHandleState? attach(HeroHandleState state) {
    final previousState = _heroes[state.widget.tag];
    _heroes[state.widget.tag] = state;

    return previousState;
  }

  void detachByTag(Object tag) {
    if (_heroes.containsKey(tag)) {
      _heroes.remove(tag);
    }
  }

  void detach(HeroHandleState state) {
    if (_heroes.containsKey(state.widget.tag) && _heroes[state.widget.tag] == state) {
      _heroes.remove(state.widget.tag);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
