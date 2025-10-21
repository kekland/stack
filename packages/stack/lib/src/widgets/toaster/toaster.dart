import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stack/stack.dart';

part 'toaster_animator.dart';

final _toasterKey = GlobalKey<ToasterState>();

typedef ToasterAnimatorBuilder = Widget Function(ToastEntry? toastEntry, VoidCallback onPop);
Widget defaultToasterAnimatorBuilder(ToastEntry? toastEntry, VoidCallback onPop) {
  return DefaultToasterAnimator(
    toastEntry: toastEntry,
    onPop: onPop,
  );
}

/// A widget that contains the scope for the toaster.
///
/// Toasts will be shown above the provided [child].
class Toaster extends StatefulWidget {
  Toaster({
    Key? key,
    required this.child,
    this.animatorBuilder = defaultToasterAnimatorBuilder,
  }) : super(key: key ?? _toasterKey);

  final Widget child;
  final ToasterAnimatorBuilder animatorBuilder;

  static ToasterState get instance => _toasterKey.currentState!;

  @override
  State<Toaster> createState() => ToasterState();
}

typedef ToastEntry<T> = (Key key, Widget toast, Completer<T?> completer, {Duration? duration});

class ToasterState extends State<Toaster> {
  ToastEntry? _activeEntry;
  final _queue = <ToastEntry>[];

  /// Pushes a toast onto the queue.
  ///
  /// If `duration` is `null`, then the toast is treated as a persistent toast, and it will not be removed
  /// automatically.
  Future<T?> push<T>({
    required Widget toast,
    Duration? duration = const Duration(seconds: 5),
  }) {
    final completer = Completer<T?>();
    _queue.add((
      UniqueKey(),
      toast,
      completer,
      duration: duration,
    ));

    _maybeDequeue();
    return completer.future;
  }

  Future<void> pushBuilder({
    required Widget Function(BuildContext context) builder,
    Duration? duration = const Duration(seconds: 5),
  }) {
    return push(
      toast: Builder(builder: (context) => builder(context)),
      duration: duration,
    );
  }

  void pop([dynamic result]) {
    if (_activeEntry != null) {
      _activeEntry?.$3.complete(result);
      _activeEntry = null;
      _maybeDequeue();
      setState(() {});
    }
  }

  void _maybeDequeue() {
    if (_activeEntry == null && _queue.isNotEmpty) {
      final entry = _queue.removeAt(0);
      _activeEntry = entry;
      setState(() {});

      if (entry.duration != null) {
        Future.delayed(entry.duration!, () {
          if (entry == _activeEntry) {
            pop();
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        widget.animatorBuilder(_activeEntry, pop),
      ],
    );
  }
}
