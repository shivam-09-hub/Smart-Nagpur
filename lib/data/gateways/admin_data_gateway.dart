import 'package:smart_nagpur/domain/domain.dart';

abstract class AdminDataGateway {
  // Dashboard & Stats
  Future<AdminStats> getAdminStats();

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

  // Realtime Live Sync
  void subscribeToAdminLiveUpdates(void Function() onUpdate);
  void unsubscribeFromAdminLiveUpdates();
}
