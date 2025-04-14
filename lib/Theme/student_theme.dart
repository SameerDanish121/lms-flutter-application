import 'package:flutter/material.dart';

class StudentTheme {
  // Colors
  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color secondaryColor = Color(0xFF4A45B1);
  static const Color accentColor = Color(0xFFFF6584);
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color cardColor = Colors.white;
  static const Color textColor = Color(0xFF333333);
  static const Color lightTextColor = Color(0xFF666666);
  static const Color dividerColor = Color(0xFFEEEEEE);

  // Text Styles
  static const TextStyle appBarTitleStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle sectionTitleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );

  static const TextStyle cardTitleStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textColor,
  );

  static const TextStyle cardSubtitleStyle = TextStyle(
    fontSize: 14,
    color: lightTextColor,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  // Theme Data
  static ThemeData get themeData {
    return ThemeData(
        primaryColor: primaryColor,
        colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        surface: cardColor,
        background: backgroundColor,
    ),
    scaffoldBackgroundColor: backgroundColor,
    appBarTheme: AppBarTheme(
    backgroundColor: primaryColor,
    centerTitle: true,
    elevation: 0,
    titleTextStyle: appBarTitleStyle,
    iconTheme: const IconThemeData(color: Colors.white),
    ),
    cardTheme: CardTheme(
    color: cardColor,
    elevation: 4,
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(15),),
    margin: const EdgeInsets.all(0),
    ),
    dividerTheme: const DividerThemeData(
    color: dividerColor,
    thickness: 1,
    space: 20,
    ),
      textTheme: const TextTheme(
        titleLarge: sectionTitleStyle,
        titleMedium: cardTitleStyle,
        titleSmall: cardSubtitleStyle,
        bodyLarge: TextStyle(fontSize: 16, color: textColor),
        bodyMedium: TextStyle(fontSize: 14, color: lightTextColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(10),
    ),
    textStyle: buttonTextStyle,
    ),
    ),
    inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: primaryColor, width: 1.5),
    ),
    ),
    );
  }

  // Custom Widget Styles
  static BoxDecoration profileHeaderDecoration = BoxDecoration(
    color: primaryColor,
    borderRadius: BorderRadius.circular(15),
    boxShadow: [
      BoxShadow(
        color: primaryColor.withOpacity(0.2),
        blurRadius: 10,
        offset: const Offset(0, 5),
      ),
    ],
  );

  static BoxDecoration editIconDecoration = BoxDecoration(
    color: accentColor,
    shape: BoxShape.circle,
    border: Border.all(color: Colors.white, width: 2),
  );

  static BoxDecoration avatarDecoration = BoxDecoration(
    shape: BoxShape.circle,
    border: Border.all(color: Colors.white, width: 3),
  );
}