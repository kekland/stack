import 'dart:async';

import 'package:latlong2/latlong.dart' as latlong2;
import '../../stack/lib/stack.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import '../../stack_permissions_service/lib/stack_permissions_service.dart';

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
  ///
  /// Returns either the last known position, or the first position update received.
  Future<geolocator.Position> start() async {
    if (isRunning) {
      logger.warning('Geolocation service is already started.');
      return currentLocation!;
    }

    // Check if location services are enabled.
    final isServiceEnabled = await geolocator.Geolocator.isLocationServiceEnabled();
    if (!isServiceEnabled) {
      logger.warning('Location services are disabled.');
      handleDisabledLocationServices();
      throw Exception('Location services are disabled.');
    }

    // Check for location permission.
    final permissionsService = di<PermissionsService>();
    final permission = permissionsService[Permission.locationWhenInUse];
    final status = await permission.request(evenIfPermanentlyDenied: false);

    if (status != PermissionStatus.granted) {
      logger.warning('Location permission not granted: $status');
      handlePermissionDenied();
      throw Exception('Location permission not granted: $status');
    }

    // Set the last known position as the initial value.
    final lastPosition = await geolocator.Geolocator.getLastKnownPosition();
    _locationSignal.value = lastPosition;

    // Listen to location updates.
    _geolocatorLocationSubscription = geolocator.Geolocator.getPositionStream().listen(_locationSignal.set);
    logger.info('Geolocation service started successfully.');

    if (lastPosition != null) {
      return lastPosition;
    } else {
      return await geolocator.Geolocator.getCurrentPosition();
    }
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
