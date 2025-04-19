import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:icons_plus/icons_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'dart:convert';
import 'package:lmsv2/api/ApiConfig.dart';
import '../../provider/student_provider.dart';
import '../../alerts/custom_alerts.dart';
import '../../file_view/pdf_word_file_viewer.dart';

class CourseContentScreen extends StatefulWidget {
  final int studentId;

  const CourseContentScreen({
    Key? key,
    required this.studentId,
  }) : super(key: key);

  @override
  State<CourseContentScreen> createState() => _CourseContentScreenState();
}

class _CourseContentScreenState extends State<CourseContentScreen> {
  late Future<Map<String, dynamic>> _courseContentData;
  String? _selectedCourse;
  String? _selectedWeek;
  bool _includePrevious = false;
  bool _showNotesOnly = true; // Initially checked
  List<String> _courseOptions = [];
  List<String> _weekOptions = List.generate(16, (index) => (index + 1).toString());
  Directory? _lmsDir;
  Map<String, String> _courseSessionMap = {};
  Map<String, String> _courseDisplayMap = {};

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
    _courseContentData = _fetchCourseContentData();
    _initDirectory();
  }

  Future<void> _initDirectory() async {
    _lmsDir = Directory('/storage/emulated/0/LMS');
    if (!await _lmsDir!.exists()) {
      await _lmsDir!.create(recursive: true);
    }
  }

  Future<Map<String, dynamic>> _fetchCourseContentData() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.apiBaseUrl}Students/getStudentCourseContent?student_id=${widget.studentId}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == 'success') {
          _processCourseData(data['data']);

          // Set initial week from provider
          final currentWeek = Provider.of<StudentProvider>(context, listen: false).student?.currentWeek;
          _selectedWeek = currentWeek?.toString() ?? '1';

          return data['data'];
        } else {
          throw Exception('Failed to load course content data');
        }
      } else {
        throw Exception('Failed to load course content data');
      }
    } catch (e) {
      CustomAlert.error(context, 'Error!', 'An error occurred while fetching data');
      throw Exception('Error: $e');
    }
  }

  void _processCourseData(Map<String, dynamic> data) {
    _courseSessionMap.clear();
    _courseDisplayMap.clear();

    final activeCourses = (data['Active'] as List);
    final previousCourses = _includePrevious ? (data['Previous'] as List) : [];

    // Process active courses (show simple name)
    for (var course in activeCourses) {
      final name = course['course_name'];
      final session = course['session'];
      final key = '$name|$session';
      _courseSessionMap[key] = name;
      _courseDisplayMap[key] = name;
    }

    // Process previous courses (show with session)
    for (var course in previousCourses) {
      final name = course['course_name'];
      final session = course['session'];
      final key = '$name|$session';
      _courseSessionMap[key] = name;
      _courseDisplayMap[key] = '$name ($session)';
    }

    setState(() {
      _courseOptions = _courseSessionMap.keys.toList();
      if (_courseOptions.isNotEmpty) {
        _selectedCourse = _courseOptions.first;
      }
    });
  }

  Future<void> _refreshData() async {
    setState(() {
      _courseContentData = _fetchCourseContentData();
    });
  }

  Color _getContentTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'notes':
        return primaryColor;
      case 'assignment':
        return Color(0xFF20C997);
      case 'quiz':
        return Color(0xFF6F42C1);
      case 'mcqs':
        return Color(0xFFFD7E14);
      case 'labtask':
        return Color(0xFF6610F2);
      default:
        return textSecondary;
    }
  }

  IconData _getContentTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'notes':
        return Bootstrap.file_earmark_text;
      case 'assignment':
        return Bootstrap.file_earmark_plus;
      case 'quiz':
        return Bootstrap.file_earmark_check;
      case 'mcqs':
        return Bootstrap.file_earmark_richtext;
      case 'labtask':
        return Bootstrap.file_earmark_code;
      default:
        return Bootstrap.file_earmark;
    }
  }

  Future<String?> _downloadFile(String url, String filename) async {
    if (url.isEmpty || url == 'null') {
      CustomAlert.error(context, 'Error!', 'No file available for download');
      return null;
    }

    try {
      CustomAlert.loading(context,'WAIT ............. ', 'Downloading...');

      // Get file extension from URL
      final fileExtension = path.extension(url);
      if (!filename.endsWith(fileExtension)) {
        filename += fileExtension;
      }

      final filePath = '${_lmsDir!.path}/$filename';
      final file = File(filePath);

      if (await file.exists()) {
        Navigator.pop(context); // Close loading dialog
        return filePath;
      }

      final dio = Dio();
      await dio.download(url, filePath);

      Navigator.pop(context); // Close loading dialog
      CustomAlert.success(context, 'Success! \n File downloaded successfully');
      return filePath;
    } catch (e) {
      Navigator.pop(context); // Close loading dialog if still open
      CustomAlert.error(context, 'Error!', 'Failed to download file: $e');
      return null;
    }
  }

  Future<void> _openFile(String url, String filename) async {
    try {
      final filePath = await _downloadFile(url, filename);
      if (filePath != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PdfViewerScreen(
              fileUrl: url,
              filename: filename,
            ),
          ),
        );
      }
    } catch (e) {
      CustomAlert.error(context, 'Error!', 'Failed to open file: $e');
    }
  }

  Future<void> _shareFile(String url, String filename) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final fileExtension = path.extension(url);
      final tempFile = File('${tempDir.path}/$filename$fileExtension');

      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      final dio = Dio();
      await dio.download(url, tempFile.path);

      await Share.shareXFiles(
        [XFile(tempFile.path)],
        text: 'Sharing $filename',
      );
    } catch (e) {
      CustomAlert.error(context, 'Error!', 'Failed to share file: $e');
    }
  }

  Widget _buildContentCard(Map<String, dynamic> content) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
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
                    content['title'] ?? 'Untitled',
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
                    color: _getContentTypeColor(content['type']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getContentTypeColor(content['type']).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    content['type'].toString().toUpperCase(),
                    style: TextStyle(
                      color: _getContentTypeColor(content['type']),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),

            // File handling section
            if (content['File'] != null && content['File'] != 'null') ...[
              Row(
                children: [
                  Icon(
                    _getContentTypeIcon(content['type']),
                    size: 18,
                    color: primaryColor,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () => _openFile(content['File'], content['title']),
                      child: Text(
                        'View ${content['type']}',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    icon: Icon(Bootstrap.download, size: 16),
                    label: Text('Download'),
                    onPressed: () => _downloadFile(content['File'], content['title']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor.withOpacity(0.1),
                      foregroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: Icon(Bootstrap.share, size: 16),
                    label: Text('Share'),
                    onPressed: () => _shareFile(content['File'], content['title']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: successColor.withOpacity(0.1),
                      foregroundColor: successColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Text(
                'No file attached',
                style: TextStyle(
                  color: textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
              SizedBox(height: 12),
            ],

            // MCQS section
            if (content['MCQS'] != null && (content['MCQS'] as List).isNotEmpty) ...[
              Divider(height: 24),
              ExpansionTile(
                title: Text(
                  'MCQS (${content['MCQS'].length} questions)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textPrimary,
                  ),
                ),
                children: [
                  ...(content['MCQS'] as List).map<Widget>((mcq) => _buildMcqCard(mcq)).toList(),
                ],
              ),
            ],

            // Topics section
            if (content['topics'] != null && (content['topics'] as List).isNotEmpty) ...[
              Divider(height: 24),
              ExpansionTile(
                title: Text(
                  'Topics (${content['topics'].length})',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textPrimary,
                  ),
                ),
                children: [
                  ...(content['topics'] as List).map<Widget>((topic) => _buildTopicTile(topic)).toList(),
                ],
              ),
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

  Widget _buildMcqCard(Map<String, dynamic> mcq) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Q${mcq['Question NO']}: ${mcq['Question']}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text('1. ${mcq['Option 1']}'),
          Text('2. ${mcq['Option 2']}'),
          Text('3. ${mcq['Option 3']}'),
          Text('4. ${mcq['Option 4']}'),
          SizedBox(height: 8),
          Text(
            'Answer: ${mcq['Answer']}',
            style: TextStyle(
              color: successColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicTile(Map<String, dynamic> topic) {
    return ListTile(
      leading: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: topic['status'] == 'Covered' ? successColor.withOpacity(0.1) : dangerColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          topic['status'] == 'Covered' ? Bootstrap.check : Bootstrap.x,
          size: 14,
          color: topic['status'] == 'Covered' ? successColor : dangerColor,
        ),
      ),
      title: Text(
        topic['topic_name'],
        style: TextStyle(
          fontSize: 14,
          color: textPrimary,
        ),
      ),
      subtitle: Text(
        topic['status'],
        style: TextStyle(
          fontSize: 12,
          color: topic['status'] == 'Covered' ? successColor : dangerColor,
        ),
      ),
    );
  }

  Widget _buildCourseInfo(Map<String, dynamic> course) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: primaryColor.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            course['course_name'] ?? 'Unknown Course',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Bootstrap.calendar, size: 14, color: textSecondary),
              SizedBox(width: 4),
              Text(
                course['session'] ?? 'N/A',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 14,
                ),
              ),
              SizedBox(width: 12),
              Icon(Bootstrap.people, size: 14, color: textSecondary),
              SizedBox(width: 4),
              Text(
                course['Section'] ?? 'N/A',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          if (course['teacher_name'] != null && course['teacher_name'] != 'N/A') ...[
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Bootstrap.person, size: 14, color: textSecondary),
                SizedBox(width: 4),
                Text(
                  'Instructor: ${course['teacher_name']}',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> options,
    required Function(String?) onChanged,
    bool isCourse = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: textSecondary.withOpacity(0.2),
            ),
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
              isExpanded: true,
              value: value,
              icon: Icon(
                Bootstrap.chevron_down,
                size: 16,
                color: textSecondary,
              ),
              items: options.map((String key) {
                final displayText = isCourse
                    ? (_courseDisplayMap[key] ?? key)
                    : 'Week $key';
                return DropdownMenuItem<String>(
                  value: key,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      displayText,
                      style: TextStyle(
                        fontSize: 14,
                        color: textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(8),
              menuMaxHeight: 300,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required Function(bool) onSelected,
  }) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 13,
        ),
      ),
      selected: selected,
      onSelected: onSelected,
      selectedColor: primaryColor.withOpacity(0.2),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? primaryColor : textSecondary,
      ),
      checkmarkColor: primaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: selected ? primaryColor : textSecondary.withOpacity(0.2),
          width: 1,
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade100,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDropdownField(
                  label: 'Select Course',
                  value: _selectedCourse,
                  options: _courseOptions,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCourse = newValue;
                    });
                  },
                  isCourse: true,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildDropdownField(
                  label: 'Select Week',
                  value: _selectedWeek,
                  options: _weekOptions,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedWeek = newValue;
                    });
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip(
                label: 'Include Previous Courses',
                selected: _includePrevious,
                onSelected: (bool value) {
                  setState(() {
                    _includePrevious = value;
                    _refreshData();
                  });
                },
              ),
              _buildFilterChip(
                label: 'Notes Only',
                selected: _showNotesOnly,
                onSelected: (bool value) {
                  setState(() {
                    _showNotesOnly = value;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoContentCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade100,
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Bootstrap.file_earmark_text,
              size: 48,
              color: primaryColor.withOpacity(0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'No content available',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textSecondary.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Select different week or course',
              style: TextStyle(
                fontSize: 13,
                color: textSecondary.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        title: Text(
          'Course Content',
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
        child: FutureBuilder<Map<String, dynamic>>(
          future: _courseContentData,
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
                      'Failed to load course content',
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
            } else if (!snapshot.hasData || (snapshot.data!['Active'] == null && snapshot.data!['Previous'] == null)) {
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
                      'No course content available',
                      style: TextStyle(
                        fontSize: 16,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }

            final courseData = snapshot.data!;
            List<dynamic> allCourses = [...courseData['Active']];
            if (_includePrevious) {
              allCourses.addAll(courseData['Previous'] ?? []);
            }

            // Find the selected course
            final selectedCourse = allCourses.firstWhere(
                  (course) => '${course['course_name']}|${course['session']}' == _selectedCourse,
              orElse: () => allCourses.isNotEmpty ? allCourses.first : null,
            );

            if (selectedCourse == null) {
              return Center(
                child: _buildNoContentCard(),
              );
            }

            // Get content for selected week
            final weekContent = selectedCourse['course_content']?[_selectedWeek] as List<dynamic>? ?? [];

            // Filter for notes only if needed
            final filteredContent = _showNotesOnly
                ? weekContent.where((content) => content['type'] == 'Notes').toList()
                : weekContent;

            return SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildFilters(),
                  SizedBox(height: 16),
                  _buildCourseInfo(selectedCourse),
                  SizedBox(height: 16),
                  if (filteredContent.isEmpty)
                    _buildNoContentCard(),
                  ...filteredContent.map((content) => _buildContentCard(content)).toList(),
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
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          SizedBox(height: 16),
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          SizedBox(height: 16),
          ...List.generate(
            3,
                (index) => Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}