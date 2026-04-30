import 'dart:io';

import 'package:flutter/services.dart' as services;
import 'package:stack_ffi/macos.dart' as macos;

class Haptics {
  static _Haptics? _storedInstance;
  static _Haptics get _instance {
    if (_storedInstance != null) return _storedInstance!;

    if (Platform.isMacOS) {
      _storedInstance = _MacosHaptics();
    } else {
      _storedInstance = _FallbackHaptics();
    }

    return _storedInstance!;
  }

  static void click() => _instance.click();
}

sealed class _Haptics {
  void click();
}

final class _MacosHaptics extends _Haptics {
  _MacosHaptics();

  @override
  void click() {
    macos.NSHapticFeedbackManager.getDefaultPerformer().performFeedbackPattern(
      .NSHapticFeedbackPatternLevelChange,
      performanceTime: .NSHapticFeedbackPerformanceTimeDrawCompleted,
    );
  }
}

final class _FallbackHaptics extends _Haptics {
  @override
  void click() {
    services.HapticFeedback.selectionClick();
  }
}
