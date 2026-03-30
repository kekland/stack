import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../../../../stack_ui.dart';

/// Attempts to get the [ImageCacheStatus] for the given [ImageProvider] synchronously.
///
/// If it's not synchronous, returns null.
ImageCacheStatus? _getImageCacheStatusSync(ImageProvider provider) {
  final keyFuture = provider.obtainKey(ImageConfiguration.empty);
  if (keyFuture is SynchronousFuture) {
    late Object key;
    keyFuture.then((v) => key = v);

    final status = imageCache.statusForKey(key);
    return status;
  }

  return null;
}

mixin MultiRenditionImageProviderMixin on ProxyImageProvider {
  /// Renditions available for this image provider.
  List<MultiRenditionImageProviderMixin> get renditions;

  /// Index of the current rendition in the [renditions] list.
  int get currentRenditionIndex;

  /// Returns a list of renditions of this image that are currently live in the image cache.
  Map<int, MultiRenditionImageProviderMixin> get currentlyLiveRenditions {
    final liveRenditions = renditions.where((r) {
      final status = _getImageCacheStatusSync(r);
      return status != null && (status.keepAlive || status.live);
    }).toList();

    final result = <int, MultiRenditionImageProviderMixin>{};
    for (final rendition in liveRenditions) {
      final index = renditions.indexOf(rendition);
      result[index] = rendition;
    }

    return result;
  }

  /// Return a rendition of this image that is available synchronously from cache, and can be used as a placeholder
  /// while the current rendition is loading.
  MultiRenditionImageProviderMixin? get alternativeLiveRendition {
    final liveRenditions = currentlyLiveRenditions;
    if (liveRenditions.isEmpty) return null;

    // First, find a rendition that is smaller than the current one
    for (var i = currentRenditionIndex - 1; i >= 0; i--) {
      if (liveRenditions.containsKey(i)) return liveRenditions[i];
    }

    // Otherwise, return the smallest available rendition that is not the current one
    final smallestIndex = liveRenditions.keys.reduce(min);
    if (smallestIndex != currentRenditionIndex) return liveRenditions[smallestIndex];

    // If none found, return null.
    return null;
  }
}
