import 'package:flutter/material.dart';

class JuniorHome extends StatelessWidget {
  final Map<String, dynamic> juniorData;

  const JuniorHome({Key? key, required this.juniorData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Junior Home")),
      body: Center(
        child: Text(
          "Junior is Logged In\nName: ${juniorData['name'] ?? 'Unknown'}",
          style: const TextStyle(fontSize: 20),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
