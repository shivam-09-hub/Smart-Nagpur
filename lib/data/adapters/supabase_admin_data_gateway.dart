import 'package:smart_nagpur/data/gateways/admin_data_gateway.dart';
import 'package:smart_nagpur/domain/domain.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAdminDataGateway implements AdminDataGateway {
  const SupabaseAdminDataGateway({required this.client});

  final SupabaseClient client;

  @override
  Future<AdminStats> getAdminStats() async {
    try {
      final complaintStats = await _safeRpcMap('get_complaint_stats');
      final vendorStats = await _safeRpcMap('get_vendor_stats');
      final userStats = await _safeRpcMap('get_user_stats');
      final notificationStats = await _safeRpcMap('get_notification_stats');

      final byServiceRaw = complaintStats['byService'];
      final byStatusRaw = complaintStats['byStatus'];

      return AdminStats(
        totalComplaints: (complaintStats['total'] as num?)?.toInt() ?? 0,
        pendingComplaints: (complaintStats['pending'] as num?)?.toInt() ?? 0,
        resolvedComplaints: (complaintStats['resolved'] as num?)?.toInt() ?? 0,
        totalVendorApplications: (vendorStats['total'] as num?)?.toInt() ?? 0,
        pendingApplications: (vendorStats['pending'] as num?)?.toInt() ?? 0,
        approvedApplications: (vendorStats['approved'] as num?)?.toInt() ?? 0,
        rejectedApplications: (vendorStats['rejected'] as num?)?.toInt() ?? 0,
        totalNotifications: (notificationStats['total'] as num?)?.toInt() ?? 0,
        unreadNotifications: (notificationStats['unread'] as num?)?.toInt() ?? 0,
        totalUsers: (userStats['total'] as num?)?.toInt() ?? 0,
        activeUsers: (userStats['active'] as num?)?.toInt() ?? 0,
        lastUpdated: DateTime.now(),
        complaintsByService: byServiceRaw is Map
            ? byServiceRaw.map(
                (k, v) => MapEntry(k.toString(), (v as num).toInt()),
              )
            : {},
        complaintsByStatus: byStatusRaw is Map
            ? byStatusRaw.map(
                (k, v) => MapEntry(k.toString(), (v as num).toInt()),
              )
            : {},
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _safeRpcMap(
    String fn, [
    Map<String, dynamic>? params,
  ]) async {
    try {
      final res = await (params != null
          ? client.rpc(fn, params: params)
          : client.rpc(fn));
      if (res is Map) {
        return Map<String, dynamic>.from(res);
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  @override
  Future<List<ComplaintRecord>> getPendingComplaints({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await client.rpc(
        'get_admin_pending_complaints',
        params: {'p_limit': limit, 'p_offset': offset, 'p_status': null},
      );

      if (response is List) {
        return response
            .whereType<Map>()
            .map(
              (item) =>
                  ComplaintRecord.fromJson(Map<String, Object?>.from(item)),
            )
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<ComplaintRecord?> getComplaintDetails(String complaintId) async {
    try {
      final response = await client.rpc(
        'get_admin_complaint_details',
        params: {'p_id': complaintId},
      );

      if (response == null || response is! Map) return null;
      return ComplaintRecord.fromJson(Map<String, Object?>.from(response));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateComplaintStatus(
    String complaintId,
    ComplaintStatus status,
  ) async {
    try {
      await client.rpc(
        'admin_update_complaint_status',
        params: {
          'p_complaint_id': complaintId,
          'p_status': status.name,
          'p_notes': '',
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> addComplaintTimeline(
    String complaintId,
    RequestTimelineEntry entry,
  ) async {
    try {
      await client.rpc(
        'admin_update_complaint_status',
        params: {
          'p_complaint_id': complaintId,
          'p_status': 'inProgress',
          'p_notes': entry.message ?? entry.title,
        },
      );
    } catch (_) {
      // Fallback
    }
  }

  @override
  Future<AdminReview?> getComplaintReview(String complaintId) async {
    try {
      final response = await client
          .from('admin_reviews')
          .select()
          .eq('item_id', complaintId)
          .eq('item_type', 'complaint')
          .maybeSingle();

      if (response == null) return null;
      return AdminReview.fromJson(Map<String, Object?>.from(response));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> submitComplaintReview(AdminReview review) async {
    try {
      await client.from('admin_reviews').upsert(review.toJson());
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<VendorApplication>> getPendingApplications({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await client.rpc(
        'get_admin_vendor_applications',
        params: {'p_limit': limit, 'p_offset': offset, 'p_status': null},
      );

      if (response is List) {
        return response
            .whereType<Map>()
            .map(
              (item) =>
                  VendorApplication.fromJson(Map<String, Object?>.from(item)),
            )
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<VendorApplication?> getApplicationDetails(String applicationId) async {
    try {
      final response = await client.rpc(
        'get_admin_vendor_application_details',
        params: {'p_id': applicationId},
      );

      if (response == null || response is! Map) return null;
      return VendorApplication.fromJson(Map<String, Object?>.from(response));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateApplicationStatus(
    String applicationId,
    VendorStatus status,
  ) async {
    try {
      await client.rpc(
        'admin_update_vendor_status',
        params: {
          'p_application_id': applicationId,
          'p_status': status.name,
          'p_notes': '',
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> addApplicationTimeline(
    String applicationId,
    RequestTimelineEntry entry,
  ) async {
    try {
      await client.rpc(
        'admin_update_vendor_status',
        params: {
          'p_application_id': applicationId,
          'p_status': 'underReview',
          'p_notes': entry.message ?? entry.title,
        },
      );
    } catch (_) {
      // Fallback
    }
  }

  @override
  Future<AdminReview?> getApplicationReview(String applicationId) async {
    try {
      final response = await client
          .from('admin_reviews')
          .select()
          .eq('item_id', applicationId)
          .eq('item_type', 'application')
          .maybeSingle();

      if (response == null) return null;
      return AdminReview.fromJson(Map<String, Object?>.from(response));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> submitApplicationReview(AdminReview review) async {
    try {
      await client.from('admin_reviews').upsert(review.toJson());
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<AppNotification>> getAdminNotifications({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await client
          .from('admin_notifications')
          .select()
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List<dynamic>)
          .map(
            (item) => AppNotification.fromJson(Map<String, Object?>.from(item)),
          )
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> sendNotificationToUser(
    String userId,
    AppNotification notification,
  ) async {
    try {
      final category = switch (notification.category) {
        NotificationCategory.important => 'important',
        NotificationCategory.requests => 'requests',
        NotificationCategory.cityUpdates => 'cityUpdates',
      };
      final destination = switch (notification.destination) {
        NotificationDestination.complaint => 'complaint',
        NotificationDestination.vendorApplication => 'vendorApplication',
        NotificationDestination.news => 'news',
        NotificationDestination.services => 'services',
        _ => 'none',
      };

      await client.from('notifications').insert({
        'owner_id': userId,
        'title': notification.title,
        'body': notification.body,
        'category': category,
        'destination': destination,
        'reference_id': notification.referenceId,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> sendBroadcastNotification(AppNotification notification) async {
    try {
      await client.rpc(
        'send_broadcast_notification',
        params: {
          'title': notification.title,
          'body': notification.body,
          'category': notification.category.name,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<UserProfile>> getUsers({int limit = 50, int offset = 0}) async {
    try {
      final response = await client
          .from('profiles')
          .select()
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List<dynamic>)
          .map((item) => UserProfile.fromJson(Map<String, Object?>.from(item)))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<UserProfile?> getUserDetails(String userId) async {
    try {
      final response = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;
      return UserProfile.fromJson(Map<String, Object?>.from(response));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> suspendUser(String userId, String reason) async {
    try {
      await client.rpc(
        'suspend_user',
        params: {'user_id': userId, 'reason': reason},
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> reactivateUser(String userId) async {
    try {
      await client.rpc('reactivate_user', params: {'user_id': userId});
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Map<String, int>> getComplaintsByService() async {
    try {
      final result = await _safeRpcMap('get_complaints_by_service');
      return result.map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Map<String, int>> getComplaintsByStatus() async {
    try {
      final result = await _safeRpcMap('get_complaints_by_status');
      return result.map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Map<String, int>> getApplicationsByStatus() async {
    try {
      final result = await _safeRpcMap('get_applications_by_status');
      return result.map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getDailyStats(int days) async {
    try {
      final result =
          await client.rpc('get_daily_stats', params: {'days': days})
              as List<dynamic>? ??
          [];
      return result.cast<Map<String, dynamic>>();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getMonthlyReport(int month, int year) async {
    try {
      final result = await _safeRpcMap(
        'get_monthly_report',
        {'month': month, 'year': year},
      );
      return result;
    } catch (e) {
      rethrow;
    }
  }
}
