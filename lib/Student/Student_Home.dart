import 'package:flutter/material.dart';
import 'package:awesome_bottom_bar/awesome_bottom_bar.dart';
import 'package:lmsv2/Student/Profile.dart';
import 'package:lmsv2/Student/student_notification.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../provider/student_provider.dart';
import 'Attendance/Overall_Attendance.dart';
import 'Dashboard/Student_Main_AcedamciReport.dart';
import 'Dashboard/Student_Main_CourseContent.dart';
import 'Dashboard/Student_Main_DueTaskTab.dart';
import 'Dashboard/Student_Main_Home.dart';
import 'Dashboard/Stundet_Main_Timetable.dart';

class DashboardTheme {
  // Color Palette
  static const Color primaryColor = Color(0xFF4B39EF);
  static const Color secondaryColor = Color(0xFFEE8B60);
  static const Color tertiaryColor = Color(0xFFFFE8DF);
  static const Color alternateColor = Color(0xFFF1F4F8);
  static const Color primaryTextColor = Color(0xFF101213);
  static const Color secondaryTextColor = Color(0xFF57636C);
  static const Color primaryBackgroundColor = Color(0xFFF1F4F8);
  static const Color secondaryBackgroundColor = Color(0xFFFFFFFF);

  // Text Styles
  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: primaryTextColor,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: primaryTextColor,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: primaryTextColor,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: secondaryTextColor,
  );

  // Card Styles
  static BoxDecoration noticeBoardDecoration = BoxDecoration(
    color: secondaryBackgroundColor,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 6,
        offset: const Offset(0, 2),
      )
    ],
  );

  static BoxDecoration courseCardDecoration = BoxDecoration(
    color: secondaryBackgroundColor,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ],
  );

  // Theme Data
  static ThemeData get themeData {
    return ThemeData(
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: secondaryBackgroundColor,
        background: primaryBackgroundColor,
      ),
      scaffoldBackgroundColor: primaryBackgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryBackgroundColor,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: titleLarge,
        iconTheme: IconThemeData(color: primaryTextColor),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: secondaryBackgroundColor,
      ),
      textTheme: const TextTheme(
        headlineSmall: titleLarge,
        titleLarge: titleMedium,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
      ),
    );
  }
}


class StudentHome extends StatefulWidget {
  const StudentHome({Key? key}) : super(key: key);

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: DashboardTheme.themeData,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('LMS'),
          actions: [
            IconButton(
              icon: Stack(
                children: [
                  Icon(Icons.notifications,
                      color: DashboardTheme.primaryTextColor),
                  Positioned(
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: DashboardTheme.secondaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: const Text(
                        '3',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context)=>AttendanceOverviewScreen()));
              },
            ),
          ],
        ),
        body: _buildCurrentTab(),
        bottomNavigationBar: BottomBarCreative(
          items: const [
            TabItem(icon: Icons.home, title: 'Home'),
            TabItem(icon: Icons.library_books, title: 'Courses'),
            TabItem(icon: Icons.assignment, title: 'Tasks'),
            TabItem(icon: Icons.assessment, title: 'Grades'),
            TabItem(icon: Icons.schedule, title: 'Schedule'),
          ],
          backgroundColor: DashboardTheme.secondaryBackgroundColor,
          color: DashboardTheme.secondaryTextColor,
          colorSelected: DashboardTheme.primaryColor,
          indexSelected: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          highlightStyle: HighlightStyle(
            sizeLarge: true,
            background: DashboardTheme.primaryColor.withOpacity(0.1),
            elevation: 0,
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_currentIndex) {
      case 0:
        return const HomeTab();
      case 1:
        return CourseContentTab();
      case 2:
        return DueTaskTab();
      case 3:
        return AcademicReportTab();
      case 4:
        return TimetableTab();

    // Add other cases for your tabs
      default:
        return const Center(child: Text('Coming Soon'));
    }
  }
}