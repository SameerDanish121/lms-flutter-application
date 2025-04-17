import 'package:flutter/material.dart';
import 'package:lmsv2/api/ApiConfig.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:icons_plus/icons_plus.dart';
import '../provider/student_provider.dart';
import '../../alerts/custom_alerts.dart';

class StudentTimetableScreen extends StatefulWidget {
  const StudentTimetableScreen({super.key});

  @override
  State<StudentTimetableScreen> createState() => _StudentTimetableScreenState();
}

class _StudentTimetableScreenState extends State<StudentTimetableScreen>
    with TickerProviderStateMixin {
  bool isLoading = true;
  bool isRefreshing = false;
  List<DaySchedule> timetableData = [];
  List<DaySchedule> filteredData = [];
  late TabController _tabController;
  TextEditingController searchController = TextEditingController();
  String searchQuery = "";
  bool isTableView = true;
  int _currentTabIndex = 0;

  // Color Scheme (matching GraderScreen)
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
    _tabController = TabController(length: 1, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchTimetableData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Try to get DefaultTabController from ancestor if exists
    final defaultController = DefaultTabController.maybeOf(context);
    if (defaultController != null && _tabController != defaultController) {
      _tabController.dispose();
      _tabController = defaultController;
    }
  }

  Future<void> fetchTimetableData() async {
    try {
      final StudentProviders = Provider.of<StudentProvider>(context, listen: false);
      final studentId = StudentProviders.student?.id;

      final response = await http.get(
        Uri.parse('${ApiConfig.apiBaseUrl}Students/FullTimetable?student_id=${studentId}'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['status'] == 'success') {
          final List<dynamic> data = jsonData['data'];
          timetableData = data.map((day) => DaySchedule.fromJson(day)).toList();

          // Only create new controller if we're not using an ancestor controller
            _tabController.dispose();
            _tabController = TabController(
              length: timetableData.length + 1,
              vsync: this,
            );
            _tabController.addListener(() {
              setState(() {
                _currentTabIndex = _tabController.index;
              });
            });

            final currentWeekday = DateTime.now().weekday;
            if (currentWeekday == 6 || currentWeekday == 7) {
              _tabController.index = 0;
            } else {
              final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
              final currentDayName = dayNames[currentWeekday - 1];
              final dayIndex = timetableData.indexWhere((day) => day.day == currentDayName);
              if (dayIndex != -1) {
                _tabController.index = dayIndex + 1;
              }
            }


          _filterData();
        } else {
          CustomAlert.error(context, 'Failed!', 'Failed to load timetable data');
        }
      } else {
        CustomAlert.error(
            context,
            'Error ${response.statusCode}',
            response.reasonPhrase ?? 'Failed to load timetable'
        );
      }
    } catch (e) {
      CustomAlert.error(context, 'Error!', 'Failed to fetch timetable data: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
          isRefreshing = false;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() => isRefreshing = true);
    await fetchTimetableData();
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

  // @override
  // void dispose() {
  //   // Only dispose if we created our own controller
  //   if (_tabController.vsync == this) {
  //     _tabController.dispose();
  //   }
  //   searchController.dispose();
  //   super.dispose();
  // }

  Widget _buildSkeletonLoader() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Student Info Skeleton
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: cardBackground,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 150,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 200,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Search Bar Skeleton
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.only(bottom: 16),
          ),

          // Tabs Skeleton
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.only(bottom: 16),
          ),

          // Content Skeleton
          ...List.generate(3, (index) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 100,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  margin: const EdgeInsets.only(bottom: 8),
                ),
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: cardBackground,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        ...List.generate(3, (index) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Container(
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 3,
                                child: Container(
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        title: const Text(
          'Timetable',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              isTableView ? Bootstrap.grid : Bootstrap.list_ul,
              color: Colors.white,
              size: 20,
            ),
            onPressed: _toggleView,
            tooltip: isTableView ? 'Switch to Card View' : 'Switch to Table View',
          ),
        ],
        bottom: isLoading || isRefreshing || _tabController.length <= 1
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
              tabs: [
                const Tab(text: 'All'),
                ...filteredData.map((day) => Tab(text: day.day)).toList(),
              ],
            ),
          ),
        ),
      ),
      body: isLoading || isRefreshing
          ? _buildSkeletonLoader()
          : RefreshIndicator(
        onRefresh: _refreshData,
        color: primaryColor,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Student Info Card
              Consumer<StudentProvider>(
                builder: (context, provider, child) {
                  if (provider.student == null) return SizedBox();
                  return Card(
                    margin: const EdgeInsets.all(16),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: cardBackground,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundImage: NetworkImage(
                              provider.student?.image ??
                                  "https://api.dicebear.com/7.x/initials/svg?seed=${provider.student?.name}",
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  provider.student!.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${provider.type ?? "Student"} • ${provider.student?.currentSession}',
                                  style: TextStyle(
                                    color: textSecondary,
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

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by course, section, venue...',
                      hintStyle: TextStyle(
                        color: textSecondary.withOpacity(0.6),
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Bootstrap.search,
                        color: textSecondary.withOpacity(0.6),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                        icon: Icon(
                          Bootstrap.x,
                          size: 16,
                          color: textSecondary.withOpacity(0.6),
                        ),
                        onPressed: () {
                          searchController.clear();
                          setState(() {
                            searchQuery = "";
                            _filterData();
                          });
                        },
                      )
                          : null,
                    ),
                    style: TextStyle(fontSize: 14, color: textPrimary),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                        _filterData();
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tab content
              _tabController.length <= 1
                  ? Center(
                child: Text(
                  'No data available',
                  style: TextStyle(color: textSecondary),
                ),
              )
                  : SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: TabBarView(
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
                            Icon(
                              Bootstrap.calendar_x,
                              size: 40,
                              color: textSecondary.withOpacity(0.4),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              searchQuery.isEmpty
                                  ? 'No classes on ${dayData.day}'
                                  : 'No matching classes on ${dayData.day}',
                              style: TextStyle(
                                fontSize: 14,
                                color: textSecondary,
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
        ),
      ),
    );
  }

  Widget _buildAllDaysView() {
    if (filteredData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Bootstrap.calendar_x,
              size: 40,
              color: textSecondary.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              searchQuery.isEmpty
                  ? 'No classes in timetable'
                  : 'No matching classes found',
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
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
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: cardBackground,
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
              DataColumn(label: Text('Time', style: TextStyle(fontSize: 12, color: textPrimary))),
              DataColumn(label: Text('Course', style: TextStyle(fontSize: 12, color: textPrimary))),
              DataColumn(label: Text('Section', style: TextStyle(fontSize: 12, color: textPrimary))),
              DataColumn(label: Text('Venue', style: TextStyle(fontSize: 12, color: textPrimary))),
            ],
            rows: dayData.schedule.map((class_) {
              return DataRow(
                cells: [
                  DataCell(Text(
                    '${class_.start_time} - ${class_.end_time}',
                    style: TextStyle(fontSize: 11, color: textPrimary),
                  )),
                  DataCell(Tooltip(
                    message: class_.coursename,
                    child: Text(
                      class_.description,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: textPrimary),
                    ),
                  )),
                  DataCell(Text(
                    class_.section,
                    style: TextStyle(fontSize: 11, color: textPrimary),
                  )),
                  DataCell(Text(
                    class_.venue,
                    style: TextStyle(fontSize: 11, color: textPrimary),
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
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: cardBackground,
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
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        class_.description,
                        style: TextStyle(
                          color: textSecondary,
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
                _buildDetailItem(Bootstrap.clock, '${class_.start_time} - ${class_.end_time}'),
                const SizedBox(width: 16),
                _buildDetailItem(Bootstrap.geo_alt, class_.venue),
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
                  _buildPersonDetail(Bootstrap.person_fill, 'Instructor', class_.teachername),
                  if (class_.juniorlecturername != 'N/A')
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _buildPersonDetail(
                        Bootstrap.person,
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
                color: textPrimary,
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
            color: textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          name,
          style: TextStyle(
            fontSize: 12,
            color: textPrimary,
          ),
        ),
      ],
    );
  }
}

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
      day: json['day'] as String? ?? '',
      coursename: json['coursename'] as String? ?? '',
      description: json['description'] as String? ?? '',
      teachername: json['teachername'] as String? ?? '',
      juniorlecturername: json['juniorlecturername'] as String? ?? 'N/A',
      section: json['section'] as String? ?? '',
      venue: json['venue'] as String? ?? '',
      start_time: json['start_time'] as String? ?? '',
      end_time: json['end_time'] as String? ?? '',
    );
  }
}