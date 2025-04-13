import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:lmsv2/api/ApiConfig.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../file_view/pdf_word_file_viewer.dart';

class MarkTaskScreen extends StatefulWidget {
  final Map<String, dynamic> task;

  const MarkTaskScreen({Key? key, required this.task}) : super(key: key);

  @override
  _MarkTaskScreenState createState() => _MarkTaskScreenState();
}

class _MarkTaskScreenState extends State<MarkTaskScreen> {
  final Dio _dio = Dio();
  List<dynamic> _students = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final Map<int, TextEditingController> _marksControllers = {};
  bool _isSubmitting = false;

  // Color Scheme
  final Color _primaryColor = Color(0xFF4E6AEB);
  final Color _cardBgColor = Colors.white;
  final Color _textColor = Color(0xFF333333);
  final Color _secondaryTextColor = Color(0xFF666666);
  final Color _unmarkedColor = Color(0xFF00BFA5);
  final Color _submittedColor = Color(0xFF4CAF50);
  final Color _notSubmittedColor = Color(0xFFF44336);

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    setState(() => _isLoading = true);
    try {
      final response = await _dio.get(
        '${ApiConfig.apiBaseUrl}Grader/ListOfStudent',
        queryParameters: {'task_id': widget.task['task_id']},
      );

      setState(() {
        _students = response.data['assigned Tasks'] ?? [];
        for (var student in _students) {
          // Set default mark to 0 if Answer is null and ObtainedMarks is null
          final defaultMark = (student['Answer'] == null && student['ObtainedMarks'] == null)
              ? '0'
              : student['ObtainedMarks']?.toString() ?? '';

          _marksControllers[student['Student_id']] = TextEditingController(
            text: defaultMark,
          );
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load students: ${e.toString()}')),
      );
    }
  }

  int get _totalStudents => _students.length;
  int get _submissionsCount => _students.where((s) => s['Answer'] != null).length;
  int get _noSubmissionsCount => _totalStudents - _submissionsCount;

  Future<bool> _onWillPop() async {
    if (_isSubmitting) {
      return false; // Prevent back navigation while submitting
    }

    final shouldExit = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Exit Marking?'),
        content: Text('All progress will be lost. Are you sure you want to exit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Exit', style: TextStyle(color: _notSubmittedColor)),
          ),
        ],
      ),
    );

    return shouldExit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final filteredStudents = _students.where((student) {
      final query = _searchQuery.toLowerCase();
      return student['name'].toString().toLowerCase().contains(query) ||
          student['RegNo'].toString().toLowerCase().contains(query);
    }).toList();

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text('Mark Task', style: TextStyle(color: Colors.white)),
          backgroundColor: _primaryColor,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(Icons.search, color: Colors.white),
              onPressed: () {
                showSearch(
                  context: context,
                  delegate: StudentSearchDelegate(_students),
                );
              },
            ),
          ],
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          child: Column(
            children: [
              // Task Info Card
              Container(
                margin: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _cardBgColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.task['Course Name'] ?? 'No Course',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: _textColor,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        widget.task['title'] ?? 'No Title',
                        style: TextStyle(
                          fontSize: 16,
                          color: _secondaryTextColor,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.task['type'] ?? 'Unknown',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _submittedColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${widget.task['points'] ?? 0} pts',
                              style: TextStyle(
                                fontSize: 12,
                                color: _submittedColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Stats Row
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildStatCard('Total', _totalStudents, _primaryColor),
                    SizedBox(width: 8),
                    _buildStatCard('Submitted', _submissionsCount, _submittedColor),
                    SizedBox(width: 8),
                    _buildStatCard('Pending', _noSubmissionsCount, _notSubmittedColor),
                  ],
                ),
              ),
              // Search Bar
              Padding(
                padding: EdgeInsets.all(16),
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search students...',
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              // Students List
              ListView.builder(
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: filteredStudents.length,
                itemBuilder: (context, index) {
                  final student = filteredStudents[index];
                  return _buildStudentCard(student);
                },
              ),
              SizedBox(height: 16),
              // Submit Button
              Padding(
                padding: EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitMarks,
                  child: _isSubmitting
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                      : Text('Submit Marks'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: _unmarkedColor,
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 4),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final hasSubmission = student['Answer'] != null;
    final controller = _marksControllers[student['Student_id']]!;

    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: _cardBgColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
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
                      Text(
                        student['name'] ?? 'No Name',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _textColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        student['RegNo'] ?? 'No RegNo',
                        style: TextStyle(
                          fontSize: 13,
                          color: _secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                if (hasSubmission)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PdfViewerScreen(fileUrl: student['Answer'],filename: student['name'],),
                        ),
                      );
                    },
                    child: Text('View PDF'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white, backgroundColor: _primaryColor,
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  )
                else
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _notSubmittedColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _notSubmittedColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      'Not Submitted',
                      style: TextStyle(
                        fontSize: 12,
                        color: _notSubmittedColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Marks (out of ${widget.task['points']})',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitMarks() async {
    // Validate all marks are entered
    final missingMarksStudents = <String>[];

    for (var student in _students) {
      final marks = _marksControllers[student['Student_id']]?.text.trim();
      if (marks == null || marks.isEmpty) {
        missingMarksStudents.add(student['name'] ?? 'Unknown Student');
      }
    }

    if (missingMarksStudents.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Missing Marks'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Please enter marks for all students:'),
              SizedBox(height: 8),
              ...missingMarksStudents.map((name) => Text('• $name')).toList(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Prepare submissions data
      final submissions = _students.map((student) {
        final marks = _marksControllers[student['Student_id']]!.text.trim();
        return {
          'student_id': student['Student_id'],
          'obtainedMarks': int.parse(marks),
        };
      }).toList();

      // Call API to submit marks
      final response = await _dio.post(
        '${ApiConfig.apiBaseUrl}Grader/SubmitTaskResultList',
        data: {
          'task_id': widget.task['task_id'],
          'submissions': submissions,
        },
      );

      // Show success dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          // Auto-close after 5 seconds
          Future.delayed(Duration(seconds: 5), () {
            Navigator.of(context).pop();
            Navigator.of(context).pop(true); // Return to previous screen
          });

          return AlertDialog(
            title: Text('Marks Submitted Successfully'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: _submittedColor, size: 48),
                SizedBox(height: 16),
                Text('All marks have been successfully recorded.'),
                SizedBox(height: 16),
                if (response.data != null && response.data['data'] != null)
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: 200),
                    child: SingleChildScrollView(
                      child: Column(
                        children: (response.data['data'] as List)
                            .map<Widget>((log) => ListTile(
                          title: Text(log['Message'] ?? ''),
                          subtitle: log['Error'] != null
                              ? Text(log['Error'], style: TextStyle(color: _notSubmittedColor))
                              : null,
                        ))
                            .toList(),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      setState(() => _isSubmitting = false);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Submission Failed'),
          content: Text('Failed to submit marks: ${e.toString()}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _marksControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }
}

class StudentSearchDelegate extends SearchDelegate {
  final List<dynamic> students;

  StudentSearchDelegate(this.students);

  @override
  List<Widget> buildActions(BuildContext context) => [
    IconButton(
      icon: Icon(Icons.clear),
      onPressed: () => query = '',
    ),
  ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
    icon: Icon(Icons.arrow_back),
    onPressed: () => close(context, null),
  );

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults();

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults();

  Widget _buildSearchResults() {
    final results = students.where((student) {
      return student['name'].toString().toLowerCase().contains(query.toLowerCase()) ||
          student['RegNo'].toString().toLowerCase().contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final student = results[index];
        return ListTile(
          title: Text(student['name'], overflow: TextOverflow.ellipsis),
          subtitle: Text(student['RegNo']),
          onTap: () => close(context, student),
        );
      },
    );
  }
}