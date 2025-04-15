import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lmsv2/api/ApiConfig.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:animate_do/animate_do.dart';
import '../provider/student_provider.dart';
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  int? studentId;
  List<NotificationItem> notifications = [];
  bool isLoading = true;
  bool isSorted = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchNotifications();
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    studentId = studentProvider.student?.id;
  }

  Future<void> fetchNotifications() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    int studentId = studentProvider.student?.id as int;
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.apiBaseUrl}Students/Notification?student_id=$studentId'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          List<dynamic> notificationData = data['data'];
          List<NotificationItem> loadedNotifications = notificationData
              .map((item) => NotificationItem.fromJson(item))
              .toList();

          setState(() {
            notifications = loadedNotifications;
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
            errorMessage = 'Failed to load announcements';
          });
        }
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Server error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Connection error: ${e.toString()}';
      });
    }
  }

  void toggleSort() {
    setState(() {
      isSorted = !isSorted;
      if (isSorted) {
        notifications.sort((a, b) => b.date.compareTo(a.date));
      } else {
        notifications.sort((a, b) => a.date.compareTo(b.date));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.campaign_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text(
              notifications.isEmpty ? 'Announcements' : 'Announcements (${notifications.length})',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontSize: 18,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        iconTheme: IconThemeData(color: Colors.white), // Make back button white
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4361EE), Color(0xFF3A0CA3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: Icon(
                isSorted ? Icons.sort : Icons.sort_by_alpha,
                color: Colors.white,
              ),
              onPressed: toggleSort,
              tooltip: isSorted ? 'Sort by oldest' : 'Sort by newest',
            ),
          ),
        ],
      ),
      body: isLoading
          ? SkeletonLoader()
          : errorMessage.isNotEmpty
          ? ErrorView(
        errorMessage: errorMessage,
        onRetry: fetchNotifications,
      )
          : notifications.isEmpty
          ? EmptyNotificationsView()
          : NotificationListView(
        notifications: notifications,
        onRefresh: fetchNotifications,
      ),
    );
  }
}

class SkeletonLoader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: 5,
      itemBuilder: (context, index) => FadeIn(
        delay: Duration(milliseconds: index * 100),
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 8),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 140,
                          height: 18,
                          color: Colors.grey[200],
                        ),
                        SizedBox(height: 8),
                        Container(
                          width: 100,
                          height: 12,
                          color: Colors.grey[200],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 50,
                    height: 12,
                    color: Colors.grey[200],
                  ),
                ],
              ),
              SizedBox(height: 16),
              Container(
                width: double.infinity,
                height: 14,
                color: Colors.grey[200],
              ),
              SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 14,
                color: Colors.grey[200],
              ),
              SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const ErrorView({
    Key? key,
    required this.errorMessage,
    required this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FadeIn(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFFFFE5E5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 72,
                  color: Color(0xFFE53E3E),
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Oops! Something went wrong',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                errorMessage,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF4A5568),
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4361EE),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                icon: Icon(Icons.refresh_rounded),
                label: Text(
                  'Try Again',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyNotificationsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: FadeIn(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Color(0xFFE6EFFE),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_off_rounded,
                  size: 72,
                  color: Color(0xFF4361EE),
                ),
              ),
              SizedBox(height: 24),
              Text(
                'No Announcements Yet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                'You\'ll be notified when new announcements arrive.',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF4A5568),
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NotificationListView extends StatelessWidget {
  final List<NotificationItem> notifications;
  final Future<void> Function() onRefresh;

  const NotificationListView({
    Key? key,
    required this.notifications,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Map<String, List<NotificationItem>> groupedNotifications = {};
    for (var notification in notifications) {
      String dateKey = _getGroupHeaderDate(notification.date);
      if (!groupedNotifications.containsKey(dateKey)) {
        groupedNotifications[dateKey] = [];
      }
      groupedNotifications[dateKey]!.add(notification);
    }

    return RefreshIndicator(
      color: Color(0xFF4361EE),
      backgroundColor: Colors.white,
      strokeWidth: 3,
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: groupedNotifications.length,
        itemBuilder: (context, index) {
          String dateKey = groupedNotifications.keys.elementAt(index);
          List<NotificationItem> dayNotifications = groupedNotifications[dateKey]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DateHeader(dateKey),
              ...dayNotifications.asMap().entries.map((entry) {
                int idx = entry.key;
                NotificationItem notification = entry.value;
                return FadeInUp(
                  delay: Duration(milliseconds: idx * 100),
                  child: NotificationCard(notification: notification),
                );
              }).toList(),
              SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }

  String _getGroupHeaderDate(DateTime date) {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime yesterday = today.subtract(Duration(days: 1));

    if (date.isAfter(today)) {
      return 'Today';
    } else if (date.isAfter(yesterday)) {
      return 'Yesterday';
    } else {
      return DateFormat('EEEE, d MMMM y').format(date);
    }
  }
}

class DateHeader extends StatelessWidget {
  final String dateText;

  const DateHeader(this.dateText, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0, left: 4.0),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: dateText == 'Today'
                    ? [Color(0xFF4361EE), Color(0xFF3A56DA)]
                    : dateText == 'Yesterday'
                    ? [Color(0xFF7048E8), Color(0xFF5438C5)]
                    : [Color(0xFF64748B), Color(0xFF475569)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF4361EE).withOpacity(0.15),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              dateText,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Divider(
              color: Color(0xFFD1D5DB),
              thickness: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final NotificationItem notification;

  const NotificationCard({Key? key, required this.notification}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Color(0xFFFFFFFF), // Pure white for clean look
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: notification.url != null && notification.mediaType == 'link'
            ? () => _launchURL(context, notification.url!)
            : null,
        splashColor: Color(0xFF4361EE).withOpacity(0.1),
        highlightColor: Color(0xFF4361EE).withOpacity(0.05),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NotificationAvatar(imageUrl: notification.senderImage),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                            height: 1.3,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              notification.senderName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF4B5563),
                                fontFamily: 'Poppins',
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.symmetric(horizontal: 6),
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Color(0xFF6B7280),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Text(
                              DateFormat('h:mm a').format(notification.date),
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.share_rounded, size: 20, color: Color(0xFF4361EE)),
                    onPressed: () {
                      Share.share('${notification.title}: ${notification.description}');
                    },
                    tooltip: 'Share',
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  notification.description,
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF374151),
                    height: 1.5,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              if (notification.mediaType == 'image' && notification.media != null)
                NotificationImage(imageUrl: notification.media!),
              if (notification.mediaType == 'link' && notification.url != null)
                NotificationLink(url: notification.url!),
            ],
          ),
        ),
      ),
    );
  }

  void _launchURL(BuildContext context, String url) async {
    try {
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        _showErrorSnackBar(context, 'Could not launch the link');
      }
    } catch (e) {
      _showErrorSnackBar(context, 'Error opening link');
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }
}

class NotificationAvatar extends StatelessWidget {
  final String imageUrl;

  const NotificationAvatar({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFFE0E7FF), Color(0xFFC7D2FE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(2), // Creates border effect
        child: ClipRRect(
          borderRadius: BorderRadius.circular(23), // Slightly smaller to create border effect
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Color(0xFFF3F4F6),
              child: Icon(
                Icons.person,
                color: Color(0xFF9CA3AF),
                size: 24,
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Color(0xFFF3F4F6),
              child: Icon(
                Icons.person,
                color: Color(0xFF9CA3AF),
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NotificationImage extends StatelessWidget {
  final String imageUrl;

  const NotificationImage({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 12),
      child: GestureDetector(
        onTap: () => _showImageDialog(context, imageUrl),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Hero(
              tag: imageUrl,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                placeholder: (context, url) => _buildImagePlaceholder(),
                errorWidget: (context, url, error) => _buildImageError(),
                fit: BoxFit.cover,
                height: 200,
                width: double.infinity,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 200,
      color: Color(0xFFF9FAFB),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4361EE)),
          strokeWidth: 3,
        ),
      ),
    );
  }

  Widget _buildImageError() {
    return Container(
      height: 200,
      color: Color(0xFFFEF2F2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_rounded,
            color: Color(0xFFEF4444),
            size: 48,
          ),
          SizedBox(height: 8),
          Text(
            'Image not available',
            style: TextStyle(
              color: Color(0xFFEF4444),
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                color: Colors.white,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      children: [
                        Hero(
                          tag: imageUrl,
                          child: InteractiveViewer(
                            maxScale: 5.0,
                            child: CachedNetworkImage(
                              imageUrl: imageUrl,
                              placeholder: (context, url) => _buildImagePlaceholder(),
                              errorWidget: (context, url, error) => _buildImageError(),
                              fit: BoxFit.contain,
                              width: double.infinity,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              Share.share('Check this image: $imageUrl');
                              Navigator.pop(context);
                            },
                            icon: Icon(
                              Icons.share_rounded,
                              color: Color(0xFF4361EE),
                            ),
                            label: Text(
                              'Share',
                              style: TextStyle(
                                color: Color(0xFF4361EE),
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationLink extends StatelessWidget {
  final String url;

  const NotificationLink({Key? key, required this.url}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Extract domain name for display
    String displayText = "Click to view";
    try {
      final uri = Uri.parse(url);
      displayText = uri.host;
    } catch (e) {
      // Keep default text if parsing fails
    }

    return Padding(
      padding: EdgeInsets.only(top: 12),
      child: Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF4361EE).withOpacity(0.08),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFF4361EE).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.link_rounded,
                size: 20,
                color: Color(0xFF4361EE),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'External Link',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                      fontSize: 14,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    displayText,
                    style: TextStyle(
                      color: Color(0xFF4361EE),
                      fontSize: 13,
                      fontFamily: 'Poppins',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Color(0xFF4361EE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.open_in_new_rounded,
                  size: 18,
                  color: Colors.white,
                ),
                onPressed: () => _launchURL(context, url),
                tooltip: 'Open link',
                padding: EdgeInsets.all(8),
                constraints: BoxConstraints(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _launchURL(BuildContext context, String url) async {
    try {
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open the link'),
            backgroundColor: Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening link'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class NotificationItem {
  final int id;
  final String title;
  final String description;
  final String? url;
  final DateTime date;
  final String sender;
  final String senderName;
  final String senderImage;
  final String? mediaType;
  final String? media;

  NotificationItem({
    required this.id,
    required this.title,
    required this.description,
    required this.url,
    required this.date,
    required this.sender,
    required this.senderName,
    required this.senderImage,
    required this.mediaType,
    required this.media,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      url: json['url'] ?? '',
      date: DateTime.parse(json['notification_date']),
      sender: json['sender'],
      senderName: json['sender_name'],
      senderImage: json['sender_image'] ?? '',
      mediaType: json['media_type'] ?? '',
      media: json['media'] ?? '',
    );
  }
}