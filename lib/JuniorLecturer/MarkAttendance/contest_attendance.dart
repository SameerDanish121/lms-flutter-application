import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:lmsv2/api/ApiConfig.dart';
import 'package:provider/provider.dart';
import '../../Theme/theme.dart';
import '../../alerts/custom_alerts.dart';
import '../../provider/instructor_provider.dart';
class JuniorContestAttendanceScreen extends StatefulWidget {
  const JuniorContestAttendanceScreen({super.key});

  @override
  _JuniorContestAttendanceScreenState createState() =>
      _JuniorContestAttendanceScreenState();
}
class _JuniorContestAttendanceScreenState extends State<JuniorContestAttendanceScreen> {

  List<dynamic> _contestedAttendances = [];
  bool _isLoading = true;
  bool _sortAscending = true;
  String _searchQuery = '';
  final String _apiUrl = "${ApiConfig.apiBaseUrl}JuniorLec/contest-list";

  @override
  void initState() {
    super.initState();
    _fetchContestedAttendances();
  }

  Future<void> _fetchContestedAttendances() async {
    final instructorProvider = Provider.of<InstructorProvider>(context, listen: false);
    final teacherId = instructorProvider.instructor?.id;
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('$_apiUrl?jl_id=$teacherId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _contestedAttendances = data['Student Contested Attendace'] ?? [];
          _isLoading = false;
        });
      } else {
        _showError('Failed to load data');
      }
    } catch (e) {
      _showError('Error: $e');
    }
    setState(() => _isLoading = false);
  }

  void _toggleSortOrder() {
    setState(() {
      _sortAscending = !_sortAscending;
      _contestedAttendances.sort((a, b) => _sortAscending
          ? DateTime.parse(a['Date & Time'])
          .compareTo(DateTime.parse(b['Date & Time']))
          : DateTime.parse(b['Date & Time'])
          .compareTo(DateTime.parse(a['Date & Time'])));
    });
  }

  List<dynamic> get _filteredAttendances {
    return _contestedAttendances.where((attendance) {
      final name = attendance['Student Name'].toString().toLowerCase();
      final regNo = attendance['Student Reg NO'].toString().toLowerCase();
      final course = attendance['Course'].toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) ||
          regNo.contains(_searchQuery.toLowerCase()) ||
          course.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _handleAction(int contestedId, String action) async {
    final verification = action == 'Accept' ? 'Accepted' : 'Rejected';
    final confirmed = await CustomAlert.confirm(
      context,
      'You are sure about $verification the attendance request?',
    );
    if (!confirmed) return;
    CustomAlert.loading(context, 'Processing Approval fo Attendance Contest', 'Please Wait .......');
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.apiBaseUrl}Teachers/process-contest'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'verification': verification,
          'contest_id': contestedId,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        var message=responseData['message'].toString();
        Navigator.pop(context);
        CustomAlert.success(context, 'The Message Has Been Sended to User : ${message}');
        await _fetchContestedAttendances();
        return;
      }
      Navigator.pop(context);
      CustomAlert.error(context, 'UnKnown Error', 'Server responded with status ${response.statusCode}');
      return ;
    } catch (e) {
      Navigator.pop(context);
      CustomAlert.error(context, 'Unknown Error','Failed to process request: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contested Attendances',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              DateFormat('MMM dd, yyyy').format(DateTime.now()),
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.2),
      ),
      body: Column(
        children: [
          // Total Requests Card
          _buildTotalRequestsCard(),
          // Search and Sort Row
          _buildSearchSortRow(),
          // Attendance List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchContestedAttendances,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredAttendances.isEmpty
                  ? const Center(
                  child: Text('No Contest has been submitted'))
                  : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _filteredAttendances.length,
                itemBuilder: (context, index) {
                  final contest = _filteredAttendances[index];
                  return _buildAttendanceCard(contest);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRequestsCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Total Requests:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.textColor,
            ),
          ),
          Text(
            _contestedAttendances.length.toString(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSortRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTheme.backgroundColor,
                hintText: 'Search by name, reg no or course...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.iconColor),
                suffixIcon: IconButton(
                  icon: Icon(
                    _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                    color: AppTheme.primaryColor,
                  ),
                  onPressed: _toggleSortOrder,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(Map<String, dynamic> contest) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: AppTheme.primaryColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppTheme.dividerColor.withOpacity(0.2))),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Info Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Student Image
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                    image: contest['Image'] != null
                        ? DecorationImage(
                      image: NetworkImage(contest['Image']),
                      fit: BoxFit.cover,
                    )
                        : null,
                  ),
                  child: contest['Image'] == null
                      ? const Icon(Icons.person,
                      size: 30, color: AppTheme.iconColor)
                      : null,
                ),
                const SizedBox(width: 16),
                // Student Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contest['Student Name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        contest['Student Reg NO'],
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status Chip
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(contest['Status']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _getStatusColor(contest['Status'])
                            .withOpacity(0.3)),
                  ),
                  child: Text(
                    contest['Status'],
                    style: TextStyle(
                      color: _getStatusColor(contest['Status']),
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Details Section
            _buildDetailRow(
                Icons.calendar_today,
                'Date & Time',
                DateFormat('MMM dd, yyyy - hh:mm a')
                    .format(DateTime.parse(contest['Date & Time']))),
            _buildDetailRow(Icons.location_on, 'Venue', contest['Venue']),
            _buildDetailRow(Icons.school, 'Course', contest['Course']),
            _buildDetailRow(Icons.class_, 'Section', contest['Section']),
            const SizedBox(height: 16),
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.green.withOpacity(0.1),
                    side: BorderSide(color: Colors.green),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                  ),
                  onPressed: () =>
                      _handleAction(contest['contested_id'], 'Accept'),
                  child: const Text('Accept',
                      style: TextStyle(color: Colors.green)),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.1),
                    side: BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                  ),
                  onPressed: () =>
                      _handleAction(contest['contested_id'], 'Reject'),
                  child:
                  const Text('Reject', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.iconColor),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.secondaryTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return AppTheme.primaryColor;
    }
  }
}
