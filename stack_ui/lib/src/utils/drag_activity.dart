import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

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

class DragActivityGestureRecognizer extends PanGestureRecognizer {
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

  bool get isActive => _currentActivity != null;

  DragActivityFactory activityFactory;
  DragActivity? _currentActivity;

  final VoidCallback? _onStart;
  final VoidCallback? _onEnd;
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
