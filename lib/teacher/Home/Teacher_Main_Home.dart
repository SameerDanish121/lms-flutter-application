import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lmsv2/file_view/offilne_view.dart';
import 'package:lmsv2/teacher/Home/today_classes.dart';
import 'package:lmsv2/teacher/MarkAttendance/contest_attendance.dart';
import 'package:lmsv2/teacher/grader/teacher_grader.dart';
import 'package:lmsv2/teacher/timetable_teacher.dart';
import 'package:provider/provider.dart';
import '../../provider/instructor_provider.dart';
import '../course/teacher_course.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    // Get current date and time
    final now = DateTime.now();
    final formattedDate = DateFormat('MMM d, yyyy').format(now);
    final dayName = DateFormat('EEEE').format(now);
    final currentTime = TimeOfDay.fromDateTime(now);
    late final ScrollController _scrollController;
    return Container(
      // color: const Color(0xFF4448FF),
      color: const Color(0xFFFFFFFF),

      child: SingleChildScrollView(
        child: Column(
          children: [
            // Timetable section with white background and padding
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildTimetableHeader(context, formattedDate, dayName),
                  Consumer<InstructorProvider>(
                    builder: (context, instructorProvider, _) {
                      if (!instructorProvider.isInstructorAvailable) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: Text(
                              'Instructor data not available',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ),
                        );
                      }

                      final timetableData =
                          instructorProvider.instructor?.timetable ?? [];
                      var Holiday = instructorProvider.instructor?.holiday;
                      final todayClasses = timetableData.toList();


                      return todayClasses.isEmpty
                          ? (Holiday == null || Holiday!.isEmpty
                          ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: Text(
                            'No Classes Scheduled for Today',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      )
                          : Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Text(
                            Holiday!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ))
                          : _buildTimetableList(todayClasses, currentTime);

                    },
                  ),
                ],
              ),
            ),

            _buildHorizontalCardSection(
                title: 'Academic Records',
                cards: [
                  CardData(
                    title: 'Courses',
                    icon: Icons.book,
                    color: Colors.blue,
                  ),
                  CardData(
                    title: 'Graders',
                    icon: Icons.assessment,
                    color: Colors.green,
                  ),
                  CardData(
                    title: 'Attendance',
                    icon: Icons.date_range,
                    color: Colors.amber,
                  ),
                ],
                context: context),

            // Manage and Track Section (will be in scroll)
            _buildHorizontalCardSection(
                title: 'Manage and Track',
                cards: [
                  CardData(
                    title: 'Attendance',
                    icon: Icons.assignment,
                    color: Colors.purple,
                  ),
                  CardData(
                    title: 'Contest',
                    icon: Icons.school,
                    color: Colors.red,
                  ),
                  CardData(
                    title: 'Task',
                    icon: Icons.folder,
                    color: Colors.teal,
                  ),
                ],
                context: context),

            // Add some bottom padding
            const SizedBox(height: 16),

          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalCardSection({
    required String title,
    required List<CardData> cards,
    required BuildContext context,
  }) {
    final instructorProvider =
        Provider.of<InstructorProvider>(context, listen: false);
    final teacherId = instructorProvider.instructor?.id;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12, top: 4),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2D3192),
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(
            height: 150, // Slightly taller for better balance
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: cards.length,
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () {
                    if (title == 'Manage and Track' &&
                        cards[index].title == 'Attendance') {
                      ClassPrompt.showTodayClasses(context, teacherId!);
                    } else if (title == 'Manage and Track' &&
                        cards[index].title == 'Contest') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ContestAttendanceScreen()),
                      );

                    }else if(cards[index].title=='Graders'){
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => GraderInfoScreen()),
                      );
                    }else if(cards[index].title=='Courses'){
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => TeacherCoursesScreen()),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.42,
                    margin: const EdgeInsets.only(right: 16, bottom: 4, top: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.15),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              // color: cards[index].color.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Image.asset(
                              'assets/iconsv3.png',
                              width: 42,
                              height: 42,
                              // Removed the color parameter to keep original colors
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                cards[index].title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'View details',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CardData {
  final String title;
  final IconData icon;
  final Color color;

  CardData({
    required this.title,
    required this.icon,
    required this.color,
  });
}

Widget _buildTimetableHeader(BuildContext context, String date, String day) {
  return Padding(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Timetable',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4448FF),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TimetableScreen()),
                );
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'See all',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF4448FF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              date,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            Text(
              day,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _buildTimetableList(List<dynamic> timetable, TimeOfDay currentTime) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
    child: Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'Time',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                    fontSize: 11,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'Course',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                    fontSize: 11,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'Section',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                    fontSize: 11,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'Venue',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 2,
              ),
            ],
          ),
          // Set a fixed height to make exactly one row of cards visible without scrolling
          height: 155,
          child: ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: timetable.length,
            itemBuilder: (context, index) {
              final item = timetable[index];

              // Access the data using the keys from your server
              final String courseName = item['description'] ?? '';
              final String venue = item['venue'] ?? '';
              final String startTime = item['start_time'] ?? '';
              final String endTime = item['end_time'] ?? '';
              final String section = item['section'];
              bool isCurrentClass = _isCurrentTimeSlot(startTime, endTime);
              final displayCourseName = courseName.length > 4
                  ? courseName.substring(0, 4)
                  : courseName;

              return Container(
                decoration: BoxDecoration(
                  color: isCurrentClass
                      ? const Color(0xFFE3F2FD)
                      : const Color(0xFFF5F5F5),
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _formatTimeDisplay(startTime, endTime),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        displayCourseName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        section,
                        style: const TextStyle(
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        venue,
                        style: const TextStyle(
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}

String _formatTimeDisplay(String startTime, String endTime) {
  final start = startTime.split(':').take(2).join(':');
  final end = endTime.split(':').take(2).join(':');
  return '$start - $end';
}

bool _isCurrentTimeSlot(String startTime, String endTime) {
  try {
    final now = DateTime.now();
    final hm = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final current = hm * 3600 + now.minute * 60 + now.second;
    int parseTime(String t) {
      final parts = t.split(':').map(int.parse).toList();
      return parts[0] * 3600 + parts[1] * 60 + parts[2];
    }

    final start = parseTime(startTime);
    final end = parseTime(endTime);

    return start <= end
        ? current >= start && current <= end
        : current >= start || current <= end;
  } catch (_) {
    return false;
  }
}

// Helper: Directly compares time strings in "H:mm:ss" format
