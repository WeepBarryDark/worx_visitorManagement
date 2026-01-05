import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:worxvisitorapp/core/responsive/app_breakpoints.dart';
import 'package:worxvisitorapp/core/theme/app_theme.dart';
import 'package:worxvisitorapp/core/constants/app_routes.dart';

import 'package:worxvisitorapp/features/auth/controllers/auth_controller.dart';
import 'package:worxvisitorapp/services/api_service.dart';
import 'package:worxvisitorapp/widgets/auth_body.dart';
import 'package:worxvisitorapp/services/secure_storage_service.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPage();
}

class _AuthPage extends State<AuthPage> {
  late final AuthController _controller;
  bool _isCheckingInitialAuth = true;

  @override
  void initState() {
    super.initState();
    // STEP 0: Create LoginController and provide the onApproved callback.
    _controller = AuthController(
      onApproved: () async {
        await _navigateBasedOnSites();
      },
    );
    // STEP 1: Immediately check if device is already authenticated.
    _init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width; // the current screensize 
    final maxBodyWidth = AppBreakpoints.getContentWidth(width);

    return Scaffold(
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxBodyWidth),
                child: AuthBody(
                  siteTitle: 'Worx Kiosk - Visitor Management',
                  logo1Url: 'lib/assets/images/WorxSafety_Logo_NoShadow.svg',
                  logo2Url: 'lib/assets/images/Worx_PoweredBy_Logo_Mono.svg',
                  menuContent: _TabletAuthCard(
                    controller: _controller,
                    isCheckingInitialAuth: _isCheckingInitialAuth,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Logic Functions
  /// STEP 1:
  /// Check if this tablet is already authenticated.
  ///
  /// - If YES  -> navigate directly to the main entry (index)
  /// - If NO   -> generate QR and start normal QR login flow
  Future<void> _init() async {
    setState(() {
      _isCheckingInitialAuth = true;
    });

    final isAuth = await _controller.checkExistingAuth();
    //await SecureStorageService.saveSelectedSite(jsonEncode(singleSite));  if this has valued, then move to navigation as well

    if (!mounted) return;

    if (isAuth) {
      // Already authenticated -> directly go to the main entry (index).
      await _navigateBasedOnSites();
    } else {
      // Not authenticated yet or throw error -> override the current QR and start QR login flow.
      _controller.generateLocalQr();
      setState(() {
        _isCheckingInitialAuth = false;
      });
    }
  }

  /// This will be called when:
  ///   - initial check finds an existing login, OR
  ///   - QR login is approved (controller.onApproved)
  ///
  /// Here you implement your own routing logic:
  ///   - e.g. /new-site vs /dashboard based on stored sites
  /// Navigate to site selection or dashboard based on number of sites
  Future<void> _navigateBasedOnSites() async {
    //cache context-dependent objects BEFORE any await
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    //Get the saved token
    final savedToken = await SecureStorageService.getAuthToken();
    //verify Token
    // after await and before first context, need to check mounted
    if (!mounted) return;
    if (savedToken == null || savedToken.isEmpty) {
      try {
        await SecureStorageService.clearAll();
      } catch (_) {
        debugPrint('_navigatebasedOnsite clear all error');
      }
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      return;
    }
  
    //Get Site, Clinet 
    try {
      // Get sites by API key
      final sitesJson = await ApiService.fetchVisitorSites(savedToken);
      final rawCount = sitesJson['count'];
      final rawData = sitesJson['data'];

      final int sitesCount = rawCount is int ? rawCount : 0;
      final List<dynamic> sites = rawData is List ? rawData : [];

      await SecureStorageService.saveSites(jsonEncode(sites));

      // Get client data - Check local storage first, only fetch from API if not cached
      String? cachedClientJson = await SecureStorageService.getClient();

      if (cachedClientJson == null || cachedClientJson.isEmpty) {
        // No cached client data → fetch from API
        debugPrint('📥 Fetching client data from API (first time)...');
        final clientJson = await ApiService.fetchVisitorClient(savedToken);
        await SecureStorageService.saveClient(jsonEncode(clientJson));
        cachedClientJson = jsonEncode(clientJson);
        debugPrint('✓ Client data cached to local storage');
      } else {
        debugPrint('✓ Using cached client data from local storage');
      }

      //debugPrint('Client data: $cachedClientJson');

      if (!mounted) return;
      //If there is a saved selected site, check if we can go directly to kiosk
      final String? selectedSiteJson = await SecureStorageService.getSelectedSite();
      final bool hasSelectedSite = selectedSiteJson != null && selectedSiteJson.trim().isNotEmpty;

      if (!mounted) return;
      if (hasSelectedSite) {
        // Check if admin PIN is set (indicates kiosk is configured)
        final String adminPin = await SecureStorageService.getAdminPin();
        final bool hasAdminPin = adminPin.trim().isNotEmpty;

        if (!context.mounted) return;

        if (hasAdminPin) {
          // All kiosk parameters ready → go to dashboard, it will auto-navigate to kiosk
          // Store a flag to indicate we should auto-navigate to kiosk
          await SecureStorageService.saveAutoNavigateToKiosk(true);

          if (!mounted) return;
          nav.pushReplacementNamed(AppRoutes.dashboard);
        } else {
          // Site selected but no admin PIN → go to dashboard for setup (don't auto-navigate)
          await SecureStorageService.clearAutoNavigateToKiosk();

          if (!mounted) return;
          nav.pushReplacementNamed(AppRoutes.dashboard);
        }
        return;
      }
      //------------------------------------------------------------------end selected site directly

      if (sites.length > 1 || sitesCount ==0 ||sites.isEmpty) {
        nav.pushReplacementNamed(AppRoutes.newSite);
      } else {
        // Save the single site as selected site before navigating to dashboard
        final singleSite = sites.first as Map<String, dynamic>;
        await SecureStorageService.saveSelectedSite(jsonEncode(singleSite));
        if (!mounted) return;
        nav.pushReplacementNamed(AppRoutes.dashboard);
      }
    } catch (e) {
      dev.log('auth fetches sites error, which is caused by $e');
      if (!mounted) return;
      //stay oj a8tu Screen and inform the user
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            "Offline or Server Unreachable. Check Internet Connection and restart this app. If its not internet issue, please contact developer",
          ),
          duration: Duration(seconds: 5),
        ),
      );
    }
  }
}

class _TabletAuthCard extends StatelessWidget {
  final AuthController controller;
  final bool isCheckingInitialAuth;

  const _TabletAuthCard({
    required this.controller,
    required this.isCheckingInitialAuth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      //container + decoration create a blue warp
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryBlue.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          const _TabletAuthHeader(),
          const SizedBox(height: 16),
          const _TableAuthInstructionBox(),
          const SizedBox(height: 16),
          _TabletAuthQrBox(
            controller: controller,
            isCheckingInitialAuth: isCheckingInitialAuth,
          ),
          const SizedBox(height: 16),
          _TabletAuthStatusBar(
            controller: controller,
            isCheckingInitialAuth: isCheckingInitialAuth,
          ),
          const SizedBox(height: 16),
          _TabletAuthButtons(
            controller: controller,
            isCheckingInitialAuth: isCheckingInitialAuth,
          ),
        ],
      ),
    );
  }
}

// Worx logo and Title
class _TabletAuthHeader extends StatelessWidget {
  const _TabletAuthHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.qr_code_2, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Kiosk Authentication',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.slate800,
            ),
          ),
        ),
      ],
    );
  }
}

//instruction section
class _TableAuthInstructionBox extends StatelessWidget {
  const _TableAuthInstructionBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppTheme.primaryBlue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Scan this QR code with a device already logged into Worx Safety, '
              'then click "I have scanned the barcode".',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.slate700,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

//QR code Area
class _TabletAuthQrBox extends StatelessWidget {
  final AuthController controller;
  final bool isCheckingInitialAuth;

  const _TabletAuthQrBox({
    required this.controller,
    required this.isCheckingInitialAuth,
  });

  @override
  Widget build(BuildContext context) {
    final bool showLoading = isCheckingInitialAuth || controller.qrUrl == null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: SizedBox(
        width: 220,
        height: 220,
        child: Center(
          child: showLoading
              ? const CircularProgressIndicator()
              : QrImageView(
                  data: controller.qrUrl!,
                  version: QrVersions.auto,
                  size: 220,
                  backgroundColor: Colors.white,
                ),
        ),
      ),
    );
  }
}

//Status bar : show/succss/fail + icon/circling
class _TabletAuthStatusBar extends StatelessWidget {
  final AuthController controller;
  final bool isCheckingInitialAuth;

  const _TabletAuthStatusBar({
    required this.controller,
    required this.isCheckingInitialAuth,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPolling = controller.isPolling;
    final bool hasError = controller.hasError;

    // first check or polling with spinner
    final bool showSpinner = isPolling || isCheckingInitialAuth;

    final Color backgroundColor = hasError
        ? AppTheme.statusBackgroundColor('error')
        : showSpinner
        ? AppTheme.primaryBlue.withValues(alpha: 0.1)
        : AppTheme.statusBackgroundColor('success');

    final Color borderColor = hasError
        ? AppTheme.dangerColor.withValues(alpha: 0.3)
        : showSpinner
        ? AppTheme.primaryBlue.withValues(alpha: 0.3)
        : AppTheme.successColor.withValues(alpha: 0.3);

    final String message = isCheckingInitialAuth
        ? 'Checking if this tablet is already logged in...'
        : controller.statusMessage;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        children: [
          if (showSpinner)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
              ),
            )
          else
            Icon(
              hasError ? Icons.error_outline : Icons.check_circle_outline,
              color: hasError ? AppTheme.dangerColor : AppTheme.successColor,
              size: 20,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message, //  message
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.slate800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// bottom section
// show "I have scanned the barcode"
// show "Re-scan QR code"
// show "Restart QR login"
class _TabletAuthButtons extends StatelessWidget {
  final AuthController controller;
  final bool isCheckingInitialAuth;

  const _TabletAuthButtons({
    required this.controller,
    required this.isCheckingInitialAuth,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasError = controller.hasError;
    final bool isPollingStarted = controller.isPollingStarted;

    return Column(
      children: [
        if (!isPollingStarted)
          FilledButton.icon(
            // When initial auth check is running, disable the button
            onPressed: isCheckingInitialAuth ? null : controller.startPolling,
            icon: const Icon(Icons.done, size: 20),
            label: Text(isCheckingInitialAuth ? 'Checking login status...' : 'I have scanned the barcode',),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          )
        else
          FilledButton.icon(
            onPressed: null,
            icon: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            label: const Text('Waiting for approval...'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        if (hasError) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: controller.generateLocalQr,
            icon: const Icon(Icons.refresh, size: 20),
            label: const Text('Restart QR Login'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.warningColor,
              side: BorderSide(color: AppTheme.warningColor, width: 1.5),
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ],
    );
  }
}
