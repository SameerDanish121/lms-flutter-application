import 'package:flutter/material.dart';
import 'package:lmsv2/auth/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:quickalert/quickalert.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:icons_plus/icons_plus.dart';
import 'dart:ui';

import '../provider/student_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  late TabController _tabController;

  // Modern color palette (more vibrant and attractive)
  final Color _primaryColor = const Color(0xFF3949AB); // Indigo blue
  final Color _secondaryColor = const Color(0xFF00BCD4); // Cyan
  final Color _tertiaryColor = const Color(0xFFFF5252); // Red accent
  final Color _backgroundColor = const Color(0xFFF5F7FA); // Light background
  final Color _cardColor = Colors.white;
  final Color _textColor = const Color(0xFF2D3142); // Dark slate
  final Color _subtitleColor = const Color(0xFF9E9E9E); // Gray

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _changeImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _showSuccessAlert('Profile picture updated successfully!');
    }
  }

  void _showSuccessAlert(String message) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.success,
      title: 'Success',
      text: message,
      confirmBtnColor: _primaryColor,
      confirmBtnTextStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  void _logout() {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.confirm,
      title: 'Logout',
      text: 'Are you sure you want to logout?',
      confirmBtnText: 'Yes',
      cancelBtnText: 'Cancel',
      confirmBtnColor: _tertiaryColor,
      onConfirmBtnTap: () {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (context)=>Login()));
      },
    );
  }

  void _changeEmail() {
    final TextEditingController emailController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(BoxIcons.bx_envelope, color: _primaryColor),
                    const SizedBox(width: 12),
                    Text(
                      'Update Email Address',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'New Email Address',
                    hintText: 'Enter your new email address',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _primaryColor.withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _primaryColor.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _primaryColor, width: 2),
                    ),
                    floatingLabelStyle: TextStyle(color: _primaryColor),
                    prefixIcon: Icon(BoxIcons.bx_at, color: _primaryColor),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          foregroundColor: _textColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showSuccessAlert('Email updated successfully!');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Update',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _changePassword() {
    final TextEditingController currentPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(BoxIcons.bx_lock_alt, color: _primaryColor),
                    const SizedBox(width: 12),
                    Text(
                      'Change Password',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildPasswordField(
                  controller: currentPasswordController,
                  label: 'Current Password',
                  hint: 'Enter your current password',
                  icon: BoxIcons.bx_lock,
                ),
                const SizedBox(height: 16),
                _buildPasswordField(
                  controller: newPasswordController,
                  label: 'New Password',
                  hint: 'Enter your new password',
                  icon: BoxIcons.bx_key,
                ),
                const SizedBox(height: 16),
                _buildPasswordField(
                  controller: confirmPasswordController,
                  label: 'Confirm New Password',
                  hint: 'Confirm your new password',
                  icon: BoxIcons.bx_check_shield,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          foregroundColor: _textColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showSuccessAlert('Password updated successfully!');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Update',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primaryColor.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primaryColor.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primaryColor, width: 2),
        ),
        floatingLabelStyle: TextStyle(color: _primaryColor),
        prefixIcon: Icon(icon, color: _primaryColor),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final student = Provider.of<StudentProvider>(context).student;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Custom App Bar with Profile Header
          SliverAppBar(
            expandedHeight: 320, // Increased height to fix collision
            floating: false,
            pinned: true,
            backgroundColor: _primaryColor,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              // Logout button
              IconButton(
                onPressed: _logout,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    BoxIcons.bx_log_out,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                tooltip: 'Logout',
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Background design with gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _primaryColor,
                          const Color(0xFF303F9F), // Darker indigo
                          const Color(0xFF512DA8), // Deep purple
                        ],
                      ),
                    ),
                  ),

                  // Decorative elements
                  Positioned(
                    top: -30,
                    right: -20,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _secondaryColor.withOpacity(0.2),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 50,
                    left: -50,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 60,
                    right: -40,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),

                  // Header content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 30, 24, 120), // Added bottom padding
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Profile image
                            Stack(
                              children: [
                                Hero(
                                  tag: 'profile-image',
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 4),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                      image: DecorationImage(
                                        image: NetworkImage(student?.image ?? ''),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                                // Camera icon for image update
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: _changeImage,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: _tertiaryColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 3),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 5,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        BoxIcons.bx_camera,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 20),
                            // Name and ID
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    student?.name ?? 'John Doe',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      student?.regNo ?? 'REG12345',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _secondaryColor,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              BoxIcons.bxs_star,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'CGPA: ${student?.cgpa ?? '3.75'}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: _primaryColor,
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelColor: _primaryColor,
                  unselectedLabelColor: Colors.grey,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  tabs: [
                    Tab(
                      icon: Icon(BoxIcons.bx_user),
                      text: "Personal",
                    ),
                    Tab(
                      icon: Icon(BoxIcons.bx_book),
                      text: "Academic",
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Main Content
          SliverFillRemaining(
            hasScrollBody: true,
            child: Container(
              color: _backgroundColor,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Personal Info Tab - Using SingleChildScrollView to fix overflow
                  SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildPersonalInfoCard(student, screenWidth),
                        const SizedBox(height: 16),
                        _buildSystemInfoCard(student, screenWidth),
                        const SizedBox(height: 16), // Add extra space at bottom
                      ],
                    ),
                  ),

                  // Academic Info Tab - Using SingleChildScrollView to fix overflow
                  SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildAcademicInfoCard(student, screenWidth),
                        const SizedBox(height: 16), // Add extra space at bottom
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard(student, double screenWidth) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: _cardColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Bootstrap.person_fill, color: _primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Divider(color: Colors.grey.shade200, thickness: 1),
            const SizedBox(height: 12),

            _buildInfoItem(
              title: 'Username',
              value: student?.username ?? 'johndoe22',
              icon: Bootstrap.person_badge,
              screenWidth: screenWidth,
            ),

            _buildInfoItem(
              title: 'Email',
              value: student?.email ?? 'john.doe@example.com',
              icon: Bootstrap.envelope,
              isEditable: true,
              onEdit: _changeEmail,
              screenWidth: screenWidth,
            ),

            _buildInfoItem(
              title: 'Password',
              value: '••••••••',
              icon: Bootstrap.shield_lock,
              isEditable: true,
              onEdit: _changePassword,
              screenWidth: screenWidth,
            ),

            _buildInfoItem(
              title: 'Gender',
              value: student?.gender ?? 'Male',
              icon: Bootstrap.gender_ambiguous,
              screenWidth: screenWidth,
            ),

            _buildInfoItem(
              title: 'Guardian',
              value: student?.guardian ?? 'Robert Doe',
              icon: Bootstrap.people,
              screenWidth: screenWidth,
              isLast: true,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 300.ms);
  }

  Widget _buildAcademicInfoCard(student, double screenWidth) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: _cardColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Bootstrap.mortarboard_fill, color: _primaryColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Academic Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Divider(color: Colors.grey.shade200, thickness: 1),
            const SizedBox(height: 12),

            _buildInfoItem(
              title: 'Program',
              value: student?.program ?? 'Computer Science',
              icon: Bootstrap.laptop,
              screenWidth: screenWidth,
            ),

            _buildInfoItem(
              title: 'Section',
              value: student?.section ?? 'A',
              icon: Bootstrap.grid_3x3,
              screenWidth: screenWidth,
            ),

            _buildInfoItem(
              title: 'Intake Session',
              value: student?.intake ?? 'Fall 2023',
              icon: Bootstrap.calendar3,
              screenWidth: screenWidth,
            ),

            _buildInfoItem(
              title: 'Current Session',
              value: student?.currentSession ?? 'Spring 2024',
              icon: Bootstrap.calendar_check,
              screenWidth: screenWidth,
            ),

            _buildInfoItem(
              title: 'Total Enrollments',
              value: student?.totalEnrollments.toString() ?? '12',
              icon: Bootstrap.journal_text,
              screenWidth: screenWidth,
              isLast: true,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 300.ms);
  }

  Widget _buildSystemInfoCard(student, double screenWidth) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: _cardColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Bootstrap.gear_fill, color: _primaryColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  'System Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Divider(color: Colors.grey.shade200, thickness: 1),
            const SizedBox(height: 12),

            _buildInfoItem(
              title: 'User ID',
              value: student?.userId.toString() ?? '10045',
              icon: Bootstrap.fingerprint,
              screenWidth: screenWidth,
            ),

            _buildInfoItem(
              title: 'Student ID',
              value: student?.id.toString() ?? '1234',
              icon: Bootstrap.person_vcard,
              screenWidth: screenWidth,
            ),

            _buildInfoItem(
              title: 'Grader Status',
              value: student?.isGrader == true ? 'Active' : 'Inactive',
              icon: Bootstrap.patch_check,
              screenWidth: screenWidth,
              valueColor: student?.isGrader == true ? _secondaryColor : Colors.grey,
              valueIcon: student?.isGrader == true ? Bootstrap.check_circle_fill : Bootstrap.dash_circle,
              valueIconColor: student?.isGrader == true ? _secondaryColor : Colors.grey,
            ),

            _buildInfoItem(
              title: 'Current Week',
              value: student?.currentWeek.toString() ?? '6',
              icon: Bootstrap.calendar_week,
              screenWidth: screenWidth,
              isLast: true,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 300.ms);
  }

  Widget _buildInfoItem({
    required String title,
    required String value,
    required IconData icon,
    required double screenWidth,
    bool isEditable = false,
    VoidCallback? onEdit,
    Color? valueColor,
    IconData? valueIcon,
    Color? valueIconColor,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
          bottom: BorderSide(
            color: Colors.grey.shade100,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: _primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: _subtitleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    valueIcon != null
                        ? Icon(
                      valueIcon,
                      size: 16,
                      color: valueIconColor ?? _textColor,
                    )
                        : const SizedBox.shrink(),
                    valueIcon != null ? const SizedBox(width: 6) : const SizedBox.shrink(),
                    Flexible(
                      child: Text(
                        value,
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                        maxLines: 2,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: valueColor ?? _textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isEditable)
            IconButton(
              onPressed: onEdit,
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _tertiaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Bootstrap.pencil_square,
                  color: _tertiaryColor,
                  size: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
