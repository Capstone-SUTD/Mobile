import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:capstone_app/common/splash_screen.dart';
import 'package:capstone_app/web_screens/all_project_screen.dart';
import 'package:capstone_app/web_screens/dashboard_screen.dart';
import 'package:capstone_app/web_screens/web_splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Capstone App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: WebSplashScreen(), // ✅ Different splash screen for web
      debugShowCheckedModeBanner: false,  // Remove debug banner
      routes: {
        '/dashboard': (context) =>  DashboardScreen(), 
        '/projects': (context) => AllProjectsScreen(),
      },
    );
  }
}
