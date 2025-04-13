import 'package:flutter/material.dart';
import 'package:lmsv2/api/ApiConfig.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../provider/instructor_provider.dart';

class JuniorTimetableScreen extends StatefulWidget {
  const JuniorTimetableScreen({super.key});
  @override
  State<JuniorTimetableScreen> createState() => _JuniorTimetableScreenState();
}

class _JuniorTimetableScreenState extends State<JuniorTimetableScreen> with SingleTickerProviderStateMixin {
  bool isLoading = true;
  List<DaySchedule> timetableData = [];
  List<DaySchedule> filteredData = [];
  TabController? _tabController;
  TextEditingController searchController = TextEditingController();
  String searchQuery = "";
  bool isTableView = true;
  int _currentTabIndex = 0;
  final Color primaryColor = const Color(0xFF1565C0);
  final Color backgroundColor = const Color(0xFFF5F7FA); // Light grey-blue background
  final Color cardColor = const Color(0xFFE3F2FD); // Very light blue cards
  final Color textColor = const Color(0xFF263238); // Dark blue-grey text
  final Color secondaryTextColor = const Color(0xFF546E7A); // Medium blue-grey text
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchTimetableData();
    });
  }

  Future<void> fetchTimetableData() async {
    setState(() {
      isLoading = true;
    });

    final instructorProvider = Provider.of<InstructorProvider>(context, listen: false);
    final teacherId = instructorProvider.instructor?.id;

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.apiBaseUrl}JuniorLec/full-timetable?jl_id=$teacherId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        print('Teacher ID: $teacherId');
        print('API Response: ${response.body}');
        final jsonData = json.decode(response.body);
        if (jsonData['status'] == 'success') {
          final List<dynamic> data = jsonData['data'];
          timetableData = data.map((day) => DaySchedule.fromJson(day)).toList();

          // Initialize tab controller with one extra tab for "All"
          _tabController = TabController(length: timetableData.length + 1, vsync: this);
          _tabController?.addListener(() {
            setState(() {
              _currentTabIndex = _tabController?.index ?? 0;
            });
          });

          _filterData();
          final currentWeekday = DateTime.now().weekday;
          if (currentWeekday == 6 || currentWeekday == 7) { // Saturday or Sunday
            _tabController?.index = 0; // All tab
          } else {
            // Map weekday to day name
            final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
            final currentDayName = dayNames[currentWeekday - 1];
            // Find the index of the current day in timetableData
            final dayIndex = timetableData.indexWhere((day) => day.day == currentDayName);
            if (dayIndex != -1) {
              _tabController?.index = dayIndex + 1; // +1 because first tab is "All"
            }
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load timetable data')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error ${response.statusCode}: ${response.reasonPhrase}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
  void _filterData() {
    if (searchQuery.isEmpty) {
      filteredData = List.from(timetableData);
    } else {
      filteredData = timetableData.map((daySchedule) {
        final filteredScheduleItems = daySchedule.schedule.where((item) {
          final query = searchQuery.toLowerCase();
          return item.coursename.toLowerCase().contains(query) ||
              item.section.toLowerCase().contains(query) ||
              item.venue.toLowerCase().contains(query) ||
              (item.juniorlecturername.toLowerCase().contains(query) && item.juniorlecturername != 'N/A') ||
              item.day.toLowerCase().contains(query);
        }).toList();

        return DaySchedule(
          day: daySchedule.day,
          schedule: filteredScheduleItems,
        );
      }).toList();
    }
    setState(() {});
  }
  void _toggleView() {
    setState(() {
      isTableView = !isTableView;
    });
  }
  @override
  void dispose() {
    _tabController?.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Timetable',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isTableView ? Icons.view_agenda : Icons.table_chart,
              color: Colors.white,
            ),
            onPressed: _toggleView,
            tooltip: isTableView ? 'Switch to Card View' : 'Switch to Table View',
          ),
        ],
        bottom: isLoading || _tabController == null
            ? null
            : PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: primaryColor,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withOpacity(0.7),
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.normal,
              ),
              tabs: [
                const Tab(text: 'All'),
                ...filteredData.map((day) => Tab(text: day.day)).toList(),
              ],
            ),
          ),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : Column(
        children: [
          // Teacher info card
          Consumer<InstructorProvider>(
            builder: (context, provider, child) {
              if (provider.instructor == null) {
                return const SizedBox.shrink();
              }
              return Card(
                margin: const EdgeInsets.all(16),
                elevation: 0,
                color: cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: primaryColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: primaryColor.withOpacity(0.2), // optional background
                        child: ClipOval(
                          child: Image.network(
                            provider.instructor?.image ??
                                "https://api.dicebear.com/7.x/initials/svg?seed=${provider.instructor?.name}",
                            width: 56,  // double of radius
                            height: 56,
                            fit: BoxFit.contain,  // Keeps the full image visible
                          ),
                        ),
                      )
                      ,const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              provider.instructor!.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${provider.type ?? "Teacher"} • ${provider.instructor!.session}',
                              style: TextStyle(
                                color: secondaryTextColor,
                                fontSize: 13,
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
          ),

          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search by course, section, venue...',
                hintStyle: TextStyle(color: secondaryTextColor.withOpacity(0.6)),
                prefixIcon: Icon(Icons.search, color: secondaryTextColor.withOpacity(0.6)),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear, size: 20, color: secondaryTextColor),
                  onPressed: () {
                    searchController.clear();
                    setState(() {
                      searchQuery = "";
                      _filterData();
                    });
                  },
                )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: primaryColor.withOpacity(0.05),
              ),
              style: TextStyle(fontSize: 14, color: textColor),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                  _filterData();
                });
              },
            ),
          ),

          // Tab content
          Expanded(
            child: _tabController == null
                ? Center(child: Text('No data available', style: TextStyle(color: textColor)))
                : TabBarView(
              controller: _tabController,
              children: [
                // "All" tab content
                _buildAllDaysView(),
                // Individual day tabs
                ...filteredData.map((dayData) {
                  return dayData.schedule.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy, size: 48, color: secondaryTextColor.withOpacity(0.4)),
                        const SizedBox(height: 16),
                        Text(
                          searchQuery.isEmpty
                              ? 'No classes on ${dayData.day}'
                              : 'No matching classes on ${dayData.day}',
                          style: TextStyle(
                            fontSize: 14,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  )
                      : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (isTableView)
                          _buildTableView(dayData)
                        else
                          _buildCardView(dayData),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllDaysView() {
    if (filteredData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 48, color: secondaryTextColor.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(
              searchQuery.isEmpty
                  ? 'No classes in timetable'
                  : 'No matching classes found',
              style: TextStyle(
                fontSize: 14,
                color: secondaryTextColor,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          if (isTableView)
            ...filteredData.map((dayData) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 8),
                    child: Text(
                      dayData.day,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  _buildTableView(dayData),
                ],
              );
            }).toList()
          else
            ...filteredData.expand((dayData) {
              return [
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 8),
                  child: Text(
                    dayData.day,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: primaryColor,
                    ),
                  ),
                ),
                ...dayData.schedule.map((class_) => _buildClassDetailCard(class_)).toList(),
              ];
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildTableView(DaySchedule dayData) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: MaterialStateProperty.resolveWith<Color>(
                  (Set<MaterialState> states) => primaryColor.withOpacity(0.1),
            ),
            headingTextStyle: TextStyle(
              fontWeight: FontWeight.w600,
              color: primaryColor,
              fontSize: 12,
            ),
            dataRowColor: MaterialStateProperty.resolveWith<Color>(
                  (Set<MaterialState> states) {
                if (states.contains(MaterialState.hovered)) {
                  return primaryColor.withOpacity(0.05);
                }
                return Colors.transparent;
              },
            ),
            dataRowMinHeight: 40,
            dataRowMaxHeight: 48,
            columnSpacing: 20,
            horizontalMargin: 12,
            columns: [
              DataColumn(label: Text('Time', style: TextStyle(fontSize: 12, color: textColor))),
              DataColumn(label: Text('Course', style: TextStyle(fontSize: 12, color: textColor))),
              DataColumn(label: Text('Section', style: TextStyle(fontSize: 12, color: textColor))),
              DataColumn(label: Text('Venue', style: TextStyle(fontSize: 12, color: textColor))),
            ],
            rows: dayData.schedule.map((class_) {
              return DataRow(
                cells: [
                  DataCell(Text(
                    '${class_.start_time} - ${class_.end_time}',
                    style: TextStyle(fontSize: 11, color: textColor),
                  )),
                  DataCell(Tooltip(
                    message: class_.coursename,
                    child: Text(
                      class_.description,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: textColor),
                    ),
                  )),
                  DataCell(Text(
                    class_.section,
                    style: TextStyle(fontSize: 11, color: textColor),
                  )),
                  DataCell(Text(
                    class_.venue,
                    style: TextStyle(fontSize: 11, color: textColor),
                  )),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildCardView(DaySchedule dayData) {
    return Column(
      children: dayData.schedule.map((class_) => _buildClassDetailCard(class_)).toList(),
    );
  }

  Widget _buildClassDetailCard(ScheduleItem class_) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          class_.coursename,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          class_.description,
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      class_.section,
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildDetailItem(Icons.access_time, '${class_.start_time} - ${class_.end_time}'),
                  const SizedBox(width: 16),
                  _buildDetailItem(Icons.location_on, class_.venue),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildPersonDetail(Icons.person, 'Instructor', class_.teachername),
                    if (class_.juniorlecturername != 'N/A')
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: _buildPersonDetail(
                          Icons.person_outline,
                          'Junior Lecturer',
                          class_.juniorlecturername,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String text) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 16, color: primaryColor),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonDetail(IconData icon, String role, String name) {
    return Row(
      children: [
        Icon(icon, size: 16, color: primaryColor),
        const SizedBox(width: 8),
        Text(
          '$role: ',
          style: TextStyle(
            fontSize: 12,
            color: secondaryTextColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          name,
          style: TextStyle(
            fontSize: 12,
            color: textColor,
          ),
        ),
      ],
    );
  }
}

// Data models remain the same
class DaySchedule {
  final String day;
  final List<ScheduleItem> schedule;

  DaySchedule({
    required this.day,
    required this.schedule,
  });

  factory DaySchedule.fromJson(Map<String, dynamic> json) {
    return DaySchedule(
      day: json['day'] as String,
      schedule: (json['schedule'] as List)
          .map((item) => ScheduleItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ScheduleItem {
  final String day;
  final String coursename;
  final String description;
  final String teachername;
  final String juniorlecturername;
  final String section;
  final String venue;
  final String start_time;
  final String end_time;

  ScheduleItem({
    required this.day,
    required this.coursename,
    required this.description,
    required this.teachername,
    required this.juniorlecturername,
    required this.section,
    required this.venue,
    required this.start_time,
    required this.end_time,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      day: json['day'] as String,
      coursename: json['coursename'] as String,
      description: json['description'] as String,
      teachername: json['teachername'] as String,
      juniorlecturername: json['juniorlecturername'] as String,
      section: json['section'] as String,
      venue: json['venue'] as String,
      start_time: json['start_time'] as String,
      end_time: json['end_time'] as String,
    );
  }
}



// class JuniorTimetableScreen extends StatefulWidget {
//   const JuniorTimetableScreen({super.key});
//   @override
//   State<JuniorTimetableScreen> createState() => _JuniorTimetableScreenState();
// }
//
// class _JuniorTimetableScreenState extends State<JuniorTimetableScreen> with SingleTickerProviderStateMixin {
//   bool isLoading = true;
//   List<DaySchedule> timetableData = [];
//   List<DaySchedule> filteredData = [];
//   TabController? _tabController;
//   TextEditingController searchController = TextEditingController();
//   String searchQuery = "";
//   bool isTableView = true; // Track current view mode
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       fetchTimetableData();
//     });
//   }
//
//   Future<void> fetchTimetableData() async {
//     setState(() {
//       isLoading = true;
//     });
//
//     final instructorProvider = Provider.of<InstructorProvider>(context, listen: false);
//     final teacherId = instructorProvider.instructor?.id;
//
//     try {
//       final response = await http.get(
//         Uri.parse('${ApiConfig.apiBaseUrl}JuniorLec/full-timetable?jl_id=$teacherId'),
//         headers: {
//           'Content-Type': 'application/json',
//         },
//       );
//
//       if (response.statusCode == 200) {
//         final jsonData = json.decode(response.body);
//         if (jsonData['status'] == 'success') {
//           final List<dynamic> data = jsonData['data'];
//           timetableData = data.map((day) => DaySchedule.fromJson(day)).toList();
//           _tabController = TabController(length: timetableData.length, vsync: this);
//           _filterData();
//         } else {
//           // Handle API success with error status
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Failed to load timetable data')),
//           );
//         }
//       } else {
//         // Handle HTTP error
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error ${response.statusCode}: ${response.reasonPhrase}')),
//         );
//       }
//     } catch (e) {
//       // Handle network or parsing error
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error fetching data: $e')),
//       );
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
//
//   void _filterData() {
//     if (searchQuery.isEmpty) {
//       filteredData = List.from(timetableData);
//     } else {
//       filteredData = timetableData.map((daySchedule) {
//         // Create a copy with filtered schedule items
//         final filteredScheduleItems = daySchedule.schedule.where((item) {
//           final query = searchQuery.toLowerCase();
//           return item.coursename.toLowerCase().contains(query) ||
//               item.section.toLowerCase().contains(query) ||
//               item.venue.toLowerCase().contains(query) ||
//               (item.juniorlecturername.toLowerCase().contains(query) && item.juniorlecturername != 'N/A') ||
//               item.day.toLowerCase().contains(query);
//         }).toList();
//
//         return DaySchedule(
//           day: daySchedule.day,
//           schedule: filteredScheduleItems,
//         );
//       }).toList();
//     }
//     setState(() {});
//   }
//
//   void _toggleView() {
//     setState(() {
//       isTableView = !isTableView;
//     });
//   }
//
//   @override
//   void dispose() {
//     _tabController?.dispose();
//     searchController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Timetable',
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         backgroundColor: Colors.blue,
//         foregroundColor: Colors.white,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => Navigator.of(context).pop(),
//         ),
//         actions: [
//           // View toggle button
//           IconButton(
//             icon: Icon(isTableView ? Icons.view_agenda : Icons.grid_on),
//             onPressed: _toggleView,
//             tooltip: isTableView ? 'Switch to Card View' : 'Switch to Table View',
//           ),
//         ],
//         bottom: isLoading || _tabController == null
//             ? null
//             : TabBar(
//           controller: _tabController,
//           isScrollable: true,
//           labelColor: Colors.white,
//           unselectedLabelColor: Colors.white70,
//           indicatorColor: Colors.white,
//           tabs: filteredData
//               .map((day) => Tab(
//             text: day.day,
//           ))
//               .toList(),
//         ),
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Column(
//         children: [
//           // Teacher info card
//           Consumer<InstructorProvider>(
//             builder: (context, provider, child) {
//               if (provider.instructor == null) {
//                 return const SizedBox.shrink();
//               }
//
//               return Card(
//                 margin: const EdgeInsets.all(12),
//                 elevation: 2,
//                 child: Padding(
//                   padding: const EdgeInsets.all(12.0),
//                   child: Row(
//                     children: [
//                       CircleAvatar(
//                         radius: 30,
//                         backgroundColor: Colors.blue.shade100,
//                         backgroundImage: provider.instructor?.image != null
//                             ? NetworkImage(provider.instructor!.image!)
//                             : null,
//                         child: provider.instructor?.image == null
//                             ? Text(
//                           provider.instructor!.name.substring(0, 1).toUpperCase(),
//                           style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//                         )
//                             : null,
//                       ),
//                       const SizedBox(width: 16),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               provider.instructor!.name,
//                               style: const TextStyle(
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                             const SizedBox(height: 4),
//                             Text(
//                               '${provider.type ?? "Teacher"} • ${provider.instructor!.session}',
//                               style: TextStyle(
//                                 color: Colors.grey[700],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           ),
//
//           // Search field
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
//             child: TextField(
//               controller: searchController,
//               decoration: InputDecoration(
//                 hintText: 'Search by course, section, venue...',
//                 prefixIcon: const Icon(Icons.search),
//                 suffixIcon: searchQuery.isNotEmpty
//                     ? IconButton(
//                   icon: const Icon(Icons.clear),
//                   onPressed: () {
//                     searchController.clear();
//                     setState(() {
//                       searchQuery = "";
//                       _filterData();
//                     });
//                   },
//                 )
//                     : null,
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 filled: true,
//                 fillColor: Colors.grey[100],
//               ),
//               onChanged: (value) {
//                 setState(() {
//                   searchQuery = value;
//                   _filterData();
//                 });
//               },
//             ),
//           ),
//
//           // Tab content
//           Expanded(
//             child: _tabController == null
//                 ? const Center(child: Text('No data available'))
//                 : TabBarView(
//               controller: _tabController,
//               children: filteredData.map((dayData) {
//                 return dayData.schedule.isEmpty
//                     ? Center(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
//                       const SizedBox(height: 16),
//                       Text(
//                         searchQuery.isEmpty
//                             ? 'No classes on ${dayData.day}'
//                             : 'No matching classes on ${dayData.day}',
//                         style: TextStyle(
//                           fontSize: 16,
//                           color: Colors.grey[700],
//                         ),
//                       ),
//                     ],
//                   ),
//                 )
//                     : SingleChildScrollView(
//                   padding: const EdgeInsets.all(12.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.stretch,
//                     children: [
//                       // Conditionally display table or card view
//                       if (isTableView)
//                         _buildTableView(dayData)
//                       else
//                         _buildCardView(dayData),
//                     ],
//                   ),
//                 );
//               }).toList(),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildTableView(DaySchedule dayData) {
//     return Card(
//       elevation: 2,
//       margin: const EdgeInsets.only(bottom: 16),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: SingleChildScrollView(
//           scrollDirection: Axis.horizontal,
//           child: DataTable(
//             headingRowColor: MaterialStateProperty.all(
//               Colors.blue.withOpacity(0.1),
//             ),
//             dataRowMinHeight: 48,
//             dataRowMaxHeight: 60,
//             columnSpacing: 20,
//             horizontalMargin: 12,
//             columns: const [
//               DataColumn(label: Text('Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
//               DataColumn(label: Text('Course', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
//               DataColumn(label: Text('Section', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
//               DataColumn(label: Text('Venue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
//             ],
//             rows: dayData.schedule.map((class_) {
//               return DataRow(
//                 cells: [
//                   DataCell(Text(
//                     '${class_.start_time} - ${class_.end_time}',
//                     style: const TextStyle(fontSize: 12),
//                   )),
//                   DataCell(Tooltip(
//                     message: class_.coursename,
//                     child: Text(
//                       class_.description,
//                       overflow: TextOverflow.ellipsis,
//                       style: const TextStyle(fontSize: 12),
//                     ),
//                   )),
//                   DataCell(Text(
//                     class_.section,
//                     style: const TextStyle(fontSize: 12),
//                   )),
//                   DataCell(Text(
//                     class_.venue,
//                     style: const TextStyle(fontSize: 12),
//                   )),
//                 ],
//               );
//             }).toList(),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildCardView(DaySchedule dayData) {
//     return Column(
//       children: dayData.schedule.map((class_) => _buildClassDetailCard(class_)).toList(),
//     );
//   }
//
//   Widget _buildClassDetailCard(ScheduleItem class_) {
//     return Card(
//       elevation: 2,
//       margin: const EdgeInsets.only(bottom: 12),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         class_.coursename,
//                         style: const TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 18,
//                         ),
//                       ),
//                       Text(
//                         class_.description,
//                         style: TextStyle(
//                           color: Colors.grey[600],
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                   decoration: BoxDecoration(
//                     color: Colors.blue,
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Text(
//                     class_.section,
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const Divider(height: 24),
//             Row(
//               children: [
//                 Expanded(
//                   child: Row(
//                     children: [
//                       const Icon(Icons.access_time, color: Colors.blue, size: 18),
//                       const SizedBox(width: 4),
//                       Expanded(
//                         child: Text(
//                           '${class_.start_time} - ${class_.end_time}',
//                           style: TextStyle(
//                             color: Colors.grey[800],
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Expanded(
//                   child: Row(
//                     children: [
//                       const Icon(Icons.location_on, color: Colors.blue, size: 18),
//                       const SizedBox(width: 4),
//                       Expanded(
//                         child: Text(
//                           class_.venue,
//                           style: TextStyle(
//                             color: Colors.grey[800],
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             Container(
//               padding: const EdgeInsets.all(10),
//               decoration: BoxDecoration(
//                 color: Colors.blue.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Column(
//                 children: [
//                   Row(
//                     children: [
//                       const Icon(Icons.person, color: Colors.blue, size: 18),
//                       const SizedBox(width: 8),
//                       Expanded(
//                         child: Text(
//                           'Instructor: ${class_.teachername}',
//                           style: const TextStyle(
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   if (class_.juniorlecturername != 'N/A') ...[
//                     const SizedBox(height: 8),
//                     Row(
//                       children: [
//                         const Icon(Icons.person_outline, color: Colors.blue, size: 18),
//                         const SizedBox(width: 8),
//                         Expanded(
//                           child: Text(
//                             'Teacher: ${class_.juniorlecturername}',
//                             style: const TextStyle(
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// // Data models
// class DaySchedule {
//   final String day;
//   final List<ScheduleItem> schedule;
//
//   DaySchedule({
//     required this.day,
//     required this.schedule,
//   });
//
//   factory DaySchedule.fromJson(Map<String, dynamic> json) {
//     return DaySchedule(
//       day: json['day'] as String,
//       schedule: (json['schedule'] as List)
//           .map((item) => ScheduleItem.fromJson(item as Map<String, dynamic>))
//           .toList(),
//     );
//   }
// }
//
// class ScheduleItem {
//   final String day;
//   final String coursename;
//   final String description;
//   final String teachername;
//   final String juniorlecturername;
//   final String section;
//   final String venue;
//   final String start_time;
//   final String end_time;
//   ScheduleItem({
//     required this.day,
//     required this.coursename,
//     required this.description,
//     required this.teachername,
//     required this.juniorlecturername,
//     required this.section,
//     required this.venue,
//     required this.start_time,
//     required this.end_time,
//   });
//
//   factory ScheduleItem.fromJson(Map<String, dynamic> json) {
//     return ScheduleItem(
//       day: json['day'] as String,
//       coursename: json['coursename'] as String,
//       description: json['description'] as String,
//       teachername: json['Teacher'] as String,
//       juniorlecturername: 'N/A',
//       section: json['section'] as String,
//       venue: json['venue'] as String,
//       start_time: json['start_time'] as String,
//       end_time: json['end_time'] as String,
//     );
//   }
// }


