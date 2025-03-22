import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TeacherHome extends StatefulWidget {
  const TeacherHome({Key? key}) : super(key: key);

  @override
  State<TeacherHome> createState() => _TeacherHomeState();
}

class _TeacherHomeState extends State<TeacherHome> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const NotificationScreen(),
    const CreateTaskScreen(),
    const ProfileScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    if (index == 2) return; // For FAB
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onFabPressed() {
    setState(() {
      _selectedIndex = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: _buildCustomBottomNavigationBar(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF3969D7),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: _onFabPressed,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildCustomBottomNavigationBar() {
    return BottomAppBar(
      color: const Color(0xFF3969D7),
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.home, 'Home'),
            _buildNavItem(1, Icons.notifications, 'Notification'),
            const SizedBox(width: 40), // Space for FAB
            _buildNavItem(3, Icons.person, 'Profile'),
            _buildNavItem(4, Icons.settings, 'Setting'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;

    return InkWell(
      onTap: () => _onItemTapped(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.amber : Colors.white,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.amber : Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Home Screen
class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // App Bar with profile info
          _buildAppBar(),

          // Timetable Section
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Timetable', onViewAll: () {}),
                  const SizedBox(height: 16),
                  _buildTimetable(),
                  const SizedBox(height: 24),

                  // Academic Records Section
                  _buildSectionTitle('Academic Records'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildRecordCard('Attendance', Icons.person_outline, onTap: () {})),
                      const SizedBox(width: 16),
                      Expanded(child: _buildRecordCard('Courses', Icons.computer, onTap: () {})),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Manage And Tracks Section
                  _buildSectionTitle('Manage And Tracks'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildRecordCard('Mark Task', Icons.assignment_outlined, onTap: () {})),
                      const SizedBox(width: 16),
                      Expanded(child: _buildRecordCard('Mark Attendance', Icons.check_box_outlined, onTap: () {})),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 16),
      color: const Color(0xFF3969D7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Welcome Back!',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              Text(
                'Muhammad Ahsan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Lecturer',
                style: TextStyle(color: Colors.amber, fontSize: 14),
              ),
            ],
          ),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              image: const DecorationImage(
                image: AssetImage('assets/ahsan.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {required Function onViewAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        TextButton(
          onPressed: () => onViewAll(),
          child: const Text('See all'),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTimetable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date and day
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'Jun 10, 2024',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'Monday',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Table header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
          ),
          child: Row(
            children: const [
              Expanded(flex: 2, child: Text('Course', style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text('Section', style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text('Venue', style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 3, child: Text('Time', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
        ),

        // Table rows
        _buildTimetableRow('VP', 'BCS-7B', 'LT10', '09:30 - 10:30', false),
        _buildTimetableRow('DBS', 'BSE-2A', 'LT12', '11:30 - 12:30', true),
        _buildTimetableRow('DAM', 'BSE-3B', 'Lab1', '02:00 - 03:00', false),
        _buildTimetableRow('OOP', 'BCS-8A', 'LT9', '03:00 - 04:00', false),
        _buildTimetableRow('PF', 'BAI-A', 'LT2', '04:00 - 05:00', false),
      ],
    );
  }

  Widget _buildTimetableRow(String course, String section, String venue, String time, bool highlighted) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: highlighted ? Colors.grey.shade200 : Colors.transparent,
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(course)),
          Expanded(flex: 2, child: Text(section)),
          Expanded(flex: 2, child: Text(venue)),
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF3969D7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                time,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCard(String title, IconData icon, {required Function onTap}) {
    return InkWell(
      onTap: () => onTap(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF3969D7), size: 40),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'View',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Notification Screen
class NotificationScreen extends StatelessWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // App Bar with profile info
          _buildAppBar(),

          // Notification Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3969D7),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Send Notification Section
                  const Text(
                    'Send Notification',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title field
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: const [
                        Text('Title : '),
                        Expanded(
                          child: Text('Pre Scheduled Class'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Message field
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Your Class of Friday 22-Nove-2024 is pre scheduled on Tuesday 2:00-300',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Section dropdown and Send button
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text('Section'),
                              Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3969D7),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {},
                        child: const Text('Send'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Your Notifications section
                  const Text(
                    'Your Notification',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Notification list would go here
                  // Empty for now
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 16),
      color: const Color(0xFF3969D7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Welcome Back!',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              Text(
                'Muhammad Ahsan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Lecturer',
                style: TextStyle(color: Colors.amber, fontSize: 14),
              ),
            ],
          ),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              image: const DecorationImage(
                image: AssetImage('assets/ahsan.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Create Task Screen
class CreateTaskScreen extends StatelessWidget {
  const CreateTaskScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // App Bar with profile info
          _buildAppBar(),

          // Create Task Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create New Task',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3969D7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Course Field
                  _buildInputLabel('Course'),
                  _buildDropdownField('Compiler Construction'),
                  const SizedBox(height: 16),

                  // Task Title Field
                  _buildInputLabel('Task Title'),
                  _buildInputField('SP24-LABTASK-02-7B'),
                  const SizedBox(height: 16),

                  // Section & Type Fields
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInputLabel('Section'),
                            _buildDropdownField('BCS-7B'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInputLabel('Type'),
                            _buildDropdownField('Lab Task'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Selected Sections
                  _buildInputLabel('Selected Section :'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildSectionChip('BAI-7A'),
                      _buildSectionChip('BCS-7A'),
                      _buildSectionChip('BCS-7C'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Due Date and Time
                  _buildInputLabel('Due Date-Time'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Time Picker Button
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3969D7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.access_time, color: Colors.white),
                              SizedBox(width: 8),
                              Text('10:30 AM', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Date Picker Button
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3969D7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.calendar_today, color: Colors.white),
                              SizedBox(width: 8),
                              Text('15/11/2022', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Total Points
                  _buildInputLabel('Total Points :'),
                  _buildInputField('10'),
                  const SizedBox(height: 16),

                  // Upload Question File
                  _buildInputLabel('Upload Question File:'),
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.picture_as_pdf, color: Colors.red),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text('2021-ARID-4583-CC-QUIZ02.pdf'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cloud_upload, color: Color(0xFF3969D7)),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Create Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3969D7),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {},
                      child: const Text(
                        'Create',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 16),
      color: const Color(0xFF3969D7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Welcome Back!',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              Text(
                'Muhammad Ahsan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Lecturer',
                style: TextStyle(color: Colors.amber, fontSize: 14),
              ),
            ],
          ),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              image: const DecorationImage(
                image: AssetImage('assets/ahsan.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildInputField(String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(value),
    );
  }

  Widget _buildDropdownField(String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(value),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
    );
  }

  Widget _buildSectionChip(String label) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 4),
          const Icon(Icons.close, size: 16),
        ],
      ),
    );
  }
}

// Profile Screen
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // App Bar with profile info
          _buildAppBar(),

          // Profile Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3969D7),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Profile Image
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF3969D7), width: 2),
                      image: const DecorationImage(
                        image: AssetImage('assets/ahsan.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Profile Details
                  _buildProfileRow('Name :', 'Muhammad Ahsan'),
                  _buildProfileRow('Qualification :', 'Computer Science(MS)'),
                  _buildProfileRow('Gender :', 'Male'),
                  _buildProfileRow('DOB :', '25-5-1986'),
                  _buildProfileRow('Date Of Joining :', '22-08-2013'),
                  _buildProfileRow('Email :', 'MAhsan@biit.com'),
                  _buildProfileRow('Phone No :', '0307098763'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 16),
      color: const Color(0xFF3969D7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Welcome Back!',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              Text(
                'Muhammad Ahsan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Lecturer',
                style: TextStyle(color: Colors.amber, fontSize: 14),
              ),
            ],
          ),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              image: const DecorationImage(
                image: AssetImage('assets/ahsan.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF3969D7),
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold();}}