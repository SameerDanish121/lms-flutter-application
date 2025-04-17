import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:intl/intl.dart';
import 'package:quickalert/quickalert.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../alerts/custom_alerts.dart';
import '../../file_view/pdf_word_file_viewer.dart';
import '../../api/ApiConfig.dart';
import '../../provider/student_provider.dart';

class FileTaskAttemptScreen extends StatefulWidget {
  final dynamic task;
  const FileTaskAttemptScreen({Key? key, required this.task}) : super(key: key);

  @override
  State<FileTaskAttemptScreen> createState() => _FileTaskAttemptScreenState();
}

class _FileTaskAttemptScreenState extends State<FileTaskAttemptScreen> {
  PlatformFile? _selectedFile;
  bool _isSubmitting = false;
  bool _isSubmitted = false;
  bool _isMcqTask = false;

  // Theme Colors
  static const Color primaryColor = Color(0xFF4361EE);
  static const Color successColor = Color(0xFF4CC9F0);
  static const Color errorColor = Color(0xFFF94144);
  static const Color surfaceColor = Color(0xFFF8F9FA);
  static const Color onSurfaceColor = Color(0xFF212529);

  @override
  void initState() {
    super.initState();
    _checkSubmissionStatus();
    _checkIfMcqTask();
  }

  void _checkSubmissionStatus() {
    final submission = widget.task['Your_Submission'];
    setState(() {
      _isSubmitted = submission != null &&
          submission.toString().trim().isNotEmpty &&
          submission.toString().toUpperCase() != 'N/A';
    });
  }

  void _checkIfMcqTask() {
    final type = widget.task['type'];
    setState(() {
      _isMcqTask = type != null && type.toString().toUpperCase() == 'MCQS';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    final studentId = studentProvider.student?.id;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          title: Text(
            widget.task['title']?.toString() ?? 'Assignment',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.white
            ),
          ),
          elevation: 0,
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Assignment Overview Card
              _buildAssignmentCard(theme),
              const SizedBox(height: 16),

              // Submission Section
              Text(
                'Your Submission',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _isMcqTask
                  ? _buildMcqWarning(theme)
                  : _isSubmitted
                  ? _buildSubmissionStatus(theme)
                  : _buildFileUploadSection(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssignmentCard(ThemeData theme) {
    final taskType = widget.task['type']?.toString() ?? '';
    final points = widget.task['points']?.toString() ?? '0';
    final courseName = widget.task['course_name']?.toString() ?? '';
    final creatorName = widget.task['creator_name']?.toString() ?? '';
    final dueDate = widget.task['due_date']?.toString() ?? '';
    final fileUrl = widget.task['File']?.toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getTaskTypeColor(taskType).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  taskType,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: _getTaskTypeColor(taskType),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Chip(
                label: Text(
                  '$points pts',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                  ),
                ),
                backgroundColor: primaryColor,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Course', courseName, theme),
          _buildInfoRow('Created by', creatorName, theme),
          _buildInfoRow('Due', _formatDateTime(dueDate), theme),
          if (fileUrl != null && fileUrl.trim().isNotEmpty && fileUrl.toUpperCase() != 'N/A') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _viewAssignmentFile(),
                icon: const Icon(Iconsax.document, size: 18),
                label: const Text('View Assignment'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: primaryColor),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMcqWarning(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: errorColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: errorColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Iconsax.warning_2, color: errorColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'This is an MCQ task. Please use the MCQ submission interface.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: onSurfaceColor.withOpacity(0.6),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileUploadSection(ThemeData theme) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Upload your solution',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Only PDF files (max 10MB)',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: onSurfaceColor.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickFile,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _selectedFile != null
                          ? successColor
                          : Colors.grey.shade300,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Iconsax.document_upload,
                        size: 24,
                        color: _selectedFile != null
                            ? successColor
                            : primaryColor,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedFile?.name ?? 'Select PDF file',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_selectedFile != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                '${(_selectedFile!.size / (1024 * 1024)).toStringAsFixed(2)} MB',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: onSurfaceColor.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (_selectedFile != null)
                        Icon(
                          Iconsax.tick_circle,
                          color: successColor,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _selectedFile != null ? _submitAssignment : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text('Submit Assignment'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubmissionStatus(ThemeData theme) {
    final submissionDate = widget.task['Submission_Date_Time']?.toString() ?? '';
    final dueDate = widget.task['due_date']?.toString() ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: successColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: successColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Iconsax.tick_circle,
                color: successColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Submitted successfully',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _formatDateTime(submissionDate),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: onSurfaceColor.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Iconsax.eye,
                  size: 20,
                  color: primaryColor,
                ),
                onPressed: _viewSubmissionFile,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'You can view your submission until ${_formatDateTime(dueDate)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: onSurfaceColor.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.size > 10 * 1024 * 1024) { // 10MB limit
          CustomAlert.error(context, 'File Too Large', 'Maximum file size is 10MB');
          return;
        }

        setState(() {
          _selectedFile = file;
        });
      }
    } catch (e) {
      CustomAlert.error(context, 'Error', 'Failed to pick file: ${e.toString()}');
    }
  }

  Future<void> _submitAssignment() async {
    final confirmed = await CustomAlert.confirm(
        context,
        'Are you sure you want to submit this file?'
    );

    if (!confirmed) return;

    if (_selectedFile == null || _selectedFile?.path == null) {
      CustomAlert.error(context, 'Error', 'No file selected');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final studentProvider = Provider.of<StudentProvider>(context, listen: false);
      final studentId = studentProvider.student?.id;

      if (studentId == null) {
        throw Exception('Student ID not found');
      }

      final taskId = widget.task['task_id'] as int?;
      if (taskId == null) {
        throw Exception('Task ID not found');
      }

      final file = File(_selectedFile!.path!);
      if (!await file.exists()) {
        throw Exception('File does not exist');
      }

      final response = await _submitFileToServer(
        file,
        studentId,
        taskId,
      );

      if (response['success'] == true) {
        setState(() {
          _isSubmitted = true;
          _isSubmitting = false;
        });
        _showSubmissionSuccess(response);
      } else {
        throw Exception(response['error']?.toString() ?? 'Submission failed');
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      CustomAlert.error(context, 'Submission Failed', 'Error: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> _submitFileToServer(
      File file,
      int studentId,
      int taskId,
      ) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.apiBaseUrl}Students/submit-task-file'),
      );

      // Add file
      request.files.add(
        await http.MultipartFile.fromPath(
          'Answer',
          file.path,
          contentType: MediaType('application', 'pdf'),
        ),
      );

      // Add other fields
      request.fields['student_id'] = studentId.toString();
      request.fields['task_id'] = taskId.toString();

      // Send request
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        try {
          final jsonResponse = json.decode(responseBody);
          return {
            'success': true,
            'message': jsonResponse['message']?.toString() ?? 'Submission successful',
            'data': jsonResponse,
          };
        } catch (e) {
          return {
            'success': true,
            'message': 'Submission successful',
            'data': responseBody,
          };
        }
      } else {
        try {
          final errorData = json.decode(responseBody);
          return {
            'success': false,
            'error': errorData['error']?.toString() ??
                errorData['message']?.toString() ??
                'Submission failed with status ${response.statusCode}',
          };
        } catch (e) {
          return {
            'success': false,
            'error': 'Server error: ${response.statusCode}',
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  void _showSubmissionSuccess([Map<String, dynamic>? response]) {
    final points = widget.task['points']?.toString() ?? '0';

    QuickAlert.show(
      context: context,
      type: QuickAlertType.success,
      title: 'Submitted!',
      text: response?['message']?.toString() ?? 'Your work has been submitted',
      confirmBtnColor: primaryColor,
      widget: Column(
        children: [
          const SizedBox(height: 20),
          const Icon(Iconsax.tick_circle, size: 60, color: successColor),
          const SizedBox(height: 20),
          Text(
            '$points points possible',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _viewAssignmentFile() {
    final fileUrl = widget.task['File']?.toString();
    final title = widget.task['title']?.toString() ?? 'Assignment';

    if (fileUrl == null || fileUrl.isEmpty || fileUrl.toUpperCase() == 'N/A') {
      CustomAlert.error(context, 'Error', 'No file available');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(
          fileUrl: fileUrl,
          filename: title,
        ),
      ),
    );
  }

  void _viewSubmissionFile() {
    final fileUrl = widget.task['Your_Submission']?.toString();
    if (fileUrl == null || fileUrl.isEmpty || fileUrl.toUpperCase() == 'N/A') {
      CustomAlert.error(context, 'Error', 'No submission file available');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(
          fileUrl: fileUrl,
          filename: 'Your Submission',
        ),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (_selectedFile != null && !_isSubmitted) {
      return await CustomAlert.confirm(
          context,
          'You have unsaved changes. Leave without submitting?'
      );
    }
    return true;
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null || dateTime.isEmpty) return 'N/A';

    try {
      return DateFormat('MMM d, y • h:mm a').format(DateTime.parse(dateTime));
    } catch (e) {
      return dateTime;
    }
  }

  Color _getTaskTypeColor(String? type) {
    final typeStr = type?.toString().toLowerCase() ?? '';
    switch (typeStr) {
      case 'assignment': return const Color(0xFF38A3A5);
      case 'quiz': return successColor;
      case 'mcqs': return const Color(0xFF7209B7);
      case 'labtask': return const Color(0xFFF8961E);
      default: return primaryColor;
    }
  }
}