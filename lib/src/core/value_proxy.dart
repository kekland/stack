import 'package:flutter/foundation.dart';
import 'package:stack/stack.dart';

abstract class ValueProxy<T> extends Signal<T> with Disposable {
  ValueProxy(T value) : super(value) {
    _dispatcher = di.dispatcherFor<T>();
    _dispatcher.bind(this);
    $streamListen(_dispatcher.eventStreamForId(id), $onValueEvent);
  }

  late final ValueDispatcher<T> _dispatcher;

  Object get id => _dispatcher.identify(value);

  void $dispatchUpdate() {
    _dispatcher.dispatchUpdate(this, value);
  }

  @protected
  void $onValueEvent(ValueEvent<T> event) {
    if (event is ValueFetchEvent<T>) {
      value = event.value;
    } else if (event is ValueUpdateEvent<T>) {
      value = event.value;
    }
  }

  @override
  void dispose() {
    _dispatcher.unbind(this);
    super.dispose();
  }
}
