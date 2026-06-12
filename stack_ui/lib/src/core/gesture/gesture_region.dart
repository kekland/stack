import 'package:flutter/gestures.dart';

import '../_.dart';

import 'package:flutter/widgets.dart';

typedef GestureRegionDetectorBuilder =
    Widget Function(
      BuildContext context,
      HitTestBehavior behavior,
      Set<PointerDeviceKind>? supportedDevices,
      Widget child,
      VoidCallback? onTapStart,
      VoidCallback? onTapEnd,
      VoidCallback? onTap,
      GestureDragStartCallback? onHorizontalDragStart,
      GestureDragUpdateCallback? onHorizontalDragUpdate,
      GestureDragEndCallback? onHorizontalDragEnd,
      GestureDragCancelCallback? onHorizontalDragCancel,
      GestureDragDownCallback? onHorizontalDragDown,
      GestureDragStartCallback? onVerticalDragStart,
      GestureDragUpdateCallback? onVerticalDragUpdate,
      GestureDragEndCallback? onVerticalDragEnd,
      GestureDragCancelCallback? onVerticalDragCancel,
      GestureDragDownCallback? onVerticalDragDown,
      GestureDragStartCallback? onPanStart,
      GestureDragUpdateCallback? onPanUpdate,
      GestureDragEndCallback? onPanEnd,
      GestureDragCancelCallback? onPanCancel,
      GestureDragDownCallback? onPanDown,
    );

class GestureRegion extends StatefulWidget {
  const GestureRegion({
    super.key,
    this.onTap,
    this.detectorBuilder = defaultGestureRegionDetectorBuilder,
    this.builder,
    this.behavior = HitTestBehavior.opaque,
    this.cursor = SystemMouseCursors.click,
    this.supportedDevices,

    this.onHorizontalDragDown,
    this.onHorizontalDragStart,
    this.onHorizontalDragUpdate,
    this.onHorizontalDragEnd,
    this.onHorizontalDragCancel,

    this.onVerticalDragDown,
    this.onVerticalDragStart,
    this.onVerticalDragUpdate,
    this.onVerticalDragEnd,
    this.onVerticalDragCancel,

    this.onPanDown,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.onPanCancel,
  });

  GestureRegion.fromSurface({
    Key? key,
    required GestureSurface surface,
    GestureRegionDetectorBuilder detectorBuilder = defaultGestureRegionDetectorBuilder,
    Widget Function(BuildContext context, Set<WidgetState> states)? builder,
  }) : this(
         key: key,
         onTap: surface.onTap,
         behavior: surface.behavior,
         cursor: surface.cursor,
         supportedDevices: surface.supportedDevices,
         onHorizontalDragDown: surface.onHorizontalDragDown,
         onHorizontalDragStart: surface.onHorizontalDragStart,
         onHorizontalDragUpdate: surface.onHorizontalDragUpdate,
         onHorizontalDragEnd: surface.onHorizontalDragEnd,
         onHorizontalDragCancel: surface.onHorizontalDragCancel,
         onVerticalDragDown: surface.onVerticalDragDown,
         onVerticalDragStart: surface.onVerticalDragStart,
         onVerticalDragUpdate: surface.onVerticalDragUpdate,
         onVerticalDragEnd: surface.onVerticalDragEnd,
         onVerticalDragCancel: surface.onVerticalDragCancel,
         onPanDown: surface.onPanDown,
         onPanStart: surface.onPanStart,
         onPanUpdate: surface.onPanUpdate,
         onPanEnd: surface.onPanEnd,
         onPanCancel: surface.onPanCancel,
         detectorBuilder: detectorBuilder,
         builder: builder,
       );

  final HitTestBehavior behavior;
  final GestureRegionDetectorBuilder detectorBuilder;
  final Widget Function(BuildContext context, Set<WidgetState> states)? builder;
  final MouseCursor cursor;
  final Set<PointerDeviceKind>? supportedDevices;

  final VoidCallback? onTap;
  
  final GestureDragStartCallback? onHorizontalDragStart;
  final GestureDragUpdateCallback? onHorizontalDragUpdate;
  final GestureDragEndCallback? onHorizontalDragEnd;
  final GestureDragCancelCallback? onHorizontalDragCancel;
  final GestureDragDownCallback? onHorizontalDragDown;

  final GestureDragStartCallback? onVerticalDragStart;
  final GestureDragUpdateCallback? onVerticalDragUpdate;
  final GestureDragEndCallback? onVerticalDragEnd;
  final GestureDragCancelCallback? onVerticalDragCancel;
  final GestureDragDownCallback? onVerticalDragDown;

  final GestureDragStartCallback? onPanStart;
  final GestureDragUpdateCallback? onPanUpdate;
  final GestureDragEndCallback? onPanEnd;
  final GestureDragCancelCallback? onPanCancel;
  final GestureDragDownCallback? onPanDown;

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

  bool _resetMouse = false;
  void _onMouseEnter(PointerEnterEvent e) {
    if (!mounted) return;
    if (!_hasTapCallbacks) return;
    if (e.down) return;

    setState(() => _hoverState = {WidgetState.hovered});
    _resetMouse = true;
  }

  void _onMouseExit(_) {
    if (!mounted) return;
    if (!_resetMouse) return;
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
      child: Listener(
        onPointerDown: isInteractable ? (_) => _onTapStart(context) : null,
        onPointerUp: isInteractable ? (_) => _onTapEnd(context) : null,
        child: widget.detectorBuilder(
          context,
          widget.behavior,
          widget.supportedDevices,
          child ?? const SizedBox.shrink(),
          null,
          null,
          onTap,
          widget.onHorizontalDragStart,
          widget.onHorizontalDragUpdate,
          widget.onHorizontalDragEnd,
          widget.onHorizontalDragCancel,
          widget.onHorizontalDragDown,
          widget.onVerticalDragStart,
          widget.onVerticalDragUpdate,
          widget.onVerticalDragEnd,
          widget.onVerticalDragCancel,
          widget.onVerticalDragDown,
          widget.onPanStart,
          widget.onPanUpdate,
          widget.onPanEnd,
          widget.onPanCancel,
          widget.onPanDown,
        ),
      ),
    );
  }
}
