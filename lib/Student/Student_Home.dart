import 'dart:async';

import 'package:flutter/material.dart';
import 'package:awesome_bottom_bar/awesome_bottom_bar.dart';
import 'package:flutter/services.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:lmsv2/Student/Profile.dart';
import 'package:lmsv2/Student/student_notification.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../provider/student_provider.dart';
import 'Attendance/Overall_Attendance.dart';
import 'Dashboard/Student_Main_AcedamciReport.dart';
import 'Dashboard/Student_Main_CourseContent.dart';
import 'Dashboard/Student_Main_DueTaskTab.dart';
import 'Dashboard/Student_Main_Home.dart';
import 'Dashboard/Stundet_Main_Timetable.dart';

class StudentHome extends StatefulWidget {
  const StudentHome({Key? key}) : super(key: key);

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _animationController;

  final List<Widget> _tabs = [
    const HomeTab(),
    const CourseContentTab(),
    const DueTaskTab(),
    const AcademicReportTab(),
    const TimetableTab(),
  ];

  final List<TabItem> _bottomBarItems = [
    const TabItem(
      icon: Icons.home_rounded,

      title: 'Home',
    ),
    const TabItem(
      icon: Icons.menu_book_rounded,
      title: 'Courses',
    ),
    const TabItem(
      icon: Icons.menu_book_rounded,
      title: 'Due Task',
    ),
    const TabItem(
      icon: Icons.task_alt_rounded,
      title: 'Tasks',
    ),
    const TabItem(
      icon: Icons.insert_chart_rounded,
      title: 'Reports',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _selectedIndex = 0; // Start with Home tab
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FD),
      extendBody: true,
      appBar: _buildAppBar(),
      drawer: _buildDrawer(context),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigation(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF3949AB),
      elevation: 0,
      scrolledUnderElevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              BoxIcons.bxs_graduation,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _getAppBarTitle(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ).animate().fadeIn(duration: 200.ms).slideX(
            begin: 0.2,
            end: 0,
            duration: 300.ms,
            curve: Curves.easeOutQuad,
          ),
        ],
      ),
      leading: IconButton(
        icon: const Icon(BoxIcons.bx_menu, color: Colors.white, size: 28),
        onPressed: () {
          _scaffoldKey.currentState?.openDrawer();
        },
      ),
      actions: [
        IconButton(
          icon: Stack(
            children: [
              const Icon(BoxIcons.bx_bell, color: Colors.white, size: 26),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 12,
                    minHeight: 12,
                  ),
                  child: const Text(
                    '3',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            ],
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>  NotificationScreen(),
              ),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(8),
        child: Container(),
      ),
    );
  }

  String _getAppBarTitle() {
    // switch (_selectedIndex) {
    //   case 0:
    //     return 'Schedule';
    //   case 1:
    //     return 'Dashboard';
    //   case 2:
    //     return 'Course Content';
    //   case 3:
    //     return 'Due Tasks';
    //   case 4:
    //     return 'Academic Report';
    //   default:
    //     return 'LMS';
    // }
    return 'LMS';
  }

  Widget _buildBody() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Stack(
        children: [
          // Background design elements
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF3949AB).withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF3949AB).withOpacity(0.07),
              ),
            ),
          ),
          // Main content
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            child: _tabs[_selectedIndex],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: BottomBarFloating(
        items: _bottomBarItems,
        backgroundColor: Colors.transparent,
        color: Colors.grey.shade600,
        colorSelected: const Color(0xFF3949AB),
        indexSelected: _selectedIndex,
        paddingVertical: 12,
        onTap: (index) {
          if (index != _selectedIndex) {
            setState(() {
              _selectedIndex = index;
            });
            // Add a small haptic feedback
            HapticFeedback.lightImpact();
            _animationController.reset();
            _animationController.forward();
          }
        },
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () {
        // Quick action button - maybe for attendance check-in or something important
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (context) => _buildQuickActionsSheet(),
        );
      },
      backgroundColor: const Color(0xFF3949AB),
      elevation: 8,
      child: const Icon(
        Icons.add,
        color: Colors.white,
        size: 28,
      ),
    ).animate(controller: _animationController).scaleXY(
      begin: 0.8,
      end: 1.0,
      curve: Curves.elasticOut,
      duration: const Duration(milliseconds: 600),
    );
  }

  Widget _buildQuickActionsSheet() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.all(Radius.circular(10),
              ),
            ),
          ),),
          SizedBox(height: 20),
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3949AB),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              children: [
                _buildQuickActionItem(BoxIcons.bx_check_square, 'Mark\nAttendance', Colors.green),
                _buildQuickActionItem(BoxIcons.bx_file, 'Submit\nAssignment', Colors.orange),
                _buildQuickActionItem(BoxIcons.bx_calendar, 'View\nSchedule', Colors.blue),
                _buildQuickActionItem(BoxIcons.bx_book_open, 'Study\nMaterials', Colors.purple),
                _buildQuickActionItem(BoxIcons.bx_help_circle, 'Ask\nHelp', Colors.red),
                _buildQuickActionItem(BoxIcons.bx_line_chart, 'Check\nGrades', Colors.teal),
              ],
            ),
          ),
        ],
      ),
    ).animate().slideY(
      begin: 1.0,
      end: 0.0,
      duration: 300.ms,
      curve: Curves.easeOutQuad,
    );
  }

  Widget _buildQuickActionItem(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Icon(
            icon,
            color: color,
            size: 30,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 100.ms).slideY(
      begin: 0.2,
      end: 0,
      delay: 100.ms,
      duration: 300.ms,
      curve: Curves.easeOutQuad,
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final studentProvider = Provider.of<StudentProvider>(context);
    final student = studentProvider.student;

    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3949AB), Color(0xFF303F9F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundImage: student?.image != null
                            ? NetworkImage(student!.image!)
                            : const AssetImage('assets/default_avatar.png') as ImageProvider,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            student?.name ?? 'Student Name',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              student?.regNo ?? 'Registration Number',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_user,
                        color: Colors.white,
                        size: 12,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Active Student',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _buildDrawerItem(BoxIcons.bx_user_circle, 'My Profile', () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          }),
          _buildDrawerItem(BoxIcons.bx_calendar_check, 'Attendance', () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AttendanceOverviewScreen()),
            );
          }),
          _buildDrawerItem(BoxIcons.bx_file, 'Documents', () {
            Navigator.pop(context);
          }),
          _buildDrawerItem(BoxIcons.bx_book_bookmark, 'Courses', () {
            Navigator.pop(context);
            setState(() {
              _selectedIndex = 2;
            });
          }),
          _buildDrawerItem(BoxIcons.bx_money, 'Fees & Payments', () {
            Navigator.pop(context);
          }),
          const Divider(height: 35),
          _buildDrawerItem(BoxIcons.bx_cog, 'Settings', () {
            Navigator.pop(context);
          }),
          _buildDrawerItem(BoxIcons.bx_help_circle, 'Help & Support', () {
            Navigator.pop(context);
          }),
          const SizedBox(height: 20),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                BoxIcons.bx_log_out,
                color: Colors.red,
              ),
            ),
            title: const Text(
              'Logout',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Logout'),
                        onPressed: () {
                          studentProvider.logout();
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF3949AB).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF3949AB),
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}