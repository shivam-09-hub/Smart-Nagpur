import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/core_widgets.dart';
import '../../../data/demo/demo_data.dart';
import '../../../domain/domain.dart';
import '../../bootstrap/presentation/widgets/smart_nagpur_brand.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    this.profile,
    this.services,
    this.news,
    this.requests,
    this.isLoading = false,
    this.isDemoMode = true,
    this.isOffline = false,
    this.errorMessage,
    this.onRetry,
    super.key,
  });

  static const routeName = '/home';

  final UserProfile? profile;
  final List<ServiceDefinition>? services;
  final List<NewsItem>? news;
  final List<ComplaintRecord>? requests;
  final bool isLoading;
  final bool isDemoMode;
  final bool isOffline;
  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  String _currentArea = 'Dharampeth, Nagpur';

  UserProfile get _profile => widget.profile ?? DemoData.profile;
  List<ServiceDefinition> get _services => widget.services ?? DemoData.services;
  List<NewsItem> get _news => widget.news ?? DemoData.news;
  List<ComplaintRecord> get _requests => widget.requests ?? DemoData.complaints;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _navigate(String route, {Object? arguments}) {
    Navigator.of(context).pushNamed(route, arguments: arguments);
  }

  void _openService(ServiceDefinition service) {
    _navigate('/services/${service.type.slug}', arguments: service);
  }

  void _chooseArea() {
    const areas = <String>[
      'Dharampeth, Nagpur',
      'Civil Lines, Nagpur',
      'Manish Nagar, Nagpur',
    ];
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current area',
                style: Theme.of(
                  sheetContext,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose a demo area for personalised home content.',
                style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              RadioGroup<String>(
                groupValue: _currentArea,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _currentArea = value);
                  Navigator.pop(sheetContext);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: areas
                      .map(
                        (area) => RadioListTile<String>(
                          value: area,
                          contentPadding: EdgeInsets.zero,
                          title: Text(area),
                          subtitle: const Text('Demo location'),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Scaffold(body: LoadingState(message: 'Loading your city…'));
    }
    if (widget.errorMessage case final message?) {
      return Scaffold(
        body: SafeArea(
          child: ErrorState(
            title: 'Couldn’t load your home',
            message: message,
            onRetry: widget.onRetry,
          ),
        ),
      );
    }

    final importantItems = _news.where((item) => item.isImportant).toList();
    final importantNews = importantItems.isEmpty ? null : importantItems.first;
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          key: const PageStorageKey('home-scroll'),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverToBoxAdapter(child: _buildHero(context)),
            SliverToBoxAdapter(
              child: _HomeSection(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: 'Important Alert'),
                    const SizedBox(height: 12),
                    AlertCard(
                      title: importantNews?.title ?? 'No important demo alerts',
                      message:
                          importantNews?.summary ??
                          'You’re all caught up. Verified alerts will appear here when connected.',
                      actionLabel: importantNews == null ? null : 'Read update',
                      onTap: importantNews == null
                          ? () => ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('No important alerts right now.'),
                              ),
                            )
                          : () => _navigate(
                              '/news/${importantNews.id}',
                              arguments: importantNews,
                            ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(child: _buildLatestNews(context)),
            SliverToBoxAdapter(child: _buildQuickActions(context)),
            SliverToBoxAdapter(child: _buildServices(context)),
            SliverToBoxAdapter(child: _buildRecentRequests(context)),
            SliverToBoxAdapter(child: _buildCityStats(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return _HomeSection(
      top: 10,
      bottom: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: SmartNagpurBrand(compact: true, showTagline: false),
              ),
              IconButton(
                tooltip: 'Search Smart Nagpur',
                onPressed: () => _navigate('/search'),
                icon: const Icon(Icons.search_rounded),
              ),
              Badge(
                smallSize: 8,
                child: IconButton(
                  tooltip: 'Notifications',
                  onPressed: () => _navigate('/notifications'),
                  icon: const Icon(Icons.notifications_none_rounded),
                ),
              ),
              const SizedBox(width: 3),
              Semantics(
                button: true,
                label: 'Open profile for ${_profile.name}',
                child: InkWell(
                  borderRadius: BorderRadius.circular(99),
                  onTap: () => _navigate('/profile'),
                  child: CircleAvatar(
                    radius: 21,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.secondaryContainer,
                    child: Text(
                      _initials(_profile.name),
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '$_greeting, ${_profile.name.split(' ').first}',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Semantics(
            button: true,
            label: 'Current area $_currentArea. Tap to change demo area.',
            child: Material(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(99),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _chooseArea,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Flexible(child: Text(_currentArea)),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 19),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: AppShadows.raised,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 600;
              final copy = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your City. Your Voice.',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.6,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Access civic services, report problems and stay updated with Nagpur.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: .88),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primaryDark,
                        ),
                        onPressed: () => _navigate('/complaints/create'),
                        icon: const Icon(Icons.add_circle_outline_rounded),
                        label: const Text('Report a Problem'),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: .72),
                          ),
                        ),
                        onPressed: () => _navigate('/services'),
                        icon: const Icon(Icons.grid_view_rounded),
                        label: const Text('Explore Services'),
                      ),
                    ],
                  ),
                ],
              );
              final illustration = Semantics(
                label: 'Nagpur civic services illustration',
                child: Container(
                  width: wide ? 150 : 86,
                  height: wide ? 150 : 86,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .2),
                    ),
                  ),
                  child: Icon(
                    Icons.location_city_rounded,
                    color: Colors.white,
                    size: wide ? 72 : 44,
                  ),
                ),
              );
              if (wide) {
                return Row(
                  children: [
                    Expanded(child: copy),
                    const SizedBox(width: 24),
                    illustration,
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [illustration, const SizedBox(height: 20), copy],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLatestNews(BuildContext context) {
    final latest = _news.take(3).toList();
    return _HomeSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Latest from Nagpur',
            subtitle: 'Clearly labelled demo city updates',
            actionLabel: 'View all',
            onAction: () => _navigate('/news'),
          ),
          const SizedBox(height: 12),
          if (latest.isEmpty)
            EmptyState(
              title: 'No city updates yet',
              message: 'Demo city updates will appear here.',
              icon: Icons.article_outlined,
              actionLabel: 'Open news',
              onAction: () => _navigate('/news'),
            )
          else
            ...latest.indexed.expand(
              (entry) => [
                NewsCard(
                  item: entry.$2,
                  onTap: () =>
                      _navigate('/news/${entry.$2.id}', arguments: entry.$2),
                ),
                if (entry.$1 != latest.length - 1) const SizedBox(height: 12),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions =
        <({String title, IconData icon, Color color, VoidCallback tap})>[
          (
            title: 'Report a problem',
            icon: Icons.add_circle_outline_rounded,
            color: AppColors.primary,
            tap: () => _navigate('/complaints/create'),
          ),
          (
            title: 'Track requests',
            icon: Icons.track_changes_rounded,
            color: AppColors.animals,
            tap: () => _navigate('/requests'),
          ),
          (
            title: 'Vendor services',
            icon: Icons.storefront_outlined,
            color: AppColors.vendor,
            tap: () => _navigate('/services/vendor'),
          ),
          (
            title: 'Search city help',
            icon: Icons.search_rounded,
            color: AppColors.publicSpaces,
            tap: () => _navigate('/search'),
          ),
        ];
    return _HomeSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Quick Actions'),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 720 ? 4 : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: actions.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: columns == 4 ? 1.45 : 1.25,
                ),
                itemBuilder: (context, index) {
                  final action = actions[index];
                  return QuickActionCard(
                    title: action.title,
                    icon: action.icon,
                    color: action.color,
                    onTap: action.tap,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildServices(BuildContext context) {
    final featured = _services.take(5).toList();
    return _HomeSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Civic Services',
            subtitle: 'Choose a service to get started',
            actionLabel: 'View all',
            onAction: () => _navigate('/services'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 124,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: featured.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) => SizedBox(
                width: MediaQuery.sizeOf(context).width < 430 ? 286 : 320,
                child: ServiceCard(
                  service: featured[index],
                  onTap: () => _openService(featured[index]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentRequests(BuildContext context) {
    final recent = _requests.take(2).toList();
    return _HomeSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Your Recent Requests',
            subtitle: widget.isDemoMode
                ? 'Local demo records on this device'
                : widget.isOffline
                ? 'Saved cloud data shown while offline'
                : 'Synced securely with your cloud account',
            actionLabel: 'View all',
            onAction: () => _navigate('/requests'),
          ),
          const SizedBox(height: 12),
          if (recent.isEmpty)
            EmptyState(
              title: 'No requests yet',
              message: widget.isDemoMode
                  ? 'Your locally submitted demo reports will appear here.'
                  : 'Reports submitted to your cloud account will appear here.',
              icon: Icons.assignment_outlined,
              actionLabel: 'Report a problem',
              onAction: () => _navigate('/complaints/create'),
            )
          else
            ...recent.indexed.expand(
              (entry) => [
                RequestCard(
                  request: entry.$2,
                  onTap: () => _navigate(
                    '/requests/${entry.$2.id}',
                    arguments: entry.$2,
                  ),
                ),
                if (entry.$1 != recent.length - 1) const SizedBox(height: 12),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCityStats(BuildContext context) {
    final stats = <({String value, String label, IconData icon})>[
      (
        value: '10',
        label: 'Civic service areas',
        icon: Icons.grid_view_rounded,
      ),
      (
        value: '24/7',
        label: widget.isDemoMode ? 'Digital demo access' : 'Account access',
        icon: Icons.schedule_rounded,
      ),
      (
        value: widget.isDemoMode ? 'Local' : 'Private',
        label: widget.isDemoMode ? 'Demo storage' : 'Cloud data storage',
        icon: widget.isDemoMode ? Icons.phone_android : Icons.cloud_outlined,
      ),
    ];
    return _HomeSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'City at a Glance',
            subtitle: 'Smart Nagpur development preview',
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 620 ? 3 : 1;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: stats.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  mainAxisExtent: 96,
                ),
                itemBuilder: (context, index) => _StatCard(stat: stats[index]),
              );
            },
          ),
        ],
      ),
    );
  }
}

class HomeDashboard extends HomeScreen {
  const HomeDashboard({
    super.profile,
    super.services,
    super.news,
    super.requests,
    super.isLoading,
    super.errorMessage,
    super.onRetry,
    super.key,
  });
}

class _HomeSection extends StatelessWidget {
  const _HomeSection({required this.child, this.top = 28, this.bottom = 0});

  final Widget child;
  final double top;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, top, 20, bottom),
          child: child,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.stat});

  final ({String value, String label, IconData icon}) stat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              stat.icon,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.value,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  stat.label,
                  maxLines: 2,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return 'SN';
  return parts.take(2).map((part) => part[0].toUpperCase()).join();
}
