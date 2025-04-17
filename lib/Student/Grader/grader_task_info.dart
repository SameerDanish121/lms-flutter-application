import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:icons_plus/icons_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

import 'package:lmsv2/api/ApiConfig.dart';
import '../../alerts/custom_alerts.dart';
import '../../file_view/pdf_word_file_viewer.dart';
import '../../teacher/task/mark_task.dart';



class GraderTaskScreen extends StatefulWidget {
  final String teacherName;
  final int graderId;

  const GraderTaskScreen({
    Key? key,
    required this.teacherName,
    required this.graderId,
  }) : super(key: key);

  @override
  State<GraderTaskScreen> createState() => _GraderTaskScreenState();
}

class _GraderTaskScreenState extends State<GraderTaskScreen> with SingleTickerProviderStateMixin {
  late Future<Map<String, dynamic>> _tasksData;
  late TabController _tabController;
  String _selectedFilter = 'All';
  final List<String> _filterOptions = ['All', 'Marked', 'Unmarked'];

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

  @override
  void initState() {
    super.initState();
    _tasksData = _fetchTasksData();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.index = 1; // Set Completed as default tab
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetchTasksData() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.apiBaseUrl}Grader/YourTask?grader_id=${widget.graderId}'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        CustomAlert.error(context, 'Failed!', 'Failed to load tasks data');
        throw Exception('Failed to load tasks data');
      }
    } catch (e) {
      CustomAlert.error(context, 'Error!', 'An error occurred while fetching data');
      throw Exception('Error: $e');
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _tasksData = _fetchTasksData();
    });
  }

  String _formatDateTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('d MMMM y h:mm a').format(dateTime);
    } catch (e) {
      return dateTimeStr;
    }
  }

  String _getTimeRemaining(String dueDateStr) {
    try {
      final dueDate = DateTime.parse(dueDateStr);
      final now = DateTime.now();
      final difference = dueDate.difference(now);

      if (difference.isNegative) {
        return 'Deadline passed';
      }

      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} left';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} left';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} left';
      } else {
        return 'Less than a minute left';
      }
    } catch (e) {
      return 'Invalid date';
    }
  }

  Color _getTaskStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'marked':
        return successColor;
      case 'un-marked':
        return warningColor;
      default:
        return previousColor;
    }
  }

  Color _getTaskTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'quiz':
        return Color(0xFF6F42C1);
      case 'assignment':
        return Color(0xFF20C997);
      case 'labtask':
        return Color(0xFFFD7E14);
      default:
        return primaryColor;
    }
  }

  Widget _buildPreAssignedTask(Map<String, dynamic> task) {
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
                    task['title'],
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
                    color: _getTaskTypeColor(task['type']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    task['type'].toString().toUpperCase(),
                    style: TextStyle(
                      color: _getTaskTypeColor(task['type']),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              '${task['Course Name']} - ${task['Section Name']}',
              style: TextStyle(
                color: textSecondary,
                fontSize: 13,
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Bootstrap.file_earmark_text,
                  size: 16,
                  color: primaryColor,
                ),
                SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PdfViewerScreen(
                          fileUrl: task['File'],
                          filename: task['title'],
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'View Task File',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Marks: ${task['Total Marks']}',
                      style: TextStyle(
                        fontSize: 13,
                        color: textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Start: ${_formatDateTime(task['start_date'])}',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getTaskStatusColor(task['marking_status']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        task['marking_status'].toString().toUpperCase(),
                        style: TextStyle(
                          color: _getTaskStatusColor(task['marking_status']),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _getTimeRemaining(task['due_date']),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getTimeRemaining(task['due_date']).contains('passed')
                            ? dangerColor
                            : textSecondary,
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

  Widget _buildCompletedTask(Map<String, dynamic> task) {
    final isMarked = task['marking_status'] == 'Marked';

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
                    task['title'],
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
                    color: isMarked
                        ? successColor.withOpacity(0.1)
                        : warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isMarked ? 'MARKED' : 'UNMARKED',
                    style: TextStyle(
                      color: isMarked ? successColor : warningColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              '${task['Course Name']} - ${task['Section Name']}',
              style: TextStyle(
                color: textSecondary,
                fontSize: 13,
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Bootstrap.file_earmark_text,
                  size: 16,
                  color: primaryColor,
                ),
                SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PdfViewerScreen(
                          fileUrl: task['File'],
                          filename: task['title'],
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'View Task File',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Marks: ${task['Total Marks']}',
                      style: TextStyle(
                        fontSize: 13,
                        color: textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Due: ${_formatDateTime(task['due_date'])}',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                      // Mark task
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MarkTaskScreen(task: task),
                        ),
                      ).then((_) => _refreshData());
                    },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isMarked ? primaryColor : successColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text(
                    isMarked ? 'View Submissions' : 'Mark Now',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            if (isMarked && task['marking_info'] != null) ...[
              SizedBox(height: 16),
              _buildMarkingSummary(task['marking_info']),
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

  Widget _buildMarkingSummary(Map<String, dynamic> markingInfo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Marking Summary',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Best',
                markingInfo['top']['student_name'],
                markingInfo['top']['obtained_marks'],
                markingInfo['top']['title'],
                successColor,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _buildSummaryCard(
                'Average',
                markingInfo['average']['student_name'],
                markingInfo['average']['obtained_marks'],
                markingInfo['average']['title'],
                warningColor,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _buildSummaryCard(
                'Worst',
                markingInfo['worst']['student_name'],
                markingInfo['worst']['obtained_marks'],
                markingInfo['worst']['title'],
                dangerColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String studentName, dynamic marks, String feedback, Color color) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            studentName,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4),
          Text(
            'Marks: $marks',
            style: TextStyle(
              fontSize: 11,
              color: textSecondary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            feedback,
            style: TextStyle(
              fontSize: 11,
              color: textSecondary,
              fontStyle: FontStyle.italic,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedTasksTab(List<dynamic> completedTasks) {
    // Filter completed tasks based on selection
    List<dynamic> filteredCompletedTasks = [];
    if (_selectedFilter == 'All') {
      filteredCompletedTasks = List.from(completedTasks);
    } else if (_selectedFilter == 'Marked') {
      filteredCompletedTasks = completedTasks.where((t) => t['marking_status'] == 'Marked').toList();
    } else {
      filteredCompletedTasks = completedTasks.where((t) => t['marking_status'] != 'Marked').toList();
    }

    // Sort unmarked to top
    filteredCompletedTasks.sort((a, b) {
      if (a['marking_status'] == 'Marked' && b['marking_status'] != 'Marked') {
        return 1;
      } else if (a['marking_status'] != 'Marked' && b['marking_status'] == 'Marked') {
        return -1;
      }
      return 0;
    });

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
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
                    value: _selectedFilter,
                    icon: Icon(
                      Bootstrap.chevron_down,
                      size: 14,
                      color: textSecondary,
                    ),
                    items: _filterOptions.map((String value) {
                      int count = 0;
                      if (value == 'All') {
                        count = completedTasks.length;
                      } else if (value == 'Marked') {
                        count = completedTasks.where((t) => t['marking_status'] == 'Marked').length;
                      } else {
                        count = completedTasks.where((t) => t['marking_status'] != 'Marked').length;
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
                        _selectedFilter = newValue!;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        if (filteredCompletedTasks.isNotEmpty)
          ...filteredCompletedTasks.map((task) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildCompletedTask(task),
          )).toList(),
        if (filteredCompletedTasks.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                'No tasks match the selected filter',
                style: TextStyle(
                  color: textSecondary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPreAssignedTasksTab(List<dynamic> preAssignedTasks) {
    return Column(
      children: [
        if (preAssignedTasks.isNotEmpty)
          ...preAssignedTasks.map((task) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildPreAssignedTask(task),
          )).toList(),
        if (preAssignedTasks.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Bootstrap.file_earmark_text,
                    size: 40,
                    color: textSecondary,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No pre-assigned tasks',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        title: Text(
          'Tasks - ${widget.teacherName}',
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
            Tab(text: 'Pre-Assigned'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: primaryColor,
        child: FutureBuilder<Map<String, dynamic>>(
          future: _tasksData,
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
                      'Failed to load tasks',
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
                (snapshot.data!['PreAssignedTasks'] == null &&
                    snapshot.data!['CompletedTasks'] == null)) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Bootstrap.file_earmark_text,
                      size: 40,
                      color: textSecondary,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No tasks available',
                      style: TextStyle(
                        fontSize: 16,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }

            final preAssignedTasks = snapshot.data!['PreAssignedTasks'] ?? [];
            final completedTasks = snapshot.data!['CompletedTasks'] ?? [];

            return TabBarView(
              controller: _tabController,
              children: [
                // Pre-Assigned Tab
                SingleChildScrollView(
                  child: _buildPreAssignedTasksTab(preAssignedTasks),
                ),

                // Completed Tab
                SingleChildScrollView(
                  child: _buildCompletedTasksTab(completedTasks),
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
        // Pre-Assigned Skeleton
        SingleChildScrollView(
          child: Column(
            children: List.generate(
              3,
                  (index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Completed Skeleton
        SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 100,
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
