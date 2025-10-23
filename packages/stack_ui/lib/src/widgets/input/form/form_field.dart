import 'package:flutter/widgets.dart';

class StFormField<T> extends FormField<T> {
  const StFormField({
    super.key,
    required super.builder,
    this.onChanged,
    super.enabled,
    super.autovalidateMode,
    super.initialValue,
    super.validator,
    this.shouldRevalidateIfError = true,
  });

  final ValueChanged<T?>? onChanged;
  final bool shouldRevalidateIfError;

  static InheritedStFormFieldState? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<InheritedStFormFieldState>();
  }

  @override
  FormFieldState<T> createState() => StFormFieldState<T>();
}

class StFormFieldState<T> extends FormFieldState<T> {
  @override
  StFormField<T> get widget => super.widget as StFormField<T>;

  bool _hadError = false;

  void maybeRevalidate(FormFieldState state) {
    _hadError |= state.hasError;

    if (widget.shouldRevalidateIfError && _hadError) {
      state.validate();
    }
  }

  @override
  void didChange(T? value) {
    super.didChange(value);
    widget.onChanged?.call(value);
    maybeRevalidate(this);
  }

  @override
  Widget build(BuildContext context) {
    return InheritedStFormFieldState(
      errorText: errorText,
      child: super.build(context),
    );
  }
}

class InheritedStFormFieldState extends InheritedWidget {
  const InheritedStFormFieldState({
    super.key,
    required this.errorText,
    required super.child,
  });

  final String? errorText;

  bool get hasError => errorText != null;

  @override
  bool updateShouldNotify(InheritedStFormFieldState oldWidget) {
    return errorText != oldWidget.errorText;
  }
}
