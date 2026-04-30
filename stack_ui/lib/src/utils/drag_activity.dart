import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:stack/stack.dart';

abstract class DragActivity {
  DragActivity();

  late final PositionedGestureDetails startDetails;
  DragUpdateDetails? lastUpdateDetails;

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

typedef DragActivityFactory = DragActivity Function();
typedef DragActivityWithArgumentFactory<T> = DragActivity Function(T argument);

mixin _DragActivityPointerCountLimiter on PanGestureRecognizer {
  final Set<int> _trackedPointers = <int>{};

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

class DragActivityGestureRecognizer extends PanGestureRecognizer with _DragActivityPointerCountLimiter {
  DragActivityGestureRecognizer({
    required this.activityFactory,
    super.debugOwner,
    super.supportedDevices,
    super.allowedButtonsFilter,
    VoidCallback? onStart,
    VoidCallback? onEnd,
  }) : _onStart = onStart,
       _onEnd = onEnd,
       super() {
    dragStartBehavior = .down;
    onlyAcceptDragOnThreshold = true;

    this.onStart = (details) {
      assert(_currentActivity == null);
      _currentActivity = activityFactory();
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

  DragActivityFactory activityFactory;
  DragActivity? _currentActivity;

  final VoidCallback? _onStart;
  final VoidCallback? _onEnd;
}

class DragActivityWithArgumentGestureRecognizer<T> extends PanGestureRecognizer with _DragActivityPointerCountLimiter {
  DragActivityWithArgumentGestureRecognizer({
    required this.activityFactory,
    super.debugOwner,
    super.supportedDevices,
    super.allowedButtonsFilter,
    VoidCallback? onStart,
    VoidCallback? onEnd,
  }) : _onStart = onStart,
       _onEnd = onEnd,
       super() {
    dragStartBehavior = .down;
    onlyAcceptDragOnThreshold = true;

    this.onStart = (details) {
      assert(_currentActivity == null);
      if (_currentArgument == null) throw ArgumentError('Argument must be provided before starting the drag activity.');
      _currentActivity = activityFactory(_currentArgument as T);
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
  bool get isActive => _currentActivity != null;

  DragActivityWithArgumentFactory<T> activityFactory;
  T? _currentArgument;
  DragActivity? _currentActivity;

  final VoidCallback? _onStart;
  final VoidCallback? _onEnd;

  @override
  void addPointer(PointerDownEvent event, {T? argument}) {
    _currentArgument = argument;
    super.addPointer(event);
  }
}

class DragActivityGestureRecognizerFactory extends GestureRecognizerFactory<DragActivityGestureRecognizer> {
  DragActivityGestureRecognizerFactory({
    required this.activityFactory,
    VoidCallback? onStart,
    VoidCallback? onEnd,
  }) : _onStart = onStart,
       _onEnd = onEnd;

  final DragActivityFactory activityFactory;
  final VoidCallback? _onStart;
  final VoidCallback? _onEnd;

  @override
  DragActivityGestureRecognizer constructor() {
    return DragActivityGestureRecognizer(
      activityFactory: activityFactory,
      onStart: _onStart,
      onEnd: _onEnd,
    );
  }

  @override
  void initializer(DragActivityGestureRecognizer instance) {}
}

DragActivityGestureRecognizer useDragActivityRecognizer(
  DragActivity Function() activityFactory, {
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

DragActivityWithArgumentGestureRecognizer<T> useDragActivityWithArgumentRecognizer<T>(
  DragActivity Function(T argument) activityFactory, {
  VoidCallback? onStart,
  VoidCallback? onEnd,
  Set<PointerDeviceKind>? supportedDevices,
  List<Object?>? keys,
}) {
  return useManagedResource(
    create: () => DragActivityWithArgumentGestureRecognizer(
      activityFactory: activityFactory,
      onStart: onStart,
      onEnd: onEnd,
      supportedDevices: supportedDevices,
    ),
    dispose: (v) => v.dispose(),
    keys: keys,
  );
}
