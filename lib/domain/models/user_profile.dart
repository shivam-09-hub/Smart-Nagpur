class UserProfile {
  const UserProfile({
    required this.name,
    required this.phone,
    required this.email,
    this.address = '',
    this.avatarPath,
  });

  final String name;
  final String phone;
  final String email;
  final String address;
  final String? avatarPath;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'SN';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  UserProfile copyWith({
    String? name,
    String? phone,
    String? email,
    String? address,
    String? avatarPath,
  }) {
    return UserProfile(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      avatarPath: avatarPath ?? this.avatarPath,
    );
  }

  Map<String, Object?> toJson() => {
    'name': name,
    'phone': phone,
    'email': email,
    'address': address,
    'avatarPath': avatarPath,
  };

  factory UserProfile.fromJson(Map<String, Object?> json) {
    return UserProfile(
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      address: json['address'] as String? ?? '',
      avatarPath: json['avatarPath'] as String?,
    );
  }
}
