import 'package:flutter/material.dart';
import 'package:smart_nagpur/core/services/services.dart';
import 'package:smart_nagpur/core/theme/theme.dart';
import 'package:smart_nagpur/core/widgets/app_text_field.dart';
import 'package:smart_nagpur/domain/domain.dart';
import 'package:smart_nagpur/state/app_controller.dart';

import 'widgets/vendor_document_upload_card.dart';
import 'widgets/vendor_widgets.dart';

class VendorRenewalScreen extends StatefulWidget {
  const VendorRenewalScreen({
    required this.controller,
    super.key,
    this.applicationId,
    this.documentPickerService,
  });

  final AppController controller;
  final String? applicationId;
  final DocumentPickerService? documentPickerService;

  @override
  State<VendorRenewalScreen> createState() => _VendorRenewalScreenState();
}

class _VendorRenewalScreenState extends State<VendorRenewalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _applicationIdController = TextEditingController();
  final _permissionController = TextEditingController();
  final _notesController = TextEditingController();
  String _renewalPeriod = '12 months';
  bool _accepted = false;
  bool _showErrors = false;
  bool _isPicking = false;
  bool _isSubmitting = false;
  VendorDocument? _previousPermission;
  String? _renewalReference;

  DocumentPickerService get _picker =>
      widget.documentPickerService ?? widget.controller.documentPickerService;

  @override
  void initState() {
    super.initState();
    final preferredId =
        widget.applicationId ??
        (widget.controller.vendorApplications.isEmpty
            ? null
            : widget.controller.vendorApplications.first.id);
    _applicationIdController.text = preferredId ?? '';
  }

  @override
  void dispose() {
    _applicationIdController.dispose();
    _permissionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_renewalReference != null) return _buildSuccess();
    return Scaffold(
      appBar: AppBar(title: const Text('Renew Permission')),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: VendorResponsiveBody(
            child: Form(
              key: _formKey,
              autovalidateMode: _showErrors
                  ? AutovalidateMode.onUserInteraction
                  : AutovalidateMode.disabled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const VendorDemoBanner(
                    message:
                        'Renewal requests are simulated for this screen session and are not filed, saved, or reviewed by a municipality.',
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text('Permission details', style: AppTypography.headline),
                  const SizedBox(height: AppSpacing.xxs),
                  const Text(
                    'Enter an application and previous permission reference.',
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (widget.controller.vendorApplications.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      initialValue: _knownApplicationId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Choose an application',
                        prefixIcon: Icon(Icons.assignment_outlined),
                      ),
                      items: widget.controller.vendorApplications
                          .map(
                            (application) => DropdownMenuItem(
                              value: application.id,
                              child: Text(
                                '${application.id} · ${application.businessName}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _applicationIdController.text = value);
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  AppTextField(
                    controller: _applicationIdController,
                    label: 'Application ID',
                    hint: 'VN-2026-001284',
                    prefixIcon: Icons.tag_rounded,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter an application ID.'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _permissionController,
                    label: 'Previous permission number',
                    prefixIcon: Icons.verified_outlined,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter the previous permission number.'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    initialValue: _renewalPeriod,
                    decoration: const InputDecoration(
                      labelText: 'Requested renewal period',
                      prefixIcon: Icon(Icons.date_range_outlined),
                    ),
                    items: const ['3 months', '6 months', '12 months']
                        .map(
                          (period) => DropdownMenuItem(
                            value: period,
                            child: Text(period),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _renewalPeriod = value);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _notesController,
                    label: 'Changes or notes (optional)',
                    hint: 'Describe any change to location, hours, or business',
                    prefixIcon: Icons.notes_outlined,
                    minLines: 3,
                    maxLines: 5,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text('Supporting document', style: AppTypography.titleLarge),
                  const SizedBox(height: AppSpacing.sm),
                  VendorDocumentUploadCard(
                    type: 'previous-permission',
                    label: 'Previous permission',
                    requirement: DocumentRequirement.conditional,
                    document: _previousPermission,
                    isBusy: _isPicking,
                    supportingText:
                        'Attach it if available. This demo does not determine whether it is legally required.',
                    onPick: _pickPreviousPermission,
                    onRemove: _previousPermission == null
                        ? null
                        : () => setState(() => _previousPermission = null),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  CheckboxListTile(
                    value: _accepted,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text(
                      'I confirm these renewal details are accurate for this demo.',
                    ),
                    subtitle: _showErrors && !_accepted
                        ? Text(
                            'Acceptance is required.',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          )
                        : null,
                    onChanged: (value) {
                      setState(() => _accepted = value ?? false);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      icon: _isSubmitting
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.autorenew_rounded),
                      label: Text(
                        _isSubmitting
                            ? 'Creating demo request…'
                            : 'Submit Renewal Request',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? get _knownApplicationId {
    final id = _applicationIdController.text;
    return widget.controller.vendorApplications.any((item) => item.id == id)
        ? id
        : null;
  }

  Future<void> _pickPreviousPermission() async {
    setState(() => _isPicking = true);
    try {
      final selected = await _picker.pickDocuments();
      if (!mounted || selected.isEmpty) return;
      setState(() {
        _previousPermission = VendorDocument(
          type: 'previous-permission',
          label: 'Previous permission',
          path: selected.first.path,
          requirement: DocumentRequirement.conditional,
        );
      });
    } on DocumentPickerException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document selection is unavailable.')),
      );
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _submit() async {
    setState(() {
      _showErrors = true;
      _isSubmitting = true;
    });
    final formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid || !_accepted) {
      setState(() => _isSubmitting = false);
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    final serial = DateTime.now().microsecondsSinceEpoch % 1000000;
    setState(() {
      _renewalReference =
          'RN-${DateTime.now().year}-${serial.toString().padLeft(6, '0')}';
      _isSubmitting = false;
    });
  }

  Widget _buildSuccess() {
    return Scaffold(
      appBar: AppBar(title: const Text('Renew Permission')),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: VendorResponsiveBody(
            maxWidth: 620,
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.xxl),
                Container(
                  width: 88,
                  height: 88,
                  decoration: const BoxDecoration(
                    color: AppColors.successSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppColors.success,
                    size: 48,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Demo Renewal Created', style: AppTypography.headline),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'This session-only result was not saved or sent to a municipality.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: AppSpacing.xl),
                VendorSectionCard(
                  title: 'Renewal summary',
                  icon: Icons.autorenew_rounded,
                  children: [
                    VendorInfoRow(
                      label: 'Demo reference',
                      value: _renewalReference!,
                    ),
                    VendorInfoRow(
                      label: 'Application ID',
                      value: _applicationIdController.text.trim(),
                    ),
                    VendorInfoRow(
                      label: 'Permission No.',
                      value: _permissionController.text.trim(),
                    ),
                    VendorInfoRow(label: 'Period', value: _renewalPeriod),
                    const VendorInfoRow(
                      label: 'Status',
                      value: 'Demo submitted',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.maybePop(context),
                    child: const Text('Done'),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextButton(
                  onPressed: () => setState(() {
                    _renewalReference = null;
                    _accepted = false;
                    _showErrors = false;
                  }),
                  child: const Text('Create another demo renewal'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
