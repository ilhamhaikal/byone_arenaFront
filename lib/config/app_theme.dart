import 'package:flutter/material.dart';

// ByOne Arena — brand palette
const Color kDeepBlack    = Color(0xFF050507);
const Color kPrimaryBlue  = Color(0xFF2979FF);
const Color kAccentPurple = Color(0xFF7C3AED);
const Color kNeonPink     = Color(0xFFEC4899);
const Color kNintendoRed  = Color(0xFFEF4444);
const Color kSilverWhite  = Color(0xFFF1F5F9);

// Semantic aliases
const Color kPrimaryColor   = kDeepBlack;
const Color kSecondaryColor = Color(0xFF0A0A0F);
const Color kAccentColor    = Color(0xFF0F0F1A);
const Color kHighlightColor = kPrimaryBlue;
const Color kBrandPurple    = kAccentPurple;
const Color kBrandPink      = kNeonPink;
const Color kBrandCyan      = kPrimaryBlue;
const Color kSuccessColor   = Color(0xFF10B981);
const Color kWarningColor   = Color(0xFFF59E0B);
const Color kErrorColor     = kNintendoRed;
const Color kCardColor      = Color(0xFF0F0F1A);
const Color kSurface        = Color(0xFF12121F);
const Color kTextPrimary    = kSilverWhite;
const Color kTextSecondary  = Color(0xFF64748B);
const Color kDividerColor   = Color(0xFF1E2040);
const Color kBorderColor    = Color(0xFF1E2040);

// Gradient helpers
const LinearGradient kGradientBlue = LinearGradient(
  colors: [Color(0xFF2979FF), Color(0xFF1565C0)],
  begin: Alignment.topLeft, end: Alignment.bottomRight,
);
const LinearGradient kGradientPurple = LinearGradient(
  colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
  begin: Alignment.topLeft, end: Alignment.bottomRight,
);
const LinearGradient kGradientPink = LinearGradient(
  colors: [Color(0xFFEC4899), Color(0xFF9D174D)],
  begin: Alignment.topLeft, end: Alignment.bottomRight,
);
const LinearGradient kGradientBrand = LinearGradient(
  colors: [Color(0xFF2979FF), Color(0xFF7C3AED), Color(0xFFEC4899)],
  begin: Alignment.topLeft, end: Alignment.bottomRight,
);
const LinearGradient kGradientGreen = LinearGradient(
  colors: [Color(0xFF10B981), Color(0xFF059669)],
  begin: Alignment.topLeft, end: Alignment.bottomRight,
);
const LinearGradient kGradientAmber = LinearGradient(
  colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
  begin: Alignment.topLeft, end: Alignment.bottomRight,
);

ThemeData appTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: kHighlightColor,
      secondary: kBrandPurple,
      surface: kSurface,
      error: kErrorColor,
    ),
    scaffoldBackgroundColor: kPrimaryColor,
    fontFamily: 'Poppins',
    appBarTheme: const AppBarTheme(
      backgroundColor: kSecondaryColor,
      foregroundColor: kTextPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: kTextPrimary,
      ),
    ),
    cardTheme: CardThemeData(
      color: kCardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: kBorderColor, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimaryBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kTextPrimary,
        side: const BorderSide(color: kBorderColor),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500, fontSize: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: kPrimaryBlue,
        textStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kCardColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kBorderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kHighlightColor, width: 1.5),
      ),
      labelStyle: const TextStyle(color: kTextSecondary),
      hintStyle: const TextStyle(color: kTextSecondary, fontSize: 14),
      prefixIconColor: kTextSecondary,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 28),
      headlineMedium: TextStyle(color: kTextPrimary, fontWeight: FontWeight.w600, fontSize: 22),
      headlineSmall: TextStyle(color: kTextPrimary, fontWeight: FontWeight.w600, fontSize: 18),
      titleLarge: TextStyle(color: kTextPrimary, fontWeight: FontWeight.w600, fontSize: 16),
      titleMedium: TextStyle(color: kTextPrimary, fontWeight: FontWeight.w500, fontSize: 14),
      bodyLarge: TextStyle(color: kTextPrimary, fontSize: 15),
      bodyMedium: TextStyle(color: kTextSecondary, fontSize: 13),
      labelSmall: TextStyle(color: kTextSecondary, fontSize: 11),
    ),
    dividerColor: kDividerColor,
    dialogTheme: DialogThemeData(
      backgroundColor: kSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: kBorderColor),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? kSuccessColor : kTextSecondary),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? kSuccessColor.withAlpha(80)
              : kBorderColor),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: kCardColor,
      side: const BorderSide(color: kBorderColor),
      labelStyle: const TextStyle(color: kTextSecondary, fontSize: 12, fontFamily: 'Poppins'),
      selectedColor: kPrimaryBlue.withAlpha(40),
      checkmarkColor: kPrimaryBlue,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: kSurface,
      contentTextStyle: TextStyle(color: kTextPrimary, fontFamily: 'Poppins'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
      behavior: SnackBarBehavior.floating,
    ),
    popupMenuTheme: const PopupMenuThemeData(
      color: kSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        side: BorderSide(color: kBorderColor),
      ),
      textStyle: TextStyle(color: kTextPrimary, fontFamily: 'Poppins', fontSize: 14),
    ),
    tabBarTheme: const TabBarThemeData(
      indicatorColor: kHighlightColor,
      labelColor: kHighlightColor,
      unselectedLabelColor: kTextSecondary,
      labelStyle: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13),
      unselectedLabelStyle: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.normal, fontSize: 13),
    ),
  );
}
