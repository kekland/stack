import '../_.dart';

import 'package:flutter/widgets.dart';

typedef GestureRegionDetectorBuilder =
    Widget Function(
      BuildContext context,
      HitTestBehavior behavior,
      Widget child,
      VoidCallback? onTapStart,
      VoidCallback? onTapEnd,
      VoidCallback? onTap,
    );

class GestureRegion extends StatefulWidget {
  const GestureRegion({
    super.key,
    this.onTap,
    this.detectorBuilder = defaultGestureRegionDetectorBuilder,
    this.builder,
    this.behavior = HitTestBehavior.opaque,
    this.cursor = SystemMouseCursors.click,
  });

  final HitTestBehavior behavior;
  final VoidCallback? onTap;
  final GestureRegionDetectorBuilder detectorBuilder;
  final Widget Function(BuildContext context, Set<WidgetState> states)? builder;
  final MouseCursor cursor;

  @override
  State<GestureRegion> createState() => _GestureRegionState();
}

class _GestureRegionState extends State<GestureRegion> {
  final _stopwatch = Stopwatch();
  late Set<WidgetState> _gestureDetectorState;
  late Set<WidgetState> _hoverState;
  late Duration _smallAnimationDuration;
  _GestureRegionState? _parent;

  bool get _hasTapCallbacks => widget.onTap != null;

  @override
  void initState() {
    super.initState();
    _gestureDetectorState = _hasTapCallbacks ? {} : {WidgetState.disabled};
    _hoverState = {};
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _smallAnimationDuration = const Duration(milliseconds: 100);
    _parent = context.findAncestorStateOfType<_GestureRegionState>();
  }

  @override
  void didUpdateWidget(covariant GestureRegion oldWidget) {
    super.didUpdateWidget(oldWidget);
    _onOnTapChanged();
  }

  @override
  void dispose() {
    _stopwatch.stop();
    _stopwatch.reset();
    super.dispose();
  }

  void _onOnTapChanged() {
    if (!_hasTapCallbacks) {
      _gestureDetectorState = {WidgetState.disabled};
    } else if (_gestureDetectorState.contains(WidgetState.disabled)) {
      _gestureDetectorState = {};
    }
  }

  void _onTapStart(BuildContext context) {
    if (!mounted) return;

    setState(() => _gestureDetectorState = {WidgetState.pressed});
    _stopwatch.start();
  }

  Future<void> _onTapEnd(BuildContext context) async {
    if (!mounted) return;

    _stopwatch.stop();

    final duration = _stopwatch.elapsed;
    final durationToWaitFor = _smallAnimationDuration - duration;

    _stopwatch.reset();

    if (!durationToWaitFor.isNegative) {
      await Future<void>.delayed(durationToWaitFor);
    }

    if (!mounted) return;
    setState(() => _gestureDetectorState = _hasTapCallbacks ? {} : {WidgetState.disabled});
  }

  void _onMouseEnter(_) {
    if (!mounted) return;
    if (!_hasTapCallbacks) return;
    setState(() => _hoverState = {WidgetState.hovered});
  }

  void _onMouseExit(_) {
    if (!mounted) return;
    setState(() => _hoverState = {});
  }

  @override
  Widget build(BuildContext context) {
    final isInteractable = _hasTapCallbacks;

    final child = widget.builder?.call(context, {..._hoverState, ..._gestureDetectorState});

    final onTap = widget.onTap;
    final onTapStart = isInteractable ? () => _onTapStart(context) : null;
    final onTapEnd = isInteractable ? () => _onTapEnd(context) : null;

    return MouseRegion(
      hitTestBehavior: widget.behavior,
      onEnter: _onMouseEnter,
      onExit: _onMouseExit,
      cursor: widget.cursor,
      child: widget.detectorBuilder(
        context,
        widget.behavior,
        child ?? const SizedBox.shrink(),
        onTapStart,
        onTapEnd,
        onTap,
      ),
    );
  }
}
