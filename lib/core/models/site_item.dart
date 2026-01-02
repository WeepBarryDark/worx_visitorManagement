/// 🏢 Site Item Model - Represents a construction site or work location
///
/// **PURPOSE:**
/// This is the central data model for sites in the Worx Safety system.
/// Sites are work locations where visitors check in and out.
///
/// **WHY WE NEED THIS:**
/// - Stores all site information (address, managers, status)
/// - Used across dashboard, kiosk, and sign-in features
/// - Provides type-safe access to site data
///
/// **WHERE IT'S USED:**
/// - Dashboard: Site selection dropdown
/// - Kiosk: Display current site name
/// - Sign-in: Visitor badge generation
/// - Reports: Site data export
///
/// **DATA FLOW:**
/// ```
/// API Response → fromJson() → SiteItem object → Used in UI
/// ```
///
/// **EXAMPLE:**
/// ```dart
/// // From API response
/// final site = SiteItem.fromJson({
///   'id': '1002567',
///   'title': 'Thirroul Development',
///   'address': '50 Redman Ave, THIRROUL, NSW',
///   'active': true,
///   'site_manager': 'Luke One1',
///   'site_supervisor': 'Luke McIndoe',
/// });
///
/// // Access properties
/// print(site.title); // "Thirroul Development"
/// print(site.isActive); // true
/// ```
class SiteItem {
  final String id;   /// Unique identifier for the site (e.g., "1002567")
  final String title;   /// Display name of the site (e.g., "Thirroul Development")
  final String address;   /// Physical address of the site
  final bool active;   /// Whether the site is currently active (accepting visitors)
  final String siteManager;   /// Name of the site manager
  final String siteSupervisor;   /// Name of the site supervisor
  final DateTime createdAt;   /// When the site was created in the system
  final DateTime updatedAt;   /// When the site was last updated

  /// Create a SiteItem with all required fields
  const SiteItem({
    required this.id,
    required this.title,
    required this.address,
    required this.active,
    required this.siteManager,
    required this.siteSupervisor,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a SiteItem from JSON data (from API response)
  ///
  /// **Handles multiple JSON formats:**
  /// - API response: `{"id": "...", "title": "...", ...}`
  /// - Flexible field names: `site_id` OR `id`, `name` OR `title`, etc.
  ///
  /// **Example JSON:**
  /// ```json
  /// {
  ///   "id": "1002567",
  ///   "title": "Thirroul Development",
  ///   "address": "50 Redman Ave, THIRROUL, NSW",
  ///   "active": true,
  ///   "site_manager": "Luke One1",
  ///   "site_supervisor": "Luke McIndoe",
  ///   "created_at": "2021-08-10T00:00:00Z",
  ///   "updated_at": "2025-10-30T00:00:00Z"
  /// }
  /// ```
  factory SiteItem.fromJson(Map<String, dynamic> json) {
    return SiteItem(
      // Try multiple possible field names for ID
      id: (json['id'] ?? json['site_id'] ?? '').toString(),

      // Try multiple possible field names for title/name
      title: (json['title'] ?? json['name'] ?? json['site_name'] ?? '').toString(),

      // Try multiple possible field names for address
      address: (json['address'] ?? json['location'] ?? '').toString(),

      // Parse active status (handle string "true"/"false" or boolean)
      active: _parseBool(json['active'] ?? json['is_active'] ?? true),

      // Try multiple possible field names for manager
      siteManager: (json['site_manager'] ?? json['manager'] ?? '').toString(),

      // Try multiple possible field names for supervisor
      siteSupervisor: (json['site_supervisor'] ?? json['supervisor'] ?? '').toString(),

      // Parse dates safely (handle null or invalid dates)
      createdAt: _parseDate(json['created_at'] ?? json['createdAt']),

      updatedAt: _parseDate(json['updated_at'] ?? json['updatedAt']),
    );
  }

  /// Convert SiteItem to JSON (for caching or API requests)
  ///
  /// **Returns:** Map that can be encoded to JSON string
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'address': address,
      'active': active,
      'site_manager': siteManager,
      'site_supervisor': siteSupervisor,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Helper: Safely parse boolean values
  /// Handles: true, "true", 1, "1" → true
  ///          false, "false", 0, "0" → false
  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is int) return value == 1;
    return false;
  }

  /// Helper: Safely parse date values
  /// Handles: ISO8601 strings, DateTime objects, null
  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  /// Check if site is active and ready for visitors
  bool get isActive => active;

  /// Get formatted site heading for display
  /// Format: "ID - Title" (e.g., "1002567 - Thirroul Development")
  String get displayName {
    if (id.isEmpty) return title;
    if (title.isEmpty) return id;

    // Check if title already contains the ID
    if (title.toLowerCase().startsWith(id.toLowerCase())) {
      return title;
    }

    return title;
  }

  /// For debugging and logging
  @override
  String toString() {
    return 'SiteItem(id: $id, title: $title, active: $active)';
  }

  /// For comparing sites (needed for dropdown selection, etc.)
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SiteItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
