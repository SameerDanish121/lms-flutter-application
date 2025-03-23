
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lmsv2/auth/login_screen.dart';
import 'package:lmsv2/teacher/timetable_teacher.dart';
import 'package:provider/provider.dart';
import '../provider/instructor_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
class TeacherHome extends StatefulWidget {
  const TeacherHome({Key? key}) : super(key: key);
  @override
  _TeacherHomeState createState() => _TeacherHomeState();
}
class _TeacherHomeState extends State<TeacherHome> {
  int selectBtn = 0;
  // List of screens to be displayed for each tab
  final List<Widget> _screens = [
    const HomeScreen(),
    const NotificationScreen(),
    const TaskScreen(),
    const ProfileScreen(),
    const SettingsScreen(),
  ];
  @override
  Widget build(BuildContext context) {
    final instructorProvider = Provider.of<InstructorProvider>(context);
    instructorProvider.instructor?.id;
    String imageUrl;
    if (instructorProvider.instructor?.image != null && instructorProvider.instructor!.image!.isNotEmpty) {
      // Use the provided image from InstructorProvider
      imageUrl = instructorProvider.instructor!.image!;
    } else {
      // Fallback to Placeholder API or any avatar generator API using name
      String name = instructorProvider.instructor?.name ?? "User";
      imageUrl = 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}background=4FC3F7&color=ffffff';
    }
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Color(0xFF00A0E4), // The blue color from your design
        automaticallyImplyLeading: false, // Remove back button
        toolbarHeight: 100, // Increase height for the layout
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome Back!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
            Text(
              Provider.of<InstructorProvider>(context).instructor?.name ?? 'No Name',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              Provider.of<InstructorProvider>(context).type ?? 'Instructor',
              style: TextStyle(
                color: Colors.amber,
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white, // White border
              child: CircleAvatar(
                radius: 28,
                backgroundImage: NetworkImage(imageUrl), // Replace with your image
              ),
            ),
          ),
        ],
        // Extend the app bar to include system UI area (status bar)
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Color(0xFF00A0E4), // Same color as AppBar
          statusBarIconBrightness: Brightness.light, // Light status bar icons for dark background
        ),
      ),
      backgroundColor: bgColor,
      body: Column(
        children: [
          // Display the selected screen
          Expanded(
            child: _screens[selectBtn],
          ),
          // Navigation bar at the bottom
          navigationBar(),
        ],
      ),
    );
  }

  Widget navigationBar() {
    return AnimatedContainer(
      height: 70.0,
      duration: const Duration(milliseconds: 400),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(selectBtn == 0 ? 0.0 : 20.0),
          topRight:
          Radius.circular(selectBtn == navBtn.length - 1 ? 0.0 : 20.0),
        ),
      ),
      child: LayoutBuilder(
          builder: (context, constraints) {
            double itemWidth = constraints.maxWidth / navBtn.length;
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (int i = 0; i < navBtn.length; i++)
                  GestureDetector(
                    onTap: () => setState(() => selectBtn = i),
                    child: iconBtn(i, itemWidth),
                  ),
              ],
            );
          }
      ),
    );
  }

  Widget iconBtn(int i, double width) {
    bool isActive = selectBtn == i ? true : false;
    var height = isActive ? 60.0 : 0.0;
    var notchWidth = isActive ? 50.0 : 0.0;

    return SizedBox(
      width: width,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: AnimatedContainer(
              height: height,
              width: notchWidth,
              duration: const Duration(milliseconds: 600),
              child: isActive
                  ? CustomPaint(
                painter: ButtonNotch(),
              )
                  : const SizedBox(),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Image.asset(
              navBtn[i].imagePath,
              color: isActive ? selectColor : black,
              height: 22,
              width: 22,
              // Add error builder to help debug any issues
              errorBuilder: (context, error, stackTrace) {
                print('Error loading image: ${navBtn[i].imagePath}');
                // Fallback to a simple circle as placeholder
                return Container(
                  height: 22,
                  width: 22,
                  decoration: BoxDecoration(
                    color: isActive ? selectColor : black,
                    shape: BoxShape.circle,
                  ),
                );
              },
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 5.0),
              child: Text(
                navBtn[i].name,
                textAlign: TextAlign.center,
                style: isActive
                    ? bntText.copyWith(
                  color: selectColor,
                  fontSize: 11,
                )
                    : bntText.copyWith(
                  fontSize: 11,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
// Constants and additional classes
const Color black = Color(0xFF191555);
const Color white = Color(0xFFFFFFFF);
const Color bgColor = Color(0xFF4448FF);
const Color selectColor = Color(0xFF4B3FFF);
const TextStyle bntText = TextStyle(
  color: black,
  fontWeight: FontWeight.w500,
);
class Model {
  final int id;
  final String imagePath;
  final String name;

  Model({
    required this.id,
    required this.imagePath,
    required this.name,
  });
}

List<Model> navBtn = [
  Model(id: 0, imagePath: 'assets/home.png', name: 'Home'),
  Model(id: 1, imagePath: 'assets/bell.png', name: 'Notification'),
  Model(id: 2, imagePath: 'assets/more.png', name: 'Task'),
  Model(id: 3, imagePath: 'assets/user.png', name: 'Profile'),
  Model(id: 4, imagePath: 'assets/settings.png', name: 'Setting'),
];
class ButtonNotch extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var dotPoint = Offset(size.width / 2, 2);

    var paint_1 = Paint()
      ..color = bgColor
      ..style = PaintingStyle.fill;
    var paint_2 = Paint()
      ..color = white
      ..style = PaintingStyle.fill;

    var path = Path();

    path.moveTo(0, 0);
    path.quadraticBezierTo(7.5, 0, 12, 5);
    path.quadraticBezierTo(size.width / 2, size.height / 2, size.width - 12, 5);
    path.quadraticBezierTo(size.width - 7.5, 0, size.width, 0);
    path.close();
    canvas.drawPath(path, paint_1);
    canvas.drawCircle(dotPoint, 6, paint_2);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final instructorProvider = Provider.of<InstructorProvider>(context);
    String imageUrl;

    if (instructorProvider.instructor?.image != null && instructorProvider.instructor!.image!.isNotEmpty) {
      imageUrl = instructorProvider.instructor!.image!;
    } else {
      String name = instructorProvider.instructor?.name ?? "User";
      imageUrl = 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}background=4FC3F7&color=ffffff';
    }

    String name = instructorProvider.instructor?.name ?? 'No Name';
    String type = instructorProvider.type ?? 'Instructor';
    String email = instructorProvider.instructor?.gender ?? 'example@email.com';
    String phone = instructorProvider.instructor?.dateOfBirth ?? '+1 234 567 8900';

    return Container(
      color: Color(0xFF4448FF),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Profile header
            Container(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 57,
                      backgroundImage: NetworkImage(imageUrl),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    type,
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatistic('Classes', '12'),
                      _buildDivider(),
                      _buildStatistic('Students', '156'),
                      _buildDivider(),
                      _buildStatistic('Experience', '5 yrs'),
                    ],
                  ),
                ],
              ),
            ),

            // Profile details
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              padding: EdgeInsets.all(24),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Personal Information',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF191555),
                    ),
                  ),
                  SizedBox(height: 20),
                  _buildInfoItem(Icons.email, 'Email', email),
                  _buildInfoItem(Icons.phone, 'Phone', phone),
                  _buildInfoItem(Icons.school, 'Department', 'Mathematics'),
                  _buildInfoItem(Icons.location_on, 'Address', '123 Education St, Academic City'),

                  SizedBox(height: 30),
                  Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF191555),
                    ),
                  ),
                  SizedBox(height: 20),
                  _buildSettingItem(Icons.notifications, 'Notification Settings', context),
                  _buildSettingItem(Icons.lock, 'Privacy & Security', context),
                  _buildSettingItem(Icons.help, 'Help & Support', context),

                  SizedBox(height: 30),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        // Handle edit profile
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF00A0E4),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistic(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.white.withOpacity(0.3),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Color(0xFF00A0E4),
              size: 22,
            ),
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: Color(0xFF191555),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String label, BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      leading: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Color(0xFFE3F2FD),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: Color(0xFF00A0E4),
          size: 22,
        ),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: Color(0xFF191555),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: () {
        // Navigate to respective setting screen
      },
    );
  }
}
class TaskScreen extends StatefulWidget {
  const TaskScreen({Key? key}) : super(key: key);

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}
class _TaskScreenState extends State<TaskScreen> {
  // Sample task data - replace with your actual task data
  final List<Task> _tasks = [
    Task(
      id: '1',
      title: 'Prepare lesson plan',
      description: 'Create next week\'s lesson plan for Mathematics class',
      dueDate: DateTime.now().add(Duration(days: 2)),
      isCompleted: false,
    ),
    Task(
      id: '2',
      title: 'Grade assignments',
      description: 'Review and grade student assignments from last week',
      dueDate: DateTime.now().add(Duration(days: 1)),
      isCompleted: true,
    ),
    Task(
      id: '3',
      title: 'Faculty meeting',
      description: 'Attend the monthly faculty meeting',
      dueDate: DateTime.now().add(Duration(days: 3)),
      isCompleted: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xFF4448FF),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Tasks',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // Handle add task
                  },
                  icon: Icon(Icons.add),
                  label: Text('Add Task'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Color(0xFF4448FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _tasks.length,
                itemBuilder: (context, index) {
                  final task = _tasks[index];
                  return Card(
                    elevation: 3,
                    margin: EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(16),
                      leading: Checkbox(
                        value: task.isCompleted,
                        activeColor: Color(0xFF00A0E4),
                        onChanged: (bool? value) {
                          setState(() {
                            _tasks[index] = task.copyWith(isCompleted: value ?? false);
                          });
                        },
                      ),
                      title: Text(
                        task.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.description,
                            style: TextStyle(
                              color: Colors.grey[600],
                              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: _getDueDateColor(task.dueDate),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Due: ${_formatDate(task.dueDate)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _getDueDateColor(task.dueDate),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.more_vert),
                        onPressed: () {
                          // Show task options
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getDueDateColor(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;

    if (difference < 0) {
      return Colors.red; // Overdue
    } else if (difference < 2) {
      return Colors.orange; // Due soon
    } else {
      return Colors.green; // Due later
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
class Task {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final bool isCompleted;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.isCompleted,
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    bool? isCompleted,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
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
// class NotificationModel {
//   final int id;
//   final String title;
//   final String description;
//   final String url;
//   final String notificationDate;
//   final String sender;
//   final String senderName;
//   final String? senderImage;
//   final String mediaType;
//   final String media;
//
//   NotificationModel({
//     required this.id,
//     required this.title,
//     required this.description,
//     required this.url,
//     required this.notificationDate,
//     required this.sender,
//     required this.senderName,
//     this.senderImage,
//     required this.mediaType,
//     required this.media,
//   });
//
//   factory NotificationModel.fromJson(Map<String, dynamic> json) {
//     return NotificationModel(
//       id: json['id'],
//       title: json['title'],
//       description: json['description'],
//       url: json['url'],
//       notificationDate: json['notification_date'],
//       sender: json['sender'],
//       senderName: json['sender_name'],
//       senderImage: json['sender_image'],
//       mediaType: json['media_type'],
//       media: json['media'],
//     );
//   }
// }
// class NotificationScreen extends StatefulWidget {
//   const NotificationScreen({Key? key}) : super(key: key);
//
//   @override
//   State<NotificationScreen> createState() => _NotificationScreenState();
// }
// class _NotificationScreenState extends State<NotificationScreen> with TickerProviderStateMixin {
//   bool _isLoading = true;
//   List<NotificationModel> _notifications = [];
//   final TextEditingController _titleController = TextEditingController();
//   final TextEditingController _descriptionController = TextEditingController();
//   final TextEditingController _mediaLinkController = TextEditingController();
//   String _selectedMediaType = 'link';
//   late TabController _tabController;
//   int _currentTabIndex = 0;
//
//   @override
//   void initState() {
//     super.initState();
//     // Initialize the tab controller in initState
//     _tabController = TabController(length: 2, vsync: this);
//     // Add listener to update current tab index
//     _tabController.addListener(() {
//       if (_tabController.indexIsChanging) {
//         setState(() {
//           _currentTabIndex = _tabController.index;
//         });
//       }
//     });
//     // Fetch notifications after the widget is built
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _fetchNotifications();
//     });
//   }
//
//   @override
//   void dispose() {
//     _tabController.dispose();
//     _titleController.dispose();
//     _descriptionController.dispose();
//     _mediaLinkController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _fetchNotifications() async {
//     setState(() {
//       _isLoading = true;
//     });
//
//     try {
//       final instructorProvider = Provider.of<InstructorProvider>(context, listen: false);
//       final teacherId = instructorProvider.instructor?.id;
//
//       if (teacherId == null) {
//         setState(() {
//           _isLoading = false;
//         });
//         _showErrorSnackBar('Teacher ID not found');
//         return;
//       }
//
//       final response = await http.get(
//         Uri.parse('http://192.168.0.108:8000/api/Teachers/get/notifications?teacher_id=$teacherId'),
//         headers: {'Content-Type': 'application/json'},
//       );
//
//       if (response.statusCode == 200) {
//         final jsonData = jsonDecode(response.body);
//         if (jsonData['status'] == true && jsonData['data'] != null) {
//           setState(() {
//             _notifications = List<NotificationModel>.from(
//               jsonData['data'].map((x) => NotificationModel.fromJson(x)),
//             );
//             _isLoading = false;
//           });
//         } else {
//           setState(() {
//             _notifications = [];
//             _isLoading = false;
//           });
//         }
//       } else {
//         setState(() {
//           _isLoading = false;
//         });
//         _showErrorSnackBar('Failed to load notifications');
//       }
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//       });
//       _showErrorSnackBar('Error: ${e.toString()}');
//     }
//   }
//
//   void _showErrorSnackBar(String message) {
//     if (!mounted) return;
//
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//         behavior: SnackBarBehavior.floating,
//         margin: const EdgeInsets.all(16),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//       ),
//     );
//   }
//
//   Future<void> _sendNotification() async {
//     if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
//       _showErrorSnackBar('Title and description are required');
//       return;
//     }
//
//     try {
//       final instructorProvider = Provider.of<InstructorProvider>(context, listen: false);
//       final teacherId = instructorProvider.instructor?.id;
//
//       if (teacherId == null) {
//         _showErrorSnackBar('Teacher ID not found');
//         return;
//       }
//
//       // Here you would implement the API call to send a notification
//       // Example:
//       // final response = await http.post(
//       //   Uri.parse('http://192.168.0.108:8000/api/Teachers/send/notification'),
//       //   headers: {'Content-Type': 'application/json'},
//       //   body: jsonEncode({
//       //     'teacher_id': teacherId,
//       //     'title': _titleController.text,
//       //     'description': _descriptionController.text,
//       //     'media_type': _selectedMediaType,
//       //     'media': _mediaLinkController.text,
//       //   }),
//       // );
//
//       // Show success message (replace with actual API response handling)
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: const Text('Notification sent successfully'),
//           backgroundColor: Colors.green,
//           behavior: SnackBarBehavior.floating,
//           margin: const EdgeInsets.all(16),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//         ),
//       );
//
//       // Clear form fields
//       _titleController.clear();
//       _descriptionController.clear();
//       _mediaLinkController.clear();
//
//       // Refresh notifications list
//       _fetchNotifications();
//     } catch (e) {
//       _showErrorSnackBar('Error sending notification: ${e.toString()}');
//     }
//   }
//
//   IconData _getNotificationIcon(String mediaType) {
//     switch (mediaType) {
//       case 'link':
//         return Icons.link;
//       case 'image':
//         return Icons.image;
//       default:
//         return Icons.notifications;
//     }
//   }
//
//   String _formatDate(String dateString) {
//     try {
//       final DateTime date = DateTime.parse(dateString);
//       return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
//     } catch (e) {
//       return dateString;
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       color: const Color(0xFF4448FF),
//       child: Column(
//         children: [
//           // Tab Bar
//           TabBar(
//             controller: _tabController,
//             indicatorColor: Colors.white,
//             indicatorWeight: 3,
//             labelColor: Colors.white,
//             tabs: const [
//               Tab(text: 'Your Notifications'),
//               Tab(text: 'Send Notification'),
//             ],
//           ),
//
//           // Tab Content
//           Expanded(
//             child: _currentTabIndex == 0
//                 ? _buildNotificationsTab()
//                 : _buildSendNotificationTab(),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildNotificationsTab() {
//     return Padding(
//       padding: const EdgeInsets.all(12.0),
//       child: Card(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(15.0),
//         ),
//         child: _isLoading
//             ? const Center(child: CircularProgressIndicator())
//             : _notifications.isEmpty
//             ? const Center(child: Text('No notifications found'))
//             : RefreshIndicator(
//           onRefresh: _fetchNotifications,
//           child: ListView.separated(
//             padding: const EdgeInsets.all(12),
//             itemCount: _notifications.length,
//             separatorBuilder: (context, index) => const Divider(height: 1),
//             itemBuilder: (context, index) {
//               final notification = _notifications[index];
//               return _buildNotificationItem(notification);
//             },
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildNotificationItem(NotificationModel notification) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Sender Image or Default Avatar
//           CircleAvatar(
//             radius: 24,
//             backgroundColor: Colors.grey.shade200,
//             backgroundImage: notification.senderImage != null
//                 ? NetworkImage(notification.senderImage!)
//                 : null,
//             child: notification.senderImage == null
//                 ? Text(
//               notification.senderName.isNotEmpty
//                   ? notification.senderName[0].toUpperCase()
//                   : '?',
//               style: const TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Color(0xFF4448FF),
//               ),
//             )
//                 : null,
//           ),
//
//           const SizedBox(width: 12),
//
//           // Notification Content
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Title and Timestamp
//                 Row(
//                   children: [
//                     Expanded(
//                       child: Text(
//                         notification.title,
//                         style: const TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 16,
//                         ),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ),
//                     Text(
//                       _formatDate(notification.notificationDate),
//                       style: TextStyle(
//                         color: Colors.grey.shade600,
//                         fontSize: 12,
//                       ),
//                     ),
//                   ],
//                 ),
//
//                 const SizedBox(height: 4),
//
//                 // Sender Name
//                 Text(
//                   notification.senderName,
//                   style: TextStyle(
//                     color: Colors.grey.shade700,
//                     fontWeight: FontWeight.w500,
//                     fontSize: 14,
//                   ),
//                 ),
//
//                 const SizedBox(height: 4),
//
//                 // Description
//                 Text(
//                   notification.description,
//                   style: const TextStyle(fontSize: 14),
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//
//                 const SizedBox(height: 8),
//
//                 // Media Indicator
//                 if (notification.mediaType.isNotEmpty)
//                   InkWell(
//                     onTap: () {
//                       // Handle media click (open URL or show image)
//                       if (notification.mediaType == 'link') {
//                         // Implement URL launcher here
//                       } else if (notification.mediaType == 'image') {
//                         // Show image in dialog or navigate to image viewer
//                       }
//                     },
//                     child: Row(
//                       children: [
//                         Icon(
//                           _getNotificationIcon(notification.mediaType),
//                           size: 16,
//                           color: Colors.grey.shade600,
//                         ),
//                         const SizedBox(width: 4),
//                         Text(
//                           notification.mediaType == 'link' ? 'View Link' : 'View Image',
//                           style: TextStyle(
//                             color: Colors.blue.shade700,
//                             fontSize: 13,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildSendNotificationTab() {
//     return Padding(
//       padding: const EdgeInsets.all(12.0),
//       child: Card(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(15.0),
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: SingleChildScrollView(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 TextField(
//                   controller: _titleController,
//                   decoration: const InputDecoration(
//                     labelText: 'Title',
//                     border: OutlineInputBorder(),
//                     contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 TextField(
//                   controller: _descriptionController,
//                   decoration: const InputDecoration(
//                     labelText: 'Description',
//                     border: OutlineInputBorder(),
//                     contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
//                   ),
//                   maxLines: 3,
//                 ),
//                 const SizedBox(height: 16),
//
//                 // Media Type Selection
//                 const Text(
//                   'Media Type:',
//                   style: TextStyle(fontWeight: FontWeight.w500),
//                 ),
//                 Row(
//                   children: [
//                     Radio(
//                       value: 'link',
//                       groupValue: _selectedMediaType,
//                       onChanged: (value) {
//                         setState(() {
//                           _selectedMediaType = value.toString();
//                         });
//                       },
//                       activeColor: const Color(0xFF4448FF),
//                     ),
//                     const Text('Link'),
//                     const SizedBox(width: 16),
//                     Radio(
//                       value: 'image',
//                       groupValue: _selectedMediaType,
//                       onChanged: (value) {
//                         setState(() {
//                           _selectedMediaType = value.toString();
//                         });
//                       },
//                       activeColor: const Color(0xFF4448FF),
//                     ),
//                     const Text('Image'),
//                   ],
//                 ),
//
//                 TextField(
//                   controller: _mediaLinkController,
//                   decoration: InputDecoration(
//                     labelText: _selectedMediaType == 'link' ? 'URL' : 'Image URL',
//                     border: const OutlineInputBorder(),
//                     contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
//                   ),
//                 ),
//
//                 const SizedBox(height: 24),
//
//                 // Send Button
//                 ElevatedButton(
//                   onPressed: _sendNotification,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFF4448FF),
//                     minimumSize: const Size(double.infinity, 46),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                   child: const Text(
//                     'Send Notification',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  String _selectedLanguage = 'English';
  double _textSize = 1.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF4448FF),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              'Settings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildSectionHeader('App Preferences'),
                  _buildSwitchSetting(
                    'Dark Mode',
                    'Switch to dark color theme',
                    Icons.dark_mode,
                    _darkModeEnabled,
                        (value) {
                      setState(() {
                        _darkModeEnabled = value;
                      });
                    },
                  ),
                  _buildSliderSetting(
                    'Text Size',
                    'Adjust the text size in the app',
                    Icons.text_fields,
                  ),
                  _buildDropdownSetting(
                    'Language',
                    'Select your preferred language',
                    Icons.language,
                  ),
                  _buildDivider(),

                  _buildSectionHeader('Notifications'),
                  _buildSwitchSetting(
                    'Push Notifications',
                    'Receive push notifications',
                    Icons.notifications,
                    _notificationsEnabled,
                        (value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                    },
                  ),
                  _buildSettingItem(
                    'Notification Preferences',
                    'Configure which notifications you receive',
                    Icons.tune,
                    onTap: () {},
                  ),
                  _buildDivider(),

                  _buildSectionHeader('Account'),
                  _buildSettingItem(
                    'Personal Information',
                    'Update your personal details',
                    Icons.person,
                    onTap: () {},
                  ),
                  _buildSettingItem(
                    'Security',
                    'Manage your password and security settings',
                    Icons.security,
                    onTap: () {},
                  ),
                  _buildSettingItem(
                    'Privacy',
                    'Manage your privacy settings',
                    Icons.privacy_tip,
                    onTap: () {},
                  ),
                  _buildDivider(),

                  _buildSectionHeader('Support'),
                  _buildSettingItem(
                    'Help Center',
                    'Get help and find answers to your questions',
                    Icons.help,
                    onTap: () {},
                  ),
                  _buildSettingItem(
                    'Contact Us',
                    'Get in touch with our support team',
                    Icons.contact_support,
                    onTap: () {},
                  ),
                  _buildSettingItem(
                    'About',
                    'Learn more about our app',
                    Icons.info,
                    onTap: () {},
                  ),

                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Logout'),
                            content: const Text('Are you sure you want to logout?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (context) =>Login()),
                                  );
                                  // Perform logout operation
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('Logout'),
                              ),
                            ],
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade100,
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Center(
                    child: Text(
                      'App Version 1.0.0',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF00A0E4),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingItem(String title, String subtitle, IconData icon, {VoidCallback? onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFE3F2FD),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF00A0E4),
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF191555),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }

  Widget _buildSwitchSetting(String title, String subtitle, IconData icon, bool value, Function(bool) onChanged) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFE3F2FD),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF00A0E4),
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF191555),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF00A0E4),
      ),
    );
  }

  Widget _buildSliderSetting(String title, String subtitle, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF00A0E4),
              size: 22,
            ),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF191555),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 56.0, right: 16.0),
          child: Row(
            children: [
              const Text('A', style: TextStyle(fontSize: 14)),
              Expanded(
                child: Slider(
                  value: _textSize,
                  min: 0.8,
                  max: 1.2,
                  divisions: 4,
                  activeColor: const Color(0xFF00A0E4),
                  onChanged: (value) {
                    setState(() {
                      _textSize = value;
                    });
                  },
                ),
              ),
              const Text('A', style: TextStyle(fontSize: 20)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownSetting(String title, String subtitle, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF00A0E4),
              size: 22,
            ),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF191555),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 56.0, right: 16.0),
          child: DropdownButton<String>(
            value: _selectedLanguage,
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down),
            items: ['English', 'Spanish', 'French', 'German'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                _selectedLanguage = newValue!;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16.0),
      child: Divider(thickness: 1),
    );
  }
}


class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get current date and time
    final now = DateTime.now();
    final formattedDate = DateFormat('MMM d, yyyy').format(now);
    final dayName = DateFormat('EEEE').format(now);
    final currentTime = TimeOfDay.fromDateTime(now);

    return Container(
      color: const Color(0xFF4448FF),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Timetable section with white background and padding
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildTimetableHeader(context,formattedDate, dayName),
                  Consumer<InstructorProvider>(
                    builder: (context, instructorProvider, _) {
                      if (!instructorProvider.isInstructorAvailable) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: Text(
                              'Instructor data not available',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ),
                        );
                      }

                      final timetableData = instructorProvider.instructor?.timetable ?? [];

                      final todayClasses = timetableData.toList();

                      // Sort timetable by start_time
                      todayClasses.sort((a, b) {
                        final aStartTime = a['start_time'] ?? '';
                        final bStartTime = b['start_time'] ?? '';
                        return aStartTime.compareTo(bStartTime);
                      });

                      return todayClasses.isEmpty
                          ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: Text(
                            'No Classes Scheduled for Today',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      )
                          : _buildTimetableList(todayClasses, currentTime);
                    },
                  ),
                ],
              ),
            ),

            // Academic Records Section (visible without scrolling)
            _buildHorizontalCardSection(
              title: 'Academic Records',
              cards: [
                CardData(
                  title: 'Courses',
                  icon: Icons.book,
                  color: Colors.blue,
                ),
                CardData(
                  title: 'Grades',
                  icon: Icons.assessment,
                  color: Colors.green,
                ),
                CardData(
                  title: 'Attendance',
                  icon: Icons.date_range,
                  color: Colors.amber,
                ),
              ],
            ),

            // Manage and Track Section (will be in scroll)
            _buildHorizontalCardSection(
              title: 'Manage and Track',
              cards: [
                CardData(
                  title: 'Assignments',
                  icon: Icons.assignment,
                  color: Colors.purple,
                ),
                CardData(
                  title: 'Exams',
                  icon: Icons.school,
                  color: Colors.red,
                ),
                CardData(
                  title: 'Resources',
                  icon: Icons.folder,
                  color: Colors.teal,
                ),
              ],
            ),

            // Add some bottom padding
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTimetableHeader(BuildContext context,String date, String day) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Timetable',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4448FF),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TimetableScreen()),
                  );
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'See all',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF4448FF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                day,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimetableList(List<dynamic> timetable, TimeOfDay currentTime) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Time',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                      fontSize: 11,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Course',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                      fontSize: 11,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Section',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                      fontSize: 11,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Venue',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 2,
                ),
              ],
            ),
            // Set a fixed height to make exactly one row of cards visible without scrolling
            height: 120,
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: timetable.length,
              itemBuilder: (context, index) {
                final item = timetable[index];

                // Access the data using the keys from your server
                final String courseName = item['description'] ?? '';
                final String venue = item['venue'] ?? '';
                final String startTime = item['start_time'] ?? '';
                final String endTime = item['end_time'] ?? '';
                final String section = item['section'];

                // Check if this is the current class
                bool isCurrentClass = _isCurrentTimeSlot(startTime, endTime);

                // Use abbreviation for course name if it's too long
                final displayCourseName = courseName.length > 4
                    ? courseName.substring(0, 4)
                    : courseName;

                return Container(
                  decoration: BoxDecoration(
                    color: isCurrentClass
                        ? const Color(0xFFE3F2FD)
                        : (index % 2 == 0 ? Colors.white : const Color(0xFFF5F5F5)),
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(

                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _formatTimeDisplay(startTime, endTime),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          displayCourseName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          section,
                          style: const TextStyle(
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          venue,
                          style: const TextStyle(
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Format time from 09:00:00 to 09:00
  String _formatTimeDisplay(String startTime, String endTime) {
    final start = startTime.split(':').take(2).join(':');
    final end = endTime.split(':').take(2).join(':');
    return '$start - $end';
  }

  // Check if current time is between start and end times in 24-hour format
  bool _isCurrentTimeSlot(String startTimeStr, String endTimeStr) {
    try {
      final now = DateTime.now();
      final currentTimeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00';

      // Simple string comparison since all times are in 24-hour format (08:00:00)
      return currentTimeStr.compareTo(startTimeStr) >= 0 &&
          currentTimeStr.compareTo(endTimeStr) <= 0;
    } catch (e) {
      return false;
    }
  }

  Widget _buildHorizontalCardSection({
    required String title,
    required List<CardData> cards,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: cards.length,
              itemBuilder: (context, index) {
                return Container(
                  width: MediaQuery.of(context).size.width * 0.42,
                  margin: const EdgeInsets.only(right: 12, bottom: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: cards[index].color.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          cards[index].icon,
                          color: cards[index].color,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cards[index].title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Helper class for card data
class CardData {
  final String title;
  final IconData icon;
  final Color color;

  CardData({
    required this.title,
    required this.icon,
    required this.color,
  });
}