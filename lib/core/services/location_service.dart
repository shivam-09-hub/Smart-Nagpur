import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smart_nagpur/domain/domain.dart';
import 'package:url_launcher/url_launcher.dart';

enum LocationAccess {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
}

class LocationServiceException implements Exception {
  const LocationServiceException(
    this.message, {
    this.access = LocationAccess.denied,
  });

  final String message;
  final LocationAccess access;

  @override
  String toString() => message;
}

enum LocationVerificationResult {
  verified,
  outsideRadius,
  poorAccuracy,
  permissionDenied,
  permissionDeniedForever,
  serviceDisabled,
  timeout,
  mockDetected,
  staleLocation,
  error,
}

class LocationCheckOutcome {
  const LocationCheckOutcome({
    required this.result,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.distanceMeters,
    this.errorMessage,
    this.timestamp,
    this.isMocked = false,
  });

  final LocationVerificationResult result;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final double? distanceMeters;
  final String? errorMessage;
  final DateTime? timestamp;
  final bool isMocked;

  bool get isVerified => result == LocationVerificationResult.verified;
}

class LocationService {
  const LocationService();

  static const double defaultMaxRadiusMeters = 100.0;
  static const double defaultMaxAccuracyMeters = 50.0;
  static const Duration defaultGpsTimeout = Duration(seconds: 15);

  Future<bool> isServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (_) {
      return false;
    }
  }

  Future<LocationPermission> checkPermission() async {
    try {
      return await Geolocator.checkPermission();
    } catch (_) {
      return LocationPermission.denied;
    }
  }

  Future<LocationPermission> requestPermission() async {
    try {
      return await Geolocator.requestPermission();
    } catch (_) {
      return LocationPermission.denied;
    }
  }

  Future<Position?> getCurrentPosition({Duration timeLimit = defaultGpsTimeout}) async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: timeLimit,
        ),
      );
    } on TimeoutException {
      debugPrint('LocationService.getCurrentPosition timed out after $timeLimit');
      return null;
    } catch (e) {
      debugPrint('LocationService.getCurrentPosition failed: $e');
      return null;
    }
  }

  Future<ProblemLocation> getCurrentLocation() async {
    final serviceEnabled = await isServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceException(
        'Location services (GPS) are disabled on your device. Please enable GPS in your device settings.',
        access: LocationAccess.serviceDisabled,
      );
    }

    var permission = await checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationServiceException(
          'Location permission was denied. Please allow location access to tag the issue location.',
          access: LocationAccess.denied,
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationServiceException(
        'Location permissions are permanently denied. Please enable them in app settings.',
        access: LocationAccess.deniedForever,
      );
    }

    final position = await getCurrentPosition();
    if (position == null) {
      throw const LocationServiceException(
        'Unable to determine current GPS position. Please try again or select location on the map.',
        access: LocationAccess.denied,
      );
    }

    return ProblemLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      address: 'Lat: ${position.latitude.toStringAsFixed(5)}, Long: ${position.longitude.toStringAsFixed(5)}',
    );
  }

  Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (_) {
      return false;
    }
  }

  Future<bool> openAppSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (_) {
      return false;
    }
  }

  double calculateDistanceMeters({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  Future<LocationCheckOutcome> verifyStaffLocation({
    required double complaintLatitude,
    required double complaintLongitude,
    double maxRadiusMeters = defaultMaxRadiusMeters,
    double maxAccuracyMeters = defaultMaxAccuracyMeters,
    Duration timeout = defaultGpsTimeout,
  }) async {
    // 1. Validate Target Coordinates
    if (complaintLatitude < -90.0 ||
        complaintLatitude > 90.0 ||
        complaintLongitude < -180.0 ||
        complaintLongitude > 180.0 ||
        (complaintLatitude == 0.0 && complaintLongitude == 0.0)) {
      return const LocationCheckOutcome(
        result: LocationVerificationResult.error,
        errorMessage: 'Invalid complaint location coordinates attached to this task.',
      );
    }

    // 2. Hardware GPS Service Status
    final serviceEnabled = await isServiceEnabled();
    if (!serviceEnabled) {
      return const LocationCheckOutcome(
        result: LocationVerificationResult.serviceDisabled,
        errorMessage: 'Device location services (GPS) are turned off. Please swipe down and turn on Location / GPS.',
      );
    }

    // 3. Runtime Permissions
    var permission = await checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
      if (permission == LocationPermission.denied) {
        return const LocationCheckOutcome(
          result: LocationVerificationResult.permissionDenied,
          errorMessage: 'Location permission was denied. Tap to grant permission to verify your on-site presence.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return const LocationCheckOutcome(
        result: LocationVerificationResult.permissionDeniedForever,
        errorMessage: 'Location permissions are permanently denied. Please open App Settings and enable Location.',
      );
    }

    // 4. Position Acquisition with Timeout
    final Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: timeout,
        ),
      );
    } on TimeoutException {
      return const LocationCheckOutcome(
        result: LocationVerificationResult.timeout,
        errorMessage: 'GPS acquisition timed out. Please step outdoors or check if you have a clear sky view, then retry.',
      );
    } catch (e) {
      debugPrint('verifyStaffLocation error: $e');
      return LocationCheckOutcome(
        result: LocationVerificationResult.error,
        errorMessage: 'Unable to acquire accurate GPS fix: ${e.toString()}',
      );
    }

    // 5. Mock Location Detection
    if (position.isMocked) {
      return LocationCheckOutcome(
        result: LocationVerificationResult.mockDetected,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: position.timestamp,
        isMocked: true,
        errorMessage: 'Mock / Fake GPS detected. Field staff must be physically present at the site. Please disable mock locations.',
      );
    }

    // 6. Stale Location Detection (> 3 minutes old)
    final now = DateTime.now();
    final posTime = position.timestamp;
    if (posTime.isBefore(now.subtract(const Duration(minutes: 3)))) {
      return LocationCheckOutcome(
        result: LocationVerificationResult.staleLocation,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: posTime,
        errorMessage: 'Acquired GPS location fix is stale. Please wait a few seconds for a live satellite fix and tap retry.',
      );
    }

    // 7. Calculate Real Distance
    final distance = calculateDistanceMeters(
      startLatitude: position.latitude,
      startLongitude: position.longitude,
      endLatitude: complaintLatitude,
      endLongitude: complaintLongitude,
    );

    // 8. Evaluate Accuracy Threshold
    if (position.accuracy > maxAccuracyMeters) {
      return LocationCheckOutcome(
        result: LocationVerificationResult.poorAccuracy,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        distanceMeters: distance,
        timestamp: posTime,
        errorMessage: 'GPS accuracy is too low (${position.accuracy.toStringAsFixed(1)}m > ${maxAccuracyMeters.toStringAsFixed(0)}m). Please step into an open area with a clear sky view.',
      );
    }

    // 9. Evaluate Proximity Radius
    if (distance > maxRadiusMeters) {
      return LocationCheckOutcome(
        result: LocationVerificationResult.outsideRadius,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        distanceMeters: distance,
        timestamp: posTime,
        errorMessage: 'You are ${distance.toStringAsFixed(1)}m away from the complaint site. Maximum allowed distance is ${maxRadiusMeters.toStringAsFixed(0)}m.',
      );
    }

    // 10. Verified!
    return LocationCheckOutcome(
      result: LocationVerificationResult.verified,
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      distanceMeters: distance,
      timestamp: posTime,
    );
  }

  Future<bool> launchNavigation({
    required double latitude,
    required double longitude,
    String? destinationLabel,
  }) async {
    final encodedLabel = Uri.encodeComponent(destinationLabel ?? 'Nagpur Civic Complaint Site');
    // 1. Google Maps Navigation Intent (turn-by-turn driving mode)
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving',
    );
    // 2. Native geo: URI intent (Google Maps, Apple Maps, OpenStreetMap)
    final geoUrl = Uri.parse('geo:$latitude,$longitude?q=$latitude,$longitude($encodedLabel)');
    // 3. Fallback web map URL
    final webUrl = Uri.parse('https://maps.google.com/?q=$latitude,$longitude');

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        return await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(geoUrl)) {
        return await launchUrl(geoUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(webUrl)) {
        return await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (e) {
      debugPrint('LocationService.launchNavigation failed: $e');
      return false;
    }
  }
}

class DeviceLocationService extends LocationService {
  const DeviceLocationService();
}
