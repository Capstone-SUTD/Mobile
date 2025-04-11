import 'package:flutter/material.dart';
import 'msra_file_upload_widget.dart';
import '../models/project_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io' as io;

class ApprovalListWidget extends StatefulWidget {
  final int selectedTab;
  final int approvalStage;
  final List stakeholders;
  final int projectid;
  final List<Map<String, dynamic>> rejectionList;
  final Function(int) onApprovalStageChange;
  final Function(String) onVersionIncrease;

  const ApprovalListWidget({
    super.key,
    required this.selectedTab,
    required this.approvalStage,
    required this.stakeholders,
    required this.projectid,
    required this.rejectionList,
    required this.onApprovalStageChange,
    required this.onVersionIncrease,
  });

  @override
  _ApprovalListWidgetState createState() => _ApprovalListWidgetState();
}

class _ApprovalListWidgetState extends State<ApprovalListWidget> {
  late List<Map<String, dynamic>> _pendingApprovals;
  final GlobalKey _fileUploadKey = GlobalKey();
  List<io.File> _uploadedFiles = [];

  @override
  void initState() {
    super.initState();
    _initializePendingApprovals();
  }

  void _initializePendingApprovals() {
    List<String> validRoles = ["HSEOfficer", "ProjectManager", "Head"];

    _pendingApprovals = widget.stakeholders
        .where((stakeholder) => validRoles.contains(stakeholder.role))
        .map((stakeholder) => {
              "name": stakeholder.name,
              "role": stakeholder.role,
              "approved": false,
              "rejected": false,
            })
        .toList();
  }

  Future<void> _approveProject(int projectId) async {
    final url = Uri.parse('https://backend-app-huhre9drhvh6dphh.southeastasia-01.azurewebsites.net/app/approve');

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception("Token not found");
      }

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "projectid": projectId,
        }),
      );

      if (response.statusCode == 200) {
        widget.onApprovalStageChange(widget.approvalStage + 1);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Approved successfully')),
        );
      } else {
        var responseData = jsonDecode(response.body);
        String errorMessage = responseData['error'] ?? 'Unknown error';
        _showErrorSnackbar("Failed. ($errorMessage)");
      }
    } catch (e) {
      _showErrorSnackbar("Error: ${e.toString()}");
    }
  }

  Widget _buildApprovalCard(int index, Map<String, dynamic> approval) {
    bool isEnabled = false;
    bool isApprovedOrRejected = approval["approved"] || approval["rejected"];

    if (widget.selectedTab == 0) {
      if (index < widget.approvalStage) {
        return const SizedBox();
      }
    } else if (widget.selectedTab == 1) {
      if (index >= widget.approvalStage) {
        return const SizedBox();
      }
    }

    if (widget.selectedTab == 0) {
      if (widget.approvalStage == 0 && approval["role"] == "HSEOfficer") {
        isEnabled = true;
        
      } else if (widget.approvalStage == 1 && approval["role"] == "ProjectManager") {
        isEnabled = true;
      } else if (widget.approvalStage == 2 && approval["role"] == "Head") {
        isEnabled = true;
      }
    }

    const Map<String, String> roleMapping = {
      "HSEOfficer": "HSE Officer",
      "ProjectManager": "Project Manager",
      "Head": "GPIS Head",
    };

    // For selectedTab == 1, display a disabled "Approved" button
    return Card(
      child: ListTile(
        title: Text("MSRA Approval by ${roleMapping[approval["role"]]}"),
        subtitle: Text("Action by ${approval["name"]}"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.selectedTab == 0) ...[
              ElevatedButton(
                onPressed: isEnabled && !isApprovedOrRejected
                    ? () => _approveProject(widget.projectid)
                    : null,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text("Approve"),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: isEnabled && !isApprovedOrRejected
                    ? () => _showRejectionDialog(approval)
                    : null,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text("Reject"),
              ),
            ],
            if (widget.selectedTab == 1) ...[
              ElevatedButton(
                onPressed: null,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text("Approved"),
              )
            ],
          ],
        ),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showRejectionDialog(Map<String, dynamic> approval) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Rejection Reason"),
          content: TextField(
            controller: reasonController,
            decoration: const InputDecoration(hintText: "Enter your rejection reason here"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                String comments = reasonController.text;
                _rejectProject(approval, comments);
                Navigator.of(context).pop();
              },
              child: const Text("Reject"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _rejectProject(Map<String, dynamic> approval, String comments) async {
    final url = Uri.parse('https://backend-app-huhre9drhvh6dphh.southeastasia-01.azurewebsites.net/app/reject');

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception("Token not found");
      }

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "projectid": widget.projectid,
          "comments": comments,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          if (_pendingApprovals.isNotEmpty) {
            var firstPendingApproval = _pendingApprovals[widget.approvalStage];
            var newRejection = {
              "role": firstPendingApproval["role"],
              "name": firstPendingApproval["name"],
              "comments": comments,
            };
            widget.rejectionList.add(newRejection);
            // Cannot modify widget.selectedTab directly as it's a final property
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Rejected successfully')),
            );
          }
        });
      } else {
        var responseData = jsonDecode(response.body);
        String errorMessage = responseData['error'] ?? 'Unknown error';
        _showErrorSnackbar("Failed to reject. ($errorMessage)");
      }
    } catch (e) {
      _showErrorSnackbar("Error: ${e.toString()}");
    }
  }

  Future<void> uploadFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (result != null) {
        _uploadedFiles = result.paths.map((path) => io.File(path!)).toList();
        await _uploadFilesToServer();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error selecting files: $e")),
      );
    }
  }

  Future<void> _uploadFilesToServer() async {
    final projectId = widget.projectid;
    String filetype = "";

    for (final file in _uploadedFiles) {
      final name = file.path.toLowerCase();
      if (name.contains('ms')) {
        filetype = "MS";
      } else if (name.contains('ra')) {
        filetype = "RA";
      }

      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token == null) throw Exception("Missing token");

        var request = http.MultipartRequest(
          'POST',
          Uri.parse('https://backend-app-huhre9drhvh6dphh.southeastasia-01.azurewebsites.net/app/reupload'),
        )
          ..headers['Authorization'] = 'Bearer $token'
          ..fields['projectid'] = projectId.toString()
          ..fields['filetype'] = filetype
          ..files.add(await http.MultipartFile.fromPath('file', file.path));

        var response = await request.send();

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("File uploaded successfully.")),
          );
          if (filetype.isNotEmpty) {
            widget.onVersionIncrease(filetype);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: ${response.statusCode}")),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error uploading file: $e")),
        );
      }
    }
  }

  Widget _buildRejectedCard(int index, Map<String, dynamic> rejection) {
    return Card(
      child: ListTile(
        title: Text("MSRA Rejection by ${rejection["role"]}"),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Action by ${rejection["name"]}"),
            const SizedBox(height: 8),
            Text("Comments: ${rejection["comments"]}"),
          ],
        ),
        trailing: widget.selectedTab == 2
            ? ElevatedButton(
                onPressed: null,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text("Rejected"),
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedTab == 0) {
      return ListView.builder(
        itemCount: _pendingApprovals.length,
        itemBuilder: (context, index) {
          var approval = _pendingApprovals[index];
          return _buildApprovalCard(index, approval);
        },
      );
    }

    if (widget.selectedTab == 1) {
      return ListView.builder(
        itemCount: _pendingApprovals.length,
        itemBuilder: (context, index) {
          var approval = _pendingApprovals[index];
          if (index < widget.approvalStage) {
            return _buildApprovalCard(index, approval);
          }
          return const SizedBox();
        },
      );
    }

    if (widget.selectedTab == 2) {
      return ListView.builder(
        itemCount: widget.rejectionList.length,
        itemBuilder: (context, index) {
          var rejection = widget.rejectionList[index];
          return _buildRejectedCard(index, rejection);
        },
      );
    }

    if (widget.selectedTab == 3) {
      return Column(
        children: [
          const SizedBox(height: 20),
          SizedBox(
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
                onPressed: uploadFile,
                child: const Text("Upload Revised MSRA"),
              ),
              const SizedBox(width: 10),
            ],
          ),
        ],
      );
    }

    return const Center(child: Text("No approvals available"));
  }
}