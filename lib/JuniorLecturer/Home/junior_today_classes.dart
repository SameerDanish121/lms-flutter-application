import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:lmsv2/alerts/custom_alerts.dart';
import 'package:lmsv2/api/ApiConfig.dart';
import '../../Theme/theme.dart';
import '../../teacher/Home/today_classes.dart';
import '../MarkAttendance/MarkAttendance.dart';
import '../MarkAttendance/junior_ReTakeOrUpdateAttendance.dart';
class ClassPrompts {
  static Future<void> showTodayClasses(BuildContext context, int teacherId) async {
    try {
      CustomAlert.loading(context, 'Loading Your Classes', 'Please Wait ......... While we Fetch your Classes Details to Mark Attendance');
      final response = await http.get(
        Uri.parse('${ApiConfig.apiBaseUrl}JuniorLec/today?teacher_id=$teacherId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final classes = (data as List).map((e) => ClassModel.fromJson(e)).toList();

        final unmarked = classes.where((c) => c.attendanceStatus == 'Unmarked').toList();
        final marked = classes.where((c) => c.attendanceStatus == 'Marked').toList();
        final sortedClasses = [...unmarked, ...marked];
        Navigator.pop(context);
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: Column(
              children: [
                // Header Section
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 20),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Today\'s Schedule',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 22),
                            color: Colors.white.withOpacity(0.9),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('EEEE, MMMM d').format(DateTime.now()),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                // Status Indicators
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  color: AppTheme.backgroundColor,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatusChip('Unmarked: ${unmarked.length}', Colors.orange),
                      const SizedBox(width: 16),
                      _buildStatusChip('Marked: ${marked.length}', Colors.green),
                    ],
                  ),
                ),
                // Class List
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.only(top: 8, bottom: 20),
                    physics: const BouncingScrollPhysics(),
                    itemCount: sortedClasses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      return _ClassCard(
                        classInfo: sortedClasses[index],
                        index: index,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        Navigator.pop(context);
        CustomAlert.error(context,'Request Failed', 'Failed to load classes. Status code: ${response.statusCode}');
      }
    } catch (e) {
      Navigator.pop(context);
      CustomAlert.error(context, 'Request Failed', 'An error occurred: $e');
    }
  }
  static Widget _buildStatusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
      ),
    );
  }
  static void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error', style: TextStyle(color: Colors.red)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: AppTheme.primaryColor)),
          ),
        ],
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final ClassModel classInfo;
  final int index;
  const _ClassCard({required this.classInfo, required this.index});

  @override
  Widget build(BuildContext context) {
    final isUnmarked = classInfo.attendanceStatus == 'Unmarked';
    final primaryColor = isUnmarked ? AppTheme.primaryColor : Colors.green;

    return Padding(
      padding: EdgeInsets.only(
        top: index == 0 ? 0 : 6,
        bottom: 6,
        left: 12,
        right: 12,
      ),
      child: Card(
        elevation: 0,
        color: AppTheme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: AppTheme.dividerColor.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: isUnmarked ? () => _navigateToAttendance(context) : null,
          splashColor: primaryColor.withOpacity(0.1),
          highlightColor: Colors.transparent,
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200 + (index * 50)),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Course header row
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 24,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        classInfo.coursename,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textColor,
                        ),
                      ),
                    ),
                    _buildStatusIndicator(primaryColor),
                  ],
                ),
                const SizedBox(height: 12),
                // Class details
                _buildDetailRow(Icons.class_outlined, 'Section: ${classInfo.section}'),
                const SizedBox(height: 8),
                _buildDetailRow(Icons.room_outlined, 'Venue: ${classInfo.venue}'),
                const SizedBox(height: 8),
                _buildDetailRow(Icons.schedule_outlined, 'Time: ${classInfo.startTime} - ${classInfo.endTime}'),
                isUnmarked?_buildAttendanceButton(context):_buildAttendanceUpdateButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        classInfo.attendanceStatus,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.iconColor),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Align(
        alignment: Alignment.centerRight,
        child: Material(
          borderRadius: BorderRadius.circular(20),
          color: AppTheme.primaryColor,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _navigateToAttendance(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Mark Attendance',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward, size: 18, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToAttendance(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => JuniorAttendanceMarkingScreen(classRecord: classInfo),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutQuart,
            )),
            child: child,
          );
        },
      ),
    );
  }
  Widget _buildAttendanceUpdateButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Align(
        alignment: Alignment.centerRight,
        child: Material(
          borderRadius: BorderRadius.circular(20),
          color: Colors.green,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _navigateToUpdateAttendance(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Re-Take Marked Attendance',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward, size: 18, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToUpdateAttendance(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => JuniorAttendanceUpdateScreen(classRecord: classInfo),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutQuart,
            )),
            child: child,
          );
        },
      ),
    );
  }
}


