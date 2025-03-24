import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lmsv2/alerts/custom_alerts.dart';
import 'package:lmsv2/auth/login_screen.dart';
import 'package:lmsv2/teacher/timetable_teacher.dart';
import 'package:provider/provider.dart';
import '../Model/Comman Model.dart';
import '../provider/instructor_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:lmsv2/Theme/Colors.dart';
import 'Home/Teacher_Main_Home.dart';
import 'Home/Teacher_Main_Notification.dart';
import 'Home/Teacher_Main_Profile.dart';
import 'Home/Teacher_Main_Settings.dart';
import 'Home/Teacher_Main_Task.dart';
class TeacherHome extends StatefulWidget {
  const TeacherHome({Key? key}) : super(key: key);
  @override
  _TeacherHomeState createState() => _TeacherHomeState();
}
class _TeacherHomeState extends State<TeacherHome> {
  int selectBtn = 0;
  // List of screens to be displayed for each tab
  final List<Widget> _screens = [
    const HomeScreen(),
    const NotificationScreen(),
    const TaskScreen(),
    const ProfileScreen(),
    const SettingsScreen(),
  ];
  @override
  Widget build(BuildContext context) {
    final instructorProvider = Provider.of<InstructorProvider>(context);
    instructorProvider.instructor?.id;
    String imageUrl;
    if (instructorProvider.instructor?.image != null && instructorProvider.instructor!.image!.isNotEmpty) {
      // Use the provided image from InstructorProvider
      imageUrl = instructorProvider.instructor!.image!;
    } else {
      // Fallback to Placeholder API or any avatar generator API using name
      String name = instructorProvider.instructor?.name ?? "User";
      imageUrl = 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}background=4FC3F7&color=ffffff';
    }
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Color(0xFF00A0E4), // The blue color from your design
        automaticallyImplyLeading: false, // Remove back button
        toolbarHeight: 100, // Increase height for the layout
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome Back!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
            Text(
              Provider.of<InstructorProvider>(context).instructor?.name ?? 'No Name',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              Provider.of<InstructorProvider>(context).type ?? 'Instructor',
              style: TextStyle(
                color: Colors.amber,
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white, // White border
              child: CircleAvatar(
                radius: 28,
                backgroundImage: NetworkImage(imageUrl), // Replace with your image
              ),
            ),
          ),
        ],
        // Extend the app bar to include system UI area (status bar)
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Color(0xFF00A0E4), // Same color as AppBar
          statusBarIconBrightness: Brightness.light, // Light status bar icons for dark background
        ),
      ),
      backgroundColor: bgColor,
      body: Column(
        children: [
          // Display the selected screen
          Expanded(
            child: _screens[selectBtn],
          ),
          // Navigation bar at the bottom
          navigationBar(),
        ],
      ),
    );
  }

  Widget navigationBar() {
    return AnimatedContainer(
      height: 70.0,
      duration: const Duration(milliseconds: 400),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(selectBtn == 0 ? 0.0 : 20.0),
          topRight:
          Radius.circular(selectBtn == navBtn.length - 1 ? 0.0 : 20.0),
        ),
      ),
      child: LayoutBuilder(
          builder: (context, constraints) {
            double itemWidth = constraints.maxWidth / navBtn.length;
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (int i = 0; i < navBtn.length; i++)
                  GestureDetector(
                    onTap: () => setState(() => selectBtn = i),
                    child: iconBtn(i, itemWidth),
                  ),
              ],
            );
          }
      ),
    );
  }

  Widget iconBtn(int i, double width) {
    bool isActive = selectBtn == i ? true : false;
    var height = isActive ? 60.0 : 0.0;
    var notchWidth = isActive ? 50.0 : 0.0;

    return SizedBox(
      width: width,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: AnimatedContainer(
              height: height,
              width: notchWidth,
              duration: const Duration(milliseconds: 600),
              child: isActive
                  ? CustomPaint(
                painter: ButtonNotch(),
              )
                  : const SizedBox(),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Image.asset(
              navBtn[i].imagePath,
              color: isActive ? selectColor : black,
              height: 22,
              width: 22,
              // Add error builder to help debug any issues
              errorBuilder: (context, error, stackTrace) {
                print('Error loading image: ${navBtn[i].imagePath}');
                // Fallback to a simple circle as placeholder
                return Container(
                  height: 22,
                  width: 22,
                  decoration: BoxDecoration(
                    color: isActive ? selectColor : black,
                    shape: BoxShape.circle,
                  ),
                );
              },
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 5.0),
              child: Text(
                navBtn[i].name,
                textAlign: TextAlign.center,
                style: isActive
                    ? bntText.copyWith(
                  color: selectColor,
                  fontSize: 11,
                )
                    : bntText.copyWith(
                  fontSize: 11,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
const TextStyle bntText = TextStyle(
  color: black,
  fontWeight: FontWeight.w500,
);













//////////////////////////////////////////////////////


// Widget _buildAttendancePrompt() {
//   return GestureDetector(
//     onTap: () {
//       // Close when tapping outside
//       setState(() {
//         _showAttendancePrompt = false;
//       });
//     },
//     child: Container(
//       width: double.infinity,
//       height: double.infinity,
//       color: Colors.black.withOpacity(0.5),
//       child: Center(
//         child: GestureDetector(
//           onTap: () {}, // Prevent closing when tapping on the dialog
//           child: Container(
//             width: MediaQuery.of(context).size.width * 0.9,
//             constraints: BoxConstraints(
//               maxHeight: MediaQuery.of(context).size.height * 0.7,
//             ),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(16),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.2),
//                   blurRadius: 10,
//                   offset: const Offset(0, 2),
//                 ),
//               ],
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 _buildAttendancePromptHeader(),
//                 Flexible(
//                   child: _buildAttendancePromptContent(),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     ),
//   );
// }
//
// Widget _buildAttendancePromptHeader() {
//   return Container(
//     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//     decoration: const BoxDecoration(
//       color: Colors.blue,
//       borderRadius: BorderRadius.only(
//         topLeft: Radius.circular(16),
//         topRight: Radius.circular(16),
//       ),
//     ),
//     child: Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         const Text(
//           'Your Classes Today',
//           style: TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.bold,
//             fontSize: 16,
//           ),
//         ),
//         IconButton(
//           icon: const Icon(Icons.close, color: Colors.white),
//           onPressed: () {
//             setState(() {
//               _showAttendancePrompt = false;
//             });
//           },
//           padding: EdgeInsets.zero,
//           constraints: const BoxConstraints(),
//         ),
//       ],
//     ),
//   );
// }
//
// Widget _buildAttendancePromptContent() {
//   if (_isLoading) {
//     return const Center(
//       child: Padding(
//         padding: EdgeInsets.all(24),
//         child: CircularProgressIndicator(),
//       ),
//     );
//   }
//
//   if (_todayClasses.isEmpty) {
//     return const Center(
//       child: Padding(
//         padding: EdgeInsets.all(24),
//         child: Text('No classes scheduled for today'),
//       ),
//     );
//   }
//
//   return Column(
//     mainAxisSize: MainAxisSize.min,
//     children: [
//       Flexible(
//         child: ListView.builder(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//           shrinkWrap: true,
//           itemCount: _todayClasses.length,
//           itemBuilder: (context, index) {
//             final session = _todayClasses[index];
//             return _buildClassCard(session);
//           },
//         ),
//       ),
//       _buildLegend(),
//     ],
//   );
// }
//
// Widget _buildClassCard(ClassSession session) {
//   final bool isMarked = session.attendanceStatus == "Marked";
//   final String timeSlot = "${session.startTime} - ${session.endTime}";
//
//   return Card(
//     margin: const EdgeInsets.only(bottom: 8),
//     shape: RoundedRectangleBorder(
//       borderRadius: BorderRadius.circular(12),
//       side: BorderSide(
//         color: isMarked ? Colors.blue.shade300 : Colors.cyan.shade300,
//         width: 1,
//       ),
//     ),
//     elevation: 2,
//     child: InkWell(
//       onTap: isMarked ? null : () => _navigateToAttendanceMark(session),
//       borderRadius: BorderRadius.circular(12),
//       child: Padding(
//         padding: const EdgeInsets.all(12),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Row(
//                   children: [
//                     Container(
//                       width: 10,
//                       height: 10,
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         color: isMarked ? Colors.blue : Colors.cyan,
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     Text(
//                       session.description,
//                       style: const TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 16,
//                       ),
//                     ),
//                   ],
//                 ),
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                   decoration: BoxDecoration(
//                     color: isMarked ? Colors.blue.shade100 : Colors.cyan.shade100,
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Text(
//                     isMarked ? 'Marked' : 'Unmarked',
//                     style: TextStyle(
//                       fontSize: 12,
//                       fontWeight: FontWeight.bold,
//                       color: isMarked ? Colors.blue.shade800 : Colors.cyan.shade800,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Row(
//                   children: [
//                     const Icon(Icons.access_time, size: 14, color: Colors.grey),
//                     const SizedBox(width: 4),
//                     Text(
//                       timeSlot,
//                       style: TextStyle(
//                         fontSize: 13,
//                         color: Colors.grey.shade700,
//                       ),
//                     ),
//                   ],
//                 ),
//                 Row(
//                   children: [
//                     const Icon(Icons.location_on, size: 14, color: Colors.grey),
//                     const SizedBox(width: 4),
//                     Text(
//                       session.venue,
//                       style: TextStyle(
//                         fontSize: 13,
//                         color: Colors.grey.shade700,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//             const SizedBox(height: 6),
//             Text(
//               "Section: ${session.section}",
//               style: TextStyle(
//                 fontSize: 13,
//                 color: Colors.grey.shade700,
//               ),
//             ),
//             if (!isMarked) ...[
//               const SizedBox(height: 10),
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: () => _navigateToAttendanceMark(session),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.cyan,
//                     foregroundColor: Colors.white,
//                     padding: const EdgeInsets.symmetric(vertical: 8),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                   child: const Text('Mark Attendance'),
//                 ),
//               ),
//             ],
//           ],
//         ),
//       ),
//     ),
//   );
// }
//
// Widget _buildLegend() {
//   return Padding(
//     padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
//     child: Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         _buildLegendItem(Colors.blue, 'Marked'),
//         const SizedBox(width: 24),
//         _buildLegendItem(Colors.cyan, 'Un-Marked'),
//       ],
//     ),
//   );
// }
//
// Widget _buildLegendItem(Color color, String label) {
//   return Row(
//     children: [
//       Container(
//         width: 12,
//         height: 12,
//         decoration: BoxDecoration(
//           shape: BoxShape.circle,
//           color: color,
//         ),
//       ),
//       const SizedBox(width: 8),
//       Text(
//         label,
//         style: const TextStyle(
//           fontSize: 13,
//           fontWeight: FontWeight.w500,
//         ),
//       ),
//     ],
//   );
// }
//
// Widget _buildHorizontalCardSection({
//   required String title,
//   required List<CardData> cards,
// }) {
//   return Padding(
//     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//     child: Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
//           child: Text(
//             title,
//             style: const TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//               color: Colors.white,
//             ),
//           ),
//         ),
//         SizedBox(
//           height: 110, // Slightly reduced height
//           child: ListView.builder(
//             scrollDirection: Axis.horizontal,
//             itemCount: cards.length,
//             itemBuilder: (context, index) {
//               return GestureDetector(
//                 onTap: cards[index].onTap,
//                 child: Container(
//                   width: MediaQuery.of(context).size.width * 0.42,
//                   margin: const EdgeInsets.only(right: 10, bottom: 4),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(12),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.1),
//                         blurRadius: 5,
//                         offset: const Offset(0, 2),
//                       ),
//                     ],
//                   ),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Container(
//                         padding: const EdgeInsets.all(8),
//                         decoration: BoxDecoration(
//                           color: cards[index].color.withOpacity(0.2),
//                           shape: BoxShape.circle,
//                         ),
//                         child: Icon(
//                           cards[index].icon,
//                           color: cards[index].color,
//                           size: 22,
//                         ),
//                       ),
//                       const SizedBox(height: 6),
//                       Text(
//                         cards[index].title,
//                         style: const TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//       ],
//     ),
//   );
// }
//
//
// // Class to represent a class session from the API
// class ClassSession {
//   final String formattedData;
//   final int teacherOfferedCourseId;
//   final String attendanceStatus;
//   final String fixedDate;
//   final String courseName;
//   final String description;
//   final int courseId;
//   final int sectionId;
//   final String teacherName;
//   final String juniorLecturerName;
//   final String section;
//   final String venue;
//   final String startTime;
//   final String endTime;
//
//   ClassSession({
//     required this.formattedData,
//     required this.teacherOfferedCourseId,
//     required this.attendanceStatus,
//     required this.fixedDate,
//     required this.courseName,
//     required this.description,
//     required this.courseId,
//     required this.sectionId,
//     required this.teacherName,
//     required this.juniorLecturerName,
//     required this.section,
//     required this.venue,
//     required this.startTime,
//     required this.endTime,
//   });
//
//   factory ClassSession.fromJson(Map<String, dynamic> json) {
//     return ClassSession(
//       formattedData: json['FormattedData'],
//       teacherOfferedCourseId: json['teacher_offered_course_id'],
//       attendanceStatus: json['attendance_status'],
//       fixedDate: json['fixed_date'],
//       courseName: json['coursename'],
//       description: json['description'],
//       courseId: json['course_id'],
//       sectionId: json['section_id'],
//       teacherName: json['teachername'],
//       juniorLecturerName: json['juniorlecturername'],
//       section: json['section'],
//       venue: json['venue'],
//       startTime: json['start_time'],
//       endTime: json['end_time'],
//     );
//   }
// }
//
// // Placeholder for AttendanceScreen
// class AttendanceScreen extends StatelessWidget {
//   final int teacherOfferedCourseId;
//   final String fixedDate;
//   final ClassSession courseDetails;
//
//   const AttendanceScreen({
//     Key? key,
//     required this.teacherOfferedCourseId,
//     required this.fixedDate,
//     required this.courseDetails,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Mark Attendance'),
//       ),
//       body: Center(
//         child: Text(
//           'Mark attendance for:\nCourse ID: $teacherOfferedCourseId\nDate: $fixedDate',
//         ),
//       ),
//     );
//   }
// }