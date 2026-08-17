import 'package:flutter_test/flutter_test.dart';
import 'package:smart_nagpur/core/services/location_service.dart';
import 'package:smart_nagpur/data/gateways/admin_auth_gateway.dart';
import 'package:smart_nagpur/data/gateways/admin_data_gateway.dart';
import 'package:smart_nagpur/data/gateways/staff_auth_gateway.dart';
import 'package:smart_nagpur/data/gateways/staff_data_gateway.dart';
import 'package:smart_nagpur/domain/domain.dart';
import 'package:smart_nagpur/state/admin_controller.dart';
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
    if (fileBytes.isEmpty || fileBytes.length > 10 * 1024 * 1024) {
      throw ArgumentError('Evidence file size must be between 1 byte and 10 MB.');
    }

    final rawExt = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
    final validExt = switch (rawExt) {
      'jpg' || 'jpeg' => 'jpg',
      'png' => 'png',
      'webp' => 'webp',
      'pdf' => 'pdf',
      _ => throw ArgumentError('Unsupported file extension: .$rawExt. Allowed: .jpg, .png, .webp, .pdf'),
    };

    if (type == EvidenceType.inspectionReport) {
      if (validExt != 'pdf' && validExt != 'jpg' && validExt != 'png') {
        throw ArgumentError('Inspection reports must be in PDF or image format.');
      }
    } else {
      if (validExt == 'pdf') {
        throw ArgumentError('Photographic evidence cannot be a PDF document.');
      }
    }

    final distance = 25.0; // Simulated on-site distance
    final isVerified = distance <= 100.0 && accuracy <= 50.0;

    final evidence = ComplaintEvidence(
      id: 'evi-${DateTime.now().millisecondsSinceEpoch}',
      complaintId: complaintId,
      assignmentId: assignmentId,
      staffId: profile?.id ?? 'staff-1',
      evidenceType: type,
      bucketId: 'complaint-evidence',
      objectPath: '${profile?.id}/$complaintId/$assignmentId/$fileName',
      originalName: fileName,
      contentType: contentType,
      byteSize: fileBytes.length,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      distanceFromComplaintMeters: distance,
      isGeoVerified: isVerified,
      capturedAt: DateTime.now(),
      createdAt: DateTime.now(),
      notes: notes,
      signedUrl: 'https://supabase.local/storage/v1/object/sign/complaint-evidence/$fileName?token=xyz',
      staffName: profile?.name,
      staffEmployeeId: profile?.employeeId,
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
// Mock: AdminAuthGateway
// ---------------------------------------------------------------------------
class MockAdminAuthGateway implements AdminAuthGateway {
  AdminProfile? currentAdmin;

  @override
  Future<AdminProfile?> getCurrentAdmin() async => currentAdmin;

  @override
  Future<AdminProfile> loginAdmin(String email, String password) async {
    final admin = AdminProfile(
      id: 'admin-1',
      name: 'Test Admin',
      email: email,
      role: AdminRole.superAdmin,
      phone: '9876543210',
      isActive: true,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );
    currentAdmin = admin;
    return admin;
  }

  @override
  Future<void> logoutAdmin() async => currentAdmin = null;

  @override
  Future<void> createAdmin(String email, String password, AdminProfile profile) async {}

  @override
  Future<void> updateAdminProfile(AdminProfile profile) async => currentAdmin = profile;

  @override
  Future<void> changeAdminPassword(String oldPassword, String newPassword) async {}

  @override
  Future<bool> isAdminAuthenticated() async => currentAdmin != null;

  @override
  Future<AdminProfile?> getAdminById(String adminId) async => currentAdmin;

  @override
  Future<List<AdminProfile>> getAllAdmins() async => currentAdmin != null ? [currentAdmin!] : [];

  @override
  Future<void> deactivateAdmin(String adminId) async {}
}

// ---------------------------------------------------------------------------
// Mock: AdminDataGateway
// ---------------------------------------------------------------------------
class MockAdminDataGateway implements AdminDataGateway {
  final List<ComplaintEvidence> evidenceStore = [];

  @override
  Future<AdminStats> getAdminStats() async => AdminStats(
    totalComplaints: 10,
    pendingComplaints: 5,
    resolvedComplaints: 5,
    totalVendorApplications: 2,
    pendingApplications: 1,
    approvedApplications: 1,
    rejectedApplications: 0,
    totalNotifications: 15,
    unreadNotifications: 3,
    totalUsers: 20,
    activeUsers: 20,
    lastUpdated: DateTime.now(),
  );

  @override
  Future<List<ComplaintRecord>> getPendingComplaints({int limit = 50, int offset = 0}) async => [];
  @override
  Future<ComplaintRecord?> getComplaintDetails(String complaintId) async => null;
  @override
  Future<void> updateComplaintStatus(String complaintId, ComplaintStatus status, {String notes = ''}) async {}
  @override
  Future<void> addComplaintTimeline(String complaintId, RequestTimelineEntry entry) async {}
  @override
  Future<AdminReview?> getComplaintReview(String complaintId) async => null;
  @override
  Future<void> submitComplaintReview(AdminReview review) async {}
  @override
  Future<List<VendorApplication>> getPendingApplications({int limit = 50, int offset = 0}) async => [];
  @override
  Future<VendorApplication?> getApplicationDetails(String applicationId) async => null;
  @override
  Future<void> updateApplicationStatus(String applicationId, VendorStatus status, {String notes = ''}) async {}
  @override
  Future<void> addApplicationTimeline(String applicationId, RequestTimelineEntry entry) async {}
  @override
  Future<AdminReview?> getApplicationReview(String applicationId) async => null;
  @override
  Future<void> submitApplicationReview(AdminReview review) async {}
  @override
  Future<List<AppNotification>> getAdminNotifications({int limit = 50, int offset = 0}) async => [];
  @override
  Future<void> sendNotificationToUser(String userId, AppNotification notification) async {}
  @override
  Future<void> sendBroadcastNotification(AppNotification notification) async {}
  @override
  Future<void> markNotificationAsRead(String notificationId) async {}
  @override
  Future<List<UserProfile>> getUsers({int limit = 50, int offset = 0}) async => [];
  @override
  Future<UserProfile?> getUserDetails(String userId) async => null;
  @override
  Future<void> suspendUser(String userId, String reason) async {}
  @override
  Future<void> reactivateUser(String userId) async {}
  @override
  Future<Map<String, int>> getComplaintsByService() async => {};
  @override
  Future<Map<String, int>> getComplaintsByStatus() async => {};
  @override
  Future<Map<String, int>> getApplicationsByStatus() async => {};
  @override
  Future<List<Map<String, dynamic>>> getDailyStats(int days) async => [];
  @override
  Future<Map<String, dynamic>> getMonthlyReport(int month, int year) async => {};
  @override
  Future<StaffProfile> createStaff({
    required String name,
    required String email,
    required String employeeId,
    required StaffDepartment department,
    StaffRole role = StaffRole.fieldWorker,
    String phone = '',
    String zone = 'ALL',
    String ward = '',
    String? password,
  }) async => throw UnimplementedError();
  @override
  Future<List<StaffProfile>> getStaffMembers({StaffDepartment? department, bool? isActive}) async => [];
  @override
  Future<StaffProfile?> getStaffMember(String staffId) async => null;
  @override
  Future<ComplaintAssignment> assignComplaint({
    required String complaintId,
    required String staffId,
    AssignmentPriority priority = AssignmentPriority.medium,
    String instructions = '',
  }) async => throw UnimplementedError();
  @override
  Future<ComplaintAssignment?> getComplaintAssignment(String assignmentId) async => null;
  @override
  Future<List<ComplaintAssignment>> getComplaintAssignmentsHistory(String complaintId) async => [];
  @override
  Future<ComplaintAssignment> approveComplaintAssignment(String assignmentId, {String reviewNotes = ''}) async =>
      throw UnimplementedError();
  @override
  Future<ComplaintAssignment> requestReworkComplaintAssignment(String assignmentId, {String reworkInstructions = ''}) async =>
      throw UnimplementedError();
  @override
  Future<List<ComplaintEvidence>> getComplaintEvidence(String complaintId) async {
    return evidenceStore.where((e) => e.complaintId == complaintId).toList();
  }
  @override
  Future<String> getEvidenceSignedUrl(String objectPath) async {
    return 'https://supabase.local/storage/v1/object/sign/complaint-evidence/$objectPath?token=abc';
  }
  @override
  Future<AdminOperationsDashboard> getOperationsDashboard({AdminOperationsFilter? filter}) async =>
      const AdminOperationsDashboard();
  @override
  void subscribeToAdminLiveUpdates(void Function() onUpdate) {}
  @override
  void unsubscribeFromAdminLiveUpdates() {}
}

// ---------------------------------------------------------------------------
// Helper to build a StaffProfile for tests
// ---------------------------------------------------------------------------
StaffProfile _testStaffProfile({
  String id = 'staff-1',
  String name = 'Ramesh Kumar',
  String email = 'ramesh@smartnagpur.gov.in',
  String employeeId = 'NMC-RD-001',
  StaffDepartment department = StaffDepartment.road,
  StaffRole role = StaffRole.fieldWorker,
  bool isOnDuty = true,
  bool isActive = true,
}) {
  return StaffProfile(
    id: id,
    name: name,
    email: email,
    employeeId: employeeId,
    department: department,
    role: role,
    isOnDuty: isOnDuty,
    isActive: isActive,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  group('Step 8B — Domain Model & GPS Verification Unit Tests', () {
    test('1. ComplaintEvidence JSON serialization and deserialization', () {
      final now = DateTime.now();
      final evidence = ComplaintEvidence(
        id: 'ev-101',
        complaintId: 'comp-101',
        assignmentId: 'assign-101',
        staffId: 'staff-101',
        evidenceType: EvidenceType.beforeWork,
        bucketId: 'complaint-evidence',
        objectPath: 'staff-101/comp-101/assign-101/before.jpg',
        originalName: 'before.jpg',
        contentType: 'image/jpeg',
        byteSize: 1048576,
        latitude: 21.1458,
        longitude: 79.0882,
        accuracy: 12.5,
        distanceFromComplaintMeters: 35.0,
        isGeoVerified: true,
        capturedAt: now,
        createdAt: now,
        notes: 'Pre-work inspection photo',
        signedUrl: 'https://storage/signed/before.jpg',
      );

      final json = evidence.toJson();
      expect(json['id'], 'ev-101');
      expect(json['evidence_type'], 'beforeWork');
      expect(json['is_geo_verified'], isTrue);

      final reconstructed = ComplaintEvidence.fromJson({
        'id': 'ev-101',
        'complaint_id': 'comp-101',
        'assignment_id': 'assign-101',
        'staff_id': 'staff-101',
        'evidence_type': 'beforeWork',
        'bucket_id': 'complaint-evidence',
        'object_path': 'staff-101/comp-101/assign-101/before.jpg',
        'original_name': 'before.jpg',
        'content_type': 'image/jpeg',
        'byte_size': 1048576,
        'latitude': 21.1458,
        'longitude': 79.0882,
        'accuracy': 12.5,
        'distance_from_complaint_meters': 35.0,
        'is_geo_verified': true,
        'captured_at': now.toIso8601String(),
        'created_at': now.toIso8601String(),
        'notes': 'Pre-work inspection photo',
        'signed_url': 'https://storage/signed/before.jpg',
        'staff_profiles': {
          'name': 'Ramesh Kumar',
          'employee_id': 'NMC-RD-001',
        },
      });

      expect(reconstructed.id, 'ev-101');
      expect(reconstructed.isImage, isTrue);
      expect(reconstructed.isPdf, isFalse);
      expect(reconstructed.formattedFileSize, '1.0 MB');
      expect(reconstructed.staffName, 'Ramesh Kumar');
      expect(reconstructed.staffEmployeeId, 'NMC-RD-001');
    });

    test('2. EvidenceType parser from string codes', () {
      expect(EvidenceType.fromCode('beforeWork'), EvidenceType.beforeWork);
      expect(EvidenceType.fromCode('beforework'), EvidenceType.beforeWork);
      expect(EvidenceType.fromCode('afterWork'), EvidenceType.afterWork);
      expect(EvidenceType.fromCode('inspectionReport'), EvidenceType.inspectionReport);
      expect(EvidenceType.fromCode('unknown'), EvidenceType.beforeWork);
    });

    test('3. LocationService distance calculation (Haversine)', () {
      const service = LocationService();
      // Sitabuldi (21.1458, 79.0882) to Zero Mile (21.1498, 79.0806) ~ 900m
      final dist = service.calculateDistanceMeters(
        startLatitude: 21.1458,
        startLongitude: 79.0882,
        endLatitude: 21.1498,
        endLongitude: 79.0806,
      );
      expect(dist, greaterThan(800));
      expect(dist, lessThan(1200));

      // Same point distance should be 0
      final zeroDist = service.calculateDistanceMeters(
        startLatitude: 21.1458,
        startLongitude: 79.0882,
        endLatitude: 21.1458,
        endLongitude: 79.0882,
      );
      expect(zeroDist, 0.0);
    });

    test('4. LocationCheckOutcome evaluation — verified vs outside radius', () {
      const verified = LocationCheckOutcome(
        result: LocationVerificationResult.verified,
        latitude: 21.1458,
        longitude: 79.0882,
        accuracy: 10.0,
        distanceMeters: 45.0,
      );
      expect(verified.isVerified, isTrue);

      const outside = LocationCheckOutcome(
        result: LocationVerificationResult.outsideRadius,
        latitude: 21.1600,
        longitude: 79.1000,
        accuracy: 10.0,
        distanceMeters: 250.0,
        errorMessage: 'Outside radius',
      );
      expect(outside.isVerified, isFalse);
      expect(outside.errorMessage, 'Outside radius');
    });

    test('5. StaffController uploadEvidence records before-work photo', () async {
      final mockAuth = MockStaffAuthGateway();
      final mockData = MockStaffDataGateway();
      final staff = _testStaffProfile();
      mockAuth.currentStaff = staff;
      mockData.profile = staff;

      final controller = StaffController(authGateway: mockAuth, dataGateway: mockData);

      final evidence = await controller.uploadEvidence(
        complaintId: 'comp-101',
        assignmentId: 'assign-101',
        type: EvidenceType.beforeWork,
        fileBytes: [1, 2, 3, 4],
        fileName: 'before_patch.jpg',
        contentType: 'image/jpeg',
        latitude: 21.1458,
        longitude: 79.0882,
        accuracy: 15.0,
        notes: 'Pre-work inspection photo',
      );

      expect(evidence, isNotNull);
      expect(evidence!.evidenceType, EvidenceType.beforeWork);
      expect(evidence.isGeoVerified, isTrue);
      expect(evidence.signedUrl, contains('before_patch.jpg'));

      final taskEvidence = await controller.getTaskEvidence('assign-101');
      expect(taskEvidence.length, 1);
      expect(taskEvidence.first.evidenceType, EvidenceType.beforeWork);
    });

    test('6. StaffController uploadEvidence records after-work photo', () async {
      final mockAuth = MockStaffAuthGateway();
      final mockData = MockStaffDataGateway();
      final staff = _testStaffProfile();
      mockAuth.currentStaff = staff;
      mockData.profile = staff;

      final controller = StaffController(authGateway: mockAuth, dataGateway: mockData);

      final evidence = await controller.uploadEvidence(
        complaintId: 'comp-101',
        assignmentId: 'assign-101',
        type: EvidenceType.afterWork,
        fileBytes: [5, 6, 7, 8],
        fileName: 'after_patch.jpg',
        contentType: 'image/jpeg',
        latitude: 21.1458,
        longitude: 79.0882,
        accuracy: 10.0,
        notes: 'Post-repair asphalt smooth finish',
      );

      expect(evidence, isNotNull);
      expect(evidence!.evidenceType, EvidenceType.afterWork);
      expect(evidence.isGeoVerified, isTrue);
    });

    test('7. StaffController uploadEvidence records inspection report PDF', () async {
      final mockAuth = MockStaffAuthGateway();
      final mockData = MockStaffDataGateway();
      final staff = _testStaffProfile();
      mockAuth.currentStaff = staff;
      mockData.profile = staff;

      final controller = StaffController(authGateway: mockAuth, dataGateway: mockData);

      final evidence = await controller.uploadEvidence(
        complaintId: 'comp-101',
        assignmentId: 'assign-101',
        type: EvidenceType.inspectionReport,
        fileBytes: List.filled(50000, 0),
        fileName: 'inspection_report.pdf',
        contentType: 'application/pdf',
        latitude: 21.1458,
        longitude: 79.0882,
        accuracy: 5.0,
        notes: 'Signed field supervisor checklist',
      );

      expect(evidence, isNotNull);
      expect(evidence!.isPdf, isTrue);
      expect(evidence.evidenceType, EvidenceType.inspectionReport);
    });

    test('8. AdminController retrieves complaint evidence with signed URLs', () async {
      final mockAdminAuth = MockAdminAuthGateway();
      final mockAdminData = MockAdminDataGateway();

      mockAdminData.evidenceStore.add(
        ComplaintEvidence(
          id: 'ev-1',
          complaintId: 'comp-202',
          assignmentId: 'assign-202',
          staffId: 'staff-1',
          evidenceType: EvidenceType.beforeWork,
          bucketId: 'complaint-evidence',
          objectPath: 'staff-1/comp-202/assign-202/before.jpg',
          originalName: 'before.jpg',
          contentType: 'image/jpeg',
          byteSize: 100000,
          latitude: 21.1458,
          longitude: 79.0882,
          accuracy: 10.0,
          distanceFromComplaintMeters: 15.0,
          isGeoVerified: true,
          capturedAt: DateTime.now(),
          createdAt: DateTime.now(),
          signedUrl: 'https://storage/signed/before.jpg',
        ),
      );

      final controller = AdminController(authGateway: mockAdminAuth, dataGateway: mockAdminData);
      final evidenceList = await controller.getComplaintEvidence('comp-202');

      expect(evidenceList.length, 1);
      expect(evidenceList.first.isGeoVerified, isTrue);
    });

    test('9. ComplaintEvidence isPdf and isImage helpers', () {
      final jpgEvidence = ComplaintEvidence(
        id: 'e1', complaintId: 'c1', assignmentId: 'a1', staffId: 's1',
        evidenceType: EvidenceType.beforeWork,
        bucketId: 'complaint-evidence', objectPath: 'p', originalName: 'f.jpg',
        contentType: 'image/jpeg', byteSize: 100, latitude: 0, longitude: 0,
        accuracy: 0, capturedAt: DateTime.now(), createdAt: DateTime.now(),
      );
      expect(jpgEvidence.isImage, isTrue);
      expect(jpgEvidence.isPdf, isFalse);

      final pdfEvidence = jpgEvidence.copyWith(
        contentType: 'application/pdf',
        originalName: 'report.pdf',
      );
      expect(pdfEvidence.isImage, isFalse);
      expect(pdfEvidence.isPdf, isTrue);
    });

    test('10. ComplaintEvidence formattedFileSize outputs correct units', () {
      final small = ComplaintEvidence(
        id: 'e1', complaintId: 'c1', assignmentId: 'a1', staffId: 's1',
        evidenceType: EvidenceType.beforeWork,
        bucketId: 'complaint-evidence', objectPath: 'p', originalName: 'f.jpg',
        contentType: 'image/jpeg', byteSize: 512, latitude: 0, longitude: 0,
        accuracy: 0, capturedAt: DateTime.now(), createdAt: DateTime.now(),
      );
      expect(small.formattedFileSize, '512 B');

      final medium = small.copyWith(byteSize: 512 * 1024);
      expect(medium.formattedFileSize, '512.0 KB');

      final large = small.copyWith(byteSize: 5 * 1024 * 1024);
      expect(large.formattedFileSize, '5.0 MB');
    });

    test('11. ComplaintEvidence copyWith preserves all fields', () {
      final now = DateTime.now();
      final original = ComplaintEvidence(
        id: 'ev-orig', complaintId: 'c1', assignmentId: 'a1', staffId: 's1',
        evidenceType: EvidenceType.beforeWork,
        bucketId: 'complaint-evidence', objectPath: 'path/original',
        originalName: 'orig.jpg', contentType: 'image/jpeg', byteSize: 1000,
        latitude: 21.0, longitude: 79.0, accuracy: 10.0,
        distanceFromComplaintMeters: 50.0, isGeoVerified: true,
        capturedAt: now, createdAt: now, notes: 'original notes',
        signedUrl: 'https://original', staffName: 'Staff A', staffEmployeeId: 'EMP-001',
      );

      final copy = original.copyWith(signedUrl: 'https://updated');
      expect(copy.id, 'ev-orig');
      expect(copy.signedUrl, 'https://updated');
      expect(copy.staffName, 'Staff A');
      expect(copy.isGeoVerified, isTrue);
    });

    test('12. Multiple evidence items per assignment are retrievable', () async {
      final mockAuth = MockStaffAuthGateway();
      final mockData = MockStaffDataGateway();
      final staff = _testStaffProfile();
      mockAuth.currentStaff = staff;
      mockData.profile = staff;

      final controller = StaffController(authGateway: mockAuth, dataGateway: mockData);

      await controller.uploadEvidence(
        complaintId: 'comp-300', assignmentId: 'assign-300',
        type: EvidenceType.beforeWork, fileBytes: [1], fileName: 'b.jpg',
        contentType: 'image/jpeg', latitude: 21.0, longitude: 79.0, accuracy: 5.0,
      );
      await controller.uploadEvidence(
        complaintId: 'comp-300', assignmentId: 'assign-300',
        type: EvidenceType.afterWork, fileBytes: [2], fileName: 'a.jpg',
        contentType: 'image/jpeg', latitude: 21.0, longitude: 79.0, accuracy: 5.0,
      );
      await controller.uploadEvidence(
        complaintId: 'comp-300', assignmentId: 'assign-300',
        type: EvidenceType.inspectionReport, fileBytes: [3], fileName: 'r.pdf',
        contentType: 'application/pdf', latitude: 21.0, longitude: 79.0, accuracy: 5.0,
      );

      final list = await controller.getTaskEvidence('assign-300');
      expect(list.length, 3);
      expect(list.map((e) => e.evidenceType).toSet(), {
        EvidenceType.beforeWork,
        EvidenceType.afterWork,
        EvidenceType.inspectionReport,
      });
    });

    test('13. StaffController resetLocationCheck clears verification state', () {
      final mockAuth = MockStaffAuthGateway();
      final mockData = MockStaffDataGateway();
      final controller = StaffController(authGateway: mockAuth, dataGateway: mockData);

      expect(controller.isLocationVerified, isFalse);
      expect(controller.lastLocationCheck, isNull);

      controller.resetLocationCheck();
      expect(controller.lastLocationCheck, isNull);
    });

    test('14. Security: Oversized evidence file (> 10MB) is rejected', () async {
      final mockAuth = MockStaffAuthGateway();
      final mockData = MockStaffDataGateway();
      final staff = _testStaffProfile();
      mockAuth.currentStaff = staff;
      mockData.profile = staff;

      final controller = StaffController(authGateway: mockAuth, dataGateway: mockData);

      // 11MB file bytes
      final oversizedBytes = List<int>.filled(11 * 1024 * 1024, 0);

      final result = await controller.uploadEvidence(
        complaintId: 'comp-101',
        assignmentId: 'assign-101',
        type: EvidenceType.beforeWork,
        fileBytes: oversizedBytes,
        fileName: 'oversized.jpg',
        contentType: 'image/jpeg',
        latitude: 21.1458,
        longitude: 79.0882,
        accuracy: 10.0,
      );

      expect(result, isNull);
      expect(controller.errorMessage, contains('10 MB'));
    });

    test('15. Security: Empty evidence file (0 bytes) is rejected', () async {
      final mockAuth = MockStaffAuthGateway();
      final mockData = MockStaffDataGateway();
      final staff = _testStaffProfile();
      mockAuth.currentStaff = staff;
      mockData.profile = staff;

      final controller = StaffController(authGateway: mockAuth, dataGateway: mockData);

      final result = await controller.uploadEvidence(
        complaintId: 'comp-101',
        assignmentId: 'assign-101',
        type: EvidenceType.beforeWork,
        fileBytes: const [],
        fileName: 'empty.jpg',
        contentType: 'image/jpeg',
        latitude: 21.1458,
        longitude: 79.0882,
        accuracy: 10.0,
      );

      expect(result, isNull);
      expect(controller.errorMessage, contains('between 1 byte and 10 MB'));
    });

    test('16. Security: Unsupported/executable file extension (.exe, .sh, .php) is rejected', () async {
      final mockAuth = MockStaffAuthGateway();
      final mockData = MockStaffDataGateway();
      final staff = _testStaffProfile();
      mockAuth.currentStaff = staff;
      mockData.profile = staff;

      final controller = StaffController(authGateway: mockAuth, dataGateway: mockData);

      for (final badFile in ['script.sh', 'malware.exe', 'payload.php', 'hack.svg']) {
        final result = await controller.uploadEvidence(
          complaintId: 'comp-101',
          assignmentId: 'assign-101',
          type: EvidenceType.beforeWork,
          fileBytes: [1, 2, 3],
          fileName: badFile,
          contentType: 'application/octet-stream',
          latitude: 21.1458,
          longitude: 79.0882,
          accuracy: 10.0,
        );

        expect(result, isNull);
        expect(controller.errorMessage, contains('Unsupported file extension'));
      }
    });

    test('17. Security: PDF file uploaded as photographic evidence is rejected', () async {
      final mockAuth = MockStaffAuthGateway();
      final mockData = MockStaffDataGateway();
      final staff = _testStaffProfile();
      mockAuth.currentStaff = staff;
      mockData.profile = staff;

      final controller = StaffController(authGateway: mockAuth, dataGateway: mockData);

      final result = await controller.uploadEvidence(
        complaintId: 'comp-101',
        assignmentId: 'assign-101',
        type: EvidenceType.beforeWork,
        fileBytes: [1, 2, 3],
        fileName: 'report.pdf',
        contentType: 'application/pdf',
        latitude: 21.1458,
        longitude: 79.0882,
        accuracy: 10.0,
      );

      expect(result, isNull);
      expect(controller.errorMessage, contains('cannot be a PDF'));
    });

    test('18. Security: Signed URL helper returns short-lived valid URL', () async {
      final mockData = MockStaffDataGateway();
      final url = await mockData.getEvidenceSignedUrl('staff-1/comp-1/assign-1/photo.jpg');

      expect(url, isNotEmpty);
      expect(url, contains('token='));
      expect(url, startsWith('https://'));
    });
  });
}


