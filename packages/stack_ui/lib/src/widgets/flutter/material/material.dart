// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Clone of material-related utils, but without ink clipping.

// ignore_for_file: invalid_use_of_protected_member, deprecated_member_use, annotate_overrides, overridden_fields

library;

import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as mat;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart';

class MaterialWithNoInkClip extends Material {
  const MaterialWithNoInkClip({
    super.key,
    super.child,
  }) : super(
          type: MaterialType.transparency,
          clipBehavior: Clip.none,
        );

  static MaterialInkControllerWithNoInkClip? maybeOf(BuildContext context) {
    return LookupBoundary.findAncestorRenderObjectOfType<_RenderInkFeatures>(context);
  }

  static MaterialInkControllerWithNoInkClip of(BuildContext context) {
    final MaterialInkControllerWithNoInkClip? controller = maybeOf(context);
    return controller!;
  }

  @override
  State<Material> createState() => _MaterialWithNoInkClipState();
}

class _MaterialWithNoInkClipState extends State<Material> with TickerProviderStateMixin {
  final GlobalKey _inkFeatureRenderer = GlobalKey(debugLabel: 'ink renderer');

  @override
  Widget build(BuildContext context) {
    Widget? contents = widget.child;
    contents = NotificationListener<LayoutChangedNotification>(
      onNotification: (LayoutChangedNotification notification) {
        final _RenderInkFeatures renderer =
            _inkFeatureRenderer.currentContext!.findRenderObject()! as _RenderInkFeatures;
        renderer._didChangeLayout();
        return false;
      },
      child: _InkFeatures(
        key: _inkFeatureRenderer,
        absorbHitTest: false,
        color: null,
        vsync: this,
        child: contents,
      ),
    );

    const shape = RoundedRectangleBorder();

    return ClipPath(
      clipper: ShapeBorderClipper(shape: shape, textDirection: Directionality.maybeOf(context)),
      clipBehavior: widget.clipBehavior,
      child: contents,
    );
  }
}

class MaterialInkControllerAdapter extends mat.MaterialInkController {
  MaterialInkControllerAdapter({required this.parent});

  final MaterialInkControllerWithNoInkClip parent;

  @override
  void addInkFeature(InkFeature feature) => parent.addInkFeature(InkFeatureAdapter(controller: this, feature: feature));

  @override
  Color? get color => parent.color;

  @override
  void markNeedsPaint() => parent.markNeedsPaint();

  @override
  TickerProvider get vsync => parent.vsync;
}

class InkFeatureAdapter extends InkFeatureWithNoInkClip {
  InkFeatureAdapter({
    required MaterialInkControllerAdapter controller,
    required this.feature,
  }) : super(
          controller: controller.parent,
          referenceBox: feature.referenceBox,
          onRemoved: feature.onRemoved,
        );

  final mat.InkFeature feature;

  @override
  void paintFeature(Canvas canvas, Matrix4 transform) => feature.paintFeature(canvas, transform);
}

/// An interface for creating [InkSplash]s and [InkHighlight]s on a [Material].
///
/// Typically obtained via [Material.of].
abstract class MaterialInkControllerWithNoInkClip {
  /// The color of the material.
  Color? get color;

  /// The ticker provider used by the controller.
  ///
  /// Ink features that are added to this controller with [addInkFeature] should
  /// use this vsync to drive their animations.
  TickerProvider get vsync;

  /// Add an [InkFeature], such as an [InkSplash] or an [InkHighlight].
  ///
  /// The ink feature will paint as part of this controller.
  void addInkFeature(InkFeatureWithNoInkClip feature);

  /// Notifies the controller that one of its ink features needs to repaint.
  void markNeedsPaint();
}

class _RenderInkFeatures extends RenderProxyBox implements MaterialInkControllerWithNoInkClip {
  _RenderInkFeatures({
    RenderBox? child,
    required this.vsync,
    required this.absorbHitTest,
    this.color,
  }) : super(child);

  @override
  final TickerProvider vsync;

  @override
  Color? color;

  bool absorbHitTest;

  @visibleForTesting
  List<InkFeatureWithNoInkClip>? get debugInkFeatures {
    if (kDebugMode) {
      return _inkFeatures;
    }
    return null;
  }

  List<InkFeatureWithNoInkClip>? _inkFeatures;

  @override
  void addInkFeature(InkFeatureWithNoInkClip feature) {
    _inkFeatures ??= <InkFeatureWithNoInkClip>[];
    assert(!_inkFeatures!.contains(feature));
    _inkFeatures!.add(feature);
    markNeedsPaint();
  }

  void _removeFeature(InkFeatureWithNoInkClip feature) {
    assert(_inkFeatures != null);
    _inkFeatures!.remove(feature);
    markNeedsPaint();
  }

  void _didChangeLayout() {
    if (_inkFeatures?.isNotEmpty ?? false) {
      markNeedsPaint();
    }
  }

  @override
  bool hitTestSelf(Offset position) => absorbHitTest;

  @override
  void paint(PaintingContext context, Offset offset) {
    final List<InkFeatureWithNoInkClip>? inkFeatures = _inkFeatures;
    if (inkFeatures != null && inkFeatures.isNotEmpty) {
      final Canvas canvas = context.canvas;
      canvas.save();
      canvas.translate(offset.dx, offset.dy);
      for (final InkFeatureWithNoInkClip inkFeature in inkFeatures) {
        inkFeature._paint(canvas);
      }
      canvas.restore();
    }
    assert(inkFeatures == _inkFeatures);
    super.paint(context, offset);
  }
}

abstract class InkFeatureWithNoInkClip {
  InkFeatureWithNoInkClip({
    required MaterialInkControllerWithNoInkClip controller,
    required this.referenceBox,
    this.onRemoved,
  }) : _controller = controller as _RenderInkFeatures {
    assert(debugMaybeDispatchCreated('material', 'InkFeature', this));
  }

  MaterialInkControllerWithNoInkClip get controller => _controller;
  final _RenderInkFeatures _controller;

  final RenderBox referenceBox;
  final VoidCallback? onRemoved;

  bool _debugDisposed = false;

  /// Free up the resources associated with this ink feature.
  @mustCallSuper
  void dispose() {
    assert(!_debugDisposed);
    assert(() {
      _debugDisposed = true;
      return true;
    }());
    assert(debugMaybeDispatchDisposed(this));
    _controller._removeFeature(this);
    onRemoved?.call();
  }

  static Matrix4? _getPaintTransform(RenderObject fromRenderObject, RenderObject toRenderObject) {
    // The paths to fromRenderObject and toRenderObject's common ancestor.
    final List<RenderObject> fromPath = <RenderObject>[fromRenderObject];
    final List<RenderObject> toPath = <RenderObject>[toRenderObject];

    RenderObject from = fromRenderObject;
    RenderObject to = toRenderObject;

    while (!identical(from, to)) {
      final int fromDepth = from.depth;
      final int toDepth = to.depth;

      if (fromDepth >= toDepth) {
        final RenderObject? fromParent = from.parent;
        // Return early if the 2 render objects are not in the same render tree,
        // or either of them is offscreen and thus won't get painted.
        if (fromParent is! RenderObject || !fromParent.paintsChild(from)) {
          return null;
        }
        fromPath.add(fromParent);
        from = fromParent;
      }

      if (fromDepth <= toDepth) {
        final RenderObject? toParent = to.parent;
        if (toParent is! RenderObject || !toParent.paintsChild(to)) {
          return null;
        }
        toPath.add(toParent);
        to = toParent;
      }
    }
    assert(identical(from, to));

    final Matrix4 transform = Matrix4.identity();
    final Matrix4 inverseTransform = Matrix4.identity();

    for (int index = toPath.length - 1; index > 0; index -= 1) {
      toPath[index].applyPaintTransform(toPath[index - 1], transform);
    }
    for (int index = fromPath.length - 1; index > 0; index -= 1) {
      fromPath[index].applyPaintTransform(fromPath[index - 1], inverseTransform);
    }

    final double det = inverseTransform.invert();
    return det != 0 ? (inverseTransform..multiply(transform)) : null;
  }

  void _paint(Canvas canvas) {
    assert(referenceBox.attached);
    assert(!_debugDisposed);

    final Matrix4? transform = _getPaintTransform(_controller, referenceBox);
    if (transform != null) {
      paintFeature(canvas, transform);
    }
  }

  @protected
  void paintFeature(Canvas canvas, Matrix4 transform);

  @override
  String toString() => describeIdentity(this);
}

class _InkFeatures extends SingleChildRenderObjectWidget {
  const _InkFeatures({
    super.key,
    this.color,
    required this.vsync,
    required this.absorbHitTest,
    super.child,
  });

  // This widget must be owned by a WidgetState, which must be provided as the vsync.
  // This relationship must be 1:1 and cannot change for the lifetime of the WidgetState.

  final Color? color;

  final TickerProvider vsync;

  final bool absorbHitTest;

  @override
  _RenderInkFeatures createRenderObject(BuildContext context) {
    return _RenderInkFeatures(color: color, absorbHitTest: absorbHitTest, vsync: vsync);
  }

  @override
  void updateRenderObject(BuildContext context, _RenderInkFeatures renderObject) {
    renderObject
      ..color = color
      ..absorbHitTest = absorbHitTest;
    assert(vsync == renderObject.vsync);
  }
}

class InkResponseWithNoInkClip extends StatelessWidget {
  const InkResponseWithNoInkClip({
    super.key,
    this.child,
    this.onTap,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
    this.onDoubleTap,
    this.onLongPress,
    this.onSecondaryTap,
    this.onSecondaryTapUp,
    this.onSecondaryTapDown,
    this.onSecondaryTapCancel,
    this.onHighlightChanged,
    this.onHover,
    this.mouseCursor,
    this.containedInkWell = false,
    this.highlightShape = BoxShape.circle,
    this.radius,
    this.borderRadius,
    this.customBorder,
    this.focusColor,
    this.hoverColor,
    this.highlightColor,
    this.overlayColor,
    this.splashColor,
    this.splashFactory,
    this.enableFeedback = true,
    this.excludeFromSemantics = false,
    this.focusNode,
    this.canRequestFocus = true,
    this.onFocusChange,
    this.autofocus = false,
    this.statesController,
    this.hoverDuration,
  });

  final Widget? child;
  final GestureTapCallback? onTap;
  final GestureTapDownCallback? onTapDown;
  final GestureTapUpCallback? onTapUp;
  final GestureTapCallback? onTapCancel;
  final GestureTapCallback? onDoubleTap;
  final GestureLongPressCallback? onLongPress;
  final GestureTapCallback? onSecondaryTap;
  final GestureTapDownCallback? onSecondaryTapDown;
  final GestureTapUpCallback? onSecondaryTapUp;
  final GestureTapCallback? onSecondaryTapCancel;
  final ValueChanged<bool>? onHighlightChanged;
  final ValueChanged<bool>? onHover;
  final MouseCursor? mouseCursor;
  final bool containedInkWell;
  final BoxShape highlightShape;
  final double? radius;
  final BorderRadius? borderRadius;
  final ShapeBorder? customBorder;
  final Color? focusColor;
  final Color? hoverColor;
  final Color? highlightColor;
  final WidgetStateProperty<Color?>? overlayColor;
  final Color? splashColor;
  final InteractiveInkFeatureFactoryWithNoInkClip? splashFactory;
  final bool enableFeedback;
  final bool excludeFromSemantics;
  final ValueChanged<bool>? onFocusChange;
  final bool autofocus;
  final FocusNode? focusNode;
  final bool canRequestFocus;

  RectCallback? getRectCallback(RenderBox referenceBox) => null;

  final WidgetStatesController? statesController;

  final Duration? hoverDuration;

  @override
  Widget build(BuildContext context) {
    final _ParentInkResponseState? parentState = _ParentInkResponseProvider.maybeOf(context);
    return _InkResponseStateWidget(
      onTap: onTap,
      onTapDown: onTapDown,
      onTapUp: onTapUp,
      onTapCancel: onTapCancel,
      onDoubleTap: onDoubleTap,
      onLongPress: onLongPress,
      onSecondaryTap: onSecondaryTap,
      onSecondaryTapUp: onSecondaryTapUp,
      onSecondaryTapDown: onSecondaryTapDown,
      onSecondaryTapCancel: onSecondaryTapCancel,
      onHighlightChanged: onHighlightChanged,
      onHover: onHover,
      mouseCursor: mouseCursor,
      containedInkWell: containedInkWell,
      highlightShape: highlightShape,
      radius: radius,
      borderRadius: borderRadius,
      customBorder: customBorder,
      focusColor: focusColor,
      hoverColor: hoverColor,
      highlightColor: highlightColor,
      overlayColor: overlayColor,
      splashColor: splashColor,
      splashFactory: splashFactory,
      enableFeedback: enableFeedback,
      excludeFromSemantics: excludeFromSemantics,
      focusNode: focusNode,
      canRequestFocus: canRequestFocus,
      onFocusChange: onFocusChange,
      autofocus: autofocus,
      parentState: parentState,
      getRectCallback: getRectCallback,
      debugCheckContext: debugCheckContext,
      statesController: statesController,
      hoverDuration: hoverDuration,
      child: child,
    );
  }

  /// Asserts that the given context satisfies the prerequisites for
  /// this class.
  ///
  /// This method is intended to be overridden by descendants that
  /// specialize [InkResponse] for unusual cases. For example,
  /// [TableRowInkWell] implements this method to verify that the widget is
  /// in a table.
  @mustCallSuper
  bool debugCheckContext(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    assert(debugCheckHasDirectionality(context));
    return true;
  }
}

class _InkResponseStateWidget extends StatefulWidget {
  const _InkResponseStateWidget({
    this.child,
    this.onTap,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
    this.onDoubleTap,
    this.onLongPress,
    this.onSecondaryTap,
    this.onSecondaryTapUp,
    this.onSecondaryTapDown,
    this.onSecondaryTapCancel,
    this.onHighlightChanged,
    this.onHover,
    this.mouseCursor,
    this.containedInkWell = false,
    this.highlightShape = BoxShape.circle,
    this.radius,
    this.borderRadius,
    this.customBorder,
    this.focusColor,
    this.hoverColor,
    this.highlightColor,
    this.overlayColor,
    this.splashColor,
    this.splashFactory,
    this.enableFeedback = true,
    this.excludeFromSemantics = false,
    this.focusNode,
    this.canRequestFocus = true,
    this.onFocusChange,
    this.autofocus = false,
    this.parentState,
    this.getRectCallback,
    required this.debugCheckContext,
    this.statesController,
    this.hoverDuration,
  });

  final Widget? child;
  final GestureTapCallback? onTap;
  final GestureTapDownCallback? onTapDown;
  final GestureTapUpCallback? onTapUp;
  final GestureTapCallback? onTapCancel;
  final GestureTapCallback? onDoubleTap;
  final GestureLongPressCallback? onLongPress;
  final GestureTapCallback? onSecondaryTap;
  final GestureTapUpCallback? onSecondaryTapUp;
  final GestureTapDownCallback? onSecondaryTapDown;
  final GestureTapCallback? onSecondaryTapCancel;
  final ValueChanged<bool>? onHighlightChanged;
  final ValueChanged<bool>? onHover;
  final MouseCursor? mouseCursor;
  final bool containedInkWell;
  final BoxShape highlightShape;
  final double? radius;
  final BorderRadius? borderRadius;
  final ShapeBorder? customBorder;
  final Color? focusColor;
  final Color? hoverColor;
  final Color? highlightColor;
  final WidgetStateProperty<Color?>? overlayColor;
  final Color? splashColor;
  final InteractiveInkFeatureFactoryWithNoInkClip? splashFactory;
  final bool enableFeedback;
  final bool excludeFromSemantics;
  final ValueChanged<bool>? onFocusChange;
  final bool autofocus;
  final FocusNode? focusNode;
  final bool canRequestFocus;
  final _ParentInkResponseState? parentState;
  final _GetRectCallback? getRectCallback;
  final _CheckContext debugCheckContext;
  final WidgetStatesController? statesController;
  final Duration? hoverDuration;

  @override
  _InkResponseState createState() => _InkResponseState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    final List<String> gestures = <String>[
      if (onTap != null) 'tap',
      if (onDoubleTap != null) 'double tap',
      if (onLongPress != null) 'long press',
      if (onTapDown != null) 'tap down',
      if (onTapUp != null) 'tap up',
      if (onTapCancel != null) 'tap cancel',
      if (onSecondaryTap != null) 'secondary tap',
      if (onSecondaryTapUp != null) 'secondary tap up',
      if (onSecondaryTapDown != null) 'secondary tap down',
      if (onSecondaryTapCancel != null) 'secondary tap cancel',
    ];
    properties.add(IterableProperty<String>('gestures', gestures, ifEmpty: '<none>'));
    properties.add(DiagnosticsProperty<MouseCursor>('mouseCursor', mouseCursor));
    properties.add(
      DiagnosticsProperty<bool>('containedInkWell', containedInkWell, level: DiagnosticLevel.fine),
    );
    properties.add(
      DiagnosticsProperty<BoxShape>(
        'highlightShape',
        highlightShape,
        description: '${containedInkWell ? "clipped to " : ""}$highlightShape',
        showName: false,
      ),
    );
  }
}

/// Used to index the allocated highlights for the different types of highlights
/// in [_InkResponseState].
enum _HighlightType { pressed, hover, focus }

class _InkResponseState extends State<_InkResponseStateWidget>
    with AutomaticKeepAliveClientMixin<_InkResponseStateWidget>
    implements _ParentInkResponseState {
  Set<InteractiveInkFeatureWithNoInkClip>? _splashes;
  InteractiveInkFeatureWithNoInkClip? _currentSplash;
  bool _hovering = false;
  final Map<_HighlightType, InkHighlightWithNoInkClip?> _highlights = <_HighlightType, InkHighlightWithNoInkClip?>{};
  late final Map<Type, Action<Intent>> _actionMap = <Type, Action<Intent>>{
    ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: activateOnIntent),
    ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(onInvoke: activateOnIntent),
  };
  WidgetStatesController? internalStatesController;

  bool get highlightsExist => _highlights.values.where((InkHighlightWithNoInkClip? highlight) => highlight != null).isNotEmpty;

  final ObserverList<_ParentInkResponseState> _activeChildren = ObserverList<_ParentInkResponseState>();

  static const Duration _activationDuration = Duration(milliseconds: 100);
  Timer? _activationTimer;

  @override
  void markChildInkResponsePressed(_ParentInkResponseState childState, bool value) {
    final bool lastAnyPressed = _anyChildInkResponsePressed;
    if (value) {
      _activeChildren.add(childState);
    } else {
      _activeChildren.remove(childState);
    }
    final bool nowAnyPressed = _anyChildInkResponsePressed;
    if (nowAnyPressed != lastAnyPressed) {
      widget.parentState?.markChildInkResponsePressed(this, nowAnyPressed);
    }
  }

  bool get _anyChildInkResponsePressed => _activeChildren.isNotEmpty;

  void activateOnIntent(Intent? intent) {
    _activationTimer?.cancel();
    _activationTimer = null;
    _startNewSplash(context: context);
    _currentSplash?.confirm();
    _currentSplash = null;
    if (widget.onTap != null) {
      if (widget.enableFeedback) {
        Feedback.forTap(context);
      }
      widget.onTap?.call();
    }
    // Delay the call to `updateHighlight` to simulate a pressed delay
    // and give WidgetStatesController listeners a chance to react.
    _activationTimer = Timer(_activationDuration, () {
      updateHighlight(_HighlightType.pressed, value: false);
    });
  }

  void simulateTap([Intent? intent]) {
    _startNewSplash(context: context);
    handleTap();
  }

  void simulateLongPress() {
    _startNewSplash(context: context);
    handleLongPress();
  }

  void handleStatesControllerChange() {
    // Force a rebuild to resolve widget.overlayColor, widget.mouseCursor
    setState(() {});
  }

  WidgetStatesController get statesController => widget.statesController ?? internalStatesController!;

  void initStatesController() {
    if (widget.statesController == null) {
      internalStatesController = WidgetStatesController();
    }
    statesController.update(WidgetState.disabled, !enabled);
    statesController.addListener(handleStatesControllerChange);
  }

  @override
  void initState() {
    super.initState();
    initStatesController();
    FocusManager.instance.addHighlightModeListener(handleFocusHighlightModeChange);
  }

  @override
  void didUpdateWidget(_InkResponseStateWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.statesController != oldWidget.statesController) {
      oldWidget.statesController?.removeListener(handleStatesControllerChange);
      if (widget.statesController != null) {
        internalStatesController?.dispose();
        internalStatesController = null;
      }
      initStatesController();
    }
    if (widget.radius != oldWidget.radius ||
        widget.highlightShape != oldWidget.highlightShape ||
        widget.borderRadius != oldWidget.borderRadius) {
      final InkHighlightWithNoInkClip? hoverHighlight = _highlights[_HighlightType.hover];
      if (hoverHighlight != null) {
        hoverHighlight.dispose();
        updateHighlight(_HighlightType.hover, value: _hovering, callOnHover: false);
      }
      final InkHighlightWithNoInkClip? focusHighlight = _highlights[_HighlightType.focus];
      if (focusHighlight != null) {
        focusHighlight.dispose();
        // Do not call updateFocusHighlights() here because it is called below
      }
    }
    if (widget.customBorder != oldWidget.customBorder) {
      _updateHighlightsAndSplashes();
    }
    if (enabled != isWidgetEnabled(oldWidget)) {
      statesController.update(WidgetState.disabled, !enabled);
      if (!enabled) {
        statesController.update(WidgetState.pressed, false);
        // Remove the existing hover highlight immediately when enabled is false.
        // Do not rely on updateHighlight or InkHighlight.deactivate to not break
        // the expected lifecycle which is updating _hovering when the mouse exit.
        // Manually updating _hovering here or calling InkHighlight.deactivate
        // will lead to onHover not being called or call when it is not allowed.
        final InkHighlightWithNoInkClip? hoverHighlight = _highlights[_HighlightType.hover];
        hoverHighlight?.dispose();
      }
      // Don't call widget.onHover because many widgets, including the button
      // widgets, apply setState to an ancestor context from onHover.
      updateHighlight(_HighlightType.hover, value: _hovering, callOnHover: false);
    }
    updateFocusHighlights();
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(handleFocusHighlightModeChange);
    statesController.removeListener(handleStatesControllerChange);
    internalStatesController?.dispose();
    _activationTimer?.cancel();
    _activationTimer = null;
    super.dispose();
  }

  @override
  bool get wantKeepAlive => highlightsExist || (_splashes != null && _splashes!.isNotEmpty);

  Duration getFadeDurationForType(_HighlightType type) {
    switch (type) {
      case _HighlightType.pressed:
        return const Duration(milliseconds: 200);
      case _HighlightType.hover:
      case _HighlightType.focus:
        return widget.hoverDuration ?? const Duration(milliseconds: 50);
    }
  }

  void updateHighlight(_HighlightType type, {required bool value, bool callOnHover = true}) {
    final InkHighlightWithNoInkClip? highlight = _highlights[type];
    void handleInkRemoval() {
      assert(_highlights[type] != null);
      _highlights[type] = null;
      updateKeepAlive();
    }

    switch (type) {
      case _HighlightType.pressed:
        statesController.update(WidgetState.pressed, value);
      case _HighlightType.hover:
        if (callOnHover) {
          statesController.update(WidgetState.hovered, value);
        }
      case _HighlightType.focus:
        // see handleFocusUpdate()
        break;
    }

    if (type == _HighlightType.pressed) {
      widget.parentState?.markChildInkResponsePressed(this, value);
    }
    if (value == (highlight != null && highlight.active)) {
      return;
    }

    if (value) {
      if (highlight == null) {
        final Color resolvedOverlayColor = widget.overlayColor?.resolve(statesController.value) ??
            switch (type) {
              // Use the backwards compatible defaults
              _HighlightType.pressed => widget.highlightColor ?? Theme.of(context).highlightColor,
              _HighlightType.focus => widget.focusColor ?? Theme.of(context).focusColor,
              _HighlightType.hover => widget.hoverColor ?? Theme.of(context).hoverColor,
            };
        final RenderBox referenceBox = context.findRenderObject()! as RenderBox;
        _highlights[type] = InkHighlightWithNoInkClip(
          controller: MaterialWithNoInkClip.of(context),
          referenceBox: referenceBox,
          color: enabled ? resolvedOverlayColor : resolvedOverlayColor.withAlpha(0),
          shape: widget.highlightShape,
          radius: widget.radius,
          borderRadius: widget.borderRadius,
          customBorder: widget.customBorder,
          rectCallback: widget.getRectCallback!(referenceBox),
          onRemoved: handleInkRemoval,
          textDirection: Directionality.of(context),
          fadeDuration: getFadeDurationForType(type),
        );
        updateKeepAlive();
      } else {
        highlight.activate();
      }
    } else {
      highlight!.deactivate();
    }
    assert(value == (_highlights[type] != null && _highlights[type]!.active));

    switch (type) {
      case _HighlightType.pressed:
        widget.onHighlightChanged?.call(value);
      case _HighlightType.hover:
        if (callOnHover) {
          widget.onHover?.call(value);
        }
      case _HighlightType.focus:
        break;
    }
  }

  void _updateHighlightsAndSplashes() {
    for (final InkHighlightWithNoInkClip? highlight in _highlights.values) {
      highlight?.customBorder = widget.customBorder;
    }
    _currentSplash?.customBorder = widget.customBorder;

    if (_splashes != null && _splashes!.isNotEmpty) {
      for (final InteractiveInkFeatureWithNoInkClip inkFeature in _splashes!) {
        inkFeature.customBorder = widget.customBorder;
      }
    }
  }

  InteractiveInkFeatureWithNoInkClip _createSplash(Offset globalPosition) {
    final MaterialInkControllerWithNoInkClip inkController = MaterialWithNoInkClip.of(context);
    final RenderBox referenceBox = context.findRenderObject()! as RenderBox;
    final Offset position = referenceBox.globalToLocal(globalPosition);
    final Color color =
        widget.overlayColor?.resolve(statesController.value) ?? widget.splashColor ?? Theme.of(context).splashColor;
    final RectCallback? rectCallback = widget.containedInkWell ? widget.getRectCallback!(referenceBox) : null;
    final BorderRadius? borderRadius = widget.borderRadius;
    final ShapeBorder? customBorder = widget.customBorder;

    InteractiveInkFeatureWithNoInkClip? splash;
    void onRemoved() {
      if (_splashes != null) {
        assert(_splashes!.contains(splash));
        _splashes!.remove(splash);
        if (_currentSplash == splash) {
          _currentSplash = null;
        }
        updateKeepAlive();
      } // else we're probably in deactivate()
    }

    splash = widget.splashFactory!.create(
      controller: inkController,
      referenceBox: referenceBox,
      position: position,
      color: color,
      containedInkWell: widget.containedInkWell,
      rectCallback: rectCallback,
      radius: widget.radius,
      borderRadius: borderRadius,
      customBorder: customBorder,
      onRemoved: onRemoved,
      textDirection: Directionality.of(context),
    );

    return splash;
  }

  void handleFocusHighlightModeChange(FocusHighlightMode mode) {
    if (!mounted) {
      return;
    }
    setState(() {
      updateFocusHighlights();
    });
  }

  bool get _shouldShowFocus => switch (MediaQuery.maybeNavigationModeOf(context)) {
        NavigationMode.traditional || null => enabled && _hasFocus,
        NavigationMode.directional => _hasFocus,
      };

  void updateFocusHighlights() {
    final bool showFocus = switch (FocusManager.instance.highlightMode) {
      FocusHighlightMode.touch => false,
      FocusHighlightMode.traditional => _shouldShowFocus,
    };
    updateHighlight(_HighlightType.focus, value: showFocus);
  }

  bool _hasFocus = false;
  void handleFocusUpdate(bool hasFocus) {
    _hasFocus = hasFocus;
    // Set here rather than updateHighlight because this widget's
    // (WidgetState) states include WidgetState.focused if
    // the InkWell _has_ the focus, rather than if it's showing
    // the focus per FocusManager.instance.highlightMode.
    statesController.update(WidgetState.focused, hasFocus);
    updateFocusHighlights();
    widget.onFocusChange?.call(hasFocus);
  }

  void handleAnyTapDown(TapDownDetails details) {
    if (_anyChildInkResponsePressed) {
      return;
    }
    _startNewSplash(details: details);
  }

  void handleTapDown(TapDownDetails details) {
    handleAnyTapDown(details);
    widget.onTapDown?.call(details);
  }

  void handleTapUp(TapUpDetails details) {
    widget.onTapUp?.call(details);
  }

  void handleSecondaryTapDown(TapDownDetails details) {
    handleAnyTapDown(details);
    widget.onSecondaryTapDown?.call(details);
  }

  void handleSecondaryTapUp(TapUpDetails details) {
    widget.onSecondaryTapUp?.call(details);
  }

  void _startNewSplash({TapDownDetails? details, BuildContext? context}) {
    assert(details != null || context != null);

    final Offset globalPosition;
    if (context != null) {
      final RenderBox referenceBox = context.findRenderObject()! as RenderBox;
      assert(
        referenceBox.hasSize,
        'InkResponse must be done with layout before starting a splash.',
      );
      globalPosition = referenceBox.localToGlobal(referenceBox.paintBounds.center);
    } else {
      globalPosition = details!.globalPosition;
    }
    statesController.update(WidgetState.pressed, true); // ... before creating the splash
    final InteractiveInkFeatureWithNoInkClip splash = _createSplash(globalPosition);
    _splashes ??= HashSet<InteractiveInkFeatureWithNoInkClip>();
    _splashes!.add(splash);
    _currentSplash?.cancel();
    _currentSplash = splash;
    updateKeepAlive();
    updateHighlight(_HighlightType.pressed, value: true);
  }

  void handleTap() {
    _currentSplash?.confirm();
    _currentSplash = null;
    updateHighlight(_HighlightType.pressed, value: false);
    if (widget.onTap != null) {
      if (widget.enableFeedback) {
        Feedback.forTap(context);
      }
      widget.onTap?.call();
    }
  }

  void handleTapCancel() {
    _currentSplash?.cancel();
    _currentSplash = null;
    widget.onTapCancel?.call();
    updateHighlight(_HighlightType.pressed, value: false);
  }

  void handleDoubleTap() {
    _currentSplash?.confirm();
    _currentSplash = null;
    updateHighlight(_HighlightType.pressed, value: false);
    widget.onDoubleTap?.call();
  }

  void handleLongPress() {
    _currentSplash?.confirm();
    _currentSplash = null;
    if (widget.onLongPress != null) {
      if (widget.enableFeedback) {
        Feedback.forLongPress(context);
      }
      widget.onLongPress!();
    }
  }

  void handleSecondaryTap() {
    _currentSplash?.confirm();
    _currentSplash = null;
    updateHighlight(_HighlightType.pressed, value: false);
    widget.onSecondaryTap?.call();
  }

  void handleSecondaryTapCancel() {
    _currentSplash?.cancel();
    _currentSplash = null;
    widget.onSecondaryTapCancel?.call();
    updateHighlight(_HighlightType.pressed, value: false);
  }

  @override
  void deactivate() {
    if (_splashes != null) {
      final Set<InteractiveInkFeatureWithNoInkClip> splashes = _splashes!;
      _splashes = null;
      for (final InteractiveInkFeatureWithNoInkClip splash in splashes) {
        splash.dispose();
      }
      _currentSplash = null;
    }
    assert(_currentSplash == null);
    for (final _HighlightType highlight in _highlights.keys) {
      _highlights[highlight]?.dispose();
      _highlights[highlight] = null;
    }
    widget.parentState?.markChildInkResponsePressed(this, false);
    super.deactivate();
  }

  bool isWidgetEnabled(_InkResponseStateWidget widget) {
    return _primaryButtonEnabled(widget) || _secondaryButtonEnabled(widget);
  }

  bool _primaryButtonEnabled(_InkResponseStateWidget widget) {
    return widget.onTap != null ||
        widget.onDoubleTap != null ||
        widget.onLongPress != null ||
        widget.onTapUp != null ||
        widget.onTapDown != null;
  }

  bool _secondaryButtonEnabled(_InkResponseStateWidget widget) {
    return widget.onSecondaryTap != null || widget.onSecondaryTapUp != null || widget.onSecondaryTapDown != null;
  }

  bool get enabled => isWidgetEnabled(widget);
  bool get _primaryEnabled => _primaryButtonEnabled(widget);
  bool get _secondaryEnabled => _secondaryButtonEnabled(widget);

  void handleMouseEnter(PointerEnterEvent event) {
    _hovering = true;
    if (enabled) {
      handleHoverChange();
    }
  }

  void handleMouseExit(PointerExitEvent event) {
    _hovering = false;
    // If the exit occurs after we've been disabled, we still
    // want to take down the highlights and run widget.onHover.
    handleHoverChange();
  }

  void handleHoverChange() {
    updateHighlight(_HighlightType.hover, value: _hovering);
  }

  bool get _canRequestFocus => switch (MediaQuery.maybeNavigationModeOf(context)) {
        NavigationMode.traditional || null => enabled && widget.canRequestFocus,
        NavigationMode.directional => true,
      };

  @override
  Widget build(BuildContext context) {
    assert(widget.debugCheckContext(context));
    super.build(context); // See AutomaticKeepAliveClientMixin.

    final ThemeData theme = Theme.of(context);
    const Set<WidgetState> highlightableStates = <WidgetState>{
      WidgetState.focused,
      WidgetState.hovered,
      WidgetState.pressed,
    };
    final Set<WidgetState> nonHighlightableStates = statesController.value.difference(
      highlightableStates,
    );
    // Each highlightable state will be resolved separately to get the corresponding color.
    // For this resolution to be correct, the non-highlightable states should be preserved.
    final Set<WidgetState> pressed = <WidgetState>{
      ...nonHighlightableStates,
      WidgetState.pressed,
    };
    final Set<WidgetState> focused = <WidgetState>{
      ...nonHighlightableStates,
      WidgetState.focused,
    };
    final Set<WidgetState> hovered = <WidgetState>{
      ...nonHighlightableStates,
      WidgetState.hovered,
    };

    Color getHighlightColorForType(_HighlightType type) {
      return switch (type) {
        // The pressed state triggers a ripple (ink splash), per the current
        // Material Design spec. A separate highlight is no longer used.
        // See https://material.io/design/interaction/states.html#pressed
        _HighlightType.pressed =>
          widget.overlayColor?.resolve(pressed) ?? widget.highlightColor ?? theme.highlightColor,
        _HighlightType.focus => widget.overlayColor?.resolve(focused) ?? widget.focusColor ?? theme.focusColor,
        _HighlightType.hover => widget.overlayColor?.resolve(hovered) ?? widget.hoverColor ?? theme.hoverColor,
      };
    }

    for (final _HighlightType type in _highlights.keys) {
      _highlights[type]?.color = getHighlightColorForType(type);
    }

    _currentSplash?.color =
        widget.overlayColor?.resolve(statesController.value) ?? widget.splashColor ?? Theme.of(context).splashColor;

    final MouseCursor effectiveMouseCursor = WidgetStateProperty.resolveAs<MouseCursor>(
      widget.mouseCursor ?? WidgetStateMouseCursor.clickable,
      statesController.value,
    );

    return _ParentInkResponseProvider(
      state: this,
      child: Actions(
        actions: _actionMap,
        child: Focus(
          focusNode: widget.focusNode,
          canRequestFocus: _canRequestFocus,
          onFocusChange: handleFocusUpdate,
          autofocus: widget.autofocus,
          child: MouseRegion(
            cursor: effectiveMouseCursor,
            onEnter: handleMouseEnter,
            onExit: handleMouseExit,
            child: DefaultSelectionStyle.merge(
              mouseCursor: effectiveMouseCursor,
              child: Semantics(
                onTap: widget.excludeFromSemantics || widget.onTap == null ? null : simulateTap,
                onLongPress: widget.excludeFromSemantics || widget.onLongPress == null ? null : simulateLongPress,
                child: GestureDetector(
                  onTapDown: _primaryEnabled ? handleTapDown : null,
                  onTapUp: _primaryEnabled ? handleTapUp : null,
                  onTap: _primaryEnabled ? handleTap : null,
                  onTapCancel: _primaryEnabled ? handleTapCancel : null,
                  onDoubleTap: widget.onDoubleTap != null ? handleDoubleTap : null,
                  onLongPress: widget.onLongPress != null ? handleLongPress : null,
                  onSecondaryTapDown: _secondaryEnabled ? handleSecondaryTapDown : null,
                  onSecondaryTapUp: _secondaryEnabled ? handleSecondaryTapUp : null,
                  onSecondaryTap: _secondaryEnabled ? handleSecondaryTap : null,
                  onSecondaryTapCancel: _secondaryEnabled ? handleSecondaryTapCancel : null,
                  behavior: HitTestBehavior.opaque,
                  excludeFromSemantics: true,
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

abstract class _ParentInkResponseState {
  void markChildInkResponsePressed(_ParentInkResponseState childState, bool value);
}

class _ParentInkResponseProvider extends InheritedWidget {
  const _ParentInkResponseProvider({required this.state, required super.child});

  final _ParentInkResponseState state;

  @override
  bool updateShouldNotify(_ParentInkResponseProvider oldWidget) => state != oldWidget.state;

  static _ParentInkResponseState? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_ParentInkResponseProvider>()?.state;
  }
}

typedef _GetRectCallback = RectCallback? Function(RenderBox referenceBox);
typedef _CheckContext = bool Function(BuildContext context);

abstract class InteractiveInkFeatureFactoryWithNoInkClip {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  ///
  /// Subclasses should provide a const constructor.
  const InteractiveInkFeatureFactoryWithNoInkClip();

  /// The factory method.
  ///
  /// Subclasses should override this method to return a new instance of an
  /// [InteractiveInkFeature].
  @factory
  InteractiveInkFeatureWithNoInkClip create({
    required MaterialInkControllerWithNoInkClip controller,
    required RenderBox referenceBox,
    required Offset position,
    required Color color,
    required TextDirection textDirection,
    bool containedInkWell = false,
    RectCallback? rectCallback,
    BorderRadius? borderRadius,
    ShapeBorder? customBorder,
    double? radius,
    VoidCallback? onRemoved,
  });
}

abstract class InteractiveInkFeatureWithNoInkClip extends InkFeatureWithNoInkClip {
  /// Creates an InteractiveInkFeature.
  InteractiveInkFeatureWithNoInkClip({
    required super.controller,
    required super.referenceBox,
    required Color color,
    ShapeBorder? customBorder,
    super.onRemoved,
  }) : _color = color,
       _customBorder = customBorder;

  /// Called when the user input that triggered this feature's appearance was confirmed.
  ///
  /// Typically causes the ink to propagate faster across the material. By default this
  /// method does nothing.
  void confirm() {}

  /// Called when the user input that triggered this feature's appearance was canceled.
  ///
  /// Typically causes the ink to gradually disappear. By default this method does
  /// nothing.
  void cancel() {}

  /// The ink's color.
  Color get color => _color;
  Color _color;
  set color(Color value) {
    if (value == _color) {
      return;
    }
    _color = value;
    controller.markNeedsPaint();
  }

  /// The ink's optional custom border.
  ShapeBorder? get customBorder => _customBorder;
  ShapeBorder? _customBorder;
  set customBorder(ShapeBorder? value) {
    if (value == _customBorder) {
      return;
    }
    _customBorder = value;
    controller.markNeedsPaint();
  }

  /// Draws an ink splash or ink ripple on the passed in [Canvas].
  ///
  /// The [transform] argument is the [Matrix4] transform that typically
  /// shifts the coordinate space of the canvas to the space in which
  /// the ink circle is to be painted.
  ///
  /// [center] is the [Offset] from origin of the canvas where the center
  /// of the circle is drawn.
  ///
  /// [paint] takes a [Paint] object that describes the styles used to draw the ink circle.
  /// For example, [paint] can specify properties like color, strokewidth, colorFilter.
  ///
  /// [radius] is the radius of ink circle to be drawn on canvas.
  ///
  /// [clipCallback] is the callback used to obtain the [Rect] used for clipping the ink effect.
  /// If [clipCallback] is null, no clipping is performed on the ink circle.
  ///
  /// Clipping can happen in 3 different ways:
  ///  1. If [customBorder] is provided, it is used to determine the path
  ///     for clipping.
  ///  2. If [customBorder] is null, and [borderRadius] is provided, the canvas
  ///     is clipped by an [RRect] created from [clipCallback] and [borderRadius].
  ///  3. If [borderRadius] is the default [BorderRadius.zero], then the [Rect] provided
  ///      by [clipCallback] is used for clipping.
  ///
  /// [textDirection] is used by [customBorder] if it is non-null. This allows the [customBorder]'s path
  /// to be properly defined if it was the path was expressed in terms of "start" and "end" instead of
  /// "left" and "right".
  ///
  /// For examples on how the function is used, see [InkSplash] and [InkRipple].
  @protected
  void paintInkCircle({
    required Canvas canvas,
    required Matrix4 transform,
    required Paint paint,
    required Offset center,
    required double radius,
    TextDirection? textDirection,
    ShapeBorder? customBorder,
    BorderRadius borderRadius = BorderRadius.zero,
    RectCallback? clipCallback,
  }) {
    final Offset? originOffset = MatrixUtils.getAsTranslation(transform);
    canvas.save();
    if (originOffset == null) {
      canvas.transform(transform.storage);
    } else {
      canvas.translate(originOffset.dx, originOffset.dy);
    }
    if (clipCallback != null) {
      final Rect rect = clipCallback();
      if (customBorder != null) {
        canvas.clipPath(customBorder.getOuterPath(rect, textDirection: textDirection));
      } else if (borderRadius != BorderRadius.zero) {
        canvas.clipRRect(
          RRect.fromRectAndCorners(
            rect,
            topLeft: borderRadius.topLeft,
            topRight: borderRadius.topRight,
            bottomLeft: borderRadius.bottomLeft,
            bottomRight: borderRadius.bottomRight,
          ),
        );
      } else {
        canvas.clipRect(rect);
      }
    }
    canvas.drawCircle(center, radius, paint);
    canvas.restore();
  }
}

class InkSparkleWithNoInkClip extends InteractiveInkFeatureWithNoInkClip {
  InkSparkleWithNoInkClip({
    required super.controller,
    required super.referenceBox,
    required super.color,
    required Offset position,
    required TextDirection textDirection,
    bool containedInkWell = true,
    RectCallback? rectCallback,
    BorderRadius? borderRadius,
    super.customBorder,
    double? radius,
    super.onRemoved,
    double? turbulenceSeed,
  })  : assert(containedInkWell || rectCallback == null),
        _color = color,
        _position = position,
        _borderRadius = borderRadius ?? BorderRadius.zero,
        _textDirection = textDirection,
        _targetRadius = (radius ?? _getTargetRadius(referenceBox, containedInkWell, rectCallback, position)) *
            _targetRadiusMultiplier,
        _clipCallback = _getClipCallback(referenceBox, containedInkWell, rectCallback) {
    // InkSparkle will not be painted until the async compilation completes.
    _InkSparkleFactory.initializeShader();
    controller.addInkFeature(this);

    // Immediately begin animating the ink.
    _animationController = AnimationController(duration: _animationDuration, vsync: controller.vsync)
      ..addListener(controller.markNeedsPaint)
      ..addStatusListener(_handleStatusChanged)
      ..forward();

    _radiusScale = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(tween: CurveTween(curve: Curves.fastOutSlowIn), weight: 75),
      TweenSequenceItem<double>(tween: ConstantTween<double>(1.0), weight: 25),
    ]).animate(_animationController);

    // Functionally equivalent to Android 12's SkSL:
    //`return mix(u_touch, u_resolution, saturate(in_radius_scale * 2.0))`
    final Tween<Vector2> centerTween = Tween<Vector2>(
      begin: Vector2.array(<double>[_position.dx, _position.dy]),
      end: Vector2.array(<double>[referenceBox.size.width / 2, referenceBox.size.height / 2]),
    );
    final Animation<double> centerProgress = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 50),
      TweenSequenceItem<double>(tween: ConstantTween<double>(1.0), weight: 50),
    ]).animate(_radiusScale);
    _center = centerTween.animate(centerProgress);

    _alpha = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 13),
      TweenSequenceItem<double>(tween: ConstantTween<double>(1.0), weight: 27),
      TweenSequenceItem<double>(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 60),
    ]).animate(_animationController);

    _sparkleAlpha = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 13),
      TweenSequenceItem<double>(tween: ConstantTween<double>(1.0), weight: 27),
      TweenSequenceItem<double>(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 50),
    ]).animate(_animationController);

    // Creates an element of randomness so that ink emanating from the same
    // pixel have slightly different rings and sparkles.
    assert(() {
      // In tests, randomness can cause flakes. So if a seed has not
      // already been specified (i.e. for the purpose of the test), set it to
      // the constant turbulence seed.
      turbulenceSeed ??= _InkSparkleFactory.constantSeed;
      return true;
    }());
    _turbulenceSeed = turbulenceSeed ?? math.Random().nextDouble() * 1000.0;
  }

  void _handleStatusChanged(AnimationStatus status) {
    if (status.isCompleted) {
      dispose();
    }
  }

  static const Duration _animationDuration = Duration(milliseconds: 617);
  static const double _targetRadiusMultiplier = 2.3;
  static const double _rotateRight = math.pi * 0.0078125;
  static const double _rotateLeft = -_rotateRight;
  static const double _noiseDensity = 2.1;

  late AnimationController _animationController;

  // The Android 12 version has these values calculated in the GLSL. They are
  // constant for every pixel in the animation, so the Flutter implementation
  // computes these animation values in software in order to simplify the shader
  // implementation and provide better performance on most devices.
  late Animation<Vector2> _center;
  late Animation<double> _radiusScale;
  late Animation<double> _alpha;
  late Animation<double> _sparkleAlpha;

  late double _turbulenceSeed;

  final Color _color;
  final Offset _position;
  final BorderRadius _borderRadius;
  final double _targetRadius;
  final RectCallback? _clipCallback;
  final TextDirection _textDirection;

  late final ui.FragmentShader _fragmentShader;
  bool _fragmentShaderInitialized = false;

  /// Used to specify this type of ink splash for an [InkWell], [InkResponse],
  /// material [Theme], or [ButtonStyle].
  ///
  /// Since no `turbulenceSeed` is passed, the effect will be random for
  /// subsequent presses in the same position.
  static const InteractiveInkFeatureFactoryWithNoInkClip splashFactory = _InkSparkleFactory();

  /// Used to specify this type of ink splash for an [InkWell], [InkResponse],
  /// material [Theme], or [ButtonStyle].
  ///
  /// Since a `turbulenceSeed` is passed, the effect will not be random for
  /// subsequent presses in the same position. This can be used for testing.
  static const InteractiveInkFeatureFactoryWithNoInkClip constantTurbulenceSeedSplashFactory =
      _InkSparkleFactory.constantTurbulenceSeed();

  @override
  void dispose() {
    _animationController.stop();
    _animationController.dispose();
    if (_fragmentShaderInitialized) {
      _fragmentShader.dispose();
    }
    super.dispose();
  }

  @override
  void paintFeature(Canvas canvas, Matrix4 transform) {
    assert(_animationController.isAnimating);

    // InkSparkle can only paint if its shader has been compiled.
    if (_InkSparkleFactory._program == null) {
      // Skipping paintFeature because the shader it relies on is not ready to
      // be used. InkSparkleFactory.initializeShader must complete
      // before InkSparkle can paint.
      return;
    }

    if (!_fragmentShaderInitialized) {
      _fragmentShader = _InkSparkleFactory._program!.fragmentShader();
      _fragmentShaderInitialized = true;
    }

    canvas.save();
    _transformCanvas(canvas: canvas, transform: transform);
    if (_clipCallback != null) {
      _clipCanvas(
        canvas: canvas,
        clipCallback: _clipCallback,
        textDirection: _textDirection,
        customBorder: customBorder,
        borderRadius: _borderRadius,
      );
    }

    // canvas.drawRect((Offset.zero & referenceBox.size).inflate(8.0), Paint()..color = Colors.red);

    _updateFragmentShader();

    final Paint paint = Paint()..shader = _fragmentShader;
    if (_clipCallback != null) {
      canvas.drawRect(_clipCallback(), paint);
    } else {
      canvas.drawPaint(paint);
    }
    canvas.restore();
  }

  double get _width => referenceBox.size.width;
  double get _height => referenceBox.size.height;

  /// All double values for uniforms come from the Android 12 ripple
  /// implementation from the following files:
  /// - https://cs.android.com/android/platform/superproject/+/main:frameworks/base/graphics/java/android/graphics/drawable/RippleShader.java
  /// - https://cs.android.com/android/platform/superproject/+/main:frameworks/base/graphics/java/android/graphics/drawable/RippleDrawable.java
  /// - https://cs.android.com/android/platform/superproject/+/main:frameworks/base/graphics/java/android/graphics/drawable/RippleAnimationSession.java
  void _updateFragmentShader() {
    const double turbulenceScale = 1.5;
    final double turbulencePhase = _turbulenceSeed + _radiusScale.value;
    final double noisePhase = turbulencePhase;
    final double rotation1 = turbulencePhase * _rotateRight + 1.7 * math.pi;
    final double rotation2 = turbulencePhase * _rotateLeft + 2.0 * math.pi;
    final double rotation3 = turbulencePhase * _rotateRight + 2.75 * math.pi;

    _fragmentShader
      // uColor
      ..setFloat(0, _color.red / 255.0)
      ..setFloat(1, _color.green / 255.0)
      ..setFloat(2, _color.blue / 255.0)
      ..setFloat(3, _color.alpha / 255.0)
      // Composite 1 (u_alpha, u_sparkle_alpha, u_blur, u_radius_scale)
      ..setFloat(4, _alpha.value)
      ..setFloat(5, _sparkleAlpha.value)
      ..setFloat(6, 1.0)
      ..setFloat(7, _radiusScale.value)
      // uCenter
      ..setFloat(8, _center.value.x)
      ..setFloat(9, _center.value.y)
      // uMaxRadius
      ..setFloat(10, _targetRadius)
      // uResolutionScale
      ..setFloat(11, 1.0 / _width)
      ..setFloat(12, 1.0 / _height)
      // uNoiseScale
      ..setFloat(13, _noiseDensity / _width)
      ..setFloat(14, _noiseDensity / _height)
      // uNoisePhase
      ..setFloat(15, noisePhase / 1000.0)
      // uCircle1
      ..setFloat(
        16,
        turbulenceScale * 0.5 + (turbulencePhase * 0.01 * math.cos(turbulenceScale * 0.55)),
      )
      ..setFloat(
        17,
        turbulenceScale * 0.5 + (turbulencePhase * 0.01 * math.sin(turbulenceScale * 0.55)),
      )
      // uCircle2
      ..setFloat(
        18,
        turbulenceScale * 0.2 + (turbulencePhase * -0.0066 * math.cos(turbulenceScale * 0.45)),
      )
      ..setFloat(
        19,
        turbulenceScale * 0.2 + (turbulencePhase * -0.0066 * math.sin(turbulenceScale * 0.45)),
      )
      // uCircle3
      ..setFloat(
        20,
        turbulenceScale + (turbulencePhase * -0.0066 * math.cos(turbulenceScale * 0.35)),
      )
      ..setFloat(
        21,
        turbulenceScale + (turbulencePhase * -0.0066 * math.sin(turbulenceScale * 0.35)),
      )
      // uRotation1
      ..setFloat(22, math.cos(rotation1))
      ..setFloat(23, math.sin(rotation1))
      // uRotation2
      ..setFloat(24, math.cos(rotation2))
      ..setFloat(25, math.sin(rotation2))
      // uRotation3
      ..setFloat(26, math.cos(rotation3))
      ..setFloat(27, math.sin(rotation3));
  }

  /// Transforms the canvas for an ink feature to be painted on the [canvas].
  ///
  /// This should be called before painting ink features that do not use
  /// [paintInkCircle].
  ///
  /// The [transform] argument is the [Matrix4] transform that typically
  /// shifts the coordinate space of the canvas to the space in which
  /// the ink feature is to be painted.
  ///
  /// For examples on how the function is used, see [InkSparkle] and [paintInkCircle].
  void _transformCanvas({required Canvas canvas, required Matrix4 transform}) {
    final Offset? originOffset = MatrixUtils.getAsTranslation(transform);
    if (originOffset == null) {
      canvas.transform(transform.storage);
    } else {
      canvas.translate(originOffset.dx, originOffset.dy);
    }
  }

  /// Clips the canvas for an ink feature to be painted on the [canvas].
  ///
  /// This should be called before painting ink features with [paintFeature]
  /// that do not use [paintInkCircle].
  ///
  /// The [clipCallback] is the callback used to obtain the [Rect] used for clipping
  /// the ink effect.
  ///
  /// If [clipCallback] is null, no clipping is performed on the ink circle.
  ///
  /// The [textDirection] is used by [customBorder] if it is non-null. This
  /// allows the [customBorder]'s path to be properly defined if the path was
  /// expressed in terms of "start" and "end" instead of "left" and "right".
  ///
  /// For examples on how the function is used, see [InkSparkle].
  void _clipCanvas({
    required Canvas canvas,
    required RectCallback clipCallback,
    TextDirection? textDirection,
    ShapeBorder? customBorder,
    BorderRadius borderRadius = BorderRadius.zero,
  }) {
    final Rect rect = clipCallback();
    if (customBorder != null) {
      canvas.clipPath(customBorder.getOuterPath(rect, textDirection: textDirection));
    } else if (borderRadius != BorderRadius.zero) {
      canvas.clipRRect(
        RRect.fromRectAndCorners(
          rect,
          topLeft: borderRadius.topLeft,
          topRight: borderRadius.topRight,
          bottomLeft: borderRadius.bottomLeft,
          bottomRight: borderRadius.bottomRight,
        ),
      );
    } else {
      canvas.clipRect(rect);
    }
  }
}

class _InkSparkleFactory extends InteractiveInkFeatureFactoryWithNoInkClip {
  const _InkSparkleFactory() : turbulenceSeed = null;

  const _InkSparkleFactory.constantTurbulenceSeed() : turbulenceSeed = _InkSparkleFactory.constantSeed;

  static const double constantSeed = 1337.0;

  static void initializeShader() {
    if (!_initCalled) {
      ui.FragmentProgram.fromAsset('shaders/ink_sparkle.frag').then((ui.FragmentProgram program) {
        _program = program;
      });
      _initCalled = true;
    }
  }

  static bool _initCalled = false;
  static ui.FragmentProgram? _program;

  final double? turbulenceSeed;

  @override
  InteractiveInkFeatureWithNoInkClip create({
    required MaterialInkControllerWithNoInkClip controller,
    required RenderBox referenceBox,
    required ui.Offset position,
    required ui.Color color,
    required ui.TextDirection textDirection,
    bool containedInkWell = false,
    RectCallback? rectCallback,
    BorderRadius? borderRadius,
    ShapeBorder? customBorder,
    double? radius,
    ui.VoidCallback? onRemoved,
  }) {
    return InkSparkleWithNoInkClip(
      controller: controller,
      referenceBox: referenceBox,
      position: position,
      color: color,
      textDirection: textDirection,
      containedInkWell: containedInkWell,
      rectCallback: rectCallback,
      borderRadius: borderRadius,
      customBorder: customBorder,
      radius: radius,
      onRemoved: onRemoved,
      turbulenceSeed: turbulenceSeed,
    );
  }
}

RectCallback? _getClipCallback(
  RenderBox referenceBox,
  bool containedInkWell,
  RectCallback? rectCallback,
) {
  if (rectCallback != null) {
    assert(containedInkWell);
    return rectCallback;
  }
  if (containedInkWell) {
    return () => Offset.zero & referenceBox.size;
  }
  return null;
}

double _getTargetRadius(
  RenderBox referenceBox,
  bool containedInkWell,
  RectCallback? rectCallback,
  Offset position,
) {
  final Size size = rectCallback != null ? rectCallback().size : referenceBox.size;
  final double d1 = size.bottomRight(Offset.zero).distance;
  final double d2 = (size.topRight(Offset.zero) - size.bottomLeft(Offset.zero)).distance;
  return math.max(d1, d2) / 2.0;
}

const Duration _kDefaultHighlightFadeDuration = Duration(milliseconds: 200);

class InkHighlightWithNoInkClip extends InteractiveInkFeatureWithNoInkClip {
  InkHighlightWithNoInkClip({
    required super.controller,
    required super.referenceBox,
    required super.color,
    required TextDirection textDirection,
    BoxShape shape = BoxShape.rectangle,
    double? radius,
    BorderRadius? borderRadius,
    super.customBorder,
    RectCallback? rectCallback,
    super.onRemoved,
    Duration fadeDuration = _kDefaultHighlightFadeDuration,
  }) : _shape = shape,
       _radius = radius,
       _borderRadius = borderRadius ?? BorderRadius.zero,

       _textDirection = textDirection,
       _rectCallback = rectCallback {
    _alphaController =
        AnimationController(duration: fadeDuration, vsync: controller.vsync)
          ..addListener(controller.markNeedsPaint)
          ..addStatusListener(_handleAlphaStatusChanged)
          ..forward();
    _alpha = _alphaController.drive(IntTween(begin: 0, end: color.alpha));

    controller.addInkFeature(this);
  }

  final BoxShape _shape;
  final double? _radius;
  final BorderRadius _borderRadius;
  final RectCallback? _rectCallback;
  final TextDirection _textDirection;

  late Animation<int> _alpha;
  late AnimationController _alphaController;

  /// Whether this part of the material is being visually emphasized.
  bool get active => _active;
  bool _active = true;

  /// Start visually emphasizing this part of the material.
  void activate() {
    _active = true;
    _alphaController.forward();
  }

  /// Stop visually emphasizing this part of the material.
  void deactivate() {
    _active = false;
    _alphaController.reverse();
  }

  void _handleAlphaStatusChanged(AnimationStatus status) {
    if (status.isDismissed && !_active) {
      dispose();
    }
  }

  @override
  void dispose() {
    _alphaController.dispose();
    super.dispose();
  }

  void _paintHighlight(Canvas canvas, Rect rect, Paint paint) {
    canvas.save();
    if (customBorder != null) {
      canvas.clipPath(customBorder!.getOuterPath(rect, textDirection: _textDirection));
    }
    switch (_shape) {
      case BoxShape.circle:
        canvas.drawCircle(rect.center, _radius ?? Material.defaultSplashRadius, paint);
      case BoxShape.rectangle:
        if (_borderRadius != BorderRadius.zero) {
          final RRect clipRRect = RRect.fromRectAndCorners(
            rect,
            topLeft: _borderRadius.topLeft,
            topRight: _borderRadius.topRight,
            bottomLeft: _borderRadius.bottomLeft,
            bottomRight: _borderRadius.bottomRight,
          );
          canvas.drawRRect(clipRRect, paint);
        } else {
          canvas.drawRect(rect, paint);
        }
    }
    canvas.restore();
  }

  @override
  void paintFeature(Canvas canvas, Matrix4 transform) {
    final Paint paint = Paint()..color = color.withAlpha(_alpha.value);
    final Offset? originOffset = MatrixUtils.getAsTranslation(transform);
    final Rect rect = _rectCallback != null ? _rectCallback() : Offset.zero & referenceBox.size;
    if (originOffset == null) {
      canvas.save();
      canvas.transform(transform.storage);
      _paintHighlight(canvas, rect, paint);
      canvas.restore();
    } else {
      _paintHighlight(canvas, rect.shift(originOffset), paint);
    }
  }
}
