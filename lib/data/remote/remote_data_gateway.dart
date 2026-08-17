import '../../domain/domain.dart';

class RemoteUserData {
  const RemoteUserData({
    this.profile,
    this.complaints = const [],
    this.vendorApplications = const [],
    this.notifications = const [],
  });

  final UserProfile? profile;
  final List<ComplaintRecord> complaints;
  final List<VendorApplication> vendorApplications;
  final List<AppNotification> notifications;
}

class RemoteDataGatewayException implements Exception {
  const RemoteDataGatewayException(this.message, {this.code, this.cause});

  final String message;
  final String? code;
  final Object? cause;

  @override
  String toString() => message;
}

class RemoteGatewayUnavailableException extends RemoteDataGatewayException {
  const RemoteGatewayUnavailableException({Object? cause})
    : super(
        'The online service is unavailable. Showing saved data where possible.',
        code: 'gateway_unavailable',
        cause: cause,
      );
}

abstract interface class RemoteDataGateway {
  Future<RemoteUserData> loadCurrentUserData();

  Future<UserProfile> saveProfile(UserProfile profile);

  Future<ComplaintRecord> submitComplaint(ComplaintDraft draft);

  Future<VendorApplication> submitVendorApplication(
    VendorApplicationDraft draft,
  );

  Future<void> markNotificationRead(String id);

  Future<void> markAllNotificationsRead();
}
