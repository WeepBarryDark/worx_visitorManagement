class AppRoutes {
  //AppRoutes._(); // Prevents instantiation

  static const String login= '/';
  static const String dashboard ='/dashboard'; //admin adshboard
  static const String newSite = '/new-site';//select another site
  static const String visitorKiosk = '/visitor-kiosk'; //entry point of visitor kiosk

  //visitor sign in option
  static const String visitorSignIn = '/visitor-sign-in'; 
  static const String visitorSignOut = '/visitor-sign-out';
  static const String visitorDeliveries = '/delivery';
  static const String contractorSignIn = '/contractor-sign-in';
  static const String reprintBadge = '/reprint-badge'; //reprint badge for print issue or uploaded user from server not kiosk
}


