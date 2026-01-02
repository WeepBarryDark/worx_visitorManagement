import 'package:flutter/material.dart';

class AppTheme {
  // ======== WORX SAFETY COLOR PALETTE ========
  // Primary colors - Worx Safety blue theme (Tailwind-inspired)
  static const Color _primaryBlue = Color(0xFF2563EB);      // Tailwind blue-600 - Main action buttons
  static const Color _primaryBlueDark = Color(0xFF1E40AF);  // Tailwind blue-700 - Hover/pressed state
  static const Color _primaryBlueLight = Color(0xFF3B82F6); // Tailwind blue-500 - Lighter variant

  // Worx Safety brand colors
  static const Color _worxGreen = Color(0xFF10B981);        // Tailwind emerald-500 - Success/Safety
  static const Color _worxOrange = Color(0xFFF59E0B);       // Tailwind amber-500 - Warning
  static const Color _worxRed = Color(0xFFEF4444);          // Tailwind red-500 - Danger/Error

  // Neutral colors - Slate palette (Tailwind)
  static const Color _slate50 = Color(0xFFF8FAFC);          // Lightest background
  static const Color _slate100 = Color(0xFFF1F5F9);         // Page background
  static const Color _slate200 = Color(0xFFE2E8F0);         // Border light
  static const Color _slate300 = Color(0xFFCBD5E1);         // Border default
  static const Color _slate400 = Color(0xFF94A3B8);         // Disabled text
  static const Color _slate500 = Color(0xFF64748B);         // Secondary text
  static const Color _slate600 = Color(0xFF475569);         // Body text
  static const Color _slate700 = Color(0xFF334155);         // Dark text
  static const Color _slate800 = Color(0xFF1E293B);         // Headings
  static const Color _slate900 = Color(0xFF0F172A);         // Darkest text

  // Surface colors
  static const Color _pageBg = _slate100;                   // Light gray page background
  static const Color _cardBg = Colors.white;                // White card background
  static const Color _border = _slate300;                   // Light gray border

  // Text colors
  static const Color _textMain = _slate800;                 // Main text color
  static const Color _textSub = _slate500;                  // Secondary text / icon color
  //static const Color _textDisabled = _slate400;             // Disabled text

  // Status colors (used for status indicators and pills)
  static const Color success = _worxGreen;
  static const Color warning = _worxOrange;
  static const Color danger = _worxRed;

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,

    // ======== COLOR SCHEME (Worx Safety Theme) ========
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: _primaryBlue,                                // Main action color
      onPrimary: Colors.white,                              // Text on primary
      secondary: _worxGreen,                                // Secondary/success accent
      onSecondary: Colors.white,                            // Text on secondary
      tertiary: _worxOrange,                                // Tertiary/warning accent
      onTertiary: Colors.white,                             // Text on tertiary
      surface: _cardBg,                                     // Card surfaces
      onSurface: _textMain,                                 // Text on surfaces
      //background: _pageBg,                                  // Page background (deprecated but kept for compatibility)
      //onBackground: _textMain,                              // Text on background
      error: danger,                                        // Error state
      onError: Colors.white,                                // Text on error
      primaryContainer: const Color(0xFFDCEAFF),            // Light blue container
      onPrimaryContainer: _primaryBlueDark,                 // Dark text on light blue
      secondaryContainer: const Color(0xFFD1FAE5),          // Light green container
      onSecondaryContainer: const Color(0xFF065F46),        // Dark green text
      tertiaryContainer: const Color(0xFFFEF3C7),           // Light orange container
      onTertiaryContainer: const Color(0xFF92400E),         // Dark orange text
      surfaceContainerHighest: _cardBg,                     // Highest elevation surface
      surfaceContainer: _cardBg,                            // Standard elevated surface
      outline: _border,                                     // Border color
      outlineVariant: _slate200,                            // Lighter border
      scrim: Colors.black54,                                // Modal overlay
      inverseSurface: _slate800,                            // Inverse surface (dark)
      inversePrimary: _primaryBlueLight,                    // Inverse primary
    ),
    scaffoldBackgroundColor: _pageBg,

    // ======== TYPOGRAPHY (Tailwind-inspired, clear hierarchy) ========
    textTheme: const TextTheme(
      // Display styles (large headings)
      displayLarge:  TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: _slate900, letterSpacing: -0.5),
      displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: _slate900, letterSpacing: -0.5),
      displaySmall:  TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: _slate900, letterSpacing: -0.25),

      // Headline styles
      headlineLarge:  TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _slate800, letterSpacing: -0.25),
      headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _slate800),
      headlineSmall:  TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _slate800),

      // Title styles (card headers, section titles)
      titleLarge:  TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _slate800, letterSpacing: 0),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _slate800),
      titleSmall:  TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _slate700),

      // Body text
      bodyLarge:  TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: _slate700, height: 1.5),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: _slate600, height: 1.5),
      bodySmall:  TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: _slate500, height: 1.5),

      // Label text (buttons, form labels)
      labelLarge:  TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.15),
      labelMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _slate700, letterSpacing: 0.1),
      labelSmall:  TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _slate600, letterSpacing: 0.1),
    ),

    // ======== APP BAR (flat, same color as page background) ========
    appBarTheme: const AppBarTheme(
      backgroundColor: _pageBg,
      foregroundColor: _textMain,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _textMain),
      toolbarTextStyle: TextStyle(color: _textMain),
      iconTheme: IconThemeData(color: _textSub),
    ),

    // ======== CARD (white, subtle border, Tailwind-style) ========
    cardTheme: CardThemeData(
      color: _cardBg,
      elevation: 0,                                         // Flat, no shadow
      shadowColor: Colors.transparent,                      // No shadow
      surfaceTintColor: Colors.transparent,                 // No tint
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),  // No horizontal margin (let parent control)
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),            // Tailwind rounded-xl
        side: const BorderSide(color: _slate200, width: 1), // Subtle border
      ),
    ),

    // ======== DIALOG & BOTTOM SHEET (rounded corners) ========
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: _cardBg,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: _cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),

    // ======== BUTTONS (Tailwind-inspired, Worx Safety style) ========
    // FilledButton - Primary action (solid blue, like "REPORT INCIDENT" button)
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _primaryBlue,                      // Solid blue background
        foregroundColor: Colors.white,                      // White text
        disabledBackgroundColor: _slate300,                 // Gray when disabled
        disabledForegroundColor: _slate400,                 // Lighter gray text when disabled
        elevation: 0,                                       // Flat design (no shadow)
        shadowColor: Colors.transparent,                    // No shadow
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),  // Tailwind-like padding
        minimumSize: const Size(0, 48),                     // Minimum touch target
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),           // Tailwind rounded-lg
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,                      // Semi-bold
          letterSpacing: 0.3,                               // Slight letter spacing
        ),
      ),
    ),

    // ElevatedButton - Alternative primary action (with subtle shadow)
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
        elevation: 1,                                       // Subtle shadow
        shadowColor: Colors.black12,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    ),

    // OutlinedButton - Secondary action (bordered, no fill)
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _primaryBlue,                      // Blue text
        disabledForegroundColor: _slate400,                 // Gray when disabled
        side: const BorderSide(color: _border, width: 1.5), // Border
        backgroundColor: Colors.white,                      // White background
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    ),

    // TextButton - Tertiary action (minimal, text only)
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _primaryBlue,
        disabledForegroundColor: _slate400,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        minimumSize: const Size(0, 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    ),

    // ======== INPUTS (Tailwind-inspired form inputs) ========
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,                              // White background
      hintStyle: const TextStyle(color: _slate400, fontSize: 14),  // Lighter hint text
      labelStyle: const TextStyle(color: _slate600, fontSize: 14, fontWeight: FontWeight.w500),
      floatingLabelStyle: const TextStyle(color: _primaryBlue, fontSize: 14, fontWeight: FontWeight.w600),
      helperStyle: const TextStyle(color: _slate500, fontSize: 12),
      errorStyle: const TextStyle(color: _worxRed, fontSize: 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),  // Comfortable padding
      prefixIconColor: _slate400,
      suffixIconColor: _slate400,
      // Default border
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),             // Tailwind rounded-lg
        borderSide: const BorderSide(color: _border, width: 1.5),
      ),
      // Enabled but not focused
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _slate300, width: 1.5),
      ),
      // Focused state (blue ring like Tailwind)
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _primaryBlue, width: 2),
      ),
      // Error state
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _worxRed, width: 1.5),
      ),
      // Focused error state
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _worxRed, width: 2),
      ),
      // Disabled state
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _slate200, width: 1.5),
      ),
    ),

    // ======== LIST TILE / SIDEBAR ========
    listTileTheme: ListTileThemeData(
      iconColor: _textSub,
      textColor: _textMain,
      dense: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      selectedColor: _primaryBlue,
      selectedTileColor: const Color(0xFFDCEAFF),           // Light blue for selected tile
    ),

    // ======== NAVIGATION RAIL (if used) ========
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: _slate50,
      selectedIconTheme: const IconThemeData(color: _primaryBlue),
      selectedLabelTextStyle: const TextStyle(color: _primaryBlue, fontWeight: FontWeight.w700),
      unselectedIconTheme: const IconThemeData(color: _textSub),
      unselectedLabelTextStyle: const TextStyle(color: _textSub),
      indicatorColor: Colors.white,
    ),

    // ======== DIVIDER (very light and subtle) ========
    dividerTheme: const DividerThemeData(
      color: Color(0xFFEDEDED),
      thickness: 1,
      space: 20,
    ),

    // ======== CHIP / TAG (Tailwind-style badges and pills) ========
    chipTheme: ChipThemeData(
      labelStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        color: _slate700,
        letterSpacing: 0.1,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      backgroundColor: _slate100,                           // Light background
      selectedColor: const Color(0xFFDCEAFF),               // Light blue when selected
      deleteIconColor: _slate500,
      side: BorderSide.none,                                // No border by default
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),             // Tailwind rounded-md
      ),
      elevation: 0,
      shadowColor: Colors.transparent,
    ),

    // ======== DATATABLE (web-like table with subtle borders) ========
    dataTableTheme: DataTableThemeData(
      headingRowColor: WidgetStateProperty.all(const Color(0xFFF9F9F9)),
      headingTextStyle: const TextStyle(
        fontWeight: FontWeight.w700, color: _textMain, fontSize: 13.5),
      dataTextStyle: const TextStyle(color: _textMain, fontSize: 13.5),
      dividerThickness: 1,
      decoration: BoxDecoration(
        color: _cardBg,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(14),
      ),
    ),

    // ======== ICONS ========
    iconTheme: const IconThemeData(color: _textSub),
  );

  // ======== WORX SAFETY COLOR HELPERS ========
  // Public accessors for Worx Safety colors (for use in widgets)

  // Primary colors
  static Color get primaryBlue => _primaryBlue;
  static Color get primaryBlueDark => _primaryBlueDark;
  static Color get primaryBlueLight => _primaryBlueLight;

  // Brand colors
  static Color get worxGreen => _worxGreen;
  static Color get worxOrange => _worxOrange;
  static Color get worxRed => _worxRed;

  // Slate colors (useful for custom components)
  static Color get slate50 => _slate50;
  static Color get slate100 => _slate100;
  static Color get slate200 => _slate200;
  static Color get slate300 => _slate300;
  static Color get slate400 => _slate400;
  static Color get slate500 => _slate500;
  static Color get slate600 => _slate600;
  static Color get slate700 => _slate700;
  static Color get slate800 => _slate800;
  static Color get slate900 => _slate900;

  // Status colors (public)
  static Color get successColor => success;
  static Color get warningColor => warning;
  static Color get dangerColor => danger;

  // ======== UTILITY METHODS ========

  /// Get a status color with optional opacity
  static Color statusColor(String status, {double opacity = 1.0}) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'active':
      case 'completed':
        return success.withValues(alpha:opacity);
      case 'warning':
      case 'pending':
      case 'in_progress':
        return warning.withValues(alpha:opacity);
      case 'error':
      case 'failed':
      case 'danger':
      case 'inactive':
        return danger.withValues(alpha:opacity);
      default:
        return _slate500.withValues(alpha:opacity);
    }
  }

  /// Get a light status background color for containers
  static Color statusBackgroundColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'active':
      case 'completed':
        return const Color(0xFFD1FAE5);  // Light green
      case 'warning':
      case 'pending':
      case 'in_progress':
        return const Color(0xFFFEF3C7);  // Light yellow
      case 'error':
      case 'failed':
      case 'danger':
      case 'inactive':
        return const Color(0xFFFEE2E2);  // Light red
      default:
        return _slate100;                // Light gray
    }
  }
}
