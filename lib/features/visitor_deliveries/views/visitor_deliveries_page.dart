import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:worxvisitorapp/widgets/kiosk_field.dart';
import 'package:worxvisitorapp/core/constants/app_routes.dart';
import 'package:worxvisitorapp/widgets/kiosk_body.dart';
import 'package:worxvisitorapp/widgets/kiosk_guard.dart';
import 'package:worxvisitorapp/features/dashboard/controllers/dashboard_controller.dart';
import 'package:worxvisitorapp/core/models/contact_detail.dart';
import 'package:worxvisitorapp/services/notification_service.dart';
import 'package:worxvisitorapp/services/contact_loader.dart';
import 'package:worxvisitorapp/services/site_loader.dart';
import 'package:worxvisitorapp/services/secure_storage_service.dart';
import 'package:worxvisitorapp/services/helper/parse_name.dart';

class VisitorDeliveriesPage extends StatefulWidget {
  const VisitorDeliveriesPage({super.key});

  @override
  State<VisitorDeliveriesPage> createState() => _VisitorDeliveriesPage();
}

class _VisitorDeliveriesPage extends State<VisitorDeliveriesPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _orgCtrl;
  bool _submitting = false;
  bool _isInitializing = true; // Track page loading state
  _NotificationStatus? _lastNotificationStatus;

  // Client background branding
  String? _backgroundImageUrl;
  bool _useCustomBackground = false;

  @override
  void initState() {
    super.initState();
    _orgCtrl = TextEditingController();
    _loadBackgroundFromStorage();
    _initializePage();
  }

  /// Initialize page data - load contacts and sites
  Future<void> _initializePage() async {
    setState(() {
      _isInitializing = true;
    });

    // Load data in parallel for faster initialization
    await Future.wait([_refreshContacts(), _refreshSites()]);

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
    _orgCtrl.dispose();
    super.dispose();
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

    final theme = Theme.of(context);
    final siteTitle =
        c?.resolveSiteHeading('Deliveries') ?? 'Visitor Deliveries';
    final supervisor = c?.currentSite?.siteSupervisor;
    final logoBytes = c?.clientLogoDisplayBytes;

    const double maxBodyWidth = 620;

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
            padding: const EdgeInsets.fromLTRB(16, 50, 16, 50),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: maxBodyWidth),
              child: KioskBody(
                siteTitle: siteTitle,
                supervisorName: parserName(supervisor),
                supervisorTextColor: theme.colorScheme.primary,
                logo1Bytes: logoBytes,
                logo1Url: logoBytes == null
                    ? 'lib/assets/images/WorxSafety_Logo_NoShadow.svg'
                    : null,
                logo2Url: 'lib/assets/images/Worx_PoweredBy_Logo_Mono.svg',
                menuContent: _buildFormCard(c),
              ),
            ),
          ),
        ), // Close Container for Channel 7 background
      ),
    );

    return KioskGuard(child: scaffold);
  }

  Widget _buildFormCard(DashboardController? controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Delivery Details',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Let the site supervisor know when a delivery arrives.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              KioskField(
                controller: _orgCtrl,
                title: 'Delivery Company',
                required: true,
                helpText:
                    'This name appears in the text/email sent to the supervisor.',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Company name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              if (_lastNotificationStatus != null) ...[
                _NotificationBanner(status: _lastNotificationStatus!),
                const SizedBox(height: 12),
              ],
              _buildActionButtons(controller),
            ],
          ),
        ),
      ],
    );
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

  Widget _buildActionButtons(DashboardController? controller) {
    final backButton = OutlinedButton.icon(
      onPressed: () => Navigator.pop(context),
      icon: const Icon(Icons.arrow_back),
      label: const Text('Back'),
    );

    final submitButton = FilledButton.icon(
      onPressed: _submitting ? null : () => _submitDelivery(controller),
      icon: _submitting
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.check_circle),
      label: const Text('Notify Contact'),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isStacked = constraints.maxWidth < 440;
        if (isStacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [submitButton, const SizedBox(height: 12), backButton],
          );
        }
        return Row(
          children: [
            Expanded(flex: 3, child: backButton),
            const SizedBox(width: 16),
            Expanded(flex: 4, child: submitButton),
          ],
        );
      },
    );
  }

  Future<void> _submitDelivery(DashboardController? controller) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final company = _orgCtrl.text.trim();

      _NotificationStatus notificationStatus = const _NotificationStatus();

      if (controller != null) {
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

        // Get site supervisor ID directly from site data
        final siteName = controller.resolveSiteHeading('Visitor Site');
        final ContactDetail? siteSupervisor = await _getSiteContactDetailById(
          controller,
        );

        if (siteSupervisor == null) {
          //print('⚠️ No supervisor found for site: $siteName');
          notificationStatus = const _NotificationStatus();
        } else {
          debugPrint(
            'DELIVERY NOTIFICATION '
            'Site: $siteName '
            'Supervisor Name: ${siteSupervisor.name} '
            'Supervisor ID: ${siteSupervisor.id} '
            'Supervisor Email: ${siteSupervisor.email} '
            'Supervisor Phone: ${siteSupervisor.phone} '
            'Delivery Company: ${company.isEmpty ? "(Not specified)" : company} '
            'Timestamp: ${DateTime.now().toIso8601String()}',
          );
          bool smsSuccess = true;
          bool smsAttempted = false;

          // Send SMS if enabled and phone available
          if (controller.notifyDeliverySms &&
              siteSupervisor.phone.trim().isNotEmpty) {
            smsAttempted = true;
            final message = NotificationService.buildDeliveryArrivalMessage(
              siteName: siteName,
              companyName: company,
            );
            debugPrint(
              'SENDING SMS - DELIVERY NOTIFICATION | '
              'Timestamp: ${DateTime.now().toIso8601String()} | '
              'Recipient -> ID: ${siteSupervisor.id}, Name: ${siteSupervisor.name}, '
              'Phone: ${siteSupervisor.phone}, Email: ${siteSupervisor.email} | '
              'Message: "$message" | '
              'Message Length: ${message.length} chars | '
              'Site: $siteName | '
              'Company: ${company.isEmpty ? "(Not specified)" : company}',
            );
            smsSuccess = await NotificationService.sendTextMessage(
              userId: siteSupervisor.id,
              mobile: siteSupervisor.phone,
              message: message,
            );
          }

          bool emailSuccess = true;
          bool emailAttempted = false;

          // Send EMAIL if enabled and email available
          if (controller.notifyDeliveryEmail &&
              siteSupervisor.email.trim().isNotEmpty) {
            emailAttempted = true;
            final emailPayload = NotificationService.buildDeliveryArrivalEmail(
              siteName: siteName,
              companyName: company,
            );

            debugPrint(
              'EMAIL NOTIFICATION | '
              'Timestamp: ${DateTime.now().toIso8601String()} | '
              'Recipient ID: ${siteSupervisor.id} | '
              'Recipient Name: ${siteSupervisor.name} | '
              'Recipient Email: ${siteSupervisor.email} | '
              'Recipient Phone: ${siteSupervisor.phone} | '
              'Subject: ${emailPayload['subject'] ?? "(No subject)"} | '
              'Logo URL: ${logoUrl ?? "(No logo)"} | '
              'Body: "${emailPayload['body'] ?? "(No body)"}" | '
              'Body Length: ${(emailPayload['body'] ?? '').length} chars | '
              'Site: $siteName | '
              'Company: ${company.isEmpty ? "(Not specified)" : company}',
            );

            emailSuccess = await NotificationService.sendEmail(
              userId: siteSupervisor.id,
              name: company.isEmpty ? 'Unknown Company' : company,
              email: siteSupervisor.email,
              phone: siteSupervisor.phone,
              message: emailPayload['body'] ?? '',
              logoUrl: logoUrl,
            );
            debugPrint(
              '${emailSuccess ? "success" : "fail"} EMAIL Send Result: ${emailSuccess ? "SUCCESS" : "FAILED"}',
            );
          }

          notificationStatus = _NotificationStatus(
            smsAttempted: smsAttempted,
            smsSuccess: smsSuccess,
            emailAttempted: emailAttempted,
            emailSuccess: emailSuccess,
          );
        }
      }

      if (!mounted) return;
      setState(() => _lastNotificationStatus = notificationStatus);

      if (notificationStatus.smsAttempted ||
          notificationStatus.emailAttempted) {
        final summary = notificationStatus.buildSummary();
        final hasFailure =
            (notificationStatus.smsAttempted &&
                !notificationStatus.smsSuccess) ||
            (notificationStatus.emailAttempted &&
                !notificationStatus.emailSuccess);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(summary),
            backgroundColor: hasFailure ? Colors.orange : Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Delivery submitted.')));
      }
      Navigator.pushReplacementNamed(context, AppRoutes.visitorKiosk);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to submit delivery: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// Get site supervisor by ID from the current site data
  /// Returns the ContactDetail object if found, null otherwise
  Future<ContactDetail?> _getSiteContactDetailById(
    DashboardController controller,
  ) async {
    try {
      //LOOKING UP SITE SUPERVISOR
      // Get the current site
      final site = controller.currentSite;
      if (site == null) {
        debugPrint('No current site selected');
        return null;
      }

      debugPrint('CURRENT SITE | ID: ${site.id} | Title: ${site.title}');

      // Get sites data from secure storage to access supervisor ID
      final sitesJson = await SecureStorageService.getSites();
      if (sitesJson == null || sitesJson.isEmpty) {
        return null;
      }

      // Find the current site in the stored data
      // API response format: {"count": 37, "data": [{...}, {...}]}
      final sitesResponse = jsonDecode(sitesJson);
      List<dynamic> allSites;

      if (sitesResponse is Map<String, dynamic> &&
          sitesResponse.containsKey('data')) {
        allSites = sitesResponse['data'] as List<dynamic>;
      } else if (sitesResponse is List<dynamic>) {
        allSites = sitesResponse;
      } else {
        debugPrint(
          'Unexpected sites data format: ${sitesResponse.runtimeType}',
        );
        return null;
      }

      Map<String, dynamic>? currentSiteData;

      for (final siteData in allSites) {
        final siteMap = siteData as Map<String, dynamic>;
        if (siteMap['id']?.toString() == site.id) {
          currentSiteData = siteMap;
          debugPrint(
            'FOUND SITE DATA | JSON LENGTH: ${jsonEncode(siteMap).length}',
          );
          break;
        }
      }

      if (currentSiteData == null) {
        debugPrint('Site ID being searched: ${site.id}');
        return null;
      }

      // Get supervisor ID from site data
      // Try both 'site_supervisor' and 'supervisor' fields
      final supervisorData =
          currentSiteData['site_supervisor'] ?? currentSiteData['supervisor'];

      if (supervisorData == null) {
        debugPrint('Site has NO supervisor configured');
        return null;
      }

      String? supervisorId;
      if (supervisorData is Map<String, dynamic>) {
        supervisorId = supervisorData['id']?.toString();
      } else if (supervisorData is String) {
        supervisorId = supervisorData;
      }

      if (supervisorId == null || supervisorId.isEmpty) {
        debugPrint('Supervisor ID is null or empty');
        return null;
      }

      // Find the supervisor in available supervisors list by ID
      for (final supervisor in controller.availableSupervisors) {
        if (supervisor.id == supervisorId) {
          debugPrint(
            'SUPERVISOR FOUND | '
            'ID: ${supervisor.id} | '
            'Name: ${supervisor.name} | '
            'Email: ${supervisor.email} | '
            'Phone: ${supervisor.phone}',
          );
          return supervisor;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting site supervisor: $e');
      return null;
    }
  }
}

class _NotificationStatus {
  final bool smsAttempted;
  final bool smsSuccess;
  final bool emailAttempted;
  final bool emailSuccess;

  const _NotificationStatus({
    this.smsAttempted = false,
    this.smsSuccess = true,
    this.emailAttempted = false,
    this.emailSuccess = true,
  });

  String buildSummary() {
    final parts = <String>[];
    if (smsAttempted) {
      parts.add(smsSuccess ? 'Text message sent' : 'Text message failed');
    }
    if (emailAttempted) {
      parts.add(emailSuccess ? 'Email sent' : 'Email failed');
    }
    return parts.isEmpty ? 'Delivery submitted.' : parts.join(' — ');
  }
}

class _NotificationBanner extends StatelessWidget {
  const _NotificationBanner({required this.status});

  final _NotificationStatus status;

  @override
  Widget build(BuildContext context) {
    final success = !status.smsAttempted || status.smsSuccess;
    final color = success ? Colors.green : Colors.orange;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color),
      ),
      child: Text(
        status.buildSummary(),
        style: TextStyle(
          color: color.withValues(alpha: 0.9),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
