import 'package:flutter/material.dart';
import 'package:awesome_bottom_bar/awesome_bottom_bar.dart';

class StudentHome extends StatelessWidget {
  final Map<String, dynamic> studentData;

  const StudentHome({Key? key, required this.studentData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final studentInfo = studentData;
    final isGrader = studentInfo['Is Grader ?'] ?? false;
    final imageUrl = studentInfo['Image'];
    final name = studentInfo['name'];
    final regNo = studentInfo['RegNo'];
    final program = studentInfo['Program'];
    final section = studentInfo['Section'];
    final cgpa = studentInfo['CGPA'];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Student Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Stack(
              children: [
                Icon(Icons.notifications, size: 28),
                Positioned(
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '3',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {
              // Handle notification tap
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(imageUrl),
                    backgroundColor: Colors.grey.shade200,
                  ),
                  SizedBox(height: 10),
                  Text(
                    name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    regNo,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.person, color: Colors.grey.shade700),
              title: Text('Profile'),
              onTap: () {
                // Handle profile tap
              },
            ),
            ListTile(
              leading: Icon(Icons.settings, color: Colors.grey.shade700),
              title: Text('Settings'),
              onTap: () {
                // Handle settings tap
              },
            ),
            ListTile(
              leading: Icon(Icons.help_outline, color: Colors.grey.shade700),
              title: Text('Help & Support'),
              onTap: () {
                // Handle help tap
              },
            ),
            if (isGrader)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Switch to Grader',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  onPressed: () {
                    // Handle switch to grader
                  },
                ),
              ),
            Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.grey.shade700),
              title: Text('Logout'),
              onTap: () {
                // Handle logout
              },
            ),
          ],
        ),
      ),
      body: Container(
        color: Colors.grey.shade50,
        child: Column(
          children: [
            // Header with quick info
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(imageUrl),
                    backgroundColor: Colors.grey.shade200,
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, $name',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '$program • $section',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'CGPA: $cgpa',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Main content area (will be replaced with tab views)
            Expanded(
              child: Center(
                child: Text(
                  'Select a tab to view content',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomBarCreative(
        items: [
          TabItem(
            icon: Icons.home,
            title: 'Home',
          ),
          TabItem(
            icon: Icons.library_books,
            title: 'Lessons',
          ),
          TabItem(
            icon: Icons.assignment,
            title: 'Tasks',
          ),
          TabItem(
            icon: Icons.assessment,
            title: 'Reports',
          ),
          TabItem(
            icon: Icons.schedule,
            title: 'Schedule',
          ),
        ],
        backgroundColor: Colors.white,
        color: Colors.grey.shade600,
        colorSelected: Theme.of(context).primaryColor,
        indexSelected: 0,
        onTap: (int index) {
          // Handle tab change
        },
        highlightStyle: HighlightStyle(
          sizeLarge: true,
          background: Theme.of(context).primaryColor.withOpacity(0.2),
          elevation: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, -3),
          ),
        ],
      ),
    );
  }
}