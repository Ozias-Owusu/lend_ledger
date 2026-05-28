class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    this.profilePicture,
    this.dateOfBirth,
    this.country,
    this.roles = const [],
  });

  final String id;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final String? profilePicture;
  final DateTime? dateOfBirth;
  final String? country;
  final List<String> roles;

  String? get primaryRole => roles.isNotEmpty ? roles.first : null;

  String get displayInitials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '?';
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: _readString(json, const ['id', 'userId']) ?? '',
      email: _readString(json, const ['email']) ?? '',
      fullName: _readString(json, const ['fullName', 'name']) ?? '',
      phoneNumber: _readString(json, const ['phoneNumber', 'phone']),
      profilePicture: _readString(json, const [
        'profilePicture',
        'profileImage',
        'avatarUrl',
        'imageUrl',
      ]),
      dateOfBirth: _parseDate(json['dateOfBirth'] ?? json['dob']),
      country: _readString(json, const [
        'country',
        'countryRegion',
        'countryName',
      ]),
      roles: _parseRoles(json['roles']),
    );
  }

  static String? _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    return DateTime.tryParse(text);
  }

  static List<String> _parseRoles(dynamic value) {
    if (value is! List) return const [];
    return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
  }
}
