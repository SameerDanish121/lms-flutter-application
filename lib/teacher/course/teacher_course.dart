import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lmsv2/api/ApiConfig.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../Theme/theme.dart';
import '../../alerts/custom_alerts.dart';
import '../../provider/instructor_provider.dart';

class TeacherCoursesScreen extends StatefulWidget {
  const TeacherCoursesScreen({super.key});

  @override
  _TeacherCoursesScreenState createState() => _TeacherCoursesScreenState();
}

class _TeacherCoursesScreenState extends State<TeacherCoursesScreen> {
  final String _apiUrl = "${ApiConfig.apiBaseUrl}Teachers/your-courses";
  List<dynamic> _activeCourses = [];
  Map<String, dynamic> _previousCourses = {};
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedSession = 'All';
  String _currentSession = 'Spring-2025';
  @override
  void initState() {
    super.initState();
    _fetchCoursesData();
  }

  Future<void> _fetchCoursesData() async {
    final instructorProvider = Provider.of<InstructorProvider>(context, listen: false);
    final teacherId = instructorProvider.instructor?.id;

    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('$_apiUrl?teacher_id=$teacherId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _activeCourses = data['data']['active_courses'] ?? [];
          _previousCourses = data['data']['previous_courses'] ?? {};
          _currentSession = _activeCourses.isNotEmpty
              ? _activeCourses.first['session_name'] ?? 'Spring-2025'
              : 'Spring-2025';
          _selectedSession = 'All';
          _isLoading = false;
        });
      } else {
        _showError('Failed to load courses data');
      }
    } catch (e) {
      _showError('Error: $e');
    }
    setState(() => _isLoading = false);
  }

  void _showError(String message) {
    CustomAlert.error(context, 'Error', message);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Your Courses',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor: AppTheme.primaryColor,
          bottom: TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.7),
            tabs: const [
              Tab(text: 'Current'),
              Tab(text: 'Previous'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                children: [
                  _buildCurrentCourses(),
                  _buildPreviousCourses(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentCourses() {
    final filtered = _activeCourses.where((course) =>
    course['course_name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
        course['section_name'].toString().toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    return RefreshIndicator(
      onRefresh: _fetchCoursesData,
      child: Column(
        children: [
          _buildCurrentSessionCard(),
          const SizedBox(height: 8),
          _buildSearchField('Search current courses...'),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...filtered.map((course) => _buildCourseCard(course, true)).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviousCourses() {
    final allCourses = _selectedSession == 'All'
        ? _previousCourses
        : {_selectedSession!: _previousCourses[_selectedSession] ?? []};

    return RefreshIndicator(
      onRefresh: _fetchCoursesData,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _buildSessionDropdown(),
          ),
          _buildSearchField('Search previous courses...'),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final session in allCourses.keys)
                  ..._buildSessionGroup(session, allCourses[session]!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSessionGroup(String session, List<dynamic> courses) {
    final filtered = courses.where((course) =>
    course['course_name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
        course['section_name'].toString().toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    if (filtered.isEmpty) return [];

    return [
      Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(
          session,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
      ...filtered.map((course) => _buildCourseCard(course, false)),
    ];
  }

  Widget _buildCurrentSessionCard() {
    return Card(
      color: AppTheme.cardColor,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, size: 18, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Session:',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.secondaryTextColor,
                      ),
                    ),
                    Text(
                      _currentSession,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Chip(
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              label: Text(
                '${_activeCourses.length} Courses',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionDropdown() {
    final sessions = ['All', ..._previousCourses.keys.toList()];
    return DropdownButtonFormField<String>(
      value: _selectedSession,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppTheme.backgroundColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        suffixIcon: const Icon(Icons.arrow_drop_down, color: AppTheme.iconColor),
      ),
      items: sessions.map((session) => DropdownMenuItem(
        value: session,
        child: Text(
          session,
          style: const TextStyle(fontSize: 14),
        ),
      )).toList(),
      onChanged: (value) => setState(() => _selectedSession = value),
    );
  }

  Widget _buildSearchField(String hint) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        decoration: InputDecoration(
          filled: true,
          fillColor: AppTheme.backgroundColor,
          hintText: hint,
          prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.iconColor),
          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course, bool isCurrent) {
    return Card(
      color: AppTheme.cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    course['course_name'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textColor,
                    ),
                  ),
                ),
                Chip(
                  backgroundColor: course['lab'] == 'Yes'
                      ? Colors.green.withOpacity(0.1)
                      : Colors.blue.withOpacity(0.1),
                  label: Text(
                    course['lab'] == 'Yes' ? 'Lab' : 'Theory',
                    style: TextStyle(
                      color: course['lab'] == 'Yes' ? Colors.green : Colors.blue,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildCourseDetailRow(Icons.code, 'Code: ${course['course_code']}'),
            _buildCourseDetailRow(Icons.school, 'Type: ${course['course_type']}'),
            _buildCourseDetailRow(Icons.credit_score, 'Credits: ${course['credit_hours']}'),
            _buildCourseDetailRow(Icons.class_, 'Section: ${course['section_name']}'),
            _buildCourseDetailRow(Icons.people, 'Enrollments: ${course['total_enrollments']}'),
            if (course['lab'] == 'Yes' && course['junior_name'] != 'N/A') ...[
              const SizedBox(height: 8),
              _buildJuniorLecturerRow(course),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  side: BorderSide(color: AppTheme.primaryColor),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  // Navigate to course details
                },
                child: const Text(
                  'View Details',
                  style: TextStyle(color: AppTheme.primaryColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.iconColor),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJuniorLecturerRow(Map<String, dynamic> course) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            backgroundImage: course['junior_image'] != null
                ? NetworkImage(course['junior_image'])
                : null,
            child: course['junior_image'] == null
                ? const Icon(Icons.person, size: 14, color: AppTheme.iconColor)
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            'Junior: ${course['junior_name']}',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textColor,
            ),
          ),
        ],
      ),
    );
  }
}