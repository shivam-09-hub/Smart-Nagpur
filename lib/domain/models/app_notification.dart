enum NotificationCategory { important, requests, cityUpdates }

enum NotificationDestination {
  none,
  complaint,
  vendorApplication,
  news,
  services,
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.createdAt,
    this.destination = NotificationDestination.none,
    this.referenceId,
    this.isRead = false,
    this.isDemo = true,
  });

  final String id;
  final String title;
  final String body;
  final NotificationCategory category;
  final DateTime createdAt;
  final NotificationDestination destination;
  final String? referenceId;
  final bool isRead;
  final bool isDemo;

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      category: category,
      createdAt: createdAt,
      destination: destination,
      referenceId: referenceId,
      isRead: isRead ?? this.isRead,
      isDemo: isDemo,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'category': category.name,
    'createdAt': createdAt.toIso8601String(),
    'destination': destination.name,
    'referenceId': referenceId,
    'isRead': isRead,
    'isDemo': isDemo,
  };

  factory AppNotification.fromJson(Map<String, Object?> json) {
    return AppNotification(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      category: NotificationCategory.values.firstWhere(
        (value) => value.name == json['category'],
        orElse: () => NotificationCategory.cityUpdates,
      ),
      createdAt:
          DateTime.tryParse(
            (json['created_at'] ?? json['createdAt']) as String? ?? '',
          ) ??
          DateTime.now(),
      destination: NotificationDestination.values.firstWhere(
        (value) => value.name == json['destination'],
        orElse: () => NotificationDestination.none,
      ),
      referenceId:
          (json['reference_id'] ?? json['referenceId']) as String?,
      isRead: (json['is_read'] ?? json['isRead']) as bool? ?? false,
      isDemo: json['isDemo'] as bool? ?? true,
    );
  }
}
