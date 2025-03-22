import 'package:flutter/material.dart';
class InstructorProvider with ChangeNotifier {
  String? type; // "Teacher" or "Junior"
  TeacherInfo? instructor; // TeacherInfo object

  void setInstructor(String type, Map<String, dynamic> instructorData) {
    this.type = type;
    instructor = TeacherInfo.fromJson(instructorData);
    notifyListeners();
  }

  void clearInstructor() {
    type = null;
    instructor = null;
    notifyListeners();
  }

  bool get isInstructorAvailable => instructor != null;
}

class TeacherInfo {
  final int id;
  final String name;
  final int userId;
  final String gender;
  final String dateOfBirth;
  final String username;
  final String password;
  final String session;
  final List<dynamic> timetable;
  final String? image;

  TeacherInfo({
    required this.id,
    required this.name,
    required this.userId,
    required this.gender,
    required this.dateOfBirth,
    required this.username,
    required this.password,
    required this.session,
    required this.timetable,
    this.image,
  });

  factory TeacherInfo.fromJson(Map<String, dynamic> json) {
    return TeacherInfo(
      id: json['id'],
      name: json['name'],
      userId: json['user_id'],
      gender: json['gender'],
      dateOfBirth: json['Date Of Birth'],
      username: json['Username'],
      password: json['Password'],
      session: json['Session'],
      timetable: json['Timetable'] ?? [],
      image: json['image'],
    );
  }
}
