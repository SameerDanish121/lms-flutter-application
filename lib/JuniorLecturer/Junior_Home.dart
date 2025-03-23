
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lmsv2/auth/login_screen.dart';
import 'package:provider/provider.dart';
import '../provider/instructor_provider.dart';
class JuniorHome extends StatefulWidget {
  const JuniorHome({Key? key}) : super(key: key);
  @override
  _JuniorHomeState createState() => _JuniorHomeState();
}
class _JuniorHomeState extends State<JuniorHome> {
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
class NotificationScreen extends StatelessWidget {
  const NotificationScreen({Key? key}) : super(key: key);

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
            Text(
              'Notifications',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: 5,  // Replace with dynamic notification count
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 3,
                    margin: EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: Color(0xFF00A0E4),
                        child: Icon(
                          _getNotificationIcon(index),
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        'Notification ${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'This is a placeholder for notification content. Replace with actual notification data.',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                      trailing: Text(
                        '${index + 1}h ago',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      onTap: () {
                        // Handle notification tap
                      },
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

  IconData _getNotificationIcon(int index) {
    // Return different icons based on notification type
    switch (index % 3) {
      case 0:
        return Icons.notifications;
      case 1:
        return Icons.message;
      case 2:
        return Icons.event;
      default:
        return Icons.notifications;
    }
  }
}
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
                  _buildTimetableHeader(formattedDate, dayName),
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

  Widget _buildTimetableHeader(String date, String day) {
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
                onPressed: () {},
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