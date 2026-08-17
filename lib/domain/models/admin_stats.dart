class AdminStats {
  const AdminStats({
    required this.totalComplaints,
    required this.pendingComplaints,
    required this.resolvedComplaints,
    required this.totalVendorApplications,
    required this.pendingApplications,
    required this.approvedApplications,
    required this.rejectedApplications,
    required this.totalNotifications,
    required this.unreadNotifications,
    required this.totalUsers,
    required this.activeUsers,
    required this.lastUpdated,
    this.complaintsByService = const {},
    this.complaintsByStatus = const {},
  });

  final int totalComplaints;
  final int pendingComplaints;
  final int resolvedComplaints;
  final int totalVendorApplications;
  final int pendingApplications;
  final int approvedApplications;
  final int rejectedApplications;
  final int totalNotifications;
  final int unreadNotifications;
  final int totalUsers;
  final int activeUsers;
  final DateTime lastUpdated;
  final Map<String, int> complaintsByService;
  final Map<String, int> complaintsByStatus;

  double get complaintResolutionRate {
    if (totalComplaints == 0) return 0;
    return (resolvedComplaints / totalComplaints) * 100;
  }

  double get vendorApprovalRate {
    if (totalVendorApplications == 0) return 0;
    return (approvedApplications / totalVendorApplications) * 100;
  }

  AdminStats copyWith({
    int? totalComplaints,
    int? pendingComplaints,
    int? resolvedComplaints,
    int? totalVendorApplications,
    int? pendingApplications,
    int? approvedApplications,
    int? rejectedApplications,
    int? totalNotifications,
    int? unreadNotifications,
    int? totalUsers,
    int? activeUsers,
    DateTime? lastUpdated,
    Map<String, int>? complaintsByService,
    Map<String, int>? complaintsByStatus,
  }) {
    return AdminStats(
      totalComplaints: totalComplaints ?? this.totalComplaints,
      pendingComplaints: pendingComplaints ?? this.pendingComplaints,
      resolvedComplaints: resolvedComplaints ?? this.resolvedComplaints,
      totalVendorApplications:
          totalVendorApplications ?? this.totalVendorApplications,
      pendingApplications: pendingApplications ?? this.pendingApplications,
      approvedApplications: approvedApplications ?? this.approvedApplications,
      rejectedApplications: rejectedApplications ?? this.rejectedApplications,
      totalNotifications: totalNotifications ?? this.totalNotifications,
      unreadNotifications: unreadNotifications ?? this.unreadNotifications,
      totalUsers: totalUsers ?? this.totalUsers,
      activeUsers: activeUsers ?? this.activeUsers,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      complaintsByService: complaintsByService ?? this.complaintsByService,
      complaintsByStatus: complaintsByStatus ?? this.complaintsByStatus,
    );
  }

  Map<String, Object?> toJson() => {
    'totalComplaints': totalComplaints,
    'pendingComplaints': pendingComplaints,
    'resolvedComplaints': resolvedComplaints,
    'totalVendorApplications': totalVendorApplications,
    'pendingApplications': pendingApplications,
    'approvedApplications': approvedApplications,
    'rejectedApplications': rejectedApplications,
    'totalNotifications': totalNotifications,
    'unreadNotifications': unreadNotifications,
    'totalUsers': totalUsers,
    'activeUsers': activeUsers,
    'lastUpdated': lastUpdated.toIso8601String(),
    'complaintsByService': complaintsByService,
    'complaintsByStatus': complaintsByStatus,
  };

  factory AdminStats.fromJson(Map<String, Object?> json) {
    return AdminStats(
      totalComplaints: json['totalComplaints'] as int? ?? 0,
      pendingComplaints: json['pendingComplaints'] as int? ?? 0,
      resolvedComplaints: json['resolvedComplaints'] as int? ?? 0,
      totalVendorApplications: json['totalVendorApplications'] as int? ?? 0,
      pendingApplications: json['pendingApplications'] as int? ?? 0,
      approvedApplications: json['approvedApplications'] as int? ?? 0,
      rejectedApplications: json['rejectedApplications'] as int? ?? 0,
      totalNotifications: json['totalNotifications'] as int? ?? 0,
      unreadNotifications: json['unreadNotifications'] as int? ?? 0,
      totalUsers: json['totalUsers'] as int? ?? 0,
      activeUsers: json['activeUsers'] as int? ?? 0,
      lastUpdated:
          DateTime.tryParse(json['lastUpdated'] as String? ?? '') ??
          DateTime.now(),
      complaintsByService: Map<String, int>.from(
        json['complaintsByService'] as Map? ?? const <String, int>{},
      ),
      complaintsByStatus: Map<String, int>.from(
        json['complaintsByStatus'] as Map? ?? const <String, int>{},
      ),
    );
  }
}
