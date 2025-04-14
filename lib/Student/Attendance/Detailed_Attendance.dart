import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'package:percent_indicator/percent_indicator.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:async';

class AttendanceDetailScreen extends StatefulWidget {
  final Map<String, dynamic> courseData;

  const AttendanceDetailScreen({Key? key, required this.courseData}) : super(key: key);

  @override
  State<AttendanceDetailScreen> createState() => _AttendanceDetailScreenState();
}

class _AttendanceDetailScreenState extends State<AttendanceDetailScreen> {
  Map<String, dynamic> attendanceData = {};
  bool isLoading = true;
  bool hasError = false;
  Timer? _refreshTimer;
  int _selectedTabIndex = 0;

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
    // Auto-refresh every 5 minutes
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _fetchAttendanceData(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchAttendanceData({bool silent = false}) async {
    if (!silent) {
      setState(() {
        isLoading = true;
        hasError = false;
      });
    }

    try {
      final response = await http.get(
        Uri.parse('http://192.168.0.106:8000/api/Students/attendancePerSubject?teacher_offered_course_id=${widget.courseData['teacher_offered_course_id'].toString()}&student_id=36'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        setState(() {
          attendanceData = data['data'] as Map<String, dynamic>;
          isLoading = false;
        });
      } else {
        setState(() {
          hasError = true;
          isLoading = false;
        });
        if (!silent) _showErrorAlert('Failed to load attendance details');
      }
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
      if (!silent) _showErrorAlert('Network error occurred');
    }
  }

  void _showErrorAlert(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _contestAttendance(Map<String, dynamic> record) {
    // Implement your contest logic here
    // After successful contest, refresh the data
    _fetchAttendanceData();
  }

  String _formatDateTime(String dateTime) {
    try {
      final parsedDate = DateTime.parse(dateTime);
      return DateFormat('d/MMM/yyyy').format(parsedDate);
    } catch (e) {
      return dateTime;
    }
  }

  String _formatTime(String dateTime) {
    try {
      final parsedDate = DateTime.parse(dateTime);
      return DateFormat('h:mm a').format(parsedDate);
    } catch (e) {
      return dateTime;
    }
  }

  bool _canContest(Map<String, dynamic> record) {
    try {
      final recordDate = DateTime.parse(record['date_time']);
      final now = DateTime.now();
      final difference = now.difference(recordDate);

      return record['status'] == 'Absent' &&
          !record['contested'] &&
          difference.inHours < 24;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLabCourse = attendanceData['isLab'] == 'Lab';
    final classData = attendanceData['Class'] as Map<String, dynamic>? ?? {};
    final labData = attendanceData['Lab'] as Map<String, dynamic>? ?? {};

    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        title: Text(widget.courseData['course_name'].toString()),
        centerTitle: true,
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchAttendanceData,
        color: primaryColor,
        child: isLoading ? const SkeletonLoader() : _buildBody(isLabCourse, classData, labData),
      ),
    );
  }

  Widget _buildBody(bool isLabCourse, Map<String, dynamic> classData, Map<String, dynamic> labData) {
    if (hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 50, color: dangerColor),
            const SizedBox(height: 16),
            const Text('Failed to load attendance details',
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
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
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
          if (isLabCourse)
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
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedTabIndex = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedTabIndex == 0 ? primaryColor.withOpacity(0.1) : Colors.transparent,
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                        ),
                        child: Center(
                          child: Text(
                            'Class',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _selectedTabIndex == 0 ? primaryColor : textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedTabIndex = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedTabIndex == 1 ? primaryColor.withOpacity(0.1) : Colors.transparent,
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                        ),
                        child: Center(
                          child: Text(
                            'Lab',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _selectedTabIndex == 1 ? primaryColor : textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Attendance Summary Card
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
                Text(
                  _selectedTabIndex == 0 ? 'Class Attendance' : 'Lab Attendance',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                CircularPercentIndicator(
                  radius: 60,
                  lineWidth: 12,
                  percent: (_selectedTabIndex == 0
                      ? (classData['percentage'] ?? 0)
                      : (labData['percentage'] ?? 0)) / 100,
                  center: Text(
                    '${_selectedTabIndex == 0 ? classData['percentage'] : labData['percentage']}%',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  progressColor: (_selectedTabIndex == 0
                      ? (classData['percentage'] ?? 0)
                      : (labData['percentage'] ?? 0)) >= 75
                      ? successColor
                      : warningColor,
                  backgroundColor: primaryColor.withOpacity(0.1),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem(
                        'Total Classes',
                        _selectedTabIndex == 0
                            ? classData['total_classes'].toString()
                            : labData['total_classes'].toString(),
                        textPrimary
                    ),
                    _buildStatItem(
                        'Present',
                        _selectedTabIndex == 0
                            ? classData['total_present'].toString()
                            : labData['total_present'].toString(),
                        successColor
                    ),
                    _buildStatItem(
                        'Absent',
                        _selectedTabIndex == 0
                            ? classData['total_absent'].toString()
                            : labData['total_absent'].toString(),
                        dangerColor
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Attendance Records
          Text(
            'Attendance Records',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...((_selectedTabIndex == 0
              ? (classData['records'] as List<dynamic>? ?? [])
              : (labData['records'] as List<dynamic>? ?? [])).map<Widget>((record) {
            return _buildAttendanceRecordCard(record as Map<String, dynamic>);
          }).toList()),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceRecordCard(Map<String, dynamic> record) {
    final canContest = _canContest(record);
    final isContested = record['contested'] == true;
    final isAbsent = record['status'] == 'Absent';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                      _formatDateTime(record['date_time']),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _formatTime(record['date_time']),
                      style: TextStyle(
                        fontSize: 14,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: record['status'] == 'Present'
                        ? successColor.withOpacity(0.1)
                        : dangerColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: record['status'] == 'Present' ? successColor : dangerColor,
                    ),
                  ),
                  child: Text(
                    record['status'].toString(),
                    style: TextStyle(
                      color: record['status'] == 'Present' ? successColor : dangerColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Venue: ${record['venue']}',
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                  ),
                ),
                if (isAbsent)
                  ElevatedButton(
                    onPressed: canContest ? () => _contestAttendance(record) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isContested
                          ? textSecondary.withOpacity(0.5)
                          : primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text(
                      isContested ? 'Contested' : 'Contest',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
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