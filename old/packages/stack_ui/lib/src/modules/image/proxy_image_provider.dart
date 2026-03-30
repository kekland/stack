// ignore_for_file: deprecated_member_use

import 'package:flutter/widgets.dart';

abstract class ProxyImageProvider implements ImageProvider {
  ProxyImageProvider() {
    provider = createProvider();
  }

  ImageProvider createProvider();
  late final ImageProvider provider;

  @override
  Future<Object> obtainKey(ImageConfiguration configuration) {
    return provider.obtainKey(configuration);
  }

  @override
  ImageStream createStream(ImageConfiguration configuration) {
    return provider.createStream(configuration);
  }

  @override
  Future<bool> evict({ImageCache? cache, ImageConfiguration configuration = ImageConfiguration.empty}) {
    return provider.evict(cache: cache, configuration: configuration);
  }

  @override
  ImageStreamCompleter loadBuffer(Object key, DecoderBufferCallback decode) {
    return provider.loadBuffer(key, decode);
  }

  @override
  ImageStreamCompleter loadImage(Object key, ImageDecoderCallback decode) {
    return provider.loadImage(key, decode);
  }

  @override
  Future<ImageCacheStatus?> obtainCacheStatus({
    required ImageConfiguration configuration,
    ImageErrorListener? handleError,
  }) {
    return provider.obtainCacheStatus(configuration: configuration, handleError: handleError);
  }

  @override
  ImageStream resolve(ImageConfiguration configuration) {
    return provider.resolve(configuration);
  }

  @override
  void resolveStreamForKey(
    ImageConfiguration configuration,
    ImageStream stream,
    Object key,
    ImageErrorListener handleError,
  ) {
    provider.resolveStreamForKey(configuration, stream, key, handleError);
  }
}
