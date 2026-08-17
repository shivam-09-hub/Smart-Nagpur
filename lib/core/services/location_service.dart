import 'package:geolocator/geolocator.dart';

import '../../domain/domain.dart';

enum LocationAccess { granted, serviceDisabled, denied, deniedForever }

class LocationServiceException implements Exception {
  const LocationServiceException(this.access, this.message);

  final LocationAccess access;
  final String message;

  @override
  String toString() => message;
}

abstract interface class LocationService {
  Future<LocationAccess> permissionStatus();

  Future<LocationAccess> requestPermission();

  Future<ProblemLocation> getCurrentLocation();

  Future<void> openAppSettings();

  Future<void> openLocationSettings();
}

class DeviceLocationService implements LocationService {
  const DeviceLocationService();

  @override
  Future<LocationAccess> permissionStatus() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationAccess.serviceDisabled;
    }
    return _mapPermission(await Geolocator.checkPermission());
  }

  @override
  Future<LocationAccess> requestPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationAccess.serviceDisabled;
    }
    final current = await Geolocator.checkPermission();
    if (current == LocationPermission.deniedForever) {
      return LocationAccess.deniedForever;
    }
    if (current == LocationPermission.whileInUse ||
        current == LocationPermission.always) {
      return LocationAccess.granted;
    }
    return _mapPermission(await Geolocator.requestPermission());
  }

  @override
  Future<ProblemLocation> getCurrentLocation() async {
    final access = await requestPermission();
    if (access != LocationAccess.granted) {
      throw LocationServiceException(access, _messageFor(access));
    }

    Position? position;

    // 1. Try instant last known location first (< 50ms)
    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null &&
          DateTime.now().difference(lastKnown.timestamp).inMinutes < 20) {
        position = lastKnown;
      }
    } catch (_) {}

    // 2. If no fresh last known position, get current position with medium accuracy (fast cellular/wifi + gps)
    if (position == null) {
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 4),
          ),
        );
      } catch (_) {
        // 3. Fallback to any last known position or low accuracy
        position = await Geolocator.getLastKnownPosition();
        if (position == null) {
          try {
            position = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.low,
                timeLimit: Duration(seconds: 3),
              ),
            );
          } catch (_) {}
        }
      }
    }

    if (position == null) {
      throw const LocationServiceException(
        LocationAccess.serviceDisabled,
        'Unable to determine your location. Please select the pin manually on the map.',
      );
    }

    return ProblemLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      address:
          'Nagpur (${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)})',
    );
  }

  @override
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  @override
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  LocationAccess _mapPermission(LocationPermission permission) {
    return switch (permission) {
      LocationPermission.always ||
      LocationPermission.whileInUse => LocationAccess.granted,
      LocationPermission.deniedForever => LocationAccess.deniedForever,
      _ => LocationAccess.denied,
    };
  }

  String _messageFor(LocationAccess access) => switch (access) {
    LocationAccess.serviceDisabled =>
      'Location services are turned off. Enable location and try again.',
    LocationAccess.denied =>
      'Location permission was denied. You can enter or select a location manually.',
    LocationAccess.deniedForever =>
      'Location permission is blocked. Enable it in app settings or select a location manually.',
    LocationAccess.granted => '',
  };
}
