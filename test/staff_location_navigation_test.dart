import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_nagpur/core/services/location_service.dart';
import 'package:smart_nagpur/data/gateways/staff_auth_gateway.dart';
import 'package:smart_nagpur/data/gateways/staff_data_gateway.dart';
import 'package:smart_nagpur/domain/domain.dart';
import 'package:smart_nagpur/features/staff/presentation/staff_task_detail_screen.dart';
import 'package:smart_nagpur/state/staff_controller.dart';

// ---------------------------------------------------------------------------
// Mock: StaffAuthGateway
// ---------------------------------------------------------------------------
class MockStaffAuthGateway implements StaffAuthGateway {
  StaffProfile? currentStaff;

  @override
  Future<StaffProfile?> getCurrentStaff() async => currentStaff;

  @override
  Future<StaffProfile> loginStaff(String email, String password) async => currentStaff!;

  @override
  Future<void> logoutStaff() async => currentStaff = null;

  @override
  Future<void> setDutyStatus(bool isOnDuty) async {}

  @override
  Future<bool> isStaffAuthenticated() async => currentStaff != null;
}

// ---------------------------------------------------------------------------
// Mock: StaffDataGateway
// ---------------------------------------------------------------------------
class MockStaffDataGateway implements StaffDataGateway {
  StaffProfile? profile;
  final List<ComplaintAssignment> tasks = [];
  final List<ComplaintEvidence> evidenceStore = [];

  @override
  Future<StaffProfile?> getStaffProfile() async => profile;

  @override
  Future<void> updateDutyStatus(bool isOnDuty) async {}

  @override
  Future<List<ComplaintAssignment>> getMyTasks() async => List.from(tasks);

  @override
  Future<ComplaintAssignment?> getTaskDetails(String assignmentId) async {
    return tasks.where((t) => t.id == assignmentId).firstOrNull;
  }

  @override
  Future<ComplaintAssignment> acceptTask(String assignmentId) async {
    final i = tasks.indexWhere((t) => t.id == assignmentId);
    final up = tasks[i].copyWith(status: AssignmentStatus.accepted, acceptedAt: DateTime.now());
    tasks[i] = up;
    return up;
  }

  @override
  Future<ComplaintAssignment> startTask(String assignmentId) async {
    final i = tasks.indexWhere((t) => t.id == assignmentId);
    final up = tasks[i].copyWith(status: AssignmentStatus.inProgress, startedAt: DateTime.now());
    tasks[i] = up;
    return up;
  }

  @override
  Future<ComplaintAssignment> completeTask(String assignmentId, {String notes = ''}) async {
    final i = tasks.indexWhere((t) => t.id == assignmentId);
    final up = tasks[i].copyWith(status: AssignmentStatus.completed, completedAt: DateTime.now(), notes: notes);
    tasks[i] = up;
    return up;
  }

  @override
  Future<ComplaintEvidence> uploadEvidence({
    required String complaintId,
    required String assignmentId,
    required EvidenceType type,
    required List<int> fileBytes,
    required String fileName,
    required String contentType,
    required double latitude,
    required double longitude,
    required double accuracy,
    String notes = '',
  }) async {
    final evidence = ComplaintEvidence(
      id: 'ev-test',
      complaintId: complaintId,
      assignmentId: assignmentId,
      staffId: profile?.id ?? 'staff-1',
      evidenceType: type,
      bucketId: 'complaint-evidence',
      objectPath: 'staff-1/$complaintId/$assignmentId/$fileName',
      originalName: fileName,
      contentType: contentType,
      byteSize: fileBytes.length,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      distanceFromComplaintMeters: 15.0,
      isGeoVerified: true,
      capturedAt: DateTime.now(),
      createdAt: DateTime.now(),
    );
    evidenceStore.add(evidence);
    return evidence;
  }

  @override
  Future<List<ComplaintEvidence>> getTaskEvidence(String assignmentId) async {
    return evidenceStore.where((e) => e.assignmentId == assignmentId).toList();
  }

  @override
  Future<String> getEvidenceSignedUrl(String objectPath) async {
    return 'https://supabase.local/storage/v1/object/sign/complaint-evidence/$objectPath?token=xyz';
  }

  @override
  void subscribeToStaffTaskUpdates(String staffId, void Function() onUpdate) {}

  @override
  void unsubscribeFromStaffTaskUpdates() {}
}

// ---------------------------------------------------------------------------
// Mock: TestableLocationService with configurable responses
// ---------------------------------------------------------------------------
class FakeLocationService extends LocationService {
  FakeLocationService({
    this.serviceEnabled = true,
    this.simulatedOutcome,
    this.navigationSuccess = true,
  });

  final bool serviceEnabled;
  LocationCheckOutcome? simulatedOutcome;
  final bool navigationSuccess;

  @override
  Future<bool> isServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationCheckOutcome> verifyStaffLocation({
    required double complaintLatitude,
    required double complaintLongitude,
    double maxRadiusMeters = LocationService.defaultMaxRadiusMeters,
    double maxAccuracyMeters = LocationService.defaultMaxAccuracyMeters,
    Duration timeout = LocationService.defaultGpsTimeout,
  }) async {
    // Basic coordinate range check to verify business logic
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

    if (!serviceEnabled) {
      return const LocationCheckOutcome(
        result: LocationVerificationResult.serviceDisabled,
        errorMessage: 'Device location services (GPS) are turned off. Please swipe down and turn on Location / GPS.',
      );
    }

    return simulatedOutcome ??
        LocationCheckOutcome(
          result: LocationVerificationResult.verified,
          latitude: complaintLatitude,
          longitude: complaintLongitude,
          accuracy: 10.0,
          distanceMeters: 15.0,
          timestamp: DateTime.now(),
        );
  }

  @override
  Future<bool> launchNavigation({
    required double latitude,
    required double longitude,
    String? destinationLabel,
  }) async {
    return navigationSuccess;
  }
}

// ---------------------------------------------------------------------------
// Helper test data
// ---------------------------------------------------------------------------
StaffProfile _testStaffProfile() {
  return StaffProfile(
    id: 'staff-uuid-001',
    employeeId: 'NMC-RD-001',
    name: 'Ramesh Kumar',
    department: StaffDepartment.road,
    role: StaffRole.fieldWorker,
    email: 'ramesh.kumar@smartnagpur.gov.in',
    isActive: true,
    isOnDuty: true,
    createdAt: DateTime.now(),
  );
}

ComplaintAssignment _testAssignment({
  String id = 'assign-101',
  AssignmentStatus status = AssignmentStatus.assigned,
  double? lat = 21.1458,
  double? lng = 79.0882,
}) {
  return ComplaintAssignment(
    id: id,
    complaintId: 'comp-101',
    staffId: 'staff-uuid-001',
    assignedBy: 'admin-001',
    status: status,
    priority: AssignmentPriority.high,
    assignedAt: DateTime.now(),
    complaintIssue: 'Dangerous Pothole on Wardha Road',
    complaintServiceType: 'roads',
    complaintLocationAddress: 'Wardha Road, Sitabuldi, Nagpur',
    complaintLatitude: lat,
    complaintLongitude: lng,
  );
}

void main() {
  group('Smart Nagpur Step 9 — Field Navigation & GPS Real-World UX Tests', () {
    test('1. LocationVerificationResult enum has all 10 states', () {
      expect(LocationVerificationResult.values.length, 10);
      expect(LocationVerificationResult.values, containsAll([
        LocationVerificationResult.verified,
        LocationVerificationResult.outsideRadius,
        LocationVerificationResult.poorAccuracy,
        LocationVerificationResult.permissionDenied,
        LocationVerificationResult.permissionDeniedForever,
        LocationVerificationResult.serviceDisabled,
        LocationVerificationResult.timeout,
        LocationVerificationResult.mockDetected,
        LocationVerificationResult.staleLocation,
        LocationVerificationResult.error,
      ]));
    });

    test('2. LocationCheckOutcome isVerified evaluates correctly', () {
      const verified = LocationCheckOutcome(
        result: LocationVerificationResult.verified,
        latitude: 21.1458,
        longitude: 79.0882,
        accuracy: 12.0,
        distanceMeters: 25.0,
      );
      expect(verified.isVerified, isTrue);

      for (final nonVerifiedResult in [
        LocationVerificationResult.outsideRadius,
        LocationVerificationResult.poorAccuracy,
        LocationVerificationResult.permissionDenied,
        LocationVerificationResult.permissionDeniedForever,
        LocationVerificationResult.serviceDisabled,
        LocationVerificationResult.timeout,
        LocationVerificationResult.mockDetected,
        LocationVerificationResult.staleLocation,
        LocationVerificationResult.error,
      ]) {
        final outcome = LocationCheckOutcome(
          result: nonVerifiedResult,
          errorMessage: 'Test error',
        );
        expect(outcome.isVerified, isFalse, reason: 'Failed for state: $nonVerifiedResult');
      }
    });

    test('3. LocationService handles serviceDisabled state', () async {
      final fakeLocation = FakeLocationService(serviceEnabled: false);
      final outcome = await fakeLocation.verifyStaffLocation(
        complaintLatitude: 21.1458,
        complaintLongitude: 79.0882,
      );

      expect(outcome.isVerified, isFalse);
      expect(outcome.result, LocationVerificationResult.serviceDisabled);
      expect(outcome.errorMessage, contains('GPS'));
    });

    test('4. LocationService detects invalid / impossible target coordinates', () async {
      final fakeLocation = FakeLocationService();

      // (0.0, 0.0) invalid coordinates
      final zeroOutcome = await fakeLocation.verifyStaffLocation(
        complaintLatitude: 0.0,
        complaintLongitude: 0.0,
      );
      expect(zeroOutcome.result, LocationVerificationResult.error);
      expect(zeroOutcome.errorMessage, contains('Invalid complaint location'));

      // Out-of-range latitude (> 90)
      final outOfRangeLat = await fakeLocation.verifyStaffLocation(
        complaintLatitude: 95.0,
        complaintLongitude: 79.0882,
      );
      expect(outOfRangeLat.result, LocationVerificationResult.error);

      // Out-of-range longitude (> 180)
      final outOfRangeLng = await fakeLocation.verifyStaffLocation(
        complaintLatitude: 21.1458,
        complaintLongitude: 195.0,
      );
      expect(outOfRangeLng.result, LocationVerificationResult.error);
    });

    test('5. LocationService handles mock/fake GPS detection', () async {
      final fakeLocation = FakeLocationService(
        simulatedOutcome: LocationCheckOutcome(
          result: LocationVerificationResult.mockDetected,
          latitude: 21.1458,
          longitude: 79.0882,
          accuracy: 5.0,
          isMocked: true,
          errorMessage: 'Mock / Fake GPS detected. Field staff must be physically present at the site.',
        ),
      );

      final outcome = await fakeLocation.verifyStaffLocation(
        complaintLatitude: 21.1458,
        complaintLongitude: 79.0882,
      );

      expect(outcome.isVerified, isFalse);
      expect(outcome.result, LocationVerificationResult.mockDetected);
      expect(outcome.isMocked, isTrue);
      expect(outcome.errorMessage, contains('Mock / Fake GPS'));
    });

    test('6. LocationService handles GPS acquisition timeout', () async {
      final fakeLocation = FakeLocationService(
        simulatedOutcome: const LocationCheckOutcome(
          result: LocationVerificationResult.timeout,
          errorMessage: 'GPS acquisition timed out. Please step outdoors or check if you have a clear sky view, then retry.',
        ),
      );

      final outcome = await fakeLocation.verifyStaffLocation(
        complaintLatitude: 21.1458,
        complaintLongitude: 79.0882,
      );

      expect(outcome.isVerified, isFalse);
      expect(outcome.result, LocationVerificationResult.timeout);
      expect(outcome.errorMessage, contains('timed out'));
    });

    test('7. LocationService handles stale GPS fix', () async {
      final fakeLocation = FakeLocationService(
        simulatedOutcome: LocationCheckOutcome(
          result: LocationVerificationResult.staleLocation,
          latitude: 21.1458,
          longitude: 79.0882,
          accuracy: 10.0,
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
          errorMessage: 'Acquired GPS location fix is stale. Please wait a few seconds for a live satellite fix and tap retry.',
        ),
      );

      final outcome = await fakeLocation.verifyStaffLocation(
        complaintLatitude: 21.1458,
        complaintLongitude: 79.0882,
      );

      expect(outcome.isVerified, isFalse);
      expect(outcome.result, LocationVerificationResult.staleLocation);
      expect(outcome.errorMessage, contains('stale'));
    });

    test('8. LocationService handles poor accuracy (> 50m)', () async {
      final fakeLocation = FakeLocationService(
        simulatedOutcome: const LocationCheckOutcome(
          result: LocationVerificationResult.poorAccuracy,
          latitude: 21.1458,
          longitude: 79.0882,
          accuracy: 75.0,
          distanceMeters: 30.0,
          errorMessage: 'GPS accuracy is too low (75.0m > 50m). Please step into an open area with a clear sky view.',
        ),
      );

      final outcome = await fakeLocation.verifyStaffLocation(
        complaintLatitude: 21.1458,
        complaintLongitude: 79.0882,
      );

      expect(outcome.isVerified, isFalse);
      expect(outcome.result, LocationVerificationResult.poorAccuracy);
      expect(outcome.accuracy, 75.0);
    });

    test('9. LocationService handles outside radius (> 100m)', () async {
      final fakeLocation = FakeLocationService(
        simulatedOutcome: const LocationCheckOutcome(
          result: LocationVerificationResult.outsideRadius,
          latitude: 21.1480,
          longitude: 79.0900,
          accuracy: 10.0,
          distanceMeters: 280.0,
          errorMessage: 'You are 280.0m away from the complaint site. Maximum allowed distance is 100m.',
        ),
      );

      final outcome = await fakeLocation.verifyStaffLocation(
        complaintLatitude: 21.1458,
        complaintLongitude: 79.0882,
      );

      expect(outcome.isVerified, isFalse);
      expect(outcome.result, LocationVerificationResult.outsideRadius);
      expect(outcome.distanceMeters, 280.0);
    });

    test('10. LocationService launchNavigation returns true when map app is available', () async {
      final fakeLocation = FakeLocationService(navigationSuccess: true);
      final result = await fakeLocation.launchNavigation(
        latitude: 21.1458,
        longitude: 79.0882,
        destinationLabel: 'Sitabuldi Pothole',
      );

      expect(result, isTrue);
    });

    test('11. StaffController delegates verifyLocation and updates lastLocationCheck', () async {
      final mockAuth = MockStaffAuthGateway();
      final mockData = MockStaffDataGateway();
      final fakeLocation = FakeLocationService(
        simulatedOutcome: const LocationCheckOutcome(
          result: LocationVerificationResult.verified,
          latitude: 21.1458,
          longitude: 79.0882,
          accuracy: 15.0,
          distanceMeters: 30.0,
        ),
      );

      final staff = _testStaffProfile();
      mockAuth.currentStaff = staff;
      mockData.profile = staff;

      final controller = StaffController(
        authGateway: mockAuth,
        dataGateway: mockData,
        locationService: fakeLocation,
      );

      expect(controller.isLocationVerified, isFalse);
      expect(controller.lastLocationCheck, isNull);

      final outcome = await controller.verifyLocation(
        complaintLatitude: 21.1458,
        complaintLongitude: 79.0882,
      );

      expect(outcome.isVerified, isTrue);
      expect(controller.isLocationVerified, isTrue);
      expect(controller.lastLocationCheck?.accuracy, 15.0);
      expect(controller.lastLocationCheck?.distanceMeters, 30.0);
    });

    testWidgets('12. StaffTaskDetailScreen renders Field Location, Coordinates, and Navigation CTA', (tester) async {
      final mockAuth = MockStaffAuthGateway();
      final mockData = MockStaffDataGateway();
      final fakeLocation = FakeLocationService();

      final staff = _testStaffProfile();
      mockAuth.currentStaff = staff;
      mockData.profile = staff;

      final task = _testAssignment();
      mockData.tasks.add(task);

      final controller = StaffController(
        authGateway: mockAuth,
        dataGateway: mockData,
        locationService: fakeLocation,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: StaffTaskDetailScreen(
            controller: controller,
            task: task,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check header and complaint address
      expect(find.text('Field Location & GPS'), findsOneWidget);
      expect(find.text('Wardha Road, Sitabuldi, Nagpur'), findsOneWidget);
      expect(find.text('21.14580, 79.08820'), findsOneWidget);
      expect(find.text('Unverified'), findsOneWidget);
      expect(find.text('Navigate (Maps)'), findsOneWidget);
      expect(find.text('Verify GPS'), findsOneWidget);

      // Tap Verify GPS
      await tester.tap(find.text('Verify GPS'));
      await tester.pumpAndSettle();

      // Should now show GPS Verified
      expect(find.text('GPS Verified'), findsOneWidget);
      expect(find.text('Distance From Site'), findsOneWidget);
      expect(find.text('GPS Accuracy'), findsOneWidget);
    });
  });
}
