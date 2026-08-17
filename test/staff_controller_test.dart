import 'package:flutter_test/flutter_test.dart';
import 'package:smart_nagpur/data/gateways/staff_auth_gateway.dart';
import 'package:smart_nagpur/data/gateways/staff_data_gateway.dart';
import 'package:smart_nagpur/domain/domain.dart';
import 'package:smart_nagpur/state/staff_controller.dart';

class MockStaffAuthGateway implements StaffAuthGateway {
  StaffProfile? currentStaff;
  bool shouldThrowInvalidCredentials = false;
  bool shouldThrowInactive = false;
  bool shouldThrowMissingProfile = false;
  bool shouldThrowNetworkError = false;

  @override
  Future<StaffProfile?> getCurrentStaff() async {
    if (shouldThrowNetworkError) {
      throw Exception('Network connection unavailable.');
    }
    return currentStaff;
  }

  @override
  Future<StaffProfile> loginStaff(String email, String password) async {
    if (shouldThrowNetworkError) {
      throw Exception('Network connection unavailable.');
    }
    if (shouldThrowInvalidCredentials) {
      throw Exception('Invalid staff email or password. Please try again.');
    }
    if (shouldThrowMissingProfile) {
      throw Exception('No municipal staff profile found for this account. Please contact your administrator.');
    }
    if (shouldThrowInactive) {
      throw Exception('Your staff account is currently inactive. Please contact the administrator.');
    }

    final profile = StaffProfile(
      id: 'staff-uuid-101',
      name: 'Rajesh Kumar',
      email: email,
      phone: '9876543210',
      employeeId: 'ROAD-1024',
      department: StaffDepartment.road,
      role: StaffRole.fieldWorker,
      zone: 'Zone 1 - Laxmi Nagar',
      isActive: true,
      isOnDuty: false,
    );
    currentStaff = profile;
    return profile;
  }

  @override
  Future<void> logoutStaff() async {
    currentStaff = null;
  }

  @override
  Future<void> setDutyStatus(bool isOnDuty) async {
    if (shouldThrowNetworkError) {
      throw Exception('Failed to update duty status.');
    }
    if (currentStaff != null) {
      currentStaff = currentStaff!.copyWith(isOnDuty: isOnDuty);
    }
  }

  @override
  Future<bool> isStaffAuthenticated() async {
    return currentStaff != null && currentStaff!.isActive;
  }
}

class MockStaffDataGateway implements StaffDataGateway {
  StaffProfile? profile;

  @override
  Future<StaffProfile?> getStaffProfile() async => profile;

  @override
  Future<void> updateDutyStatus(bool isOnDuty) async {
    if (profile != null) {
      profile = profile!.copyWith(isOnDuty: isOnDuty);
    }
  }

  @override
  Future<List<ComplaintAssignment>> getMyTasks() async => [];

  @override
  Future<ComplaintAssignment?> getTaskDetails(String assignmentId) async => null;

  @override
  Future<ComplaintAssignment> acceptTask(String assignmentId) async {
    throw UnimplementedError();
  }

  @override
  Future<ComplaintAssignment> startTask(String assignmentId) async {
    throw UnimplementedError();
  }

  @override
  Future<ComplaintAssignment> completeTask(String assignmentId, {String notes = ''}) async {
    throw UnimplementedError();
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
  void subscribeToStaffTaskUpdates(String staffId, void Function() onUpdate) {}

  @override
  void unsubscribeFromStaffTaskUpdates() {}
}


void main() {
  group('StaffController Authentication & Session Tests', () {
    late MockStaffAuthGateway authGateway;
    late MockStaffDataGateway dataGateway;
    late StaffController controller;

    setUp(() {
      authGateway = MockStaffAuthGateway();
      dataGateway = MockStaffDataGateway();
      controller = StaffController(
        authGateway: authGateway,
        dataGateway: dataGateway,
      );
    });

    test('1. Staff login succeeds with valid credentials and sets profile', () async {
      expect(controller.isAuthenticated, isFalse);

      final success = await controller.login('rajesh@smartnagpur.gov.in', 'ValidPassword123!');

      expect(success, isTrue);
      expect(controller.isAuthenticated, isTrue);
      expect(controller.currentStaff?.name, 'Rajesh Kumar');
      expect(controller.currentStaff?.employeeId, 'ROAD-1024');
      expect(controller.currentStaff?.department, StaffDepartment.road);
      expect(controller.currentStaff?.role, StaffRole.fieldWorker);
      expect(controller.errorMessage, isNull);
    });

    test('2. Staff login fails on invalid credentials with safe error message', () async {
      authGateway.shouldThrowInvalidCredentials = true;

      final success = await controller.login('rajesh@smartnagpur.gov.in', 'WrongPassword');

      expect(success, isFalse);
      expect(controller.isAuthenticated, isFalse);
      expect(controller.currentStaff, isNull);
      expect(controller.errorMessage, contains('Invalid staff email or password'));
    });

    test('3. Staff login fails when account has no staff profile', () async {
      authGateway.shouldThrowMissingProfile = true;

      final success = await controller.login('citizen@gmail.com', 'ValidPassword123!');

      expect(success, isFalse);
      expect(controller.isAuthenticated, isFalse);
      expect(controller.errorMessage, contains('No municipal staff profile found'));
    });

    test('4. Inactive staff account is rejected during login', () async {
      authGateway.shouldThrowInactive = true;

      final success = await controller.login('suspended@smartnagpur.gov.in', 'ValidPassword123!');

      expect(success, isFalse);
      expect(controller.isAuthenticated, isFalse);
      expect(controller.errorMessage, contains('account is currently inactive'));
    });

    test('5. Active staff account loads profile and credentials correctly', () async {
      await controller.login('rajesh@smartnagpur.gov.in', 'Pass123!');

      expect(controller.currentStaff?.isActive, isTrue);
      expect(controller.currentStaff?.zone, 'Zone 1 - Laxmi Nagar');
      expect(controller.currentStaff?.phone, '9876543210');
    });

    test('6. Staff Profile domain entity enforces immutability and copyWith', () {
      const original = StaffProfile(
        id: 's-1',
        name: 'Amit Patil',
        email: 'amit@smartnagpur.gov.in',
        employeeId: 'WASTE-2048',
        department: StaffDepartment.waste,
        role: StaffRole.supervisor,
      );

      final modified = original.copyWith(isOnDuty: true);

      expect(original.isOnDuty, isFalse);
      expect(modified.isOnDuty, isTrue);
      expect(modified.employeeId, 'WASTE-2048');
      expect(modified.department, StaffDepartment.waste);
      expect(modified.role, StaffRole.supervisor);
    });

    test('7. Staff can toggle on-duty status back and forth', () async {
      await controller.login('rajesh@smartnagpur.gov.in', 'Pass123!');
      expect(controller.isOnDuty, isFalse);

      // Toggle ON
      await controller.toggleDutyStatus();
      expect(controller.isOnDuty, isTrue);
      expect(authGateway.currentStaff?.isOnDuty, isTrue);

      // Toggle OFF
      await controller.toggleDutyStatus();
      expect(controller.isOnDuty, isFalse);
      expect(authGateway.currentStaff?.isOnDuty, isFalse);
    });

    test('8. Staff on-duty toggle reverts optimistically when network fails', () async {
      await controller.login('rajesh@smartnagpur.gov.in', 'Pass123!');
      expect(controller.isOnDuty, isFalse);

      authGateway.shouldThrowNetworkError = true;
      await controller.toggleDutyStatus();

      expect(controller.isOnDuty, isFalse);
      expect(controller.errorMessage, contains('Failed to update duty status'));
    });

    test('9. Logout clears staff session and state', () async {
      await controller.login('rajesh@smartnagpur.gov.in', 'Pass123!');
      expect(controller.isAuthenticated, isTrue);

      await controller.logout();

      expect(controller.isAuthenticated, isFalse);
      expect(controller.currentStaff, isNull);
      expect(controller.errorMessage, isNull);
    });

    test('10. Session restoration on cold start initializes existing staff', () async {
      authGateway.currentStaff = const StaffProfile(
        id: 'staff-uuid-101',
        name: 'Sunita Sharma',
        email: 'sunita@smartnagpur.gov.in',
        employeeId: 'WATER-5012',
        department: StaffDepartment.water,
        role: StaffRole.officer,
        isActive: true,
        isOnDuty: true,
      );

      await controller.checkAuthStatus();

      expect(controller.isAuthenticated, isTrue);
      expect(controller.currentStaff?.name, 'Sunita Sharma');
      expect(controller.currentStaff?.role, StaffRole.officer);
      expect(controller.isOnDuty, isTrue);
    });

    test('11. Network failure on startup handles gracefully without crash', () async {
      authGateway.shouldThrowNetworkError = true;

      await controller.checkAuthStatus();

      expect(controller.isAuthenticated, isFalse);
      expect(controller.currentStaff, isNull);
      expect(controller.errorMessage, contains('Network connection unavailable'));
    });
  });
}
