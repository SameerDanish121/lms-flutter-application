import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:lmsv2/api/ApiConfig.dart';
import 'package:lmsv2/teacher/course_content/update_coursecontent_status.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../Theme/theme.dart';
import '../../file_view/pdf_word_file_viewer.dart';
import '../../provider/instructor_provider.dart';
import 'package:path_provider/path_provider.dart'; // For getApplicationDocumentsDirectory()
import 'dart:io'; // For File class
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

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
  GlobalKey<RefreshIndicatorState>();
  late final String teacherId;
  @override
  void initState() {
    final instructor =
        Provider.of<InstructorProvider>(context, listen: false).instructor;
    teacherId=instructor?.id as String;
    super.initState();
    fetchCourseContent();
  }
  Future<void> fetchCourseContent() async {
    setState(() {
      isLoading = true;
      courseData = null;
      selectedCourse = null;
      selectedWeek = null;
    });
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.apiBaseUrl}Teachers/get_course_content?teacher_id=${teacherId}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map && data['status'] == true && data['course_contents'] is Map) {
          setState(() {
            courseData = Map<String, dynamic>.from(data['course_contents']);
            if (courseData != null && courseData!.isNotEmpty) {
              selectedCourse = courseData!.keys.first;
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
    if (selectedCourse == null ||
        courseData == null ||
        courseData![selectedCourse] is! List ||
        courseData![selectedCourse].isEmpty ||
        courseData![selectedCourse][0] is! Map) {
      return [];
    }

    final courseContent = courseData![selectedCourse][0]['course_content'];
    if (courseContent is! Map || courseContent.isEmpty) return [];

    try {
      return courseContent.keys
          .where((weekStr) => weekStr is String && int.tryParse(weekStr) != null)
          .map<int>((weekStr) => int.parse(weekStr))
          .toList()
        ..sort();
    } catch (e) {
      debugPrint('Error parsing weeks: $e');
      return [];
    }
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
    // Handle section click - you can access full section data here
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SectionDetailsScreen(
          section: Map<String, dynamic>.from(section),
          teacherId:teacherId,
        ),
      ),
    );
  }
  Widget _buildContentItem(dynamic item, BuildContext context) {
    if (item is! Map) {
      return Card(
        child: ListTile(
          title: Text('Invalid content format', style: AppTheme.bodyStyle),
          leading: Icon(Icons.error, color: Colors.red),
        ),
      );
    }

    final type = item['type']?.toString()?.toLowerCase() ?? 'unknown';
    final title = item['title']?.toString() ?? 'Untitled';
    final fileUrl = item['File']?.toString();
    final isMCQs = type == 'quiz' && item['File'] is List;
    final hasFile = fileUrl != null && fileUrl.isNotEmpty && !isMCQs;

    // State for download progress
    bool isDownloading = false;
    double downloadProgress = 0;

    // Define color schemes for each type
    final Map<String, Color> typeColors = {
      'notes': Colors.blue,
      'assignment': Colors.green,
      'quiz': isMCQs ? Colors.purple : Colors.orange,
    };

    final displayType = isMCQs ? 'quiz (mcqs)' : type;
    final Color typeColor = typeColors[displayType] ?? Colors.grey;
    final Color borderColor = typeColor.withOpacity(0.3);
    final Color badgeColor = typeColor.withOpacity(0.2);
    final Color textColor = typeColor;
    Future<bool> _requestPermissions() async {
      if (Platform.isAndroid) {
        if (await Permission.storage.isGranted) return true;

        final status = await Permission.storage.request();
        if (!status.isGranted) {
          if (await Permission.manageExternalStorage.request().isGranted) {
            return true;
          }
          return false;
        }
        return true;
      }
      return true;
    }

    Future<void> handleDownload() async {
      if (!await _requestPermissions()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Storage permission required')),
        );
        return;
      }

      setState(() => isDownloading = true);

      try {
        final extension = fileUrl?.split('.').last;
        final fileName = '${title.replaceAll(RegExp(r'[^\w.]'), '_')}.$extension';
        final dir = await getApplicationDocumentsDirectory();
        final savePath = '${dir.path}/$fileName';

        await Dio().download(
          fileUrl!,
          savePath,
          onReceiveProgress: (received, total) {
            if (total != -1) {
              setState(() => downloadProgress = received / total);
            }
          },
          options: Options(
            receiveTimeout: Duration(minutes: 5),
            sendTimeout: Duration(minutes: 5),
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File saved successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => isDownloading = false);
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

      if (await File(localPath).exists()) {
        if (extension == 'pdf') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PdfViewerScreen(filePath: localPath,filename: fileName,),
            ),
          );
        } else {
          await OpenFilex.open(localPath);
        }
      } else {
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
    }

    return StatefulBuilder(
      builder: (context, setState) {
        return Card(
          margin: EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: borderColor,
              width: 1.5,
            ),
          ),
          child: InkWell(
            onTap: isMCQs ? handleView : null,
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge in top right corner
                      Align(
                        alignment: Alignment.topRight,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: borderColor,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            displayType.toUpperCase(),
                            style: AppTheme.captionStyle.copyWith(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            _getIconForType(type),
                            color: AppTheme.iconColor,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              title,
                              style: AppTheme.subHeadingStyle.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (isDownloading)
                            SizedBox(
                              width: 100,
                              child: LinearProgressIndicator(
                                value: downloadProgress,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                              ),
                            )
                          else if (hasFile || isMCQs)
                            IconButton(
                              icon: Icon(Icons.visibility),
                              onPressed: handleView,
                            ),
                          if (hasFile && !isMCQs && !isDownloading)
                            IconButton(
                              icon: Icon(Icons.download),
                              onPressed: handleDownload,
                            ),
                        ],
                      ),
                      if (type == 'notes' && item['topics'] is List)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Divider(color: AppTheme.dividerColor),
                              ...(item['topics'] as List).whereType<Map>().map((topic) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    children: [
                                      Icon(Icons.circle, size: 8, color: AppTheme.secondaryTextColor),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          topic['topic_name']?.toString() ?? 'Untitled topic',
                                          style: AppTheme.bodyStyle,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      if (!hasFile && !isMCQs)
                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'No file available',
                              style: AppTheme.captionStyle.copyWith(color: Colors.grey),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  IconData _getIconForType(String type) {
    switch (type) {
      case 'notes':
        return Icons.notes;
      case 'assignment':
        return Icons.assignment;
      case 'quiz':
        return Icons.quiz;
      default:
        return Icons.help_outline;
    }
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
                  separatorBuilder: (context, index) => Divider(color: AppTheme.dividerColor),
                  itemBuilder: (context, index) {
                    final question = questions[index];
                    if (question is! Map) {
                      return ListTile(
                        title: Text('Invalid question format', style: AppTheme.bodyStyle),
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
          Expanded(child: Text(option?.toString() ?? 'N/A', style: AppTheme.bodyStyle)),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final instructor =Provider.of<InstructorProvider>(context, listen: false).instructor;
    final currentSession=instructor!.session??'NO Current Session';

    return Theme(
      data: AppTheme.themeData,
      child: Scaffold(
        appBar: AppBar(
          title: Center(child: Text('Course Content')),
          automaticallyImplyLeading: false,

        ),
        body: RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: fetchCourseContent,
          color: AppTheme.primaryColor,
          child: isLoading
              ? Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
              : courseData == null || courseData!.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: AppTheme.secondaryTextColor),
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
                  // Current Session Card
                  Card(
                    margin: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Session Value (Prominent)
                          Text(
                            currentSession,
                            style: AppTheme.headingStyle.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4),
                          // Current Session Label + Total Courses in a row
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

                  // Course Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedCourse,
                    items: getCourseDropdownItems(),
                    onChanged: (value) {
                      setState(() {
                        selectedCourse = value;
                        selectedWeek = null;
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

                  // Section Buttons
                  Text(
                    'Sections:',
                    style: AppTheme.subHeadingStyle,
                  ),
                  _buildSectionButtons(),
                  SizedBox(height: 16),

                  // Week Dropdown
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

                  // Course Content List
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
                        ...getCurrentWeekContent().map((content) => _buildContentItem(content,context)),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppTheme.primaryColor,
          onPressed: () {
            // Implement add course content functionality
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Add Course Content clicked'),
                backgroundColor: AppTheme.primaryColor,
              ),
            );
          },
          child: Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}