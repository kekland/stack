import 'package:flutter/material.dart';
import 'package:stack/stack.dart';

class SteppedPageTemplate extends StatefulHookWidget {
  const SteppedPageTemplate({
    super.key,
    required this.steps,
    required this.builder,
    this.onStepChanged,
    this.onCompleted,
    this.onPreviousPageAnimationStyle,
    this.onNextPageAnimationStyle,
  });

  final Map<String, SteppedPageChild> steps;
  final ValueChanged<String>? onStepChanged;
  final VoidCallback? onCompleted;
  final AnimationStyle? onPreviousPageAnimationStyle;
  final AnimationStyle? onNextPageAnimationStyle;

  final Widget Function(
    BuildContext context,
    Future<void> Function()? onContinue,
    Future<void> Function()? onSkip,
    void Function()? onBack,
    int currentStepIndex,
    String currentStepId,
    SteppedPageChild currentStepWidget,
    Widget child,
  )
  builder;

  @override
  State<SteppedPageTemplate> createState() => SteppedPageTemplateState();
}

class SteppedPageTemplateState extends State<SteppedPageTemplate> {
  late PageController pageController;
  late int pageCount;
  final formKeys = <String, GlobalKey<FormState>>{};

  void _generateFormKeys() {
    for (final step in widget.steps.entries) {
      formKeys[step.key] ??= GlobalKey<FormState>();
    }
  }

  @override
  void initState() {
    super.initState();

    pageController = PageController();
    pageCount = widget.steps.length;
    _generateFormKeys();
  }

  @override
  void didUpdateWidget(covariant SteppedPageTemplate oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.steps.length != widget.steps.length) {
      pageCount = widget.steps.length;
      _generateFormKeys();
    }
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  Future<void> animateToPage({
    required int page,
    AnimationStyle? animationStyle,
  }) async {
    final style = animationStyle ?? context.stack.defaultEffectAnimation;
    await pageController.animateToPage(
      page,
      duration: style.duration!,
      curve: style.curve ?? Curves.linear,
    );
  }

  Future<void> previousPage() async {
    if (pageController.page == null) return;
    final page = pageController.page!.toInt();

    if (page == 0) {
      // Check if we can pop.
      if (Navigator.canPop(context)) Navigator.pop(context);
      return;
    }

    await animateToPage(page: page - 1, animationStyle: widget.onPreviousPageAnimationStyle);
    widget.onStepChanged?.call(widget.steps.keys.elementAt(page - 1));
  }

  Future<void> nextPage() async {
    if (pageController.page == null) return;
    final page = pageController.page!.toInt();

    if (page == pageCount - 1) {
      widget.onCompleted?.call();
      return;
    }

    await animateToPage(page: page + 1, animationStyle: widget.onNextPageAnimationStyle);
    widget.onStepChanged?.call(widget.steps.keys.elementAt(page + 1));
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = usePageControllerCurrentPage(pageController);
    final currentStepId = widget.steps.keys.elementAt(currentStep);
    final currentStepWidget = widget.steps[currentStepId]!;

    Future<void> onContinue() async {
      final formKey = formKeys[currentStepId];
      if (formKey == null || !formKey.currentState!.validate()) return;

      await currentStepWidget.onContinue(context);
      nextPage();
    }

    Future<void> onSkip() async {
      await currentStepWidget.onSkip(context);
      nextPage();
    }

    final child = PageView.builder(
      controller: pageController,
      itemCount: pageCount,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, i) {
        final id = widget.steps.keys.elementAt(i);

        return InheritedFormKey(
          formKey: formKeys[id]!,
          child: widget.steps[id]!,
        );
      },
    );

    return widget.builder(
      context,
      currentStepWidget.canContinue ? onContinue : null,
      currentStepWidget.canSkip ? onSkip : null,
      currentStepWidget.canGoBack && Navigator.of(context).canPop() ? previousPage : null,
      currentStep,
      currentStepId,
      currentStepWidget,
      child,
    );
  }
}

mixin SteppedPageChild on Widget {
  bool get canContinue => true;
  bool get canSkip => false;
  bool get canGoBack => true;

  Future<void> onContinue(BuildContext context) async {}
  Future<void> onSkip(BuildContext context) async {}
}
