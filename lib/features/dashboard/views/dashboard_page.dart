import 'dart:convert';
import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/scheduler.dart';

// Models
import 'package:worxvisitorapp/core/models/site_item.dart';
import 'package:worxvisitorapp/core/models/contact_detail.dart';

// Controllers
import '../controllers/dashboard_controller.dart';

// Constants
import 'package:worxvisitorapp/core/responsive/app_breakpoints.dart';
import 'package:worxvisitorapp/core/theme/app_theme.dart';
import 'package:worxvisitorapp/core/constants/app_routes.dart';

// Services
import 'package:worxvisitorapp/services/api_service.dart';
import 'package:worxvisitorapp/services/secure_storage_service.dart';
import 'package:http/http.dart' as http;

// Widgets
import 'package:worxvisitorapp/widgets/dashboard_custom_widgets.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.controller});

  final DashboardController controller;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isInitializing = true;

  // Client Logo & Name
  Uint8List? _clientLogoBytes; // For UI display
  bool _isLoadingLogo = false;
  // ignore: unused_field
  String? _clientLogoUrl;
  String? _clientName;

  // Visitor contacts / supervisors
  bool _isLoadingContacts = false;
  String? _contactsError;

  // ====== Admin PIN ======
  final TextEditingController _adminPinCtrl = TextEditingController();
  bool _obscureAdminPin = true;
  bool _savingAdminPin = false;
  bool _loadingAdminPin = true;
  String? _adminPinError;
  String? _adminPinStatus;

  // ====== Scroll Controller for auto-scroll to preview ======
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _badgePreviewKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Initialize page data first, then printer initialization will start automatically
    _initializePage();
  }

  /// Initialize printer connection (called after page data is loaded)
  Future<void> _initializePrinter() async {
    // Check if printer initialization should start
    // Only start if not already initialized and hasn't attempted connection yet
    if (!widget.controller.initialized &&
        !widget.controller.hasAttemptedConnection) {
      dev.log('Starting printer initialization...');
      widget.controller.initializePrinter().catchError((error) {
        dev.log('Printer initialization error: $error');
      });
    } else {
      dev.log(
        'Printer initialization skipped - already initialized or attempted',
      );
    }
  }

  @override
  void dispose() {
    _adminPinCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Initialize page data - load all dashboard data in parallel
  Future<void> _initializePage() async {
    setState(() {
      _isInitializing = true;
    });

    // Load all dashboard data
    // Use eagerError: false to ensure all tasks complete even if one fails
    await Future.wait(
      [
        _loadClientData(),
        _loadVisitorContacts(),
        _loadAdminPin(),
      ],
      eagerError: false,
    );

    if (!mounted) return;

    // Check if we should auto-navigate to kiosk BEFORE showing dashboard
    final shouldNavigate = await SecureStorageService.getAutoNavigateToKiosk();

    if (shouldNavigate) {
      // Auto-navigating to kiosk - keep showing loading
      debugPrint('🚀 Auto-navigating to kiosk...');

      // Clear the flag so we don't auto-navigate next time
      await SecureStorageService.clearAutoNavigateToKiosk();

      // Start printer initialization in background
      _initializePrinter();

      // Small delay to ensure everything is loaded
      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;

      // Navigate to kiosk with controller (loading stays visible until navigation)
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.visitorKiosk,
        arguments: widget.controller,
      );
    } else {
      // NOT auto-navigating - show dashboard UI
      setState(() {
        _isInitializing = false;
      });

      // Start printer initialization AFTER page data is loaded
      // Delay longer (3 seconds) to allow user to navigate freely without blocking
      // This prevents UI freezing when user enters Sign In page during printer scan
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;
      _initializePrinter();
    }
  }

  /// Handle requirement field changes (with debouncing if needed)
  void _handleRequirementChange(void Function(bool) setter, bool value) {
    setter(value);
  }

  /// Handle notification setting changes
  void _handleNotificationChange(void Function(bool) setter, bool value) {
    setter(value);
  }

  /// Scroll to badge preview card after preview is generated
  void _scrollToBadgePreview() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final targetContext = _badgePreviewKey.currentContext;
      if (targetContext == null) return;

      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
    });
  }

  // ===========================
  // ====== DATA LOADERS =======
  // ===========================
  /// Load client data from secure storage, fetching and caching if missing
  /// Client['logo'] client['name'] client['trading_name']
  Future<void> _loadClientData() async {
    try {
      final clientJson = await _loadOrFetchClient();
      if (clientJson == null) return;

      final logoUrl = clientJson['logo'] as String?;
      final clientName =
          (clientJson['trading_name'] as String?) ??
          (clientJson['name'] as String?);
      final clientId = clientJson['id'] as int?;
      final backgroundImage = clientJson['background_image'] as String?;

      // Check for printer model info from API
      //final printerModels = clientJson['printer_models'] ?? clientJson['supported_printers'];
      //final printerModel = clientJson['printer_model'] ?? clientJson['default_printer'];
      //print(printerModels);
      //print(printerModel);

      // Validate and enable background image if format is valid (PNG/JPG)
      if (_isValidBackground(backgroundImage)) {
        widget.controller.backgroundImageUrl = backgroundImage;
        widget.controller.useCustomBackground = true;
        debugPrint('Background image enabled from cache: $backgroundImage');
      } else {
        widget.controller.useCustomBackground = false;
        debugPrint('Background image not available or invalid format');
      }

      if (!mounted) return;

      setState(() {
        _clientLogoUrl = logoUrl;
        _clientName = clientName;
      });

      // Store logo URL and client ID in controller immediately (for badge generation)
      if (logoUrl != null && logoUrl.isNotEmpty) {
        widget.controller.setClientLogo(logoUrl: logoUrl, id: clientId);
      } else if (clientId != null) {
        // Store client ID even if logo is not available
        widget.controller.setClientLogo(id: clientId);
      }

      // Download logo from URL
      if (logoUrl != null && logoUrl.isNotEmpty) {
        await _downloadClientLogo(logoUrl);
      }
    } catch (e) {
      debugPrint('dashboard fetches client error: $e');
      return;
    }
  }

  /// Try to load client from storage; if missing, fetch once and cache.
  Future<Map<String, dynamic>?> _loadOrFetchClient() async {
    final cached = await SecureStorageService.getClient();
    if (cached != null && cached.isNotEmpty) {
      try {
        return jsonDecode(cached) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('Error decoding cached client: $e');
      }
    }

    final savedToken = await SecureStorageService.getAuthToken();
    if (savedToken == null || savedToken.isEmpty) {
      return null;
    }

    final freshClient = await ApiService.fetchVisitorClient(savedToken);
    await SecureStorageService.saveClient(jsonEncode(freshClient));
    return freshClient;
  }

  bool _isValidBackground(String? backgroundImage) {
    if (backgroundImage == null) return false;
    final lower = backgroundImage.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg');
  }

  /// Download client logo from URL and store in controller
  Future<void> _downloadClientLogo(String url) async {
    if (!mounted) return;

    setState(() {
      _isLoadingLogo = true;
    });

    try {
      //print('📥 Dashboard - Downloading client logo: $url');

      // Use CORS proxy for web platform
      final fetchUrl = kIsWeb
          ? 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(url)}'
          : url;

      final response = await http.get(
        Uri.parse(fetchUrl),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      );

      if (response.statusCode == 200) {
        // Store logo bytes
        Uint8List logoBytes = response.bodyBytes;

        if (mounted) {
          final Uint8List displayBytes = logoBytes;
          setState(() {
            _clientLogoBytes = displayBytes;
            _isLoadingLogo = false;
          });

          // Store in controller for badge printing
          widget.controller.setClientLogo(
            displayBytes: displayBytes,
            badgeBytes: logoBytes,
            logoUrl: url,
          );
        }
      } else {
        if (mounted) {
          setState(() => _isLoadingLogo = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingLogo = false);
      }
    }
  }

  /// Load visitor contacts (supervisors)
  Future<void> _loadVisitorContacts({bool forceApiFetch = false}) async {
    if (_isLoadingContacts) return;

    setState(() {
      _isLoadingContacts = true;
      _contactsError = null;
    });

    try {
      // Try loading from cache first
      String? contactsData;
      if (!forceApiFetch) {
        contactsData = await SecureStorageService.getContacts();
      }

      // If no cache or force fetch, get from API
      if (contactsData == null || contactsData.isEmpty || forceApiFetch) {
        final savedToken = await SecureStorageService.getAuthToken();
        if (savedToken != null && savedToken.isNotEmpty) {
          final contactsJson = await ApiService.fetchVisitorContacts(
            savedToken,
          );
          final List<dynamic> contacts = contactsJson['data'];
          contactsData = jsonEncode(contacts);
          await SecureStorageService.saveContacts(contactsData);
          //print('visitor contacts ==================================');
          //print(contacts);
        }
      }

      // Parse contacts
      if (contactsData != null && contactsData.isNotEmpty) {
        final decoded = jsonDecode(contactsData);
        List<dynamic> contactsList;

        // Handle both List and Map responses
        if (decoded is List) {
          contactsList = decoded;
        } else if (decoded is Map && decoded.containsKey('data')) {
          // If it's a Map with 'data' key, extract the list
          contactsList = decoded['data'] as List<dynamic>;
        } else {
          throw Exception('Invalid contacts data format');
        }

        final supervisors = contactsList
            .map((json) => ContactDetail.fromMap(json as Map<String, dynamic>))
            .toList();

        // Update controller
        widget.controller.updateAvailableSupervisors(supervisors);
      }

      if (!mounted) return;
      setState(() {
        _isLoadingContacts = false;
      });
    } catch (e) {
      //print('dashboard fetches contacts error, which is caused by $e');
      if (!mounted) return;
      setState(() {
        _isLoadingContacts = false;
        _contactsError = e.toString();
      });
    }
  }

  //Admin Pin=================================
  Future<void> _loadAdminPin() async {
    final pin = await SecureStorageService.getAdminPin();
    if (!mounted) return;
    setState(() {
      _adminPinCtrl.text = pin;
      _loadingAdminPin = false;
    });
  }

  Future<void> _saveAdminPin() async {
    final pin = _adminPinCtrl.text.trim();
    if (pin.length < 4) {
      setState(() {
        _adminPinError = 'Password must be at least 4 characters.';
        _adminPinStatus = null;
      });
      return;
    }

    setState(() {
      _savingAdminPin = true;
      _adminPinError = null;
      _adminPinStatus = null;
    });

    try {
      await SecureStorageService.saveAdminPin(pin);
      if (!mounted) return;
      setState(() {
        _adminPinStatus = 'Password updated successfully.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kiosk admin password saved.'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _adminPinError = 'Failed to save password. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _savingAdminPin = false);
      }
    }
  }

  //Admin Pin=================================

  //pop out window============================
  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  //============================================
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final maxBodyWidth = AppBreakpoints.getContentWidth(width);

    if (_isInitializing) {
      return const _LoadingDashboardInterface();
    }

    return _LoadedDashboardInterface(
      controller: widget.controller,
      maxBodyWidth: maxBodyWidth,

      // client logo
      clientLogoBytes: _clientLogoBytes,
      isLoadingLogo: _isLoadingLogo,
      clientName: _clientName,

      // admin pin
      adminPinCtrl: _adminPinCtrl,
      obscureAdminPin: _obscureAdminPin,
      loadingAdminPin: _loadingAdminPin,
      savingAdminPin: _savingAdminPin,
      adminPinError: _adminPinError,
      adminPinStatus: _adminPinStatus,
      onToggleObscureAdminPin: () {
        setState(() => _obscureAdminPin = !_obscureAdminPin);
      },
      onSaveAdminPin: _saveAdminPin,

      // contacts / supervisors
      isLoadingContacts: _isLoadingContacts,
      contactsError: _contactsError,
      loadVisitorContacts: _loadVisitorContacts,

      // callbacks
      onRequirementChange: _handleRequirementChange,
      onNotificationChange: _handleNotificationChange,

      // scroll and preview
      scrollController: _scrollController,
      badgePreviewKey: _badgePreviewKey,
      onPreviewGenerated: _scrollToBadgePreview,

      // misc
      showToast: _toast,
    );
  }
}

// ===================================================
// =============== UI INTERFACES =====================
// ===================================================

//interface - loading icon
class _LoadingDashboardInterface extends StatelessWidget {
  const _LoadingDashboardInterface();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'Loading dashboard...',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadedDashboardInterface extends StatelessWidget {
  const _LoadedDashboardInterface({
    required this.controller,
    required this.maxBodyWidth,

    // client logo
    required this.clientLogoBytes,
    required this.isLoadingLogo,
    this.clientName,

    // admin pin
    required this.adminPinCtrl,
    required this.obscureAdminPin,
    required this.loadingAdminPin,
    required this.savingAdminPin,
    this.adminPinError,
    this.adminPinStatus,
    required this.onToggleObscureAdminPin,
    required this.onSaveAdminPin,

    // contacts / supervisors
    required this.isLoadingContacts,
    this.contactsError,
    required this.loadVisitorContacts,

    // callbacks
    required this.onRequirementChange,
    required this.onNotificationChange,

    // scroll and preview
    required this.scrollController,
    required this.badgePreviewKey,
    required this.onPreviewGenerated,

    // misc
    required this.showToast,
  });

  final DashboardController controller;
  final double maxBodyWidth;

  // client logo
  final Uint8List? clientLogoBytes;
  final bool isLoadingLogo;
  final String? clientName;

  // admin pin
  final TextEditingController adminPinCtrl;
  final bool obscureAdminPin;
  final bool loadingAdminPin;
  final bool savingAdminPin;
  final String? adminPinError;
  final String? adminPinStatus;
  final VoidCallback onToggleObscureAdminPin;
  final Future<void> Function() onSaveAdminPin;

  // contacts / supervisors
  final bool isLoadingContacts;
  final String? contactsError;
  final Future<void> Function({bool forceApiFetch}) loadVisitorContacts;

  // callbacks
  final void Function(void Function(bool) setter, bool value)
  onRequirementChange;
  final void Function(void Function(bool) setter, bool value)
  onNotificationChange;

  // scroll and preview
  final ScrollController scrollController;
  final GlobalKey badgePreviewKey;
  final VoidCallback onPreviewGenerated;

  // misc
  final void Function(String msg) showToast;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration:
            controller.useCustomBackground &&
                controller.backgroundImageUrl != null
            ? BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(controller.backgroundImageUrl!),
                  fit: BoxFit.cover,
                  opacity: 0.9,
                ),
              )
            : null,
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            return Center(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxBodyWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SiteInformationCard(
                        controller: controller,
                        clientLogoBytes: clientLogoBytes,
                        isLoadingLogo: isLoadingLogo,
                        clientName: clientName,
                      ),
                      const SizedBox(height: 16),
                      // admin pin
                      _KioskAdminPasswordCard(
                        adminPinCtrl: adminPinCtrl,
                        obscureAdminPin: obscureAdminPin,
                        loadingAdminPin: loadingAdminPin,
                        savingAdminPin: savingAdminPin,
                        adminPinError: adminPinError,
                        adminPinStatus: adminPinStatus,
                        onToggleObscureAdminPin: onToggleObscureAdminPin,
                        onSaveAdminPin: onSaveAdminPin,
                      ),
                      const SizedBox(height: 16),

                      // Printer Status Card
                      PrintStatusCard(controller: controller),
                      const SizedBox(height: 16),

                      // Visitor Required Fields Card
                      VisitorRequirementFieldsCard(
                        controller: controller,
                        isLoadingContacts: isLoadingContacts,
                        contactsError: contactsError,
                        loadVisitorContacts: loadVisitorContacts,
                        onRequirementChange: onRequirementChange,
                        onPreviewGenerated: onPreviewGenerated,
                      ),
                      const SizedBox(height: 16),

                      // Badge Preview Card
                      BadgePreviewCard(
                        key: badgePreviewKey,
                        controller: controller,
                        onNotificationChange: onNotificationChange,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ), // Close Container for Channel 7 background
    );
  }
}

class _KioskAdminPasswordCard extends StatelessWidget {
  const _KioskAdminPasswordCard({
    required this.adminPinCtrl,
    required this.obscureAdminPin,
    required this.loadingAdminPin,
    required this.savingAdminPin,
    this.adminPinError,
    this.adminPinStatus,
    required this.onToggleObscureAdminPin,
    required this.onSaveAdminPin,
  });

  final TextEditingController adminPinCtrl;
  final bool obscureAdminPin;
  final bool loadingAdminPin;
  final bool savingAdminPin;
  final String? adminPinError;
  final String? adminPinStatus;
  final VoidCallback onToggleObscureAdminPin;
  final Future<void> Function() onSaveAdminPin;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Kiosk Admin Password', style: tt.titleMedium),
            const SizedBox(height: 4),
            Text(
              'This password is required when tapping "Admin Sign In" on the kiosk. '
              'Share it only with trusted staff.',
              style: tt.bodySmall?.copyWith(color: AppTheme.slate600),
            ),
            const SizedBox(height: 16),
            if (loadingAdminPin)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              TextField(
                controller: adminPinCtrl,
                obscureText: obscureAdminPin,
                decoration: InputDecoration(
                  labelText: 'Admin password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureAdminPin ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: onToggleObscureAdminPin,
                  ),
                  errorText: adminPinError,
                  helperText: 'Minimum 4 characters. Numbers only recommended.',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: savingAdminPin ? null : onSaveAdminPin,
                icon: savingAdminPin
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: const Text('Save Password'),
              ),
              if (adminPinStatus != null) ...[
                const SizedBox(height: 8),
                Text(
                  adminPinStatus!,
                  style: TextStyle(
                    color: AppTheme.successColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _SiteInformationCard extends StatelessWidget {
  const _SiteInformationCard({
    required this.controller,
    required this.clientLogoBytes,
    required this.isLoadingLogo,
    this.clientName,
  });

  final DashboardController controller;
  final Uint8List? clientLogoBytes;
  final bool isLoadingLogo;
  final String? clientName;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Welcome, $clientName team',
              textAlign: TextAlign.center,
              style: tt.titleLarge,
            ),
            const SizedBox(height: 12),
            // Client logo
            Center(
              child: isLoadingLogo
                  ? const SizedBox(
                      height: 60,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : clientLogoBytes != null
                  ? _buildLogoWidget(clientLogoBytes!, 60)
                  : Image.asset(
                      'lib/assets/images/WorxSafety_Logo_NoShadow.png',
                      height: 60,
                      fit: BoxFit.contain,
                    ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Text('Current Site', style: tt.titleMedium)),
                FilledButton.icon(
                  onPressed: () async {
                    // Navigate to new-site page and await result
                    final result = await Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.newSite,
                    );
                    // Update selected site if user selected one
                    if (result != null && result is SiteItem) {
                      controller.selectSite(result);
                    }
                  },
                  icon: const Icon(Icons.sync),
                  label: const Text('Change Site'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Site name display
            _SiteInfoRow(
              label: 'Site Name',
              value: controller.resolveSiteHeading('-'),
            ),
            const SizedBox(height: 12),
            _SiteInfoRow(
              label: 'Address',
              value: controller.currentSite?.address ?? '-',
            ),
          ],
        ),
      ),
    );
  }

  //_build Logo Widget
  Widget _buildLogoWidget(Uint8List bytes, double height) {
    final String bytesAsString = String.fromCharCodes(bytes.take(100));
    final isSvg =
        bytesAsString.contains('<svg') || bytesAsString.contains('<?xml');

    if (isSvg) {
      return SvgPicture.memory(bytes, height: height, fit: BoxFit.contain);
    } else {
      return Image.memory(bytes, height: height, fit: BoxFit.contain);
    }
  }
}

/// Helper widget for displaying site information rows
class _SiteInfoRow extends StatelessWidget {
  const _SiteInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value, style: tt.bodyMedium)),
        ],
      ),
    );
  }
}
