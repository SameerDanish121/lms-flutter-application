import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lmsv2/api/ApiConfig.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../Theme/theme.dart';
import '../../alerts/custom_alerts.dart';
import '../../provider/instructor_provider.dart';
class GraderInfoScreen extends StatefulWidget {
  const GraderInfoScreen({super.key});
  @override
  _GraderInfoScreenState createState() => _GraderInfoScreenState();
}

class _GraderInfoScreenState extends State<GraderInfoScreen> {
  final String _apiUrl = "${ApiConfig.apiBaseUrl}Teachers/teacher-graders";
  final String _feedbackApiUrl = "${ApiConfig.apiBaseUrl}Teachers/add-or-update-feedbacks";
  List<dynamic> _activeGraders = [];
  Map<String, dynamic> _previousGraders = {};
  bool _isLoading = true;
  String _currentSession = 'Spring-2025';
  String _searchQuery = '';
  String? _selectedSession = 'All';
  final TextEditingController _feedbackController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchGraderData();
  }

  Future<void> _fetchGraderData() async {
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
          _activeGraders = data['active_graders'] ?? [];
          _previousGraders = data['previous_graders'] ?? {};
          _isLoading = false;
        });
      } else {
        _showError('Failed to load grader data');
      }
    } catch (e) {
      _showError('Error: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _handleFeedbackAction(Map<String, dynamic> grader, String? feedback) async {
    await CustomAlert.performWithLoading(
      context: context,
      loadingText: feedback == null ? 'Removing feedback...' : 'Saving feedback...',
      task: () async {
        try {
          final response = await http.post(
            Uri.parse(_feedbackApiUrl),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'teacher_grader_id': grader['teacher_grader_id'],
              'feedback': feedback,
            }),
          );

          if (response.statusCode == 200) {
            await _fetchGraderData();
            return true;
          }
          throw Exception('Server responded with status ${response.statusCode}');
        } catch (e) {
          throw Exception('Failed to process request: $e');
        }
      },
      successMessage: feedback == null
          ? 'Feedback removed successfully'
          : 'Feedback saved successfully',
      errorMessage: feedback == null
          ? 'Failed to remove feedback'
          : 'Failed to save feedback',
    );
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
            'Your Graders',
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
                  _buildCurrentGraders(),
                  _buildPreviousGraders(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentGraders() {
    final filtered = _activeGraders.where((grader) =>
    grader['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
        grader['RegNo'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (grader['type']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
    ).toList();

    return RefreshIndicator(
      onRefresh: _fetchGraderData,
      child: Column(
        children: [
          _buildCurrentSessionCard(),
          const SizedBox(height: 8),
          _buildSearchField('Search current graders...'),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...filtered.map((grader) => _buildGraderCard(grader, true)).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviousGraders() {
    final sessions = _previousGraders.keys.toList();
    final allGraders = _selectedSession == 'All'
        ? _previousGraders
        : {_selectedSession!: _previousGraders[_selectedSession] ?? []};

    return RefreshIndicator(
      onRefresh: _fetchGraderData,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _buildSessionDropdown(),
          ),
          _buildSearchField('Search previous graders...'),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final session in allGraders.keys)
                  ..._buildSessionGroup(session, allGraders[session]!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSessionGroup(String session, List<dynamic> graders) {
    final filtered = graders.where((grader) =>
    grader['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
        grader['RegNo'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (grader['type']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
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
      ...filtered.map((grader) => _buildGraderCard(grader, false)),
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
                '${_activeGraders.length} Graders',
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
    final sessions = ['All', ..._previousGraders.keys.toList()];
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

  Widget _buildGraderCard(Map<String, dynamic> grader, bool isCurrent) {
    return Card(
      color: AppTheme.cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                backgroundImage: grader['image'] != null
                    ? NetworkImage(grader['image'])
                    : null,
                child: grader['image'] == null
                    ? const Icon(Icons.person, size: 18, color: AppTheme.iconColor)
                    : null,
              ),
              title: Text(
                grader['name'],
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textColor,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    grader['RegNo'],
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Type: ${grader['type'] ?? 'N/A'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.secondaryTextColor,
                    ),
                  ),
                  if (isCurrent) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Section: ${grader['section']}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.secondaryTextColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (grader['feedback'] != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Feedback:',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        grader['feedback'],
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: grader['feedback'] == null
                            ? Colors.green.withOpacity(0.1)
                            : Colors.blue.withOpacity(0.1),
                        side: BorderSide(
                            color: grader['feedback'] == null ? Colors.green : Colors.blue),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _showFeedbackBottomSheet(grader),
                      child: Text(
                        grader['feedback'] == null ? 'Add Feedback' : 'Update Feedback',
                        style: TextStyle(
                          color: grader['feedback'] == null ? Colors.green : Colors.blue,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  if (grader['feedback'] != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.1),
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => _handleFeedbackAction(grader, null),
                        child: const Text(
                          'Remove Feedback',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFeedbackBottomSheet(Map<String, dynamic> grader) {
    _feedbackController.text = grader['feedback'] ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        grader['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textColor,
                        ),
                      ),
                      Text(
                        'Session: ${grader['session'] ?? _currentSession}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _feedbackController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Feedback',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppTheme.cardColor,
                        side: BorderSide(color: AppTheme.primaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: AppTheme.primaryColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () async {
                        final feedback = _feedbackController.text.trim();
                        Navigator.pop(context);
                        await _handleFeedbackAction(grader, feedback);
                      },
                      child: const Text(
                        'Save',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }
}