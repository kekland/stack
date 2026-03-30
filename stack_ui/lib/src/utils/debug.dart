import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

void copyRenderTreeDump() {
  final data = <String>[
    for (final RenderView renderView in RendererBinding.instance.renderViews) renderView.toStringDeep(),
  ].join('\n\n');

  Clipboard.setData(ClipboardData(text: data));
}
