import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'ApiConfig.dart'; // Ensure this is correctly imported

class ApiServices {

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

  static Future<http.Response> storeFcmToken(String userId, String token) async {
    final url = Uri.parse("${ApiConfig.apiBaseUrl}store-fcmtoken");
    return await http.post(url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'fcm_token': token}));
  }
}
