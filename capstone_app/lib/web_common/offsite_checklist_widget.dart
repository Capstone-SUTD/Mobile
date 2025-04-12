import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../web_screens/msra_generation_screen.dart';
import '../web_screens/onsite_checklist_screen.dart';
import 'project_tab_widget.dart';
import '../web_screens/project_screen.dart';

class OffsiteChecklistWidget extends StatefulWidget {
  final dynamic project;
  //final int projectId;
  const OffsiteChecklistWidget({Key? key, required this.project}) : super(key: key);

  @override
  _OffsiteChecklistWidgetState createState() => _OffsiteChecklistWidgetState();
}

class _OffsiteChecklistWidgetState extends State<OffsiteChecklistWidget> {
  Map<String, bool> expandedSections = {};
  Map<String, dynamic> checklistData = {};
  bool isLoading = true;
  String? errorMessage;
  late dynamic _project;

  @override
  void initState() {
    super.initState();
    _project = widget.project;
    _fetchChecklistData();
  }

  Future<void> _fetchChecklistData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse("https://backend-app-huhre9drhvh6dphh.southeastasia-01.azurewebsites.net/project/get-project-checklist?projectid=${_project.projectId}"),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        _processChecklistData(jsonData['OffSiteFixed'] as Map<String, dynamic>);
      } else {
        throw Exception('Failed to load checklist: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      _handleError('Network error: ${e.message}');
    } on TimeoutException {
      _handleError('Request timed out');
    } catch (e) {
      _handleError('Error fetching checklist: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _processChecklistData(Map<String, dynamic> offsiteData) {
    final Map<String, dynamic> processedData = {};
    final Map<String, bool> sectionsState = {};

    offsiteData.forEach((section, content) {
      final List<String> descriptions = [];
      final int? taskId = content['taskid'];
      final bool completed = content['completed'] ?? false;
      final bool hasComments = content['has_comments'] ?? false;
      final bool hasAttachment = content['has_attachment'] ?? false;
      final String comments = content['comments'] ?? "";

      content.forEach((key, value) {
        if (!['taskid', 'completed', 'has_comments', 'has_attachment', 'comments'].contains(key)) {
          if (value is String) {
            descriptions.add(value);
          } else if (value is List) {
            descriptions.addAll(value.map((v) => v.toString()));
          } else if (value is Map) {
            descriptions.addAll(value.values.map((v) => v.toString()));
          }
        }
      });

      processedData[section] = {
        'taskid': taskId,
        'completed': completed,
        'has_comments': hasComments,
        'has_attachment': hasAttachment,
        'comments': comments,
        'descriptions': descriptions
      };

      sectionsState[section] = false;
    });

    if (mounted) {
      setState(() {
        checklistData = processedData;
        expandedSections = sectionsState;
      });
    }
  }

  Future<void> _updateChecklistStatus(int taskid, bool completed) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.post(
        Uri.parse("https://backend-app-huhre9drhvh6dphh.southeastasia-01.azurewebsites.net/project/update-checklist-completion"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'taskid': taskid, 'completed': completed}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('Failed to update checklist task $taskid');
      }
    } on http.ClientException catch (e) {
      _showErrorSnackbar('Network error: ${e.message}');
    } on TimeoutException {
      _showErrorSnackbar('Update timed out');
    } catch (e) {
      _showErrorSnackbar('Error updating checklist: $e');
    }
  }

  void _handleError(String message) {
    if (mounted) {
      setState(() => errorMessage = message);
    }
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onTabSelected(int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder:(_, __, ___) => ProjectScreen(
            projectId: _project?.projectId,
          ),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    }
    if (index == 2) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => MSRAGenerationScreen(project: _project),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    }
    if (index == 3) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => OnsiteChecklistScreen(project: _project),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Offsite Checklist"),
      backgroundColor: Colors.teal,
      foregroundColor: Colors.white,
      ),
      body: SizedBox(
        width: 1200,
        height: MediaQuery.of(context).size.height * 0.92,
        child: Container(
          padding: const EdgeInsets.all(16.0),
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _buildContent(), // this is your checklist UI
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            errorMessage!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchChecklistData,
            child: const Text('Retry'),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProjectTabWidget(
          selectedTabIndex: 1,
          onTabSelected: _onTabSelected,
        ),
        const SizedBox(height: 16),
        const Text(
          "Offsite Checklist",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: checklistData.keys.map((section) {
                return _buildChecklistSection(section);
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChecklistSection(String section) {
    final sectionData = checklistData[section];
    final isExpanded = expandedSections[section] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            leading: Checkbox(
              value: sectionData['completed'],
              onChanged: (bool? newValue) async {
                if (newValue != null) {
                  setState(() {
                    checklistData[section]['completed'] = newValue;
                  });
                  await _updateChecklistStatus(sectionData['taskid'], newValue);
                }
              },
            ),
            title: Text(
              section,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: IconButton(
              icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () {
                setState(() {
                  expandedSections[section] = !isExpanded;
                });
              },
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 32.0, bottom: 16, right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...(sectionData['descriptions'] as List<String>).map((desc) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        "• $desc",
                        style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
                      ),
                    );
                  }).toList(),
                  if (sectionData['comments']?.isNotEmpty ?? false)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        "Comments: ${sectionData['comments']}",
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}