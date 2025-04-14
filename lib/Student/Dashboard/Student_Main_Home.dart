import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../provider/student_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Student_Home.dart';


class HomeTab extends StatelessWidget {
  const HomeTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: DashboardTheme.themeData,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello,',
                    style: DashboardTheme.bodyMedium.copyWith(
                      fontSize: 16,
                      color: DashboardTheme.secondaryTextColor,
                    ),
                  ),
                  Text(
                    'John Nathan',
                    style: DashboardTheme.titleLarge.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Notice Board
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notice Board',
                    style: DashboardTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: DashboardTheme.noticeBoardDecoration,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'New UI/UX Course for',
                          style: DashboardTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildCategoryChip('Graphic Design'),
                            _buildCategoryChip('Web Design'),
                            _buildCategoryChip('Web Development'),
                            _buildCategoryChip('Data Science'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Popular Courses
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Popular Courses',
                    style: DashboardTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCourseCard('Graphic Design for Beginners'),
                        const SizedBox(width: 12),
                        _buildCourseCard('Web Development Fundamentals'),
                        const SizedBox(width: 12),
                        _buildCourseCard('Advanced UI/UX Principles'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Recent Activities
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Activities',
                    style: DashboardTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _buildActivityItem('Completed Quiz 1', 'Graphic Design'),
                  _buildActivityItem('New assignment posted', 'Web Development'),
                  _buildActivityItem('Grade updated', 'UI/UX Principles'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String text) {
    return Chip(
      label: Text(text),
      backgroundColor: DashboardTheme.tertiaryColor,
      labelStyle: DashboardTheme.bodyMedium.copyWith(
        color: DashboardTheme.primaryTextColor,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildCourseCard(String title) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: DashboardTheme.courseCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: DashboardTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                Icons.library_books,
                size: 40,
                color: DashboardTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: DashboardTheme.bodyLarge,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            'Enroll Now',
            style: DashboardTheme.bodyMedium.copyWith(
              color: DashboardTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String course) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: DashboardTheme.courseCardDecoration,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: DashboardTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications,
              color: DashboardTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: DashboardTheme.bodyLarge),
                const SizedBox(height: 4),
                Text(course, style: DashboardTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
// class HomeTab extends StatefulWidget {
//   const HomeTab({Key? key}) : super(key: key);
//
//   @override
//   State<HomeTab> createState() => _HomeTabState();
// }
//
// class _HomeTabState extends State<HomeTab> {
//   @override
//   Widget build(BuildContext context) {
//     final student = Provider.of<StudentProvider>(context).student;
//
//     return SingleChildScrollView(
//       child: Column(
//         children: [
//           // Welcome Card
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Theme.of(context).primaryColor,
//               borderRadius: const BorderRadius.only(
//                 bottomLeft: Radius.circular(20),
//                 bottomRight: Radius.circular(20),
//               ),
//             ),
//             child: Row(
//               children: [
//                 CircleAvatar(
//                   radius: 30,
//                   backgroundImage: NetworkImage(student?.image ?? ''),
//                   backgroundColor: Colors.grey.shade200,
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Welcome, ${student?.name}',
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         '${student?.program} • ${student?.section}',
//                         style: TextStyle(
//                           color: Colors.white.withOpacity(0.9),
//                           fontSize: 14,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Row(
//                         children: [
//                           const Icon(Icons.star, color: Colors.amber, size: 16),
//                           const SizedBox(width: 4),
//                           Text(
//                             'CGPA: ${student?.cgpa}',
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontSize: 14,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ).animate().fadeIn(delay: 100.ms),
//
//           // Stats Cards
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: GridView.count(
//               shrinkWrap: true,
//               physics: const NeverScrollableScrollPhysics(),
//               crossAxisCount: 2,
//               crossAxisSpacing: 16,
//               mainAxisSpacing: 16,
//               children: [
//                 _buildStatCard(
//                   context,
//                   title: 'Current Week',
//                   value: student?.currentWeek.toString() ?? '0',
//                   icon: Icons.calendar_today,
//                   color: Colors.blue.shade100,
//                   textColor: Colors.blue.shade800,
//                 ),
//                 _buildStatCard(
//                   context,
//                   title: 'Enrollments',
//                   value: student?.totalEnrollments.toString() ?? '0',
//                   icon: Icons.book,
//                   color: Colors.green.shade100,
//                   textColor: Colors.green.shade800,
//                 ),
//                 _buildStatCard(
//                   context,
//                   title: 'Attendance',
//                   value: '${_calculateOverallAttendance(student?.attendance ?? [])}%',
//                   icon: Icons.assignment_turned_in,
//                   color: Colors.orange.shade100,
//                   textColor: Colors.orange.shade800,
//                 ),
//                 _buildStatCard(
//                   context,
//                   title: 'Due Tasks',
//                   value: student?.taskInfo.length.toString() ?? '0',
//                   icon: Icons.assignment_late,
//                   color: Colors.red.shade100,
//                   textColor: Colors.red.shade800,
//                 ),
//               ],
//             ).animate().slideY(duration: 300.ms),
//           ),
//
//           // Quick Links
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   'Quick Links',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 GridView.count(
//                   shrinkWrap: true,
//                   physics: const NeverScrollableScrollPhysics(),
//                   crossAxisCount: 4,
//                   children: [
//                     _buildQuickLink(Icons.book, 'Courses'),
//                     _buildQuickLink(Icons.assignment, 'Assignments'),
//                     _buildQuickLink(Icons.quiz, 'Quizzes'),
//                     _buildQuickLink(Icons.grade, 'Grades'),
//                   ],
//                 ),
//               ],
//             ).animate().fadeIn(delay: 200.ms),
//           ),
//
//           // Recent Activities
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: Card(
//               elevation: 4,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Recent Activities',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     _buildActivityItem('New assignment posted', '2 hours ago'),
//                     _buildActivityItem('Grade updated for Quiz 1', '1 day ago'),
//                     _buildActivityItem('Attendance marked', '2 days ago'),
//                   ],
//                 ),
//               ),
//             ).animate().slideX(duration: 300.ms),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildStatCard(
//       BuildContext context, {
//         required String title,
//         required String value,
//         required IconData icon,
//         required Color color,
//         required Color textColor,
//       }) {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(12),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: color,
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(icon, color: textColor),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               value,
//               style: TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//                 color: textColor,
//               ),
//             ),
//             Text(
//               title,
//               style: TextStyle(
//                 fontSize: 12,
//                 color: Colors.grey.shade600,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildQuickLink(IconData icon, String label) {
//     return Column(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(12),
//           decoration: BoxDecoration(
//             color: Colors.grey.shade100,
//             shape: BoxShape.circle,
//           ),
//           child: Icon(icon, color: Theme.of(context).primaryColor),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           label,
//           style: const TextStyle(fontSize: 12),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildActivityItem(String title, String time) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         children: [
//           Container(
//             width: 8,
//             height: 8,
//             decoration: BoxDecoration(
//               color: Theme.of(context).primaryColor,
//               shape: BoxShape.circle,
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Text(title),
//           ),
//           Text(
//             time,
//             style: TextStyle(
//               color: Colors.grey.shade600,
//               fontSize: 12,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   double _calculateOverallAttendance(List<dynamic> attendance) {
//     if (attendance.isEmpty) return 0;
//     double totalPercentage = 0;
//     for (var course in attendance) {
//       totalPercentage += course['Percentage'] ?? 0;
//     }
//     return (totalPercentage / attendance.length).roundToDouble();
//   }
// }