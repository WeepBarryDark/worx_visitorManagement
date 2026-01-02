import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Service to manage kiosk mode features
/// - Prevents screen from sleeping (wakelock)
/// - Manages kiosk-specific behaviors
class KioskModeService {
  KioskModeService._(); // Private constructor

  static bool _isWakelockEnabled = false;

  /// Enable wakelock to keep screen awake
  /// Should be called when entering kiosk pages
  static Future<void> enableWakelock() async {
    try {
      await WakelockPlus.enable();
      _isWakelockEnabled = true;
      debugPrint('✓ Kiosk Mode: Wakelock enabled - screen will stay awake');
    } catch (e) {
      debugPrint('✗ Kiosk Mode: Failed to enable wakelock - $e');
    }
  }

  /// Disable wakelock to allow screen to sleep normally
  /// Should be called when leaving kiosk pages
  static Future<void> disableWakelock() async {
    try {
      await WakelockPlus.disable();
      _isWakelockEnabled = false;
      debugPrint('✓ Kiosk Mode: Wakelock disabled - screen can sleep normally');
    } catch (e) {
      debugPrint('✗ Kiosk Mode: Failed to disable wakelock - $e');
    }
  }

  /// Check if wakelock is currently enabled
  static Future<bool> isWakelockEnabled() async {
    try {
      return await WakelockPlus.enabled;
    } catch (e) {
      debugPrint('✗ Kiosk Mode: Failed to check wakelock status - $e');
      return false;
    }
  }

  /// Get the current wakelock status from cache
  static bool get wakelockEnabled => _isWakelockEnabled;

  /// Toggle wakelock on/off
  static Future<void> toggleWakelock() async {
    final isEnabled = await isWakelockEnabled();
    if (isEnabled) {
      await disableWakelock();
    } else {
      await enableWakelock();
    }
  }
}
