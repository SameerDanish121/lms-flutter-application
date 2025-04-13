import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lmsv2/JuniorLecturer/Junior_Home.dart';
import 'package:lmsv2/alerts/custom_alerts.dart';
import 'dart:convert';

import '../../Theme/theme.dart';
import '../../api/ApiConfig.dart';
import '../../teacher/Home/today_classes.dart';

class JuniorAttendanceUpdateScreen extends StatefulWidget {
  final ClassModel classRecord;
  const JuniorAttendanceUpdateScreen({super.key, required this.classRecord});
  @override
  State<JuniorAttendanceUpdateScreen> createState() => _JuniorAttendanceUpdateScreenState();
}
class _JuniorAttendanceUpdateScreenState extends State<JuniorAttendanceUpdateScreen> {
  List<Student> students = [];
  int presentCount = 0;
  int absentCount = 0;
  bool isLoading = true;
  bool isSubmitting = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAttendanceList();
  }

  Future<void> _fetchAttendanceList() async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.apiBaseUrl}Teachers/re-take'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "teacher_offered_course_id": widget.classRecord.teacherOfferedCourseId,
          "venue_name": widget.classRecord.venue.toLowerCase(),
          "fixed_date":widget.classRecord.fixedDate,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          students = (data['students'] as List)
              .map((e) => Student.fromJson(e))
              .toList();
          presentCount=students.where((s)=>s.attendanceStatus=='P').length;
          absentCount=students.where((n)=>n.attendanceStatus=='A').length;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load attendance list. Status: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      CustomAlert.error(context,'Failed To Load Student List', 'Students Are Not Enrolled in this Section !');
      await Future.delayed(Duration(seconds: 5));
      Navigator.pop(context);
    }
  }

  void _updateAttendanceStatus(int index, String status) {
    setState(() {
      if (students[index].attendanceStatus != status) {
        if (status == 'P') {
          presentCount++;
          if (students[index].attendanceStatus == 'A') absentCount--;
        } else if (status == 'A') {
          absentCount++;
          if (students[index].attendanceStatus == 'P') presentCount--;
        } else {
          if (students[index].attendanceStatus == 'P') presentCount--;
          if (students[index].attendanceStatus == 'A') absentCount--;
        }
        students[index].attendanceStatus = status;
      }
    });
  }

  Future<void> _submitAttendance() async {

    final unmarkedStudents = students.where((s) => s.attendanceStatus.isEmpty).toList();
    if (unmarkedStudents.isNotEmpty) {
      final result = await CustomAlert.confirm(
          context, "You missed attendance for ${unmarkedStudents.length} student(s) ! . \n Do You Want to CONTINUE ( All Remaining Student Will be Marked Absent !");
      if (result != true) return;
      for (var student in students) {
        if (student.attendanceStatus.isEmpty) {
          student.attendanceStatus = 'A';
        }
      }

    }
    final shouldSubmit = await CustomAlert.confirm(
        context,'Are you sure you want to upload attendance ?');
    if (shouldSubmit != true) return;

    setState(() => isSubmitting = true);

    try {
      CustomAlert.loading(context, 'Uploading Attendance Sheet !', 'Please Wait For the Data to be Submitted');
      final attendanceRecords = students
          .where((student) => student.attendanceStatus.isNotEmpty)
          .map((student) => {
        'student_id': student.studentId,
        'teacher_offered_course_id': widget.classRecord.teacherOfferedCourseId,
        'status': student.attendanceStatus.toLowerCase(),
        'date_time': widget.classRecord.fixedDate,
        'isLab': true,
        'venue_id': widget.classRecord.venueId,
      })
          .toList();

      final response = await http.post(
        Uri.parse('${ApiConfig.apiBaseUrl}Teachers/attendance/mark-bulk'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'attendance_records': attendanceRecords}),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context);
        CustomAlert.success(context, 'Attendance Submitted Successfully !');
        await Future.delayed(Duration(seconds: 3));
        Navigator.pushReplacement( context,
            MaterialPageRoute(builder: (context) =>JuniorHome() ));
      } else {
        throw Exception('Server responded with status: ${response.statusCode}');
      }
    } catch (e) {
      Navigator.pop(context);
      CustomAlert.error(context,'Failed', 'Failed to submit attendance: $e');
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  Future<bool> _onWillPop() async {
    final shouldExit=await CustomAlert.confirm(
        context,'You have unsaved changes. Are you sure you want to exit?');

    // final shouldExit = await showDialog<bool>(
    //   context: context,
    //   builder: (context) => AlertDialog(
    //     title: const Text('Unsaved Changes'),
    //     content: const Text('You have unsaved changes. Are you sure you want to exit?'),
    //     actions: [
    //       TextButton(
    //         onPressed: () => Navigator.pop(context, false),
    //         child: const Text('CANCEL'),
    //       ),
    //       ElevatedButton(
    //         onPressed: () => Navigator.pop(context, true),
    //         style: ElevatedButton.styleFrom(
    //           backgroundColor: Colors.red,
    //         ),
    //         child: const Text('EXIT', style: TextStyle(color: Colors.white)),
    //       ),
    //     ],
    //   ),
    // );

    return shouldExit ?? false;
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  List<Student> get filteredStudents {
    if (_searchController.text.isEmpty) {
      return students;
    }
    final query = _searchController.text.toLowerCase();
    return students.where((student) {
      return student.name.toLowerCase().contains(query) ||
          student.regNo.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Mark Attendance',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          backgroundColor: AppTheme.primaryColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => _onWillPop().then((value) {
              if (value) Navigator.pop(context);
            }),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.format_list_numbered, color: Colors.white, size: 20),
              onPressed: () {},
              tooltip: 'Sequence Attendance List',
            ),
          ],
        ),
        backgroundColor: AppTheme.backgroundColor,
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            // Header Card
            Card(
              margin: const EdgeInsets.all(12),
              elevation: 1,
              color: AppTheme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: AppTheme.dividerColor),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.classRecord.coursename,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Section: ${widget.classRecord.section}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.secondaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${widget.classRecord.startTime} - ${widget.classRecord.endTime}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            widget.classRecord.venue,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatusIndicator('Total', students.length),
                        _buildStatusIndicator('Present', presentCount),
                        _buildStatusIndicator('Absent', absentCount),
                        _buildStatusIndicator('Seats', students.where((s) => s.seatNumber != null).length),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                height: 40,
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Find student by name or roll number...',
                    hintStyle: const TextStyle(fontSize: 12),
                    prefixIcon: const Icon(Icons.search, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppTheme.dividerColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppTheme.primaryColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Student List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: filteredStudents.length,
                itemBuilder: (context, index) {
                  final student = filteredStudents[index];
                  return _buildStudentCard(student, index);
                },
              ),
            ),
            // Submit Button
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                height: 42,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : _submitAttendance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    'Submit Attendance',
                    style: TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(String label, int count) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppTheme.secondaryTextColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStudentCard(Student student, int index) {
    final isLowAttendance = student.percentage < 75;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: 0,
      color: isLowAttendance
          ? Colors.orange[50]
          : AppTheme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isLowAttendance
              ? Colors.orange.withOpacity(0.5)
              : AppTheme.dividerColor,
          width: isLowAttendance ? 1.2 : 0.8,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            // Student Avatar
            CircleAvatar(
              radius: 20,
              backgroundColor: _getAvatarColor(student.name),
              backgroundImage: student.image != null ? NetworkImage(student.image!) : null,
              child: student.image == null
                  ? Text(
                student.name.isNotEmpty
                    ? student.name.split(' ').map((e) => e[0]).take(2).join()
                    : '?',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              )
                  : null,
            ),
            const SizedBox(width: 10),
            // Student Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                    ),
                  ),
                  Text(
                    student.regNo,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (student.seatNumber != null)
                        Row(
                          children: [
                            Icon(
                              Icons.chair,
                              size: 12,
                              color: AppTheme.secondaryTextColor,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'Seat ${student.seatNumber}',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.secondaryTextColor,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                        ),
                      Icon(
                        Icons.bar_chart,
                        size: 12,
                        color: isLowAttendance
                            ? Colors.orange
                            : AppTheme.secondaryTextColor,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${student.percentage.toStringAsFixed(2)}%',
                        style: TextStyle(
                          fontSize: 11,
                          color: isLowAttendance
                              ? Colors.orange
                              : AppTheme.secondaryTextColor,
                          fontWeight: isLowAttendance
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      if (isLowAttendance) ...[
                        const SizedBox(width: 2),
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 12,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'Low',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Attendance Status
            Row(
              children: [
                _buildStatusButton('P', student.attendanceStatus == 'P', () {
                  _updateAttendanceStatus(
                      students.indexOf(student), student.attendanceStatus == 'P' ? '' : 'P');
                }),
                const SizedBox(width: 6),
                _buildStatusButton('A', student.attendanceStatus == 'A', () {
                  _updateAttendanceStatus(
                      students.indexOf(student), student.attendanceStatus == 'A' ? '' : 'A');
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton(String label, bool isSelected, VoidCallback onPressed) {
    final color = label == 'P' ? Colors.green : Colors.red;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.3),
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Color _getAvatarColor(String name) {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
    ];
    final index = name.hashCode % colors.length;
    return colors[index];
  }
}
class Student {
  final int? seatNumber;
  final int studentId;
  final String name;
  final String regNo;
  final String? image;
  final double percentage;
  String attendanceStatus;

  Student({
    this.seatNumber,
    required this.studentId,
    required this.name,
    required this.regNo,
    this.image,
    required this.percentage,
    this.attendanceStatus = '',
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
        seatNumber: json['SeatNumber'],
        studentId: json['student_id'],
        name: json['name'],
        regNo: json['RegNo'],
        image: json['image'],
        percentage: (json['percentage'] as num).toDouble(),
        attendanceStatus:json['attedance_status'].toString().toUpperCase()
    );
  }
}