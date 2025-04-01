import 'package:flutter/material.dart';
import '../common/login_signup_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Sidebar extends StatelessWidget {
  final String selectedPage;
  final Function(String)? onPageSelected;

  const Sidebar({
    Key? key,
    required this.selectedPage,
    this.onPageSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Container(
      width: 80,
      color: Colors.blue.shade900,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Ensures top, middle, and bottom spacing
        children: [
          // Empty Spacer for top padding
          SizedBox(height: 20),

          // Middle Icons (Home & Projects)
          Column(
            children: [
              _buildSidebarIcon(
                context, Icons.list, "/projects", selectedPage == "/projects"),
            ],
          ),

          // Bottom Icons (User & Logout)
          Column(
            children: [
              _buildSidebarIcon(
                context, Icons.logout, "/logout", selectedPage == "/logout", _handleLogout), // Attach the logout handler here
              SizedBox(height: 20), // Extra padding at bottom
            ],
          ),
        ],
      ),
    );
  }

  // 🔹 Helper function to create a Sidebar Icon
  Widget _buildSidebarIcon(BuildContext context, IconData icon, String route, bool isSelected, [Function? onTap]) {
    return IconButton(
      icon: Icon(icon, color: isSelected ? Colors.orange : Colors.white),
      onPressed: () {
        if (route == "/logout") {
          if (onTap != null) {
            onTap(context); // Call the logout handler when logout is clicked
          }
        } else {
          if (ModalRoute.of(context)!.settings.name != route) {
            Navigator.pushNamed(context, route);
          }
        }
      },
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Clear the token from SharedPreferences
    await prefs.remove('auth_token');
    
    // Redirect to Login/Signup screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginSignUpScreen()),
    );
  }
}