import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:smart_nagpur/core/services/location_service.dart';
import 'package:smart_nagpur/core/theme/theme.dart';
import 'package:smart_nagpur/domain/domain.dart';
import 'package:smart_nagpur/state/staff_controller.dart';

class StaffTaskDetailScreen extends StatefulWidget {
  const StaffTaskDetailScreen({
    required this.controller,
    required this.task,
    super.key,
  });

  final StaffController controller;
  final ComplaintAssignment task;

  @override
  State<StaffTaskDetailScreen> createState() => _StaffTaskDetailScreenState();
}

class _StaffTaskDetailScreenState extends State<StaffTaskDetailScreen> {
  final TextEditingController _notesController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  late ComplaintAssignment _currentTask;
  List<ComplaintEvidence> _evidenceList = [];
  bool _isProcessing = false;
  bool _isLoadingEvidence = false;

  @override
  void initState() {
    super.initState();
    _currentTask = widget.task;
    _loadEvidence();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadEvidence() async {
    setState(() => _isLoadingEvidence = true);
    final list = await widget.controller.getTaskEvidence(_currentTask.id);
    if (mounted) {
      setState(() {
        _evidenceList = list;
        _isLoadingEvidence = false;
      });
    }
  }

  ComplaintEvidence? get _beforeWorkEvidence =>
      _evidenceList.where((e) => e.evidenceType == EvidenceType.beforeWork).lastOrNull;

  ComplaintEvidence? get _afterWorkEvidence =>
      _evidenceList.where((e) => e.evidenceType == EvidenceType.afterWork).lastOrNull;

  ComplaintEvidence? get _inspectionReportEvidence =>
      _evidenceList.where((e) => e.evidenceType == EvidenceType.inspectionReport).lastOrNull;

  Future<void> _handleVerifyLocation() async {
    final complaintLat = _currentTask.complaintLatitude;
    final complaintLng = _currentTask.complaintLongitude;

    if (complaintLat == null || complaintLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complaint does not have GPS coordinates attached.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);
    final outcome = await widget.controller.verifyLocation(
      complaintLatitude: complaintLat,
      complaintLongitude: complaintLng,
    );
    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (outcome.isVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.verified_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'GPS Verified! Distance: ${outcome.distanceMeters?.toStringAsFixed(1)}m, Accuracy: ±${outcome.accuracy?.toStringAsFixed(1)}m',
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      SnackBarAction? action;
      if (outcome.result == LocationVerificationResult.permissionDeniedForever) {
        action = SnackBarAction(
          label: 'Settings',
          textColor: Colors.amber,
          onPressed: () => widget.controller.locationService.openAppSettings(),
        );
      } else if (outcome.result == LocationVerificationResult.serviceDisabled) {
        action = SnackBarAction(
          label: 'Enable GPS',
          textColor: Colors.amber,
          onPressed: () => widget.controller.locationService.openLocationSettings(),
        );
      } else if (outcome.result == LocationVerificationResult.outsideRadius) {
        action = SnackBarAction(
          label: 'Open Maps',
          textColor: Colors.amber,
          onPressed: _handleOpenNavigation,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(outcome.errorMessage ?? 'Location verification failed.'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 5),
          action: action,
        ),
      );
    }
  }

  Future<void> _handleOpenNavigation() async {
    final complaintLat = _currentTask.complaintLatitude;
    final complaintLng = _currentTask.complaintLongitude;

    if (complaintLat == null || complaintLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No coordinates available for navigation.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final launched = await widget.controller.launchNavigation(
      latitude: complaintLat,
      longitude: complaintLng,
    );

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not launch map navigation application.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleCaptureEvidence(EvidenceType type) async {
    // 1. Ensure GPS check was performed or perform it now
    var outcome = widget.controller.lastLocationCheck;
    if (outcome == null || !outcome.isVerified) {
      final complaintLat = _currentTask.complaintLatitude ?? 21.1458;
      final complaintLng = _currentTask.complaintLongitude ?? 79.0882;

      setState(() => _isProcessing = true);
      outcome = await widget.controller.verifyLocation(
        complaintLatitude: complaintLat,
        complaintLongitude: complaintLng,
      );
      if (!mounted) return;
      setState(() => _isProcessing = false);
    }

    // 2. Capture Photo with device camera
    try {
      final photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (photo == null) return;

      final bytes = await photo.readAsBytes();
      final fileName = photo.name.isNotEmpty ? photo.name : 'evidence_${DateTime.now().millisecondsSinceEpoch}.jpg';

      setState(() => _isProcessing = true);
      final evidence = await widget.controller.uploadEvidence(
        complaintId: _currentTask.complaintId,
        assignmentId: _currentTask.id,
        type: type,
        fileBytes: bytes,
        fileName: fileName,
        contentType: 'image/jpeg',
        latitude: outcome.latitude ?? 0.0,
        longitude: outcome.longitude ?? 0.0,
        accuracy: outcome.accuracy ?? 0.0,
        notes: '${type.label} captured by field staff.',
      );

      if (!mounted) return;
      setState(() => _isProcessing = false);

      if (evidence != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${type.label} photo uploaded and recorded successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
        await _loadEvidence();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.controller.errorMessage ?? 'Failed to upload photo.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleUploadInspectionPdf() async {
    try {
      final selected = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (selected == null) return;

      final bytes = await selected.readAsBytes();

      if (bytes.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selected PDF is empty or unreadable.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      if (bytes.length > 10 * 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF size exceeds 10MB limit.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final outcome = widget.controller.lastLocationCheck;

      setState(() => _isProcessing = true);
      final evidence = await widget.controller.uploadEvidence(
        complaintId: _currentTask.complaintId,
        assignmentId: _currentTask.id,
        type: EvidenceType.inspectionReport,
        fileBytes: bytes,
        fileName: selected.name,
        contentType: 'application/pdf',
        latitude: outcome?.latitude ?? 0.0,
        longitude: outcome?.longitude ?? 0.0,
        accuracy: outcome?.accuracy ?? 0.0,
        notes: 'Inspection Report PDF attached.',
      );

      if (!mounted) return;
      setState(() => _isProcessing = false);

      if (evidence != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inspection Report PDF uploaded successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
        await _loadEvidence();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to upload inspection PDF. Please retry.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error choosing PDF: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleAccept() async {
    setState(() => _isProcessing = true);
    final success = await widget.controller.acceptTask(_currentTask.id);
    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task accepted successfully.'),
          backgroundColor: AppColors.success,
        ),
      );
      final updated = await widget.controller.getTaskDetails(_currentTask.id);
      if (updated != null && mounted) {
        setState(() => _currentTask = updated);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.controller.errorMessage ?? 'Failed to accept task.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleStart() async {
    setState(() => _isProcessing = true);
    final success = await widget.controller.startTask(_currentTask.id);
    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Work started on task.'),
          backgroundColor: AppColors.success,
        ),
      );
      final updated = await widget.controller.getTaskDetails(_currentTask.id);
      if (updated != null && mounted) {
        setState(() => _currentTask = updated);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.controller.errorMessage ?? 'Failed to start work.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleComplete() async {
    // Evidence Requirement Guard: Verify Before and After evidence
    if (_beforeWorkEvidence == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Required: Please capture a Before-Work photographic proof before submitting completion.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (_afterWorkEvidence == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Required: Please capture an After-Work photographic proof before submitting completion.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final notes = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Work for Verification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add resolution summary or field notes for administrative verification:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 3,
              maxLength: 2000,
              decoration: InputDecoration(
                labelText: 'Completion Notes (Optional)',
                hintText: 'e.g. Cleared drainage obstruction with suction truck.',
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
            onPressed: () => Navigator.pop(context, _notesController.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Submit for Verification'),
          ),
        ],
      ),
    );

    if (notes == null) return;

    setState(() => _isProcessing = true);
    final success = await widget.controller.completeTask(_currentTask.id, notes: notes);
    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Work submitted for verification successfully.'),
          backgroundColor: AppColors.success,
        ),
      );
      final updated = await widget.controller.getTaskDetails(_currentTask.id);
      if (updated != null && mounted) {
        setState(() => _currentTask = updated);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.controller.errorMessage ?? 'Failed to submit work.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
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
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final isWorkingState = _currentTask.status == AssignmentStatus.inProgress ||
        _currentTask.status == AssignmentStatus.accepted ||
        _currentTask.status == AssignmentStatus.reworkRequired;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Task #${_currentTask.id.substring(0, 8)}'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.page),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Status & Priority Header
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  side: const BorderSide(color: AppColors.border),
                ),
                color: AppColors.surface,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current Status',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(_currentTask.status).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Text(
                              _currentTask.status.label,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: _getStatusColor(_currentTask.status),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Task Priority',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getPriorityColor(_currentTask.priority).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              border: Border.all(
                                color: _getPriorityColor(_currentTask.priority).withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.flag_rounded,
                                  size: 14,
                                  color: _getPriorityColor(_currentTask.priority),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _currentTask.priority.label,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: _getPriorityColor(_currentTask.priority),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // 2. Admin Directives / Instructions Card
              if (_currentTask.instructions.isNotEmpty) ...[
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    side: const BorderSide(color: AppColors.info, width: 1.5),
                  ),
                  color: AppColors.infoSoft,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.campaign_rounded, size: 20, color: AppColors.info),
                            const SizedBox(width: 8),
                            Text(
                              'Admin Directives',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.info,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _currentTask.instructions,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

              // 2.2 Rework Required Notice Card
              if (_currentTask.status == AssignmentStatus.reworkRequired) ...[
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    side: const BorderSide(color: AppColors.warning, width: 1.5),
                  ),
                  color: AppColors.warningSoft,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, size: 20, color: AppColors.warning),
                            const SizedBox(width: 8),
                            Text(
                              'Rework Requested by Supervisor',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _currentTask.rejectionReason != null && _currentTask.rejectionReason!.isNotEmpty
                              ? _currentTask.rejectionReason!
                              : 'Please inspect the field site again and apply corrective actions before resubmitting.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

              // 3. Location Verification Section (GPS)
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  side: const BorderSide(color: AppColors.border),
                ),
                color: AppColors.surface,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: ListenableBuilder(
                    listenable: widget.controller,
                    builder: (context, _) {
                      final outcome = widget.controller.lastLocationCheck;
                      final isVerified = outcome?.isVerified ?? false;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Field Location & GPS',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isVerified ? AppColors.successSoft : AppColors.surfaceMuted,
                                  borderRadius: BorderRadius.circular(AppRadius.xs),
                                  border: Border.all(
                                    color: isVerified ? AppColors.success : AppColors.border,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isVerified ? Icons.check_circle_rounded : Icons.location_off_rounded,
                                      size: 14,
                                      color: isVerified ? AppColors.success : AppColors.textMuted,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isVerified ? 'GPS Verified' : 'Unverified',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: isVerified ? AppColors.success : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Target Address & Coords
                          _buildDetailRow(
                            'Complaint Site',
                            _currentTask.complaintLocationAddress ?? 'Nagpur Municipal Area',
                            icon: Icons.place_outlined,
                          ),
                          const SizedBox(height: 8),
                          if (_currentTask.complaintLatitude != null &&
                              _currentTask.complaintLongitude != null) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDetailRow(
                                    'GPS Coordinates',
                                    '${_currentTask.complaintLatitude!.toStringAsFixed(5)}, ${_currentTask.complaintLongitude!.toStringAsFixed(5)}',
                                    icon: Icons.gps_fixed_rounded,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Copy Coordinates',
                                  icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.textMuted),
                                  onPressed: () {
                                    final coords = '${_currentTask.complaintLatitude}, ${_currentTask.complaintLongitude}';
                                    Clipboard.setData(ClipboardData(text: coords));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Coordinates copied: $coords'),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],

                          // Live Check Metrics & Diagnosis
                          if (outcome != null) ...[
                            const Divider(height: 16, color: AppColors.divider),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Distance From Site', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                    const SizedBox(height: 2),
                                    Text(
                                      outcome.distanceMeters != null
                                          ? '${outcome.distanceMeters!.toStringAsFixed(1)} m'
                                          : 'N/A',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: (outcome.distanceMeters ?? 999) <= 100 ? AppColors.success : AppColors.error,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('GPS Accuracy', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                    const SizedBox(height: 2),
                                    Text(
                                      outcome.accuracy != null
                                          ? '± ${outcome.accuracy!.toStringAsFixed(1)} m'
                                          : 'N/A',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: (outcome.accuracy ?? 999) <= 50 ? AppColors.success : AppColors.warning,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (!isVerified && outcome.errorMessage != null) ...[
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(AppRadius.xs),
                                  border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.info_outline_rounded, color: AppColors.error, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        outcome.errorMessage!,
                                        style: const TextStyle(fontSize: 11, color: AppColors.error, height: 1.3),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],

                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _isProcessing ? null : _handleOpenNavigation,
                                  icon: const Icon(Icons.navigation_rounded, size: 16),
                                  label: const Text('Navigate (Maps)', style: TextStyle(fontSize: 12)),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isProcessing ? null : _handleVerifyLocation,
                                  icon: _isProcessing
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : const Icon(Icons.my_location_rounded, size: 16),
                                  label: const Text('Verify GPS', style: TextStyle(fontSize: 12)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // 4. Field Evidence Section
              Card(
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
                      Text(
                        'Field Evidence & Proof',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Capture photos on-site before starting and after completing field actions.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      if (_isLoadingEvidence) ...[
                        const SizedBox(height: 8),
                        const LinearProgressIndicator(),
                      ],
                      const SizedBox(height: AppSpacing.md),

                      // Before Work Card
                      _buildEvidenceCard(
                        title: 'Before-Work Photo',
                        type: EvidenceType.beforeWork,
                        evidence: _beforeWorkEvidence,
                        isRequired: true,
                        isEditable: isWorkingState,
                        onCapture: () => _handleCaptureEvidence(EvidenceType.beforeWork),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // After Work Card
                      _buildEvidenceCard(
                        title: 'After-Work Photo',
                        type: EvidenceType.afterWork,
                        evidence: _afterWorkEvidence,
                        isRequired: true,
                        isEditable: isWorkingState,
                        onCapture: () => _handleCaptureEvidence(EvidenceType.afterWork),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Inspection PDF Card
                      _buildInspectionReportCard(
                        evidence: _inspectionReportEvidence,
                        isEditable: isWorkingState,
                        onUpload: _handleUploadInspectionPdf,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // 5. Complaint Details Card
              Card(
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
                      Text(
                        'Complaint Details',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildDetailRow(
                        'Service Category',
                        _currentTask.complaintServiceType?.toUpperCase() ?? 'MUNICIPAL SERVICE',
                        icon: Icons.category_outlined,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _buildDetailRow(
                        'Issue Title',
                        _currentTask.complaintIssue ?? 'Civic Issue',
                        icon: Icons.error_outline_rounded,
                      ),
                      if (_currentTask.complaintDescription != null &&
                          _currentTask.complaintDescription!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        _buildDetailRow(
                          'Citizen Description',
                          _currentTask.complaintDescription!,
                          icon: Icons.notes_rounded,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // 6. Assignment Milestones Timeline
              Card(
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
                      Text(
                        'Milestone Timeline',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildMilestoneRow(
                        'Admin Assignment',
                        dateFormat.format(_currentTask.assignedAt.toLocal()),
                        isDone: true,
                      ),
                      _buildMilestoneRow(
                        'Staff Accepted',
                        _currentTask.acceptedAt != null ? dateFormat.format(_currentTask.acceptedAt!.toLocal()) : 'Pending acceptance',
                        isDone: _currentTask.acceptedAt != null,
                      ),
                      _buildMilestoneRow(
                        'Field Work Commenced',
                        _currentTask.startedAt != null ? dateFormat.format(_currentTask.startedAt!.toLocal()) : 'Pending start',
                        isDone: _currentTask.startedAt != null,
                      ),
                      _buildMilestoneRow(
                        'Field Work Submitted',
                        _currentTask.completedAt != null ? dateFormat.format(_currentTask.completedAt!.toLocal()) : 'Pending completion',
                        isDone: _currentTask.completedAt != null,
                      ),
                      _buildMilestoneRow(
                        'Admin Approval & Resolution',
                        _currentTask.status == AssignmentStatus.approved ? 'Approved & Resolved' : 'Pending verification',
                        isDone: _currentTask.status == AssignmentStatus.approved,
                        isLast: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // 7. Context-Dependent Action Button
              if (_currentTask.status == AssignmentStatus.assigned)
                SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _handleAccept,
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.thumb_up_alt_rounded),
                    label: const Text('ACCEPT TASK', style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  ),
                )
              else if (_currentTask.status == AssignmentStatus.accepted)
                SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _handleStart,
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.play_arrow_rounded),
                    label: const Text('START WORK', style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
                  ),
                )
              else if (_currentTask.status == AssignmentStatus.inProgress)
                SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _handleComplete,
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.task_alt_rounded),
                    label: const Text('SUBMIT WORK FOR VERIFICATION', style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                  ),
                )
              else if (_currentTask.status == AssignmentStatus.reworkRequired)
                SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _handleStart,
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.replay_rounded),
                    label: const Text('START REWORK', style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
                  ),
                )
              else if (_currentTask.status == AssignmentStatus.completed)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.infoSoft,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.info.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.pending_actions_rounded, color: AppColors.info),
                      SizedBox(width: 8),
                      Text(
                        'Work Submitted for Verification',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.info,
                        ),
                      ),
                    ],
                  ),
                )
              else if (_currentTask.status == AssignmentStatus.approved)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.successSoft,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified_rounded, color: AppColors.success),
                      SizedBox(width: 8),
                      Text(
                        'Work Approved & Resolved',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEvidenceCard({
    required String title,
    required EvidenceType type,
    required ComplaintEvidence? evidence,
    required bool isRequired,
    required bool isEditable,
    required VoidCallback onCapture,
  }) {
    final dateFormat = DateFormat('dd MMM, hh:mm a');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: evidence != null ? AppColors.surfaceMuted : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: evidence != null ? AppColors.success.withValues(alpha: 0.5) : AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: evidence != null ? AppColors.successSoft : AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: evidence?.signedUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Image.network(
                      evidence!.signedUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image_rounded, color: AppColors.textMuted),
                    ),
                  )
                : Icon(
                    Icons.camera_alt_outlined,
                    color: evidence != null ? AppColors.success : AppColors.textMuted,
                    size: 24,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
                    ),
                    if (isRequired) ...[
                      const SizedBox(width: 4),
                      const Text('*', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                if (evidence != null) ...[
                  Text(
                    'Captured: ${dateFormat.format(evidence.capturedAt.toLocal())}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        evidence.isGeoVerified ? Icons.check_circle_rounded : Icons.location_off_rounded,
                        size: 12,
                        color: evidence.isGeoVerified ? AppColors.success : AppColors.warning,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        evidence.isGeoVerified
                            ? 'GPS Verified (${evidence.distanceFromComplaintMeters?.toStringAsFixed(0) ?? '0'}m)'
                            : 'Unverified Location',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: evidence.isGeoVerified ? AppColors.success : AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ] else
                  const Text('No photo captured yet', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          if (isEditable)
            TextButton.icon(
              onPressed: _isProcessing ? null : onCapture,
              icon: Icon(evidence != null ? Icons.replay_rounded : Icons.add_a_photo_outlined, size: 14),
              label: Text(evidence != null ? 'Retake' : 'Capture', style: const TextStyle(fontSize: 11)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInspectionReportCard({
    required ComplaintEvidence? evidence,
    required bool isEditable,
    required VoidCallback onUpload,
  }) {
    final dateFormat = DateFormat('dd MMM, hh:mm a');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: evidence != null ? AppColors.surfaceMuted : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: evidence != null ? AppColors.info.withValues(alpha: 0.5) : AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: evidence != null ? AppColors.infoSoft : AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              Icons.picture_as_pdf_outlined,
              color: evidence != null ? AppColors.info : AppColors.textMuted,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Inspection Report PDF',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                if (evidence != null) ...[
                  Text(
                    '${evidence.originalName} (${evidence.formattedFileSize})',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  Text(
                    'Uploaded: ${dateFormat.format(evidence.capturedAt.toLocal())}',
                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                  ),
                ] else
                  const Text('Optional report document', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          if (isEditable)
            TextButton.icon(
              onPressed: _isProcessing ? null : onUpload,
              icon: Icon(evidence != null ? Icons.replay_rounded : Icons.upload_file_outlined, size: 14),
              label: Text(evidence != null ? 'Replace' : 'Upload', style: const TextStyle(fontSize: 11)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {required IconData icon}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMilestoneRow(String title, String subtitle, {required bool isDone, bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(
              isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              size: 18,
              color: isDone ? AppColors.success : AppColors.textMuted,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 24,
                color: isDone ? AppColors.success.withValues(alpha: 0.5) : AppColors.border,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDone ? AppColors.textPrimary : AppColors.textMuted,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isDone ? AppColors.textSecondary : AppColors.textMuted,
                ),
              ),
              if (!isLast) const SizedBox(height: 10),
            ],
          ),
        ),
      ],
    );
  }
}
