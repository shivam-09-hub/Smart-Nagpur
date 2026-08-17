import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_nagpur/data/data.dart';
import 'package:smart_nagpur/domain/domain.dart';
import 'package:smart_nagpur/state/app_controller.dart';

void main() {
  group('AppController cloud authentication', () {
    test(
      'signed-out initialization ignores persisted auth and protected cache',
      () async {
        final cachedComplaint = _complaint('cached-request');
        final repository = InMemoryAppRepository(
          AppStateData(
            hasCompletedOnboarding: true,
            isAuthenticated: true,
            localeCode: 'mr',
            cachedUserId: 'previous-user',
            profile: _profile('Cached Citizen', 'cached@example.com'),
            complaints: [cachedComplaint],
            notifications: [_notification('cached-notification')],
          ),
        );
        final auth = FakeAuthGateway();
        final remote = FakeRemoteDataGateway();
        final controller = AppController(
          repository: repository,
          authGateway: auth,
          remoteDataGateway: remote,
        );
        addTearDown(() async {
          controller.dispose();
          await auth.close();
        });

        await controller.initialize();

        expect(controller.usesCloudBackend, isTrue);
        expect(controller.hasCompletedOnboarding, isTrue);
        expect(controller.locale.languageCode, 'mr');
        expect(controller.isAuthenticated, isFalse);
        expect(controller.profile, isNull);
        expect(controller.complaints, isEmpty);
        expect(controller.notifications, isEmpty);
        expect(remote.loadCalls, 0);
        expect(repository.state?.isAuthenticated, isFalse);
        expect(repository.state?.cachedUserId, isNull);
        expect(repository.state?.profile, isNull);
        expect(repository.state?.complaints, isEmpty);
      },
    );

    test('successful remote login hydrates server data', () async {
      final remoteProfile = _profile('Cloud Citizen', 'citizen@example.com');
      final remoteComplaint = _complaint('remote-request');
      final repository = InMemoryAppRepository(const AppStateData());
      final auth = FakeAuthGateway(signInUserId: 'user-123');
      final remote = FakeRemoteDataGateway(
        loadResult: RemoteUserData(
          profile: remoteProfile,
          complaints: [remoteComplaint],
          notifications: [_notification('remote-notification')],
        ),
      );
      final controller = AppController(
        repository: repository,
        authGateway: auth,
        remoteDataGateway: remote,
      );
      addTearDown(() async {
        controller.dispose();
        await auth.close();
      });
      await controller.initialize();

      final success = await controller.login(
        email: ' Citizen@Example.com ',
        password: 'secure-password',
      );

      expect(success, isTrue);
      expect(auth.signInCalls, 1);
      expect(auth.lastSignInEmail, 'citizen@example.com');
      expect(auth.lastSignInPassword, 'secure-password');
      expect(remote.loadCalls, 1);
      expect(controller.isAuthenticated, isTrue);
      expect(controller.isDemoMode, isFalse);
      expect(controller.profile?.name, remoteProfile.name);
      expect(controller.complaints.single.id, remoteComplaint.id);
      expect(controller.notifications.single.id, 'remote-notification');
      expect(repository.state?.isAuthenticated, isFalse);
      expect(repository.state?.cachedUserId, 'user-123');
      expect(repository.state?.profile?.email, remoteProfile.email);
    });

    test(
      'signed-in cold start keeps matching cached data when gateway is offline',
      () async {
        final cachedProfile = _profile('Cached Citizen', 'citizen@example.com');
        final cachedComplaint = _complaint('cached-request');
        final repository = InMemoryAppRepository(
          AppStateData(
            hasCompletedOnboarding: true,
            cachedUserId: 'user-123',
            profile: cachedProfile,
            complaints: [cachedComplaint],
          ),
        );
        final auth = FakeAuthGateway(
          authenticated: true,
          userId: 'user-123',
          email: 'citizen@example.com',
        );
        final remote = FakeRemoteDataGateway(
          loadError: const RemoteGatewayUnavailableException(),
        );
        final controller = AppController(
          repository: repository,
          authGateway: auth,
          remoteDataGateway: remote,
        );
        addTearDown(() async {
          controller.dispose();
          await auth.close();
        });

        await controller.initialize();

        expect(controller.isInitialized, isTrue);
        expect(controller.isAuthenticated, isTrue);
        expect(controller.isOffline, isTrue);
        expect(controller.profile, cachedProfile);
        expect(controller.complaints.single.id, cachedComplaint.id);
        expect(controller.error, contains('Showing saved data'));
      },
    );

    test(
      'confirmation-required registration does not hydrate protected data',
      () async {
        final repository = InMemoryAppRepository(const AppStateData());
        final auth = FakeAuthGateway(
          registrationStatus: RegistrationStatus.confirmationRequired,
        );
        final remote = FakeRemoteDataGateway();
        final controller = AppController(
          repository: repository,
          authGateway: auth,
          remoteDataGateway: remote,
        );
        addTearDown(() async {
          controller.dispose();
          await auth.close();
        });
        await controller.initialize();

        final status = await controller.register(
          name: '  Riya Patil  ',
          phone: '98765-43210',
          email: ' RIYA@EXAMPLE.COM ',
          password: 'secure-password-1',
        );

        expect(status, RegistrationStatus.confirmationRequired);
        expect(auth.signUpCalls, 1);
        expect(auth.lastSignUpName, 'Riya Patil');
        expect(auth.lastSignUpPhone, '9876543210');
        expect(auth.lastSignUpEmail, 'riya@example.com');
        expect(controller.isAuthenticated, isFalse);
        expect(controller.profile, isNull);
        expect(remote.saveProfileCalls, 0);
        expect(remote.loadCalls, 0);
        expect(repository.state?.cachedUserId, isNull);
      },
    );

    test('sending a reset email does not enter password recovery', () async {
      final repository = InMemoryAppRepository(const AppStateData());
      final auth = FakeAuthGateway();
      final controller = AppController(
        repository: repository,
        authGateway: auth,
        remoteDataGateway: FakeRemoteDataGateway(),
      );
      addTearDown(() async {
        controller.dispose();
        await auth.close();
      });
      await controller.initialize();

      final sent = await controller.sendPasswordReset('citizen@example.com');

      expect(sent, isTrue);
      expect(auth.passwordResetCalls, 1);
      expect(controller.isPasswordRecovery, isFalse);
      expect(repository.state?.passwordRecoveryPending, isFalse);
    });

    test('replayed cold-start recovery event allows password update', () async {
      final profile = _profile('Cloud Citizen', 'citizen@example.com');
      final repository = InMemoryAppRepository(
        AppStateData(cachedUserId: 'user-123', profile: profile),
      );
      final auth = FakeAuthGateway(
        authenticated: true,
        userId: 'user-123',
        email: 'citizen@example.com',
        replayedSessionSnapshot: const AuthSessionSnapshot(
          event: AuthSessionEvent.passwordRecovery,
          isAuthenticated: true,
          userId: 'user-123',
          email: 'citizen@example.com',
        ),
      );
      final remote = FakeRemoteDataGateway(
        loadResult: RemoteUserData(profile: profile),
      );
      final controller = AppController(
        repository: repository,
        authGateway: auth,
        remoteDataGateway: remote,
      );
      addTearDown(() async {
        controller.dispose();
        await auth.close();
      });

      await controller.initialize();
      await Future<void>.delayed(Duration.zero);
      expect(controller.isPasswordRecovery, isTrue);

      final updated = await controller.updateRecoveredPassword(
        'new-secure-password-2',
      );

      expect(updated, isTrue);
      expect(auth.updatePasswordCalls, 1);
      expect(controller.isPasswordRecovery, isFalse);
      expect(repository.state?.passwordRecoveryPending, isFalse);
    });

    test('signed-out auth event clears an active recovery session', () async {
      final profile = _profile('Cloud Citizen', 'citizen@example.com');
      final repository = InMemoryAppRepository(
        AppStateData(cachedUserId: 'user-123', profile: profile),
      );
      final auth = FakeAuthGateway(
        authenticated: true,
        userId: 'user-123',
        email: 'citizen@example.com',
        replayedSessionSnapshot: const AuthSessionSnapshot(
          event: AuthSessionEvent.passwordRecovery,
          isAuthenticated: true,
          userId: 'user-123',
          email: 'citizen@example.com',
        ),
      );
      final controller = AppController(
        repository: repository,
        authGateway: auth,
        remoteDataGateway: FakeRemoteDataGateway(
          loadResult: RemoteUserData(profile: profile),
        ),
      );
      addTearDown(() async {
        controller.dispose();
        await auth.close();
      });
      await controller.initialize();
      await Future<void>.delayed(Duration.zero);
      expect(controller.isPasswordRecovery, isTrue);

      auth.emitSession(
        const AuthSessionSnapshot(
          event: AuthSessionEvent.signedOut,
          isAuthenticated: false,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(controller.isAuthenticated, isFalse);
      expect(controller.isPasswordRecovery, isFalse);
      expect(repository.state?.passwordRecoveryPending, isFalse);
    });

    test(
      'cloud logout signs out and clears protected state and cache',
      () async {
        final remoteProfile = _profile('Cloud Citizen', 'citizen@example.com');
        final remoteComplaint = _complaint('remote-request');
        final repository = InMemoryAppRepository(
          AppStateData(
            hasCompletedOnboarding: true,
            cachedUserId: 'user-123',
            profile: remoteProfile,
            complaints: [remoteComplaint],
            notifications: [_notification('remote-notification')],
          ),
        );
        final auth = FakeAuthGateway(
          authenticated: true,
          userId: 'user-123',
          email: 'citizen@example.com',
        );
        final remote = FakeRemoteDataGateway(
          loadResult: RemoteUserData(
            profile: remoteProfile,
            complaints: [remoteComplaint],
            notifications: [_notification('remote-notification')],
          ),
        );
        final controller = AppController(
          repository: repository,
          authGateway: auth,
          remoteDataGateway: remote,
        );
        addTearDown(() async {
          controller.dispose();
          await auth.close();
        });
        await controller.initialize();
        expect(controller.profile, isNotNull);
        expect(controller.complaints, isNotEmpty);

        await controller.logout();

        expect(auth.signOutCalls, 1);
        expect(controller.isAuthenticated, isFalse);
        expect(controller.isDemoMode, isFalse);
        expect(controller.profile, isNull);
        expect(controller.complaints, isEmpty);
        expect(controller.vendorApplications, isEmpty);
        expect(controller.notifications, isEmpty);
        expect(repository.state?.isAuthenticated, isFalse);
        expect(repository.state?.cachedUserId, isNull);
        expect(repository.state?.profile, isNull);
        expect(repository.state?.complaints, isEmpty);
      },
    );
  });
}

class FakeAuthGateway implements AuthGateway {
  FakeAuthGateway({
    bool authenticated = false,
    String? userId,
    String? email,
    this.signInUserId = 'signed-in-user',
    this.registrationStatus = RegistrationStatus.authenticated,
    AuthSessionSnapshot? replayedSessionSnapshot,
  }) : _isAuthenticated = authenticated,
       _userId = userId,
       _email = email,
       _latestSessionSnapshot = replayedSessionSnapshot;

  final StreamController<AuthSessionSnapshot> _sessionController =
      StreamController<AuthSessionSnapshot>.broadcast(sync: true);
  final String signInUserId;
  RegistrationStatus registrationStatus;

  bool _isAuthenticated;
  String? _userId;
  String? _email;
  AuthSessionSnapshot? _latestSessionSnapshot;
  int signInCalls = 0;
  int signUpCalls = 0;
  int signOutCalls = 0;
  int passwordResetCalls = 0;
  int updatePasswordCalls = 0;
  String? lastSignInEmail;
  String? lastSignInPassword;
  String? lastSignUpName;
  String? lastSignUpPhone;
  String? lastSignUpEmail;

  @override
  bool get isAuthenticated => _isAuthenticated;

  @override
  String? get currentUserId => _userId;

  @override
  String? get currentEmail => _email;

  @override
  Stream<AuthSessionSnapshot> get sessionChanges => Stream.multi((listener) {
    final latest = _latestSessionSnapshot;
    if (latest != null) listener.add(latest);
    final subscription = _sessionController.stream.listen(
      listener.add,
      onError: listener.addError,
      onDone: listener.close,
    );
    listener.onCancel = subscription.cancel;
  });

  void emitSession(AuthSessionSnapshot snapshot) {
    _latestSessionSnapshot = snapshot;
    _isAuthenticated = snapshot.isAuthenticated;
    _userId = snapshot.isAuthenticated ? snapshot.userId : null;
    _email = snapshot.isAuthenticated ? snapshot.email : null;
    _sessionController.add(snapshot);
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    signInCalls++;
    lastSignInEmail = email;
    lastSignInPassword = password;
    _isAuthenticated = true;
    _userId = signInUserId;
    _email = email;
  }

  @override
  Future<RegistrationStatus> signUp({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    signUpCalls++;
    lastSignUpName = name;
    lastSignUpPhone = phone;
    lastSignUpEmail = email;
    if (registrationStatus == RegistrationStatus.authenticated) {
      _isAuthenticated = true;
      _userId = signInUserId;
      _email = email;
    }
    return registrationStatus;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    _isAuthenticated = false;
    _userId = null;
    _email = null;
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    passwordResetCalls++;
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    updatePasswordCalls++;
  }

  Future<void> close() => _sessionController.close();
}

class FakeRemoteDataGateway implements RemoteDataGateway {
  FakeRemoteDataGateway({
    this.loadResult = const RemoteUserData(),
    this.loadError,
  });

  RemoteUserData loadResult;
  Object? loadError;
  int loadCalls = 0;
  int saveProfileCalls = 0;

  @override
  Future<RemoteUserData> loadCurrentUserData() async {
    loadCalls++;
    if (loadError case final error?) throw error;
    return loadResult;
  }

  @override
  Future<UserProfile> saveProfile(UserProfile profile) async {
    saveProfileCalls++;
    return profile;
  }

  @override
  Future<ComplaintRecord> submitComplaint(ComplaintDraft draft) {
    throw UnimplementedError();
  }

  @override
  Future<VendorApplication> submitVendorApplication(
    VendorApplicationDraft draft,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<void> markNotificationRead(String id) async {}

  @override
  Future<void> markAllNotificationsRead() async {}

  @override
  void subscribeToLiveUpdates(void Function() onUpdate) {}

  @override
  void unsubscribeFromLiveUpdates() {}
}

UserProfile _profile(String name, String email) =>
    UserProfile(name: name, phone: '9876543210', email: email);

ComplaintRecord _complaint(String id) {
  final timestamp = DateTime.utc(2026, 8, 17, 9);
  return ComplaintRecord(
    id: id,
    serviceType: ServiceType.roads,
    issue: 'Pothole',
    description: 'A remote request fixture.',
    location: const ProblemLocation(
      latitude: 21.1458,
      longitude: 79.0882,
      accuracy: 12,
      address: 'Nagpur',
    ),
    contactPhone: '9876543210',
    createdAt: timestamp,
    updatedAt: timestamp,
    status: ComplaintStatus.submitted,
  );
}

AppNotification _notification(String id) => AppNotification(
  id: id,
  title: 'Request update',
  body: 'Your request was updated.',
  category: NotificationCategory.requests,
  createdAt: DateTime.utc(2026, 8, 17, 9),
);
