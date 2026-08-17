enum RegistrationStatus { authenticated, confirmationRequired, failed }

enum AuthSessionEvent {
  signedIn,
  signedOut,
  refreshed,
  userUpdated,
  passwordRecovery,
}

class AuthSessionSnapshot {
  const AuthSessionSnapshot({
    required this.event,
    required this.isAuthenticated,
    this.userId,
    this.email,
  });

  final AuthSessionEvent event;
  final bool isAuthenticated;
  final String? userId;
  final String? email;
}

class AuthenticationGatewayException implements Exception {
  const AuthenticationGatewayException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

abstract interface class AuthGateway {
  bool get isAuthenticated;

  String? get currentUserId;

  String? get currentEmail;

  Stream<AuthSessionSnapshot> get sessionChanges;

  Future<void> signIn({required String email, required String password});

  Future<RegistrationStatus> signUp({
    required String name,
    required String phone,
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<void> sendPasswordReset(String email);

  Future<void> updatePassword(String newPassword);
}
