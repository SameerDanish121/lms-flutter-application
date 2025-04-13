import 'package:flutter/material.dart';

class StudentProvider with ChangeNotifier {
  String? type;
  StudentInfo? student;

  void setStudent(String type, Map<String, dynamic> studentData) {
    this.type = type;
    student = StudentInfo.fromJson(studentData['StudentInfo'] ?? studentData);
    notifyListeners();
  }

  void clearStudent() {
    type = null;
    student = null;
    notifyListeners();
  }

  void updateEmail(String newEmail) {
    if (student != null) {
      student = student!.copyWith(email: newEmail);
      notifyListeners();
    }
  }

  void updatePassword(String newPassword) {
    if (student != null) {
      student = student!.copyWith(password: newPassword);
      notifyListeners();
    }
  }

  void updateImage(String newImageUrl) {
    if (student != null) {
      student = student!.copyWith(image: newImageUrl);
      notifyListeners();
    }
  }

  Future<void> logout() async {
    clearStudent();
  }

  bool get isStudentAvailable => student != null;
}

class StudentInfo {
  final int id;
  final String name;
  final String regNo;
  final String cgpa;
  final int userId;
  final String gender;
  final String guardian;
  final String username;
  final String password;
  final String email;
  final String intake;
  final String program;
  final bool isGrader;
  final String section;
  final int totalEnrollments;
  final String currentSession;
  final List<dynamic> timetable;
  final List<dynamic> attendance;
  final String? image;
  final int currentWeek;
  final List<dynamic> taskInfo;

  StudentInfo({
    required this.id,
    required this.name,
    required this.regNo,
    required this.cgpa,
    required this.userId,
    required this.gender,
    required this.guardian,
    required this.username,
    required this.password,
    required this.email,
    required this.intake,
    required this.program,
    required this.isGrader,
    required this.section,
    required this.totalEnrollments,
    required this.currentSession,
    required this.timetable,
    required this.attendance,
    this.image,
    required this.currentWeek,
    required this.taskInfo,
  });

  factory StudentInfo.fromJson(Map<String, dynamic> json) {
    return StudentInfo(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? 'N/A',
      regNo: json['RegNo']?.toString() ?? 'N/A',
      cgpa: json['CGPA']?.toString() ?? '0.00',
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      gender: json['Gender']?.toString() ?? 'N/A',
      guardian: json['Guardian']?.toString() ?? 'N/A',
      username: json['username']?.toString() ?? 'N/A',
      password: json['password']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      intake: json['InTake']?.toString() ?? 'N/A',
      program: json['Program']?.toString() ?? 'N/A',
      isGrader: json['Is Grader ?'] is bool ? json['Is Grader ?'] : (json['Is Grader ?']?.toString().toLowerCase() == 'true'),
      section: json['Section']?.toString() ?? 'N/A',
      totalEnrollments: json['Total Enrollments'] is int ? json['Total Enrollments'] : int.tryParse(json['Total Enrollments']?.toString() ?? '0') ?? 0,
      currentSession: json['Current Session']?.toString() ?? 'N/A',
      timetable: json['Timetable'] is List ? json['Timetable'] : [],
      attendance: json['Attendance'] is List ? json['Attendance'] : [],
      image: json['Image']?.toString(),
      currentWeek: json['Current_Week'] is int ? json['Current_Week'] : int.tryParse(json['Current_Week']?.toString() ?? '0') ?? 0,
      taskInfo: json['Task_Info'] is List ? json['Task_Info'] : [],
    );
  }

  StudentInfo copyWith({
    int? id,
    String? name,
    String? regNo,
    String? cgpa,
    int? userId,
    String? gender,
    String? guardian,
    String? username,
    String? password,
    String? email,
    String? intake,
    String? program,
    bool? isGrader,
    String? section,
    int? totalEnrollments,
    String? currentSession,
    List<dynamic>? timetable,
    List<dynamic>? attendance,
    String? image,
    int? currentWeek,
    List<dynamic>? taskInfo,
  }) {
    return StudentInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      regNo: regNo ?? this.regNo,
      cgpa: cgpa ?? this.cgpa,
      userId: userId ?? this.userId,
      gender: gender ?? this.gender,
      guardian: guardian ?? this.guardian,
      username: username ?? this.username,
      password: password ?? this.password,
      email: email ?? this.email,
      intake: intake ?? this.intake,
      program: program ?? this.program,
      isGrader: isGrader ?? this.isGrader,
      section: section ?? this.section,
      totalEnrollments: totalEnrollments ?? this.totalEnrollments,
      currentSession: currentSession ?? this.currentSession,
      timetable: timetable ?? this.timetable,
      attendance: attendance ?? this.attendance,
      image: image ?? this.image,
      currentWeek: currentWeek ?? this.currentWeek,
      taskInfo: taskInfo ?? this.taskInfo,
    );
  }
}



// // Initialize the provider
// final studentProvider = Provider.of<StudentProvider>(context, listen: false);
// studentProvider.setStudent('student', studentData);
//
// // Access student data
// final student = studentProvider.student;
// print(student?.name);
// print(student?.regNo);
//
// // Update student email
// studentProvider.updateEmail('newemail@example.com');