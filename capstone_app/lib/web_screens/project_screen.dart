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
  int selectedTabIndex = 0;
  int currentStep = 0;
  List<String> resultsOOG = [];
  List<PlatformFile> uploadedFiles = [];

  final GlobalKey<ProjectFormWidgetState> _formKey = GlobalKey<ProjectFormWidgetState>();
  final GlobalKey<CargoDetailsTableWidgetState> _cargoKey = GlobalKey<CargoDetailsTableWidgetState>();
  final GlobalKey<WorkScopeWidgetState> _workScopeKey = GlobalKey<WorkScopeWidgetState>();
  final GlobalKey _fileUploadKey = GlobalKey();

  // Page controller for the tab content
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadProjectData();
  }

  @override
  void dispose() {
    _pageController.dispose();
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
      Uri.parse('http://10.0.2.2:3000/project/new'),
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
        Uri.parse('http://10.0.2.2:3000/project/save'),
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
          Uri.parse('http://10.0.2.2:3000/project/generate-checklist'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'projectid': int.tryParse(projectId)}),
        );

        if (generateChecklistResponse.statusCode == 200) {
          print("Checklist generated successfully.");
          setState(() {
            isSaved = true;
            showChecklist = true;
            isGenerateMSRAEnabled = true;
          });
        } else {
          print("Checklist generation failed: ${generateChecklistResponse.body}");
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

  void onTabSelected(int index) {
    setState(() {
      selectedTabIndex = index;
    });
    
    // Animate to the selected page
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // Build project details content
  Widget _buildProjectDetailsContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProjectFormWidget(
              key: _formKey,
              project: _project,
              isNewProject: isNewProject,
            ),
            const SizedBox(height: 20),
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
            if (isOOG) ...[
              WorkScopeWidget(
                key: _workScopeKey,
                isNewProject: isNewProject,
                workScopeList: isNewProject ? null : _project!.scope,
              ),
              const SizedBox(height: 20),
              if (isNewProject || (_project!.scope?.isEmpty ?? true)) ...[
                Container(
                  width: 400,
                  child: FileUploadWidget(
                    key: _fileUploadKey,
                  ),
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
                    const SizedBox(width: 10),
                  ],
                ),
              ],
              const SizedBox(height: 20),
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
                              Uri.parse('http://10.0.2.2:3000/project/generate-docs'),
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
                                // Move to MS/RA Generation tab
                                selectedTabIndex = 2;
                                _pageController.animateToPage(
                                  2,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              });
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
              const SizedBox(height: 20),
            ],
          ],
        ),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(isNewProject ? "New Project" : _project!.projectName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.onPopCallback != null) {
              widget.onPopCallback!();
            }
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isNewProject && isOOG)
            ProjectTabWidget(
              selectedTabIndex: selectedTabIndex,
              onTabSelected: onTabSelected,
            ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(), // Disable swiping
              onPageChanged: (index) {
                setState(() {
                  selectedTabIndex = index;
                });
              },
              children: [
                // Page 0: Project Details
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildProjectDetailsContent(),
                    ),
                    // if ((isOOG && isSaved) || (isOOG && !(_project!.scope?.isEmpty ?? true)))
                    //   Expanded(
                    //     flex: 1,
                    //     child: SingleChildScrollView(
                    //       child: Padding(
                    //         padding: const EdgeInsets.only(top: 16.0),
                    //         child: OffsiteChecklistWidget(
                    //           projectId: int.tryParse(_project?.projectId.toString() ?? '0') ?? 0,
                    //         ),
                    //       ),
                    //     ),
                    //   ),
                  ],
                ),
                
                // Page 1: Offsite Checklist
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0), 
                    child: OffsiteChecklistWidget(
                      projectId: int.tryParse(_project?.projectId.toString() ?? '0') ?? 0,
                    ),
                  ),
                ),
                
                // Page 2: MS/RA Generation
                MSRAGenerationScreen(project: _project),
                
                // Page 3: Onsite Checklist
                OnsiteChecklistScreen(project: _project),
              ],
            ),
          ),
        ],
      ),
    );
  }
}