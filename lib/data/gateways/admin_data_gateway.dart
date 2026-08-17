import 'package:smart_nagpur/domain/domain.dart';

abstract class AdminDataGateway {
  // Dashboard & Stats
  Future<AdminStats> getAdminStats();
  Future<AdminOperationsDashboard> getOperationsDashboard({AdminOperationsFilter? filter});

  // Complaints
  Future<List<ComplaintRecord>> getPendingComplaints({
    int limit = 50,
    int offset = 0,
  });
  Future<ComplaintRecord?> getComplaintDetails(String complaintId);
  Future<void> updateComplaintStatus(
    String complaintId,
    ComplaintStatus status, {
    String notes,
  });
  Future<void> addComplaintTimeline(
    String complaintId,
    RequestTimelineEntry entry,
  );
  Future<AdminReview?> getComplaintReview(String complaintId);
  Future<void> submitComplaintReview(AdminReview review);

  // Vendor Applications
  Future<List<VendorApplication>> getPendingApplications({
    int limit = 50,
    int offset = 0,
  });
  Future<VendorApplication?> getApplicationDetails(String applicationId);
  Future<void> updateApplicationStatus(
    String applicationId,
    VendorStatus status, {
    String notes,
  });
  Future<void> addApplicationTimeline(
    String applicationId,
    RequestTimelineEntry entry,
  );
  Future<AdminReview?> getApplicationReview(String applicationId);
  Future<void> submitApplicationReview(AdminReview review);

  // Notifications
  Future<List<AppNotification>> getAdminNotifications({
    int limit = 50,
    int offset = 0,
  });
  Future<void> sendNotificationToUser(
    String userId,
    AppNotification notification,
  );
  Future<void> sendBroadcastNotification(AppNotification notification);
  Future<void> markNotificationAsRead(String notificationId);

  // Users
  Future<List<UserProfile>> getUsers({int limit = 50, int offset = 0});
  Future<UserProfile?> getUserDetails(String userId);
  Future<void> suspendUser(String userId, String reason);
  Future<void> reactivateUser(String userId);

  // Reports & Analytics
  Future<Map<String, int>> getComplaintsByService();
  Future<Map<String, int>> getComplaintsByStatus();
  Future<Map<String, int>> getApplicationsByStatus();
  Future<List<Map<String, dynamic>>> getDailyStats(int days);
  Future<Map<String, dynamic>> getMonthlyReport(int month, int year);

  // Staff Management
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
  });
  Future<List<StaffProfile>> getStaffMembers({
    StaffDepartment? department,
    bool? isActive,
    bool? isOnDuty,
  });
  Future<StaffProfile?> getStaffMember(String staffId);

  // Complaint Assignments & Evidence
  Future<ComplaintAssignment> assignComplaint({
    required String complaintId,
    required String staffId,
    AssignmentPriority priority = AssignmentPriority.medium,
    String instructions = '',
  });
  Future<ComplaintAssignment?> getComplaintAssignment(String assignmentId);
  Future<List<ComplaintAssignment>> getComplaintAssignmentsHistory(String complaintId);
  Future<ComplaintAssignment> approveComplaintAssignment(String assignmentId, {String reviewNotes = ''});
  Future<ComplaintAssignment> requestReworkComplaintAssignment(String assignmentId, {String reworkInstructions = ''});
  Future<List<ComplaintEvidence>> getComplaintEvidence(String complaintId);
  Future<String> getEvidenceSignedUrl(String objectPath);

  // Realtime Live Sync

  void subscribeToAdminLiveUpdates(void Function() onUpdate);
  void unsubscribeFromAdminLiveUpdates();
}

