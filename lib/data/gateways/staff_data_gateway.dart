import 'package:smart_nagpur/domain/domain.dart';

abstract class StaffDataGateway {
  Future<StaffProfile?> getStaffProfile();
  Future<void> updateDutyStatus(bool isOnDuty);

  // Staff Task Management
  Future<List<ComplaintAssignment>> getMyTasks();
  Future<ComplaintAssignment?> getTaskDetails(String assignmentId);
  Future<ComplaintAssignment> acceptTask(String assignmentId);
  Future<ComplaintAssignment> startTask(String assignmentId);
  Future<ComplaintAssignment> completeTask(String assignmentId, {String notes = ''});

  // Field Evidence & GPS
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
  });
  Future<List<ComplaintEvidence>> getTaskEvidence(String assignmentId);
  Future<String> getEvidenceSignedUrl(String objectPath);

  // Realtime Live Sync
  void subscribeToStaffTaskUpdates(String staffId, void Function() onUpdate);
  void unsubscribeFromStaffTaskUpdates();
}


