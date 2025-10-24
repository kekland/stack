
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stack/stack.dart';

class SharedPreferencesStore extends SignalsKeyValueStore {
  SharedPreferencesStore({required this.prefs});

  final SharedPreferencesWithCache prefs;

  @override
  Future<String?> getItem(String key) async => prefs.getString(key);

  @override
  Future<void> removeItem(String key) async => prefs.remove(key);

  @override
  Future<void> setItem(String key, String value) async => prefs.setString(key, value);
}

class SecureStorageStore extends SignalsKeyValueStore {
  SecureStorageStore({required this.storage});

  final FlutterSecureStorage storage;

  @override
  Future<String?> getItem(String key) => storage.read(key: key);

  @override
  Future<void> removeItem(String key) => storage.delete(key: key);

  @override
  Future<void> setItem(String key, String value) => storage.write(key: key, value: value);
}
