import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_nagpur/data/data.dart';
import 'package:smart_nagpur/domain/domain.dart';
import 'package:smart_nagpur/state/app_controller.dart';

void main() {
  group('AppController initialization and authentication', () {
    test('restores onboarding, authentication, locale, and profile', () async {
      const profile = UserProfile(
        name: 'Meera Deshmukh',
        phone: '9123456780',
        email: 'meera@example.com',
      );
      final repository = InMemoryAppRepository(
        const AppStateData(
          hasCompletedOnboarding: true,
          isAuthenticated: true,
          localeCode: 'mr',
          profile: profile,
        ),
      );
      final controller = AppController(repository: repository);

      await controller.initialize();

      expect(controller.isInitialized, isTrue);
      expect(controller.hasCompletedOnboarding, isTrue);
      expect(controller.isAuthenticated, isTrue);
      expect(controller.locale, const Locale('mr'));
      expect(controller.profile?.name, profile.name);
    });

    test('onboarding and valid login are persisted', () async {
      final repository = InMemoryAppRepository(const AppStateData());
      final controller = AppController(repository: repository);
      await controller.initialize();

      await controller.completeOnboarding();
      final loggedIn = await controller.login(
        email: ' citizen@example.com ',
        password: 'nagpur-secure',
      );

      expect(loggedIn, isTrue);
      expect(controller.isAuthenticated, isTrue);
      expect(controller.profile?.email, 'citizen@example.com');
      expect(repository.state?.hasCompletedOnboarding, isTrue);
      expect(repository.state?.isAuthenticated, isTrue);
      expect(repository.state?.profile?.email, 'citizen@example.com');
    });

    test('invalid login reports an error without authenticating', () async {
      final repository = InMemoryAppRepository(const AppStateData());
      final controller = AppController(repository: repository);
      await controller.initialize();

      final loggedIn = await controller.login(
        email: 'not-an-email',
        password: 'short',
      );

      expect(loggedIn, isFalse);
      expect(controller.isAuthenticated, isFalse);
      expect(controller.error, isNotNull);
      expect(repository.state?.isAuthenticated, isFalse);

      controller.clearError();
      expect(controller.error, isNull);
    });

    test('registration trims data and logout is persisted', () async {
      final repository = InMemoryAppRepository(const AppStateData());
      final controller = AppController(repository: repository);
      await controller.initialize();

      final registered = await controller.register(
        name: '  Riya Patil  ',
        phone: '98765-43210',
        email: ' riya@example.com ',
        password: 'safe-password',
      );

      expect(registered, RegistrationStatus.authenticated);
      expect(controller.profile?.name, 'Riya Patil');
      expect(controller.profile?.email, 'riya@example.com');
      expect(controller.profile?.phone, '9876543210');

      await controller.logout();
      expect(controller.isAuthenticated, isFalse);
      expect(repository.state?.isAuthenticated, isFalse);
    });
  });

  group('AppController submissions', () {
    test(
      'complaint is saved, discoverable, and creates a notification',
      () async {
        final repository = InMemoryAppRepository(const AppStateData());
        final controller = AppController(repository: repository);
        await controller.initialize();

        final complaint = await controller.submitComplaint(
          const ComplaintDraft(
            serviceType: ServiceType.roads,
            issue: '  Pothole  ',
            description: '  Deep pothole near the junction.  ',
            photoPaths: ['photo.jpg'],
            location: ProblemLocation(
              latitude: 21.1458,
              longitude: 79.0882,
              accuracy: 14,
              address: 'Civil Lines, Nagpur',
            ),
            contactPhone: '9876543210',
            citizenAddress: 'Dharampeth, Nagpur',
            extraFields: {'severity': 'High'},
          ),
        );

        expect(complaint.id, startsWith('NAG-'));
        expect(complaint.issue, 'Pothole');
        expect(complaint.description, 'Deep pothole near the junction.');
        expect(complaint.status, ComplaintStatus.submitted);
        expect(complaint.timeline.single.title, 'Submitted');
        expect(controller.complaintById(complaint.id), same(complaint));
        expect(controller.activeComplaints, contains(same(complaint)));
        expect(repository.state?.complaints.single.id, complaint.id);

        final notification = controller.notifications.first;
        expect(notification.referenceId, complaint.id);
        expect(notification.destination, NotificationDestination.complaint);
        expect(notification.category, NotificationCategory.requests);
        expect(repository.state?.notifications.single.id, notification.id);
      },
    );

    test('invalid complaint is rejected before persistence', () async {
      final repository = InMemoryAppRepository(const AppStateData());
      final controller = AppController(repository: repository);
      await controller.initialize();

      expect(
        () => controller.submitComplaint(
          const ComplaintDraft(
            serviceType: ServiceType.water,
            issue: '',
            description: 'No water supply',
            location: ProblemLocation(
              latitude: 21.1,
              longitude: 79.1,
              accuracy: 10,
              address: 'Nagpur',
            ),
            contactPhone: '123',
          ),
        ),
        throwsArgumentError,
      );
      expect(repository.state?.complaints, isEmpty);
      expect(repository.state?.notifications, isEmpty);
    });

    test(
      'vendor application and its tracking notification are persisted',
      () async {
        final repository = InMemoryAppRepository(const AppStateData());
        final controller = AppController(repository: repository);
        await controller.initialize();

        final application = await controller.submitVendorApplication(
          const VendorApplicationDraft(
            applicantName: 'Anaya Joshi',
            mobile: '9876543210',
            email: 'anaya@example.com',
            businessName: 'Orange City Crafts',
            businessType: 'Handicrafts',
            category: 'Retail',
            acceptedDeclaration: true,
          ),
        );

        expect(application.id, startsWith('VN-'));
        expect(application.status, VendorStatus.submitted);
        expect(application.timeline, hasLength(6));
        expect(application.timeline.first.isCurrent, isTrue);
        expect(
          controller.vendorApplicationById(application.id),
          same(application),
        );
        expect(repository.state?.vendorApplications.single.id, application.id);

        final notification = controller.notifications.first;
        expect(notification.referenceId, application.id);
        expect(
          notification.destination,
          NotificationDestination.vendorApplication,
        );
      },
    );

    test('vendor declaration is required before persistence', () async {
      final repository = InMemoryAppRepository(const AppStateData());
      final controller = AppController(repository: repository);
      await controller.initialize();

      expect(
        () => controller.submitVendorApplication(
          const VendorApplicationDraft(
            applicantName: 'Anaya Joshi',
            mobile: '9876543210',
            businessName: 'Orange City Crafts',
          ),
        ),
        throwsArgumentError,
      );
      expect(repository.state?.vendorApplications, isEmpty);
    });
  });

  group('AppController filtering and lookup', () {
    test('separates active and resolved complaints and resolves IDs', () async {
      final active = _complaint('active', ComplaintStatus.inProgress);
      final resolved = _complaint('resolved', ComplaintStatus.resolved);
      final rejected = _complaint('rejected', ComplaintStatus.rejected);
      final repository = InMemoryAppRepository(
        AppStateData(complaints: [active, resolved, rejected]),
      );
      final controller = AppController(repository: repository);
      await controller.initialize();

      expect(controller.activeComplaints.map((item) => item.id), ['active']);
      expect(controller.resolvedComplaints.map((item) => item.id), [
        'resolved',
      ]);
      expect(controller.complaintById('rejected'), same(rejected));
      expect(controller.complaintById('missing'), isNull);
      expect(controller.vendorApplicationById('missing'), isNull);
      expect(controller.newsById('demo-news-water-1'), isNotNull);
      expect(controller.newsById('missing'), isNull);
      expect(
        controller.serviceFor(ServiceType.drainage).type,
        ServiceType.drainage,
      );
    });

    test('notification read state and unread count stay in sync', () async {
      final repository = InMemoryAppRepository(
        AppStateData(
          notifications: [_notification('first'), _notification('second')],
        ),
      );
      final controller = AppController(repository: repository);
      await controller.initialize();
      expect(controller.unreadNotificationCount, 2);

      await controller.markNotificationRead('first');
      expect(controller.unreadNotificationCount, 1);
      expect(repository.state?.notifications.first.isRead, isTrue);

      await controller.markAllNotificationsRead();
      expect(controller.unreadNotificationCount, 0);
      expect(
        repository.state?.notifications.every((item) => item.isRead),
        isTrue,
      );
    });
  });
}

ComplaintRecord _complaint(String id, ComplaintStatus status) {
  final timestamp = DateTime(2026, 8, 17);
  return ComplaintRecord(
    id: id,
    serviceType: ServiceType.roads,
    issue: 'Road issue',
    description: 'Description',
    location: const ProblemLocation(
      latitude: 21.1458,
      longitude: 79.0882,
      accuracy: 12,
      address: 'Nagpur',
    ),
    contactPhone: '9876543210',
    createdAt: timestamp,
    updatedAt: timestamp,
    status: status,
  );
}

AppNotification _notification(String id) => AppNotification(
  id: id,
  title: 'Update',
  body: 'Request updated',
  category: NotificationCategory.requests,
  createdAt: DateTime(2026, 8, 17),
);
