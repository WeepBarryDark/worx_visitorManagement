import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DevicePermission {
  static const _storage = FlutterSecureStorage();
  static const _wifiPermissionSeenKey = 'wifi_permission_dialog_seen';
  /// Request local network permissions (for printer discovery)
  ///
  /// **Why we need this:**
  /// - Android: Requires location permission for local network scanning
  /// - iOS: Uses local network permission (automatically prompted by system)
  /// - This is a security requirement, NOT for tracking location
  /// - We only use it to scan WiFi network for printers (port 9100, 515, 631)
  ///
  /// **iOS:** The system will automatically prompt for local network access when
  /// the app first tries to discover network devices. No manual request needed.
  ///
  /// Shows dialog to explain and guide user
  static Future<bool> requestLocationPermission(BuildContext context) async {
    if (kIsWeb) return true; // Web doesn't need location permission

    // iOS: Local network permission is handled automatically by the system
    // When the app tries to discover printers, iOS will show a system prompt
    if (Platform.isIOS) {
      // Check if user has already seen the dialog
      final hasSeenDialog = await _storage.read(key: _wifiPermissionSeenKey);

      // Only show dialog if user hasn't seen it before
      if (hasSeenDialog != 'true' && context.mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('WiFi Network Access'),
            content: const Text(
              'This app discovers Brother printers on your WiFi network.\n\n'
              'iOS will ask for permission to find devices on your local network.\n\n'
              'Please tap "Allow" when prompted to enable printer discovery.\n\n'
              'Note: This is required for the app to work. Your network activity is not tracked.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got It'),
              ),
            ],
          ),
        );

        // Mark as seen so it won't show again
        await _storage.write(key: _wifiPermissionSeenKey, value: 'true');
      }
      return true; // iOS handles local network permission automatically
    }

    // Android: Check current permission status
    var status = await Permission.location.status;

    if (status.isGranted) {
      return true;
    }

    // Show explanation dialog before requesting
    if (context.mounted) {
      final shouldRequest = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Local Network Access'),
          content: const Text(
            'To discover printers on your WiFi network, this app needs permission to scan your local network.\n\n'
            'We only scan for printers on your network. '
            'Your location and data are NOT tracked or stored.\n\n'
            'Tap "Allow" on the next screen to continue.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continue'),
            ),
          ],
        ),
      );

      if (shouldRequest != true) {
        return false;
      }
    }

    // Request permission
    status = await Permission.location.request();

    if (status.isGranted) {
      return true;
    }

    // If denied (including permanently denied), guide user to settings
    if (context.mounted) {
      final shouldOpenSettings = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Permission Required'),
          content: const Text(
            'Local network access is required to discover printers.\n\n'
            'Please enable this permission in Settings to continue.\n\n'
            'We will open Settings for you now.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );

      if (shouldOpenSettings == true) {
        await openAppSettings();
      }
    }

    return false;
  }

  /// Request nearby devices permission (Android 12+ only - iOS uses WiFi only)
  ///
  /// **Why we need this:**
  /// - Android 12+: Required to scan for nearby network devices
  /// - iOS: NOT USED - iOS uses WiFi network discovery only (no Bluetooth)
  /// - Allows discovery of printers via local network
  /// - We only use it to find printers, not to track devices
  ///
  /// Shows dialog to explain and guide user
  static Future<bool> requestNearbyDevicesPermission(BuildContext context) async {
    if (kIsWeb) return true;

    // iOS: Skip Bluetooth permission entirely - use WiFi only
    if (Platform.isIOS) {
      return true; // iOS uses local network permission for WiFi printer discovery
    }

    // Android: Request Bluetooth scan permission
    final permission = Permission.bluetoothScan;
    var status = await permission.status;

    if (status.isGranted) {
      return true;
    }

    // Show explanation dialog
    if (context.mounted) {
      final shouldRequest = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Nearby Devices Access'),
          content: const Text(
            'To discover printers on your network, this app needs permission to scan for nearby devices.\n\n'
            'This allows the app to find printers via WiFi and Bluetooth.\n\n'
            'We only use this to find printers.\n\n'
            'Tap "Allow" on the next screen to continue.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continue'),
            ),
          ],
        ),
      );

      if (shouldRequest != true) {
        return false;
      }
    }

    // Request permission
    status = await permission.request();

    if (status.isGranted) {
      return true;
    }

    // Handle denial - guide to settings
    if (context.mounted) {
      final shouldOpenSettings = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Permission Required'),
          content: const Text(
            'Nearby devices access is required to discover printers.\n\n'
            'Please enable this permission in Settings to continue.\n\n'
            'We will open Settings for you now.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );

      if (shouldOpenSettings == true) {
        await openAppSettings();
      }
    }

    return false;
  }

  /// Request all necessary permissions for printer discovery
  static Future<bool> requestPrinterPermissions(BuildContext context) async {
    if (kIsWeb) return true;

    // Request location permission first (required for network scanning)
    final hasLocation = await requestLocationPermission(context);
    if (!hasLocation || !context.mounted) {
      return false;
    }

    // Request nearby devices permission (Android 12+ / iOS Bluetooth)
    final hasNearbyDevices = await requestNearbyDevicesPermission(context);
    if (!hasNearbyDevices) {
      return false;
    }

    return true;
  }

  /// Show dialog with retry option after user returns from settings
  static Future<bool> showRetryPermissionDialog(BuildContext context) async {
    final retry = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Permission Status'),
        content: const Text(
          'Did you enable the required permissions?\n\n'
          'Tap "Retry" to check permissions again, or "Cancel" to continue without printer discovery.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
    return retry ?? false;
  }

  /// Check if all printer permissions are granted
  static Future<bool> hasAllPrinterPermissions() async {
    if (kIsWeb) return true;

    // iOS: Local network permission is handled automatically by system
    // No way to check it programmatically, so we assume it's granted
    if (Platform.isIOS) {
      return true; // iOS will prompt automatically when discovering printers
    }

    // Android needs location + nearby devices
    final locationStatus = await Permission.location.status;
    final bluetoothStatus = await Permission.bluetoothScan.status;

    return locationStatus.isGranted && bluetoothStatus.isGranted;
  }
}
