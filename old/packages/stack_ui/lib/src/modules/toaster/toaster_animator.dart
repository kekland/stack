part of 'toaster.dart';

class DefaultToasterAnimator extends StatefulWidget {
  const DefaultToasterAnimator({
    super.key,
    required this.toastEntry,
    required this.onPop,
  });

  final ToastEntry? toastEntry;
  final VoidCallback onPop;

  @override
  State<DefaultToasterAnimator> createState() => DefaultToasterAnimatorState();
}

class DefaultToasterAnimatorState extends State<DefaultToasterAnimator> with TickerProviderStateMixin {
  AnimationStyle? _animationStyle;
  late final AnimationController _forwardAnimationController;
  late final AnimationController _reverseAnimationController;
  Animation<double>? _forwardAnimation;
  Animation<double>? _reverseAnimation;
  Animation<Offset>? _forwardSlideAnimation;
  Animation<Offset>? _reverseSlideAnimation;
  Animation<double>? _forwardOpacityAnimation;
  Animation<double>? _reverseOpacityAnimation;

  ToastEntry? oldToastEntry;
  ToastEntry? toastEntry;

  @override
  void initState() {
    super.initState();

    _forwardAnimationController = AnimationController(vsync: this);
    _reverseAnimationController = AnimationController(vsync: this);

    _reverseAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        oldToastEntry = null;
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final animationStyle = context.stack.defaultSpatialAnimation;
    if (_animationStyle != animationStyle) {
      _animationStyle = animationStyle;

      _forwardAnimationController.duration = animationStyle.duration;
      _reverseAnimationController.duration = animationStyle.reverseDuration ?? animationStyle.duration;

      final forwardCurve = animationStyle.curve ?? Curves.linear;
      final reverseCurve = animationStyle.reverseCurve ?? forwardCurve;
      _forwardAnimation = CurvedAnimation(parent: _forwardAnimationController, curve: forwardCurve);
      _reverseAnimation = CurvedAnimation(parent: _reverseAnimationController, curve: reverseCurve);

      _forwardSlideAnimation = Tween<Offset>(
        begin: const Offset(0.0, -1.125),
        end: const Offset(0.0, 0.0),
      ).animate(_forwardAnimation!);

      _reverseSlideAnimation = Tween<Offset>(
        begin: const Offset(0.0, -1.125),
        end: const Offset(0.0, 0.0),
      ).animate(_reverseAnimation!);

      _forwardOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _forwardAnimationController,
          curve: const Interval(0.0, 0.75, curve: Curves.easeInOut),
        ),
      );

      _reverseOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _reverseAnimationController,
          curve: const Interval(0.65, 1.0, curve: Curves.easeInOut),
        ),
      );
    }
  }

  @override
  void didUpdateWidget(DefaultToasterAnimator oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (toastEntry != widget.toastEntry) {
      oldToastEntry = toastEntry;
      toastEntry = widget.toastEntry;

      _forwardAnimationController.forward(from: 0.0);
      _reverseAnimationController.reverse(from: 1.0);
    }
  }

  @override
  void dispose() {
    _forwardAnimationController.dispose();
    _reverseAnimationController.dispose();
    oldToastEntry = null;
    toastEntry = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var padding = MediaQuery.paddingOf(context).copyWith(bottom: 0.0);
    padding += const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0);
    Widget _wrapInPadding(Widget child) => Padding(padding: padding, child: child);

    return Stack(
      children: [
        if (oldToastEntry != null)
          SlideTransition(
            position: _reverseSlideAnimation!,
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: 1.0,
              child: Dismissible(
                key: oldToastEntry!.$1,
                direction: DismissDirection.none,
                onDismissed: (d) {},
                child: FadeTransition(
                  opacity: _reverseOpacityAnimation!,
                  child: _wrapInPadding(oldToastEntry!.$2),
                ),
              ),
            ),
          ),
        if (toastEntry != null)
          SlideTransition(
            position: _forwardSlideAnimation!,
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: 1.0,
              child: Dismissible(
                key: toastEntry!.$1,
                direction: DismissDirection.up,
                onDismissed: (d) {
                  toastEntry = null;
                  widget.onPop();
                },
                child: FadeTransition(
                  opacity: _forwardOpacityAnimation!,
                  child: _wrapInPadding(toastEntry!.$2),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
