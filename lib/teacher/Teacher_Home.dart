import 'package:flutter/material.dart';

import '../auth/login_screen.dart';

class TeacherHome extends StatelessWidget {
  final Map<String, dynamic> teacherData;

  const TeacherHome({Key? key, required this.teacherData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Teacher Home")),
      body: Center(
        child: Column(
          children: [
            Text(
              "Teacher is Logged In\nName: ${teacherData['name'] ?? 'Unknown'}",
              style: const TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF004D40),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text(
                "Logout",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => Login()),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
