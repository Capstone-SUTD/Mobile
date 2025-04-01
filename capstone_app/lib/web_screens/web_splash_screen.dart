import 'package:flutter/material.dart';
import 'package:capstone_app/web_screens/dashboard_screen.dart';
import 'package:capstone_app/common/login_signup_screen.dart';

class WebSplashScreen extends StatefulWidget {
  @override
  _WebSplashScreenState createState() => _WebSplashScreenState();
}

class _WebSplashScreenState extends State<WebSplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 2), () {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginSignUpScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'OOG Web Navigator',
          style: TextStyle(
            fontSize: 26,
            color: Colors.blue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

