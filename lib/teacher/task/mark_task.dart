import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lmsv2/api/ApiConfig.dart';
import '../../alerts/custom_alerts.dart';
import '../../file_view/pdf_word_file_viewer.dart';

class MarkTaskScreen extends StatefulWidget {
  final Map<String, dynamic> task;

  const MarkTaskScreen({Key? key, required this.task}) : super(key: key);

  @override
  State<MarkTaskScreen> createState() => _MarkTaskScreenState();
}

class _MarkTaskScreenState extends State<MarkTaskScreen> {
  final Dio _dio = Dio();
  List<dynamic> _students = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final Map<int, TextEditingController> _marksControllers = {};
  bool _isSubmitting = false;

  // Color Scheme (matching GraderTaskScreen)
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
    _fetchStudents();
  }

  @override
  void dispose() {
    _marksControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
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
          )..addListener(() => _validateMarks(student['Student_id']));
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      CustomAlert.error(context, 'Failed!', 'Failed to load students: ${e.toString()}');
    }
  }

  void _validateMarks(int studentId) {
    final controller = _marksControllers[studentId];
    if (controller == null) return;

    final text = controller.text;
    if (text.isEmpty) return;

    final marks = double.tryParse(text);
    final totalMarks = widget.task['points'] ?? widget.task['Total Marks']??0;

    if (marks != null && marks > totalMarks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.text = totalMarks.toString();
        CustomAlert.warning(context, 'Marks cannot exceed $totalMarks');
      });
    }
  }

  int get _totalStudents => _students.length;
  int get _submissionsCount => _students.where((s) => s['Answer'] != null).length;
  int get _noSubmissionsCount => _totalStudents - _submissionsCount;

  Future<bool> _onWillPop() async {
    if (_isSubmitting) return false;

    final shouldExit = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Exit Marking?', style: TextStyle(color: textPrimary)),
        content: Text('All progress will be lost. Are you sure you want to exit?',
            style: TextStyle(color: textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: TextStyle(color: primaryColor)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Exit', style: TextStyle(color: dangerColor)),
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
        backgroundColor: lightBackground,
        appBar: AppBar(
          title: Text('Mark Task - ${widget.task['title']}'),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Bootstrap.search, color: Colors.white),
              onPressed: () => _showSearchDialog(),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
          onRefresh: _fetchStudents,
          color: primaryColor,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Task Info Card
                Card(
                  margin: EdgeInsets.only(bottom: 16),
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
                        Text(
                          widget.task['Course Name'] ?? 'No Course',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '${widget.task['Section Name'] ?? 'No Section'} • ${widget.task['type'] ?? 'No Type'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: textSecondary,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${widget.task['points'] ?? 0} Points',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Spacer(),
                            Text(
                              '${_submissionsCount}/${_totalStudents} Submitted',
                              style: TextStyle(
                                fontSize: 13,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Students Table
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: cardBackground,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Table Header
                        Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'Student',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Reg No',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Status',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Marks',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 8),

                        // Table Rows
                        ...filteredStudents.map((student) => _buildStudentRow(student)).toList(),
                      ],
                    ),
                  ),
                ),

                // Submit Button
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitMarks,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: successColor,
                      minimumSize: Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                        : Text(
                      'Submit Marks',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentRow(Map<String, dynamic> student) {
    final hasSubmission = student['Answer'] != null;
    final controller = _marksControllers[student['Student_id']]!;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade100,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Student Name
          Expanded(
            flex: 3,
            child: Text(
              student['name'] ?? 'No Name',
              style: TextStyle(
                fontSize: 13,
                color: textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Reg No
          Expanded(
            flex: 2,
            child: Text(
              student['RegNo'] ?? 'No RegNo',
              style: TextStyle(
                fontSize: 13,
                color: textSecondary,
              ),
            ),
          ),

          // Status
          Expanded(
            flex: 2,
            child: hasSubmission
                ? InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PdfViewerScreen(
                      fileUrl: student['Answer'],
                      filename: student['name'],
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'View',
                  style: TextStyle(
                    fontSize: 12,
                    color: successColor,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
                : Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: dangerColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Missing',
                style: TextStyle(
                  fontSize: 12,
                  color: dangerColor,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Marks Input
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 36,
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.grey.shade300,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.grey.shade300,
                    ),
                  ),
                  hintText: '0',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Search Students'),
          content: TextField(
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search by name or reg no...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        );
      },
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
      CustomAlert.warning(
        context,
        'Missing Marks \n Please enter marks for all students',
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
      await _dio.post(
        '${ApiConfig.apiBaseUrl}Grader/SubmitTaskResultList',
        data: {
          'task_id': widget.task['task_id'],
          'submissions': submissions,
        },
      );

      // Show success dialog
      CustomAlert.success(
        context,
        'Submitted \n Marks submitted successfully',
      );
    } catch (e) {
      CustomAlert.error(
        context,
        'Failed!',
        'Failed to submit marks: ${e.toString()}',
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}