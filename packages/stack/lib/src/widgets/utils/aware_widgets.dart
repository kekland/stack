import 'package:flutter/widgets.dart';
import 'package:stack/stack.dart';

class InheritedSurroundings<T extends Widget> extends InheritedWidget {
  const InheritedSurroundings({
    super.key,
    required super.child,
    required this.left,
    required this.right,
    required this.top,
    required this.bottom,
    this.topLeft,
    this.topRight,
    this.bottomLeft,
    this.bottomRight,
  });

  static InheritedSurroundings<T>? maybeOf<T extends Widget>(
    BuildContext context,
  ) {
    return context
        .dependOnInheritedWidgetOfExactType<InheritedSurroundings<T>>();
  }

  final T? left;
  final T? right;
  final T? top;
  final T? bottom;
  final T? topLeft;
  final T? topRight;
  final T? bottomLeft;
  final T? bottomRight;

  @override
  bool updateShouldNotify(InheritedSurroundings oldWidget) =>
      left != oldWidget.left ||
      right != oldWidget.right ||
      top != oldWidget.top ||
      bottom != oldWidget.bottom ||
      topLeft != oldWidget.topLeft ||
      topRight != oldWidget.topRight ||
      bottomLeft != oldWidget.bottomLeft ||
      bottomRight != oldWidget.bottomRight;
}

class FlexAware<T extends Widget> extends StatelessWidget {
  const FlexAware({
    super.key,
    required this.direction,
    required this.children,
    this.spacing = 0.0,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
  });

  final Axis direction;
  final List<Widget> children;
  final double spacing;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;

  T? _unwrapChild(Widget child) {
    Widget? current = child;

    while (current is! T) {
      if (current is Expanded) {
        current = current.child;
      } else if (current is Flexible) {
        current = current.child;
      } else if (current is Padding) {
        current = current.child;
      } else if (current is Align) {
        current = current.child;
      } else if (current is SizedBox) {
        current = current.child;
      } else if (current is AwareUnwrappable) {
        current = current.child;
      } else if (current is PreferredSize) {
        current = current.child;
      } else if (current is StAnimatedSizeSwitcher) {
        current = current.child;
      } else {
        return null;
      }
    }

    return current;
  }

  @override
  Widget build(BuildContext context) {
    final unwrappedChildren = children.map(_unwrapChild).toList();
    final childrenWithData = <Widget>[];

    for (var i = 0; i < children.length; i++) {
      final previous = i > 0 ? unwrappedChildren[i - 1] : null;
      final next = i < children.length - 1 ? unwrappedChildren[i + 1] : null;

      T? above, below, left, right;
      if (direction == Axis.horizontal) {
        left = previous;
        right = next;
      } else {
        above = previous;
        below = next;
      }

      childrenWithData.add(
        InheritedSurroundings<T>(
          left: left,
          right: right,
          top: above,
          bottom: below,
          child: children[i],
        ),
      );
    }

    return Flex(
      direction: direction,
      spacing: spacing,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: childrenWithData,
    );
  }
}

mixin AwareUnwrappable on Widget {
  Widget get child;
}
