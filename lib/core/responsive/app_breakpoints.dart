/// Responsive breakpoints and content width constants
/// Used for responsive layouts and max-width constraints
class AppBreakpoints {
  AppBreakpoints._(); // Prevent instantiation

  // ========== SCREEN SIZE BREAKPOINTS ==========
  // Device breakpoints for responsive behavior
  static const double md = 600;   // Tablet portrait
  static const double lg = 1000;  // Tablet landscape / Small desktop
  static const double xl = 1440;  // Large desktop

  // ========== CONTENT MAX WIDTHS ==========
  // Maximum widths for centered content containers
  static const double compact = 420.0;   // Kiosk buttons, simple forms
  static const double standard = 620.0;  // Visitor forms
  static const double wide = 720.0;      // Dashboard, admin pages
  static const double max = 1200.0;      // Full desktop content

  // ========== HELPER METHODS ==========
  /// Get appropriate max width based on screen size
  static double getContentWidth(double screenWidth) {
    if (screenWidth < md) return compact;
    if (screenWidth < lg) return standard;
    if (screenWidth < xl) return wide;
    return max;
  }

  /// Check if screen is small (mobile)
  static bool isSmallScreen(double screenWidth) => screenWidth < md;

  /// Check if screen is medium (tablet portrait)
  static bool isMediumScreen(double screenWidth) => screenWidth >= md && screenWidth < lg;

  /// Check if screen is large (tablet landscape / desktop)
  static bool isLargeScreen(double screenWidth) => screenWidth >= lg;

  /// Get dialog width for responsive dialogs
  static double getDialogWidth(double screenWidth) {
    if (isSmallScreen(screenWidth)) {
      return screenWidth * 0.95; // 95% on mobile
    }
    return 500.0; // Fixed width on larger screens
  }

  /// Get dialog max width
  static double getDialogMaxWidth(double screenWidth) {
    return isSmallScreen(screenWidth) ? screenWidth * 0.95 : 600.0;
  }

  /// Get dialog height (70% of screen height)
  static double getDialogHeight(double screenHeight) {
    return screenHeight * 0.7;
  }
}