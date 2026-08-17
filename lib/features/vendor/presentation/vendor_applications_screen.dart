import 'package:flutter/material.dart';
import 'package:smart_nagpur/core/theme/theme.dart';
import 'package:smart_nagpur/core/widgets/states.dart';
import 'package:smart_nagpur/domain/domain.dart';
import 'package:smart_nagpur/state/app_controller.dart';

import 'vendor_application_detail_screen.dart';
import 'vendor_application_screen.dart';
import 'widgets/vendor_widgets.dart';

enum VendorApplicationFilter { all, active, completed }

class VendorApplicationsScreen extends StatefulWidget {
  const VendorApplicationsScreen({
    required this.controller,
    super.key,
    this.showAppBar = true,
  });

  final AppController controller;
  final bool showAppBar;

  @override
  State<VendorApplicationsScreen> createState() =>
      _VendorApplicationsScreenState();
}

class _VendorApplicationsScreenState extends State<VendorApplicationsScreen> {
  final _searchController = TextEditingController();
  VendorApplicationFilter _filter = VendorApplicationFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final applications = _filteredApplications;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.sm,
                AppSpacing.page,
                0,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    children: [
                      VendorDemoBanner(isDemo: widget.controller.isDemoMode),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          labelText: 'Search applications',
                          hintText: 'Application ID or business name',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _searchController.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Clear search',
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<VendorApplicationFilter>(
                          segments: const [
                            ButtonSegment(
                              value: VendorApplicationFilter.all,
                              label: Text('All'),
                            ),
                            ButtonSegment(
                              value: VendorApplicationFilter.active,
                              label: Text('Active'),
                            ),
                            ButtonSegment(
                              value: VendorApplicationFilter.completed,
                              label: Text('Closed'),
                            ),
                          ],
                          selected: {_filter},
                          showSelectedIcon: false,
                          onSelectionChanged: (selection) {
                            setState(() => _filter = selection.first);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: applications.isEmpty
                  ? EmptyState(
                      icon: Icons.assignment_outlined,
                      title: _searchController.text.trim().isEmpty
                          ? 'No applications here'
                          : 'No matching applications',
                      message: _searchController.text.trim().isEmpty
                          ? widget.controller.isDemoMode
                                ? 'Start a demo application to see it here.'
                                : 'Applications you submit will appear here.'
                          : 'Try a different ID, business name, or filter.',
                      actionLabel: _searchController.text.trim().isEmpty
                          ? 'Start application'
                          : 'Clear filters',
                      onAction: _searchController.text.trim().isEmpty
                          ? _startApplication
                          : () {
                              _searchController.clear();
                              setState(() {
                                _filter = VendorApplicationFilter.all;
                              });
                            },
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.page,
                        AppSpacing.xs,
                        AppSpacing.page,
                        104,
                      ),
                      itemCount: applications.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) => Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 760),
                          child: _VendorApplicationCard(
                            application: applications[index],
                            onTap: () => _openApplication(applications[index]),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );

    if (!widget.showAppBar) return content;
    return Scaffold(
      appBar: AppBar(title: const Text('Vendor Applications')),
      body: SafeArea(top: false, child: content),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startApplication,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Application'),
      ),
    );
  }

  List<VendorApplication> get _filteredApplications {
    final query = _searchController.text.trim().toLowerCase();
    final applications = widget.controller.vendorApplications.where((
      application,
    ) {
      final inFilter = switch (_filter) {
        VendorApplicationFilter.all => true,
        VendorApplicationFilter.active =>
          application.status != VendorStatus.rejected &&
              application.status != VendorStatus.permissionIssued,
        VendorApplicationFilter.completed =>
          application.status == VendorStatus.rejected ||
              application.status == VendorStatus.permissionIssued,
      };
      if (!inFilter) return false;
      if (query.isEmpty) return true;
      return application.id.toLowerCase().contains(query) ||
          application.businessName.toLowerCase().contains(query) ||
          application.applicantName.toLowerCase().contains(query);
    }).toList();
    applications.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return applications;
  }

  void _startApplication() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VendorApplicationScreen(controller: widget.controller),
      ),
    );
  }

  void _openApplication(VendorApplication application) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VendorApplicationDetailScreen(
          controller: widget.controller,
          application: application,
        ),
      ),
    );
  }
}

class _VendorApplicationCard extends StatelessWidget {
  const _VendorApplicationCard({
    required this.application,
    required this.onTap,
  });

  final VendorApplication application;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:
          '${application.businessName}, ${application.id}, status ${application.status.label}',
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: AppColors.vendor,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            application.businessName,
                            style: AppTypography.title,
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(application.id, style: AppTypography.caption),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    VendorStatusChip(status: application.status),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    const Icon(
                      Icons.category_outlined,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        application.category.isEmpty
                            ? 'Uncategorised'
                            : application.category,
                        style: AppTypography.bodySmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    const Icon(
                      Icons.update_rounded,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Updated ${vendorFormatDate(application.updatedAt)}',
                        style: AppTypography.bodySmall,
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
