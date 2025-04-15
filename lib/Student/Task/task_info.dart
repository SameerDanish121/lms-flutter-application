import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lmsv2/api/ApiConfig.dart';
import 'package:provider/provider.dart';
import 'package:quickalert/quickalert.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:convert';
import 'package:icons_plus/icons_plus.dart';
import '../../file_view/pdf_word_file_viewer.dart';
import '../../provider/student_provider.dart';

class YourTasksScreen extends StatefulWidget {
  const YourTasksScreen({Key? key}) : super(key: key);

  @override
  State<YourTasksScreen> createState() => _YourTasksScreenState();
}

class _YourTasksScreenState extends State<YourTasksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic> taskData = {};
  final Map<int, bool> _mcqsExpansionState = {};
  bool isLoading = true;
  bool hasError = false;
  Timer? _timer;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Enhanced Color Scheme
  static const Color primaryColor = Color(0xFF4361EE);
  static const Color secondaryColor = Color(0xFF3A0CA3);
  static const Color accentColor = Color(0xFF7209B7);
  static const Color successColor = Color(0xFF4CC9F0);
  static const Color warningColor = Color(0xFFF8961E);
  static const Color dangerColor = Color(0xFFF94144);
  static const Color urgentColor = Color(0xFFFF3860);
  static const Color assignmentColor = Color(0xFF38A3A5);
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color cardBackground = Colors.white;
  static const Color textPrimary = Color(0xFF212529);
  static const Color textSecondary = Color(0xFF6C757D);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchTaskData();
    // Start a timer to update time remaining every second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _timer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchTaskData() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    int? studentId = studentProvider.student?.id;

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.apiBaseUrl}Students/task/details?student_id=$studentId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          taskData = data['TaskDetails'];
          isLoading = false;
        });
      } else {
        setState(() {
          hasError = true;
          isLoading = false;
        });
        _showErrorAlert('Failed to load task data');
      }
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
      _showErrorAlert('Network error occurred');
    }
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
      return DateFormat('d MMM y, h:mm a').format(parsedDate);
    } catch (e) {
      return dateTime;
    }
  }

  String _timeAgo(String dateTime) {
    try {
      final parsedDate = DateTime.parse(dateTime);
      final now = DateTime.now();
      final difference = now.difference(parsedDate);

      if (difference.inDays > 30) {
        return '${(difference.inDays / 30).floor()}mo ago';
      } else if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'just now';
      }
    } catch (e) {
      return 'recently';
    }
  }

  String _timeRemaining(String dueDate) {
    try {
      final due = DateTime.parse(dueDate);
      final now = DateTime.now();
      if (now.isAfter(due)) return 'Ended';

      final difference = due.difference(now);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ${difference.inHours.remainder(24)}h ${difference.inMinutes.remainder(60)}m ${difference.inSeconds.remainder(60)}s';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ${difference.inMinutes.remainder(60)}m ${difference.inSeconds.remainder(60)}s';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ${difference.inSeconds.remainder(60)}s';
      } else {
        return '${difference.inSeconds}s';
      }
    } catch (e) {
      return 'N/A';
    }
  }

  String _timeUntilStart(String startDate) {
    try {
      final start = DateTime.parse(startDate);
      final now = DateTime.now();
      if (now.isAfter(start)) return 'Started';

      final difference = start.difference(now);

      if (difference.inDays > 0) {
        return 'Starts in ${difference.inDays}d ${difference.inHours.remainder(24)}h';
      } else if (difference.inHours > 0) {
        return 'Starts in ${difference.inHours}h ${difference.inMinutes.remainder(60)}m';
      } else if (difference.inMinutes > 0) {
        return 'Starts in ${difference.inMinutes}m';
      } else {
        return 'Starting soon';
      }
    } catch (e) {
      return 'N/A';
    }
  }

  bool _isUrgent(String dueDate) {
    try {
      final due = DateTime.parse(dueDate);
      final now = DateTime.now();
      return due.difference(now).inHours < 24;
    } catch (e) {
      return false;
    }
  }

  List<dynamic> _filterCompletedTasks(List<dynamic> tasks) {
    if (_searchQuery.isEmpty) return tasks;
    return tasks.where((task) =>
    task['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
        task['course_name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
        task['type'].toString().toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        title: Row(
          children: [
            const SizedBox(width: 8),
            const Text('Your Tasks',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          tabs: [
            Tab(
              // icon: const Icon(Icons.access_time_filled, size: 20),
              text: 'Active (${taskData['Active_Tasks']?.length ?? 0})',
            ),
            Tab(
              // icon: const Icon(Icons.calendar_today, size: 20),
              text: 'Upcoming (${taskData['Upcoming_Tasks']?.length ?? 0})',
            ),
            Tab(
              // icon: const Icon(Icons.check_circle, size: 20),
              text: 'Completed (${taskData['Completed_Tasks']?.length ?? 0})',
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchTaskData,
        color: primaryColor,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const TaskSkeletonLoader();
    }

    if (hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 50, color: dangerColor),
            const SizedBox(height: 16),
            const Text('Failed to load task data',
                style: TextStyle(color: textPrimary)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchTaskData,
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

    return TabBarView(
      controller: _tabController,
      children: [
        _buildActiveTasks(),
        _buildUpcomingTasks(),
        _buildCompletedTasks(),
      ],
    );
  }

  Widget _buildActiveTasks() {
    List<dynamic> activeTasks = taskData['Active_Tasks'] as List<dynamic>? ?? [];

    // Sort by due date (closest first)
    activeTasks.sort((a, b) => DateTime.parse(a['due_date']).compareTo(DateTime.parse(b['due_date'])));

    if (activeTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in, size: 60, color: textSecondary.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text('No active tasks',
              style: TextStyle(
                fontSize: 18,
                color: textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              'Tasks due soonest appear first',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, index) {
              final task = activeTasks[index];
              final isMcqs = task['type'] == 'MCQS';
              final hasSubmission = task['Your_Submission'] != null && task['Your_Submission'] != 'N/A';
              final canAttempt = !hasSubmission && (isMcqs || task['type'] == 'Quiz' || task['type'] == 'Assignment' || task['type'] == 'LabTask');
              final isUrgent = _isUrgent(task['due_date']);

              return Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
                  border: isUrgent
                      ? Border.all(color: urgentColor.withOpacity(0.3), width: 1.5)
                      : null,
                ),
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
                                  task['title'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  task['course_name'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getTaskTypeColor(task['type']).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: _getTaskTypeColor(task['type']).withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              task['type'],
                              style: TextStyle(
                                fontSize: 12,
                                color: _getTaskTypeColor(task['type']),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildTaskStat('Points', '${task['points']}', textPrimary),
                          const SizedBox(width: 16),
                          _buildTaskStat('Started', _timeAgo(task['start_date']), textPrimary),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTaskStat('Due Date', _formatDateTime(task['due_date']), textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isUrgent
                              ? urgentColor.withOpacity(0.1)
                              : primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isUrgent ? 'Urgent! Time remaining' : 'Time remaining',
                              style: TextStyle(
                                color: isUrgent ? urgentColor : primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _timeRemaining(task['due_date']),
                              style: TextStyle(
                                color: isUrgent ? urgentColor : primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ).animate(onPlay: (controller) => controller.repeat())
                                .shimmer(duration: 1000.ms, color: (isUrgent ? urgentColor : primaryColor).withOpacity(0.5)),
                          ],
                        ),
                      ),
                      if (hasSubmission) ...[
                        const SizedBox(height: 12),
                        _buildTaskStat('Submitted', _timeAgo(task['Submission_Date_Time']), successColor),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              _navigateToViewSubmissionScreen(context, task);
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: successColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.assignment_turned_in, size: 18),
                            label: const Text('View Submission'),
                          ),
                        ),
                      ],
                      if (canAttempt) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _navigateToAttemptScreen(context, task);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text(
                              'Attempt Now',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
            childCount: activeTasks.length,
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingTasks() {
    List<dynamic> upcomingTasks = taskData['Upcoming_Tasks'] as List<dynamic>? ?? [];

    // Sort by start date (soonest first)
    upcomingTasks.sort((a, b) => DateTime.parse(a['start_date']).compareTo(DateTime.parse(b['start_date'])));

    if (upcomingTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 60, color: textSecondary.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text('No upcoming tasks',
              style: TextStyle(
                fontSize: 18,
                color: textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              'Tasks starting soon appear first',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, index) {
              final task = upcomingTasks[index];

              return Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task['title'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  task['course_name'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getTaskTypeColor(task['type']).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: _getTaskTypeColor(task['type']).withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              task['type'],
                              style: TextStyle(
                                fontSize: 12,
                                color: _getTaskTypeColor(task['type']),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildTaskStat('Points', '${task['points']}', textPrimary),
                          const SizedBox(width: 16),
                          _buildTaskStat('Starts', _formatDateTime(task['start_date']), textPrimary),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTaskStat('Due Date', _formatDateTime(task['due_date']), textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: secondaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Starts',
                              style: TextStyle(
                                color: secondaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _timeUntilStart(task['start_date']),
                              style: TextStyle(
                                color: secondaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ).animate(onPlay: (controller) => controller.repeat())
                                .shimmer(duration: 1000.ms, color: secondaryColor.withOpacity(0.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            childCount: upcomingTasks.length,
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedTasks() {
    List<dynamic> completedTasks = _filterCompletedTasks(taskData['Completed_Tasks'] as List<dynamic>? ?? []);

    // Sort by due date (most recent first)
    completedTasks.sort((a, b) => DateTime.parse(b['due_date']).compareTo(DateTime.parse(a['due_date'])));

    if (completedTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment, size: 60, color: textSecondary.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'No completed tasks'
                  : 'No matching tasks found',
              style: TextStyle(
                fontSize: 18,
                color: textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          sliver: SliverToBoxAdapter(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search completed tasks...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: textSecondary.withOpacity(0.2)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, index) {
              final task = completedTasks[index];
              final isMcqs = task['type'] == 'MCQS';
              final isMarked = task['IsMarked'] == 'Yes';
              final hasSubmission = task['Your_Submission'] != null && task['Your_Submission'] != 'N/A';
              final hasFile = task['File'] != null && task['File'] != 'N/A';

              return Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task['title'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  task['course_name'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getTaskTypeColor(task['type']).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: _getTaskTypeColor(task['type']).withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              task['type'],
                              style: TextStyle(
                                fontSize: 12,
                                color: _getTaskTypeColor(task['type']),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildTaskStat('Points', '${task['points']}', textPrimary),
                          const SizedBox(width: 16),
                          _buildTaskStat('Status', isMarked ? 'Marked' : 'Not Marked',
                              isMarked ? successColor : warningColor),
                          if (isMarked) ...[
                            const SizedBox(width: 16),
                            _buildTaskStat('Obtained', '${task['obtained_points'] ?? 'N/A'}', successColor),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTaskStat('Started', _formatDateTime(task['start_date']), textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTaskStat('Ended', _formatDateTime(task['due_date']), textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (isMcqs) ...[
                        _buildExpandableMcqsSection(index, task['MCQS'] as List<dynamic>? ?? []),
                        const SizedBox(height: 12),
                      ],
                      if (hasFile) ...[
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
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
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: primaryColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.file_open, size: 18),
                            label: const Text('View Task File'),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (hasSubmission) ...[
                        _buildTaskStat('Submitted On', _formatDateTime(task['Submission_Date_Time']), successColor),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PdfViewerScreen(
                                    fileUrl: task['Your_Submission'],
                                    filename: 'Your Submission',
                                  ),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: successColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.assignment_turned_in, size: 18),
                            label: const Text('View Your Submission'),
                          ),
                        ),
                      ] else if (!isMcqs) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: null,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: dangerColor.withOpacity(0.3)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.warning_amber, size: 18),
                            label: const Text('Not Submitted'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
            childCount: completedTasks.length,
          ),
        ),
      ],
    );
  }

  // Add this to your state class


  Widget _buildExpandableMcqsSection(int taskIndex, List<dynamic> mcqs) {
    _mcqsExpansionState.putIfAbsent(taskIndex, () => false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _mcqsExpansionState[taskIndex] = !_mcqsExpansionState[taskIndex]!;
            });
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MCQs (${mcqs.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(
                _mcqsExpansionState[taskIndex]!
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: textSecondary,
              ),
            ],
          ),
        ),
        if (_mcqsExpansionState[taskIndex]!) ...[
          const SizedBox(height: 8),
          ...mcqs.map((mcq) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Q${mcq['Question NO']}: ${mcq['Question']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('A: ${mcq['Answer']}',
                    style: TextStyle(
                      color: successColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const Divider(height: 16),
                ],
              ),
            );
          }).toList(),
        ],
      ],
    );
  }
  Widget _buildTaskStat(String label, String value, Color color) {
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

  Color _getTaskTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'assignment':
        return assignmentColor;
      case 'quiz':
        return successColor;
      case 'mcqs':
        return secondaryColor;
      case 'labtask':
        return warningColor;
      default:
        return primaryColor;
    }
  }

  void _navigateToAttemptScreen(BuildContext context, dynamic task) {
    if (task['type'] == 'MCQS') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => McqsAttemptScreen(task: task),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FileTaskAttemptScreen(task: task),
        ),
      );
    }
  }

  void _navigateToViewSubmissionScreen(BuildContext context, dynamic task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(
          fileUrl: task['Your_Submission'],
          filename: 'Your Submission',
        ),
      ),
    );
  }
}

class TaskSkeletonLoader extends StatelessWidget {
  const TaskSkeletonLoader({Key? key}) : super(key: key);

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

class McqsAttemptScreen extends StatelessWidget {
  final dynamic task;
  const McqsAttemptScreen({Key? key, required this.task}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(task['title']),
      ),
      body: Center(
        child: Text('MCQS Attempt Screen for ${task['title']}'),
      ),
    );
  }
}

class FileTaskAttemptScreen extends StatelessWidget {
  final dynamic task;
  const FileTaskAttemptScreen({Key? key, required this.task}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(task['title']),
      ),
      body: Center(
        child: Text('File Task Attempt Screen for ${task['title']}'),
      ),
    );
  }
}