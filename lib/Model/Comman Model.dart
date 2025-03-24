import 'package:flutter/cupertino.dart';
import '../Theme/Colors.dart';
class Model {
  final int id;
  final String imagePath;
  final String name;

  Model({
    required this.id,
    required this.imagePath,
    required this.name,
  });
}
class Task {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final bool isCompleted;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.isCompleted,
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    bool? isCompleted,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
class NotificationModel {
  final int id;
  final String title;
  final String description;
  final String url;
  final String notificationDate;
  final String sender;
  final String senderName;
  final String? senderImage;
  final String mediaType;
  final String media;

  NotificationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.url,
    required this.notificationDate,
    required this.sender,
    required this.senderName,
    this.senderImage,
    required this.mediaType,
    required this.media,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      url: json['url'],
      notificationDate: json['notification_date'],
      sender: json['sender'],
      senderName: json['sender_name'],
      senderImage: json['sender_image'],
      mediaType: json['media_type'],
      media: json['media'],
    );
  }
}
List<Model> navBtn = [
  Model(id: 0, imagePath: 'assets/home.png', name: 'Home'),
  Model(id: 1, imagePath: 'assets/bell.png', name: 'Notification'),
  Model(id: 2, imagePath: 'assets/more.png', name: 'Task'),
  Model(id: 3, imagePath: 'assets/user.png', name: 'Profile'),
  Model(id: 4, imagePath: 'assets/settings.png', name: 'Setting'),
];
class ButtonNotch extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var dotPoint = Offset(size.width / 2, 2);

    var paint_1 = Paint()
      ..color = bgColor
      ..style = PaintingStyle.fill;
    var paint_2 = Paint()
      ..color = white
      ..style = PaintingStyle.fill;

    var path = Path();

    path.moveTo(0, 0);
    path.quadraticBezierTo(7.5, 0, 12, 5);
    path.quadraticBezierTo(size.width / 2, size.height / 2, size.width - 12, 5);
    path.quadraticBezierTo(size.width - 7.5, 0, size.width, 0);
    path.close();
    canvas.drawPath(path, paint_1);
    canvas.drawCircle(dotPoint, 6, paint_2);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
class UserData {
  static String? userId;
  static String? email;
}