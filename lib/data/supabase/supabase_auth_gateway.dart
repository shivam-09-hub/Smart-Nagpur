import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../remote/auth_gateway.dart';

class SupabaseAuthGateway implements AuthGateway {
  SupabaseAuthGateway(this._client);

  final SupabaseClient _client;

  @override
  bool get isAuthenticated => _client.auth.currentSession != null;

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  String? get currentEmail => _client.auth.currentUser?.email;

  @override
  Stream<AuthSessionSnapshot> get sessionChanges {
    // GoTrue exposes this as a replaying stream. Keeping the transformation
    // directly on that source lets a passwordRecovery event emitted while
    // Supabase.initialize was handling a cold-start link reach the controller.
    return _client.auth.onAuthStateChange
        .where((state) => state.event != AuthChangeEvent.initialSession)
        .map(
          (state) => AuthSessionSnapshot(
            event: _eventFrom(state.event),
            isAuthenticated: state.session != null,
            userId: state.session?.user.id,
            email: state.session?.user.email,
          ),
        );
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      if (response.session == null) {
        throw const AuthenticationGatewayException(
          'Sign in did not create a session. Please try again.',
        );
      }
    } on AuthException catch (error) {
      throw _friendlyException(error);
    } catch (error) {
      throw _handleNetworkError(error);
    }
  }

  @override
  Future<RegistrationStatus> signUp({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim().toLowerCase(),
        password: password,
        emailRedirectTo: SupabaseConfig.authCallbackUrl,
        data: {'name': name.trim(), 'phone': phone.trim()},
      );
      if (response.user == null) {
        throw const AuthenticationGatewayException(
          'The account could not be created. Please try again.',
        );
      }
      return response.session == null
          ? RegistrationStatus.confirmationRequired
          : RegistrationStatus.authenticated;
    } on AuthException catch (error) {
      throw _friendlyException(error);
    } catch (error) {
      throw _handleNetworkError(error);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (error) {
      throw _friendlyException(error);
    } catch (error) {
      throw _handleNetworkError(error);
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email.trim().toLowerCase(),
        redirectTo: SupabaseConfig.authCallbackUrl,
      );
    } on AuthException catch (error) {
      throw _friendlyException(error);
    } catch (error) {
      throw _handleNetworkError(error);
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (error) {
      throw _friendlyException(error);
    } catch (error) {
      throw _handleNetworkError(error);
    }
  }

  AuthSessionEvent _eventFrom(AuthChangeEvent event) => switch (event) {
    AuthChangeEvent.signedIn => AuthSessionEvent.signedIn,
    AuthChangeEvent.signedOut => AuthSessionEvent.signedOut,
    AuthChangeEvent.tokenRefreshed => AuthSessionEvent.refreshed,
    AuthChangeEvent.userUpdated => AuthSessionEvent.userUpdated,
    AuthChangeEvent.passwordRecovery => AuthSessionEvent.passwordRecovery,
    _ =>
      isAuthenticated ? AuthSessionEvent.refreshed : AuthSessionEvent.signedOut,
  };

  AuthenticationGatewayException _handleNetworkError(Object error) {
    if (error is AuthenticationGatewayException) return error;
    final errStr = error.toString().toLowerCase();
    if (errStr.contains('socketexception') ||
        errStr.contains('failed host lookup') ||
        errStr.contains('clientexception') ||
        errStr.contains('network') ||
        errStr.contains('connection refused') ||
        errStr.contains('timeout')) {
      return const AuthenticationGatewayException(
        'No internet connection. Please connect your phone to Wi-Fi or Mobile Data and try again.',
      );
    }
    return AuthenticationGatewayException(error.toString());
  }

  AuthenticationGatewayException _friendlyException(AuthException error) {
    final message = switch (error.code) {
      'invalid_credentials' => 'Incorrect email address or password.',
      'email_not_confirmed' => 'Confirm your email address before signing in.',
      'user_already_exists' ||
      'email_exists' => 'An account already exists for this email address.',
      'weak_password' => 'Choose a stronger password and try again.',
      'over_request_rate_limit' =>
        'Too many attempts. Wait a moment and try again.',
      _ =>
        error.message.isEmpty
            ? 'Authentication is temporarily unavailable. Please try again.'
            : error.message,
    };
    return AuthenticationGatewayException(message, code: error.code);
  }
}
