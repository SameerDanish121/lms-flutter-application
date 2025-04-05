import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import '../../alerts/custom_alerts.dart';
import '../../provider/instructor_provider.dart';
import 'package:lmsv2/api/ApiConfig.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);
  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with TickerProviderStateMixin {
  final Color primaryColor = const Color(0xFF4448FF);
  final Color backgroundColor = const Color(0xFFF5F7FA);
  final Color cardColor = const Color(0xFFE3F2FD);
  final Color textColor = const Color(0xFF263238);
  final Color secondaryTextColor = const Color(0xFF546E7A);
  double _downloadProgress = 0.0;  // Tracks download progress (0.0 to 1.0)
  bool _isDownloading = false;
  bool _isLoading = true;
  List<NotificationModel> _notifications = [];
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _mediaLinkController = TextEditingController();
  String _selectedMediaType = 'link';
  late TabController _tabController;
  int _currentTabIndex = 0;

  // Recipient selection variables
  bool _isBroadcast = false;
  String _recipientType = 'section';
  List<Map<String, dynamic>> _allStudents = [];
  List<Map<String, dynamic>> _allSections = [];
  List<Map<String, dynamic>> _selectedRecipients = [];
  final TextEditingController _recipientSearchController =
      TextEditingController();
  List<Map<String, dynamic>> _filteredRecipients = [];
  bool _isLoadingRecipients = false;
  Future<void> _saveToCustomFolder(String imageUrl) async {
    try {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text('Downloading image...',
      //         style: TextStyle(color: Colors.white)),
      //     backgroundColor: Colors.blue,
      //     duration: Duration(seconds: 2),
      //   ),
      // );
CustomAlert.loading(context, 'Downloading', 'Please Wait .......... !');
      // Create LMS directory if it doesn't exist
      final lmsDir = Directory('/storage/emulated/0/LMS');
      if (!await lmsDir.exists()) {
        await lmsDir.create(recursive: true);
      }

      // Generate filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExtension = imageUrl.split('.').last;
      final filePath = '${lmsDir.path}/image_$timestamp.$fileExtension';

      // Download and save the image
      await Dio().download(
        imageUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
          }
        },
      );
      Navigator.pop(context);
      CustomAlert.success(context, 'Image Saved to Downloads');
    } catch (e) {
      Navigator.pop(context);

     CustomAlert.error(context, 'Failed to save',e.toString());
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Stack(
      alignment: Alignment.center,
      children: [
        TextButton.icon(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
              side: BorderSide(color: Colors.white.withOpacity(0.2)),
            ),),
          onPressed: _isDownloading ? null : onPressed,
          icon: Icon(icon, size: 20),
          label: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (_isDownloading)
          CircularProgressIndicator(
            value: _downloadProgress,
            color: Colors.white,
            strokeWidth: 2,
          ),
      ],
    );
  }
  // Image picker variables
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchNotifications();
      _fetchAllStudents();
      _fetchAllSections();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _mediaLinkController.dispose();
    _recipientSearchController.dispose();
    super.dispose();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final instructorProvider =
          Provider.of<InstructorProvider>(context, listen: false);
      final teacherId = instructorProvider.instructor?.id;

      if (teacherId == null) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Teacher ID not found');
        return;
      }

      final response = await http.get(
        Uri.parse(
            '${ApiConfig.apiBaseUrl}Teachers/get/notifications?teacher_id=$teacherId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['status'] == true && jsonData['data'] != null) {
          setState(() {
            _notifications = List<NotificationModel>.from(
              jsonData['data'].map((x) => NotificationModel.fromJson(x)),
            );
            _isLoading = false;
          });
        } else {
          setState(() {
            _notifications = [];
            _isLoading = false;
          });
        }
      } else {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Failed to load notifications');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error: ${e.toString()}');
    }
  }

  Future<void> _fetchAllStudents() async {
    setState(() => _isLoadingRecipients = true);
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.apiBaseUrl}Dropdown/AllStudentData'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        setState(() {
          _allStudents = jsonData
              .map((item) => {
                    'id': item['id'],
                    'name': item['name'],
                    'regno': item['regno'],
                    'display': item['Format'],
                    'type': 'student'
                  })
              .toList();
          _isLoadingRecipients = false;
        });
      } else {
        setState(() => _isLoadingRecipients = false);
        _showErrorSnackBar('Failed to load students');
      }
    } catch (e) {
      setState(() => _isLoadingRecipients = false);
      _showErrorSnackBar('Failed to load students: ${e.toString()}');
    }
  }

  Future<void> _fetchAllSections() async {
    setState(() => _isLoadingRecipients = true);
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.apiBaseUrl}Dropdown/AllSection'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        setState(() {
          _allSections = jsonData
              .map((item) => {
                    'id': item['id'],
                    'display': item['data'],
                    'type': 'section'
                  })
              .toList();
          _isLoadingRecipients = false;
        });
      } else {
        setState(() => _isLoadingRecipients = false);
        _showErrorSnackBar('Failed to load sections');
      }
    } catch (e) {
      setState(() => _isLoadingRecipients = false);
      _showErrorSnackBar('Failed to load sections: ${e.toString()}');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
          _mediaLinkController.text = image.path;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: ${e.toString()}');
    }
  }

  Future<void> _takePhotoWithCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setState(() {
          _imageFile = File(photo.path);
          _mediaLinkController.text = photo.path;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to take photo: ${e.toString()}');
    }
  }

  void _filterRecipients(String query) {
    final List<Map<String, dynamic>> sourceList =
        _recipientType == 'student' ? _allStudents : _allSections;

    setState(() {
      _filteredRecipients = sourceList.where((recipient) {
        final display = recipient['display'].toString().toLowerCase();
        return display.contains(query.toLowerCase());
      }).toList();
    });
  }

  void _addRecipient(Map<String, dynamic> recipient) {
    if (!_selectedRecipients.any(
        (r) => r['id'] == recipient['id'] && r['type'] == recipient['type'])) {
      setState(() {
        _selectedRecipients.add(recipient);
        _recipientSearchController.clear();
        _filteredRecipients = [];
      });
    }
  }

  void _removeRecipient(Map<String, dynamic> recipient) {
    setState(() {
      _selectedRecipients.removeWhere(
          (r) => r['id'] == recipient['id'] && r['type'] == recipient['type']);
    });
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showConfirmationDialog() {
    final recipientsInfo = _isBroadcast
        ? "All students (Broadcast)"
        : _selectedRecipients.map((r) => r['display']).join(", ");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          "Confirm Notification",
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildConfirmationRow(
                context,
                label: "Title",
                value: _titleController.text,
              ),
              const SizedBox(height: 12),
              _buildConfirmationRow(
                context,
                label: "Description",
                value: _descriptionController.text,
              ),
              if (_mediaLinkController.text.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildConfirmationRow(
                  context,
                  label: "Media",
                  value: _mediaLinkController.text,
                ),
              ],
              const SizedBox(height: 12),
              _buildConfirmationRow(
                context,
                label: "Recipients",
                value: recipientsInfo,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              _sendNotification();
            },
            child: const Text("Send"),
          ),
        ],
      ),
    );
  }

// Helper method to create consistent confirmation rows
  Widget _buildConfirmationRow(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              "$label:",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendNotification() async {
    // Validation (keep existing validation)
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      CustomAlert.error(
          context, 'Validation Error', 'Title and description are required');
      return;
    }

    if (!_isBroadcast && _selectedRecipients.isEmpty) {
      CustomAlert.error(
          context, 'Validation Error', 'Please select at least one recipient');
      return;
    }

    final instructorProvider =
        Provider.of<InstructorProvider>(context, listen: false);
    final teacherId = instructorProvider.instructor?.userId;
    if (teacherId == null) {
      CustomAlert.error(context, 'Error', 'Teacher ID not found');
      return;
    }
    try {
      CustomAlert.loading(context, 'Sending Message ! ', 'Please Wait ..... ');
      // Prepare request data
      final Map<String, dynamic> requestData = {
        'sender': 'Teacher',
        'sender_id': teacherId.toString(),
        'title': _titleController.text,
        'description': _descriptionController.text
      };
      if (_isBroadcast) {
        requestData['broadcast'] = 'true';
      }
      // Media handling
      if (_selectedMediaType == 'image' && _imageFile != null) {
        requestData['image'] = _imageFile!;
      } else if (_selectedMediaType == 'link' &&
          _mediaLinkController.text.isNotEmpty) {
        requestData['image'] = _mediaLinkController.text;
      }

      if (_isBroadcast) {
        final response = await _sendNotificationRequest(requestData);
        Navigator.pop(context);
        _handleResponse(response);
      } else {
        // Handle individual recipients
        bool allSuccess = true;
        String errorMessages = '';

        for (final recipient in _selectedRecipients) {
          final recipientData = Map<String, dynamic>.from(requestData);

          if (recipient['type'] == 'section') {
            recipientData['Student_Section'] = recipient['id'].toString();
          } else {
            recipientData['Student_id'] = recipient['id'].toString();
          }

          try {
            final response = await _sendNotificationRequest(recipientData);
            if (!response['success']) {
              allSuccess = false;
              errorMessages +=
                  '❌ ${recipient['display']}: ${response['message']}\n';
            }
          } catch (e) {
            allSuccess = false;
            errorMessages += '❌ ${recipient['display']}: ${e.toString()}\n';
          }
        }

        // Show results
        if (allSuccess) {
          Navigator.pop(context);
          CustomAlert.success(context, 'All notifications sent successfully!');
        } else {
          Navigator.pop(context);
          CustomAlert.error(
            context,
            'Partial Success',
            'Some notifications failed ',
          );
        }
      }

      // Clear form
      _clearForm();
    } catch (e) {
      Navigator.pop(context);
      CustomAlert.error(
        context,
        'Error',
        'Failed to send notification , Please Try Again ',
      );
    }
  }

  void _clearForm() {
    setState(() {
      _titleController.clear();
      _descriptionController.clear();
      _mediaLinkController.clear();
      _selectedRecipients.clear();
      _isBroadcast = false;
      _imageFile = null;
    });
    _fetchNotifications();
  }

  Future<Map<String, dynamic>> _sendNotificationRequest(
      Map<String, dynamic> data) async {
    try {
      debugPrint('\n📨 Preparing API request with data:');
      data.forEach((key, value) => debugPrint('   $key: ${value.toString()}'));

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.apiBaseUrl}student/notification'),
      );
      request.headers['Accept'] = 'application/json';
      request.fields.addAll({
        'title': data['title'],
        'description': data['description'],
        'sender': data['sender'],
        'sender_id': data['sender_id']
      });
      if (data.containsKey('broadcast')) {
        request.fields['Broadcast'] = data['broadcast'];
      }
      if (data.containsKey('Student_id')) {
        request.fields['Student_id'] = data['Student_id'].toString();
      }
      if (data.containsKey('Student_Section')) {
        request.fields['Student_Section'] = data['Student_Section'].toString();
      }
      if (data['image'] is File) {
        request.files.add(await http.MultipartFile.fromPath(
          'image',
          (data['image'] as File).path,
          contentType: MediaType('image', 'jpeg'),
        ));
      } else if (data['image'] is String && data['image'].isNotEmpty) {
        request.fields['image'] = data['image'];
      }
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(responseBody);
      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'message': jsonResponse['message'] ?? 'No message',
        'response': jsonResponse,
      };
    } catch (e) {
      debugPrint('❌ Request failed: $e');
      return {
        'success': false,
        'message': 'Request failed: ${e.toString()}',
        'error': e.toString(),
      };
    }
  }

  void _handleResponse(Map<String, dynamic> response) {
    if (response['success'] == true) {
      CustomAlert.success(
        context,
        response['message'] ?? 'Notification sent successfully!',
      );
    } else {
      final statusCode = response['statusCode'] ?? 'Unknown';
      final errorMessage = response['message'] ?? 'No error message';
      final serverResponse = response['response']?.toString() ?? 'No response';

      CustomAlert.error(
        context,
        'Failed (Status $statusCode)',
        '$errorMessage\n\n'
            'Server Response:\n$serverResponse',
      );
    }
  }

  String _formatDate(String dateString) {
    try {
      final DateTime date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
    } catch (e) {
      return dateString;
    }
  }

  Future<void> _launchUrl(String url) async {
    if (url.isEmpty) return;
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showErrorSnackBar('Could not launch URL: $url');
      }
    } catch (e) {
      _showErrorSnackBar('Error launching URL: ${e.toString()}');
    }
  }

  void _showImageFullscreen(String imageUrl) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(0),
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.9),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(6),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 28),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: InteractiveViewer(
                          panEnabled: true,
                          minScale: 0.1,
                          maxScale: 5.0,
                          child: Hero(
                            tag: imageUrl,
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.contain,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: progress.expectedTotalBytes != null
                                        ? progress.cumulativeBytesLoaded /
                                            progress.expectedTotalBytes!
                                        : null,
                                    color: theme.primaryColor,
                                    strokeWidth: 2,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[900],
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.error_outline,
                                            size: 40,
                                            color: theme.colorScheme.error),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Failed to load image',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            color: theme.colorScheme.error,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SafeArea(
                    minimum: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildActionButton(
                          icon: Icons.download_rounded,
                          label: 'Save',
                          onPressed:() async {
                            await _saveToCustomFolder(imageUrl);
                          },
                        ),
                        const SizedBox(width: 20),
                        _buildActionButton(
                          icon: Icons.share_rounded,
                          label: 'Share',
                          onPressed: () async {
                            try {
                              final tempDir = await getTemporaryDirectory();
                              final timestamp =
                                  DateTime.now().millisecondsSinceEpoch;
                              final file =
                                  File('${tempDir.path}/image_$timestamp.jpg');

                              await Dio().download(imageUrl, file.path);

                              await Share.shareXFiles(
                                [XFile(file.path, mimeType: 'image/jpeg')],
                                text: 'Shared image from LMS',
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Share failed: ${e.toString()}',
                                      style: TextStyle(color: Colors.white)),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: Column(
        children: [
          // Tab Bar
          Container(
            color: primaryColor,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withOpacity(0.7),
              tabs: const [
                Tab(text: 'Your Notifications'),
                Tab(text: 'Send Notification'),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNotificationsTab(),
                _buildSendNotificationTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsTab() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchNotifications,
              child: _notifications.isEmpty
                  ? Center(
                      child: Text(
                        'No notifications available',
                        style: TextStyle(color: secondaryTextColor),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(top: 8),
                      itemCount: _notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, index) =>
                          _buildNotificationCard(_notifications[index]),
                    ),
            ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return Card(
      elevation: 0,
      color: cardColor,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: primaryColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with avatar and sender info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar with fallback
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryColor.withOpacity(0.1),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: notification.senderImage != null
                      ? ClipOval(
                          child: Image.network(
                            notification.senderImage!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildAvatarFallback(notification),
                          ),
                        )
                      : _buildAvatarFallback(notification),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.senderName,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: textColor,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Text(
                            _formatDate(notification.notificationDate),
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        notification.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: textColor.withOpacity(0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Notification message
            Text(
              notification.description,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),

            // Media preview (if exists)
            if (notification.media.isNotEmpty) _buildMediaPreview(notification),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarFallback(NotificationModel notification) {
    return Center(
      child: Text(
        notification.senderName.isNotEmpty
            ? notification.senderName[0].toUpperCase()
            : '?',
        style: TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildMediaPreview(NotificationModel notification) {
    final double imageAspectRatio = 16 / 9; // Standard widescreen aspect ratio

    if (notification.mediaType == 'image') {
      return GestureDetector(
        onTap: () => _showImageFullscreen(notification.media),
        child: Container(
          width: double.infinity, // Takes full width of card
          constraints: BoxConstraints(
            maxHeight: 200, // Maximum height for images
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[100],
          ),
          child: AspectRatio(
            aspectRatio: imageAspectRatio,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                notification.media,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: progress.expectedTotalBytes != null
                          ? progress.cumulativeBytesLoaded /
                              progress.expectedTotalBytes!
                          : null,
                      color: primaryColor,
                      strokeWidth: 2,
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image,
                          size: 32, color: secondaryTextColor),
                      const SizedBox(height: 4),
                      Text(
                        'Could not load image',
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      // For non-image media (links)
      return InkWell(
        onTap: () => _launchUrl(notification.media),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: primaryColor.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.link,
                  size: 16,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attachment Link',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: primaryColor,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notification.media,
                      style: TextStyle(
                        color: textColor.withOpacity(0.7),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: primaryColor.withOpacity(0.5),
                size: 20,
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildSendNotificationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Removed animated header
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey.shade200,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16), // Reduced padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Field
                    _buildFancyTextField(
                      controller: _titleController,
                      label: "Notification Title",
                      icon: Icons.title,
                    ),
                    const SizedBox(height: 12), // Reduced spacing

                    // Description Field
                    _buildFancyTextField(
                      controller: _descriptionController,
                      label: "Description",
                      icon: Icons.description,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),

                    // Media Type Selection
                    _buildMediaTypeSelector(),
                    const SizedBox(height: 12),

                    // Media Input (Conditional)
                    _buildMediaInputSection(),
                    const SizedBox(height: 16),

                    // Broadcast Toggle
                    _buildBroadcastToggle(),
                    const SizedBox(height: 12),

                    // Recipient Selection (Conditional)
                    if (!_isBroadcast) ...[
                      _buildRecipientSelector(),
                      const SizedBox(height: 12),
                    ],

                    // Send Button
                    _buildSendButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

// Existing other methods remain the same, with minor design tweaks

// Enhance the fancy text field
  Widget _buildFancyTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    void Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      onChanged: onChanged,
      style: TextStyle(
        color: textColor,
        fontSize: 14, // Slightly smaller font
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: secondaryTextColor,
          fontSize: 12, // Smaller label
        ),
        prefixIcon: Icon(icon, color: primaryColor, size: 20),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: primaryColor,
            width: 1.5,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: maxLines > 1 ? 12 : 0,
        ),
      ),
    );
  }

// Simplified Media Type Selector
  Widget _buildMediaTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Media Type",
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        ToggleButtons(
          isSelected: [
            _selectedMediaType == 'link',
            _selectedMediaType == 'image',
          ],
          onPressed: (index) {
            setState(() {
              _selectedMediaType = index == 0 ? 'link' : 'image';
              _mediaLinkController.clear();
              _imageFile = null;
            });
          },
          borderRadius: BorderRadius.circular(10),
          selectedColor: Colors.white,
          fillColor: primaryColor.withOpacity(0.8),
          color: primaryColor,
          constraints: const BoxConstraints(
            minHeight: 40,
            minWidth: 90,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.link, size: 16),
                  const SizedBox(width: 4),
                  Text("Link", style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.image, size: 16),
                  const SizedBox(width: 4),
                  Text("Image", style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMediaInputSection() {
    if (_selectedMediaType == 'link') {
      return _buildFancyTextField(
        controller: _mediaLinkController,
        label: "Link URL",
        icon: Icons.link,
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Select Image",
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMediaOptionButton(
                  onTap: _pickImageFromGallery,
                  icon: Icons.photo_library,
                  label: "Gallery",
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMediaOptionButton(
                  onTap: _takePhotoWithCamera,
                  icon: Icons.camera_alt,
                  label: "Camera",
                ),
              ),
            ],
          ),
          if (_imageFile != null) ...[
            const SizedBox(height: 12),
            Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                image: DecorationImage(
                  image: FileImage(_imageFile!),
                  fit: BoxFit.cover,
                ),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _imageFile = null;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      );
    }
  }

// New helper method for media option buttons
  Widget _buildMediaOptionButton({
    required VoidCallback onTap,
    required IconData icon,
    required String label,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: primaryColor,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBroadcastToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.cast, color: primaryColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Broadcast to all students",
              style: TextStyle(
                color: textColor,
                fontSize: 14,
              ),
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: _isBroadcast,
              onChanged: (value) {
                setState(() {
                  _isBroadcast = value;
                  if (_isBroadcast) {
                    _selectedRecipients.clear();
                  }
                });
              },
              activeColor: primaryColor,
              activeTrackColor: primaryColor.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipientSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Select Recipients",
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.grey.shade200,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.group, color: primaryColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _recipientType,
                    icon: const Icon(Icons.arrow_drop_down),
                    style: TextStyle(color: textColor, fontSize: 14),
                    onChanged: (String? newValue) {
                      setState(() {
                        _recipientType = newValue!;
                        _filteredRecipients = [];
                        _recipientSearchController.clear();
                      });
                    },
                    items: <String>['section', 'student']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value == 'section' ? 'By Sections' : 'By Students',
                          style: TextStyle(fontSize: 14),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _buildFancyTextField(
          controller: _recipientSearchController,
          label:
              "Search ${_recipientType == 'student' ? 'students' : 'sections'}",
          icon: Icons.search,
          onChanged: _filterRecipients,
        ),
        if (_isLoadingRecipients)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_filteredRecipients.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            constraints: const BoxConstraints(maxHeight: 180),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.grey.shade200,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredRecipients.length,
              itemBuilder: (context, index) {
                final recipient = _filteredRecipients[index];
                return ListTile(
                  title: Text(
                    recipient['display'],
                    style: TextStyle(fontSize: 14),
                  ),
                  leading: Icon(
                    _recipientType == 'student' ? Icons.person : Icons.class_,
                    color: primaryColor,
                    size: 20,
                  ),
                  onTap: () => _addRecipient(recipient),
                );
              },
            ),
          ),
        ],
        if (_selectedRecipients.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _selectedRecipients.map((recipient) {
              return Chip(
                label: Text(
                  recipient['display'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
                avatar: Icon(
                  recipient['type'] == 'student' ? Icons.person : Icons.class_,
                  size: 14,
                  color: Colors.white,
                ),
                backgroundColor: primaryColor,
                deleteIcon: const Icon(
                  Icons.close,
                  size: 14,
                  color: Colors.white,
                ),
                onDeleted: () => _removeRecipient(recipient),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildSendButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          if (_titleController.text.isEmpty ||
              _descriptionController.text.isEmpty) {
            CustomAlert.warning(context, 'Title and description are required');
            return;
          }
          if (!_isBroadcast && _selectedRecipients.isEmpty) {
            CustomAlert.warning(
                context, 'Please select at least one recipient');
            return;
          }
          _showConfirmationDialog();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 2,
          shadowColor: primaryColor.withOpacity(0.3),
        ),
        child: Text(
          'Send Notification',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class NotificationModel {
  final int id;
  final String title;
  final String description;
  final String url;
  final String notificationDate;
  final String sender;
  final String senderName;
  final String? senderImage;
  final String mediaType;
  final String media;

  NotificationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.url,
    required this.notificationDate,
    required this.sender,
    required this.senderName,
    this.senderImage,
    required this.mediaType,
    required this.media,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      url: json['url'],
      notificationDate: json['notification_date'],
      sender: json['sender'],
      senderName: json['sender_name'],
      senderImage: json['sender_image'],
      mediaType: json['media_type'],
      media: json['media'],
    );
  }
}
