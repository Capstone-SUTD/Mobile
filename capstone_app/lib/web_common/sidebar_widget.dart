// import 'package:flutter/material.dart';
// import '../common/login_signup_screen.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class Sidebar extends StatelessWidget {
//   final String selectedPage;
//   final Function(String)? onPageSelected;

//   const Sidebar({
//     Key? key,
//     required this.selectedPage,
//     this.onPageSelected,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Drawer(
//       child: Container(
//         color: Colors.blue.shade900,
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             SizedBox(height: 20),

//             // Middle Icons (Projects)
//             Column(
//               children: [
//                 _buildSidebarIcon(
//                     context, Icons.list, "/projects", selectedPage == "/projects"),
//               ],
//             ),

//             // Bottom Icons (Logout)
//             Column(
//               children: [
//                 _buildSidebarIcon(context, Icons.logout, "/logout",
//                     selectedPage == "/logout", _handleLogout),
//                 SizedBox(height: 20),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // Helper function to create a Sidebar Icon
//   Widget _buildSidebarIcon(BuildContext context, IconData icon, String route, bool isSelected, [Function? onTap]) {
//     return IconButton(
//       icon: Icon(icon, color: isSelected ? Colors.orange : Colors.white),
//       onPressed: () {
//         Navigator.pop(context); // Close the drawer
//         if (route == "/logout") {
//           if (onTap != null) {
//             onTap(context);
//           }
//         } else {
//           if (ModalRoute.of(context)!.settings.name != route) {
//             Navigator.pushNamed(context, route);
//           }
//         }
//       },
//     );
//   }

//   Future<void> _handleLogout(BuildContext context) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove('auth_token');
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (context) => LoginSignUpScreen()),
//     );
//   }
// }
