import 'dart:async';
import 'dart:collection';

import 'package:flutter/widgets.dart';

import '../core/services/services.dart';
import '../data/data.dart';
import '../domain/domain.dart';

class AppController extends ChangeNotifier {
  AppController({
    AppRepository? repository,
    LocationService? locationService,
    MediaPickerService? mediaPickerService,
    DocumentPickerService? documentPickerService,
    this.authGateway,
    this.remoteDataGateway,
    this.clearLocalSensitiveFiles,
  }) : repository = repository ?? LocalAppRepository(),
       locationService = locationService ?? const DeviceLocationService(),
       mediaPickerService = mediaPickerService ?? DeviceMediaPickerService(),
       documentPickerService =
           documentPickerService ?? const DeviceDocumentPickerService();

  final AppRepository repository;
  final LocationService locationService;
  final MediaPickerService mediaPickerService;
  final DocumentPickerService documentPickerService;
  final AuthGateway? authGateway;
  final RemoteDataGateway? remoteDataGateway;
  final Future<void> Function()? clearLocalSensitiveFiles;

  StreamSubscription<AuthSessionSnapshot>? _authSubscription;

  bool _isInitialized = false;
  bool _isBusy = false;
  String? _error;
  bool _hasCompletedOnboarding = false;
  bool _isAuthenticated = false;
  bool _isDemoMode = false;
  bool _isOffline = false;
  bool _passwordRecoveryPending = false;
  bool _isPasswordRecovery = false;
  Locale _locale = const Locale('en');
  UserProfile? _profile;
  List<ComplaintRecord> _complaints = [];
  List<VendorApplication> _vendorApplications = [];
  List<AppNotification> _notifications = [];

  bool get isInitialized => _isInitialized;
  bool get isBusy => _isBusy;
  String? get error => _error;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  bool get isAuthenticated => _isAuthenticated;
  bool get isDemoMode => _isDemoMode;
  bool get usesCloudBackend => authGateway != null && remoteDataGateway != null;
  bool get isOffline => _isOffline;
  bool get isPasswordRecovery => _isPasswordRecovery;
  Locale get locale => _locale;
  UserProfile? get profile => _profile;
  UnmodifiableListView<ComplaintRecord> get complaints =>
      UnmodifiableListView(_complaints);
  UnmodifiableListView<VendorApplication> get vendorApplications =>
      UnmodifiableListView(_vendorApplications);
  UnmodifiableListView<AppNotification> get notifications =>
      UnmodifiableListView(_notifications);
  UnmodifiableListView<NewsItem> get news =>
      UnmodifiableListView(DemoData.news);
  UnmodifiableListView<ServiceDefinition> get services =>
      UnmodifiableListView(DemoData.services);

  int get unreadNotificationCount =>
      _notifications.where((notification) => !notification.isRead).length;

  List<ComplaintRecord> get activeComplaints => _complaints
      .where((complaint) => complaint.status.isActive)
      .toList(growable: false);

  List<ComplaintRecord> get resolvedComplaints => _complaints
      .where((complaint) => complaint.status == ComplaintStatus.resolved)
      .toList(growable: false);

  Future<void> initialize() async {
    if (_isInitialized || _isBusy) return;
    _setBusy(true);
    try {
      final saved = await repository.load();
      if (usesCloudBackend) {
        _applyPreferences(saved ?? const AppStateData());
        // Recovery is an auth event, not a durable preference. The Supabase
        // auth stream replays a cold-start passwordRecovery callback.
        _passwordRecoveryPending = false;
        _isPasswordRecovery = false;
        _isAuthenticated = authGateway!.isAuthenticated;
        _listenToAuthChanges();

        if (_isAuthenticated) {
          final userId = authGateway!.currentUserId;
          if (saved?.cachedUserId == userId) {
            _applyProtectedData(saved!);
          } else {
            _clearProtectedData();
          }
          await _refreshRemoteData(allowCachedFallback: true);
        } else {
          _passwordRecoveryPending = false;
          _isPasswordRecovery = false;
          _clearProtectedData();
        }
        await repository.save(_snapshot());
      } else {
        final state =
            saved ??
            AppStateData(
              profile: DemoData.profile,
              complaints: List.of(DemoData.complaints),
              vendorApplications: List.of(DemoData.vendorApplications),
              notifications: List.of(DemoData.notifications),
            );
        _apply(state);
        if (saved == null) await repository.save(state);
      }
      _isInitialized = true;
      if (!_isOffline) _error = null;
    } catch (error) {
      _error = 'We could not load saved app data. Please try again.';
      debugPrint('AppController.initialize failed: $error');
    } finally {
      _setBusy(false);
    }
  }

  Future<void> retryInitialize() async {
    _isInitialized = false;
    await initialize();
  }

  Future<void> refreshCloudData() async {
    if (!usesCloudBackend || _isDemoMode || !_isAuthenticated) return;
    _setBusy(true);
    try {
      await _refreshRemoteData(allowCachedFallback: true);
      await repository.save(_snapshot());
      if (!_isOffline) _error = null;
    } on RemoteDataGatewayException catch (error) {
      _error = error.message;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> completeOnboarding() async {
    await _mutate(() {
      _hasCompletedOnboarding = true;
    });
  }

  Future<bool> login({required String email, required String password}) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (!_isValidEmail(normalizedEmail) || password.length < 8) {
      _error =
          'Enter a valid email address and a password of at least 8 characters.';
      notifyListeners();
      return false;
    }

    if (!usesCloudBackend) {
      await _mutate(() {
        _profile = (_profile ?? DemoData.profile).copyWith(
          email: normalizedEmail,
        );
        _isAuthenticated = true;
      });
      return _error == null;
    }

    _setBusy(true);
    try {
      await authGateway!.signIn(email: normalizedEmail, password: password);
      _isAuthenticated = true;
      _isDemoMode = false;
      _passwordRecoveryPending = false;
      _isPasswordRecovery = false;
      _clearProtectedData();
      await _refreshRemoteData(allowCachedFallback: false);
      await repository.save(_snapshot());
      _error = null;
      return true;
    } on AuthenticationGatewayException catch (error) {
      _error = error.message;
      return false;
    } on RemoteDataGatewayException catch (error) {
      await _discardFailedCloudSession();
      _error = error.message;
      return false;
    } catch (error) {
      debugPrint('AppController.login failed: $error');
      _error = 'Sign in is temporarily unavailable. Please try again.';
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<RegistrationStatus> register({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    final normalizedPhone = phone.replaceAll(RegExp(r'\D'), '');
    final normalizedEmail = email.trim().toLowerCase();
    if (name.trim().length < 2 ||
        normalizedPhone.length < 10 ||
        !_isValidEmail(normalizedEmail) ||
        password.length < 8) {
      _error = 'Check your name, mobile number, email and password.';
      notifyListeners();
      return RegistrationStatus.failed;
    }

    if (!usesCloudBackend) {
      await _mutate(() {
        _profile = UserProfile(
          name: name.trim(),
          phone: normalizedPhone,
          email: normalizedEmail,
        );
        _isAuthenticated = true;
      });
      return _error == null
          ? RegistrationStatus.authenticated
          : RegistrationStatus.failed;
    }

    _setBusy(true);
    try {
      final status = await authGateway!.signUp(
        name: name.trim(),
        phone: normalizedPhone,
        email: normalizedEmail,
        password: password,
      );
      if (status == RegistrationStatus.authenticated) {
        _isAuthenticated = true;
        _isDemoMode = false;
        _passwordRecoveryPending = false;
        _isPasswordRecovery = false;
        final profile = UserProfile(
          name: name.trim(),
          phone: normalizedPhone,
          email: normalizedEmail,
        );
        _profile = await remoteDataGateway!.saveProfile(profile);
        await _refreshRemoteData(allowCachedFallback: false);
        await repository.save(_snapshot());
      }
      _error = null;
      return status;
    } on AuthenticationGatewayException catch (error) {
      _error = error.message;
      return RegistrationStatus.failed;
    } on RemoteDataGatewayException catch (error) {
      await _discardFailedCloudSession();
      _error = error.message;
      return RegistrationStatus.failed;
    } catch (error) {
      debugPrint('AppController.register failed: $error');
      _error = 'The account could not be created. Please try again.';
      return RegistrationStatus.failed;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> continueInDemoMode() async {
    _setBusy(true);
    try {
      _isDemoMode = true;
      _isAuthenticated = true;
      _profile = DemoData.profile;
      _complaints = List.of(DemoData.complaints);
      _vendorApplications = List.of(DemoData.vendorApplications);
      _notifications = List.of(DemoData.notifications);
      _isOffline = false;
      _error = null;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (!_isValidEmail(normalizedEmail)) {
      _error = 'Enter a valid email address.';
      notifyListeners();
      return false;
    }
    if (!usesCloudBackend) {
      _error = 'Password reset is available only for online accounts.';
      notifyListeners();
      return false;
    }
    _setBusy(true);
    try {
      await authGateway!.sendPasswordReset(normalizedEmail);
      _error = null;
      return true;
    } on AuthenticationGatewayException catch (error) {
      _error = error.message;
      return false;
    } catch (error) {
      debugPrint('AppController.sendPasswordReset failed: $error');
      _error = 'The reset email could not be sent. Please try again.';
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> updateRecoveredPassword(String newPassword) async {
    if (!usesCloudBackend || !_isPasswordRecovery) {
      _error = 'Open the password recovery link from your email first.';
      notifyListeners();
      return false;
    }
    if (newPassword.length < 8 ||
        !RegExp(r'[A-Za-z]').hasMatch(newPassword) ||
        !RegExp(r'\d').hasMatch(newPassword)) {
      _error = 'Use at least 8 characters with a letter and number.';
      notifyListeners();
      return false;
    }
    _setBusy(true);
    try {
      await authGateway!.updatePassword(newPassword);
      _passwordRecoveryPending = false;
      _isPasswordRecovery = false;
      await repository.save(_snapshot());
      _error = null;
      return true;
    } on AuthenticationGatewayException catch (error) {
      _error = error.message;
      return false;
    } catch (error) {
      debugPrint('AppController.updateRecoveredPassword failed: $error');
      _error = 'Your password could not be updated. Please try again.';
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> logout() async {
    _setBusy(true);
    AuthenticationGatewayException? signOutError;
    StackTrace? signOutStackTrace;
    try {
      if (usesCloudBackend && !_isDemoMode) {
        try {
          await authGateway!.signOut();
        } on AuthenticationGatewayException catch (error, stackTrace) {
          signOutError = error;
          signOutStackTrace = stackTrace;
        }
      }
      _isAuthenticated = false;
      _isDemoMode = false;
      _passwordRecoveryPending = false;
      _isPasswordRecovery = false;
      _clearProtectedData();
      try {
        await clearLocalSensitiveFiles?.call();
      } catch (error) {
        debugPrint('Failed to clear local sensitive files: $error');
      }
      await repository.save(_snapshot());
      if (signOutError != null) {
        _error = signOutError.message;
        Error.throwWithStackTrace(signOutError, signOutStackTrace!);
      }
      _error = null;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> changeLocale(Locale locale) async {
    final languageCode = locale.languageCode == 'mr' ? 'mr' : 'en';
    await _mutate(() {
      _locale = Locale(languageCode);
    });
  }

  Future<void> updateProfile(UserProfile profile) async {
    if (usesCloudBackend && !_isDemoMode) {
      _setBusy(true);
      try {
        _profile = await remoteDataGateway!.saveProfile(profile);
        await repository.save(_snapshot());
        _error = null;
      } on RemoteDataGatewayException catch (error) {
        _error = error.message;
        rethrow;
      } finally {
        _setBusy(false);
      }
      return;
    }
    await _mutate(() {
      _profile = profile;
    });
  }

  Future<ComplaintRecord> submitComplaint(ComplaintDraft draft) async {
    if (draft.issue.trim().isEmpty || draft.description.trim().isEmpty) {
      throw ArgumentError('Issue and description are required.');
    }
    if (draft.contactPhone.replaceAll(RegExp(r'\D'), '').length < 10) {
      throw ArgumentError('A valid contact phone is required.');
    }

    if (usesCloudBackend && !_isDemoMode) {
      _setBusy(true);
      try {
        final complaint = await remoteDataGateway!.submitComplaint(draft);
        _complaints = [complaint, ..._complaints];
        await _refreshRemoteData(allowCachedFallback: true);
        await repository.save(_snapshot());
        _error = null;
        return complaint;
      } on RemoteDataGatewayException catch (error) {
        _error = error.message;
        rethrow;
      } finally {
        _setBusy(false);
      }
    }

    final now = DateTime.now();
    final id = _nextId('NAG', _complaints.map((item) => item.id));
    final complaint = ComplaintRecord(
      id: id,
      serviceType: draft.serviceType,
      issue: draft.issue.trim(),
      description: draft.description.trim(),
      photoPaths: List.of(draft.photoPaths),
      location: draft.location,
      contactPhone: draft.contactPhone,
      citizenAddress: draft.citizenAddress,
      extraFields: Map.of(draft.extraFields),
      createdAt: now,
      updatedAt: now,
      status: ComplaintStatus.submitted,
      timeline: [
        RequestTimelineEntry(
          title: 'Submitted',
          timestamp: now,
          message:
              'Saved locally in demo mode. No municipal department has processed this report yet.',
        ),
      ],
    );

    await _mutate(() {
      _complaints = [complaint, ..._complaints];
      _notifications = [
        AppNotification(
          id: 'notification-$id',
          title: '${draft.issue.trim()} report submitted',
          body: '$id is now available in My Requests (demo mode).',
          category: NotificationCategory.requests,
          createdAt: now,
          destination: NotificationDestination.complaint,
          referenceId: id,
        ),
        ..._notifications,
      ];
    });
    return complaint;
  }

  Future<VendorApplication> submitVendorApplication(
    VendorApplicationDraft draft,
  ) async {
    if (draft.applicantName.trim().isEmpty ||
        draft.businessName.trim().isEmpty ||
        draft.mobile.replaceAll(RegExp(r'\D'), '').length < 10) {
      throw ArgumentError(
        'Applicant name, business name and a valid mobile number are required.',
      );
    }
    if (!draft.acceptedDeclaration) {
      throw ArgumentError(
        'The declaration must be accepted before submission.',
      );
    }

    if (usesCloudBackend && !_isDemoMode) {
      _setBusy(true);
      try {
        final application = await remoteDataGateway!.submitVendorApplication(
          draft,
        );
        _vendorApplications = [application, ..._vendorApplications];
        await _refreshRemoteData(allowCachedFallback: true);
        await repository.save(_snapshot());
        _error = null;
        return application;
      } on RemoteDataGatewayException catch (error) {
        _error = error.message;
        rethrow;
      } finally {
        _setBusy(false);
      }
    }

    final now = DateTime.now();
    final id = _nextId('VN', _vendorApplications.map((item) => item.id));
    final application = VendorApplication(
      id: id,
      details: draft,
      status: VendorStatus.submitted,
      createdAt: now,
      updatedAt: now,
      timeline: [
        VendorTimelineEntry(
          title: 'Application submitted',
          timestamp: now,
          message:
              'Saved locally in demo mode. This is not a municipal approval or permit.',
          isCompleted: true,
          isCurrent: true,
        ),
        const VendorTimelineEntry(title: 'Documents verified'),
        const VendorTimelineEntry(title: 'Under review'),
        const VendorTimelineEntry(title: 'Location assessment'),
        const VendorTimelineEntry(title: 'Decision'),
        const VendorTimelineEntry(title: 'Permission issued'),
      ],
    );

    await _mutate(() {
      _vendorApplications = [application, ..._vendorApplications];
      _notifications = [
        AppNotification(
          id: 'notification-$id',
          title: 'Vendor application submitted',
          body: '$id is available to track locally in demo mode.',
          category: NotificationCategory.requests,
          createdAt: now,
          destination: NotificationDestination.vendorApplication,
          referenceId: id,
        ),
        ..._notifications,
      ];
    });
    return application;
  }

  Future<void> markNotificationRead(String id) async {
    final index = _notifications.indexWhere((item) => item.id == id);
    if (index < 0 || _notifications[index].isRead) return;
    if (usesCloudBackend && !_isDemoMode) {
      await remoteDataGateway!.markNotificationRead(id);
    }
    await _mutate(() {
      final next = List<AppNotification>.of(_notifications);
      next[index] = next[index].copyWith(isRead: true);
      _notifications = next;
    });
  }

  Future<void> markAllNotificationsRead() async {
    if (_notifications.every((item) => item.isRead)) return;
    if (usesCloudBackend && !_isDemoMode) {
      await remoteDataGateway!.markAllNotificationsRead();
    }
    await _mutate(() {
      _notifications = _notifications
          .map((item) => item.copyWith(isRead: true))
          .toList();
    });
  }

  ComplaintRecord? complaintById(String id) {
    for (final complaint in _complaints) {
      if (complaint.id == id) return complaint;
    }
    return null;
  }

  VendorApplication? vendorApplicationById(String id) {
    for (final application in _vendorApplications) {
      if (application.id == id) return application;
    }
    return null;
  }

  NewsItem? newsById(String id) {
    for (final item in DemoData.news) {
      if (item.id == id) return item;
    }
    return null;
  }

  ServiceDefinition serviceFor(ServiceType type) =>
      DemoData.services.firstWhere((service) => service.type == type);

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  Future<void> _mutate(VoidCallback mutation) async {
    if (!_isInitialized) {
      throw StateError('AppController.initialize must complete first.');
    }
    _setBusy(true);
    try {
      mutation();
      await repository.save(_snapshot());
      _error = null;
    } catch (error) {
      _error = 'Your change could not be saved. Please try again.';
      debugPrint('AppController mutation failed: $error');
      rethrow;
    } finally {
      _setBusy(false);
    }
  }

  void _apply(AppStateData state) {
    _hasCompletedOnboarding = state.hasCompletedOnboarding;
    _isAuthenticated = state.isAuthenticated;
    _passwordRecoveryPending = state.passwordRecoveryPending;
    _locale = Locale(state.localeCode == 'mr' ? 'mr' : 'en');
    _profile = state.profile;
    _complaints = List.of(state.complaints);
    _vendorApplications = List.of(state.vendorApplications);
    _notifications = List.of(state.notifications);
  }

  void _applyPreferences(AppStateData state) {
    _hasCompletedOnboarding = state.hasCompletedOnboarding;
    _locale = Locale(state.localeCode == 'mr' ? 'mr' : 'en');
  }

  void _applyProtectedData(AppStateData state) {
    _profile = state.profile;
    _complaints = List.of(state.complaints);
    _vendorApplications = List.of(state.vendorApplications);
    _notifications = List.of(state.notifications);
  }

  void _applyRemoteData(RemoteUserData data) {
    _profile = data.profile;
    _complaints = List.of(data.complaints);
    _vendorApplications = List.of(data.vendorApplications);
    _notifications = List.of(data.notifications);
  }

  void _clearProtectedData() {
    remoteDataGateway?.unsubscribeFromLiveUpdates();
    _profile = null;
    _complaints = [];
    _vendorApplications = [];
    _notifications = [];
  }

  Future<void> _discardFailedCloudSession() async {
    try {
      await authGateway?.signOut();
    } catch (error) {
      debugPrint('Failed to discard an incomplete cloud session: $error');
    }
    _isAuthenticated = false;
    _isDemoMode = false;
    _passwordRecoveryPending = false;
    _isPasswordRecovery = false;
    _clearProtectedData();
    await repository.save(_snapshot());
  }

  Future<void> _refreshRemoteData({required bool allowCachedFallback}) async {
    try {
      final data = await remoteDataGateway!.loadCurrentUserData();
      _applyRemoteData(data);
      _isOffline = false;
      _subscribeToRealtimeSync();
    } on RemoteGatewayUnavailableException catch (error) {
      _isOffline = true;
      _error = error.message;
      if (!allowCachedFallback) rethrow;
    }
  }

  void _subscribeToRealtimeSync() {
    if (!usesCloudBackend || _isDemoMode || !_isAuthenticated) return;
    remoteDataGateway?.subscribeToLiveUpdates(() async {
      try {
        final data = await remoteDataGateway!.loadCurrentUserData();
        _applyRemoteData(data);
        await repository.save(_snapshot());
        notifyListeners();
      } catch (e) {
        debugPrint('Realtime live sync background refresh failed: $e');
      }
    });
  }

  void _listenToAuthChanges() {
    if (_authSubscription != null || authGateway == null) return;
    _authSubscription = authGateway!.sessionChanges.listen(
      (snapshot) {
        if (snapshot.event == AuthSessionEvent.passwordRecovery &&
            snapshot.isAuthenticated) {
          _isAuthenticated = true;
          _isDemoMode = false;
          _passwordRecoveryPending = true;
          _isPasswordRecovery = true;
          unawaited(repository.save(_snapshot()));
          if (_isInitialized && !_isBusy) {
            unawaited(_hydrateExternalSession());
          }
          notifyListeners();
          return;
        }
        if (snapshot.event == AuthSessionEvent.signedOut ||
            !snapshot.isAuthenticated) {
          _isAuthenticated = false;
          _isDemoMode = false;
          _isOffline = false;
          _passwordRecoveryPending = false;
          _isPasswordRecovery = false;
          _clearProtectedData();
          unawaited(repository.save(_snapshot()));
          notifyListeners();
          return;
        }

        final wasAuthenticated = _isAuthenticated;
        _isAuthenticated = true;
        if (snapshot.event == AuthSessionEvent.signedIn) {
          _passwordRecoveryPending = false;
          _isPasswordRecovery = false;
        }
        if (!wasAuthenticated && _isInitialized && !_isBusy) {
          unawaited(_hydrateExternalSession());
        }
        notifyListeners();
      },
      onError: (Object error) {
        debugPrint('Authentication state stream failed: $error');
      },
    );
  }

  Future<void> _hydrateExternalSession() async {
    _setBusy(true);
    try {
      await _refreshRemoteData(allowCachedFallback: true);
      await repository.save(_snapshot());
    } on RemoteDataGatewayException catch (error) {
      _error = error.message;
    } finally {
      _setBusy(false);
    }
  }

  AppStateData _snapshot() => AppStateData(
    hasCompletedOnboarding: _hasCompletedOnboarding,
    isAuthenticated: usesCloudBackend ? false : _isAuthenticated,
    passwordRecoveryPending: _passwordRecoveryPending,
    localeCode: _locale.languageCode,
    cachedUserId: usesCloudBackend && _isAuthenticated && !_isDemoMode
        ? authGateway?.currentUserId
        : null,
    profile: _profile,
    complaints: _complaints,
    vendorApplications: _vendorApplications,
    notifications: _notifications,
  );

  String _nextId(String prefix, Iterable<String> existingIds) {
    final year = DateTime.now().year;
    var number = DateTime.now().microsecondsSinceEpoch % 1000000;
    var candidate = '$prefix-$year-${number.toString().padLeft(6, '0')}';
    final ids = existingIds.toSet();
    while (ids.contains(candidate)) {
      number = (number + 1) % 1000000;
      candidate = '$prefix-$year-${number.toString().padLeft(6, '0')}';
    }
    return candidate;
  }

  void _setBusy(bool value) {
    _isBusy = value;
    notifyListeners();
  }

  bool _isValidEmail(String value) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value);

  @override
  void dispose() {
    unawaited(_authSubscription?.cancel());
    super.dispose();
  }
}
