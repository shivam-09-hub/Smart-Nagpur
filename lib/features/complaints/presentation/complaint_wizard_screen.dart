import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_nagpur/core/services/services.dart';
import 'package:smart_nagpur/core/theme/theme.dart';
import 'package:smart_nagpur/domain/domain.dart';
import 'package:smart_nagpur/features/complaints/presentation/widgets/development_map.dart';
import 'package:smart_nagpur/state/app_controller.dart';

class ComplaintWizardScreen extends StatefulWidget {
  const ComplaintWizardScreen({
    required this.controller,
    this.serviceType = ServiceType.roads,
    this.initialIssue,
    this.locationService,
    this.mediaPickerService,
    super.key,
  });

  final AppController controller;
  final ServiceType serviceType;
  final String? initialIssue;
  final LocationService? locationService;
  final MediaPickerService? mediaPickerService;

  @override
  State<ComplaintWizardScreen> createState() => _ComplaintWizardScreenState();
}

class _ComplaintWizardScreenState extends State<ComplaintWizardScreen> {
  static const _stepLabels = [
    'Choose issue',
    'Description',
    'Photo',
    'Location',
    'Contact',
    'Review',
  ];

  static const Map<ServiceType, List<String>> _issues = {
    ServiceType.garbage: [
      'Missed collection',
      'Overflowing garbage',
      'Illegal dumping',
      'Open garbage point',
    ],
    ServiceType.water: [
      'No water',
      'Leakage',
      'Pipeline damage',
      'Water quality concern',
    ],
    ServiceType.roads: [
      'Pothole',
      'Road damage',
      'Broken footpath',
      'Open excavation',
      'Missing or damaged road sign',
      'Traffic obstruction',
    ],
    ServiceType.animals: [
      'Stray animal',
      'Injured animal',
      'Rescue request',
      'Animal nuisance',
      'Dead animal',
    ],
    ServiceType.drainage: [
      'Blocked drain',
      'Waterlogging',
      'Open drain',
      'Flooding',
    ],
    ServiceType.streetlights: [
      'Streetlight not working',
      'Damaged pole',
      'Exposed wire',
      'Electrical hazard',
    ],
    ServiceType.publicSpaces: [
      'Park issue',
      'Playground issue',
      'Public toilet issue',
      'Damaged public property',
      'Cleanliness issue',
    ],
    ServiceType.encroachment: [
      'Road encroachment',
      'Illegal obstruction',
      'Unauthorized construction',
      'Unauthorized vendor',
      'Public space encroachment',
    ],
    ServiceType.other: ['Other civic issue'],
    ServiceType.vendor: ['Vendor service concern'],
  };

  late ServiceType _serviceType;
  String? _issue;
  int _step = 0;
  bool _showErrors = false;
  bool _isLocating = false;
  bool _isPickingPhoto = false;
  bool _isSubmitting = false;
  ComplaintRecord? _submitted;
  ProblemLocation? _location;
  String? _photoPath;
  String _severity = 'Medium';
  String _animalType = 'Dog';
  String _animalCondition = 'Needs assessment';
  String _urgency = 'Normal';

  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _citizenAddressController = TextEditingController();
  final _problemAddressController = TextEditingController();

  LocationService get _locationService =>
      widget.locationService ?? const DeviceLocationService();
  MediaPickerService get _mediaService =>
      widget.mediaPickerService ?? DeviceMediaPickerService();

  @override
  void initState() {
    super.initState();
    _serviceType = widget.serviceType == ServiceType.vendor
        ? ServiceType.other
        : widget.serviceType;
    final availableIssues = _issues[_serviceType] ?? const <String>[];
    if (widget.initialIssue != null && widget.initialIssue!.trim().isNotEmpty) {
      _issue = _normaliseIssue(widget.initialIssue!, availableIssues);
    }
    _phoneController.text = widget.controller.profile?.phone ?? '';
    _citizenAddressController.text = widget.controller.profile?.address ?? '';
  }

  String _normaliseIssue(String value, List<String> available) {
    final cleaned = value.replaceFirst(
      RegExp('^Report ', caseSensitive: false),
      '',
    );
    for (final issue in available) {
      if (issue.toLowerCase() == cleaned.toLowerCase()) return issue;
    }
    return cleaned;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _phoneController.dispose();
    _citizenAddressController.dispose();
    _problemAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted != null) return _buildSuccess(context, _submitted!);
    final color = _serviceType.color;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report a problem'),
        leading: IconButton(
          tooltip: _step == 0 ? 'Close' : 'Previous step',
          onPressed: _isSubmitting
              ? null
              : () {
                  if (_step == 0) {
                    Navigator.maybePop(context);
                  } else {
                    setState(() {
                      _step--;
                      _showErrors = false;
                    });
                  }
                },
          icon: Icon(_step == 0 ? Icons.close : Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _WizardProgress(step: _step, labels: _stepLabels, color: color),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: KeyedSubtree(
                    key: ValueKey(_step),
                    child: _buildStep(context, color),
                  ),
                ),
              ),
            ),
            _buildFooter(context, color),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context, Color color) => switch (_step) {
    0 => _buildIssueStep(context, color),
    1 => _buildDescriptionStep(context, color),
    2 => _buildPhotoStep(context, color),
    3 => _buildLocationStep(context, color),
    4 => _buildContactStep(context, color),
    _ => _buildReviewStep(context, color),
  };

  Widget _stepHeading(
    BuildContext context, {
    required String title,
    required String body,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 16),
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text(body, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildIssueStep(BuildContext context, Color color) {
    final availableIssues = _issues[_serviceType] ?? const <String>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeading(
          context,
          title: 'What needs attention?',
          body: 'Choose the civic service and the issue you want to report.',
          icon: Icons.report_outlined,
          color: color,
        ),
        DropdownButtonFormField<ServiceType>(
          initialValue: _serviceType,
          decoration: const InputDecoration(labelText: 'Civic service'),
          items: ServiceType.values
              .where((type) => type != ServiceType.vendor)
              .map(
                (type) =>
                    DropdownMenuItem(value: type, child: Text(type.title)),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _serviceType = value;
              _issue = null;
              _showErrors = false;
            });
          },
        ),
        const SizedBox(height: 20),
        Text('Issue', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        ...availableIssues.map(
          (issue) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: _issue == issue
                  ? color.withValues(alpha: 0.1)
                  : Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: _issue == issue
                      ? color
                      : Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: ListTile(
                leading: Icon(
                  _issue == issue
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: _issue == issue ? color : null,
                ),
                title: Text(issue),
                onTap: () => setState(() => _issue = issue),
              ),
            ),
          ),
        ),
        if (_showErrors && (_issue == null || _issue!.isEmpty))
          Text(
            'Choose an issue to continue.',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
      ],
    );
  }

  Widget _buildDescriptionStep(BuildContext context, Color color) {
    final isAnimal = _serviceType == ServiceType.animals;
    final isDrainage = _serviceType == ServiceType.drainage;
    final isElectricalHazard =
        _serviceType == ServiceType.streetlights &&
        (_issue?.toLowerCase().contains('wire') == true ||
            _issue?.toLowerCase().contains('hazard') == true);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeading(
          context,
          title: 'Tell us what you can see',
          body: 'A clear description helps classify your report correctly.',
          icon: Icons.notes_rounded,
          color: color,
        ),
        if (isElectricalHazard) ...[
          _WarningCard(
            icon: Icons.electrical_services,
            color: Colors.amber.shade900,
            title: 'Keep a safe distance',
            body:
                'Do not touch exposed wires or damaged poles. If there is immediate danger, contact emergency services.',
          ),
          const SizedBox(height: 16),
        ],
        TextFormField(
          controller: _descriptionController,
          minLines: 5,
          maxLines: 8,
          maxLength: 600,
          decoration: InputDecoration(
            labelText: 'Description',
            hintText: 'Describe the issue and nearby landmarks',
            errorText:
                _showErrors && _descriptionController.text.trim().length < 10
                ? 'Enter at least 10 characters.'
                : null,
            alignLabelWithHint: true,
          ),
          onChanged: (_) {
            if (_showErrors) setState(() {});
          },
        ),
        if (isAnimal) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _animalType,
            decoration: const InputDecoration(labelText: 'Animal type'),
            items: const ['Dog', 'Cat', 'Cattle', 'Bird', 'Other']
                .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(),
            onChanged: (value) =>
                setState(() => _animalType = value ?? 'Other'),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _animalCondition,
            decoration: const InputDecoration(labelText: 'Condition'),
            items:
                const [
                      'Needs assessment',
                      'Injured',
                      'Aggressive',
                      'Unable to move',
                      'Deceased',
                    ]
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
            onChanged: (value) =>
                setState(() => _animalCondition = value ?? _animalCondition),
          ),
        ],
        if (isDrainage) ...[
          const SizedBox(height: 18),
          Text('Severity', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['Low', 'Medium', 'High', 'Critical']
                .map(
                  (value) => ChoiceChip(
                    label: Text(value),
                    selected: _severity == value,
                    onSelected: (_) => setState(() => _severity = value),
                  ),
                )
                .toList(),
          ),
        ],
        if (isAnimal || isDrainage) ...[
          const SizedBox(height: 18),
          Text('Urgency', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'Normal', label: Text('Normal')),
              ButtonSegment(value: 'Urgent', label: Text('Urgent')),
            ],
            selected: {_urgency},
            onSelectionChanged: (value) =>
                setState(() => _urgency = value.first),
          ),
        ],
      ],
    );
  }

  Widget _buildPhotoStep(BuildContext context, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeading(
          context,
          title: 'Add a photo',
          body:
              'A photo is optional, but it can help explain the problem. Review it before continuing.',
          icon: Icons.add_a_photo_outlined,
          color: color,
        ),
        if (_photoPath != null)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Image.file(
                    File(_photoPath!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Theme.of(context).colorScheme.errorContainer,
                      alignment: Alignment.center,
                      child: const Text('This image cannot be previewed.'),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 10,
                top: 10,
                child: IconButton.filled(
                  tooltip: 'Remove photo',
                  onPressed: _removePhoto,
                  icon: const Icon(Icons.delete_outline),
                ),
              ),
            ],
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 20),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.28)),
            ),
            child: Column(
              children: [
                Icon(Icons.photo_camera_back_outlined, color: color, size: 48),
                const SizedBox(height: 12),
                const Text('No photo selected'),
              ],
            ),
          ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isPickingPhoto ? null : () => _pickPhoto(true),
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Take photo'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: _isPickingPhoto ? null : () => _pickPhoto(false),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Gallery'),
              ),
            ),
          ],
        ),
        if (_isPickingPhoto) ...[
          const SizedBox(height: 16),
          const LinearProgressIndicator(),
        ],
      ],
    );
  }

  Widget _buildLocationStep(BuildContext context, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeading(
          context,
          title: 'Confirm the problem location',
          body:
              'This is separate from your home address. Check the pin before continuing.',
          icon: Icons.location_on_outlined,
          color: color,
        ),
        FilledButton.icon(
          onPressed: _isLocating ? null : _useCurrentLocation,
          icon: _isLocating
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.my_location),
          label: Text(
            _isLocating ? 'Getting location…' : 'Use current location',
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _useDevelopmentLocation,
          icon: const Icon(Icons.map_outlined),
          label: const Text('Select location on map'),
        ),
        if (_location != null) ...[
          const SizedBox(height: 20),
          DevelopmentMap(
            location: _location!,
            onChanged: (location) {
              setState(() {
                _location = location;
                _problemAddressController.text = location.address;
              });
            },
          ),
          const SizedBox(height: 14),
          if (_location!.hasLowAccuracy) ...[
            const _WarningCard(
              icon: Icons.gps_off,
              color: Color(0xFFB45309),
              title: 'Location accuracy is low',
              body:
                  'Try again or adjust the pin before confirming this location.',
            ),
            const SizedBox(height: 14),
          ],
          TextFormField(
            controller: _problemAddressController,
            minLines: 2,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Problem address or landmark',
              errorText:
                  _showErrors && _problemAddressController.text.trim().isEmpty
                  ? 'Enter an address or landmark.'
                  : null,
            ),
            onChanged: (value) {
              if (_location != null) {
                _location = _location!.copyWith(address: value.trim());
              }
              if (_showErrors) setState(() {});
            },
          ),
          const SizedBox(height: 12),
          _DetailTile(
            icon: Icons.pin_drop_outlined,
            label: 'Coordinates',
            value: _location!.coordinates,
          ),
          _DetailTile(
            icon: Icons.gps_fixed,
            label: 'GPS accuracy',
            value: '±${_location!.accuracy.toStringAsFixed(0)} metres',
          ),
        ] else if (_showErrors) ...[
          const SizedBox(height: 14),
          Text(
            'Select the problem location to continue.',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }

  Widget _buildContactStep(BuildContext context, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeading(
          context,
          title: 'How can we contact you?',
          body:
              'Your contact details are used for this report and are not the problem location.',
          icon: Icons.contact_phone_outlined,
          color: color,
        ),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          decoration: InputDecoration(
            labelText: 'Contact phone',
            prefixText: '+91 ',
            errorText: _showErrors && !_validPhone(_phoneController.text)
                ? 'Enter a valid 10-digit mobile number.'
                : null,
          ),
          onChanged: (_) {
            if (_showErrors) setState(() {});
          },
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _citizenAddressController,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Home address (optional)',
            helperText: 'Kept separate from the problem location',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 18),
        const _WarningCard(
          icon: Icons.shield_outlined,
          color: Color(0xFF0F766E),
          title: 'Demo submission',
          body:
              'This MVP stores your report only on this device. It is not sent to a municipal department.',
        ),
      ],
    );
  }

  Widget _buildReviewStep(BuildContext context, Color color) {
    final location = _location!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeading(
          context,
          title: 'Review your report',
          body: 'Check the information below before submitting.',
          icon: Icons.fact_check_outlined,
          color: color,
        ),
        _ReviewSection(
          title: 'Issue',
          onEdit: () => setState(() => _step = 0),
          children: [
            _ReviewRow(label: 'Category', value: _serviceType.title),
            _ReviewRow(label: 'Issue', value: _issue!),
          ],
        ),
        _ReviewSection(
          title: 'Description',
          onEdit: () => setState(() => _step = 1),
          children: [
            Text(_descriptionController.text.trim()),
            if (_serviceType == ServiceType.drainage)
              _ReviewRow(label: 'Severity', value: _severity),
            if (_serviceType == ServiceType.animals) ...[
              _ReviewRow(label: 'Animal', value: _animalType),
              _ReviewRow(label: 'Condition', value: _animalCondition),
            ],
          ],
        ),
        _ReviewSection(
          title: 'Photo',
          onEdit: () => setState(() => _step = 2),
          children: [
            Text(_photoPath == null ? 'No photo attached' : '1 photo attached'),
          ],
        ),
        _ReviewSection(
          title: 'Problem location',
          onEdit: () => setState(() => _step = 3),
          children: [
            Text(location.address),
            _ReviewRow(
              label: 'Latitude',
              value: location.latitude.toStringAsFixed(6),
            ),
            _ReviewRow(
              label: 'Longitude',
              value: location.longitude.toStringAsFixed(6),
            ),
            _ReviewRow(
              label: 'Accuracy',
              value: '±${location.accuracy.toStringAsFixed(0)} m',
            ),
          ],
        ),
        _ReviewSection(
          title: 'Contact',
          onEdit: () => setState(() => _step = 4),
          children: [Text('+91 ${_phoneController.text.trim()}')],
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context, Color color) {
    return Material(
      elevation: 10,
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            children: [
              if (_step > 0) ...[
                OutlinedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => setState(() {
                          _step--;
                          _showErrors = false;
                        }),
                  child: const Text('Back'),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: color),
                  onPressed: _isSubmitting ? null : _continue,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: _isSubmitting
                        ? const SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _step == _stepLabels.length - 1
                                ? 'Submit report'
                                : 'Continue',
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _continue() async {
    setState(() => _showErrors = true);
    if (!_currentStepValid) return;
    if (_step < _stepLabels.length - 1) {
      setState(() {
        _step++;
        _showErrors = false;
      });
      return;
    }
    await _submit();
  }

  bool get _currentStepValid => switch (_step) {
    0 => _issue?.trim().isNotEmpty == true,
    1 => _descriptionController.text.trim().length >= 10,
    2 => true,
    3 => _location != null && _problemAddressController.text.trim().isNotEmpty,
    4 => _validPhone(_phoneController.text),
    _ => true,
  };

  bool _validPhone(String value) => RegExp(r'^\d{10}$').hasMatch(value.trim());

  Future<void> _submit() async {
    final location = _location!.copyWith(
      address: _problemAddressController.text.trim(),
    );
    final extraFields = <String, String>{};
    if (_serviceType == ServiceType.animals) {
      extraFields.addAll({
        'Animal type': _animalType,
        'Condition': _animalCondition,
        'Urgency': _urgency,
      });
    }
    if (_serviceType == ServiceType.drainage) {
      extraFields.addAll({'Severity': _severity, 'Urgency': _urgency});
    }
    setState(() => _isSubmitting = true);
    try {
      final record = await widget.controller.submitComplaint(
        ComplaintDraft(
          serviceType: _serviceType,
          issue: _issue!,
          description: _descriptionController.text.trim(),
          photoPaths: _photoPath == null ? const [] : [_photoPath!],
          location: location,
          contactPhone: _phoneController.text.trim(),
          citizenAddress: _citizenAddressController.text.trim(),
          extraFields: extraFields,
        ),
      );
      if (!mounted) return;
      setState(() => _submitted = record);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The report could not be saved. Please try again.'),
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
        _problemAddressController.text = location.address;
      });
    } on LocationServiceException catch (error) {
      if (!mounted) return;
      await _showLocationError(error);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Current location is unavailable. Select the pin manually.',
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
      builder: (context) => AlertDialog(
        title: const Text('Location unavailable'),
        content: Text(error.message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Use map'),
          ),
          if (error.access == LocationAccess.deniedForever ||
              error.access == LocationAccess.serviceDisabled)
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
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

  void _useDevelopmentLocation() {
    const location = ProblemLocation(
      latitude: 21.1458,
      longitude: 79.0882,
      accuracy: 80,
      address: 'Central Nagpur (adjust the pin)',
    );
    setState(() {
      _location = location;
      _problemAddressController.text = location.address;
    });
  }

  Future<void> _pickPhoto(bool camera) async {
    setState(() => _isPickingPhoto = true);
    try {
      final media = camera
          ? await _mediaService.takePhoto()
          : await _mediaService.choosePhoto();
      if (!mounted || media == null) return;
      setState(() => _photoPath = media.path);
    } on MediaPickerException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo selection is unavailable.')),
      );
    } finally {
      if (mounted) setState(() => _isPickingPhoto = false);
    }
  }

  Future<void> _removePhoto() async {
    final path = _photoPath;
    if (path == null) return;
    setState(() => _photoPath = null);
    try {
      await _mediaService.removeManagedMedia(path);
    } catch (_) {
      // The UI is already cleared. A stale managed file is harmless.
    }
  }

  Widget _buildSuccess(BuildContext context, ComplaintRecord record) {
    final color = record.serviceType.color;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
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
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_rounded, size: 54, color: color),
                ),
                const SizedBox(height: 24),
                Text(
                  'Report Submitted',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  record.isDemo
                      ? 'Saved on this device in demo mode. No municipal department has processed it.'
                      : 'Securely saved to your Smart Nagpur cloud account. Municipal processing is not yet connected in this development build.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _ReviewRow(label: 'Complaint ID', value: record.id),
                        _ReviewRow(
                          label: 'Category',
                          value: record.serviceType.title,
                        ),
                        _ReviewRow(label: 'Issue', value: record.issue),
                        _ReviewRow(
                          label: 'Location',
                          value: record.location.address,
                        ),
                        _ReviewRow(
                          label: 'Date',
                          value: DateFormat(
                            'd MMM yyyy, h:mm a',
                          ).format(record.createdAt.toLocal()),
                        ),
                        _ReviewRow(label: 'Status', value: record.status.label),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pushReplacementNamed(
                      context,
                      '/requests/${record.id}',
                      arguments: record.id,
                    ),
                    child: const Text('Track Request'),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/home',
                    (route) => false,
                  ),
                  child: const Text('Return to Home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WizardProgress extends StatelessWidget {
  const _WizardProgress({
    required this.step,
    required this.labels,
    required this.color,
  });

  final int step;
  final List<String> labels;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Step ${step + 1} of ${labels.length}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
                const Spacer(),
                Flexible(
                  child: Text(
                    labels[step],
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: (step + 1) / labels.length,
              minHeight: 6,
              borderRadius: BorderRadius.circular(999),
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}

class _WarningCard extends StatelessWidget {
  const _WarningCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewSection extends StatelessWidget {
  const _ReviewSection({
    required this.title,
    required this.onEdit,
    required this.children,
  });

  final String title;
  final VoidCallback onEdit;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                ),
              ],
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
