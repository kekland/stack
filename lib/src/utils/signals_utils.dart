import 'package:stack/stack.dart';

T useComputedValue<T>(T Function() getter) {
  return useComputed(getter).value;
}

T useDisposable<T extends Disposable>(T Function() create) {
  final disposable = useMemoized(create);

  useEffect(() {
    return disposable.dispose;
  }, [disposable]);

  return disposable;
}
