import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

HeroController useHeroController() {
  final controller = useMemoized(() => HeroController());
  useEffect(() => controller.dispose, [controller]);
  return controller;
}

T useManagedResource<T>({
  T? value,
  required T Function() create,
  required void Function(T value) dispose,
  List<Object?>? keys,
}) {
  return use(
    _ManagedResourceHook<T>(
      value: value,
      create: create,
      dispose: dispose,
      keys: keys,
    ),
  );
}

class _ManagedResourceHook<T> extends Hook<T> {
  const _ManagedResourceHook({
    super.keys,
    required this.value,
    required this.create,
    required this.dispose,
  });

  final T? value;
  final T Function() create;
  final void Function(T value) dispose;

  @override
  HookState<T, Hook<T>> createState() => _ManagedResourceHookState();
}

class _ManagedResourceHookState<T> extends HookState<T, _ManagedResourceHook<T>> {
  late T value;

  @override
  void initHook() {
    super.initHook();
    value = hook.value ?? hook.create();
  }

  @override
  void didUpdateHook(_ManagedResourceHook<T> oldHook) {
    super.didUpdateHook(oldHook);

    if (oldHook.value != hook.value) {
      if (oldHook.value == null) hook.dispose(value);
      value = hook.value ?? hook.create();
    }
  }

  @override
  void dispose() {
    if (hook.value == null) hook.dispose(value);
    super.dispose();
  }

  @override
  T build(BuildContext context) => value;
}

void useListenerEffect(ChangeNotifier notifier, VoidCallback listener, {bool callImmediately = false}) {
  useEffect(() {
    notifier.addListener(listener);
    if (callImmediately) listener();

    return () => notifier.removeListener(listener);
  }, [notifier, listener]);
}

bool useFocusNodeHasFocus(FocusNode focusNode) {
  final hasFocus = useState(focusNode.hasFocus);
  useListenerEffect(focusNode, () => hasFocus.value = focusNode.hasFocus, callImmediately: true);

  return hasFocus.value;
}

bool useTextControllerIsEmpty(TextEditingController controller) {
  final isEmpty = useState(controller.text.isEmpty);
  useListenerEffect(controller, () => isEmpty.value = controller.text.isEmpty, callImmediately: true);

  return isEmpty.value;
}
