import 'dart:io';

import 'package:stack/stack.dart';

import 'package:stack_ffi/darwin.dart' as darwin;
import 'package:stack_ffi/macos.dart' as macos;
import 'package:stack_ffi/src/logger.dart';

abstract class FullscreenObserver extends Controller {
  FullscreenObserver._() : super(logger: Logger('FullscreenObserver')) {
    $effect(() {
      final isFullscreen = this.isFullscreen;
      logger.finer('Fullscreen state changed: $isFullscreen');
    });
  }

  factory FullscreenObserver() {
    if (Platform.isMacOS) return _MacosFullscreenObserver();

    logger.warning(
      'FullscreenObserver is not implemented for this platform. Returning a no-op implementation.',
    );
    return _NoopFullscreenObserver();
  }

  late final _isFullscreen = $prop($signal(false));
  bool get isFullscreen => _isFullscreen.value;
}

class _NoopFullscreenObserver extends FullscreenObserver {
  _NoopFullscreenObserver() : super._();
}

class _MacosFullscreenObserver extends FullscreenObserver {
  _MacosFullscreenObserver() : super._() {
    final application = macos.NSApplication.getSharedApplication();
    final window = application.flutterWindow;

    enterFullscreenListener = $disposable(
      darwin.NotificationCenterListener(
        object: window,
        name: macos.NSWindowWillEnterFullScreenNotification,
        callback: () => _isFullscreen.value = true,
      ),
    );

    exitFullscreenListener = $disposable(
      darwin.NotificationCenterListener(
        object: window,
        name: macos.NSWindowWillExitFullScreenNotification,
        callback: () => _isFullscreen.value = false,
      ),
    );

    _isFullscreen.value = window.styleMask & macos.NSWindowStyleMask.NSWindowStyleMaskFullScreen != 0;
  }

  late final darwin.NotificationCenterListener enterFullscreenListener;
  late final darwin.NotificationCenterListener exitFullscreenListener;
}
