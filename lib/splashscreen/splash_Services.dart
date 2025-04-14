
import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lmsv2/api/ApiConfig.dart';
import 'package:lmsv2/auth/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../JuniorLecturer/Junior_Home.dart';
import '../Student/Student_Home.dart';
import '../alerts/custom_alerts.dart';
import '../provider/instructor_provider.dart';
import '../provider/student_provider.dart';
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
      if(prefs.containsKey('apiBaseUrl')){
        var n=prefs.getString('apiBaseUrl') as String;
        ApiConfig.apiBaseUrl=n;
      }
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

        CustomAlert.loading(context, 'Auto-Login', 'Validating saved login credentials. Please wait...');
        // Try to login with stored credentials
        final response = await http.get(
          Uri.parse('${ApiConfig.apiBaseUrl}remember').replace(
            queryParameters: {
              'username': username,
              'password': password,
            },
          ),
        ).timeout(Duration(seconds: 20)); // Add timeout to prevent indefinite waiting
        Navigator.pop(context);
        CustomAlert.loading(context, 'Auto-login', 'sameer danish');
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final userType = data['Type'];

          // Navigate based on user type
          switch (userType) {
            case 'Student':
              final studentProvider = Provider.of<StudentProvider>(context, listen: false);
              studentProvider.setStudent('student', data);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => StudentHome()),
              );
              return; // Exit early, we've navigated to the right screen
            case 'Teacher':
              Provider.of<InstructorProvider>(context, listen: false)
                  .setInstructor("Teacher", data['TeacherInfo']);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => TeacherHome()),
              );
              return; // Exit early
            case 'JuniorLecturer':
              Provider.of<InstructorProvider>(context, listen: false)
                  .setInstructor("Junior", data['TeacherInfo']);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => JuniorHome()),
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