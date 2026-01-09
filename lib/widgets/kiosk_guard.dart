import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;

/// Kiosk Guard Widget
/// Keeps the app in immersive mode and blocks accidental exit
/// - Blocks back button navigation
/// - Intercepts edge swipe gestures on iOS/iPadOS
/// - Shows warning when user tries to exit

class KioskGuard extends StatefulWidget {
  const KioskGuard({
    super.key,
    required this.child,
    this.exitMessage = 'Kiosk mode active. Use Admin Sign In to exit.',
  });

  final Widget child;
  final String exitMessage;

  @override
  State<KioskGuard> createState() => _KioskGuardState();
}

class _KioskGuardState extends State<KioskGuard> with WidgetsBindingObserver {
  DateTime? _lastGestureWarningTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _KioskModeManager.acquire();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _KioskModeManager.release();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _KioskModeManager.reapply();
    }
  }

  void _showExitWarning() {
    // Throttle warnings to avoid spam (show at most once per 3 seconds)
    final now = DateTime.now();
    if (_lastGestureWarningTime != null &&
        now.difference(_lastGestureWarningTime!).inSeconds < 3) {
      return;
    }
    _lastGestureWarningTime = now;

    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(widget.exitMessage),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.orange.shade700,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    // Wrap with GestureDetector to intercept edge gestures
    final gestureChild = GestureDetector(
      // Intercept gestures for iOS edge swipe navigation
      onHorizontalDragStart: (details) {
        // Detect edge swipes (from left or right edge)
        final screenWidth = MediaQuery.of(context).size.width;
        if (details.globalPosition.dx < 30 ||
            details.globalPosition.dx > screenWidth - 30) {
          _showExitWarning();
        }
      },
      onVerticalDragStart: (details) {
        // Detect swipe from bottom edge (iOS home gesture)
        final screenHeight = MediaQuery.of(context).size.height;
        if (details.globalPosition.dy > screenHeight - 50) {
          _showExitWarning();
        }
      },
      // CRITICAL: Use deferToChild to let PopScope handle back button
      behavior: HitTestBehavior.deferToChild,
      excludeFromSemantics: true,
      child: widget.child,
    );

    // PopScope blocks Android back button and iOS back gesture
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _showExitWarning();
        }
      },
      child: gestureChild,
    );
  }
}

/// Kiosk Mode Manager
/// Manages immersive mode with reference counting
class _KioskModeManager {
  static int _refCount = 0;

  static Future<void> acquire() async {
    _refCount++;
    await _applyImmersive();
  }

  static Future<void> release() async {
    if (_refCount > 0) {
      _refCount--;
    }
    if (_refCount == 0) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  static Future<void> reapply() async {
    if (_refCount > 0) {
      await _applyImmersive();
    }
  }

  static Future<void> _applyImmersive() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }
}
