import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../web_common/project_tab_widget.dart';
// import '../web_common/project_stepper_widget.dart';
import 'msra_generation_screen.dart';
// import '../web_common/step_label.dart';
import 'project_screen.dart';
import '../web_common/offsite_checklist_widget.dart';

/// File data holder for cross-platform file operations
class PickedFileData {
  final Uint8List bytes;
  final String fileName;
  PickedFileData(this.bytes, this.fileName);
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

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'pdf'],
      allowMultiple: false,
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.bytes != null) {
        setState(() {
          _pickedBytes = file.bytes!;
          _pickedFileName = file.name;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Attach File"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: _pickFile,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE0F7F7),
              foregroundColor: const Color(0xFF167D86),
            ),
            child: const Text("Select File"),
          ),
          const SizedBox(height: 10),
          if (_pickedFileName.isNotEmpty)
            Text(
              "Selected: $_pickedFileName",
              style: const TextStyle(fontSize: 13),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _pickedBytes != null
              ? () {
                  widget
                      .onAttach(PickedFileData(_pickedBytes!, _pickedFileName));
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

/// Improved Comment Popup - Mobile version
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
                    // Navigator.pop(context);
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

/// New View Attachment Dialog
class ViewAttachmentDialog extends StatelessWidget {
  final Uint8List imageBytes;
  final String taskName;

  const ViewAttachmentDialog(
      {Key? key, required this.imageBytes, required this.taskName})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Attachment for $taskName"),
      content: SizedBox(
        width: 300,
        height: 300,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            imageBytes,
            fit: BoxFit.contain,
          ),
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

  @override
  void initState() {
    super.initState();
    _project = widget.project;
    _loadChecklistData();
  }

  Future<void> _loadChecklistData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.get(
        Uri.parse(
            "https://backend-app-huhre9drhvh6dphh.southeastasia-01.azurewebsites.net/project/get-project-checklist?projectid=${_project.projectId}"),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

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
              };
            });
          }
        });

        setState(() => _isLoading = false);
      } else {
        throw Exception("Failed to load checklist data");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading checklist: $e")),
      );
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
          final bool hasComments = task['has_comments'] ?? false;
          final bool hasAttachment = task['has_attachment'] ?? false;

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
                      onPressed: () => _showCommentOptions(
                          task['taskid'], taskName, hasComments),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.attach_file,
                        color: hasAttachment ? Colors.teal : null,
                      ),
                      onPressed: () => _showAttachmentOptions(
                          task['taskid'], taskName, hasAttachment),
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
                title: const Text("Add New Attachment"),
                onTap: () => Navigator.pop(context, "add"),
              ),
              ListTile(
                leading: const Icon(Icons.image),
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
        await _showViewAttachment(taskId, taskName);
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
      await _loadChecklistData(); // Refresh to update UI
    }
  }

  Future<void> _showViewAttachment(int taskId, String taskName) async {
    try {
      final bytes = await _fetchAttachmentImageBytes(taskId);
      if (bytes != null) {
        await showDialog(
          context: context,
          builder: (context) => ViewAttachmentDialog(
            imageBytes: bytes,
            taskName: taskName,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("No attachment found or error retrieving.")),
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
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(
            "https://backend-app-huhre9drhvh6dphh.southeastasia-01.azurewebsites.net/project/upload-blob-azure"),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['taskid'] = taskId.toString();
      request.files.add(http.MultipartFile.fromBytes(
        'file', // Changed from 'image' to match mobile interface
        fileData.bytes,
        filename: fileData.fileName,
      ));

      final response = await request.send();
      if (response.statusCode != 200) {
        throw Exception("Failed to upload attachment");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error uploading attachment: $e")),
      );
    }
  }

  Future<Uint8List?> _fetchAttachmentImageBytes(int taskId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      // First get the signed URL
      final response = await http.get(
        Uri.parse(
            "https://backend-app-huhre9drhvh6dphh.southeastasia-01.azurewebsites.net/project/get-blob-url?taskid=$taskId"),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final raw = jsonDecode(response.body);
        String? signedUrl;

        // Handle case A: plain string
        if (raw is String) {
          signedUrl = raw;
        }
        // Handle case B: JSON object with a key
        else if (raw is Map && raw['signedUrl'] is String) {
          signedUrl = raw['signedUrl'] as String;
        } else {
          throw Exception("Unexpected format for signed URL");
        }

        // Now fetch the actual image using the signed URL
        final imageResponse = await http.get(Uri.parse(signedUrl));
        if (imageResponse.statusCode == 200) {
          return imageResponse.bodyBytes;
        } else {
          throw Exception("Failed to load image from signed URL");
        }
      } else {
        throw Exception("Failed to get blob URL");
      }
    } catch (e) {
      print("Error fetching attachment: $e");
      return null;
    }
  }
}
