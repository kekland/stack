import 'dart:async';

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

class _FunctionalTween<T> extends Tween<T> {
  _FunctionalTween({
    required super.begin,
    required super.end,
    required T? Function(T? a, T? b, double t) lerp,
  }) : _lerp = lerp;

  final T? Function(T? a, T? b, double t) _lerp;

  @override
  T lerp(double t) {
    if (t == 0.0) return begin!;
    if (t == 1.0) return end!;

    return _lerp(begin, end, t)!;
  }
}

T useImplicitAnimation<T>(
  T value, {
  required AnimationStyle? animationStyle,
  T? Function(T? a, T? b, double t)? lerp,
  VoidCallback? onEnd,
}) {
  final hasAnimation = animationStyle?.duration != null && animationStyle?.duration != Duration.zero;

  final animationController = useAnimationController(duration: animationStyle?.duration);
  final animation = useMemoized(
    () => CurvedAnimation(parent: animationController, curve: animationStyle?.curve ?? Curves.linear),
    [animationStyle],
  );

  final tween = useValueChanged<T, Tween<T>>(value, (previousValue, previousTween) {
    if (!hasAnimation) return null;
    final Tween<T> result;

    if (lerp != null) {
      result = _FunctionalTween<T>(begin: previousTween?.evaluate(animation) ?? previousValue, end: value, lerp: lerp);
    } else {
      result = Tween<T>(begin: previousTween?.evaluate(animation) ?? previousValue, end: value);
    }

    animationController.forward(from: 0.0).then((_) => onEnd?.call());
    return result;
  });

  final animationValue = useAnimation(animation);

  if (tween == null || !hasAnimation) {
    return value;
  } else {
    return tween.transform(animationValue);
  }
}

void useTimerPeriodic(Duration duration, VoidCallback callback) {
  useEffect(() {
    final timer = Timer.periodic(duration, (_) => callback());
    return timer.cancel;
  }, [duration, callback]);
}

GlobalKey<FormState> useFormKey() {
  return useMemoized(() => GlobalKey<FormState>());
}

extension ValueNotifierSetterFn<T> on ValueNotifier<T> {
  void $set(T value) {
    this.value = value;
  }

  void $setUnsafe(dynamic value) {
    this.value = value as T;
  }
}

void useCallOnce(VoidCallback callback) {
  useEffect(() {
    callback();
    return null;
  }, const []);
}
