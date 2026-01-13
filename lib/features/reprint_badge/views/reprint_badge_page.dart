// Re-print Badge Page
// Allows re-printing of visitor badges for signed-in visitors

import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:worxvisitorapp/core/theme/app_theme.dart';
import 'package:worxvisitorapp/widgets/kiosk_body.dart';
import 'package:worxvisitorapp/widgets/kiosk_guard.dart';
import 'package:worxvisitorapp/features/dashboard/controllers/dashboard_controller.dart';
import 'package:worxvisitorapp/services/secure_storage_service.dart';
import 'package:worxvisitorapp/services/api_service.dart';
import 'package:worxvisitorapp/services/badge_generator.dart';
import 'package:worxvisitorapp/core/models/print_status.dart';
import 'package:worxvisitorapp/widgets/print_progress_widget.dart';

class ReprintBadgePage extends StatefulWidget {
  const ReprintBadgePage({super.key});

  @override
  State<ReprintBadgePage> createState() => _ReprintBadgePageState();
}

class _ReprintBadgePageState extends State<ReprintBadgePage> {
  final _formKey = GlobalKey<FormState>();
  final _visitorIdCtrl = TextEditingController();
  bool _isInitializing = true;
  bool _isPrinting = false;
  Map<String, _SignedVisitor> _visitorsById = {};
  ui.Image? _badgeImage;
  Uint8List? _badgeImageBytes;
  PrintProgress _printProgress = PrintProgress.idle();

  // Client background branding
  String? _backgroundImageUrl;
  bool _useCustomBackground = false;

  @override
  void initState() {
    super.initState();
    _visitorIdCtrl.clear();
    _loadBackgroundFromStorage();
    _initializePage();
  }

  Future<void> _initializePage() async {
    setState(() {
      _isInitializing = true;
    });

    await _loadRecentVisitors();

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
    final byId = <String, _SignedVisitor>{};

    try {
      // Get auth token and site ID
      final token = await SecureStorageService.getAuthToken();
      final controller = DashboardController.instance;
      final siteId = controller?.currentSite?.id;

      if (token == null || token.isEmpty) {
        debugPrint('❌ No auth token found');
        throw Exception('Authentication required');
      }

      if (siteId == null || siteId.isEmpty) {
        debugPrint('❌ No site selected');
        throw Exception('Please select a site');
      }

      debugPrint('📡 Fetching signed in visitors from API...');
      debugPrint('   Site ID: $siteId');

      // Fetch visitors from API
      final visitors = await ApiService.fetchSignedInVisitors(
        token: token,
        siteId: siteId,
      );

      debugPrint('✅ Received ${visitors.length} visitors from API');

      // Parse visitors into _SignedVisitor objects
      for (final visitor in visitors) {
        // IMPORTANT: Use visitor_id (VIS...) NOT database id
        // Badge generation requires the visitor_id format
        final id = visitor['visitor_id']?.toString().trim() ??
                   visitor['unique_id']?.toString().trim() ??
                   visitor['id']?.toString().trim() ?? '';
        final email = visitor['email']?.toString().trim().toLowerCase() ?? '';
        final fullName = visitor['full_name']?.toString() ??
                        visitor['name']?.toString() ?? '';
        final phone = visitor['phone']?.toString().trim() ??
                     visitor['mobile']?.toString().trim() ?? '';
        final workType = visitor['work_type']?.toString().trim() ??
                        visitor['type']?.toString().trim() ?? '';
        final company = visitor['company']?.toString().trim() ??
                       visitor['organisation']?.toString().trim() ?? '';
        final address = visitor['address']?.toString().trim() ?? '';
        final supervisor = visitor['supervisor']?.toString().trim() ??
                          visitor['supervisor_name']?.toString().trim() ?? '';
        final signInTime = visitor['sign_in_time']?.toString().trim() ??
                          visitor['signed_in_at']?.toString().trim() ??
                          visitor['created_at']?.toString().trim() ?? '';

        if (id.isNotEmpty) {
          final record = _SignedVisitor(
            id: id,
            email: email,
            fullName: fullName,
            phone: phone,
            workType: workType,
            company: company,
            address: address,
            supervisor: supervisor,
            signInTime: signInTime,
          );
          byId[id] = record;
        }
      }

      debugPrint('✅ Parsed ${byId.length} visitors successfully');
    } catch (e) {
      debugPrint('❌ Error loading visitors from API: $e');

      // Fallback: Try to load from local storage
      debugPrint('📦 Falling back to local storage...');
      try {
        final visitors = await SecureStorageService.getSignedVisitors();
        for (final visitor in visitors) {
          // Use visitor_id from local storage (should be VIS... format)
          final id = visitor['visitor_id']?.toString().trim() ??
                     visitor['id']?.toString().trim() ?? '';
          final email = visitor['email']?.toString().trim().toLowerCase() ?? '';
          final fullName = visitor['full_name']?.toString() ?? '';
          final phone = visitor['phone']?.toString().trim() ?? '';
          final workType = visitor['work_type']?.toString().trim() ?? '';
          final company = visitor['company']?.toString().trim() ?? '';
          final address = visitor['address']?.toString().trim() ?? '';
          final supervisor = visitor['supervisor_name']?.toString().trim() ?? '';
          final signInTime = visitor['sign_in_time']?.toString().trim() ?? '';

          if (id.isNotEmpty) {
            final record = _SignedVisitor(
              id: id,
              email: email,
              fullName: fullName,
              phone: phone,
              workType: workType,
              company: company,
              address: address,
              supervisor: supervisor,
              signInTime: signInTime,
            );
            byId[id] = record;
          }
        }
        debugPrint('✅ Loaded ${byId.length} visitors from local storage');
      } catch (storageError) {
        debugPrint('❌ Error loading from storage: $storageError');
      }
    }

    if (!mounted) return;
    setState(() {
      _visitorsById = byId;
    });
  }

  /// Show list of signed-in visitors for selection
  Future<void> _showSignedInVisitorsList() async {
    if (_visitorsById.isEmpty) {
      if (!mounted) return;
      // Clear any existing snackbars first to prevent accumulation
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No signed-in visitors found. Please try again or check your connection.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final visitors = _visitorsById.values.toList();

    final selectedVisitor = await showDialog<_SignedVisitor>(
      context: context,
      barrierDismissible: true,
      builder: (context) => _SearchableVisitorDialog(visitors: visitors),
    );

    if (selectedVisitor != null) {
      setState(() {
        _visitorIdCtrl.text = selectedVisitor.id;
      });
      await _loadVisitorBadge(selectedVisitor);
    }
  }

  /// Load and generate badge for selected visitor
  Future<void> _loadVisitorBadge(_SignedVisitor visitor) async {
    setState(() {
      _badgeImage = null;
      _badgeImageBytes = null;
    });

    final controller = DashboardController.instance;
    final siteName = controller?.resolveSiteHeading('Visitor Badge') ?? 'Visitor Badge';

    // REPRINT LOGIC: Display fields based on what data actually exists
    // If the visitor has email/phone/etc in their data, show it on the badge
    // This recreates the original badge as it was when first printed
    debugPrint('🎫 REPRINT BADGE - Visitor Data:');
    debugPrint('   Visitor ID: ${visitor.id}');
    debugPrint('   Full Name: "${visitor.fullName}" (${visitor.fullName.isNotEmpty ? "✓" : "✗"})');
    debugPrint('   Email: "${visitor.email}" (${visitor.email.isNotEmpty ? "✓" : "✗"})');
    debugPrint('   Phone: "${visitor.phone}" (${visitor.phone.isNotEmpty ? "✓" : "✗"})');
    debugPrint('   Company: "${visitor.company}" (${visitor.company.isNotEmpty ? "✓" : "✗"})');
    debugPrint('   Work Type: "${visitor.workType}" (${visitor.workType.isNotEmpty ? "✓" : "✗"})');
    debugPrint('   Address: "${visitor.address}" (${visitor.address.isNotEmpty ? "✓" : "✗"})');
    debugPrint('   Supervisor: "${visitor.supervisor}" (${visitor.supervisor.isNotEmpty ? "✓" : "✗"})');
    debugPrint('   Sign In Time: "${visitor.signInTime}" (${visitor.signInTime.isNotEmpty ? "✓" : "✗"})');

    final badgeData = BadgeData(
      visitorId: visitor.id,
      // Show field ONLY if it has actual data
      fullName: visitor.fullName.isNotEmpty ? visitor.fullName : null,
      email: visitor.email.isNotEmpty ? visitor.email : null,
      phone: visitor.phone.isNotEmpty ? visitor.phone : null,
      workType: visitor.workType.isNotEmpty ? visitor.workType : null,
      company: visitor.company.isNotEmpty ? visitor.company : null,
      address: visitor.address.isNotEmpty ? visitor.address : null,
      supervisor: visitor.supervisor.isNotEmpty ? visitor.supervisor : null,
      signInTime: visitor.signInTime.isNotEmpty ? visitor.signInTime : null,
      siteName: siteName,
      clientLogoBytes: controller?.clientLogoBytes,
      clientLogoUrl: controller?.clientLogoUrl,
      visitorPhotoBytes: null, // Photo not available for reprint
    );

    debugPrint('🎫 BADGE DATA TO GENERATE:');
    debugPrint('   Full Name: ${badgeData.fullName ?? "NULL"}');
    debugPrint('   Email: ${badgeData.email ?? "NULL"}');
    debugPrint('   Phone: ${badgeData.phone ?? "NULL"}');
    debugPrint('   Company: ${badgeData.company ?? "NULL"}');
    debugPrint('   Work Type: ${badgeData.workType ?? "NULL"}');
    debugPrint('   Address: ${badgeData.address ?? "NULL"}');
    debugPrint('   Supervisor: ${badgeData.supervisor ?? "NULL"}');
    debugPrint('   Sign In Time: ${badgeData.signInTime ?? "NULL"}');

    try {
      // Generate ui.Image directly (same as sign in page)
      final badgeImage = await BadgeGenerator.generateBadgeImage(badgeData);

      // Convert to bytes for preview display
      final byteData = await badgeImage.toByteData(format: ui.ImageByteFormat.png);
      final badgeBytes = byteData!.buffer.asUint8List();

      if (mounted) {
        setState(() {
          _badgeImage = badgeImage;
          _badgeImageBytes = badgeBytes;
        });
      }
    } catch (e) {
      debugPrint('Error generating badge: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating badge: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Print the badge
  Future<void> _printBadge() async {
    if (_badgeImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No badge to print. Please select a visitor first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final controller = DashboardController.instance;
    if (controller == null || !controller.initialized) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Printer not connected'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isPrinting = true;
      _printProgress = PrintProgress.idle();
    });

    try {
      // Print using the ui.Image directly (same as sign in page)
      final success = await controller.printerService.printImage(
        _badgeImage!,
        onStatusUpdate: (progress) {
          if (mounted) {
            setState(() {
              _printProgress = progress;
            });
          }
        },
      );

      if (!mounted) return;

      // Show simple snackbar only on completion
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Badge printed successfully'),
            backgroundColor: AppTheme.successColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Print error: $e');
      if (!mounted) return;

      setState(() {
        _printProgress = PrintProgress.failed(
          'Print failed: ${e.toString()}',
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isPrinting = false;
        });
      }
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
                  'Loading...',
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

    final siteTitle = c?.resolveSiteHeading('Re-print Badge') ?? 'Re-print Badge';
    final logoBytes = c?.clientLogoDisplayBytes;

    const double maxBodyWidth = 720;

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
                logo1Bytes: logoBytes,
                logo1Url: logoBytes == null
                    ? 'lib/assets/images/WorxSafety_Logo_NoShadow.svg'
                    : null,
                logo2Url: 'lib/assets/images/Worx_PoweredBy_Logo_Mono.svg',
                menuContent: _buildContent(c),
              ),
            ),
          ),
        ),
      ),
    );

    return KioskGuard(child: scaffold);
  }

  Widget _buildContent(DashboardController? controller) {
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
                'Re-print Visitor Badge',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Search for a signed-in visitor and re-print their badge.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
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
              // Search button first
              FilledButton.icon(
                onPressed: _showSignedInVisitorsList,
                icon: const Icon(Icons.search, size: 22),
                label: const Text('Search Visitor'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 56),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Visitor ID field (read-only)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected Visitor ID',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _visitorIdCtrl,
                    readOnly: true,
                    decoration: InputDecoration(
                      hintText: 'Click "Search Visitor" to select',
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Badge preview
              if (_badgeImageBytes != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Badge Preview',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 800),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            _badgeImageBytes!,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Print Progress Display
              if (_printProgress.status != PrintStatus.idle) ...[
                PrintProgressWidget(
                  progress: _printProgress,
                  showIcon: true,
                  showTimestamp: false,
                ),
                const SizedBox(height: 20),
              ],

              // Action buttons
              _buildActionButtons(controller),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(DashboardController? controller) {
    final backButton = OutlinedButton.icon(
      onPressed: () => Navigator.pop(context),
      icon: const Icon(Icons.arrow_back),
      label: const Text('Back'),
    );

    final printButton = FilledButton.icon(
      onPressed: (_isPrinting || _badgeImage == null) ? null : _printBadge,
      icon: _isPrinting
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.print),
      label: Text(_isPrinting ? 'Printing...' : 'Print Badge'),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isStacked = constraints.maxWidth < 440;
        if (isStacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              printButton,
              const SizedBox(height: 12),
              backButton,
            ],
          );
        }
        return Row(
          children: [
            Expanded(flex: 3, child: backButton),
            const SizedBox(width: 16),
            Expanded(flex: 4, child: printButton),
          ],
        );
      },
    );
  }
}

// Visitor data model
class _SignedVisitor {
  final String id;
  final String email;
  final String fullName;
  final String phone;
  final String workType;
  final String company;
  final String address;
  final String supervisor;
  final String signInTime;

  _SignedVisitor({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.workType,
    required this.company,
    required this.address,
    required this.supervisor,
    required this.signInTime,
  });
}

// Searchable visitor dialog
class _SearchableVisitorDialog extends StatefulWidget {
  final List<_SignedVisitor> visitors;

  const _SearchableVisitorDialog({required this.visitors});

  @override
  State<_SearchableVisitorDialog> createState() =>
      _SearchableVisitorDialogState();
}

class _SearchableVisitorDialogState extends State<_SearchableVisitorDialog> {
  final _searchCtrl = TextEditingController();
  List<_SignedVisitor> _filteredVisitors = [];

  @override
  void initState() {
    super.initState();
    _filteredVisitors = widget.visitors;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _filterVisitors(String query) {
    final lowerQuery = query.toLowerCase().trim();
    if (lowerQuery.isEmpty) {
      setState(() {
        _filteredVisitors = widget.visitors;
      });
      return;
    }

    setState(() {
      _filteredVisitors = widget.visitors.where((visitor) {
        return visitor.fullName.toLowerCase().contains(lowerQuery) ||
            visitor.id.toLowerCase().contains(lowerQuery) ||
            visitor.email.toLowerCase().contains(lowerQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Select Visitor',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Search by name, ID, or email',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: _filterVisitors,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _filteredVisitors.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No visitors found',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredVisitors.length,
                      itemBuilder: (context, index) {
                        final visitor = _filteredVisitors[index];
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              visitor.fullName.isNotEmpty
                                  ? visitor.fullName[0].toUpperCase()
                                  : '?',
                            ),
                          ),
                          title: Text(visitor.fullName),
                          subtitle: Text('ID: ${visitor.id}${visitor.email.isNotEmpty ? ' • ${visitor.email}' : ''}'),
                          onTap: () => Navigator.pop(context, visitor),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
