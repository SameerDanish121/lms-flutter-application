import 'dart:io';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:lmsv2/alerts/custom_alerts.dart';
import 'package:lmsv2/auth/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'dart:convert';
import '../../Theme/theme.dart';
import '../../provider/instructor_provider.dart';
import '../../api/ApiConfig.dart';
import 'package:cached_network_image/cached_network_image.dart';
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}
class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _isEditingEmail = false;
  bool _isEditingPassword = false;
  bool _isLoading = false;
  final Color _primaryColor = Color(0xFF2A3F54); // Dark blue
  final Color _accentColor = Color(0xFF4A85FF); // Vibrant blue
  final Color _successColor = Color(0xFF43A047); // Green
  final Color _dangerColor = Color(0xFFE53935); // Red
  final Color _warningColor = Color(0xFFFFA000); // Amber
  final Color _cardColor = Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    final instructor =
        Provider.of<InstructorProvider>(context, listen: false).instructor;
    _emailController = TextEditingController(text: instructor?.email ?? '');
    _passwordController = TextEditingController(text: '********');
  }
  void _logout() async {
    final result = await CustomAlert.confirm(
        context, "Are you sure you want to log out  ?");

    if (result == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
      );
    }
  }
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  Future<void> _showEmailChangeDialog(BuildContext context, String currentEmail) async {
    final emailController = TextEditingController(text: currentEmail);

    await QuickAlert.show(
      context: context,
      type: QuickAlertType.custom,
      barrierDismissible: true,
      confirmBtnText: 'Update',
      showConfirmBtn: true,
      showCancelBtn: true,
      confirmBtnColor: Colors.blue, // Optional: customize button color
      widget: Container(
        width: MediaQuery.of(context).size.width * 0.8, // Constrain width
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            Text('Update Email', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            TextFormField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'New Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
      ),
      onConfirmBtnTap: () async {
        if (emailController.text == currentEmail) {
          Navigator.pop(context); // Close the dialog
          QuickAlert.show(
            context: context,
            type: QuickAlertType.warning,
            title: 'No Changes',
            text: 'The email you entered is the same as the current one.',
          );
          return;
        }

        Navigator.pop(context); // Close the dialog
        await _updateEmails(emailController.text);
      },
    );
  }

  Future<void> _showPasswordChangeDialog(BuildContext context) async {
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    await QuickAlert.show(
      context: context,
      type: QuickAlertType.custom,
      barrierDismissible: true,
      confirmBtnText: 'Update',
      showConfirmBtn: true,
      showCancelBtn: true,
      customAsset: 'assets/developer.jpg', // Empty string removes default image
    // Remove any default padding around the widget
      widget: Container(
        width: MediaQuery.of(context).size.width * 0.8, // Constrain width
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            Text('Change Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            TextFormField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
      ),
      onConfirmBtnTap: () async {

        if (passwordController.text.isEmpty) {
          Navigator.pop(context);
          QuickAlert.show(
            context: context,
            type: QuickAlertType.warning,
            title: 'Invalid Password',
            text: 'Please enter a new password.',
          );
          return;
        }
        Navigator.pop(context);
        await _updatePasswords(passwordController.text);
      },
    );
  }

// Update your existing methods to accept parameters
  Future<void> _updateEmails(String newEmail) async {
    setState(() => _isLoading = true);
    final instructorProvider = Provider.of<InstructorProvider>(context, listen: false);
    final teacherId = instructorProvider.instructor?.id;

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.apiBaseUrl}Teachers/update-teacher-email'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'teacher_id': teacherId,
          'email': newEmail,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        instructorProvider.updateEmail(newEmail);
        QuickAlert.show(
          context: context,
          type: QuickAlertType.success,
          title: 'Success',
          text: 'Email updated successfully',
        );
      } else {
        throw Exception('Server responded with ${response.statusCode}');
      }
    } catch (e) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Error',
        text: e.toString(),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePasswords(String newPassword) async {
    setState(() => _isLoading = true);
    final instructorProvider = Provider.of<InstructorProvider>(context, listen: false);
    final teacherId = instructorProvider.instructor?.id;

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.apiBaseUrl}Teachers/update-teacher-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'teacher_id': teacherId,
          'password': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        instructorProvider.updatePassword(newPassword);
        QuickAlert.show(
          context: context,
          type: QuickAlertType.success,
          title: 'Success',
          text: 'Password updated successfully',
        );
      } else {
        throw Exception('Server responded with ${response.statusCode}');
      }
    } catch (e) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Error',
        text: e.toString(),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
  Future<void> _updateEmail() async {
    if (_emailController.text.isEmpty) {
      CustomAlert.warning(context, 'Email cannot be empty');
      return;
    }

    setState(() => _isLoading = true);
    final instructorProvider =
        Provider.of<InstructorProvider>(context, listen: false);
    final teacherId = instructorProvider.instructor?.id;

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.apiBaseUrl}Teachers/update-teacher-email'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'teacher_id': teacherId,
          'email': _emailController.text,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        instructorProvider.updateEmail(_emailController.text);
        CustomAlert.success(context, 'Email updated successfully');
        setState(() => _isEditingEmail = false);
      } else {
        throw Exception('Server responded with ${response.statusCode}');
      }
    } catch (e) {
      CustomAlert.error(context, 'Error: ', ' ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePassword() async {
    if (_passwordController.text.isEmpty ||
        _passwordController.text == '********') {
      CustomAlert.warning(context, 'Please enter a new password');
      return;
    }
    setState(() => _isLoading = true);
    final instructorProvider =
        Provider.of<InstructorProvider>(context, listen: false);
    final teacherId = instructorProvider.instructor?.id;

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.apiBaseUrl}Teachers/update-teacher-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'teacher_id': teacherId,
          'password': _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        instructorProvider.updatePassword(_passwordController.text);
        CustomAlert.success(context, 'Password updated successfully');
        setState(() {
          _isEditingPassword = false;
          _passwordController.text = '********';
        });
      } else {
        throw Exception('Server responded with ${response.statusCode}');
      }
    } catch (e) {
      CustomAlert.error(context, 'Error:', '${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfileImage() async {
    setState(() => _isLoading = true);
    try {
      await Provider.of<InstructorProvider>(context, listen: false)
          .pickAndUploadImage();
      CustomAlert.success(context, 'Profile image updated');
    } catch (e) {
      CustomAlert.error(context, 'Failed to update image:', ' ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  Widget _buildAvatar(String imageUrl, String name) {
    if (imageUrl.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        imageBuilder: (context, imageProvider) => CircleAvatar(
          radius: 57,
          backgroundImage: imageProvider,
        ),
        placeholder: (context, url) => CircleAvatar(
          radius: 57,
          backgroundColor: AppTheme.cardColor,
          child: const CircularProgressIndicator(),
        ),
        errorWidget: (context, url, error) => _buildInitialsAvatar(name),
      );
    } else {
      // For local images (after picking from gallery)
      return CircleAvatar(
        radius: 57,
        backgroundImage: FileImage(File(imageUrl)),
      );
    }
  }

  Widget _buildInitialsAvatar(String name) {
    final initials = name.isNotEmpty
        ? name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join()
        : 'US';

    return CircleAvatar(
      radius: 57,
      backgroundColor: AppTheme.primaryColor,
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final instructorProvider = Provider.of<InstructorProvider>(context);
    final instructor = instructorProvider.instructor;
    final name = instructor?.name ?? 'User';
    final email = instructor?.email ?? 'No email';
    final gender = instructor?.gender ?? 'Not specified';
    final dob = instructor?.dateOfBirth ?? 'Not specified';
    final username = instructor?.username;
    final imageUrl = instructor?.image ??
        'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}background=4FC3F7&color=ffffff';
    final password=instructor?.password??'';
    final maskedPassword = password.isNotEmpty
        ? '${password[0]}${'*' * (password.length - 2)}${password[password.length - 1]}'
        : '';
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    width: double.infinity,
                    color: AppTheme.primaryColor,
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _updateProfileImage,
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.white, // White border
                            child: CircleAvatar(
                              radius: 58, // Slightly smaller than parent
                              backgroundColor:
                                  Colors.grey[200], // optional background
                              child: ClipOval(
                                child: Image.network(
                                  imageUrl,
                                  width: 116, // double of inner radius (58 * 2)
                                  height: 116,
                                  fit: BoxFit
                                      .cover, // Changed to cover for better image display
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(
                                    Icons.person,
                                    size: 58,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          instructorProvider.type ?? 'Instructor',
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),

                  _buildCard(
                      title:"Personal Information",
                      icon:Icons.account_circle,
                      child:Column(
                        children:[
                          ListTile(
                            leading: Icon(Icons.supervised_user_circle_outlined, color: _accentColor),
                            title: Text("Username"),
                            subtitle: Text( username! ?? 'N/A'),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),

                          ),
                          SizedBox(height: 10),
                          ListTile(
                            leading: Icon(Icons.person, color: _successColor),
                            title: Text("Gender"),
                            subtitle: Text(gender),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                          ),
                          SizedBox(height: 10),
                          ListTile(
                            leading: Icon(Icons.cake, color: _warningColor),
                            title: Text("Date Of Birth"),
                            subtitle: Text(dob),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                          ),
                        ],
                      )
                  ),
                  SizedBox(height: 20),
                  _buildCard(
                    title: "Update Credentials",
                    icon: Icons.update,
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(Icons.email_outlined, color: _warningColor),
                          title: Text("Recovery Email"),
                          subtitle: Text(email),
                          trailing: Icon(Icons.arrow_forward_ios, size: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          onTap: () => _showEmailChangeDialog(context, email),
                        ),
                        SizedBox(height: 10),
                        ListTile(
                          leading: Icon(Icons.password, color: _dangerColor),
                          title: Text("Change Password"),
                          subtitle: Text(maskedPassword),
                          trailing: Icon(Icons.arrow_forward_ios, size: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          onTap: () => _showPasswordChangeDialog(context),
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
                          subtitle: Text("Exit Your Account"),
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
                  Center(
                    child: Text(
                      "LMS Console v1.0",
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
    );
  }
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
  Widget _buildEditableInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required bool isEditing,
    required TextEditingController controller,
    required VoidCallback onEdit,
    required VoidCallback onSave,
    required VoidCallback onCancel,
    bool obscureText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: AppTheme.secondaryTextColor, fontSize: 14)),
                if (!isEditing)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          obscureText ? '********' : value,
                          style: TextStyle(
                            color: AppTheme.textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.edit,
                            size: 18, color: AppTheme.primaryColor),
                        onPressed: onEdit,
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      TextField(
                        controller: controller,
                        obscureText: obscureText,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                              onPressed: onCancel,
                              child: Text('Cancel',
                                  style: TextStyle(
                                      color: AppTheme.secondaryTextColor))),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: onSave,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 22),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: AppTheme.secondaryTextColor, fontSize: 14)),
              Text(
                value,
                style: TextStyle(
                  color: AppTheme.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
