import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:worxvisitorapp/core/models/site_item.dart';
import 'package:worxvisitorapp/services/api_service.dart';
import 'package:worxvisitorapp/services/secure_storage_service.dart';

/// Site Loader Service
/// Helper for refreshing the sites list whenever a kiosk flow starts

class SiteLoader {
  static Future<List<SiteItem>> reloadSites() async {
    final token = await SecureStorageService.getAuthToken();
    if (token != null && token.isNotEmpty) {
      try {
        final apiSites = await ApiService.fetchVisitorSites(token);
        await SecureStorageService.saveSites(jsonEncode(apiSites));
        final parsed = _parseSites(apiSites);
        if (parsed.isNotEmpty) return parsed;
      } catch (e) {
        debugPrint('SiteLoader API refresh failed: $e');
      }
    }
    return await loadCachedSites();
  }

  static Future<List<SiteItem>> loadCachedSites() async {
    try {
      final raw = await SecureStorageService.getSites();
      if (raw == null || raw.isEmpty) return const [];
      final decoded = jsonDecode(raw);
      return _parseSites(decoded);
    } catch (e) {
      debugPrint('SiteLoader cache parse error: $e');
      return const [];
    }
  }

  static List<SiteItem> _parseSites(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(SiteItem.fromJson)
          .toList();
    }

    if (raw is Map<String, dynamic>) {
      final list = raw['data'];
      if (list is List) {
        return list
            .whereType<Map<String, dynamic>>()
            .map(SiteItem.fromJson)
            .toList();
      }
    }
    return const [];
  }
}
