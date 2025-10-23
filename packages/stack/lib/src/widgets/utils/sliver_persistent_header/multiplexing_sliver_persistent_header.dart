import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:stack/stack.dart';

const kDebugShowMultiplexingSliverBoundaries = false;

class MultiplexingSliverPersistentHeaderDelegate
    extends SliverPersistentHeaderDelegate {
  MultiplexingSliverPersistentHeaderDelegate({
    required this.delegates,
    this.wrapperBuilder,
  });

  final List<SliverPersistentHeaderDelegate> delegates;
  final Widget Function(BuildContext context, Widget child)? wrapperBuilder;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final extent = (maxExtent - shrinkOffset).clamp(minExtent, maxExtent);
    var flexibleExtent = extent - minExtent;
    final extents = delegates.map((v) => v.minExtent).toList();

    // Grow from first until flexible extent is reached
    for (var i = 0; i < extents.length; i++) {
      final delegate = delegates[i];
      var delegateGrow = delegate.maxExtent - delegate.minExtent;
      delegateGrow = min(delegateGrow, flexibleExtent);
      flexibleExtent -= delegateGrow;
      extents[i] += delegateGrow;

      if (flexibleExtent <= 0) {
        break;
      }
    }

    var children = List<Widget>.generate(
      extents.length,
      (i) => ClipRect(
        child: SizedBox(
          height: extents[i],
          child: delegates[i].build(
            context,
            max(0, delegates[i].maxExtent - extents[i]),
            overlapsContent,
          ),
        ),
      ),
    );

    if (kDebugMode && kDebugShowMultiplexingSliverBoundaries) {
      children = children
          .mapIndexed(
            (i, v) => ColoredBox(
              color: Colors.primaries[i % Colors.primaries.length]
                  .withMultipliedOpacity(0.2),
              child: v,
            ),
          )
          .toList();
    }

    // Layout children with the calculated extents
    Widget child = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );

    if (wrapperBuilder != null) child = wrapperBuilder!(context, child);

    return child;
  }

  @override
  double get maxExtent => delegates.map((v) => v.maxExtent).sum;

  @override
  double get minExtent => delegates.map((v) => v.minExtent).sum;

  @override
  PersistentHeaderShowOnScreenConfiguration? get showOnScreenConfiguration =>
      PersistentHeaderShowOnScreenConfiguration(
        minShowOnScreenExtent: minExtent,
        maxShowOnScreenExtent: maxExtent,
      );

  @override
  bool shouldRebuild(MultiplexingSliverPersistentHeaderDelegate oldDelegate) =>
      !listEquals(oldDelegate.delegates, delegates);
}
