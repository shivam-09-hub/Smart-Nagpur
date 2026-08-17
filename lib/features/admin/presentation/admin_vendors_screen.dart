import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_nagpur/core/theme/theme.dart';
import 'package:smart_nagpur/core/widgets/states.dart';
import 'package:smart_nagpur/domain/domain.dart';
import 'package:smart_nagpur/state/admin_controller.dart';

class AdminVendorsScreen extends StatefulWidget {
  const AdminVendorsScreen({required this.controller, super.key});

  final AdminController controller;

  @override
  State<AdminVendorsScreen> createState() => _AdminVendorsScreenState();
}

class _AdminVendorsScreenState extends State<AdminVendorsScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.loadPendingApplications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Applications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => widget.controller.loadPendingApplications(),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          if (widget.controller.isLoading &&
              widget.controller.pendingApplications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final applications = widget.controller.pendingApplications;
          if (applications.isEmpty) {
            return EmptyState(
              icon: Icons.store_mall_directory,
              title: 'No pending applications',
              message: 'All vendor applications have been reviewed',
            );
          }

          return RefreshIndicator(
            onRefresh: () => widget.controller.loadPendingApplications(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
              itemCount: applications.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _VendorApplicationTile(
                application: applications[index],
                controller: widget.controller,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _VendorApplicationTile extends StatelessWidget {
  const _VendorApplicationTile({
    required this.application,
    required this.controller,
  });

  final VendorApplication application;
  final AdminController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: application.status != VendorStatus.rejected
          ? AppColors.info.withValues(alpha: 0.06)
          : Theme.of(context).colorScheme.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () => Navigator.of(
          context,
        ).pushNamed('/admin/vendor-detail', arguments: application.id),
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
                      color: AppColors.info.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.store, color: AppColors.info),
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
                                'App #${application.id}',
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
                                  application.status,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                application.status.label,
                                style: TextStyle(
                                  color: _getStatusColor(application.status),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          application.details.businessName,
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

              // Business info
              Text(
                'Applicant: ${application.details.applicantName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                application.details.category,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),

              // Metadata
              Row(
                children: [
                  Icon(Icons.phone, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      application.details.mobile,
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
                    DateFormat('dd MMM').format(application.createdAt),
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

  Color _getStatusColor(VendorStatus status) {
    return switch (status) {
      VendorStatus.submitted => AppColors.info,
      VendorStatus.documentsVerified => AppColors.info,
      VendorStatus.underReview => AppColors.warning,
      VendorStatus.locationAssessment => AppColors.warning,
      VendorStatus.approved => AppColors.success,
      VendorStatus.permissionIssued => AppColors.success,
      VendorStatus.rejected => AppColors.error,
      VendorStatus.changesRequired => AppColors.warning,
    };
  }
}
