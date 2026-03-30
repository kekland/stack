import 'package:flutter/widgets.dart';

class InheritedFormKey extends InheritedWidget {
  const InheritedFormKey({
    super.key,
    required this.formKey,
    required super.child,
  });

  final GlobalKey<FormState> formKey;

  static GlobalKey<FormState>? maybeOf(BuildContext context) {
    final inheritedFormKey = context.dependOnInheritedWidgetOfExactType<InheritedFormKey>();
    return inheritedFormKey?.formKey;
  }

  static GlobalKey<FormState> of(BuildContext context) => maybeOf(context)!;

  @override
  bool updateShouldNotify(InheritedFormKey oldWidget) => false;
}
