import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_nagpur/app.dart';
import 'package:smart_nagpur/data/data.dart';
import 'package:smart_nagpur/domain/domain.dart';
import 'package:smart_nagpur/state/app_controller.dart';

void main() {
  testWidgets('fresh launch initializes after the first frame without errors', (
    tester,
  ) async {
    final controller = AppController(
      repository: InMemoryAppRepository(const AppStateData()),
    );

    await tester.pumpWidget(SmartNagpurApp(controller: controller));
    expect(tester.takeException(), isNull);

    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 1201));
    await tester.pumpAndSettle();

    expect(
      find.text('Everything your city needs, in one place.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('authenticated users reach the app shell and can change tabs', (
    tester,
  ) async {
    final controller = AppController(
      repository: InMemoryAppRepository(
        const AppStateData(
          hasCompletedOnboarding: true,
          isAuthenticated: true,
          profile: UserProfile(
            name: 'Test Citizen',
            phone: '9876543210',
            email: 'citizen@example.com',
          ),
        ),
      ),
    );
    await controller.initialize();

    await tester.pumpWidget(SmartNagpurApp(controller: controller));

    expect(find.text('Connecting you to Nagpur'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1201));
    await tester.pumpAndSettle();

    var navigationBar = tester.widget<NavigationBar>(
      find.byType(NavigationBar),
    );
    expect(navigationBar.selectedIndex, 0);
    expect(
      find.textContaining(RegExp(r'^Good (morning|afternoon|evening), Test$')),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(Icons.grid_view_outlined));
    await tester.pumpAndSettle();

    navigationBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navigationBar.selectedIndex, 1);
  });

  testWidgets('cached cloud session reaches home when startup is offline', (
    tester,
  ) async {
    const profile = UserProfile(
      name: 'Offline Citizen',
      phone: '9876543210',
      email: 'offline@example.com',
    );
    final controller = AppController(
      repository: InMemoryAppRepository(
        const AppStateData(
          hasCompletedOnboarding: true,
          cachedUserId: 'user-123',
          profile: profile,
        ),
      ),
      authGateway: const _AuthenticatedAuthGateway(),
      remoteDataGateway: const _UnavailableRemoteGateway(),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(SmartNagpurApp(controller: controller));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1201));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.textContaining('Offline'), findsWidgets);
    expect(find.text('Try Again'), findsNothing);
    expect(controller.isInitialized, isTrue);
    expect(controller.isOffline, isTrue);
  });

  testWidgets('real repository initialization failure remains on splash', (
    tester,
  ) async {
    final controller = AppController(repository: const _FailingRepository());
    addTearDown(controller.dispose);

    await tester.pumpWidget(SmartNagpurApp(controller: controller));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1201));
    await tester.pumpAndSettle();

    expect(find.text('Try Again'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(controller.isInitialized, isFalse);
  });
}

class _FailingRepository implements AppRepository {
  const _FailingRepository();

  @override
  Future<AppStateData?> load() => throw StateError('unreadable local state');

  @override
  Future<void> save(AppStateData state) async {}
}

class _AuthenticatedAuthGateway implements AuthGateway {
  const _AuthenticatedAuthGateway();

  @override
  String? get currentEmail => 'offline@example.com';

  @override
  String? get currentUserId => 'user-123';

  @override
  bool get isAuthenticated => true;

  @override
  Stream<AuthSessionSnapshot> get sessionChanges => const Stream.empty();

  @override
  Future<void> sendPasswordReset(String email) => throw UnimplementedError();

  @override
  Future<void> signIn({required String email, required String password}) =>
      throw UnimplementedError();

  @override
  Future<void> signOut() => throw UnimplementedError();

  @override
  Future<RegistrationStatus> signUp({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<void> updatePassword(String newPassword) => throw UnimplementedError();
}

class _UnavailableRemoteGateway implements RemoteDataGateway {
  const _UnavailableRemoteGateway();

  @override
  Future<RemoteUserData> loadCurrentUserData() =>
      throw const RemoteGatewayUnavailableException();

  @override
  Future<void> markAllNotificationsRead() => throw UnimplementedError();

  @override
  Future<void> markNotificationRead(String id) => throw UnimplementedError();

  @override
  Future<UserProfile> saveProfile(UserProfile profile) =>
      throw UnimplementedError();

  @override
  Future<ComplaintRecord> submitComplaint(ComplaintDraft draft) =>
      throw UnimplementedError();

  @override
  Future<VendorApplication> submitVendorApplication(
    VendorApplicationDraft draft,
  ) => throw UnimplementedError();

  @override
  void subscribeToLiveUpdates(void Function() onUpdate) {}

  @override
  void unsubscribeFromLiveUpdates() {}
}
