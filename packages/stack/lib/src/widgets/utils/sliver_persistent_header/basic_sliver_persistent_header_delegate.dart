import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class BasicSliverPersistentHeaderDelegate extends SliverPersistentHeaderDelegate {
  BasicSliverPersistentHeaderDelegate({
    required this.maxExtent,
    required this.minExtent,
    required this.child,
  });

  BasicSliverPersistentHeaderDelegate.static({
    required double extent,
    required this.child,
  })  : minExtent = extent,
        maxExtent = extent;

  BasicSliverPersistentHeaderDelegate.preferredSize({
    required PreferredSizeWidget this.child,
  })  : minExtent = child.preferredSize.height,
        maxExtent = child.preferredSize.height;

  @override
  final double maxExtent;

  @override
  final double minExtent;

  final Widget child;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    if (maxExtent == minExtent) return child;

    return OverflowBox(
      fit: OverflowBoxFit.deferToChild,
      alignment: Alignment.bottomLeft,
      minWidth: minExtent,
      maxHeight: maxExtent,
      child: child,
    );
  }

  @override
  bool shouldRebuild(BasicSliverPersistentHeaderDelegate oldDelegate) =>
      oldDelegate.minExtent != minExtent || oldDelegate.maxExtent != maxExtent || oldDelegate.child != child;
}

class PaddingSliverPersistentHeaderDelegate extends SliverPersistentHeaderDelegate {
  PaddingSliverPersistentHeaderDelegate({required this.padding, required this.delegate});

  final EdgeInsets padding;
  final SliverPersistentHeaderDelegate delegate;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Padding(
      padding: padding,
      child: delegate.build(context, shrinkOffset, overlapsContent),
    );
  }

  @override
  double get maxExtent => delegate.maxExtent + padding.vertical;

  @override
  double get minExtent => delegate.minExtent + padding.vertical;

  @override
  bool shouldRebuild(PaddingSliverPersistentHeaderDelegate oldDelegate) =>
      oldDelegate.padding != padding || oldDelegate.delegate != delegate;
}

class SpacerSliverPersistentHeaderDelegate extends SliverPersistentHeaderDelegate {
  SpacerSliverPersistentHeaderDelegate({required this.spacing});

  final double spacing;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox(height: spacing);
  }

  @override
  double get maxExtent => spacing;

  @override
  double get minExtent => spacing;

  @override
  bool shouldRebuild(SpacerSliverPersistentHeaderDelegate oldDelegate) => oldDelegate.spacing != spacing;
}
