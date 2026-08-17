class ProblemLocation {
  const ProblemLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.address,
  });

  final double latitude;
  final double longitude;
  final double accuracy;
  final String address;

  bool get hasLowAccuracy => accuracy > 50;

  String get coordinates =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';

  ProblemLocation copyWith({
    double? latitude,
    double? longitude,
    double? accuracy,
    String? address,
  }) {
    return ProblemLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      address: address ?? this.address,
    );
  }

  Map<String, Object?> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'accuracy': accuracy,
    'address': address,
  };

  factory ProblemLocation.fromJson(Map<String, Object?> json) {
    return ProblemLocation(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0,
      address: json['address'] as String? ?? '',
    );
  }
}
