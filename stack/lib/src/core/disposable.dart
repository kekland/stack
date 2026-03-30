import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:signals_flutter/signals_flutter.dart' as signals;

class _Disposable {
  bool isDisposed = false;

  final _disposeCallbacks = <VoidCallback>{};

  void addDisposeCallback(VoidCallback callback) {
    _disposeCallbacks.add(callback);
  }

  void dispose() {
    if (isDisposed) throw StateError('Already disposed');

    for (final disposeCallback in _disposeCallbacks) disposeCallback();
    _disposeCallbacks.clear();

    isDisposed = true;
  }
}

/// A mixin that automates the disposal of various objects.
///
/// Use extensions to add additional disposable types as needed. Methods that produce disposable objects should be
/// prefixed with `$`.
mixin Disposable {
  final _d = _Disposable();

  /// Whether this object has been disposed.
  bool get isDisposed => _d.isDisposed;
  void addDisposeCallback(VoidCallback callback) => _d.addDisposeCallback(callback);

  @mustCallSuper
  void dispose() => _d.dispose();
}

mixin ChangeNotifierDisposable on ChangeNotifier implements Disposable {
  @override
  final _d = _Disposable();

  /// Registers an automatic [notifyListeners] call whenever any of the given [signals] change.
  void notifyListenersOn(List<signals.Signal> signals) {
    for (final signal in signals) {
      $effect(() {
        signal.value;
        notifyListeners();
      });
    }
  }

  @override
  bool get isDisposed => _d.isDisposed;

  @override
  void addDisposeCallback(VoidCallback callback) => _d.addDisposeCallback(callback);

  @override
  void dispose() {
    _d.dispose();
    super.dispose();
  }
}

extension DisposableDisposableExt on Disposable {
  /// Creates a [Disposable] that is automatically disposed of when this object is disposed.
  T $disposable<T extends Disposable>(T disposable) {
    addDisposeCallback(disposable.dispose);
    return disposable;
  }
}

extension HttpDisposableExt on Disposable {
  /// Creates an [http.Client] that is automatically closed when this object is disposed.
  http.Client $httpClient() {
    final client = http.Client();
    addDisposeCallback(client.close);
    return client;
  }
}

extension StreamDisposableExt on Disposable {
  /// Adds a [StreamSubscription] to be automatically cancelled when this object is disposed.
  void $streamListen<T>(
    Stream<T> stream,
    void Function(T) onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final subscription = stream.listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
    addDisposeCallback(subscription.cancel);
  }

  StreamController<T> $streamController<T>({bool sync = false}) {
    final controller = StreamController<T>(sync: sync);
    addDisposeCallback(controller.close);
    return controller;
  }

  StreamController<T> $streamControllerBroadcast<T>({bool sync = false}) {
    final controller = StreamController<T>.broadcast(sync: sync);
    addDisposeCallback(controller.close);
    return controller;
  }
}

extension SignalDisposableExt on Disposable {
  /// Creates a [signals.Signal] that is automatically disposed of when this object is disposed.
  signals.FlutterSignal<T> $signal<T>(T initialValue) {
    final signal = signals.signal<T>(initialValue);
    addDisposeCallback(signal.dispose);
    return signal;
  }

  /// Creates a [signals.Effect] that is automatically disposed of when this object is disposed.
  void $effect(void Function() effect) {
    final dispose = signals.effect(effect);
    addDisposeCallback(dispose);
  }

  /// Creates a [signals.Computed] that is automatically disposed of when this object is disposed.
  signals.FlutterComputed<T> $computed<T>(T Function() compute) {
    final computed = signals.computed<T>(compute);
    addDisposeCallback(computed.dispose);
    return computed;
  }

  /// Creates a [signals.ListSignal] that is automatically disposed of when this object is disposed.
  signals.ListSignal<T> $listSignal<T>(List<T> initialValue) {
    final listSignal = signals.listSignal<T>(initialValue);
    addDisposeCallback(listSignal.dispose);
    return listSignal;
  }

  /// Creates a [signals.MapSignal] that is automatically disposed of when this object is disposed.
  signals.MapSignal<K, V> $mapSignal<K, V>(Map<K, V> initialValue) {
    final mapSignal = signals.mapSignal<K, V>(initialValue);
    addDisposeCallback(mapSignal.dispose);
    return mapSignal;
  }

  /// Creates a [signals.SetSignal] that is automatically disposed of when this object is disposed.
  signals.SetSignal<T> $setSignal<T>(Set<T> initialValue) {
    final setSignal = signals.setSignal<T>(initialValue);
    addDisposeCallback(setSignal.dispose);
    return setSignal;
  }
}

extension ValueNotifierDisposable on Disposable {
  ValueNotifier<T> $valueNotifier<T>(T initialValue) {
    final notifier = ValueNotifier<T>(initialValue);
    addDisposeCallback(notifier.dispose);
    return notifier;
  }
}
