import 'package:flutter/widgets.dart';
import 'package:stack/stack.dart';

class ValueSourceBuilder<T> extends HookWidget {
  const ValueSourceBuilder({
    super.key,
    required this.valueSource,
    required this.valueBuilder,
    this.initialStateBuilder,
    this.loadingBuilder,
    this.errorBuilder,
    this.emptyBuilder,
    this.defaultWidget = const SizedBox.shrink(),
  });

  final ValueSource<T> valueSource;
  final WidgetBuilder? initialStateBuilder;
  final Widget Function(BuildContext context, Object? error)? loadingBuilder;
  final Widget Function(BuildContext context, Object error)? errorBuilder;
  final Widget Function(BuildContext context, bool isLoading, Object? error) valueBuilder;
  final Widget Function(BuildContext context)? emptyBuilder;
  final Widget defaultWidget;

  @override
  Widget build(BuildContext context) {
    final isInitialState = useExistingSignal(valueSource.isInitialStateSignal).value;
    final hasValue = useExistingSignal(valueSource.hasValueSignal).value;
    final isLoading = useExistingSignal(valueSource.isLoadingSignal).value;
    final error = useExistingSignal(valueSource.errorSignal).value;

    // Cases are as follows:
    // - Initial state: show [initialStateBuilder]
    // - No value, no loading, no error: show [emptyBuilder]
    // - No value, loading, no error: show [loadingBuilder]
    // - No value, no loading, error: show [errorBuilder]
    // - No value, loading, error: show [loadingBuilder]
    // - Value, no loading, no error: show [valueBuilder]
    // - Value, loading, no error: show [valueBuilder]
    // - Value, no loading, error: show [valueBuilder]
    // - Value, loading, error: show [valueBuilder]

    if (isInitialState) {
      return initialStateBuilder?.call(context) ?? defaultWidget;
    } else {
      if (!hasValue) {
        if (isLoading) {
          return loadingBuilder?.call(context, error) ?? defaultWidget;
        } else if (error != null) {
          return errorBuilder?.call(context, error) ?? defaultWidget;
        } else {
          return emptyBuilder?.call(context) ?? defaultWidget;
        }
      } else {
        return valueBuilder(context, isLoading, error);
      }
    }
  }
}
