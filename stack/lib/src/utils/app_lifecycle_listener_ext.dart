import 'package:stack/stack.dart';
import 'package:flutter/widgets.dart';

extension AppLifecycleListenerExt on Disposable {
  void $appLifecycleListener({
    VoidCallback? onResume,
    VoidCallback? onInactive,
    VoidCallback? onHide,
    VoidCallback? onShow,
    VoidCallback? onPause,
    VoidCallback? onRestart,
    VoidCallback? onDetach,
    AppExitRequestCallback? onExitRequested,
    void Function(AppLifecycleState state)? onStateChange,
  }) {
    final listener = AppLifecycleListener(
      binding: WidgetsBinding.instance,
      onResume: onResume,
      onInactive: onInactive,
      onHide: onHide,
      onShow: onShow,
      onPause: onPause,
      onRestart: onRestart,
      onDetach: onDetach,
      onExitRequested: onExitRequested,
      onStateChange: onStateChange,
    );

    addDisposeCallback(listener.dispose);
  }
}
