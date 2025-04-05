import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lmsv2/api/ApiConfig.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../Theme/theme.dart';
import '../../provider/instructor_provider.dart';

class SectionDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> section;
  final String teacherId;

  const SectionDetailsScreen({
    Key? key,
    required this.section,
    required this.teacherId,
  }) : super(key: key);

  @override
  _SectionDetailsScreenState createState() => _SectionDetailsScreenState();
}

class _SectionDetailsScreenState extends State<SectionDetailsScreen> {
  Map<String, dynamic>? courseContent;
  bool isLoading = true;
  String? selectedWeek = 'All';
  String? errorMessage;
  int currentWeek = 0;
  int totalWeek = 0;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
  GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _fetchSectionContent();
    final instructor =
        Provider.of<InstructorProvider>(context, listen: false).instructor;
    currentWeek = instructor?.week ?? 0;
    selectedWeek = currentWeek > 0 ? currentWeek.toString() : 'All';
  }

  Future<void> _fetchSectionContent() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      selectedWeek = 'All';
    });

    try {
      final teacherOfferedCourseId =
      widget.section['teacher_offered_course_id']?.toString();
      if (teacherOfferedCourseId == null || teacherOfferedCourseId.isEmpty) {
        throw Exception('Invalid course ID');
      }

      final response = await http.get(
        Uri.parse(
            '${ApiConfig.apiBaseUrl}Teachers/topic?teacher_offered_course_id=$teacherOfferedCourseId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is! Map) {
          throw Exception('Invalid API response format');
        }

        if (data['Course_Content'] != null) {
          if (data['Course_Content'] is Map) {
            setState(() {
              courseContent = Map<String, dynamic>.from(data['Course_Content']);
              totalWeek = courseContent!.length;
              // Reset selected week to current week if it exists in the new data
              if (currentWeek > 0 && courseContent!.containsKey(currentWeek.toString())) {
                selectedWeek = currentWeek.toString();
              }
            });
          } else if (data['Course_Content'] is String) {
            try {
              final parsedContent = json.decode(data['Course_Content']);
              if (parsedContent is Map) {
                setState(() {
                  courseContent = Map<String, dynamic>.from(parsedContent);
                  totalWeek = courseContent!.length;
                  if (currentWeek > 0 && courseContent!.containsKey(currentWeek.toString())) {
                    selectedWeek = currentWeek.toString();
                  }
                });
              } else {
                throw Exception('Invalid Course_Content format');
              }
            } catch (e) {
              throw Exception('Failed to parse Course_Content: $e');
            }
          } else {
            throw Exception('Unexpected Course_Content type');
          }
        } else {
          setState(() {
            courseContent = {};
            totalWeek = 0;
          });
        }
      } else {
        throw Exception(
            'Server responded with status code: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = _getErrorMessage(e);
        selectedWeek = 'All';
      });
      debugPrint('Error fetching section content: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is String) return error;
    if (error is Map) return error['message'] ?? 'Unknown error occurred';
    return error.toString();
  }

  Future<void> _updateTopicStatus(
      String courseContentId, String topicId, bool newStatus) async {
    try {
      final teacherOfferedCourseId =
      widget.section['teacher_offered_course_id']?.toString();
      if (teacherOfferedCourseId == null || teacherOfferedCourseId.isEmpty) {
        throw Exception('Invalid course ID');
      }

      final response = await http
          .post(
        Uri.parse('${ApiConfig.apiBaseUrl}Teachers/update-course-content'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "coursecontent_id": courseContentId,
          "topic_id": topicId,
          "teacher_offered_courses_id": teacherOfferedCourseId,
          "Status": newStatus,
        }),
      )
          .timeout(Duration(seconds: 30));

      final responseData = json.decode(response.body);
      if (response.statusCode == 200) {
        if (responseData['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message'] ?? 'Status updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          await _fetchSectionContent();
        } else {
          throw Exception(responseData['message'] ?? 'Failed to update status');
        }
      } else {
        throw Exception(
            'Server error: ${response.statusCode} - ${responseData['message']}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating status: ${_getErrorMessage(e)}'),
          backgroundColor: Colors.red,
        ),
      );
      debugPrint('Error updating topic status: $e');
    }
  }

  List<DropdownMenuItem<String>> _getWeekDropdownItems() {
    final items = <DropdownMenuItem<String>>[
      DropdownMenuItem<String>(
        value: 'All',
        child: Text('All Weeks', style: AppTheme.bodyStyle),
      ),
    ];

    if (courseContent == null || courseContent!.isEmpty) return items;

    try {
      // Convert keys to integers, sort them, then convert back to strings
      final weekNumbers = courseContent!.keys
          .whereType<String>()
          .map((week) => int.tryParse(week) ?? 0)
          .where((week) => week > 0)
          .toList()
        ..sort();

      for (var week in weekNumbers) {
        items.add(
          DropdownMenuItem<String>(
            value: week.toString(),
            child: Text('Week $week', style: AppTheme.bodyStyle),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error generating week dropdown: $e');
    }

    // Ensure current week exists in dropdown if we have data
    if (currentWeek > 0 && !items.any((item) => item.value == currentWeek.toString())) {
      items.add(
        DropdownMenuItem<String>(
          value: currentWeek.toString(),
          child: Text('Week $currentWeek', style: AppTheme.bodyStyle),
        ),
      );
    }

    return items;
  }

  List<dynamic> _getFilteredContent() {
    if (courseContent == null || courseContent!.isEmpty) return [];

    try {
      if (selectedWeek == 'All') {
        return courseContent!.values
            .whereType<List>()
            .expand((weekContent) => weekContent.whereType<Map>())
            .toList();
      }

      final weekContent = courseContent![selectedWeek];
      if (weekContent is List) {
        return weekContent.whereType<Map>().toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error filtering content: $e');
      return [];
    }
  }

  Map<String, dynamic> _calculateProgress() {
    try {
      final filteredContent = _getFilteredContent();
      int totalTopics = 0;
      int coveredTopics = 0;

      for (var content in filteredContent) {
        if (content is! Map) continue;

        final topics = content['topics'];
        if (topics is! List) continue;

        totalTopics += topics.length;
        coveredTopics += topics.where((t) {
          if (t is! Map) return false;
          return t['status'] == 'Covered';
        }).length;
      }

      final percentage = totalTopics > 0 ? (coveredTopics / totalTopics * 100) : 0;

      return {
        'total': totalTopics,
        'covered': coveredTopics,
        'remaining': totalTopics - coveredTopics,
        'percentage': percentage.round(),
      };
    } catch (e) {
      debugPrint('Error calculating progress: $e');
      return {
        'total': 0,
        'covered': 0,
        'remaining': 0,
        'percentage': 0,
      };
    }
  }

  Widget _buildProgressIndicator() {
    final progress = _calculateProgress();
    final percentage = progress['percentage'] as int;
    final covered = progress['covered'] as int;
    final remaining = progress['remaining'] as int;
    final total = progress['total'] as int;

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Course Progress',
              style: AppTheme.subHeadingStyle.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$percentage% Completed',
                        style: AppTheme.headingStyle.copyWith(
                          fontSize: 24,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '$covered of $total topics covered',
                        style: AppTheme.bodyStyle.copyWith(
                          color: AppTheme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: CircularProgressIndicator(
                          value: percentage / 100,
                          strokeWidth: 10,
                          backgroundColor: Colors.orange.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryColor),
                        ),
                      ),
                      Text(
                        '$percentage%',
                        style: AppTheme.subHeadingStyle.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                _buildProgressStat('Covered', covered, Colors.green),
                SizedBox(width: 16),
                _buildProgressStat('Remaining', remaining, Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressStat(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: AppTheme.subHeadingStyle.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: AppTheme.captionStyle.copyWith(
                color: AppTheme.secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentCard(dynamic content) {
    if (content is! Map) {
      return Card(
        child: ListTile(
          leading: Icon(Icons.error, color: Colors.red),
          title: Text('Invalid content format', style: AppTheme.bodyStyle),
        ),
      );
    }

    final week = content['week']?.toString() ?? 'N/A';
    final title = content['title']?.toString() ?? 'Untitled';
    final topics = content['topics'];

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTheme.subHeadingStyle.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Week $week',
                    style: AppTheme.captionStyle.copyWith(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            if (topics == null || (topics is List && topics.isEmpty))
              Text(
                'No topics available',
                style: AppTheme.captionStyle,
              ),
            if (topics is List)
              ...topics.map((topic) => _buildTopicTile(topic, content)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicTile(dynamic topic, dynamic content) {
    if (topic is! Map) {
      return ListTile(
        leading: Icon(Icons.error, color: Colors.red),
        title: Text('Invalid topic format', style: AppTheme.bodyStyle),
      );
    }

    final isCovered = topic['status']?.toString() == 'Covered';
    final topicName = topic['topic_name']?.toString() ?? 'Untitled Topic';
    final topicId = topic['topic_id']?.toString();
    final courseContentId = content['course_content_id']?.toString();

    if (topicId == null || courseContentId == null) {
      return ListTile(
        leading: Icon(Icons.error, color: Colors.red),
        title: Text('Missing required topic IDs', style: AppTheme.bodyStyle),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              topicName,
              style: AppTheme.bodyStyle,
            ),
          ),
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isCovered
                  ? Colors.green.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCovered ? Colors.green : Colors.orange,
                width: 1,
              ),
            ),
            child: Text(
              isCovered ? 'Covered' : 'Not Covered',
              style: AppTheme.captionStyle.copyWith(
                color: isCovered ? Colors.green : Colors.orange,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              isCovered ? Icons.toggle_on : Icons.toggle_off,
              color: isCovered ? Colors.green : Colors.orange,
              size: 50,
            ),
            onPressed: () {
              _updateTopicStatus(
                courseContentId,
                topicId,
                !isCovered,
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.themeData,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.section['section_name']?.toString() ?? 'Section Details'),
        ),
        body: RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: _fetchSectionContent,
          color: AppTheme.primaryColor,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text(
              errorMessage!,
              style: AppTheme.subHeadingStyle,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              style: AppTheme.primaryButtonStyle,
              onPressed: _fetchSectionContent,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (courseContent == null || courseContent!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 48, color: AppTheme.secondaryTextColor),
            SizedBox(height: 16),
            Text(
              'No content available for this section',
              style: AppTheme.subHeadingStyle,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              style: AppTheme.primaryButtonStyle,
              onPressed: _fetchSectionContent,
              child: Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Section Information',
                    style: AppTheme.subHeadingStyle.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  _buildInfoRow(
                      'Course:', widget.section['course_name']?.toString()),
                  _buildInfoRow(
                      'Section:', widget.section['section_name']?.toString()),
                  _buildInfoRow('Current Week ',
                      '${currentWeek.toString()}'),
                  _buildInfoRow('Total Week in Session : ',
                      '${totalWeek.toString()}'),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // Progress Indicator
          _buildProgressIndicator(),

          // Week Dropdown
          DropdownButtonFormField<String>(
            value: _getWeekDropdownItems().any((item) => item.value == selectedWeek)
                ? selectedWeek
                : 'All',
            items: _getWeekDropdownItems(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  selectedWeek = value;
                });
              }
            },
            decoration: InputDecoration(
              labelText: 'Select Week',
              border: OutlineInputBorder(),
              filled: true,
            ),
            isExpanded: true,
            style: AppTheme.bodyStyle,
          ),
          SizedBox(height: 16),

          // Content List
          ..._getFilteredContent().map((content) => _buildContentCard(content)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTheme.bodyStyle.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: AppTheme.bodyStyle,
            ),
          ),
        ],
      ),
    );
  }
}