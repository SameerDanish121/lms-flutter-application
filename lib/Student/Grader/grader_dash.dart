import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class GraderDashboard extends StatelessWidget {
  final int studentId;

  const GraderDashboard({Key? key, required this.studentId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grader Dashboard'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Grader View',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Student ID: $studentId',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Student View'),
            ),
          ],
        ).animate().scale(duration: 300.ms),
      ),
    );
  }
}