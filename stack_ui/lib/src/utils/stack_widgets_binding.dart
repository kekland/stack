import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:stack_ui/stack_ui.dart';

class StackWidgetsFlutterBinding extends BindingBase
    with
        GestureBinding,
        SchedulerBinding,
        ServicesBinding,
        PaintingBinding,
        SemanticsBinding,
        RendererBinding,
        WidgetsBinding {
  StackWidgetsFlutterBinding() : super();

  static StackWidgetsFlutterBinding? _instance;
  static StackWidgetsFlutterBinding get instance => _instance!;

  static WidgetsBinding ensureInitialized() {
    if (_instance != null) return _instance!;

    _instance = StackWidgetsFlutterBinding();
    return _instance!;
  }

  @override
  BinaryMessenger createBinaryMessenger() {
    return InterceptingBinaryMessenger(super.createBinaryMessenger());
  }

  @override
  PipelineOwner createRootPipelineOwner() {
    return StackRootPipelineOwner();
  }

  final _ensureVisualUpdateListeners = <VoidCallback>{};
  void addEnsureVisualUpdateListener(VoidCallback l) => _ensureVisualUpdateListeners.add(l);
  void removeEnsureVisualUpdateListener(VoidCallback l) => _ensureVisualUpdateListeners.remove(l);

  @override
  void ensureVisualUpdate() {
    for (final l in _ensureVisualUpdateListeners) l();
    super.ensureVisualUpdate();
  }

  @override
  StackRootPipelineOwner get rootPipelineOwner => super.rootPipelineOwner as StackRootPipelineOwner;

  @override
  InterceptingBinaryMessenger get defaultBinaryMessenger => super.defaultBinaryMessenger as InterceptingBinaryMessenger;
}

typedef OutgoingInterceptor = bool Function(ByteData? message);

/// A [BinaryMessenger] that intercepts messages and allows for custom handling.
class InterceptingBinaryMessenger extends BinaryMessenger {
  InterceptingBinaryMessenger(this._delegate);

  final BinaryMessenger _delegate;

  final _outgoingInterceptors = <String, List<OutgoingInterceptor>>{};

  void addOutgoingInterceptor(String channel, OutgoingInterceptor interceptor) {
    _outgoingInterceptors[channel] ??= [];
    _outgoingInterceptors[channel]!.add(interceptor);
  }

  void removeOutgoingInterceptor(String channel, OutgoingInterceptor interceptor) {
    _outgoingInterceptors[channel]?.remove(interceptor);
  }

  @override
  Future<void> handlePlatformMessage(
    String channel,
    ByteData? data,
    PlatformMessageResponseCallback? callback,
    // ignore: deprecated_member_use
  ) => _delegate.handlePlatformMessage(channel, data, callback);

  @override
  Future<ByteData?>? send(String channel, ByteData? message) {
    if (_outgoingInterceptors[channel] != null) {
      for (final interceptor in _outgoingInterceptors[channel]!) {
        if (interceptor(message)) return Future.value(null);
      }
    }

    return _delegate.send(channel, message);
  }

  @override
  void setMessageHandler(String channel, MessageHandler? handler) => _delegate.setMessageHandler(channel, handler);
}
