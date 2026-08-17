import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:smart_nagpur/core/services/location_service.dart';
import 'package:smart_nagpur/data/gateways/staff_auth_gateway.dart';
import 'package:smart_nagpur/data/gateways/staff_data_gateway.dart';
import 'package:smart_nagpur/domain/domain.dart';

class StaffController extends ChangeNotifier {
  StaffController({
    required this.authGateway,
    required this.dataGateway,
    this.locationService = const LocationService(),
  });

  final StaffAuthGateway authGateway;
  final StaffDataGateway dataGateway;
  final LocationService locationService;

  StaffProfile? _currentStaff;
  List<ComplaintAssignment> _myTasks = [];
  bool _isLoading = false;
  bool _isLoadingTasks = false;
  String? _errorMessage;
  LocationCheckOutcome? _lastLocationCheck;

  final Set<String> _inFlightTasks = <String>{};
  bool _isUploadingEvidence = false;
  Timer? _realtimeDebounceTimer;

  StaffProfile? get currentStaff => _currentStaff;
  List<ComplaintAssignment> get myTasks => List.unmodifiable(_myTasks);
  bool get isAuthenticated => _currentStaff != null;
  bool get isLoading => _isLoading;
  bool get isLoadingTasks => _isLoadingTasks;
  String? get errorMessage => _errorMessage;
  bool get isOnDuty => _currentStaff?.isOnDuty ?? false;
  LocationCheckOutcome? get lastLocationCheck => _lastLocationCheck;
  bool get isLocationVerified => _lastLocationCheck?.isVerified ?? false;
  bool isTaskInFlight(String assignmentId) => _inFlightTasks.contains(assignmentId);
  bool get isUploadingEvidence => _isUploadingEvidence;

  // Task Statistics for Dashboard
  int get pendingTasksCount =>
      _myTasks.where((t) => t.status == AssignmentStatus.assigned).length;

  int get acceptedTasksCount =>
      _myTasks.where((t) => t.status == AssignmentStatus.accepted).length;

  int get inProgressTasksCount =>
      _myTasks.where((t) => t.status == AssignmentStatus.inProgress).length;

  int get completedTasksCount =>
      _myTasks.where((t) => t.status == AssignmentStatus.completed).length;

  int get totalTasksCount => _myTasks.length;

  Future<void> checkAuthStatus() async {
    _setLoading(true);
    try {
      _currentStaff = await authGateway.getCurrentStaff();
      _errorMessage = null;
      if (_currentStaff != null) {
        _subscribeToRealtimeTasks(_currentStaff!.id);
        await loadMyTasks();
      }
    } catch (e) {
      _currentStaff = null;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _currentStaff = await authGateway.loginStaff(email, password);
      _errorMessage = null;
      if (_currentStaff != null) {
        _subscribeToRealtimeTasks(_currentStaff!.id);
        await loadMyTasks();
      }
      notifyListeners();
      return true;
    } catch (e) {
      _currentStaff = null;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      _realtimeDebounceTimer?.cancel();
      _realtimeDebounceTimer = null;
      dataGateway.unsubscribeFromStaffTaskUpdates();
      await authGateway.logoutStaff();
    } catch (_) {
      // Ignore logout network errors and clear local state
    } finally {
      _currentStaff = null;
      _myTasks = [];
      _errorMessage = null;
      _inFlightTasks.clear();
      _isUploadingEvidence = false;
      _setLoading(false);
    }
  }

  Future<void> toggleDutyStatus() async {
    if (_currentStaff == null) return;
    final newStatus = !_currentStaff!.isOnDuty;

    // Optimistic UI update
    _currentStaff = _currentStaff!.copyWith(isOnDuty: newStatus);
    notifyListeners();

    try {
      await authGateway.setDutyStatus(newStatus);
    } catch (e) {
      // Revert on failure
      _currentStaff = _currentStaff!.copyWith(isOnDuty: !newStatus);
      _errorMessage = 'Failed to update duty status. Please check your connection.';
      notifyListeners();
    }
  }

  // Task Management
  Future<void> loadMyTasks() async {
    if (_currentStaff == null) return;
    _isLoadingTasks = true;
    notifyListeners();

    try {
      final tasks = await dataGateway.getMyTasks();
      _myTasks = _deduplicateAndSort(tasks);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoadingTasks = false;
      notifyListeners();
    }
  }

  Future<ComplaintAssignment?> getTaskDetails(String assignmentId) async {
    try {
      return await dataGateway.getTaskDetails(assignmentId);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<bool> acceptTask(String assignmentId) async {
    if (_inFlightTasks.contains(assignmentId)) return false;
    _inFlightTasks.add(assignmentId);
    try {
      _setLoading(true);
      _errorMessage = null;
      final updated = await dataGateway.acceptTask(assignmentId);
      _updateTaskInList(updated);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _inFlightTasks.remove(assignmentId);
      _setLoading(false);
    }
  }

  Future<bool> startTask(String assignmentId) async {
    if (_inFlightTasks.contains(assignmentId)) return false;
    _inFlightTasks.add(assignmentId);
    try {
      _setLoading(true);
      _errorMessage = null;
      final updated = await dataGateway.startTask(assignmentId);
      _updateTaskInList(updated);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _inFlightTasks.remove(assignmentId);
      _setLoading(false);
    }
  }

  Future<bool> completeTask(String assignmentId, {String notes = ''}) async {
    if (_inFlightTasks.contains(assignmentId)) return false;
    _inFlightTasks.add(assignmentId);
    try {
      _setLoading(true);
      _errorMessage = null;
      final updated = await dataGateway.completeTask(assignmentId, notes: notes);
      _updateTaskInList(updated);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _inFlightTasks.remove(assignmentId);
      _setLoading(false);
    }
  }

  void _subscribeToRealtimeTasks(String staffId) {
    dataGateway.subscribeToStaffTaskUpdates(staffId, () {
      _realtimeDebounceTimer?.cancel();
      _realtimeDebounceTimer = Timer(const Duration(milliseconds: 500), () async {
        try {
          final tasks = await dataGateway.getMyTasks();
          _myTasks = _deduplicateAndSort(tasks);
          notifyListeners();
        } catch (e) {
          debugPrint('Staff realtime task sync error: $e');
        }
      });
    });
  }


  void _updateTaskInList(ComplaintAssignment updated) {
    final index = _myTasks.indexWhere((t) => t.id == updated.id);
    if (index >= 0) {
      _myTasks[index] = updated;
    } else {
      _myTasks.add(updated);
    }
    _myTasks = _deduplicateAndSort(_myTasks);
  }

  List<ComplaintAssignment> _deduplicateAndSort(List<ComplaintAssignment> list) {
    final seen = <String>{};
    final unique = <ComplaintAssignment>[];
    for (final task in list) {
      if (seen.add(task.id)) {
        unique.add(task);
      }
    }

    unique.sort((a, b) {
      final pCompare = _priorityWeight(a.priority).compareTo(_priorityWeight(b.priority));
      if (pCompare != 0) return pCompare;
      return b.assignedAt.compareTo(a.assignedAt);
    });

    return unique;
  }

  int _priorityWeight(AssignmentPriority priority) {
    return switch (priority) {
      AssignmentPriority.urgent => 0,
      AssignmentPriority.high => 1,
      AssignmentPriority.medium => 2,
      AssignmentPriority.low => 3,
    };
  }

  // GPS & Location Verification
  Future<LocationCheckOutcome> verifyLocation({
    required double complaintLatitude,
    required double complaintLongitude,
  }) async {
    _setLoading(true);
    try {
      final outcome = await locationService.verifyStaffLocation(
        complaintLatitude: complaintLatitude,
        complaintLongitude: complaintLongitude,
      );
      _lastLocationCheck = outcome;
      if (!outcome.isVerified && outcome.errorMessage != null) {
        _errorMessage = outcome.errorMessage;
      } else {
        _errorMessage = null;
      }
      notifyListeners();
      return outcome;
    } catch (e) {
      final errorOutcome = LocationCheckOutcome(
        result: LocationVerificationResult.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      _lastLocationCheck = errorOutcome;
      _errorMessage = errorOutcome.errorMessage;
      notifyListeners();
      return errorOutcome;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> launchNavigation({
    required double latitude,
    required double longitude,
  }) async {
    return await locationService.launchNavigation(
      latitude: latitude,
      longitude: longitude,
    );
  }

  // Field Evidence Operations
  Future<ComplaintEvidence?> uploadEvidence({
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
    if (_isUploadingEvidence) return null;
    _isUploadingEvidence = true;
    _setLoading(true);
    try {
      final evidence = await dataGateway.uploadEvidence(
        complaintId: complaintId,
        assignmentId: assignmentId,
        type: type,
        fileBytes: fileBytes,
        fileName: fileName,
        contentType: contentType,
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
        notes: notes,
      );
      _errorMessage = null;
      notifyListeners();
      return evidence;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    } finally {
      _isUploadingEvidence = false;
      _setLoading(false);
    }
  }

  Future<List<ComplaintEvidence>> getTaskEvidence(String assignmentId) async {
    try {
      return await dataGateway.getTaskEvidence(assignmentId);
    } catch (e) {
      return [];
    }
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  void resetLocationCheck() {
    _lastLocationCheck = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _realtimeDebounceTimer?.cancel();
    _realtimeDebounceTimer = null;
    dataGateway.unsubscribeFromStaffTaskUpdates();
    super.dispose();
  }
}



