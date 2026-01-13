import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'package:worxvisitorapp/core/models/site_item.dart';
import 'package:worxvisitorapp/core/models/contact_detail.dart';
import 'package:worxvisitorapp/core/models/paper_type.dart';
import 'package:worxvisitorapp/services/secure_storage_service.dart';
import 'package:worxvisitorapp/services/printer_service.dart';
import 'package:worxvisitorapp/services/badge_generator.dart';
import 'package:worxvisitorapp/services/timezone_service.dart';
import 'package:worxvisitorapp/services/device_permission.dart';

/// Dashboard Controller
/// Manages dashboard state including site selection, printer status, and visitor settings
class DashboardController extends ChangeNotifier {
  // ========== SINGLETON INSTANCE ==========
  // Global reference for simple access outside dashboard flow
  static DashboardController? instance;

  // ========== SITE MANAGEMENT ==========
  List<SiteItem> sites;
  SiteItem? currentSite;

  // ========== PRINTER STATUS ==========
  // Note: Printer initialization only happens in dashboard page as per requirements
  bool initialized = false;
  bool hasAttemptedConnection =
      false; // Track if first connection attempt completed
  bool hasManuallyRetried =
      false; // Track if user manually clicked retry button
  String printerName = 'Not connected';
  String printerIp = '-';
  String printerModel = ''; // Printer model (QL-820NWB, QL-720NW, etc.)
  bool printVisitorBadge = true; // Enable/disable automatic badge printing
  bool hasTestPrinted = false; // Track if test print has been done (reset on paper type change)

  // Paper type selection
  PaperType selectedPaperType = PaperType.defaultType;
  List<PaperType> availablePaperTypes = []; // Paper types for current printer model

  // Printer service for Network discovery
  final PrinterService printerService = PrinterService();

  // BuildContext for permission dialogs (set from dashboard page)
  late final Future<dynamic> Function() _getContext;

  // ========== VISITOR REQUIRED FIELDS (Checkboxes) ==========
  bool reqFullName = true;
  bool reqPhone = false;
  bool reqEmail = true; // Always required, cannot be disabled
  bool reqWorkType = false;
  bool reqCompany = false;
  bool reqAddress = false;
  bool reqSupervisor = false;
  bool reqSignInTime = false;
  bool reqVisitorPhoto = false; // Require visitor photo during sign-in

  // ========== NOTIFICATION SETTINGS ==========
  bool notifyVisitorSms = false;
  bool notifyVisitorEmail =
      true; // Enable email by default for visitor notifications
  bool notifyDeliverySms = false;
  bool notifyDeliveryEmail =
      true; // Enable email by default for delivery notifications

  // ========== BADGE PREVIEW ==========
  bool showPreview = false;
  Uint8List? previewImageBytes; // Actual badge image for preview and printing
  Uint8List? clientLogoBytes; // Downloaded client logo for badge printing
  Uint8List? clientLogoDisplayBytes; // Raw/converted logo for UI display
  String?
  clientLogoUrl; // Client logo URL for direct download in badge generator

  // ========== CLIENT INFORMATION ==========
  int? clientId; // Client ID for reference and tracking
  String? backgroundImageUrl; // Dynamic background image URL from API
  bool useCustomBackground =
      false; // Global flag to enable custom background image

  DashboardController({
    required this.sites,
    SiteItem? initialSite,
    Future<dynamic> Function()? getContext,
  }) {
    DashboardController.instance = this;
    currentSite = initialSite ?? (sites.isNotEmpty ? sites.first : null);
    _getContext = getContext ?? (() => Future.value(null));

    // Load last selected site from storage
    _loadSelectedSite();
    // Load notification preferences from storage
    _loadNotificationPreferences();
    // Load visitor field requirements from storage
    _loadVisitorRequirements();
    // Load print settings from storage
    _loadPrintSettings();
  }

  // ========== SITE SELECTION ==========

  /// Load previously selected site from secure storage
  Future<void> _loadSelectedSite() async {
    final siteJson = await SecureStorageService.getSelectedSite();
    if (siteJson != null && siteJson.isNotEmpty) {
      try {
        final siteData = jsonDecode(siteJson) as Map<String, dynamic>;
        final selectedSite = SiteItem.fromJson(siteData);

        // Find matching site in available sites list
        final match = sites.where((s) => s.id == selectedSite.id).firstOrNull;
        if (match != null) {
          currentSite = match;
          notifyListeners();
        }
      } catch (e) {
        debugPrint('Error loading selected site: $e');
      }
    }
  }

  /// Select a new site
  void selectSite(SiteItem? site) {
    currentSite = site;
    notifyListeners();

    // Save selection to storage
    if (site != null) {
      SecureStorageService.saveSelectedSite(jsonEncode(site.toJson()));
      debugPrint('✅ Site selected: ${site.displayName}');
    }
  }

  /// Get site display name with ID prefix
  String resolveSiteHeading([String fallback = 'Visitor Site']) {
    final site = currentSite;
    if (site == null) return fallback;

    final id = site.id.trim();
    final title = site.title.trim();
    final baseTitle = title.isNotEmpty ? title : fallback;

    if (id.isEmpty) {
      return baseTitle.isNotEmpty ? baseTitle : fallback;
    }

    final hasIdPrefix = baseTitle.toLowerCase().startsWith(id.toLowerCase());
    return hasIdPrefix ? baseTitle : '$id - $baseTitle';
  }

  // ========== VISITOR FIELD REQUIREMENTS (Setters) ==========

  void setReqFullName(bool v) {
    // Name is always required, ignore attempts to disable it
    reqFullName = true;
    notifyListeners();
  }

  void setReqPhone(bool v) {
    reqPhone = v;
    _saveVisitorRequirements();
    notifyListeners();
  }

  void setReqEmail(bool v) {
    // Email is always required, ignore attempts to disable it
    reqEmail = true;
    _saveVisitorRequirements();
    notifyListeners();
  }

  void setReqWorkType(bool v) {
    reqWorkType = v;
    _saveVisitorRequirements();
    notifyListeners();
  }

  void setReqCompany(bool v) {
    reqCompany = v;
    _saveVisitorRequirements();
    notifyListeners();
  }

  void setReqAddress(bool v) {
    reqAddress = v;
    _saveVisitorRequirements();
    notifyListeners();
  }

  void setReqSupervisor(bool v) {
    reqSupervisor = v;
    _saveVisitorRequirements();
    notifyListeners();
  }

  void setReqSignInTime(bool v) {
    reqSignInTime = v;
    _saveVisitorRequirements();
    notifyListeners();
  }

  void setReqVisitorPhoto(bool v) {
    reqVisitorPhoto = v;
    _saveVisitorRequirements();
    notifyListeners();
  }

  // ========== NOTIFICATION SETTINGS (Setters) ==========

  void setNotifyVisitorSms(bool v) {
    notifyVisitorSms = v;
    _saveNotificationPreferences();
    notifyListeners();
  }

  void setNotifyVisitorEmail(bool v) {
    notifyVisitorEmail = v;
    _saveNotificationPreferences();
    notifyListeners();
  }

  void setNotifyDeliverySms(bool v) {
    notifyDeliverySms = v;
    _saveNotificationPreferences();
    notifyListeners();
  }

  void setNotifyDeliveryEmail(bool v) {
    notifyDeliveryEmail = v;
    _saveNotificationPreferences();
    notifyListeners();
  }

  /// Load notification preferences from secure storage
  Future<void> _loadNotificationPreferences() async {
    try {
      final prefs = await SecureStorageService.getNotificationPreferences();
      if (prefs != null && prefs.isNotEmpty) {
        final data = jsonDecode(prefs) as Map<String, dynamic>;
        notifyVisitorSms = data['notify_visitor_sms'] as bool? ?? false;
        notifyVisitorEmail = data['notify_visitor_email'] as bool? ?? true;
        notifyDeliverySms = data['notify_delivery_sms'] as bool? ?? false;
        notifyDeliveryEmail = data['notify_delivery_email'] as bool? ?? true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading notification preferences: $e');
    }
  }

  /// Save notification preferences to secure storage
  Future<void> _saveNotificationPreferences() async {
    try {
      final prefs = {
        'notify_visitor_sms': notifyVisitorSms,
        'notify_visitor_email': notifyVisitorEmail,
        'notify_delivery_sms': notifyDeliverySms,
        'notify_delivery_email': notifyDeliveryEmail,
      };
      await SecureStorageService.saveNotificationPreferences(jsonEncode(prefs));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error saving notification preferences: $e');
      }
    }
  }

  // ========== SUPERVISOR DATA ==========
  // Available supervisors for visitor sign-in page (populated from API)
  List<ContactDetail> availableSupervisors = [];

  void updateAvailableSupervisors(List<ContactDetail> supervisors) {
    availableSupervisors = supervisors;
    notifyListeners();
  }

  // ========== PRINTER MANAGEMENT ==========

  /// Initialize printer (called from dashboard page)
  /// Requests permissions and discovers network printers
  Future<void> initializePrinter() async {
    // Detect platform and initialize accordingly
    if (kIsWeb) {
      // Web: Use system printer
      await Future.delayed(const Duration(milliseconds: 300));
      initialized = true;
      printerName = 'System Printer (Web)';
      printerIp = 'Browser';
      hasAttemptedConnection = true;
      notifyListeners();
    } else {
      // Mobile: Auto-discover network printers
      try {
        // Get context for permission dialogs
        final context = await _getContext();
        if (context == null) {
          printerName = 'Initialization failed';
          printerIp = 'Context not available';
          hasAttemptedConnection = true;
          notifyListeners();
          return;
        }

        // Request permissions (with dialogs to guide user)
        final hasPermission = await DevicePermission.requestPrinterPermissions(
          context,
        );

        if (!hasPermission) {
          printerName = 'Permission denied';
          printerIp = 'Grant permissions to discover printers';
          hasAttemptedConnection = true;
          notifyListeners();
          return;
        }

        // Check if there's a saved printer to try reconnecting to
        final savedPrinter = await SecureStorageService.getLastPrinter();

        if (savedPrinter != null) {
          // STEP 1: Try to reconnect to saved printer (fast)
          printerName = 'Reconnecting to printer...';
          printerIp = 'Checking saved printer';
          notifyListeners();

          final reconnected = await printerService.tryConnectToSavedPrinter();

          if (reconnected) {
            // Successfully reconnected to saved printer
            final printer = printerService.selectedPrinter;
            if (printer != null) {
              initialized = true;
              printerName = printer.name;
              printerIp = printer.address;
              printerModel = printer.model;

              // Update available paper types based on printer model
              _updateAvailablePaperTypes(printer.model);

              hasAttemptedConnection = true;
              notifyListeners();
              return;
            }
          }
          await SecureStorageService.clearLastPrinter();
          // Fall through to network scan
        }
        printerName = 'Scanning network...';
        printerIp = 'Please wait';
        hasAttemptedConnection = false;
        notifyListeners();

        // Run printer discovery in the background without blocking UI
        // Use unawaited Future to prevent blocking
        printerService
            .discoverPrinters()
            .then((void _) {
              // Auto-select first available printer (with model verification)
              final printers = printerService.discoveredPrinters;
              if (printers.isNotEmpty) {
                final firstPrinter = printers.first;
                printerService.selectPrinter(firstPrinter);

                initialized = true;
                printerName = firstPrinter.name;
                printerIp = firstPrinter.address;
                printerModel = firstPrinter.model;

                // Update available paper types based on printer model
                _updateAvailablePaperTypes(firstPrinter.model);
              } else {
                initialized = false;
                printerName = 'No printers found';
                printerIp = 'Tap "Try Again" to rescan';
              }

              // Mark attempt as completed (success or failure)
              hasAttemptedConnection = true;
              notifyListeners();
            })
            .catchError((error) {
              initialized = false;
              printerName = 'Discovery failed';
              printerIp = 'Error: ';
              hasAttemptedConnection = true;
              notifyListeners();
            });

        // Don't wait for discovery to complete - let it run in background
        // This prevents blocking the UI thread
      } catch (e) {
        debugPrint('Printer initialization error: $e');
        initialized = false;
        printerName = 'Connection failed';
        printerIp = 'Error: ${e.toString()}';
        hasAttemptedConnection = true;
        notifyListeners();
      }
    }
  }

  /// Retry printer connection
  /// This is called when user clicks "Try Again" button
  /// Always performs network scan (does NOT try saved printer)
  Future<void> retryPrinterConnection() async {
    // Mark that user manually retried (to show detailed error if it fails again)
    hasManuallyRetried = true;

    // Reset state to show loading
    hasAttemptedConnection = false;
    initialized = false;
    printerName = 'Scanning network...';
    printerIp = 'Please wait';
    notifyListeners();

    // Add a small delay to ensure UI updates
    await Future.delayed(const Duration(milliseconds: 100));

    // Force network scan by clearing saved printer first
    // This ensures we don't try reconnecting, but do a fresh scan
    await SecureStorageService.clearLastPrinter();

    // Retry connection (will scan network since no saved printer)
    await initializePrinter();
  }

  /// Enable/disable automatic visitor badge printing
  void setPrintVisitorBadge(bool v) {
    printVisitorBadge = v;
    _savePrintSettings();
    notifyListeners();
  }

  /// Mark test print as done
  void markTestPrinted() {
    hasTestPrinted = true;
    notifyListeners();
  }

  /// Reset test print flag (called when paper type changes)
  void resetTestPrintFlag() {
    hasTestPrinted = false;
    notifyListeners();
  }

  /// Update printer connection status after manual addition
  void updatePrinterConnection(String name, String ip, bool isConnected) {
    initialized = isConnected;
    printerName = name;
    printerIp = ip;
    hasAttemptedConnection = true;
    notifyListeners();
  }

  /// Update available paper types based on printer model
  void _updateAvailablePaperTypes(String model) {
    debugPrint('📄 Updating paper types for model: $model');

    // Get paper types for this model
    availablePaperTypes = PaperType.getPaperTypesForModel(model);

    debugPrint('📄 Available paper types: ${availablePaperTypes.length}');
    for (var paper in availablePaperTypes) {
      debugPrint('   - ${paper.fullDisplayName}');
    }

    // Load saved paper type or use default
    _loadSavedPaperType();
  }

  /// Select a paper type
  void selectPaperType(PaperType paperType) {
    debugPrint('📄 Selecting paper type: ${paperType.fullDisplayName}');
    selectedPaperType = paperType;
    hasTestPrinted = false; // Reset test print flag when paper changes
    notifyListeners();

    // Save to storage
    _savePaperType(paperType);
  }

  /// Save selected paper type to storage
  Future<void> _savePaperType(PaperType paperType) async {
    try {
      await SecureStorageService.savePaperType(paperType.toJson());
      debugPrint('✅ Paper type saved: ${paperType.code}');
    } catch (e) {
      debugPrint('❌ Failed to save paper type: $e');
    }
  }

  /// Load saved paper type from storage
  Future<void> _loadSavedPaperType() async {
    try {
      final paperMap = await SecureStorageService.getPaperType();
      if (paperMap != null) {
        final paper = PaperType.fromJson(paperMap);

        // Check if saved paper is compatible with current printer
        if (availablePaperTypes.any((p) => p.code == paper.code)) {
          selectedPaperType = paper;
          debugPrint('✅ Loaded saved paper type: ${paper.code}');
        } else {
          debugPrint('⚠️ Saved paper type ${paper.code} not compatible with current printer');
          selectedPaperType = availablePaperTypes.isNotEmpty
              ? availablePaperTypes.first
              : PaperType.defaultType;
        }
      } else {
        // Use first available paper type or default
        selectedPaperType = availablePaperTypes.isNotEmpty
            ? availablePaperTypes.first
            : PaperType.defaultType;
        debugPrint('ℹ️ No saved paper type, using: ${selectedPaperType.code}');
      }
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Failed to load paper type: $e');
      selectedPaperType = availablePaperTypes.isNotEmpty
          ? availablePaperTypes.first
          : PaperType.defaultType;
    }
  }

  // ========== CLIENT LOGO MANAGEMENT ==========

  /// Set client logo bytes and URL (called from dashboard page after download)
  void setClientLogo({
    Uint8List? displayBytes,
    Uint8List? badgeBytes,
    String? logoUrl,
    int? id,
  }) {
    clientLogoDisplayBytes = displayBytes;
    clientLogoBytes =
        badgeBytes; // Only use badge bytes if conversion succeeded (null if failed)
    clientLogoUrl = logoUrl;
    clientId = id; // Store client ID

    notifyListeners();
  }

  // ========== BADGE PREVIEW GENERATION ==========

  /// Generate preview badge with sample data
  Future<void> generatePreview() async {
    // Generate sample badge with demo data
    const uuid = Uuid();
    final sampleVisitorId = uuid
        .v4()
        .substring(0, 8)
        .toUpperCase(); // Short ID for demo

    final timezoneSnapshot = reqSignInTime
        ? TimezoneService.captureNow()
        : null;
    final badgeData = BadgeData(
      visitorId: sampleVisitorId,
      fullName: reqFullName ? 'Firstname Lastname' : null,
      email: reqEmail ? 'visitor@example.com' : null,
      phone: reqPhone ? '+61 412 345 678' : null,
      workType: reqWorkType ? 'Contractor' : null,
      company: reqCompany ? 'ABC Construction' : null,
      address: reqAddress ? '123 Main St, Sydney' : null,
      supervisor: reqSupervisor ? 'Barry Wang' : null,
      signInTime: timezoneSnapshot == null
          ? null
          : TimezoneService.formatLocal(timezoneSnapshot.localTime),
      siteName: resolveSiteHeading('Visitor Badge'),
      clientLogoBytes: clientLogoBytes, // Use client logo bytes if available
      clientLogoUrl: clientLogoUrl, // Pass URL for direct download
      visitorPhotoBytes: reqVisitorPhoto ? Uint8List(1) : null, // Dummy photo data for preview
    );

    // Generate the actual image (same one that will be printed)
    previewImageBytes = await BadgeGenerator.generateBadgeBytes(badgeData);
    showPreview = true;
    notifyListeners();
  }

  // ========== VISITOR REQUIREMENTS PERSISTENCE ==========

  /// Load visitor field requirements from secure storage
  Future<void> _loadVisitorRequirements() async {
    try {
      final requirementsJson = await SecureStorageService.getVisitorRequirements();
      if (requirementsJson != null && requirementsJson.isNotEmpty) {
        final data = jsonDecode(requirementsJson) as Map<String, dynamic>;
        reqPhone = data['req_phone'] as bool? ?? false;
        reqWorkType = data['req_work_type'] as bool? ?? false;
        reqCompany = data['req_company'] as bool? ?? false;
        reqAddress = data['req_address'] as bool? ?? false;
        reqSupervisor = data['req_supervisor'] as bool? ?? false;
        reqSignInTime = data['req_sign_in_time'] as bool? ?? false;
        reqVisitorPhoto = data['req_visitor_photo'] as bool? ?? false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading visitor requirements: $e');
    }
  }

  /// Save visitor field requirements to secure storage
  Future<void> _saveVisitorRequirements() async {
    try {
      final requirements = {
        'req_phone': reqPhone,
        'req_work_type': reqWorkType,
        'req_company': reqCompany,
        'req_address': reqAddress,
        'req_supervisor': reqSupervisor,
        'req_sign_in_time': reqSignInTime,
        'req_visitor_photo': reqVisitorPhoto,
      };
      await SecureStorageService.saveVisitorRequirements(jsonEncode(requirements));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error saving visitor requirements: $e');
      }
    }
  }

  // ========== PRINT SETTINGS PERSISTENCE ==========

  /// Load print settings from secure storage
  Future<void> _loadPrintSettings() async {
    try {
      final settingsJson = await SecureStorageService.getPrintSettings();
      if (settingsJson != null && settingsJson.isNotEmpty) {
        final data = jsonDecode(settingsJson) as Map<String, dynamic>;
        printVisitorBadge = data['print_visitor_badge'] as bool? ?? true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading print settings: $e');
    }
  }

  /// Save print settings to secure storage
  Future<void> _savePrintSettings() async {
    try {
      final settings = {
        'print_visitor_badge': printVisitorBadge,
      };
      await SecureStorageService.savePrintSettings(jsonEncode(settings));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error saving print settings: $e');
      }
    }
  }

  // ========== CLEANUP ==========
  @override
  void dispose() {
    printerService.dispose();
    super.dispose();
  }
}
