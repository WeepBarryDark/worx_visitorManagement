// Contractor Sign-In Page
// Displays QR code for contractors to self-register via web portal

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:worxvisitorapp/core/constants/app_routes.dart';
import 'package:worxvisitorapp/core/responsive/app_breakpoints.dart';
import 'package:worxvisitorapp/widgets/kiosk_body.dart';
import 'package:worxvisitorapp/widgets/kiosk_guard.dart';
import 'package:worxvisitorapp/features/dashboard/controllers/dashboard_controller.dart';
import 'package:worxvisitorapp/services/secure_storage_service.dart';

class ContractorSignInPage extends StatefulWidget {
  const ContractorSignInPage({super.key});

  @override
  State<ContractorSignInPage> createState() => _ContractorSignInPageState();
}

class _ContractorSignInPageState extends State<ContractorSignInPage> {
  String? _clientSlug;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClientData();
  }

  Future<void> _loadClientData() async {
    try {
      final clientJson = await SecureStorageService.getClient();
      if (clientJson != null && clientJson.isNotEmpty) {
        final client = jsonDecode(clientJson) as Map<String, dynamic>;
        debugPrint('📊 Contractor Sign-In: Client data loaded');
        debugPrint('   Raw client: $client');

        // Try to get slug from different possible fields
        final slug = client['slug'] as String? ??
                     client['client_slug'] as String? ??
                     client['identifier'] as String?;

        debugPrint('   Extracted slug: $slug');

        if (mounted) {
          setState(() {
            _clientSlug = slug;
            _isLoading = false;
          });
        }
      } else {
        debugPrint('⚠️ Contractor Sign-In: No client data found in storage');
        if (mounted) {
          setState(() {
            _clientSlug = null;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading client data: $e');
      if (mounted) {
        setState(() {
          _clientSlug = null;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final DashboardController? c = DashboardController.instance ?? (args is DashboardController ? args : null);

    final backgroundImage = c?.backgroundImageUrl;
    final useCustomBackground = c?.useCustomBackground == true && backgroundImage != null;
    final siteTitle = c?.resolveSiteHeading('Contractor Sign In') ?? 'Contractor Sign In';
    final logoBytes = c?.clientLogoDisplayBytes;

    // Show loading indicator while fetching client data
    if (_isLoading) {
      debugPrint('⏳ Contractor Sign-In: Still loading client data...');
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    debugPrint('✅ Contractor Sign-In: Loading complete, building UI...');

    // Build URL with client slug and project ID from selected site
    // Format: https://app.worxsafety.com.au/{clientSlug}/projects/view/{siteId}
    // If missing slug or siteId, fallback to https://app.worxsafety.com.au
    final siteId = c?.currentSite?.id ?? '';
    final clientSlug = _clientSlug;

    debugPrint('═════════════════════════════════════════════');
    debugPrint('🔗 CONTRACTOR SIGN-IN URL BUILDER');
    debugPrint('   Client Slug: "$clientSlug"');
    debugPrint('   Site ID: "$siteId"');
    debugPrint('   Current Site: ${c?.currentSite?.title ?? "NULL"}');

    final String siteUrl;
    if (clientSlug != null && clientSlug.isNotEmpty && siteId.isNotEmpty) {
      // Both slug and site ID available - build full URL
      siteUrl = 'https://app.worxsafety.com.au/$clientSlug/projects/view/$siteId';
      debugPrint('✅ FULL URL: $siteUrl');
    } else {
      // Missing slug or site ID - use base URL
      siteUrl = 'https://app.worxsafety.com.au';
      debugPrint('⚠️ FALLBACK URL: $siteUrl');
      if (clientSlug == null || clientSlug.isEmpty) {
        debugPrint('   ❌ Problem: Client Slug is missing!');
      }
      if (siteId.isEmpty) {
        debugPrint('   ❌ Problem: Site ID is missing!');
      }
    }
    debugPrint('═════════════════════════════════════════════');

    const double maxBodyWidth = AppBreakpoints.compact;

    return KioskGuard(
      child: Scaffold(
        body: Container(
          decoration: useCustomBackground
              ? BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(backgroundImage),
                    fit: BoxFit.cover,
                    opacity: 0.9,
                  ),
                )
              : null,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: maxBodyWidth),
                child: KioskBody(
                  siteTitle: siteTitle,
                  logo1Bytes: logoBytes,
                  logo1Url: logoBytes == null
                      ? 'lib/assets/images/WorxSafety_Logo_NoShadow.svg'
                      : null,
                  logo2Url: 'lib/assets/images/Worx_PoweredBy_Logo_Mono.svg',
                  menuContent: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Title
                          Text(
                            'Contractor Registration',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),

                          // Instructions
                          Text(
                            'Scan the QR code below with your mobile device to complete contractor registration',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),

                          // QR Code
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: QrImageView(
                                key: ValueKey(siteUrl), // Force rebuild when URL changes
                                data: siteUrl,
                                version: QrVersions.auto,
                                size: 280,
                                backgroundColor: Colors.white,
                                errorCorrectionLevel: QrErrorCorrectLevel.M,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // URL Display
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.link,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  siteUrl,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontFamily: 'monospace',
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Next Visitor Button
                          FilledButton.icon(
                            onPressed: () => Navigator.pushNamedAndRemoveUntil(
                              context,
                              AppRoutes.visitorKiosk,
                              (route) => false,
                              arguments: c,
                            ),
                            icon: const Icon(Icons.arrow_forward, size: 22),
                            label: const Text('Next Visitor'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 56),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
