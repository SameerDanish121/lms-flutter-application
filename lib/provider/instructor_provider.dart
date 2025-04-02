// import 'package:flutter/material.dart';
//
// class InstructorProvider with ChangeNotifier {
//   String? type; // "Teacher" or "Junior"
//   TeacherInfo? instructor; // TeacherInfo object
//
//   void setInstructor(String type, Map<String, dynamic> instructorData) {
//     this.type = type;
//     instructor = TeacherInfo.fromJson(instructorData);
//     notifyListeners();
//   }
//   void updateEmail(String newEmail) {
//     if (instructor != null) {
//       instructor = TeacherInfo(
//         id: instructor!.id,
//         name: instructor!.name,
//         userId: instructor!.userId,
//         gender: instructor!.gender,
//         dateOfBirth: instructor!.dateOfBirth,
//         username: instructor!.username,
//         password: instructor!.password,
//         session: instructor!.session,
//         timetable: instructor!.timetable,
//         image: instructor!.image,
//         Holiday: instructor!.Holiday,
//         email: newEmail,
//       );
//       notifyListeners();
//     }
//   }
//
//   void updatePassword(String newPassword) {
//     if (instructor != null) {
//       instructor = TeacherInfo(
//         id: instructor!.id,
//         name: instructor!.name,
//         userId: instructor!.userId,
//         gender: instructor!.gender,
//         dateOfBirth: instructor!.dateOfBirth,
//         username: instructor!.username,
//         password: newPassword,
//         session: instructor!.session,
//         timetable: instructor!.timetable,
//         image: instructor!.image,
//         Holiday: instructor!.Holiday,
//         email: instructor!.email,
//       );
//       notifyListeners();
//     }
//   }
//   void updateImage(String newImageUrl) {
//     if (instructor != null) {
//       instructor = TeacherInfo(
//         id: instructor!.id,
//         name: instructor!.name,
//         userId: instructor!.userId,
//         gender: instructor!.gender,
//         dateOfBirth: instructor!.dateOfBirth,
//         username: instructor!.username,
//         password: instructor!.password,
//         session: instructor!.session,
//         timetable: instructor!.timetable,
//         image: newImageUrl,
//         Holiday: instructor!.Holiday,
//         email: instructor!.email,
//       );
//       notifyListeners();
//     }
//   }
//
//   Future<void> logout() async {
//     clearInstructor();
//     // Add any additional logout logic here (e.g., clearing tokens)
//   }
//   void clearInstructor() {
//     type = null;
//     instructor = null;
//     notifyListeners();
//   }
//
//   bool get isInstructorAvailable => instructor != null;
// }
// class TeacherInfo {
//   final int id;
//   final String name;
//   final int userId;
//   final String gender;
//   final String dateOfBirth;
//   final String username;
//   final String password;
//   final String session;
//   final List<dynamic> timetable;
//   final String? image;
//   final String Holiday;
//   final String email;
//   TeacherInfo({
//     required this.id,
//     required this.name,
//     required this.userId,
//     required this.gender,
//     required this.dateOfBirth,
//     required this.username,
//     required this.password,
//     required this.session,
//     required this.timetable,
//     this.image,
//     required this.Holiday,
//     required this.email,
//   });
//
//   factory TeacherInfo.fromJson(Map<String, dynamic> json) {
//     return TeacherInfo(
//       id: json['id'],
//       name: json['name'],
//       userId: json['user_id'],
//       gender: json['gender'],
//       dateOfBirth: json['Date Of Birth'],
//       username: json['Username'],
//       password: json['Password'],
//       session: json['Session'],
//       timetable: json['Timetable'] ?? json['Reschedule'] ?? [],
//       image: json['image'],
//       Holiday: json['Holiday']??'',
//       email:json['email']??'',
//     );
//   }
// }
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../api/ApiConfig.dart';
import 'package:http/http.dart' as http;
class InstructorProvider with ChangeNotifier {
  String? type;
  TeacherInfo? instructor;

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

  void updateEmail(String newEmail) {
    if (instructor != null) {
      instructor = instructor!.copyWith(email: newEmail);
      notifyListeners();
    }
  }

  void updatePassword(String newPassword) {
    if (instructor != null) {
      instructor = instructor!.copyWith(password: newPassword);
      notifyListeners();
    }
  }

  void updateImage(String newImageUrl) {
    if (instructor != null) {
      instructor = instructor!.copyWith(image: newImageUrl);
      notifyListeners();
    }
  }

  Future<void> logout() async {
    clearInstructor();
  }

  Future<void> pickAndUploadImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        // Create multipart request
        final teacherId = instructor?.id;
        if (teacherId == null) throw Exception('Teacher ID not available');

        var request = http.MultipartRequest(
          'POST',
          Uri.parse('${ApiConfig.apiBaseUrl}Teachers/update-teacher-image'),
        );

        // Add teacher_id as form field
        request.fields['teacher_id'] = teacherId.toString();

        // Add image file
        request.files.add(await http.MultipartFile.fromPath(
          'image', // This should match your API's expected parameter name
          pickedFile.path,
        ));

        // Send request
        final response = await request.send();
        final responseString = await response.stream.bytesToString();

        if (response.statusCode == 200) {
          final jsonResponse = json.decode(responseString);
            // Update local image with the new URL from server
            final imageUrl = jsonResponse['data']['image_url'];
            updateImage(imageUrl);
        } else {
          throw Exception('Server responded with ${response.statusCode}');
        }
      }
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
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
  final String holiday;
  final String email;
  final int week;
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
    required this.holiday,
    required this.email,
    required this.week,
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
      timetable: json['Timetable'] ?? json['Reschedule'] ?? [],
      image: json['image'],
      holiday: json['Holiday'] ?? '',
      email: json['email'] ?? '',
      week: json['week'] is int ? json['week'] : int.tryParse(json['week'] ?? '0') ?? 0,

    );
  }

  TeacherInfo copyWith({
    int? id,
    String? name,
    int? userId,
    String? gender,
    String? dateOfBirth,
    String? username,
    String? password,
    String? session,
    List<dynamic>? timetable,
    String? image,
    String? holiday,
    String? email,
    int? week
  }) {
    return TeacherInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      userId: userId ?? this.userId,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      username: username ?? this.username,
      password: password ?? this.password,
      session: session ?? this.session,
      timetable: timetable ?? this.timetable,
      image: image ?? this.image,
      holiday: holiday ?? this.holiday,
      email: email ?? this.email,
      week: week??this.week
    );
  }
}