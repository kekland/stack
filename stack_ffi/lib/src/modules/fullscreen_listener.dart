import 'package:flutter/widgets.dart';
import 'package:stack/stack.dart';
import 'package:stack_ffi/stack_ffi.dart';

class FullscreenListener extends HookWidget {
  const FullscreenListener({
    super.key,
    required this.builder,
  });

  final Widget Function(BuildContext context, bool isFullscreen) builder;

  @override
  Widget build(BuildContext context) {
    final observer = useDisposable(() => FullscreenObserver());
    final isFullscreen = useComputedValue(() => observer.isFullscreen);
    return builder(context, isFullscreen);
  }
}
