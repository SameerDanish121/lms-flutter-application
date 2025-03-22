import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/instructor_provider.dart';


class JuniorHome extends StatelessWidget {
  const JuniorHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final instructorProvider = Provider.of<InstructorProvider>(context);
    final instructor = instructorProvider.instructor;

    return Scaffold(
      appBar: AppBar(title: const Text("Junior Lecturer Dashboard")),
      body: Center(
        child: instructor == null
            ? const Text("No Data Found")
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Junior Lecturer is Logged In",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text("Name: ${instructor.name}", style: const TextStyle(fontSize: 18)),
            Text("Gender: ${instructor.gender}", style: const TextStyle(fontSize: 18)),
            Text("Session: ${instructor.session}", style: const TextStyle(fontSize: 18)),
            Text("Username: ${instructor.username}", style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
