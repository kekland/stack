import 'package:flutter/foundation.dart';
import 'package:stack/stack.dart';
import 'package:permission_handler/permission_handler.dart';

export 'package:permission_handler/permission_handler.dart' show Permission, PermissionStatus;

/// A service that manages app permissions.
///
/// It provides methods to check and request permissions, and exposes signals to notify about permission status changes.
///
/// You should generally extend this service to add shorthands for the permissions that you use:
///
/// ```dart
/// class MyPermissionsService extends PermissionsService {
///   MyPermissionsService() : super(permissions: {
///     Permission.camera,
///     Permission.location,
///   });
///
///   PermissionSignal get camera => this[Permission.camera];
///   PermissionSignal get location => this[Permission.location];
/// }
/// ```
///
/// To actually add the permissions to your app, you should follow the guides of the `permission_handler` package.
class PermissionsService extends Service {
  PermissionsService({required this.permissions}) : super(logger: Logger('PermissionsService')) {
    $appLifecycleListener(onShow: loadPermissions);
  }

  /// Set of permissions managed by this service.
  final Set<Permission> permissions;
  final _permissionSignalsMap = <Permission, PermissionSignal>{};

  /// Creates a new permission signal managed by this service.
  PermissionSignal $permissionSignal(Permission permission) {
    final signal = permissionSignal(this, permission);
    _permissionSignalsMap[permission] = signal;
    addDisposeCallback(signal.dispose);
    return signal;
  }

  @override
  Future<void> initialize() async {
    // Setup signals
    for (final permission in permissions) {
      $permissionSignal(permission);
    }

    await loadPermissions();
    return super.initialize();
  }

  @protected
  Future<void> loadPermissions() async {
    await Future.wait(_permissionSignalsMap.values.map((v) => v.load()));
  }

  /// Override this method to show a rationale dialog before requesting a permission. Return `true` to proceed with the
  /// request, or `false` to cancel it.
  ///
  /// By default, this method does nothing and returns `true`.
  Future<bool> handleShowRequestRationale(Permission permission) async {
    return true;
  }

  /// Override this method to show a dialog or notification when a permission is permanently denied. By default,
  /// this will open the app settings.
  Future<void> handlePermanentlyDenied(Permission permission) async {
    await openAppSettings();
  }

  /// Get a permission signal for a specific permission.
  PermissionSignal operator [](Permission permission) => _permissionSignalsMap[permission]!;

  /// Get the current status of a specific permission.
  PermissionStatus getStatus(Permission permission) => this[permission].value;

  /// Request a specific permission.
  Future<PermissionStatus> request(Permission permission) => this[permission].request();
}

/// Creates a signal to handle the state of a specific permission.
PermissionSignal permissionSignal(PermissionsService service, Permission permission) {
  return switch (permission) {
    Permission.locationAlways => LocationAlwaysPermissionSignal(service),
    _ => PermissionSignal(service, permission),
  };
}

/// A generic permission signal.
class PermissionSignal extends Signal<PermissionStatus?> {
  PermissionSignal(this.service, this.permission) : super(null) {
    load();
  }

  final PermissionsService service;
  final Permission permission;

  /// Load the status of the permission.
  Future<void> load() async {
    final status = await permission.status;
    value = status;
  }

  /// Request the permission.
  ///
  /// This method handles showing rationale and permanently denied cases via the service.
  Future<PermissionStatus> request() async {
    await load();

    // If granted, return early.
    if (value == PermissionStatus.granted) return value;

    // If permanently denied, handle it via the service call.
    if (value == PermissionStatus.permanentlyDenied) {
      await service.handlePermanentlyDenied(permission);
      return PermissionStatus.permanentlyDenied;
    }

    // Show rationale if needed.
    final shouldShowRequestRationale = await permission.shouldShowRequestRationale;
    if (shouldShowRequestRationale) {
      final proceed = await service.handleShowRequestRationale(permission);
      if (!proceed) return value;
    }

    // Actually request the permission.
    value = await permission.request();
    return value;
  }

  /// Get the current permission status value.
  ///
  /// Note that even though the base class allows null values, this will always return a non-null value after loading.
  /// It's expected that before using the service, all permissions are loaded.
  @override
  PermissionStatus get value => super.value!;
}

// Below are specific PermissionSignal implementations for special cases.

/// A permission signal for LocationAlways permission, which requires Location permission to be granted first.
class LocationAlwaysPermissionSignal extends PermissionSignal {
  LocationAlwaysPermissionSignal(PermissionsService service) : super(service, Permission.locationAlways);

  @override
  Future<PermissionStatus> request() async {
    final location = service[Permission.location];
    if (await location.request() != PermissionStatus.granted) return PermissionStatus.denied;

    return super.request();
  }
}
