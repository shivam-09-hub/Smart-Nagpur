import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_nagpur/data/gateways/admin_auth_gateway.dart';
import 'package:smart_nagpur/data/gateways/admin_data_gateway.dart';
import 'package:smart_nagpur/domain/domain.dart';
import 'package:smart_nagpur/features/admin/presentation/admin_operations_screen.dart';
import 'package:smart_nagpur/state/admin_controller.dart';

// ---------------------------------------------------------------------------
// Mock: AdminAuthGateway
// ---------------------------------------------------------------------------
class MockAdminAuthGateway implements AdminAuthGateway {
  AdminProfile? currentAdmin;

  @override
  Future<AdminProfile?> getCurrentAdmin() async => currentAdmin;

  @override
  Future<AdminProfile> loginAdmin(String email, String password) async => currentAdmin!;

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
  AdminOperationsDashboard simulatedDashboard = const AdminOperationsDashboard();
  bool shouldThrowUnauthorized = false;
  AdminOperationsFilter? lastReceivedFilter;

  @override
  Future<AdminOperationsDashboard> getOperationsDashboard({AdminOperationsFilter? filter}) async {
    if (shouldThrowUnauthorized) {
      throw Exception('Access denied. Administrator or Supervisor credentials required.');
    }
    lastReceivedFilter = filter;

    // Apply basic filter simulation
    var queue = simulatedDashboard.verificationQueue;
    if (filter?.department != null) {
      queue = queue.where((q) => q.serviceType.toLowerCase().contains(filter!.department!.code.toLowerCase())).toList();
    }
    if (filter?.priority != null) {
      queue = queue.where((q) => q.priority == filter!.priority).toList();
    }

    return AdminOperationsDashboard(
      complaintsByStatus: simulatedDashboard.complaintsByStatus,
      assignmentsByStatus: simulatedDashboard.assignmentsByStatus,
      staffWorkloadSummary: simulatedDashboard.staffWorkloadSummary,
      staffWorkloads: simulatedDashboard.staffWorkloads,
      verificationQueue: queue,
    );
  }

  @override
  Future<AdminStats> getAdminStats() async => AdminStats(
        totalComplaints: 20,
        pendingComplaints: 5,
        resolvedComplaints: 10,
        totalVendorApplications: 4,
        pendingApplications: 1,
        approvedApplications: 3,
        rejectedApplications: 0,
        totalNotifications: 0,
        unreadNotifications: 0,
        totalUsers: 100,
        activeUsers: 80,
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
  Future<StaffProfile> createStaff({required String name, required String email, required String employeeId, required StaffDepartment department, StaffRole role = StaffRole.fieldWorker, String phone = '', String zone = 'ALL', String ward = '', String? password}) async => throw UnimplementedError();
  @override
  Future<List<StaffProfile>> getStaffMembers({StaffDepartment? department, bool? isActive, bool? isOnDuty}) async => [];
  @override
  Future<StaffProfile?> getStaffMember(String staffId) async => null;
  @override
  Future<ComplaintAssignment> assignComplaint({required String complaintId, required String staffId, AssignmentPriority priority = AssignmentPriority.medium, String instructions = ''}) async => throw UnimplementedError();
  @override
  Future<ComplaintAssignment?> getComplaintAssignment(String assignmentId) async => null;
  @override
  Future<List<ComplaintAssignment>> getComplaintAssignmentsHistory(String complaintId) async => [];
  @override
  Future<ComplaintAssignment> approveComplaintAssignment(String assignmentId, {String reviewNotes = ''}) async => throw UnimplementedError();
  @override
  Future<ComplaintAssignment> requestReworkComplaintAssignment(String assignmentId, {String reworkInstructions = ''}) async => throw UnimplementedError();
  @override
  Future<List<ComplaintEvidence>> getComplaintEvidence(String complaintId) async => [];
  @override
  Future<String> getEvidenceSignedUrl(String objectPath) async => '';
  @override
  void subscribeToAdminLiveUpdates(void Function() onUpdate) {}
  @override
  void unsubscribeFromAdminLiveUpdates() {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
AdminProfile _testAdmin() {
  return AdminProfile(
    id: 'admin-001',
    email: 'admin@smartnagpur.gov.in',
    name: 'Municipal Admin',
    role: AdminRole.superAdmin,
    createdAt: DateTime.now(),
    lastLoginAt: DateTime.now(),
  );
}


AdminOperationsDashboard _sampleDashboard() {
  return AdminOperationsDashboard(
    complaintsByStatus: {
      'submitted': 4,
      'assigned': 3,
      'inProgress': 5,
      'underReview': 2,
      'reworkRequired': 1,
      'resolved': 12,
    },
    assignmentsByStatus: {
      'assigned': 3,
      'accepted': 2,
      'inProgress': 5,
      'completed': 2,
      'reworkRequired': 1,
      'approved': 12,
    },
    staffWorkloadSummary: const StaffWorkloadSummary(
      totalStaff: 10,
      activeStaff: 9,
      onDutyStaff: 7,
      pendingTasks: 5,
      inProgressTasks: 6,
      completedTasks: 14,
    ),
    staffWorkloads: [
      StaffWorkloadItem(
        staffId: 'staff-1',
        name: 'Ramesh Kumar',
        employeeId: 'NMC-RD-001',
        department: StaffDepartment.road,
        role: StaffRole.fieldWorker,
        isOnDuty: true,
        isActive: true,
        activeTaskCount: 2,
        completedTaskCount: 8,
      ),
      StaffWorkloadItem(
        staffId: 'staff-2',
        name: 'Suresh Patil',
        employeeId: 'NMC-WS-002',
        department: StaffDepartment.waste,
        role: StaffRole.fieldWorker,
        isOnDuty: false,
        isActive: true,
        activeTaskCount: 0,
        completedTaskCount: 5,
      ),
    ],
    verificationQueue: [
      VerificationQueueItem(
        complaintId: 'comp-101',
        assignmentId: 'assign-101',
        issue: 'Pothole near Sitabuldi flyover',
        serviceType: 'road',
        priority: AssignmentPriority.urgent,
        complaintAddress: 'Wardha Road, Sitabuldi',
        complaintCreatedAt: DateTime.now().subtract(const Duration(days: 1)),
        staffId: 'staff-1',
        staffName: 'Ramesh Kumar',
        staffEmployeeId: 'NMC-RD-001',
        assignedAt: DateTime.now().subtract(const Duration(hours: 5)),
        completedAt: DateTime.now().subtract(const Duration(hours: 1)),
        assignmentAgeHours: 4.0,
        technicianNotes: 'Asphalt cold mix patched and leveled.',
        evidenceCount: 2,
        hasBeforePhoto: true,
        hasAfterPhoto: true,
        hasInspectionPdf: false,
        isGeoVerified: true,
        distanceMeters: 18.5,
        accuracyMeters: 8.0,
      ),
      VerificationQueueItem(
        complaintId: 'comp-102',
        assignmentId: 'assign-102',
        issue: 'Garbage accumulation at Dharampeth',
        serviceType: 'waste',
        priority: AssignmentPriority.medium,
        complaintAddress: 'West High Court Road, Dharampeth',
        complaintCreatedAt: DateTime.now().subtract(const Duration(days: 2)),
        staffId: 'staff-2',
        staffName: 'Suresh Patil',
        staffEmployeeId: 'NMC-WS-002',
        assignedAt: DateTime.now().subtract(const Duration(hours: 8)),
        completedAt: DateTime.now().subtract(const Duration(minutes: 45)),
        assignmentAgeHours: 7.25,
        technicianNotes: 'Dumpster emptied and area disinfected.',
        evidenceCount: 1,
        hasBeforePhoto: true,
        hasAfterPhoto: false,
        hasInspectionPdf: true,
        isGeoVerified: false,
        distanceMeters: 250.0,
        accuracyMeters: 60.0,
      ),
    ],
  );
}

void main() {
  group('Smart Nagpur Step 10 — Admin Operations & Verification Dashboard Tests', () {
    test('1. VerificationQueueItem JSON serialization and getters', () {
      final item = VerificationQueueItem(
        complaintId: 'c1',
        assignmentId: 'a1',
        issue: 'Broken water pipe',
        serviceType: 'water',
        priority: AssignmentPriority.high,
        complaintAddress: 'Civil Lines, Nagpur',
        complaintCreatedAt: DateTime.now(),
        staffId: 's1',
        staffName: 'Vikram Singh',
        staffEmployeeId: 'NMC-WT-003',
        assignedAt: DateTime.now(),
        completedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        assignmentAgeHours: 1.5,
        technicianNotes: 'Pipe leak repaired with PVC sleeve.',
        evidenceCount: 3,
        hasBeforePhoto: true,
        hasAfterPhoto: true,
        hasInspectionPdf: true,
        isGeoVerified: true,
      );

      expect(item.hasCompleteEvidence, isTrue);
      expect(item.formattedCompletedAgo, '30m ago');

      final json = item.toJson();
      expect(json['complaint_id'], 'c1');
      expect(json['is_geo_verified'], isTrue);

      final reconstructed = VerificationQueueItem.fromJson(json);
      expect(reconstructed.issue, 'Broken water pipe');
      expect(reconstructed.hasCompleteEvidence, isTrue);
    });

    test('2. StaffWorkloadSummary and StaffWorkloadItem JSON parsing', () {
      final summary = StaffWorkloadSummary.fromJson({
        'total_staff': 15,
        'active_staff': 14,
        'on_duty_staff': 10,
        'pending_tasks': 4,
        'in_progress_tasks': 8,
        'completed_tasks': 25,
      });

      expect(summary.totalStaff, 15);
      expect(summary.onDutyStaff, 10);
      expect(summary.inProgressTasks, 8);

      final staffItem = StaffWorkloadItem.fromJson({
        'staff_id': 'staff-100',
        'name': 'Anil Deshmukh',
        'employee_id': 'NMC-RD-100',
        'department': 'ROAD',
        'role': 'FIELD_WORKER',
        'is_on_duty': true,
        'is_active': true,
        'active_task_count': 3,
        'completed_task_count': 12,
      });

      expect(staffItem.staffId, 'staff-100');
      expect(staffItem.isOnDuty, isTrue);
      expect(staffItem.activeTaskCount, 3);
    });

    test('3. AdminOperationsFilter copyWith and hasActiveFilter', () {
      const emptyFilter = AdminOperationsFilter();
      expect(emptyFilter.hasActiveFilter, isFalse);

      final deptFilter = emptyFilter.copyWith(department: StaffDepartment.road);
      expect(deptFilter.hasActiveFilter, isTrue);
      expect(deptFilter.department, StaffDepartment.road);

      final priorityFilter = deptFilter.copyWith(priority: AssignmentPriority.urgent);
      expect(priorityFilter.priority, AssignmentPriority.urgent);
      expect(priorityFilter.department, StaffDepartment.road);

      final cleared = priorityFilter.copyWith(clearDepartment: true, clearPriority: true);
      expect(cleared.hasActiveFilter, isFalse);
      expect(cleared.department, isNull);
      expect(cleared.priority, isNull);
    });

    test('4. AdminOperationsDashboard getters and status counts', () {
      final dashboard = _sampleDashboard();

      expect(dashboard.awaitingVerificationCount, 2);
      expect(dashboard.submittedComplaintsCount, 4);
      expect(dashboard.inProgressComplaintsCount, 5);
      expect(dashboard.resolvedComplaintsCount, 12);
      expect(dashboard.reworkComplaintsCount, 1);
    });

    test('5. AdminController loads operations dashboard and updates state', () async {
      final mockAuth = MockAdminAuthGateway();
      final mockData = MockAdminDataGateway();
      mockAuth.currentAdmin = _testAdmin();
      mockData.simulatedDashboard = _sampleDashboard();

      final controller = AdminController(authGateway: mockAuth, dataGateway: mockData);

      expect(controller.operationsDashboard, isNull);

      await controller.loadOperationsDashboard();

      expect(controller.operationsDashboard, isNotNull);
      expect(controller.operationsDashboard!.verificationQueue.length, 2);
      expect(controller.operationsDashboard!.staffWorkloadSummary.onDutyStaff, 7);
    });

    test('6. AdminController applies department and priority filters', () async {
      final mockAuth = MockAdminAuthGateway();
      final mockData = MockAdminDataGateway();
      mockAuth.currentAdmin = _testAdmin();
      mockData.simulatedDashboard = _sampleDashboard();

      final controller = AdminController(authGateway: mockAuth, dataGateway: mockData);

      // Filter by ROAD
      controller.setOperationsFilter(
        const AdminOperationsFilter(department: StaffDepartment.road),
      );
      await pumpEventQueue();

      expect(controller.operationsDashboard!.verificationQueue.length, 1);
      expect(controller.operationsDashboard!.verificationQueue.first.serviceType, 'road');

      // Clear filter
      controller.clearOperationsFilter();
      await pumpEventQueue();

      expect(controller.operationsDashboard!.verificationQueue.length, 2);
    });

    test('7. AdminController handles unauthorized access gracefully', () async {
      final mockAuth = MockAdminAuthGateway();
      final mockData = MockAdminDataGateway();
      mockAuth.currentAdmin = _testAdmin();
      mockData.shouldThrowUnauthorized = true;

      final controller = AdminController(authGateway: mockAuth, dataGateway: mockData);

      await controller.loadOperationsDashboard();

      expect(controller.error, contains('Access denied'));
    });

    testWidgets('8. AdminOperationsScreen renders tabs, verification cards, and metrics', (tester) async {
      final mockAuth = MockAdminAuthGateway();
      final mockData = MockAdminDataGateway();
      mockAuth.currentAdmin = _testAdmin();
      mockData.simulatedDashboard = _sampleDashboard();

      final controller = AdminController(authGateway: mockAuth, dataGateway: mockData);
      await controller.loadOperationsDashboard();

      await tester.pumpWidget(
        MaterialApp(
          home: AdminOperationsScreen(controller: controller),
        ),
      );

      await tester.pumpAndSettle();

      // Check App Bar and Tabs
      expect(find.text('Field Operations & Verification'), findsOneWidget);
      expect(find.text('Verification Queue'), findsOneWidget);
      expect(find.text('Staff Workload'), findsOneWidget);
      expect(find.text('Workload Breakdown'), findsOneWidget);

      // Check Verification Queue cards
      expect(find.text('Pothole near Sitabuldi flyover'), findsOneWidget);
      expect(find.text('Garbage accumulation at Dharampeth'), findsOneWidget);
      expect(find.text('GPS Verified'), findsOneWidget);
      expect(find.text('GPS Unverified'), findsOneWidget);

      // Switch to Staff Workload Tab
      await tester.tap(find.text('Staff Workload'));
      await tester.pumpAndSettle();

      expect(find.text('On Duty'), findsOneWidget);
      expect(find.text('7 / 9'), findsOneWidget);
      expect(find.text('Ramesh Kumar'), findsOneWidget);
      expect(find.text('Suresh Patil'), findsOneWidget);
      expect(find.text('ON DUTY'), findsOneWidget);
      expect(find.text('OFF DUTY'), findsOneWidget);

      // Switch to Workload Breakdown Tab
      await tester.tap(find.text('Workload Breakdown'));
      await tester.pumpAndSettle();

      expect(find.text('Complaint Lifecycle Breakdown'), findsOneWidget);
      expect(find.text('Field Assignment Breakdown'), findsOneWidget);
      expect(find.text('Submitted (New)'), findsOneWidget);
      expect(find.text('Under Verification'), findsOneWidget);
    });
  });
}
