import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../web_common/project_tab_widget.dart';
import 'msra_generation_screen.dart';
import 'project_screen.dart';
import '../web_common/offsite_checklist_widget.dart';

/// File data holder for cross-platform file operations
class PickedFileData {
  final Uint8List bytes;
  final String fileName;
  final String mimeType;
  
  PickedFileData(this.bytes, this.fileName, this.mimeType);
}

/// Improved Attachment Popup for mobile interface
class AttachmentPopup extends StatefulWidget {
  final ValueChanged<PickedFileData> onAttach;

  const AttachmentPopup({Key? key, required this.onAttach}) : super(key: key);

  @override
  State<AttachmentPopup> createState() => _AttachmentPopupState();
}

class _AttachmentPopupState extends State<AttachmentPopup> {
  Uint8List? _pickedBytes;
  String _pickedFileName = '';
  String _mimeType = '';
  bool _isLoading = false;

  // Add missing style definitions
  final ButtonStyle tealButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFFE0F7F7),
    foregroundColor: const Color(0xFF167D86),
  );

  final ButtonStyle tealOutlineStyle = OutlinedButton.styleFrom(
    foregroundColor: const Color(0xFF167D86),
    side: const BorderSide(color: Color(0xFF167D86)),
  );

  Future<void> _pickFile() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        allowMultiple: false,
        withData: true, // Ensure we get the file bytes
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        
        if (file.bytes != null) {
          // Determine mime type based on extension
          String mimeType = 'application/octet-stream'; // Default
          final extension = file.extension?.toLowerCase() ?? '';
          
          if (extension == 'pdf') {
            mimeType = 'application/pdf';
          } else if (extension == 'jpg' || extension == 'jpeg') {
            mimeType = 'image/jpeg';
          } else if (extension == 'png') {
            mimeType = 'image/png';
          }
          
          setState(() {
            _pickedBytes = file.bytes!;
            _pickedFileName = file.name;
            _mimeType = mimeType;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error selecting file: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Attach File"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _pickFile,
            style: tealButtonStyle,
            icon: const Icon(Icons.upload_file),
            label: const Text("Select File"),
          ),
          const SizedBox(height: 15),
          if (_isLoading)
            const CircularProgressIndicator(color: Color(0xFF167D86)),
          if (_pickedFileName.isNotEmpty && !_isLoading)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(
                    _mimeType.startsWith('image/') ? Icons.image : Icons.insert_drive_file,
                    color: const Color(0xFF167D86),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Selected: $_pickedFileName",
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: (_pickedBytes != null && _pickedFileName.isNotEmpty && !_isLoading)
              ? () {
                  widget.onAttach(
                    PickedFileData(_pickedBytes!, _pickedFileName, _mimeType),
                  );
                  Navigator.pop(context);
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF167D86),
            foregroundColor: Colors.white,
          ),
          child: const Text("Attach"),
        ),
      ],
    );
  }
}

/// View Attachment Dialog - Improved to handle different file types
/// View Attachment Dialog - Improved to handle different file types
class ViewAttachmentDialog extends StatelessWidget {
  final Uint8List fileBytes;
  final String fileName;
  final String taskName;
  final String mimeType;

  const ViewAttachmentDialog({
    Key? key, 
    required this.fileBytes, 
    required this.fileName,
    required this.taskName,
    required this.mimeType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Attachment for $taskName"),
      content: SizedBox(
        width: 300,
        height: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              fileName,
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildPreviewWidget(context),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close"),
        ),
      ],
    );
  }
  
  Widget _buildPreviewWidget(BuildContext context) {
    if (mimeType.startsWith('image/')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          fileBytes,
          fit: BoxFit.contain,
        ),
      );
    } else if (mimeType == 'application/pdf') {
      // For PDF, we show an icon with file name
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.picture_as_pdf, size: 80, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            "PDF preview not available",
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.open_in_new),
            label: const Text("Open PDF"),
            onPressed: () {
              // Using the context parameter now
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("PDF opening not implemented")),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      );
    } else {
      // For other file types
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.insert_drive_file, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            "Preview not available for this file type",
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
  }
}
/// Main Onsite Checklist Screen - Mobile interface
class OnsiteChecklistScreen extends StatefulWidget {
  final dynamic project;
  const OnsiteChecklistScreen({Key? key, required this.project})
      : super(key: key);

  @override
  State<OnsiteChecklistScreen> createState() => _OnsiteChecklistScreenState();
}

class _OnsiteChecklistScreenState extends State<OnsiteChecklistScreen> {
  late dynamic _project;
  bool _isLoading = true;
  final Map<String, bool> _sectionExpansionStates = {};
  final Map<String, Map<String, dynamic>> _checklistData = {};
  
  // Track attachment upload progress
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _project = widget.project;
    _loadChecklistData();
  }

  Future<void> _loadChecklistData() async {
    try {
      setState(() => _isLoading = true);
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.get(
        Uri.parse(
            "https://backend-app-huhre9drhvh6dphh.southeastasia-01.azurewebsites.net/project/get-project-checklist?projectid=${_project.projectId}"),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        _checklistData.clear();
        _sectionExpansionStates.clear();
        
        data.forEach((section, items) {
          _checklistData[section] = {};
          _sectionExpansionStates[section] = false;

          if (items is Map) {
            items.forEach((subtype, details) {
              _checklistData[section]![subtype] = {
                'taskid': details['taskid'],
                'completed': details['completed'] ?? false,
                'has_comments': details['has_comments'] ?? false,
                'has_attachment': details['has_attachment'] ?? false,
                'descriptions': details['descriptions'] ?? [],
                'file_type': details['file_type'] ?? '',
                'file_name': details['file_name'] ?? '',
              };
            });
          }
        });
      } else {
        throw Exception("Failed to load checklist data");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading checklist: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateTaskStatus(int taskId, bool completed) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.post(
        Uri.parse(
            "https://backend-app-huhre9drhvh6dphh.southeastasia-01.azurewebsites.net/project/update-checklist-completion"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'taskid': taskId, 'completed': completed}),
      );

      if (response.statusCode != 200) {
        throw Exception("Failed to update task status");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating task: $e")),
      );
    }
  }

  void _onTabSelected(int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => ProjectScreen(
            projectId: _project?.projectId,
          ),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    }
    if (index == 1) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) =>
              OffsiteChecklistWidget(project: _project),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Onsite Checklist"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF167D86)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ProjectTabWidget(
                        selectedTabIndex: 3,
                        onTabSelected: _onTabSelected,
                      ),
                      const SizedBox(height: 20),
                      ..._checklistData.entries.map((entry) {
                        final section = entry.key;
                        final items = entry.value;
                        return _buildChecklistSection(section, items);
                      }).toList(),
                    ],
                  ),
                ),
          if (_isUploading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF167D86)),
                    SizedBox(height: 16),
                    Text(
                      "Uploading file...",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChecklistSection(String section, Map<String, dynamic> items) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title:
            Text(section, style: const TextStyle(fontWeight: FontWeight.bold)),
        initiallyExpanded: _sectionExpansionStates[section] ?? false,
        onExpansionChanged: (expanded) {
          setState(() {
            _sectionExpansionStates[section] = expanded;
          });
        },
        children: items.entries.map((item) {
          final taskName = item.key;
          final task = item.value;
          final bool hasComments = task['has_comments'] == true;
          final bool hasAttachment = task['has_attachment'] == true;

          return Column(
            children: [
              CheckboxListTile(
                title: Text(taskName),
                value: task['completed'],
                onChanged: (value) {
                  setState(() {
                    task['completed'] = value;
                  });
                  _updateTaskStatus(task['taskid'], value!);
                },
                secondary: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.comment,
                        color: hasComments ? Colors.teal : null,
                      ),
                      tooltip: "Comments",
                      onPressed: () => _showCommentOptions(
                          task['taskid'], taskName, hasComments),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.attach_file,
                        color: hasAttachment ? Colors.teal : null,
                      ),
                      tooltip: hasAttachment ? "View or Replace Attachment" : "Add Attachment",
                      onPressed: () => _showAttachmentOptions(
                          task['taskid'], taskName, hasAttachment),
                    ),
                  ],
                ),
              ),
              if (hasAttachment)
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.insert_drive_file, size: 16, color: Colors.teal),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          task['file_name'] ?? "Attached file",
                          style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text("View", style: TextStyle(fontSize: 12)),
                        onPressed: () => _viewAttachment(task['taskid'], taskName),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(0, 30),
                        ),
                      ),
                    ],
                  ),
                ),
              if (task['descriptions'] != null &&
                  task['descriptions'].isNotEmpty)
                Padding(
                  padding:
                      const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:
                        (task['descriptions'] as List).map<Widget>((desc) {
                      return Text("• $desc",
                          style: const TextStyle(fontSize: 13));
                    }).toList(),
                  ),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Future<void> _showCommentOptions(
      int taskId, String taskName, bool hasComments) async {
    if (hasComments) {
      // Show options: Add new or View existing
      final choice = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Comment Options"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add_comment),
                title: const Text("Add New Comment"),
                onTap: () => Navigator.pop(context, "add"),
              ),
              ListTile(
                leading: const Icon(Icons.comment),
                title: const Text("View All Comments"),
                onTap: () => Navigator.pop(context, "view"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
          ],
        ),
      );

      if (choice == "add") {
        await _showCommentDialog(taskId);
      } else if (choice == "view") {
        await _showCommentsConversation(taskId, taskName);
      }
    } else {
      // Directly show add comment dialog
      await _showCommentDialog(taskId);
    }
  }

  Future<void> _showAttachmentOptions(
      int taskId, String taskName, bool hasAttachment) async {
    if (hasAttachment) {
      // Show options: Add new or View existing
      final choice = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Attachment Options"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.upload_file),
                title: const Text("Replace Attachment"),
                onTap: () => Navigator.pop(context, "add"),
              ),
              ListTile(
                leading: const Icon(Icons.visibility),
                title: const Text("View Attachment"),
                onTap: () => Navigator.pop(context, "view"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
          ],
        ),
      );

      if (choice == "add") {
        await _showAttachmentDialog(taskId);
      } else if (choice == "view") {
        await _viewAttachment(taskId, taskName);
      }
    } else {
      // Directly show add attachment dialog
      await _showAttachmentDialog(taskId);
    }
  }

  Future<void> _showCommentDialog(int taskId) async {
    final comment = await showDialog<String>(
      context: context,
      builder: (context) => CommentPopup(
        initialComment: "",
        onCommentAdded: (text) => Navigator.pop(context, text),
      ),
    );

    if (comment != null && comment.isNotEmpty) {
      await _addComment(taskId, comment);
      await _loadChecklistData(); // Refresh to update UI
    }
  }

  Future<void> _showCommentsConversation(int taskId, String taskName) async {
    await showDialog(
      context: context,
      builder: (context) => CommentsConversationPopup(
        taskId: taskId,
        taskName: taskName,
        projectId: int.tryParse(_project.projectId.toString()) ?? 0,
      ),
    );

    // Refresh data after viewing/editing comments
    await _loadChecklistData();
  }

  Future<void> _showAttachmentDialog(int taskId) async {
    final fileData = await showDialog<PickedFileData>(
      context: context,
      builder: (context) => AttachmentPopup(
        onAttach: (data) => Navigator.pop(context, data),
      ),
    );

    if (fileData != null) {
      await _uploadAttachment(taskId, fileData);
    }
  }

  Future<void> _viewAttachment(int taskId, String taskName) async {
    try {
      final attachmentData = await _fetchAttachment(taskId);
      if (attachmentData != null) {
        final fileBytes = attachmentData['bytes'] as Uint8List;
        final fileName = attachmentData['fileName'] as String;
        final mimeType = attachmentData['mimeType'] as String;
        
        await showDialog(
          context: context,
          builder: (context) => ViewAttachmentDialog(
            fileBytes: fileBytes,
            fileName: fileName,
            taskName: taskName,
            mimeType: mimeType,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("No attachment found or error retrieving")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading attachment: $e")),
      );
    }
  }

  Future<void> _addComment(int taskId, String comment) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.post(
        Uri.parse(
            "https://backend-app-huhre9drhvh6dphh.southeastasia-01.azurewebsites.net/project/add-task-comments"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'taskid': taskId,
          'comments': comment,
          'projectid': _project.projectId,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception("Failed to add comment");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error adding comment: $e")),
      );
    }
  }

  Future<void> _uploadAttachment(int taskId, PickedFileData fileData) async {
    try {
      setState(() => _isUploading = true);
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(
            "https://backend-app-huhre9drhvh6dphh.southeastasia-01.azurewebsites.net/project/upload-blob-azure"),
      );
      
      // Add authorization
      request.headers['Authorization'] = 'Bearer $token';
      
      // Add file metadata
      request.fields['taskid'] = taskId.toString();
      request.fields['file_type'] = fileData.mimeType;
      request.fields['file_name'] = fileData.fileName;
      
      // Add the file
      request.files.add(http.MultipartFile.fromBytes(
        'file', // Field name for the file
        fileData.bytes,
        filename: fileData.fileName,
      ));

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("File uploaded successfully")),
        );
        await _loadChecklistData(); // Refresh UI
      } else {
        throw Exception("Failed to upload file: ${response.body}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error uploading file: $e")),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<Map<String, dynamic>?> _fetchAttachment(int taskId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      // First get the metadata and signed URL
      final metadataResponse = await http.get(
        Uri.parse(
            "https://backend-app-huhre9drhvh6dphh.southeastasia-01.azurewebsites.net/project/get-file-metadata?taskid=$taskId"),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (metadataResponse.statusCode != 200) {
        throw Exception("Failed to get file metadata");
      }
      
      final metadata = jsonDecode(metadataResponse.body);
      final String fileName = metadata['file_name'] ?? 'attachment';
      final String mimeType = metadata['file_type'] ?? 'application/octet-stream'; 
      
      // Get the signed URL
      final urlResponse = await http.get(
        Uri.parse(
            "https://backend-app-huhre9drhvh6dphh.southeastasia-01.azurewebsites.net/project/get-blob-url?taskid=$taskId"),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (urlResponse.statusCode != 200) {
        throw Exception("Failed to get file URL");
      }

      // Parse URL from response
      final urlData = jsonDecode(urlResponse.body);
      String signedUrl;
      
      if (urlData is String) {
        signedUrl = urlData;
      } else if (urlData is Map && urlData['signedUrl'] is String) {
        signedUrl = urlData['signedUrl'];
      } else {
        throw Exception("Invalid URL format received");
      }

      // Now fetch the actual file using the signed URL
      final fileResponse = await http.get(Uri.parse(signedUrl));
      
      if (fileResponse.statusCode != 200) {
        throw Exception("Failed to download file content");
      }
      
      return {
        'bytes': fileResponse.bodyBytes,
        'fileName': fileName,
        'mimeType': mimeType,
      };
    } catch (e) {
      print("Error fetching attachment: $e");
      return null;
    }
  }
}

// Comment Popup and Comments Conversation remain the same
class CommentPopup extends StatefulWidget {
  final String initialComment;
  final ValueChanged<String> onCommentAdded;

  const CommentPopup({
    Key? key,
    required this.initialComment,
    required this.onCommentAdded,
  }) : super(key: key);

  @override
  State<CommentPopup> createState() => _CommentPopupState();
}

class _CommentPopupState extends State<CommentPopup> {
  late TextEditingController _controller;
  bool isSaveEnabled = false;
  String? validationMessage;
  final int maxChars = 200;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialComment);
    isSaveEnabled = widget.initialComment.trim().isNotEmpty;

    _controller.addListener(() {
      setState(() {
        isSaveEnabled = _controller.text.trim().isNotEmpty;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Add Comment"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            maxLines: 5,
            maxLength: maxChars,
            decoration: InputDecoration(
              hintText: "Enter your comment...",
              border: const OutlineInputBorder(),
              counterText: "${_controller.text.trim().length} / $maxChars",
            ),
          ),
          if (validationMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                validationMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: isSaveEnabled
              ? () {
                  if (_controller.text.trim().isEmpty) {
                    setState(() {
                      validationMessage = "Comment cannot be empty";
                    });
                  } else {
                    widget.onCommentAdded(_controller.text.trim());
                    Navigator.pop(context, _controller.text.trim());
                  }
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF167D86),
            foregroundColor: Colors.white,
          ),
          child: const Text("Save"),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// Improved Comments Conversation - Mobile version
class CommentsConversationPopup extends StatefulWidget {
  final int taskId;
  final String taskName;
  final int projectId;

  const CommentsConversationPopup({
    Key? key,
    required this.taskId,
    required this.taskName,
    required this.projectId,
  }) : super(key: key);

  @override
  State<CommentsConversationPopup> createState() =>
      _CommentsConversationPopupState();
}

class _CommentsConversationPopupState extends State<CommentsConversationPopup> {
  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = true;
  Map<int, bool> isEditing = {}; // track editing state
  Map<int, TextEditingController> controllers = {}; // controllers for editing

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.get(
        Uri.parse(
            "https://backend-app-huhre9drhvh6dphh.southeastasia-01.azurewebsites.net/project/get-task-comments?taskid=${widget.taskId}"),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          _comments = data.map((e) => e as Map<String, dynamic>).toList();
          _isLoading = false;

          // Initialize controllers for editing
          for (var comment in _comments) {
            final id = int.tryParse(comment['commentid'].toString()) ?? 0;
            isEditing[id] = false;
            controllers[id] =
                TextEditingController(text: comment['comments'] ?? "");
          }
        });
      } else {
        throw Exception("Failed to load comments");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading comments: $e")),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteComment(int commentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.delete(
        Uri.parse(
            "https://backend-app-huhre9drhvh6dphh.southeastasia-01.azurewebsites.net/project/delete-task-comment?commentid=$commentId&taskid=${widget.taskId}"),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        await _loadComments();
      } else {
        throw Exception("Failed to delete comment");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting comment: $e")),
      );
    }
  }

  Future<void> _updateComment(int commentId) async {
    try {
      final text = controllers[commentId]?.text.trim() ?? "";
      if (text.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.post(
        Uri.parse(
            "https://backend-app-huhre9drhvh6dphh.southeastasia-01.azurewebsites.net/project/update-task-comments"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          'commentid': commentId,
          'comments': text,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          isEditing[commentId] = false;
        });
        await _loadComments();
      } else {
        throw Exception("Failed to update comment");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating comment: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Comments for ${widget.taskName}"),
      content: SizedBox(
        width: 300,
        height: 400,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                color: Color(0xFF167D86),
              ))
            : _comments.isEmpty
                ? const Center(
                    child: Text("No comments yet"),
                  )
                : ListView.builder(
                    itemCount: _comments.length,
                    itemBuilder: (context, index) {
                      final comment = _comments[index];
                      final commentId = comment['commentid'];
                      final username = comment['username'] ?? 'Unknown';
                      final editing = isEditing[commentId] ?? false;
                      final controller = controllers[commentId]!;

                      return Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              username,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            editing
                                ? TextField(
                                    controller: controller,
                                    maxLines: null,
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      border: OutlineInputBorder(),
                                    ),
                                  )
                                : Text(comment['comments'] ?? ''),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: Icon(editing ? Icons.check : Icons.edit),
                                  tooltip: editing ? 'Save' : 'Edit',
                                  onPressed: () {
                                    if (editing) {
                                      _updateComment(commentId);
                                    } else {
                                      setState(() => isEditing[commentId] = true);
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  tooltip: 'Delete',
                                  onPressed: () => _deleteComment(commentId),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
      actions: [
        ElevatedButton.icon(
          icon: const Icon(Icons.add_comment),
          label: const Text("Add Comment"),
          onPressed: () async {
            final comment = await showDialog<String>(
              context: context,
              builder: (context) => CommentPopup(
                initialComment: "",
                onCommentAdded: (text) => Navigator.pop(context, text),
              ),
            );

            if (comment != null && comment.isNotEmpty) {
              try {
                final prefs = await SharedPreferences.getInstance();
                final token = prefs.getString('auth_token');

                final response = await http.post(
                  Uri.parse(
                      "https://backend-app-huhre9drhvh6dphh.southeastasia-01.azurewebsites.net/project/add-task-comments"),
                  headers: {
                    'Authorization': 'Bearer $token',
                    'Content-Type': 'application/json',
                  },
                  body: jsonEncode({
                    'taskid': widget.taskId,
                    'comments': comment,
                    'projectid': widget.projectId,
                  }),
                );

                if (response.statusCode == 200) {
                  await _loadComments();
                } else {
                  throw Exception("Failed to add comment");
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error adding comment: $e")),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF167D86),
            foregroundColor: Colors.white,
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close"),
        ),
      ],
    );
  }

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
