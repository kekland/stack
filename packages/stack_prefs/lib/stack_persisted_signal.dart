import 'package:stack/stack.dart';

class StackPersistedSignal<T> extends FlutterSignal<T?> with PersistedSignalMixin<T?> {
  StackPersistedSignal({
    required this.key,
    required this.store,
    this.decoder,
    this.encoder,
    this.enumValues,
  }) : super.lazy();

  @override
  final SignalsKeyValueStore store;

  @override
  final String key;

  final T Function(String v)? decoder;
  final String Function(T v)? encoder;
  final List<T>? enumValues;

  @override
  Future<T?> load() async {
    final val = await store.getItem(key);
    if (val == null) return null;
    return decode(val);
  }

  @override
  T decode(String value) {
    if (decoder != null) return decoder!(value);

    if (T is String) return value as T;
    if (T is int) return int.parse(value) as T;
    if (T is double) return double.parse(value) as T;
    if (T is bool) return (value.toLowerCase() == 'true') as T;
    if (T is DateTime) return DateTime.parse(value) as T;
    if (T is Enum) return enumValues!.firstWhere((e) => e.toString() == value);

    throw UnimplementedError('No decoder provided for type $T');
  }

  @override
  String encode(T? value) {
    if (value == null) throw StateError('Cannot encode null value');
    if (encoder != null) return encoder!(value);

    if (T is String) return value as String;
    if (T is int) return (value as int).toString();
    if (T is double) return (value as double).toString();
    if (T is bool) return (value as bool).toString();
    if (T is DateTime) return (value as DateTime).toIso8601String();
    if (T is Enum) return value.toString();

    throw UnimplementedError('No encoder provided for type $T');
  }
}
