import 'package:flutter/foundation.dart';

enum EvidenceType {
  beforeWork,
  afterWork,
  inspectionReport;

  String get label => switch (this) {
    EvidenceType.beforeWork => 'Before Work',
    EvidenceType.afterWork => 'After Work',
    EvidenceType.inspectionReport => 'Inspection Report',
  };

  static EvidenceType fromCode(String? code) {
    return switch ((code ?? '').toLowerCase()) {
      'beforework' => EvidenceType.beforeWork,
      'afterwork' => EvidenceType.afterWork,
      'inspectionreport' => EvidenceType.inspectionReport,
      _ => EvidenceType.beforeWork,
    };
  }
}

@immutable
class ComplaintEvidence {
  const ComplaintEvidence({
    required this.id,
    required this.complaintId,
    required this.assignmentId,
    required this.staffId,
    required this.evidenceType,
    required this.bucketId,
    required this.objectPath,
    required this.originalName,
    required this.contentType,
    required this.byteSize,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.capturedAt,
    required this.createdAt,
    this.notes = '',
    this.distanceFromComplaintMeters,
    this.isGeoVerified = false,
    this.signedUrl,
    this.staffName,
    this.staffEmployeeId,
  });

  final String id;
  final String complaintId;
  final String assignmentId;
  final String staffId;
  final EvidenceType evidenceType;
  final String bucketId;
  final String objectPath;
  final String originalName;
  final String contentType;
  final int byteSize;
  final String notes;
  final double latitude;
  final double longitude;
  final double accuracy;
  final double? distanceFromComplaintMeters;
  final bool isGeoVerified;
  final DateTime capturedAt;
  final DateTime createdAt;
  final String? signedUrl;
  final String? staffName;
  final String? staffEmployeeId;

  bool get isPdf => contentType == 'application/pdf';
  bool get isImage => contentType.startsWith('image/');

  String get formattedFileSize {
    if (byteSize < 1024) return '$byteSize B';
    if (byteSize < 1024 * 1024) return '${(byteSize / 1024).toStringAsFixed(1)} KB';
    return '${(byteSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  factory ComplaintEvidence.fromJson(Map<String, dynamic> json) {
    final staffData = json['staff_profiles'] is Map ? json['staff_profiles'] as Map<String, dynamic> : null;

    return ComplaintEvidence(
      id: json['id'] as String? ?? '',
      complaintId: json['complaint_id'] as String? ?? '',
      assignmentId: json['assignment_id'] as String? ?? '',
      staffId: json['staff_id'] as String? ?? '',
      evidenceType: EvidenceType.fromCode(json['evidence_type'] as String?),
      bucketId: json['bucket_id'] as String? ?? 'complaint-evidence',
      objectPath: json['object_path'] as String? ?? '',
      originalName: json['original_name'] as String? ?? '',
      contentType: json['content_type'] as String? ?? 'image/jpeg',
      byteSize: (json['byte_size'] as num?)?.toInt() ?? 0,
      notes: json['notes'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
      distanceFromComplaintMeters: (json['distance_from_complaint_meters'] as num?)?.toDouble(),
      isGeoVerified: json['is_geo_verified'] as bool? ?? false,
      capturedAt: json['captured_at'] != null
          ? DateTime.tryParse(json['captured_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      signedUrl: json['signed_url'] as String?,
      staffName: staffData?['name'] as String?,
      staffEmployeeId: staffData?['employee_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'complaint_id': complaintId,
      'assignment_id': assignmentId,
      'staff_id': staffId,
      'evidence_type': evidenceType.name,
      'bucket_id': bucketId,
      'object_path': objectPath,
      'original_name': originalName,
      'content_type': contentType,
      'byte_size': byteSize,
      'notes': notes,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'distance_from_complaint_meters': distanceFromComplaintMeters,
      'is_geo_verified': isGeoVerified,
      'captured_at': capturedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      if (signedUrl != null) 'signed_url': signedUrl,
    };
  }

  ComplaintEvidence copyWith({
    String? id,
    String? complaintId,
    String? assignmentId,
    String? staffId,
    EvidenceType? evidenceType,
    String? bucketId,
    String? objectPath,
    String? originalName,
    String? contentType,
    int? byteSize,
    String? notes,
    double? latitude,
    double? longitude,
    double? accuracy,
    double? distanceFromComplaintMeters,
    bool? isGeoVerified,
    DateTime? capturedAt,
    DateTime? createdAt,
    String? signedUrl,
    String? staffName,
    String? staffEmployeeId,
  }) {
    return ComplaintEvidence(
      id: id ?? this.id,
      complaintId: complaintId ?? this.complaintId,
      assignmentId: assignmentId ?? this.assignmentId,
      staffId: staffId ?? this.staffId,
      evidenceType: evidenceType ?? this.evidenceType,
      bucketId: bucketId ?? this.bucketId,
      objectPath: objectPath ?? this.objectPath,
      originalName: originalName ?? this.originalName,
      contentType: contentType ?? this.contentType,
      byteSize: byteSize ?? this.byteSize,
      notes: notes ?? this.notes,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      distanceFromComplaintMeters: distanceFromComplaintMeters ?? this.distanceFromComplaintMeters,
      isGeoVerified: isGeoVerified ?? this.isGeoVerified,
      capturedAt: capturedAt ?? this.capturedAt,
      createdAt: createdAt ?? this.createdAt,
      signedUrl: signedUrl ?? this.signedUrl,
      staffName: staffName ?? this.staffName,
      staffEmployeeId: staffEmployeeId ?? this.staffEmployeeId,
    );
  }
}
