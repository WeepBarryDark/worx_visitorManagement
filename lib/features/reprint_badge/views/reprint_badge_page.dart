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
    // TODO: Replace with API call when available
    // For now, use combination of stored visitors and dummy data

    final byId = <String, _SignedVisitor>{};

    // Try to load from storage first
    try {
      final visitors = await SecureStorageService.getSignedVisitors();
      for (final visitor in visitors) {
        final id = visitor['id']?.toString().trim() ?? '';
        final email = visitor['email']?.toString().trim().toLowerCase() ?? '';
        final fullName = visitor['full_name']?.toString() ?? '';
        final phone = visitor['phone']?.toString().trim() ?? '';
        final workType = visitor['work_type']?.toString().trim() ?? '';
        final company = visitor['company']?.toString().trim() ?? '';
        final address = visitor['address']?.toString().trim() ?? '';
        final supervisor = visitor['supervisor_name']?.toString().trim() ?? '';
        final signInTime = visitor['sign_in_time']?.toString().trim() ?? '';

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

        if (id.isNotEmpty) {
          byId[id] = record;
        }
      }
    } catch (e) {
      debugPrint('Error loading stored visitors: $e');
    }

    // Add dummy data for testing (will be removed when API is available)
    if (byId.isEmpty) {
      final dummyVisitors = [
        _SignedVisitor(
          id: 'V001',
          email: 'john.smith@example.com',
          fullName: 'John Smith',
          phone: '+61 412 345 678',
          workType: 'Contractor',
          company: 'ABC Construction',
          address: '123 Main St, Sydney',
          supervisor: 'Barry Wang',
          signInTime: '2026-01-08 09:30 AM',
        ),
        _SignedVisitor(
          id: 'V002',
          email: 'sarah.jones@example.com',
          fullName: 'Sarah Jones',
          phone: '+61 423 456 789',
          workType: 'Visitor',
          company: 'XYZ Corporation',
          address: '456 Park Ave, Melbourne',
          supervisor: 'Barry Wang',
          signInTime: '2026-01-08 10:15 AM',
        ),
        _SignedVisitor(
          id: 'V003',
          email: 'michael.chen@example.com',
          fullName: 'Michael Chen',
          phone: '+61 434 567 890',
          workType: 'Delivery',
          company: 'Fast Delivery Co',
          address: '789 High St, Brisbane',
          supervisor: 'Barry Wang',
          signInTime: '2026-01-08 11:00 AM',
        ),
        _SignedVisitor(
          id: 'V004',
          email: 'emma.wilson@example.com',
          fullName: 'Emma Wilson',
          phone: '+61 445 678 901',
          workType: 'Contractor',
          company: 'Building Services',
          address: '321 Queen St, Perth',
          supervisor: 'Barry Wang',
          signInTime: '2026-01-08 11:45 AM',
        ),
        _SignedVisitor(
          id: 'V005',
          email: 'david.brown@example.com',
          fullName: 'David Brown',
          phone: '+61 456 789 012',
          workType: 'Visitor',
          company: 'Tech Solutions Ltd',
          address: '654 King St, Adelaide',
          supervisor: 'Barry Wang',
          signInTime: '2026-01-08 01:30 PM',
        ),
      ];

      for (final visitor in dummyVisitors) {
        byId[visitor.id] = visitor;
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

    // Respect dashboard settings for which fields to display on badge
    // Only include fields that are enabled in dashboard configuration
    final badgeData = BadgeData(
      visitorId: visitor.id,
      fullName: (controller?.reqFullName ?? true) && visitor.fullName.isNotEmpty
          ? visitor.fullName
          : null,
      email: (controller?.reqEmail ?? true) && visitor.email.isNotEmpty
          ? visitor.email
          : null,
      phone: (controller?.reqPhone ?? false) && visitor.phone.isNotEmpty
          ? visitor.phone
          : null,
      workType: (controller?.reqWorkType ?? false) && visitor.workType.isNotEmpty
          ? visitor.workType
          : null,
      company: (controller?.reqCompany ?? false) && visitor.company.isNotEmpty
          ? visitor.company
          : null,
      address: (controller?.reqAddress ?? false) && visitor.address.isNotEmpty
          ? visitor.address
          : null,
      supervisor: (controller?.reqSupervisor ?? false) && visitor.supervisor.isNotEmpty
          ? visitor.supervisor
          : null,
      signInTime: (controller?.reqSignInTime ?? true) && visitor.signInTime.isNotEmpty
          ? visitor.signInTime
          : null,
      siteName: siteName,
      clientLogoBytes: controller?.clientLogoBytes,
      clientLogoUrl: controller?.clientLogoUrl,
    );

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
                        constraints: const BoxConstraints(maxHeight: 400),
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
