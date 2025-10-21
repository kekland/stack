import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stack/stack.dart';

class RefreshControlWidget extends StatelessWidget {
  const RefreshControlWidget({
    super.key,
    this.onRefresh,
    required this.builder,
    this.edgeOffset,
  });

  final double? edgeOffset;
  final Future<void> Function()? onRefresh;
  final Widget Function(BuildContext context, Widget? refreshSliver) builder;

  @override
  Widget build(BuildContext context) {
    if (onRefresh == null) return builder(context, null);

    if (context.stack.platform == ThemePlatform.material) {
      return RefreshIndicator(
        onRefresh: onRefresh!,
        edgeOffset: edgeOffset ?? 0.0,
        child: builder(context, null),
      );
    } else {
      return builder(
        context,
        CupertinoSliverRefreshControl(
          onRefresh: onRefresh,
          builder: (context, state, pulledExtent, pullDistance, extent) {
            return Transform.translate(
              offset: Offset(0.0, edgeOffset ?? 0.0),
              child: CupertinoSliverRefreshControl.buildRefreshIndicator(
                context,
                state,
                pulledExtent,
                pullDistance,
                extent,
              ),
            );
          },
        ),
      );
    }
  }
}
