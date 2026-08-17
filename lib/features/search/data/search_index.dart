import '../../../domain/domain.dart';
import '../domain/search_result.dart';

abstract final class SearchIndex {
  static List<GlobalSearchResult> build({
    required List<ServiceDefinition> services,
    required List<NewsItem> news,
  }) => [
    ...services.map(
      (service) => GlobalSearchResult(
        id: 'service-${service.type.slug}',
        title: service.title,
        subtitle: service.description,
        type: SearchResultType.service,
        keywords: [
          service.shortTitle,
          service.heroTitle,
          ...service.searchTerms,
          ...service.actions.map((action) => action.title),
        ],
        service: service,
      ),
    ),
    ...news.map(
      (item) => GlobalSearchResult(
        id: 'news-${item.id}',
        title: item.title,
        subtitle: item.summary,
        type: SearchResultType.news,
        keywords: [item.category.label, item.content],
        newsItem: item,
      ),
    ),
    ...announcements,
    ...faqs,
  ];

  static const announcements = <GlobalSearchResult>[
    GlobalSearchResult(
      id: 'announcement-monsoon',
      title: 'Demo: Monsoon preparedness checklist',
      subtitle: 'A sample civic announcement for the development preview.',
      type: SearchResultType.announcement,
      keywords: ['rain', 'flood', 'drainage', 'emergency', 'monsoon'],
      body:
          'Keep emergency contacts available, avoid waterlogged routes and report open drains from Drainage & Flooding. This is demo guidance, not a live municipal announcement.',
    ),
    GlobalSearchResult(
      id: 'announcement-centre',
      title: 'Demo: Citizen service centre information',
      subtitle: 'See how verified centre hours and closures will appear.',
      type: SearchResultType.announcement,
      keywords: ['office', 'hours', 'support', 'citizen centre'],
      body:
          'Verified centre addresses, opening hours and holiday closures will appear after a municipal data connection is enabled.',
    ),
    GlobalSearchResult(
      id: 'announcement-cleanliness',
      title: 'Demo: Neighbourhood cleanliness drive',
      subtitle: 'A sample community-participation announcement.',
      type: SearchResultType.announcement,
      keywords: ['waste', 'garbage', 'event', 'clean city'],
      body:
          'This sample demonstrates an event announcement. It is not an invitation to a real event; verified locations and dates will replace this copy.',
    ),
  ];

  static const faqs = <GlobalSearchResult>[
    GlobalSearchResult(
      id: 'faq-report',
      title: 'How do I report a civic problem?',
      subtitle: 'Choose a service, add details, photo and problem location.',
      type: SearchResultType.faq,
      keywords: ['complaint', 'issue', 'submit', 'report problem'],
      body:
          'Open Services, choose the relevant civic service and select an issue. The guided report asks for a description, optional photo, exact problem location and contact details before you review and submit.',
    ),
    GlobalSearchResult(
      id: 'faq-track',
      title: 'Where can I track a request?',
      subtitle: 'Submitted reports appear under My Requests.',
      type: SearchResultType.faq,
      keywords: ['status', 'complaint id', 'tracking', 'my requests'],
      body:
          'Open My Requests from the bottom navigation. Choose a request to see its status, latest update and demo timeline.',
    ),
    GlobalSearchResult(
      id: 'faq-vendor',
      title: 'How do I start vendor registration?',
      subtitle: 'Use Vendor & Small Business under Services.',
      type: SearchResultType.faq,
      keywords: ['business', 'permission', 'vendor application', 'documents'],
      body:
          'Open Services, choose Vendor & Small Business, then select Register as Vendor. Complete and review all eight guided steps before submitting the application.',
    ),
    GlobalSearchResult(
      id: 'faq-location',
      title: 'Why does a report need my location?',
      subtitle: 'The problem location helps identify the exact civic issue.',
      type: SearchResultType.faq,
      keywords: ['gps', 'map', 'pin', 'accuracy', 'permission'],
      body:
          'Your problem location is separate from your home address. You can use GPS or adjust the map pin, then confirm the address and accuracy before submission.',
    ),
    GlobalSearchResult(
      id: 'faq-photo',
      title: 'Can I add a photo to a report?',
      subtitle: 'Take a photo or choose one from your gallery.',
      type: SearchResultType.faq,
      keywords: ['camera', 'gallery', 'image', 'remove photo'],
      body:
          'Yes. In the report flow you can take a photo, choose from the gallery, preview it or remove it before submitting.',
    ),
  ];
}
