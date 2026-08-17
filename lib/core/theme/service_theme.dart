import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import 'app_tokens.dart';

extension ServiceTypeTheme on ServiceType {
  String get title => switch (this) {
    ServiceType.vendor => 'Vendor & Small Business',
    ServiceType.garbage => 'Garbage & Waste',
    ServiceType.water => 'Water Services',
    ServiceType.roads => 'Roads & Infrastructure',
    ServiceType.animals => 'Animal Services',
    ServiceType.drainage => 'Drainage & Flooding',
    ServiceType.streetlights => 'Streetlights & Electricity',
    ServiceType.publicSpaces => 'Public Spaces',
    ServiceType.encroachment => 'Encroachment & Civic Issues',
    ServiceType.other => 'Other Civic Services',
  };

  String get shortTitle => switch (this) {
    ServiceType.vendor => 'Vendor',
    ServiceType.garbage => 'Garbage',
    ServiceType.water => 'Water',
    ServiceType.roads => 'Roads',
    ServiceType.animals => 'Animals',
    ServiceType.drainage => 'Drainage',
    ServiceType.streetlights => 'Streetlights',
    ServiceType.publicSpaces => 'Public Spaces',
    ServiceType.encroachment => 'Encroachment',
    ServiceType.other => 'Other',
  };

  String get description => switch (this) {
    ServiceType.vendor =>
      'Registration, permissions and support for local vendors.',
    ServiceType.garbage => 'Report waste collection and cleanliness concerns.',
    ServiceType.water => 'Report water supply, leakage and quality issues.',
    ServiceType.roads => 'Report road damage and public infrastructure issues.',
    ServiceType.animals =>
      'Request help for animals and related public concerns.',
    ServiceType.drainage => 'Report blocked drains, waterlogging and flooding.',
    ServiceType.streetlights =>
      'Report public lighting and electrical safety concerns.',
    ServiceType.publicSpaces =>
      'Report issues in parks and other shared facilities.',
    ServiceType.encroachment =>
      'Report possible obstructions for municipal verification.',
    ServiceType.other => 'Tell us about another civic concern.',
  };

  Color get color => switch (this) {
    ServiceType.vendor => AppColors.vendor,
    ServiceType.garbage => AppColors.garbage,
    ServiceType.water => AppColors.water,
    ServiceType.roads => AppColors.roads,
    ServiceType.animals => AppColors.animals,
    ServiceType.drainage => AppColors.drainage,
    ServiceType.streetlights => AppColors.streetlights,
    ServiceType.publicSpaces => AppColors.publicSpaces,
    ServiceType.encroachment => AppColors.encroachment,
    ServiceType.other => AppColors.other,
  };

  Color get softColor =>
      Color.alphaBlend(color.withValues(alpha: 0.12), AppColors.surface);

  IconData get icon => switch (this) {
    ServiceType.vendor => Icons.storefront_rounded,
    ServiceType.garbage => Icons.delete_outline_rounded,
    ServiceType.water => Icons.water_drop_rounded,
    ServiceType.roads => Icons.add_road_rounded,
    ServiceType.animals => Icons.pets_rounded,
    ServiceType.drainage => Icons.flood_rounded,
    ServiceType.streetlights => Icons.lightbulb_rounded,
    ServiceType.publicSpaces => Icons.park_rounded,
    ServiceType.encroachment => Icons.report_problem_rounded,
    ServiceType.other => Icons.apps_rounded,
  };
}

extension NewsCategoryTheme on NewsCategory {
  Color get color => switch (this) {
    NewsCategory.cityUpdates => AppColors.primary,
    NewsCategory.roadWork => AppColors.roads,
    NewsCategory.water => AppColors.water,
    NewsCategory.waste => AppColors.garbage,
    NewsCategory.publicNotices => AppColors.other,
    NewsCategory.events => AppColors.animals,
    NewsCategory.emergencyAlerts => AppColors.error,
  };

  IconData get icon => switch (this) {
    NewsCategory.cityUpdates => Icons.location_city_rounded,
    NewsCategory.roadWork => Icons.construction_rounded,
    NewsCategory.water => Icons.water_drop_rounded,
    NewsCategory.waste => Icons.recycling_rounded,
    NewsCategory.publicNotices => Icons.campaign_rounded,
    NewsCategory.events => Icons.event_rounded,
    NewsCategory.emergencyAlerts => Icons.warning_amber_rounded,
  };
}
