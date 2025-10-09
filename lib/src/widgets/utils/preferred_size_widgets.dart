import 'package:flutter/material.dart';

class PaddingPreferredSize extends StatelessWidget implements PreferredSizeWidget {
  const PaddingPreferredSize({
    super.key,
    required this.padding,
    this.child,
  });

  final EdgeInsets padding;
  final PreferredSizeWidget? child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: child ?? const SizedBox.shrink(),
    );
  }

  @override
  Size get preferredSize => padding.inflateSize(child?.preferredSize ?? Size.zero);
}

class ColumnPreferredSize extends StatelessWidget implements PreferredSizeWidget {
  const ColumnPreferredSize({
    super.key,
    required this.children,
    this.spacing = 0.0,
  });

  final List<PreferredSizeWidget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: spacing,
      children: children,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
      children.map((e) => e.preferredSize.height).reduce((a, b) => a + b) + spacing * (children.length - 1));
}
