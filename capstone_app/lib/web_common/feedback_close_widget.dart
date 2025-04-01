import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/project_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FeedbackAndClose extends StatefulWidget {
  final List<Stakeholder> stakeholders;
  final VoidCallback onClose;
  final Future<List<Stakeholder>> Function() fetchUpdatedStakeholders;
  final String projectId;

  const FeedbackAndClose({
    required this.stakeholders,
    required this.onClose,
    required this.fetchUpdatedStakeholders,
    required this.projectId,
    Key? key,
  }) : super(key: key);

  @override
  _FeedbackAndCloseState createState() => _FeedbackAndCloseState();
}

class _FeedbackAndCloseState extends State<FeedbackAndClose> {
  final Map<int, TextEditingController> _controllers = {};
  List<Stakeholder> _updatedStakeholders = [];

  @override
  void initState() {
    super.initState();
    _updatedStakeholders = widget.stakeholders;
    for (var stakeholder in _updatedStakeholders) {
      _controllers[stakeholder.userId] = TextEditingController();
    }
  }

  Future<void> _submitFeedback(int userId, String role) async {
    String feedback = _controllers[userId]?.text ?? "";
    if (feedback.isEmpty) return;

    await _sendFeedbackToAPI(userId, feedback, role);

    List<Stakeholder> updatedList = await widget.fetchUpdatedStakeholders();

    setState(() {
        _updatedStakeholders = List.from(updatedList); // Create a new reference
        _controllers.clear(); // Clear old controllers
        for (var stakeholder in _updatedStakeholders) {
        _controllers[stakeholder.userId] = TextEditingController();
        }
    });
    }

  Future<void> _sendFeedbackToAPI(int userId, String feedback, String role) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');

        if (token == null) {
        throw Exception("Token not found");
        }

        final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/project/feedback'),
        headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json', // optional but recommended
        },
        body: jsonEncode({
            'projectid': int.tryParse(widget.projectId ?? "0") ?? 0, 
            'comments' : feedback,
            'role' : role,
        }),
        );

        if (response.statusCode == 200) {
            ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Feedback submitted succesfully')),
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

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "Feedback and Close",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: _updatedStakeholders.map((stakeholder) {
                bool hasComments =
                    stakeholder.comments != null && stakeholder.comments!.isNotEmpty;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Container(
                    width: double.infinity,
                    child: Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Feedback from ${stakeholder.name ?? "Unknown"}",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            if (hasComments)
                              Container(
                                width: double.infinity,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 10.0),
                                  child: Text(
                                    stakeholder.comments!,
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                              )
                            else
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextField(
                                    controller: _controllers[stakeholder.userId],
                                    decoration: InputDecoration(
                                      labelText: "Enter your feedback...",
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: ElevatedButton(
                                      onPressed: () => _submitFeedback(stakeholder.userId, stakeholder.role),
                                      child: Text("Submit Feedback"),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: widget.onClose,
          child: Text("Close Project"),
        ),
      ],
    );
  }
}