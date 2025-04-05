import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lmsv2/api/ApiConfig.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import '../../provider/instructor_provider.dart';
import '../../Theme/theme.dart';
import '../../alerts/custom_alerts.dart';
import '../course_content/add_course_content.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({Key? key}) : super(key: key);

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  late String? teacherId;
  Map<String, dynamic>? tasksData;
  bool isLoading = true;
  String? errorMessage;
  String? selectedCourse;
  String? selectedType = 'All';
  String? selectedWeek = 'All';
  String? selectedSection = 'All';
  final TextEditingController searchController = TextEditingController();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final instructor = Provider.of<InstructorProvider>(context, listen: false).instructor;
    teacherId = instructor?.id.toString();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.apiBaseUrl}Teachers/task/un-assigned?teacher_id=${int.parse(teacherId ?? '0')}'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          setState(() {
            tasksData = data['data'];
          });
        } else {
          throw Exception(data['message'] ?? 'Failed to load tasks');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Map<String, int> _getTaskTypeCounts() {
    final counts = <String, int>{};
    if (selectedCourse == null || tasksData == null || !tasksData!.containsKey(selectedCourse)) {
      return counts;
    }

    final courseData = tasksData![selectedCourse][0];
    final taskDetails = courseData['task_details'];

    taskDetails.forEach((week, tasks) {
      for (var task in tasks) {
        if (task['un_assigned_to'].isEmpty) continue;
        if (selectedWeek != 'All' && week != selectedWeek) continue;
        if (selectedSection != 'All' &&
            !task['un_assigned_to'].any((s) => s['teacher_offered_course_id'].toString() == selectedSection)) {
          continue;
        }
        counts[task['type']] = (counts[task['type']] ?? 0) + 1;
      }
    });

    return counts;
  }

  List<DropdownMenuItem<String>> _buildCourseDropdownItems() {
    if (tasksData == null || tasksData!.isEmpty) return [];

    return tasksData!.keys.map<DropdownMenuItem<String>>((courseId) {
      final course = tasksData![courseId][0];
      return DropdownMenuItem<String>(
        value: courseId,
        child: Text(
          '${course['course_name']} ${course['course_lab'] == 'Yes' ? '(Lab)' : ''}',
          style: AppTheme.bodyStyle,
        ),
      );
    }).toList();
  }

  List<DropdownMenuItem<String>> _buildTypeDropdownItems() {
    final items = <DropdownMenuItem<String>>[
      DropdownMenuItem(
        value: 'All',
        child: Text('All Types', style: AppTheme.bodyStyle),
      ),
    ];

    if (selectedCourse == null || tasksData == null || !tasksData!.containsKey(selectedCourse)) {
      return items;
    }

    final types = <String>{};
    final courseData = tasksData![selectedCourse][0];
    final taskDetails = courseData['task_details'];

    taskDetails.forEach((week, tasks) {
      for (var task in tasks) {
        types.add(task['type']);
      }
    });

    items.addAll(types.map<DropdownMenuItem<String>>((type) {
      return DropdownMenuItem<String>(
        value: type,
        child: Text(type, style: AppTheme.bodyStyle),
      );
    }));

    return items;
  }

  List<DropdownMenuItem<String>> _buildWeekDropdownItems() {
    final items = <DropdownMenuItem<String>>[
      DropdownMenuItem(
        value: 'All',
        child: Text('All Weeks', style: AppTheme.bodyStyle),
      ),
    ];

    if (selectedCourse == null || tasksData == null || !tasksData!.containsKey(selectedCourse)) {
      return items;
    }

    final courseData = tasksData![selectedCourse][0];
    final taskDetails = courseData['task_details'];
    final weeks = taskDetails.keys.toList();

    items.addAll(weeks.map<DropdownMenuItem<String>>((week) {
      return DropdownMenuItem<String>(
        value: week,
        child: Text('Week $week', style: AppTheme.bodyStyle),
      );
    }));

    return items;
  }

  List<DropdownMenuItem<String>> _buildSectionDropdownItems() {
    final items = <DropdownMenuItem<String>>[
      DropdownMenuItem(
        value: 'All',
        child: Text('All Sections', style: AppTheme.bodyStyle),
      ),
    ];

    if (selectedCourse == null || tasksData == null || !tasksData!.containsKey(selectedCourse)) {
      return items;
    }

    final courseData = tasksData![selectedCourse][0];
    final sections = courseData['sections'];

    items.addAll(sections.map<DropdownMenuItem<String>>((section) {
      return DropdownMenuItem<String>(
        value: section['teacher_offered_course_id'].toString(),
        child: Text(section['section_name'], style: AppTheme.bodyStyle),
      );
    }));

    return items;
  }

  List<Map<String, dynamic>> _getFilteredTasks() {
    if (selectedCourse == null || tasksData == null || !tasksData!.containsKey(selectedCourse)) {
      return [];
    }

    final courseData = tasksData![selectedCourse][0];
    final taskDetails = courseData['task_details'];
    final filteredTasks = <Map<String, dynamic>>[];

    taskDetails.forEach((week, tasks) {
      if (selectedWeek != 'All' && week != selectedWeek) return;

      for (var task in tasks) {
        if (selectedType != 'All' && task['type'] != selectedType) continue;
        if (searchController.text.isNotEmpty &&
            !task['title'].toString().toLowerCase().contains(searchController.text.toLowerCase())) {
          continue;
        }

        if (selectedSection != 'All' &&
            !task['un_assigned_to'].any((s) => s['teacher_offered_course_id'].toString() == selectedSection)) {
          continue;
        }

        if (task['un_assigned_to'].isNotEmpty) {
          filteredTasks.add(task);
        }
      }
    });

    return filteredTasks;
  }

  void _openFile(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      CustomAlert.error(context, 'Error', 'Could not open the file');
    }
  }

  void _showMCQs(List<dynamic> mcqs) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('MCQ Questions', style: AppTheme.subHeadingStyle),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: mcqs.length,
            itemBuilder: (context, index) {
              final mcq = mcqs[index];
              return Card(
                margin: EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Q${index + 1}: ${mcq['Question']}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text('Points: ${mcq['Points']}'),
                      SizedBox(height: 8),
                      Text('1. ${mcq['Option 1']}'),
                      Text('2. ${mcq['Option 2']}'),
                      Text('3. ${mcq['Option 3']}'),
                      Text('4. ${mcq['Option 4']}'),
                      SizedBox(height: 8),
                      Text(
                        'Correct Answer: ${mcq['Answer']}',
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: AppTheme.primaryColor)),
          ),
        ],
      ),
    );
  }

  Future<void> _showAssignTaskDialog(Map<String, dynamic> task) async {
    final sections = task['un_assigned_to'] as List;
    final selectedSections = <String>[];
    final pointsController = TextEditingController();
    final startDateController = TextEditingController();
    final endDateController = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(20, 16, 12, 20),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Assign Task',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close, size: 20),
                              color: Colors.white.withOpacity(0.9),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Task Card
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    task['title'],
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textColor,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _getTypeColor(task['type']).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color: _getTypeColor(task['type']).withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Text(
                                    task['type'],
                                    style: TextStyle(
                                      color: _getTypeColor(task['type']),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.calendar_today, size: 18, color: AppTheme.iconColor),
                                SizedBox(width: 8),
                                Text(
                                  'Week ${task['week']}',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: AppTheme.secondaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Sections Selection
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Sections to Assign',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textColor,
                          ),
                        ),
                        SizedBox(height: 10),
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.primaryColor.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: sections.map((section) {
                              return FilterChip(
                                label: Text(
                                  section['section_name'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: selectedSections.contains(section['teacher_offered_course_id'].toString())
                                        ? Colors.white
                                        : AppTheme.textColor,
                                  ),
                                ),
                                selected: selectedSections.contains(section['teacher_offered_course_id'].toString()),
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      selectedSections.add(section['teacher_offered_course_id'].toString());
                                    } else {
                                      selectedSections.remove(section['teacher_offered_course_id'].toString());
                                    }
                                  });
                                },
                                selectedColor: AppTheme.primaryColor,
                                backgroundColor: Colors.grey[100],
                                shape: StadiumBorder(
                                  side: BorderSide(
                                    color: selectedSections.contains(section['teacher_offered_course_id'].toString())
                                        ? AppTheme.primaryColor
                                        : Colors.grey[300]!,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Points Field
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Task Points',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textColor,
                          ),
                        ),
                        SizedBox(height: 8),
                        TextField(
                          controller: pointsController,
                          decoration: InputDecoration(
                            hintText: 'Enter points for this task',
                            prefixIcon: Icon(Icons.star, color: AppTheme.primaryColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppTheme.primaryColor),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  ),

                  // Date Time Pickers
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Task Timeline',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textColor,
                          ),
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Start Date & Time',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.secondaryTextColor,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  InkWell(
                                    onTap: () async {
                                      final date = await showDatePicker(
                                        context: context,
                                        initialDate: DateTime.now(),
                                        firstDate: DateTime.now(),
                                        lastDate: DateTime.now().add(Duration(days: 365)),
                                        builder: (context, child) {
                                          return Theme(
                                            data: ThemeData.light().copyWith(
                                              colorScheme: ColorScheme.light(
                                                primary: AppTheme.primaryColor,
                                              ),
                                              dialogBackgroundColor: Colors.white,
                                            ),
                                            child: child!,
                                          );
                                        },
                                      );
                                      if (date != null) {
                                        final time = await showTimePicker(
                                          context: context,
                                          initialTime: TimeOfDay.now(),
                                          builder: (context, child) {
                                            return Theme(
                                              data: ThemeData.light().copyWith(
                                                colorScheme: ColorScheme.light(
                                                  primary: AppTheme.primaryColor,
                                                ),
                                                dialogBackgroundColor: Colors.white,
                                              ),
                                              child: child!,
                                            );
                                          },
                                        );
                                        if (time != null) {
                                          setState(() {
                                            startDate = DateTime(
                                              date.year, date.month, date.day,
                                              time.hour, time.minute,
                                            );
                                            startDateController.text = DateFormat('MMM dd, yyyy - hh:mm a').format(startDate!);
                                          });
                                        }
                                      }
                                    },
                                    child: AbsorbPointer(
                                      child: TextField(
                                        controller: startDateController,
                                        decoration: InputDecoration(
                                          hintText: 'Select start date and time',
                                          prefixIcon: Icon(Icons.calendar_today, size: 20, color: AppTheme.primaryColor),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: AppTheme.primaryColor),
                                          ),
                                          filled: true,
                                          fillColor: Colors.white,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'End Date & Time',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.secondaryTextColor,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  InkWell(
                                    onTap: () async {
                                      final date = await showDatePicker(
                                        context: context,
                                        initialDate: startDate ?? DateTime.now(),
                                        firstDate: startDate ?? DateTime.now(),
                                        lastDate: DateTime.now().add(Duration(days: 365)),
                                        builder: (context, child) {
                                          return Theme(
                                            data: ThemeData.light().copyWith(
                                              colorScheme: ColorScheme.light(
                                                primary: AppTheme.primaryColor,
                                              ),
                                              dialogBackgroundColor: Colors.white,
                                            ),
                                            child: child!,
                                          );
                                        },
                                      );
                                      if (date != null) {
                                        final time = await showTimePicker(
                                          context: context,
                                          initialTime: TimeOfDay.now(),
                                          builder: (context, child) {
                                            return Theme(
                                              data: ThemeData.light().copyWith(
                                                colorScheme: ColorScheme.light(
                                                  primary: AppTheme.primaryColor,
                                                ),
                                                dialogBackgroundColor: Colors.white,
                                              ),
                                              child: child!,
                                            );
                                          },
                                        );
                                        if (time != null) {
                                          setState(() {
                                            endDate = DateTime(
                                              date.year, date.month, date.day,
                                              time.hour, time.minute,
                                            );
                                            endDateController.text = DateFormat('MMM dd, yyyy - hh:mm a').format(endDate!);
                                          });
                                        }
                                      }
                                    },
                                    child: AbsorbPointer(
                                      child: TextField(
                                        controller: endDateController,
                                        decoration: InputDecoration(
                                          hintText: 'Select end date and time',
                                          prefixIcon: Icon(Icons.calendar_today, size: 20, color: AppTheme.primaryColor),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: AppTheme.primaryColor),
                                          ),
                                          filled: true,
                                          fillColor: Colors.white,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Submit Button
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: Size(double.infinity, 50),
                        elevation: 3,
                      ),
                      onPressed: () async {
                        if (selectedSections.isEmpty) {
                          CustomAlert.error(context, 'Error', 'Please select at least one section');
                          return;
                        }
                        if (pointsController.text.isEmpty) {
                          CustomAlert.error(context, 'Error', 'Please enter points');
                          return;
                        }
                        if (startDate == null || endDate == null) {
                          CustomAlert.error(context, 'Error', 'Please select both start and end dates');
                          return;
                        }
                        if (endDate!.isBefore(startDate!)) {
                          CustomAlert.error(context, 'Error', 'End date must be after start date');
                          return;
                        }

                        try {
                          CustomAlert.loading(context, 'Assigning Task', 'Processing ${selectedSections.length} sections...');

                          final results = await _assignTaskToSections(
                            task: task,
                            sectionIds: selectedSections,
                            points: pointsController.text,
                            startDate: startDate!,
                            endDate: endDate!,
                          );

                          Navigator.pop(context); // Close loading
                          Navigator.pop(context); // Close dialog

                          _showAssignmentResults(
                            context: context,
                            results: results,
                            taskTitle: task['title'],
                          );

                          _fetchTasks(); // Refresh data
                        } catch (e) {
                          Navigator.pop(context); // Close loading
                          CustomAlert.error(context, 'Error', 'Failed to assign task: ${e.toString()}');
                        }
                      },
                      child: Text(
                        'Assign to ${selectedSections.length} Section(s)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _assignTaskToSections({
    required Map<String, dynamic> task,
    required List<String> sectionIds,
    required String points,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final results = <Map<String, dynamic>>[];

    for (final sectionId in sectionIds) {
      try {
        final response = await http.post(
          Uri.parse('${ApiConfig.apiBaseUrl}Teachers/create/task'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: json.encode({
            'coursecontent_id': task['id'],
            'points': points,
            'start_date': DateFormat('yyyy-MM-dd HH:mm:ss').format(startDate),
            'due_date': DateFormat('yyyy-MM-dd HH:mm:ss').format(endDate),
            'teacher_offered_course_id': sectionId,
          }),
        );

        final responseData = json.decode(response.body);
        final sectionName = task['un_assigned_to'].firstWhere(
              (s) => s['teacher_offered_course_id'].toString() == sectionId,
        )['section_name'];

        // Handle API response based on your Laravel endpoint
        if (response.statusCode == 200) {
          if (responseData['status'] == 'success') {
            // Task created or updated successfully
            results.add({
              'sectionId': sectionId,
              'sectionName': sectionName,
              'success': true,
              'message': responseData['data']['status'] ?? 'Task processed successfully',
            });
          } else {
            // API returned error
            results.add({
              'sectionId': sectionId,
              'sectionName': sectionName,
              'success': false,
              'message': responseData['message'] ?? 'Failed to assign task',
            });
          }
        } else if (response.statusCode == 422) {
          // Validation error
          final errorMessage = responseData['error'] ?? 'Validation failed';
          results.add({
            'sectionId': sectionId,
            'sectionName': sectionName,
            'success': false,
            'message': errorMessage,
          });
        } else {
          // Other server errors
          results.add({
            'sectionId': sectionId,
            'sectionName': sectionName,
            'success': false,
            'message': responseData['message'] ??
                'Server error: ${response.statusCode}',
          });
        }
      } catch (e) {
        final sectionName = task['un_assigned_to'].firstWhere(
              (s) => s['teacher_offered_course_id'].toString() == sectionId,
        )['section_name'];

        results.add({
          'sectionId': sectionId,
          'sectionName': sectionName,
          'success': false,
          'message': e.toString(),
        });
      }
    }

    return results;
  }

  void _showAssignmentResults({
    required BuildContext context,
    required List<Map<String, dynamic>> results,
    required String taskTitle,
  }) {
    final successful = results.where((r) => r['success'] == true).length;
    final failed = results.length - successful;

    // Check if all assignments were updates of existing tasks
    final allUpdates = results.every((r) =>
    r['success'] == true &&
        r['message'].toString().contains('Updated Successfully'));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(allUpdates ? 'Tasks Updated' : 'Assignment Results'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Task: $taskTitle',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              if (allUpdates)
                Text(
                  '✅ All selected sections were already assigned this task and have been updated',
                  style: TextStyle(color: Colors.green),
                )
              else ...[
                Text(
                  '${successful + failed} sections processed:',
                  style: TextStyle(color: Colors.grey),
                ),
                SizedBox(height: 4),
                Text('✅ $successful successful'),
                SizedBox(height: 4),
                Text('❌ $failed failed'),
              ],
              SizedBox(height: 16),
              if (failed > 0 && !allUpdates) ...[
                Text(
                  'Failed assignments:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                ...results.where((r) => !r['success']).map((result) => Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Section ${result['sectionName']}',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        result['message'],
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                  ),
                )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }


  Color _getTypeColor(String type) {
    switch (type) {
      case 'Quiz':
        return Colors.blue;
      case 'Assignment':
        return Colors.green;
      case 'Quiz ( MCQS )':
        return Colors.purple;
      case 'LabTask':
        return Colors.orange;
      default:
        return AppTheme.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskTypeCounts = _getTaskTypeCounts();

    return Theme(
      data: AppTheme.themeData,
      child: Scaffold(
        backgroundColor: Color(0xFFF0F3FF),
        appBar: AppBar(
          title: Text(
            'Unassigned Tasks',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF4E6AEB), // Same blue color
              fontWeight: FontWeight.w600, // Added semi-bold for consistency
            ),
          ),
          backgroundColor: Color(0xFFF0F3FF), // Light blue background
          elevation: 0,
          automaticallyImplyLeading: false,
          iconTheme: IconThemeData(color: Color(0xFF4E6AEB)), // Blue icons
          actions: [
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Color(0xFF4E6AEB)),
              onSelected: (String value) {
                switch (value) {
                  case 'create':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateCourseContentScreen(
                            teacherId: teacherId.toString()
                        ),
                      ),
                    );
                    break;
                  case 'deadlines':
                  // Navigate to view task deadlines
                    break;
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<String>(
                  value: 'create',
                  child: Row(
                    children: [
                      Icon(Icons.add_task, color: Color(0xFF4E6AEB)), // Task-specific icon
                      SizedBox(width: 12),
                      Text(
                        'Create New Content',
                        style: TextStyle(color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'deadlines',
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: Color(0xFF4E6AEB)), // Calendar icon
                      SizedBox(width: 12),
                      Text(
                        'View Task Deadlines',
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
          onRefresh: _fetchTasks,
          color: AppTheme.primaryColor,
          child: Builder(
            builder: (context) {
              if (isLoading) {
                return Center(child: CircularProgressIndicator());
              }
              if (errorMessage != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, color: Colors.red, size: 48),
                      SizedBox(height: 16),
                      Text(errorMessage!),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchTasks,
                        child: Text('Retry'),
                        style: AppTheme.primaryButtonStyle,
                      ),
                    ],
                  ),
                );
              }
              if (tasksData == null || tasksData!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment, color: Colors.grey, size: 48),
                      SizedBox(height: 16),
                      Text('No tasks available'),
                    ],
                  ),
                );
              }
              return SingleChildScrollView(
                child: Column(
                  children: [
                    // Search Field
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by task title...',
                          prefixIcon: Icon(Icons.search, color: AppTheme.primaryColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.primaryColor),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        onChanged: (value) => setState(() {}),
                      ),
                    ),

                    // Course Dropdown
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: DropdownButtonFormField<String>(
                        value: selectedCourse,
                        items: _buildCourseDropdownItems(),
                        onChanged: (value) {
                          setState(() {
                            selectedCourse = value;
                            selectedType = 'All';
                            selectedWeek = 'All';
                            selectedSection = 'All';
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Select Course',
                          labelStyle: AppTheme.bodyStyle,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.primaryColor),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        style: AppTheme.bodyStyle,
                        icon: Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor),
                      ),
                    ),

                    // Type Dropdown (only for lab courses)
                    if (selectedCourse != null &&
                        tasksData![selectedCourse][0]['course_lab'] == 'Yes')
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: DropdownButtonFormField<String>(
                          value: selectedType,
                          items: _buildTypeDropdownItems(),
                          onChanged: (value) {
                            setState(() {
                              selectedType = value;
                            });
                          },
                          decoration: InputDecoration(
                            labelText: 'Filter by Type',
                            labelStyle: AppTheme.bodyStyle,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppTheme.primaryColor),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          style: AppTheme.bodyStyle,
                          icon: Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor),
                        ),
                      ),

                    // Week Dropdown
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: DropdownButtonFormField<String>(
                        value: selectedWeek,
                        items: _buildWeekDropdownItems(),
                        onChanged: (value) {
                          setState(() {
                            selectedWeek = value;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Filter by Week',
                          labelStyle: AppTheme.bodyStyle,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.primaryColor),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        style: AppTheme.bodyStyle,
                        icon: Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor),
                      ),
                    ),

                    // Section Dropdown
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: DropdownButtonFormField<String>(
                        value: selectedSection,
                        items: _buildSectionDropdownItems(),
                        onChanged: (value) {
                          setState(() {
                            selectedSection = value;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Filter by Section',
                          labelStyle: AppTheme.bodyStyle,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.primaryColor),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        style: AppTheme.bodyStyle,
                        icon: Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor),
                      ),
                    ),

                    // Task Type Counts
                    if (taskTypeCounts.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.primaryColor.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Task Summary',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textColor,
                                ),
                              ),
                              SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: taskTypeCounts.entries.map((entry) {
                                  return Chip(
                                    backgroundColor: _getTypeColor(entry.key).withOpacity(0.15),
                                    label: Text(
                                      '${entry.key}: ${entry.value}',
                                      style: TextStyle(
                                        color: _getTypeColor(entry.key),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    shape: StadiumBorder(
                                      side: BorderSide(
                                        color: _getTypeColor(entry.key).withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Task List
                    ..._getFilteredTasks().map((task) {
                      return Padding(
                        padding: EdgeInsets.all(16),
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.2), width: 1),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        task['title'],
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textColor,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _getTypeColor(task['type']).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(15),
                                        border: Border.all(
                                          color: _getTypeColor(task['type']).withOpacity(0.3),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Text(
                                        task['type'],
                                        style: TextStyle(
                                          color: _getTypeColor(task['type']),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: 18, color: AppTheme.iconColor),
                                    SizedBox(width: 8),
                                    Text(
                                      'Week ${task['week']}',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: AppTheme.secondaryTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.group, size: 18, color: AppTheme.iconColor),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Sections without this task:',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: AppTheme.secondaryTextColor,
                                            ),
                                          ),
                                          SizedBox(height: 6),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 6,
                                            children: task['un_assigned_to'].map<Widget>((section) {
                                              return Chip(
                                                label: Text(
                                                  section['section_name'],
                                                  style: TextStyle(fontSize: 13),
                                                ),
                                                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                                shape: StadiumBorder(
                                                  side: BorderSide(
                                                    color: AppTheme.primaryColor.withOpacity(0.3),
                                                    width: 1,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (task['content'] is String && task['content'].isNotEmpty)
                                      ElevatedButton(
                                        onPressed: () => _openFile(task['content']),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.file_open, size: 18),
                                            SizedBox(width: 6),
                                            Text('View File'),
                                          ],
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue[50],
                                          foregroundColor: Colors.blue[800],
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        ),
                                      ),
                                    if (task['content'] is List && task['content'].isNotEmpty)
                                      ElevatedButton(
                                        onPressed: () => _showMCQs(task['content']),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.quiz, size: 18),
                                            SizedBox(width: 6),
                                            Text('View MCQs'),
                                          ],
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.purple[50],
                                          foregroundColor: Colors.purple[800],
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        ),
                                      ),
                                    ElevatedButton(
                                      onPressed: () => _showAssignTaskDialog(task),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.assignment_add, size: 18),
                                          SizedBox(width: 6),
                                          Text('Assign'),
                                        ],
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryColor,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),

                    if (_getFilteredTasks().isEmpty)
                      Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.search_off, size: 48, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'No tasks match your current filters',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}