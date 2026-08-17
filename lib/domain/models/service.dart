enum ServiceType {
  vendor,
  garbage,
  water,
  roads,
  animals,
  drainage,
  streetlights,
  publicSpaces,
  encroachment,
  other,
}

extension ServiceTypeIdentity on ServiceType {
  String get slug => switch (this) {
    ServiceType.garbage => 'waste',
    ServiceType.publicSpaces => 'public-spaces',
    _ => name,
  };
}

ServiceType serviceTypeFromJson(Object? value) {
  return ServiceType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => ServiceType.other,
  );
}

enum ServiceActionKind {
  report,
  information,
  vendorRegistration,
  vendorPermission,
  vendorZones,
  vendorTracking,
  vendorRenewal,
  vendorDocuments,
}

class ServiceAction {
  const ServiceAction({
    required this.id,
    required this.title,
    this.description,
    this.kind = ServiceActionKind.report,
    this.safetyMessage,
  });

  final String id;
  final String title;
  final String? description;
  final ServiceActionKind kind;
  final String? safetyMessage;
}

class ServiceDefinition {
  const ServiceDefinition({
    required this.type,
    required this.title,
    required this.shortTitle,
    required this.description,
    required this.heroTitle,
    required this.actions,
    this.searchTerms = const [],
  });

  final ServiceType type;
  final String title;
  final String shortTitle;
  final String description;
  final String heroTitle;
  final List<ServiceAction> actions;
  final List<String> searchTerms;
}
