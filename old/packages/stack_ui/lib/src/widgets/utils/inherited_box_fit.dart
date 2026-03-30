import 'package:flutter/widgets.dart';

class InheritedBoxFit extends InheritedWidget {
  const InheritedBoxFit({
    super.key,
    required super.child,
    required this.fit,
  });

  static BoxFit? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<InheritedBoxFit>()?.fit;
  static BoxFit of(BuildContext context) => maybeOf(context)!;

  final BoxFit fit;

  @override
  bool updateShouldNotify(covariant InheritedBoxFit oldWidget) => fit != oldWidget.fit;
}
