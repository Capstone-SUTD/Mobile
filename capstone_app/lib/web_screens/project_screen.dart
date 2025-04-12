import 'package:flutter/material.dart';
import '../models/project_model.dart';
import '../models/data_service.dart';
import '../web_common/project_tab_widget.dart';
import '../web_common/project_form_widget.dart';
import '../web_common/cargo_details_table_widget.dart';
import '../web_common/work_scope_widget.dart';
import '../web_common/offsite_checklist_widget.dart';
import '../web_common/msra_file_upload_widget.dart';
import 'msra_generation_screen.dart';
import 'onsite_checklist_screen.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../web_common/step_label.dart';

class ProjectScreen extends StatefulWidget {
  final String? projectId;
  final VoidCallback? onPopCallback;

  const ProjectScreen({Key? key, this.projectId, this.onPopCallback}) : super(key: key);

  @override
  _ProjectScreenState createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  Project? _project;
  bool isNewProject = true;
  bool isOOG = false;
  bool isLoading = true;
  bool hasRun = false;
  bool isSaving = false;
  bool isSaved = false;
  bool showChecklist = false;
  bool isGenerateMSRAEnabled = false;
  bool hasGenerateMSRA = false;
  bool showOffsiteChecklist = false;
  int selectedTabIndex = 0;
  int currentStep = 0;
  List<String> resultsOOG = [];
  List<PlatformFile> uploadedFiles = [];

  final GlobalKey<ProjectFormWidgetState> _formKey = GlobalKey<ProjectFormWidgetState>();
  final GlobalKey<CargoDetailsTableWidgetState> _cargoKey = GlobalKey<CargoDetailsTableWidgetState>();
  final GlobalKey<WorkScopeWidgetState> _workScopeKey = GlobalKey<WorkScopeWidgetState>();
  final GlobalKey _fileUploadKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadProjectData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadProjectData() async {
    if (widget.projectId != null) {
      List<Project> projects = await DataService.getProjects();
      Project? foundProject = projects.firstWhere(
        (p) => p.projectId == widget.projectId,
        orElse: () => Project(
          client: '',
          projectId: '',
          projectName: '',
          projectType: '',
          startDestination: '',
          endDestination: '',
          projectStatus: '',
          emailsubjectheader: '',
          stage: '',
          startDate: DateTime.now(),
          stakeholders: [],
          cargo: [],
          scope: [],
        ),
      );

      if (foundProject.projectId.isNotEmpty) {
        setState(() {
          _project = foundProject;
          if (_project!.stage != null && _project!.stage!.isNotEmpty) {
            final stageLabel = _project!.stage!.toLowerCase();
            //final index = kStepLabels.indexWhere((label) => label.toLowerCase() == stageLabel);
            //currentStep = index >= 0 ? index : 0;
          }
          isNewProject = false;
          isOOG = true;
          hasRun = isOOG;
          isLoading = false;
        });
      }
    } else {
      setState(() {
        _project = Project(
          client: '',
          projectId: '',
          projectName: '',
          projectType: '',
          startDestination: '',
          endDestination: '',
          projectStatus: '',
          emailsubjectheader: '',
          stage: '',
          startDate: DateTime.now(),
          stakeholders: [],
          cargo: [],
          scope: [],
        );
        isNewProject = true;
        isLoading = false;
      });
    }
  }

  Future<void> _onRunPressed() async {
    final stakeholders = _formKey.currentState?.getSelectedStakeholders() ?? [];
    print("Sending stakeholders: $stakeholders");
    final cargo = _cargoKey.currentState?.getCargoList() ?? [];

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Authentication token missing")),
      );
      return;
    }

    final response = await http.post(
      Uri.parse('https://backend-app-huhre9drhvh6dphh.southeastasia-01.azurewebsites.net/project/new'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "projectname": _formKey.currentState?.getProjectName(),
        "client": _formKey.currentState?.getClient(),
        "emailsubjectheader": _formKey.currentState?.getEmailSubjectHeader(),
        "stakeholders": stakeholders,
        "cargo": cargo,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      bool setOOG = false;
      List<String> resultList = [];
      if (responseData['cargo'] != null) {
        for (int i = 0; i < responseData['cargo'].length; i++) {
          String? oogResult = responseData['cargo'][i]['oog'];
          String result = oogResult == "Yes" ? "OOG" : "Normal";
          resultList.add(result);

          if (oogResult == "Yes") {
            setOOG = true;
          }
        }
      }

      setState(() {
        hasRun = true;
        isOOG = setOOG;
        String projectType = isOOG ? "OOG" : "Normal";
        resultsOOG = resultList;

        _project = Project(
          client: _formKey.currentState?.getClient() ?? '',
          projectId: responseData["projectid"]?.toString() ?? '',
          projectName: _formKey.currentState?.getProjectName() ?? '',
          projectType: projectType,
          startDestination: '',
          endDestination: '',
          projectStatus: '',
          emailsubjectheader: '',
          stage: '',
          startDate: DateTime.now(),
          stakeholders: stakeholders,
          cargo: [], 
          scope: [],
        );
      });
    } else {
      print("Failed to classify OOG. Status: ${response.statusCode}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to classify OOG: ${response.statusCode}")),
      );
    }
  }

  void onSavePressed() async {
    setState(() {
      isSaving = true;
    });

    final projectId = _project?.projectId ?? "";
    final rawScopeList = _workScopeKey.currentState?.getWorkScopeData() ?? [];

    PlatformFile? vendorMS;
    PlatformFile? vendorRA;

    for (final file in uploadedFiles) {
      final name = file.name.toLowerCase();
      if (vendorMS == null && name.contains('ms')) {
        vendorMS = file;
      } else if (vendorRA == null && name.contains('ra')) {
        vendorRA = file;
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception("Missing token");

      final scopeList = rawScopeList.map((row) {
        return {
          "start": row["startDestination"] ?? "",
          "end": row["endDestination"] ?? "",
          "work": row["scope"] ?? "",
          "equipment": row["equipmentList"] ?? "",
        };
      }).toList();

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://backend-app-huhre9drhvh6dphh.southeastasia-01.azurewebsites.net/project/save'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['projectid'] = projectId;
      request.fields['scope'] = jsonEncode(scopeList);

      if (vendorMS != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'VendorMS',
          vendorMS.path!,
          filename: vendorMS.name,
        ));
      }

      if (vendorRA != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'VendorRA',
          vendorRA.path!,
          filename: vendorRA.name,
        ));
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      setState(() {
        isSaving = false;
      });

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Project saved successfully.")),
        );

        final generateChecklistResponse = await http.post(
          Uri.parse('https://backend-app-huhre9drhvh6dphh.southeastasia-01.azurewebsites.net/project/generate-checklist'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'projectid': int.tryParse(projectId)}),
        );

        if (generateChecklistResponse.statusCode == 200) {
          print("✅ Checklist generated successfully.");
          setState(() {
            isSaved = true;
            showChecklist = true;
            showOffsiteChecklist = true;
            isGenerateMSRAEnabled = true;
          });
          
          // Scroll to the bottom to show the offsite checklist
          Future.delayed(Duration(milliseconds: 300), () {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: 500),
              curve: Curves.easeOut,
            );
          });
        } else {
          print("❌ Checklist generation failed: ${generateChecklistResponse.body}");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Checklist generation failed")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${response.statusCode} - $responseBody")),
        );
      }
    } catch (e) {
      setState(() {
        isSaving = false;
      });
      print("Error saving project: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving project: $e")),
      );
    }
  }

  void toggleOffsiteChecklist() {
    setState(() {
      showOffsiteChecklist = !showOffsiteChecklist;
    });
    
    if (showOffsiteChecklist) {
      Future.delayed(Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<Project?> fetchProjectById(String projectId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final response = await http.get(
      Uri.parse('https://backend-app-huhre9drhvh6dphh.southeastasia-01.azurewebsites.net/project/list'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      final projectJson = data.firstWhere(
          (p) => p['projectid'].toString() == projectId,
          orElse: () => null);
      return projectJson != null ? Project.fromJson(projectJson) : null;
    }
    return null;
  }

  void onTabSelected(int index) {
    setState(() {
      selectedTabIndex = index;
    });

    Widget screen;

    switch (index) {
      case 0:
        screen = ProjectScreen(projectId: _project?.projectId);
        break;
      case 1:
        screen = OffsiteChecklistWidget(project: _project);
        break;
      case 2:
        screen = MSRAGenerationScreen(project: _project);
        break;
      case 3:
        screen = OnsiteChecklistScreen(project: _project);
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => screen,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Show toggle button only when we have OOG project and either saved or has scope
    bool shouldShowChecklistToggle = isOOG && ((isSaved) || (!(_project!.scope?.isEmpty ?? true)));

    // Mobile-optimized layout
    return Scaffold(
      appBar: AppBar(
        title: Text(isNewProject ? "New Project" : _project!.projectName),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.onPopCallback != null) {
              widget.onPopCallback!();
            }
            Navigator.pop(context);
          },
        ),
        // actions: shouldShowChecklistToggle ? [
        //   // Only show toggle button in app bar
        //   TextButton.icon(
        //     icon: Icon(
        //       showOffsiteChecklist ? Icons.visibility_off : Icons.visibility,
        //       color: Theme.of(context).primaryTextTheme.bodyLarge?.color,
        //     ),
        //     label: Text(
        //       showOffsiteChecklist ? "Hide Checklist" : "Show Checklist",
        //       style: TextStyle(
        //         color: Theme.of(context).primaryTextTheme.bodyLarge?.color,
        //       ),
        //     ),
        //     onPressed: toggleOffsiteChecklist,
        //   ),
        // ] : null,
      ),
      body: Column(
        children: [
          if (!isNewProject && isOOG)
            ProjectTabWidget(
              selectedTabIndex: selectedTabIndex,
              onTabSelected: onTabSelected,
            ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main project form
                    ProjectFormWidget(
                      key: _formKey,
                      project: _project,
                      isNewProject: isNewProject,
                    ),
                    const SizedBox(height: 20),
                    
                    // Cargo details
                    CargoDetailsTableWidget(
                      key: _cargoKey,
                      cargoList: _project!.cargo,
                      isNewProject: isNewProject,
                      isEditable: isNewProject,
                      hasRun: hasRun,
                      onRunPressed: _onRunPressed,
                      resultList: resultsOOG,
                    ),
                    const SizedBox(height: 20),
                    
                    // Work scope and related widgets for OOG projects
                    if (isOOG) ...[
                      WorkScopeWidget(
                        key: _workScopeKey,
                        isNewProject: isNewProject,
                        workScopeList: isNewProject ? null : _project!.scope,
                      ),
                      const SizedBox(height: 20),
                      
                      // File upload and save button for new projects
                      if (isNewProject || (_project!.scope?.isEmpty ?? true)) ...[
                        FileUploadWidget(
                          key: _fileUploadKey,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              onPressed: isSaving ? null : onSavePressed,
                              child: isSaving
                                ? const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Text("Saving..."),
                                    ]
                                  )
                                : const Text("Save"),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 20),
                      
                      // Generate MS/RA button
                      if ((isOOG && isSaved) || (isOOG && _project?.msra != true && !(_project!.scope?.isEmpty ?? true))) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              onPressed: hasGenerateMSRA
                                ? null
                                : () async {
                                    final prefs = await SharedPreferences.getInstance();
                                    final token = prefs.getString('auth_token');

                                    final rawProjectId = _project?.projectId;
                                    int? projectId;

                                    if (rawProjectId is Set) {
                                      final firstValue = (rawProjectId as Set).first;
                                      projectId = int.tryParse(firstValue.toString());
                                    } else {
                                      projectId = int.tryParse(rawProjectId.toString());
                                    }

                                    if (projectId == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Invalid project ID.")),
                                      );
                                      return;
                                    }

                                    try {
                                      final response = await http.post(
                                        Uri.parse('https://backend-app-huhre9drhvh6dphh.southeastasia-01.azurewebsites.net/project/generate-docs'),
                                        headers: {
                                          'Authorization': 'Bearer $token',
                                          'Content-Type': 'application/json',
                                        },
                                        body: jsonEncode({
                                          'projectid': projectId,
                                        }),
                                      );

                                      if (response.statusCode == 200) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("MS/RA generated successfully")),
                                        );

                                        setState(() {
                                          hasGenerateMSRA = true;
                                        });

                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => MSRAGenerationScreen(project: _project),
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text("Generation failed: ${response.body}")),
                                        );
                                      }
                                    } catch (e) {
                                      print("Error triggering MS/RA generation: $e");
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text("An error occurred while generating MS/RA"),
                                        ),
                                      );
                                    }
                                  },
                              child: const Text("Generate MS/RA"),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      // Remove the floating action button
    );
  }
}