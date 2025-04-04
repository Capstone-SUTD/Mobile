import 'package:capstone_app/web_screens/all_project_screen.dart';
import 'package:flutter/material.dart';

class LoginSignupWidget extends StatefulWidget {
  @override
  _LoginSignupWidgetState createState() => _LoginSignupWidgetState();
}

class _LoginSignupWidgetState extends State<LoginSignupWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold( 
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Placeholder for company logo
                Image.asset(
                'assets/images/logo.png',
                height: 100,
                ),
              SizedBox(height: 20),
              Text(
                'Log In',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Handle login/signup action
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AllProjectsScreen()));
                },
                child: Text('Log In'),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}