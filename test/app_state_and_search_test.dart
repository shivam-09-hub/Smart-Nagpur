import 'package:flutter_test/flutter_test.dart';
import 'package:smart_nagpur/data/data.dart';
import 'package:smart_nagpur/domain/domain.dart';
import 'package:smart_nagpur/features/search/data/search_index.dart';
import 'package:smart_nagpur/features/search/domain/search_result.dart';

void main() {
  test('AppStateData JSON round-trip preserves citizen workflow state', () {
    final timestamp = DateTime.utc(2026, 8, 17, 9, 30);
    final original = AppStateData(
      hasCompletedOnboarding: true,
      isAuthenticated: true,
      localeCode: 'mr',
      profile: const UserProfile(
        name: 'Aarav Kulkarni',
        phone: '9876543210',
        email: 'aarav@example.com',
      ),
      complaints: [
        ComplaintRecord(
          id: 'NAG-2026-000001',
          serviceType: ServiceType.garbage,
          issue: 'Missed collection',
          description: 'Collection was missed.',
          location: const ProblemLocation(
            latitude: 21.1458,
            longitude: 79.0882,
            accuracy: 15,
            address: 'Nagpur',
          ),
          contactPhone: '9876543210',
          createdAt: timestamp,
          updatedAt: timestamp,
          status: ComplaintStatus.submitted,
        ),
      ],
      vendorApplications: [
        VendorApplication(
          id: 'VN-2026-000001',
          details: const VendorApplicationDraft(
            applicantName: 'Aarav Kulkarni',
            mobile: '9876543210',
            businessName: 'Orange City Snacks',
            acceptedDeclaration: true,
          ),
          status: VendorStatus.submitted,
          createdAt: timestamp,
          updatedAt: timestamp,
        ),
      ],
      notifications: [
        AppNotification(
          id: 'notification-1',
          title: 'Request submitted',
          body: 'Saved locally.',
          category: NotificationCategory.requests,
          createdAt: timestamp,
          destination: NotificationDestination.complaint,
          referenceId: 'NAG-2026-000001',
        ),
      ],
    );

    final restored = AppStateData.fromJson(original.toJson());

    expect(restored.hasCompletedOnboarding, isTrue);
    expect(restored.isAuthenticated, isTrue);
    expect(restored.localeCode, 'mr');
    expect(restored.profile?.name, 'Aarav Kulkarni');
    expect(restored.complaints.single.id, 'NAG-2026-000001');
    expect(restored.complaints.single.location.address, 'Nagpur');
    expect(restored.vendorApplications.single.id, 'VN-2026-000001');
    expect(
      restored.vendorApplications.single.details.acceptedDeclaration,
      isTrue,
    );
    expect(restored.notifications.single.referenceId, 'NAG-2026-000001');
  });

  test('search index supports keyword filtering across result types', () {
    final index = SearchIndex.build(
      services: DemoData.services,
      news: DemoData.news,
    );

    final potholeMatches = _filter(index, 'pothole');
    expect(
      potholeMatches.any(
        (result) =>
            result.type == SearchResultType.service &&
            result.service?.type == ServiceType.roads,
      ),
      isTrue,
    );

    final trackingMatches = _filter(index, 'tracking');
    expect(
      trackingMatches.any((result) => result.type == SearchResultType.faq),
      isTrue,
    );

    final impossibleMatches = _filter(index, 'not-a-real-civic-query');
    expect(impossibleMatches, isEmpty);
  });

  test('search index has stable unique IDs and linked records', () {
    final index = SearchIndex.build(
      services: DemoData.services,
      news: DemoData.news,
    );

    expect(index.map((result) => result.id).toSet(), hasLength(index.length));
    expect(
      index.where((result) => result.type == SearchResultType.service),
      hasLength(DemoData.services.length),
    );
    expect(
      index.where((result) => result.type == SearchResultType.news),
      hasLength(DemoData.news.length),
    );
    expect(
      index
          .where((result) => result.type == SearchResultType.service)
          .every((result) => result.service != null),
      isTrue,
    );
    expect(
      index
          .where((result) => result.type == SearchResultType.news)
          .every((result) => result.newsItem != null),
      isTrue,
    );
  });

  test('domain status and location helpers encode filtering rules', () {
    expect(ComplaintStatus.submitted.isActive, isTrue);
    expect(ComplaintStatus.moreInformationRequired.isActive, isTrue);
    expect(ComplaintStatus.resolved.isActive, isFalse);
    expect(ComplaintStatus.rejected.isActive, isFalse);
    expect(
      const ProblemLocation(
        latitude: 21.1458,
        longitude: 79.0882,
        accuracy: 75,
        address: 'Nagpur',
      ).hasLowAccuracy,
      isTrue,
    );
  });
}

List<GlobalSearchResult> _filter(List<GlobalSearchResult> index, String query) {
  final normalized = query.trim().toLowerCase();
  return index
      .where((result) => result.searchableText.contains(normalized))
      .toList(growable: false);
}
