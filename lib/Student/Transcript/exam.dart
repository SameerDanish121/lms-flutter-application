import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:icons_plus/icons_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:convert';

import 'package:lmsv2/api/ApiConfig.dart';
import '../../alerts/custom_alerts.dart';
import '../../file_view/pdf_word_file_viewer.dart';

class ExamResultsScreen extends StatefulWidget {
  final int studentId;

  const ExamResultsScreen({Key? key, required this.studentId}) : super(key: key);

  @override
  State<ExamResultsScreen> createState() => _ExamResultsScreenState();
}

class _ExamResultsScreenState extends State<ExamResultsScreen> {
  late Future<List<dynamic>> _examData;
  String? _selectedCourse = 'All';
  List<String> _courseOptions = ['All'];
  bool _isLoading = false;

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
    _examData = _fetchExamData();
  }

  Future<List<dynamic>> _fetchExamData() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.apiBaseUrl}Students/exam-result?student_id=${widget.studentId}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          // Extract unique course names for filter dropdown with proper type casting
          final courses = ['All'];
          final courseNames = (data['data'] as List)
              .map<String>((e) => e['course_name'] as String)
              .toSet()
              .toList();
          courses.addAll(courseNames);

          setState(() => _courseOptions = courses);
          return data['data'];
        } else {
          throw Exception('Failed to load exam data');
        }
      } else {
        CustomAlert.error(context, 'Failed!', 'Failed to load exam results');
        throw Exception('Failed to load exam data');
      }
    } catch (e) {
      CustomAlert.error(context, 'Error!', 'An error occurred while fetching data');
      throw Exception('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _examData = _fetchExamData();
    });
  }
  Widget _buildCourseFilterDropdown(List<dynamic> examData) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textSecondary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCourse,
          icon: Icon(Bootstrap.chevron_down, size: 16, color: textSecondary),
          dropdownColor: Colors.white, // Set dropdown background color
          elevation: 2, // Add slight elevation
          borderRadius: BorderRadius.circular(8), // Match container radius
          style: TextStyle(
            fontSize: 14,
            color: textPrimary,
          ),
          itemHeight: 48, // Set consistent item height
          menuMaxHeight: 300, // Limit maximum height
          items: _courseOptions.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  value,
                  style: TextStyle(fontSize: 14),
                ),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedCourse = newValue;
            });
          },
        ),
      ),
    );
  }

  Widget _buildExamCard(Map<String, dynamic> exam) {
    final hasResults = exam['exam_results'] != null && exam['exam_results'].isNotEmpty;
    final midExam = hasResults && exam['exam_results']['Mid'] != null
        ? exam['exam_results']['Mid'][0]
        : null;
    final finalExam = hasResults && exam['exam_results']['Final'] != null
        ? exam['exam_results']['Final'][0]
        : null;

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course header info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    exam['course_name'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    exam['section'],
                    style: TextStyle(
                      fontSize: 12,
                      color: primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              exam['session'],
              style: TextStyle(
                fontSize: 13,
                color: textSecondary,
              ),
            ),
            SizedBox(height: 12),

            // Only show summary row if there are results
            if (hasResults) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSummaryItem('Total Marks', exam['total_marks']?.toString() ?? '0'),
                  _buildSummaryItem('Obtained Marks', exam['obtained_marks']?.toString() ?? '0'),
                  _buildSummaryItem('Solid Marks', (exam['solid_marks']?.toString() ?? '0')+' / '+(exam['solid_marks_equivalent']?.toString() ?? '0')),
                ],
              ),
              SizedBox(height: 16),
            ],

            // Exam details
            if (!hasResults)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No exam results declared yet',
                    style: TextStyle(
                      color: textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mid Term Exam
                  if (midExam != null) ...[
                    _buildExamSection('Mid Term', midExam),
                    SizedBox(height: 16),
                  ],

                  // Final Exam
                  if (finalExam != null) ...[
                    _buildExamSection('Final Term', finalExam),
                  ],
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

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: textSecondary,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildExamSection(String title, Map<String, dynamic> exam) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title and status in same row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: exam['status'] == 'Declared'
                    ? successColor.withOpacity(0.1)
                    : warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                exam['status'] ?? 'Pending',
                style: TextStyle(
                  color: exam['status'] == 'Declared' ? successColor : warningColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildExamSummaryItem('Total', exam['total_marks']?.toString() ?? '0'),
            _buildExamSummaryItem('Obtained', exam['obtained_marks']?.toString() ?? '0'),
            _buildExamSummaryItem('Solid', exam['solid_marks']?.toString() ?? '0'),
            _buildExamSummaryItem('Obtained Solid', exam['solid_marks_equivalent']?.toString() ?? '0'),

          ],
        ),
        SizedBox(height: 8),

        if(exam['exam_question_paper']!=null)...[
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
                        fileUrl: exam['exam_question_paper'],
                        filename:exam['exam_type'],
                      ),
                    ),
                  );
                },
                child: Text(
                  'View Question Paper',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
        SizedBox(height: 12),
        // Questions table
        if (exam['questions'] != null && exam['questions'].isNotEmpty)
          _buildQuestionsTable(exam['questions']),
      ],
    );
  }

  Widget _buildExamSummaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionsTable(List<dynamic> questions) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: constraints.maxWidth, // Takes full available width
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DataTable(
            columnSpacing: 0, // Remove default spacing
            horizontalMargin: 0, // Remove default margin
            headingRowHeight: 36,
            dataRowHeight: 36,
            columns: [
              DataColumn(
                label: Expanded(
                  child: Center(
                    child: Text(
                      'Q.No',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              DataColumn(
                label: Expanded(
                  child: Center(
                    child: Text(
                      'Marks',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              DataColumn(
                label: Expanded(
                  child: Center(
                    child: Text(
                      'Obtained',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
            rows: questions.map<DataRow>((question) {
              return DataRow(
                cells: [
                  DataCell(
                    Center(child: Text(question['q_no'].toString())),
                  ),
                  DataCell(
                    Center(child: Text(question['marks'].toString())),
                  ),
                  DataCell(
                    Center(
                      child: Text(
                        question['obtained_marks'].toString(),
                        style: TextStyle(
                          color: question['obtained_marks'] == question['marks']
                              ? successColor
                              : question['obtained_marks'] == 0
                              ? dangerColor
                              : warningColor,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
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
          'Exam Results',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: primaryColor,
        child: FutureBuilder<List<dynamic>>(
          future: _examData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
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
                      'Failed to load exam results',
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
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
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
                      'No exam results available',
                      style: TextStyle(
                        fontSize: 16,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }

            final examData = snapshot.data!;
            final filteredData = _selectedCourse == 'All'
                ? examData
                : examData.where((e) => e['course_name'] == _selectedCourse).toList();

            return SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Filter dropdown
                  Row(
                    children: [
                      Icon(Bootstrap.funnel, size: 16, color: textSecondary),
                      SizedBox(width: 8),
                      Text(
                        'Filter by:',
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondary,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(child: _buildCourseFilterDropdown(examData)),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Exam cards
                  ...filteredData.map((exam) => _buildExamCard(exam)).toList(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Filter skeleton
          Row(
            children: [
              Container(width: 16, height: 16, color: Colors.grey.shade300),
              SizedBox(width: 8),
              Container(width: 60, height: 16, color: Colors.grey.shade300),
              SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Exam card skeletons
          ...List.generate(3, (index) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              height: 220,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          )),
        ],
      ),
    );
  }
}