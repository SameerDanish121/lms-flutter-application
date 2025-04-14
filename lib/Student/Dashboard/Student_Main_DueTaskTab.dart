// due_task_tab.dart
import 'package:flutter/material.dart';

class DueTaskTab extends StatefulWidget {
  const DueTaskTab({Key? key}) : super(key: key);

  @override
  State<DueTaskTab> createState() => _DueTaskTabState();
}

class _DueTaskTabState extends State<DueTaskTab> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Due Task Tab'),
    );
  }
}