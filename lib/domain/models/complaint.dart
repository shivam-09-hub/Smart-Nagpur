import 'problem_location.dart';
import 'service.dart';

enum ComplaintStatus {
  submitted,
  underReview,
  assigned,
  inProgress,
  resolved,
  rejected,
  moreInformationRequired,
}

ComplaintStatus complaintStatusFromJson(Object? value) {
  return ComplaintStatus.values.firstWhere(
    (status) => status.name == value,
    orElse: () => ComplaintStatus.submitted,
  );
}

extension ComplaintStatusDetails on ComplaintStatus {
  String get label => switch (this) {
    ComplaintStatus.submitted => 'Submitted',
    ComplaintStatus.underReview => 'Under review',
    ComplaintStatus.assigned => 'Assigned',
    ComplaintStatus.inProgress => 'In progress',
    ComplaintStatus.resolved => 'Resolved',
    ComplaintStatus.rejected => 'Rejected',
    ComplaintStatus.moreInformationRequired => 'More information required',
  };

  bool get isActive => switch (this) {
    ComplaintStatus.resolved || ComplaintStatus.rejected => false,
    _ => true,
  };
}

class RequestTimelineEntry {
  const RequestTimelineEntry({
    required this.title,
    required this.timestamp,
    this.message,
    this.isCompleted = true,
  });

  final String title;
  final DateTime timestamp;
  final String? message;
  final bool isCompleted;

  Map<String, Object?> toJson() => {
    'title': title,
    'timestamp': timestamp.toIso8601String(),
    'message': message,
    'isCompleted': isCompleted,
  };

  factory RequestTimelineEntry.fromJson(Map<String, Object?> json) {
    return RequestTimelineEntry(
      title: json['title'] as String? ?? '',
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      message: json['message'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? true,
    );
  }
}

class ComplaintDraft {
  const ComplaintDraft({
    required this.serviceType,
    required this.issue,
    required this.description,
    required this.location,
    required this.contactPhone,
    this.photoPaths = const [],
    this.citizenAddress,
    this.extraFields = const {},
  });

  final ServiceType serviceType;
  final String issue;
  final String description;
  final List<String> photoPaths;
  final ProblemLocation location;
  final String contactPhone;
  final String? citizenAddress;
  final Map<String, String> extraFields;

  Map<String, Object?> toJson() => {
    'serviceType': serviceType.name,
    'issue': issue,
    'description': description,
    'photoPaths': photoPaths,
    'location': location.toJson(),
    'contactPhone': contactPhone,
    'citizenAddress': citizenAddress,
    'extraFields': extraFields,
  };

  factory ComplaintDraft.fromJson(Map<String, Object?> json) {
    return ComplaintDraft(
      serviceType: serviceTypeFromJson(json['serviceType']),
      issue: json['issue'] as String? ?? '',
      description: json['description'] as String? ?? '',
      photoPaths: (json['photoPaths'] as List<Object?>? ?? const [])
          .whereType<String>()
          .toList(),
      location: ProblemLocation.fromJson(
        Map<String, Object?>.from(
          json['location'] as Map? ?? const <String, Object?>{},
        ),
      ),
      contactPhone: json['contactPhone'] as String? ?? '',
      citizenAddress: json['citizenAddress'] as String?,
      extraFields: Map<String, String>.from(
        json['extraFields'] as Map? ?? const <String, String>{},
      ),
    );
  }
}

class ComplaintRecord {
  const ComplaintRecord({
    required this.id,
    required this.serviceType,
    required this.issue,
    required this.description,
    required this.location,
    required this.contactPhone,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    this.photoPaths = const [],
    this.citizenAddress,
    this.extraFields = const {},
    this.timeline = const [],
    this.currentAssignmentId,
    this.assignedDepartment,
    this.isDemo = true,
  });

  final String id;
  final ServiceType serviceType;
  final String issue;
  final String description;
  final List<String> photoPaths;
  final ProblemLocation location;
  final String contactPhone;
  final String? citizenAddress;
  final Map<String, String> extraFields;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ComplaintStatus status;
  final List<RequestTimelineEntry> timeline;
  final String? currentAssignmentId;
  final String? assignedDepartment;
  final bool isDemo;

  ComplaintRecord copyWith({
    ComplaintStatus? status,
    DateTime? updatedAt,
    List<RequestTimelineEntry>? timeline,
    String? currentAssignmentId,
    String? assignedDepartment,
  }) {
    return ComplaintRecord(
      id: id,
      serviceType: serviceType,
      issue: issue,
      description: description,
      photoPaths: photoPaths,
      location: location,
      contactPhone: contactPhone,
      citizenAddress: citizenAddress,
      extraFields: extraFields,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      timeline: timeline ?? this.timeline,
      currentAssignmentId: currentAssignmentId ?? this.currentAssignmentId,
      assignedDepartment: assignedDepartment ?? this.assignedDepartment,
      isDemo: isDemo,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'serviceType': serviceType.name,
    'issue': issue,
    'description': description,
    'photoPaths': photoPaths,
    'location': location.toJson(),
    'contactPhone': contactPhone,
    'citizenAddress': citizenAddress,
    'extraFields': extraFields,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'status': status.name,
    'timeline': timeline.map((entry) => entry.toJson()).toList(),
    if (currentAssignmentId != null) 'current_assignment_id': currentAssignmentId,
    if (assignedDepartment != null) 'assigned_department': assignedDepartment,
    'isDemo': isDemo,
  };

  factory ComplaintRecord.fromJson(Map<String, Object?> json) {
    return ComplaintRecord(
      id: json['id'] as String? ?? '',
      serviceType: serviceTypeFromJson(json['serviceType'] ?? json['service_type']),
      issue: json['issue'] as String? ?? '',
      description: json['description'] as String? ?? '',
      photoPaths: (json['photoPaths'] as List<Object?>? ??
              json['photo_paths'] as List<Object?>? ??
              const [])
          .whereType<String>()
          .toList(),
      location: ProblemLocation.fromJson(
        Map<String, Object?>.from(
          json['location'] as Map? ?? const <String, Object?>{},
        ),
      ),
      contactPhone: json['contactPhone'] as String? ?? json['contact_phone'] as String? ?? '',
      citizenAddress: json['citizenAddress'] as String? ?? json['citizen_address'] as String?,
      extraFields: Map<String, String>.from(
        json['extraFields'] as Map? ?? json['extra_fields'] as Map? ?? const <String, String>{},
      ),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? json['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? json['updated_at'] as String? ?? '') ??
          DateTime.now(),
      status: complaintStatusFromJson(json['status']),
      timeline: (json['timeline'] as List<Object?>? ?? const [])
          .whereType<Map>()
          .map(
            (entry) =>
                RequestTimelineEntry.fromJson(Map<String, Object?>.from(entry)),
          )
          .toList(),
      currentAssignmentId: json['current_assignment_id'] as String? ?? json['currentAssignmentId'] as String?,
      assignedDepartment: json['assigned_department'] as String? ?? json['assignedDepartment'] as String?,
      isDemo: json['isDemo'] as bool? ?? json['is_demo'] as bool? ?? true,
    );
  }
}

