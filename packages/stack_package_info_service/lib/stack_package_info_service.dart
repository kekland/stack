import 'package:package_info_plus/package_info_plus.dart';
import 'package:stack/stack.dart';

class PackageInfoService extends Service {
  PackageInfoService() : super(logger: Logger('PackageInfoService'));

  late final _info = $signal<PackageInfo?>(null);
  late final _appName = $computed(() => _info.value!.appName);
  late final _packageName = $computed(() => _info.value!.packageName);
  late final _version = $computed(() => _info.value!.version);
  late final _buildNumber = $computed(() => _info.value!.buildNumber);
  late final _buildSignature = $computed(() => _info.value!.buildSignature);
  late final _installerStore = $computed(() => _info.value!.installerStore);
  late final _installTime = $computed(() => _info.value!.installTime);
  late final _updateTime = $computed(() => _info.value!.updateTime);

  PackageInfo get info => _info.value!;
  String get appName => _appName.value;
  String get packageName => _packageName.value;
  String get version => _version.value;
  String get buildNumber => _buildNumber.value;
  String get buildSignature => _buildSignature.value;
  String? get installerStore => _installerStore.value;
  DateTime? get installTime => _installTime.value;
  DateTime? get updateTime => _updateTime.value;

  @override
  Future<void> initialize() async {
    _info.value = await PackageInfo.fromPlatform();
    return super.initialize();
  }
}
