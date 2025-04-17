import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:icons_plus/icons_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:convert';

import 'package:lmsv2/api/ApiConfig.dart';
import '../../alerts/custom_alerts.dart';
import 'grader_task_info.dart';

class GraderDashboard extends StatefulWidget {
  final int studentId;

  const GraderDashboard({Key? key, required this.studentId}) : super(key: key);

  @override
  State<GraderDashboard> createState() => _GraderDashboardState();
}

class _GraderDashboardState extends State<GraderDashboard> {
  late Future<Map<String, dynamic>> _graderData;
  int? graderId;
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _filteredAllocations = [];
  List<dynamic> _currentAllocations = [];
  List<dynamic> _previousAllocations = [];

  // Color Scheme
  static const Color primaryColor = Color(0xFF4361EE);
  static const Color activeColor = Color(0xFF4CC9F0);
  static const Color previousColor = Color(0xFF6C757D);
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color textPrimary = Color(0xFF212529);
  static const Color textSecondary = Color(0xFF6C757D);

  @override
  void initState() {
    super.initState();
    _graderData = _fetchGraderData();
    _searchController.addListener(_filterAllocations);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetchGraderData() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.apiBaseUrl}Grader/GraderInfo?student_id=${widget.studentId}'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['data'].isNotEmpty) {
        graderId = data['data'][0]['grader_id'];
        _organizeAllocations(data['data'][0]['Grader Allocations'] ?? []);
      }
      return data;
    } else {
      CustomAlert.error(context, 'Failed!', 'Failed to load grader data');
      return {"message": "Failed", "data": []};
    }
  }

  void _organizeAllocations(List<dynamic> allocations) {
    _currentAllocations = allocations.where((a) => a['Session is ? '].contains('Current')).toList();
    _previousAllocations = allocations.where((a) => !a['Session is ? '].contains('Current')).toList();
    _filteredAllocations = [..._currentAllocations, ..._previousAllocations];
  }

  void _filterAllocations() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredAllocations = [..._currentAllocations, ..._previousAllocations];
      } else {
        _filteredAllocations = [..._currentAllocations, ..._previousAllocations]
            .where((allocation) =>
        allocation['teacher_name'].toString().toLowerCase().contains(query) ||
            allocation['session_name'].toString().toLowerCase().contains(query))
            .toList();
      }
    });
  }

  Future<void> _refreshData() async {
    setState(() {
      _graderData = _fetchGraderData();
    });
  }
  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'merit':
        return Colors.green;
      case 'need-based':
        return Colors.blue;
      case 'assistant':
        return Colors.purple;
      default:
        return Colors.orange;
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: primaryColor,
        child: FutureBuilder<Map<String, dynamic>>(
          future: _graderData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SkeletonLoader();
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!['data'].isEmpty) {
              return const Center(child: Text('No grader data available'));
            }

            final graderInfo = snapshot.data!['data'][0];

            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 110,
                  floating: false,
                  pinned: true,
                  backgroundColor: primaryColor,
                  automaticallyImplyLeading: false,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      color: primaryColor,
                      padding: EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: MediaQuery.of(context).padding.top + 8,
                        bottom: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  graderInfo['grader_name'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Bootstrap.person_badge,
                                        size: 14,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'GRADER',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getTypeColor(graderInfo['type']).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _getTypeColor(graderInfo['type']).withOpacity(0.4),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    graderInfo['type'].toString().toUpperCase(),
                                    style: TextStyle(
                                      color: _getTypeColor(graderInfo['type']),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: Colors.white,
                                child: CircleAvatar(
                                  radius: 24,
                                  backgroundImage: graderInfo['image'] != null &&
                                      graderInfo['image'].toString().isNotEmpty
                                      ? NetworkImage(graderInfo['image'])
                                      : const AssetImage('assets/user.png') as ImageProvider,
                                ),
                              ),
                              Positioned.fill(
                                child: Center(
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.pop(context);
                                    },
                                    child: const Icon(
                                      Icons.import_export_outlined, // Unique & elegant from icons_plus
                                      color: Colors.white,
                                      size: 26,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // CircleAvatar(
                          //   radius: 26,
                          //   backgroundColor: Colors.white,
                          //   child: CircleAvatar(
                          //     radius: 24,
                          //     backgroundImage: graderInfo['image'] != null && graderInfo['image'].toString().isNotEmpty
                          //         ? NetworkImage(graderInfo['image'])
                          //         : const AssetImage('assets/user.png') as ImageProvider,
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Search Bar
                        Container(
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
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search by teacher or session...',
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
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Grader Of Section
                        Row(
                          children: [
                            Icon(
                              Bootstrap.person_workspace,
                              size: 20,
                              color: textPrimary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Grader Of',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Current Allocations
                        if (_filteredAllocations.where((a) => a['Session is ? '].contains('Current')).isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  'Current Session',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: textSecondary,
                                  ),
                                ),
                              ),
                              ..._filteredAllocations
                                  .where((a) => a['Session is ? '].contains('Current'))
                                  .map((allocation) => _buildGraderRecord(allocation, isClickable: true))
                                  .toList(),
                            ],
                          ),

                        // Previous Allocations
                        if (_filteredAllocations.where((a) => !a['Session is ? '].contains('Current')).isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 16, bottom: 8),
                                child: Text(
                                  'Previous Sessions',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: textSecondary,
                                  ),
                                ),
                              ),
                              ..._filteredAllocations
                                  .where((a) => !a['Session is ? '].contains('Current'))
                                  .map((allocation) => _buildGraderRecord(allocation, isClickable: false))
                                  .toList(),
                            ],
                          ),

                        if (_filteredAllocations.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Text(
                              'No matching records found',
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildGraderRecord(Map<String, dynamic> allocation, {required bool isClickable}) {
    final isCurrentSession = allocation['Session is ? '].contains('Current');
    final statusColor = isCurrentSession ? activeColor : previousColor;
    final feedback = allocation['feedback'] ?? 'No feedback provided';
    final teacher=allocation['teacher_name']??'No Name';

    return Column(
      children: [
        InkWell(
          onTap: isClickable ? () {
            Navigator.push(context, MaterialPageRoute(builder:
                (context) => GraderTaskScreen(teacherName: teacher,graderId:graderId as int)));
          } : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                // Teacher avatar
                CircleAvatar(
                  radius: 24,
                  backgroundImage: allocation['teacher_image'] != null && allocation['teacher_image'].toString().isNotEmpty
                      ? NetworkImage(allocation['teacher_image'])
                      : const AssetImage('assets/user.png') as ImageProvider,
                ),
                const SizedBox(width: 16),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            allocation['teacher_name'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isCurrentSession ? 'CURRENT' : 'PREVIOUS',
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Session: ${allocation['session_name']}',
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
        ),

        // Feedback indicator
        if (!isCurrentSession || feedback != 'Not Added By Instructor')
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Bootstrap.chat_square_text,
                      size: 16,
                      color: textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Feedback',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  feedback == 'Not Added By Instructor'
                      ? 'No feedback provided yet'
                      : feedback,
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

        // Divider line
        const Divider(height: 1, thickness: 0.5, color: Color(0xFFE9ECEF)),
      ],
    ).animate().fadeIn(delay: 80.ms).slideY(
      begin: 0.1,
      end: 0,
      delay: 80.ms,
      duration: 250.ms,
      curve: Curves.easeOutQuad,
    );
  }
}

class SkeletonLoader extends StatelessWidget {
  const SkeletonLoader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 110,
          floating: false,
          pinned: true,
          backgroundColor: _GraderDashboardState.primaryColor,
          automaticallyImplyLeading: false,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              color: _GraderDashboardState.primaryColor,
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: MediaQuery.of(context).padding.top + 8,
                bottom: 12,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 150,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 80,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: _GraderDashboardState.textSecondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 80,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _GraderDashboardState.textSecondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...List.generate(3, (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 120,
                                  height: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: 160,
                                  height: 12,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        height: 1,
                        color: const Color(0xFFE9ECEF),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ),
      ],
    );
  }
}