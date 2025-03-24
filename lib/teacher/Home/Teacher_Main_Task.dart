import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../Model/Comman Model.dart';

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