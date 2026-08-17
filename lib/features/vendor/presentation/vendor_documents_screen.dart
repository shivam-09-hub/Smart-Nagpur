import 'package:flutter/material.dart';
import 'package:smart_nagpur/core/services/services.dart';
import 'package:smart_nagpur/core/theme/theme.dart';
import 'package:smart_nagpur/core/widgets/states.dart';
import 'package:smart_nagpur/domain/domain.dart';
import 'package:smart_nagpur/state/app_controller.dart';

import 'vendor_application_screen.dart';
import 'widgets/vendor_document_upload_card.dart';
import 'widgets/vendor_widgets.dart';

class VendorDocumentsScreen extends StatefulWidget {
  const VendorDocumentsScreen({
    required this.controller,
    super.key,
    this.applicationId,
    this.documentPickerService,
  });

  final AppController controller;
  final String? applicationId;
  final DocumentPickerService? documentPickerService;

  @override
  State<VendorDocumentsScreen> createState() => _VendorDocumentsScreenState();
}

class _VendorDocumentsScreenState extends State<VendorDocumentsScreen> {
  static const _allApplications = '__all__';

  final List<VendorDocument> _sessionDocuments = <VendorDocument>[];
  late String _selectedApplicationId;
  bool _isPicking = false;

  DocumentPickerService get _picker =>
      widget.documentPickerService ?? widget.controller.documentPickerService;

  @override
  void initState() {
    super.initState();
    _selectedApplicationId = widget.applicationId ?? _allApplications;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Vendor Documents'),
        actions: [
          IconButton(
            tooltip: 'Choose documents',
            onPressed: _isPicking ? null : _pickSessionDocuments,
            icon: const Icon(Icons.upload_file_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) {
            _normaliseSelectedApplication();
            final records = _visibleDocuments;
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
                          VendorDemoBanner(
                            isDemo: widget.controller.isDemoMode,
                            message: widget.controller.isDemoMode
                                ? 'Application documents are local demo files. Files added here remain only for this screen session unless selected during an application.'
                                : 'Documents attached during an application are private cloud files. New files chosen on this screen are temporary previews and are not uploaded.',
                          ),
                          if (widget
                              .controller
                              .vendorApplications
                              .isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.md),
                            DropdownButtonFormField<String>(
                              key: ValueKey(_selectedApplicationId),
                              initialValue: _selectedApplicationId,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Show documents for',
                                prefixIcon: Icon(Icons.filter_list_rounded),
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: _allApplications,
                                  child: Text('All applications'),
                                ),
                                ...widget.controller.vendorApplications.map(
                                  (application) => DropdownMenuItem(
                                    value: application.id,
                                    child: Text(
                                      '${application.id} · ${application.businessName}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(
                                    () => _selectedApplicationId = value,
                                  );
                                }
                              },
                            ),
                          ],
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _isPicking
                                      ? null
                                      : _pickSessionDocuments,
                                  icon: _isPicking
                                      ? const SizedBox.square(
                                          dimension: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.upload_file_rounded),
                                  label: Text(
                                    _isPicking
                                        ? 'Choosing…'
                                        : 'Add Session Documents',
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: _startApplication,
                                  icon: const Icon(Icons.add_rounded),
                                  label: const Text('New Application'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: records.isEmpty
                      ? EmptyState(
                          title: 'No documents here',
                          message: _selectedApplicationId == _allApplications
                              ? 'Add a session document or attach files in a vendor application.'
                              : 'This application has no attached documents.',
                          icon: Icons.folder_open_outlined,
                          actionLabel: 'Choose documents',
                          onAction: _pickSessionDocuments,
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.page,
                            AppSpacing.xs,
                            AppSpacing.page,
                            AppSpacing.xxl,
                          ),
                          itemCount: records.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, index) => Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 760),
                              child: _DocumentCard(
                                record: records[index],
                                onTap: () => _showDocument(records[index]),
                                onRemove: records[index].isSession
                                    ? () {
                                        setState(() {
                                          _sessionDocuments.remove(
                                            records[index].document,
                                          );
                                        });
                                      }
                                    : null,
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _normaliseSelectedApplication() {
    if (_selectedApplicationId == _allApplications) return;
    final exists = widget.controller.vendorApplications.any(
      (application) => application.id == _selectedApplicationId,
    );
    if (!exists) _selectedApplicationId = _allApplications;
  }

  List<_VendorDocumentRecord> get _visibleDocuments {
    final records = <_VendorDocumentRecord>[];
    for (final application in widget.controller.vendorApplications) {
      if (_selectedApplicationId != _allApplications &&
          application.id != _selectedApplicationId) {
        continue;
      }
      for (final document in application.documents) {
        records.add(
          _VendorDocumentRecord(
            document: document,
            applicationId: application.id,
            businessName: application.businessName,
          ),
        );
      }
    }
    if (_selectedApplicationId == _allApplications) {
      for (final document in _sessionDocuments) {
        records.add(_VendorDocumentRecord(document: document, isSession: true));
      }
    }
    return records;
  }

  Future<void> _pickSessionDocuments() async {
    setState(() => _isPicking = true);
    try {
      final picked = await _picker.pickDocuments(allowMultiple: true);
      if (!mounted || picked.isEmpty) return;
      setState(() {
        for (final selected in picked) {
          _sessionDocuments.add(
            VendorDocument(
              type: 'session-${DateTime.now().microsecondsSinceEpoch}',
              label: selected.name,
              path: selected.path,
              requirement: DocumentRequirement.optional,
            ),
          );
        }
        _selectedApplicationId = _allApplications;
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

  void _startApplication() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VendorApplicationScreen(controller: widget.controller),
      ),
    );
  }

  void _showDocument(_VendorDocumentRecord record) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            0,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(
                      Icons.description_outlined,
                      color: AppColors.vendor,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      record.document.label,
                      style: AppTypography.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              VendorInfoRow(
                label: 'File name',
                value: vendorFileName(record.document.path),
              ),
              VendorInfoRow(
                label: 'Requirement',
                value: documentRequirementLabel(record.document.requirement),
              ),
              VendorInfoRow(
                label: 'Source',
                value: record.isSession
                    ? 'This screen session'
                    : '${record.applicationId} · ${record.businessName}',
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'The managed file path is hidden for privacy. Opening files requires an approved platform viewer integration.',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.record,
    required this.onTap,
    this.onRemove,
  });

  final _VendorDocumentRecord record;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: record.isSession
                      ? AppColors.warningSoft
                      : AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  Icons.description_outlined,
                  color: record.isSession
                      ? AppColors.warning
                      : AppColors.vendor,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(record.document.label, style: AppTypography.label),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      vendorFileName(record.document.path),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      record.isSession
                          ? 'SESSION ONLY'
                          : record.applicationId ?? 'Demo application',
                      style: AppTypography.caption.copyWith(
                        color: record.isSession
                            ? AppColors.warning
                            : AppColors.vendor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if (onRemove != null)
                IconButton(
                  tooltip: 'Remove session document',
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline_rounded),
                )
              else
                const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _VendorDocumentRecord {
  const _VendorDocumentRecord({
    required this.document,
    this.applicationId,
    this.businessName,
    this.isSession = false,
  });

  final VendorDocument document;
  final String? applicationId;
  final String? businessName;
  final bool isSession;
}
