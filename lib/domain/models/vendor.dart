import 'problem_location.dart';

enum DocumentRequirement { required, optional, conditional }

class VendorDocument {
  const VendorDocument({
    required this.type,
    required this.label,
    required this.path,
    this.requirement = DocumentRequirement.optional,
  });

  final String type;
  final String label;
  final String path;
  final DocumentRequirement requirement;

  Map<String, Object?> toJson() => {
    'type': type,
    'label': label,
    'path': path,
    'requirement': requirement.name,
  };

  factory VendorDocument.fromJson(Map<String, Object?> json) {
    return VendorDocument(
      type: json['type'] as String? ?? '',
      label: json['label'] as String? ?? '',
      path: json['path'] as String? ?? '',
      requirement: DocumentRequirement.values.firstWhere(
        (value) => value.name == json['requirement'],
        orElse: () => DocumentRequirement.optional,
      ),
    );
  }
}

enum VendorStatus {
  submitted,
  documentsVerified,
  underReview,
  locationAssessment,
  approved,
  changesRequired,
  rejected,
  permissionIssued,
}

VendorStatus vendorStatusFromJson(Object? value) {
  return VendorStatus.values.firstWhere(
    (status) => status.name == value,
    orElse: () => VendorStatus.submitted,
  );
}

extension VendorStatusDetails on VendorStatus {
  String get label => switch (this) {
    VendorStatus.submitted => 'Submitted',
    VendorStatus.documentsVerified => 'Documents verified',
    VendorStatus.underReview => 'Under review',
    VendorStatus.locationAssessment => 'Location assessment',
    VendorStatus.approved => 'Approved',
    VendorStatus.changesRequired => 'Changes required',
    VendorStatus.rejected => 'Rejected',
    VendorStatus.permissionIssued => 'Permission issued',
  };

  bool get isClosed => this == VendorStatus.rejected;
}

class VendorTimelineEntry {
  const VendorTimelineEntry({
    required this.title,
    this.timestamp,
    this.message,
    this.isCompleted = false,
    this.isCurrent = false,
  });

  final String title;
  final DateTime? timestamp;
  final String? message;
  final bool isCompleted;
  final bool isCurrent;

  Map<String, Object?> toJson() => {
    'title': title,
    'timestamp': timestamp?.toIso8601String(),
    'message': message,
    'isCompleted': isCompleted,
    'isCurrent': isCurrent,
  };

  factory VendorTimelineEntry.fromJson(Map<String, Object?> json) {
    return VendorTimelineEntry(
      title: json['title'] as String? ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? ''),
      message: json['message'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? false,
      isCurrent: json['isCurrent'] as bool? ?? false,
    );
  }
}

class VendorApplicationDraft {
  const VendorApplicationDraft({
    this.applicantName = '',
    this.mobile = '',
    this.email = '',
    this.residentialAddress = '',
    this.identityInformation = '',
    this.businessName = '',
    this.businessType = '',
    this.category = '',
    this.description = '',
    this.productsServices = '',
    this.registrationNumber = '',
    this.location,
    this.preferredZone = '',
    this.operatingDays = const [],
    this.startTime = '',
    this.endTime = '',
    this.durationType = 'Permanent',
    this.outletType = '',
    this.documents = const [],
    this.acceptedDeclaration = false,
  });

  final String applicantName;
  final String mobile;
  final String email;
  final String residentialAddress;
  final String identityInformation;
  final String businessName;
  final String businessType;
  final String category;
  final String description;
  final String productsServices;
  final String registrationNumber;
  final ProblemLocation? location;
  final String preferredZone;
  final List<String> operatingDays;
  final String startTime;
  final String endTime;
  final String durationType;
  final String outletType;
  final List<VendorDocument> documents;
  final bool acceptedDeclaration;

  VendorApplicationDraft copyWith({
    String? applicantName,
    String? mobile,
    String? email,
    String? residentialAddress,
    String? identityInformation,
    String? businessName,
    String? businessType,
    String? category,
    String? description,
    String? productsServices,
    String? registrationNumber,
    ProblemLocation? location,
    String? preferredZone,
    List<String>? operatingDays,
    String? startTime,
    String? endTime,
    String? durationType,
    String? outletType,
    List<VendorDocument>? documents,
    bool? acceptedDeclaration,
  }) {
    return VendorApplicationDraft(
      applicantName: applicantName ?? this.applicantName,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      residentialAddress: residentialAddress ?? this.residentialAddress,
      identityInformation: identityInformation ?? this.identityInformation,
      businessName: businessName ?? this.businessName,
      businessType: businessType ?? this.businessType,
      category: category ?? this.category,
      description: description ?? this.description,
      productsServices: productsServices ?? this.productsServices,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      location: location ?? this.location,
      preferredZone: preferredZone ?? this.preferredZone,
      operatingDays: operatingDays ?? this.operatingDays,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationType: durationType ?? this.durationType,
      outletType: outletType ?? this.outletType,
      documents: documents ?? this.documents,
      acceptedDeclaration: acceptedDeclaration ?? this.acceptedDeclaration,
    );
  }

  Map<String, Object?> toJson() => {
    'applicantName': applicantName,
    'mobile': mobile,
    'email': email,
    'residentialAddress': residentialAddress,
    'identityInformation': identityInformation,
    'businessName': businessName,
    'businessType': businessType,
    'category': category,
    'description': description,
    'productsServices': productsServices,
    'registrationNumber': registrationNumber,
    'location': location?.toJson(),
    'preferredZone': preferredZone,
    'operatingDays': operatingDays,
    'startTime': startTime,
    'endTime': endTime,
    'durationType': durationType,
    'outletType': outletType,
    'documents': documents.map((document) => document.toJson()).toList(),
    'acceptedDeclaration': acceptedDeclaration,
  };

  factory VendorApplicationDraft.fromJson(Map<String, Object?> json) {
    final locationJson = json['location'];
    return VendorApplicationDraft(
      applicantName: json['applicantName'] as String? ?? '',
      mobile: json['mobile'] as String? ?? '',
      email: json['email'] as String? ?? '',
      residentialAddress: json['residentialAddress'] as String? ?? '',
      identityInformation: json['identityInformation'] as String? ?? '',
      businessName: json['businessName'] as String? ?? '',
      businessType: json['businessType'] as String? ?? '',
      category: json['category'] as String? ?? '',
      description: json['description'] as String? ?? '',
      productsServices: json['productsServices'] as String? ?? '',
      registrationNumber: json['registrationNumber'] as String? ?? '',
      location: locationJson is Map
          ? ProblemLocation.fromJson(Map<String, Object?>.from(locationJson))
          : null,
      preferredZone: json['preferredZone'] as String? ?? '',
      operatingDays: (json['operatingDays'] as List<Object?>? ?? const [])
          .whereType<String>()
          .toList(),
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      durationType: json['durationType'] as String? ?? 'Permanent',
      outletType: json['outletType'] as String? ?? '',
      documents: (json['documents'] as List<Object?>? ?? const [])
          .whereType<Map>()
          .map(
            (document) =>
                VendorDocument.fromJson(Map<String, Object?>.from(document)),
          )
          .toList(),
      acceptedDeclaration: json['acceptedDeclaration'] as bool? ?? false,
    );
  }
}

class VendorApplication {
  const VendorApplication({
    required this.id,
    required this.details,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.timeline = const [],
    this.isDemo = true,
  });

  final String id;
  final VendorApplicationDraft details;
  final VendorStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<VendorTimelineEntry> timeline;
  final bool isDemo;

  String get applicantName => details.applicantName;
  String get businessName => details.businessName;
  String get category => details.category;
  ProblemLocation? get location => details.location;
  List<VendorDocument> get documents => details.documents;

  VendorApplication copyWith({
    VendorStatus? status,
    DateTime? updatedAt,
    List<VendorTimelineEntry>? timeline,
  }) {
    return VendorApplication(
      id: id,
      details: details,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      timeline: timeline ?? this.timeline,
      isDemo: isDemo,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'details': details.toJson(),
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'timeline': timeline.map((entry) => entry.toJson()).toList(),
    'isDemo': isDemo,
  };

  factory VendorApplication.fromJson(Map<String, Object?> json) {
    return VendorApplication(
      id: json['id'] as String? ?? '',
      details: VendorApplicationDraft.fromJson(
        Map<String, Object?>.from(
          json['details'] as Map? ?? const <String, Object?>{},
        ),
      ),
      status: vendorStatusFromJson(json['status']),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      timeline: (json['timeline'] as List<Object?>? ?? const [])
          .whereType<Map>()
          .map(
            (entry) =>
                VendorTimelineEntry.fromJson(Map<String, Object?>.from(entry)),
          )
          .toList(),
      isDemo: json['isDemo'] as bool? ?? true,
    );
  }
}
