import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:icons_plus/icons_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:lmsv2/api/ApiConfig.dart';
import '../../alerts/custom_alerts.dart';

class StudentCoursesScreen extends StatefulWidget {
  final int studentId;

  const StudentCoursesScreen({
    Key? key,
    required this.studentId,
  }) : super(key: key);

  @override
  State<StudentCoursesScreen> createState() => _StudentCoursesScreenState();
}

class _StudentCoursesScreenState extends State<StudentCoursesScreen>
    with SingleTickerProviderStateMixin {
  late Future<Map<String, dynamic>> _coursesData;
  late TabController _tabController;
  String _selectedSession = 'All';
  List<String> _sessionOptions = ['All'];
  int _failedSubjectsCount = 0;

  // Color Scheme
  static const Color primaryColor = Color(0xFF4361EE);
  static const Color activeColor = Color(0xFF4CC9F0);
  static const Color previousColor = Color(0xFF6C757D);
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color textPrimary = Color(0xFF212529);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color successColor = Color(0xFF28A745);
  static const Color warningColor = Color(0xFFFFC107);
  static const Color dangerColor = Color(0xFFDC3545);
  static const Color cardBackground = Colors.white;
  static const Color infoColor = Color(0xFF17A2B8);

  @override
  void initState() {
    super.initState();
    _coursesData = _fetchCoursesData();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetchCoursesData() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.apiBaseUrl}Students/getAllEnrollments?student_id=${widget.studentId}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Extract session names for dropdown
        if (data['PreviousCourses'] != null) {
          final sessions = (data['PreviousCourses'] as Map<String, dynamic>).keys.toList();
          setState(() {
            _sessionOptions = ['All', ...sessions];
          });

          // Calculate failed subjects count
          _calculateFailedSubjects(data['PreviousCourses']);
        }

        return data;
      } else {
        CustomAlert.error(context, 'Failed!', 'Failed to load courses data');
        throw Exception('Failed to load courses data');
      }
    } catch (e) {
      CustomAlert.error(context, 'Error!', 'An error occurred while fetching data');
      throw Exception('Error: $e');
    }
  }

  void _calculateFailedSubjects(Map<String, dynamic> previousCourses) {
    int failedCount = 0;

    previousCourses.forEach((session, courses) {
      for (var course in courses) {
        if (course['grade'] == 'F') {
          failedCount++;
        }
      }
    });

    setState(() {
      _failedSubjectsCount = failedCount;
    });
  }

  Future<void> _refreshData() async {
    setState(() {
      _coursesData = _fetchCoursesData();
    });
  }

  Color _getCourseTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'core':
        return Color(0xFF6F42C1);
      case 'elective':
        return Color(0xFF20C997);
      case 'lab':
        return Color(0xFFFD7E14);
      default:
        return primaryColor;
    }
  }

  Color _getGradeColor(String? grade) {
    if (grade == null || grade == 'N/A') return textSecondary;

    switch (grade.toUpperCase()) {
      case 'A':
        return successColor;
      case 'B':
        return Color(0xFF5CB85C);
      case 'C':
        return warningColor;
      case 'D':
        return Color(0xFFFF851B);
      case 'F':
        return dangerColor;
      default:
        return textSecondary;
    }
  }

  Widget _buildCurrentCourseCard(Map<String, dynamic> course) {
    final isLab = course['Is'] == 'Lab';

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    course['course_name'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getCourseTypeColor(course['Type']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    course['Short Form'],
                    style: TextStyle(
                      color: _getCourseTypeColor(course['Type']),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              '${course['course_code']} • ${course['credit_hours']} Credit Hours • ${course['section']}',
              style: TextStyle(
                color: textSecondary,
                fontSize: 13,
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(course['teacher_image']),
                  onBackgroundImageError: (_, __) => Icon(Icons.person, size: 16),
                ),
                SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course['teacher_name'],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      '${course['Type']} • ${course['Is']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (isLab && course['junior_lecturer_name'] != null) ...[
              SizedBox(height: 8),
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: NetworkImage(course['junior_image']),
                    onBackgroundImageError: (_, __) => Icon(Icons.person, size: 16),
                  ),
                  SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course['junior_lecturer_name'],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        'Lab Instructor',
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    course['program'],
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        _showCourseOptions(course);
                      },
                      icon: Icon(
                        Bootstrap.three_dots_vertical,
                        size: 18,
                        color: primaryColor,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        _navigateToCourseDetails(course);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      child: Text(
                        'Follow Up',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(
      begin: 0.1,
      end: 0,
      duration: 250.ms,
      curve: Curves.easeOutQuad,
    );
  }

  Widget _buildPreviousCourseCard(Map<String, dynamic> course) {
    final isFailed = course['grade'] == 'F';
    final canReEnroll = course['can_re_enroll'] == 'Yes';
    final isLab = course['Is'] == 'Lab';
    final hasResultInfo = course['result Info'] != null &&
        course['result Info'] != 'N/A';

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color:cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    course['course_name'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isFailed ? dangerColor : textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getCourseTypeColor(course['Type']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    course['Short Form'],
                    style: TextStyle(
                      color: _getCourseTypeColor(course['Type']),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              '${course['course_code']} • ${course['credit_hours']} Credit Hours • ${course['section']}',
              style: TextStyle(
                color: textSecondary,
                fontSize: 13,
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(course['teacher_image']),
                  onBackgroundImageError: (_, __) => Icon(Icons.person, size: 16),
                ),
                SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course['teacher_name'] ?? 'N/A',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      '${course['Type']} • ${course['Is']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (isLab && course['junior_image'] != null) ...[
              SizedBox(height: 8),
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: NetworkImage(course['junior_image']),
                    onBackgroundImageError: (_, __) => Icon(Icons.person, size: 16),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Lab Instructor',
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getGradeColor(course['grade']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getGradeColor(course['grade']),
                    ),
                  ),
                  child: Text(
                    'Grade: ${course['grade'] ?? 'N/A'}',
                    style: TextStyle(
                      color: _getGradeColor(course['grade']),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (isFailed && canReEnroll)
                  ElevatedButton(
                    onPressed: () {
                      _showReEnrollDialog(course);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: dangerColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    child: Text(
                      'Request Re-Enroll',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                if (course['grade'] == 'D' && canReEnroll)
                  ElevatedButton(
                    onPressed: () {
                      _showImproveDialog(course);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: warningColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    child: Text(
                      'Request Improvement',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            if (hasResultInfo) ...[
              SizedBox(height: 12),
              _buildResultInfo(course['result Info']),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(
      begin: 0.1,
      end: 0,
      duration: 250.ms,
      curve: Curves.easeOutQuad,
    );
  }

  Widget _buildResultInfo(dynamic resultInfo) {
    if (resultInfo == null || resultInfo == 'N/A' || resultInfo=='Failed') return SizedBox();

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(
        'View Result Details',
        style: TextStyle(
          fontSize: 13,
          color: primaryColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              _buildResultDetailItem('Mid Term', resultInfo['mid']?.toString() ?? 'N/A'),
              _buildResultDetailItem('Final Term', resultInfo['final']?.toString() ?? 'N/A'),
              _buildResultDetailItem('Internal', resultInfo['internal']?.toString() ?? 'N/A'),
              if (resultInfo['lab'] != null)
                _buildResultDetailItem('Lab', resultInfo['lab']?.toString() ?? 'N/A'),
              _buildResultDetailItem('Quality Points', resultInfo['quality_points']?.toString() ?? 'N/A'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentCoursesTab(List<dynamic> currentCourses) {
    return Column(
      children: [
        if (currentCourses.isNotEmpty)
          ...currentCourses.map((course) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildCurrentCourseCard(course),
          )).toList(),
        if (currentCourses.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Bootstrap.book,
                    size: 40,
                    color: textSecondary,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No current courses',
                    style: TextStyle(
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPreviousCoursesTab(Map<String, dynamic> previousCourses) {
    // Filter courses based on selected session
    List<dynamic> filteredCourses = [];
    if (_selectedSession == 'All') {
      previousCourses.forEach((session, courses) {
        filteredCourses.addAll(courses);
      });
    } else {
      filteredCourses = previousCourses[_selectedSession] ?? [];
    }

    // Sort by session date (newest first)
    filteredCourses.sort((a, b) {
      final dateA = DateTime.parse(a['session_start']);
      final dateB = DateTime.parse(b['session_start']);
      return dateB.compareTo(dateA);
    });

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _failedSubjectsCount > 0 ? dangerColor.withOpacity(0.1) : successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _failedSubjectsCount > 0 ? dangerColor.withOpacity(0.3) : successColor.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  'Failed Subjects: $_failedSubjectsCount',
                  style: TextStyle(
                    color: _failedSubjectsCount > 0 ? dangerColor : successColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: textSecondary.withOpacity(0.2),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedSession,
                    icon: Icon(
                      Bootstrap.chevron_down,
                      size: 14,
                      color: textSecondary,
                    ),
                    items: _sessionOptions.map((String value) {
                      int count = 0;
                      if (value == 'All') {
                        count = previousCourses.values.fold<int>(0, (sum, courses) => sum + (courses as List).length);
                      } else {
                        count = (previousCourses[value] as List?)?.length ?? 0;
                      }

                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          '$value ($count)',
                          style: TextStyle(
                            fontSize: 13,
                            color: textPrimary,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedSession = newValue!;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        if (filteredCourses.isNotEmpty)
          ...filteredCourses.map((course) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildPreviousCourseCard(course),
          )).toList(),
        if (filteredCourses.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Bootstrap.book,
                    size: 40,
                    color: textSecondary,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No courses found for selected session',
                    style: TextStyle(
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _showCourseOptions(Map<String, dynamic> course) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Bootstrap.calendar_check, color: primaryColor),
                title: Text('Lesson Plan'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToLessonPlan(course);
                },
              ),
              ListTile(
                leading: Icon(Bootstrap.bar_chart, color: primaryColor),
                title: Text('Academic Report'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToAcademicReport(course);
                },
              ),
              ListTile(
                leading: Icon(Bootstrap.clipboard_check, color: primaryColor),
                title: Text('Attendance'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToAttendance(course);
                },
              ),
              ListTile(
                leading: Icon(Bootstrap.file_earmark_text, color: primaryColor),
                title: Text('Exams'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToExams(course);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToCourseDetails(Map<String, dynamic> course) {
    // Implement navigation to course details
    print('Navigating to course details: ${course['course_name']}');
  }

  void _navigateToLessonPlan(Map<String, dynamic> course) {
    // Implement navigation to lesson plan
    print('Navigating to lesson plan: ${course['course_name']}');
  }

  void _navigateToAcademicReport(Map<String, dynamic> course) {
    // Implement navigation to academic report
    print('Navigating to academic report: ${course['course_name']}');
  }

  void _navigateToAttendance(Map<String, dynamic> course) {
    // Implement navigation to attendance
    print('Navigating to attendance: ${course['course_name']}');
  }

  void _navigateToExams(Map<String, dynamic> course) {
    // Implement navigation to exams
    print('Navigating to exams: ${course['course_name']}');
  }

  void _showReEnrollDialog(Map<String, dynamic> course) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Re-Enroll Request'),
          content: Text(
            'This subject (${course['course_name']}) is offered in the current session. '
                'You can request to re-enroll in this course. '
                'Please contact the admin office for further assistance.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                CustomAlert.success(context, 'Request Sent \n Your re-enroll request for ${course['course_name']} has been submitted.');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: dangerColor,
              ),
              child: Text('Request Re-Enroll'),
            ),
          ],
        );
      },
    );
  }

  void _showImproveDialog(Map<String, dynamic> course) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Grade Improvement'),
          content: Text(
            'You can request to improve your grade (${course['grade']}) in '
                '${course['course_name']}. This will allow you to retake exams '
                'to improve your marks.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                CustomAlert.success(context, 'Request Sent \n Your improvement request for ${course['course_name']} has been submitted.');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: warningColor,
              ),
              child: Text('Request Improvement'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        title: Text(
          'My Courses',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          tabs: [
            Tab(text: 'Current Courses'),
            Tab(text: 'Previous Courses'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: primaryColor,
        child: FutureBuilder<Map<String, dynamic>>(
          future: _coursesData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildSkeletonLoader();
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Bootstrap.exclamation_triangle,
                      size: 40,
                      color: dangerColor,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Failed to load courses',
                      style: TextStyle(
                        fontSize: 16,
                        color: textPrimary,
                      ),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _refreshData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Retry',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            } else if (!snapshot.hasData ||
                (snapshot.data!['CurrentCourses'] == null &&
                    snapshot.data!['PreviousCourses'] == null)) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Bootstrap.book,
                      size: 40,
                      color: textSecondary,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No courses available',
                      style: TextStyle(
                        fontSize: 16,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }

            final currentCourses = snapshot.data!['CurrentCourses'] ?? [];
            final previousCourses = snapshot.data!['PreviousCourses'] ?? {};

            return TabBarView(
              controller: _tabController,
              children: [
                // Current Courses Tab
                SingleChildScrollView(
                  child: _buildCurrentCoursesTab(currentCourses),
                ),

                // Previous Courses Tab
                SingleChildScrollView(
                  child: _buildPreviousCoursesTab(previousCourses),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return TabBarView(
      controller: _tabController,
      children: [
        // Current Courses Skeleton
        SingleChildScrollView(
          child: Column(
            children: List.generate(
              3,
                  (index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Previous Courses Skeleton
        SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 150,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    Container(
                      width: 120,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: textSecondary.withOpacity(0.2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ...List.generate(
                3,
                    (index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    height: 220,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}