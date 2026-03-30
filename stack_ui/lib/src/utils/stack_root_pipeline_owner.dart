import 'package:flutter/rendering.dart';

final class StackRootPipelineOwner extends PipelineOwner {
  final _preFlushLayoutListeners = <VoidCallback>{};
  void addPreFlushLayoutListener(VoidCallback l) => _preFlushLayoutListeners.add(l);
  void removePreFlushLayoutListener(VoidCallback l) => _preFlushLayoutListeners.remove(l);

  final _postFlushLayoutListeners = <VoidCallback>{};
  void addPostFlushLayoutListener(VoidCallback l) => _postFlushLayoutListeners.add(l);
  void removePostFlushLayoutListener(VoidCallback l) => _postFlushLayoutListeners.remove(l);

  @override
  void flushLayout() {
    for (final l in _preFlushLayoutListeners) l();
    super.flushLayout();
    for (final l in _postFlushLayoutListeners) l();
  }

  final _preFlushPaintListeners = <VoidCallback>{};
  void addPreFlushPaintListener(VoidCallback l) => _preFlushPaintListeners.add(l);
  void removePreFlushPaintListener(VoidCallback l) => _preFlushPaintListeners.remove(l);

  final _postFlushPaintListeners = <VoidCallback>{};
  void addPostFlushPaintListener(VoidCallback l) => _postFlushPaintListeners.add(l);
  void removePostFlushPaintListener(VoidCallback l) => _postFlushPaintListeners.remove(l);

  @override
  void flushPaint() {
    for (final l in _preFlushPaintListeners) l();
    super.flushPaint();
    for (final l in _postFlushPaintListeners) l();
  }

  @override
  set rootNode(RenderObject? _) {
    assert(() {
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('Cannot set a rootNode on the default root pipeline owner.'),
        ErrorDescription(
          'By default, the RendererBinding.rootPipelineOwner is not configured '
          'to manage a root node because this pipeline owner does not define a '
          'proper onSemanticsUpdate callback to handle semantics for that node.',
        ),
        ErrorHint(
          'Typically, the root pipeline owner does not manage a root node. '
          'Instead, properly configured child pipeline owners (which do manage '
          'root nodes) are added to it. Alternatively, if you do want to set a '
          'root node for the root pipeline owner, override '
          'RendererBinding.createRootPipelineOwner to create a '
          'pipeline owner that is configured to properly handle semantics for '
          'the provided root node.',
        ),
      ]);
    }());
  }
}
