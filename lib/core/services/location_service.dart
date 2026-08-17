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

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
    return ProblemLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      address: 'Selected GPS location',
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
