import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lmsv2/teacher/course_content/teacher_course_content.dart';
import 'package:provider/provider.dart';
import '../Model/Comman Model.dart';
import '../alerts/custom_alerts.dart';
import '../auth/login_screen.dart';
import '../provider/instructor_provider.dart';
import 'package:lmsv2/Theme/Colors.dart';
import 'Home/Teacher_Main_Home.dart';
import 'Home/Teacher_Main_Notification.dart';
import 'Home/Teacher_Main_Profile.dart';
import 'Home/Teacher_Main_Task.dart';
class TeacherHome extends StatefulWidget {
  const TeacherHome({Key? key}) : super(key: key);
  @override
  _TeacherHomeState createState() => _TeacherHomeState();
}
const TextStyle bntText = TextStyle(
  color: black,
  fontWeight: FontWeight.w500,
);

class _TeacherHomeState extends State<TeacherHome> {
  int selectBtn = 0;
  final List<Widget> _screens = [
    const HomeScreen(),
    const CourseContent(),
    const TaskScreen(),
    const NotificationScreen(),
    const ProfileScreen(),
  ];
  @override
  Widget build(BuildContext context) {
    final instructorProvider = Provider.of<InstructorProvider>(context);
    instructorProvider.instructor?.id;
    String imageUrl;
    if (instructorProvider.instructor?.image != null && instructorProvider.instructor!.image!.isNotEmpty) {
      imageUrl = instructorProvider.instructor!.image!;
    } else {
      String name = instructorProvider.instructor?.name ?? "User";
      imageUrl = 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}background=4FC3F7&color=ffffff';
    }
    return WillPopScope(
      onWillPop: () async {
        bool shouldLogout = await CustomAlert.confirm(context, "Are you sure you want to logout?");
        if (shouldLogout) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => Login()), // Replace with your Login Page
                (route) => false, // Clears navigation stack
          );
        }
        return false; // Prevents default back navigation
      },
      child: Scaffold(
        backgroundColor:  Color(0xFF4448FF),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Color(0xFF4448FF), // The blue color from your design
          automaticallyImplyLeading: false, // Remove back button
          toolbarHeight: 100, // Increase height for the layout
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome Back!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
              ),
              Text(
                Provider.of<InstructorProvider>(context).instructor?.name ?? 'No Name',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                Provider.of<InstructorProvider>(context).type ?? 'Instructor',
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white, // White border
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey[200], // optional background
                  child: ClipOval(
                    child: Image.network(
                      imageUrl,
                      width: 56,  // double of radius
                      height: 56,
                      fit: BoxFit.contain,  // Keeps the full image visible
                    ),
                  ),
                ),
      
              ),
            ),
          ],
          // Extend the app bar to include system UI area (status bar)
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor:  Color(0xFF4448FF), // Same color as AppBar
            statusBarIconBrightness: Brightness.light, // Light status bar icons for dark background
          ),
        ),
        body: Column(
          children: [
            // Display the selected screen
            Expanded(
              child: _screens[selectBtn],
            ),
            // Navigation bar at the bottom
            navigationBar(),
          ],
        ),
      ),
    );
  }

  Widget navigationBar() {
    return AnimatedContainer(
      height: 70.0,
      duration: const Duration(milliseconds: 400),
      decoration: BoxDecoration(
        color: Color(0xFF4448FF),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(selectBtn == 0 ? 0.0 : 20.0),
          topRight:
          Radius.circular(selectBtn == navBtn.length - 1 ? 0.0 : 20.0),
        ),
      ),
      child: LayoutBuilder(
          builder: (context, constraints) {
            double itemWidth = constraints.maxWidth / navBtn.length;
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (int i = 0; i < navBtn.length; i++)
                  GestureDetector(
                    onTap: () => setState(() => selectBtn = i),
                    child: iconBtn(i, itemWidth),
                  ),
              ],
            );
          }
      ),
    );
  }

  Widget iconBtn(int i, double width) {
    bool isActive = selectBtn == i ? true : false;
    var height = isActive ? 60.0 : 0.0;
    var notchWidth = isActive ? 50.0 : 0.0;

    return SizedBox(
      width: width,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: AnimatedContainer(
              height: height,
              width: notchWidth,
              duration: const Duration(milliseconds: 600),
              child: isActive
                  ? CustomPaint(
                painter: ButtonNotch(),
              )
                  : const SizedBox(),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Image.asset(
              navBtn[i].imagePath,
              color: isActive ? Colors.amber : Colors.white,
              height: 22,
              width: 22,
              // Add error builder to help debug any issues
              errorBuilder: (context, error, stackTrace) {
                print('Error loading image: ${navBtn[i].imagePath}');
                // Fallback to a simple circle as placeholder
                return Container(
                  height: 22,
                  width: 22,
                  decoration: BoxDecoration(
                    color: isActive ? selectColor : black,
                    shape: BoxShape.circle,
                  ),
                );
              },
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 5.0),
              child: Text(
                navBtn[i].name,
                textAlign: TextAlign.center,
                style: isActive
                    ? bntText.copyWith(
                  color: Colors.amber,
                  fontSize: 11,
                )
                    : bntText.copyWith(
                  color: Colors.white,
                  fontSize: 11,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
