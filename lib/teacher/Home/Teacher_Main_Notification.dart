import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import '../../Model/Comman Model.dart';
import '../../provider/instructor_provider.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}
class _NotificationScreenState extends State<NotificationScreen> with TickerProviderStateMixin {
  bool _isLoading = true;
  List<NotificationModel> _notifications = [];
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _mediaLinkController = TextEditingController();
  String _selectedMediaType = 'link';
  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    // Initialize the tab controller in initState
    _tabController = TabController(length: 2, vsync: this);
    // Add listener to update current tab index
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
    // Fetch notifications after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchNotifications();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _mediaLinkController.dispose();
    super.dispose();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final instructorProvider = Provider.of<InstructorProvider>(context, listen: false);
      final teacherId = instructorProvider.instructor?.id;

      if (teacherId == null) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Teacher ID not found');
        return;
      }

      final response = await http.get(
        Uri.parse('http://192.168.0.108:8000/api/Teachers/get/notifications?teacher_id=$teacherId'),
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
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to load notifications');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error: ${e.toString()}');
    }
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

  Future<void> _sendNotification() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      _showErrorSnackBar('Title and description are required');
      return;
    }

    try {
      final instructorProvider = Provider.of<InstructorProvider>(context, listen: false);
      final teacherId = instructorProvider.instructor?.id;

      if (teacherId == null) {
        _showErrorSnackBar('Teacher ID not found');
        return;
      }

      // Here you would implement the API call to send a notification
      // Example:
      // final response = await http.post(
      //   Uri.parse('http://192.168.0.108:8000/api/Teachers/send/notification'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: jsonEncode({
      //     'teacher_id': teacherId,
      //     'title': _titleController.text,
      //     'description': _descriptionController.text,
      //     'media_type': _selectedMediaType,
      //     'media': _mediaLinkController.text,
      //   }),
      // );

      // Show success message (replace with actual API response handling)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Notification sent successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      // Clear form fields
      _titleController.clear();
      _descriptionController.clear();
      _mediaLinkController.clear();

      // Refresh notifications list
      _fetchNotifications();
    } catch (e) {
      _showErrorSnackBar('Error sending notification: ${e.toString()}');
    }
  }

  IconData _getNotificationIcon(String mediaType) {
    switch (mediaType) {
      case 'link':
        return Icons.link;
      case 'image':
        return Icons.image;
      default:
        return Icons.notifications;
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

  // Launch URL in browser
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

  // Show image in fullscreen
  void _showImageFullscreen(String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: const Text('Image Preview'),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Flexible(
                child: InteractiveViewer(
                  minScale: 0.1,
                  maxScale: 3.0,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Text('Error loading image',
                            style: TextStyle(color: Colors.red)),
                      );
                    },
                  ),
                ),
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
      color: const Color(0xFF4448FF),
      child: Column(
        children: [
          // Tab Bar
          TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            tabs: const [
              Tab(text: 'Your Notifications'),
              Tab(text: 'Send Notification'),
            ],
          ),

          // Tab Content
          Expanded(
            child: _currentTabIndex == 0
                ? _buildNotificationsTab()
                : _buildSendNotificationTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsTab() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _notifications.isEmpty
            ? const Center(child: Text('No notifications found'))
            : RefreshIndicator(
          onRefresh: _fetchNotifications,
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: _notifications.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final notification = _notifications[index];
              return _buildNotificationItem(notification);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sender Image or Default Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: notification.senderImage != null
                ? NetworkImage(notification.senderImage!)
                : null,
            child: notification.senderImage == null
                ? Text(
              notification.senderName.isNotEmpty
                  ? notification.senderName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4448FF),
              ),
            )
                : null,
          ),

          const SizedBox(width: 12),

          // Notification Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Timestamp
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _formatDate(notification.notificationDate),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // Sender Name
                Text(
                  notification.senderName,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 4),

                // Description
                Text(
                  notification.description,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 8),

                // Display media based on type
                if (notification.mediaType == 'image' && notification.media.isNotEmpty)
                  GestureDetector(
                    onTap: () => _showImageFullscreen(notification.media),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey.shade200,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              notification.media,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.broken_image, size: 32),
                                      const SizedBox(height: 8),
                                      Text('Unable to load image',
                                          style: TextStyle(color: Colors.grey.shade600)),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap to view image',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Media Link Indicator
                if (notification.mediaType == 'link' && notification.media.isNotEmpty)
                  InkWell(
                    onTap: () => _launchUrl(notification.media),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.link,
                            size: 18,
                            color: Colors.blue.shade800,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              notification.media,
                              style: TextStyle(
                                color: Colors.blue.shade800,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSendNotificationTab() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Media Type Selection
                const Text(
                  'Media Type:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Row(
                  children: [
                    Radio(
                      value: 'link',
                      groupValue: _selectedMediaType,
                      onChanged: (value) {
                        setState(() {
                          _selectedMediaType = value.toString();
                        });
                      },
                      activeColor: const Color(0xFF4448FF),
                    ),
                    const Text('Link'),
                    const SizedBox(width: 16),
                    Radio(
                      value: 'image',
                      groupValue: _selectedMediaType,
                      onChanged: (value) {
                        setState(() {
                          _selectedMediaType = value.toString();
                        });
                      },
                      activeColor: const Color(0xFF4448FF),
                    ),
                    const Text('Image'),
                  ],
                ),

                TextField(
                  controller: _mediaLinkController,
                  decoration: InputDecoration(
                    labelText: _selectedMediaType == 'link' ? 'URL' : 'Image URL',
                    hintText: _selectedMediaType == 'link'
                        ? 'https://example.com'
                        : 'https://example.com/image.jpg',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),

                // Preview section for image
                if (_selectedMediaType == 'image' && _mediaLinkController.text.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      const Text('Preview:',
                          style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade200,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _mediaLinkController.text,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.broken_image, size: 32),
                                    const SizedBox(height: 8),
                                    Text('Invalid image URL',
                                        style: TextStyle(color: Colors.grey.shade600)),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 24),

                // Send Button
                ElevatedButton(
                  onPressed: _sendNotification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4448FF),
                    minimumSize: const Size(double.infinity, 46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Send Notification',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}