import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:worxvisitorapp/core/models/contact_detail.dart';
import 'package:worxvisitorapp/services/api_service.dart';
import 'package:worxvisitorapp/services/secure_storage_service.dart';

class ContactLoader {
  /// Reload supervisors from API when possible, otherwise fall back to cached contacts.
  static Future<List<ContactDetail>> reloadSupervisors() async {
    final token = await SecureStorageService.getAuthToken();
    if (token != null && token.isNotEmpty) {
      try {
        final response = await ApiService.fetchVisitorContacts(token);
        await SecureStorageService.saveContacts(jsonEncode(response));
        final parsed = _parseContacts(response);
        if (parsed.isNotEmpty) return parsed;
      } catch (e) {
        debugPrint('ContactLoader API refresh failed: $e');
      }
    }
    return await loadCachedSupervisors();
  }

  /// Load supervisors from cached contacts in secure storage.
  static Future<List<ContactDetail>> loadCachedSupervisors() async {
    try {
      final raw = await SecureStorageService.getContacts();
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw);
      return _parseContacts(decoded);
    } catch (e) {
      debugPrint('ContactLoader cache parse error: $e');
      return [];
    }
  }

  static List<ContactDetail> _parseContacts(dynamic raw) {
    Iterable<dynamic>? entries;
    if (raw is List) {
      entries = raw;
    } else if (raw is Map<String, dynamic>) {
      const preferredKeys = ['data', 'contacts', 'results', 'items'];
      for (final key in preferredKeys) {
        final value = raw[key];
        if (value is List) {
          entries = value;
          break;
        }
      }
      entries ??= raw.values.whereType<List>().firstOrNull;
    }

    if (entries == null) return [];
    final results = <ContactDetail>[];
    for (final entry in entries) {
      if (entry is Map<String, dynamic>) {
        final supervisor = ContactDetail.fromMap(entry);
        if (supervisor.name.trim().isNotEmpty) {
          results.add(supervisor);
        }
      }
    }
    return results;
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
