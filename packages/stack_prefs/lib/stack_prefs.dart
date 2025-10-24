import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stack/stack.dart';

import 'stores.dart';
import 'stack_persisted_signal.dart';

class Prefs extends Service {
  Prefs() : super(logger: Logger('Prefs'));

  late final SharedPreferencesWithCache prefs;
  late final FlutterSecureStorage secureStorage;

  @override
  Future<void> initialize() async {
    prefs = await SharedPreferencesWithCache.create(cacheOptions: SharedPreferencesWithCacheOptions());
    secureStorage = const FlutterSecureStorage();

    await allSignals.map((s) => s.init()).wait;
    return super.initialize();
  }

  late final _prefsStore = SharedPreferencesStore(prefs: prefs);
  late final _secureStore = SecureStorageStore(storage: secureStorage);

  Iterable<StackPersistedSignal> get allSignals => [];

  StackPersistedSignal<T?> _$internalStoreSignal<T>(
    String key, {
    required SignalsKeyValueStore store,
    T Function(String v)? decoder,
    String Function(T v)? encoder,
    List<T>? enumValues,
  }) {
    final signal = StackPersistedSignal<T>(
      key: key,
      store: store,
      decoder: decoder,
      encoder: encoder,
      enumValues: enumValues,
    );

    addDisposeCallback(signal.dispose);
    return signal;
  }

  StackPersistedSignal<T?> $prefSignal<T>(
    String key, {
    T Function(String v)? decoder,
    String Function(T v)? encoder,
    List<T>? enumValues,
  }) => _$internalStoreSignal<T>(
    key,
    store: _prefsStore,
    decoder: decoder,
    encoder: encoder,
    enumValues: enumValues,
  );

  StackPersistedSignal<T?> $prefSecureSignal<T>(
    String key, {
    T Function(String v)? decoder,
    String Function(T v)? encoder,
    List<T>? enumValues,
  }) => _$internalStoreSignal<T>(
    key,
    store: _secureStore,
    decoder: decoder,
    encoder: encoder,
    enumValues: enumValues,
  );

  Future<void> clear() async {
    await prefs.clear();
    await secureStorage.deleteAll();
    await allSignals.map((s) => s.load()).wait;
  }
}
