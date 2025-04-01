import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../web_common/project_tab_widget.dart';
import '../web_common/project_stepper_widget.dart';
import 'msra_generation_screen.dart';
import '../web_common/step_label.dart';
import 'project_screen.dart';

/// File data holder for cross-platform file operations
class PickedFileData {
  final Uint8List bytes;
  final String fileName;
  PickedFileData(this.bytes, this.fileName);
}

/// Simplified Attachment Popup for cross-platform use
class AttachmentPopup extends StatelessWidget {
  final ValueChanged<PickedFileData> onAttach;

  const AttachmentPopup({Key? key, required this.onAttach}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Attach File"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: () async {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['jpg', 'png', 'pdf'],
                allowMultiple: false,
              );
              if (result != null && result.files.isNotEmpty) {
                final file = result.files.first;
                if (file.bytes != null) {
                  onAttach(PickedFileData(file.bytes!, file.name));
                  Navigator.pop(context);
                }
              }
            },
            child: const Text("Select File"),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
      ],
    );
  }
}

/// Comment Popup - Cross Platform
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
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialComment);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Add Comment"),
      content: TextField(
        controller: _controller,
        maxLines: 5,
        decoration: const InputDecoration(
          hintText: "Enter your comment...",
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onCommentAdded(_controller.text);
            Navigator.pop(context);
          },
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

/// Comments Conversation - Cross Platform
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
  State<CommentsConversationPopup> createState() => _CommentsConversationPopupState();
}

class _CommentsConversationPopupState extends State<CommentsConversationPopup> {
  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = true;

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
        Uri.parse("http://10.0.2.2:3000/project/get-task-comments?taskid=${widget.taskId}"),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          _comments = data.map((e) => e as Map<String, dynamic>).toList();
          _isLoading = false;
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Comments for ${widget.taskName}"),
      content: SizedBox(
        width: 600,
        height: 400,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: _comments.length,
                itemBuilder: (context, index) {
                  final comment = _comments[index];
                  return ListTile(
                    title: Text(comment['username'] ?? 'Unknown'),
                    subtitle: Text(comment['comments'] ?? ''),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteComment(comment['commentid']),
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

  Future<void> _deleteComment(int commentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.delete(
        Uri.parse("http://10.0.2.2:3000/project/delete-task-comment?commentid=$commentId"),
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
}

/// Main Onsite Checklist Screen - Cross Platform
class OnsiteChecklistScreen extends StatefulWidget {
  final dynamic project;
  const OnsiteChecklistScreen({Key? key, required this.project}) : super(key: key);

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
        Uri.parse("http://10.0.2.2:3000/project/get-project-checklist?projectid=${_project.projectId}"),
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
        Uri.parse("http://10.0.2.2:3000/project/update-checklist-completion"),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Onsite Checklist"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ProjectTabWidget(
                    selectedTabIndex: 2,
                    onTabSelected: (index) {
                      if (index == 1) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MSRAGenerationScreen(project: _project),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  ProjectStepperWidget(
                    currentStage: _project.stage,
                    projectId: _project.projectId,
                    onStepTapped: (_) {},
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
        title: Text(section, style: const TextStyle(fontWeight: FontWeight.bold)),
        initiallyExpanded: _sectionExpansionStates[section] ?? false,
        onExpansionChanged: (expanded) {
          setState(() {
            _sectionExpansionStates[section] = expanded;
          });
        },
        children: items.entries.map((item) {
          final task = item.value;
          return CheckboxListTile(
            title: Text(item.key),
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
                  icon: const Icon(Icons.comment),
                  onPressed: () => _showCommentDialog(task['taskid']),
                ),
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: () => _showAttachmentDialog(task['taskid']),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
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
      await _loadChecklistData();
    }
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
      await _loadChecklistData();
    }
  }

  Future<void> _addComment(int taskId, String comment) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.post(
        Uri.parse("http://localhost:3000/project/add-task-comments"),
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
        Uri.parse("http://10.0.2.2:3000/project/upload-blob-azure"),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['taskid'] = taskId.toString();
      request.files.add(http.MultipartFile.fromBytes(
        'file',
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
}