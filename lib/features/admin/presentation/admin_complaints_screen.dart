import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_nagpur/core/theme/theme.dart';
import 'package:smart_nagpur/core/widgets/states.dart';
import 'package:smart_nagpur/domain/domain.dart';
import 'package:smart_nagpur/state/admin_controller.dart';

class AdminComplaintsScreen extends StatefulWidget {
  const AdminComplaintsScreen({required this.controller, super.key});

  final AdminController controller;

  @override
  State<AdminComplaintsScreen> createState() => _AdminComplaintsScreenState();
}

class _AdminComplaintsScreenState extends State<AdminComplaintsScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.loadPendingComplaints();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaint Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => widget.controller.loadPendingComplaints(),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          if (widget.controller.isLoading &&
              widget.controller.pendingComplaints.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final complaints = widget.controller.pendingComplaints;
          if (complaints.isEmpty) {
            return EmptyState(
              icon: Icons.assignment_turned_in,
              title: 'No pending complaints',
              message: 'All complaints have been reviewed',
            );
          }

          return RefreshIndicator(
            onRefresh: () => widget.controller.loadPendingComplaints(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
              itemCount: complaints.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _ComplaintTile(
                complaint: complaints[index],
                controller: widget.controller,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ComplaintTile extends StatelessWidget {
  const _ComplaintTile({required this.complaint, required this.controller});

  final ComplaintRecord complaint;
  final AdminController controller;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _getServiceIcon(complaint.serviceType);

    return Card(
      margin: EdgeInsets.zero,
      color: complaint.status.isActive
          ? color.withValues(alpha: 0.06)
          : Theme.of(context).colorScheme.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () => Navigator.of(
          context,
        ).pushNamed('/admin/complaint-detail', arguments: complaint.id),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Complaint #${complaint.id}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  complaint.status,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                complaint.status.label,
                                style: TextStyle(
                                  color: _getStatusColor(complaint.status),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          complaint.issue,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Details
              Text(
                complaint.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),

              // Metadata
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      complaint.location.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd MMM').format(complaint.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  (IconData, Color) _getServiceIcon(ServiceType type) {
    return switch (type) {
      ServiceType.vendor => (Icons.store, AppColors.primary),
      ServiceType.garbage => (Icons.delete_outline, AppColors.success),
      ServiceType.water => (Icons.water_drop, AppColors.info),
      ServiceType.roads => (Icons.directions_car, AppColors.warning),
      ServiceType.animals => (Icons.pets, AppColors.secondary),
      ServiceType.drainage => (Icons.water_damage, AppColors.info),
      ServiceType.streetlights => (Icons.light, AppColors.warning),
      ServiceType.publicSpaces => (Icons.public, AppColors.secondary),
      ServiceType.encroachment => (Icons.warning, AppColors.error),
      ServiceType.other => (Icons.help, AppColors.textSecondary),
    };
  }

  Color _getStatusColor(ComplaintStatus status) {
    return switch (status) {
      ComplaintStatus.submitted => AppColors.info,
      ComplaintStatus.underReview => AppColors.warning,
      ComplaintStatus.assigned => AppColors.primary,
      ComplaintStatus.inProgress => AppColors.warning,
      ComplaintStatus.resolved => AppColors.success,
      ComplaintStatus.rejected => AppColors.error,
      ComplaintStatus.moreInformationRequired => AppColors.warning,
    };
  }
}
