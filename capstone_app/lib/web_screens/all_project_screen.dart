import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
//import '../web_common/sidebar_widget.dart';
import '../web_common/project_table_widget.dart';
import '../web_common/equipment_recommendation_widget.dart';
import '../models/project_model.dart';
import 'project_screen.dart';
import '../common/login_signup_screen.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class AllProjectsScreen extends StatefulWidget {
  const AllProjectsScreen({super.key});

  @override
  _AllProjectsScreenState createState() => _AllProjectsScreenState();
}

class _AllProjectsScreenState extends State<AllProjectsScreen> with AutomaticKeepAliveClientMixin, RouteAware {
  List<Project> projectsList = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    getProjects();
  }

  @override
  void didPopNext() {
    super.didPopNext();
    getProjects();
  }

  Future<void> getProjects() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('https://backend-app-huhre9drhvh6dphh.southeastasia-01.azurewebsites.net/project/list'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        print("API raw response: ${response.body}");

        if (decoded is List) {
          List<Project> projects = List<Project>.from(
            decoded.map((item) => Project.fromJson(item)),
          );

          setState(() {
            projectsList = projects;
            isLoading = false;
            errorMessage = null;
          });
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to load projects: ${response.statusCode}');
      }
    } catch (error) {
      setState(() {
        errorMessage = 'Error fetching data: $error';
        isLoading = false;
      });
    }
  }

  void _openEquipmentRecommendation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const EquipmentRecommendationDialog();
      },
    );
  }

  void _createNewProject(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProjectScreen(
          projectId: null,
          onPopCallback: getProjects,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: _buildAppBar(),
      body: Row(
        children: [
          //Sidebar(selectedPage: '/projects'),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : errorMessage != null
                            ? Center(child: Text(errorMessage!))
                            : ProjectTableWidget(projects: projectsList),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
      backgroundColor: Colors.teal,
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      ListView(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        children: [
          ListTile(
            leading: const Icon(Icons.build, color: Colors.white,),
            title: const Text("Equipment Recommendation", textAlign: TextAlign.center, style:TextStyle(color: Colors.white),),
            onTap: () {
              Navigator.pop(context); // Close drawer
              _openEquipmentRecommendation(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.add, color: Colors.white,),
            title: const Text("New Project", textAlign: TextAlign.center, style:TextStyle(color: Colors.white),),
            onTap: () {
              Navigator.pop(context); // Close drawer
              _createNewProject(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white,),
            title: const Text("Logout", textAlign: TextAlign.center, style:TextStyle(color: Colors.white),),
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginSignUpScreen()),
                (route) => false,
              );
       },
),
    ],
  ),
    ],
  ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text("All Projects", style: TextStyle(color: Colors.white)),
      backgroundColor: Colors.teal,
      foregroundColor: Colors.white,
      elevation: 1,
    );
  }
}