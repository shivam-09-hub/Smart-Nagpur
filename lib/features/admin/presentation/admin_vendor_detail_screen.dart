import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_nagpur/core/theme/theme.dart';
import 'package:smart_nagpur/core/widgets/app_photo_gallery.dart';
import 'package:smart_nagpur/domain/domain.dart';
import 'package:smart_nagpur/features/complaints/presentation/widgets/development_map.dart';
import 'package:smart_nagpur/state/admin_controller.dart';

class AdminVendorDetailScreen extends StatefulWidget {
  const AdminVendorDetailScreen({
    required this.controller,
    required this.applicationId,
    super.key,
  });

  final AdminController controller;
  final String applicationId;

  @override
  State<AdminVendorDetailScreen> createState() =>
      _AdminVendorDetailScreenState();
}

class _AdminVendorDetailScreenState extends State<AdminVendorDetailScreen> {
  VendorApplication? _application;
  bool _isLoading = true;
  VendorStatus? _selectedStatus;
  final _notesController = TextEditingController();
  final _commentsController = TextEditingController();
  int _selectedRating = 5;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _commentsController.dispose();
    super.dispose();
  }

  Future<void> _loadDetails() async {
    setState(() => _isLoading = true);
    final application =
        await widget.controller.getApplicationDetails(widget.applicationId);
    if (mounted) {
      setState(() {
        _application = application;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus() async {
    if (_selectedStatus == null || _application == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a new status')),
      );
      return;
    }

    final success = await widget.controller.updateApplicationStatus(
      _application!.id,
      _selectedStatus!,
      _notesController.text.trim(),
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status updated successfully')),
      );
      _notesController.clear();
      _loadDetails();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.controller.error ?? 'Failed to update application status',
          ),
        ),
      );
    }
  }

  Future<void> _submitReview() async {
    if (_commentsController.text.trim().isEmpty || _application == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter review comments')),
      );
      return;
    }

    final currentAdmin = widget.controller.currentAdmin;
    if (currentAdmin == null) return;

    final review = AdminReview(
      id: 'rev_${DateTime.now().millisecondsSinceEpoch}',
      itemType: 'application',
      itemId: _application!.id,
      reviewedBy: currentAdmin.id,
      status: ReviewStatus.approved,
      comments: _commentsController.text.trim(),
      rating: _selectedRating,
      createdAt: DateTime.now(),
    );

    final success = await widget.controller.submitApplicationReview(
      _application!.id,
      review,
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted successfully')),
      );
      _commentsController.clear();
      _loadDetails();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.controller.error ?? 'Failed to submit review',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Vendor Application')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final application = _application;
    if (application == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Vendor Application')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              const Text('Application not found'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDetails,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final details = application.details;

    return Scaffold(
      appBar: AppBar(
        title: Text('Application #${application.id}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDetails,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            _buildHeaderCard(application),
            const SizedBox(height: 20),

            // Business Information
            _buildSection(
              title: 'Business Information',
              children: [
                _buildInfoRow('Business Name', details.businessName),
                _buildInfoRow('Business Type', details.businessType),
                _buildInfoRow('Category', details.category),
                _buildInfoRow('Outlet Type', details.outletType),
                _buildInfoRow('Duration Type', details.durationType),
                _buildInfoRow('Preferred Zone', details.preferredZone),
                _buildInfoRow('Description', details.description),
                _buildInfoRow('Products / Services', details.productsServices),
                if (details.registrationNumber.isNotEmpty)
                  _buildInfoRow('Registration No.', details.registrationNumber),
                _buildInfoRow(
                  'Operating Hours',
                  '${details.startTime} - ${details.endTime}',
                ),
                _buildInfoRow(
                  'Operating Days',
                  details.operatingDays.join(', '),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Applicant Contact Information
            _buildSection(
              title: 'Applicant Details',
              children: [
                _buildInfoRow('Full Name', details.applicantName),
                _buildInfoRow('Mobile Phone', details.mobile),
                _buildInfoRow('Email Address', details.email),
                _buildInfoRow('Residential Address', details.residentialAddress),
                _buildInfoRow('Identity Proof', details.identityInformation),
              ],
            ),
            const SizedBox(height: 20),

            // Location
            _buildSection(
              title: 'Vending Location',
              children: [
                if (details.location != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      height: 200,
                      width: double.infinity,
                      child: DevelopmentMap(
                        location: details.location!,
                        isEditable: false,
                        aspectRatio: 1.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Icon(Icons.location_on, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            details.location?.address ?? 'No specific address provided',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          if (details.location != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              details.location!.coordinates,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Documents & Photos
            if (details.documents.isNotEmpty) ...[
              _buildSection(
                title: 'Attached Documents & Photos (${details.documents.length})',
                children: [
                  ...details.documents.map((doc) {
                    final hasImage = doc.path.isNotEmpty;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                hasImage ? Icons.image : Icons.description,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  doc.label.isNotEmpty ? doc.label : doc.type,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
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
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  doc.requirement.name,
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (hasImage) ...[
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: () {
                                showDialog<void>(
                                  context: context,
                                  barrierColor: Colors.black87,
                                  builder: (context) => Dialog.fullscreen(
                                    backgroundColor: Colors.transparent,
                                    child: Stack(
                                      children: [
                                        InteractiveViewer(
                                          minScale: 0.5,
                                          maxScale: 4.0,
                                          child: Center(
                                            child: AppImageWidget(
                                              path: doc.path,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 40,
                                          right: 20,
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 30,
                                            ),
                                            onPressed: () =>
                                                Navigator.of(context).pop(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: SizedBox(
                                  height: 140,
                                  width: double.infinity,
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: AppImageWidget(
                                          path: doc.path,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(
                                              alpha: 0.65,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.fullscreen,
                                                color: Colors.white,
                                                size: 14,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'Tap to view',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // Application Timeline
            if (application.timeline.isNotEmpty) ...[
              _buildSection(
                title: 'Application Timeline',
                children: [
                  Column(
                    children: application.timeline.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              margin: const EdgeInsets.only(top: 4),
                              decoration: BoxDecoration(
                                color: entry.isCompleted
                                    ? AppColors.success
                                    : AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  if (entry.message != null &&
                                      entry.message!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      entry.message!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ],
                                  if (entry.timestamp != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('dd MMM yyyy, hh:mm a')
                                          .format(entry.timestamp!),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // Status Update Section
            _buildSection(
              title: 'Update Application Status',
              children: [
                DropdownButtonFormField<VendorStatus>(
                  initialValue: _selectedStatus,
                  items: VendorStatus.values
                      .where((status) => status != application.status)
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status.label),
                        ),
                      )
                      .toList(),
                  onChanged: (status) =>
                      setState(() => _selectedStatus = status),
                  decoration: InputDecoration(
                    labelText: 'New Status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Reviewer Notes for Citizen',
                    hintText:
                        'Add remarks (e.g. Approved for Civil Lines zone)...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: widget.controller.isLoading ? null : _updateStatus,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Update Status & Notify Citizen'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Review Submission Section
            _buildSection(
              title: 'Add Administrative Review',
              children: [
                Row(
                  children: [
                    const Text('Rating: '),
                    const SizedBox(width: 8),
                    ...List.generate(5, (index) {
                      final star = index + 1;
                      return IconButton(
                        icon: Icon(
                          star <= _selectedRating
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                        ),
                        onPressed: () => setState(() => _selectedRating = star),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _commentsController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Review Comments',
                    hintText: 'Enter internal verification remarks...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: widget.controller.isLoading ? null : _submitReview,
                    icon: const Icon(Icons.save_as),
                    label: const Text('Save Review Assessment'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(VendorApplication application) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  application.details.businessName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Created on ${DateFormat('dd MMM yyyy').format(application.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(application.status).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                application.status.label,
                style: TextStyle(
                  color: _getStatusColor(application.status),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'N/A',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
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
