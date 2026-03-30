import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'image.dart';
import '../../widgets/utils/animated_switcher.dart';
import '../../../stack_ui.dart';

ImageProvider stDefaultCreateImageProvider(Object rawProvider) {
  if (rawProvider is ImageProvider) return rawProvider;
  if (rawProvider is String) {
    if (rawProvider.startsWith('http://') || rawProvider.startsWith('https://')) {
      return NetworkImage(rawProvider);
    }

    if (kIsWeb) {
      return NetworkImage(rawProvider);
    } else {
      return FileImage(File(rawProvider));
    }
  }

  if (rawProvider is File) return FileImage(rawProvider);
  if (rawProvider is Uint8List) return MemoryImage(rawProvider);

  throw Exception('Unsupported rawProvider type: ${rawProvider.runtimeType}');
}

class StImage extends StatefulWidget {
  StImage({
    super.key,
    required this.rawProvider,
    ImageProvider Function(Object rawProvider) createImageProvider = stDefaultCreateImageProvider,
    this.fit,
    this.width,
    this.height,
    this.placeholderBuilder,
    this.errorBuilder,
  }) : provider = createImageProvider(rawProvider);

  final Object rawProvider;
  final ImageProvider provider;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final WidgetBuilder? placeholderBuilder;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  State<StImage> createState() => StImageState();
}

class StImageState extends State<StImage> {
  var _isLoaded = false;

  @override
  Widget build(BuildContext context) {
    final size = (widget.provider is SizedImageProviderMixin)
        ? (widget.provider as SizedImageProviderMixin).size
        : null;

    final fit = widget.fit ?? InheritedBoxFit.maybeOf(context) ?? BoxFit.contain;

    Widget child = Image(
      image: widget.provider,
      fit: fit,
      width: widget.width,
      height: widget.height,
      errorBuilder: widget.errorBuilder,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) {
          _isLoaded = true;
          return child;
        }

        _isLoaded = frame != null;

        if (!_isLoaded && widget.provider is MultiRenditionImageProviderMixin) {
          final provider = widget.provider as MultiRenditionImageProviderMixin;
          final alternativeLiveRendition = provider.alternativeLiveRendition;
          if (alternativeLiveRendition != null) {
            return Image(
              image: alternativeLiveRendition,
              fit: size != null ? BoxFit.contain : fit,
            );
          }
        }

        if (!_isLoaded && widget.placeholderBuilder == null) {
          return const SizedBox.shrink();
        }

        return StAnimatedSwitcher(
          child: _isLoaded
              ? KeyedSubtree(
                  key: Key('image'),
                  child: child,
                )
              : KeyedSubtree(
                  key: Key('placeholder'),
                  child: widget.placeholderBuilder?.call(context) ?? const SizedBox.shrink(),
                ),
        );
      },
    );

    if (size != null) {
      return FittedBox(
        fit: fit,
        clipBehavior: Clip.hardEdge,
        child: SizedBox.fromSize(
          size: size,
          child: child,
        ),
      );
    }

    return child;
  }
}
