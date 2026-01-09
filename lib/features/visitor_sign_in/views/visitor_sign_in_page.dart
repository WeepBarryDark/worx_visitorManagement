import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:worxvisitorapp/widgets/kiosk_field.dart';
import 'package:worxvisitorapp/core/constants/app_routes.dart';
import 'package:worxvisitorapp/core/responsive/app_breakpoints.dart';
import 'package:worxvisitorapp/core/theme/app_theme.dart';
import 'package:worxvisitorapp/widgets/kiosk_body.dart';
import 'package:worxvisitorapp/widgets/kiosk_guard.dart';
import 'package:worxvisitorapp/features/dashboard/controllers/dashboard_controller.dart';
import 'package:worxvisitorapp/core/models/contact_detail.dart';
import 'package:worxvisitorapp/services/api_service.dart';
import 'package:worxvisitorapp/services/badge_generator.dart';
import 'package:worxvisitorapp/services/secure_storage_service.dart';
import 'package:worxvisitorapp/features/visitor_sign_in/models/site_question.dart';
import 'package:worxvisitorapp/features/visitor_sign_in/views/site_questions_page.dart';
import 'package:worxvisitorapp/services/timezone_service.dart';
import 'package:worxvisitorapp/services/notification_service.dart';
import 'package:worxvisitorapp/services/contact_loader.dart';
import 'package:worxvisitorapp/services/site_loader.dart';
import 'package:worxvisitorapp/core/models/print_status.dart';
import 'package:worxvisitorapp/widgets/print_progress_widget.dart';
import 'package:image_picker/image_picker.dart';

class VisitorSignInPage extends StatefulWidget {
  const VisitorSignInPage({super.key});

  @override
  State<VisitorSignInPage> createState() => _VisitorSignInPageState();
}

class _VisitorSignInPageState extends State<VisitorSignInPage> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _workTypeCtrl = TextEditingController();
  final TextEditingController _signInTimeCtrl = TextEditingController();

  ContactDetail? _selectedContactDetail;
  bool _submitting = false;
  bool _isInitializing = true; // Track page loading state
  late String _signInTimeDisplay;
  late String _signInUtcIso;
  late TimezoneSnapshot _signInTimezone;
  Timer? _signInClockTimer;

  // Client background branding
  String? _backgroundImageUrl;
  bool _useCustomBackground = false;

  // Site questions and answers
  List<SiteQuestion> _siteQuestions = []; // Questions shown to user
  Map<String, String> _questionAnswers = {}; // Answers from user
  int? _signFormId; // Form ID if custom questions

  // Email validation
  String? _emailMatchWarning; // Warning if email matches a contact

  // Visitor photo
  Uint8List? _visitorPhotoBytes; // Captured visitor photo
  final ImagePicker _imagePicker = ImagePicker();
  bool _isTakingPhoto = false; // Prevent multiple concurrent camera requests

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _companyCtrl.dispose();
    _addressCtrl.dispose();
    _workTypeCtrl.dispose();
    _signInClockTimer?.cancel();
    _signInTimeCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _applySignInTimestamp(TimezoneService.captureNow());
    _startSignInClock();
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

  /// Take visitor photo
  Future<void> _takePhoto() async {
    // Prevent multiple concurrent camera requests
    if (_isTakingPhoto) {
      debugPrint('Camera already in use, ignoring request');
      return;
    }

    setState(() {
      _isTakingPhoto = true;
    });

    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (photo != null) {
        final bytes = await photo.readAsBytes();
        if (mounted) {
          setState(() {
            _visitorPhotoBytes = bytes;
          });
        }
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture photo: $e'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    } finally {
      // Always reset the flag
      if (mounted) {
        setState(() {
          _isTakingPhoto = false;
        });
      }
    }
  }

  /// Remove visitor photo
  void _removePhoto() {
    setState(() {
      _visitorPhotoBytes = null;
    });
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    // Get dashboard controller with settings
    final args = ModalRoute.of(context)?.settings.arguments;
    final DashboardController? c =
        DashboardController.instance ??
        (args is DashboardController ? args : null);

    if (c == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Error: Configuration not found. Please restart from dashboard.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ⚠️ IMPORTANT: Check email against contacts before proceeding
    _checkEmailAgainstContacts(c);
    if (_emailMatchWarning != null) {
      // Email matches a contact - show error and prevent sign-in
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_emailMatchWarning!),
          backgroundColor: AppTheme.dangerColor,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
      return;
    }

    // Check if visitor photo is required but not taken
    if (c.reqVisitorPhoto && _visitorPhotoBytes == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Visitor photo is required. Please take a photo before continuing.',
          ),
          backgroundColor: AppTheme.warningColor,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Take Photo',
            textColor: Colors.white,
            onPressed: _takePhoto,
          ),
        ),
      );
      return;
    }

    // Check printer status if printing is enabled
    if (c.printVisitorBadge && !c.initialized) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Error: Cannot submit. Printer is not connected. Please contact administrator.',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() {
      _submitting = true;
      _applySignInTimestamp(TimezoneService.captureNow());
    });

    try {
      // STEP 1: Load site questions (use default if none from server)
      final questions = await _loadSiteQuestions(c);

      // Use default questions if no custom questions
      final questionsToShow = questions.isNotEmpty
          ? questions
          : await SiteQuestion.getDefaultQuestions();

      debugPrint('Questions to show: ${questionsToShow.length}');
      debugPrint('Custom questions: ${questions.isNotEmpty}');

      // Show site questions page before badge preview
      if (!mounted) return;

      final result = await Navigator.push<Map<String, String>>(
        context,
        MaterialPageRoute(
          builder: (_) => SiteQuestionsPage(
            siteName: c.currentSite?.title ?? 'Site Induction',
            questions: questionsToShow,
            logoBytes: c.clientLogoDisplayBytes,
          ),
        ),
      );

      // If user cancelled or didn't answer all "Yes", abort sign-in
      if (result == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Sign in cancelled. Please complete site induction to continue.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
          setState(() => _submitting = false);
        }
        return;
      }

      // Store questions and answers
      _siteQuestions = questionsToShow;
      _questionAnswers = result;
      _signFormId = questions.isNotEmpty
          ? int.tryParse(questions.first.id)
          : null;

      // STEP 2: Submit to server FIRST (before generating badge)
      final token = await SecureStorageService.getAuthToken();
      if (token == null) {
        throw Exception('No auth token found');
      }

      // Generate temporary visitor ID for photo key (will be replaced by server's ID)
      final tempVisitorId = 'VIS${DateTime.now().millisecondsSinceEpoch}';

      // Format the "agree" data
      final Map<String, dynamic> agreeData = _formatAgreeData();

      // Prepare photos payload with visitor ID as key
      Map<String, String>? photosPayload;
      if (_visitorPhotoBytes != null) {
        photosPayload = {
          tempVisitorId: base64Encode(_visitorPhotoBytes!),
        };
      }

      final response = await ApiService.submitSignInLedger(
        token: token,
        siteId: c.currentSite?.id ?? '',
        name: _fullNameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        questions: agreeData,
        uniqueId: '', // Will be generated by server
        // Optional fields - only include if enabled in dashboard
        organisation: c.reqCompany && _companyCtrl.text.trim().isNotEmpty
            ? _companyCtrl.text.trim()
            : null,
        phone: c.reqPhone && _phoneCtrl.text.trim().isNotEmpty
            ? _phoneCtrl.text.trim()
            : null,
        address: c.reqAddress && _addressCtrl.text.trim().isNotEmpty
            ? _addressCtrl.text.trim()
            : null,
        workType: c.reqWorkType && _workTypeCtrl.text.trim().isNotEmpty
            ? _workTypeCtrl.text.trim()
            : null,
        supervisor: c.reqSupervisor && _selectedContactDetail != null
            ? _selectedContactDetail!.name
            : null,
        signInTime: c.reqSignInTime ? _signInTimeDisplay : null,
        visitorPhotos: photosPayload,
      );

      debugPrint('Sign in successfully in site!');
      // Get the unique_id from server response
      final String serverVisitorId =
          response['visitor_id']?.toString() ??
          response['unique_id']?.toString() ??
          'VIS${DateTime.now().millisecondsSinceEpoch}';
      await SecureStorageService.addSignedVisitor(
        visitorId: serverVisitorId,
        email: _emailCtrl.text.trim(),
        fullName: _fullNameCtrl.text.trim(),
        supervisorId: _selectedContactDetail?.id,
        supervisorName: _selectedContactDetail?.name,
        supervisorEmail: _selectedContactDetail?.email,
        supervisorPhone: _selectedContactDetail?.phone,
        notifyViaSms: c.notifyVisitorSms,
        notifyViaEmail: c.notifyVisitorEmail,
      );

      // STEP 2.5: Send notifications IMMEDIATELY after successful sign-in
      final badgeData = BadgeData(
        visitorId: serverVisitorId,
        fullName: c.reqFullName ? _fullNameCtrl.text.trim() : null,
        email: c.reqEmail ? _emailCtrl.text.trim() : null,
        phone: c.reqPhone ? _phoneCtrl.text.trim() : null,
        workType: c.reqWorkType ? _workTypeCtrl.text.trim() : null,
        company: c.reqCompany ? _companyCtrl.text.trim() : null,
        address: c.reqAddress ? _addressCtrl.text.trim() : null,
        supervisor: c.reqSupervisor ? _selectedContactDetail?.name : null,
        signInTime: c.reqSignInTime ? _signInTimeDisplay : null,
        siteName: c.resolveSiteHeading('Visitor Badge'),
        clientLogoBytes: c.clientLogoBytes,
        clientLogoUrl: c.clientLogoUrl,
        visitorPhotoBytes: _visitorPhotoBytes,
      );
      await _sendNotificationsOnSignIn(c, badgeData);

      // STEP 3: Generate badge image (reusing badgeData from above)
      /*
      debugPrint(
        'VISITOR BADGE GENERATION | '
        'Visitor ID: $serverVisitorId | '
        'Client Logo URL: ${c.clientLogoUrl ?? 'NULL'} | '
        'Client Logo Bytes: ${c.clientLogoBytes != null ? 'Available (${c.clientLogoBytes!.length} bytes)' : 'NULL'}'
      );*/

      // STEP 4: Generate the badge image
      final ui.Image badgeImage = await BadgeGenerator.generateBadgeImage(
        badgeData,
      );

      // STEP 5: Navigate to badge preview page (will auto-print there)
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => _BadgePreviewPage(
              badgeImage: badgeImage,
              badgeData: badgeData,
              controller: c,
              siteHeading: c.resolveSiteHeading('Visitor Badge'),
            ),
          ),
          (route) => false, // Remove all previous routes
        );
      }
    } catch (e) {
      if (!mounted) return;
      // Show error page instead of snackbar
      _showErrorPage(e.toString());
      setState(() => _submitting = false);
    }
  }

  /// Show error page when sign-in submission fails
  void _showErrorPage(String errorMessage) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SignInErrorDialog(
        errorMessage: errorMessage,
        onReturn: () {
          Navigator.of(context).pop();
          // Reset form or navigate back
        },
      ),
    );
  }

  /// Check if email matches any contact in the system
  /// If match found, set warning and prevent sign-in
  void _checkEmailAgainstContacts(DashboardController? c) {
    if (c == null) return;

    final email = _emailCtrl.text.trim().toLowerCase();
    if (email.isEmpty) {
      setState(() => _emailMatchWarning = null);
      return;
    }

    // Check if email matches any contact
    final matchingContact = c.availableSupervisors.firstWhere(
      (contact) => contact.email.toLowerCase() == email,
      orElse: () => ContactDetail(id: '', name: '', email: '', phone: ''),
    );

    if (matchingContact.id.isNotEmpty) {
      // Email matches a contact - NOT ALLOWED
      setState(() {
        _emailMatchWarning =
            'This email belongs to ${matchingContact.name}. '
            'Staff members cannot sign in as visitors.';
      });
      debugPrint('Email matches contact: ${matchingContact.name}');
    } else {
      setState(() => _emailMatchWarning = null);
    }
  }

  /// Format the "agree" data for server submission
  /// Returns default format for default questions, custom format for custom questions
  Map<String, dynamic> _formatAgreeData() {
    // Check if using custom questions (has sign_form_id)
    if (_signFormId != null) {
      // Custom format
      return {
        'sign_form_id': _signFormId,
        'project_question': _questionAnswers.values.toList(),
        'questions': _siteQuestions
            .map((q) => {'name': q.id, 'question': q.text})
            .toList(),
      };
    } else {
      // Default format
      final agreeMap = <String, dynamic>{};
      for (var entry in _questionAnswers.entries) {
        // All answers are "Yes" since we validated this earlier
        agreeMap[entry.key] = true;
      }
      return agreeMap;
    }
  }

  void _applySignInTimestamp(TimezoneSnapshot snapshot) {
    _signInTimezone = snapshot;
    _signInTimeDisplay = TimezoneService.formatLocal(snapshot.localTime);
    _signInUtcIso = snapshot.utcTime.toIso8601String();
    _signInTimeCtrl.text = _signInTimeDisplay;
  }

  void _startSignInClock() {
    _signInClockTimer?.cancel();
    _signInClockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final now = DateTime.now();
      final text = TimezoneService.formatLocal(now);
      if (text != _signInTimeDisplay) {
        setState(() {
          _signInTimeDisplay = text;
          _signInTimeCtrl.text = text;
        });
      }
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

  Future<_NotificationResult> _sendNotificationsOnSignIn(
    DashboardController c,
    BadgeData badgeData,
  ) async {
    /*
    debugPrint(
      'SIGN-IN NOTIFICATION LOGIC | '
      'Notify SMS: ${c.notifyVisitorSms} | '
      'Notify Email: ${c.notifyVisitorEmail} | '
    );
    */

    final contact = _selectedContactDetail;
    if (contact == null) {
      debugPrint('Notifications will NOT be sent');
      return const _NotificationResult();
    }
    /*
      debugPrint(
      'CONTACT INFO | '
      'ID: ${contact.id} | '
      'Name: ${contact.name} | '
      'Email: ${contact.email} | '
      'Phone: ${contact.phone} | '
      'VISITOR INFO | '
      'Visitor Name: ${badgeData.fullName ?? "N/A"} | '
      'Visitor Company: ${badgeData.company ?? "N/A"} | '
      'Visitor Phone: ${badgeData.phone ?? "N/A"} | '
      'Work Type: ${badgeData.workType ?? "N/A"}'
    );
    */

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

    final siteName = c.resolveSiteHeading('Visitor Site');
    bool smsAttempted = false;
    bool smsSuccess = true;
    bool emailAttempted = false;

    if (c.notifyVisitorSms && contact.phone.trim().isNotEmpty) {
      smsAttempted = true;
      final message = NotificationService.buildVisitorSignInMessage(
        siteName: siteName,
        visitorName: badgeData.fullName ?? 'Visitor',
        company: badgeData.company,
        phoneNumber: badgeData.phone,
        workType: badgeData.workType,
      );

      debugPrint(
        'SENDING SMS NOTIFICATION | '
        'Recipient: ${contact.name} | '
        'Phone: ${contact.phone} | '
        'Contact ID: ${contact.id} | '
        'Message: $message',
      );

      smsSuccess = await NotificationService.sendTextMessage(
        userId: contact.id,
        mobile: contact.phone,
        message: message,
      );

      debugPrint('RESULT: ${smsSuccess ? "SUCCESS" : "FAILED"}');
    }

    bool emailSuccess = true;
    if (c.notifyVisitorEmail && contact.email.trim().isNotEmpty) {
      emailAttempted = true;
      final email = NotificationService.buildVisitorSignInEmail(
        siteName: siteName,
        visitorName: badgeData.fullName ?? 'Visitor',
        company: badgeData.company,
        phoneNumber: badgeData.phone,
        workType: badgeData.workType,
      );

      /*
      debugPrint(
        'SENDING EMAIL NOTIFICATION | '
        'Recipient: ${contact.name} | '
        'Email: ${contact.email} | '
        'Contact ID: ${contact.id} | '
        'Contact Phone: ${contact.phone} | '
        'Logo URL: ${logoUrl ?? "N/A"} | '
        'Email Body: ${email['body'] ?? ""}'
      );
      */
      // Prepare visitor photo if available
      String? visitorPhotoBase64;
      if (badgeData.visitorPhotoBytes != null) {
        visitorPhotoBase64 = base64Encode(badgeData.visitorPhotoBytes!);
      }

      // Send actual email via API with logo URL and visitor photo
      emailSuccess = await NotificationService.sendEmail(
        userId: contact.id,
        name: badgeData.fullName ?? 'Visitor',
        email: contact.email,
        phone: contact.phone,
        message: email['body'] ?? '',
        logoUrl: logoUrl,
        visitorPhoto: visitorPhotoBase64,
      );
      debugPrint(emailSuccess ? "SUCCESS" : "FAILED");
    }
    return _NotificationResult(
      smsAttempted: smsAttempted,
      smsSuccess: smsSuccess,
      emailAttempted: emailAttempted,
      emailSuccess: emailSuccess,
    );
  }

  Future<List<SiteQuestion>> _loadSiteQuestions(
    DashboardController controller,
  ) async {
    final siteId = controller.currentSite?.id;
    if (siteId == null || siteId.isEmpty) {
      return [];
    }

    final token = await SecureStorageService.getAuthToken();
    if (token == null || token.isEmpty) {
      return [];
    }

    try {
      final response = await ApiService.fetchSiteQuestions(token, siteId);

      final payload = _extractQuestionList(response);
      if (payload.isEmpty) {
        return [];
      }

      return payload
          .whereType<Map<String, dynamic>>()
          .map(SiteQuestion.fromJson)
          .toList();
    } catch (e) {
      debugPrint('Failed to load site questions: $e');
      return [];
    }
  }

  List<dynamic> _extractQuestionList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map<String, dynamic>) {
      const keys = ['data', 'questions', 'site_questions', 'items', 'results'];
      for (final key in keys) {
        final value = raw[key];
        final list = _extractQuestionList(value);
        if (list.isNotEmpty) {
          return list;
        }
      }
    }
    return const <dynamic>[];
  }

  @override
  Widget build(BuildContext context) {
    // Get controller early to determine background styling
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
                // Loading spinner with container for better visibility
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Preparing form...',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppTheme.slate800,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Loading contacts and site information',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.slate600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Controller already retrieved above for loading screen styling
    final siteHeading =
        c?.resolveSiteHeading('Visitor Sign In') ?? 'Visitor Sign In';

    final bool showFullName = c?.reqFullName ?? true;
    final bool showPhone = c?.reqPhone ?? false;
    final bool showEmail = c?.reqEmail ?? true;
    final bool showCompany = c?.reqCompany ?? false;
    final bool showAddress = c?.reqAddress ?? false;
    final bool showWorkType = c?.reqWorkType ?? false;
    final bool showContactDetail = c?.reqSupervisor ?? false;
    final bool showSignInTime = c?.reqSignInTime ?? true;
    final List<ContactDetail> availableSupervisors =
        c?.availableSupervisors ?? [];

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
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: maxBodyWidth),
              child: KioskBody(
                siteTitle: siteHeading,
                supervisorName: null,
                printerReady: c?.initialized ?? false,
                logo1Bytes: c?.clientLogoDisplayBytes,
                logo1Url: c?.clientLogoDisplayBytes == null
                    ? 'lib/assets/images/WorxSafety_Logo_NoShadow.svg'
                    : null,
                logo2Url: 'lib/assets/images/Worx_PoweredBy_Logo_Mono.svg',
                menuContent: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showFullName) ...[
                          KioskField(
                            controller: _fullNameCtrl,
                            title: 'Full Name',
                            required: true,
                            autofill: const [AutofillHints.name],
                            validator: (v) {
                              final text = (v ?? '').trim();
                              if (text.isEmpty) return 'Full name is required';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (showEmail) ...[
                          KioskField(
                            controller: _emailCtrl,
                            title: 'Email Address',
                            keyboardType: TextInputType.emailAddress,
                            autofill: const [AutofillHints.email],
                            required: true,
                            onChanged: (value) {
                              // Real-time check against contacts
                              _checkEmailAgainstContacts(c);
                            },
                            validator: (v) {
                              final text = (v ?? '').trim();
                              if (text.isEmpty) return 'Email is required';
                              final emailReg = RegExp(
                                r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                              );
                              if (!emailReg.hasMatch(text)) {
                                return 'Enter a valid email';
                              }
                              final controller = c;
                              if (controller != null) {
                                final normalized = text.toLowerCase();
                                final exists = controller.availableSupervisors
                                    .any(
                                      (contact) =>
                                          contact.email.trim().toLowerCase() ==
                                          normalized,
                                    );
                                if (exists) {
                                  return 'This email already exists in Worx Safety. Staff members cannot sign in as visitors.';
                                }
                              }
                              return null;
                            },
                          ),
                          // Show warning message if email matches a contact
                          if (_emailMatchWarning != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.dangerColor.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppTheme.dangerColor.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: AppTheme.dangerColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _emailMatchWarning!,
                                      style: TextStyle(
                                        color: AppTheme.dangerColor,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                        ],
                        if (showPhone) ...[
                          KioskField(
                            controller: _phoneCtrl,
                            title: 'Phone Number',
                            keyboardType: TextInputType.phone,
                            autofill: const [AutofillHints.telephoneNumber],
                            required: true,
                            validator: (v) {
                              final text = (v ?? '').trim();
                              if (text.isEmpty) {
                                return 'Phone number is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (showWorkType) ...[
                          KioskField(
                            controller: _workTypeCtrl,
                            title: 'Work Type',
                            required: true,
                            validator: (v) {
                              final text = (v ?? '').trim();
                              if (text.isEmpty) {
                                return 'Work type is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (showCompany) ...[
                          KioskField(
                            controller: _companyCtrl,
                            title: 'Company',
                            required: true,
                            validator: (v) {
                              final text = (v ?? '').trim();
                              if (text.isEmpty) return 'Company is required';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                        ],
                        if (showAddress) ...[
                          KioskField(
                            controller: _addressCtrl,
                            title: 'Address',
                            required: true,
                            validator: (v) {
                              final text = (v ?? '').trim();
                              if (text.isEmpty) return 'Address is required';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                        ],
                        if (showContactDetail) ...[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Person Visiting',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 12),
                              if (availableSupervisors.isEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppTheme.warningColor.withValues(
                                        alpha: 0.4,
                                      ),
                                    ),
                                    color: AppTheme.statusBackgroundColor(
                                      'warning',
                                    ),
                                  ),
                                  child: Text(
                                    'No contacts available. Please refresh contacts on the dashboard.',
                                    style: TextStyle(
                                      color: AppTheme.slate700,
                                      fontSize: 13,
                                    ),
                                  ),
                                )
                              else ...[
                                // Dropdown-style button to open contact selector
                                InkWell(
                                  onTap: () async {
                                    final selected = await showDialog<ContactDetail>(
                                      context: context,
                                      builder: (context) => _ContactSelectorDialog(
                                        contacts: availableSupervisors,
                                        currentSelection: _selectedContactDetail,
                                      ),
                                    );
                                    if (selected != null) {
                                      setState(() {
                                        _selectedContactDetail = selected;
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: AppTheme.slate300,
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.supervisor_account,
                                          color: AppTheme.slate600,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _selectedContactDetail != null
                                              ? Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      _selectedContactDetail!.name,
                                                      style: TextStyle(
                                                        color: AppTheme.slate900,
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                    if (_selectedContactDetail!.email.isNotEmpty)
                                                      Text(
                                                        _selectedContactDetail!.email,
                                                        style: TextStyle(
                                                          color: AppTheme.slate600,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                  ],
                                                )
                                              : Text(
                                                  'Select person',
                                                  style: TextStyle(
                                                    color: AppTheme.slate500,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                        ),
                                        Icon(
                                          Icons.arrow_drop_down,
                                          color: AppTheme.slate600,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Show success indicator if selected
                                if (_selectedContactDetail != null) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: AppTheme.successColor,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Person selected',
                                        style: TextStyle(
                                          color: AppTheme.successColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const Spacer(),
                                      TextButton.icon(
                                        onPressed: () {
                                          setState(() {
                                            _selectedContactDetail = null;
                                          });
                                        },
                                        icon: const Icon(Icons.close, size: 14),
                                        label: const Text('Clear'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: AppTheme.slate600,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                // Validation message
                                FormField<ContactDetail>(
                                  initialValue: _selectedContactDetail,
                                  validator: (v) {
                                    if (availableSupervisors.isEmpty) {
                                      return 'No contacts available';
                                    }
                                    if (_selectedContactDetail == null) {
                                      return 'Please select who you are visiting';
                                    }
                                    return null;
                                  },
                                  builder: (formFieldState) {
                                    return formFieldState.hasError
                                        ? Padding(
                                            padding: const EdgeInsets.only(top: 8, left: 12),
                                            child: Text(
                                              formFieldState.errorText ?? '',
                                              style: TextStyle(
                                                color: AppTheme.dangerColor,
                                                fontSize: 12,
                                              ),
                                            ),
                                          )
                                        : const SizedBox.shrink();
                                  },
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                        if (showSignInTime) ...[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sign In Time',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _signInTimeCtrl,
                                enabled: false,
                                decoration: const InputDecoration(
                                  labelText: 'Sign In Time',
                                  prefixIcon: Icon(Icons.access_time),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Device time (${_signInTimezone.timezoneDescription}); logged as $_signInUtcIso UTC',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ],

                        // Visitor Photo Section
                        if (c?.reqVisitorPhoto ?? false) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.statusBackgroundColor('info'),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.camera_alt,
                                      color: AppTheme.primaryBlue,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Visitor Photo',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.slate800,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (_visitorPhotoBytes != null) ...[
                                  Container(
                                    height: 200,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppTheme.slate300,
                                        width: 2,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.memory(
                                        _visitorPhotoBytes!,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: _takePhoto,
                                          icon: const Icon(Icons.refresh, size: 20),
                                          label: const Text('Retake'),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: _removePhoto,
                                          icon: const Icon(Icons.delete, size: 20),
                                          label: const Text('Remove'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppTheme.dangerColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ] else ...[
                                  FilledButton.icon(
                                    onPressed: _takePhoto,
                                    icon: const Icon(Icons.camera_alt),
                                    label: const Text('Take Photo'),
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Photo is required to continue',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.slate600,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => Navigator.pop(this.context),
                              label: const Text('Back'),
                              icon: const Icon(Icons.arrow_back),
                            ),
                            const Spacer(),
                            FilledButton(
                              onPressed: _submitting ? null : _onSubmit,
                              child: _submitting
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Next'),
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

class _NotificationResult {
  final bool smsAttempted;
  final bool smsSuccess;
  final bool emailAttempted;
  final bool emailSuccess;

  const _NotificationResult({
    this.smsAttempted = false,
    this.smsSuccess = true,
    this.emailAttempted = false,
    this.emailSuccess = true,
  });
}

/// Badge Preview Page - Shows badge and auto-prints
class _BadgePreviewPage extends StatefulWidget {
  const _BadgePreviewPage({
    required this.badgeImage,
    required this.badgeData,
    required this.controller,
    required this.siteHeading,
  });

  final ui.Image badgeImage;
  final BadgeData badgeData;
  final DashboardController controller;
  final String siteHeading;

  @override
  State<_BadgePreviewPage> createState() => _BadgePreviewPageState();
}

class _BadgePreviewPageState extends State<_BadgePreviewPage> {
  PrintProgress _printProgress = PrintProgress.idle();

  @override
  void initState() {
    super.initState();
    // Auto-print badge after preview is shown
    _autoPrintBadge();
  }

  Future<void> _autoPrintBadge() async {
    if (!widget.controller.printVisitorBadge) {
      // Printing not enabled, user can return immediately
      return;
    }

    final printSuccess = await widget.controller.printerService.printImage(
      widget.badgeImage,
      onStatusUpdate: (progress) {
        if (mounted) {
          setState(() {
            _printProgress = progress;
          });
        }
      },
    );

    if (mounted) {
      if (printSuccess) {
        // Auto-return after 5 seconds when print completes
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) _returnToKiosk();
        });
        debugPrint('Badge printed successfully!');
      } else {
        debugPrint('Badge printing failed');
      }
    }
  }

  void _returnToKiosk() {
    // Only allow return if printing is not in progress
    if (!_printProgress.status.isInProgress || !widget.controller.printVisitorBadge) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.visitorKiosk,
        (route) => false,
        arguments: widget.controller,
      );
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.slate600,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: AppTheme.slate800, fontSize: 14),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scaffold = PopScope(
      // Prevent back button during printing
      canPop: !_printProgress.status.isInProgress || !widget.controller.printVisitorBadge,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // Show warning if user tries to exit during printing
        if (_printProgress.status.isInProgress && widget.controller.printVisitorBadge) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Please wait for printing to complete before returning to kiosk',
              ),
              backgroundColor: AppTheme.warningColor,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      child: Scaffold(
        body: Align(
          alignment: Alignment.center,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppBreakpoints.standard,
            ),
            child: KioskBody(
              siteTitle: widget.siteHeading,
              supervisorName: null,
              logo1Bytes: widget.controller.clientLogoDisplayBytes,
              logo1Url: widget.controller.clientLogoDisplayBytes == null
                  ? 'lib/assets/images/WorxSafety_Logo_NoShadow.svg'
                  : null,
              logo2Url: 'lib/assets/images/Worx_PoweredBy_Logo_Mono.svg',
              menuContent: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Badge preview header
                    Text(
                      'Your visitor badge has been generated',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Badge image preview
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 300,
                            maxHeight: 800,
                          ),
                          child: RawImage(
                            image: widget.badgeImage,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Visitor information
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.statusBackgroundColor('info'),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.slate300, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Visitor Information',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppTheme.slate800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            'Visitor ID:',
                            widget.badgeData.visitorId,
                          ),
                          const SizedBox(height: 8),
                          if (widget.badgeData.fullName != null) ...[
                            _buildInfoRow('Name:', widget.badgeData.fullName!),
                            const SizedBox(height: 8),
                          ],
                          if (widget.badgeData.company != null) ...[
                            _buildInfoRow(
                              'Company:',
                              widget.badgeData.company!,
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (widget.badgeData.phone != null) ...[
                            _buildInfoRow('Phone:', widget.badgeData.phone!),
                            const SizedBox(height: 8),
                          ],
                          if (widget.badgeData.signInTime != null)
                            _buildInfoRow(
                              'Sign-in Time:',
                              widget.badgeData.signInTime!,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Print Progress Display (only show if printing is enabled)
                    if (widget.controller.printVisitorBadge) ...[
                      PrintProgressWidget(
                        progress: _printProgress,
                        showIcon: true,
                        showTimestamp: false,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Action button: Disabled while printing, enabled when done
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: (_printProgress.status.isInProgress &&
                                widget.controller.printVisitorBadge)
                            ? null // Disabled while printing
                            : _returnToKiosk,
                        icon: (_printProgress.status.isInProgress &&
                                widget.controller.printVisitorBadge)
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white70,
                                  ),
                                ),
                              )
                            : const Icon(Icons.home),
                        label: Text(
                          (_printProgress.status.isInProgress &&
                                  widget.controller.printVisitorBadge)
                              ? 'Please wait...'
                              : 'Return to Kiosk',
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Info message - only show if printing disabled
                    if (!widget.controller.printVisitorBadge)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.statusBackgroundColor('success'),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppTheme.successColor,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Sign-in complete! Click "Return to Kiosk" when ready.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.slate700,
                                ),
                              ),
                            ),
                          ],
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
    );

    return KioskGuard(child: scaffold);
  }
}

/// Contact Selector Dialog with Search
class _ContactSelectorDialog extends StatefulWidget {
  final List<ContactDetail> contacts;
  final ContactDetail? currentSelection;

  const _ContactSelectorDialog({
    required this.contacts,
    this.currentSelection,
  });

  @override
  State<_ContactSelectorDialog> createState() => _ContactSelectorDialogState();
}

class _ContactSelectorDialogState extends State<_ContactSelectorDialog> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredContacts = widget.contacts.where((contact) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return contact.name.toLowerCase().contains(query) ||
             contact.email.toLowerCase().contains(query);
    }).toList();

    // Get screen size for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = AppBreakpoints.isSmallScreen(screenWidth);
    final dialogMaxWidth = AppBreakpoints.getDialogMaxWidth(screenWidth);
    final dialogHeight = AppBreakpoints.getDialogHeight(screenHeight);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: dialogHeight,
          maxWidth: dialogMaxWidth,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.supervisor_account,
                    color: AppTheme.primaryBlue,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Select Person Visiting',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.slate900,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),

            // Search field (first row)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: TextField(
                controller: _searchCtrl,
                autofocus: !isSmallScreen,
                decoration: InputDecoration(
                  labelText: 'Search',
                  hintText: 'Search by name or email...',
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchCtrl.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),

            // Results count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${filteredContacts.length} contact${filteredContacts.length == 1 ? '' : 's'} found',
                  style: TextStyle(
                    color: AppTheme.slate600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Contact list
            Flexible(
              child: filteredContacts.isEmpty
                  ? Container(
                      constraints: BoxConstraints(
                        minHeight: isSmallScreen ? 150 : 200,
                        maxHeight: dialogHeight * 0.5,
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: isSmallScreen ? 48 : 64,
                                color: AppTheme.slate400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No contacts found',
                                style: TextStyle(
                                  color: AppTheme.slate700,
                                  fontSize: isSmallScreen ? 14 : 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try adjusting your search',
                                style: TextStyle(
                                  color: AppTheme.slate600,
                                  fontSize: isSmallScreen ? 12 : 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: filteredContacts.length,
                      itemBuilder: (context, index) {
                        final contact = filteredContacts[index];
                        final isSelected = widget.currentSelection?.id == contact.id;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          elevation: isSelected ? 2 : 0,
                          color: isSelected
                              ? AppTheme.primaryBlue.withValues(alpha: 0.1)
                              : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSelected
                                  ? AppTheme.primaryBlue
                                  : AppTheme.slate200,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 12 : 16,
                              vertical: isSmallScreen ? 4 : 8,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: isSelected
                                  ? AppTheme.primaryBlue
                                  : AppTheme.slate400,
                              radius: isSmallScreen ? 20 : 24,
                              child: Text(
                                contact.name.isNotEmpty
                                    ? contact.name[0].toUpperCase()
                                    : 'C',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isSmallScreen ? 16 : 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              contact.name,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                fontSize: isSmallScreen ? 14 : 16,
                              ),
                            ),
                            subtitle: contact.email.isNotEmpty
                                ? Text(
                                    contact.email,
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 11 : 12,
                                    ),
                                  )
                                : null,
                            trailing: isSelected
                                ? Icon(
                                    Icons.check_circle,
                                    color: AppTheme.successColor,
                                    size: isSmallScreen ? 20 : 24,
                                  )
                                : Icon(
                                    Icons.arrow_forward_ios,
                                    size: isSmallScreen ? 14 : 16,
                                    color: AppTheme.slate400,
                                  ),
                            onTap: () => Navigator.pop(context, contact),
                          ),
                        );
                      },
                    ),
            ),

            // Footer with cancel button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.slate50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Error Dialog for Sign-In Failures
class _SignInErrorDialog extends StatelessWidget {
  const _SignInErrorDialog({
    required this.errorMessage,
    required this.onReturn,
  });

  final String errorMessage;
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Error Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.dangerColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 60,
                color: AppTheme.dangerColor,
              ),
            ),
            const SizedBox(height: 24),

            // Error Title
            Text(
              'Sign-In Failed',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.slate900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Error Message
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.dangerColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.dangerColor.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                errorMessage,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.slate700),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),

            // Return Button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onReturn,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Return to Kiosk'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.primaryBlue,
                ),
              ),
            ),

            // Additional Help Text
            const SizedBox(height: 16),
            Text(
              'Please check the error message and try again.\nIf the problem persists, contact support.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.slate600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
