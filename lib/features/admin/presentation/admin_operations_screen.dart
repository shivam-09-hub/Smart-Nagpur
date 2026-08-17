import 'package:flutter/material.dart';
import 'package:smart_nagpur/core/theme/theme.dart';
import 'package:smart_nagpur/domain/domain.dart';
import 'package:smart_nagpur/state/admin_controller.dart';

class AdminOperationsScreen extends StatefulWidget {
  const AdminOperationsScreen({required this.controller, super.key});

  final AdminController controller;

  @override
  State<AdminOperationsScreen> createState() => _AdminOperationsScreenState();
}

class _AdminOperationsScreenState extends State<AdminOperationsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    widget.controller.loadOperationsDashboard();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Field Operations & Verification'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => widget.controller.loadOperationsDashboard(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: [
            ListenableBuilder(
              listenable: widget.controller,
              builder: (context, _) {
                final count = widget.controller.operationsDashboard?.awaitingVerificationCount ?? 0;
                return Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Verification Queue'),
                      if (count > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.warning,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            const Tab(text: 'Staff Workload'),
            const Tab(text: 'Workload Breakdown'),
          ],
        ),
      ),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          if (widget.controller.isLoading && widget.controller.operationsDashboard == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final dashboard = widget.controller.operationsDashboard;
          if (dashboard == null && widget.controller.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                    const SizedBox(height: 12),
                    Text(
                      widget.controller.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.error),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => widget.controller.loadOperationsDashboard(),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              // Filter Bar
              _buildFilterBar(),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildVerificationQueueTab(dashboard?.verificationQueue ?? []),
                    _buildStaffWorkloadTab(
                      dashboard?.staffWorkloadSummary ?? const StaffWorkloadSummary(),
                      dashboard?.staffWorkloads ?? [],
                    ),
                    _buildWorkloadBreakdownTab(
                      dashboard?.complaintsByStatus ?? {},
                      dashboard?.assignmentsByStatus ?? {},
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterBar() {
    final currentFilter = widget.controller.operationsFilter;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Department Filter
            DropdownButton<String>(
              value: currentFilter.department?.code ?? 'ALL',
              hint: const Text('Department'),
              underline: const SizedBox(),
              icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
              style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
              items: const [
                DropdownMenuItem(value: 'ALL', child: Text('All Departments')),
                DropdownMenuItem(value: 'ROAD', child: Text('Roads & Potholes')),
                DropdownMenuItem(value: 'WASTE', child: Text('Waste Management')),
                DropdownMenuItem(value: 'WATER', child: Text('Water Supply')),
                DropdownMenuItem(value: 'VENDOR', child: Text('Street Vendors')),
                DropdownMenuItem(value: 'GENERAL', child: Text('General Civic')),
              ],
              onChanged: (val) {
                final dept = val == null || val == 'ALL' ? null : StaffDepartment.fromCode(val);
                widget.controller.setOperationsFilter(
                  currentFilter.copyWith(department: dept, clearDepartment: dept == null),
                );
              },
            ),
            const SizedBox(width: 8),

            // Priority Filter
            DropdownButton<String>(
              value: currentFilter.priority?.name ?? 'ALL',
              hint: const Text('Priority'),
              underline: const SizedBox(),
              icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
              style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
              items: const [
                DropdownMenuItem(value: 'ALL', child: Text('All Priorities')),
                DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                DropdownMenuItem(value: 'high', child: Text('High')),
                DropdownMenuItem(value: 'medium', child: Text('Medium')),
                DropdownMenuItem(value: 'low', child: Text('Low')),
              ],
              onChanged: (val) {
                final p = val == null || val == 'ALL' ? null : AssignmentPriority.fromCode(val);
                widget.controller.setOperationsFilter(
                  currentFilter.copyWith(priority: p, clearPriority: p == null),
                );
              },
            ),
            const SizedBox(width: 8),

            // Clear Filter
            if (currentFilter.hasActiveFilter)
              ActionChip(
                avatar: const Icon(Icons.close_rounded, size: 14, color: AppColors.textSecondary),
                label: const Text('Reset', style: TextStyle(fontSize: 11)),
                backgroundColor: AppColors.surfaceMuted,
                onPressed: () => widget.controller.clearOperationsFilter(),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 1: Verification Queue
  // ---------------------------------------------------------------------------
  Widget _buildVerificationQueueTab(List<VerificationQueueItem> queue) {
    if (queue.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.successSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline_rounded, size: 48, color: AppColors.success),
              ),
              const SizedBox(height: 16),
              const Text(
                'Verification Queue Clear',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              const Text(
                'No field work is currently awaiting supervisor or admin verification.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: queue.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final item = queue[index];
        return _buildVerificationQueueCard(item);
      },
    );
  }

  Widget _buildVerificationQueueCard(VerificationQueueItem item) {
    final theme = Theme.of(context);

    final priorityColor = switch (item.priority) {
      AssignmentPriority.urgent => AppColors.error,
      AssignmentPriority.high => Colors.deepOrange,
      AssignmentPriority.medium => Colors.amber.shade800,
      AssignmentPriority.low => Colors.blueGrey,
    };

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: AppColors.border),
      ),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Priority & Completed Time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                    border: Border.all(color: priorityColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    item.priority.label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: priorityColor,
                    ),
                  ),
                ),
                Text(
                  'Completed ${item.formattedCompletedAgo}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Complaint Issue & Address
            Text(
              item.issue,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.place_outlined, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.complaintAddress,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Technician Details
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 14, color: AppColors.textPrimary),
                      const SizedBox(width: 6),
                      Text(
                        item.staffName,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      if (item.staffEmployeeId.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Text(
                          '(${item.staffEmployeeId})',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ],
                  ),
                  if (item.technicianNotes.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Notes: "${item.technicianNotes}"',
                      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Evidence & GPS Badges
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                // GPS Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: item.isGeoVerified ? AppColors.successSoft : AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                    border: Border.all(
                      color: item.isGeoVerified ? AppColors.success : AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.isGeoVerified ? Icons.check_circle_rounded : Icons.location_off_rounded,
                        size: 12,
                        color: item.isGeoVerified ? AppColors.success : AppColors.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.isGeoVerified ? 'GPS Verified' : 'GPS Unverified',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: item.isGeoVerified ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),

                // Before Photo
                _buildEvidenceChip(
                  label: 'Before Photo',
                  isPresent: item.hasBeforePhoto,
                  icon: Icons.camera_alt_outlined,
                ),

                // After Photo
                _buildEvidenceChip(
                  label: 'After Photo',
                  isPresent: item.hasAfterPhoto,
                  icon: Icons.check_circle_outline,
                ),

                // Inspection PDF
                if (item.hasInspectionPdf)
                  _buildEvidenceChip(
                    label: 'Inspection PDF',
                    isPresent: true,
                    icon: Icons.picture_as_pdf_outlined,
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Action Button: Review & Verify
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    '/admin/complaint-detail',
                    arguments: item.complaintId,
                  );
                },
                icon: const Icon(Icons.rate_review_outlined, size: 16),
                label: const Text('Review Field Evidence & Verify', style: TextStyle(fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvidenceChip({
    required String label,
    required bool isPresent,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isPresent ? AppColors.surfaceMuted : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(AppRadius.xs),
        border: Border.all(
          color: isPresent ? AppColors.border : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: isPresent ? AppColors.textPrimary : Colors.grey),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isPresent ? AppColors.textPrimary : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 2: Staff Workload
  // ---------------------------------------------------------------------------
  Widget _buildStaffWorkloadTab(StaffWorkloadSummary summary, List<StaffWorkloadItem> staffList) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Workload Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryMetricCard(
                  'On Duty',
                  '${summary.onDutyStaff} / ${summary.activeStaff}',
                  Icons.badge_outlined,
                  AppColors.success,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryMetricCard(
                  'In Progress',
                  '${summary.inProgressTasks}',
                  Icons.construction_rounded,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryMetricCard(
                  'Pending',
                  '${summary.pendingTasks}',
                  Icons.schedule_rounded,
                  Colors.amber.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          const Text(
            'Field Technicians & Supervisors',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.md),

          if (staffList.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No staff members found for the selected filter.', style: TextStyle(color: AppColors.textSecondary)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: staffList.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final staff = staffList[index];
                return _buildStaffItemCard(staff);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffItemCard(StaffWorkloadItem staff) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        side: const BorderSide(color: AppColors.border),
      ),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: staff.isOnDuty ? AppColors.successSoft : AppColors.surfaceMuted,
              child: Icon(
                staff.isOnDuty ? Icons.work_rounded : Icons.work_off_outlined,
                size: 16,
                color: staff.isOnDuty ? AppColors.success : AppColors.textMuted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    staff.name,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${staff.department.label} • ${staff.employeeId}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: staff.isOnDuty ? AppColors.successSoft : AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    staff.isOnDuty ? 'ON DUTY' : 'OFF DUTY',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: staff.isOnDuty ? AppColors.success : AppColors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${staff.activeTaskCount} active tasks',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: staff.activeTaskCount > 0 ? AppColors.primary : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 3: Workload Breakdown
  // ---------------------------------------------------------------------------
  Widget _buildWorkloadBreakdownTab(Map<String, int> compMap, Map<String, int> assignMap) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Complaint Lifecycle Breakdown',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.md),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildBreakdownChip('Submitted (New)', compMap['submitted'] ?? 0, Colors.blue),
              _buildBreakdownChip('Assigned', compMap['assigned'] ?? 0, Colors.indigo),
              _buildBreakdownChip('In Progress', compMap['inProgress'] ?? 0, Colors.orange),
              _buildBreakdownChip('Under Verification', compMap['underReview'] ?? 0, Colors.amber.shade800),
              _buildBreakdownChip('Rework Required', compMap['reworkRequired'] ?? 0, Colors.red),
              _buildBreakdownChip('Resolved', compMap['resolved'] ?? 0, Colors.teal),
              _buildBreakdownChip('Rejected', compMap['rejected'] ?? 0, Colors.grey),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          const Text(
            'Field Assignment Breakdown',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.md),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildBreakdownChip('Pending Acceptance', assignMap['assigned'] ?? 0, Colors.blueGrey),
              _buildBreakdownChip('Accepted', assignMap['accepted'] ?? 0, Colors.blue),
              _buildBreakdownChip('In Progress', assignMap['inProgress'] ?? 0, Colors.orange),
              _buildBreakdownChip('Completed (Work Submitted)', assignMap['completed'] ?? 0, Colors.amber.shade800),
              _buildBreakdownChip('Rework Required', assignMap['reworkRequired'] ?? 0, Colors.red),
              _buildBreakdownChip('Approved', assignMap['approved'] ?? 0, Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownChip(String title, int count, Color color) {
    return Container(
      width: (MediaQuery.of(context).size.width - 40) / 2,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ),
          Text(
            '$count',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
