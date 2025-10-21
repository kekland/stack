import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stack/src/widgets/flutter/scaffold.dart' as flutter;
import 'package:stack/stack.dart';

class Scaffold extends StatelessWidget {
  const Scaffold({
    super.key,
    this.backgroundColor,
    this.isFullScreen = true,
    this.resizeToAvoidBottomInset = true,
    required this.child,
  });

  final Color? backgroundColor;
  final bool isFullScreen;
  final bool resizeToAvoidBottomInset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scrollController = PrimaryScrollController.of(context);

    final viewInsets = MediaQuery.viewInsetsOf(context);
    final color = SurfaceColor(
      background: backgroundColor ?? context.stack.backgroundColor,
      foreground: context.stack.defaultDisplayColor,
    );

    Widget child;

    child = BackdropGroup(
      child: Padding(
        padding: resizeToAvoidBottomInset ? viewInsets : EdgeInsets.zero,
        child: Builder(
          builder: (context) {
            return MediaQuery.removeViewInsets(
              context: context,
              removeTop: resizeToAvoidBottomInset,
              removeBottom: resizeToAvoidBottomInset,
              removeLeft: resizeToAvoidBottomInset,
              removeRight: resizeToAvoidBottomInset,
              child: this.child,
            );
          },
        ),
      ),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarBrightness: context.stack.brightness,
        statusBarIconBrightness: context.stack.brightness.inverse,
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: context.stack.brightness.inverse,
        systemStatusBarContrastEnforced: false,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Stack(
        children: [
          flutter.Scaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: color.background,
            body: Surface(color: color, child: child),
          ),

          // Only add the tap-to-scroll-to-top area on iOS when we're guaranteed that the scaffold is full-screen
          if (isFullScreen && context.stack.platform == ThemePlatform.cupertino)
            ListenableBuilder(
              listenable: scrollController,
              builder: (context, child) {
                if (scrollController.hasClients) {
                  return child!;
                }

                return const SizedBox.shrink();
              },
              child: Positioned(
                top: 0.0,
                left: 0.0,
                right: 0.0,
                height: MediaQuery.paddingOf(context).top,
                child: GestureDetector(
                  onTap: () {
                    if (scrollController.hasClients)
                      scrollController.animateTo(
                        0.0,
                        duration: const Duration(milliseconds: 650),
                        curve: Curves.easeOutCirc,
                      );
                  },
                  behavior: HitTestBehavior.opaque,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
