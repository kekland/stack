import 'package:flutter/material.dart';
import '../../../stack_ui.dart';

class HeroHandle extends StatefulWidget {
  const HeroHandle({
    super.key,
    required this.tag,
    required this.child,
    this.createRectTween,
    this.flightShuttleBuilder,
    this.placeholderBuilder,
    this.transitionOnUserGestures = false,
  });

  final Object tag;
  final CreateRectTween? createRectTween;
  final HeroFlightShuttleBuilder? flightShuttleBuilder;
  final HeroPlaceholderBuilder? placeholderBuilder;
  final bool transitionOnUserGestures;

  final Widget child;

  @override
  State<HeroHandle> createState() => HeroHandleState();
}

class HeroHandleState extends State<HeroHandle> {
  late final HeroContainerState _heroContainerState;
  dynamic _heroState;
  var _isActive = true;

  @override
  void initState() {
    super.initState();

    _heroContainerState = HeroContainer.of(context);

    final oldState = _heroContainerState.attach(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (oldState != null && oldState._isActive) {
        _isActive = false;
        setActive(oldState._isActive, potentiallyStartsFlight: false);
      }
    });
  }

  @override
  void didUpdateWidget(covariant HeroHandle oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.tag != widget.tag) {
      _heroContainerState.detachByTag(oldWidget.tag);
      _heroContainerState.attach(this);
    }
  }

  void setActive(bool isActive, {bool potentiallyStartsFlight = false}) {
    if (isActive == _isActive) return;
    _isActive = isActive;

    if (potentiallyStartsFlight) {
      _changeHeroState();
    }
  }

  void _changeHeroState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isActive && mounted) {
        _heroState?.startFlight(shouldIncludedChildInPlaceholder: true);
      } else {
        _heroState?.endFlight(keepPlaceholder: false);
      }
    });
  }

  @override
  void dispose() {
    _heroContainerState.detach(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_heroState == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.visitChildElements((element) {
          if (element is! StatefulElement) return;
          _heroState = (element.state as dynamic);
        });
      });
    }

    return Hero(
      tag: widget.tag,
      createRectTween: widget.createRectTween,
      flightShuttleBuilder: widget.flightShuttleBuilder,
      placeholderBuilder: widget.placeholderBuilder,
      transitionOnUserGestures: widget.transitionOnUserGestures,
      child: widget.child,
    );
  }
}
