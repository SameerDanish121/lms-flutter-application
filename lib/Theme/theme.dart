import 'package:flutter/material.dart';

class AppTheme {
  // Color Scheme
  static const Color primaryColor = Color(0xFF1565C0);
  static const Color backgroundColor = Color(0xFFF5F7FA); // Light grey-blue background
  static const Color cardColor = Color(0xFFE3F2FD); // Very light blue cards
  static const Color textColor = Color(0xFF263238); // Dark blue-grey text
  static const Color secondaryTextColor = Color(0xFF546E7A); // Medium blue-grey text
  static const Color iconColor = Color(0xFF1565C0); // Primary color for icons
  static const Color dividerColor = Color(0xFFB0BEC5); // Light divider color
  // #4E6AEB MAIN HEADER ,
  //#F0F3FF BACK
  //BUTTONS #3C51B4
  //tEXT #303133
  // Text Styles
  static const TextStyle headingStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textColor,
  );

  static const TextStyle subHeadingStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: secondaryTextColor,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 14,
    color: textColor,
  );

  static const TextStyle captionStyle = TextStyle(
    fontSize: 12,
    color: secondaryTextColor,
  );

  // Card Theme
  static CardTheme cardTheme = CardTheme(
    color: cardColor,
    elevation: 0,
    margin: EdgeInsets.all(8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(
        color: primaryColor.withOpacity(0.2),
        width: 1,
      ),
    ),
  );

  // AppBar Theme
  static AppBarTheme appBarTheme = AppBarTheme(
    color: primaryColor,
    elevation: 0,
    titleTextStyle: headingStyle.copyWith(color: Colors.white),
    iconTheme: IconThemeData(color: Colors.white),
  );

  // Input Decoration Theme
  static InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
    filled: true,
    fillColor: primaryColor.withOpacity(0.05),
    contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: primaryColor, width: 1),
    ),
    hintStyle: captionStyle.copyWith(color: secondaryTextColor.withOpacity(0.6)),
  );

  // Button Theme
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    textStyle: bodyStyle.copyWith(fontWeight: FontWeight.w500),
  );

  // Full Theme Data
  static ThemeData get themeData {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      cardTheme: cardTheme,
      appBarTheme: appBarTheme,
      inputDecorationTheme: inputDecorationTheme,
      textTheme: TextTheme(
        displayLarge: headingStyle,
        displayMedium: subHeadingStyle,
        bodyLarge: bodyStyle,
        bodyMedium: bodyStyle,
        bodySmall: captionStyle,
      ),
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        surface: cardColor,
        background: backgroundColor,
      ),
    );
  }
}