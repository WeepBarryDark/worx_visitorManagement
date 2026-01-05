import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

/// Secure Storage Service for sensitive data like auth tokens
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
    webOptions: WebOptions(
      dbName: 'WorxCompanionDB',
      publicKey: 'WorxCompanionPublicKey',
    ),
  );

  // Storage keys
  static const String _keyAuthToken = 'auth_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyDeviceName = 'device_name';
  static const String _keySetupCode = 'setup_code';
  static const String _keyUserId = 'user_id';
  static const String _keyUserEmail = 'user_email';
  static const String _keySites = 'visitor_sites';
  static const String _keyContacts = 'visitor_contacts';
  static const String _keyClient = 'visitor_client';
  static const String _keySignedVisitors = 'signed_visitors';
  static const String _keyKioskAdminPin = 'kiosk_admin_pin';
  static const String _keySelectedSite = 'selected_site';
  static const String _keyNotificationPreferences = 'notification_preferences';
  static const String _keyLastPrinter = 'last_printer'; // Store last discovered printer info
  static const String _keyPaperType = 'printer_paper_type'; // Store selected paper type
  static const String _keyVisitorRequirements = 'visitor_requirements'; // Store required visitor fields
  static const String _keyPrintSettings = 'print_settings'; // Store print-related settings
  static const String _keyAutoNavigateToKiosk = 'auto_navigate_to_kiosk'; // Flag to auto-navigate to kiosk after dashboard loads

  // Data fetch failure tracking keys
  static const String _keyFetchFailureSites = 'fetch_failure_sites';
  static const String _keyFetchFailureContacts = 'fetch_failure_contacts';
  static const String _keyFetchFailureClient = 'fetch_failure_client';

  /// Save authentication token
  static Future<void> saveAuthToken(String token) async {
    try {
      await _storage.write(key: _keyAuthToken, value: token);
      debugPrint('Auth token saved securely');
    } catch (e) {
      debugPrint('Error reading auth token: $e');
      rethrow;
    }
  }

  /// Get authentication token
  static Future<String?> getAuthToken() async {
    try {
      return await _storage.read(key: _keyAuthToken);
    } catch (e) {
      debugPrint('Error reading auth token: $e');
      return null;
    }
  }

  /// Save refresh token
  static Future<void> saveRefreshToken(String token) async {
    try {
      await _storage.write(key: _keyRefreshToken, value: token);
    } catch (e) {
      debugPrint('Error saving refresh token: $e');
      rethrow;
    }
  }

  /// Get refresh token
  static Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _keyRefreshToken);
    } catch (e) {
      debugPrint('Error reading refresh token: $e');
      return null;
    }
  }

  /// Save device name
  static Future<void> saveDeviceName(String name) async {
    try {
      await _storage.write(key: _keyDeviceName, value: name);
    } catch (e) {
      debugPrint('Error saving device name: $e');
    }
  }

  /// Get device name
  static Future<String?> getDeviceName() async {
    try {
      return await _storage.read(key: _keyDeviceName);
    } catch (e) {
      debugPrint('Error reading device name: $e');
      return null;
    }
  }

  /// Save setup code (for re-authentication if needed)
  static Future<void> saveSetupCode(String code) async {
    try {
      await _storage.write(key: _keySetupCode, value: code);
    } catch (e) {
      debugPrint('Error saving setup code: $e');
    }
  }

  /// Get setup code
  static Future<String?> getSetupCode() async {
    try {
      return await _storage.read(key: _keySetupCode);
    } catch (e) {
      debugPrint('Error reading setup code: $e');
      return null;
    }
  }

  /// Save user ID
  static Future<void> saveUserId(String userId) async {
    try {
      await _storage.write(key: _keyUserId, value: userId);
    } catch (e) {
      debugPrint('Error saving user ID: $e');
    }
  }

  /// Get user ID
  static Future<String?> getUserId() async {
    try {
      return await _storage.read(key: _keyUserId);
    } catch (e) {
      debugPrint('Error reading user ID: $e');
      return null;
    }
  }

  /// Save user email
  static Future<void> saveUserEmail(String email) async {
    try {
      await _storage.write(key: _keyUserEmail, value: email);
    } catch (e) {
      debugPrint('Error saving user email: $e');
    }
  }

  /// Get user email
  static Future<String?> getUserEmail() async {
    try {
      return await _storage.read(key: _keyUserEmail);
    } catch (e) {
      debugPrint('Error reading user email: $e');
      return null;
    }
  }

  /// Check if user is authenticated (has valid token)
  static Future<bool> isAuthenticated() async {
    final token = await getAuthToken();
    return token != null && token.isNotEmpty;
  }

  /// Save visitor sites data
  static Future<void> saveSites(String sitesJson) async {
    try {
      await _storage.write(key: _keySites, value: sitesJson);
    } catch (e) {
       debugPrint('Error saving sites: $e');
    }
  }

  /// Get visitor sites data
  static Future<String?> getSites() async {
    try {
      return await _storage.read(key: _keySites);
    } catch (e) {
      debugPrint('Error reading sites: $e');
      return null;
    }
  }

  /// Save visitor contacts data
  static Future<void> saveContacts(String contactsJson) async {
    try {
      await _storage.write(key: _keyContacts, value: contactsJson);
    } catch (e) {
      debugPrint('Error saving contacts: $e');
    }
  }

  /// Get visitor contacts data
  static Future<String?> getContacts() async {
    try {
      return await _storage.read(key: _keyContacts);
    } catch (e) {
      debugPrint('Error reading contacts: $e');
      return null;
    }
  }

  /// Save visitor client data
  static Future<void> saveClient(String clientJson) async {
    try {
      await _storage.delete(key: _keyClient);
      await _storage.write(key: _keyClient, value: clientJson);
    } catch (e) {
      debugPrint('Error saving client: $e');
    }
  }

  /// Get visitor client data
  static Future<String?> getClient() async {
    try {
      return await _storage.read(key: _keyClient);
    } catch (e) {
      debugPrint('Error reading client: $e');
      return null;
    }
  }

  /// Save selected site data
  static Future<void> saveSelectedSite(String siteJson) async {
    try {
      await _storage.write(key: _keySelectedSite, value: siteJson);
    } catch (e) {
      debugPrint('Error saving selected site: $e');
    }
  }

  /// Get selected site data
  static Future<String?> getSelectedSite() async {
    try {
      return await _storage.read(key: _keySelectedSite);
    } catch (e) {
      debugPrint('Error reading selected site: $e');
      return null;
    }
  }

  /// Save notification preferences
  static Future<void> saveNotificationPreferences(String preferencesJson) async {
    try {
      await _storage.write(key: _keyNotificationPreferences, value: preferencesJson);
    } catch (e) {
      debugPrint('Error saving notification preferences: $e');
    }
  }

  /// Get notification preferences
  static Future<String?> getNotificationPreferences() async {
    try {
      return await _storage.read(key: _keyNotificationPreferences);
    } catch (e) {
      debugPrint('Error reading notification preferences: $e');
      return null;
    }
  }

  /// Save all authentication data at once
  static Future<void> saveAuthData({
    required String authToken,
    String? refreshToken,
    String? deviceName,
    String? setupCode,
    String? userId,
    String? userEmail,
  }) async {
    await saveAuthToken(authToken);
    if (refreshToken != null) await saveRefreshToken(refreshToken);
    if (deviceName != null) await saveDeviceName(deviceName);
    if (setupCode != null) await saveSetupCode(setupCode);
    if (userId != null) await saveUserId(userId);
    if (userEmail != null) await saveUserEmail(userEmail);
    debugPrint('All auth data saved');
  }

  /// Clear all authentication data (logout)
  static Future<void> clearAuthData() async {
    try {
      await Future.wait([
        _storage.delete(key: _keyAuthToken),
        _storage.delete(key: _keyRefreshToken),
        _storage.delete(key: _keyUserId),
        _storage.delete(key: _keyUserEmail),
        _storage.delete(key: _keySignedVisitors),  // Clear visitor data on logout
        _storage.delete(key: _keySites),           // Clear site data
        _storage.delete(key: _keyContacts),        // Clear contacts
        _storage.delete(key: _keyClient),          // Clear client data
        // Keep device name and setup code for easier re-authentication
      ]);

    } catch (e) {
      debugPrint('Error clearing auth data: $e');
      rethrow;
    }
  }

  /// Clear all stored data (complete reset)
  static Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      debugPrint('Error clearing storage: $e');
      rethrow;
    }
  }

  /// Get all stored keys (for debugging)
  static Future<Map<String, String>> getAllData() async {
    try {
      return await _storage.readAll();
    } catch (e) {
      debugPrint('Error reading all data: $e');
      return {};
    }
  }

  /// Store signed-in visitor for quick lookup (used by sign-out autofill)
  static Future<void> addSignedVisitor({
    required String visitorId,
    String? email,
    String? fullName,
    String? supervisorId,
    String? supervisorName,
    String? supervisorEmail,
    String? supervisorPhone,
    bool notifyViaSms = false,
    bool notifyViaEmail = false,
  }) async {
    try {
      final raw = await _storage.read(key: _keySignedVisitors);
      List<dynamic> records = [];
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          records = decoded;
        }
      }

      final normalizedId = visitorId.trim();
      final normalizedEmail = email?.trim().toLowerCase() ?? '';
      final record = <String, dynamic>{
        'id': normalizedId,
        'email': normalizedEmail,
        'full_name': fullName?.trim() ?? '',
        'supervisor_id': supervisorId?.trim() ?? '',
        'supervisor_name': supervisorName?.trim() ?? '',
        'supervisor_email': supervisorEmail?.trim() ?? '',
        'supervisor_phone': supervisorPhone?.trim() ?? '',
        'notify_via_sms': notifyViaSms,
        'notify_via_email': notifyViaEmail,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      final existingIndex = records.indexWhere((entry) {
        if (entry is Map) {
          final id = entry['id']?.toString();
          final mail = entry['email']?.toString().toLowerCase();
          if (id == normalizedId && normalizedId.isNotEmpty) return true;
          if (normalizedEmail.isNotEmpty && normalizedEmail == mail) {
            return true;
          }
        }
        return false;
      });

      if (existingIndex >= 0) {
        records[existingIndex] = record;
      } else {
        records.insert(0, record);
      }

      if (records.length > 200) {
        records = records.sublist(0, 200);
      }

      await _storage.write(
        key: _keySignedVisitors,
        value: jsonEncode(records),
      );
    } catch (e) {
      debugPrint('Error: $e tack trace: ${StackTrace.current} ');
    }
  }

  /// Remove a signed visitor from local storage by visitor ID
  static Future<void> removeSignedVisitor(String visitorId) async {
    try {
      final raw = await _storage.read(key: _keySignedVisitors);
      if (raw == null || raw.isEmpty) {
        debugPrint('No visitors in storage, nothing to remove');
        return;
      }

      List<dynamic> records = [];
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        records = decoded;
      }

      final normalizedId = visitorId.trim();

      // Remove the visitor with matching ID
      final updatedRecords = records.where((entry) {
        if (entry is Map) {
          final id = entry['id']?.toString();
          return id != normalizedId;
        }
        return true;
      }).toList();
      
      await _storage.write(
        key: _keySignedVisitors,
        value: jsonEncode(updatedRecords),
      );

    } catch (e) {
      debugPrint('Error: $e Stack trace: ${StackTrace.current} ');
    }
  }

  /// Return cached signed-in visitors
  static Future<List<Map<String, dynamic>>> getSignedVisitors() async {
    try {
      final raw = await _storage.read(key: _keySignedVisitors);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        final results = <Map<String, dynamic>>[];
        for (final entry in decoded) {
          if (entry is Map) {
            results.add(
              entry.map(
                (key, value) => MapEntry(key.toString(), value),
              ),
            );
          }
        }
        return results;
      }
      return [];
    } catch (e) {
      debugPrint('Error loading signed visitors: $e');
      return [];
    }
  }

  /// Save kiosk admin password (used to exit kiosk)
  static Future<void> saveAdminPin(String pin) async {
    try {
      await _storage.write(key: _keyKioskAdminPin, value: pin);
      debugPrint('Admin PIN saved');
    } catch (e) {
      debugPrint('Error saving admin PIN: $e');
      rethrow;
    }
  }

  /// Load kiosk admin password (defaults to 1234 if none stored)
  static Future<String> getAdminPin() async {
    try {
      final value = await _storage.read(key: _keyKioskAdminPin);
      if (value == null || value.isEmpty) {
        return '1234';
      }
      return value;
    } catch (e) {
      debugPrint('Error loading admin PIN: $e');
      return '1234';
    }
  }

  // ---------------------------------------------------------
  // Data Fetch Failure Tracking
  // ---------------------------------------------------------

  /// Mark sites data fetch as failed
  static Future<void> markSitesFailure(String errorMessage) async {
    try {
      await _storage.write(key: _keyFetchFailureSites, value: errorMessage);
    } catch (e) {
      debugPrint('Error marking sites failure: $e');
    }
  }

  /// Mark contacts data fetch as failed
  static Future<void> markContactsFailure(String errorMessage) async {
    try {
      await _storage.write(key: _keyFetchFailureContacts, value: errorMessage);
    } catch (e) {
      debugPrint('Error marking contacts failure: $e');
    }
  }

  /// Mark client data fetch as failed
  static Future<void> markClientFailure(String errorMessage) async {
    try {
      await _storage.write(key: _keyFetchFailureClient, value: errorMessage);
    } catch (e) {
      debugPrint('Error marking client failure: $e');
    }
  }

  /// Get sites fetch failure message (null if no failure)
  static Future<String?> getSitesFailure() async {
    try {
      return await _storage.read(key: _keyFetchFailureSites);
    } catch (e) {
      return null;
    }
  }

  /// Get contacts fetch failure message (null if no failure)
  static Future<String?> getContactsFailure() async {
    try {
      return await _storage.read(key: _keyFetchFailureContacts);
    } catch (e) {
      return null;
    }
  }

  /// Get client fetch failure message (null if no failure)
  static Future<String?> getClientFailure() async {
    try {
      return await _storage.read(key: _keyFetchFailureClient);
    } catch (e) {
      return null;
    }
  }

  /// Clear all data fetch failure markers
  static Future<void> clearDataFetchFailures() async {
    try {
      await Future.wait([
        _storage.delete(key: _keyFetchFailureSites),
        _storage.delete(key: _keyFetchFailureContacts),
        _storage.delete(key: _keyFetchFailureClient),
      ]);
    } catch (e) {
      debugPrint('Error clearing fetch failures: $e');
    }
  }

  /// Check if any data fetch failed
  static Future<bool> hasAnyFetchFailure() async {
    final sitesFailure = await getSitesFailure();
    final contactsFailure = await getContactsFailure();
    final clientFailure = await getClientFailure();
    return sitesFailure != null || contactsFailure != null || clientFailure != null;
  }

  /// Get all fetch failures as a map
  static Future<Map<String, String>> getAllFetchFailures() async {
    final failures = <String, String>{};

    final sitesFailure = await getSitesFailure();
    if (sitesFailure != null) {
      failures['Sites'] = sitesFailure;
    }

    final contactsFailure = await getContactsFailure();
    if (contactsFailure != null) {
      failures['Contacts'] = contactsFailure;
    }

    final clientFailure = await getClientFailure();
    if (clientFailure != null) {
      failures['Client'] = clientFailure;
    }

    return failures;
  }

  // ========== PRINTER INFO STORAGE ==========

  /// Save last successfully discovered printer information
  /// This allows quick reconnection without network scanning
  static Future<void> saveLastPrinter({
    required String name,
    required String address,
    required String model,
  }) async {
    try {
      final printerData = jsonEncode({
        'name': name,
        'address': address,
        'model': model,
        'saved_at': DateTime.now().toIso8601String(),
      });
      await _storage.write(key: _keyLastPrinter, value: printerData);
    } catch (e) {
      debugPrint('Error saving printer info: $e');
    }
  }

  /// Get last successfully discovered printer information
  /// Returns Map with keys: name, address, model, saved_at
  /// Returns null if no printer info saved
  static Future<Map<String, dynamic>?> getLastPrinter() async {
    try {
      final printerJson = await _storage.read(key: _keyLastPrinter);
      if (printerJson == null || printerJson.isEmpty) {
        return null;
      }
      final printerData = jsonDecode(printerJson) as Map<String, dynamic>;
      return printerData;
    } catch (e) {
      debugPrint('Error reading printer info: $e');
      return null;
    }
  }

  /// Clear saved printer information
  static Future<void> clearLastPrinter() async {
    try {
      await _storage.delete(key: _keyLastPrinter);
    } catch (e) {
      debugPrint('Error clearing printer info: $e');
    }
  }

  // ========== PAPER TYPE STORAGE ==========

  /// Save selected paper type for printing
  /// Stores the full paper type configuration as JSON
  static Future<void> savePaperType(String paperTypeJson) async {
    try {
      await _storage.write(
        key: _keyPaperType,
        value: paperTypeJson,
      );
      debugPrint('Paper type saved: $paperTypeJson');
    } catch (e) {
      debugPrint('Error saving paper type: $e');
    }
  }

  /// Get saved paper type
  /// Returns paper type JSON string, or null if not set
  static Future<String?> getPaperType() async {
    try {
      return await _storage.read(key: _keyPaperType);
    } catch (e) {
      debugPrint('Error reading paper type: $e');
      return null;
    }
  }

  /// Clear saved paper type
  static Future<void> clearPaperType() async {
    try {
      await _storage.delete(key: _keyPaperType);
    } catch (e) {
      debugPrint('Error clearing paper type: $e');
    }
  }

  // ========== VISITOR REQUIREMENTS STORAGE ==========

  /// Save visitor field requirements
  /// Stores which fields are required during visitor sign-in
  static Future<void> saveVisitorRequirements(String requirementsJson) async {
    try {
      await _storage.write(
        key: _keyVisitorRequirements,
        value: requirementsJson,
      );
      debugPrint('Visitor requirements saved');
    } catch (e) {
      debugPrint('Error saving visitor requirements: $e');
    }
  }

  /// Get saved visitor field requirements
  /// Returns requirements JSON string, or null if not set
  static Future<String?> getVisitorRequirements() async {
    try {
      return await _storage.read(key: _keyVisitorRequirements);
    } catch (e) {
      debugPrint('Error reading visitor requirements: $e');
      return null;
    }
  }

  /// Clear saved visitor requirements
  static Future<void> clearVisitorRequirements() async {
    try {
      await _storage.delete(key: _keyVisitorRequirements);
    } catch (e) {
      debugPrint('Error clearing visitor requirements: $e');
    }
  }

  // ========== PRINT SETTINGS STORAGE ==========

  /// Save print-related settings
  /// Stores settings like automatic badge printing
  static Future<void> savePrintSettings(String settingsJson) async {
    try {
      await _storage.write(
        key: _keyPrintSettings,
        value: settingsJson,
      );
      debugPrint('Print settings saved');
    } catch (e) {
      debugPrint('Error saving print settings: $e');
    }
  }

  /// Get saved print settings
  /// Returns settings JSON string, or null if not set
  static Future<String?> getPrintSettings() async {
    try {
      return await _storage.read(key: _keyPrintSettings);
    } catch (e) {
      debugPrint('Error reading print settings: $e');
      return null;
    }
  }

  /// Clear saved print settings
  static Future<void> clearPrintSettings() async {
    try {
      await _storage.delete(key: _keyPrintSettings);
    } catch (e) {
      debugPrint('Error clearing print settings: $e');
    }
  }

  // ========== AUTO-NAVIGATE TO KIOSK FLAG ==========

  /// Save flag to auto-navigate to kiosk after dashboard loads
  static Future<void> saveAutoNavigateToKiosk(bool shouldNavigate) async {
    try {
      await _storage.write(
        key: _keyAutoNavigateToKiosk,
        value: shouldNavigate.toString(),
      );
      debugPrint('Auto-navigate to kiosk flag saved: $shouldNavigate');
    } catch (e) {
      debugPrint('Error saving auto-navigate flag: $e');
    }
  }

  /// Get auto-navigate to kiosk flag
  static Future<bool> getAutoNavigateToKiosk() async {
    try {
      final value = await _storage.read(key: _keyAutoNavigateToKiosk);
      return value == 'true';
    } catch (e) {
      debugPrint('Error reading auto-navigate flag: $e');
      return false;
    }
  }

  /// Clear auto-navigate to kiosk flag
  static Future<void> clearAutoNavigateToKiosk() async {
    try {
      await _storage.delete(key: _keyAutoNavigateToKiosk);
      debugPrint('Auto-navigate to kiosk flag cleared');
    } catch (e) {
      debugPrint('Error clearing auto-navigate flag: $e');
    }
  }
}
