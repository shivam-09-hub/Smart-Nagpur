import 'package:flutter/material.dart';
import 'package:smart_nagpur/core/theme/theme.dart';
import 'package:smart_nagpur/core/widgets/states.dart';
import 'package:smart_nagpur/domain/domain.dart';
import 'package:smart_nagpur/state/app_controller.dart';

import 'vendor_documents_screen.dart';
import 'widgets/vendor_widgets.dart';

class VendorApplicationDetailScreen extends StatefulWidget {
  const VendorApplicationDetailScreen({
    required this.controller,
    super.key,
    this.application,
    this.applicationId,
  }) : assert(application != null || applicationId != null);

  final AppController controller;
  final VendorApplication? application;
  final String? applicationId;

  @override
  State<VendorApplicationDetailScreen> createState() =>
      _VendorApplicationDetailScreenState();
}

class _VendorApplicationDetailScreenState
    extends State<VendorApplicationDetailScreen> {
  int? _selectedTimelineIndex;

  VendorApplication? get _application {
    if (widget.applicationId != null) {
      return widget.controller.vendorApplicationById(widget.applicationId!);
    }
    return widget.application;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final application = _application;
        if (application == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Application')),
            body: ErrorState(
              title: 'Application not found',
              message: 'This application is not available for this account.',
              retryLabel: 'Go back',
              onRetry: () => Navigator.maybePop(context),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Application Details'),
            actions: [
              IconButton(
                tooltip: 'About tracking status',
                onPressed: () => _showTrackingExplanation(
                  context,
                  isDemo: application.isDemo,
                ),
                icon: const Icon(Icons.info_outline_rounded),
              ),
            ],
          ),
          body: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: VendorResponsiveBody(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VendorDemoBanner(isDemo: application.isDemo),
                    const SizedBox(height: AppSpacing.md),
                    _buildSummary(application),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Application Timeline',
                      style: AppTypography.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    const Text(
                      'Tap a stage to view its details.',
                      style: AppTypography.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildTimeline(application),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Application Information',
                      style: AppTypography.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildDetails(application),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => VendorDocumentsScreen(
                                controller: widget.controller,
                                applicationId: application.id,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.folder_copy_outlined),
                        label: Text(
                          'View Documents (${application.documents.length})',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummary(VendorApplication application) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    size: 29,
                    color: AppColors.vendor,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        application.businessName,
                        style: AppTypography.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      SelectableText(
                        application.id,
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current status',
                        style: AppTypography.caption,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      VendorStatusChip(status: application.status),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Last updated', style: AppTypography.caption),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        vendorFormatDate(application.updatedAt),
                        textAlign: TextAlign.end,
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: vendorStatusColor(
                  application.status,
                ).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                _statusMessage(application),
                style: AppTypography.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(VendorApplication application) {
    if (application.timeline.isEmpty) {
      return const Text(
        'No timeline information is available.',
        style: AppTypography.bodySmall,
      );
    }
    return Column(
      children: List.generate(application.timeline.length, (index) {
        final entry = application.timeline[index];
        final selected = _selectedTimelineIndex == index;
        final color = entry.isCurrent
            ? AppColors.vendor
            : entry.isCompleted
            ? AppColors.success
            : AppColors.textMuted;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 40,
                child: Column(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: entry.isCompleted || entry.isCurrent
                            ? color
                            : AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: color, width: 2),
                      ),
                      child: Icon(
                        entry.isCompleted
                            ? Icons.check_rounded
                            : entry.isCurrent
                            ? Icons.more_horiz_rounded
                            : Icons.circle_outlined,
                        size: 17,
                        color: entry.isCompleted || entry.isCurrent
                            ? Colors.white
                            : color,
                      ),
                    ),
                    if (index < application.timeline.length - 1)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: entry.isCompleted
                              ? AppColors.success
                              : AppColors.border,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedTimelineIndex = selected ? null : index;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    entry.title,
                                    style: AppTypography.label.copyWith(
                                      color: entry.isCurrent ? color : null,
                                    ),
                                  ),
                                ),
                                Icon(
                                  selected
                                      ? Icons.expand_less_rounded
                                      : Icons.expand_more_rounded,
                                  color: AppColors.textSecondary,
                                ),
                              ],
                            ),
                            if (entry.timestamp != null) ...[
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                vendorFormatDate(entry.timestamp!),
                                style: AppTypography.caption,
                              ),
                            ],
                            AnimatedCrossFade(
                              firstChild: const SizedBox(
                                width: double.infinity,
                              ),
                              secondChild: Padding(
                                padding: const EdgeInsets.only(
                                  top: AppSpacing.sm,
                                ),
                                child: Text(
                                  entry.message ??
                                      (application.isDemo
                                          ? entry.isCompleted
                                                ? 'This demo stage is complete.'
                                                : entry.isCurrent
                                                ? 'This is the current simulated stage.'
                                                : 'This stage has not started.'
                                          : entry.isCompleted
                                          ? 'This recorded stage is complete.'
                                          : entry.isCurrent
                                          ? 'This is the current cloud status.'
                                          : 'This stage has not started.'),
                                  style: AppTypography.bodySmall,
                                ),
                              ),
                              crossFadeState: selected
                                  ? CrossFadeState.showSecond
                                  : CrossFadeState.showFirst,
                              duration: const Duration(milliseconds: 180),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDetails(VendorApplication application) {
    final details = application.details;
    return Column(
      children: [
        VendorSectionCard(
          title: 'Applicant',
          icon: Icons.person_outline_rounded,
          children: [
            VendorInfoRow(label: 'Name', value: details.applicantName),
            VendorInfoRow(label: 'Mobile', value: details.mobile),
            VendorInfoRow(label: 'Email', value: details.email),
            VendorInfoRow(label: 'Address', value: details.residentialAddress),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        VendorSectionCard(
          title: 'Business',
          icon: Icons.storefront_outlined,
          children: [
            VendorInfoRow(label: 'Type', value: details.businessType),
            VendorInfoRow(label: 'Category', value: details.category),
            VendorInfoRow(label: 'Description', value: details.description),
            VendorInfoRow(
              label: 'Products/Services',
              value: details.productsServices,
            ),
            VendorInfoRow(
              label: 'Registration No.',
              value: details.registrationNumber,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        VendorSectionCard(
          title: 'Location & Operations',
          icon: Icons.location_on_outlined,
          children: [
            VendorInfoRow(
              label: 'Address',
              value: details.location?.address ?? '',
            ),
            VendorInfoRow(
              label: 'Coordinates',
              value: details.location?.coordinates ?? '',
            ),
            VendorInfoRow(
              label: 'Preferred zone',
              value: details.preferredZone,
            ),
            VendorInfoRow(
              label: 'Operating days',
              value: details.operatingDays.join(', '),
            ),
            VendorInfoRow(
              label: 'Hours',
              value: '${details.startTime} – ${details.endTime}',
            ),
            VendorInfoRow(label: 'Duration', value: details.durationType),
            VendorInfoRow(label: 'Outlet type', value: details.outletType),
          ],
        ),
      ],
    );
  }

  String _statusMessage(VendorApplication application) {
    final message = switch (application.status) {
      VendorStatus.submitted =>
        'The application is saved at the submitted stage.',
      VendorStatus.documentsVerified =>
        'The status indicates that documents were verified.',
      VendorStatus.underReview => 'The application status is under review.',
      VendorStatus.locationAssessment =>
        'The location is at the assessment stage.',
      VendorStatus.approved => 'The application has an approved status.',
      VendorStatus.changesRequired =>
        'The status indicates that changes are required.',
      VendorStatus.rejected => 'The application has a rejected status.',
      VendorStatus.permissionIssued => 'The status shows permission issued.',
    };
    return application.isDemo
        ? '$message This is simulated local data, not a municipal decision.'
        : '$message It is stored in your cloud account, but this development service is not connected to a municipal authority.';
  }

  void _showTrackingExplanation(BuildContext context, {required bool isDemo}) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xs,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'About application tracking',
                style: AppTypography.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                isDemo
                    ? 'Timeline entries and statuses on this screen are local development data. They do not represent communication, verification, approval, rejection, or permission from a municipal authority.'
                    : 'Timeline entries and statuses are stored in your private cloud account. This development service is not connected to a municipal case-management system, so they do not represent official municipal communication, approval, rejection, or permission.',
                style: AppTypography.body,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
