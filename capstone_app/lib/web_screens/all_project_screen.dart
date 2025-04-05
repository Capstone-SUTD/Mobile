import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
//import '../web_common/sidebar_widget.dart';
import '../web_common/project_table_widget.dart';
import '../web_common/equipment_recommendation_widget.dart';
import '../models/project_model.dart';
import 'project_screen.dart';

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
        Uri.parse('http://10.0.2.2:3000/project/list'),
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
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.center,
                  //   children: [
                  //     ElevatedButton(
                  //       onPressed: () => _openEquipmentRecommendation(context),
                  //       child: const Text("Equipment Recommendation"),
                  //     ),
                  //     const SizedBox(width: 16),
                  //     ElevatedButton.icon(
                  //       onPressed: () => _createNewProject(context),
                  //       icon: const Icon(Icons.add),
                  //       label: const Text("New Project"),
                  //     ),
                  //   ],
                  // ),
                ],
              ),
            ),
          ),
        ],
        
      ),
      drawer: Drawer(
  child: ListView(
    padding: EdgeInsets.zero,
    children: [
      DrawerHeader(
        decoration: const BoxDecoration(
          color: Colors.deepPurple,
        ),
        child: const Text(
          'Project Menu',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
          ),
        ),
      ),
      const SizedBox(height: 20),
    //children: [
      ListTile(
        leading: const Icon(Icons.build),
        title: const Text("Equipment Recommendation"),
        onTap: () {
          Navigator.pop(context); // Close drawer
          _openEquipmentRecommendation(context);
        },
      ),
      ListTile(
        leading: const Icon(Icons.add),
        title: const Text("New Project"),
        onTap: () {
          Navigator.pop(context); // Close drawer
          _createNewProject(context);
        },
      ),
      ListTile(
        leading: const Icon(Icons.logout),
        title: const Text("Logout"),
        onTap: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('auth_token'); // Remove token
          
          Navigator.pushReplacementNamed(context, '/login'); // Navigate to login
        },
      ),
    ],
  ),
),

    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text("All Projects"),
      backgroundColor: Colors.white,
      elevation: 1,
    );
  }
}