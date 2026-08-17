import '../../domain/domain.dart';

abstract final class DemoData {
  static const UserProfile profile = UserProfile(
    name: 'Aarav Kulkarni',
    phone: '9876543210',
    email: 'aarav@example.com',
    address: 'Dharampeth, Nagpur, Maharashtra',
  );

  static const services = <ServiceDefinition>[
    ServiceDefinition(
      type: ServiceType.vendor,
      title: 'Vendor & Small Business',
      shortTitle: 'Vendor',
      description: 'Registration, permissions and support for local vendors.',
      heroTitle: 'Start or manage your small business in Nagpur.',
      searchTerms: ['vendor registration', 'hawker', 'permission', 'stall'],
      actions: [
        ServiceAction(
          id: 'vendor-register',
          title: 'Register as Vendor',
          kind: ServiceActionKind.vendorRegistration,
        ),
        ServiceAction(
          id: 'vendor-permission',
          title: 'Apply for Permission',
          kind: ServiceActionKind.vendorPermission,
        ),
        ServiceAction(
          id: 'vendor-zones',
          title: 'Find Vendor Zones',
          kind: ServiceActionKind.vendorZones,
        ),
        ServiceAction(
          id: 'vendor-track',
          title: 'Track Application',
          kind: ServiceActionKind.vendorTracking,
        ),
        ServiceAction(
          id: 'vendor-renew',
          title: 'Renew Permission',
          kind: ServiceActionKind.vendorRenewal,
        ),
        ServiceAction(
          id: 'vendor-documents',
          title: 'My Documents',
          kind: ServiceActionKind.vendorDocuments,
        ),
      ],
    ),
    ServiceDefinition(
      type: ServiceType.garbage,
      title: 'Garbage & Waste',
      shortTitle: 'Garbage',
      description: 'Report waste collection and cleanliness concerns.',
      heroTitle: 'Help keep every Nagpur neighbourhood clean.',
      searchTerms: ['garbage', 'waste', 'dumping', 'collection'],
      actions: [
        ServiceAction(id: 'garbage-missed', title: 'Report Missed Collection'),
        ServiceAction(
          id: 'garbage-overflowing',
          title: 'Report Overflowing Garbage',
        ),
        ServiceAction(id: 'garbage-dumping', title: 'Report Illegal Dumping'),
        ServiceAction(
          id: 'garbage-open-point',
          title: 'Report Open Garbage Point',
        ),
        ServiceAction(
          id: 'garbage-info',
          title: 'View Collection Information',
          kind: ServiceActionKind.information,
        ),
      ],
    ),
    ServiceDefinition(
      type: ServiceType.water,
      title: 'Water Services',
      shortTitle: 'Water',
      description: 'Report water supply, leakage and quality issues.',
      heroTitle: 'Report water concerns in your area.',
      searchTerms: ['water leakage', 'no water', 'pipeline', 'water quality'],
      actions: [
        ServiceAction(id: 'water-none', title: 'Report No Water'),
        ServiceAction(id: 'water-leakage', title: 'Report Leakage'),
        ServiceAction(id: 'water-pipeline', title: 'Report Pipeline Damage'),
        ServiceAction(
          id: 'water-quality',
          title: 'Report Water Quality Concern',
        ),
        ServiceAction(
          id: 'water-info',
          title: 'View Water Information',
          kind: ServiceActionKind.information,
        ),
      ],
    ),
    ServiceDefinition(
      type: ServiceType.roads,
      title: 'Roads & Infrastructure',
      shortTitle: 'Roads',
      description: 'Report road damage and public infrastructure issues.',
      heroTitle: 'Make Nagpur streets safer for everyone.',
      searchTerms: ['road complaint', 'pothole', 'footpath', 'excavation'],
      actions: [
        ServiceAction(id: 'roads-pothole', title: 'Report Pothole'),
        ServiceAction(id: 'roads-damage', title: 'Report Road Damage'),
        ServiceAction(id: 'roads-footpath', title: 'Report Broken Footpath'),
        ServiceAction(id: 'roads-excavation', title: 'Report Open Excavation'),
        ServiceAction(
          id: 'roads-sign',
          title: 'Report Missing/Damaged Road Sign',
        ),
        ServiceAction(
          id: 'roads-obstruction',
          title: 'Report Traffic Obstruction',
        ),
      ],
    ),
    ServiceDefinition(
      type: ServiceType.animals,
      title: 'Animal Services',
      shortTitle: 'Animals',
      description: 'Request help for animals and related public concerns.',
      heroTitle: 'Get the right help for animals in the city.',
      searchTerms: ['stray animal', 'rescue', 'injured animal'],
      actions: [
        ServiceAction(id: 'animals-stray', title: 'Report Stray Animal'),
        ServiceAction(id: 'animals-injured', title: 'Report Injured Animal'),
        ServiceAction(id: 'animals-rescue', title: 'Request Rescue'),
        ServiceAction(id: 'animals-nuisance', title: 'Report Animal Nuisance'),
        ServiceAction(id: 'animals-dead', title: 'Report Dead Animal'),
      ],
    ),
    ServiceDefinition(
      type: ServiceType.drainage,
      title: 'Drainage & Flooding',
      shortTitle: 'Drainage',
      description: 'Report blocked drains, waterlogging and flooding.',
      heroTitle: 'Help us respond to drainage problems quickly.',
      searchTerms: ['drain', 'waterlogging', 'flooding'],
      actions: [
        ServiceAction(id: 'drainage-blocked', title: 'Report Blocked Drain'),
        ServiceAction(
          id: 'drainage-waterlogging',
          title: 'Report Waterlogging',
        ),
        ServiceAction(id: 'drainage-open', title: 'Report Open Drain'),
        ServiceAction(id: 'drainage-flooding', title: 'Report Flooding'),
      ],
    ),
    ServiceDefinition(
      type: ServiceType.streetlights,
      title: 'Streetlights & Electricity',
      shortTitle: 'Streetlights',
      description: 'Report public lighting and electrical safety concerns.',
      heroTitle: 'Keep streets visible and electrical hazards reported.',
      searchTerms: ['streetlight', 'pole', 'exposed wire', 'electricity'],
      actions: [
        ServiceAction(
          id: 'streetlights-not-working',
          title: 'Streetlight Not Working',
        ),
        ServiceAction(id: 'streetlights-pole', title: 'Damaged Pole'),
        ServiceAction(
          id: 'streetlights-wire',
          title: 'Exposed Wire',
          safetyMessage: 'Keep a safe distance and do not touch exposed wires.',
        ),
        ServiceAction(
          id: 'streetlights-hazard',
          title: 'Electrical Hazard',
          safetyMessage:
              'Keep away from the hazard. Contact emergency services if there is immediate danger.',
        ),
      ],
    ),
    ServiceDefinition(
      type: ServiceType.publicSpaces,
      title: 'Public Spaces',
      shortTitle: 'Public Spaces',
      description: 'Report issues in parks and other shared facilities.',
      heroTitle: 'Care for Nagpur’s shared public spaces.',
      searchTerms: ['park', 'playground', 'public toilet', 'public property'],
      actions: [
        ServiceAction(id: 'spaces-park', title: 'Report Park Issue'),
        ServiceAction(
          id: 'spaces-playground',
          title: 'Report Playground Issue',
        ),
        ServiceAction(id: 'spaces-toilet', title: 'Report Public Toilet Issue'),
        ServiceAction(
          id: 'spaces-property',
          title: 'Report Damaged Public Property',
        ),
        ServiceAction(
          id: 'spaces-cleanliness',
          title: 'Report Cleanliness Issue',
        ),
      ],
    ),
    ServiceDefinition(
      type: ServiceType.encroachment,
      title: 'Encroachment & Civic Issues',
      shortTitle: 'Encroachment',
      description: 'Report possible obstructions for municipal verification.',
      heroTitle: 'Report a civic obstruction for fair verification.',
      searchTerms: ['encroachment', 'obstruction', 'unauthorized construction'],
      actions: [
        ServiceAction(
          id: 'encroachment-road',
          title: 'Report Road Encroachment',
        ),
        ServiceAction(
          id: 'encroachment-obstruction',
          title: 'Report Illegal Obstruction',
        ),
        ServiceAction(
          id: 'encroachment-construction',
          title: 'Report Unauthorized Construction',
        ),
        ServiceAction(
          id: 'encroachment-vendor',
          title: 'Report Unauthorized Vendor',
        ),
        ServiceAction(
          id: 'encroachment-space',
          title: 'Report Public Space Encroachment',
        ),
      ],
    ),
    ServiceDefinition(
      type: ServiceType.other,
      title: 'Other Civic Services',
      shortTitle: 'Other',
      description: 'Tell us about another civic concern.',
      heroTitle: 'Find help for another civic issue.',
      searchTerms: ['other issue', 'civic help', 'municipal service'],
      actions: [
        ServiceAction(id: 'other-report', title: 'Report Another Civic Issue'),
        ServiceAction(
          id: 'other-information',
          title: 'Browse Civic Information',
          kind: ServiceActionKind.information,
        ),
      ],
    ),
  ];

  static final news = <NewsItem>[
    NewsItem(
      id: 'demo-news-water-1',
      title: 'Water supply maintenance advisory',
      summary:
          'A development-mode advisory demonstrates how scheduled maintenance updates appear.',
      content:
          'This is sample content for the Smart Nagpur development build. In a connected release, verified schedule, affected areas and official contact details will be supplied by the municipal backend.',
      category: NewsCategory.water,
      publishedAt: DateTime(2026, 8, 17, 8, 30),
      isImportant: true,
    ),
    NewsItem(
      id: 'demo-news-road-1',
      title: 'Ward road improvement update',
      summary:
          'See how route diversions and public works updates will be shared with citizens.',
      content:
          'Demo update: road improvement information, expected duration and alternate-route guidance will appear here after verification by the responsible department.',
      category: NewsCategory.roadWork,
      publishedAt: DateTime(2026, 8, 16, 17, 15),
    ),
    NewsItem(
      id: 'demo-news-waste-1',
      title: 'Neighbourhood cleanliness drive',
      summary:
          'A sample city update about community participation in a cleanliness drive.',
      content:
          'This development-only story demonstrates the news experience. Official event locations and timings will replace this copy when live data is connected.',
      category: NewsCategory.events,
      publishedAt: DateTime(2026, 8, 15, 10),
    ),
    NewsItem(
      id: 'demo-news-notice-1',
      title: 'Citizen service centre information',
      summary:
          'A sample public notice showing how service-centre information can be presented.',
      content:
          'Demo notice: verified hours, addresses and holiday closures will be sourced from the municipal service when the production backend is connected.',
      category: NewsCategory.publicNotices,
      publishedAt: DateTime(2026, 8, 14, 12),
    ),
  ];

  static final complaints = <ComplaintRecord>[
    ComplaintRecord(
      id: 'NAG-2026-001238',
      serviceType: ServiceType.roads,
      issue: 'Pothole',
      description:
          'Demo request: a deep pothole is shown near the lane intersection.',
      location: const ProblemLocation(
        latitude: 21.1458,
        longitude: 79.0882,
        accuracy: 12,
        address: 'Near Civil Lines, Nagpur (demo location)',
      ),
      contactPhone: profile.phone,
      createdAt: DateTime(2026, 8, 12, 9, 42),
      updatedAt: DateTime(2026, 8, 13, 14, 20),
      status: ComplaintStatus.underReview,
      timeline: [
        RequestTimelineEntry(
          title: 'Submitted',
          timestamp: DateTime(2026, 8, 12, 9, 42),
          message: 'Demo report saved on this device.',
        ),
        RequestTimelineEntry(
          title: 'Under review',
          timestamp: DateTime(2026, 8, 13, 14, 20),
          message: 'Simulated status for development preview.',
        ),
      ],
    ),
    ComplaintRecord(
      id: 'NAG-2026-001191',
      serviceType: ServiceType.garbage,
      issue: 'Missed collection',
      description:
          'Demo request: household waste collection was shown as missed.',
      location: const ProblemLocation(
        latitude: 21.1214,
        longitude: 79.0474,
        accuracy: 18,
        address: 'Dharampeth, Nagpur (demo location)',
      ),
      contactPhone: profile.phone,
      createdAt: DateTime(2026, 8, 7, 7, 35),
      updatedAt: DateTime(2026, 8, 9, 11),
      status: ComplaintStatus.resolved,
      timeline: [
        RequestTimelineEntry(
          title: 'Submitted',
          timestamp: DateTime(2026, 8, 7, 7, 35),
          message: 'Demo report saved on this device.',
        ),
        RequestTimelineEntry(
          title: 'Resolved',
          timestamp: DateTime(2026, 8, 9, 11),
          message: 'Simulated resolution for development preview.',
        ),
      ],
    ),
  ];

  static final vendorApplications = <VendorApplication>[
    VendorApplication(
      id: 'VN-2026-001284',
      details: const VendorApplicationDraft(
        applicantName: 'Aarav Kulkarni',
        mobile: '9876543210',
        email: 'aarav@example.com',
        residentialAddress: 'Dharampeth, Nagpur',
        identityInformation: 'Identity details provided in demo mode',
        businessName: 'Orange City Snacks',
        businessType: 'Street food cart',
        category: 'Food & Beverage',
        description: 'Fresh snacks and beverages',
        productsServices: 'Poha, tea and packaged water',
        location: ProblemLocation(
          latitude: 21.1458,
          longitude: 79.0882,
          accuracy: 15,
          address: 'Civil Lines vendor zone (demo location)',
        ),
        preferredZone: 'Civil Lines demo zone',
        operatingDays: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
        startTime: '08:00',
        endTime: '18:00',
        outletType: 'Cart',
        acceptedDeclaration: true,
      ),
      status: VendorStatus.underReview,
      createdAt: DateTime(2026, 8, 10, 10, 25),
      updatedAt: DateTime(2026, 8, 12, 15, 10),
      timeline: [
        VendorTimelineEntry(
          title: 'Application submitted',
          timestamp: DateTime(2026, 8, 10, 10, 25),
          message: 'Demo application saved on this device.',
          isCompleted: true,
        ),
        VendorTimelineEntry(
          title: 'Documents verified',
          timestamp: DateTime(2026, 8, 11, 12),
          message: 'Simulated status for development preview.',
          isCompleted: true,
        ),
        VendorTimelineEntry(
          title: 'Under review',
          timestamp: DateTime(2026, 8, 12, 15, 10),
          message: 'Simulated status — no municipal decision has been made.',
          isCurrent: true,
        ),
        VendorTimelineEntry(title: 'Location assessment'),
        VendorTimelineEntry(title: 'Decision'),
        VendorTimelineEntry(title: 'Permission issued'),
      ],
    ),
  ];

  static final notifications = <AppNotification>[
    AppNotification(
      id: 'demo-notification-water',
      title: 'Water maintenance advisory',
      body: 'Open the sample city update for development preview details.',
      category: NotificationCategory.important,
      createdAt: DateTime(2026, 8, 17, 8, 35),
      destination: NotificationDestination.news,
      referenceId: 'demo-news-water-1',
    ),
    AppNotification(
      id: 'demo-notification-vendor',
      title: 'Vendor application under review',
      body: 'VN-2026-001284 has a simulated “Under review” status.',
      category: NotificationCategory.requests,
      createdAt: DateTime(2026, 8, 12, 15, 11),
      destination: NotificationDestination.vendorApplication,
      referenceId: 'VN-2026-001284',
    ),
    AppNotification(
      id: 'demo-notification-complaint',
      title: 'Road report submitted',
      body: 'NAG-2026-001238 is available in My Requests.',
      category: NotificationCategory.requests,
      createdAt: DateTime(2026, 8, 12, 9, 43),
      destination: NotificationDestination.complaint,
      referenceId: 'NAG-2026-001238',
      isRead: true,
    ),
  ];
}
