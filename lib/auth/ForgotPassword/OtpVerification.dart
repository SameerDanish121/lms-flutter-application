import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../Model/Comman Model.dart';
import '../../alerts/custom_alerts.dart';
import '../../api/api_services.dart';
import '../login_screen.dart';
import 'UpdatePassword.dart';

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
        final result = await ApiServices.forgotPassword(UserData.email!);

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
      final result = await ApiServices.verifyOtp(UserData.userId!, otp);

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