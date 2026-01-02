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
}