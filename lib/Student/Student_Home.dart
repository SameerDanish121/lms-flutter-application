import 'package:flutter/material.dart';
import '../auth/login_screen.dart';

class StudentHome extends StatelessWidget {
  final Map<String, dynamic> studentData;

  const StudentHome({Key? key, required this.studentData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Colors.teal.shade700;
    final Color secondaryColor = Colors.white;
    final Color labelColor = Colors.grey.shade700;
    final Color valueColor = Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "🎓 Student Profile",
          style: TextStyle(fontWeight: FontWeight.bold,color:Colors.white),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF00796B), Color(0xFF004D40)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        centerTitle: true,
        elevation: 5,
      ),
      backgroundColor: const Color(0xFFF1F8E9),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Image
            if (studentData['Image'] != null)
              CircleAvatar(
                radius: 60,
                backgroundImage: NetworkImage(studentData['Image']),
              )
            else
              const CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, size: 50, color: Colors.white),
              ),

            const SizedBox(height: 20),

            // Form-style Info
            _buildFormField("Name", studentData['name'], labelColor, valueColor),
            _buildFormField("Registration No", studentData['RegNo'], labelColor, valueColor),
            _buildFormField("CGPA", studentData['CGPA'].toString(), labelColor, valueColor),
            _buildFormField("Gender", studentData['Gender'], labelColor, valueColor),
            _buildFormField("Guardian", studentData['Guardian'], labelColor, valueColor),
            _buildFormField("Username", studentData['username'], labelColor, valueColor),
            _buildFormField("Email", studentData['email'], labelColor, valueColor),
            _buildFormField("Intake", studentData['InTake'], labelColor, valueColor),
            _buildFormField("Program", studentData['Program'], labelColor, valueColor),
            _buildFormField("Is Grader?", studentData['Is Grader ?'] ? "Yes" : "No", labelColor, valueColor),
            _buildFormField("Section", studentData['Section'], labelColor, valueColor),
            _buildFormField("Total Enrollments", studentData['Total Enrollments'].toString(), labelColor, valueColor),
            _buildFormField("Current Session", studentData['Current Session'], labelColor, valueColor),

            const SizedBox(height: 30),

            // Logout Button
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

  // Form Field Styled Widget
  Widget _buildFormField(String label, String value, Color labelColor, Color valueColor) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.shade100,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              "$label:",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: labelColor,
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
