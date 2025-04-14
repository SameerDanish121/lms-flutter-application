import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

    try {
      final response = await http.get(
        Uri.parse('http://192.168.0.106:8000/api/Students/Notification?student_id=36'),
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
      appBar: AppBar(
        backgroundColor: Color(0xFF4A90E2),
        elevation: 0,
        title: Text(
          notifications.isEmpty ? 'Announcements' : 'Announcements (${notifications.length})',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: isLoading
          ? SkeletonLoader()
          : errorMessage.isNotEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Color(0xFFE53E3E)),
            SizedBox(height: 16),
            Text(
              errorMessage,
              style: TextStyle(fontSize: 16, color: Color(0xFF2D3748)),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: fetchNotifications,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFF5A623),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      )
          : notifications.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeIn(
              child: Icon(
                Icons.notifications_off,
                size: 64,
                color: Color(0xFF2D3748).withOpacity(0.5),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'No announcements yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2D3748),
              ),
            ),
          ],
        ),
      )
          : NotificationListView(
        notifications: notifications,
        onRefresh: fetchNotifications,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: toggleSort,
        backgroundColor: Color(0xFFF5A623),
        tooltip: isSorted ? 'Sort by oldest' : 'Sort by newest',
        child: Icon(isSorted ? Icons.sort_by_alpha : Icons.sort, color: Colors.white),
      ),
    );
  }
}

class SkeletonLoader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
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
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 100,
                height: 16,
                color: Colors.grey[200],
              ),
              SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 40,
                color: Colors.grey[200],
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
      color: Color(0xFF4A90E2),
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: groupedNotifications.length,
        itemBuilder: (context, index) {
          String dateKey = groupedNotifications.keys.elementAt(index);
          List<NotificationItem> dayNotifications = groupedNotifications[dateKey]!;

          return StickyHeader(
            header: Container(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Color(0xFFF8FAFC),
              child: Text(
                dateKey,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748).withOpacity(0.7),
                ),
              ),
            ),
            content: Column(
              children: dayNotifications.asMap().entries.map((entry) {
                int idx = entry.key;
                NotificationItem notification = entry.value;
                return FadeInUp(
                  delay: Duration(milliseconds: idx * 100),
                  child: NotificationCard(notification: notification),
                );
              }).toList(),
            ),
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
      return DateFormat('d MMMM y').format(date);
    }
  }
}

class NotificationCard extends StatelessWidget {
  final NotificationItem notification;

  const NotificationCard({Key? key, required this.notification}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: notification.url != null && notification.mediaType == 'link'
            ? () => _launchURL(context, notification.url!)
            : null,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: CachedNetworkImageProvider(notification.senderImage),
                    backgroundColor: Color(0xFFF8FAFC),
                    child: notification.senderImage.isEmpty
                        ? Icon(Icons.person, color: Color(0xFF2D3748))
                        : null,
                  ),
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
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          notification.senderName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF2D3748).withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        DateFormat('h:mm a').format(notification.date),
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF2D3748).withOpacity(0.5),
                        ),
                      ),
                      SizedBox(height: 8),
                      IconButton(
                        icon: Icon(Icons.share, size: 20, color: Color(0xFF4A90E2)),
                        onPressed: () {
                          Share.share('${notification.title}: ${notification.description}');
                        },
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                notification.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF2D3748),
                  height: 1.5,
                ),
              ),
              if (notification.mediaType == 'image' && notification.media != null)
                Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: GestureDetector(
                    onTap: () => _showImageDialog(context, notification.media!),
                    child: Hero(
                      tag: notification.media!,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: notification.media!,
                          placeholder: (context, url) => Container(
                            height: 150,
                            color: Color(0xFFF8FAFC),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 150,
                            color: Color(0xFFF8FAFC),
                            child: Icon(Icons.broken_image, color: Color(0xFFE53E3E)),
                          ),
                          fit: BoxFit.cover,
                          height: 150,
                          width: double.infinity,
                        ),
                      ),
                    ),
                  ),
                ),
              if (notification.mediaType == 'link' && notification.url != null)
                Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: GestureDetector(
                    onTap: () => _launchURL(context, notification.url!),
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(0xFF4A90E2).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.link, size: 20, color: Color(0xFF4A90E2)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              notification.url!,
                              style: TextStyle(
                                color: Color(0xFF4A90E2),
                                fontSize: 14,
                                decoration: TextDecoration.underline,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Hero(
              tag: imageUrl,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                placeholder: (context, url) => Container(
                  height: 300,
                  color: Color(0xFFF8FAFC),
                  child: Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 300,
                  color: Color(0xFFF8FAFC),
                  child: Icon(Icons.broken_image, color: Color(0xFFE53E3E)),
                ),
                fit: BoxFit.contain,
                width: double.infinity,
              ),
            ),
            ButtonBar(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Close',
                    style: TextStyle(color: Color(0xFF2D3748)),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Share.share('Check this image: $imageUrl');
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Share',
                    style: TextStyle(color: Color(0xFF4A90E2)),
                  ),
                ),
              ],
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
          SnackBar(content: Text('Could not launch $url')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
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

class StickyHeader extends StatelessWidget {
  final Widget header;
  final Widget content;

  const StickyHeader({Key? key, required this.header, required this.content}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        content,
      ],
    );
  }
}