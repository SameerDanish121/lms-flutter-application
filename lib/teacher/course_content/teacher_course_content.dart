import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lmsv2/teacher/course_content/add_course_content.dart';
import 'dart:convert';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:lmsv2/alerts/custom_alerts.dart';
import 'package:lmsv2/api/ApiConfig.dart';
import 'package:lmsv2/teacher/course_content/update_coursecontent_status.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import '../../Theme/theme.dart';
import '../../file_view/offilne_view.dart';
import '../../file_view/pdf_word_file_viewer.dart';
import '../../provider/instructor_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class CourseContent extends StatefulWidget {
  const CourseContent({Key? key}) : super(key: key);
  @override
  _CourseContentState createState() => _CourseContentState();
}

class _CourseContentState extends State<CourseContent> {
  Map<String, dynamic>? courseData;
  bool isLoading = true;
  String? selectedCourse;
  int? selectedWeek;
  int? providerWeek; // Store the week from provider separately

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
  GlobalKey<RefreshIndicatorState>();
  late final String teacherId;

  @override
  void initState() {
    final instructor =
        Provider.of<InstructorProvider>(context, listen: false).instructor;
    teacherId = instructor!.id.toString();
    providerWeek = instructor.week; // Store the week from provider
    super.initState();
    fetchCourseContent();
  }

  Future<void> fetchCourseContent() async {
    setState(() {
      isLoading = true;
      courseData = null;
      selectedCourse = null;
    });

    try {
      final response = await http.get(
        Uri.parse(
            '${ApiConfig.apiBaseUrl}Teachers/get_course_content?teacher_id=${teacherId}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map && data['status'] == true && data['course_contents'] is Map) {
          setState(() {
            courseData = Map<String, dynamic>.from(data['course_contents']);
            if (courseData != null && courseData!.isNotEmpty) {
              selectedCourse = courseData!.keys.first;
              // Always use the provider week if it exists
              if (providerWeek != null && providerWeek != 0) {
                selectedWeek = providerWeek;
              }
            }
          });
        } else {
          throw Exception('No valid course content available');
        }
      } else {
        throw Exception('Failed to load course content: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      debugPrint('Error fetching course content: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  List<DropdownMenuItem<String>> getCourseDropdownItems() {
    if (courseData == null || courseData!.isEmpty) return [];
    return courseData!.keys.map((courseId) {
      final courseList = courseData![courseId];
      if (courseList is! List || courseList.isEmpty || courseList[0] is! Map) {
        return DropdownMenuItem<String>(
          value: courseId,
          child: Text('Unknown Course', style: AppTheme.bodyStyle),
        );
      }
      final course = courseList[0];
      return DropdownMenuItem<String>(
        value: courseId,
        child: Text(
          course['course_name']?.toString() ?? 'Unknown Course',
          style: AppTheme.bodyStyle,
        ),
      );
    }).toList();
  }

  List<int> getAvailableWeeks() {
    // Get weeks from course content
    List<int> contentWeeks = [];
    if (selectedCourse != null &&
        courseData != null &&
        courseData![selectedCourse] is List &&
        courseData![selectedCourse].isNotEmpty &&
        courseData![selectedCourse][0] is Map) {
      final courseContent = courseData![selectedCourse][0]['course_content'];
      if (courseContent is Map && courseContent.isNotEmpty) {
        contentWeeks = courseContent.keys
            .where((weekStr) => weekStr is String && int.tryParse(weekStr) != null)
            .map<int>((weekStr) => int.parse(weekStr))
            .toList();
      }
    }

    // Add provider week if it exists and isn't already in the list
    if (providerWeek != null && providerWeek != 0 && !contentWeeks.contains(providerWeek)) {
      contentWeeks.add(providerWeek!);
    }

    contentWeeks.sort();
    return contentWeeks;
  }

  List<dynamic> getCurrentWeekContent() {
    if (selectedCourse == null || selectedWeek == null || courseData == null) {
      return [];
    }
    final courseContent = courseData![selectedCourse][0]['course_content'] ?? {};
    return courseContent[selectedWeek.toString()] ?? [];
  }

  Widget _buildSectionButtons() {
    if (selectedCourse == null ||
        courseData == null ||
        courseData![selectedCourse] is! List ||
        courseData![selectedCourse].isEmpty ||
        courseData![selectedCourse][0] is! Map) {
      return SizedBox();
    }

    final sections = courseData![selectedCourse][0]['sections'];
    if (sections is! List || sections.isEmpty) return SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: sections.whereType<Map>().map((section) {
          return ActionChip(
            label: Text(
              section['section_name']?.toString() ?? 'Section',
              style: AppTheme.bodyStyle.copyWith(color: Colors.white),
            ),
            backgroundColor: AppTheme.primaryColor,
            onPressed: () => _handleSectionClick(section),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _handleSectionClick(Map<dynamic, dynamic> section) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SectionDetailsScreen(
          section: Map<String, dynamic>.from(section),
          teacherId: teacherId,
        ),
      ),
    );
  }

  Widget _buildContentItem(dynamic item, BuildContext context) {
    if (item is! Map) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          title: Text('Invalid content format', style: AppTheme.bodyStyle),
          leading: Icon(Icons.error_outline, color: Colors.red),
        ),
      );
    }

    final type = item['type']?.toString()?.toLowerCase() ?? 'unknown';
    final title = item['title']?.toString() ?? 'Untitled';
    final fileUrl = item['File']?.toString();
    final isMCQs = type == 'quiz' && item['File'] is List;
    final hasFile = fileUrl != null && fileUrl.isNotEmpty && !isMCQs;

    bool isDownloading = false;
    double downloadProgress = 0;

    final Map<String, Color> typeColors = {
      'notes': Color(0xFF4285F4),
      'assignment': Color(0xFF34A853),
      'quiz': isMCQs ? Color(0xFF673AB7) : Color(0xFFFBBC05),
      'unknown': Color(0xFF9E9E9E),
    };

    final displayType = isMCQs ? 'quiz (mcqs)' : type;
    final Color typeColor = typeColors[displayType] ?? Colors.grey;
    final Color borderColor = typeColor.withOpacity(0.2);
    final Color badgeColor = typeColor.withOpacity(0.15);
    final Color textColor = typeColor;

    Future<String?> handleDownload() async {
      try {
        String? url = fileUrl;
        String fileName = title;
        Directory lmsDir = Directory('/storage/emulated/0/LMS');

        if (!await lmsDir.exists()) {
          await lmsDir.create(recursive: true);
        }

        String fileExtension = path.extension(fileUrl!);
        if (!fileName.endsWith(fileExtension)) {
          fileName += fileExtension;
        }

        String filePath = '${lmsDir.path}/$fileName';

        Dio dio = Dio();
        await dio.download(fileUrl!, filePath, onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() => downloadProgress = received / total);
          }
        });
        CustomAlert.success(
            context, 'The file has been downloaded successfully: $filePath');
        return filePath;
      } catch (e) {
        CustomAlert.error(context, 'Error', "Download failed: $e");
        return null;
      }
    }

    Future<void> handleView() async {
      if (isMCQs) {
        _showQuizDialog(item['File']);
        return;
      }

      if (!hasFile) return;

      final extension = fileUrl.split('.').last;
      final fileName = '${title.replaceAll(RegExp(r'[^\w.]'), '_')}.$extension';
      final dir = await getApplicationDocumentsDirectory();
      final localPath = '${dir.path}/$fileName';
      if (extension == 'pdf') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PdfViewerScreen(fileUrl: fileUrl),
          ),
        );
      } else {
        await OpenFilex.open(fileUrl);
      }
    }

    IconData _getIconForType(String type) {
      switch (type) {
        case 'notes':
          return Icons.article_outlined;
        case 'assignment':
          return Icons.assignment_outlined;
        case 'quiz':
          return isMCQs ? Icons.quiz_outlined : Icons.assignment_turned_in_outlined;
        default:
          return Icons.insert_drive_file_outlined;
      }
    }

    return StatefulBuilder(
      builder: (context, setState) {
        return Card(
          elevation: 2,
          margin: EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: borderColor,
              width: 1,
            ),
          ),
          child: InkWell(
            onTap: isMCQs ? handleView : null,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          displayType.toUpperCase(),
                          style: AppTheme.captionStyle.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Spacer(),
                      if (hasFile || isMCQs)
                        IconButton(
                          icon: Icon(
                            Icons.visibility_outlined,
                            color: AppTheme.primaryColor,
                            size: 24,
                          ),
                          onPressed: handleView,
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                        ),
                      if (hasFile && !isMCQs && !isDownloading)
                        IconButton(
                          icon: Icon(
                            Icons.download_outlined,
                            color: AppTheme.primaryColor,
                            size: 24,
                          ),
                          onPressed: () async {
                            await handleDownload();
                          },
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                        ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        _getIconForType(type),
                        color: typeColor,
                        size: 28,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: AppTheme.subHeadingStyle.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  if (isDownloading)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: LinearProgressIndicator(
                        value: downloadProgress,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(typeColor),
                      ),
                    )
                  else if (!hasFile && !isMCQs)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'No file available',
                        style: AppTheme.captionStyle.copyWith(
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  if (type == 'notes' && item['topics'] is List)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Divider(
                            color: AppTheme.dividerColor.withOpacity(0.5),
                            height: 1,
                          ),
                          SizedBox(height: 8),
                          ...(item['topics'] as List).whereType<Map>().map((topic) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.circle,
                                    size: 8,
                                    color: typeColor.withOpacity(0.6),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      topic['topic_name']?.toString() ?? 'Untitled topic',
                                      style: AppTheme.bodyStyle.copyWith(
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showQuizDialog(List<dynamic>? questions) {
    if (questions == null || questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No quiz questions available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quiz Questions',
                style: AppTheme.headingStyle.copyWith(color: AppTheme.primaryColor),
              ),
              SizedBox(height: 16),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                width: MediaQuery.of(context).size.width * 0.8,
                child: ListView.separated(
                  itemCount: questions.length,
                  separatorBuilder: (context, index) =>
                      Divider(color: AppTheme.dividerColor),
                  itemBuilder: (context, index) {
                    final question = questions[index];
                    if (question is! Map) {
                      return ListTile(
                        title: Text('Invalid question format',
                            style: AppTheme.bodyStyle),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Q${question['Question NO']?.toString() ?? '?'}: ${question['Question']?.toString() ?? 'No question text'}',
                            style: AppTheme.subHeadingStyle,
                          ),
                          SizedBox(height: 8),
                          _buildOption(1, question['Option 1']),
                          _buildOption(2, question['Option 2']),
                          _buildOption(3, question['Option 3']),
                          _buildOption(4, question['Option 4']),
                          SizedBox(height: 8),
                          Text(
                            'Answer: ${question['Answer']?.toString() ?? 'Unknown'}',
                            style: AppTheme.bodyStyle.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption(int number, dynamic option) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text('$number. ', style: AppTheme.bodyStyle),
          Expanded(
              child: Text(option?.toString() ?? 'N/A', style: AppTheme.bodyStyle)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final instructor =
        Provider.of<InstructorProvider>(context, listen: false).instructor;
    final currentSession = instructor!.session ?? 'NO Current Session';

    return Theme(
      data: AppTheme.themeData,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Course Content',
            style: TextStyle(
              color: Color(0xFF1976D2),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 1,
          automaticallyImplyLeading: false,
          iconTheme: IconThemeData(color: Color(0xFF1976D2)),
          actions: [
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Color(0xFF1976D2)),
              onSelected: (String value) {
                switch (value) {
                  case 'downloads':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => DownloadsViewerScreen()),
                    );
                    break;
                  case 'create':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CreateCourseContentScreen(teacherId: teacherId),
                      ),
                    );
                    break;
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<String>(
                  value: 'downloads',
                  child: Row(
                    children: [
                      Icon(Icons.download, color: Color(0xFF1976D2)),
                      SizedBox(width: 12),
                      Text(
                        'Downloads',
                        style: TextStyle(color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'create',
                  child: Row(
                    children: [
                      Icon(Icons.add_box, color: Color(0xFF1976D2)),
                      SizedBox(width: 12),
                      Text(
                        'Create New Content',
                        style: TextStyle(color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: fetchCourseContent,
          color: AppTheme.primaryColor,
          child: isLoading
              ? Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor))
              : courseData == null || courseData!.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline,
                    size: 48, color: AppTheme.secondaryTextColor),
                SizedBox(height: 16),
                Text(
                  'No course content available',
                  style: AppTheme.subHeadingStyle,
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  style: AppTheme.primaryButtonStyle,
                  onPressed: fetchCourseContent,
                  child: Text('Retry'),
                ),
              ],
            ),
          )
              : SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    margin: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            currentSession,
                            style: AppTheme.headingStyle.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                'Current Session',
                                style: AppTheme.subHeadingStyle.copyWith(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(width: 8),
                              Container(
                                height: 12,
                                width: 1,
                                color: Colors.grey[400],
                              ),
                              SizedBox(width: 8),
                              Text(
                                '${courseData?.length ?? 0} Courses',
                                style: AppTheme.captionStyle.copyWith(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: selectedCourse,
                    items: getCourseDropdownItems(),
                    onChanged: (value) {
                      setState(() {
                        selectedCourse = value;
                        // Reset to provider week when course changes
                        selectedWeek = providerWeek;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Select Course',
                      border: OutlineInputBorder(),
                      filled: true,
                    ),
                    isExpanded: true,
                    style: AppTheme.bodyStyle,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Sections:',
                    style: AppTheme.subHeadingStyle,
                  ),
                  _buildSectionButtons(),
                  SizedBox(height: 16),
                  if (selectedCourse != null)
                    DropdownButtonFormField<int>(
                      value: selectedWeek,
                      items: getAvailableWeeks().map((week) {
                        return DropdownMenuItem<int>(
                          value: week,
                          child: Text(
                            'Week $week',
                            style: AppTheme.bodyStyle,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedWeek = value;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Select Week',
                        border: OutlineInputBorder(),
                        filled: true,
                      ),
                      isExpanded: true,
                      style: AppTheme.bodyStyle,
                    ),
                  SizedBox(height: 20),
                  if (selectedWeek != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Week $selectedWeek Content',
                          style: AppTheme.subHeadingStyle.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        if (getCurrentWeekContent().isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'No content available for this week',
                              style: AppTheme.captionStyle,
                            ),
                          ),
                        ...getCurrentWeekContent()
                            .map((content) => _buildContentItem(content, context)),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}