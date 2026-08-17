import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_nagpur/core/theme/theme.dart';
import 'package:smart_nagpur/domain/domain.dart';
import 'package:smart_nagpur/state/admin_controller.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({required this.controller, super.key});

  final AdminController controller;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.controller.loadAdminStats();
        widget.controller.loadOperationsDashboard();
      }
    });
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      widget.controller.loadAdminStats(),
      widget.controller.loadOperationsDashboard(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAll,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                widget.controller.logoutAdmin();
                Navigator.of(context).pushReplacementNamed('/admin/login');
              } else if (value == 'profile') {
                Navigator.of(context).pushNamed('/admin/profile');
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person),
                    SizedBox(width: 8),
                    Text('Profile'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          if (widget.controller.isLoading &&
              widget.controller.adminStats == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final stats = widget.controller.adminStats;
          if (stats == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(widget.controller.error ?? 'Failed to load stats'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _refreshAll,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshAll,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildHeader(),
                  const SizedBox(height: 20),

                  // Operations & Verification Banner
                  _buildOperationsBanner(),
                  const SizedBox(height: 24),

                  // Key metrics
                  _buildMetricsSection(stats),
                  const SizedBox(height: 24),

                  // Complaint metrics
                  if (widget.controller.canReviewComplaints)
                    _buildComplaintSection(stats),
                  const SizedBox(height: 24),

                  // Vendor metrics
                  if (widget.controller.canReviewVendors)
                    _buildVendorSection(stats),
                  const SizedBox(height: 24),

                  // Quick actions
                  _buildQuickActions(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }


  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back, ${widget.controller.currentAdmin?.name}',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          '${widget.controller.currentAdmin?.role.label} • Last login: ${_formatDate(widget.controller.currentAdmin?.lastLoginAt)}',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildOperationsBanner() {
    final ops = widget.controller.operationsDashboard;
    final queueCount = ops?.awaitingVerificationCount ?? 0;
    final onDutyStaff = ops?.staffWorkloadSummary.onDutyStaff ?? 0;
    final inProgressTasks = ops?.staffWorkloadSummary.inProgressTasks ?? 0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: queueCount > 0 ? AppColors.warning.withValues(alpha: 0.6) : AppColors.border,
          width: queueCount > 0 ? 1.5 : 1.0,
        ),
      ),
      color: queueCount > 0 ? AppColors.warning.withValues(alpha: 0.06) : AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: queueCount > 0 ? AppColors.warning.withValues(alpha: 0.15) : AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: Icon(
                    Icons.fact_check_outlined,
                    size: 20,
                    color: queueCount > 0 ? AppColors.warning : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Field Operations & Verification',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        queueCount > 0
                            ? '$queueCount complaints submitted for verification'
                            : '$onDutyStaff staff on duty • $inProgressTasks active field tasks',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: queueCount > 0 ? FontWeight.w600 : FontWeight.normal,
                          color: queueCount > 0 ? AppColors.warning : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pushNamed('/admin/operations'),
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: Text(
                  queueCount > 0
                      ? 'Open Verification Queue ($queueCount)'
                      : 'View Field Operations & Staff Workload',
                  style: const TextStyle(fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: queueCount > 0 ? AppColors.warning : AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsSection(AdminStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Overview',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Total Users',
                value: stats.totalUsers.toString(),
                subtitle: '${stats.activeUsers} active',
                icon: Icons.people,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Total Complaints',
                value: stats.totalComplaints.toString(),
                subtitle: '${stats.pendingComplaints} pending',
                icon: Icons.report,
                color: AppColors.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Vendor Apps',
                value: stats.totalVendorApplications.toString(),
                subtitle: '${stats.pendingApplications} pending',
                icon: Icons.store,
                color: AppColors.info,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Notifications',
                value: stats.totalNotifications.toString(),
                subtitle: '${stats.unreadNotifications} unread',
                icon: Icons.notifications,
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildComplaintSection(AdminStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Complaint Management',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem(
                      'Submitted',
                      stats.totalComplaints.toString(),
                      AppColors.primary,
                    ),
                    _buildStatItem(
                      'Pending',
                      stats.pendingComplaints.toString(),
                      AppColors.warning,
                    ),
                    _buildStatItem(
                      'Resolved',
                      stats.resolvedComplaints.toString(),
                      AppColors.success,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: stats.complaintResolutionRate / 100,
                  minHeight: 8,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.success),
                ),
                const SizedBox(height: 8),
                Text(
                  'Resolution Rate: ${stats.complaintResolutionRate.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVendorSection(AdminStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vendor Management',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem(
                      'Total',
                      stats.totalVendorApplications.toString(),
                      AppColors.primary,
                    ),
                    _buildStatItem(
                      'Pending',
                      stats.pendingApplications.toString(),
                      AppColors.warning,
                    ),
                    _buildStatItem(
                      'Approved',
                      stats.approvedApplications.toString(),
                      AppColors.success,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: stats.vendorApprovalRate / 100,
                  minHeight: 8,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.success),
                ),
                const SizedBox(height: 8),
                Text(
                  'Approval Rate: ${stats.vendorApprovalRate.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildActionButton(
              icon: Icons.fact_check_outlined,
              label: 'Field Operations',
              color: AppColors.primary,
              onTap: () =>
                  Navigator.of(context).pushNamed('/admin/operations'),
            ),
            if (widget.controller.canReviewComplaints)
              _buildActionButton(
                icon: Icons.assignment_turned_in,
                label: 'Review Complaints',
                color: AppColors.warning,
                onTap: () =>
                    Navigator.of(context).pushNamed('/admin/complaints'),
              ),
            if (widget.controller.canReviewVendors)
              _buildActionButton(
                icon: Icons.store_outlined,
                label: 'Review Vendors',
                color: AppColors.info,
                onTap: () => Navigator.of(context).pushNamed('/admin/vendors'),
              ),
            if (widget.controller.canManageNotifications)
              _buildActionButton(
                icon: Icons.notifications_active,
                label: 'Send Notification',
                color: AppColors.secondary,
                onTap: () =>
                    Navigator.of(context).pushNamed('/admin/notifications'),
              ),
            if (widget.controller.canManageUsers)
              _buildActionButton(
                icon: Icons.people_alt,
                label: 'Manage Users',
                color: AppColors.primary,
                onTap: () => Navigator.of(context).pushNamed('/admin/users'),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        value,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(icon, size: 32, color: color.withValues(alpha: 0.5)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Never';
    return DateFormat('dd MMM, hh:mm a').format(date.toLocal());
  }
}
