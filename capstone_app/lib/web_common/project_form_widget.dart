import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project_model.dart';

class ProjectFormWidget extends StatefulWidget {
  final Project? project;
  final bool isNewProject;

  const ProjectFormWidget({
    Key? key,
    this.project,
    required this.isNewProject,
  }) : super(key: key);

  @override
  ProjectFormWidgetState createState() => ProjectFormWidgetState();
}

class ProjectFormWidgetState extends State<ProjectFormWidget> {
  late TextEditingController _nameController;
  late TextEditingController _clientController;
  late TextEditingController _emailController;
  late TextEditingController _startDateController;

  List<Map<String, String>> selectedStakeholders = [];
  List<Map<String, dynamic>> stakeholdersList = [];
  Set<String> selectedRoles = {};
  bool _isLoadingStakeholders = false;
  String? _stakeholderError;

  final List<String> _roleOptions = ["HSEOfficer", "Operations", "ProjectManager", "Additional"];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _fetchStakeholders();
  }

  void _initializeControllers() {
    final formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _nameController = TextEditingController(text: widget.project?.projectName ?? "");
    _clientController = TextEditingController(text: widget.project?.client ?? "");
    _emailController = TextEditingController(text: widget.project?.emailsubjectheader ?? "");
    _startDateController = TextEditingController(
      text: widget.isNewProject ? formattedDate : widget.project?.startDate.toString() ?? "",
    );

    // Initialize stakeholders for new project
    if (widget.isNewProject) {
      selectedStakeholders = [
        {"userId": "", "role": "HSEOfficer", "name": ""},
        {"userId": "", "role": "Operations", "name": ""},
        {"userId": "", "role": "ProjectManager", "name": ""},
      ];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _clientController.dispose();
    _emailController.dispose();
    _startDateController.dispose();
    super.dispose();
  }

  Future<void> _fetchStakeholders() async {
    if (!widget.isNewProject) return;

    setState(() {
      _isLoadingStakeholders = true;
      _stakeholderError = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception("Authentication token not found");
      }

      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/project/stakeholders'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          stakeholdersList = data.map((s) => {
            "userId": s["userid"].toString(),
            "name": s["username"].toString(),
            "email": s["email"]?.toString() ?? "",
          }).toList();
        });
      } else {
        throw Exception("Failed to load stakeholders: ${response.statusCode}");
      }
    } on http.ClientException catch (e) {
      setState(() => _stakeholderError = "Network error: ${e.message}");
    } on TimeoutException {
      setState(() => _stakeholderError = "Request timed out");
    } catch (e) {
      setState(() => _stakeholderError = "Error: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() => _isLoadingStakeholders = false);
      }
    }
  }

  bool _isRoleSelectedElsewhere(String role, int currentIndex) {
    return selectedStakeholders.any((s) =>
        s["role"] == role && role != "Additional" && selectedStakeholders.indexOf(s) != currentIndex);
  }

  void _addStakeholder() {
    setState(() {
      selectedStakeholders.add({"userId": "", "role": "Additional", "name": ""});
    });
  }

  void _removeStakeholder(int index) {
    setState(() {
      selectedStakeholders.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField("Project Name", _nameController),
          const SizedBox(height: 16),
          _buildTextField("Client", _clientController),
          const SizedBox(height: 16),
          _buildStakeholderSection(),
          const SizedBox(height: 16),
          _buildTextField("Email Subject Header", _emailController),
          const SizedBox(height: 16),
          _buildTextField("Start Date", _startDateController, readOnly: true),
        ],
      ),
    );
  }

  Widget _buildStakeholderSection() {
    if (!widget.isNewProject && widget.project != null && widget.project!.stakeholders.isNotEmpty) {
      return _buildStakeholdersTable(widget.project!.stakeholders);
    }

    if (widget.isNewProject) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Stakeholders",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (_isLoadingStakeholders)
            const Center(child: CircularProgressIndicator()),
          if (_stakeholderError != null)
            Text(
              _stakeholderError!,
              style: const TextStyle(color: Colors.red),
            ),
          if (!_isLoadingStakeholders && _stakeholderError == null)
            ..._buildStakeholderInputs(),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  List<Widget> _buildStakeholderInputs() {
    return List.generate(selectedStakeholders.length, (index) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Select Stakeholder",
                  border: OutlineInputBorder(),
                ),
                items: stakeholdersList.map((s) {
                  return DropdownMenuItem<String>(
                    value: s["userId"] as String,
                    child: Text(s["name"]!),
                  );
                }).toList(),
                value: selectedStakeholders[index]["userId"]!.isNotEmpty
                    ? selectedStakeholders[index]["userId"]
                    : null,
                onChanged: (value) {
                  setState(() {
                    selectedStakeholders[index]["userId"] = value!;
                    final selectedStakeholder = stakeholdersList.firstWhere((s) => s["userId"] == value);
                    selectedStakeholders[index]["name"] = selectedStakeholder["name"]!;
                  });
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 3,
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Role",
                  border: OutlineInputBorder(),
                ),
                items: _roleOptions.map((role) {
                  bool isDisabled = _isRoleSelectedElsewhere(role, index);
                  return DropdownMenuItem(
                    value: role,
                    child: Text(
                      role,
                      style: TextStyle(
                        color: isDisabled ? Colors.grey : Colors.black,
                      ),
                    ),
                    enabled: !isDisabled || role == "Additional",
                  );
                }).toList(),
                value: selectedStakeholders[index]["role"]!.isNotEmpty
                    ? selectedStakeholders[index]["role"]
                    : null,
                onChanged: (value) {
                  if (!_isRoleSelectedElsewhere(value!, index) || value == "Additional") {
                    setState(() {
                      selectedStakeholders[index]["role"] = value;
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 48,
              child: index == 0
                  ? IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.blue),
                      onPressed: _addStakeholder,
                    )
                  : index > 2
                      ? IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () => _removeStakeholder(index),
                        )
                      : const SizedBox.shrink(),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStakeholdersTable(List<Stakeholder> stakeholders) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Stakeholders", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Table(
            border: TableBorder.all(color: Colors.grey),
            columnWidths: {
              0: FlexColumnWidth(3),
              1: FlexColumnWidth(3),
              2: FlexColumnWidth(3),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.grey[300]),
                children: [
                  _buildHeaderCell("Name"),
                  _buildHeaderCell("Email"),
                  _buildHeaderCell("Role"),
                ],
              ),
              for (var stakeholder in stakeholders)
                TableRow(
                  children: [
                    _buildTableCell(stakeholder.name ?? ""),
                    _buildTableCell(stakeholder.email ?? ""),
                    _buildTableCell(stakeholder.role),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 15),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool readOnly = false}) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildHeaderCell(String title) {
    return TableCell(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildTableCell(String value) {
    return TableCell(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Text(value, textAlign: TextAlign.center),
      ),
    );
  }

  List<Stakeholder> getSelectedStakeholders() {
    return selectedStakeholders.map((s) {
      final rawUserId = s["userId"];
      final parsedUserId = int.tryParse(rawUserId ?? '') ?? -1;
      return Stakeholder(
        userId: parsedUserId,
        role: s["role"] ?? "",
        name: s["name"] ?? "",
      );
    }).toList();
  }

  String getProjectName() => _nameController.text;
  String getClient() => _clientController.text;
  String getEmailSubjectHeader() => _emailController.text;
}