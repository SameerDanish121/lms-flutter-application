import 'package:app_settings/app_settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:lmsv2/api/ApiConfig.dart';
import 'package:lmsv2/auth/login_screen.dart';
import 'package:quickalert/quickalert.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../alerts/custom_alerts.dart';

class SecretScreen extends StatefulWidget {
  const SecretScreen({super.key});
  @override
  _SecretScreenState createState() => _SecretScreenState();
}

class _SecretScreenState extends State<SecretScreen> {
  final TextEditingController _urlController = TextEditingController();
  String _currentBaseUrl = ApiConfig.apiBaseUrl; // Get from ApiConfig
  bool _isTesting = false;
  String? _fcmToken; // Store FCM token

  // Theme colors
  final Color _primaryColor = Color(0xFF2A3F54); // Dark blue
  final Color _accentColor = Color(0xFF4A85FF); // Vibrant blue
  final Color _successColor = Color(0xFF43A047); // Green
  final Color _dangerColor = Color(0xFFE53935); // Red
  final Color _warningColor = Color(0xFFFFA000); // Amber
  final Color _cardColor = Color(0xFFF5F7FA); // Light gray background

  @override
  void initState() {
    super.initState();
    _fetchFCMToken(); // Fetch FCM token on screen load
    _urlController.text =
        _currentBaseUrl; // Pre-populate URL field with current value
  }

  // Fetch FCM Token
  Future<void> _fetchFCMToken() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? token = await messaging.getToken();
    setState(() {
      _fcmToken = token;
    });
  }

  Future<void> testConnection() async {
    CustomAlert.loading(context, 'Testing', 'Testing connection to API...');
    setState(() {
      _isTesting = true;
    });
    try {
      final response = await http.get(Uri.parse("$_currentBaseUrl"));
      if (response.statusCode == 200) {
        Navigator.pop(context);
        CustomAlert.success(context, "API is reachable ! ");
      } else {
        Navigator.pop(context);
        CustomAlert.error(context,
            "Connection Failed",
            "Failed to reach the API. Status Code: ${response.statusCode}");
      }
    } catch (e) {
      Navigator.pop(context);
      CustomAlert.error(context,"Connection Failed", "Error: $e");
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  void _showAuthenticationDialog() {
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
      onConfirmBtnTap: () async {
        if (password == '123') {

          Navigator.pop(context); // Close the QuickAlert
          // Update the API URL
          _currentBaseUrl = _urlController.text;
          var sf=await SharedPreferences.getInstance();
          sf.setString('apiBaseUrl', _currentBaseUrl);
          setState(()  {

            ApiConfig.apiBaseUrl = _currentBaseUrl;

          });

          CustomAlert.success(context, "Base URL updated successfully!");
        } else {
          Navigator.pop(context); // Close the first alert
          CustomAlert.error(
              context, "Authentication Failed", "Incorrect Password!");
        }
      },
    );
  }

  // Function to copy text to clipboard
  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    CustomAlert.success(context, "$label copied to clipboard");
  }

  // Function to log out and navigate to login screen
  void _logout() async {
    final result = await CustomAlert.confirm(
        context, "Are you sure you want to log out of the developer panel?");

    if (result == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
      );
    }
  }

  // Function to refresh FCM token
  void _refreshFCMToken() async {
    await CustomAlert.performWithLoading(
        context: context,
        loadingText: "Refreshing FCM token...",
        task: () async {
          setState(() {
            _fcmToken = null; // Clear current token to show loading state
          });
          await _fetchFCMToken();
        },
        successMessage: "FCM Token refreshed successfully");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Developer Console",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: _primaryColor,
        elevation: 2,
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
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
            tooltip: "Logout",
          ),
        ],
      ),
      body: Container(
        color: Colors.grey[100],
        child: LayoutBuilder(builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxWidth: 600), // Limit max width for larger screens
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // API URL Card
                    _buildCard(
                      title: "API Configuration",
                      icon: Icons.api,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Current API URL:",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.all(12),
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
                                      fontSize: 15,
                                      color: _accentColor,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.copy, color: _accentColor),
                                  onPressed: () => _copyToClipboard(
                                      _currentBaseUrl, "API URL"),
                                  tooltip: "Copy URL",
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 20),
                          Text(
                            "Update API URL:",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          TextField(
                            controller: _urlController,
                            decoration: InputDecoration(
                              hintText: 'https://your-api-url.com',
                              prefixIcon: Icon(Icons.link, color: _accentColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    BorderSide(color: _accentColor, width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            keyboardType: TextInputType.url,
                          ),
                          SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _showAuthenticationDialog,
                            icon: Icon(Icons.save, color: Colors.white),
                            label: Text("Update URL",
                                style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accentColor,
                              minimumSize: Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 2,
                            ),
                          ),
                          SizedBox(height: 12),
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
                                : Icon(Icons.network_check,
                                    color: Colors.white),
                            label: Text(
                              _isTesting ? "Testing..." : "Test API Connection",
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _successColor,
                              disabledBackgroundColor:
                                  _successColor.withOpacity(0.6),
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

                    SizedBox(height: 20),

                    // FCM Token Card
                    _buildCard(
                      title: "FCM Token",
                      icon: Icons.notifications_active,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Your Firebase Cloud Messaging Token:",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 10),
                          Container(
                            padding: EdgeInsets.all(12),
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
                                              color: _accentColor,
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          Text("Fetching token..."),
                                        ],
                                      )
                                    : SelectableText(
                                        _fcmToken!,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.black87,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _fcmToken != null
                                      ? () => _copyToClipboard(
                                          _fcmToken!, "FCM Token")
                                      : null,
                                  icon: Icon(Icons.copy, color: Colors.white),
                                  label: Text("Copy Token",
                                      style: TextStyle(color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _accentColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: EdgeInsets.symmetric(vertical: 14),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: _refreshFCMToken,
                                icon: Icon(Icons.refresh, color: Colors.white),
                                label: Text("Refresh",
                                    style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                      vertical: 14, horizontal: 16),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20),

                    // System Actions Card
                    _buildCard(
                      title: "System Actions",
                      icon: Icons.settings_applications,
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(Icons.settings, color: _warningColor),
                            title: Text("Device Settings"),
                            subtitle: Text("Access application settings"),
                            trailing: Icon(Icons.arrow_forward_ios, size: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            onTap: () {
                              AppSettings.openAppSettings();
                            },
                          ),
                          SizedBox(height: 10),
                          ListTile(
                            leading: Icon(Icons.logout, color: _dangerColor),
                            title: Text("Logout"),
                            subtitle: Text("Exit developer panel"),
                            trailing: Icon(Icons.arrow_forward_ios, size: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            onTap: _logout,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20),

                    // Footer
                    Center(
                      child: Text(
                        "Developer Console v1.0",
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          );
        }),
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
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: _primaryColor, size: 22),
                ),
                SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20),
            child: child,
          ),
        ],
      ),
    );
  }
}
