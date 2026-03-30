import 'dart:math';

import 'package:flutter/material.dart';
import '../../../stack_ui.dart';
import '../../../../../stack/lib/stack.dart';

typedef DarkroomWidgetBuilder = Widget Function(BuildContext context, DarkroomScopeContainer scope, Widget child);

class DarkroomScopeContainer extends ScopeContainer<DarkroomWidget> {
  DarkroomScopeContainer({
    required this.heroKeyPrefix,
    required this.heroContainerKey,
  });

  final GlobalKey<HeroContainerState> heroContainerKey;

  final String heroKeyPrefix;
  String getHeroTag(int index) => '$heroKeyPrefix/$index';

  HeroContainerState get heroContainerState => heroContainerKey.currentState!;
  late final orderedChildren = $signal(<int, DarkroomWidget>{});

  int get potentialPageCount => orderedChildren.keys.reduce(max) + 1;

  @override
  void bind(BuildContext context) {
    super.bind(context);

    final widget = context.widget as DarkroomWidget;
    if (orderedChildren.value.containsKey(widget.index)) {
      throw Exception('Duplicate DarkroomWidget index: ${widget.index}');
    }
    orderedChildren.value[widget.index] = widget;
  }

  @override
  void unbind(BuildContext context) {
    super.unbind(context);
    final widget = context.widget as DarkroomWidget;
    orderedChildren.value.remove(widget.index);
  }
}

class DarkroomWidget extends HookWidget {
  const DarkroomWidget({
    super.key,
    required this.builder,
    required this.imageBuilder,
    this.index = 0,
    this.fit,
    this.borderRadius = BorderRadius.zero,
  });

  final DarkroomWidgetBuilder builder;
  final WidgetBuilder imageBuilder;
  final int index;
  final BoxFit? fit;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final container = useScopedBinding<DarkroomScopeContainer>();
    if (container == null) return DarkroomScope(child: this);

    final heroTag = useMemoized(() => container.getHeroTag(index));
    return ClipRRect(
      borderRadius: borderRadius,
      child: InheritedBoxFit(
        fit: fit ?? BoxFit.cover,
        child: builder(
          context,
          container,
          HeroHandle(
            tag: heroTag,
            child: imageBuilder(context),
          ),
        ),
      ),
    );
  }
}

class DarkroomScope extends HookWidget {
  const DarkroomScope({
    super.key,
    required this.child,
    this.totalCount,
  });

  final Widget child;
  final int? totalCount;

  @override
  Widget build(BuildContext context) {
    final heroContainerKey = useMemoized(() => GlobalKey<HeroContainerState>());
    final heroKeyPrefix = useMemoized(() => 'darkroom_hero_${UniqueKey().toString()}/');
    final scopeContainer = useScopeContainer(
      () => DarkroomScopeContainer(
        heroKeyPrefix: heroKeyPrefix,
        heroContainerKey: heroContainerKey,
      ),
    );

    return HeroContainer(
      key: heroContainerKey,
      child: Scope(container: scopeContainer, child: child),
    );
  }
}

class DarkroomPageBuilder extends HookWidget {
  const DarkroomPageBuilder({
    super.key,
    required this.container,
    required this.pageBuilder,
    this.initialIndex = 0,
  });

  final DarkroomScopeContainer container;
  final int initialIndex;
  final Widget Function(BuildContext context, int index, Widget child) pageBuilder;

  @override
  Widget build(BuildContext context) {
    final pageController = usePageController(initialPage: initialIndex);
    final orderedChildren = useSignalValue(container.orderedChildren);
    final pageCount = container.potentialPageCount;

    return PageView.builder(
      controller: pageController,
      itemCount: pageCount,
      itemBuilder: (context, i) {
        final darkroomWidget = orderedChildren[i] as DarkroomWidget;
        Widget child = darkroomWidget;

        child = HeroTarget(
          isActive: true,
          child: Hero(
            tag: container.getHeroTag(i),
            child: darkroomWidget.imageBuilder(context),
          ),
        );

        return pageBuilder(context, i, child);
      },
    );
  }
}
