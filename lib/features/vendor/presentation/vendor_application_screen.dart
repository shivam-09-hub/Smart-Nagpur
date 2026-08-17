import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_nagpur/core/services/services.dart';
import 'package:smart_nagpur/core/theme/theme.dart';
import 'package:smart_nagpur/core/widgets/app_text_field.dart';
import 'package:smart_nagpur/domain/domain.dart';
import 'package:smart_nagpur/features/complaints/presentation/widgets/development_map.dart';
import 'package:smart_nagpur/state/app_controller.dart';

import 'vendor_application_detail_screen.dart';
import 'widgets/vendor_document_upload_card.dart';
import 'widgets/vendor_widgets.dart';

class VendorApplicationScreen extends StatefulWidget {
  const VendorApplicationScreen({
    required this.controller,
    super.key,
    this.locationService,
    this.documentPickerService,
    this.sourceAction,
    this.initialPreferredZone,
    this.initialLocation,
    this.initialDocuments = const [],
  });

  final AppController controller;
  final LocationService? locationService;
  final DocumentPickerService? documentPickerService;
  final String? sourceAction;
  final String? initialPreferredZone;
  final ProblemLocation? initialLocation;
  final List<VendorDocument> initialDocuments;

  @override
  State<VendorApplicationScreen> createState() =>
      _VendorApplicationScreenState();
}

class _VendorApplicationScreenState extends State<VendorApplicationScreen> {
  static const _stepLabels = <String>[
    'Applicant',
    'Business',
    'Location',
    'Operations',
    'Documents',
    'Declaration',
    'Review',
    'Submit',
  ];

  static const _categories = <String>[
    'Food & Beverage',
    'Fruits & Vegetables',
    'Clothing',
    'Household Items',
    'Repair Services',
    'Handicrafts',
    'Books',
    'Flowers',
    'Other',
  ];

  static const _businessTypes = <String>[
    'Sole proprietor',
    'Partnership',
    'Self-help group',
    'Co-operative',
    'Other',
  ];

  static const _outletTypes = <String>['Stall', 'Cart', 'Shop', 'Other'];
  static const _days = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const _documentSpecs = <_DocumentSpec>[
    _DocumentSpec(
      type: 'identity-proof',
      label: 'Identity Proof',
      requirement: DocumentRequirement.required,
      help: 'Choose a clear PDF or image for this application.',
    ),
    _DocumentSpec(
      type: 'address-proof',
      label: 'Address Proof',
      requirement: DocumentRequirement.required,
    ),
    _DocumentSpec(
      type: 'photograph',
      label: 'Photograph',
      requirement: DocumentRequirement.required,
    ),
    _DocumentSpec(
      type: 'business-registration',
      label: 'Business registration/license',
      requirement: DocumentRequirement.optional,
    ),
    _DocumentSpec(
      type: 'food-license',
      label: 'Food-related license where applicable',
      requirement: DocumentRequirement.conditional,
      help:
          'This may apply to some food businesses. The app is not determining a legal requirement.',
    ),
    _DocumentSpec(
      type: 'previous-permission',
      label: 'Previous permission where applicable',
      requirement: DocumentRequirement.conditional,
    ),
    _DocumentSpec(
      type: 'other-supporting',
      label: 'Other supporting document',
      requirement: DocumentRequirement.optional,
    ),
  ];

  final _applicantFormKey = GlobalKey<FormState>();
  final _businessFormKey = GlobalKey<FormState>();
  final _locationFormKey = GlobalKey<FormState>();
  final _operationsFormKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _residentialAddressController = TextEditingController();
  final _identityController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _productsController = TextEditingController();
  final _registrationController = TextEditingController();
  final _locationSearchController = TextEditingController();
  final _locationAddressController = TextEditingController();
  final _preferredZoneController = TextEditingController();

  int _step = 0;
  String? _businessType;
  String? _category;
  String? _outletType;
  String _durationType = 'Permanent';
  String _startTime = '';
  String _endTime = '';
  final Set<String> _operatingDays = <String>{};
  final Map<String, VendorDocument> _documents = <String, VendorDocument>{};
  ProblemLocation? _location;
  bool _acceptedDeclaration = false;
  bool _showErrors = false;
  bool _isLocating = false;
  bool _isSubmitting = false;
  String? _pickingDocumentType;
  VendorApplication? _submittedApplication;

  LocationService get _locationService =>
      widget.locationService ?? widget.controller.locationService;
  DocumentPickerService get _documentPickerService =>
      widget.documentPickerService ?? widget.controller.documentPickerService;

  bool get _isPermissionApplication =>
      widget.sourceAction?.contains('permission') == true;

  @override
  void initState() {
    super.initState();
    final profile = widget.controller.profile;
    _nameController.text = profile?.name ?? '';
    _mobileController.text = profile?.phone ?? '';
    _emailController.text = profile?.email ?? '';
    _residentialAddressController.text = profile?.address ?? '';
    _preferredZoneController.text = widget.initialPreferredZone ?? '';
    _location = widget.initialLocation;
    if (_location != null) {
      _locationAddressController.text = _location!.address;
    }
    for (final document in widget.initialDocuments) {
      _documents[document.type] = document;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _residentialAddressController.dispose();
    _identityController.dispose();
    _businessNameController.dispose();
    _descriptionController.dispose();
    _productsController.dispose();
    _registrationController.dispose();
    _locationSearchController.dispose();
    _locationAddressController.dispose();
    _preferredZoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final submitted = _submittedApplication;
    if (submitted != null) return _buildSuccess(context, submitted);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isPermissionApplication
              ? 'Apply for Vendor Permission'
              : 'Vendor Registration',
        ),
        leading: IconButton(
          tooltip: _step == 0 ? 'Close application' : 'Previous step',
          onPressed: _isSubmitting
              ? null
              : () {
                  if (_step == 0) {
                    Navigator.maybePop(context);
                  } else {
                    _previousStep();
                  }
                },
          icon: Icon(
            _step == 0 ? Icons.close_rounded : Icons.arrow_back_rounded,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _VendorWizardProgress(step: _step, labels: _stepLabels),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: VendorResponsiveBody(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: KeyedSubtree(
                      key: ValueKey(_step),
                      child: _buildStep(context),
                    ),
                  ),
                ),
              ),
            ),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context) => switch (_step) {
    0 => _buildApplicantStep(context),
    1 => _buildBusinessStep(context),
    2 => _buildLocationStep(context),
    3 => _buildOperationsStep(context),
    4 => _buildDocumentsStep(context),
    5 => _buildDeclarationStep(context),
    6 => _buildReviewStep(context),
    _ => _buildSubmitStep(context),
  };

  Widget _stepHeading({
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.vendor.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: AppColors.vendor),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.headline),
                const SizedBox(height: AppSpacing.xxs),
                Text(description, style: AppTypography.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicantStep(BuildContext context) {
    return Form(
      key: _applicantFormKey,
      autovalidateMode: _showErrors
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeading(
            title: 'Applicant Information',
            description:
                'Tell us who is applying. Review any details filled from your profile.',
            icon: Icons.person_outline_rounded,
          ),
          VendorDemoBanner(isDemo: widget.controller.isDemoMode),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _nameController,
            label: 'Full Name',
            prefixIcon: Icons.badge_outlined,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            validator: (value) => (value?.trim().length ?? 0) < 2
                ? 'Enter your full name.'
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _mobileController,
            label: 'Mobile Number',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            maxLength: 10,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            autofillHints: const [AutofillHints.telephoneNumber],
            validator: (value) => _validPhone(value ?? '')
                ? null
                : 'Enter a valid 10-digit mobile number.',
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _emailController,
            label: 'Email',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            validator: (value) => _validEmail(value ?? '')
                ? null
                : 'Enter a valid email address.',
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _residentialAddressController,
            label: 'Residential Address',
            prefixIcon: Icons.home_outlined,
            minLines: 2,
            maxLines: 3,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.fullStreetAddress],
            validator: _requiredValidator('Enter your residential address.'),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _identityController,
            label: 'Identity information',
            hint: 'For example, identity type and last four digits',
            prefixIcon: Icons.fingerprint_rounded,
            minLines: 2,
            maxLines: 3,
            textInputAction: TextInputAction.done,
            validator: _requiredValidator('Enter identity information.'),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Avoid entering full identity numbers unless they are required for this development service.',
            style: AppTypography.caption.copyWith(color: AppColors.warning),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessStep(BuildContext context) {
    return Form(
      key: _businessFormKey,
      autovalidateMode: _showErrors
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeading(
            title: 'Business Information',
            description:
                'Describe the business, what it offers, and any existing registration.',
            icon: Icons.storefront_outlined,
          ),
          AppTextField(
            controller: _businessNameController,
            label: 'Business Name',
            prefixIcon: Icons.business_outlined,
            textInputAction: TextInputAction.next,
            validator: _requiredValidator('Enter the business name.'),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _businessType,
            decoration: const InputDecoration(
              labelText: 'Business Type',
              prefixIcon: Icon(Icons.account_tree_outlined),
            ),
            items: _businessTypes
                .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                .toList(),
            onChanged: (value) => setState(() => _businessType = value),
            validator: (value) =>
                value == null ? 'Select a business type.' : null,
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _category,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Category',
              prefixIcon: Icon(Icons.category_outlined),
            ),
            items: _categories
                .map(
                  (category) =>
                      DropdownMenuItem(value: category, child: Text(category)),
                )
                .toList(),
            onChanged: (value) => setState(() => _category = value),
            validator: (value) => value == null ? 'Select a category.' : null,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _descriptionController,
            label: 'Description',
            hint: 'Briefly describe how the business operates',
            prefixIcon: Icons.notes_rounded,
            minLines: 3,
            maxLines: 5,
            textInputAction: TextInputAction.next,
            validator: (value) => (value?.trim().length ?? 0) < 10
                ? 'Enter at least 10 characters.'
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _productsController,
            label: 'Products/Services',
            hint: 'List the main products or services',
            prefixIcon: Icons.inventory_2_outlined,
            minLines: 2,
            maxLines: 4,
            textInputAction: TextInputAction.next,
            validator: _requiredValidator('Enter the products or services.'),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _registrationController,
            label: 'Existing Registration Number (optional)',
            prefixIcon: Icons.numbers_rounded,
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStep(BuildContext context) {
    return Form(
      key: _locationFormKey,
      autovalidateMode: _showErrors
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeading(
            title: 'Business Location',
            description:
                'Use GPS, search by area, or adjust the pin directly on the interactive map.',
            icon: Icons.location_on_outlined,
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.warningSoft,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.35),
              ),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: AppColors.warning),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Your requested location may require municipal approval.',
                    style: AppTypography.label,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isLocating ? null : _useCurrentLocation,
              icon: _isLocating
                  ? const SizedBox.square(
                      dimension: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.my_location_rounded),
              label: Text(
                _isLocating ? 'Getting location…' : 'Use Current Location',
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppTextField(
                  controller: _locationSearchController,
                  label: 'Search location',
                  hint: 'Area, landmark, or address in Nagpur',
                  prefixIcon: Icons.search_rounded,
                  textInputAction: TextInputAction.search,
                  onChanged: (_) {
                    if (_showErrors) setState(() {});
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              IconButton.filledTonal(
                tooltip: 'Search location',
                onPressed: _locationSearchController.text.trim().isEmpty
                    ? null
                    : _useSearchLocation,
                icon: const Icon(Icons.arrow_forward_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Search uses a configuration-free Nagpur development location; it is not a live geocoder.',
            style: AppTypography.caption,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_location == null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: _showErrors ? AppColors.errorSoft : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: _showErrors ? AppColors.error : AppColors.border,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.add_location_alt_outlined,
                    size: 42,
                    color: _showErrors
                        ? AppColors.error
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _showErrors
                        ? 'Select a business location to continue.'
                        : 'Choose GPS or search to place the initial map pin.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton.icon(
                    onPressed: _useDevelopmentLocation,
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Start with Nagpur center map'),
                  ),
                ],
              ),
            )
          else ...[
            DevelopmentMap(
              location: _location!,
              onChanged: (location) {
                setState(() {
                  _location = location;
                  _locationAddressController.text = location.address;
                });
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                children: [
                  VendorInfoRow(
                    label: 'Latitude',
                    value: _location!.latitude.toStringAsFixed(6),
                  ),
                  VendorInfoRow(
                    label: 'Longitude',
                    value: _location!.longitude.toStringAsFixed(6),
                  ),
                  VendorInfoRow(
                    label: 'GPS accuracy',
                    value: '±${_location!.accuracy.toStringAsFixed(0)} m',
                  ),
                ],
              ),
            ),
            if (_location!.hasLowAccuracy) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'GPS accuracy is low. Confirm the address and adjust the pin before continuing.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _locationAddressController,
            label: 'Address',
            hint: 'Business location address or nearby landmark',
            prefixIcon: Icons.place_outlined,
            minLines: 2,
            maxLines: 3,
            validator: _requiredValidator(
              'Enter the business location address.',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _preferredZoneController,
            label: 'Preferred zone',
            hint: 'For example, Civil Lines demo zone',
            prefixIcon: Icons.map_outlined,
            validator: _requiredValidator('Enter or select a preferred zone.'),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationsStep(BuildContext context) {
    return Form(
      key: _operationsFormKey,
      autovalidateMode: _showErrors
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeading(
            title: 'Operating Details',
            description:
                'Choose the proposed days, hours, duration, and outlet type.',
            icon: Icons.schedule_outlined,
          ),
          Text('Operating days', style: AppTypography.title),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: _days
                .map(
                  (day) => FilterChip(
                    label: Text(day.substring(0, 3)),
                    tooltip: day,
                    selected: _operatingDays.contains(day),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _operatingDays.add(day);
                        } else {
                          _operatingDays.remove(day);
                        }
                      });
                    },
                  ),
                )
                .toList(),
          ),
          if (_showErrors && _operatingDays.isEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Select at least one operating day.',
              style: Theme.of(context).inputDecorationTheme.errorStyle,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 480;
              final start = _TimeField(
                label: 'Start time',
                value: _startTime,
                hasError: _showErrors && _startTime.isEmpty,
                onTap: () => _pickTime(isStart: true),
              );
              final end = _TimeField(
                label: 'End time',
                value: _endTime,
                hasError: _showErrors && _endTime.isEmpty,
                onTap: () => _pickTime(isStart: false),
              );
              if (compact) {
                return Column(
                  children: [
                    start,
                    const SizedBox(height: AppSpacing.md),
                    end,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: start),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: end),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Temporary/Permanent', style: AppTypography.title),
          const SizedBox(height: AppSpacing.xs),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'Temporary',
                label: Text('Temporary'),
                icon: Icon(Icons.event_outlined),
              ),
              ButtonSegment(
                value: 'Permanent',
                label: Text('Permanent'),
                icon: Icon(Icons.store_outlined),
              ),
            ],
            selected: {_durationType},
            onSelectionChanged: (selection) {
              setState(() => _durationType = selection.first);
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          DropdownButtonFormField<String>(
            initialValue: _outletType,
            decoration: const InputDecoration(
              labelText: 'Stall/Cart/Shop type',
              prefixIcon: Icon(Icons.store_mall_directory_outlined),
            ),
            items: _outletTypes
                .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                .toList(),
            onChanged: (value) => setState(() => _outletType = value),
            validator: (value) =>
                value == null ? 'Select an outlet type.' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsStep(BuildContext context) {
    final missing = _requiredDocumentsMissing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeading(
          title: 'Documents',
          description:
              'Attach PDF, JPG, JPEG, or PNG files. Labels describe this demo flow and are not legal advice.',
          icon: Icons.folder_copy_outlined,
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.infoSoft,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Text(
            _category == 'Food & Beverage'
                ? 'Food-related documentation is shown as Conditional. Requirements depend on the business and municipal review.'
                : 'Conditional documents are only relevant in some circumstances. Not every listed document is legally required.',
            style: AppTypography.bodySmall,
          ),
        ),
        if (_showErrors && missing.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.errorSoft,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.error),
            ),
            child: Text(
              'Choose the required files: ${missing.join(', ')}.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        ..._documentSpecs.expand(
          (spec) => [
            VendorDocumentUploadCard(
              type: spec.type,
              label: spec.label,
              requirement: spec.requirement,
              document: _documents[spec.type],
              isBusy: _pickingDocumentType == spec.type,
              supportingText: spec.help,
              onPick: () => _pickDocument(spec),
              onRemove: _documents.containsKey(spec.type)
                  ? () => setState(() => _documents.remove(spec.type))
                  : null,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ],
    );
  }

  Widget _buildDeclarationStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeading(
          title: 'Declaration',
          description:
              'Read and accept the declaration before reviewing your application.',
          icon: Icons.fact_check_outlined,
        ),
        VendorDemoBanner(isDemo: widget.controller.isDemoMode),
        const SizedBox(height: AppSpacing.lg),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Applicant declaration', style: AppTypography.titleLarge),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'I confirm that the information entered in this application is accurate to the best of my knowledge. I understand that submitting through this development service does not create a municipal application, approval, licence, or permission.',
                  style: AppTypography.body,
                ),
                const SizedBox(height: AppSpacing.md),
                CheckboxListTile(
                  value: _acceptedDeclaration,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('I have read and accept the declaration.'),
                  subtitle: _showErrors && !_acceptedDeclaration
                      ? Text(
                          'Acceptance is required to continue.',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        )
                      : null,
                  onChanged: (value) {
                    setState(() => _acceptedDeclaration = value ?? false);
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewStep(BuildContext context) {
    final location = _location!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeading(
          title: 'Review Application',
          description: 'Check each section before moving to submission.',
          icon: Icons.preview_outlined,
        ),
        VendorSectionCard(
          title: 'Applicant Information',
          icon: Icons.person_outline_rounded,
          onEdit: () => _goToStep(0),
          children: [
            VendorInfoRow(
              label: 'Full Name',
              value: _nameController.text.trim(),
            ),
            VendorInfoRow(
              label: 'Mobile Number',
              value: _mobileController.text.trim(),
            ),
            VendorInfoRow(label: 'Email', value: _emailController.text.trim()),
            VendorInfoRow(
              label: 'Residential Address',
              value: _residentialAddressController.text.trim(),
            ),
            VendorInfoRow(
              label: 'Identity information',
              value: _identityController.text.trim(),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        VendorSectionCard(
          title: 'Business Information',
          icon: Icons.storefront_outlined,
          onEdit: () => _goToStep(1),
          children: [
            VendorInfoRow(
              label: 'Business Name',
              value: _businessNameController.text.trim(),
            ),
            VendorInfoRow(label: 'Business Type', value: _businessType ?? ''),
            VendorInfoRow(label: 'Category', value: _category ?? ''),
            VendorInfoRow(
              label: 'Description',
              value: _descriptionController.text.trim(),
            ),
            VendorInfoRow(
              label: 'Products/Services',
              value: _productsController.text.trim(),
            ),
            VendorInfoRow(
              label: 'Registration No.',
              value: _registrationController.text.trim(),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        VendorSectionCard(
          title: 'Business Location',
          icon: Icons.location_on_outlined,
          onEdit: () => _goToStep(2),
          children: [
            VendorInfoRow(
              label: 'Address',
              value: _locationAddressController.text.trim(),
            ),
            VendorInfoRow(
              label: 'Preferred zone',
              value: _preferredZoneController.text.trim(),
            ),
            VendorInfoRow(label: 'Coordinates', value: location.coordinates),
            VendorInfoRow(
              label: 'Accuracy',
              value: '±${location.accuracy.toStringAsFixed(0)} m',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        VendorSectionCard(
          title: 'Operating Details',
          icon: Icons.schedule_outlined,
          onEdit: () => _goToStep(3),
          children: [
            VendorInfoRow(
              label: 'Operating days',
              value: _orderedOperatingDays.join(', '),
            ),
            VendorInfoRow(label: 'Hours', value: '$_startTime – $_endTime'),
            VendorInfoRow(label: 'Duration', value: _durationType),
            VendorInfoRow(label: 'Outlet type', value: _outletType ?? ''),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        VendorSectionCard(
          title: 'Documents',
          icon: Icons.folder_copy_outlined,
          onEdit: () => _goToStep(4),
          children: _documentSpecs
              .map(
                (spec) => VendorInfoRow(
                  label: spec.label,
                  value: _documents[spec.type] == null
                      ? documentRequirementLabel(spec.requirement)
                      : vendorFileName(_documents[spec.type]!.path),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: AppSpacing.sm),
        VendorSectionCard(
          title: 'Declaration',
          icon: Icons.verified_user_outlined,
          onEdit: () => _goToStep(5),
          children: const [VendorInfoRow(label: 'Accepted', value: 'Yes')],
        ),
      ],
    );
  }

  Widget _buildSubmitStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeading(
          title: 'Ready to Submit',
          description: widget.controller.isDemoMode
              ? 'Your completed application will be stored locally for this demo session.'
              : 'Your completed application and documents will be securely stored in your cloud account.',
          icon: Icons.send_outlined,
        ),
        VendorDemoBanner(
          isDemo: widget.controller.isDemoMode,
          message: widget.controller.isDemoMode
              ? 'Submitting creates a local demo application. It is not filed with a municipal department and does not grant permission.'
              : 'Submitting saves this application to Supabase. It is not yet filed with a municipal department and does not grant permission.',
        ),
        const SizedBox(height: AppSpacing.lg),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                const Icon(
                  Icons.assignment_turned_in_outlined,
                  size: 58,
                  color: AppColors.vendor,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  _businessNameController.text.trim(),
                  style: AppTypography.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${_category ?? ''} · ${_preferredZoneController.text.trim()}',
                  style: AppTypography.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                const Divider(),
                VendorInfoRow(
                  label: 'Applicant',
                  value: _nameController.text.trim(),
                ),
                VendorInfoRow(
                  label: 'Documents',
                  value: '${_documents.length} attached',
                ),
                VendorInfoRow(
                  label: 'Declaration',
                  value: _acceptedDeclaration ? 'Accepted' : 'Not accepted',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    final finalStep = _step == _stepLabels.length - 1;
    return Material(
      elevation: 12,
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.sm,
            AppSpacing.page,
            AppSpacing.sm,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Row(
                children: [
                  if (_step > 0) ...[
                    OutlinedButton(
                      onPressed: _isSubmitting ? null : _previousStep,
                      child: const Text('Back'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isSubmitting ? null : _continue,
                      icon: _isSubmitting
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              finalStep
                                  ? Icons.send_rounded
                                  : Icons.arrow_forward_rounded,
                            ),
                      label: Text(
                        _isSubmitting
                            ? 'Submitting…'
                            : finalStep
                            ? 'Submit Application'
                            : _step == 6
                            ? 'Continue to Submit'
                            : 'Continue',
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

  Future<void> _continue() async {
    setState(() => _showErrors = true);
    if (!_validateCurrentStep()) return;
    FocusScope.of(context).unfocus();
    if (_step < _stepLabels.length - 1) {
      setState(() {
        _step++;
        _showErrors = false;
      });
      return;
    }
    await _submit();
  }

  bool _validateCurrentStep() => switch (_step) {
    0 => _applicantFormKey.currentState?.validate() ?? false,
    1 => _businessFormKey.currentState?.validate() ?? false,
    2 =>
      (_locationFormKey.currentState?.validate() ?? false) && _location != null,
    3 =>
      (_operationsFormKey.currentState?.validate() ?? false) &&
          _operatingDays.isNotEmpty &&
          _startTime.isNotEmpty &&
          _endTime.isNotEmpty,
    4 => _requiredDocumentsMissing.isEmpty,
    5 => _acceptedDeclaration,
    _ => true,
  };

  void _previousStep() {
    if (_step == 0) return;
    setState(() {
      _step--;
      _showErrors = false;
    });
  }

  void _goToStep(int step) {
    setState(() {
      _step = step;
      _showErrors = false;
    });
  }

  Future<void> _submit() async {
    final location = _location;
    if (location == null) return;
    setState(() => _isSubmitting = true);
    try {
      final application = await widget.controller.submitVendorApplication(
        VendorApplicationDraft(
          applicantName: _nameController.text.trim(),
          mobile: _mobileController.text.trim(),
          email: _emailController.text.trim(),
          residentialAddress: _residentialAddressController.text.trim(),
          identityInformation: _identityController.text.trim(),
          businessName: _businessNameController.text.trim(),
          businessType: _businessType!,
          category: _category!,
          description: _descriptionController.text.trim(),
          productsServices: _productsController.text.trim(),
          registrationNumber: _registrationController.text.trim(),
          location: location.copyWith(
            address: _locationAddressController.text.trim(),
          ),
          preferredZone: _preferredZoneController.text.trim(),
          operatingDays: _orderedOperatingDays,
          startTime: _startTime,
          endTime: _endTime,
          durationType: _durationType,
          outletType: _outletType!,
          documents: _documentSpecs
              .map((spec) => _documents[spec.type])
              .whereType<VendorDocument>()
              .toList(growable: false),
          acceptedDeclaration: _acceptedDeclaration,
        ),
      );
      if (!mounted) return;
      setState(() => _submittedApplication = application);
    } on ArgumentError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message?.toString() ?? 'Check the form.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.controller.isDemoMode
                ? 'The demo application could not be saved. Please try again.'
                : 'The application could not be saved to your cloud account. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      final location = await _locationService.getCurrentLocation();
      if (!mounted) return;
      setState(() {
        _location = location;
        _locationAddressController.text = location.address;
      });
    } on LocationServiceException catch (error) {
      if (!mounted) return;
      await _showLocationError(error);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Current location is unavailable. Use search or the development map.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _showLocationError(LocationServiceException error) async {
    final openSettings = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Location unavailable'),
        content: Text(error.message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Use map'),
          ),
          if (error.access == LocationAccess.deniedForever ||
              error.access == LocationAccess.serviceDisabled)
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Open settings'),
            ),
        ],
      ),
    );
    if (openSettings == true) {
      if (error.access == LocationAccess.serviceDisabled) {
        await _locationService.openLocationSettings();
      } else {
        await _locationService.openAppSettings();
      }
    } else {
      _useDevelopmentLocation();
    }
  }

  void _useSearchLocation() {
    final query = _locationSearchController.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _location = ProblemLocation(
        latitude: 21.1458,
        longitude: 79.0882,
        accuracy: 80,
        address: '$query (development selection)',
      );
      _locationAddressController.text = '$query, Nagpur';
    });
  }

  void _useDevelopmentLocation() {
    const location = ProblemLocation(
      latitude: 21.1458,
      longitude: 79.0882,
      accuracy: 80,
      address: 'Central Nagpur (adjust the pin)',
    );
    setState(() {
      _location = location;
      _locationAddressController.text = location.address;
    });
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial =
        _parseTime(isStart ? _startTime : _endTime) ??
        (isStart
            ? const TimeOfDay(hour: 9, minute: 0)
            : const TimeOfDay(hour: 18, minute: 0));
    final selected = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (selected == null || !mounted) return;
    final value =
        '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}';
    setState(() {
      if (isStart) {
        _startTime = value;
      } else {
        _endTime = value;
      }
    });
  }

  TimeOfDay? _parseTime(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> _pickDocument(_DocumentSpec spec) async {
    setState(() => _pickingDocumentType = spec.type);
    try {
      final picked = await _documentPickerService.pickDocuments();
      if (!mounted || picked.isEmpty) return;
      setState(() {
        _documents[spec.type] = VendorDocument(
          type: spec.type,
          label: spec.label,
          path: picked.first.path,
          requirement: spec.requirement,
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
      if (mounted) setState(() => _pickingDocumentType = null);
    }
  }

  Widget _buildSuccess(BuildContext context, VendorApplication application) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: VendorResponsiveBody(
            padding: const EdgeInsets.all(AppSpacing.xl),
            maxWidth: 620,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.sizeOf(context).height - 96,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: const BoxDecoration(
                      color: AppColors.successSoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 54,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Application Submitted',
                    style: AppTypography.headline,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    application.isDemo
                        ? 'Saved on this device in demo mode. No municipal review or approval has occurred.'
                        : 'Securely saved to your cloud account. Municipal review is not yet connected in this development build.',
                    style: AppTypography.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  VendorSectionCard(
                    title: 'Submission details',
                    icon: Icons.receipt_long_outlined,
                    children: [
                      VendorInfoRow(
                        label: 'Application ID',
                        value: application.id,
                      ),
                      VendorInfoRow(
                        label: 'Business',
                        value: application.businessName,
                      ),
                      VendorInfoRow(
                        label: 'Submitted',
                        value: vendorFormatDate(application.createdAt),
                      ),
                      const VendorInfoRow(label: 'Status', value: 'Submitted'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute<void>(
                            builder: (_) => VendorApplicationDetailScreen(
                              controller: widget.controller,
                              application: application,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.timeline_rounded),
                      label: const Text('Track Application'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextButton(
                    onPressed: () => Navigator.maybePop(context),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<String> get _requiredDocumentsMissing => _documentSpecs
      .where(
        (spec) =>
            spec.requirement == DocumentRequirement.required &&
            !_documents.containsKey(spec.type),
      )
      .map((spec) => spec.label)
      .toList(growable: false);

  List<String> get _orderedOperatingDays =>
      _days.where(_operatingDays.contains).toList(growable: false);

  FormFieldValidator<String> _requiredValidator(String message) {
    return (value) => value == null || value.trim().isEmpty ? message : null;
  }

  bool _validPhone(String value) => RegExp(r'^\d{10}$').hasMatch(value.trim());

  bool _validEmail(String value) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim());
}

class _VendorWizardProgress extends StatelessWidget {
  const _VendorWizardProgress({required this.step, required this.labels});

  final int step;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Semantics(
        label: 'Step ${step + 1} of ${labels.length}: ${labels[step]}',
        value: '${((step + 1) / labels.length * 100).round()} percent',
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.xxs,
            AppSpacing.page,
            AppSpacing.sm,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Step ${step + 1} of ${labels.length}',
                        style: AppTypography.label.copyWith(
                          color: AppColors.vendor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Flexible(
                        child: Text(
                          labels[step],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  LinearProgressIndicator(
                    value: (step + 1) / labels.length,
                    minHeight: 7,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    color: AppColors.vendor,
                    backgroundColor: AppColors.primarySoft,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.value,
    required this.onTap,
    required this.hasError,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InputDecorator(
        isEmpty: value.isEmpty,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.access_time_rounded),
          errorText: hasError ? 'Choose a time.' : null,
          suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
        ),
        child: Text(value.isEmpty ? 'Select time' : value),
      ),
    );
  }
}

class _DocumentSpec {
  const _DocumentSpec({
    required this.type,
    required this.label,
    required this.requirement,
    this.help,
  });

  final String type;
  final String label;
  final DocumentRequirement requirement;
  final String? help;
}
