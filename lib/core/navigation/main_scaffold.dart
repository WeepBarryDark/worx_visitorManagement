import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'package:worxvisitorapp/core/constants/app_routes.dart';

import 'package:worxvisitorapp/core/models/site_item.dart' as dashboard_site;


import 'package:worxvisitorapp/services/secure_storage_service.dart';
import 'package:worxvisitorapp/services/api_service.dart';
import 'package:worxvisitorapp/features/dashboard/views/dashboard_page.dart';
import 'package:worxvisitorapp/features/dashboard/controllers/dashboard_controller.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Dashboard controller - will be initialized with API data
  DashboardController? _dashboardController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  /// Load sites from secure storage and initialize dashboard
  Future<void> _loadDashboardData() async {
    try {
      final sitesJson = await SecureStorageService.getSites();
      final selectedSiteJson = await SecureStorageService.getSelectedSite();

      List<dashboard_site.SiteItem> sites = [];
      dashboard_site.SiteItem? selectedSite;

      // Parse cached sites (supports raw List or {data:[...]})
      if (sitesJson != null && sitesJson.isNotEmpty) {
        try {
          final decoded = jsonDecode(sitesJson);
          final rawList = decoded is List
              ? decoded
              : (decoded is Map<String, dynamic> && decoded['data'] is List
                  ? decoded['data']
                  : <dynamic>[]);

          sites = rawList
              .whereType<Map<String, dynamic>>()
              .map(dashboard_site.SiteItem.fromJson)
              .toList();
        } catch (e) {
          debugPrint('Failed to parse cached sites: $e');
          sites = [];
        }
      }

      // Parse last selected site if available
      if (selectedSiteJson != null && selectedSiteJson.isNotEmpty) {
        try {
          final selectedMap = jsonDecode(selectedSiteJson) as Map<String, dynamic>;
          selectedSite = dashboard_site.SiteItem.fromJson(selectedMap);
        } catch (e) {
          debugPrint('Failed to parse selected site: $e');
        }
      }

      // Initialize dashboard controller
      _dashboardController = DashboardController(
        sites: sites,
        initialSite: selectedSite ?? (sites.isNotEmpty ? sites.first : null),
        getContext: () async => context,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      // On error, initialize with empty data
      _dashboardController =
          DashboardController(sites: const <dashboard_site.SiteItem>[]);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while data is being loaded
    if (_isLoading || _dashboardController == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
        key: _scaffoldKey,
        drawer: _buildDrawer(context),

        // Body with IndexedStack (preserves state automatically)
        body: IndexedStack(
          index: _currentIndex,
          children: [
            DashboardPage(controller: _dashboardController!),
          ],
        ),

        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.menu),
                label: "Menu",
              ),
          ],
          onTap: (index){
            if(index == 1){
              // Open drawer (Menu button is at index 1)
              _scaffoldKey.currentState?.openDrawer();
            } else {
                setState(() {
                  _currentIndex = index;
                });
            }
          },
          ),

    );
  }

  Widget _buildDrawer(BuildContext context) {
    return  Drawer(
      child: SafeArea(
        child:  ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, //horizantal
                  mainAxisAlignment: MainAxisAlignment.end, //verticle 
                  children: [
                    Text(
                      'Worx Companion',
                      style: TextStyle(
                        color:  Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'visitor Management',
                      style: TextStyle(color: Colors.white70),
                    )
                  ],
                )
              ),
              ListTile(
                leading: const Icon(Icons.dashboard_outlined),
                title: const Text('Dashboard'),
                selected: _currentIndex == 0,
                onTap: (){
                  Navigator.pop(context);//close drawer
                  setState(() => _currentIndex = 0);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Log out'),
                onTap:() {
                  Navigator.pop(context);
                  _handleLogout(context);
                },
              )
          ],
        ) 
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    //show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              // Get root navigator context BEFORE showing any dialogs
              final rootNavigator = Navigator.of(context, rootNavigator: true);

              // Close confirmation dialog
              Navigator.pop(context);

              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (dialogContext) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              try {
                // STEP 1: Revoke API key on server
                final authToken = await SecureStorageService.getAuthToken();

                if (authToken != null && authToken.isNotEmpty && !kIsWeb) {

                  try {
                    await ApiService.revokeVisitorToken(authToken);
                      debugPrint('API key revoked successfully');
                  } catch (e) {
                      debugPrint('Failed to revoke API key: $e');
                    // Continue with logout even if revoke fails
                  }
                }
                await SecureStorageService.clearAll();
              } catch (e) {
                // Even if error, still clear all data
                await SecureStorageService.clearAll();
              }

              // Pop the loading dialog using root navigator
              rootNavigator.pop();

              // Small delay to ensure dialog is closed
              await Future.delayed(const Duration(milliseconds: 150));

              // Navigate to login using root navigator
              rootNavigator.pushNamedAndRemoveUntil(
                AppRoutes.login,
                (route) => false,
              );
            },
            child: const Text('Log out'),
          ),
        ],
      )
    );
  }

}
