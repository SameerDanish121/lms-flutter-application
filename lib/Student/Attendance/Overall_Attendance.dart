import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lmsv2/api/ApiConfig.dart';
import 'package:provider/provider.dart';
import 'package:quickalert/quickalert.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

import '../../alerts/custom_alerts.dart';
import '../../provider/student_provider.dart';
import 'Detailed_Attendance.dart';

class AttendanceOverviewScreen extends StatefulWidget {
  const AttendanceOverviewScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceOverviewScreen> createState() => _AttendanceOverviewScreenState();
}

class _AttendanceOverviewScreenState extends State<AttendanceOverviewScreen> {
  List<dynamic> attendanceData = [];
  bool isLoading = true;
  bool hasError = false;
  int totalClasses = 0;
  int totalPresent = 0;
  double overallPercentage = 0.0;
  String currentSession = "Spring 2025";
  int currentWeek = 7;
  String shortData='';
  bool isShort=false;
  // Color Scheme
  static const Color primaryColor = Color(0xFF4361EE);
  static const Color secondaryColor = Color(0xFF3A0CA3);
  static const Color accentColor = Color(0xFF7209B7);
  static const Color successColor = Color(0xFF4CC9F0);
  static const Color warningColor = Color(0xFFF8961E);
  static const Color dangerColor = Color(0xFFF94144);
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color cardBackground = Colors.white;
  static const Color textPrimary = Color(0xFF212529);
  static const Color textSecondary = Color(0xFF6C757D);

  @override
  void initState() {
    super.initState();
    _fetchAttendanceData();
  }

  Future<void> _fetchAttendanceData() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    int? StudentId=studentProvider.student?.id;
    currentSession=studentProvider.student!.currentSession.toString();
    currentWeek=studentProvider.student?.currentWeek as int;
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.apiBaseUrl}Students/attendance?student_id=$StudentId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          attendanceData = data['data'];
          _calculateTotals();
          isLoading = false;
        });
      } else {
        setState(() {
          hasError = true;
          isLoading = false;
        });
        _showErrorAlert('Failed to load attendance data');
      }
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
      _showErrorAlert('Network error occurred');
    }
  }

  void _calculateTotals() {
    totalClasses = 0;
    totalPresent = 0;
    for (var course in attendanceData) {
      totalClasses += course['Total_classes_conducted'] as int;
      totalPresent += course['total_present'] as int;
      double per = course['Percentage'] is double
          ? course['Percentage']
          : double.tryParse(course['Percentage'].toString()) ?? 0;

      if (per < 75) {
        isShort = true;
        shortData = '$shortData, ${course['course_name']} : ${per.toStringAsFixed(1)}';
      }

    }

    overallPercentage = totalClasses > 0 ? (totalPresent / totalClasses) * 100 : 0.0;
  }

  void _showErrorAlert(String message) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.error,
      title: 'Error',
      text: message,
      confirmBtnColor: primaryColor,
    );
  }

  String _formatDateTime(String dateTime) {
    try {
      final parsedDate = DateTime.parse(dateTime);
      final now = DateTime.now();
      final difference = now.difference(parsedDate);

      if (difference.inDays > 30) {
        return 'Updated ${(difference.inDays / 30).floor()}mo ago';
      } else if (difference.inDays > 0) {
        return 'Updated ${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return 'Updated ${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return 'Updated ${difference.inMinutes}m ago';
      } else {
        return 'Updated just now';
      }
    } catch (e) {
      return 'Updated recently';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        title: const Text('Overall Attendance',
            style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchAttendanceData,
        color: primaryColor,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const SkeletonLoader();
    }

    if (hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 50, color: dangerColor),
            const SizedBox(height: 16),
            const Text('Failed to load attendance data',
                style: TextStyle(color: textPrimary)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchAttendanceData,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Retry',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Session Info Card
          Container(
            decoration: BoxDecoration(
              color: cardBackground,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current Session',
                      style: TextStyle(
                        fontSize: 14,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(currentSession,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current Week',
                      style: TextStyle(
                        fontSize: 14,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('Week $currentWeek',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Disclaimer for low attendance
          if (isShort)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: warningColor.withOpacity(0.3)),
              ),
              child: Text(
                '⚠️ Your overall attendance is below 75% in $shortData. According to university policy, you may not be allowed to sit in the final exam if your attendance remains below this threshold.',
                style: TextStyle(
                  color: warningColor,
                  fontSize: 14,
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Overall Attendance Card
          Container(
            decoration: BoxDecoration(
              color: cardBackground,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text('Overall Attendance This Session',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                CircularPercentIndicator(
                  radius: 60,
                  lineWidth: 12,
                  percent: overallPercentage / 100,
                  center: Text(
                    '${overallPercentage.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  progressColor: overallPercentage >= 75 ? successColor : warningColor,
                  backgroundColor: primaryColor.withOpacity(0.1),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem('Total Classes', totalClasses.toString(), textPrimary),
                    _buildStatItem('Present', totalPresent.toString(), successColor),
                    _buildStatItem('Absent', (totalClasses - totalPresent).toString(), dangerColor),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Course-wise Attendance
          Text('Course-wise Attendance',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...attendanceData.map((course) => _buildCourseAttendanceCard(course)).toList(),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label,
          style: TextStyle(
            fontSize: 14,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildCourseAttendanceCard(Map<String, dynamic> course) {
    bool isExpanded = false;
    final percentage = course['Percentage'] / 100;
    final isLowAttendance = percentage < 0.75;
    final hasPendingRequests = course['pending_requests_count'] > 0;

    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          decoration: BoxDecoration(
            color: cardBackground,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course['course_name'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${course['course_code']} • ${course['section_name']}',
                            style: TextStyle(
                              fontSize: 14,
                              color: textSecondary,
                            ),
                          ),
                          Text(
                            course['course_lab'] == 'Theory' ? 'Class' : 'Class+Lab (Combined)',
                            style: TextStyle(
                              fontSize: 13,
                              color: textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDateTime(course['Updated_at']),
                            style: TextStyle(
                              fontSize: 12,
                              color: textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CircularPercentIndicator(
                      radius: 30,
                      lineWidth: 6,
                      percent: percentage,
                      center: Text(
                        '${course['Percentage']}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: isLowAttendance ? warningColor : successColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      progressColor: isLowAttendance ? warningColor : successColor,
                      backgroundColor: primaryColor.withOpacity(0.1),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildAttendanceStat('Conducted', course['Total_classes_conducted'].toString(), textPrimary),
                    const SizedBox(width: 16),
                    _buildAttendanceStat('Present', course['total_present'].toString(), successColor),
                    const SizedBox(width: 16),
                    _buildAttendanceStat('Absent', course['total_absent'].toString(), dangerColor),
                  ],
                ),
                if (hasPendingRequests) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: warningColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${course['pending_requests_count']} Pending Requests',
                          style: TextStyle(
                            color: warningColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              isExpanded = !isExpanded;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: warningColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isExpanded ? 'Hide' : 'View',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                              Icon(
                                isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                size: 16,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (isExpanded && hasPendingRequests)
                  ...course['pending_requests'].map<Widget>((request) {
                    return Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: lightBackground,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Date: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(request['date_time']))}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    'Venue: ${request['venue']}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    'To : ${request['type']}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  int id = request['id'] as int;
                                  bool? confirm = await CustomAlert.confirm(
                                    context,
                                    'Are you sure you want to withdraw this contested attendance request?',
                                  );

                                  if (confirm == true) {
                                    await CustomAlert.performWithLoading(
                                      context: context,
                                      loadingText: 'Withdrawing request...',
                                      task: () async {
                                        final response = await http.delete(
                                          Uri.parse('${ApiConfig.apiBaseUrl}Students/contested-attendance/$id/withdraw'),
                                        );
                                        if (response.statusCode == 200) {
                                          // Optional: refresh list if you have a method like _fetchAttendanceData();
                                          _fetchAttendanceData();
                                        } else {
                                          final data = jsonDecode(response.body);
                                          throw Exception(data['message'] ?? 'Failed to withdraw contested request.');
                                        }
                                      },
                                      successMessage: 'Contested attendance request withdrawn successfully!',
                                      errorMessage: 'Could not withdraw the contested attendance request.',
                                    );
                                  }
                                },

                                style: ElevatedButton.styleFrom(
                                  backgroundColor: dangerColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                ),
                                child: const Text(
                                  'Withdraw',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AttendanceDetailScreen(courseData:course),
                        ),
                      );
                      // Navigate to detailed attendance screen
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'View Detailed Attendance',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttendanceStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
          style: TextStyle(
            fontSize: 12,
            color: textSecondary,
          ),
        ),
        Text(value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class SkeletonLoader extends StatelessWidget {
  const SkeletonLoader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 200,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 80,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 120,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ).animate(
          delay: Duration(milliseconds: index * 100),
          onPlay: (controller) => controller.repeat(),
        ).shimmer(duration: 1000.ms),
      ),
    );
  }
}