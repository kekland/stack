// deferred_layout_builder
// Allows for a builder to be deferred until the given target RenderObject is laid out.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:stack_ui/stack_ui.dart';

const _kDebugDeferredLayoutBuilder = false;

int _scheduledSecondPasses = 0;
var _isSecondPass = false;
final _nodesNeedingLayoutCache = <RenderObject, bool>{};

/// A [LayoutBuilder] that can defer its layout until certain target [RenderObject]s have finished their layout.
class DeferredLayoutBuilder extends LayoutBuilder {
  const DeferredLayoutBuilder({
    super.key,
    required super.builder,
    required this.targets,
  });

  final List<RenderObject> targets;

  @override
  RenderDeferredLayoutBuilder createRenderObject(BuildContext context) {
    return RenderDeferredLayoutBuilder()..targets = targets;
  }

  @override
  void updateRenderObject(BuildContext context, RenderDeferredLayoutBuilder renderObject) {
    renderObject.targets = targets;
  }
}

class RenderDeferredLayoutBuilder extends RenderBox
    with
        RenderObjectWithChildMixin<RenderBox>,
        RenderObjectWithLayoutCallbackMixin,
        RenderAbstractLayoutBuilderMixin<BoxConstraints, RenderBox> {
  late List<RenderObject> _targets;
  List<RenderObject> get targets => _targets;
  set targets(List<RenderObject> value) {
    _targets = value;
    markNeedsLayout();
  }

  StackRootPipelineOwner get _rootOwner => StackWidgetsFlutterBinding.instance.rootPipelineOwner;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _rootOwner.addPreFlushLayoutListener(_onPreFlushLayout);
    _rootOwner.addPostFlushLayoutListener(_onPostFlushLayout);
  }

  @override
  void detach() {
    _rootOwner.removePreFlushLayoutListener(_onPreFlushLayout);
    _rootOwner.removePostFlushLayoutListener(_onPostFlushLayout);

    if (_willDeferLayout) {
      _scheduledSecondPasses--;
      _willDeferLayout = false;
    }

    super.detach();
  }

  var _willDeferLayout = false;

  bool _maybeLog(String message) {
    if (_kDebugDeferredLayoutBuilder) debugPrint('DeferredLayoutBuilder: $message');
    return true;
  }

  void _onPreFlushLayout() {
    if (_isSecondPass || owner == null) return;
    _willDeferLayout = false;

    // If our targets are marked as needing layout - then we will defer our layout.
    for (final target in _targets) {
      final targetOwner = target.owner;
      if (targetOwner == null) continue;

      // Check the cache first.
      // final cachedValue = _nodesNeedingLayoutCache[target];
      // if (cachedValue == true) {
      //   _willDeferLayout = true;
      //   _scheduledSecondPasses++;
      //   return;
      // } else if (cachedValue == false) {
      //   continue;
      // }

      // Nodes needing layout are the relayout boundaries. We need to check if the target is a descendant of any of
      // those boundaries.
      // ignore: invalid_use_of_protected_member
      final nodesNeedingLayout = targetOwner.nodesNeedingLayout;

      var targetNeedsLayout = false;
      RenderObject? current = target;
      while (current != null) {
        if (nodesNeedingLayout.contains(current)) {
          targetNeedsLayout = true;
          break;
        }
        current = current.parent;
      }

      _nodesNeedingLayoutCache[target] = targetNeedsLayout;
      if (targetNeedsLayout) {
        _willDeferLayout = true;
        _scheduledSecondPasses++;
        return;
      }
    }
  }

  void _onPostFlushLayout() {
    if (_isSecondPass || owner == null) return;
    assert(_maybeLog('_onFlushLayoutEnd: will relayout (second pass): $_willDeferLayout ($_scheduledSecondPasses)'));

    if (_willDeferLayout) {
      // When the primary flush finishes - if we have a scheduled deferred layout, mark ourselves as dirty.
      markNeedsLayout();
      _willDeferLayout = false;

      // Once all of the scheduled deferred layouts have been marked dirty, we can start the second pass on this frame.
      _scheduledSecondPasses--;
      if (_scheduledSecondPasses == 0) {
        assert(_maybeLog('== starting second pass =='));
        _isSecondPass = true;
        _rootOwner.flushLayout();
        _isSecondPass = false;
        _nodesNeedingLayoutCache.clear();
        assert(_maybeLog('== finished second pass =='));
      }
    }
  }

  @override
  void layout(Constraints constraints, {bool parentUsesSize = false}) {
    assert(_maybeLog('layout called: will defer layout: $_willDeferLayout'));
    super.layout(constraints, parentUsesSize: parentUsesSize);
  }

  late BoxConstraints _layoutInfo;

  @override
  BoxConstraints get layoutInfo => _layoutInfo;

  // --
  // The rest of this class is copied from _RenderLayoutBuilder.
  // Change: performLayout is overridden to ignore layout if we're deferring.
  // --

  @override
  double computeMinIntrinsicWidth(double height) {
    assert(_debugThrowIfNotCheckingIntrinsics());
    return 0.0;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    assert(_debugThrowIfNotCheckingIntrinsics());
    return 0.0;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    assert(_debugThrowIfNotCheckingIntrinsics());
    return 0.0;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    assert(_debugThrowIfNotCheckingIntrinsics());
    return 0.0;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    assert(
      debugCannotComputeDryLayout(
        reason:
            'Calculating the dry layout would require running the layout callback '
            'speculatively, which might mutate the live render object tree.',
      ),
    );
    return Size.zero;
  }

  @override
  double? computeDryBaseline(BoxConstraints constraints, TextBaseline baseline) {
    assert(
      debugCannotComputeDryLayout(
        reason:
            'Calculating the dry baseline would require running the layout callback '
            'speculatively, which might mutate the live render object tree.',
      ),
    );
    return null;
  }

  BoxConstraints? _lastConstraints;

  @override
  void performLayout() {
    final BoxConstraints constraints = this.constraints;

    // If we're deferring the layout, and the constraints haven't changed - skip the layout for now.
    if (_willDeferLayout && constraints == _lastConstraints) return;
    _layoutInfo = _isSecondPass ? _NonEqualBoxConstraints(constraints) : constraints;

    _lastConstraints = constraints;
    runLayoutCallback();
    if (child != null) {
      child!.layout(constraints, parentUsesSize: true);
      size = constraints.constrain(child!.size);
    } else {
      size = constraints.biggest;
    }
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    return child?.getDistanceToActualBaseline(baseline) ?? super.computeDistanceToActualBaseline(baseline);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return child?.hitTest(result, position: position) ?? false;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      context.paintChild(child!, offset);
    }
  }

  bool _debugThrowIfNotCheckingIntrinsics() {
    assert(() {
      if (!RenderObject.debugCheckingIntrinsics) {
        throw FlutterError(
          'DeferredLayoutBuilder does not support returning intrinsic dimensions.\n'
          'Calculating the intrinsic dimensions would require running the layout '
          'callback speculatively, which might mutate the live render object tree.',
        );
      }
      return true;
    }());

    return true;
  }
}

class _NonEqualBoxConstraints extends BoxConstraints {
  _NonEqualBoxConstraints(BoxConstraints parent)
    : super(
        minWidth: parent.minWidth,
        maxWidth: parent.maxWidth,
        minHeight: parent.minHeight,
        maxHeight: parent.maxHeight,
      );

  @override
  bool operator ==(Object other) => identical(this, other);

  @override
  int get hashCode => identityHashCode(this);
}
