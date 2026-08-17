import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_nagpur/core/theme/theme.dart';
import 'package:smart_nagpur/core/widgets/states.dart';
import 'package:smart_nagpur/domain/domain.dart';
import 'package:smart_nagpur/state/app_controller.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({required this.controller, super.key});

  final AppController controller;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _markAllRead() async {
    try {
      await widget.controller.markAllNotificationsRead();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Read status could not sync. Try again when you are online.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Notifications'),
            actions: [
              if (widget.controller.unreadNotificationCount > 0)
                TextButton(
                  onPressed: _markAllRead,
                  child: const Text('Mark all read'),
                ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: const [
                Tab(text: 'Important'),
                Tab(text: 'Requests'),
                Tab(text: 'City Updates'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children:
                const [
                      _NotificationCategoryView(
                        category: NotificationCategory.important,
                      ),
                      _NotificationCategoryView(
                        category: NotificationCategory.requests,
                      ),
                      _NotificationCategoryView(
                        category: NotificationCategory.cityUpdates,
                      ),
                    ]
                    .map(
                      (view) => _NotificationCategoryView(
                        category: view.category,
                        controller: widget.controller,
                      ),
                    )
                    .toList(),
          ),
        );
      },
    );
  }
}

class _NotificationCategoryView extends StatelessWidget {
  const _NotificationCategoryView({required this.category, this.controller});

  final NotificationCategory category;
  final AppController? controller;

  @override
  Widget build(BuildContext context) {
    final items =
        controller!.notifications
            .where((item) => item.category == category)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (items.isEmpty) {
      return EmptyState(
        icon: Icons.notifications_none,
        title: 'No ${_categoryLabel(category).toLowerCase()} notifications',
        message: 'New demo updates will appear here.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _NotificationTile(
        notification: items[index],
        controller: controller!,
      ),
    );
  }

  static String _categoryLabel(NotificationCategory category) =>
      switch (category) {
        NotificationCategory.important => 'Important',
        NotificationCategory.requests => 'Requests',
        NotificationCategory.cityUpdates => 'City Updates',
      };
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.controller,
  });

  final AppNotification notification;
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (notification.category) {
      NotificationCategory.important => (
        Icons.warning_amber_rounded,
        AppColors.warning,
      ),
      NotificationCategory.requests => (
        Icons.assignment_outlined,
        AppColors.info,
      ),
      NotificationCategory.cityUpdates => (
        Icons.location_city,
        AppColors.secondary,
      ),
    };
    return Card(
      margin: EdgeInsets.zero,
      color: notification.isRead
          ? Theme.of(context).colorScheme.surface
          : color.withValues(alpha: 0.06),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () => _open(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: notification.isRead
                                  ? FontWeight.w600
                                  : FontWeight.w800,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(notification.body),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          DateFormat(
                            'd MMM, h:mm a',
                          ).format(notification.createdAt.toLocal()),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (notification.isDemo) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'DEMO',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    unawaited(_markReadWithoutBlockingNavigation(context));
    final reference = notification.referenceId;
    switch (notification.destination) {
      case NotificationDestination.complaint:
        if (reference != null) {
          await Navigator.pushNamed(
            context,
            '/requests/$reference',
            arguments: reference,
          );
        }
      case NotificationDestination.vendorApplication:
        await Navigator.pushNamed(
          context,
          '/vendor/application',
          arguments: reference,
        );
      case NotificationDestination.news:
        if (reference != null) {
          await Navigator.pushNamed(
            context,
            '/news/$reference',
            arguments: reference,
          );
        }
      case NotificationDestination.services:
        await Navigator.pushNamed(context, '/services');
      case NotificationDestination.none:
        if (!context.mounted) return;
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(notification.title),
            content: Text(notification.body),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
    }
  }

  Future<void> _markReadWithoutBlockingNavigation(BuildContext context) async {
    try {
      await controller.markNotificationRead(notification.id);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Opened the notification, but its read status could not sync. Try again when online.',
          ),
        ),
      );
    }
  }
}
