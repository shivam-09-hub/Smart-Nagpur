import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:smart_nagpur/data/gateways/admin_auth_gateway.dart';
import 'package:smart_nagpur/data/gateways/admin_data_gateway.dart';
import 'package:smart_nagpur/domain/domain.dart';

class AdminController extends ChangeNotifier {
  AdminController({required this.authGateway, required this.dataGateway});

  final AdminAuthGateway authGateway;
  final AdminDataGateway dataGateway;

  AdminProfile? _currentAdmin;
  AdminStats? _adminStats;
  List<ComplaintRecord> _pendingComplaints = [];
  List<VendorApplication> _pendingApplications = [];
  List<AppNotification> _adminNotifications = [];
  List<UserProfile> _users = [];
  AdminOperationsDashboard? _operationsDashboard;
  AdminOperationsFilter _operationsFilter = const AdminOperationsFilter();

  bool _isLoading = false;
  String? _error;

  Timer? _realtimeDebounceTimer;
  final Set<String> _inFlightComplaints = <String>{};
  final Set<String> _inFlightAssignments = <String>{};
  final Set<String> _inFlightApplications = <String>{};

  // Getters
  AdminProfile? get currentAdmin => _currentAdmin;
  AdminStats? get adminStats => _adminStats;
  AdminOperationsDashboard? get operationsDashboard => _operationsDashboard;
  AdminOperationsFilter get operationsFilter => _operationsFilter;
  List<ComplaintRecord> get pendingComplaints => _pendingComplaints;
  List<VendorApplication> get pendingApplications => _pendingApplications;
  List<AppNotification> get adminNotifications => _adminNotifications;
  List<UserProfile> get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentAdmin != null;

  bool isComplaintInFlight(String complaintId) => _inFlightComplaints.contains(complaintId);
  bool isAssignmentInFlight(String assignmentId) => _inFlightAssignments.contains(assignmentId);
  bool isApplicationInFlight(String applicationId) => _inFlightApplications.contains(applicationId);

  bool get canReviewComplaints =>
      _currentAdmin?.role.canReviewComplaints ?? false;
  bool get canReviewVendors => _currentAdmin?.role.canReviewVendors ?? false;
  bool get canViewReports => _currentAdmin?.role.canViewReports ?? false;
  bool get canManageNotifications =>
      _currentAdmin?.role.canManageNotifications ?? false;
  bool get canManageUsers => _currentAdmin?.role.canManageUsers ?? false;

  // Authentication
  Future<bool> loginAdmin(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      _currentAdmin = await authGateway.loginAdmin(email, password);
      _subscribeToAdminLiveSync();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logoutAdmin() async {
    try {
      _isLoading = true;
      _realtimeDebounceTimer?.cancel();
      _realtimeDebounceTimer = null;
      dataGateway.unsubscribeFromAdminLiveUpdates();
      await authGateway.logoutAdmin();
      _currentAdmin = null;
      _adminStats = null;
      _pendingComplaints = [];
      _pendingApplications = [];
      _adminNotifications = [];
      _users = [];
      _inFlightComplaints.clear();
      _inFlightAssignments.clear();
      _inFlightApplications.clear();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> checkAuthStatus() async {
    try {
      _currentAdmin = await authGateway.getCurrentAdmin();
      if (_currentAdmin != null) {
        _subscribeToAdminLiveSync();
      }
      notifyListeners();
    } catch (e) {
      _currentAdmin = null;
      notifyListeners();
    }
  }

  void _subscribeToAdminLiveSync() {
    dataGateway.subscribeToAdminLiveUpdates(() {
      _realtimeDebounceTimer?.cancel();
      _realtimeDebounceTimer = Timer(const Duration(milliseconds: 500), () async {
        try {
          final results = await Future.wait([
            dataGateway.getAdminStats(),
            dataGateway.getPendingComplaints(),
            dataGateway.getPendingApplications(),
          ]);
          _adminStats = results[0] as AdminStats;
          _pendingComplaints = results[1] as List<ComplaintRecord>;
          _pendingApplications = results[2] as List<VendorApplication>;
          notifyListeners();
        } catch (e) {
          debugPrint('Admin realtime live sync refresh failed: $e');
        }
      });
    });
  }

  @override
  void dispose() {
    _realtimeDebounceTimer?.cancel();
    _realtimeDebounceTimer = null;
    dataGateway.unsubscribeFromAdminLiveUpdates();
    super.dispose();
  }


  // Dashboard & Stats
  Future<void> loadAdminStats() async {
    try {
      _isLoading = true;
      _error = null;
      _adminStats = await dataGateway.getAdminStats();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Complaints
  Future<void> loadPendingComplaints({int limit = 50, int offset = 0}) async {
    try {
      _isLoading = true;
      _error = null;
      _pendingComplaints = await dataGateway.getPendingComplaints(
        limit: limit,
        offset: offset,
      );
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ComplaintRecord?> getComplaintDetails(String complaintId) async {
    try {
      return await dataGateway.getComplaintDetails(complaintId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateComplaintStatus(
    String complaintId,
    ComplaintStatus status,
    String notes,
  ) async {
    if (_inFlightComplaints.contains(complaintId)) return false;
    _inFlightComplaints.add(complaintId);
    try {
      _isLoading = true;
      await dataGateway.updateComplaintStatus(
        complaintId,
        status,
        notes: notes,
      );

      // Refresh complaints
      await loadPendingComplaints();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _inFlightComplaints.remove(complaintId);
      _isLoading = false;
    }
  }

  Future<bool> submitComplaintReview(
    String complaintId,
    AdminReview review,
  ) async {
    try {
      _isLoading = true;
      await dataGateway.submitComplaintReview(review);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Vendor Applications
  Future<void> loadPendingApplications({int limit = 50, int offset = 0}) async {
    try {
      _isLoading = true;
      _error = null;
      _pendingApplications = await dataGateway.getPendingApplications(
        limit: limit,
        offset: offset,
      );
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<VendorApplication?> getApplicationDetails(String applicationId) async {
    try {
      return await dataGateway.getApplicationDetails(applicationId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateApplicationStatus(
    String applicationId,
    VendorStatus status,
    String notes,
  ) async {
    if (_inFlightApplications.contains(applicationId)) return false;
    _inFlightApplications.add(applicationId);
    try {
      _isLoading = true;
      await dataGateway.updateApplicationStatus(
        applicationId,
        status,
        notes: notes,
      );

      // Refresh applications
      await loadPendingApplications();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _inFlightApplications.remove(applicationId);
      _isLoading = false;
    }
  }

  Future<bool> submitApplicationReview(
    String applicationId,
    AdminReview review,
  ) async {
    try {
      _isLoading = true;
      await dataGateway.submitApplicationReview(review);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Notifications
  Future<void> loadAdminNotifications({int limit = 50, int offset = 0}) async {
    try {
      _isLoading = true;
      _error = null;
      _adminNotifications = await dataGateway.getAdminNotifications(
        limit: limit,
        offset: offset,
      );
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendNotificationToUser(
    String userId,
    String title,
    String body,
    NotificationCategory category,
  ) async {
    try {
      _isLoading = true;
      final notification = AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: body,
        category: category,
        createdAt: DateTime.now(),
      );
      await dataGateway.sendNotificationToUser(userId, notification);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendBroadcastNotification(
    String title,
    String body,
    NotificationCategory category,
  ) async {
    try {
      _isLoading = true;
      final notification = AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: body,
        category: category,
        createdAt: DateTime.now(),
      );
      await dataGateway.sendBroadcastNotification(notification);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Users
  Future<void> loadUsers({int limit = 50, int offset = 0}) async {
    try {
      _isLoading = true;
      _error = null;
      _users = await dataGateway.getUsers(limit: limit, offset: offset);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> suspendUser(String userId, String reason) async {
    try {
      _isLoading = true;
      await dataGateway.suspendUser(userId, reason);
      await loadUsers();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> reactivateUser(String userId) async {
    try {
      _isLoading = true;
      await dataGateway.reactivateUser(userId);
      await loadUsers();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Staff & Complaint Assignment Management
  Future<List<StaffProfile>> getStaffMembers({
    StaffDepartment? department,
    bool? isActive = true,
  }) async {
    try {
      return await dataGateway.getStaffMembers(
        department: department,
        isActive: isActive,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  Future<bool> assignComplaint({
    required String complaintId,
    required String staffId,
    AssignmentPriority priority = AssignmentPriority.medium,
    String instructions = '',
  }) async {
    if (_inFlightComplaints.contains(complaintId)) return false;
    _inFlightComplaints.add(complaintId);
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await dataGateway.assignComplaint(
        complaintId: complaintId,
        staffId: staffId,
        priority: priority,
        instructions: instructions,
      );

      // Refresh complaints list and stats in parallel
      final results = await Future.wait([
        dataGateway.getPendingComplaints(),
        dataGateway.getAdminStats(),
      ]);
      _pendingComplaints = results[0] as List<ComplaintRecord>;
      _adminStats = results[1] as AdminStats;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    } finally {
      _inFlightComplaints.remove(complaintId);
    }
  }

  Future<ComplaintAssignment?> getComplaintAssignment(String assignmentId) async {
    try {
      return await dataGateway.getComplaintAssignment(assignmentId);
    } catch (e) {
      return null;
    }
  }

  Future<List<ComplaintAssignment>> getComplaintAssignmentsHistory(String complaintId) async {
    try {
      return await dataGateway.getComplaintAssignmentsHistory(complaintId);
    } catch (e) {
      return [];
    }
  }

  Future<bool> approveComplaintAssignment(String assignmentId, {String reviewNotes = ''}) async {
    if (_inFlightAssignments.contains(assignmentId)) return false;
    _inFlightAssignments.add(assignmentId);
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await dataGateway.approveComplaintAssignment(
        assignmentId,
        reviewNotes: reviewNotes,
      );

      final results = await Future.wait([
        dataGateway.getPendingComplaints(),
        dataGateway.getAdminStats(),
      ]);
      _pendingComplaints = results[0] as List<ComplaintRecord>;
      _adminStats = results[1] as AdminStats;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    } finally {
      _inFlightAssignments.remove(assignmentId);
    }
  }

  Future<bool> requestReworkComplaintAssignment(String assignmentId, {String reworkInstructions = ''}) async {
    if (_inFlightAssignments.contains(assignmentId)) return false;
    _inFlightAssignments.add(assignmentId);
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await dataGateway.requestReworkComplaintAssignment(
        assignmentId,
        reworkInstructions: reworkInstructions,
      );

      final results = await Future.wait([
        dataGateway.getPendingComplaints(),
        dataGateway.getAdminStats(),
      ]);
      _pendingComplaints = results[0] as List<ComplaintRecord>;
      _adminStats = results[1] as AdminStats;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    } finally {
      _inFlightAssignments.remove(assignmentId);
    }
  }


  Future<List<ComplaintEvidence>> getComplaintEvidence(String complaintId) async {
    try {
      return await dataGateway.getComplaintEvidence(complaintId);
    } catch (e) {
      return [];
    }
  }

  Future<String?> getEvidenceSignedUrl(String objectPath) async {
    try {
      return await dataGateway.getEvidenceSignedUrl(objectPath);
    } catch (e) {
      return null;
    }
  }

  Future<void> loadOperationsDashboard({AdminOperationsFilter? filter}) async {
    try {
      _isLoading = true;
      _error = null;
      if (filter != null) {
        _operationsFilter = filter;
      }
      notifyListeners();

      _operationsDashboard = await dataGateway.getOperationsDashboard(
        filter: _operationsFilter,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  void setOperationsFilter(AdminOperationsFilter filter) {
    _operationsFilter = filter;
    loadOperationsDashboard(filter: filter);
  }

  void clearOperationsFilter() {
    _operationsFilter = const AdminOperationsFilter();
    loadOperationsDashboard(filter: _operationsFilter);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}




