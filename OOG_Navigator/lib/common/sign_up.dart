
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_signup_screen.dart';
import 'package:dio/dio.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  Future<void> _register(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      Dio dio = Dio();
      final response = await dio.post(
        'https://backend-app-huhre9drhvh6dphh.southeastasia-01.azurewebsites.net/auth/register',
        data: {
          'username': username,
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 201) {
        _showSuccessBanner();
        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;
          ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginSignUpScreen()),
          );
        });
      } else {
        _showErrorBanner("Signup failed. Please try again.");
      }
    } catch (e) {
      print("Signup error: $e");
      _showErrorBanner("An error occurred. Please try again.");
    }
  }

  void _showSuccessBanner() {
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        content: const Text(
          'Signup Successful!',
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
        backgroundColor: Colors.green,
        leading: const Icon(Icons.check_circle, color: Colors.white),
        margin: const EdgeInsets.all(10),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
            },
          ),
        ],
      ),
    );
  }

  void _showErrorBanner(String message) {
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        content: Text(
          message,
          style: const TextStyle(fontSize: 18, color: Colors.white),
        ),
        backgroundColor: Colors.red,
        margin: const EdgeInsets.all(10),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
            },
          ),
        ],
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
    });
  }

  InputDecoration _requiredFieldDecoration(String label) {
    return InputDecoration(
      hintText: '$label *',
      border: OutlineInputBorder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _usernameController,
                decoration: _requiredFieldDecoration('Username'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Username is required' : null,
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                decoration: _requiredFieldDecoration('Email'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Email is required' : null,
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: _requiredFieldDecoration('Password'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Password is required' : null,
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: _requiredFieldDecoration('Re-enter Password'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please re-enter password';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(horizontal: 70, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => _register(context),
                child: Text(
                  'Register',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}