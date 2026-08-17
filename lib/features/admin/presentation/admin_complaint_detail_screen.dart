import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_nagpur/core/theme/theme.dart';
import 'package:smart_nagpur/domain/domain.dart';
import 'package:smart_nagpur/state/admin_controller.dart';

class AdminComplaintDetailScreen extends StatefulWidget {
  const AdminComplaintDetailScreen({
    required this.controller,
    required this.complaintId,
    super.key,
  });

  final AdminController controller;
  final String complaintId;

  @override
  State<AdminComplaintDetailScreen> createState() =>
      _AdminComplaintDetailScreenState();
}

class _AdminComplaintDetailScreenState
    extends State<AdminComplaintDetailScreen> {
  ComplaintRecord? _complaint;
  bool _isLoading = true;
  late final TextEditingController _notesController;
  late final TextEditingController _commentsController;
  ComplaintStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
    _commentsController = TextEditingController();
    _loadData();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _commentsController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    _complaint = await widget.controller.getComplaintDetails(
      widget.complaintId,
    );
    setState(() => _isLoading = false);
  }

  Future<void> _updateStatus() async {
    if (_selectedStatus == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a status')));
      return;
    }

    final success = await widget.controller.updateComplaintStatus(
      widget.complaintId,
      _selectedStatus!,
      _notesController.text,
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status updated successfully')),
      );
      await _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.controller.error ?? 'Failed to update status'),
        ),
      );
    }
  }

  Future<void> _submitReview() async {
    if (_commentsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add review comments')),
      );
      return;
    }

    final review = AdminReview(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      itemType: 'complaint',
      itemId: widget.complaintId,
      reviewedBy: widget.controller.currentAdmin?.id ?? 'unknown',
      status: ReviewStatus.approved,
      createdAt: DateTime.now(),
      comments: _commentsController.text,
    );

    final success = await widget.controller.submitComplaintReview(
      widget.complaintId,
      review,
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted successfully')),
      );
      _commentsController.clear();
      await _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.controller.error ?? 'Failed to submit review'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Complaint Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_complaint == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Complaint Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Complaint not found'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final complaint = _complaint!;

    return Scaffold(
      appBar: AppBar(title: const Text('Complaint Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(complaint),
            const SizedBox(height: 24),

            // Description
            _buildSection(
              title: 'Issue & Description',
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Issue Type',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            complaint.issue,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Service Type',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            complaint.serviceType.name.replaceAll(
                              RegExp(r'(?<=[a-z])(?=[A-Z])'),
                              ' ',
                            ),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 8),
                Text(complaint.description),
              ],
            ),
            const SizedBox(height: 24),

            // Location
            _buildSection(
              title: 'Location',
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            complaint.location.address,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            complaint.location.coordinates,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Contact Information
            _buildSection(
              title: 'Contact Information',
              children: [
                Row(
                  children: [
                    Icon(Icons.phone, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Text(complaint.contactPhone),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.location_city, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(child: Text(complaint.citizenAddress ?? 'N/A')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Timeline
            if (complaint.timeline.isNotEmpty)
              _buildSection(
                title: 'Timeline',
                children: [
                  Column(
                    children: complaint.timeline
                        .map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      if (entry.message != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          entry.message!,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                      ],
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat(
                                          'dd MMM yyyy, hh:mm a',
                                        ).format(entry.timestamp),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            const SizedBox(height: 24),

            // Status Update
            if (complaint.status.isActive)
              _buildSection(
                title: 'Update Status',
                children: [
                  DropdownButtonFormField<ComplaintStatus>(
                    initialValue: _selectedStatus,
                    items: ComplaintStatus.values
                        .where((status) => status != complaint.status)
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
                      labelText: 'Notes',
                      hintText: 'Add any notes for this update...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _updateStatus,
                    icon: const Icon(Icons.check),
                    label: const Text('Update Status'),
                  ),
                ],
              ),
            const SizedBox(height: 24),

            // Review Section
            _buildSection(
              title: 'Add Review',
              children: [
                TextField(
                  controller: _commentsController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Review Comments',
                    hintText: 'Add your review and assessment...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _submitReview,
                  icon: const Icon(Icons.done_all),
                  label: const Text('Submit Review'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ComplaintRecord complaint) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Complaint #${complaint.id}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat(
                        'dd MMM yyyy, hh:mm a',
                      ).format(complaint.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                      complaint.status,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    complaint.status.label,
                    style: TextStyle(
                      color: _getStatusColor(complaint.status),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ),
      ],
    );
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
