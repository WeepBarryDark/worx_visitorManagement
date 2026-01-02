class Supervisor {
  /// Supervisor Model
  /// Represents a site supervisor or contact person
  /// Unique identifier for the supervisor
  final String id;

  /// Full name of the supervisor
  final String name;

  /// Email address (for notifications)
  final String email;

  /// Phone number (for SMS notifications)
  final String phone;

  /// Create a Supervisor with all required fields
  const Supervisor({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
  });

  /// Create a Supervisor from a flexible JSON/Map structure
  factory Supervisor.fromMap(Map<String, dynamic> map) {
    // Step 1: Resolve the name from various possible fields
    String resolveName() {
      // Try common name fields
      final parts = <String?>[
        map['name']?.toString(),
        map['full_name']?.toString(),
        map['contact_name']?.toString(),
        map['title']?.toString(),
      ].where((value) => value != null && value.trim().isNotEmpty).toList();

      if (parts.isNotEmpty) {
        return parts.first!.trim();
      }

      // Try combining first and last name
      final first = map['first_name']?.toString() ?? '';
      final last = map['last_name']?.toString() ?? '';
      final combined = '$first $last'.trim();
      if (combined.isNotEmpty) {
        return combined;
      }

      return 'Contact';
    }

    // Step 2: Resolve ID
    String resolveId(String name) {
      final candidate = map['id'] ?? map['uuid'] ?? map['contact_id'] ?? map['value'];
      if (candidate != null && candidate.toString().trim().isNotEmpty) {
        return candidate.toString();
      }

      // Generate ID from other fields
      final fromFields = '${name}_${map['email'] ?? ''}_${map['phone'] ?? ''}'.trim();
      if (fromFields.isNotEmpty) {
        return fromFields;
      }

      return DateTime.now().microsecondsSinceEpoch.toString();
    }

    final name = resolveName();
    final email = (map['email'] ?? map['contact_email'] ?? map['mail'] ?? '').toString();
    final phone = (map['phone'] ?? map['contact_phone'] ?? map['mobile'] ?? map['phone_number'] ?? '').toString();

    return Supervisor(
      id: resolveId(name),
      name: name,
      email: email,
      phone: phone,
    );
  }

  /// Convert Supervisor to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
    };
  }

  /// Check if supervisor has email contact
  bool get hasEmail => email.isNotEmpty;

  /// Check if supervisor has phone contact
  bool get hasPhone => phone.isNotEmpty;

  /// Check if supervisor has any contact method
  bool get hasContactInfo => hasEmail || hasPhone;

  /// Get initials from name
  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Supervisor &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
