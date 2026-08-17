import 'package:smart_nagpur/data/gateways/admin_data_gateway.dart';
import 'package:smart_nagpur/domain/domain.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAdminDataGateway implements AdminDataGateway {
  SupabaseAdminDataGateway({required this.client});

  final SupabaseClient client;

  @override
  Future<AdminStats> getAdminStats() async {
    try {
      final results = await Future.wait([
        _safeRpcMap('get_complaint_stats'),
        _safeRpcMap('get_vendor_stats'),
        _safeRpcMap('get_user_stats'),
        _safeRpcMap('get_notification_stats'),
      ]);

      final complaintStats = results[0];
      final vendorStats = results[1];
      final userStats = results[2];
      final notificationStats = results[3];

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
        return await Future.wait(
          response
              .whereType<Map>()
              .map((item) => _mapComplaintRecord(Map<String, Object?>.from(item))),
        );
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
      return await _mapComplaintRecord(Map<String, Object?>.from(response));
    } catch (e) {
      rethrow;
    }
  }

  Future<ComplaintRecord> _mapComplaintRecord(Map<String, Object?> map) async {
    final photosRaw = map['photos'];
    final photoPaths = <String>[];
    if (photosRaw is List && photosRaw.isNotEmpty) {
      final validItems = photosRaw.whereType<Map>().toList();
      final urls = await Future.wait(
        validItems.map((item) async {
          final bucket = item['bucket'] as String? ?? 'complaint-photos';
          final objectPath = item['objectPath'] as String? ?? '';
          if (objectPath.isEmpty) return '';
          try {
            return await client.storage
                .from(bucket)
                .createSignedUrl(objectPath, 60 * 60 * 24);
          } catch (_) {
            return client.storage.from(bucket).getPublicUrl(objectPath);
          }
        }),
      );
      photoPaths.addAll(urls.where((url) => url.isNotEmpty));
    }
    final json = Map<String, Object?>.from(map);
    json['photoPaths'] = photoPaths;
    return ComplaintRecord.fromJson(json);
  }


  @override
  Future<void> updateComplaintStatus(
    String complaintId,
    ComplaintStatus status, {
    String notes = '',
  }) async {
    try {
      await client.rpc(
        'admin_update_complaint_status',
        params: {
          'p_complaint_id': complaintId,
          'p_status': status.name,
          'p_notes': notes,
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
      await client.from('complaint_timeline').insert({
        'complaint_id': complaintId,
        'title': entry.title,
        'message': entry.message ?? '',
        'is_completed': entry.isCompleted,
        'occurred_at': entry.timestamp.toIso8601String(),
      });
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
      await client.from('admin_reviews').upsert(review.toDbMap());
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
        return await Future.wait(
          response
              .whereType<Map>()
              .map((item) => _mapVendorApplication(Map<String, Object?>.from(item))),
        );
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
      return await _mapVendorApplication(Map<String, Object?>.from(response));
    } catch (e) {
      rethrow;
    }
  }

  Future<VendorApplication> _mapVendorApplication(Map<String, Object?> map) async {
    final json = Map<String, Object?>.from(map);
    final detailsRaw = json['details'];
    if (detailsRaw is Map) {
      final details = Map<String, Object?>.from(detailsRaw);
      final remoteDocs = details['documents'];
      if (remoteDocs is List && remoteDocs.isNotEmpty) {
        final validDocs = remoteDocs.whereType<Map>().toList();
        final localDocs = await Future.wait(
          validDocs.map((item) async {
            final bucket = item['bucket'] as String? ?? 'vendor-documents';
            final objectPath = item['objectPath'] as String? ?? '';
            String url = '';
            if (objectPath.isNotEmpty) {
              try {
                url = await client.storage
                    .from(bucket)
                    .createSignedUrl(objectPath, 60 * 60 * 24);
              } catch (_) {
                url = client.storage.from(bucket).getPublicUrl(objectPath);
              }
            }
            return <String, Object?>{
              'type': item['type'] ?? '',
              'label': item['label'] ?? '',
              'requirement': item['requirement'] ?? 'optional',
              'path': url,
            };
          }),
        );
        details['documents'] = localDocs;
      } else {
        details['documents'] = <Map<String, Object?>>[];
      }
      json['details'] = details;
    }
    return VendorApplication.fromJson(json);
  }


  @override
  Future<void> updateApplicationStatus(
    String applicationId,
    VendorStatus status, {
    String notes = '',
  }) async {
    try {
      await client.rpc(
        'admin_update_vendor_status',
        params: {
          'p_application_id': applicationId,
          'p_status': status.name,
          'p_notes': notes,
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
      await client.from('vendor_timeline').insert({
        'vendor_application_id': applicationId,
        'title': entry.title,
        'message': entry.message ?? '',
        'is_completed': entry.isCompleted,
        'occurred_at': entry.timestamp.toIso8601String(),
      });
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
      await client.from('admin_reviews').upsert(review.toDbMap());
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

  RealtimeChannel? _adminRealtimeChannel;

  @override
  void subscribeToAdminLiveUpdates(void Function() onUpdate) {
    _adminRealtimeChannel?.unsubscribe();

    _adminRealtimeChannel = client
        .channel('admin-live-sync')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'complaints',
          callback: (_) => onUpdate(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'vendor_applications',
          callback: (_) => onUpdate(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'complaint_timeline',
          callback: (_) => onUpdate(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'vendor_timeline',
          callback: (_) => onUpdate(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'admin_reviews',
          callback: (_) => onUpdate(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          callback: (_) => onUpdate(),
        )
        .subscribe();
  }

  // Staff Management
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
  }) async {
    try {
      // 1. Primary: Native PostgreSQL RPC
      final rpcRes = await client.rpc(
        'admin_create_staff_account',
        params: {
          'p_name': name.trim(),
          'p_email': email.trim().toLowerCase(),
          'p_password': password ?? 'StaffPassword123!',
          'p_phone': phone.trim(),
          'p_employee_id': employeeId.trim(),
          'p_department': department.code,
          'p_role': role.code,
          'p_zone': zone.trim(),
          'p_ward': ward.trim(),
        },
      );

      if (rpcRes is Map && rpcRes['staff'] != null) {
        final staffMap = Map<String, dynamic>.from(rpcRes['staff'] as Map);
        return StaffProfile.fromJson(staffMap);
      }
    } catch (rpcError) {
      // 2. Secondary: Edge Function Fallback
      try {
        final response = await client.functions.invoke(
          'admin-create-staff',
          body: {
            'name': name,
            'email': email,
            'employee_id': employeeId,
            'department': department.code,
            'role': role.code,
            'phone': phone,
            'zone': zone,
            'ward': ward,
            if (password != null && password.isNotEmpty) 'password': password,
          },
        );

        if (response.status != 201 && response.status != 200) {
          final errorMsg = response.data is Map && (response.data as Map)['error'] != null
              ? (response.data as Map)['error'].toString()
              : 'Failed to provision staff member (HTTP ${response.status})';
          throw Exception(errorMsg);
        }

        final data = response.data as Map<String, dynamic>;
        final staffMap = data['staff'] as Map<String, dynamic>;
        return StaffProfile.fromJson(staffMap);
      } catch (_) {
        // Rethrow the primary RPC error message if edge function is not deployed
        rethrow;
      }
    }
    throw Exception('Failed to create staff profile');
  }

  @override
  Future<List<StaffProfile>> getStaffMembers({
    StaffDepartment? department,
    bool? isActive,
    bool? isOnDuty,
  }) async {
    try {
      var query = client.from('staff_profiles').select();
      if (department != null) {
        query = query.eq('department', department.code);
      }
      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }
      if (isOnDuty != null) {
        query = query.eq('is_on_duty', isOnDuty);
      }
      final response = await query.order('created_at', ascending: false);
      return (response as List<dynamic>)
          .map((item) => StaffProfile.fromJson(Map<String, Object?>.from(item)))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<StaffProfile?> getStaffMember(String staffId) async {
    try {
      final response = await client
          .from('staff_profiles')
          .select()
          .eq('id', staffId)
          .maybeSingle();
      if (response == null) return null;
      return StaffProfile.fromJson(Map<String, Object?>.from(response));
    } catch (e) {
      rethrow;
    }
  }

  // Complaint Assignments
  @override
  Future<ComplaintAssignment> assignComplaint({
    required String complaintId,
    required String staffId,
    AssignmentPriority priority = AssignmentPriority.medium,
    String instructions = '',
  }) async {
    try {
      final response = await client.rpc(
        'assign_complaint',
        params: {
          'p_complaint_id': complaintId,
          'p_staff_id': staffId,
          'p_priority': priority.name,
          'p_instructions': instructions,
        },
      );

      final result = Map<String, dynamic>.from(response as Map);
      final assignmentId = result['assignmentId'] as String;

      // Fetch the newly created assignment with joined staff details
      final assignment = await getComplaintAssignment(assignmentId);
      if (assignment != null) return assignment;

      return ComplaintAssignment(
        id: assignmentId,
        complaintId: complaintId,
        staffId: staffId,
        assignedBy: client.auth.currentUser?.id ?? '',
        priority: priority,
        instructions: instructions,
        assignedAt: DateTime.now(),
        staffName: result['staffName'] as String?,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<ComplaintAssignment?> getComplaintAssignment(String assignmentId) async {
    try {
      final response = await client
          .from('complaint_assignments')
          .select('*, staff_profiles(name, employee_id, department)')
          .eq('id', assignmentId)
          .maybeSingle();

      if (response == null) return null;
      return ComplaintAssignment.fromJson(Map<String, dynamic>.from(response));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<ComplaintAssignment>> getComplaintAssignmentsHistory(String complaintId) async {
    try {
      final response = await client
          .from('complaint_assignments')
          .select('*, staff_profiles(name, employee_id, department)')
          .eq('complaint_id', complaintId)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((item) => ComplaintAssignment.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<ComplaintAssignment> approveComplaintAssignment(String assignmentId, {String reviewNotes = ''}) async {
    try {
      await client.rpc(
        'approve_complaint_assignment',
        params: {
          'p_assignment_id': assignmentId,
          'p_review_notes': reviewNotes,
        },
      );

      final updated = await getComplaintAssignment(assignmentId);
      if (updated == null) {
        throw Exception('Assignment could not be fetched after approval.');
      }
      return updated;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<ComplaintAssignment> requestReworkComplaintAssignment(String assignmentId, {String reworkInstructions = ''}) async {
    try {
      await client.rpc(
        'request_rework_complaint_assignment',
        params: {
          'p_assignment_id': assignmentId,
          'p_rework_instructions': reworkInstructions,
        },
      );

      final updated = await getComplaintAssignment(assignmentId);
      if (updated == null) {
        throw Exception('Assignment could not be fetched after requesting rework.');
      }
      return updated;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<ComplaintEvidence>> getComplaintEvidence(String complaintId) async {
    try {
      final response = await client
          .from('complaint_evidence')
          .select('*, staff_profiles(name, employee_id)')
          .eq('complaint_id', complaintId)
          .order('captured_at', ascending: true);

      final items = (response as List<dynamic>)
          .map((item) => ComplaintEvidence.fromJson(Map<String, dynamic>.from(item)))
          .toList();

      return await Future.wait(
        items.map((item) async {
          try {
            final url = await getEvidenceSignedUrl(item.objectPath);
            return item.copyWith(signedUrl: url);
          } catch (_) {
            return item;
          }
        }),
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<String> getEvidenceSignedUrl(String objectPath) async {
    try {
      return await client.storage
          .from('complaint-evidence')
          .createSignedUrl(
            objectPath,
            300, // 5 minutes validity (secure short-lived expiration)
          )
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      rethrow;
    }
  }


  @override
  Future<AdminOperationsDashboard> getOperationsDashboard({AdminOperationsFilter? filter}) async {
    try {
      final response = await client.rpc(
        'get_admin_operations_dashboard',
        params: {
          if (filter?.department != null) 'p_department': filter!.department!.code,
          if (filter?.priority != null) 'p_priority': filter!.priority!.name,
          if (filter?.status != null) 'p_status': filter!.status,
          if (filter?.staffId != null) 'p_staff_id': filter!.staffId,
          if (filter?.fromDate != null) 'p_from_date': filter!.fromDate!.toIso8601String(),
          if (filter?.toDate != null) 'p_to_date': filter!.toDate!.toIso8601String(),
        },
      );

      if (response == null) {
        return const AdminOperationsDashboard();
      }

      return AdminOperationsDashboard.fromJson(Map<String, dynamic>.from(response));
    } catch (e) {
      rethrow;
    }
  }

  @override
  void unsubscribeFromAdminLiveUpdates() {
    _adminRealtimeChannel?.unsubscribe();
    _adminRealtimeChannel = null;
  }
}




