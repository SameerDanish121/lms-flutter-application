import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'ApiConfig.dart'; // Ensure this is correctly imported

class ApiServices {
  static Future<http.Response> sendOtp(String email) async {
    final url = Uri.parse("${ApiConfig.apiBaseUrl}forgot-password");
    return await http.post(url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}));
  }
  static Future<void> storeFcmTokens(int userId) async {
    try {
      // Get the FCM token from Firebase Messaging
      final FirebaseMessaging messaging = FirebaseMessaging.instance;
      final String? fcmToken = await messaging.getToken();

      if (fcmToken == null) {
        print('FCM token is null, cannot proceed with the API call');
        return;
      }

      // API endpoint
      final String apiUrl = '${ApiConfig.apiBaseUrl}store-fcmtoken'; // Replace with your actual base URL

      // Prepare request parameters
      final Map<String, dynamic> params = {
        'user_id': userId,
        'fcm_token': fcmToken,
      };

      // Make the API call
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          // Add any other headers your API requires (e.g., authorization)
        },
        body: jsonEncode(params),
      ).timeout(
        const Duration(seconds: 30), // Set a timeout to prevent hanging
        onTimeout: () {
          print('API call timed out');
          return http.Response('Timeout', 408);
        },
      );

      // Log the response for debugging
      print('FCM token storage response: ${response.statusCode}, ${response.body}');

      // We don't process the response as per requirements
    } catch (e) {
      // Catch any errors but don't crash the UI
      print('Error storing FCM token: $e');
    }
  }
  // Store FCM Token
  static Future<http.Response> storeFcmToken(String userId, String token) async {
    final url = Uri.parse("${ApiConfig.apiBaseUrl}store-fcmtoken");
    return await http.post(url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'fcm_token': token}));
  }

  // Verify OTP
  static Future<http.Response> verifyOtp(String userId, int otp) async {
    final url = Uri.parse("${ApiConfig.apiBaseUrl}verify-otp");
    return await http.post(url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'otp': otp}));
  }

  // Update Password
  static Future<http.Response> updatePassword(String userId, String newPassword) async {
    final url = Uri.parse("${ApiConfig.apiBaseUrl}update-pass");
    return await http.post(url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'new_password': newPassword}));
  }
}
