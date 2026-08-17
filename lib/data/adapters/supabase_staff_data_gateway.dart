import 'dart:typed_data';

import 'package:smart_nagpur/data/gateways/staff_data_gateway.dart';
import 'package:smart_nagpur/domain/domain.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class SupabaseStaffDataGateway implements StaffDataGateway {
  SupabaseStaffDataGateway({required this.client});

  final SupabaseClient client;

  @override
  Future<StaffProfile?> getStaffProfile() async {
    try {
      final user = client.auth.currentUser;
      if (user == null) return null;

      final response = await client
          .from('staff_profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) return null;
      return StaffProfile.fromJson(Map<String, Object?>.from(response));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateDutyStatus(bool isOnDuty) async {
    try {
      final user = client.auth.currentUser;
      if (user == null) {
        throw Exception('Staff is not authenticated.');
      }

      await client.from('staff_profiles').update({
        'is_on_duty': isOnDuty,
        'last_active_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
    } catch (e) {
      rethrow;
    }
  }

  RealtimeChannel? _staffTasksChannel;

  @override
  Future<List<ComplaintAssignment>> getMyTasks() async {
    try {
      final user = client.auth.currentUser;
      if (user == null) {
        throw Exception('Staff is not authenticated.');
      }

      final response = await client
          .from('complaint_assignments')
          .select('*, complaints!complaint_assignments_complaint_id_fkey(service_type, issue, description, location_address, latitude, longitude)')
          .eq('staff_id', user.id);

      final tasks = (response as List<dynamic>)
          .map((item) => ComplaintAssignment.fromJson(Map<String, dynamic>.from(item)))
          .toList();

      // Sort: 1. urgent, 2. high, 3. medium, 4. low, then newest assigned_at first
      tasks.sort((a, b) {
        final pCompare = _priorityWeight(a.priority).compareTo(_priorityWeight(b.priority));
        if (pCompare != 0) return pCompare;
        return b.assignedAt.compareTo(a.assignedAt);
      });

      return tasks;
    } catch (e) {
      rethrow;
    }
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
    try {
      final response = await client
          .from('complaint_assignments')
          .select('*, complaints!complaint_assignments_complaint_id_fkey(service_type, issue, description, location_address, latitude, longitude)')
          .eq('id', assignmentId)
          .maybeSingle();

      if (response == null) return null;
      return ComplaintAssignment.fromJson(Map<String, dynamic>.from(response));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<ComplaintAssignment> acceptTask(String assignmentId) async {
    try {
      await client.rpc(
        'accept_complaint_assignment',
        params: {'p_assignment_id': assignmentId},
      );

      final updated = await getTaskDetails(assignmentId);
      if (updated == null) {
        throw Exception('Task could not be found after accepting.');
      }
      return updated;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<ComplaintAssignment> startTask(String assignmentId) async {
    try {
      await client.rpc(
        'start_complaint_assignment',
        params: {'p_assignment_id': assignmentId},
      );

      final updated = await getTaskDetails(assignmentId);
      if (updated == null) {
        throw Exception('Task could not be found after starting.');
      }
      return updated;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<ComplaintAssignment> completeTask(String assignmentId, {String notes = ''}) async {
    try {
      await client.rpc(
        'complete_complaint_assignment',
        params: {
          'p_assignment_id': assignmentId,
          'p_completion_notes': notes,
        },
      );

      final updated = await getTaskDetails(assignmentId);
      if (updated == null) {
        throw Exception('Task could not be found after completing.');
      }
      return updated;
    } catch (e) {
      rethrow;
    }
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
  }) async {
    try {
      final staffId = client.auth.currentUser?.id;
      if (staffId == null) {
        throw Exception('Staff is not authenticated.');
      }

      // 1. Client-Side Defensive Validation
      if (fileBytes.isEmpty || fileBytes.length > 10 * 1024 * 1024) {
        throw ArgumentError('Evidence file size must be between 1 byte and 10 MB.');
      }

      final rawExt = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
      final validExt = switch (rawExt) {
        'jpg' || 'jpeg' => 'jpg',
        'png' => 'png',
        'webp' => 'webp',
        'pdf' => 'pdf',
        _ => throw ArgumentError('Unsupported file extension: .$rawExt. Allowed: .jpg, .png, .webp, .pdf'),
      };

      if (type == EvidenceType.inspectionReport) {
        if (validExt != 'pdf' && validExt != 'jpg' && validExt != 'png') {
          throw ArgumentError('Inspection reports must be in PDF or image format.');
        }
      } else {
        if (validExt == 'pdf') {
          throw ArgumentError('Photographic evidence cannot be a PDF document.');
        }
      }

      // 2. Generate secure UUID filename — never trust raw user filenames for storage path
      final secureFileName = '${const Uuid().v4()}.$validExt';
      final objectPath = '$staffId/$complaintId/$assignmentId/$secureFileName';

      // 3. Upload to private Supabase Storage bucket
      await client.storage.from('complaint-evidence').uploadBinary(
        objectPath,
        Uint8List.fromList(fileBytes),
        fileOptions: FileOptions(
          contentType: contentType,
          upsert: false,
        ),
      );

      // 4. Call server-side authoritative verification RPC
      final rpcResult = await client.rpc(
        'record_complaint_evidence',
        params: {
          'p_assignment_id': assignmentId,
          'p_evidence_type': type.name,
          'p_object_path': objectPath,
          'p_original_name': fileName.trim().isEmpty ? secureFileName : fileName.trim(),
          'p_content_type': contentType,
          'p_byte_size': fileBytes.length,
          'p_latitude': latitude,
          'p_longitude': longitude,
          'p_accuracy': accuracy,
          'p_notes': notes,
        },
      );

      final evidenceId = (rpcResult as Map<String, dynamic>)['evidenceId'] as String;

      // 5. Fetch newly created record
      final record = await client
          .from('complaint_evidence')
          .select('*, staff_profiles(name, employee_id)')
          .eq('id', evidenceId)
          .single();

      final signedUrl = await getEvidenceSignedUrl(objectPath);

      final evidence = ComplaintEvidence.fromJson(Map<String, dynamic>.from(record));
      return evidence.copyWith(signedUrl: signedUrl);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<ComplaintEvidence>> getTaskEvidence(String assignmentId) async {
    try {
      final response = await client
          .from('complaint_evidence')
          .select('*, staff_profiles(name, employee_id)')
          .eq('assignment_id', assignmentId)
          .order('captured_at', ascending: true);

      final items = (response as List<dynamic>)
          .map((item) => ComplaintEvidence.fromJson(Map<String, dynamic>.from(item)))
          .toList();

      // Hydrate signed URLs in parallel to eliminate N+1 sequential network roundtrips
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
  void subscribeToStaffTaskUpdates(String staffId, void Function() onUpdate) {
    if (_staffTasksChannel != null) {
      unsubscribeFromStaffTaskUpdates();
    }

    _staffTasksChannel = client
        .channel('staff_tasks_sync_$staffId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'complaint_assignments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'staff_id',
            value: staffId,
          ),
          callback: (payload) {
            onUpdate();
          },
        )
        .subscribe();
  }

  @override
  void unsubscribeFromStaffTaskUpdates() {
    _staffTasksChannel?.unsubscribe();
    _staffTasksChannel = null;
  }
}


