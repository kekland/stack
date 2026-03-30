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
  WindowEntry({required super.builder});

  @override
  WidgetBuilder get builder {
    return (context) => WindowWidget(entry: this, builder: super.builder);
  }

  void insert(BuildContext context) {
    final root = context.findAncestorStateOfType<WindowRootState>()!;
    root.overlay.insert(this);
  }
}

class WindowWidget extends StatefulWidget {
  const WindowWidget({
    super.key,
    required this.entry,
    required this.builder,
  });

  final WindowEntry entry;
  final WidgetBuilder builder;

  @override
  State<WindowWidget> createState() => WindowWidgetState();
}

class WindowWidgetState extends State<WindowWidget> {
  Rect? _rect;
  Rect? get rect => _rect;

  @override
  Widget build(BuildContext context) {
    return _WindowPositioned(
      rect: rect,
      onInitialRectComputed: (r) => _rect = r,
      windowConstraints: BoxConstraints.loose(Size.square(400.0)),
      child: RawGestureDetector(
        behavior: HitTestBehavior.opaque,
        gestures: {
          DragActivityGestureRecognizer: DragActivityGestureRecognizerFactory(
            activityFactory: () => WindowMoveActivity(
              initialRect: rect!,
              onChanged: (r) => setState(() => _rect = r),
            ),
          ),
        },
        // TODO: replace this with an actual Navigator. problem - _RenderTheater layout takes up the entire space.
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (_, _) => widget.entry.remove(),
          child: widget.builder(context),
        ),
      ),
    );
  }
}

class _WindowPositioned extends SingleChildRenderObjectWidget {
  _WindowPositioned({
    super.key,
    required Widget super.child,
    this.rect,
    this.initialOffset,
    this.initialAlignment,
    this.onInitialRectComputed,
    this.windowConstraints,
  });

  final Rect? rect;
  final Offset? initialOffset;
  final Alignment? initialAlignment;
  final ValueChanged<Rect>? onInitialRectComputed;
  final BoxConstraints? windowConstraints;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderWindowPositioned(
      rect: rect,
      initialOffset: initialOffset,
      initialAlignment: initialAlignment,
      onInitialRectComputed: onInitialRectComputed,
      windowConstraints: windowConstraints,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderWindowPositioned renderObject) {
    renderObject
      ..rect = rect
      ..windowConstraints = windowConstraints;
  }
}

class _RenderWindowPositioned extends RenderProxyBox {
  _RenderWindowPositioned({
    BoxConstraints? windowConstraints,
    Rect? rect,
    Offset? initialOffset,
    Alignment? initialAlignment,
    ValueChanged<Rect>? onInitialRectComputed,
  }) : _rect = rect,
       _initialOffset = initialOffset,
       _initialAlignment = initialAlignment,
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

  final Alignment? _initialAlignment;
  final Offset? _initialOffset;
  final ValueChanged<Rect>? _onInitialRectComputed;

  void _recomputeRect() {
    child!.layout(windowConstraints ?? constraints, parentUsesSize: true);

    final childSize = child!.size;
    final alignment = _initialAlignment ?? Alignment.center;
    final offset = rect?.center ?? _initialOffset ?? (constraints.biggest.center(Offset.zero));

    _rect = Rect.fromCenter(
      center: offset + Offset(alignment.x * childSize.width, alignment.y * childSize.height),
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

    // To allow for iteration in debug mode, allow changing the rect during layout.
    if (kDebugMode) {
      _recomputeRect();
      return;
    }

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
