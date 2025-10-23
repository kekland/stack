import 'package:flutter/material.dart';
import 'package:stack_ui/stack_ui.dart';

export 'gesture_region_detectors/default.dart';
export 'gesture_region_detectors/material.dart';

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
  });

  final HitTestBehavior behavior;
  final VoidCallback? onTap;

  final GestureRegionDetectorBuilder detectorBuilder;

  final Widget Function(BuildContext context, Set<WidgetState> states)? builder;

  @override
  State<GestureRegion> createState() => _GestureRegionState();
}

class _GestureRegionState extends State<GestureRegion> {
  final _stopwatch = Stopwatch();
  late Set<WidgetState> _gestureState;
  late Duration _smallAnimationDuration;

  bool get _hasTapCallbacks => widget.onTap != null;

  @override
  void initState() {
    super.initState();
    _gestureState = _hasTapCallbacks ? {} : {WidgetState.disabled};
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _smallAnimationDuration = switch (context.stack.platform) {
      ThemePlatform.material => const Duration(milliseconds: 100),
      ThemePlatform.cupertino => const Duration(milliseconds: 75),
    };
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
      _gestureState = {WidgetState.disabled};
    } else if (_gestureState.contains(WidgetState.disabled)) {
      _gestureState = {};
    }
  }

  void _onTapStart(BuildContext context) {
    if (!mounted) return;

    setState(() => _gestureState = {WidgetState.pressed});
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
    setState(() => _gestureState = _hasTapCallbacks ? {} : {WidgetState.disabled});
  }

  @override
  Widget build(BuildContext context) {
    final isInteractable = _hasTapCallbacks;

    final child = widget.builder?.call(context, _gestureState);

    final onTap = widget.onTap;
    final onTapStart = isInteractable ? () => _onTapStart(context) : null;
    final onTapEnd = isInteractable ? () => _onTapEnd(context) : null;

    return widget.detectorBuilder(
      context,
      widget.behavior,
      child ?? const SizedBox.shrink(),
      onTapStart,
      onTapEnd,
      onTap,
    );
  }
}
