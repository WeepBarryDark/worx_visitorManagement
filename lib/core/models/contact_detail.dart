import '../../services/helper/user_detail_trim.dart';

/// 👤 Contact Detail Model - Represents a site supervisor or contact person
///
/// **PURPOSE:**
/// Stores information about supervisors/contacts that visitors can select
/// when checking in. Used for notifications and visitor tracking.
///
/// **WHY WE NEED THIS:**
/// - Visitors select who they're visiting
/// - Contact information for notifications (SMS/email)
/// - Supervisor name appears on visitor badges
///
/// **WHERE IT'S USED:**
/// - Sign-in page: Supervisor dropdown selector
/// - Badge generation: Shows supervisor name on printed badge
/// - Dashboard: Managing available contacts
///
/// **DATA FLOW:**
/// ```
/// API Response → fromMap() → Supervisor object → Dropdown UI
/// ```
///
/// **EXAMPLE:**
/// ```dart
/// // From API
/// final supervisor = Supervisor.fromMap({
///   'id': 'sup_001',
///   'name': 'Barry Wang',
///   'email': 'barry.wang@worxsafety.com',
///   'phone': '+61 412 345 678',
/// });
///
/// // Display in dropdown
/// DropdownMenuItem(
///   value: supervisor,
///   child: Text(supervisor.name),
/// );
/// ```

class ContactDetail {
/// Unique identifier for the supervisor
  final String id;

  /// Full name of the supervisor
  final String name;

  /// Email address (for notifications)
  final String email;

  /// Phone number (for SMS notifications)
  final String phone;

  /// Create a Supervisor with all required fields
  const ContactDetail({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
  });

  /// Create a Supervisor from a flexible JSON/Map structure
  ///
  /// **Handles many different API response formats:**
  /// - Name fields: `name`, `full_name`, `contact_name`, `title`, `first_name + last_name`
  /// - Email fields: `email`, `contact_email`, `mail`
  /// - Phone fields: `phone`, `contact_phone`, `mobile`, `phone_number`
  /// - ID fields: `id`, `uuid`, `contact_id`, `value`
  ///
  /// **Smart features:**
  /// - Automatically combines first_name + last_name if needed
  /// - Generates ID from other fields if ID is missing
  /// - Sanitizes contact names (removes special characters)
  /// - Falls back to "Contact" if no name found
  ///
  /// **Example JSON formats:**
  /// ```json
  /// // Format 1: Standard
  /// {"id": "1", "name": "John Doe", "email": "john@example.com", "phone": "+61 400 000 000"}
  ///
  /// // Format 2: Separate name fields
  /// {"id": "2", "first_name": "Jane", "last_name": "Smith", "contact_email": "jane@example.com"}
  ///
  /// // Format 3: Minimal (ID and email only)
  /// {"uuid": "3", "mail": "bob@example.com"}
  /// ```
  factory ContactDetail.fromMap(Map<String, dynamic> map) {
    // Step 1: Resolve the name from various possible fields
    String resolveName() {
      // Try common name fields in order of preference
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

      // Fallback to generic name
      return 'Contact';
    }

    // Step 2: Resolve ID from various possible fields or generate one
    String resolveId(String name) {
      // Try common ID fields
      final candidate = map['id'] ?? map['uuid'] ?? map['contact_id'] ?? map['value'];
      if (candidate != null && candidate.toString().trim().isNotEmpty) {
        return candidate.toString();
      }

      // Generate ID from other fields if no ID provided
      final fromFields = '${name}_${map['email'] ?? ''}_${map['phone'] ?? ''}'.trim();
      if (fromFields.isNotEmpty) {
        return fromFields;
      }

      // Last resort: use current timestamp
      return DateTime.now().microsecondsSinceEpoch.toString();
    }

    // Step 3: Get name and sanitize it
    final name = sanitizeContactName(resolveName());

    // Step 4: Get email from various possible fields
    final email = (map['email'] ??
                   map['contact_email'] ??
                   map['mail'] ??
                   '').toString();

    // Step 5: Get phone from various possible fields
    final phone = (map['phone'] ??
                   map['contact_phone'] ??
                   map['mobile'] ??
                   map['phone_number'] ??
                   '').toString();

    // Step 6: Create the Supervisor object
    return ContactDetail(
      id: resolveId(name),
      name: name,
      email: email,
      phone: phone,
    );
  }

  /// Convert Supervisor to JSON (for caching or API requests)
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

  /// Get initials from name (for avatar displays)
  /// Example: "Barry Wang" → "BW"
  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  /// For displaying in dropdown (shows just the name)
  @override
  String toString() => name;

  /// For comparing supervisors (needed for dropdown selection)
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContactDetail &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
