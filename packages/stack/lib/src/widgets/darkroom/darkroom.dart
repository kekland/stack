import 'package:flutter/material.dart';
import 'package:stack/stack.dart';

typedef DarkroomWidgetBuilder =
    Widget Function(
      BuildContext context,
      ScopeContainer<DarkroomWidget>? scope,
      BoxFit? fit,
    );

class DarkroomWidget extends HookWidget {
  const DarkroomWidget({
    super.key,
    required this.builder,
  });

  final DarkroomWidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    final container = useScopedBinding(this);
    return builder(context, container, null);
  }
}

class DarkroomScope extends HookWidget {
  const DarkroomScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scopeContainer = useScopeContainer<DarkroomWidget>();

    return Scope<DarkroomWidget>(
      container: scopeContainer,
      child: child,
    );
  }
}
