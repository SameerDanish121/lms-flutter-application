import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lmsv2/splashscreen/splash_Services.dart';
class BallBounceIndex extends StatefulWidget {
  BallBounceIndex({super.key});
  @override
  State<BallBounceIndex> createState() => _BallBounceIndexState();
}
class _BallBounceIndexState extends State<BallBounceIndex> {
  SplashServices sp = SplashServices();
  @override
  void initState() {
    super.initState();
    sp.isLogin(context);
  }
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 130),
              child: CircleAvatar(
                backgroundColor: Color(0xFF3969D7),
              )
                  .animate()
                  .scaleXY(end: 15, duration: 1.5.seconds, curve: Curves.easeIn),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/splash_screen.png',
                  width: 200,  // Match Flutter logo size
                  height: 200, // Match Flutter logo size
                  fit: BoxFit.contain,  // Ensures it maintains its aspect ratio
                )
                    .animate()
                    .fadeIn(delay: 1.5.seconds, duration: 1.seconds)
                    .slideX(begin: 2.5, duration: 1.5.seconds, curve: Curves.easeOut),
                SizedBox(height: 20),
                Text(
                  "LMS",
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Montserrat',
                    color: Colors.white,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 3.seconds, duration: 0.5.seconds)
                    .slideY(begin: -0.5, duration: 0.5.seconds, curve: Curves.easeOut),
                SizedBox(height: 5),
                Text(
                  "Empowering Minds, Igniting Futures.",
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Lora',
                    fontStyle: FontStyle.italic,
                    color: Colors.white,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 3.5.seconds, duration: 0.5.seconds)
                    .slideY(begin: -0.3, duration: 0.5.seconds, curve: Curves.easeOut),
              ],
            ),
          )
        ],
      ),
    );
  }
}
