
import 'package:flutter/material.dart';
import 'package:lmsv2/Student/Timetable.dart';
import 'package:lmsv2/Student/student_notification.dart';
import '../Profile.dart';
class TimetableTab extends StatefulWidget {
  const TimetableTab({Key? key}) : super(key: key);
  @override
  State<TimetableTab> createState() => _TimetableTabState();
}
class _TimetableTabState extends State<TimetableTab> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SizedBox(width: 2000,),
          ElevatedButton(onPressed: (){
            Navigator.push(context, MaterialPageRoute(builder: (context)=>StudentTimetableScreen()));
          },child: Text('Timetable Na View ')),
          Text('Hell no'),

          ElevatedButton(onPressed: (){
            Navigator.push(context, MaterialPageRoute(builder: (context)=>ProfileScreen()));
          },child: Text('Profile na view ')),
          ElevatedButton(onPressed: (){
            Navigator.push(context, MaterialPageRoute(builder: (context)=>NotificationScreen()));
          },child: Text('Notification na View ')),
        ],
      ),

    );
  }
}
