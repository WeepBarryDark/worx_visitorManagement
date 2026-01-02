import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_svg/flutter_svg.dart';

import '../controllers/new_site_controller.dart';
import '../../../core/models/site_item.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/responsive/app_breakpoints.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/secure_storage_service.dart';
import '../../../services/api_service.dart';
import '../../../services/helper/parse_name.dart';

/// New Site Selection Page
/// Allows users to browse and select a site from the available sites list
class NewSitePage extends StatefulWidget {
  const NewSitePage({super.key});

  @override
  State<NewSitePage> createState() => _NewSitePageState();
}

class _NewSitePageState extends State<NewSitePage> {
  final _searchCtrl = TextEditingController();
  final _controller = NewSiteController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Client branding data
  String? _clientLogoUrl;
  // ignore: unused_field
  String? _clientName;
  Uint8List? _clientLogoBytes; // Downloaded logo bytes
  bool _isLoadingLogo = false;

  // Custom background data
  String? _backgroundImageUrl;
  bool _useCustomBackground = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Load client data and sites from API (fresh data every time)
  Future<void> _loadData() async {
    // Load client data
    Map<String, dynamic>? client;
    final cachedClientJson = await SecureStorageService.getClient();
    if (cachedClientJson != null && cachedClientJson.isNotEmpty) {
      client = jsonDecode(cachedClientJson) as Map<String, dynamic>;
    } else {
      final authToken = await SecureStorageService.getAuthToken();
      if (authToken != null && authToken.isNotEmpty) {
        final fetchedClient = await ApiService.fetchVisitorClient(authToken);
        await SecureStorageService.saveClient(jsonEncode(fetchedClient));
        client = fetchedClient;
      }
    }

    if (client != null) {
      final clientData = client;
      final backgroundImage = clientData['background_image'] as String?;

      // Validate and enable background image if format is valid (PNG/JPG)
      if (_isValidBackground(backgroundImage)) {
        setState(() {
          _backgroundImageUrl = backgroundImage;
          _useCustomBackground = true;
        });
      }

      setState(() {
        _clientLogoUrl = clientData['logo'] as String?;
        _clientName =
            clientData['name'] as String? ??
            clientData['trading_name'] as String?;
      });

      // Download logo to bypass CORS restrictions
      if (_clientLogoUrl != null && _clientLogoUrl!.isNotEmpty) {
        await _downloadLogo(_clientLogoUrl!);
      }
    }

    // FETCH FRESH SITES FROM API (not from secure storage)
    try {
      final authToken = await SecureStorageService.getAuthToken();
      if (authToken == null) {
        //print('No auth token found');
        return;
      }

      // Call API to get fresh sites
      final sitesData = await ApiService.fetchVisitorSites(authToken);

      if (sitesData['data'] != null && sitesData['count'] > 0) {
        final sites = sitesData['data'] as List<dynamic>;

        // Save to secure storage for offline access
        await SecureStorageService.saveSites(jsonEncode(sites));

        if (kDebugMode) {
          debugPrint('Fetched ${sites.length} sites from API');
        }

        // Load sites into controller
        await _controller.reloadSites();

        if (mounted) {
          setState(() {}); // Trigger rebuild with loaded sites
        }
      }
    } catch (e) {
      debugPrint('Error fetching sites from API: $e');
      // Fallback to secure storage if API fails
      await _controller.reloadSites();
      if (mounted) {
        setState(() {});
      }
    }
  }

  /// Download logo image to bypass CORS restrictions to bypass CORS restrictions
  Future<void> _downloadLogo(String url) async {
    if (!mounted) return;

    setState(() {
      _isLoadingLogo = true;
    });

    try {
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
        // Store logo bytes (supports both SVG and PNG/JPG)
        Uint8List logoBytes = response.bodyBytes;
        if (mounted) {
          setState(() {
            _clientLogoBytes = logoBytes;
            _isLoadingLogo = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingLogo = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error downloading logo: $e');
      if (mounted) {
        setState(() {
          _isLoadingLogo = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Handle site selection - Return selected site to caller
  void _handleSiteSelection(SiteItem site) async {
    // Save selected site to secure storage
    await SecureStorageService.saveSelectedSite(jsonEncode(site.toJson()));

    // Navigate to dashboard with selected site
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
    }
  }

  bool _isValidBackground(String? backgroundImage) {
    if (backgroundImage == null) return false;
    final lower = backgroundImage.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg');
  }

  /// Build logo widget - supports both SVG and PNG/JPG
  Widget _buildLogoWidget(Uint8List bytes, double height) {
    // Check if it's SVG
    final String bytesAsString = String.fromCharCodes(bytes.take(100));
    final isSvg =
        bytesAsString.contains('<svg') || bytesAsString.contains('<?xml');

    if (isSvg) {
      return SvgPicture.memory(bytes, height: height, fit: BoxFit.contain);
    } else {
      return Image.memory(bytes, height: height, fit: BoxFit.contain);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMedium = screenWidth >= AppBreakpoints.md;
    final isLarge = screenWidth >= AppBreakpoints.lg;

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(context),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Select Site'),
        actions: isMedium
            ? [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(
                    width: isLarge ? 360 : screenWidth * 0.42,
                    child: _buildSearchField(),
                  ),
                ),
              ]
            : null,
      ),
      body: Container(
        decoration: _useCustomBackground && _backgroundImageUrl != null
            ? BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(_backgroundImageUrl!),
                  fit: BoxFit.cover,
                  opacity: 0.9,
                ),
              )
            : null,
        child: Column(
          children: [
            // Client logo at top (only show if logo bytes available)
            if (_clientLogoUrl != null && _clientLogoUrl!.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: _isLoadingLogo
                      ? const SizedBox(
                          height: 80,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : _clientLogoBytes != null
                      ? _buildLogoWidget(_clientLogoBytes!, 80)
                      : const SizedBox.shrink(), // Hide if failed to load
                ),
              ),

            // Search bar on top for mobile
            if (!isMedium)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: _buildSearchField(),
              ),

            // Site count display (below search bar)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                _controller.searchQuery.isEmpty
                    ? 'Total Sites: ${_controller.all.length}'
                    : 'Showing ${_controller.filtered.length} of ${_controller.all.length} sites',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ),

            // Search chips (Active Only filter removed as per reference)
            if (_controller.searchQuery.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Chip(
                  label: Text(
                    'Search: ${_controller.searchQuery}',
                    overflow: TextOverflow.ellipsis,
                  ),
                  onDeleted: () {
                    _searchCtrl.clear();
                    setState(() => _controller.clearSearch());
                  },
                ),
              ),

            // Sites list
            Expanded(
              child: _controller.filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No sites found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try adjusting your search',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: _controller.filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final site = _controller.filtered[i];
                        return _SiteCard(
                          site: site,
                          wide: isLarge,
                          onTap: () => _handleSiteSelection(site),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build drawer menu
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: AppTheme.primaryBlue),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Worx Companion',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Site Selection',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.location_city_outlined),
              title: const Text('Select Site'),
              selected: true,
              onTap: () {
                Navigator.pop(context); // Close drawer
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.pop(context); // Go back to dashboard
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Log Out'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                _handleLogout(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Handle logout flow
  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Close dialog
              Navigator.pop(context);

              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) =>
                    const Center(child: CircularProgressIndicator()),
              );

              try {
                // Get auth token
                final authToken = await SecureStorageService.getAuthToken();

                // Call API to revoke token
                if (authToken != null && authToken.isNotEmpty) {
                  await ApiService.revokeVisitorToken(authToken);
                }

                // Clear local auth data
                await SecureStorageService.clearAuthData();

                // Small delay to ensure storage write completes
                await Future.delayed(const Duration(milliseconds: 100));

                //print('Logged out successfully');

                // Close loading dialog
                if (context.mounted) {
                  Navigator.pop(context);
                }

                // Navigate to login and remove all previous routes
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/',
                    (route) => false,
                  );
                }
              } catch (e) {
                // Even if something fails, still log out locally
                await SecureStorageService.clearAuthData();

                // Small delay to ensure storage write completes
                await Future.delayed(const Duration(milliseconds: 100));

                // Close loading dialog
                if (context.mounted) {
                  Navigator.pop(context);
                }

                // Navigate to login and remove all previous routes
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/',
                    (route) => false,
                  );
                }
              }
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  /// Build search text field
  Widget _buildSearchField() {
    return TextField(
      controller: _searchCtrl,
      textInputAction: TextInputAction.search,
      onChanged: (q) => setState(() => _controller.updateSearch(q)),
      onSubmitted: (q) => setState(() => _controller.updateSearch(q)),
      decoration: const InputDecoration(
        hintText: 'Search sites...',
        prefixIcon: Icon(Icons.search),
      ),
    );
  }
}

/// Site Card Widget
/// Displays site information in a card format
class _SiteCard extends StatelessWidget {
  final SiteItem site;
  final bool wide;
  final VoidCallback onTap;

  const _SiteCard({
    required this.site,
    required this.wide,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Site title and active status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      site.displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: site.active
                          ? AppTheme.statusBackgroundColor('success')
                          : AppTheme.statusBackgroundColor('inactive'),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      site.active ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: site.active
                            ? AppTheme.successColor
                            : AppTheme.dangerColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Address
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: AppTheme.slate500,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      site.address.isNotEmpty ? site.address : 'No address',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppTheme.slate600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Site Manager
              if (site.siteManager.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 16,
                      color: AppTheme.slate500,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Manager: ${site.siteManager}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.slate600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],

              // Site Supervisor
              if (site.siteSupervisor.isNotEmpty)
                Row(
                  children: [
                    Icon(
                      Icons.supervisor_account_outlined,
                      size: 16,
                      color: AppTheme.slate500,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Supervisor: ${parserName(site.siteSupervisor)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.slate600,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
