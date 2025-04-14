import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quickalert/quickalert.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../provider/student_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  final Color _primaryColor = const Color(0xFF6C63FF); // Professional purple
  final Color _secondaryColor = const Color(0xFF4A45B1); // Darker purple
  final Color _accentColor = const Color(0xFFFF6584); // Pink accent
  final Color _backgroundColor = const Color(0xFFF8F9FA); // Light background
  final Color _cardColor = Colors.white;
  final Color _textColor = const Color(0xFF333333);

  Future<void> _changeImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.success,
        title: 'Success',
        text: 'Profile picture updated successfully!',
        confirmBtnColor: _primaryColor,
      );
    }
  }

  void _changeEmail() {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.custom,
      barrierDismissible: true,
      confirmBtnText: 'Save',
      confirmBtnColor: _primaryColor,
      customAsset: 'assets/images/email_icon.png', // Add your asset
      widget: Column(
        children: [
          TextFormField(
            decoration: InputDecoration(
              labelText: 'New Email',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              prefixIcon: Icon(Icons.email, color: _primaryColor),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ),
      onConfirmBtnTap: () {
        Navigator.pop(context);
        QuickAlert.show(
          context: context,
          type: QuickAlertType.success,
          title: 'Success',
          text: 'Email updated successfully!',
          confirmBtnColor: _primaryColor,
        );
      },
    );
  }

  void _changePassword() {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.custom,
      barrierDismissible: true,
      confirmBtnText: 'Save',
      confirmBtnColor: _primaryColor,
      widget: Column(
        children: [
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Current Password',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              prefixIcon: Icon(Icons.lock, color: _primaryColor),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'New Password',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              prefixIcon: Icon(Icons.lock_outline, color: _primaryColor),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Confirm New Password',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              prefixIcon: Icon(Icons.lock_reset, color: _primaryColor),
            ),
            obscureText: true,
          ),
        ],
      ),
      onConfirmBtnTap: () {
        Navigator.pop(context);
        QuickAlert.show(
          context: context,
          type: QuickAlertType.success,
          title: 'Success',
          text: 'Password updated successfully!',
          confirmBtnColor: _primaryColor,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final student = Provider.of<StudentProvider>(context).student;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text('My Profile'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: _primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _primaryColor,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: _primaryColor.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          image: DecorationImage(
                            image: NetworkImage(student?.image ?? ''),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _changeImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _accentColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student?.name ?? '',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          student?.regNo ?? '',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 20),
                            const SizedBox(width: 5),
                            Text(
                              'CGPA: ${student?.cgpa}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 20),

            // Personal Information Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              color: _cardColor,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Personal Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const Divider(height: 20, thickness: 1),
                    _buildInfoRow(Icons.person_outline, 'Username', student?.username ?? ''),
                    _buildInfoRow(Icons.email_outlined, 'Email', student?.email ?? '', editable: true, onTap: _changeEmail),
                    _buildInfoRow(Icons.lock_outline, 'Password', '••••••••', editable: true, onTap: _changePassword),
                    _buildInfoRow(Icons.transgender, 'Gender', student?.gender ?? ''),
                    _buildInfoRow(Icons.family_restroom, 'Guardian', student?.guardian ?? ''),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 20),

            // Academic Information Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              color: _cardColor,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Academic Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const Divider(height: 20, thickness: 1),
                    _buildInfoRow(Icons.school_outlined, 'Program', student?.program ?? ''),
                    _buildInfoRow(Icons.class_outlined, 'Section', student?.section ?? ''),
                    _buildInfoRow(Icons.calendar_today_outlined, 'Intake Session', student?.intake ?? ''),
                    _buildInfoRow(Icons.date_range_outlined, 'Current Session', student?.currentSession ?? ''),
                    _buildInfoRow(Icons.assignment_ind_outlined, 'Total Enrollments', student?.totalEnrollments.toString() ?? '0'),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 20),

            // System Information Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              color: _cardColor,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'System Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const Divider(height: 20, thickness: 1),
                    _buildInfoRow(Icons.person_pin_circle_outlined, 'User ID', student?.userId.toString() ?? ''),
                    _buildInfoRow(Icons.badge_outlined, 'Student ID', student?.id.toString() ?? ''),
                    _buildInfoRow(Icons.verified_user_outlined, 'Grader Status', student?.isGrader == true ? 'Yes' : 'No'),
                    _buildInfoRow(Icons.timeline_outlined, 'Current Week', student?.currentWeek.toString() ?? '0'),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 400.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool editable = false, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _primaryColor, size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _textColor,
                  ),
                ),
              ],
            ),
          ),
          if (editable)
            IconButton(
              icon: Icon(Icons.edit_outlined, color: _accentColor),
              onPressed: onTap,
            ),
        ],
      ),
    );
  }
}