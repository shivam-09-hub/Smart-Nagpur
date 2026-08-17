import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_nagpur/core/theme/theme.dart';
import 'package:smart_nagpur/core/widgets/app_photo_gallery.dart';
import 'package:smart_nagpur/domain/domain.dart';
import 'package:smart_nagpur/features/complaints/presentation/widgets/development_map.dart';
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
  late final TextEditingController _instructionsController;
  ComplaintStatus? _selectedStatus;

  // Assignment & Evidence State
  List<StaffProfile> _availableStaff = [];
  StaffProfile? _selectedStaff;
  StaffDepartment _selectedDepartment = StaffDepartment.general;
  AssignmentPriority _selectedPriority = AssignmentPriority.medium;
  ComplaintAssignment? _currentAssignment;
  List<ComplaintEvidence> _evidenceList = [];
  bool _isAssigning = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
    _commentsController = TextEditingController();
    _instructionsController = TextEditingController();
    _loadData();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _commentsController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    _complaint = await widget.controller.getComplaintDetails(
      widget.complaintId,
    );

    if (_complaint != null) {
      _selectedDepartment = _getDepartmentForService(_complaint!.serviceType);
      await _loadStaffForDepartment(_selectedDepartment);

      if (_complaint!.currentAssignmentId != null) {
        _currentAssignment = await widget.controller.getComplaintAssignment(
          _complaint!.currentAssignmentId!,
        );
      }

      _evidenceList = await widget.controller.getComplaintEvidence(
        widget.complaintId,
      );
    }

    setState(() => _isLoading = false);
  }


  StaffDepartment _getDepartmentForService(ServiceType type) {
    return switch (type) {
      ServiceType.roads => StaffDepartment.road,
      ServiceType.garbage || ServiceType.drainage => StaffDepartment.waste,
      ServiceType.water => StaffDepartment.water,
      ServiceType.vendor => StaffDepartment.vendor,
      _ => StaffDepartment.general,
    };
  }

  Future<void> _loadStaffForDepartment(StaffDepartment dept) async {
    final staffList = await widget.controller.getStaffMembers(
      department: dept,
      isActive: true,
    );
    if (mounted) {
      setState(() {
        _availableStaff = staffList;
        if (_selectedStaff != null && !_availableStaff.contains(_selectedStaff)) {
          _selectedStaff = null;
        }
      });
    }
  }

  Future<void> _handleAssign() async {
    if (_selectedStaff == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an active staff member to assign.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isAssigning = true);

    final success = await widget.controller.assignComplaint(
      complaintId: _complaint?.id ?? widget.complaintId,
      staffId: _selectedStaff!.id,
      priority: _selectedPriority,
      instructions: _instructionsController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isAssigning = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Complaint assigned to ${_selectedStaff!.name} successfully.',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      _instructionsController.clear();
      _selectedStaff = null;
      await _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.controller.error ?? 'Failed to assign complaint.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleApproveAssignment() async {
    if (_currentAssignment == null) return;

    final reviewNotes = await showDialog<String>(
      context: context,
      builder: (context) {
        final notesController = TextEditingController();
        return AlertDialog(
          title: const Text('Approve & Resolve Complaint'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Confirm field work resolution and approve this task. The complaint will be marked as RESOLVED for the citizen.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                maxLines: 3,
                maxLength: 2000,
                decoration: InputDecoration(
                  labelText: 'Verification Notes (Optional)',
                  hintText: 'e.g. Verified road patch meets municipal standards.',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, notesController.text.trim()),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
              child: const Text('Approve & Resolve'),
            ),
          ],
        );
      },
    );

    if (reviewNotes == null) return;

    setState(() => _isAssigning = true);
    final success = await widget.controller.approveComplaintAssignment(
      _currentAssignment!.id,
      reviewNotes: reviewNotes,
    );
    if (!mounted) return;
    setState(() => _isAssigning = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Field work approved. Complaint resolved successfully.'),
          backgroundColor: AppColors.success,
        ),
      );
      await _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.controller.error ?? 'Failed to approve work.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleRequestRework() async {
    if (_currentAssignment == null) return;

    final reworkInstructions = await showDialog<String>(
      context: context,
      builder: (context) {
        final reworkController = TextEditingController();
        return AlertDialog(
          title: const Text('Request Rework'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Specify why the field work was insufficient and what corrective actions the field staff must perform:',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reworkController,
                maxLines: 3,
                maxLength: 1000,
                decoration: InputDecoration(
                  labelText: 'Rework Instructions',
                  hintText: 'e.g. Trench not leveled evenly; re-roll asphalt edges.',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, reworkController.text.trim()),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
              child: const Text('Send Rework Request'),
            ),
          ],
        );
      },
    );

    if (reworkInstructions == null) return;

    setState(() => _isAssigning = true);
    final success = await widget.controller.requestReworkComplaintAssignment(
      _currentAssignment!.id,
      reworkInstructions: reworkInstructions,
    );
    if (!mounted) return;
    setState(() => _isAssigning = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rework requested. Staff task returned to active workflow.'),
          backgroundColor: AppColors.warning,
        ),
      );
      await _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.controller.error ?? 'Failed to request rework.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
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
            if (complaint.photoPaths.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildSection(
                title: 'Attached Photos (${complaint.photoPaths.length})',
                children: [
                  AppPhotoGallery(photoPaths: complaint.photoPaths),
                ],
              ),
            ],
            const SizedBox(height: 24),

            // Location
            _buildSection(
              title: 'Location',
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: DevelopmentMap(
                      location: complaint.location,
                      isEditable: false,
                      aspectRatio: 1.8,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
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

            // Field Evidence & Proof Section
            if (_evidenceList.isNotEmpty) ...[
              _buildEvidenceSection(complaint),
              const SizedBox(height: 24),
            ],

            // Staff Assignment Section
            _buildAssignmentSection(complaint),
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

  Widget _buildAssignmentSection(ComplaintRecord complaint) {
    return _buildSection(
      title: 'Field Staff Assignment',
      children: [
        // Current Assignment Info Banner if assigned
        if (_currentAssignment != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.infoSoft,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person_pin_rounded, size: 20, color: AppColors.info),
                        const SizedBox(width: 6),
                        Text(
                          'Currently Assigned Staff',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.info,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _currentAssignment!.status.label,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${_currentAssignment!.staffName ?? 'Staff Member'} (${_currentAssignment!.staffEmployeeId ?? 'N/A'})',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Department: ${_currentAssignment!.staffDepartment?.label ?? _selectedDepartment.label} | Priority: ${_currentAssignment!.priority.label}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                if (_currentAssignment!.instructions.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Instructions: "${_currentAssignment!.instructions}"',
                    style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  'Assigned on: ${DateFormat('dd MMM yyyy, hh:mm a').format(_currentAssignment!.assignedAt)}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                if (_currentAssignment!.status == AssignmentStatus.reworkRequired &&
                    _currentAssignment!.rejectionReason != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.warningSoft,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: Text(
                      'Rework Reason: ${_currentAssignment!.rejectionReason}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Action verification card if work completed by staff
          if (_currentAssignment!.status == AssignmentStatus.completed) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.successSoft,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified_outlined, size: 20, color: AppColors.success),
                      const SizedBox(width: 6),
                      Text(
                        'Field Work Submitted for Verification',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (_currentAssignment!.notes.isNotEmpty) ...[
                    Text(
                      'Technician Notes: "${_currentAssignment!.notes}"',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (_currentAssignment!.completedAt != null)
                    Text(
                      'Completed on: ${DateFormat('dd MMM yyyy, hh:mm a').format(_currentAssignment!.completedAt!)}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isAssigning ? null : _handleRequestRework,
                          icon: const Icon(Icons.replay_rounded, size: 16, color: AppColors.warning),
                          label: const Text('Request Rework', style: TextStyle(color: AppColors.warning, fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.warning),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isAssigning ? null : _handleApproveAssignment,
                          icon: const Icon(Icons.check_circle_rounded, size: 16),
                          label: const Text('Approve & Resolve', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],


        // Department Selection Dropdown
        DropdownButtonFormField<StaffDepartment>(
          initialValue: _selectedDepartment,
          items: StaffDepartment.values
              .map(
                (dept) => DropdownMenuItem(
                  value: dept,
                  child: Text(dept.label),
                ),
              )
              .toList(),
          onChanged: (dept) {
            if (dept != null) {
              setState(() => _selectedDepartment = dept);
              _loadStaffForDepartment(dept);
            }
          },
          decoration: InputDecoration(
            labelText: 'Assigned Department',
            prefixIcon: const Icon(Icons.domain_rounded),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Staff Selection Dropdown
        DropdownButtonFormField<StaffProfile>(
          isExpanded: true,
          initialValue: _selectedStaff,
          items: _availableStaff
              .map(
                (staff) => DropdownMenuItem(
                  value: staff,
                  child: Text(
                    '${staff.name} (${staff.employeeId} - ${staff.role.label})',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (staff) => setState(() => _selectedStaff = staff),
          decoration: InputDecoration(
            labelText: 'Select Field Staff Member',
            hintText: _availableStaff.isEmpty
                ? 'No active staff in this department'
                : 'Choose a staff member',
            prefixIcon: const Icon(Icons.engineering_rounded),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Priority Selection Dropdown
        DropdownButtonFormField<AssignmentPriority>(
          initialValue: _selectedPriority,
          items: AssignmentPriority.values
              .map(
                (p) => DropdownMenuItem(
                  value: p,
                  child: Text('${p.label} Priority'),
                ),
              )
              .toList(),
          onChanged: (p) {
            if (p != null) setState(() => _selectedPriority = p);
          },
          decoration: InputDecoration(
            labelText: 'Task Priority',
            prefixIcon: const Icon(Icons.flag_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Instructions Input Field
        TextField(
          controller: _instructionsController,
          maxLines: 3,
          maxLength: 2000,
          decoration: InputDecoration(
            labelText: 'Field Instructions / Task Directives',
            hintText: 'e.g. Inspect road patch, deploy asphalt repair crew, verify drainage cover...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Assignment Action Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isAssigning ? null : _handleAssign,
            icon: _isAssigning
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Icon(_currentAssignment != null ? Icons.published_with_changes_rounded : Icons.assignment_ind_rounded),
            label: Text(
              _isAssigning
                  ? 'Assigning Task...'
                  : (_currentAssignment != null ? 'Reassign Complaint' : 'Assign to Field Staff'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEvidenceSection(ComplaintRecord complaint) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return _buildSection(
      title: 'Field Verification Proofs (${_evidenceList.length})',
      children: [
        for (final evidence in _evidenceList) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: evidence.isGeoVerified
                    ? AppColors.success.withValues(alpha: 0.5)
                    : AppColors.border,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          evidence.isPdf ? Icons.picture_as_pdf_outlined : Icons.photo_camera_outlined,
                          size: 18,
                          color: evidence.isPdf ? AppColors.info : AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          evidence.evidenceType.label,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: evidence.isGeoVerified ? AppColors.successSoft : AppColors.warningSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        evidence.isGeoVerified ? 'GPS Verified' : 'Unverified GPS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: evidence.isGeoVerified ? AppColors.success : AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Photo preview if signed url available
                if (evidence.isImage && evidence.signedUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Image.network(
                      evidence.signedUrl!,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 100,
                        color: AppColors.surface,
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image_outlined, color: AppColors.textMuted),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Metadata Rows
                if (evidence.staffName != null)
                  Text(
                    'Staff: ${evidence.staffName} (${evidence.staffEmployeeId ?? 'N/A'})',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                if (evidence.distanceFromComplaintMeters != null)
                  Text(
                    'Distance From Complaint: ${evidence.distanceFromComplaintMeters!.toStringAsFixed(1)}m (Accuracy: ±${evidence.accuracy.toStringAsFixed(1)}m)',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                Text(
                  'Captured: ${dateFormat.format(evidence.capturedAt)}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}


