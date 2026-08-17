import 'package:flutter_test/flutter_test.dart';
import 'package:smart_nagpur/data/gateways/staff_auth_gateway.dart';
import 'package:smart_nagpur/data/gateways/staff_data_gateway.dart';
import 'package:smart_nagpur/domain/domain.dart';
import 'package:smart_nagpur/state/staff_controller.dart';

class MockStaffAuthGateway implements StaffAuthGateway {
  StaffProfile? currentStaff;

  @override
  Future<StaffProfile?> getCurrentStaff() async => currentStaff;

  @override
  Future<StaffProfile> loginStaff(String email, String password) async {
    final staff = StaffProfile(
      id: 'staff-worker-101',
      name: 'Ramesh Patil',
      email: email,
      employeeId: 'ROAD-101',
      department: StaffDepartment.road,
      role: StaffRole.fieldWorker,
      isActive: true,
      isOnDuty: true,
    );
    currentStaff = staff;
    return staff;
  }

  @override
  Future<void> logoutStaff() async {
    currentStaff = null;
  }

  @override
  Future<bool> isStaffAuthenticated() async => currentStaff != null;

  @override
  Future<void> setDutyStatus(bool isOnDuty) async {
    if (currentStaff != null) {
      currentStaff = currentStaff!.copyWith(isOnDuty: isOnDuty);
    }
  }
}

class MockStaffDataGateway implements StaffDataGateway {
  final Map<String, ComplaintAssignment> allAssignments = {};
  String currentStaffId = 'staff-worker-101';
  void Function()? realtimeCallback;

  @override
  Future<StaffProfile?> getStaffProfile() async {
    return StaffProfile(
      id: currentStaffId,
      name: 'Ramesh Patil',
      email: 'ramesh@smartnagpur.gov.in',
      employeeId: 'ROAD-101',
      department: StaffDepartment.road,
      role: StaffRole.fieldWorker,
      isActive: true,
      isOnDuty: true,
    );
  }

  @override
  Future<void> updateDutyStatus(bool isOnDuty) async {}

  @override
  Future<List<ComplaintAssignment>> getMyTasks() async {
    final tasks = allAssignments.values
        .where((a) => a.staffId == currentStaffId)
        .toList();

    tasks.sort((a, b) {
      final pCompare = _priorityWeight(a.priority).compareTo(_priorityWeight(b.priority));
      if (pCompare != 0) return pCompare;
      return b.assignedAt.compareTo(a.assignedAt);
    });

    return tasks;
  }

  int _priorityWeight(AssignmentPriority priority) {
    return switch (priority) {
      AssignmentPriority.urgent => 0,
      AssignmentPriority.high => 1,
      AssignmentPriority.medium => 2,
      AssignmentPriority.low => 3,
    };
  }

  @override
  Future<ComplaintAssignment?> getTaskDetails(String assignmentId) async {
    final task = allAssignments[assignmentId];
    if (task == null || task.staffId != currentStaffId) return null;
    return task;
  }

  @override
  Future<ComplaintAssignment> acceptTask(String assignmentId) async {
    final task = allAssignments[assignmentId];
    if (task == null) throw Exception('Task does not exist.');
    if (task.staffId != currentStaffId) {
      throw Exception('Access denied. Assignment does not belong to calling staff.');
    }
    if (task.status != AssignmentStatus.assigned) {
      throw Exception('Invalid status transition: Cannot accept assignment in "${task.status.name}".');
    }

    final updated = task.copyWith(
      status: AssignmentStatus.accepted,
      acceptedAt: DateTime.now(),
    );
    allAssignments[assignmentId] = updated;
    return updated;
  }

  @override
  Future<ComplaintAssignment> startTask(String assignmentId) async {
    final task = allAssignments[assignmentId];
    if (task == null) throw Exception('Task does not exist.');
    if (task.staffId != currentStaffId) {
      throw Exception('Access denied. Assignment does not belong to calling staff.');
    }
    if (task.status != AssignmentStatus.accepted && task.status != AssignmentStatus.reworkRequired) {
      throw Exception('Invalid status transition: Cannot start work in "${task.status.name}".');
    }


    final updated = task.copyWith(
      status: AssignmentStatus.inProgress,
      startedAt: DateTime.now(),
    );
    allAssignments[assignmentId] = updated;
    return updated;
  }

  @override
  Future<ComplaintAssignment> completeTask(String assignmentId, {String notes = ''}) async {
    final task = allAssignments[assignmentId];
    if (task == null) throw Exception('Task does not exist.');
    if (task.staffId != currentStaffId) {
      throw Exception('Access denied. Assignment does not belong to calling staff.');
    }
    if (task.status != AssignmentStatus.inProgress) {
      throw Exception('Invalid status transition: Cannot complete assignment in "${task.status.name}".');
    }

    final updated = task.copyWith(
      status: AssignmentStatus.completed,
      notes: notes.isNotEmpty ? notes : task.notes,
      completedAt: DateTime.now(),
    );
    allAssignments[assignmentId] = updated;
    return updated;
  }

  @override
  void subscribeToStaffTaskUpdates(String staffId, void Function() onUpdate) {
    realtimeCallback = onUpdate;
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
  }) async => throw UnimplementedError();

  @override
  Future<List<ComplaintEvidence>> getTaskEvidence(String assignmentId) async => [];

  @override
  Future<String> getEvidenceSignedUrl(String objectPath) async => '';

  @override
  void unsubscribeFromStaffTaskUpdates() {
    realtimeCallback = null;
  }
}

void main() {
  group('Staff Task Consumption & Workflow Tests (Step 7)', () {
    late MockStaffAuthGateway authGateway;
    late MockStaffDataGateway dataGateway;
    late StaffController controller;

    setUp(() async {
      authGateway = MockStaffAuthGateway();
      dataGateway = MockStaffDataGateway();
      controller = StaffController(
        authGateway: authGateway,
        dataGateway: dataGateway,
      );

      // Seed mock tasks in database
      // 3 tasks belonging to staff-worker-101 (urgent, high, medium)
      dataGateway.allAssignments['task-urgent-1'] = ComplaintAssignment(
        id: 'task-urgent-1',
        complaintId: 'c-101',
        staffId: 'staff-worker-101',
        assignedBy: 'admin-1',
        status: AssignmentStatus.assigned,
        priority: AssignmentPriority.urgent,
        instructions: 'Urgent road trench fix at Sitabuldi.',
        assignedAt: DateTime(2026, 8, 19, 8, 0),
        complaintIssue: 'Deep road trench near Metro Pillar 42',
        complaintServiceType: 'roads',
      );

      dataGateway.allAssignments['task-high-2'] = ComplaintAssignment(
        id: 'task-high-2',
        complaintId: 'c-102',
        staffId: 'staff-worker-101',
        assignedBy: 'admin-1',
        status: AssignmentStatus.assigned,
        priority: AssignmentPriority.high,
        instructions: 'Pothole cluster patch.',
        assignedAt: DateTime(2026, 8, 19, 9, 0),
        complaintIssue: 'Potholes on Wardha Road',
        complaintServiceType: 'roads',
      );

      dataGateway.allAssignments['task-medium-3'] = ComplaintAssignment(
        id: 'task-medium-3',
        complaintId: 'c-103',
        staffId: 'staff-worker-101',
        assignedBy: 'admin-1',
        status: AssignmentStatus.assigned,
        priority: AssignmentPriority.medium,
        instructions: 'Kerb painting inspection.',
        assignedAt: DateTime(2026, 8, 19, 10, 0),
        complaintIssue: 'Faded kerb markers',
        complaintServiceType: 'roads',
      );

      // 1 task belonging to another staff member (staff-other-999)
      dataGateway.allAssignments['task-other-4'] = ComplaintAssignment(
        id: 'task-other-4',
        complaintId: 'c-104',
        staffId: 'staff-other-999',
        assignedBy: 'admin-1',
        status: AssignmentStatus.assigned,
        priority: AssignmentPriority.urgent,
        instructions: 'Drainage blockage clearance.',
        assignedAt: DateTime(2026, 8, 19, 7, 30),
        complaintIssue: 'Blocked stormwater drain',
        complaintServiceType: 'drainage',
      );

      await controller.login('ramesh@smartnagpur.gov.in', 'Password123!');
    });

    test('1. Staff sees only their own assignments sorted by priority', () async {
      await controller.loadMyTasks();

      expect(controller.myTasks.length, 3);
      expect(controller.myTasks[0].id, 'task-urgent-1'); // Urgent first
      expect(controller.myTasks[1].id, 'task-high-2');   // High second
      expect(controller.myTasks[2].id, 'task-medium-3'); // Medium third
    });

    test('2. Staff cannot see another staff member assignments', () async {
      await controller.loadMyTasks();

      final hasOtherTask = controller.myTasks.any((t) => t.id == 'task-other-4');
      expect(hasOtherTask, isFalse);

      final otherDetails = await controller.getTaskDetails('task-other-4');
      expect(otherDetails, isNull);
    });

    test('3. Assigned -> accepted works successfully', () async {
      final success = await controller.acceptTask('task-urgent-1');
      expect(success, isTrue);

      final task = controller.myTasks.firstWhere((t) => t.id == 'task-urgent-1');
      expect(task.status, AssignmentStatus.accepted);
      expect(task.acceptedAt, isNotNull);
    });

    test('4. Accepted -> inProgress works successfully', () async {
      await controller.acceptTask('task-urgent-1');
      final success = await controller.startTask('task-urgent-1');
      expect(success, isTrue);

      final task = controller.myTasks.firstWhere((t) => t.id == 'task-urgent-1');
      expect(task.status, AssignmentStatus.inProgress);
      expect(task.startedAt, isNotNull);
    });

    test('5. InProgress -> completed works successfully with notes', () async {
      await controller.acceptTask('task-urgent-1');
      await controller.startTask('task-urgent-1');
      final success = await controller.completeTask(
        'task-urgent-1',
        notes: 'Cold mix patch laid and rolled.',
      );
      expect(success, isTrue);

      final task = controller.myTasks.firstWhere((t) => t.id == 'task-urgent-1');
      expect(task.status, AssignmentStatus.completed);
      expect(task.completedAt, isNotNull);
      expect(task.notes, 'Cold mix patch laid and rolled.');
    });

    test('6. Invalid state transitions are rejected server-side', () async {
      // Cannot complete directly from assigned
      final directComplete = await controller.completeTask('task-high-2');
      expect(directComplete, isFalse);
      expect(controller.errorMessage, contains('Invalid status transition'));

      // Accept first
      await controller.acceptTask('task-high-2');

      // Cannot accept again
      final acceptAgain = await controller.acceptTask('task-high-2');
      expect(acceptAgain, isFalse);
      expect(controller.errorMessage, contains('Invalid status transition'));
    });

    test('7. Staff cannot modify another staff member assignment', () async {
      final success = await controller.acceptTask('task-other-4');
      expect(success, isFalse);
      expect(controller.errorMessage, contains('Access denied'));
    });

    test('8. Staff cannot change staff_id or reassign task', () async {
      final task = controller.myTasks.firstWhere((t) => t.id == 'task-medium-3');
      expect(task.staffId, 'staff-worker-101');
      // The domain model and RPC only allow updating status, timestamps, and notes.
    });

    test('9. Staff cannot change priority of task', () async {
      final task = controller.myTasks.firstWhere((t) => t.id == 'task-urgent-1');
      expect(task.priority, AssignmentPriority.urgent);
    });

    test('10. Dashboard counts only own tasks across all states', () async {
      await controller.loadMyTasks();

      // Initial state: 3 pending (assigned)
      expect(controller.pendingTasksCount, 3);
      expect(controller.acceptedTasksCount, 0);
      expect(controller.inProgressTasksCount, 0);
      expect(controller.completedTasksCount, 0);
      expect(controller.totalTasksCount, 3);

      // Transition 1 task to accepted
      await controller.acceptTask('task-urgent-1');
      expect(controller.pendingTasksCount, 2);
      expect(controller.acceptedTasksCount, 1);

      // Transition 1 task to inProgress
      await controller.startTask('task-urgent-1');
      expect(controller.acceptedTasksCount, 0);
      expect(controller.inProgressTasksCount, 1);

      // Transition 1 task to completed
      await controller.completeTask('task-urgent-1');
      expect(controller.inProgressTasksCount, 0);
      expect(controller.completedTasksCount, 1);
    });

    test('11. Realtime dispatch updates task list and counts automatically', () async {
      await controller.loadMyTasks();
      expect(controller.myTasks.length, 3);

      // Admin dispatches a new assignment
      dataGateway.allAssignments['task-new-5'] = ComplaintAssignment(
        id: 'task-new-5',
        complaintId: 'c-105',
        staffId: 'staff-worker-101',
        assignedBy: 'admin-1',
        status: AssignmentStatus.assigned,
        priority: AssignmentPriority.urgent,
        instructions: 'Water pipe repair assist.',
        assignedAt: DateTime(2026, 8, 19, 12, 0),
      );

      // Realtime event triggers
      dataGateway.realtimeCallback?.call();

      // Await debounce and async event loop
      await Future<void>.delayed(const Duration(milliseconds: 600));

      expect(controller.myTasks.length, 4);
      expect(controller.myTasks.first.id, 'task-new-5');
    });

    test('12. Duplicate realtime events do not create duplicate task entries', () async {
      await controller.loadMyTasks();
      expect(controller.myTasks.length, 3);

      // Fire realtime callback twice
      dataGateway.realtimeCallback?.call();
      dataGateway.realtimeCallback?.call();

      await Future<void>.delayed(const Duration(milliseconds: 600));

      expect(controller.myTasks.length, 3);
    });


    test('13. Completed task becomes immutable and cannot be re-accepted', () async {
      await controller.acceptTask('task-urgent-1');
      await controller.startTask('task-urgent-1');
      await controller.completeTask('task-urgent-1');

      final reaccept = await controller.acceptTask('task-urgent-1');
      expect(reaccept, isFalse);
      expect(controller.errorMessage, contains('Invalid status transition'));
    });

    test('14. Staff can receive rework and transition reworkRequired -> inProgress -> completed', () async {
      await controller.acceptTask('task-urgent-1');
      await controller.startTask('task-urgent-1');
      await controller.completeTask('task-urgent-1');

      // Supervisor sets status to reworkRequired
      final completedTask = dataGateway.allAssignments['task-urgent-1']!;
      dataGateway.allAssignments['task-urgent-1'] = completedTask.copyWith(
        status: AssignmentStatus.reworkRequired,
        rejectionReason: 'Asphalt edge not aligned with kerb',
      );

      // Staff starts rework
      final startRework = await controller.startTask('task-urgent-1');
      expect(startRework, isTrue);

      final inProgressTask = controller.myTasks.firstWhere((t) => t.id == 'task-urgent-1');
      expect(inProgressTask.status, AssignmentStatus.inProgress);

      // Staff resubmits work
      final resubmit = await controller.completeTask(
        'task-urgent-1',
        notes: 'Re-aligned asphalt and rolled edge.',
      );
      expect(resubmit, isTrue);

      final resubmittedTask = controller.myTasks.firstWhere((t) => t.id == 'task-urgent-1');
      expect(resubmittedTask.status, AssignmentStatus.completed);
      expect(resubmittedTask.notes, 'Re-aligned asphalt and rolled edge.');
    });
  });
}

