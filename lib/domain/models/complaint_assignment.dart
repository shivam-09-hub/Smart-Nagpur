import 'package:flutter/foundation.dart';
import 'staff_profile.dart';

enum AssignmentStatus {
  assigned,
  accepted,
  inProgress,
  completed,
  reworkRequired,
  approved,
  reassigned,
  cancelled;

  String get label => switch (this) {
    AssignmentStatus.assigned => 'Assigned',
    AssignmentStatus.accepted => 'Accepted',
    AssignmentStatus.inProgress => 'In Progress',
    AssignmentStatus.completed => 'Completed (Pending Verification)',
    AssignmentStatus.reworkRequired => 'Rework Required',
    AssignmentStatus.approved => 'Approved & Resolved',
    AssignmentStatus.reassigned => 'Reassigned',
    AssignmentStatus.cancelled => 'Cancelled',
  };

  static AssignmentStatus fromCode(String? code) {
    return AssignmentStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == (code ?? '').toLowerCase(),
      orElse: () => AssignmentStatus.assigned,
    );
  }
}

enum AssignmentPriority {
  low,
  medium,
  high,
  urgent;

  String get label => switch (this) {
    AssignmentPriority.low => 'Low',
    AssignmentPriority.medium => 'Medium',
    AssignmentPriority.high => 'High',
    AssignmentPriority.urgent => 'Urgent',
  };

  static AssignmentPriority fromCode(String? code) {
    return AssignmentPriority.values.firstWhere(
      (e) => e.name.toLowerCase() == (code ?? '').toLowerCase(),
      orElse: () => AssignmentPriority.medium,
    );
  }
}

@immutable
class ComplaintAssignment {
  const ComplaintAssignment({
    required this.id,
    required this.complaintId,
    required this.staffId,
    required this.assignedBy,
    this.status = AssignmentStatus.assigned,
    this.priority = AssignmentPriority.medium,
    this.instructions = '',
    this.notes = '',
    this.rejectionReason,
    this.reassignedToId,
    required this.assignedAt,
    this.acceptedAt,
    this.startedAt,
    this.completedAt,
    this.createdAt,
    this.updatedAt,
    this.staffName,
    this.staffEmployeeId,
    this.staffDepartment,
    this.complaintServiceType,
    this.complaintIssue,
    this.complaintDescription,
    this.complaintLocationAddress,
    this.complaintLatitude,
    this.complaintLongitude,
  });

  final String id;
  final String complaintId;
  final String staffId;
  final String assignedBy;
  final AssignmentStatus status;
  final AssignmentPriority priority;
  final String instructions;
  final String notes;
  final String? rejectionReason;
  final String? reassignedToId;
  final DateTime assignedAt;
  final DateTime? acceptedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Optional hydrated staff details for UI rendering
  final String? staffName;
  final String? staffEmployeeId;
  final StaffDepartment? staffDepartment;

  // Optional hydrated complaint details for UI rendering
  final String? complaintServiceType;
  final String? complaintIssue;
  final String? complaintDescription;
  final String? complaintLocationAddress;
  final double? complaintLatitude;
  final double? complaintLongitude;

  ComplaintAssignment copyWith({
    String? id,
    String? complaintId,
    String? staffId,
    String? assignedBy,
    AssignmentStatus? status,
    AssignmentPriority? priority,
    String? instructions,
    String? notes,
    String? rejectionReason,
    String? reassignedToId,
    DateTime? assignedAt,
    DateTime? acceptedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? staffName,
    String? staffEmployeeId,
    StaffDepartment? staffDepartment,
    String? complaintServiceType,
    String? complaintIssue,
    String? complaintDescription,
    String? complaintLocationAddress,
    double? complaintLatitude,
    double? complaintLongitude,
  }) {
    return ComplaintAssignment(
      id: id ?? this.id,
      complaintId: complaintId ?? this.complaintId,
      staffId: staffId ?? this.staffId,
      assignedBy: assignedBy ?? this.assignedBy,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      instructions: instructions ?? this.instructions,
      notes: notes ?? this.notes,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      reassignedToId: reassignedToId ?? this.reassignedToId,
      assignedAt: assignedAt ?? this.assignedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      staffName: staffName ?? this.staffName,
      staffEmployeeId: staffEmployeeId ?? this.staffEmployeeId,
      staffDepartment: staffDepartment ?? this.staffDepartment,
      complaintServiceType: complaintServiceType ?? this.complaintServiceType,
      complaintIssue: complaintIssue ?? this.complaintIssue,
      complaintDescription: complaintDescription ?? this.complaintDescription,
      complaintLocationAddress: complaintLocationAddress ?? this.complaintLocationAddress,
      complaintLatitude: complaintLatitude ?? this.complaintLatitude,
      complaintLongitude: complaintLongitude ?? this.complaintLongitude,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'complaint_id': complaintId,
      'staff_id': staffId,
      'assigned_by': assignedBy,
      'status': status.name,
      'priority': priority.name,
      'instructions': instructions,
      'notes': notes,
      if (rejectionReason != null) 'rejection_reason': rejectionReason,
      if (reassignedToId != null) 'reassigned_to_id': reassignedToId,
      'assigned_at': assignedAt.toIso8601String(),
      if (acceptedAt != null) 'accepted_at': acceptedAt!.toIso8601String(),
      if (startedAt != null) 'started_at': startedAt!.toIso8601String(),
      if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  factory ComplaintAssignment.fromJson(Map<String, dynamic> json) {
    return ComplaintAssignment(
      id: json['id'] as String? ?? '',
      complaintId: json['complaint_id'] as String? ?? '',
      staffId: json['staff_id'] as String? ?? '',
      assignedBy: json['assigned_by'] as String? ?? '',
      status: AssignmentStatus.fromCode(json['status'] as String?),
      priority: AssignmentPriority.fromCode(json['priority'] as String?),
      instructions: json['instructions'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      rejectionReason: json['rejection_reason'] as String?,
      reassignedToId: json['reassigned_to_id'] as String?,
      assignedAt: (DateTime.tryParse(json['assigned_at'] as String? ?? '') ?? DateTime.now()).toLocal(),
      acceptedAt: json['accepted_at'] != null ? DateTime.tryParse(json['accepted_at'] as String)?.toLocal() : null,
      startedAt: json['started_at'] != null ? DateTime.tryParse(json['started_at'] as String)?.toLocal() : null,
      completedAt: json['completed_at'] != null ? DateTime.tryParse(json['completed_at'] as String)?.toLocal() : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String)?.toLocal() : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String)?.toLocal() : null,
      staffName: json['staff_profiles'] is Map ? (json['staff_profiles'] as Map)['name'] as String? : null,
      staffEmployeeId: json['staff_profiles'] is Map ? (json['staff_profiles'] as Map)['employee_id'] as String? : null,
      staffDepartment: json['staff_profiles'] is Map && (json['staff_profiles'] as Map)['department'] != null
          ? StaffDepartment.fromCode((json['staff_profiles'] as Map)['department'] as String)
          : null,
      complaintServiceType: json['complaints'] is Map ? (json['complaints'] as Map)['service_type'] as String? : null,
      complaintIssue: json['complaints'] is Map ? (json['complaints'] as Map)['issue'] as String? : null,
      complaintDescription: json['complaints'] is Map ? (json['complaints'] as Map)['description'] as String? : null,
      complaintLocationAddress: json['complaints'] is Map ? (json['complaints'] as Map)['location_address'] as String? : null,
      complaintLatitude: json['complaints'] is Map && (json['complaints'] as Map)['latitude'] != null
          ? ((json['complaints'] as Map)['latitude'] as num).toDouble()
          : null,
      complaintLongitude: json['complaints'] is Map && (json['complaints'] as Map)['longitude'] != null
          ? ((json['complaints'] as Map)['longitude'] as num).toDouble()
          : null,
    );
  }
}


