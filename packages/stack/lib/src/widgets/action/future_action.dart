import 'package:flutter/material.dart';
import 'package:stack/stack.dart';

class FutureActionScope extends StatefulWidget {
  const FutureActionScope({super.key, required this.child});

  final Widget child;

  @override
  State<FutureActionScope> createState() => _FutureActionScopeState();
}

class _FutureActionScopeState extends State<FutureActionScope> {
  var _isLoading = false;

  void setLoading(bool isLoading) {
    if (_isLoading == isLoading) return;
    _isLoading = isLoading;
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class FutureAction extends StatefulWidget {
  const FutureAction({
    super.key,
    this.onTap,
    required this.builder,
    this.showChildWhileLoading = false,
    this.activityIndicator,
  });

  final Future<void> Function()? onTap;
  final Widget Function(BuildContext context, VoidCallback? onTap, Widget? loadingIndicator) builder;
  final bool showChildWhileLoading;
  final WidgetBuilder? activityIndicator;

  @override
  State<FutureAction> createState() => _FutureActionState();
}

class _FutureActionState extends State<FutureAction> {
  Size? _size;
  var _isExecuting = false;
  _FutureActionScopeState? _scope;

  @override
  void initState() {
    super.initState();
    _scope = context.findAncestorStateOfType<_FutureActionScopeState>();
  }

  @override
  void dispose() {
    if (_isExecuting) _scope?.setLoading(false);
    _scope = null;

    super.dispose();
  }

  Future<void> _onTap() async {
    if (_isExecuting) return;
    if (_scope?._isLoading == true) return;

    setState(() => _isExecuting = true);
    _scope?.setLoading(true);

    try {
      await widget.onTap!();
    } finally {
      _scope?.setLoading(false);
      if (mounted) setState(() => _isExecuting = false);
    }
  }

  Widget _buildActivityIndicator(BuildContext context) {
    if (widget.activityIndicator != null) {
      return widget.activityIndicator!(context);
    }

    return const ActivityIndicator();
  }

  Future<void> Function()? get onTap => widget.onTap != null && !_isExecuting ? _onTap : null;

  Widget _buildSpinner(BuildContext context) {
    if (_size == null) return _buildActivityIndicator(context);

    if (widget.showChildWhileLoading) {
      return SizedBox.fromSize(
        size: _size,
        child: widget.builder(context, null, _buildActivityIndicator(context)),
      );
    }

    return SizedBox.fromSize(
      size: _size,
      child: Center(child: _buildActivityIndicator(context)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget child;

    if (widget.showChildWhileLoading) {
      child = _isExecuting ? _buildSpinner(context) : SizedBox(child: widget.builder(context, onTap, null));
    } else {
      child = StAnimatedSwitcher(
        child: _isExecuting
            ? KeyedSubtree(
                key: const Key('executing'),
                child: _buildSpinner(context),
              )
            : KeyedSubtree(
                key: const Key('normal'),
                child: widget.builder(context, onTap, null),
              ),
      );
    }

    return SizeNotifierWidget(
      onChanged: (size) => _size = size,
      child: child,
    );
  }
}
