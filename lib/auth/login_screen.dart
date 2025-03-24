import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:lmsv2/alerts/custom_alerts.dart';
import 'package:lmsv2/api/api_services.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../JuniorLecturer/Junior_Home.dart';
import '../Student/Student_Home.dart';
import '../api/ApiConfig.dart';
import '../dev/developer_options.dart';
import '../provider/instructor_provider.dart';
import '../teacher/Teacher_Home.dart';
import 'package:provider/provider.dart';
import 'ForgotPassword/RecoveryEmail.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool _rememberMe = false;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkRememberedCredentials();
  }
  Future<void> _checkRememberedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('rememberMe') ?? false;

    if (rememberMe) {
      setState(() {
        _rememberMe = true;
        _usernameController.text = prefs.getString('username') ?? '';
        _passwordController.text = prefs.getString('password') ?? '';
      });
    }
  }
  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rememberMe', _rememberMe);

    if (_rememberMe) {
      await prefs.setString('username', _usernameController.text);
      await prefs.setString('password', _passwordController.text);
    } else {
      // Clear stored credentials if remember me is unchecked
      await prefs.remove('username');
      await prefs.remove('password');
    }
  }
  void handleRoleNavigation(BuildContext context, String role, Map<String, dynamic> data) {
    int userId = data['TeacherInfo']['user_id'];
    String otpValue = '';
    bool isLoading = false;
    // Start 5-minute countdown timer
    int timeLeft = 300; // 5 minutes in seconds
    Timer? countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      timeLeft--;
      if (timeLeft <= 0) {
        timer.cancel();
        // Close any open QuickAlert if timer expires
        Navigator.of(context).popUntil((route) => route.isFirst);
        // Show expired message
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          title: 'OTP Expired',
          text: 'Verification code has expired. Please login again.',
          confirmBtnText: 'Return to Login',
          onConfirmBtnTap: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => Login()),
                  (route) => false,
            );
          },
        );
      }
    });
    String formatTime(int seconds) {
      int minutes = seconds ~/ 60;
      int remainingSeconds = seconds % 60;
      return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    }
    QuickAlert.show(
      context: context,
      type: QuickAlertType.custom,
      barrierDismissible: false,
      confirmBtnText: 'Verify',
      customAsset: 'assets/two_factor.png', // Use an appropriate verification animation
      title: 'Two-Step Verification',
      text: 'Enter the verification code ',
      widget: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Timer display
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(0xFFE6F0FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: StatefulBuilder(
                  builder: (context, setState) {
                    Timer.periodic(Duration(seconds: 1), (timer) {
                      setState(() {});
                      if (timeLeft <= 0) timer.cancel();
                    });

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timer, size: 16, color: Color(0xFF3969D7)),
                        SizedBox(width: 4),
                        Text(
                          'Expires in: ${formatTime(timeLeft)}',
                          style: TextStyle(color: Color(0xFF3969D7)),
                        ),
                      ],
                    );
                  },
                ),
              ),
              SizedBox(height: 10),
              // OTP Input field
              TextFormField(
                decoration: InputDecoration(
                  alignLabelWithHint: true,
                  hintText: 'Enter OTP',
                  prefixIcon: Icon(Icons.lock_outlined),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                ),
                textAlign: TextAlign.center,
                textInputAction: TextInputAction.done,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                onChanged: (value) => otpValue = value,
              ),
            ],
          ),
        ),
      ),

      // Just keep backgroundColor
      backgroundColor: Colors.white,
      onConfirmBtnTap: () async {
        try {
          // Validate OTP
          if (otpValue.isEmpty) {
            QuickAlert.show(
              context: context,
              type: QuickAlertType.error,
              text: 'Please enter the verification code',
            );
            return;
          }
          // Show loading state
          Navigator.pop(context);
          QuickAlert.show(
            context: context,
            type: QuickAlertType.loading,
            title: 'Verifying',
            text: 'Please wait...',
          );

          // Call API to verify OTP
          final response = await ApiServices.verifyLoginOTP(
            userId,
            int.parse(otpValue),
          );

          // Close loading dialog
          Navigator.pop(context);

          // Handle verification result
          if (response['status'] == 'success') {
            // Cancel the timer
            countdownTimer?.cancel();

            // Show success message
            QuickAlert.show(
              context: context,
              type: QuickAlertType.success,
              text: 'Verification successful!',
              autoCloseDuration: Duration(seconds: 2),
            );

            // Wait for alert to close
            await Future.delayed(Duration(seconds: 2));

            // Navigate based on role
            if (role == 'Teacher') {
              ApiServices.storeFcmTokens(userId);

              // Store the data in InstructorProvider
              Provider.of<InstructorProvider>(context, listen: false)
                  .setInstructor("Teacher", data['TeacherInfo']);

              // Navigate without passing params
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const TeacherHome()),
                    (route) => false,
              );
            } else if (role == 'JuniorLecturer') {
              ApiServices.storeFcmTokens(userId);

              Provider.of<InstructorProvider>(context, listen: false)
                  .setInstructor("Junior", data['TeacherInfo']);

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const JuniorHome()),
                    (route) => false,
              );
            }
          } else {
            // Show error message
            QuickAlert.show(
              context: context,
              type: QuickAlertType.error,
              title: 'Verification Failed',
              text: response['message'] ?? 'Invalid OTP. Please try again.',
              confirmBtnText: 'Try Again',
              onConfirmBtnTap: () {
                // Show OTP dialog again
                Navigator.pop(context);  // Close current dialog
                handleRoleNavigation(context, role, data);
              },
            );
          }
        } catch (e) {
          // Close loading dialog if open
          Navigator.of(context).pop();

          // Show error message
          QuickAlert.show(
            context: context,
            type: QuickAlertType.error,
            title: 'Error',
            text: 'An unexpected error occurred: ${e.toString()}',
            confirmBtnText: 'Try Again',
            onConfirmBtnTap: () {
              // Show OTP dialog again
              Navigator.pop(context);  // Close current dialog
              handleRoleNavigation(context, role, data);
            },
          );
        }
      },
      cancelBtnText: 'Cancel',
      showCancelBtn: true,
      onCancelBtnTap: () {
        // Cancel the timer
        countdownTimer?.cancel();

        // Navigate back to login
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => Login()),
              (route) => false,
        );
      },
    );
    // Login function
  }
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.apiBaseUrl}Login').replace(
          queryParameters: {
            'username': _usernameController.text,
            'password': _passwordController.text,
          },
        ),
      );
      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Save credentials if remember me is checked
        await _saveCredentials();

        // Navigate based on user type
        final userType = data['Type'];

        switch (userType) {
          case 'Student':
            ApiServices.storeFcmTokens(data['StudentInfo']['user_id']);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => StudentHome(studentData: data['StudentInfo'])),
            );
            break;
          case 'Teacher':
            handleRoleNavigation(context, 'Teacher', {'TeacherInfo': data['TeacherInfo']});

            break;
          case 'JuniorLecturer':
            handleRoleNavigation(context, 'JuniorLecturer', {'TeacherInfo': data['TeacherInfo']});
            break;
          default:
            CustomAlert.error(context,'Login Failed','Please Enter Valid Username and Password !');
        }
      } else {
        CustomAlert.error(context,'Login Failed','Please Enter Valid Username and Password !');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      CustomAlert.error(context,'Connection error','${e.toString()}');
    }
  }
  void _showPasswordDialog(BuildContext context) {
    String password = '';
    QuickAlert.show(
      context: context,
      type: QuickAlertType.custom,
      barrierDismissible: false,
      title: 'Developer Access',
      customAsset: 'assets/developer.jpg', // For the developer photo
      widget: TextField(
        obscureText: true,
        onChanged: (value) => password = value,
        decoration: InputDecoration(
          hintText: 'Enter Password',
          hintStyle: TextStyle(color: Colors.grey[600]),
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
      confirmBtnText: 'Submit',
      cancelBtnText: 'Cancel',
      confirmBtnColor: Color(0xFF3969D7),
      onConfirmBtnTap: () {
        if (password == '123') {
          Navigator.pop(context); // Close the QuickAlert
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SecretScreen()),
          );
        } else {
          Navigator.pop(context); // Close the first alert
          QuickAlert.show(
            context: context,
            type: QuickAlertType.error,
            text: 'Incorrect Password!',
          );
        }
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    // Get device size for responsive design
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;
    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onLongPress: () {
          Future.delayed(Duration(seconds: 3), () {
            _showPasswordDialog(context);
          });
        },
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                width: size.width > 600 ? 500 : size.width * 0.9,
                padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo
                      Center(
                        child: Image.asset(
                          'assets/iconsv3.png',
                          height: isSmallScreen ? 100 : 120,
                        ),
                      ),

                      SizedBox(height: size.height * 0.04),

                      // Welcome Text
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: isSmallScreen ? 24 : 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          children: [
                            TextSpan(text: "Welcome to "),
                            TextSpan(
                              text: "LMS!",
                              style: TextStyle(color: Color(0xFF3969D7)),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 8),

                      Text(
                        'Please enter your details.',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: isSmallScreen ? 14 : 16,
                        ),
                      ),

                      SizedBox(height: 32),

                      // Email/Username Field
                      Text(
                        'Username',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 14 : 16,
                        ),
                      ),

                      SizedBox(height: 8),

                      TextFormField(
                        controller: _usernameController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your username';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: 'Enter your username',
                          filled: false,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Color(0xFF3969D7)),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.red),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: isSmallScreen ? 12 : 16
                          ),
                        ),
                      ),

                      SizedBox(height: 20),

                      // Password Field
                      Text(
                        'Password',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 14 : 16,
                        ),
                      ),

                      SizedBox(height: 8),

                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: 'Enter your password',
                          filled: false,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Color(0xFF3969D7)),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.red),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: isSmallScreen ? 12 : 16
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
                      ),

                      SizedBox(height: 16),

                      // Remember Me & Forgot Password
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                height: 24,
                                width: 24,
                                child: Checkbox(
                                  value: _rememberMe,
                                  activeColor: Color(0xFF3969D7),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  onChanged: (bool? value) {
                                    setState(() {
                                      _rememberMe = value ?? false;
                                    });
                                  },
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Remember me',
                                style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: Color(0xFF009FD9),
                                fontStyle: FontStyle.italic,
                                fontSize: isSmallScreen ? 12 : 14,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 32),

                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: isSmallScreen ? 48 : 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF3969D7),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                            disabledBackgroundColor: Color(0xFF3969D7).withOpacity(0.7),
                          ),
                          child: _isLoading
                              ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : Text(
                            'Login',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}