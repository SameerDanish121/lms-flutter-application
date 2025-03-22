import 'package:app_settings/app_settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:lmsv2/api/ApiConfig.dart';
import 'package:lmsv2/auth/login_screen.dart';
class SecretScreen extends StatefulWidget {
  @override
  _SecretScreenState createState() => _SecretScreenState();
}
class _SecretScreenState extends State<SecretScreen> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _currentBaseUrl = ApiConfig.apiBaseUrl; // Get from ApiConfig
  bool _isTesting = false;
  String? _fcmToken; // Store FCM token

  // Color theme constants
  final Color _primaryColor = Color(0xFF3F51B5);  // Indigo
  final Color _accentColor = Color(0xFF03A9F4);   // Light Blue
  final Color _successColor = Color(0xFF4CAF50); // Green
  final Color _dangerColor = Color(0xFFE53935);  // Red
  final Color _cardColor = Color(0xFFF5F7FA);    // Light background for cards

  @override
  void initState() {
    super.initState();
    _fetchFCMToken(); // Fetch FCM token on screen load
    _urlController.text = _currentBaseUrl; // Pre-populate URL field with current value
  }

  // Fetch FCM Token
  Future<void> _fetchFCMToken() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? token = await messaging.getToken();
    setState(() {
      _fcmToken = token;
    });
  }

  // Function to test the connection to the API
  Future<void> testConnection() async {
    setState(() {
      _isTesting = true;
    });
    try {
      final response = await http.get(Uri.parse("$_currentBaseUrl"));
      if (response.statusCode == 200) {
        _showDialog("Connection Success", "API is reachable!", isSuccess: true);
      } else {
        _showDialog(
            "Connection Failed",
            "Failed to reach the API. Status Code: ${response.statusCode}",
            isSuccess: false);
      }
    } catch (e) {
      _showDialog("Connection Failed", "Error: $e", isSuccess: false);
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  // Function to show dialog with connection status
  void _showDialog(String title, String message, {bool isSuccess = true}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: isSuccess ? _successColor : _dangerColor,
            ),
            SizedBox(width: 10),
            Text(title),
          ],
        ),
        content: Text(message),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK", style: TextStyle(color: _primaryColor)),
          ),
        ],
      ),
    );
  }

  // Function to update the base URL
  void _updateBaseUrl() {
    _passwordController.clear(); // Clear previous password
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lock, color: _primaryColor),
            SizedBox(width: 10),
            Text("Confirm Password"),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Please enter the password to confirm URL change."),
            SizedBox(height: 15),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter password',
                prefixIcon: Icon(Icons.vpn_key, color: _primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: _primaryColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: _primaryColor, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (_passwordController.text == "sameer") {
                setState(() {
                  _currentBaseUrl = _urlController.text;
                  ApiConfig.apiBaseUrl = _currentBaseUrl;
                });
                Navigator.pop(context);
                _showDialog("Success", "Base URL updated successfully!", isSuccess: true);
              } else {
                Navigator.pop(context);
                _showDialog("Error", "Incorrect password. Please try again.", isSuccess: false);
              }
            },
            child: Text("Confirm", style: TextStyle(color: _primaryColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  // Function to copy text to clipboard
  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10),
            Text("$label copied to clipboard"),
          ],
        ),
        backgroundColor: _successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Function to log out and navigate to login screen
  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.exit_to_app, color: _dangerColor),
            SizedBox(width: 10),
            Text("Confirm Logout"),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: Text("Are you sure you want to log out of the developer panel?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => Login()),
              );
            },
            child: Text("Yes", style: TextStyle(color: _dangerColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("No", style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  // Function to refresh FCM token
  void _refreshFCMToken() async {
    setState(() {
      _fcmToken = null; // Clear current token to show loading state
    });
    await _fetchFCMToken();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.refresh, color: Colors.white),
            SizedBox(width: 10),
            Text("FCM Token refreshed"),
          ],
        ),
        backgroundColor: _successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Developer Panel",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: _primaryColor,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false, // Hides the back button
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              AppSettings.openAppSettings();
            },
            tooltip: "Open Settings",
          ),
        ],
      ),
      body: Container(
        color: Colors.grey[50],
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // API URL Card
              _buildCard(
                title: "Current API URL",
                icon: Icons.link,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: SelectableText(
                              _currentBaseUrl,
                              style: TextStyle(
                                fontSize: 16,
                                color: _accentColor,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.copy, color: _accentColor),
                            onPressed: () => _copyToClipboard(_currentBaseUrl, "Base URL"),
                            tooltip: "Copy URL",
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 15),
                    TextField(
                      controller: _urlController,
                      decoration: InputDecoration(
                        labelText: 'New API Base URL',
                        hintText: 'https://your-api-url.com',
                        prefixIcon: Icon(Icons.edit, color: _primaryColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: _primaryColor, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      keyboardType: TextInputType.url,
                    ),
                    SizedBox(height: 15),
                    ElevatedButton.icon(
                      onPressed: _updateBaseUrl,
                      icon: Icon(Icons.save, color: Colors.white),
                      label: Text("Update API URL", style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        minimumSize: Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // FCM Token Card
              _buildCard(
                title: "Firebase Cloud Messaging Token",
                icon: Icons.notifications_active,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fcmToken == null
                              ? Row(
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: _primaryColor,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text("Fetching token..."),
                            ],
                          )
                              : SelectableText(
                            _fcmToken!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _fcmToken != null
                                ? () => _copyToClipboard(_fcmToken!, "FCM Token")
                                : null,
                            icon: Icon(Icons.copy, color: Colors.white),
                            label: Text("Copy Token", style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accentColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        IconButton(
                          onPressed: _refreshFCMToken,
                          icon: Icon(Icons.refresh),
                          tooltip: "Refresh Token",
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // Actions Card
              _buildCard(
                title: "Connection & System Actions",
                icon: Icons.settings_applications,
                child: Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isTesting ? null : testConnection,
                      icon: _isTesting
                          ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : Icon(Icons.network_check, color: Colors.white),
                      label: Text(
                        _isTesting ? "Testing..." : "Test API Connection",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _successColor,
                        disabledBackgroundColor: _successColor.withOpacity(0.6),
                        minimumSize: Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                      ),
                    ),
                    SizedBox(height: 15),
                    ElevatedButton.icon(
                      onPressed: () {
                        AppSettings.openAppSettings();
                      },
                      icon: Icon(Icons.settings, color: Colors.white),
                      label: Text("Open System Settings", style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[700],
                        minimumSize: Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                      ),
                    ),
                    SizedBox(height: 15),
                    ElevatedButton.icon(
                      onPressed: _logout,
                      icon: Icon(Icons.logout, color: Colors.white),
                      label: Text("Logout", style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _dangerColor,
                        minimumSize: Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build consistent card layouts
  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Icon(icon, color: _primaryColor),
                SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}