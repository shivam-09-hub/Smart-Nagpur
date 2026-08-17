import 'package:flutter/material.dart';
import 'package:smart_nagpur/core/theme/theme.dart';
import 'package:smart_nagpur/core/widgets/states.dart';
import 'package:smart_nagpur/domain/domain.dart';
import 'package:smart_nagpur/features/complaints/presentation/widgets/development_map.dart';
import 'package:smart_nagpur/state/app_controller.dart';

import 'vendor_application_screen.dart';
import 'widgets/vendor_widgets.dart';

class VendorZonesScreen extends StatefulWidget {
  const VendorZonesScreen({required this.controller, super.key});

  final AppController controller;

  @override
  State<VendorZonesScreen> createState() => _VendorZonesScreenState();
}

class _VendorZonesScreenState extends State<VendorZonesScreen> {
  static const _zones = <_VendorZone>[
    _VendorZone(
      name: 'Civil Lines Demo Zone',
      area: 'Civil Lines',
      address: 'Near Civil Lines, Nagpur (illustrative location)',
      category: 'General',
      hours: '7:00 AM – 9:00 PM',
      latitude: 21.1534,
      longitude: 79.0713,
      availability: 'Limited demo availability',
    ),
    _VendorZone(
      name: 'Dharampeth Demo Zone',
      area: 'Dharampeth',
      address: 'Dharampeth market area, Nagpur (illustrative location)',
      category: 'Food',
      hours: '8:00 AM – 10:00 PM',
      latitude: 21.1397,
      longitude: 79.0596,
      availability: 'Review required',
    ),
    _VendorZone(
      name: 'Sadar Demo Zone',
      area: 'Sadar',
      address: 'Sadar market area, Nagpur (illustrative location)',
      category: 'General',
      hours: '8:00 AM – 9:00 PM',
      latitude: 21.1631,
      longitude: 79.0737,
      availability: 'Demo spaces shown',
    ),
    _VendorZone(
      name: 'Itwari Demo Zone',
      area: 'Itwari',
      address: 'Itwari, Nagpur (illustrative location)',
      category: 'Market',
      hours: '6:00 AM – 8:00 PM',
      latitude: 21.1541,
      longitude: 79.1112,
      availability: 'High-demand demo area',
    ),
    _VendorZone(
      name: 'Manish Nagar Demo Zone',
      area: 'Manish Nagar',
      address: 'Manish Nagar, Nagpur (illustrative location)',
      category: 'Food',
      hours: '4:00 PM – 10:00 PM',
      latitude: 21.0905,
      longitude: 79.0717,
      availability: 'Evening demo zone',
    ),
  ];

  final _searchController = TextEditingController();
  String _category = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final zones = _filteredZones;
    return Scaffold(
      appBar: AppBar(title: const Text('Find Vendor Zones')),
      body: SafeArea(
        top: false,
        child: Column(
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const VendorDemoBanner(
                        message:
                            'Zone names, availability, hours, and locations are illustrative development data. Confirm official vending zones with the municipality.',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Search vendor zones',
                          hintText: 'Area or zone name',
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
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['All', 'General', 'Food', 'Market']
                              .map(
                                (category) => Padding(
                                  padding: const EdgeInsets.only(
                                    right: AppSpacing.xs,
                                  ),
                                  child: ChoiceChip(
                                    label: Text(category),
                                    selected: _category == category,
                                    onSelected: (_) {
                                      setState(() => _category = category);
                                    },
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Expanded(
              child: zones.isEmpty
                  ? EmptyState(
                      title: 'No demo zones found',
                      message: 'Try another area or clear the category filter.',
                      icon: Icons.map_outlined,
                      actionLabel: 'Clear filters',
                      onAction: () {
                        _searchController.clear();
                        setState(() => _category = 'All');
                      },
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.page,
                        AppSpacing.xs,
                        AppSpacing.page,
                        AppSpacing.xxl,
                      ),
                      itemCount: zones.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) => Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 760),
                          child: _ZoneCard(
                            zone: zones[index],
                            onPreview: () => _previewZone(zones[index]),
                            onUse: () => _useZone(zones[index]),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<_VendorZone> get _filteredZones {
    final query = _searchController.text.trim().toLowerCase();
    return _zones
        .where((zone) {
          final categoryMatches =
              _category == 'All' || zone.category == _category;
          final searchMatches =
              query.isEmpty ||
              zone.name.toLowerCase().contains(query) ||
              zone.area.toLowerCase().contains(query) ||
              zone.address.toLowerCase().contains(query);
          return categoryMatches && searchMatches;
        })
        .toList(growable: false);
  }

  void _useZone(_VendorZone zone) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VendorApplicationScreen(
          controller: widget.controller,
          initialPreferredZone: zone.name,
          initialLocation: zone.location,
        ),
      ),
    );
  }

  void _previewZone(_VendorZone zone) {
    var previewLocation = zone.location;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              0,
              AppSpacing.page,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(zone.name, style: AppTypography.titleLarge),
                const SizedBox(height: AppSpacing.xxs),
                const Text(
                  'Illustrative map preview — not an official zone boundary.',
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: AppSpacing.md),
                DevelopmentMap(
                  location: previewLocation,
                  onChanged: (location) {
                    setSheetState(() => previewLocation = location);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                VendorInfoRow(label: 'Address', value: zone.address),
                VendorInfoRow(
                  label: 'Preview pin',
                  value: previewLocation.coordinates,
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      Navigator.of(this.context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => VendorApplicationScreen(
                            controller: widget.controller,
                            initialPreferredZone: zone.name,
                            initialLocation: previewLocation.copyWith(
                              address: zone.address,
                            ),
                          ),
                        ),
                      );
                    },
                    child: const Text('Use This Zone'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ZoneCard extends StatelessWidget {
  const _ZoneCard({
    required this.zone,
    required this.onPreview,
    required this.onUse,
  });

  final _VendorZone zone;
  final VoidCallback onPreview;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(
                    Icons.location_city,
                    color: AppColors.vendor,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(zone.name, style: AppTypography.title),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(zone.address, style: AppTypography.bodySmall),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(zone.category, style: AppTypography.caption),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            VendorInfoRow(label: 'Hours', value: zone.hours),
            VendorInfoRow(label: 'Availability', value: zone.availability),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPreview,
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Preview'),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: FilledButton(
                    onPressed: onUse,
                    child: const Text('Use Zone'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VendorZone {
  const _VendorZone({
    required this.name,
    required this.area,
    required this.address,
    required this.category,
    required this.hours,
    required this.latitude,
    required this.longitude,
    required this.availability,
  });

  final String name;
  final String area;
  final String address;
  final String category;
  final String hours;
  final double latitude;
  final double longitude;
  final String availability;

  ProblemLocation get location => ProblemLocation(
    latitude: latitude,
    longitude: longitude,
    accuracy: 30,
    address: address,
  );
}
