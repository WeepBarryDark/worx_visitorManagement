import 'dart:convert';

import '../../../core/models/site_item.dart';
import '../../../services/secure_storage_service.dart';

/// Controller for the New Site selection page
/// Manages site list, search functionality, and filtering
class NewSiteController {
  // Filter options
  bool showActiveOnly = false;
  String searchQuery = '';

  // Site data
  List<SiteItem> _all = [];
  bool _isLoaded = false;

  /// Get all loaded sites
  List<SiteItem> get all => _all;

  /// Load sites from secure storage (fetched from API during authentication)
  Future<void> loadSites({bool forceReload = false}) async {
    if (_isLoaded && !forceReload) return; // Already loaded

    final sitesJson = await SecureStorageService.getSites();
    if (sitesJson != null && sitesJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(sitesJson);
        final rawList = decoded is List
            ? decoded
            : (decoded is Map<String, dynamic> && decoded['data'] is List
                ? decoded['data'] as List<dynamic>
                : <dynamic>[]);
        _all = rawList
            .whereType<Map<String, dynamic>>()
            .map(SiteItem.fromJson)
            .toList();
      } catch (_) {
        _all = [];
      }
    }
    _isLoaded = true;
  }

  /// Reload sites from secure storage (forces a fresh load)
  Future<void> reloadSites() async {
    _isLoaded = false;
    await loadSites(forceReload: true);
  }

  /// Get filtered sites based on current search query and active filter
  List<SiteItem> get filtered {
    Iterable<SiteItem> items = _all;

    // Apply active filter
    if (showActiveOnly) {
      items = items.where((e) => e.active);
    }

    // Apply search query
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      items = items.where((e) =>
          e.title.toLowerCase().contains(q) ||
          e.address.toLowerCase().contains(q) ||
          e.siteManager.toLowerCase().contains(q) ||
          e.siteSupervisor.toLowerCase().contains(q));
    }

    return items.toList(growable: false);
  }

  /// Update search query
  void updateSearch(String q) => searchQuery = q.trim();

  /// Clear search query
  void clearSearch() => searchQuery = '';

  /// Toggle active filter
  void toggleActiveFilter(bool v) => showActiveOnly = v;
}
