import '../../stack.dart';

T useComputedValue<T>(T Function() getter) {
  return useComputed(getter).value;
}

T useDisposable<T extends Disposable>(T Function() create, [List<Object?> keys = const []]) {
  final disposable = useMemoized(create, keys);

  useEffect(() {
    return disposable.dispose;
  }, [disposable]);

  return disposable;
}
