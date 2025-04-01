import 'package:flutter/material.dart';
// import 'package:capstone_app/mobile_screens/dashboard_screen.dart';
import 'package:capstone_app/web_screens/all_project_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:capstone_app/common/sign_up.dart'; // Or wherever your SignUpScreen is located

class LoginSignUpScreen extends StatefulWidget {
  const LoginSignUpScreen({Key? key}) : super(key: key);

  @override
  _LoginSignUpScreenState createState() => _LoginSignUpScreenState();
}

class _LoginSignUpScreenState extends State<LoginSignUpScreen> {
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _userIdFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _userIdController.text = '';
    _passwordController.text = '';
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _passwordController.dispose();
    _userIdFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _login(BuildContext context) async {
  final email = _userIdController.text.trim();
  final password = _passwordController.text.trim();

  if (email.isEmpty || password.isEmpty) {
    _showErrorBanner("Email and password cannot be empty.");
    return;
  }

  try {
    Dio dio = Dio();
    final response = await dio.post(
      'http://10.0.2.2:3000/auth/login', // 🔁 Replace with your actual login API
      data: {
        'email': email,
        'password': password,
      },
    );

    if (response.statusCode == 200 && response.data['token'] != null) {
      String token = response.data['token'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setInt(
          'token_expiry', DateTime.now().millisecondsSinceEpoch + (24 * 60 * 60 * 1000)); // 1 day

      // if (!mounted) return;

      _showSuccessBanner();


      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AllProjectsScreen()),
        );
      });
    } else {
      _showErrorBanner("Login failed. Please check your credentials.");
    }
  } catch (e) {
    print("Login error: $e");
    _showErrorBanner("An error occurred. Please try again.");
  }
}

void _showSuccessBanner() {
  ScaffoldMessenger.of(context).showMaterialBanner(
    MaterialBanner(
      content: const Text(
        'Login Successful!',
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Company logo
                const Text(
                  'OOG Navigator',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 24),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _userIdController,
                  focusNode: _userIdFocus,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) {
                    FocusScope.of(context).requestFocus(_passwordFocus);
                  },
                  decoration: const InputDecoration(
                    hintText: 'User ID',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _login(context),
                  decoration: const InputDecoration(
                    hintText: 'Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 70, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => _login(context),
                  child: const Text(
                    'Log In',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 70, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                   onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => SignUpScreen()), // This should be a class, not a method
                    );
                  },
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}