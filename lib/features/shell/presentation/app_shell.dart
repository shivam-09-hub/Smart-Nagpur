import 'package:flutter/material.dart';
import 'package:smart_nagpur/core/theme/theme.dart';
import 'package:smart_nagpur/features/home/home.dart';
import 'package:smart_nagpur/features/notifications/presentation/notifications_screen.dart';
import 'package:smart_nagpur/features/profile/presentation/profile_screen.dart';
import 'package:smart_nagpur/features/requests/presentation/requests_screen.dart';
import 'package:smart_nagpur/features/services/services.dart';
import 'package:smart_nagpur/state/app_controller.dart';

class AppShell extends StatefulWidget {
  const AppShell({required this.controller, this.initialIndex = 0, super.key});

  final AppController controller;
  final int initialIndex;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, 4);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final pages = [
          HomeScreen(
            profile: widget.controller.profile,
            services: widget.controller.services,
            news: widget.controller.news,
            requests: widget.controller.complaints,
            isDemoMode: widget.controller.isDemoMode,
            isOffline: widget.controller.isOffline,
          ),
          ServicesScreen(services: widget.controller.services),
          RequestsScreen(controller: widget.controller),
          NotificationsScreen(controller: widget.controller),
          ProfileScreen(controller: widget.controller),
        ];
        return PopScope<void>(
          canPop: _index == 0,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop && _index != 0) setState(() => _index = 0);
          },
          child: Scaffold(
            body: IndexedStack(index: _index, children: pages),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (index) => setState(() => _index = index),
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(AppIcons.home),
                  label: 'Home',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.grid_view_outlined),
                  selectedIcon: Icon(AppIcons.services),
                  label: 'Services',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.assignment_outlined),
                  selectedIcon: Icon(AppIcons.requests),
                  label: 'My Requests',
                ),
                NavigationDestination(
                  icon: _NotificationIcon(
                    count: widget.controller.unreadNotificationCount,
                    selected: false,
                  ),
                  selectedIcon: _NotificationIcon(
                    count: widget.controller.unreadNotificationCount,
                    selected: true,
                  ),
                  label: 'Notifications',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(AppIcons.profile),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NotificationIcon extends StatelessWidget {
  const _NotificationIcon({required this.count, required this.selected});

  final int count;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Badge(
      isLabelVisible: count > 0,
      label: Text(count > 99 ? '99+' : '$count'),
      child: Icon(
        selected ? AppIcons.notifications : Icons.notifications_outlined,
      ),
    );
  }
}
