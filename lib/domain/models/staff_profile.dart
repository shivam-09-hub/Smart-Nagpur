import 'package:flutter/foundation.dart';

enum StaffDepartment {
  road('ROAD', 'Road & Infrastructure'),
  waste('WASTE', 'Solid Waste & Sanitation'),
  water('WATER', 'Water Works & Drainage'),
  vendor('VENDOR', 'Hawkers & Market Vending'),
  general('GENERAL', 'General Municipal Services');

  const StaffDepartment(this.code, this.label);
  final String code;
  final String label;

  static StaffDepartment fromCode(String code) {
    return StaffDepartment.values.firstWhere(
      (d) => d.code.toUpperCase() == code.toUpperCase(),
      orElse: () => StaffDepartment.general,
    );
  }
}

enum StaffRole {
  fieldWorker('FIELD_WORKER', 'Field Technician / Worker'),
  supervisor('SUPERVISOR', 'Field Supervisor'),
  officer('OFFICER', 'Department Officer');

  const StaffRole(this.code, this.label);
  final String code;
  final String label;

  static StaffRole fromCode(String code) {
    return StaffRole.values.firstWhere(
      (r) => r.code.toUpperCase() == code.toUpperCase(),
      orElse: () => StaffRole.fieldWorker,
    );
  }
}

@immutable
class StaffProfile {
  const StaffProfile({
    required this.id,
    required this.name,
    this.phone = '',
    required this.email,
    required this.employeeId,
    required this.department,
    this.role = StaffRole.fieldWorker,
    this.zone = 'ALL',
    this.ward = '',
    this.isActive = true,
    this.isOnDuty = false,
    this.lastActiveAt,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory StaffProfile.fromJson(Map<String, Object?> json) {
    return StaffProfile(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      employeeId: json['employee_id'] as String? ?? '',
      department: StaffDepartment.fromCode(
        json['department'] as String? ?? 'GENERAL',
      ),
      role: StaffRole.fromCode(
        json['role'] as String? ?? 'FIELD_WORKER',
      ),
      zone: json['zone'] as String? ?? 'ALL',
      ward: json['ward'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      isOnDuty: json['is_on_duty'] as bool? ?? false,
      lastActiveAt: json['last_active_at'] != null
          ? DateTime.tryParse(json['last_active_at'] as String)
          : null,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  final String id;
  final String name;
  final String phone;
  final String email;
  final String employeeId;
  final StaffDepartment department;
  final StaffRole role;
  final String zone;
  final String ward;
  final bool isActive;
  final bool isOnDuty;
  final DateTime? lastActiveAt;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'employee_id': employeeId,
        'department': department.code,
        'role': role.code,
        'zone': zone,
        'ward': ward,
        'is_active': isActive,
        'is_on_duty': isOnDuty,
        if (lastActiveAt != null)
          'last_active_at': lastActiveAt!.toIso8601String(),
        if (createdBy != null) 'created_by': createdBy,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      };

  StaffProfile copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? employeeId,
    StaffDepartment? department,
    StaffRole? role,
    String? zone,
    String? ward,
    bool? isActive,
    bool? isOnDuty,
    DateTime? lastActiveAt,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StaffProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      employeeId: employeeId ?? this.employeeId,
      department: department ?? this.department,
      role: role ?? this.role,
      zone: zone ?? this.zone,
      ward: ward ?? this.ward,
      isActive: isActive ?? this.isActive,
      isOnDuty: isOnDuty ?? this.isOnDuty,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
