import 'package:flutter_test/flutter_test.dart';
import 'package:smart_nagpur/data/gateways/admin_auth_gateway.dart';
import 'package:smart_nagpur/data/gateways/admin_data_gateway.dart';
import 'package:smart_nagpur/domain/domain.dart';
import 'package:smart_nagpur/state/admin_controller.dart';

class MockAdminAuthGateway implements AdminAuthGateway {
  AdminProfile? currentAdmin;

  @override
  Future<AdminProfile?> getCurrentAdmin() async => currentAdmin;

  @override
  Future<AdminProfile> loginAdmin(String email, String password) async {
    final admin = AdminProfile(
      id: 'admin-uuid-001',
      email: email,
      name: 'Commissioner Sharma',
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
  Future<void> logoutAdmin() async {
    currentAdmin = null;
  }

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

class MockAdminDataGateway implements AdminDataGateway {
  final List<StaffProfile> mockStaff = [
    const StaffProfile(
      id: 'staff-road-1',
      name: 'Ramesh Patil',
      email: 'ramesh@smartnagpur.gov.in',
      employeeId: 'ROAD-101',
      department: StaffDepartment.road,
      role: StaffRole.fieldWorker,
      isActive: true,
    ),
    const StaffProfile(
      id: 'staff-road-inactive',
      name: 'Inactive Road Worker',
      email: 'inactive@smartnagpur.gov.in',
      employeeId: 'ROAD-999',
      department: StaffDepartment.road,
      role: StaffRole.fieldWorker,
      isActive: false,
    ),
    const StaffProfile(
      id: 'staff-waste-1',
      name: 'Ganesh Deshmukh',
      email: 'ganesh@smartnagpur.gov.in',
      employeeId: 'WASTE-201',
      department: StaffDepartment.waste,
      role: StaffRole.fieldWorker,
      isActive: true,
    ),
    const StaffProfile(
      id: 'staff-water-1',
      name: 'Vikram Joshi',
      email: 'vikram@smartnagpur.gov.in',
      employeeId: 'WATER-301',
      department: StaffDepartment.water,
      role: StaffRole.supervisor,
      isActive: true,
    ),
  ];

  final Map<String, ComplaintAssignment> assignments = {};
  int _idCounter = 0;
  bool shouldThrowUnauthorized = false;
  bool shouldThrowInvalidPriority = false;
  bool shouldThrowDepartmentMismatch = false;

  @override
  Future<List<StaffProfile>> getStaffMembers({
    StaffDepartment? department,
    bool? isActive,
    bool? isOnDuty,
  }) async {
    return mockStaff.where((s) {
      if (department != null && s.department != department) return false;
      if (isActive != null && s.isActive != isActive) return false;
      if (isOnDuty != null && s.isOnDuty != isOnDuty) return false;
      return true;
    }).toList();
  }

  @override
  Future<StaffProfile?> getStaffMember(String staffId) async {
    try {
      return mockStaff.firstWhere((s) => s.id == staffId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ComplaintAssignment> assignComplaint({
    required String complaintId,
    required String staffId,
    AssignmentPriority priority = AssignmentPriority.medium,
    String instructions = '',
  }) async {
    if (shouldThrowUnauthorized) {
      throw Exception('Access denied. Caller is not an active municipal administrator.');
    }
    if (shouldThrowInvalidPriority) {
      throw Exception('Invalid assignment priority.');
    }

    final staff = await getStaffMember(staffId);
    if (staff == null) {
      throw Exception('Staff member does not exist.');
    }
    if (!staff.isActive) {
      throw Exception('Cannot assign complaint to inactive staff member.');
    }

    if (shouldThrowDepartmentMismatch) {
      throw Exception('Staff department does not match complaint department.');
    }

    // Check existing assignment on complaint
    String? prevId;
    for (final a in assignments.values) {
      if (a.complaintId == complaintId && a.status == AssignmentStatus.assigned) {
        prevId = a.id;
        break;
      }
    }

    final assignmentId = 'asgn-${++_idCounter}';

    // If reassigned, mark previous
    if (prevId != null) {
      assignments[prevId] = assignments[prevId]!.copyWith(
        status: AssignmentStatus.reassigned,
        reassignedToId: assignmentId,
      );
    }

    final newAssignment = ComplaintAssignment(
      id: assignmentId,
      complaintId: complaintId,
      staffId: staffId,
      assignedBy: 'admin-uuid-001',
      status: AssignmentStatus.assigned,
      priority: priority,
      instructions: instructions,
      assignedAt: DateTime.now(),
      staffName: staff.name,
      staffEmployeeId: staff.employeeId,
      staffDepartment: staff.department,
    );

    assignments[assignmentId] = newAssignment;
    return newAssignment;
  }

  @override
  Future<ComplaintAssignment?> getComplaintAssignment(String assignmentId) async {
    return assignments[assignmentId];
  }

  @override
  Future<List<ComplaintAssignment>> getComplaintAssignmentsHistory(String complaintId) async {
    return assignments.values.where((a) => a.complaintId == complaintId).toList();
  }

  @override
  Future<ComplaintAssignment> approveComplaintAssignment(String assignmentId, {String reviewNotes = ''}) async {
    if (shouldThrowUnauthorized) {
      throw Exception('Access denied. Caller is not an authorized municipal administrator or supervisor.');
    }
    final asgn = assignments[assignmentId];
    if (asgn == null) throw Exception('Assignment does not exist.');
    if (asgn.status != AssignmentStatus.completed) {
      throw Exception('Invalid status transition: Cannot approve assignment in "${asgn.status.name}".');
    }

    final updated = asgn.copyWith(
      status: AssignmentStatus.approved,
    );
    assignments[assignmentId] = updated;
    return updated;
  }

  @override
  Future<ComplaintAssignment> requestReworkComplaintAssignment(String assignmentId, {String reworkInstructions = ''}) async {
    if (shouldThrowUnauthorized) {
      throw Exception('Access denied. Caller is not an authorized municipal administrator or supervisor.');
    }
    final asgn = assignments[assignmentId];
    if (asgn == null) throw Exception('Assignment does not exist.');
    if (asgn.status != AssignmentStatus.completed) {
      throw Exception('Invalid status transition: Cannot request rework on assignment in "${asgn.status.name}".');
    }

    final updated = asgn.copyWith(
      status: AssignmentStatus.reworkRequired,
      rejectionReason: reworkInstructions,
    );
    assignments[assignmentId] = updated;
    return updated;
  }

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
  Future<StaffProfile> createStaff({required String name, required String email, required String employeeId, required StaffDepartment department, StaffRole role = StaffRole.fieldWorker, String phone = '', String zone = 'ALL', String ward = '', String? password}) async {
    throw UnimplementedError();
  }
  @override
  Future<List<ComplaintEvidence>> getComplaintEvidence(String complaintId) async => [];
  @override
  Future<String> getEvidenceSignedUrl(String objectPath) async => '';
  @override
  Future<AdminOperationsDashboard> getOperationsDashboard({AdminOperationsFilter? filter}) async =>
      const AdminOperationsDashboard();
  @override
  void subscribeToAdminLiveUpdates(void Function() onUpdate) {}
  @override
  void unsubscribeFromAdminLiveUpdates() {}
}

void main() {
  group('Admin Complaint Assignment System Tests', () {
    late MockAdminAuthGateway authGateway;
    late MockAdminDataGateway dataGateway;
    late AdminController controller;

    setUp(() async {
      authGateway = MockAdminAuthGateway();
      dataGateway = MockAdminDataGateway();
      controller = AdminController(
        authGateway: authGateway,
        dataGateway: dataGateway,
      );
      await controller.loginAdmin('admin@smartnagpur.gov.in', 'AdminPassword123!');
    });

    test('1. Active staff members can be listed and filtered by department', () async {
      final roadStaff = await controller.getStaffMembers(
        department: StaffDepartment.road,
        isActive: true,
      );

      expect(roadStaff.length, 1);
      expect(roadStaff.first.name, 'Ramesh Patil');
      expect(roadStaff.first.employeeId, 'ROAD-101');
      expect(roadStaff.first.isActive, isTrue);
    });

    test('2. Inactive staff members are excluded from assignment list', () async {
      final activeRoadStaff = await controller.getStaffMembers(
        department: StaffDepartment.road,
        isActive: true,
      );

      expect(activeRoadStaff.any((s) => s.id == 'staff-road-inactive'), isFalse);
    });

    test('3. Inactive staff member cannot be assigned to a complaint', () async {
      final success = await controller.assignComplaint(
        complaintId: 'complaint-101',
        staffId: 'staff-road-inactive',
        priority: AssignmentPriority.high,
      );

      expect(success, isFalse);
      expect(controller.error, contains('inactive staff member'));
    });

    test('4. Admin can assign active staff member with priority and instructions', () async {
      final success = await controller.assignComplaint(
        complaintId: 'complaint-101',
        staffId: 'staff-road-1',
        priority: AssignmentPriority.urgent,
        instructions: 'Deploy patch vehicle to Sitabuldi junction.',
      );

      expect(success, isTrue);
      expect(controller.error, isNull);

      final history = await controller.getComplaintAssignmentsHistory('complaint-101');
      expect(history.length, 1);
      expect(history.first.staffId, 'staff-road-1');
      expect(history.first.priority, AssignmentPriority.urgent);
      expect(history.first.instructions, 'Deploy patch vehicle to Sitabuldi junction.');
      expect(history.first.status, AssignmentStatus.assigned);
    });

    test('5. Reassigning a complaint marks the previous assignment as reassigned', () async {
      // First assignment
      await controller.assignComplaint(
        complaintId: 'complaint-202',
        staffId: 'staff-road-1',
        priority: AssignmentPriority.medium,
        instructions: 'Initial road inspection.',
      );

      final initialHistory = await controller.getComplaintAssignmentsHistory('complaint-202');
      final firstAssignmentId = initialHistory.first.id;

      // Reassign to another staff member
      final success = await controller.assignComplaint(
        complaintId: 'complaint-202',
        staffId: 'staff-waste-1',
        priority: AssignmentPriority.high,
        instructions: 'Transferred to waste department clearance.',
      );

      expect(success, isTrue);

      final updatedPrevious = await controller.getComplaintAssignment(firstAssignmentId);
      expect(updatedPrevious?.status, AssignmentStatus.reassigned);
      expect(updatedPrevious?.reassignedToId, isNotNull);

      final allHistory = await controller.getComplaintAssignmentsHistory('complaint-202');
      expect(allHistory.length, 2);
    });

    test('6. Unauthorized admin request is rejected', () async {
      dataGateway.shouldThrowUnauthorized = true;

      final success = await controller.assignComplaint(
        complaintId: 'complaint-101',
        staffId: 'staff-road-1',
      );

      expect(success, isFalse);
      expect(controller.error, contains('Access denied'));
    });

    test('7. ComplaintAssignment domain entity JSON roundtrip preserves data', () {
      final assignment = ComplaintAssignment(
        id: 'asgn-505',
        complaintId: 'c-100',
        staffId: 's-200',
        assignedBy: 'adm-300',
        status: AssignmentStatus.assigned,
        priority: AssignmentPriority.urgent,
        instructions: 'Urgent water leakage repair.',
        assignedAt: DateTime(2026, 8, 19, 10, 30),
        acceptedAt: DateTime(2026, 8, 19, 10, 35),
      );

      final json = assignment.toJson();
      final restored = ComplaintAssignment.fromJson(json);

      expect(restored.id, 'asgn-505');
      expect(restored.complaintId, 'c-100');
      expect(restored.priority, AssignmentPriority.urgent);
      expect(restored.instructions, 'Urgent water leakage repair.');
      expect(restored.status, AssignmentStatus.assigned);
    });

    test('8. Priority and Status enum parsing handle edge cases safely', () {
      expect(AssignmentPriority.fromCode('urgent'), AssignmentPriority.urgent);
      expect(AssignmentPriority.fromCode('invalid'), AssignmentPriority.medium);
      expect(AssignmentStatus.fromCode('inProgress'), AssignmentStatus.inProgress);
      expect(AssignmentStatus.fromCode('reassigned'), AssignmentStatus.reassigned);
      expect(AssignmentStatus.fromCode(null), AssignmentStatus.assigned);
    });

    test('9. Department mismatch is rejected server-side (ROAD complaint to WASTE staff)', () async {
      dataGateway.shouldThrowDepartmentMismatch = true;

      final success = await controller.assignComplaint(
        complaintId: 'complaint-road-1',
        staffId: 'staff-waste-1',
        priority: AssignmentPriority.high,
      );

      expect(success, isFalse);
      expect(controller.error, contains('Staff department does not match complaint department'));
    });

    test('10. Admin can approve completed assignment', () async {
      // Create assignment and set to completed
      final assignment = await controller.assignComplaint(
        complaintId: 'complaint-101',
        staffId: 'staff-road-1',
      );
      expect(assignment, isTrue);

      final asgn = dataGateway.assignments.values.first;
      dataGateway.assignments[asgn.id] = asgn.copyWith(status: AssignmentStatus.completed);

      final success = await controller.approveComplaintAssignment(
        asgn.id,
        reviewNotes: 'Inspected and verified road patch.',
      );

      expect(success, isTrue);
      expect(dataGateway.assignments[asgn.id]?.status, AssignmentStatus.approved);
    });

    test('11. Admin can request rework with instructions on completed assignment', () async {
      // Create assignment and set to completed
      await controller.assignComplaint(
        complaintId: 'complaint-101',
        staffId: 'staff-road-1',
      );
      final asgn = dataGateway.assignments.values.first;
      dataGateway.assignments[asgn.id] = asgn.copyWith(status: AssignmentStatus.completed);

      final success = await controller.requestReworkComplaintAssignment(
        asgn.id,
        reworkInstructions: 'Re-roll asphalt edges evenly.',
      );

      expect(success, isTrue);
      expect(dataGateway.assignments[asgn.id]?.status, AssignmentStatus.reworkRequired);
      expect(dataGateway.assignments[asgn.id]?.rejectionReason, 'Re-roll asphalt edges evenly.');
    });

    test('12. Unauthorized caller cannot approve or request rework', () async {
      await controller.assignComplaint(
        complaintId: 'complaint-101',
        staffId: 'staff-road-1',
      );
      final asgn = dataGateway.assignments.values.first;
      dataGateway.assignments[asgn.id] = asgn.copyWith(status: AssignmentStatus.completed);

      dataGateway.shouldThrowUnauthorized = true;

      final approveSuccess = await controller.approveComplaintAssignment(asgn.id);
      expect(approveSuccess, isFalse);
      expect(controller.error, contains('Access denied'));

      final reworkSuccess = await controller.requestReworkComplaintAssignment(asgn.id);
      expect(reworkSuccess, isFalse);
      expect(controller.error, contains('Access denied'));
    });

    test('13. Invalid transition (approving uncompleted assignment) is rejected', () async {
      await controller.assignComplaint(
        complaintId: 'complaint-101',
        staffId: 'staff-road-1',
      );
      final asgn = dataGateway.assignments.values.first;
      // Status is currently 'assigned', not 'completed'

      final success = await controller.approveComplaintAssignment(asgn.id);
      expect(success, isFalse);
      expect(controller.error, contains('Invalid status transition'));
    });
  });
}
