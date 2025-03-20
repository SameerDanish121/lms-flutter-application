
import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lmsv2/api/ApiConfig.dart';
import 'package:lmsv2/auth/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../JuniorLecturer/Junior_Home.dart';
import '../Student/Student_Home.dart';
import '../alerts/custom_alerts.dart';
import '../teacher/Teacher_Home.dart';
class SplashServices{
  Future<void> isLogin(BuildContext context) async {
    // First try to get stored credentials
    bool hasCredentials = false;
    String? username;
    String? password;
    await Future.delayed(Duration(seconds: 6));
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool('rememberMe') ?? false;

      if (rememberMe) {
        username = prefs.getString('username');
        password = prefs.getString('password');

        // Check if we have both username and password
        if (username != null && username.isNotEmpty &&
            password != null && password.isNotEmpty) {
          hasCredentials = true;
        }
      }
    } catch (e) {
      print('Warning: Could not retrieve saved credentials: ${e.toString()}');
      // Continue to login page if there's an error
      hasCredentials = false;
    }

    // If we have credentials, try to auto-login
    if (hasCredentials) {
      try {
        CustomAlert.loading(context, 'Auto-login', 'Please Wait While , we validate your old data');
        // Try to login with stored credentials
        final response = await http.get(
          Uri.parse('${ApiConfig.apiBaseUrl}remember').replace(
            queryParameters: {
              'username': username,
              'password': password,
            },
          ),
        ).timeout(Duration(seconds: 10)); // Add timeout to prevent indefinite waiting

        // Close loading dialog
        Navigator.pop(context);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final userType = data['Type'];

          // Navigate based on user type
          switch (userType) {
            case 'Student':
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => StudentHome(studentData: data['StudentInfo'])),
              );
              return; // Exit early, we've navigated to the right screen
            case 'Teacher':
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => TeacherHome(teacherData: data['TeacherInfo'])),
              );
              return; // Exit early
            case 'JuniorLecturer':
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => JuniorHome(juniorData: data['TeacherInfo'])),
              );
              return; // Exit early
            default:
            // Unknown user type, will fall through to the login page
              break;
          }
        }
      } catch (e) {
        // Close loading dialog if it's showing
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        print('Auto-login failed: ${e.toString()}');
        // Continue to login page on error
      }
    }

    // If auto-login failed or no credentials, go to login page

        Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => Login())
        );
  }
}