import 'dart:async';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:lmsv2/Student/Course/lesson_plan.dart';
import 'package:lmsv2/Student/Timetable.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../provider/student_provider.dart';
import '../Student_Home.dart';
import '../Task/task_info.dart';
import '../Transcript/exam.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({Key? key}) : super(key: key);

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  Timer? _timer;
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
    // Refresh the UI every minute to update current class highlighting
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StudentProvider>(
      builder: (context, studentProvider, _) {
        final student = studentProvider.student;
        if (student == null) {
          return const Center(child: CircularProgressIndicator());
        }

        // Get today's timetable
        final now = DateTime.now();
        final day = _getDayName(now.weekday);
        final todayClasses = student.timetable;

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStudentInfoCard(student),
                const SizedBox(height: 24),
                _buildTodayTimetableSection(todayClasses, day, now),
                const SizedBox(height: 24),
                // _buildQuickAccessSection(),
                _buildQuickAccessSections(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStudentInfoCard(StudentInfo student) {
    return Container(
      constraints: BoxConstraints(minHeight: 130), // Optimal height
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, activeColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative elements
          Positioned(
            right: 10,
            top: 10,
            child: Icon(BoxIcons.bx_user_circle, size: 60, color: Colors.white.withOpacity(0.1)),
          ),

          // Content Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile image with semi-circle cutout
                Container(
                  width: 80,
                  height: 100,
                  margin: const EdgeInsets.only(right: 16),
                  child: Stack(
                    children: [
                      // Semi-circle background
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              bottomLeft: Radius.circular(20),
                            ),
                          ),
                        ),
                      ),
                      // Profile image
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 60,
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: Offset(2, 3),
                                )
                              ],
                            ),
                            child: student.image != null
                                ? Image.network(
                              student.image!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: Colors.grey.shade300,
                                child: Icon(
                                  Icons.person,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                            )
                                : Container(
                              color: Colors.grey.shade300,
                              child: Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Student info
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 2,
                              offset: Offset(1, 1),
                            )
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      _buildInfoChip(BoxIcons.bx_id_card, student.regNo),
                      const SizedBox(height: 4),
                      _buildInfoChip(BoxIcons.bx_book, student.program),
                      const SizedBox(height: 4),
                      _buildInfoChip(BoxIcons.bx_group, '${student.section} • ${student.currentSession}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(
      begin: 0.1,
      end: 0,
      duration: 250.ms,
      curve: Curves.easeOutQuad,
    );
  }
  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white.withOpacity(0.9)),
          SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildTodayTimetableSection(
      List todayClasses, String day, DateTime now) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Classes",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,  // Semi-bold instead of bold for modern look
                    color: textPrimary,  // Using your theme's primary text color
                    letterSpacing: -0.3,  // Slightly tighter letter spacing
                  ),
                ),
                const SizedBox(height: 2),  // Reduced spacing for tighter grouping
                Row(
                  children: [
                    Icon(
                      Bootstrap.calendar3,  // Calendar icon for visual enhancement
                      size: 14,
                      color: textSecondary.withOpacity(0.7),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$day, ${now.day} ${_getMonthName(now.month)} ${now.year}',
                      style: TextStyle(
                        fontSize: 13,
                        color: textSecondary.withOpacity(0.8),  // Using your theme color
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ],
            ).animate().fadeIn(delay: 50.ms).slideY(
              begin: -4,
              end: 0,
              duration: 200.ms,
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => StudentTimetableScreen()),
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: primaryColor.withOpacity(0.3)),
                ),
                child: Text(
                  'View All',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ),

          ],
        ),
        const SizedBox(height: 12),
        todayClasses.isEmpty
            ? _buildNoClassesCard()
            : _buildCompactTimetable(todayClasses),
      ],
    );
  }
  Widget _buildCompactTimetable(List todayClasses) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Table(
        border: TableBorder(
          horizontalInside: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        columnWidths: const {
          0: FixedColumnWidth(90), // Time (slightly wider)
          1: FixedColumnWidth(60), // Code (wider with padding)
          2: FixedColumnWidth(80), // Venue (dedicated width)
          3: FlexColumnWidth(), // Instructor (takes remaining space)
        },
        children: [
          // Header row with improved spacing
          TableRow(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                child: Center(
                    child: Text('TIME',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12))),
              ),
              Padding(
                padding:
                    EdgeInsets.only(left: 12, right: 8, top: 10, bottom: 10),
                child: Center(
                    child: Text('CODE',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12))),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                child: Center(
                    child: Text('VENUE',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12))),
              ),
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  child: Center(
                      child: Text('INSTRUCTOR',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12)))),
            ],
          ),
          // Data rows
          ...todayClasses.map((classInfo) {
            final isCurrentClass = isCurrentTimeSlot(
              classInfo['start_time'].toString(),
              classInfo['end_time'].toString(),
            );

            String instructor = '';
            if (classInfo['teachername'] != "N/A" &&
                    (classInfo['juniorlecturer'] != "N/A") ||
                classInfo['juniorlecturer'] != null) {
              instructor =
                  '${classInfo['teachername']}\n${classInfo['juniorlecturer']}';
            } else if (classInfo['teachername'] != "N/A") {
              instructor = classInfo['teachername'].toString();
            } else if (classInfo['juniorlecturer'] != "N/A") {
              instructor = classInfo['juniorlecturer'].toString();
            }

            return TableRow(
              decoration: BoxDecoration(
                color: isCurrentClass ? const Color(0xFFE8F5E9) : Colors.white,
              ),
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: Center(
                    child: Text(
                      '${classInfo['start_time'].toString().substring(0, 5)}\n${classInfo['end_time'].toString().substring(0, 5)}',
                      style: TextStyle(
                        color: isCurrentClass
                            ? const Color(0xFF4CAF50)
                            : Colors.grey.shade700,
                        fontWeight: isCurrentClass
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                      left: 12, right: 8, top: 12, bottom: 12),
                  child: Center(
                    child: Text(
                      classInfo['description'].toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                        color: Colors.grey.shade800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: Center(
                    child: Text(
                      classInfo['venue'].toString(),
                      style: const TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: Center(
                    child: Text(
                      instructor,
                      style: const TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildNoClassesCard() {
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
              BoxIcons.bx_calendar_heart, // More thematic icon
              size: 48,
              color: primaryColor.withOpacity(0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'No classes scheduled',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textSecondary.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Enjoy your free time!',
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



  String _getDayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  bool isCurrentTimeSlot(String startTime, String endTime) {
    try {
      final now = DateTime.now();
      final current = now.hour * 3600 + now.minute * 60 + now.second;

      int parseTime(String t) {
        final parts = t.split(':').map(int.parse).toList();
        return parts[0] * 3600 +
            parts[1] * 60 +
            (parts.length > 2 ? parts[2] : 0);
      }

      final start = parseTime(startTime);
      final end = parseTime(endTime);

      return start <= end
          ? current >= start && current <= end
          : current >= start || current <= end;
    } catch (e) {
      return false;
    }
  }




/////////////////////////////////fault////////////////////////////////////

  Widget _buildQuickAccessSections() {
    final List<Map<String, dynamic>> quickAccess = [
      {
        'title':'Due Task',
        'icon':BoxIcons.bx_task,
        'color':const Color(0xFF4CAF50)
      },
      {
        'title': 'Transcript',
        'icon': BoxIcons.bx_file,
        'color': primaryColor,
      },
      {
        'title': 'Courses',
        'icon': BoxIcons.bx_book_alt,
        'color': const Color(0xFF2196F3),
      },
      {
        'title': 'Exams',
        'icon': BoxIcons.bx_edit_alt,
        'color': const Color(0xFFF44336),
      },
      {
        'title': 'Academic Report',
        'icon': BoxIcons.bx_bar_chart_alt_2,
        'color': const Color(0xFF4CAF50),
      },
      {
        'title': 'Timetable',
        'icon': BoxIcons.bx_calendar,
        'color': const Color(0xFFFFC107),
      },
      {
        'title': 'Course Content',
        'icon': BoxIcons.bx_folder_open,
        'color': const Color(0xFF9C27B0),
      },
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Quick Access',
                    style: TextStyle(
                      fontSize: 17,  // Slightly smaller for better hierarchy
                      fontWeight: FontWeight.w600,  // Semi-bold instead of bold
                      color: textPrimary,  // Using your theme's primary text color
                      letterSpacing: -0.3,  // Tighter letter spacing
                    ),
                  ),
                  const SizedBox(width: 8),  // Spacing between text and icon
                  Icon(
                    Bootstrap.thunderbolt,  // Lightning bolt icon for "quick" concept
                    size: 16,
                    color: activeColor,  // Using your activeColor for accent
                  ),
                ],
              ).animate().fadeIn(delay: 50.ms).slideY(
                begin: -4,
                end: 0,
                duration: 200.ms,
              ),
              TextButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (context) => _buildQuickActionsSheet(),
                  );
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: primaryColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    'View All',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: quickAccess.length,
          itemBuilder: (context, index) {
            final item = quickAccess[index];
            return _buildQuickAccessCards(item);
          },
        ),
      ],
    );
  }
  static const Color cardColor = Colors.white;
  Widget _buildQuickAccessCards(Map<String, dynamic> item) {
    return SizedBox(
      width: 110, // Fixed width
      height: 100, // Increased height to prevent overflow
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            final studentProvider = Provider.of<StudentProvider>(context, listen: false);
            if(item['title']=='Due Task'){
              Navigator.push(context,MaterialPageRoute(builder: (context)=>YourTasksScreen()));
            }else if(item['title']=='Exams'){

              Navigator.push(context,MaterialPageRoute(builder: (context)=>ExamResultsScreen(studentId: studentProvider.student!.id,)));
            }else if(item['title']=='Course Content'){
              Navigator.push(context,MaterialPageRoute(builder: (context)=>CourseContentScreen(studentId: studentProvider.student!.id,)));
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(8), // Reduced padding
            child: Column(
              mainAxisSize: MainAxisSize.min, // Added to prevent overflow
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10), // Reduced padding
                  decoration: BoxDecoration(
                    color: item['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: item['color'].withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    item['icon'],
                    color: item['color'],
                    size: 20, // Reduced icon size
                  ),
                ),
                const SizedBox(height: 6), // Reduced spacing
                Text(
                  item['title'],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11, // Reduced font size
                    fontWeight: FontWeight.w500,
                    color: textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildQuickActionsSheet() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: textSecondary,
                borderRadius: BorderRadius.all(
                  Radius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              children: [
                _buildQuickActionItem(
                    BoxIcons.bx_check_square, 'Mark\nAttendance', Colors.green),
                _buildQuickActionItem(
                    BoxIcons.bx_file, 'Submit\nAssignment', Colors.orange),
                _buildQuickActionItem(
                    BoxIcons.bx_calendar, 'View\nSchedule', primaryColor),
                _buildQuickActionItem(
                    BoxIcons.bx_book_open, 'Study\nMaterials', Colors.purple),
                _buildQuickActionItem(
                    BoxIcons.bx_help_circle, 'Ask\nHelp', Colors.red),
                _buildQuickActionItem(
                    BoxIcons.bx_line_chart, 'Check\nGrades', Colors.teal),
              ],
            ),
          ),
        ],
      ),
    ).animate().slideY(
      begin: 1.0,
      end: 0.0,
      duration: 300.ms,
      curve: Curves.easeOutQuad,
    );
  }

  Widget _buildQuickActionItem(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Icon(
            icon,
            color: color,
            size: 30,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textPrimary,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 100.ms).slideY(
      begin: 0.2,
      end: 0,
      delay: 100.ms,
      duration: 300.ms,
      curve: Curves.easeOutQuad,
    );
  }
}
