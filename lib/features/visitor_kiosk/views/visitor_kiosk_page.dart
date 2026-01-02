// Visitor Kiosk Main Page
// Entry point for visitor sign-in, sign-out, and delivery workflows

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:worxvisitorapp/core/constants/app_routes.dart';
import 'package:worxvisitorapp/core/responsive/app_breakpoints.dart';
import 'package:worxvisitorapp/widgets/kiosk_body.dart';
import 'package:worxvisitorapp/widgets/kiosk_guard.dart';
import 'package:worxvisitorapp/features/dashboard/controllers/dashboard_controller.dart';
import 'package:worxvisitorapp/services/secure_storage_service.dart';

class VisitorDashboard extends StatelessWidget {
  const VisitorDashboard({super.key});

  Future<void> _handleAdminSignIn(BuildContext context) async {
    final success = await showDialog<bool>(
      context: context,
      builder: (context) => const _AdminPasswordDialog(),
    );
    if (success == true && context.mounted) {
      //Persist current site
      final controller = DashboardController.instance;
      final previousSite = controller?.currentSite;
      if (previousSite != null) {
        try {
          await SecureStorageService.saveSelectedSite(
            jsonEncode(previousSite.toJson()),
          );
        } catch (e) {
          debugPrint('Fail to persist select site: $e');
        }
      }
      if (!context.mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.dashboard,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final DashboardController? c =
        DashboardController.instance ??
        (args is DashboardController ? args : null); // forward settings if any
    final backgroundImage = c?.backgroundImageUrl;
    final useCustomBackground =
        c?.useCustomBackground == true && backgroundImage != null;

    final siteTitle = c?.resolveSiteHeading('Visitor Kiosk') ?? 'Visitor Kiosk';
    final logoBytes = c?.clientLogoDisplayBytes;

    const double maxBodyWidth = AppBreakpoints.compact;

    debugPrint('useCustomBackground = ${c?.useCustomBackground}');

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
                  footerAction: IconButton(
                    tooltip: 'Admin Sign In',
                    icon: const Icon(Icons.admin_panel_settings),
                    onPressed: () => _handleAdminSignIn(context),
                  ),
                  menuContent: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Visitor Sign In button
                          FilledButton.icon(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              AppRoutes.visitorSignIn,
                              arguments: c,
                            ),
                            icon: const Icon(Icons.person_add, size: 22),
                            label: const Text('Visitor Sign In'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 56),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Visitor Sign Out button
                          FilledButton.icon(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              AppRoutes.visitorSignOut,
                              arguments: c,
                            ),
                            icon: const Icon(Icons.logout, size: 22),
                            label: const Text('Visitor Sign Out'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 56),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Delivery button
                          FilledButton.icon(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              AppRoutes.visitorDeliveries,
                              arguments: c,
                            ),
                            icon: const Icon(Icons.local_shipping, size: 22),
                            label: const Text('Delivery'),
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
          ), // Close Container for Channel 7 background
        ),
      ),
    );
  }
}

class _AdminPasswordDialog extends StatefulWidget {
  const _AdminPasswordDialog();

  @override
  State<_AdminPasswordDialog> createState() => _AdminPasswordDialogState();
}

class _AdminPasswordDialogState extends State<_AdminPasswordDialog> {
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  String? _errorText;
  String _expectedPassword = '1234';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAdminPassword();
  }

  Future<void> _loadAdminPassword() async {
    final pin = await SecureStorageService.getAdminPin();
    if (!mounted) return;
    setState(() {
      _expectedPassword = pin;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _validate() {
    if (_loading) return;
    if (_passwordCtrl.text.trim() == _expectedPassword) {
      Navigator.of(context).pop(true); // Return true on success
    } else {
      setState(() => _errorText = 'Incorrect password');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 24,
        bottom: bottomInset > 0 ? bottomInset : 24,
      ),
      child: Center(
        child: Material(
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Admin Sign In', style: tt.titleLarge),
                  const SizedBox(height: 16),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else ...[
                    Text(
                      'Enter the administrator password to exit kiosk mode. '
                      'You can change this password from the dashboard.',
                      style: tt.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _passwordCtrl,
                      obscureText: _obscure,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        errorText: _errorText,
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      onSubmitted: (_) => _validate(),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: _loading ? null : _validate,
                        child: const Text('Confirm'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
