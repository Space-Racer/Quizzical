// app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Define the colors from your HTML CSS variables
class AppColors {
  static const Color primaryBlue = Color(0xFF6A057F); // Deep Purple
  static const Color secondaryPurple = Color(0xFF8B5FBF); // Lighter Purple
  static const Color accentPink = Color(0xFFF72585); // Vibrant Pink
  static const Color accentGreen = Color(0xFF2ecc71); // Success Green
  static const Color accentRed = Color(0xFFe74c3c);
  static const Color accentOrange = Color(0xffea853e);
  static const Color backgroundGradientStart = Color(0xFFD8BFD8); // Light Plum
  static const Color backgroundGradientEnd = Color(0xFFBA55D3); // Medium Orchid
  static const Color textDark = Color(0xFF333333); // Dark text
  static const Color textLight = Color(0xFFF9F9F9); // Light text
  static const Color cardBackground = Color(0xF2FFFFFF); // rgba(255, 255, 255, 0.95)
  static const Color googleBlue = Color(0xFF4285F4); // Google Blue
  static const Color dividerColor = Color(0xFFE0E0E0); // A light grey, common for dividers/borders
}

// Define common border radii
class AppBorderRadius {
  static const BorderRadius large = BorderRadius.all(Radius.circular(25.0));
  static const BorderRadius small = BorderRadius.all(Radius.circular(15.0));
  static const BorderRadius extraSmall = BorderRadius.all(Radius.circular(8.0));
}

// Define common box shadows
class AppShadows {
  static List<BoxShadow> light = [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
  static List<BoxShadow> heavy = [
    BoxShadow(
      color: Colors.black.withOpacity(0.25),
      blurRadius: 25,
      offset: const Offset(0, 12),
    ),
  ];
}

final ThemeData appTheme = ThemeData(
  primaryColor: AppColors.primaryBlue,
  colorScheme: const ColorScheme.light(
    primary: AppColors.primaryBlue,
    secondary: AppColors.accentPink, // Used for accent colors
    surface: AppColors.cardBackground, // Card backgrounds
    onSurface: AppColors.textDark, // Text on card backgrounds
    onPrimary: AppColors.textLight, // Text on primary colored elements
    error: AppColors.accentRed,
  ),
  scaffoldBackgroundColor: Colors.transparent, // Allow body gradient to show

  // Text Themes
  textTheme: TextTheme(
    displayLarge: GoogleFonts.balsamiqSans(
      fontSize: 4.0 * 16, // 4em
      color: AppColors.primaryBlue,
      shadows: [
        Shadow(
          offset: const Offset(2, 2),
          blurRadius: 4.0,
          color: Colors.black.withOpacity(0.1),
        ),
      ],
    ),
    headlineMedium: GoogleFonts.balsamiqSans(
      fontSize: 2.5 * 16, // 2.5em for app header
      color: AppColors.textLight,
      letterSpacing: 2,
      shadows: [
        Shadow(
          offset: const Offset(2, 2),
          blurRadius: 4.0,
          color: Colors.black.withOpacity(0.2),
        ),
      ],
    ),
    headlineSmall: GoogleFonts.poppins(
      fontSize: 2.2 * 16, // 2.2em for section titles
      color: AppColors.primaryBlue,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: GoogleFonts.poppins(
      fontSize: 1.1 * 16, // 1.1em for labels/inputs
      color: AppColors.textDark,
    ),
    bodyMedium: GoogleFonts.poppins(
      fontSize: 1.0 * 16, // 1em for general text
      color: AppColors.textDark,
    ),
    labelLarge: GoogleFonts.poppins(
      fontSize: 1.2 * 16, // 1.2em for buttons
      fontWeight: FontWeight.w600,
      color: AppColors.textLight,
    ),
  ),

  // Input Field Decoration Theme
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white.withOpacity(0.9), // Slightly transparent white
    contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
    border: OutlineInputBorder(
      borderRadius: AppBorderRadius.extraSmall, // 8px
      borderSide: const BorderSide(color: AppColors.secondaryPurple, width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: AppBorderRadius.extraSmall,
      borderSide: const BorderSide(color: AppColors.secondaryPurple, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: AppBorderRadius.extraSmall,
      borderSide: const BorderSide(color: AppColors.accentPink, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: AppBorderRadius.extraSmall,
      borderSide: const BorderSide(color: AppColors.accentRed, width: 2),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: AppBorderRadius.extraSmall,
      borderSide: const BorderSide(color: AppColors.accentRed, width: 2),
    ),
    labelStyle: GoogleFonts.poppins(
      fontWeight: FontWeight.w600,
      color: AppColors.primaryBlue,
      fontSize: 1.1 * 16,
    ),
    hintStyle: GoogleFonts.poppins(
      color: AppColors.textDark.withOpacity(0.6),
      fontSize: 1.1 * 16,
    ),
    prefixIconColor: AppColors.primaryBlue,
  ),

  // Button Themes
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.accentPink, // Default button background
      foregroundColor: AppColors.textLight, // Default button text color
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 18),
      shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.small), // 15px
      elevation: 5,
      shadowColor: Colors.black.withOpacity(0.15),
      textStyle: GoogleFonts.poppins(
        fontSize: 1.2 * 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primaryBlue,
      textStyle: GoogleFonts.poppins(
        fontSize: 16,
        decoration: TextDecoration.underline,
      ),
    ),
  ),

  // AppBar Theme
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.primaryBlue,
    foregroundColor: AppColors.textLight,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: GoogleFonts.poppins(
      fontSize: 1.5 * 16, // Adjust as needed
      fontWeight: FontWeight.w600,
      color: AppColors.textLight,
    ),
  ),
);
