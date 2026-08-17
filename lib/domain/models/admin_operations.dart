import 'package:smart_nagpur/domain/models/complaint_assignment.dart';
import 'package:smart_nagpur/domain/models/staff_profile.dart';

class VerificationQueueItem {
  const VerificationQueueItem({
    required this.complaintId,
    required this.assignmentId,
    required this.issue,
    required this.serviceType,
    required this.priority,
    required this.complaintAddress,
    required this.complaintCreatedAt,
    required this.staffId,
    required this.staffName,
    required this.staffEmployeeId,
    required this.assignedAt,
    required this.completedAt,
    required this.assignmentAgeHours,
    required this.technicianNotes,
    required this.evidenceCount,
    required this.hasBeforePhoto,
    required this.hasAfterPhoto,
    required this.hasInspectionPdf,
    required this.isGeoVerified,
    this.distanceMeters,
    this.accuracyMeters,
  });

  final String complaintId;
  final String assignmentId;
  final String issue;
  final String serviceType;
  final AssignmentPriority priority;
  final String complaintAddress;
  final DateTime complaintCreatedAt;
  final String staffId;
  final String staffName;
  final String staffEmployeeId;
  final DateTime assignedAt;
  final DateTime completedAt;
  final double assignmentAgeHours;
  final String technicianNotes;
  final int evidenceCount;
  final bool hasBeforePhoto;
  final bool hasAfterPhoto;
  final bool hasInspectionPdf;
  final bool isGeoVerified;
  final double? distanceMeters;
  final double? accuracyMeters;

  bool get hasCompleteEvidence => hasBeforePhoto && hasAfterPhoto;

  String get formattedCompletedAgo {
    final diff = DateTime.now().difference(completedAt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  factory VerificationQueueItem.fromJson(Map<String, dynamic> json) {
    return VerificationQueueItem(
      complaintId: json['complaint_id'] as String? ?? '',
      assignmentId: json['assignment_id'] as String? ?? '',
      issue: json['issue'] as String? ?? 'Civic Complaint',
      serviceType: json['service_type'] as String? ?? 'general',
      priority: AssignmentPriority.fromCode(json['priority'] as String? ?? 'medium'),
      complaintAddress: json['complaint_address'] as String? ?? 'Nagpur Municipal Area',
      complaintCreatedAt: DateTime.tryParse(json['complaint_created_at'] as String? ?? '') ?? DateTime.now(),
      staffId: json['staff_id'] as String? ?? '',
      staffName: json['staff_name'] as String? ?? 'Field Technician',
      staffEmployeeId: json['staff_employee_id'] as String? ?? '',
      assignedAt: DateTime.tryParse(json['assigned_at'] as String? ?? '') ?? DateTime.now(),
      completedAt: DateTime.tryParse(json['completed_at'] as String? ?? '') ?? DateTime.now(),
      assignmentAgeHours: (json['assignment_age_hours'] as num?)?.toDouble() ?? 0.0,
      technicianNotes: json['technician_notes'] as String? ?? '',
      evidenceCount: json['evidence_count'] as int? ?? 0,
      hasBeforePhoto: json['has_before_photo'] as bool? ?? false,
      hasAfterPhoto: json['has_after_photo'] as bool? ?? false,
      hasInspectionPdf: json['has_inspection_pdf'] as bool? ?? false,
      isGeoVerified: json['is_geo_verified'] as bool? ?? false,
      distanceMeters: (json['distance_meters'] as num?)?.toDouble(),
      accuracyMeters: (json['accuracy_meters'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'complaint_id': complaintId,
      'assignment_id': assignmentId,
      'issue': issue,
      'service_type': serviceType,
      'priority': priority.name,
      'complaint_address': complaintAddress,
      'complaint_created_at': complaintCreatedAt.toIso8601String(),
      'staff_id': staffId,
      'staff_name': staffName,
      'staff_employee_id': staffEmployeeId,
      'assigned_at': assignedAt.toIso8601String(),
      'completed_at': completedAt.toIso8601String(),
      'assignment_age_hours': assignmentAgeHours,
      'technician_notes': technicianNotes,
      'evidence_count': evidenceCount,
      'has_before_photo': hasBeforePhoto,
      'has_after_photo': hasAfterPhoto,
      'has_inspection_pdf': hasInspectionPdf,
      'is_geo_verified': isGeoVerified,
      'distance_meters': distanceMeters,
      'accuracy_meters': accuracyMeters,
    };
  }
}

class StaffWorkloadItem {
  const StaffWorkloadItem({
    required this.staffId,
    required this.name,
    required this.employeeId,
    required this.department,
    required this.role,
    required this.isOnDuty,
    required this.isActive,
    required this.activeTaskCount,
    required this.completedTaskCount,
    this.lastActiveAt,
  });

  final String staffId;
  final String name;
  final String employeeId;
  final StaffDepartment department;
  final StaffRole role;
  final bool isOnDuty;
  final bool isActive;
  final int activeTaskCount;
  final int completedTaskCount;
  final DateTime? lastActiveAt;

  factory StaffWorkloadItem.fromJson(Map<String, dynamic> json) {
    return StaffWorkloadItem(
      staffId: json['staff_id'] as String? ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      employeeId: json['employee_id'] as String? ?? '',
      department: StaffDepartment.fromCode(json['department'] as String? ?? 'GENERAL'),
      role: StaffRole.fromCode(json['role'] as String? ?? 'FIELD_WORKER'),
      isOnDuty: json['is_on_duty'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      activeTaskCount: json['active_task_count'] as int? ?? 0,
      completedTaskCount: json['completed_task_count'] as int? ?? 0,
      lastActiveAt: json['last_active_at'] != null ? DateTime.tryParse(json['last_active_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'staff_id': staffId,
      'name': name,
      'employee_id': employeeId,
      'department': department.code,
      'role': role.code,
      'is_on_duty': isOnDuty,
      'is_active': isActive,
      'active_task_count': activeTaskCount,
      'completed_task_count': completedTaskCount,
      'last_active_at': lastActiveAt?.toIso8601String(),
    };
  }
}

class StaffWorkloadSummary {
  const StaffWorkloadSummary({
    this.totalStaff = 0,
    this.activeStaff = 0,
    this.onDutyStaff = 0,
    this.pendingTasks = 0,
    this.inProgressTasks = 0,
    this.completedTasks = 0,
  });

  final int totalStaff;
  final int activeStaff;
  final int onDutyStaff;
  final int pendingTasks;
  final int inProgressTasks;
  final int completedTasks;

  factory StaffWorkloadSummary.fromJson(Map<String, dynamic> json) {
    return StaffWorkloadSummary(
      totalStaff: json['total_staff'] as int? ?? 0,
      activeStaff: json['active_staff'] as int? ?? 0,
      onDutyStaff: json['on_duty_staff'] as int? ?? 0,
      pendingTasks: json['pending_tasks'] as int? ?? 0,
      inProgressTasks: json['in_progress_tasks'] as int? ?? 0,
      completedTasks: json['completed_tasks'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_staff': totalStaff,
      'active_staff': activeStaff,
      'on_duty_staff': onDutyStaff,
      'pending_tasks': pendingTasks,
      'in_progress_tasks': inProgressTasks,
      'completed_tasks': completedTasks,
    };
  }
}

class AdminOperationsFilter {
  const AdminOperationsFilter({
    this.department,
    this.priority,
    this.status,
    this.staffId,
    this.fromDate,
    this.toDate,
  });

  final StaffDepartment? department;
  final AssignmentPriority? priority;
  final String? status;
  final String? staffId;
  final DateTime? fromDate;
  final DateTime? toDate;

  bool get hasActiveFilter =>
      department != null ||
      priority != null ||
      status != null ||
      staffId != null ||
      fromDate != null ||
      toDate != null;

  AdminOperationsFilter copyWith({
    StaffDepartment? department,
    bool clearDepartment = false,
    AssignmentPriority? priority,
    bool clearPriority = false,
    String? status,
    bool clearStatus = false,
    String? staffId,
    bool clearStaffId = false,
    DateTime? fromDate,
    bool clearFromDate = false,
    DateTime? toDate,
    bool clearToDate = false,
  }) {
    return AdminOperationsFilter(
      department: clearDepartment ? null : (department ?? this.department),
      priority: clearPriority ? null : (priority ?? this.priority),
      status: clearStatus ? null : (status ?? this.status),
      staffId: clearStaffId ? null : (staffId ?? this.staffId),
      fromDate: clearFromDate ? null : (fromDate ?? this.fromDate),
      toDate: clearToDate ? null : (toDate ?? this.toDate),
    );
  }
}

class AdminOperationsDashboard {
  const AdminOperationsDashboard({
    this.complaintsByStatus = const {},
    this.assignmentsByStatus = const {},
    this.staffWorkloadSummary = const StaffWorkloadSummary(),
    this.staffWorkloads = const [],
    this.verificationQueue = const [],
    this.lastRefreshedAt,
  });

  final Map<String, int> complaintsByStatus;
  final Map<String, int> assignmentsByStatus;
  final StaffWorkloadSummary staffWorkloadSummary;
  final List<StaffWorkloadItem> staffWorkloads;
  final List<VerificationQueueItem> verificationQueue;
  final DateTime? lastRefreshedAt;

  int get awaitingVerificationCount => verificationQueue.length;

  int get submittedComplaintsCount => complaintsByStatus['submitted'] ?? 0;
  int get underReviewComplaintsCount => complaintsByStatus['underReview'] ?? 0;
  int get inProgressComplaintsCount => complaintsByStatus['inProgress'] ?? 0;
  int get resolvedComplaintsCount => complaintsByStatus['resolved'] ?? 0;
  int get reworkComplaintsCount => complaintsByStatus['reworkRequired'] ?? 0;

  factory AdminOperationsDashboard.fromJson(Map<String, dynamic> json) {
    final compStatusMap = <String, int>{};
    if (json['complaints_by_status'] is Map) {
      (json['complaints_by_status'] as Map).forEach((k, v) {
        compStatusMap[k.toString()] = (v as num?)?.toInt() ?? 0;
      });
    }

    final assignStatusMap = <String, int>{};
    if (json['assignments_by_status'] is Map) {
      (json['assignments_by_status'] as Map).forEach((k, v) {
        assignStatusMap[k.toString()] = (v as num?)?.toInt() ?? 0;
      });
    }

    final staffSummary = json['staff_workload_summary'] is Map<String, dynamic>
        ? StaffWorkloadSummary.fromJson(json['staff_workload_summary'] as Map<String, dynamic>)
        : const StaffWorkloadSummary();

    final staffList = <StaffWorkloadItem>[];
    if (json['staff_workloads'] is List) {
      for (final item in json['staff_workloads'] as List) {
        if (item is Map<String, dynamic>) {
          staffList.add(StaffWorkloadItem.fromJson(item));
        }
      }
    }

    final queueList = <VerificationQueueItem>[];
    if (json['verification_queue'] is List) {
      for (final item in json['verification_queue'] as List) {
        if (item is Map<String, dynamic>) {
          queueList.add(VerificationQueueItem.fromJson(item));
        }
      }
    }

    return AdminOperationsDashboard(
      complaintsByStatus: compStatusMap,
      assignmentsByStatus: assignStatusMap,
      staffWorkloadSummary: staffSummary,
      staffWorkloads: staffList,
      verificationQueue: queueList,
      lastRefreshedAt: DateTime.now(),
    );
  }
}
