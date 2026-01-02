import 'package:flutter/material.dart';

//route
import 'package:worxvisitorapp/core/constants/app_routes.dart';
import 'package:worxvisitorapp/core/navigation/main_scaffold.dart';
//theme
import 'package:worxvisitorapp/core/theme/app_theme.dart';
//pages
import 'package:worxvisitorapp/features/auth/views/auth_page.dart';
import 'package:worxvisitorapp/features/new_site/views/new_site_page.dart';
import 'package:worxvisitorapp/features/visitor_kiosk/views/visitor_kiosk_page.dart';
import 'package:worxvisitorapp/features/visitor_sign_in/views/visitor_sign_in_page.dart';
import 'package:worxvisitorapp/features/visitor_sign_out/views/visitor_sign_out_page.dart';
import 'package:worxvisitorapp/features/visitor_deliveries/views/visitor_deliveries_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Worx Visitor Kiosk',
      theme: AppTheme.lightTheme,

      //initial route - Splash Screen checks auth
      initialRoute: '/',

      routes: {
        '/': (context) => const AuthPage(),
        AppRoutes.dashboard: (context) => const MainScaffold(),
        AppRoutes.newSite: (context) => const NewSitePage(),
        AppRoutes.visitorKiosk: (context) => const VisitorDashboard(),
        AppRoutes.visitorSignIn: (context) => const VisitorSignInPage(),
        AppRoutes.visitorSignOut: (context) => const VisitorSignOutPage(),
        AppRoutes.visitorDeliveries: (context) => const VisitorDeliveriesPage(),
      },
    );
  }
}
