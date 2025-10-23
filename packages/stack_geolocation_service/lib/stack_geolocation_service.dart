import 'dart:async';

import 'package:latlong2/latlong.dart' as latlong2;
import 'package:stack/stack.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:stack_permissions_service/stack_permissions_service.dart';

extension LatLngExtension on geolocator.Position {
  latlong2.LatLng get asLatLng => latlong2.LatLng(latitude, longitude);
}

class LocationSignal extends Signal<geolocator.Position?> with StreamSignalMixin {
  LocationSignal(super.internalValue);
}

class GeolocationService extends Service {
  GeolocationService() : super(logger: Logger('GeolocationService'));

  late final _locationSignal = LocationSignal(null);
  LocationSignal get locationSignal => _locationSignal;
  geolocator.Position? get currentLocation => _locationSignal.value;

  StreamSubscription? _geolocatorLocationSubscription;
  bool get isRunning => _geolocatorLocationSubscription != null;

  Future<void> handleDisabledLocationServices() async {
    await geolocator.Geolocator.openLocationSettings();
  }

  Future<void> handlePermissionDenied() async {}

  /// Starts the geolocation service.
  Future<void> start() async {
    if (isRunning) {
      logger.warning('Geolocation service is already started.');
      return;
    }

    // Check if location services are enabled.
    final isServiceEnabled = await geolocator.Geolocator.isLocationServiceEnabled();
    if (!isServiceEnabled) {
      logger.warning('Location services are disabled.');
      handleDisabledLocationServices();
      return;
    }

    // Check for location permission.
    final permissionsService = di<PermissionsService>();
    final permission = permissionsService[Permission.locationWhenInUse];
    final status = await permission.request();

    if (status != PermissionStatus.granted) {
      logger.warning('Location permission not granted: $status');
      handlePermissionDenied();
      return;
    }

    // Set the last known position as the initial value.
    final lastPosition = await geolocator.Geolocator.getLastKnownPosition();
    _locationSignal.value = lastPosition;

    // Listen to location updates.
    _geolocatorLocationSubscription = geolocator.Geolocator.getPositionStream().listen(_locationSignal.set);
    logger.info('Geolocation service started successfully.');
  }

  /// Stops the geolocation service.
  Future<void> stop() async {
    if (!isRunning) {
      logger.warning('Geolocation service is not started.');
      return;
    }

    _geolocatorLocationSubscription?.cancel();
    logger.info('Geolocation service stopped.');
  }

  @override
  void dispose() {
    if (isRunning) stop();
    super.dispose();
  }
}
