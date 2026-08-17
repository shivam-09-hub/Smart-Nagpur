import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_nagpur/data/gateways/admin_auth_gateway.dart';
import 'package:smart_nagpur/data/gateways/admin_data_gateway.dart';
import 'package:smart_nagpur/data/gateways/staff_auth_gateway.dart';
import 'package:smart_nagpur/data/gateways/staff_data_gateway.dart';
import 'package:smart_nagpur/domain/domain.dart';
import 'package:smart_nagpur/state/admin_controller.dart';
import 'package:smart_nagpur/state/staff_controller.dart';

class SlowMockStaffDataGateway implements StaffDataGateway {
  int acceptTaskCalls = 0;
  int startTaskCalls = 0;
  int completeTaskCalls = 0;
  int uploadEvidenceCalls = 0;
  int getMyTasksCalls = 0;
  bool isUnsubscribed = false;
  void Function()? realtimeCallback;

  Completer<ComplaintAssignment>? acceptCompleter;
  Completer<ComplaintEvidence>? evidenceCompleter;

  @override
  Future<StaffProfile?> getStaffProfile() async => null;

  @override
  Future<void> updateDutyStatus(bool isOnDuty) async {}

  @override
  Future<List<ComplaintAssignment>> getMyTasks() async {
    getMyTasksCalls++;
    return [];
  }

  @override
  Future<ComplaintAssignment?> getTaskDetails(String assignmentId) async => null;

  @override
  Future<ComplaintAssignment> acceptTask(String assignmentId) async {
    acceptTaskCalls++;
    if (acceptCompleter != null) {
      return await acceptCompleter!.future;
    }
    return ComplaintAssignment(
      id: assignmentId,
      complaintId: 'c-1',
      staffId: 's-1',
      assignedBy: 'a-1',
      status: AssignmentStatus.accepted,
      assignedAt: DateTime.now(),
    );
  }

  @override
  Future<ComplaintAssignment> startTask(String assignmentId) async {
    startTaskCalls++;
    return ComplaintAssignment(
      id: assignmentId,
      complaintId: 'c-1',
      staffId: 's-1',
      assignedBy: 'a-1',
      status: AssignmentStatus.inProgress,
      assignedAt: DateTime.now(),
    );
  }

  @override
  Future<ComplaintAssignment> completeTask(String assignmentId, {String notes = ''}) async {
    completeTaskCalls++;
    return ComplaintAssignment(
      id: assignmentId,
      complaintId: 'c-1',
      staffId: 's-1',
      assignedBy: 'a-1',
      status: AssignmentStatus.completed,
      assignedAt: DateTime.now(),
    );
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
    uploadEvidenceCalls++;
    if (evidenceCompleter != null) {
      return await evidenceCompleter!.future;
    }
    return ComplaintEvidence(
      id: 'ev-1',
      complaintId: complaintId,
      assignmentId: assignmentId,
      staffId: 's-1',
      evidenceType: type,
      bucketId: 'complaint-evidence',
      objectPath: 'path/1.jpg',
      originalName: fileName,
      contentType: contentType,
      byteSize: fileBytes.length,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      distanceFromComplaintMeters: 10.0,
      isGeoVerified: true,
      capturedAt: DateTime.now(),
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<List<ComplaintEvidence>> getTaskEvidence(String assignmentId) async => [];

  @override
  Future<String> getEvidenceSignedUrl(String objectPath) async => 'https://signed.url/$objectPath';

  @override
  void subscribeToStaffTaskUpdates(String staffId, void Function() onUpdate) {
    realtimeCallback = onUpdate;
    isUnsubscribed = false;
  }

  @override
  void unsubscribeFromStaffTaskUpdates() {
    isUnsubscribed = true;
    realtimeCallback = null;
  }
}

class MockStaffAuthGatewayImpl implements StaffAuthGateway {
  @override
  Future<StaffProfile?> getCurrentStaff() async => StaffProfile(
        id: 's-1',
        name: 'Staff Test',
        email: 'staff@nagpur.gov.in',
        employeeId: 'EMP-01',
        department: StaffDepartment.road,
        role: StaffRole.fieldWorker,
        isActive: true,
      );

  @override
  Future<StaffProfile> loginStaff(String email, String password) async => (await getCurrentStaff())!;

  @override
  Future<void> logoutStaff() async {}

  @override
  Future<void> setDutyStatus(bool isOnDuty) async {}

  @override
  Future<bool> isStaffAuthenticated() async => true;
}

class SlowMockAdminDataGateway implements AdminDataGateway {
  int assignComplaintCalls = 0;
  int approveAssignmentCalls = 0;
  int reworkAssignmentCalls = 0;
  int updateComplaintStatusCalls = 0;
  int updateApplicationStatusCalls = 0;
  int getAdminStatsCalls = 0;
  bool isUnsubscribed = false;
  void Function()? realtimeCallback;

  Completer<ComplaintAssignment>? assignCompleter;
  Completer<ComplaintAssignment>? approveCompleter;

  @override
  Future<AdminStats> getAdminStats() async {
    getAdminStatsCalls++;
    return AdminStats(
      totalComplaints: 10,
      pendingComplaints: 5,
      resolvedComplaints: 5,
      totalVendorApplications: 4,
      pendingApplications: 2,
      approvedApplications: 1,
      rejectedApplications: 1,
      totalNotifications: 0,
      unreadNotifications: 0,
      totalUsers: 20,
      activeUsers: 18,
      lastUpdated: DateTime.now(),
    );
  }

  @override
  Future<List<ComplaintRecord>> getPendingComplaints({int limit = 50, int offset = 0}) async => [];

  @override
  Future<ComplaintRecord?> getComplaintDetails(String complaintId) async => null;

  @override
  Future<void> updateComplaintStatus(String complaintId, ComplaintStatus status, {String notes = ''}) async {
    updateComplaintStatusCalls++;
  }

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
  Future<void> updateApplicationStatus(String applicationId, VendorStatus status, {String notes = ''}) async {
    updateApplicationStatusCalls++;
  }

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
  void subscribeToAdminLiveUpdates(void Function() onUpdate) {
    realtimeCallback = onUpdate;
    isUnsubscribed = false;
  }

  @override
  void unsubscribeFromAdminLiveUpdates() {
    isUnsubscribed = true;
    realtimeCallback = null;
  }

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
  }) async {
    assignComplaintCalls++;
    if (assignCompleter != null) {
      return await assignCompleter!.future;
    }
    return ComplaintAssignment(
      id: 'asg-1',
      complaintId: complaintId,
      staffId: staffId,
      assignedBy: 'admin-1',
      priority: priority,
      assignedAt: DateTime.now(),
    );
  }

  @override
  Future<ComplaintAssignment?> getComplaintAssignment(String assignmentId) async => null;

  @override
  Future<List<ComplaintAssignment>> getComplaintAssignmentsHistory(String complaintId) async => [];

  @override
  Future<ComplaintAssignment> approveComplaintAssignment(String assignmentId, {String reviewNotes = ''}) async {
    approveAssignmentCalls++;
    if (approveCompleter != null) {
      return await approveCompleter!.future;
    }
    return ComplaintAssignment(
      id: assignmentId,
      complaintId: 'c-1',
      staffId: 's-1',
      assignedBy: 'admin-1',
      status: AssignmentStatus.approved,
      assignedAt: DateTime.now(),
    );
  }

  @override
  Future<ComplaintAssignment> requestReworkComplaintAssignment(String assignmentId, {String reworkInstructions = ''}) async {
    reworkAssignmentCalls++;
    return ComplaintAssignment(
      id: assignmentId,
      complaintId: 'c-1',
      staffId: 's-1',
      assignedBy: 'admin-1',
      status: AssignmentStatus.reworkRequired,
      assignedAt: DateTime.now(),
    );
  }

  @override
  Future<List<ComplaintEvidence>> getComplaintEvidence(String complaintId) async => [];

  @override
  Future<String> getEvidenceSignedUrl(String objectPath) async => 'https://signed.url/$objectPath';

  @override
  Future<AdminOperationsDashboard> getOperationsDashboard({AdminOperationsFilter? filter}) async =>
      const AdminOperationsDashboard();
}

class MockAdminAuthGatewayImpl implements AdminAuthGateway {
  AdminProfile? currentAdmin;

  @override
  Future<AdminProfile?> getCurrentAdmin() async =>
      currentAdmin ??
      AdminProfile(
        id: 'admin-1',
        email: 'admin@nagpur.gov.in',
        name: 'Super Admin',
        role: AdminRole.superAdmin,
        isActive: true,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

  @override
  Future<AdminProfile> loginAdmin(String email, String password) async => (await getCurrentAdmin())!;

  @override
  Future<void> logoutAdmin() async => currentAdmin = null;

  @override
  Future<void> createAdmin(String email, String password, AdminProfile profile) async {}

  @override
  Future<void> updateAdminProfile(AdminProfile profile) async {
    currentAdmin = profile;
  }

  @override
  Future<void> changeAdminPassword(String oldPassword, String newPassword) async {}

  @override
  Future<bool> isAdminAuthenticated() async => true;

  @override
  Future<AdminProfile?> getAdminById(String adminId) async => await getCurrentAdmin();

  @override
  Future<List<AdminProfile>> getAllAdmins() async => [ (await getCurrentAdmin())! ];

  @override
  Future<void> deactivateAdmin(String adminId) async {}
}

void main() {
  group('Step 12 Performance & Resilience - StaffController', () {
    late SlowMockStaffDataGateway dataGateway;
    late MockStaffAuthGatewayImpl authGateway;
    late StaffController staffController;

    setUp(() {
      dataGateway = SlowMockStaffDataGateway();
      authGateway = MockStaffAuthGatewayImpl();
      staffController = StaffController(
        authGateway: authGateway,
        dataGateway: dataGateway,
      );
    });

    tearDown(() {
      staffController.dispose();
    });

    test('Prevents duplicate in-flight acceptTask calls on rapid taps', () async {
      dataGateway.acceptCompleter = Completer<ComplaintAssignment>();

      // First click
      final firstFuture = staffController.acceptTask('asg-1');
      expect(staffController.isTaskInFlight('asg-1'), isTrue);

      // Second rapid click on same assignment
      final secondResult = await staffController.acceptTask('asg-1');
      expect(secondResult, isFalse);
      expect(dataGateway.acceptTaskCalls, equals(1));

      // Complete the first call
      dataGateway.acceptCompleter!.complete(ComplaintAssignment(
        id: 'asg-1',
        complaintId: 'c-1',
        staffId: 's-1',
        assignedBy: 'a-1',
        status: AssignmentStatus.accepted,
        assignedAt: DateTime.now(),
      ));

      final firstResult = await firstFuture;
      expect(firstResult, isTrue);
      expect(staffController.isTaskInFlight('asg-1'), isFalse);
    });

    test('Prevents duplicate in-flight uploadEvidence calls on rapid submissions', () async {
      dataGateway.evidenceCompleter = Completer<ComplaintEvidence>();

      final firstFuture = staffController.uploadEvidence(
        complaintId: 'c-1',
        assignmentId: 'asg-1',
        type: EvidenceType.beforeWork,
        fileBytes: [1, 2, 3],
        fileName: 'photo.jpg',
        contentType: 'image/jpeg',
        latitude: 21.1458,
        longitude: 79.0882,
        accuracy: 10.0,
      );

      expect(staffController.isUploadingEvidence, isTrue);

      // Duplicate submission while in flight
      final secondResult = await staffController.uploadEvidence(
        complaintId: 'c-1',
        assignmentId: 'asg-1',
        type: EvidenceType.beforeWork,
        fileBytes: [1, 2, 3],
        fileName: 'photo.jpg',
        contentType: 'image/jpeg',
        latitude: 21.1458,
        longitude: 79.0882,
        accuracy: 10.0,
      );

      expect(secondResult, isNull);
      expect(dataGateway.uploadEvidenceCalls, equals(1));

      dataGateway.evidenceCompleter!.complete(ComplaintEvidence(
        id: 'ev-1',
        complaintId: 'c-1',
        assignmentId: 'asg-1',
        staffId: 's-1',
        evidenceType: EvidenceType.beforeWork,
        bucketId: 'complaint-evidence',
        objectPath: 'path/1.jpg',
        originalName: 'photo.jpg',
        contentType: 'image/jpeg',
        byteSize: 3,
        latitude: 21.1458,
        longitude: 79.0882,
        accuracy: 10.0,
        distanceFromComplaintMeters: 5.0,
        isGeoVerified: true,
        capturedAt: DateTime.now(),
        createdAt: DateTime.now(),
      ));

      final firstResult = await firstFuture;
      expect(firstResult, isNotNull);
      expect(staffController.isUploadingEvidence, isFalse);
    });

    test('Debounces burst realtime task updates into a single refresh', () async {
      await staffController.checkAuthStatus();
      expect(dataGateway.realtimeCallback, isNotNull);

      final initialGetMyTasks = dataGateway.getMyTasksCalls;

      // Simulate 5 rapid realtime events
      for (int i = 0; i < 5; i++) {
        dataGateway.realtimeCallback!();
      }

      // Wait 600ms for debounce timer to fire
      await Future<void>.delayed(const Duration(milliseconds: 600));

      // Should only have made 1 additional call despite 5 events
      expect(dataGateway.getMyTasksCalls, equals(initialGetMyTasks + 1));
    });

    test('Unsubscribes from realtime channel upon controller disposal', () async {
      final localController = StaffController(
        authGateway: authGateway,
        dataGateway: dataGateway,
      );
      await localController.checkAuthStatus();
      expect(dataGateway.isUnsubscribed, isFalse);

      localController.dispose();
      expect(dataGateway.isUnsubscribed, isTrue);
    });
  });

  group('Step 12 Performance & Resilience - AdminController', () {
    late SlowMockAdminDataGateway dataGateway;
    late MockAdminAuthGatewayImpl authGateway;
    late AdminController adminController;

    setUp(() {
      dataGateway = SlowMockAdminDataGateway();
      authGateway = MockAdminAuthGatewayImpl();
      adminController = AdminController(
        authGateway: authGateway,
        dataGateway: dataGateway,
      );
    });

    tearDown(() {
      adminController.dispose();
    });

    test('Prevents duplicate in-flight assignComplaint calls', () async {
      dataGateway.assignCompleter = Completer<ComplaintAssignment>();

      final firstFuture = adminController.assignComplaint(
        complaintId: 'c-100',
        staffId: 's-1',
      );

      expect(adminController.isComplaintInFlight('c-100'), isTrue);

      // Duplicate click
      final secondResult = await adminController.assignComplaint(
        complaintId: 'c-100',
        staffId: 's-1',
      );
      expect(secondResult, isFalse);
      expect(dataGateway.assignComplaintCalls, equals(1));

      dataGateway.assignCompleter!.complete(ComplaintAssignment(
        id: 'asg-100',
        complaintId: 'c-100',
        staffId: 's-1',
        assignedBy: 'admin-1',
        assignedAt: DateTime.now(),
      ));

      final firstResult = await firstFuture;
      expect(firstResult, isTrue);
      expect(adminController.isComplaintInFlight('c-100'), isFalse);
    });

    test('Prevents duplicate in-flight approveComplaintAssignment calls', () async {
      dataGateway.approveCompleter = Completer<ComplaintAssignment>();

      final firstFuture = adminController.approveComplaintAssignment('asg-50');
      expect(adminController.isAssignmentInFlight('asg-50'), isTrue);

      final secondResult = await adminController.approveComplaintAssignment('asg-50');
      expect(secondResult, isFalse);
      expect(dataGateway.approveAssignmentCalls, equals(1));

      dataGateway.approveCompleter!.complete(ComplaintAssignment(
        id: 'asg-50',
        complaintId: 'c-50',
        staffId: 's-1',
        assignedBy: 'admin-1',
        status: AssignmentStatus.approved,
        assignedAt: DateTime.now(),
      ));

      final firstResult = await firstFuture;
      expect(firstResult, isTrue);
      expect(adminController.isAssignmentInFlight('asg-50'), isFalse);
    });

    test('Debounces live sync events in AdminController', () async {
      await adminController.checkAuthStatus();
      expect(dataGateway.realtimeCallback, isNotNull);

      final initialStatsCalls = dataGateway.getAdminStatsCalls;

      // Burst 4 rapid live sync events
      for (int i = 0; i < 4; i++) {
        dataGateway.realtimeCallback!();
      }

      await Future<void>.delayed(const Duration(milliseconds: 600));

      // Should only have executed 1 batch refresh
      expect(dataGateway.getAdminStatsCalls, equals(initialStatsCalls + 1));
    });

    test('Unsubscribes from admin realtime channel upon disposal', () async {
      final localController = AdminController(
        authGateway: authGateway,
        dataGateway: dataGateway,
      );
      await localController.checkAuthStatus();
      expect(dataGateway.isUnsubscribed, isFalse);

      localController.dispose();
      expect(dataGateway.isUnsubscribed, isTrue);
    });
  });
}

