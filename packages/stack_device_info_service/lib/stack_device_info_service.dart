import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:stack/stack.dart';

enum DeviceType {
  android,
  ios,
  development,
}

class DeviceInfoService extends Service {
  DeviceInfoService() : super(logger: Logger('DeviceInfoService'));

  final _plugin = DeviceInfoPlugin();

  late final _deviceTypeSignal = $signal<DeviceType?>(null);
  late final _osSignal = $signal<String?>(null);
  late final _osVersionSignal = $signal<String?>(null);
  late final _isEmulatorSignal = $signal<bool?>(null);
  late final _brand = $signal<String?>(null);
  late final _model = $signal<String?>(null);
  late final _androidSdkVersion = $signal<int?>(null);
  late final _locale = $signal<String?>(null);

  DeviceType get deviceType => _deviceTypeSignal.value!;
  String get os => _osSignal.value ?? 'unknown';
  String get osVersion => _osVersionSignal.value!;
  bool get isEmulator => _isEmulatorSignal.value!;
  String get brand => _brand.value!;
  String get model => _model.value!;
  String? get locale => _locale.value;
  int? get androidSdkVersion => _androidSdkVersion.value;

  @override
  Future<void> initialize() async {
    if (Platform.isAndroid) {
      final info = await _plugin.androidInfo;
      _osSignal.value = 'Android';
      _deviceTypeSignal.value = DeviceType.android;
      _osVersionSignal.value = info.version.release;
      _isEmulatorSignal.value = info.isPhysicalDevice == false;
      _brand.value = info.brand;
      _model.value = info.model;
      _androidSdkVersion.value = info.version.sdkInt;
    } else if (Platform.isIOS) {
      final info = await _plugin.iosInfo;
      _osSignal.value = 'iOS';
      _deviceTypeSignal.value = DeviceType.ios;
      _osVersionSignal.value = info.systemVersion;
      _isEmulatorSignal.value = info.isPhysicalDevice == false;
      _brand.value = info.name;
      _model.value = info.model;
    } else {
      _deviceTypeSignal.value = DeviceType.development;
      _osSignal.value = 'Development';
      _osVersionSignal.value = 'unknown';
      _isEmulatorSignal.value = true;
      _brand.value = 'Developer';
      _model.value = 'unknown';
    }

    _locale.value = WidgetsBinding.instance.platformDispatcher.locale.toLanguageTag();
    return super.initialize();
  }
}
