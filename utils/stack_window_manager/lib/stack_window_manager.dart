import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:stack_ui/stack_ui.dart';
import 'package:stack_window_manager/activities.dart';

/// A widget that hosts the Overlay for windows.
class WindowRoot extends StatefulWidget {
  const WindowRoot({super.key, required this.child});

  final Widget child;

  @override
  State<WindowRoot> createState() => WindowRootState();
}

class WindowRootState extends State<WindowRoot> {
  final _overlayKey = GlobalKey<OverlayState>();
  OverlayState get overlay => _overlayKey.currentState!;

  @override
  Widget build(BuildContext context) {
    return Overlay(
      key: _overlayKey,
      initialEntries: [
        OverlayEntry(builder: (context) => widget.child, canSizeOverlay: true),
      ],
    );
  }
}

class WindowEntry extends OverlayEntry {
  WindowEntry({
    required super.builder,
    this.anchor,
    this.isModal = false,
    this.animationStyle = .noAnimation,
    this.transitionBuilder = _defaultWindowTransitionBuilder,
  });

  static WindowAnchor createAnchorForContext(
    BuildContext context, {
    EdgeInsets padding = .zero,
  }) {
    final overlay = context.findAncestorStateOfType<WindowRootState>()!;
    final renderBox = context.findRenderObject() as RenderBox;

    final rect = MatrixUtils.transformRect(
      renderBox.getTransformTo(overlay.context.findRenderObject()),
      (Offset.zero & renderBox.size),
    );

    return WindowAnchor(rect: padding.inflateRect(rect));
  }

  factory WindowEntry.withContextAnchor(
    BuildContext context, {
    required WidgetBuilder builder,
    AnimationStyle animationStyle = AnimationStyle.noAnimation,
    WindowTransitionBuilder transitionBuilder = _defaultWindowTransitionBuilder,
  }) => WindowEntry(
    builder: builder,
    anchor: createAnchorForContext(context),
    animationStyle: animationStyle,
    transitionBuilder: transitionBuilder,
  );

  final AnimationStyle animationStyle;
  final WindowAnchor? anchor;
  final bool isModal;
  final WindowTransitionBuilder transitionBuilder;

  var _isActive = false;
  bool get isActive => _isActive;
  bool get isRemoved => !_isActive;

  final _removedNotifier = ChangeNotifier();

  void addRemovedListener(VoidCallback listener) => _removedNotifier.addListener(listener);
  void removeRemovedListener(VoidCallback listener) => _removedNotifier.removeListener(listener);

  @override
  WidgetBuilder get builder {
    return (context) => WindowWidget(
      entry: this,
      builder: super.builder,
      transitionBuilder: transitionBuilder,
    );
  }

  void insert(BuildContext context) {
    if (_isActive) return;
    final root = context.findAncestorStateOfType<WindowRootState>()!;
    root.overlay.insert(this);
    _isActive = true;
  }

  @override
  void remove() {
    if (!_isActive) return;
    super.remove();
    _isActive = false;

    // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
    _removedNotifier.notifyListeners();
  }

  @override
  void dispose() {
    if (_isActive) remove();
    _removedNotifier.dispose();
    super.dispose();
  }
}

typedef WindowTransitionBuilder = Widget Function(BuildContext context, Animation<double> animation, Widget child);

Widget _defaultWindowTransitionBuilder(
  BuildContext context,
  Animation<double> animation,
  Widget child,
) {
  return FadeTransition(opacity: animation, child: child);
}

class WindowWidget extends StatefulWidget {
  const WindowWidget({
    super.key,
    required this.entry,
    required this.builder,
    this.transitionBuilder = _defaultWindowTransitionBuilder,
  });

  final WindowEntry entry;
  final WidgetBuilder builder;
  final WindowTransitionBuilder transitionBuilder;

  @override
  State<WindowWidget> createState() => WindowWidgetState();
}

class WindowWidgetState extends State<WindowWidget> with SingleTickerProviderStateMixin {
  late final _animationController = AnimationController(
    vsync: this,
    duration: animationStyle.duration,
  );
  late final _animation = CurvedAnimation(
    parent: _animationController,
    curve: animationStyle.curve ?? Curves.linear,
    reverseCurve: animationStyle.reverseCurve,
  );

  WindowEntry get entry => widget.entry;

  AnimationStyle get animationStyle => widget.entry.animationStyle;
  bool get isModal => widget.entry.isModal;
  WindowAnchor? get anchor => widget.entry.anchor;

  Rect? _rect;
  Rect? get rect => _rect;

  @override
  void initState() {
    super.initState();

    if (animationStyle.duration != .zero) {
      _animationController.forward();
    } else {
      _animationController.value = 1.0;
    }

    _animationController.addStatusListener((status) {
      if (status == .dismissed) widget.entry.remove();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = widget.builder(context);
    child = widget.transitionBuilder(context, _animation, child);

    // Navigator.of(context).pop();

    return Listener(
      behavior: .translucent,
      onPointerDown: (d) {
        if (!widget.entry.isModal) return;

        final position = d.localPosition;
        if (!_rect!.contains(position)) {
          widget.entry.remove();
        }
      },
      child: _WindowPositioned(
        rect: rect,
        onInitialRectComputed: (r) => _rect = r,
        anchor: widget.entry.anchor,
        // windowConstraints: BoxConstraints.loose(Size.square(400.0)),
        child: Stack(
          clipBehavior: .none,
          children: [
            // TODO: replace this with an actual Navigator. problem - _RenderTheater layout takes up the entire space.
            PopScope(
              canPop: false,
              onPopInvokedWithResult: (_, _) {
                _animationController.reverse();
              },
              child: child,
            ),

            // TODO: allow configurable draggable area.
            Positioned(
              left: 0.0,
              right: 0.0,
              top: 0.0,
              height: 48.0,
              child: RawGestureDetector(
                behavior: HitTestBehavior.translucent,
                gestures: {
                  DragActivityGestureRecognizer<WindowMoveActivity>: DragActivityGestureRecognizerFactory(
                    activityFactory: () => WindowMoveActivity(
                      initialRect: rect!,
                      onChanged: (r) => setState(() => _rect = r),
                    ),
                  ),
                },
                child: SizedBox.expand(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WindowAnchor {
  const WindowAnchor({required this.rect, this.alignment});

  final Rect rect;
  final Alignment? alignment;
}

class _WindowPositioned extends SingleChildRenderObjectWidget {
  _WindowPositioned({
    super.key,
    required Widget super.child,
    this.rect,
    this.anchor,
    this.onInitialRectComputed,
    this.windowConstraints,
  });

  final Rect? rect;
  final WindowAnchor? anchor;
  final ValueChanged<Rect>? onInitialRectComputed;
  final BoxConstraints? windowConstraints;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderWindowPositioned(
      rect: rect,
      anchor: anchor,
      onInitialRectComputed: onInitialRectComputed,
      windowConstraints: windowConstraints,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderWindowPositioned renderObject,
  ) {
    renderObject
      ..rect = rect
      ..windowConstraints = windowConstraints;
  }
}

class _RenderWindowPositioned extends RenderProxyBox {
  _RenderWindowPositioned({
    BoxConstraints? windowConstraints,
    Rect? rect,
    WindowAnchor? anchor,
    ValueChanged<Rect>? onInitialRectComputed,
  }) : _rect = rect,
       _anchor = anchor,
       _onInitialRectComputed = onInitialRectComputed,
       _windowConstraints = windowConstraints;

  BoxConstraints? _windowConstraints;
  BoxConstraints? get windowConstraints => _windowConstraints;
  set windowConstraints(BoxConstraints? value) {
    if (value == _windowConstraints) return;
    _windowConstraints = value;
    markNeedsLayout();
  }

  Rect? _rect;
  Rect? get rect => _rect;
  set rect(Rect? value) {
    if (value == _rect) return;
    _rect = value;
    markNeedsLayout();
  }

  final WindowAnchor? _anchor;
  final ValueChanged<Rect>? _onInitialRectComputed;

  void _recomputeRect() {
    child!.layout(
      windowConstraints ?? constraints.loosen(),
      parentUsesSize: true,
    );

    final childSize = child!.size;

    final containerRect = Offset.zero & constraints.biggest;
    late final Offset center;

    if (_anchor != null) {
      if (_anchor.alignment != null) {
        // TODO
      } else {
        // Try to find a sensible default alignment based on the anchor rect, window rect and child size.
        final anchorRect = _anchor.rect;
        final anchorCenter = anchorRect.center;
        final containerCenter = containerRect.center;

        final halfWidth = childSize.width / 2.0;
        final halfHeight = childSize.height / 2.0;

        double centerY = anchorRect.bottom + halfHeight;
        if (centerY + halfHeight > containerRect.bottom) {
          centerY = anchorRect.top - halfHeight;
        }

        double centerX = anchorCenter.dx;
        if (centerX + halfWidth > containerRect.right) {
          centerX = containerRect.right - halfWidth;
        } else if (centerX - halfWidth < containerRect.left) {
          centerX = containerRect.left + halfWidth;
        }

        center = Offset(centerX, centerY);
      }
    } else {
      center = containerRect.center;
    }

    _rect = Rect.fromCenter(
      center: center,
      width: childSize.width,
      height: childSize.height,
    );

    _onInitialRectComputed?.call(_rect!);
  }

  @override
  void performLayout() {
    size = constraints.biggest;

    // If no rect is passed - try to compute an initial rect.
    if (rect == null) {
      _recomputeRect();
      return;
    }

    final rectConstraints = BoxConstraints.tight(rect!.size);

    // // To allow for iteration in debug mode, allow changing the rect during layout.
    // if (kDebugMode) {
    //   _recomputeRect();
    //   return;
    // }

    child!.layout(rectConstraints);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final childOffset = offset + rect!.topLeft;
    context.paintChild(child!, childOffset);
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    transform.translateByDouble(rect!.left, rect!.top, 0.0, 1.0);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return result.addWithPaintOffset(
      offset: rect!.topLeft,
      position: position,
      hitTest: (result, position) => child!.hitTest(result, position: position),
    );
  }
}
