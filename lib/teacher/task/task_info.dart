import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:lmsv2/api/ApiConfig.dart';
import 'package:lmsv2/file_view/pdf_word_file_viewer.dart';

import 'mark_task.dart';

class TaskDetailsScreen extends StatefulWidget {
  final int teacherId;

  const TaskDetailsScreen({Key? key, required this.teacherId}) : super(key: key);

  @override
  _TaskDetailsScreenState createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  final Dio _dio = Dio();
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy hh:mm a');
  Map<String, dynamic> _tasks = {};
  bool _isLoading = true;
  String _currentTab = 'ongoing_tasks';
  String _searchQuery = '';
  String _sortBy = 'due_date';
  String _graderFilter = 'all';
  Timer? _timer;
  List<String> _sections = [];
  List<String> _courses = [];
  bool _sortAscending = true;

  // Color Scheme
  final Color _completedColor = Color(0xFF4CAF50);
  final Color _ongoingColor = Color(0xFF2196F3);
  final Color _upcomingColor = Color(0xFFFF9800);
  final Color _unmarkedColor = Color(0xFF00BFA5); // Teal color
  final Color _cardBgColor = Colors.white;
  final Color _textColor = Color(0xFF333333);
  final Color _secondaryTextColor = Color(0xFF666666);

  @override
  void initState() {
    super.initState();
    _fetchTasks();
    _timer = Timer.periodic(Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchTasks() async {
    setState(() => _isLoading = true);
    try {
      final response = await _dio.get(
        '${ApiConfig.apiBaseUrl}Teachers/task/get',
        queryParameters: {'teacher_id': widget.teacherId},
      );

      final tasks = response.data['Tasks'] ?? {};
      final sections = <String>{};
      final courses = <String>{};

      tasks.forEach((key, value) {
        for (var task in value) {
          if (task['Section'] != null) sections.add(task['Section']);
          if (task['Course Name'] != null) courses.add(task['Course Name']);
        }
      });

      setState(() {
        _tasks = tasks;
        _sections = sections.toList()..sort();
        _courses = courses.toList()..sort();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load tasks: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  int _getTaskCount(String tabKey) => _tasks[tabKey]?.length ?? 0;

  List<dynamic> get _currentTasks {
    final tasks = _tasks[_currentTab] ?? [];
    var filtered = List.from(tasks);

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((task) =>
      (task['Course Name']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (task['Section']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (task['title']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)).toList();
    }

    if (_graderFilter != 'all') {
      filtered = filtered.where((task) =>
      (_graderFilter == 'assigned' && task['Is Allocated To Grader'] == 'Yes') ||
          (_graderFilter == 'unassigned' && task['Is Allocated To Grader'] == 'No')).toList();
    }

    filtered.sort((a, b) {
      final comparison = DateTime.parse(a['due_date']).compareTo(DateTime.parse(b['due_date']));
      return _sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

  Widget _buildTimeRemainingIndicator(String dueDate) {
    final now = DateTime.now();
    final due = DateTime.parse(dueDate);
    final difference = due.difference(now);
    final isOverdue = difference.isNegative;
    final totalDays = difference.inDays.abs();
    final totalHours = difference.inHours.abs().remainder(24);

    Color color;
    if (isOverdue) {
      color = Colors.red;
    } else if (difference.inDays < 1) {
      color = Colors.orange;
    } else if (difference.inDays < 3) {
      color = Colors.amber;
    } else {
      color = Colors.green;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isOverdue ? Icons.warning : Icons.access_time, size: 14, color: color),
          SizedBox(width: 4),
          Text(
            isOverdue ? 'Overdue by $totalDays d $totalHours h' : '$totalDays d $totalHours h remaining',
            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final isCompleted = _currentTab == 'completed_tasks';
    final isUpcoming = _currentTab == 'upcoming_tasks';
    final isOngoing = _currentTab == 'ongoing_tasks';
    final isUnmarked = _currentTab == 'unmarked_tasks';
    final isMCQS = task['type'] == 'MCQS';

    Color cardColor;
    if (isCompleted) cardColor = _completedColor.withOpacity(0.05);
    else if (isOngoing) cardColor = _ongoingColor.withOpacity(0.05);
    else if (isUpcoming) cardColor = _upcomingColor.withOpacity(0.05);
    else cardColor = _unmarkedColor.withOpacity(0.05);

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: _cardBgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isCompleted ? _completedColor :
                    isOngoing ? _ongoingColor :
                    isUpcoming ? _upcomingColor : _unmarkedColor,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  isCompleted ? 'COMPLETED' :
                  isOngoing ? 'ONGOING' :
                  isUpcoming ? 'UPCOMING' : 'UNMARKED',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _secondaryTextColor, letterSpacing: 0.5),
                ),
                Spacer(),
                _buildTimeRemainingIndicator(task['due_date']),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(task['title'] ?? 'No Title',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textColor)),
                          SizedBox(height: 4),
                          Text('${task['Course Name'] ?? 'No Course'} • ${task['Section'] ?? 'No Section'}',
                              style: TextStyle(fontSize: 13, color: _secondaryTextColor)),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(task['type'] ?? 'Unknown',
                          style: TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(children: [
                  Icon(Icons.calendar_today, size: 16, color: _secondaryTextColor),
                  SizedBox(width: 8),
                  Text('Starts: ${_dateFormat.format(DateTime.parse(task['start_date']))}',
                      style: TextStyle(fontSize: 12, color: _secondaryTextColor)),
                ]),
                SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.timer, size: 16, color: _secondaryTextColor),
                  SizedBox(width: 8),
                  Text('Due: ${_dateFormat.format(DateTime.parse(task['due_date']))}',
                      style: TextStyle(fontSize: 12, color: _secondaryTextColor)),
                ]),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('Points',
                            style: TextStyle(fontSize: 13, color: _secondaryTextColor)),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(task['points'].toString() ?? '0',
                            style: TextStyle(fontSize: 13, color: _secondaryTextColor)),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                // Only show grader info if not MCQ
                if (!isMCQS) ...[
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(task['Is Allocated To Grader'] == 'Yes' ? Icons.verified_user : Icons.person_outline,
                            size: 20, color: _secondaryTextColor),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(task['Grader Info For this Task'] ?? 'No grader assigned',
                              style: TextStyle(fontSize: 13, color: _secondaryTextColor)),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                ],

                if (isCompleted && task['marking_info'] != null) ...[
                  SizedBox(height: 12),
                  _buildMarkingInfo(task['marking_info']),
                ],
                SizedBox(height: 12),

                if (isCompleted)
                  ElevatedButton.icon(
                    icon: Icon(Icons.visibility, size: 16, color: Colors.white),
                    label: Text(
                      'View Submissions',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    onPressed: () => _viewSubmissions(task),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _completedColor,
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20), // Matches tab radius
                      ),
                      elevation: 0,
                    ),
                  ),

                if ((isUnmarked || isOngoing || isUpcoming) && !isMCQS)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (task['Is Allocated To Grader'] == 'No')
                        OutlinedButton.icon(
                          icon: Icon(Icons.person_add, size: 16),
                          label: Text('Assign Grader'),
                          onPressed: () => _showGraderAssignmentDialog(task['task_id'],task['title'],task['Grader Info For this Task']),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue,
                            side: BorderSide(color: Colors.blue),
                            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      if (isUnmarked)
                        ElevatedButton.icon(
                          icon: Icon(Icons.grade, size: 16, color: Colors.white),
                          label: Text(
                            'Mark Task',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          onPressed: () => _markTask(task),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _unmarkedColor, // Using your teal color variable
                            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20), // Matches tab radius
                            ),
                            elevation: 0, // Flat design like tabs
                          ),
                        ),
                      if (isOngoing)
                        OutlinedButton.icon(
                          icon: Icon(Icons.edit_calendar, size: 16),
                          label: Text('Extend Deadline'),
                          onPressed: () => _updateEndTime(task['task_id'], task['due_date']),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _ongoingColor,
                            side: BorderSide(color: _ongoingColor),
                            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      if (isUpcoming) ...[
                        OutlinedButton.icon(
                          icon: Icon(Icons.edit, size: 16),
                          label: Text('Edit Dates'),
                          onPressed: () => _updateTaskDates(task['task_id'], task['start_date'], task['due_date'],task['points']),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _upcomingColor,
                            side: BorderSide(color: _upcomingColor),
                            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        OutlinedButton.icon(
                          icon: Icon(Icons.delete, size: 16, color: Colors.red),
                          label: Text('Delete', style: TextStyle(color: Colors.red)),
                          onPressed: () => _deleteTask(task['task_id']),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.red),
                            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ],
                  ),
                SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: Icon(isMCQS ? Icons.quiz : Icons.insert_drive_file, size: 16),
                  label: Text(isMCQS ? 'View Questions' : 'View File',
                      style: TextStyle(fontSize: 14)),
                  onPressed: () => isMCQS
                      ? _showMCQSPreview(task['MCQS'],context)
                      : _viewFile(task['File']),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.purple,
                    side: BorderSide(color: Colors.purple),
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkingInfo(dynamic markingInfo) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _completedColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _completedColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Performance Summary', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textColor)),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPerformancePill('🥇 Top', markingInfo['top']?['obtained_marks'], _completedColor),
              _buildPerformancePill('📊 Average', markingInfo['average']?['obtained_marks'], Colors.blue),
              _buildPerformancePill('⚠️ Low', markingInfo['worst']?['obtained_marks'], Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformancePill(String label, dynamic marks, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
        ),
        SizedBox(height: 4),
        Text(marks?.toString() ?? 'N/A',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textColor)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Task Management', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF4E6AEB),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward, color: Colors.white),
            onPressed: () => setState(() => _sortAscending = !_sortAscending),
            tooltip: 'Sort direction',
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.white),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'create',
                child: Row(
                  children: [
                    Icon(Icons.add, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Create New Task'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {/* Handle create task */},
          ),
        ],
      ),
      body: Column(
        children: [
          // Only tabs are sticky
          Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryTab('Unmarked', _unmarkedColor, 'unmarked_tasks', _getTaskCount('unmarked_tasks')),
                  _buildCategoryTab('Ongoing', _ongoingColor, 'ongoing_tasks', _getTaskCount('ongoing_tasks')),
                  _buildCategoryTab('Upcoming', _upcomingColor, 'upcoming_tasks', _getTaskCount('upcoming_tasks')),
                  _buildCategoryTab('Completed', _completedColor, 'completed_tasks', _getTaskCount('completed_tasks')),
                ],
              ),
            ),
          ),
          // Rest of content scrolls together
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchTasks,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Search and filter section
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextField(
                            decoration: InputDecoration(
                              hintText: 'Search tasks...',
                              prefixIcon: Icon(Icons.search, color: Colors.grey),
                              filled: true,
                              fillColor: Colors.grey[100],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.symmetric(vertical: 12),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                icon: Icon(Icons.clear, color: Colors.grey),
                                onPressed: () => setState(() => _searchQuery = ''),
                              )
                                  : null,
                            ),
                            onChanged: (value) => setState(() => _searchQuery = value),
                          ),
                          SizedBox(height: 16),
                          // Improved Grader Status filter
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(bottom: 8),
                                child: Text(
                                  'Grader Status:',
                                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                                ),
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 40, // Fixed height for consistent alignment
                                      child: RadioListTile<String>(
                                        title: Text('All', overflow: TextOverflow.ellipsis),
                                        value: 'all',
                                        groupValue: _graderFilter,
                                        onChanged: (value) => setState(() => _graderFilter = value!),
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: SizedBox(
                                      height: 40,
                                      child: RadioListTile<String>(
                                        title: Text('Unassigned', overflow: TextOverflow.ellipsis),
                                        value: 'unassigned',
                                        groupValue: _graderFilter,
                                        onChanged: (value) => setState(() => _graderFilter = value!),
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 2),
                                  Expanded(
                                    child: SizedBox(
                                      height: 40,
                                      child: RadioListTile<String>(
                                        title: Text('Assigned', overflow: TextOverflow.ellipsis),
                                        value: 'assigned',
                                        groupValue: _graderFilter,
                                        onChanged: (value) => setState(() => _graderFilter = value!),
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 4),

                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Task list
                    _isLoading
                        ? Center(child: CircularProgressIndicator())
                        : _currentTasks.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.task, size: 48, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No tasks found', style: TextStyle(fontSize: 16, color: Colors.grey)),
                        ],
                      ),
                    )
                        : ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: _currentTasks.length,
                      itemBuilder: (context, index) => _buildTaskCard(_currentTasks[index]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTab(String label, Color color, String tabKey, int count) {
    return GestureDetector(
      onTap: () => setState(() => _currentTab = tabKey),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _currentTab == tabKey ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _currentTab == tabKey ? color : Colors.grey[300]!, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: _currentTab == tabKey ? FontWeight.w600 : FontWeight.w500,
                color: _currentTab == tabKey ? color : Colors.grey,
              ),
            ),
            SizedBox(width: 4),
            Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Placeholder methods for task actions
  void _viewSubmissions(var taskId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MarkTaskScreen(task: taskId),
      ),
    );
  }
  Future<void> _markTask(var taskId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MarkTaskScreen(task: taskId),
      ),
    );
    await _fetchTasks();
  }

  void _showMCQSPreview(List<dynamic>? mcqs, BuildContext context) {
    if (mcqs == null || mcqs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No MCQs available')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.all(16),
        child: Container(
          padding: EdgeInsets.all(20),
          constraints: BoxConstraints(maxWidth: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'MCQs Preview',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: mcqs.length,
                  itemBuilder: (context, index) {
                    final mcq = mcqs[index];
                    return _buildMCQCard(mcq, index + 1);
                  },
                ),
              ),
              SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildMCQCard(Map<String, dynamic> mcq, int questionNumber) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Q${mcq['Question NO'] ?? questionNumber}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${mcq['Points'] ?? 0} pts',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              mcq['Question'] ?? 'No question text',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 16),
            Column(
              children: [
                _buildOptionTile('1. ${mcq['Option 1']}', mcq['Answer'] == mcq['Option 1']),
                _buildOptionTile('2. ${mcq['Option 2']}', mcq['Answer'] == mcq['Option 2']),
                _buildOptionTile('3. ${mcq['Option 3']}', mcq['Answer'] == mcq['Option 3']),
                _buildOptionTile('4. ${mcq['Option 4']}', mcq['Answer'] == mcq['Option 4']),
              ],
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildOptionTile(String optionText, bool isCorrect) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isCorrect ? Colors.green.withOpacity(0.1) : null,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCorrect ? Colors.green : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 12),
        dense: true,
        title: Text(
          optionText,
          style: TextStyle(
            color: isCorrect ? Colors.green : null,
            fontWeight: isCorrect ? FontWeight.bold : null,
          ),
        ),
        leading: Icon(
          isCorrect ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isCorrect ? Colors.green : Colors.grey,
        ),
      ),
    );
  }
  Future<void> _viewFile(String? fileUrl) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(fileUrl: fileUrl.toString()),
      ),
    );
  }

  void _showGraderAssignmentDialog(int taskId, String title, String? graderInfo) async {
    bool isLoading = true;
    List<dynamic> activeGraders = [];
    int? selectedGraderId;
    // Fetch active graders
    try {
      final response = await _dio.get(
        '${ApiConfig.apiBaseUrl}Teachers/grader_assign?teacher_id=${widget.teacherId}',
      );

      if (response.data['status'] == 'success') {
        activeGraders = response.data['active_graders'] ?? [];
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load graders: ${e.toString()}')),
      );
    } finally {
      isLoading = false;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Assign Grader'),
                  SizedBox(height: 4),
                  Text(
                    title,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
              content: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You are assigning a grader for this task. Please select from available graders:',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  SizedBox(height: 16),
                  if (activeGraders.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'No active graders available',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  if (activeGraders.isNotEmpty)
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: 300),
                      child: SingleChildScrollView(
                        child: Column(
                          children: activeGraders.map<Widget>((grader) {
                            return Card(
                              margin: EdgeInsets.only(bottom: 8),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: selectedGraderId == grader['grader_id']
                                      ? Colors.blue
                                      : Colors.grey[300]!,
                                  width: 1.5,
                                ),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () {
                                  setState(() {
                                    selectedGraderId = grader['grader_id'];
                                  });
                                },
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: Colors.blue[100],
                                            child: Text(
                                              grader['name']?.toString().substring(0, 1) ?? 'G',
                                              style: TextStyle(color: Colors.blue),
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  grader['name'] ?? 'Unknown Grader',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                SizedBox(height: 2),
                                                Text(
                                                  grader['RegNo'] ?? '',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (selectedGraderId == grader['grader_id'])
                                            Icon(Icons.check_circle, color: Colors.blue),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.green[50],
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              grader['section'] ?? '',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.green[800],
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.orange[50],
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Tasks: ${grader['total_tasks_assigned'] ?? 0}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.orange[800],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      if (grader['feedback'] != null)
                                        Text(
                                          '"${grader['feedback']}"',
                                          style: TextStyle(
                                            fontStyle: FontStyle.italic,
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selectedGraderId == null
                      ? null
                      : () async {
                    try {
                      final response = await _dio.post(
                        '${ApiConfig.apiBaseUrl}Teachers/tasks/assign-grader',
                        data: {
                          'task_id': taskId,
                          'grader_id': selectedGraderId,
                        },
                      );

                      if (response.data['status'] == 'success') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Grader assigned successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        Navigator.pop(context);
                        _fetchTasks(); // Refresh the task list
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(response.data['message'] ?? 'Failed to assign grader'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error assigning grader: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: Text('Assign'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteTask(int taskId) async {
    // Show confirmation dialog
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete this task? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      // Call API to delete task
      final response = await _dio.delete(
        '${ApiConfig.apiBaseUrl}Teachers/remover/task',
        data: {'task_id': taskId},
      );

      // Close loading indicator
      Navigator.pop(context);

      if (response.data['status'] == 'success') {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.data['message'] ?? 'Task deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh the task list
        _fetchTasks();
      } else {
        // Show error message from API
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.data['message'] ?? 'Failed to delete task'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on DioException catch (e) {
      // Close loading indicator
      Navigator.pop(context);

      String errorMessage = 'Failed to delete task';
      if (e.response?.data != null && e.response?.data['message'] != null) {
        errorMessage = e.response!.data['message'];
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Connection timeout. Please try again.';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Server took too long to respond.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      // Close loading indicator
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An unexpected error occurred: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  Future<void> _updateEndTime(int taskId, String currentEndTime) async {
    DateTime initialDate = DateTime.parse(currentEndTime);
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    // First select date
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _ongoingColor, // Using your ongoing color
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (date == null) return; // User cancelled date picker

    // Then select time
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _ongoingColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (time == null) return; // User cancelled time picker

    // Combine date and time
    selectedDate = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    // Format for API
    final formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(selectedDate);

    // Show confirmation dialog
    final shouldUpdate = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Update'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current End Time:'),
            Text(
              DateFormat('MMM dd, yyyy - hh:mm a').format(initialDate),
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text('New End Time:'),
            Text(
              DateFormat('MMM dd, yyyy - hh:mm a').format(selectedDate!),
              style: TextStyle(fontWeight: FontWeight.bold, color: _ongoingColor),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Update'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _ongoingColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (shouldUpdate != true) return;

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      // Call API to update end time
      final response = await _dio.post(
        '${ApiConfig.apiBaseUrl}Teachers/task/update-enddatetime',
        data: {
          'task_id': taskId,
          'EndDateTime': formattedDate,
        },
      );

      // Close loading indicator
      Navigator.pop(context);

      if (response.data['status'] == 'success') {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.data['message'] ?? 'End time updated successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh the task list
        _fetchTasks();
      } else {
        // Show error message from API
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.data['message'] ?? 'Failed to update end time'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on DioException catch (e) {
      // Close loading indicator
      Navigator.pop(context);

      String errorMessage = 'Failed to update end time';
      if (e.response?.data != null && e.response?.data['message'] != null) {
        errorMessage = e.response!.data['message'];
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Connection timeout. Please try again.';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Server took too long to respond.';
      } else if (e.response?.statusCode == 400) {
        errorMessage = 'Invalid date/time selection';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      // Close loading indicator
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An unexpected error occurred: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  Future<void> _updateTaskDates(int taskId, String startDate, String endDate, int points) async {
    DateTime initialStartDate = DateTime.parse(startDate);
    DateTime initialEndDate = DateTime.parse(endDate);
    DateTime? newStartDate;
    DateTime? newEndDate;
    int? newPoints;

    // Show edit dialog
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Update Task Details'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Points Field
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Points',
                        hintText: points.toString(),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          newPoints = int.tryParse(value);
                        }
                      },
                    ),
                    SizedBox(height: 16),

                    // Start Date Picker
                    ListTile(
                      title: Text('Start Date'),
                      subtitle: Text(
                        newStartDate != null
                            ? DateFormat('MMM dd, yyyy - hh:mm a').format(newStartDate!)
                            : DateFormat('MMM dd, yyyy - hh:mm a').format(initialStartDate),
                      ),
                      trailing: Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: newStartDate ?? initialStartDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(newStartDate ?? initialStartDate),
                          );
                          if (time != null) {
                            setState(() {
                              newStartDate = DateTime(
                                date.year, date.month, date.day,
                                time.hour, time.minute,
                              );
                            });
                          }
                        }
                      },
                    ),
                    SizedBox(height: 8),

                    // End Date Picker
                    ListTile(
                      title: Text('End Date'),
                      subtitle: Text(
                        newEndDate != null
                            ? DateFormat('MMM dd, yyyy - hh:mm a').format(newEndDate!)
                            : DateFormat('MMM dd, yyyy - hh:mm a').format(initialEndDate),
                      ),
                      trailing: Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: newEndDate ?? initialEndDate,
                          firstDate: newStartDate ?? initialStartDate,
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(newEndDate ?? initialEndDate),
                          );
                          if (time != null) {
                            setState(() {
                              newEndDate = DateTime(
                                date.year, date.month, date.day,
                                time.hour, time.minute,
                              );
                            });
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Validate end date is after start date if both changed
                    if (newStartDate != null && newEndDate != null &&
                        newEndDate!.isBefore(newStartDate!)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('End date must be after start date')),
                      );
                      return;
                    }
                    Navigator.pop(context, {
                      'points': newPoints,
                      'startDate': newStartDate,
                      'endDate': newEndDate,
                    });
                  },
                  child: Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return; // User cancelled

    // Prepare request data
    final Map<String, dynamic> requestData = {'task_id': taskId};
    if (result['points'] != null) requestData['points'] = result['points'];
    if (result['startDate'] != null) {
      requestData['StartDateTime'] = DateFormat('yyyy-MM-dd HH:mm:ss').format(result['startDate']);
    }
    if (result['endDate'] != null) {
      requestData['EndDateTime'] = DateFormat('yyyy-MM-dd HH:mm:ss').format(result['endDate']);
    }

    // Don't call API if nothing changed
    if (requestData.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No changes detected')),
      );
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      // Call API to update task details
      final response = await _dio.post(
        '${ApiConfig.apiBaseUrl}Teachers/task/update-details',
        data: requestData,
      );

      // Close loading indicator
      Navigator.pop(context);

      if (response.data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.data['message'] ?? 'Task details updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchTasks(); // Refresh task list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.data['message'] ?? 'Failed to update task details'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on DioException catch (e) {
      Navigator.pop(context); // Close loading
      String errorMessage = 'Failed to update task details';
      if (e.response?.data != null) {
        errorMessage = e.response!.data['message'] ?? errorMessage;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An unexpected error occurred: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}