enum AdminRole {
  superAdmin,
  complaintReviewer,
  vendorReviewer,
  reportViewer,
  notificationManager,
  userManager,
}

extension AdminRoleDetails on AdminRole {
  String get label => switch (this) {
    AdminRole.superAdmin => 'Super Admin',
    AdminRole.complaintReviewer => 'Complaint Reviewer',
    AdminRole.vendorReviewer => 'Vendor Reviewer',
    AdminRole.reportViewer => 'Report Viewer',
    AdminRole.notificationManager => 'Notification Manager',
    AdminRole.userManager => 'User Manager',
  };

  String get description => switch (this) {
    AdminRole.superAdmin => 'Full system access and control',
    AdminRole.complaintReviewer => 'Review and manage complaints',
    AdminRole.vendorReviewer => 'Review and approve vendor applications',
    AdminRole.reportViewer => 'View analytics and reports',
    AdminRole.notificationManager => 'Manage and send notifications',
    AdminRole.userManager => 'Manage user accounts and profiles',
  };

  bool get canReviewComplaints =>
      this == AdminRole.superAdmin || this == AdminRole.complaintReviewer;
  bool get canReviewVendors =>
      this == AdminRole.superAdmin || this == AdminRole.vendorReviewer;
  bool get canViewReports =>
      this == AdminRole.superAdmin || this == AdminRole.reportViewer;
  bool get canManageNotifications =>
      this == AdminRole.superAdmin || this == AdminRole.notificationManager;
  bool get canManageUsers =>
      this == AdminRole.superAdmin || this == AdminRole.userManager;
}

AdminRole adminRoleFromJson(Object? value) {
  return AdminRole.values.firstWhere(
    (role) => role.name == value,
    orElse: () => AdminRole.complaintReviewer,
  );
}

class AdminProfile {
  const AdminProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
    required this.lastLoginAt,
    this.phone = '',
    this.isActive = true,
    this.permissions = const [],
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final AdminRole role;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isActive;
  final List<String> permissions;

  AdminProfile copyWith({
    String? name,
    String? email,
    String? phone,
    AdminRole? role,
    DateTime? lastLoginAt,
    bool? isActive,
    List<String>? permissions,
  }) {
    return AdminProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
      permissions: permissions ?? this.permissions,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'role': role.name,
    'createdAt': createdAt.toIso8601String(),
    'lastLoginAt': lastLoginAt?.toIso8601String(),
    'isActive': isActive,
    'permissions': permissions,
  };

  factory AdminProfile.fromJson(Map<String, Object?> json) {
    return AdminProfile(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: adminRoleFromJson(json['role']),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      lastLoginAt: DateTime.tryParse(json['lastLoginAt'] as String? ?? ''),
      isActive: json['isActive'] as bool? ?? true,
      permissions: (json['permissions'] as List<Object?>? ?? const [])
          .whereType<String>()
          .toList(),
    );
  }
}
