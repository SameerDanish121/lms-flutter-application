
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lmsv2/api/ApiConfig.dart';
import 'package:quickalert/quickalert.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../alerts/custom_alerts.dart';
import 'login_screen.dart';
// API Service
class ApiService {
  // Forgot Password
  static Future<Map<String, dynamic>> verifyLoginOTP(int userId, int otp) async {
    try {
      // Create URI for the endpoint
      final uri = Uri.parse('${ApiConfig.apiBaseUrl}verify/login');

      // Prepare request body
      final body = jsonEncode({
        'user_id': userId,
        'otp': otp,
      });

      // Make POST request
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: body,
      );

      // Parse response body
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      // Check status code
      if (response.statusCode == 200) {
        return responseData;
      } else {
        // Handle error responses
        throw Exception(responseData['message'] ?? 'Failed to verify OTP');
      }
    } catch (e) {
      // Handle any errors
      throw Exception('Error verifying OTP: ${e.toString()}');
    }
  }
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.apiBaseUrl}forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to send OTP: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Verify OTP
  static Future<Map<String, dynamic>> verifyOtp(String userId, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.apiBaseUrl}verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'otp': otp}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to verify OTP: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Update Password
  static Future<Map<String, dynamic>> updatePassword(String userId, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.apiBaseUrl}update-pass'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'new_password': newPassword}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update password: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
// Shared user data
class UserData {
  static String? userId;
  static String? email;
}
// 1. Forgot Password Screen
class ForgotPasswordScreen extends StatefulWidget {
  final VoidCallback? onNavigateToLogin;
  const ForgotPasswordScreen({Key? key, this.onNavigateToLogin}) : super(key: key);
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}
class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await ApiService.forgotPassword(_emailController.text.trim());

      if (result['status'] == 'success') {
        UserData.userId = result['user_id'].toString();
        UserData.email = _emailController.text.trim();

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VerificationScreen(
                onNavigateToLogin: widget.onNavigateToLogin,
              ),
            ),
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'])),
          );
        }
      } else {
        if (mounted) {
          CustomAlert.error(context, 'Error', result['message'] ?? 'Failed to send OTP');
        }
      }
    } catch (e) {
      if (mounted) {
        CustomAlert.error(context, 'Error', e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Color(0xFF3969D7),
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              if (widget.onNavigateToLogin != null) {
                widget.onNavigateToLogin!();
              } else {
                Navigator.pop(context);
              }
            },
          ),
          title: Text(
            'Forgot Password',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 60),
                    Icon(
                      Icons.lock_reset,
                      size: 70,
                      color: Color(0xFF3969D7),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Forgot Password?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Enter your email address. We will send a verification code to reset your password.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 40),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email is required';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        hintText: 'Enter your email',
                        prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF3969D7)),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color(0xFF3969D7), width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.red, width: 1),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                    SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _sendResetEmail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF3969D7),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          disabledBackgroundColor: Colors.grey[400],
                        ),
                        child: _isLoading
                            ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : Text(
                          'Send Verification Code',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => Login()),
                        );
                      },
                      child: Text(
                        'Back to Login',
                        style: TextStyle(
                          color: Color(0xFF3969D7),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
    );
  }
}
// 2. OTP Verification Screen
class VerificationScreen extends StatefulWidget {
  final VoidCallback? onNavigateToLogin;

  const VerificationScreen({Key? key, this.onNavigateToLogin}) : super(key: key);

  @override
  _VerificationScreenState createState() => _VerificationScreenState();
}
class _VerificationScreenState extends State<VerificationScreen> {
  // For 6-digit OTP
  final List<TextEditingController> _controllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  bool _isLoading = false;
  int _remainingSeconds = 120; // 2 minutes
  late Timer _timer;
  bool _resendEnabled = false;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    setState(() {
      _remainingSeconds = 120;
      _resendEnabled = false;
    });

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _resendEnabled = true;
          _timer.cancel();
        }
      });
    });
  }

  String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _resendOtp() async {
    if (!_resendEnabled) return;

    setState(() => _isLoading = true);

    try {
      if (UserData.email != null) {
        final result = await ApiService.forgotPassword(UserData.email!);

        if (result['status'] == 'success') {
          UserData.userId = result['user_id'].toString();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Verification code resent successfully')),
            );

            // Reset the OTP fields
            for (var controller in _controllers) {
              controller.clear();
            }

            // Reset the timer
            startTimer();
          }
        } else {
          if (mounted) {
            CustomAlert.error(context, 'Error', result['message'] ?? 'Failed to resend OTP');
          }
        }
      } else {
        if (mounted) {
          CustomAlert.error(context, 'Error', 'Email not found. Please go back and try again.');
        }
      }
    } catch (e) {
      if (mounted) {
        CustomAlert.error(context, 'Error', e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _verifyOtp() async {
    // Get the complete OTP
    String otp = _controllers.map((controller) => controller.text).join();

    // Validate OTP
    if (otp.length != 6) {
      CustomAlert.warning(context, 'Please enter all 6 digits');
      return;
    }

    if (UserData.userId == null) {
      CustomAlert.error(context, 'Error', 'User information not found. Please try again.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ApiService.verifyOtp(UserData.userId!, otp);

      if (result['status'] == 'success') {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChangePasswordScreen(
                onNavigateToLogin: widget.onNavigateToLogin,
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          CustomAlert.error(context, 'Error', result['message'] ?? 'Failed to verify OTP');
        }
      }
    } catch (e) {
      if (mounted) {
        CustomAlert.error(context, 'Error', e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Color(0xFF3969D7),
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Verification',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  SizedBox(height: 50),
                  Icon(
                    Icons.verified_user,
                    size: 70,
                    color: Color(0xFF3969D7),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Verification Code',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Enter the 6-digit code sent to your email',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 36),
                  // OTP Timer
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: _resendEnabled ? Colors.red[50] : Colors.blue[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer,
                          color: _resendEnabled ? Colors.red : Colors.blue,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          _resendEnabled ? 'Code expired' : 'Code expires in ${formatTime(_remainingSeconds)}',
                          style: TextStyle(
                            color: _resendEnabled ? Colors.red : Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32),
                  // OTP fields - using Intrinsic height to fix overflow
                  Container(
                    width: double.infinity,
                    child: IntrinsicHeight(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: List.generate(6, (index) {
                          return SizedBox(
                            width: 45,
                            child: TextFormField(
                              controller: _controllers[index],
                              focusNode: _focusNodes[index],
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(1),
                              ],
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                counterText: "",
                                contentPadding: EdgeInsets.zero,
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Color(0xFF3969D7), width: 2),
                                ),
                              ),
                              onChanged: (value) {
                                if (value.isNotEmpty) {
                                  // Move to next field
                                  if (index < 5) {
                                    FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
                                  } else {
                                    // Last digit entered
                                    FocusScope.of(context).unfocus();
                                  }
                                }
                              },
                              onTap: () {
                                _controllers[index].selection = TextSelection(
                                  baseOffset: 0,
                                  extentOffset: _controllers[index].text.length,
                                );
                              },
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Handle backspace navigation
                  Focus(
                    onKeyEvent: (node, event) {
                      if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
                        for (int i = 1; i < _controllers.length; i++) {
                          if (_focusNodes[i].hasFocus && _controllers[i].text.isEmpty) {
                            _controllers[i - 1].clear();
                            FocusScope.of(context).requestFocus(_focusNodes[i - 1]);
                            return KeyEventResult.handled;
                          }
                        }
                      }
                      return KeyEventResult.ignored;
                    },
                    child: SizedBox(height: 0, width: 0),
                  ),
                  SizedBox(height: 24),
                  GestureDetector(
                    onTap: _isLoading ? null : _resendOtp,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Didn't receive the code? ",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          "Resend",
                          style: TextStyle(
                            color: _resendEnabled ? Color(0xFF3969D7) : Colors.grey,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 40),
                  // Verify Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verifyOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF3969D7),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        disabledBackgroundColor: Colors.grey[400],
                      ),
                      child: _isLoading
                          ? SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : Text(
                        'Verify',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => Login()),
                      );
                    },
                    child: Text(
                      'Back to Login',
                      style: TextStyle(
                        color: Color(0xFF3969D7),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
class ChangePasswordScreen extends StatefulWidget {
  final VoidCallback? onNavigateToLogin;

  const ChangePasswordScreen({Key? key, this.onNavigateToLogin}) : super(key: key);

  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _newPasswordValid = true;
  bool _passwordsMatch = true;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validateNewPassword() {
    setState(() {
      _newPasswordValid = _newPasswordController.text.length >= 8;
    });
  }

  void _validatePasswordsMatch() {
    setState(() {
      _passwordsMatch = _newPasswordController.text == _confirmPasswordController.text;
    });
  }

  Future<void> _updatePassword() async {
    _validateNewPassword();
    _validatePasswordsMatch();

    if (!_formKey.currentState!.validate() || !_newPasswordValid || !_passwordsMatch) {
      return;
    }

    if (UserData.userId == null) {
      CustomAlert.error(context, 'Error', 'User information not found. Please try again.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ApiService.updatePassword(
        UserData.userId!,
        _newPasswordController.text,
      );

      if (mounted) {
        CustomAlert.success(context, result['message'] ?? 'Password updated successfully');

        // Navigate back to login after 2 seconds
        Future.delayed(Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => Login()),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        CustomAlert.error(context, 'Error', e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Color(0xFF3969D7),
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Change Password',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 40),
                    Center(
                      child: Icon(
                        Icons.lock_outline,
                        size: 70,
                        color: Color(0xFF3969D7),
                      ),
                    ),
                    SizedBox(height: 24),
                    Center(
                      child: Text(
                        'Create New Password',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    Center(
                      child: Text(
                        'Your new password must be different from previously used passwords',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    SizedBox(height: 40),

                    // New Password Section
                    Text(
                      'New Password',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3969D7),
                      ),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: !_showNewPassword,
                      onChanged: (_) {
                        _validateNewPassword();
                        if (_confirmPasswordController.text.isNotEmpty) {
                          _validatePasswordsMatch();
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required';
                        }
                        if (value.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'Enter new password',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showNewPassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey[600],
                          ),
                          onPressed: () {
                            setState(() {
                              _showNewPassword = !_showNewPassword;
                            });
                          },
                        ),
                      ),
                    ),
                    if (!_newPasswordValid && _newPasswordController.text.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Password must be at least 8 characters',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    SizedBox(height: 24),

                    // Password Requirements
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Password Requirements:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                _newPasswordController.text.length >= 8
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                color: _newPasswordController.text.length >= 8
                                    ? Colors.green
                                    : Colors.grey,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Text('At least 8 characters'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),

                    // Confirm Password Section
                    Text(
                      'Confirm Password',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3969D7),
                      ),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: !_showConfirmPassword,
                      onChanged: (_) => _validatePasswordsMatch(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _newPasswordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'Confirm new password',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showConfirmPassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey[600],
                          ),
                          onPressed: () {
                            setState(() {
                              _showConfirmPassword = !_showConfirmPassword;
                            });
                          },
                        ),
                      ),
                    ),
                    if (!_passwordsMatch && _confirmPasswordController.text.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Passwords do not match',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    SizedBox(height: 40),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updatePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF3969D7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                          'Update Password',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
