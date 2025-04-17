import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:icons_plus/icons_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:lmsv2/api/ApiConfig.dart';
import '../provider/student_provider.dart';
import 'Transcript/manage.dart';

class StudentTranscriptScreen extends StatefulWidget {
  final int studentId;

  const StudentTranscriptScreen({
    Key? key,
    required this.studentId,
  }) : super(key: key);

  @override
  State<StudentTranscriptScreen> createState() => _StudentTranscriptScreenState();
}

class _StudentTranscriptScreenState extends State<StudentTranscriptScreen> {
  late Future<List<dynamic>> _transcriptData;
  String? _pdfUrl;
  bool _isDownloading = false;
  String? _downloadedFilePath;
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
    _transcriptData = _fetchTranscriptData();
  }

  Future<List<dynamic>> _fetchTranscriptData() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.apiBaseUrl}Students/Transcript?student_id=${widget.studentId}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;

        setState(() {
          _sessionOptions = ['All', ...data.map((e) => e['session_name'] as String).toList()];
          _calculateFailedSubjects(data);
        });

        return data;
      } else {
        throw Exception('Failed to load transcript data');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }


  void _calculateFailedSubjects(List<dynamic> transcriptData) {
    int failedCount = 0;
    for (var session in transcriptData) {
      for (var subject in session['subjects'] ?? []) {
        if (subject['grade'] == 'F') failedCount++;
      }
    }
    setState(() => _failedSubjectsCount = failedCount);
  }

  Future<void> _refreshData() async {
    setState(() {
      _transcriptData = _fetchTranscriptData();
    });
  }

  Color _getGradeColor(String? grade) {
    if (grade == null || grade == 'N/A' || grade == 'Pending') return textSecondary;
    switch (grade.toUpperCase()) {
      case 'A': return successColor;
      case 'B': return Color(0xFF5CB85C);
      case 'C': return warningColor;
      case 'D': return Color(0xFFFF851B);
      case 'F': return dangerColor;
      default: return textSecondary;
    }
  }


  Widget _buildTranscriptHeader(BuildContext context) {
    final student = Provider.of<StudentProvider>(context).student;
    final currentSemester = student?.section?.split('-').last ?? 'N/A';

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'ACADEMIC TRANSCRIPT',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ),
          SizedBox(height: 16),
          _buildInfoRow('Name:', student?.name ?? 'N/A'),
          _buildInfoRow('Registration No:', student?.regNo ?? 'N/A'),
          _buildInfoRow('Father/Guardian:', student?.guardian ?? 'N/A'),
          _buildInfoRow('Current Semester:', currentSemester),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoChip(
                'Failed Subjects: $_failedSubjectsCount',
                _failedSubjectsCount > 0 ? dangerColor : successColor,
              ),
              _buildInfoChip(
                'CGPA: ${student?.cgpa ?? 'N/A'}',
                primaryColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSessionDropdown(List<dynamic> transcriptData) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textSecondary.withOpacity(0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedSession,
          icon: Icon(Bootstrap.chevron_down, size: 14, color: textSecondary),
          items: _sessionOptions.map((String value) {
            int count = value == 'All'
                ? transcriptData.length
                : transcriptData.where((e) => e['session_name'] == value).length;
            return DropdownMenuItem<String>(
              value: value,
              child: Text('$value ($count)', style: TextStyle(fontSize: 13)),
            );
          }).toList(),
          onChanged: (String? newValue) => setState(() => _selectedSession = newValue!),
        ),
      ),
    );
  }

  Widget _buildSessionTranscript(Map<String, dynamic> session) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: cardBackground,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  session['session_name'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: primaryColor,
                  ),
                ),
                Row(
                  children: [
                    Text('GPA: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(session['GPA'], style: TextStyle(color: primaryColor)),
                    SizedBox(width: 12),
                    Text('Credits: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(session['total_credit_points'].toString()),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1),
          _buildSubjectsTable(session['subjects']),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(
      begin: 0.1, end: 0, duration: 250.ms, curve: Curves.easeOutQuad,
    );
  }

  Widget _buildSubjectsTable(List<dynamic> subjects) {
    return DataTable(
      columnSpacing: 12,
      horizontalMargin: 12,
      headingRowHeight: 40,
      dataRowHeight: 40,
      columns: [
        DataColumn(label: Text('Code', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Course', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(
          label: Text('Credit', style: TextStyle(fontWeight: FontWeight.bold)),
          numeric: true,
        ),
        DataColumn(label: Text('Grade', style: TextStyle(fontWeight: FontWeight.bold))),
      ],
      rows: subjects.map<DataRow>((subject) {
        return DataRow(
            cells: [
        DataCell(
        Text(subject['course_code'] ?? 'N/A', style: TextStyle(fontSize: 12)),),
        DataCell(
        Text(subject['course_name'] ?? 'N/A', style: TextStyle(fontSize: 12)),),
        DataCell(
        Text(subject['credit_hours']?.toString() ?? '0', style: TextStyle(fontSize: 12)),),
        DataCell(
        InkWell(
        onTap: subject['overall'] != null && subject['overall'] != 'N/A'
        ? () => _showSubjectDetails(subject)
            : null,
        child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
        color: _getGradeColor(subject['grade']).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
        subject['grade'] ?? 'N/A',
        style: TextStyle(
        color: _getGradeColor(subject['grade']),
        fontWeight: FontWeight.w500,
        fontSize: 12,
        ),
        ),
        ),
        ),
        ),
        ],
        );
      }).toList(),
    );
  }

  void _showSubjectDetails(Map<String, dynamic> subject) {
    final overall = subject['overall'];
    if (overall == null || overall == 'N/A') return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Result Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${subject['course_name']} (${subject['course_code']})',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              _buildDetailRow('Mid Term', overall['mid']?.toString() ?? 'N/A'),
              _buildDetailRow('Final Term', overall['final']?.toString() ?? 'N/A'),
              _buildDetailRow('Internal', overall['internal']?.toString() ?? 'N/A'),
              if (overall['lab'] != null)
                _buildDetailRow('Lab', overall['lab']?.toString() ?? 'N/A'),
              _buildDetailRow('Quality Points', overall['quality_points']?.toString() ?? 'N/A'),
              Divider(height: 24),
              _buildDetailRow('Final Grade', subject['grade'] ?? 'N/A',
                  color: _getGradeColor(subject['grade'])),
            ],
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

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: textSecondary)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w500, color: color ?? textPrimary)),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed: () => TranscriptPDFHandler.downloadAndOpenTranscript(context, widget.studentId),
            icon: Icon(Bootstrap.download, size: 16),
            label: Text('Download PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
          SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: () => TranscriptPDFHandler.shareTranscript(context, widget.studentId),
            icon: Icon(Bootstrap.share, size: 16),
            label: Text('Share'),
            style: ElevatedButton.styleFrom(
              backgroundColor: successColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        title: Text('Academic Transcript', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: primaryColor,
        child: FutureBuilder<List<dynamic>>(
          future: _transcriptData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildSkeletonLoader();
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Bootstrap.exclamation_triangle, size: 40, color: dangerColor),
                    SizedBox(height: 16),
                    Text('Failed to load transcript', style: TextStyle(fontSize: 16)),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _refreshData,
                      style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                      child: Text('Retry', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Bootstrap.file_earmark_text, size: 40, color: textSecondary),
                    SizedBox(height: 16),
                    Text('No transcript data available', style: TextStyle(fontSize: 16)),
                  ],
                ),
              );
            }

            final transcriptData = snapshot.data!;
            final filteredData = _selectedSession == 'All'
                ? transcriptData
                : transcriptData.where((e) => e['session_name'] == _selectedSession).toList();

            return SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildTranscriptHeader(context),
                  _buildActionButtons(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [_buildSessionDropdown(transcriptData)],
                  ),
                  SizedBox(height: 16),
                  ...filteredData.map((session) => _buildSessionTranscript(session)),
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
          Container(height: 180, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 120, height: 40, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
              SizedBox(width: 16),
              Container(width: 80, height: 40, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
            ],
          ),
          SizedBox(height: 16),
          Container(width: 150, height: 30, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
          SizedBox(height: 16),
          ...List.generate(3, (index) => Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Container(height: 200, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
          )),
        ],
      ),
    );
  }
}