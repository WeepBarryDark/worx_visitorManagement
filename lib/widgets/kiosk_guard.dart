import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Kiosk Guard Widget
/// Keeps the app in immersive mode and blocks accidental exit

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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          final messenger = ScaffoldMessenger.of(context);
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(widget.exitMessage),
                duration: const Duration(seconds: 2),
              ),
            );
        }
      },
      child: widget.child,
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
