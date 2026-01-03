// Contractor Sign-In Page
// Displays QR code for contractors to self-register via web portal

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:worxvisitorapp/core/constants/server_link.dart';
import 'package:worxvisitorapp/core/constants/app_routes.dart';
import 'package:worxvisitorapp/core/responsive/app_breakpoints.dart';
import 'package:worxvisitorapp/widgets/kiosk_body.dart';
import 'package:worxvisitorapp/widgets/kiosk_guard.dart';
import 'package:worxvisitorapp/features/dashboard/controllers/dashboard_controller.dart';

class ContractorSignInPage extends StatelessWidget {
  const ContractorSignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final DashboardController? c =
        DashboardController.instance ??
        (args is DashboardController ? args : null);

    final backgroundImage = c?.backgroundImageUrl;
    final useCustomBackground =
        c?.useCustomBackground == true && backgroundImage != null;
    final siteTitle = c?.resolveSiteHeading('Contractor Sign In') ?? 'Contractor Sign In';
    final logoBytes = c?.clientLogoDisplayBytes;

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
                                data: ServerLink.mainServerURL,
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
                                  ServerLink.mainServerURL,
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
