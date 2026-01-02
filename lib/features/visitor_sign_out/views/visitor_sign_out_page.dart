import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:worxvisitorapp/widgets/kiosk_field.dart';
import 'package:worxvisitorapp/core/constants/app_routes.dart';
import 'package:worxvisitorapp/core/responsive/app_breakpoints.dart';
import 'package:worxvisitorapp/core/theme/app_theme.dart';
import 'package:worxvisitorapp/widgets/kiosk_body.dart';
import 'package:worxvisitorapp/widgets/qr_scanner_widget.dart';
import 'package:worxvisitorapp/widgets/kiosk_guard.dart';
import 'package:worxvisitorapp/features/dashboard/controllers/dashboard_controller.dart';
import 'package:worxvisitorapp/services/secure_storage_service.dart';
import 'package:worxvisitorapp/services/timezone_service.dart';
import 'package:worxvisitorapp/services/contact_loader.dart';
import 'package:worxvisitorapp/services/site_loader.dart';
import 'package:worxvisitorapp/services/notification_service.dart';
import 'package:worxvisitorapp/services/api_service.dart';

class VisitorSignOutPage extends StatefulWidget {
  const VisitorSignOutPage({super.key});

  @override
  State<VisitorSignOutPage> createState() => _VisitorSignOutPage();
}

class _VisitorSignOutPage extends State<VisitorSignOutPage> {
  final _formKey = GlobalKey<FormState>();
  final _visitorIdCtrl = TextEditingController();
  bool _scannedFromQR = false;
  bool _isInitializing = true; // Track page loading state
  Map<String, _SignedVisitor> _visitorsById = {};

  // Client background branding
  String? _backgroundImageUrl;
  bool _useCustomBackground = false;

  @override
  void initState() {
    super.initState();
    // Reset form state to ensure clean initialization
    _visitorIdCtrl.clear();
    _scannedFromQR = false;
    _loadBackgroundFromStorage();
    _initializePage();
  }

  /// Initialize page data - load visitors, contacts, and sites
  Future<void> _initializePage() async {
    setState(() {
      _isInitializing = true;
    });

    // Load data in parallel for faster initialization
    await Future.wait([
      _loadRecentVisitors(),
      _refreshContacts(),
      _refreshSites(),
    ]);

    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  Future<void> _loadBackgroundFromStorage() async {
    final cachedClient = await SecureStorageService.getClient();
    if (cachedClient == null || cachedClient.isEmpty) return;

    try {
      final client = jsonDecode(cachedClient) as Map<String, dynamic>;
      final backgroundImage = client['background_image'] as String?;

      if (_isValidBackground(backgroundImage)) {
        final controller = DashboardController.instance;
        if (controller != null) {
          controller.backgroundImageUrl = backgroundImage;
          controller.useCustomBackground = true;
        }

        if (mounted) {
          setState(() {
            _backgroundImageUrl = backgroundImage;
            _useCustomBackground = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading background image from storage: $e');
    }
  }

  bool _isValidBackground(String? backgroundImage) {
    if (backgroundImage == null) return false;
    final lower = backgroundImage.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg');
  }

  @override
  void dispose() {
    _visitorIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRecentVisitors() async {
    final visitors = await SecureStorageService.getSignedVisitors();
    if (!mounted) return;

    final byId = <String, _SignedVisitor>{};
    for (final visitor in visitors) {
      final id = visitor['id']?.toString().trim() ?? '';
      final email = visitor['email']?.toString().trim().toLowerCase() ?? '';
      final fullName = visitor['full_name']?.toString() ?? '';
      final supervisorId = visitor['supervisor_id']?.toString().trim() ?? '';
      final supervisorName =
          visitor['supervisor_name']?.toString().trim() ?? '';
      final supervisorEmail =
          visitor['supervisor_email']?.toString().trim() ?? '';
      final supervisorPhone =
          visitor['supervisor_phone']?.toString().trim() ?? '';
      final notifyViaSms = visitor['notify_via_sms'] == true;
      final notifyViaEmail = visitor['notify_via_email'] == true;

      final record = _SignedVisitor(
        id: id,
        email: email,
        fullName: fullName,
        supervisorId: supervisorId,
        supervisorName: supervisorName,
        supervisorEmail: supervisorEmail,
        supervisorPhone: supervisorPhone,
        notifyViaSms: notifyViaSms,
        notifyViaEmail: notifyViaEmail,
      );

      if (id.isNotEmpty) {
        byId[id] = record;
      }
    }

    setState(() {
      _visitorsById = byId;
    });
  }

  Future<void> _refreshContacts() async {
    final controller = DashboardController.instance;
    if (controller == null) return;
    final supervisors = await ContactLoader.reloadSupervisors();
    if (supervisors.isNotEmpty) {
      controller.updateAvailableSupervisors(supervisors);
      if (mounted) setState(() {});
    }
  }

  Future<void> _refreshSites() async {
    final controller = DashboardController.instance;
    if (controller == null) return;
    final sites = await SiteLoader.reloadSites();
    if (sites.isEmpty) return;
    controller.sites = sites;
    final current = controller.currentSite;
    if (current != null) {
      final match = sites.firstWhere(
        (site) => site.id == current.id,
        orElse: () => sites.first,
      );
      controller.selectSite(match);
    } else {
      controller.selectSite(sites.first);
    }
    if (mounted) setState(() {});
  }

  /// Handle visitor sign-out using API
  Future<void> _handleSignOut(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final visitorId = _visitorIdCtrl.text.trim();

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Get auth token
      final authToken = await SecureStorageService.getAuthToken();
      if (authToken == null || authToken.isEmpty) {
        if (!context.mounted) return;
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication required. Please log in again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Call sign-out API
      final result = await ApiService.signOutVisitor(
        visitorId: visitorId,
        authToken: authToken,
      );
      //debugPrint("call sign-out API----------------------------------");
      //print(result);

      if (!context.mounted) return;
      Navigator.pop(context); // Close loading

      // Check if already signed out by examining the data.success field
      final dataSuccess = result['data']?['success'];
      final isAlreadySignedOut =
          dataSuccess is String &&
          dataSuccess.toLowerCase().contains('already been signed out');

      if (result['success'] == true && !isAlreadySignedOut) {
        // Capture sign-out timestamp for notifications
        final signOutSnapshot = TimezoneService.captureNow();
        final signOutUtc = signOutSnapshot.formattedUtc;

        // Get visitor data to retrieve supervisor info and notification preferences
        final visitorRecord = _visitorsById[visitorId];

        if (visitorRecord == null) {
          // Still allow sign-out but without notifications
          await _showSignOutSuccess(context, visitorId, signOutUtc);
          return;
        }

        // Retrieve supervisor info from visitor record
        final supervisorId = visitorRecord.supervisorId;
        //final supervisorName = visitorRecord.supervisorName;
        final supervisorEmail = visitorRecord.supervisorEmail;
        final supervisorPhone = visitorRecord.supervisorPhone;
        final notifyViaSms = visitorRecord.notifyViaSms;
        final notifyViaEmail = visitorRecord.notifyViaEmail;

        // ONE-RECIPIENT SAFETY CHECK
        if (supervisorId.isEmpty) {
          debugPrint(
            'No supervisor assigned for visitor $visitorId - skipping notifications',
          );
          await _showSignOutSuccess(context, visitorId, signOutUtc);
          return;
        }
        /*debugPrint(
      'VISITOR SIGN-OUT NOTIFICATION CHECK | '
      'Timestamp: ${DateTime.now().toIso8601String()} | '
      'Visitor ID: $visitorId | '
      'Visitor Name: ${visitorRecord.fullName} | '
      'Visitor Email: ${visitorRecord.email} | '
      'Supervisor ID: $supervisorId | '
      'Supervisor Name: $supervisorName | '
      'Supervisor Email: $supervisorEmail | '
      'Supervisor Phone: $supervisorPhone | '
      'Send SMS: $notifyViaSms | '
      'Send Email: $notifyViaEmail'
    );*/
        // Get dashboard controller for site info
        final c = DashboardController.instance;
        final siteName =
            c?.resolveSiteHeading('Visitor Site') ?? 'Visitor Site';

        // Get logo URL from secure storage
        String? logoUrl;
        try {
          final clientJson = await SecureStorageService.getClient();
          if (clientJson != null && clientJson.isNotEmpty) {
            final client = jsonDecode(clientJson) as Map<String, dynamic>;
            logoUrl = client['logo'] as String?;
          }
        } catch (e) {
          debugPrint('Failed to load logo URL: $e');
        }

        // Send SMS notification if enabled during sign-in
        if (notifyViaSms && supervisorPhone.trim().isNotEmpty) {
          final message = NotificationService.buildVisitorSignOutMessage(
            siteName: siteName,
            visitorName: visitorRecord.fullName,
          );

          /*debugPrint(
        'SENDING SMS - VISITOR SIGN-OUT NOTIFICATION | '
        'Timestamp: ${DateTime.now().toIso8601String()} | '
        'Recipient ID: $supervisorId | '
        'Recipient Name: $supervisorName | '
        'Recipient Phone: $supervisorPhone | '
        'Recipient Email: $supervisorEmail | '
        'Message: $message | '
        'Message Length: ${message.length} characters | '
        'Site: $siteName'
      );*/

          final smsSuccess = await NotificationService.sendTextMessage(
            userId: supervisorId,
            mobile: supervisorPhone,
            message: message,
          );
          debugPrint(
            '${smsSuccess ? "success" : "fail"} SMS Send Result: ${smsSuccess ? "SUCCESS" : "FAILED"}',
          );
        }

        // Send email notification if enabled during sign-in
        if (notifyViaEmail && supervisorEmail.trim().isNotEmpty) {
          final email = NotificationService.buildVisitorSignOutEmail(
            siteName: siteName,
            visitorName: visitorRecord.fullName,
          );

          /*debugPrint(
        'SENDING EMAIL - VISITOR SIGN-OUT NOTIFICATION | '
        'Timestamp: ${DateTime.now().toIso8601String()} | '
        'Recipient ID: $supervisorId | '
        'Recipient Name: $supervisorName | '
        'Recipient Email: $supervisorEmail | '
        'Recipient Phone: $supervisorPhone | '
        'Subject: ${email['subject'] ?? "(No subject)"} | '
        'Logo URL: ${logoUrl ?? "(No logo)"} | '
        'Email Body: ${email['body'] ?? "(No body)"} | '
        'Body Length: ${(email['body'] ?? "").length} characters | '
        'Site: $siteName'
      );*/

          final emailSuccess = await NotificationService.sendEmail(
            userId: supervisorId,
            name: visitorRecord.fullName,
            email: supervisorEmail,
            phone: supervisorPhone,
            message: email['body'] ?? '',
            logoUrl: logoUrl,
          );
          debugPrint(
            '${emailSuccess ? "success" : "fail"} SMS Send Result: ${emailSuccess ? "SUCCESS" : "FAILED"}',
          );
        }

        if (!context.mounted) return;
        await _showSignOutSuccess(context, visitorId, signOutUtc);
      } else {
        // Sign-out failed or already signed out - show error message
        if (!context.mounted) return;

        // Use the data.success message if it's an "already signed out" case,
        // otherwise use the main message
        final String errorMessage = isAlreadySignedOut
            ? dataSuccess
            : (result['message'] ?? 'Unknown error');

        // Clear any existing snackbars first
        ScaffoldMessenger.of(context).clearSnackBars();

        // Show snackbar with error message only (no action buttons)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Sign-out failed: $errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Close loading if still open

      // Clear any existing snackbars first
      ScaffoldMessenger.of(context).clearSnackBars();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _showSignOutSuccess(
    BuildContext context,
    String visitorId,
    String signOutUtc,
  ) async {
    if (!mounted) return;

    // Remove visitor from local storage after successful sign-out
    await SecureStorageService.removeSignedVisitor(visitorId);

    // Update local visitor list
    setState(() {
      _visitorsById.remove(visitorId);
    });

    if (!context.mounted) return;

    // Clear any existing snackbars before showing new one
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Sign-out successful for ID: $visitorId at $signOutUtc UTC',
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );

    // Wait a moment to let user see the success message before navigating
    await Future.delayed(const Duration(milliseconds: 500));

    if (!context.mounted) return;

    // Clear snackbar before navigating to prevent it from showing on next page
    ScaffoldMessenger.of(context).clearSnackBars();
    Navigator.pushReplacementNamed(context, AppRoutes.visitorKiosk);
  }

  /// Open QR scanner to scan visitor badge
  Future<void> _openQRScanner() async {
    final scannedCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerWidget()),
    );

    if (scannedCode != null && scannedCode.isNotEmpty) {
      setState(() {
        _visitorIdCtrl.text = scannedCode;
        _scannedFromQR = true;
      });

      if (!mounted) return;

      // Clear any existing snackbars first
      ScaffoldMessenger.of(context).clearSnackBars();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Scanned Visitor ID: $scannedCode'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Show list of signed-in visitors for selection
  Future<void> _showSignedInVisitorsList() async {
    if (_visitorsById.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No signed-in visitors found on this device'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final visitors = _visitorsById.values.toList();

    final selectedVisitor = await showDialog<_SignedVisitor>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Visitor to Sign Out'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: visitors.length,
            itemBuilder: (context, index) {
              final visitor = visitors[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Text(
                      visitor.fullName.isNotEmpty
                          ? visitor.fullName[0].toUpperCase()
                          : 'V',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    visitor.fullName.isNotEmpty ? visitor.fullName : 'Unnamed',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ID: ${visitor.id}'),
                      if (visitor.email.isNotEmpty)
                        Text('Email: ${visitor.email}'),
                    ],
                  ),
                  onTap: () => Navigator.pop(context, visitor),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
        ],
      ),
    );

    if (selectedVisitor != null) {
      setState(() {
        _visitorIdCtrl.text = selectedVisitor.id;
        _scannedFromQR = false;
      });

      if (!mounted) return;

      // Clear any existing snackbars first
      ScaffoldMessenger.of(context).clearSnackBars();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✓ Selected: ${selectedVisitor.fullName} (${selectedVisitor.id})',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final DashboardController? c =
        DashboardController.instance ??
        (args is DashboardController ? args : null);
    final backgroundImage = _backgroundImageUrl ?? c?.backgroundImageUrl;
    final useCustomBackground =
        _useCustomBackground || (c?.useCustomBackground ?? false);

    // Show loading indicator while page initializes
    if (_isInitializing) {
      return Scaffold(
        body: Container(
          decoration: useCustomBackground && backgroundImage != null
              ? BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(backgroundImage),
                    fit: BoxFit.cover,
                    opacity: 0.9,
                  ),
                )
              : null,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                Text(
                  'Loading form...',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final siteTitle =
        c?.resolveSiteHeading('Visitor Sign Out') ?? 'Visitor Sign Out';
    final logoBytes = c?.clientLogoDisplayBytes;

    const double maxBodyWidth = AppBreakpoints.standard;

    final scaffold = Scaffold(
      body: Container(
        decoration: useCustomBackground && backgroundImage != null
            ? BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(backgroundImage),
                  fit: BoxFit.cover,
                  opacity: 0.9,
                ),
              )
            : null,
        child: Align(
          alignment: Alignment.center,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: maxBodyWidth),
              child: KioskBody(
                siteTitle: siteTitle,
                logo1Bytes: logoBytes,
                logo1Url: logoBytes == null
                    ? 'lib/assets/images/WorxSafety_Logo_NoShadow.svg'
                    : null,
                logo2Url: 'lib/assets/images/Worx_PoweredBy_Logo_Mono.svg',
                menuContent: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 5, 16, 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // QR Code Scanner Button
                        FilledButton.icon(
                          onPressed: _openQRScanner,
                          icon: const Icon(Icons.qr_code_scanner, size: 28),
                          label: const Text('Scan Visitor Badge'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.blue,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Show signed-in visitors list button
                        OutlinedButton.icon(
                          onPressed: _showSignedInVisitorsList,
                          icon: const Icon(Icons.list, size: 24),
                          label: const Text('Select from Signed-In Visitors'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(
                              color: Colors.blue,
                              width: 2,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Divider with "OR" text
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                'OR ENTER MANUALLY',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Visitor ID Field (auto-filled from QR scan)
                        KioskField(
                          controller: _visitorIdCtrl,
                          title: 'Visitor ID',
                          helpText: 'Scan QR code or enter manually',
                          validator: (v) {
                            final text = (v ?? '').trim();
                            if (text.isEmpty) return 'Visitor ID is required';
                            return null;
                          },
                        ),

                        // Show scanned status
                        if (_scannedFromQR) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.statusBackgroundColor('success'),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppTheme.successColor.withValues(
                                  alpha: 0.3,
                                ),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: AppTheme.successColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Badge scanned successfully',
                                    style: TextStyle(
                                      color: AppTheme.slate800,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Action buttons
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => Navigator.pop(this.context),
                              label: const Text('Back'),
                              icon: const Icon(Icons.arrow_back),
                            ),
                            const Spacer(),
                            FilledButton(
                              onPressed: () => _handleSignOut(context),
                              child: const Text('Submit'),
                            ),
                          ],
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
    );

    return KioskGuard(child: scaffold);
  }
}

class _SignedVisitor {
  final String id;
  final String email;
  final String fullName;
  final String supervisorId;
  final String supervisorName;
  final String supervisorEmail;
  final String supervisorPhone;
  final bool notifyViaSms;
  final bool notifyViaEmail;

  const _SignedVisitor({
    required this.id,
    required this.email,
    required this.fullName,
    this.supervisorId = '',
    this.supervisorName = '',
    this.supervisorEmail = '',
    this.supervisorPhone = '',
    this.notifyViaSms = false,
    this.notifyViaEmail = false,
  });
}
