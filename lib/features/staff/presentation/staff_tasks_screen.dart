import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_nagpur/core/theme/theme.dart';
import 'package:smart_nagpur/domain/domain.dart';
import 'package:smart_nagpur/features/staff/presentation/staff_task_detail_screen.dart';
import 'package:smart_nagpur/state/staff_controller.dart';

class StaffTasksScreen extends StatefulWidget {
  const StaffTasksScreen({required this.controller, super.key});

  final StaffController controller;

  @override
  State<StaffTasksScreen> createState() => _StaffTasksScreenState();
}

class _StaffTasksScreenState extends State<StaffTasksScreen> {
  AssignmentStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.loadMyTasks();
    });
  }

  Color _getPriorityColor(AssignmentPriority priority) {
    return switch (priority) {
      AssignmentPriority.urgent => AppColors.error,
      AssignmentPriority.high => AppColors.warning,
      AssignmentPriority.medium => AppColors.info,
      AssignmentPriority.low => AppColors.textSecondary,
    };
  }

  Color _getStatusColor(AssignmentStatus status) {
    return switch (status) {
      AssignmentStatus.assigned => AppColors.primary,
      AssignmentStatus.accepted => AppColors.info,
      AssignmentStatus.inProgress => AppColors.warning,
      AssignmentStatus.completed => AppColors.info,
      AssignmentStatus.reworkRequired => AppColors.error,
      AssignmentStatus.approved => AppColors.success,
      AssignmentStatus.reassigned => AppColors.textSecondary,
      AssignmentStatus.cancelled => AppColors.error,
    };
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMM, hh:mm a');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Tasks'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            final allTasks = widget.controller.myTasks;
            final filteredTasks = _filterStatus == null
                ? allTasks
                : allTasks.where((t) => t.status == _filterStatus).toList();

            return RefreshIndicator(
              onRefresh: widget.controller.loadMyTasks,
              child: CustomScrollView(
                slivers: [
                  // 1. Status Filter Chips
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.page,
                        vertical: AppSpacing.md,
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip(
                              label: 'All (${allTasks.length})',
                              isSelected: _filterStatus == null,
                              onSelected: () => setState(() => _filterStatus = null),
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              label: 'Pending (${widget.controller.pendingTasksCount})',
                              isSelected: _filterStatus == AssignmentStatus.assigned,
                              onSelected: () => setState(() => _filterStatus = AssignmentStatus.assigned),
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              label: 'Accepted (${widget.controller.acceptedTasksCount})',
                              isSelected: _filterStatus == AssignmentStatus.accepted,
                              onSelected: () => setState(() => _filterStatus = AssignmentStatus.accepted),
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              label: 'In Progress (${widget.controller.inProgressTasksCount})',
                              isSelected: _filterStatus == AssignmentStatus.inProgress,
                              onSelected: () => setState(() => _filterStatus = AssignmentStatus.inProgress),
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              label: 'Completed (${widget.controller.completedTasksCount})',
                              isSelected: _filterStatus == AssignmentStatus.completed,
                              onSelected: () => setState(() => _filterStatus = AssignmentStatus.completed),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 2. Loading State
                  if (widget.controller.isLoadingTasks && allTasks.isEmpty)
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  // 3. Empty State
                  else if (filteredTasks.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xxl),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: const BoxDecoration(
                                  color: AppColors.surfaceMuted,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.assignment_turned_in_outlined,
                                  size: 36,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                _filterStatus == null ? 'No tasks assigned yet' : 'No ${_filterStatus!.label} tasks',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'When municipal administrators assign complaints to your department, they will appear here in real-time.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  // 4. Task Cards List
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.page,
                        vertical: AppSpacing.sm,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final task = filteredTasks[index];
                            final priorityColor = _getPriorityColor(task.priority);
                            final statusColor = _getStatusColor(task.status);

                            return Card(
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: AppSpacing.md),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                side: BorderSide(
                                  color: task.priority == AssignmentPriority.urgent
                                      ? AppColors.error.withValues(alpha: 0.6)
                                      : AppColors.border,
                                  width: task.priority == AssignmentPriority.urgent ? 1.5 : 1.0,
                                ),
                              ),
                              color: AppColors.surface,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => StaffTaskDetailScreen(
                                        controller: widget.controller,
                                        task: task,
                                      ),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.lg),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Top Badges Row
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: priorityColor.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(AppRadius.xs),
                                              border: Border.all(color: priorityColor.withValues(alpha: 0.4)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.flag_rounded, size: 12, color: priorityColor),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${task.priority.label.toUpperCase()} PRIORITY',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    color: priorityColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: statusColor.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(AppRadius.xs),
                                            ),
                                            child: Text(
                                              task.status.label,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: statusColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: AppSpacing.md),

                                      // Task Issue Title
                                      Text(
                                        task.complaintIssue ?? 'Civic Complaint Task',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      if (task.complaintDescription != null &&
                                          task.complaintDescription!.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          task.complaintDescription!,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: AppSpacing.md),

                                      // Admin Directives snippet if present
                                      if (task.instructions.isNotEmpty) ...[
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppColors.infoSoft,
                                            borderRadius: BorderRadius.circular(AppRadius.xs),
                                          ),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Icon(Icons.campaign_rounded, size: 14, color: AppColors.info),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  task.instructions,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                    color: AppColors.info,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: AppSpacing.md),
                                      ],

                                      const Divider(height: 1, color: AppColors.divider),
                                      const SizedBox(height: AppSpacing.sm),

                                      // Location & Timestamp Footer
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    task.complaintLocationAddress ?? 'Nagpur Municipal Area',
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: AppColors.textSecondary,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            dateFormat.format(task.assignedAt),
                                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          childCount: filteredTasks.length,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.primarySoft,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
        ),
      ),
    );
  }
}
