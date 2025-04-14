import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:lmsv2/firebase/notification_services.dart';
import 'package:lmsv2/provider/instructor_provider.dart';
import 'package:lmsv2/provider/student_provider.dart';
import 'package:lmsv2/splashscreen/ball%20bounce/index.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.instance.initialize(); // ⬅️ Call it here
  SharedPreferences prefs = await SharedPreferences.getInstance();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => InstructorProvider()),
        ChangeNotifierProvider(create: (_) => StudentProvider()),
        // Add other providers if needed
      ],
      child: const MyApp(),
    ),
  );
}
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}
class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LMS',
      theme: ThemeData(
          primaryColor: const Color(0xFF3969D7),
          scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home:BallBounceIndex(),
    );
  }
}
