import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:stack/stack.dart';

abstract class DragActivity {
  DragActivity();

  late final PositionedGestureDetails startDetails;
  DragUpdateDetails? lastUpdateDetails;
  PointerEvent? pointerEvent;

  @mustCallSuper
  void onStart(PositionedGestureDetails details) {
    startDetails = details;
  }

  @mustCallSuper
  void onUpdate(DragUpdateDetails details) {
    lastUpdateDetails = details;
  }

  void onEnd(DragEndDetails? details) {}
}

mixin KeyboardListenerDragActivity on DragActivity {
  Set<LogicalKeyboardKey> get keysToListen;

  @override
  void onStart(PositionedGestureDetails details) {
    super.onStart(details);
    HardwareKeyboard.instance.addHandler(_handler);
  }

  @override
  void onEnd(DragEndDetails? details) {
    HardwareKeyboard.instance.removeHandler(_handler);
    super.onEnd(details);
  }

  bool isKeyPressed(Set<LogicalKeyboardKey> keys) => keys.any((k) => HardwareKeyboard.instance.isLogicalKeyPressed(k));
  bool get isShiftPressed => HardwareKeyboard.instance.isShiftPressed;
  bool get isControlPressed => HardwareKeyboard.instance.isControlPressed;
  bool get isAltPressed => HardwareKeyboard.instance.isAltPressed;
  bool get isMetaPressed => HardwareKeyboard.instance.isMetaPressed;

  bool _handler(KeyEvent event) {
    if (lastUpdateDetails == null) return false;

    if (keysToListen.any((k) => event.logicalKey == k)) {
      onUpdate(lastUpdateDetails!);
      return true;
    }

    return false;
  }
}

typedef DragActivityFactory<T extends DragActivity> = T Function();
typedef DragActivityWithArgumentFactory<T extends DragActivity, A> = T Function(A argument);

mixin _DragActivityPointerCountLimiter on PanGestureRecognizer {
  final Set<int> _trackedPointers = <int>{};

  Set<PointerDeviceKind> get devicesToAcceptImmediately;

  bool get isActive;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    if (isActive) return;

    super.addAllowedPointer(event);
    _trackedPointers.add(event.pointer);

    if (_trackedPointers.length > 1) {
      for (final int pointer in _trackedPointers.toList()) {
        resolvePointer(pointer, .rejected);
        stopTrackingPointer(pointer);
      }

      _trackedPointers.clear();
    } else {
      // Instantly win the arena
      if (devicesToAcceptImmediately.contains(event.kind)) {
        resolvePointer(event.pointer, .accepted);
      }
    }
  }

  @override
  void handleEvent(PointerEvent event) {
    super.handleEvent(event);
    if (event is PointerUpEvent || event is PointerCancelEvent) {
      _trackedPointers.remove(event.pointer);
    }
  }

  @override
  void rejectGesture(int pointer) {
    _trackedPointers.remove(pointer);
    super.rejectGesture(pointer);
  }
}

mixin _DragActivityCommons<T extends DragActivity> on PanGestureRecognizer {
  T? get currentActivity;

  PointerEvent? _lastPointerEvent;
  
  void _onActivityCreated() {
    currentActivity!.pointerEvent = _lastPointerEvent;
  }

  @override
  void handleEvent(PointerEvent event) {
    _lastPointerEvent = event;
    currentActivity?.pointerEvent = event;
    super.handleEvent(event);
  }
}

class DragActivityGestureRecognizer<T extends DragActivity> extends PanGestureRecognizer
    with _DragActivityCommons, _DragActivityPointerCountLimiter {
  DragActivityGestureRecognizer({
    required this.activityFactory,
    super.debugOwner,
    super.supportedDevices,
    super.allowedButtonsFilter,
    VoidCallback? onStart,
    VoidCallback? onEnd,
    this.devicesToAcceptImmediately = const {},
  }) : _onStart = onStart,
       _onEnd = onEnd,
       super() {
    dragStartBehavior = .down;
    onlyAcceptDragOnThreshold = false;

    this.onStart = (details) {
      assert(_currentActivity == null);
      _currentActivity = activityFactory();
      _onActivityCreated();
      _currentActivity!.onStart(details);
      _onStart?.call();
    };

    onUpdate = (details) {
      _currentActivity?.onUpdate(details);
    };

    this.onEnd = (details) {
      if (_currentActivity == null) return;
      _currentActivity!.onEnd(details);
      _currentActivity = null;
      _onEnd?.call();
    };
  }

  @override
  bool get isActive => _currentActivity != null;

  @override
  Set<PointerDeviceKind> devicesToAcceptImmediately;

  DragActivityFactory<T> activityFactory;
  T? _currentActivity;

  @override
  T? get currentActivity => _currentActivity;

  final VoidCallback? _onStart;
  final VoidCallback? _onEnd;
}

class DragActivityWithArgumentGestureRecognizer<T extends DragActivity, A> extends PanGestureRecognizer
    with _DragActivityCommons, _DragActivityPointerCountLimiter {
  DragActivityWithArgumentGestureRecognizer({
    required this.activityFactory,
    super.debugOwner,
    super.supportedDevices,
    super.allowedButtonsFilter,
    VoidCallback? onStart,
    VoidCallback? onEnd,
    this.devicesToAcceptImmediately = const {},
  }) : _onStart = onStart,
       _onEnd = onEnd,
       super() {
    dragStartBehavior = .down;
    onlyAcceptDragOnThreshold = false;

    this.onStart = (details) {
      assert(_currentActivity == null);
      if (_currentArgument == null)
        throw ArgumentError(
          'Argument must be provided before starting the drag activity.',
        );
      _currentActivity = activityFactory(_currentArgument as A);
      _onActivityCreated();
      _currentActivity!.onStart(details);
      _onStart?.call();
    };

    onUpdate = (details) {
      _currentActivity?.onUpdate(details);
    };

    this.onEnd = (details) {
      if (_currentActivity == null) return;
      _currentActivity!.onEnd(details);
      _currentActivity = null;
      _currentArgument = null;
      _onEnd?.call();
    };
  }

  @override
  Set<PointerDeviceKind> devicesToAcceptImmediately;

  @override
  bool get isActive => _currentActivity != null;

  DragActivityWithArgumentFactory<T, A> activityFactory;
  A? _currentArgument;
  T? _currentActivity;

  @override
  T? get currentActivity => _currentActivity;

  final VoidCallback? _onStart;
  final VoidCallback? _onEnd;

  @override
  void addPointer(PointerDownEvent event, {A? argument}) {
    _currentArgument = argument;
    super.addPointer(event);
  }
}

class DragActivityGestureRecognizerFactory<T extends DragActivity>
    extends GestureRecognizerFactory<DragActivityGestureRecognizer<T>> {
  DragActivityGestureRecognizerFactory({
    required this.activityFactory,
    VoidCallback? onStart,
    VoidCallback? onEnd,
  }) : _onStart = onStart,
       _onEnd = onEnd;

  final DragActivityFactory<T> activityFactory;
  final VoidCallback? _onStart;
  final VoidCallback? _onEnd;

  @override
  DragActivityGestureRecognizer<T> constructor() {
    return DragActivityGestureRecognizer<T>(
      activityFactory: activityFactory,
      onStart: _onStart,
      onEnd: _onEnd,
    );
  }

  @override
  void initializer(DragActivityGestureRecognizer instance) {}
}

DragActivityGestureRecognizer<T> useDragActivityRecognizer<T extends DragActivity>(
  DragActivityFactory<T> activityFactory, {
  VoidCallback? onStart,
  VoidCallback? onEnd,
  Set<PointerDeviceKind>? supportedDevices,
  List<Object?>? keys,
}) {
  return useManagedResource(
    create: () => DragActivityGestureRecognizer(
      activityFactory: activityFactory,
      onStart: onStart,
      onEnd: onEnd,
      supportedDevices: supportedDevices,
    ),
    dispose: (v) => v.dispose(),
    keys: keys,
  );
}

DragActivityWithArgumentGestureRecognizer<DragActivity, A> useDragActivityWithArgumentRecognizer<A>(
  DragActivityWithArgumentFactory<DragActivity, A> activityFactory, {
  VoidCallback? onStart,
  VoidCallback? onEnd,
  Set<PointerDeviceKind>? supportedDevices,
  List<Object?>? keys,
}) {
  return useManagedResource(
    create: () => DragActivityWithArgumentGestureRecognizer<DragActivity, A>(
      activityFactory: activityFactory,
      onStart: onStart,
      onEnd: onEnd,
      supportedDevices: supportedDevices,
    ),
    dispose: (v) => v.dispose(),
    keys: keys,
  );
}
