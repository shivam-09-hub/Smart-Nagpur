import '../../domain/domain.dart';

class AppStateData {
  const AppStateData({
    this.schemaVersion = 2,
    this.hasCompletedOnboarding = false,
    this.isAuthenticated = false,
    this.passwordRecoveryPending = false,
    this.localeCode = 'en',
    this.cachedUserId,
    this.profile,
    this.complaints = const [],
    this.vendorApplications = const [],
    this.notifications = const [],
  });

  final int schemaVersion;
  final bool hasCompletedOnboarding;
  final bool isAuthenticated;
  final bool passwordRecoveryPending;
  final String localeCode;
  final String? cachedUserId;
  final UserProfile? profile;
  final List<ComplaintRecord> complaints;
  final List<VendorApplication> vendorApplications;
  final List<AppNotification> notifications;

  AppStateData copyWith({
    bool? hasCompletedOnboarding,
    bool? isAuthenticated,
    bool? passwordRecoveryPending,
    String? localeCode,
    String? cachedUserId,
    UserProfile? profile,
    List<ComplaintRecord>? complaints,
    List<VendorApplication>? vendorApplications,
    List<AppNotification>? notifications,
  }) {
    return AppStateData(
      schemaVersion: schemaVersion,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      passwordRecoveryPending:
          passwordRecoveryPending ?? this.passwordRecoveryPending,
      localeCode: localeCode ?? this.localeCode,
      cachedUserId: cachedUserId ?? this.cachedUserId,
      profile: profile ?? this.profile,
      complaints: complaints ?? this.complaints,
      vendorApplications: vendorApplications ?? this.vendorApplications,
      notifications: notifications ?? this.notifications,
    );
  }

  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'hasCompletedOnboarding': hasCompletedOnboarding,
    'isAuthenticated': isAuthenticated,
    'passwordRecoveryPending': passwordRecoveryPending,
    'localeCode': localeCode,
    'cachedUserId': cachedUserId,
    'profile': profile?.toJson(),
    'complaints': complaints.map((item) => item.toJson()).toList(),
    'vendorApplications': vendorApplications
        .map((item) => item.toJson())
        .toList(),
    'notifications': notifications.map((item) => item.toJson()).toList(),
  };

  factory AppStateData.fromJson(Map<String, Object?> json) {
    final profileJson = json['profile'];
    return AppStateData(
      schemaVersion: json['schemaVersion'] as int? ?? 1,
      hasCompletedOnboarding: json['hasCompletedOnboarding'] as bool? ?? false,
      isAuthenticated: json['isAuthenticated'] as bool? ?? false,
      passwordRecoveryPending:
          json['passwordRecoveryPending'] as bool? ?? false,
      localeCode: json['localeCode'] as String? ?? 'en',
      cachedUserId: json['cachedUserId'] as String?,
      profile: profileJson is Map
          ? UserProfile.fromJson(Map<String, Object?>.from(profileJson))
          : null,
      complaints: (json['complaints'] as List<Object?>? ?? const [])
          .whereType<Map>()
          .map(
            (item) => ComplaintRecord.fromJson(Map<String, Object?>.from(item)),
          )
          .toList(),
      vendorApplications:
          (json['vendorApplications'] as List<Object?>? ?? const [])
              .whereType<Map>()
              .map(
                (item) =>
                    VendorApplication.fromJson(Map<String, Object?>.from(item)),
              )
              .toList(),
      notifications: (json['notifications'] as List<Object?>? ?? const [])
          .whereType<Map>()
          .map(
            (item) => AppNotification.fromJson(Map<String, Object?>.from(item)),
          )
          .toList(),
    );
  }
}

abstract interface class AppRepository {
  Future<AppStateData?> load();

  Future<void> save(AppStateData state);
}
